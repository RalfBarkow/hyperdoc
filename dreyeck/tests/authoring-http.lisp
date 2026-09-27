;;;; Signed HyperDoc authoring over HTTP, end to end on a loopback socket.
;;;;
;;;; A real listener on 127.0.0.1 and a real HTTP client. Keys are generated
;;;; in memory for each run and dropped with it; none is stored or printed.
;;;; Every refusal is checked for its status, the reason its observer is told, an unchanged
;;;; page and journal, and, where the authority has not reached the
;;;; challenge, a challenge that still works afterwards.

(defpackage #:dreyeck/authoring-http/tests
  (:use #:cl)
  (:local-nicknames (#:http #:dreyeck/authoring-http)
                    (#:aa #:dreyeck/authenticated-page-authoring)
                    (#:ae #:dreyeck/authoring-envelope)
                    (#:fa #:dreyeck/fedwiki-assets)
                    (#:mat #:dreyeck/fedwiki-page-materialization)
                    (#:work #:dreyeck/work/reading)
                    (#:tm #:dreyeck/topicmap)
                    (#:bt #:bordeaux-threads))
  (:export #:run-authoring-http-tests))

(in-package #:dreyeck/authoring-http/tests)

;;; Signing, as a client would

(defparameter +n+ #xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141)
(defparameter +service+ "hyperdoc-authoring-test")

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

(defun envelope (challenge &key principal (site "dreyeck.ch") (page "work-breakdown") body
                                (operation "fedwiki-page-edit"))
  (utf8 (format nil "hyperdoc-authoring-v1~%service=~A~%principal=~A~%operation=~A~%site=~A~%page=~A~%nonce=~A~%issued-at=~D~%expires-at=~D~%body-keccak256=~A"
                +service+ principal operation site page
                (gethash "nonce" challenge) (gethash "issuedAt" challenge) (gethash "expiresAt" challenge)
                (hex (ae:keccak-256 body)))))

(defun signed (private challenge &rest keys &key body &allow-other-keys)
  "A request as the client sends it: encoded envelope, signature, body."
  (let ((envelope (apply #'envelope challenge keys)))
    (list :envelope (http:base64url-encode envelope) :signature (sign private envelope) :body body)))

;;; A site, principals, an authority, an adapter and a listener

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
               (merge-pathnames (format nil "dreyeck-authoring-http-~A/" (symbol-name (gensym "RUN-")))
                                (uiop:temporary-directory)))))
    (ensure-directories-exist (merge-pathnames "pages/" root))
    (dolist (slug '("work-breakdown" "other-page"))
      (let ((items (work-items)))
        (mat:materialize-fedwiki-page-json
         (obj "title" slug "story" (coerce items 'vector)
              "journal" (vector (obj "type" "create" "id" (next-id)
                                     "item" (obj "title" slug "story" (coerce items 'vector))
                                     "date" 1790000000000)))
         root slug)))
    root))

(defun make-recorder ()
  "A test-owned observer, and a function returning what it was told, newest
first. The adapter tells it from Hunchentoot's worker threads."
  (let ((told nil) (lock (bt:make-lock "authoring http test observer")))
    (values (lambda (method path status reason)
              (bt:with-lock-held (lock)
                (push (list :method method :path path :status status :reason reason) told)))
            (lambda () (bt:with-lock-held (lock) (copy-list told))))))

(defparameter *root* nil)
(defparameter *authority* nil)
(defparameter *adapter* nil)
(defparameter *told* nil "What the adapter under test told its observer.")
(defparameter *port* nil)
(defparameter *p* nil "The authorized principal's id.")
(defparameter *q* nil "Another registered principal's id, with no rule.")
(defparameter *r* nil "A third registered principal, for the issuance bound.")
(defparameter *p-key* nil)
(defparameter *q-key* nil)
(defparameter *keys* nil "Each principal's id and public key.")

(defun fresh-observer ()
  "A new recorder for the adapter under test; *TOLD* reads what it was told."
  (multiple-value-bind (observer told) (make-recorder)
    (setf *told* told)
    observer))

(defun make-authority (keys root)
  (aa:make-authoring-authority
   :service-id +service+
   :registry (aa:make-principal-registry keys)
   :rules (list (aa:make-authoring-rule (first (first keys)) "fedwiki-page-edit" "dreyeck.ch" "work-breakdown"))
   :sites (list (cons "dreyeck.ch" root) (cons "elsewhere.example" root))))

(defmacro with-listener (() &body body)
  `(let* ((*root* (make-site)) (*next-id* *next-id*) (listener nil))
     (unwind-protect
          (multiple-value-bind (p-key p-public) (make-test-key)
            (multiple-value-bind (q-key q-public) (make-test-key)
              (let* ((*p* (aa:new-principal-id)) (*q* (aa:new-principal-id)) (*r* (aa:new-principal-id))
                     (*p-key* p-key) (*q-key* q-key)
                     (*keys* (list (list *p* p-public) (list *q* q-public) (list *r* q-public)))
                     (*authority* (make-authority *keys* *root*))
                     (*adapter* (http:make-authoring-http-adapter *authority* :observer (fresh-observer)))
                     (*port* nil))
                (setf listener (http:start-authoring-http-listener *adapter*)
                      *port* (http:authoring-http-listener-port listener))
                ,@body)))
       (when listener (http:stop-authoring-http-listener listener))
       (uiop:delete-directory-tree *root* :validate t))))

;;; The client side

(defun url (path) (format nil "http://127.0.0.1:~D~A" *port* path))

(defun http (method path &key body headers)
  "Status, body text and response headers, from a real request."
  (multiple-value-bind (content status response-headers)
      (drakma:http-request (url path) :method method :content body
                                      :content-type "application/octet-stream"
                                      :additional-headers headers :force-binary t
                                      :connection-timeout 5)
    (values status (sb-ext:octets-to-string content :external-format :utf-8) response-headers)))

(defun get-challenge (principal)
  (multiple-value-bind (status text) (http :post "/authoring/v1/challenge"
                                           :body (utf8 (json (obj "principal" principal))))
    (assert (= 200 status) () "No challenge for ~A: ~D ~A" principal status text)
    (shasht:read-json text)))

(defun edit-path (&optional (site "dreyeck.ch") (page "work-breakdown"))
  (format nil "/authoring/v1/fedwiki/~A/~A" site page))

(defun put (request &key (path (edit-path)) (method :put) headers)
  (http method path :body (getf request :body)
                    :headers (append (list (cons "HyperDoc-Authoring-Envelope" (getf request :envelope))
                                           (cons "HyperDoc-Authoring-Signature" (getf request :signature)))
                                     headers)))

(defun page () (fa:read-local-fedwiki-page *root* "work-breakdown"))
(defun page-bytes ()
  (uiop:read-file-string (fa:local-fedwiki-page-pathname *root* "work-breakdown") :external-format :utf-8))
(defun a1 (page)
  (find-if (lambda (item) (equal "interaction" (gethash "from" item))) (coerce (gethash "story" page) 'list)))

(defun edit-body (item relation)
  (let ((new (alexandria:copy-hash-table item)))
    (setf (gethash "relation" new) relation)
    (utf8 (json (obj "expected" item "action" (obj "type" "edit" "id" (gethash "id" item)
                                                   "item" new "date" 1790486348600))))))

(defun last-reason () (getf (first (funcall *told*)) :reason))

(defmacro refused ((status reason) &body request)
  "REQUEST answers STATUS, the observer is told REASON, and the page is byte-identical."
  `(let ((before (page-bytes)))
     (let ((status (progn ,@request)))
       (assert (eql ,status status) () "~S answered ~S, not ~S" ',request status ,status)
       (assert (eq ,reason (last-reason)) () "~S told ~S, not ~S" ',request (last-reason) ,reason)
       (assert (string= before (page-bytes)) () "~S changed the page" ',request))))

(defun other-relation ()
  "The relation A1 does not hold now, so an edit to it changes something."
  (if (equal "work:relation/requires" (gethash "relation" (a1 (page))))
      "work:relation/informs"
      "work:relation/requires"))

(defun good-request (&key (relation (other-relation)) (principal *p*) (key *p-key*)
                          (challenge (get-challenge principal)) (site "dreyeck.ch") (page "work-breakdown"))
  (signed key challenge :principal principal :site site :page page
                        :body (edit-body (a1 (page)) relation)))

(defun store-size () (hash-table-count (aa::%store-challenges (aa:authoring-authority-challenges *authority*))))

(defun hunchentoot-threads ()
  (remove-if-not (lambda (thread)
                   (let ((name (bt:thread-name thread)))
                     (and name (or (search "hunchentoot" name :test #'char-equal)
                                   (search "authoring-http" name :test #'char-equal)))))
                 (bt:all-threads)))

;;; Tests

(defun test-transport-encoding ()
  (let ((octets (utf8 "hyperdoc-authoring-v1 and some more octets")))
    (assert (equalp octets (http:base64url-decode (http:base64url-encode octets))))
    (dolist (n '(0 1 2 3 4 5))
      (let ((bytes (subseq octets 0 n)))
        (assert (equalp bytes (http:base64url-decode (http:base64url-encode bytes)))))))
  (let ((encoded (http:base64url-encode (utf8 "ab"))))
    ;; Padding, the standard alphabet and unused bits set are all refused.
    (assert (null (http:base64url-decode (concatenate 'string encoded "="))))
    (assert (null (http:base64url-decode (substitute #\+ #\- "a-b-"))))
    (assert (null (http:base64url-decode "YWJ")))  ; "ab" is YWI; J sets unused bits
    (assert (equalp (utf8 "ab") (http:base64url-decode "YWI")))
    (assert (null (http:base64url-decode "Y")))))

(defun test-no-socket-until-started ()
  ;; Loading the system started nothing, and a non-loopback address is refused
  ;; before anything is made.
  (assert (null (hunchentoot-threads)))
  (let ((adapter (http:make-authoring-http-adapter
                  (aa:make-authoring-authority :service-id +service+
                                               :registry (aa:make-principal-registry nil)))))
    (dolist (address '("0.0.0.0" "::" "192.0.2.1" "localhost"))
      ;; Refused as an address, before any attempt to bind: a failed bind
      ;; would also be an error, and would not show the address was refused.
      (assert (handler-case (progn (http:start-authoring-http-listener adapter :address address)
                                   nil)
                (error (condition) (search "only a loopback address" (princ-to-string condition))))
              () "~A was not refused as a listening address." address))
    (assert (null (hunchentoot-threads)))))

(defun test-challenges ()
  (let ((challenge (get-challenge *p*)))
    (assert (equal *p* (gethash "principal" challenge)))
    (assert (= 64 (length (gethash "nonce" challenge))))
    (assert (< (gethash "issuedAt" challenge) (gethash "expiresAt" challenge))))
  (refused (400 :malformed-transport) (http :post "/authoring/v1/challenge" :body (utf8 "not json")))
  (refused (400 :malformed-transport)
    (http :post "/authoring/v1/challenge" :body (utf8 (json (obj "principal" *p* "extra" 1)))))
  (refused (405 :method) (http :get "/authoring/v1/challenge"))
  ;; An unknown principal is refused and allocates nothing.
  (let ((size (store-size)))
    (dotimes (i 50)
      (refused (401 :unknown-principal)
        (http :post "/authoring/v1/challenge"
              :body (utf8 (json (obj "principal" (aa:new-principal-id)))))))
    (assert (= size (store-size))))
  ;; The authority's bound reaches the wire as 429.
  (dotimes (i 4) (get-challenge *r*))
  (refused (429 :challenge-limit-reached)
    (http :post "/authoring/v1/challenge" :body (utf8 (json (obj "principal" *r*))))))

(defun test-signed-edit-end-to-end ()
  (let* ((before (page))
         (item (a1 before))
         (journal (length (gethash "journal" before))))
    (multiple-value-bind (status text headers) (put (good-request))
      (assert (= 200 status) () "~A" text)
      (let ((answer (shasht:read-json text)))
        (assert (equal "edit" (gethash "applied" answer)))
        (assert (equal (gethash "id" item) (gethash "id" answer))))
      ;; Nothing that could make a session or a cross-origin grant.
      (dolist (header headers)
        (assert (not (member (car header) '(:set-cookie :access-control-allow-origin
                                            :access-control-allow-credentials))))))
    ;; Reread from disk.
    (let* ((after (page))
           (edited (a1 after)))
      (assert (equal (gethash "id" item) (gethash "id" edited)))
      (assert (equal "work:relation/requires" (gethash "relation" edited)))
      (assert (= (length (gethash "story" before)) (length (gethash "story" after))))
      (loop for old across (gethash "story" before) for new across (gethash "story" after)
            unless (equal (gethash "id" old) (gethash "id" item))
              do (assert (equal (json old) (json new))))
      (assert (= (1+ journal) (length (gethash "journal" after))))
      ;; The journal holds the ordinary Action, and nothing about who sent it.
      (let ((entry (aref (gethash "journal" after) journal)))
        (assert (equal '("date" "id" "item" "type")
                       (sort (loop for key being the hash-keys of entry collect key) #'string<)))
        (assert (equal "edit" (gethash "type" entry))))
      (assert (not (search *p* (page-bytes))))
      ;; The Work read side sees the new relation.
      (let* ((projection (work:project-fedwiki-work after :site "dreyeck.ch" :slug "work-breakdown"))
             (association (find-if (lambda (a) (and (equal "interaction" (tm:topicmap-association-from-of a))
                                                    (equal "operations" (tm:topicmap-association-to-of a))))
                                   (tm:topicmap-projection-associations-of projection))))
        (assert (equal "work:relation/requires" (tm:topicmap-association-type-of association)))))
    (assert (eq :applied (last-reason)))))

(defun test-replay ()
  (let ((request (good-request :relation "work:relation/informs")))
    (multiple-value-bind (status text) (put request) (assert (= 200 status) () "~A" text))
    (refused (401 :used-challenge) (put request))
    ;; A -> B -> A: the first request's expected Item is current again, and
    ;; it is still refused.
    (multiple-value-bind (status text) (put (good-request :relation "work:relation/requires"))
      (assert (= 200 status) () "~A" text))
    (let ((expected (gethash "expected" (shasht:read-json
                                         (sb-ext:octets-to-string (getf request :body)
                                                                  :external-format :utf-8))))
          (current (a1 (page))))
      (assert (equal (gethash "id" expected) (gethash "id" current)))
      (assert (equal (gethash "relation" expected) (gethash "relation" current))))
    (refused (401 :used-challenge) (put request))))

(defun test-route-binding-and-tampering ()
  (let* ((good (good-request))
         (encoded (getf good :envelope))
         (signature (getf good :signature)))
    (flet ((raw (envelope signature &key (body (getf good :body)))
             (put (list :envelope envelope :signature signature :body body))))
      (refused (400 :route-mismatch) (put good :path (edit-path "dreyeck.ch" "other-page")))
      (refused (400 :route-mismatch) (put good :path (edit-path "elsewhere.example" "work-breakdown")))
      (refused (405 :method) (put good :method :post))
      (refused (404 :not-found) (put good :path (format nil "~A/extra" (edit-path))))
      (refused (404 :not-found) (put good :path "/authoring/v2/fedwiki/dreyeck.ch/work-breakdown"))
      (refused (404 :not-found) (put good :path "/authoring/v1/fedwiki/dreyeck.ch/work%2Fbreakdown"))
      (refused (401 :body-mismatch)
        (raw encoded signature :body (let ((body (copy-seq (getf good :body))))
                                       (setf (aref body 5) (logxor 1 (aref body 5)))
                                       body)))
      (refused (400 :malformed-transport) (raw (concatenate 'string encoded "=") signature))
      (refused (400 :malformed-transport) (raw (concatenate 'string "+" (subseq encoded 1)) signature))
      (refused (400 :malformed-transport)
        (http :put (edit-path) :body (getf good :body)
                               :headers (list (cons "HyperDoc-Authoring-Signature" signature))))
      (refused (400 :malformed-transport)
        (http :put (edit-path) :body (getf good :body)
                               :headers (list (cons "HyperDoc-Authoring-Envelope" encoded))))
      (let ((altered (copy-seq (http:base64url-decode encoded))))
        ;; One octet of the nonce: still well formed, no longer what was signed.
        (let ((at (+ (search (utf8 "nonce=") altered) 6)))
          (setf (aref altered at) (if (= (aref altered at) 48) 49 48)))
        (refused (401 :invalid-signature) (raw (http:base64url-encode altered) signature)))
      (refused (401 :invalid-signature)
        (raw encoded (format nil "~A~A" (subseq signature 0 127)
                             (if (char= #\0 (char signature 127)) "1" "0"))))
      (refused (401 :malformed-signature) (raw encoded "not-a-signature"))
      ;; No refusal above used the challenge up.
      (multiple-value-bind (status text) (put good) (assert (= 200 status) () "~A" text)))))

(defun test-no-ambient-authority ()
  (let ((ambient (list (cons "Cookie" (format nil "wikiSession=~A; hyperdocSession=owner" *p*))
                       (cons "X-Forwarded-User" *p*) (cons "Remote-User" *p*)
                       (cons "Authorization" "Bearer owner"))))
    ;; Q's key over P's claim, with every ambient credential for P.
    (let ((forged (good-request)))
      (setf (getf forged :signature)
            (sign *q-key* (http:base64url-decode (getf forged :envelope))))
      (refused (401 :invalid-signature) (put forged :headers ambient)))
    ;; Q's own valid request, dressed as P: Q has no rule.
    (refused (403 :no-authoring-rule)
      (put (good-request :principal *q* :key *q-key*) :headers ambient)))
  ;; Authority is the adapter's, not the process's: another adapter with its
  ;; own authority -- the same principals, keys, rule and site -- knows nothing
  ;; of this one's challenge.
  (multiple-value-bind (observer told) (make-recorder)
    (let* ((other (http:make-authoring-http-adapter (make-authority *keys* *root*) :observer observer))
           (listener (http:start-authoring-http-listener other)))
      (unwind-protect
           (let ((request (good-request)) (before (page-bytes)))
             (let ((*port* (http:authoring-http-listener-port listener)))
               (assert (= 401 (put request))))
             (assert (eq :unknown-challenge (getf (first (funcall told)) :reason)))
             (assert (string= before (page-bytes)))
             ;; The request is still good where its challenge was issued.
             (assert (= 200 (put request))))
        (http:stop-authoring-http-listener listener)))))

(defun test-application-refusals ()
  (let* ((stale (alexandria:copy-hash-table (a1 (page)))))
    (setf (gethash "text" stale) "Not what the page holds.")
    (let* ((challenge (get-challenge *p*))
           (request (signed *p-key* challenge :principal *p*
                                              :body (utf8 (json (obj "expected" stale
                                                                     "action" (obj "type" "edit" "id" (gethash "id" stale)
                                                                                   "item" stale "date" 1)))))))
      (refused (409 :stale) (put request))
      ;; M0 refuses after the challenge was used.
      (refused (401 :used-challenge) (put request))))
  (refused (403 :page-not-authorized)
    (put (good-request :page "other-page") :path (edit-path "dreyeck.ch" "other-page"))))

(defun test-bodies-are-bounded-and-drained ()
  (let ((large (make-array 60000 :element-type '(unsigned-byte 8) :initial-element 65))
        (too-large (make-array 70000 :element-type '(unsigned-byte 8) :initial-element 65)))
    ;; A full body on a route that refuses at once still gets its answer.
    (refused (404 :not-found) (http :put "/nowhere" :body large))
    (refused (405 :method) (http :post (edit-path) :body large))
    (refused (404 :not-found) (http :put "/authoring/v1/fedwiki/only-one-segment" :body large))
    ;; Past the limit: 413, answered, nothing applied.
    (let ((good (good-request)))
      (refused (413 :too-large) (put (list* :body too-large good)))
      (multiple-value-bind (status text) (put good) (assert (= 200 status) () "~A" text)))))

(defun test-adapter-keeps-no-history ()
  "The adapter holds its authority and its observer, and nothing a request
could add to; an observer that fails changes no answer."
  (let ((class (find-class 'http:authoring-http-adapter)))
    (sb-mop:finalize-inheritance class)
    (assert (equal '("AUTHORITY" "OBSERVER")
                   (mapcar (lambda (slot) (symbol-name (sb-mop:slot-definition-name slot)))
                           (sb-mop:class-slots class)))))
  (let ((quiet (http:make-authoring-http-adapter *authority*))
        (failing (http:make-authoring-http-adapter
                  *authority* :observer (lambda (&rest told)
                                          (declare (ignore told))
                                          (error "The observer failed.")))))
    (dolist (env (list (list :request-method :get :path-info "/nowhere")
                       (list :request-method :get :path-info "/authoring/v1/challenge")
                       (list :request-method :post :path-info (edit-path))
                       (list :request-method :post :path-info "/authoring/v1/challenge")))
      (setf (getf env :headers) (make-hash-table :test #'equal))
      (assert (equal (http:authoring-http-response quiet env)
                     (http:authoring-http-response failing env))))))

(defun listening-thread-p (port)
  (find-if (lambda (thread)
             (search (format nil "hunchentoot-listener-127.0.0.1:~D" port)
                     (or (bt:thread-name thread) "")))
           (bt:all-threads)))

(defun test-listener-owns-its-bind ()
  "START returns exactly when this adapter's own socket is bound."
  ;; A port another socket already holds: START signals, and no server of
  ;; ours listens there.
  (let* ((foreign (usocket:socket-listen "127.0.0.1" 0 :reuse-address nil))
         (port (usocket:get-local-port foreign)))
    (unwind-protect
         (let ((message (handler-case
                            (progn (http:start-authoring-http-listener
                                    (http:make-authoring-http-adapter *authority*) :port port)
                                   nil)
                          (error (condition) (princ-to-string condition)))))
           (assert (and message (search "could not bind" message)) ()
                   "Port ~D was held by another socket, and START returned." port)
           (assert (not (listening-thread-p port))))
      (usocket:socket-close foreign)))
  ;; Port 0: the listener reports the port it bound, and what answers there
  ;; is this adapter, because its observer is told.
  (multiple-value-bind (observer told) (make-recorder)
    (let* ((own (http:make-authoring-http-adapter *authority* :observer observer))
           (listener (http:start-authoring-http-listener own))
           (port (http:authoring-http-listener-port listener)))
      (unwind-protect
           (let ((*port* port))
             (assert (plusp port))
             (assert (= 404 (http :get "/answered-by-this-adapter")))
             (assert (equal "/answered-by-this-adapter" (getf (first (funcall told)) :path)))
             ;; The same port again is refused, and the first listener keeps it.
             (assert (handler-case (progn (http:start-authoring-http-listener own :port port) nil)
                       (error (condition) (search "could not bind" (princ-to-string condition)))))
             (assert (= 404 (http :get "/still-this-adapter")))
             (assert (equal "/still-this-adapter" (getf (first (funcall told)) :path))))
        (http:stop-authoring-http-listener listener))
      ;; Stopped: nothing accepts there.
      (assert (handler-case (progn (usocket:socket-close
                                    (usocket:socket-connect "127.0.0.1" port :timeout 1))
                                   nil)
                (error () t))))))

(defun run-authoring-http-tests ()
  (test-transport-encoding)
  (test-no-socket-until-started)
  (with-listener ()
    (test-challenges)
    (test-signed-edit-end-to-end)
    (test-replay)
    (test-route-binding-and-tampering)
    (test-no-ambient-authority)
    (test-application-refusals)
    (test-bodies-are-bounded-and-drained)
    (test-adapter-keeps-no-history)
    (test-listener-owns-its-bind))
  ;; Connection threads end with their connections.
  (loop repeat 100 while (hunchentoot-threads) do (sleep 0.05))
  (assert (null (hunchentoot-threads)))
  (format t "~&AUTHORING-HTTP-PASS: strict base64url; no listener until started, and ~
none but loopback; challenges over HTTP, unknown principals allocating nothing and ~
the bound answered 429; a signed PUT applied end to end, reread from disk, one ~
ordinary journal entry, no identity stored, and the Work projection sees it; ~
replay and A->B->A replay refused; route mismatch and every tampering refused ~
with the challenge left usable; cookies and proxy headers carry no authority, ~
and another adapter's authority is not this one's; M0 and rule refusals mapped; ~
bodies bounded and drained; the adapter keeps no history, and a failing ~
observer changes no answer; START returns only on its own bind, refusing a ~
port another socket holds; the listener stopped.~%")
  t)
