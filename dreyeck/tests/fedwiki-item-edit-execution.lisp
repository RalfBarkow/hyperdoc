(defpackage #:dreyeck/fedwiki-item-edit-execution/tests
  (:use #:cl)
  (:local-nicknames (#:x #:dreyeck/fedwiki-item-edit-execution)
                    (#:p #:dreyeck/fedwiki-item-edit-preview)
                    (#:lp #:dreyeck/local-fedwiki-page)
                    (#:pa #:dreyeck/fedwiki-page-authoring)
                    (#:plan #:dreyeck/fedwiki-page-edit-plan)
                    (#:aa #:dreyeck/authenticated-page-authoring)
                    (#:ae #:dreyeck/authoring-envelope)
                    (#:bt #:bordeaux-threads)
                    (#:v #:html-inspector-views))
  (:export #:run-tests))
(in-package #:dreyeck/fedwiki-item-edit-execution/tests)

;; Every page here is a temporary copy of the retained page. Keys are made in memory for each
;; run. A refusal test is paired with the same fixture succeeding, so that a refusal is a
;; difference and not a fixture that never worked.

(defvar *checks* 0)
(defmacro check (form) `(progn (incf *checks*) (assert ,form)))

(defparameter +slug+ "ctm-and-tmdm-in-hyperdoc")
(defparameter +site+ "localhost")
(defparameter +e3-id+ "ed37e9bac2fcd548")
(defparameter +observed-sha256+ "d7215c50f4efa07b3e94749b060b7d7b828654f2a44caab7f1034415c6003dff")
(defparameter +text+ "E3 — execution test text, not a decision.")
(defparameter +n+ #xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141)

(defun evidence-path ()
  (asdf:system-relative-pathname "dreyeck/fedwiki-item-edit-execution" "dreyeck/work/ctm-page-evidence/site/pages/ctm-and-tmdm-in-hyperdoc"))
(defun file-sha (path) (ironclad:byte-array-to-hex-string (ironclad:digest-file :sha256 path)))
(defun page-path (root) (merge-pathnames (format nil "pages/~A" +slug+) root))
(defun json (value) (let ((*print-pretty* nil)) (shasht:write-json value nil)))
(defun hex (octets) (ironclad:byte-array-to-hex-string octets))

(defun call-with-site (function)
  (let ((root (merge-pathnames (format nil "item-edit-execution-~D-~D/" (get-universal-time) (random 1000000)) (uiop:temporary-directory))))
    (ensure-directories-exist (page-path root))
    (unwind-protect (progn (uiop:copy-file (evidence-path) (page-path root)) (funcall function (truename root)))
      (uiop:delete-directory-tree root :validate t :if-does-not-exist :ignore))))

(defun rewrite (root mutate)
  (let ((object (shasht:read-json (uiop:read-file-string (page-path root) :external-format :utf-8))))
    (funcall mutate object)
    (with-open-file (out (page-path root) :direction :output :if-exists :supersede :external-format :utf-8)
      (shasht:write-json object out))))
(defun story-item (object id) (find id (gethash "story" object) :key (lambda (i) (gethash "id" i)) :test #'equal))
(defun page-json (root) (shasht:read-json (uiop:read-file-string (page-path root) :external-format :utf-8)))

;;; Keys and signing, as a client would

(defun make-test-key ()
  (multiple-value-bind (private public) (ironclad:generate-key-pair :secp256k1)
    (let ((point (getf (ironclad:destructure-public-key public) :y)))
      (values private (format nil "~A~A" (if (evenp (aref point 64)) "02" "03") (hex (subseq point 1 33)))))))
(defun sign (private octets)
  (let* ((signature (ironclad:sign-message private (ae:keccak-256 octets)))
         (s (ironclad:octets-to-integer (subseq signature 32))))
    (format nil "~A~(~64,'0X~)" (hex (subseq signature 0 32)) (if (> s (floor +n+ 2)) (- +n+ s) s))))

(defun make-principal (root &key (site +site+) (page +slug+) (site-root root))
  "A principal, its private key and an authority whose one rule lets it edit PAGE of SITE."
  (multiple-value-bind (private public) (make-test-key)
    (let* ((id (aa:new-principal-id))
           (authority (aa:make-authoring-authority
                       :service-id "hyperdoc-authoring-test"
                       :registry (aa:make-principal-registry (list (cons id (list public))))
                       :rules (list (aa:make-authoring-rule id "fedwiki-page-edit" site page))
                       :sites (list (cons +site+ site-root)))))
      (list :authority authority :private private :id id))))

(defun signed-request (principal completion &key (body (x:completion-body completion)) (key (getf principal :private)) (now (x:unix-milliseconds)))
  "A request for COMPLETION: a challenge from the principal's authority, the envelope for BODY, signed with KEY."
  (let* ((authority (getf principal :authority))
         (challenge (aa:issue-authoring-challenge authority (getf principal :id) :now now))
         (envelope (x:completion-envelope-octets completion :service "hyperdoc-authoring-test" :principal (getf principal :id)
                                                            :challenge challenge :site +site+)))
    ;; The envelope names the body of COMPLETION; a request for another BODY carries that body's digest.
    (unless (eq body (x:completion-body completion))
      (setf envelope (sb-ext:string-to-octets
                      (let ((text (map 'string #'code-char envelope)))
                        (concatenate 'string (subseq text 0 (search "body-keccak256=" text)) "body-keccak256=" (hex (ae:keccak-256 body))))
                      :external-format :utf-8)))
    (values (list :envelope envelope :body body :signature (sign key envelope)) challenge)))

;;; A fixture: temporary site, proposal, preview, completion, principal

(defun make-fixture (root &key (text +text+) (date (x:unix-milliseconds)))
  (let* ((source (lp:observe-local-fedwiki-page-source root +slug+))
         (item (find +e3-id+ (lp:source-story-items source) :key #'lp:story-item-id :test #'equal))
         (proposal (p:propose-item-edit item text))
         (preview (p:preview-item-edit proposal))
         (completion (x:complete-item-edit preview :now date)))
    (list :source source :proposal proposal :preview preview :completion completion :principal (make-principal root))))
(defun fx (fixture key) (getf fixture key))

(defun view (object title)
  (let ((view (or (find title (v:all-views object) :key #'v:view-title :test #'equal) (error "Missing ~A view of ~S" title object))))
    (v:view-html view)
    (check (notany (lambda (ref) (typep (cdr ref) 'condition)) (v:view-references view)))
    view))
(defun refs (object title) (mapcar #'cdr (v:view-references (view object title))))
(defun html (object title) (v:view-html (view object title)))
(defun all-views-of (object)
  (dolist (view (remove-if-not (lambda (view) (typep view 'v::html-view)) (v:all-views object))) (v:view-html view)))

(defun unchanged-p (root before)
  "The page file is byte for byte what it was."
  (equal before (file-sha (page-path root))))
(defun refused-with (reason thunk)
  (let ((condition (handler-case (progn (funcall thunk) nil) (error (c) c))))
    (check condition)
    (check (cond ((typep condition 'x:execution-refused) (eq reason (x:execution-refusal-reason condition)))
                 ((typep condition 'aa:authoring-request-refused) (eq reason (aa:authoring-request-refusal-reason condition)))
                 ((typep condition 'ae:authoring-envelope-refused) (eq reason (ae:authoring-envelope-refusal-reason condition)))
                 ((typep condition 'pa:fedwiki-page-edit-refused) (eq reason (pa:page-edit-refusal-reason condition)))
                 (t nil)))
    condition))

(defun system-closure (name)
  (let ((seen nil))
    (labels ((visit (designator)
               (let ((system (and (or (stringp designator) (symbolp designator)) (asdf:find-system designator nil))))
                 (when (and system (not (member (asdf:component-name system) seen :test #'string=)))
                   (push (asdf:component-name system) seen)
                   (mapc #'visit (asdf:system-depends-on system))))))
      (visit name))
    seen))

;;; The tests

(defun check-full-path (root)
  "Previewed, completed, authorized, executed, persisted, verified, each with its evidence."
  (let* ((before (file-sha (page-path root))) (before-json (page-json root))
         (fixture (make-fixture root)) (preview (fx fixture :preview)) (completion (fx fixture :completion))
         (principal (fx fixture :principal)) (action (p:preview-action preview))
         (snapshot (json action)))
    (check (equal +observed-sha256+ before))
    (check (= 18 (length (gethash "story" before-json))))
    (check (= 2 (length (gethash "journal" before-json))))
    ;; The proposal and the preview exist without any authority: the Execution view says so and offers only a copy.
    (let ((text (html preview "Execution")))
      (check (search "It is not authorized, executed or persisted" text))
      (check (search "it is not an authorization" text)))
    ;; Completed: a copy with one more field. The previewed Action is untouched.
    (check (not (eq action (x:completion-action completion))))
    (check (equal snapshot (json action)))
    (check (null (nth-value 1 (gethash "date" action))))
    (check (integerp (x:completion-date completion)))
    (check (eql (x:completion-date completion) (gethash "date" (x:completion-action completion))))
    (check (equal '("type" "id" "item" "date") (loop for key being the hash-keys of (x:completion-action completion) collect key)))
    (check (plan::%json-equal (let ((copy (plan::%copy-json (x:completion-action completion)))) (remhash "date" copy) copy) action))
    (check (search "Everything else equals the proposed Action: checked, equal." (html completion "Completed Action")))
    ;; Nothing in the views makes a capability: none until the signed request is executed.
    (let ((made 0))
      (sb-int:encapsulate 'pa:make-fedwiki-page-authoring-capability 'count-test
                          (lambda (function &rest arguments) (incf made) (apply function arguments)))
      (unwind-protect
           (progn
             (dolist (part (list preview completion (p:preview-proposal preview) (fx fixture :source))) (all-views-of part))
             (check (zerop made))
             ;; Authorized and executed, by the existing writer, with the capability the authenticated path derives.
             (multiple-value-bind (request challenge) (signed-request principal completion)
               (check (eq :unused (if (aa:authoring-challenge-used-p challenge) :used :unused)))
               (let ((execution (x:execute-completed-edit (getf principal :authority) completion request)))
                 (check (= 1 made))
                 (check (aa:authoring-challenge-used-p challenge))
                 (check (typep (x:execution-edit execution) 'pa:fedwiki-page-edit))
                 (full-path-checks root before before-json fixture execution)
                 (dolist (part (list execution (x:execution-edit execution) (x:execution-authenticated execution)
                                     (x:execution-persisted-source execution) (x:execution-journal-entry execution)))
                   (all-views-of part))
                 (check (= 1 made)))))
        (sb-int:unencapsulate 'pa:make-fedwiki-page-authoring-capability 'count-test)))))

(defun full-path-checks (root before before-json fixture execution)
  (let* ((completion (fx fixture :completion)) (preview (fx fixture :preview)) (facts (x:execution-facts execution))
         (after-json (page-json root)) (edit (x:execution-edit execution)))
    ;; Persisted: the file changed, in exactly one Item and one journal entry.
    (check (not (unchanged-p root before)))
    (check (= 18 (length (gethash "story" after-json))))
    (check (= 3 (length (gethash "journal" after-json))))
    (check (equal (list +e3-id+) (getf facts :changed-ids)))
    (check (= 17 (loop for old across (gethash "story" before-json) for new across (gethash "story" after-json)
                       count (plan::%json-equal old new))))
    (check (plan::%json-equal (gethash "item" (x:completion-action completion)) (story-item after-json +e3-id+)))
    (let ((entry (aref (gethash "journal" after-json) 2)))
      (check (plan::%json-equal entry (x:completion-action completion)))
      (check (equal "edit" (gethash "type" entry)))
      (check (equal +e3-id+ (gethash "id" entry)))
      (check (eql (x:completion-date completion) (gethash "date" entry)))
      (check (null (nth-value 1 (gethash "date" (p:preview-action preview))))))
    (check (plan::%json-equal (aref (gethash "journal" before-json) 0) (aref (gethash "journal" after-json) 0)))
    (check (plan::%json-equal (aref (gethash "journal" before-json) 1) (aref (gethash "journal" after-json) 1)))
    ;; The writer's record: the Action appended is the completed one, the previous Item the observed one.
    (check (plan::%json-equal (pa:page-edit-action edit) (x:completion-action completion)))
    (check (plan::%json-equal (pa:page-edit-previous-item edit) (p:preview-expected-item preview)))
    ;; Each step with its evidence; verified only after a new process says so.
    (let ((states (x:execution-states execution)))
      (check (equal '(:proposed :previewed :authorized :executed :persisted :verified) (mapcar #'first states)))
      (check (eq (p:preview-proposal preview) (second (assoc :proposed states))))
      (check (eq preview (second (assoc :previewed states))))
      (check (eq (x:execution-authenticated execution) (second (assoc :authorized states))))
      (check (eq edit (second (assoc :executed states))))
      (check (eq (x:execution-persisted-source execution) (second (assoc :persisted states))))
      (check (null (second (assoc :verified states)))))
    (let ((text (html execution "Execution")))
      (check (search "Verified" text))
      (check (search "not yet. A new process has not read the file." text))
      (check (not (search "Verified in a new process" text))))
    ;; The links go to the objects themselves.
    (let ((table (refs execution "Execution")))
      (dolist (object (list (x:execution-persisted-source execution) (x:execution-journal-entry execution) edit
                            (pa:page-edit-previous-item edit) (x:completion-action completion) completion
                            (x:execution-authenticated execution) (p:preview-action preview) (fdefinition 'pa:edit-fedwiki-page-item)
                            (lp:page-source-json (x:execution-persisted-source execution))))
        (check (member object table :test #'eq)))
      (check (eq (x:execution-journal-entry execution)
                 (aref (gethash "journal" (lp:page-source-json (x:execution-persisted-source execution))) 2))))
    (let ((table (refs edit "Executed edit")))
      (check (member (pa:page-edit-action edit) table :test #'eq))
      (check (member (pa:page-edit-previous-item edit) table :test #'eq))
      (check (find-if (lambda (o) (typep o 'lp:local-fedwiki-page-source)) table))
      (check (find-if (lambda (o) (and (hash-table-p o) (plan::%json-equal o (x:completion-action completion)))) table)))
    ;; Verified, by a new process; and the verifier does notice a file that is not the edit.
    (let ((verification (x:verify-persisted-edit execution)))
      (check (x:verification-verified-p verification))
      (check (eq verification (x:execution-verification execution)))
      (check (equal (file-sha (page-path root)) (getf (x:verification-facts verification) :sha256)))
      (check (equal (list +e3-id+) (getf (x:verification-facts verification) :changed-ids)))
      (check (eq verification (second (assoc :verified (x:execution-states execution)))))
      (check (search "Verified in a new process" (html verification "Verification")))
      (check (member verification (refs execution "Execution") :test #'eq)))
    (rewrite root (lambda (object) (setf (gethash "text" (story-item object "fa6304a65d40144c")) "tampered")))
    (let ((tampered (x:verify-persisted-edit execution)))
      (check (not (x:verification-verified-p tampered)))
      (check (null (second (assoc :verified (x:execution-states execution))))))))

(defun check-refusals ()
  ;; Each refusal changes nothing and leaves the single-use challenge usable; the same fixture without the defect executes.
  (flet ((attempt (defect expected)
           (call-with-site
            (lambda (root)
              (let* ((fixture (make-fixture root)) (principal (fx fixture :principal)) (completion (fx fixture :completion))
                     (before (file-sha (page-path root))) (challenge nil) (request nil))
                (multiple-value-setq (request challenge) (signed-request principal completion))
                (funcall defect root fixture)
                (let ((after-defect (file-sha (page-path root))))
                  (check (not (equal before after-defect)))
                  (refused-with expected (lambda () (x:execute-completed-edit (getf principal :authority) completion request)))
                  (check (unchanged-p root after-defect)))
                (check (not (aa:authoring-challenge-used-p challenge)))
                (check (= 2 (length (gethash "journal" (page-json root))))))))))
    ;; Positive control: the fixture as it is executes.
    (call-with-site
     (lambda (root)
       (let* ((fixture (make-fixture root)) (principal (fx fixture :principal)))
         (check (typep (x:execute-completed-edit (getf principal :authority) (fx fixture :completion)
                                                 (signed-request principal (fx fixture :completion)))
                       'x:item-edit-execution)))))
    ;; The page changed elsewhere after the preview: another Item, E3 itself.
    (attempt (lambda (root fixture) (declare (ignore fixture))
               (rewrite root (lambda (o) (setf (gethash "text" (story-item o "fa6304a65d40144c")) "E2 changed elsewhere."))))
             :stale-revision)
    (attempt (lambda (root fixture) (declare (ignore fixture))
               (rewrite root (lambda (o) (setf (gethash "text" (story-item o +e3-id+)) "E3 changed by someone else."))))
             :stale-revision)
    ;; The body that was signed is not the completion's body.
    (call-with-site
     (lambda (root)
       (let* ((fixture (make-fixture root)) (principal (fx fixture :principal)) (completion (fx fixture :completion))
              (other (x:complete-item-edit (fx fixture :preview) :now (1+ (x:completion-date completion))))
              (before (file-sha (page-path root))))
         (refused-with :body-differs
                       (lambda () (x:execute-completed-edit (getf principal :authority) completion
                                                            (signed-request principal other))))
         (check (unchanged-p root before))
         ;; The undated, previewed Action can never be what is executed.
         (let ((undated (let ((body (make-hash-table :test #'equal)))
                          (setf (gethash "expected" body) (p:preview-expected-item (fx fixture :preview))
                                (gethash "action" body) (p:preview-action (fx fixture :preview)))
                          (sb-ext:string-to-octets (json body) :external-format :utf-8))))
           (refused-with :body-differs
                         (lambda () (x:execute-completed-edit (getf principal :authority) completion
                                                              (signed-request principal completion :body undated)))))
         (check (unchanged-p root before)))))
    ;; The site id means another directory than the one the preview read.
    (call-with-site
     (lambda (root)
       (call-with-site
        (lambda (elsewhere)
          (let* ((fixture (make-fixture root)) (principal (make-principal root :site-root elsewhere))
                 (completion (fx fixture :completion)) (before (file-sha (page-path root))))
            (refused-with :site-root-differs
                          (lambda () (x:execute-completed-edit (getf principal :authority) completion (signed-request principal completion))))
            (check (unchanged-p root before)))))))
    ;; Authorization: an unknown principal, a rule for another page, a signature of another key. Each refused before the writer.
    (call-with-site
     (lambda (root)
       (let* ((fixture (make-fixture root)) (completion (fx fixture :completion)) (before (file-sha (page-path root)))
              (stranger (make-principal root)) (elsewhere (make-principal root :page "another-page"))
              (principal (fx fixture :principal)) (authority (getf principal :authority)))
         (multiple-value-bind (private) (make-test-key)
           ;; A request signed by a stranger, judged by an authority that does not know it.
           (refused-with :unknown-principal
                         (lambda () (x:execute-completed-edit authority completion
                                                              (multiple-value-bind (request) (signed-request stranger completion)
                                                                request))))
           (refused-with :page-not-authorized
                         (lambda () (x:execute-completed-edit (getf elsewhere :authority) completion (signed-request elsewhere completion))))
           (refused-with :invalid-signature
                         (lambda () (x:execute-completed-edit authority completion (signed-request principal completion :key private)))))
         (check (unchanged-p root before))
         ;; Positive control: the right principal executes.
         (check (typep (x:execute-completed-edit authority completion (signed-request principal completion)) 'x:item-edit-execution)))))
    ;; The writer itself refuses without a capability or outside it, and applies inside it.
    (call-with-site
     (lambda (root)
       (let* ((fixture (make-fixture root)) (preview (fx fixture :preview)) (before (file-sha (page-path root)))
              (action (x:completion-action (fx fixture :completion))))
         (refused-with :no-capability (lambda () (pa:edit-fedwiki-page-item nil +slug+ (p:preview-expected-item preview) action)))
         (refused-with :outside-capability
                       (lambda () (pa:edit-fedwiki-page-item (pa:make-fedwiki-page-authoring-capability root (list "another-page"))
                                                             +slug+ (p:preview-expected-item preview) action)))
         (check (unchanged-p root before))
         (check (typep (pa:edit-fedwiki-page-item (pa:make-fedwiki-page-authoring-capability root (list +slug+))
                                                  +slug+ (p:preview-expected-item preview) action)
                       'pa:fedwiki-page-edit)))))
    ;; An unchanged proposal has no Action to complete; a changed one has.
    (call-with-site
     (lambda (root)
       (let* ((source (lp:observe-local-fedwiki-page-source root +slug+))
              (item (find +e3-id+ (lp:source-story-items source) :key #'lp:story-item-id :test #'equal))
              (unchanged (p:interactive-preview (p:propose-item-edit item)))
              (changed (p:interactive-preview (p:propose-item-edit item +text+))))
         (check (typep unchanged 'p:unchanged-edit-preview))
         (refused-with :not-a-preview (lambda () (x:complete-item-edit unchanged)))
         (check (typep (x:complete-item-edit changed) 'x:item-edit-completion)))))))

(defun check-concurrency ()
  "Two requests for one completion, released together: exactly one edit is persisted."
  (call-with-site
   (lambda (root)
     (let* ((fixture (make-fixture root)) (principal (fx fixture :principal)) (completion (fx fixture :completion))
            (authority (getf principal :authority))
            (requests (list (signed-request principal completion) (signed-request principal completion)))
            (gate (bt:make-semaphore)) (results nil) (lock (bt:make-lock)))
       (let ((threads (loop for request in requests
                            collect (let ((request request))
                                      (bt:make-thread (lambda ()
                                                        (bt:wait-on-semaphore gate)
                                                        (let ((result (handler-case (x:execute-completed-edit authority completion request)
                                                                        (error (c) c))))
                                                          (bt:with-lock-held (lock) (push result results)))))))))
         (bt:signal-semaphore gate :count 2)
         (mapc #'bt:join-thread threads))
       (check (= 1 (count-if (lambda (r) (typep r 'x:item-edit-execution)) results)))
       (check (= 1 (count-if (lambda (r) (typep r 'error)) results)))
       (check (= 3 (length (gethash "journal" (page-json root)))))
       (check (equal +e3-id+ (gethash "id" (aref (gethash "journal" (page-json root)) 2))))))))

(defun check-interactive ()
  "The Execute button of an attached request, and the refusal it yields."
  (call-with-site
   (lambda (root)
     (let* ((fixture (make-fixture root)) (principal (fx fixture :principal)) (completion (fx fixture :completion))
            (before (file-sha (page-path root))))
       (check (not (search "Execute the attached signed request" (html completion "Completed Action"))))
       (check (search "To authorize:" (html completion "Completed Action")))
       (let ((request (signed-request principal completion)))
         (x:attach-signed-request completion (getf principal :authority) request))
       (check (search "Execute the attached signed request" (html completion "Completed Action")))
       (check (unchanged-p root before))
       ;; The page moves before the button is pressed: a refusal object, nothing written, the challenge not used.
       (rewrite root (lambda (o) (setf (gethash "text" (story-item o "fa6304a65d40144c")) "E2 moved.")))
       (let* ((moved (file-sha (page-path root)))
              (button (find-if (lambda (o) (typep o 'v:thunk)) (refs completion "Completed Action")))
              (result (v:eval-thunk button)))
         (check (typep result 'x:execution-refusal))
         (check (eq :unused (x:refusal-challenge-used-p result)))
         (check (typep (x:refusal-condition result) 'x:execution-refused))
         (check (eq :stale-revision (x:execution-refusal-reason (x:refusal-condition result))))
         (let ((refusal-view (find "Refusal" (v:all-views result) :key #'v:view-title :test #'equal)))
           ;; The view offers the condition as a link, on purpose, so that it can be inspected.
           (check (search "No page byte was written" (v:view-html refusal-view)))
           (check (member (x:refusal-condition result) (mapcar #'cdr (v:view-references refusal-view)) :test #'eq)))
         (check (unchanged-p root moved))))))
  ;; And on a page that has not moved, the same button executes.
  (call-with-site
   (lambda (root)
     (let* ((fixture (make-fixture root)) (principal (fx fixture :principal)) (completion (fx fixture :completion)))
       (x:attach-signed-request completion (getf principal :authority) (signed-request principal completion))
       (let* ((button (find-if (lambda (o) (typep o 'v:thunk)) (refs completion "Completed Action")))
              (result (v:eval-thunk button)))
         (check (typep result 'x:item-edit-execution))
         (check (= 3 (length (gethash "journal" (page-json root)))))
         (let ((verify (find-if (lambda (o) (typep o 'v:thunk)) (refs result "Execution"))))
           (check verify)
           (check (x:verification-verified-p (v:eval-thunk verify)))))))))

;;; Concurrent and unexpected outcomes. A write by another process between the revision check and the
;;; writer's own read is simulated by a thunk run just before the writer; the real Node server could do the
;;; same. The outcomes are read from the file, never from which condition was signalled.

(defun call-with-writer-wrapped (wrapper function)
  "Run FUNCTION with EDIT-FEDWIKI-PAGE-ITEM replaced by (funcall WRAPPER original arguments)."
  (sb-int:encapsulate 'pa:edit-fedwiki-page-item 'wrapped (lambda (original &rest arguments) (funcall wrapper original arguments)))
  (unwind-protect (funcall function)
    (sb-int:unencapsulate 'pa:edit-fedwiki-page-item 'wrapped)))

(defun call-with-concurrent-writer (concurrent function)
  (call-with-writer-wrapped (lambda (original arguments) (funcall concurrent) (apply original arguments)) function))

(defun execute-with (fixture &key (request nil))
  "Execute the fixture's completion; the result or the condition."
  (let* ((principal (fx fixture :principal)) (completion (fx fixture :completion))
         (request (or request (signed-request principal completion))))
    (handler-case (x:execute-completed-edit (getf principal :authority) completion request)
      (error (c) c))))

(defun raw-view (object title)
  "A view that links a condition on purpose, so the helper that refuses condition links is not used."
  (let ((view (find title (v:all-views object) :key #'v:view-title :test #'equal)))
    (v:view-html view) view))
(defun raw-refs (object title) (mapcar #'cdr (v:view-references (raw-view object title))))
(defun raw-html (object title) (v:view-html (raw-view object title)))

(defun html-of-views (object titles)
  (let ((view (find-if (lambda (view) (member (v:view-title view) titles :test #'equal)) (v:all-views object))))
    (v:view-html view)))

(defun check-differing-outcome ()
  ;; (1) Another Item changes after the revision check: the writer, which compares only the Item, applies the
  ;; edit on top of the newer page. The completed Action is in the file: an execution comes back, :DIFFERS,
  ;; with the deviation, the real journal and the real challenge state; it is not shown as verified.
  (call-with-site
   (lambda (root)
     (let* ((fixture (make-fixture root)) (completion (fx fixture :completion)) (result nil))
       (call-with-concurrent-writer
        (lambda () (rewrite root (lambda (o) (setf (gethash "text" (story-item o "fa6304a65d40144c")) "E2 changed meanwhile."))))
        (lambda () (setf result (execute-with fixture))))
       (let ((after (page-json root)))
         (check (typep result 'x:item-edit-execution))
         (check (eq :differs (x:execution-expectation result)))
         (check (equal '("fa6304a65d40144c") (getf (x:execution-deviations result) :other-changed-items)))
         (check (null (x:execution-condition result)))
         (check (eq :used (getf (x:execution-observed result) :challenge-state)))
         (check (not (equal (getf (x:execution-observed result) :before-sha) (getf (x:execution-observed result) :after-sha))))
         ;; The file: the edit and the other change.
         (check (= 3 (length (gethash "journal" after))))
         (check (equal "E2 changed meanwhile." (gethash "text" (story-item after "fa6304a65d40144c"))))
         (check (plan::%json-equal (gethash "item" (x:completion-action completion)) (story-item after +e3-id+)))
         (check (plan::%json-equal (x:execution-journal-entry result) (aref (gethash "journal" after) 2)))
         (check (equal '("fa6304a65d40144c" "ed37e9bac2fcd548") (getf (x:execution-facts result) :changed-ids)))
         ;; Not a success, not verified: in the states and in the views, before and after a new process looked.
         (check (null (second (assoc :verified (x:execution-states result)))))
         (let ((text (html result "Execution")))
           (check (search "File differs from the preview." text))
           (check (not (search "File as previewed." text)))
           (check (search "The run ended without a condition." text))
           (check (eq :writer-returned (getf (x:execution-observed result) :attribution)))
           (check (search "other-changed-items" text))
           (check (search "not yet. A new process has not read the file." text)))
         (let ((verification (x:verify-persisted-edit result)))
           (check (not (x:verification-verified-p verification)))
           (check (null (second (assoc :verified (x:execution-states result)))))
           (let ((text (html result "Execution")))
             (check (not (search "Verified in a new process" text)))
             (check (search "not as previewed" text)))))))))

(defun check-writer-condition-after-replacement ()
  ;; (2) The writer replaces the page and then signals (its own :VERIFICATION refusal, simulated): the condition is
  ;; kept, the execution is found in the file, and it is neither "not executed" nor a verified success.
  (call-with-site
   (lambda (root)
     (let* ((fixture (make-fixture root)) (simulated nil) (result nil))
       (call-with-writer-wrapped
        (lambda (original arguments)
          (apply original arguments)
          (setf simulated (make-condition 'pa:fedwiki-page-edit-refused :reason :verification :detail "simulated, after the replacement"))
          (error simulated))
        (lambda () (setf result (execute-with fixture))))
       (let ((after (page-json root)))
         (check (typep result 'x:item-edit-execution))
         ;; The file is as previewed; the condition is a separate fact and does not change that.
         (check (eq :as-previewed (x:execution-expectation result)))
         (check (null (x:execution-deviations result)))
         (check (eq simulated (x:execution-condition result)))
         (check (not (getf (x:execution-observed result) :without-condition)))
         (check (eq :writer-verification (getf (x:execution-observed result) :attribution)))
         (check (null (x:execution-edit result)))
         (check (typep (x:execution-authenticated result) 'aa::authenticated-principal))
         (check (= 3 (length (gethash "journal" after))))
         (check (plan::%json-equal (aref (gethash "journal" after) 2) (x:completion-action (fx fixture :completion))))
         (check (eq :used (getf (x:execution-observed result) :challenge-state)))
         (check (typep (second (assoc :executed (x:execution-states result))) 'hash-table))
         ;; The condition is an inspectable object, linked from the view.
         (check (member simulated (raw-refs result "Execution") :test #'eq))
         (let ((text (raw-html result "Execution")))
           (check (search "File as previewed." text))
           (check (not (search "File differs from the preview." text)))
           (check (search "The run did not end cleanly." text)))
         ;; A new process confirms the file; that is the file only, and the view still states the condition.
         (check (x:verification-verified-p (x:verify-persisted-edit result)))
         (check (second (assoc :verified (x:execution-states result))))
         (let ((text (raw-html result "Execution")))
           (check (search "The run did not end cleanly." text))
           (check (member simulated (raw-refs result "Execution") :test #'eq)))))))
  ;; Positive control: without the simulated condition the same fixture is as previewed.
  (call-with-site
   (lambda (root)
     (let ((result (execute-with (make-fixture root))))
       (check (typep result 'x:item-edit-execution))
       (check (eq :as-previewed (x:execution-expectation result)))
       (check (null (x:execution-condition result)))
       (check (getf (x:execution-observed result) :without-condition))
       (check (eq :writer-returned (getf (x:execution-observed result) :attribution)))
       (check (x:verification-verified-p (x:verify-persisted-edit result)))
       (check (second (assoc :verified (x:execution-states result))))
       (let ((text (html result "Execution")))
         (check (search "File as previewed." text))
         (check (search "The run ended without a condition." text))
         (check (not (search "did not end cleanly" text))))))))

(defun foreign-write (root completion)
  "What another process would leave: the completed Action's replacement Item in place and the Action appended."
  (let ((action (x:completion-action completion)))
    (rewrite root (lambda (o)
                    (let ((story (gethash "story" o)))
                      (setf (aref story (position +e3-id+ story :key (lambda (i) (gethash "id" i)) :test #'equal))
                            (gethash "item" action)))
                    (setf (gethash "journal" o) (concatenate 'vector (gethash "journal" o) (vector action)))))))

(defun check-foreign-write ()
  ;; The expected Action is in the file, but the file alone does not say who wrote it. (a) Our call fails with an
  ;; unclassified error after consuming the challenge, having let another process write: the Action is observed and the
  ;; origin is undetermined; not shown as executed by this call. (b) The failure comes before the challenge is consumed:
  ;; then this call's writer cannot have run, and that is stated. Control: the writer's own return is attributed.
  (flet ((run (attribution challenge wrap)
           (call-with-site
            (lambda (root)
              (let* ((fixture (make-fixture root)) (completion (fx fixture :completion)) (result nil))
                (funcall wrap root completion
                         (lambda () (setf result (execute-with fixture))))
                (check (typep result 'x:item-edit-execution))
                (let ((observed (x:execution-observed result)))
                  (check (eq attribution (getf observed :attribution)))
                  (check (eq challenge (getf observed :challenge-state)))
                  (check (typep (x:execution-condition result) 'simple-error))
                  (check (not (getf observed :without-condition))))
                ;; The Action is persisted and as previewed; the write is not ascribed to this call.
                (check (eq :as-previewed (x:execution-expectation result)))
                (check (second (assoc :persisted (x:execution-states result))))
                (check (null (second (assoc :executed (x:execution-states result)))))
                (check (null (x:execution-edit result)))
                (let ((text (raw-html result "Execution")))
                  (check (search "File as previewed." text))
                  (check (search "The run did not end cleanly." text))
                  (check (search "Origin of the write: " text))
                  (check (search (ecase attribution (:undetermined "not determinable") (:not-this-call "not this call")) text))
                  (check (search "Executed</strong>: not shown. Only that the Action is persisted was observed." text))
                  (check (search "Edit Action observed in the persisted page" text))
                  (check (not (search "Executed edit of" text)))))))))
    (run :undetermined :used
         (lambda (root completion function)
           (call-with-writer-wrapped
            (lambda (original arguments) (declare (ignore original arguments))
              (foreign-write root completion) (error "simulated failure of an unknown kind"))
            function)))
    (run :not-this-call :unused
         (lambda (root completion function)
           (sb-int:encapsulate 'aa:authenticate-authorize-fedwiki-page-edit 'foreign
                               (lambda (original &rest arguments) (declare (ignore original arguments))
                                 (foreign-write root completion) (error "simulated failure of an unknown kind")))
           (unwind-protect (funcall function)
             (sb-int:unencapsulate 'aa:authenticate-authorize-fedwiki-page-edit 'foreign))))))

(defun check-refused-before-the-writer ()
  ;; (3) E3 changes before the writer: the writer refuses (:STALE, before it writes). That is provable, so the claim
  ;; holds; the challenge is used up, the file is the other party's, and nothing is called persisted.
  (call-with-site
   (lambda (root)
     (let* ((fixture (make-fixture root)) (principal (fx fixture :principal)) (completion (fx fixture :completion)) (result nil))
       (x:attach-signed-request completion (getf principal :authority) (signed-request principal completion))
       (call-with-concurrent-writer
        (lambda () (rewrite root (lambda (o) (setf (gethash "text" (story-item o +e3-id+)) "E3 changed meanwhile."))))
        (lambda () (setf result (x:interactive-execute completion))))
       (let ((after (page-json root)) (refusal-view (find "Refusal" (v:all-views result) :key #'v:view-title :test #'equal)))
         (check (typep result 'x:execution-refusal))
         (check (eq :not-written (x:refusal-outcome result)))
         (check (eq :used (x:refusal-challenge-used-p result)))
         (check (typep (x:refusal-condition result) 'pa:fedwiki-page-edit-refused))
         (check (eq :stale (pa:page-edit-refusal-reason (x:refusal-condition result))))
         (check (getf (x:refusal-observation result) :file-changed))
         (check (= 2 (length (gethash "journal" after))))
         (check (equal "E3 changed meanwhile." (gethash "text" (story-item after +e3-id+))))
         (check (search "No page byte was written" (v:view-html refusal-view)))
         (check (search "a used challenge is not a persisted Action" (v:view-html refusal-view))))))))

(defun check-unclear-outcomes ()
  ;; (4) An error nobody classified, and a file with no completed Action in it: nothing is claimed either way. The
  ;; file may be changed by someone else, or unchanged: neither shows whether this execution wrote.
  (dolist (disturbance (list (lambda (root) (rewrite root (lambda (o) (setf (gethash "text" (story-item o "fa6304a65d40144c")) "someone else"))))
                             (lambda (root) (declare (ignore root)) nil)))
    (flet ((failing-writer (root)
             (lambda (original arguments) (declare (ignore original arguments))
               (funcall disturbance root) (error "simulated failure of an unknown kind"))))
      ;; Called directly: the condition, with the observation.
      (call-with-site
       (lambda (root)
         (let* ((fixture (make-fixture root)) (before (file-sha (page-path root))) (condition nil))
           (call-with-writer-wrapped (failing-writer root) (lambda () (setf condition (execute-with fixture))))
           (check (typep condition 'x:execution-unclear))
           (check (null (getf (x:execution-unclear-observation condition) :edit-present)))
           (check (eq :used (getf (x:execution-unclear-observation condition) :challenge-state)))
           (check (typep (x:execution-unclear-cause condition) 'simple-error))
           (check (eq (not (equal before (file-sha (page-path root)))) (and (getf (x:execution-unclear-observation condition) :file-changed) t)))
           (check (= 2 (length (gethash "journal" (page-json root))))))))
      ;; Through the button: an outcome :UNCLEAR whose view claims nothing about writing.
      (call-with-site
       (lambda (root)
         (let* ((fixture (make-fixture root)) (principal (fx fixture :principal)) (completion (fx fixture :completion)) (result nil))
           (x:attach-signed-request completion (getf principal :authority) (signed-request principal completion))
           (call-with-writer-wrapped (failing-writer root) (lambda () (setf result (x:interactive-execute completion))))
           (let ((text (v:view-html (find "Refusal" (v:all-views result) :key #'v:view-title :test #'equal))))
             (check (typep result 'x:execution-refusal))
             (check (eq :unclear (x:refusal-outcome result)))
             (check (search "It cannot be told whether this execution wrote the page." text))
             (check (not (search "No page byte was written" text)))
             (check (not (search "As previewed" text)))))))))
  ;; Positive control: a proven refusal, in the same view, does make the claim, and the same fixture executes.
  (call-with-site
   (lambda (root)
     (let* ((fixture (make-fixture root)) (principal (fx fixture :principal)) (completion (fx fixture :completion)))
       (rewrite root (lambda (o) (setf (gethash "text" (story-item o "fa6304a65d40144c")) "moved")))
       (x:attach-signed-request completion (getf principal :authority) (signed-request principal completion))
       (let* ((result (x:interactive-execute completion))
              (text (v:view-html (find "Refusal" (v:all-views result) :key #'v:view-title :test #'equal))))
         (check (eq :not-written (x:refusal-outcome result)))
         (check (search "No page byte was written" text))))))
  (call-with-site (lambda (root) (check (typep (execute-with (make-fixture root)) 'x:item-edit-execution)))))

(defun check-equality-agrees-with-the-writer ()
  "The comparison used to find the Action in the file is the writer's own, not a lookalike."
  (let ((a (shasht:read-json "{\"type\":\"edit\",\"id\":\"x\",\"n\":1,\"text\":\"Ab\"}"))
        (reordered (shasht:read-json "{\"text\":\"Ab\",\"n\":1,\"id\":\"x\",\"type\":\"edit\"}"))
        (other-case (shasht:read-json "{\"type\":\"edit\",\"id\":\"x\",\"n\":1,\"text\":\"ab\"}"))
        (other-number (shasht:read-json "{\"type\":\"edit\",\"id\":\"x\",\"n\":1.0,\"text\":\"Ab\"}")))
    (check (x:json-equal a reordered))
    (check (not (x:json-equal a other-case)))
    ;; The obvious lookalike, EQUALP, would call these two equal where the writer does not: why the writer's own is used.
    (check (equalp a other-case))
    (check (eq (x:json-equal a other-number) (plan::%json-equal a other-number)))
    (check (eq (x:json-equal a other-case) (plan::%json-equal a other-case)))))

(defun check-closure ()
  "Execution is authoring-side: the Catalog's closure and the preview's hold neither it nor the writer."
  (let ((catalog (system-closure "dreyeck/catalog-application")) (preview (system-closure "dreyeck/fedwiki-item-edit-preview"))
        (execution (system-closure "dreyeck/fedwiki-item-edit-execution")))
    (check (not (member "dreyeck/fedwiki-item-edit-execution" catalog :test #'string=)))
    (check (not (member "dreyeck/fedwiki-page-authoring" catalog :test #'string=)))
    (check (not (member "dreyeck/fedwiki-page-authoring" preview :test #'string=)))
    (check (member "dreyeck/fedwiki-page-authoring" execution :test #'string=))
    (check (member "dreyeck/authenticated-page-authoring" execution :test #'string=))
    ;; The readers' side, the preview and the proposal anatomy, loads neither the writer, the authenticated
    ;; path nor this system, so loading them can make no capability.
    (dolist (reader (list "dreyeck/fedwiki-item-edit-preview" "dreyeck/work/item-edit-proposal"))
      (let ((closure (system-closure reader)))
        (dolist (authoring '("dreyeck/fedwiki-page-authoring" "dreyeck/authenticated-page-authoring"
                             "dreyeck/authoring-envelope" "dreyeck/fedwiki-item-edit-execution"))
          (check (not (member authoring closure :test #'string=))))))))

(defun run-tests ()
  (let ((*checks* 0)
        (evidence (file-sha (evidence-path))))
    (check (equal +observed-sha256+ evidence))
    (call-with-site #'check-full-path)
    (check-refusals)
    (check-concurrency)
    (check-interactive)
    (check-differing-outcome)
    (check-writer-condition-after-replacement)
    (check-foreign-write)
    (check-refused-before-the-writer)
    (check-unclear-outcomes)
    (check-equality-agrees-with-the-writer)
    (check-closure)
    (check (equal evidence (file-sha (evidence-path))))
    (format t "~&FEDWIKI-ITEM-EDIT-EXECUTION-PASS: ~D checks; on temporary copies only: a previewed edit completed with a date (the previewed Action untouched), authorized by a signed request, executed by the existing writer, persisted (18 Items, one changed; 2 journal entries become 3) and verified in a new process; outcomes read from the file (as previewed, differs, the writer's condition after the replacement kept, unclear, refused before the writer) with the challenge state; refusals for a stale page, a changed E3, another body, an undated Action, another site root, an unknown principal, another page, a wrong key, no capability and an unchanged proposal, each with a control; two concurrent requests persist one edit; no capability is made by inspection.~%" *checks*)
    t))
