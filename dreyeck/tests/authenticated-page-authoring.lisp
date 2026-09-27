;;;; Authenticated FedWiki page authoring: identity, freshness, authorization.
;;;;
;;;; Keys are generated in memory for each run and dropped with it; none is
;;;; stored or printed. Cross-language agreement on the signatures themselves
;;;; is AUTHORING-ENVELOPE's test vector. Times are passed as :NOW, so nothing
;;;; here waits for a clock, and concurrent requests are released together
;;;; right before the challenge is used up.

(defpackage #:dreyeck/authenticated-page-authoring/tests
  (:use #:cl)
  (:local-nicknames (#:aa #:dreyeck/authenticated-page-authoring)
                    (#:ae #:dreyeck/authoring-envelope)
                    (#:pa #:dreyeck/fedwiki-page-authoring)
                    (#:fa #:dreyeck/fedwiki-assets)
                    (#:mat #:dreyeck/fedwiki-page-materialization)
                    (#:bt #:bordeaux-threads)
                    (#:views #:html-inspector-views))
  (:export #:run-authenticated-page-authoring-tests))

(in-package #:dreyeck/authenticated-page-authoring/tests)

;;; Signing, as a client would

(defparameter +n+ #xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141)

(defun hex (octets) (ironclad:byte-array-to-hex-string octets))
(defun utf8 (string) (sb-ext:string-to-octets string :external-format :utf-8))

(defun make-test-key ()
  "An ephemeral key pair: the private key object and the compressed public key."
  (multiple-value-bind (private public) (ironclad:generate-key-pair :secp256k1)
    (let ((point (getf (ironclad:destructure-public-key public) :y)))
      (values private (format nil "~A~A" (if (evenp (aref point 64)) "02" "03") (hex (subseq point 1 33)))))))

(defun sign (private octets)
  "A compact low-s signature of the Keccak-256 of OCTETS."
  (let* ((signature (ironclad:sign-message private (ae:keccak-256 octets)))
         (s (ironclad:octets-to-integer (subseq signature 32))))
    (format nil "~A~(~64,'0X~)" (hex (subseq signature 0 32)) (if (> s (floor +n+ 2)) (- +n+ s) s))))

(defun envelope (&key (service "hyperdoc-authoring-test") principal (operation "fedwiki-page-edit")
                      (site "dreyeck.ch") (page "work-breakdown") challenge nonce issued-at expires-at body
                      (version "hyperdoc-authoring-v1"))
  (utf8 (format nil "~A~%service=~A~%principal=~A~%operation=~A~%site=~A~%page=~A~%nonce=~A~%issued-at=~D~%expires-at=~D~%body-keccak256=~A"
                version service principal operation site page
                (or nonce (aa:authoring-challenge-nonce challenge))
                (or issued-at (aa:authoring-challenge-issued-at challenge))
                (or expires-at (aa:authoring-challenge-expires-at challenge))
                (hex (ae:keccak-256 body)))))

(defun signed-request (private &rest keys &key body &allow-other-keys)
  (let ((envelope (apply #'envelope keys)))
    (list :envelope envelope :body body :signature (sign private envelope))))

;;; A site, a page, principals and an authority

(defun obj (&rest plist)
  (let ((object (make-hash-table :test #'equal)))
    (loop for (key value) on plist by #'cddr do (setf (gethash key object) value))
    object))

(defun json (value) (let ((*print-pretty* nil)) (shasht:write-json value nil)))

(defparameter *next-id* 0)
(defun next-id () (format nil "~(~16,'0X~)" (incf *next-id*)))

(defun work-items ()
  (flet ((topic (topic label kind page)
           (obj "id" (next-id) "type" "work-topic" "topic" topic "label" label "kind" kind "status" "draft" "page" page))
         (rel (from relation to)
           (obj "id" (next-id) "type" "work-relationship" "from" from "relation" relation "to" to
                "text" (format nil "~A ~A ~A." from relation to))))
    (list (topic "interaction" "Interaction" "area" "Interaction")
          (topic "operations" "Operations and change" "area" "Operations and Change")
          (topic "connect" "Connect / Associations" "area" "Connect and Associations")
          (topic "work:relation/informs" "informs" "relation" "Relation Contract: informs")
          (topic "work:relation/requires" "requires" "relation" "Relation Contract: informs")
          (rel "interaction" "work:relation/informs" "operations")
          (rel "operations" "work:relation/informs" "connect"))))

(defun make-site ()
  (let ((root (uiop:ensure-directory-pathname
               (merge-pathnames (format nil "dreyeck-authenticated-authoring-~A/" (symbol-name (gensym "RUN-")))
                                (uiop:temporary-directory)))))
    (ensure-directories-exist (merge-pathnames "pages/" root))
    (dolist (slug '("work-breakdown" "other-page"))
      (let ((items (work-items)))
        (mat:materialize-fedwiki-page-json
         (obj "title" slug "story" (coerce items 'vector)
              "journal" (vector (obj "type" "create" "id" (next-id) "item" (obj "title" slug "story" (coerce items 'vector))
                                     "date" 1790000000000)))
         root slug)))
    root))

(defparameter *root* nil)
(defparameter *authority* nil)
(defparameter *p* nil "The authorized principal's id.")
(defparameter *q* nil "Another registered principal's id, with no rule.")
(defparameter *keyless* nil "A registered principal without keys.")
(defparameter *p-key* nil)
(defparameter *q-key* nil)
(defparameter *attacker-key* nil "A key no principal registers.")
(defparameter *attacker-public* nil)

(defmacro with-authority (() &body body)
  `(let* ((*root* (make-site)) (*next-id* *next-id*))
     (unwind-protect
          (multiple-value-bind (p-key p-public) (make-test-key)
            (multiple-value-bind (q-key q-public) (make-test-key)
              (multiple-value-bind (attacker-key attacker-public) (make-test-key)
                (let* ((*p* (aa:new-principal-id)) (*q* (aa:new-principal-id)) (*keyless* (aa:new-principal-id))
                       (*p-key* p-key) (*q-key* q-key) (*attacker-key* attacker-key) (*attacker-public* attacker-public)
                       (*authority* (aa:make-authoring-authority
                                     :service-id "hyperdoc-authoring-test"
                                     :registry (aa:make-principal-registry
                                                (list (list *p* p-public) (list *q* q-public) (list *keyless*)))
                                     :rules (list (aa:make-authoring-rule *p* "fedwiki-page-edit" "dreyeck.ch" "work-breakdown"))
                                     :sites (list (cons "dreyeck.ch" *root*) (cons "elsewhere.example" *root*)))))
                  ,@body))))
       (uiop:delete-directory-tree *root* :validate t))))

(defun page () (fa:read-local-fedwiki-page *root* "work-breakdown"))
(defun page-bytes () (uiop:read-file-string (fa:local-fedwiki-page-pathname *root* "work-breakdown") :external-format :utf-8))
(defun journal-length () (length (gethash "journal" (page))))
(defun a1 (page) (find-if (lambda (item) (equal "interaction" (gethash "from" item))) (coerce (gethash "story" page) 'list)))

(defun edit-body (item relation)
  (let ((new (alexandria:copy-hash-table item)))
    (setf (gethash "relation" new) relation)
    (utf8 (json (obj "expected" item "action" (obj "type" "edit" "id" (gethash "id" item) "item" new "date" 1790486348600))))))

(defun challenge (&optional (principal *p*) (now 1000000))
  (aa:issue-authoring-challenge (aa:authoring-authority-challenges *authority*) principal :now now :lifetime-ms 60000))

(defun submit (request &key (now 1000100))
  (aa:authenticate-authorize-fedwiki-page-edit *authority* request :now now))

(defun refusal (thunk)
  "The refusal reason THUNK signals, from this layer or the envelope layer, or NIL."
  (handler-case (progn (funcall thunk) nil)
    (aa:authoring-request-refused (c) (aa:authoring-request-refusal-reason c))
    (ae:authoring-envelope-refused (c) (ae:authoring-envelope-refusal-reason c))))

(defmacro refused-without-effect ((reason &optional challenge) &body body)
  "BODY is refused for REASON; the page, its journal and CHALLENGE are as they were."
  `(let ((bytes (page-bytes)) (journal (journal-length)))
     (assert (eq ,reason (refusal (lambda () ,@body))) () "Expected ~S." ,reason)
     (assert (string= bytes (page-bytes)))
     (assert (= journal (journal-length)))
     ,@(when challenge `((assert (not (aa:authoring-challenge-used-p ,challenge)))))))

;;; Tests

(defun test-principals ()
  (with-authority ()
    (let* ((registry (aa:authoring-authority-registry *authority*))
           (principal (aa:find-authoring-principal registry *p*)))
      (assert (eql 0 (search "principal-" *p*)))
      (assert (= 42 (length *p*)))
      (assert (string/= *p* *q*))
      (assert (equal *p* (aa:authoring-principal-id principal)))
      (assert (= 1 (length (aa:authoring-principal-keys principal))))
      (assert (not (member *p* (aa:authoring-principal-keys principal) :test #'string=)))
      (assert (null (aa:authoring-principal-keys (aa:find-authoring-principal registry *keyless*))))
      (assert (null (aa:find-authoring-principal registry (aa:new-principal-id))))
      ;; A registry is trusted configuration, and is checked as such.
      (dolist (entries (list (list (list "principal x" *attacker-public*))
                             (list (list *p* "02zz")) (list (list *p* *attacker-public*) (list *p*))))
        (assert (handler-case (progn (aa:make-principal-registry entries) nil) (error () t)))))))

(defun test-an-authenticated-edit ()
  (with-authority ()
    (let* ((before (page)) (c (challenge))
           (request (signed-request *p-key* :principal *p* :challenge c
                                             :body (edit-body (a1 before) "work:relation/requires"))))
      (multiple-value-bind (edit authenticated) (submit request)
        (let ((after (page)) (capability (pa:page-edit-capability edit)))
          (assert (typep edit 'pa:fedwiki-page-edit))
          (assert (equal *p* (aa:authenticated-principal-id authenticated)))
          (assert (aa:authoring-challenge-used-p c))
          (assert (equal (gethash "id" (a1 before)) (gethash "id" (a1 after))))
          (assert (equal "work:relation/requires" (gethash "relation" (a1 after))))
          (assert (= (1+ (length (gethash "journal" before))) (length (gethash "journal" after))))
          ;; The capability M0 got: the configured root, one page, edit.
          (assert (typep capability 'pa:fedwiki-page-authoring-capability))
          (assert (equal (truename *root*) (pa:capability-site-root capability)))
          (assert (equal '("work-breakdown") (pa:capability-slugs capability)))
          (assert (equal '("edit") (pa:capability-actions capability)))
          ;; Nothing of the request's authentication is stored.
          (let ((stored (page-bytes)))
            (dolist (needle (list *p* (aa:authoring-principal-keys (aa:find-authoring-principal (aa:authoring-authority-registry *authority*) *p*))
                                  (getf request :signature) (aa:authoring-challenge-nonce c)
                                  "hyperdoc-authoring" "fedwiki-page-edit" "expected" "capability" "principal"))
              (dolist (needle (if (listp needle) needle (list needle)))
                (assert (not (search needle stored)) () "The page stores ~S." needle))))
          ;; The authenticated principal is not the FedWiki capability.
          (assert (not (typep authenticated 'pa:fedwiki-page-authoring-capability))))))))

(defun test-a-b-a-replay ()
  (with-authority ()
    (let* ((r1 (signed-request *p-key* :principal *p* :challenge (challenge)
                                        :body (edit-body (a1 (page)) "work:relation/requires"))))
      (submit r1)
      (submit (signed-request *p-key* :principal *p* :challenge (challenge)
                                       :body (edit-body (a1 (page)) "work:relation/informs")))
      ;; The page is back where R1 started; R1 is still refused.
      (refused-without-effect (:used-challenge) (submit r1))
      ;; Control: M0 alone would apply R1's body again.
      (let ((body (shasht:read-json (sb-ext:octets-to-string (getf r1 :body) :external-format :utf-8))))
        (assert (typep (pa:edit-fedwiki-page-item (pa:make-fedwiki-page-authoring-capability *root* '("work-breakdown"))
                                                  "work-breakdown" (gethash "expected" body) (gethash "action" body))
                       'pa:fedwiki-page-edit))))))

(defun test-concurrent-replay ()
  (with-authority ()
    (let* ((c (challenge))
           (request (signed-request *p-key* :principal *p* :challenge c
                                             :body (edit-body (a1 (page)) "work:relation/requires")))
           (journal (journal-length))
           (original (fdefinition 'aa::%consume-challenge))
           (authority *authority*)          ; threads do not see this thread's bindings
           (lock (bt:make-lock)) (arrived 0))
      ;; Both workers reach consumption before either consumes.
      (setf (fdefinition 'aa::%consume-challenge)
            (lambda (&rest arguments)
              (bt:with-lock-held (lock) (incf arrived))
              (loop until (>= arrived 2) do (sleep 0.001))
              (apply original arguments)))
      (let ((results
              (unwind-protect
                   (mapcar #'bt:join-thread
                           (loop repeat 2
                                 collect (bt:make-thread
                                          (lambda () (handler-case (aa:authenticate-authorize-fedwiki-page-edit
                                                                    authority request :now 1000100)
                                                       (aa:authoring-request-refused (c) (aa:authoring-request-refusal-reason c))
                                                       (error (c) c))))))
                (setf (fdefinition 'aa::%consume-challenge) original))))
        (assert (= 2 arrived))
        (assert (= 1 (count-if (lambda (r) (typep r 'pa:fedwiki-page-edit)) results)) () "Results: ~S" results)
        (assert (= 1 (count :used-challenge results)) () "Results: ~S" results)
        (assert (= (1+ journal) (journal-length)))))))

(defun test-challenge-belongs-to-its-principal ()
  (with-authority ()
    (let* ((c (challenge *p*))
           (q-request (signed-request *q-key* :principal *q* :challenge c
                                               :body (edit-body (a1 (page)) "work:relation/requires"))))
      ;; Q authenticates, and still cannot use P's challenge.
      (assert (equal *q* (aa:authenticated-principal-id (aa:authenticate-authoring-request *authority* q-request))))
      (refused-without-effect (:challenge-principal-mismatch c) (submit q-request))
      ;; P can.
      (assert (typep (submit (signed-request *p-key* :principal *p* :challenge c
                                                      :body (edit-body (a1 (page)) "work:relation/requires")))
                     'pa:fedwiki-page-edit)))))

(defun test-authorization-refusals ()
  (with-authority ()
    (let ((c (challenge *p*)) (body (edit-body (a1 (page)) "work:relation/requires")))
      ;; Each target is refused by the rules, the challenge untouched.
      (refused-without-effect (:site-not-authorized c)
        (submit (signed-request *p-key* :principal *p* :challenge c :site "elsewhere.example" :body body)))
      (refused-without-effect (:page-not-authorized c)
        (submit (signed-request *p-key* :principal *p* :challenge c :page "other-page" :body body)))
      (refused-without-effect (:operation-not-authorized c)
        (submit (signed-request *p-key* :principal *p* :challenge c :operation "fedwiki-page-remove" :body body)))
      (refused-without-effect (:malformed-body c)
        (submit (signed-request *p-key* :principal *p* :challenge c :body (utf8 "{\"expected\":{}}"))))
      ;; The same challenge then serves the authorized request.
      (assert (typep (submit (signed-request *p-key* :principal *p* :challenge c :body body)) 'pa:fedwiki-page-edit))
      (assert (aa:authoring-challenge-used-p c)))
    ;; A principal with no rule at all.
    (let ((c (challenge *q*)))
      (refused-without-effect (:no-authoring-rule c)
        (submit (signed-request *q-key* :principal *q* :challenge c :body (edit-body (a1 (page)) "work:relation/requires")))))))

(defun test-time ()
  (with-authority ()
    (let ((c (challenge *p* 1000000)) (body (edit-body (a1 (page)) "work:relation/requires")))
      (refused-without-effect (:expired-challenge c)
        (submit (signed-request *p-key* :principal *p* :challenge c :body body) :now 1060001))
      (refused-without-effect (:challenge-time-mismatch c)
        (submit (signed-request *p-key* :principal *p* :challenge c :issued-at 1000001 :body body)))
      (refused-without-effect (:challenge-time-mismatch c)
        (submit (signed-request *p-key* :principal *p* :challenge c :expires-at 1090000 :body body)))
      ;; At its last millisecond it is current.
      (assert (typep (submit (signed-request *p-key* :principal *p* :challenge c :body body) :now 1060000)
                     'pa:fedwiki-page-edit)))))

(defun test-authentication-refusals ()
  (with-authority ()
    (let* ((c (challenge *p*)) (body (edit-body (a1 (page)) "work:relation/requires"))
           (good (signed-request *p-key* :principal *p* :challenge c :body body)))
      (refused-without-effect (:malformed-envelope c)
        (submit (list :envelope (utf8 "not an envelope") :body body :signature (getf good :signature))))
      (refused-without-effect (:unsupported-version c)
        (submit (signed-request *p-key* :principal *p* :challenge c :version "hyperdoc-authoring-v2" :body body)))
      (refused-without-effect (:unknown-principal c)
        (submit (signed-request *attacker-key* :principal (aa:new-principal-id) :challenge c :body body)))
      (refused-without-effect (:no-verification-key c)
        (submit (signed-request *attacker-key* :principal *keyless* :challenge c :body body)))
      ;; A key the request brings is not a key the server accepts.
      (refused-without-effect (:invalid-signature c)
        (submit (list* :public-key *attacker-public*
                       (signed-request *attacker-key* :principal *p* :challenge c :body body))))
      (refused-without-effect (:invalid-signature c)
        (submit (list :envelope (getf good :envelope) :body body :signature (sign *q-key* (getf good :envelope)))))
      (refused-without-effect (:body-mismatch c)
        (submit (list :envelope (getf good :envelope) :body (utf8 "{}") :signature (getf good :signature))))
      (refused-without-effect (:wrong-service c)
        (submit (signed-request *p-key* :principal *p* :challenge c :service "another-service" :body body)))
      (refused-without-effect (:unknown-challenge c)
        (submit (signed-request *p-key* :principal *p* :challenge c
                                         :nonce (hex (ironclad:random-data 32)) :body body)))
      ;; After every refusal above, the challenge still works.
      (assert (typep (submit good) 'pa:fedwiki-page-edit)))))

(defun test-inspection ()
  (with-authority ()
    (let* ((c (challenge))
           (principal (aa:find-authoring-principal (aa:authoring-authority-registry *authority*) *p*))
           (authenticated (aa:authenticate-authoring-request
                           *authority* (signed-request *p-key* :principal *p* :challenge c
                                                                :body (edit-body (a1 (page)) "work:relation/requires")))))
      (flet ((view-of (object title)
               (let ((view (find title (views:all-views object) :key #'views:view-title :test #'equal)))
                 (assert view)
                 (assert (null (views:view-references view)))
                 (views:view-html view))))
        (let ((html (view-of principal "Authoring principal")))
          (assert (search *p* html))
          (assert (search "Key fingerprint" html))
          (assert (not (search (first (aa:authoring-principal-keys principal)) html))))
        (let ((html (view-of c "Authoring challenge")))
          (assert (search *p* html))
          (assert (search (subseq (aa:authoring-challenge-nonce c) 0 8) html))
          (assert (not (search (aa:authoring-challenge-nonce c) html))))
        (assert (search "Authenticated only" (view-of authenticated "Authenticated principal")))
        (assert (search "work-breakdown" (view-of (aa:make-authoring-rule *p* "fedwiki-page-edit" "dreyeck.ch" "work-breakdown")
                                                  "Authoring rule")))))))

(defun test-boundaries ()
  (let ((direct (mapcar #'asdf:coerce-name
                        (asdf:system-depends-on (asdf:find-system "dreyeck/authenticated-page-authoring")))))
    (dolist (name '("clog" "clack" "hunchentoot" "drakma" "dreyeck/workflow/authoring"))
      (assert (not (member name direct :test #'string-equal)))))
  ;; M0 is reached only through its exported entry point.
  (assert (fboundp 'pa:edit-fedwiki-page-item)))

(defun run-authenticated-page-authoring-tests ()
  (test-principals)
  (test-an-authenticated-edit)
  (test-a-b-a-replay)
  (test-concurrent-replay)
  (test-challenge-belongs-to-its-principal)
  (test-authorization-refusals)
  (test-time)
  (test-authentication-refusals)
  (test-inspection)
  (test-boundaries)
  (format t "~&AUTHENTICATED-PAGE-AUTHORING-PASS: a registered key's signature, a ~
current challenge of the same principal and an authoring rule derive the page ~
capability and M0 applies the edit; replay after A->B->A and a concurrent ~
duplicate are refused as a used challenge; another principal's challenge, ~
a wrong site, page or operation, a bad time, key, signature, body or service ~
leave the challenge unused and the page unchanged; nothing of it is stored.~%")
  t)
