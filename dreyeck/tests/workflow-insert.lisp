;;;; What INSERT-OWNED-FORM must refuse, and what it must not disturb.
(defpackage #:dreyeck/workflow/insert/tests
  (:use #:cl)
  (:local-nicknames (#:a #:dreyeck/workflow/authoring) (#:wf #:dreyeck/workflow))
  (:export #:run-insert-tests))

(in-package #:dreyeck/workflow/insert/tests)

(defparameter +fixture-asd+
  "(defsystem \"insert-proof\" :components ((:file \"answer\")))

(defsystem \"insert-proof/tests\" :depends-on (\"insert-proof\"))

(defsystem \"insert-proof/extra\" :depends-on (\"insert-proof\"))
"
  "Three owned DEFSYSTEM forms, so an anchor has neighbours on both sides.")

(defun %fixture-root ()
  (merge-pathnames (format nil "workflow-insert-proof-~D-~D/"
                           (get-universal-time) (random 100000))
                   (uiop:temporary-directory)))

(defun call-with-fixture (function)
  "Build a throwaway authority, hand it to FUNCTION, then remove it.
A function rather than a macro: the acceptance check for a newly created
source authority cannot yet round-trip a backquoted form, and nothing
here needs one."
  (let* ((root (%fixture-root))
         (asd (merge-pathnames "insert-proof.asd" root)))
    (ensure-directories-exist root)
    (unwind-protect
         (progn
           (uiop:with-output-file (stream asd :external-format :utf-8)
             (write-string +fixture-asd+ stream))
           (uiop:with-output-file (stream (merge-pathnames "answer.lisp" root)
                                          :external-format :utf-8)
             (write-string "(in-package :cl-user)" stream))
           (asdf:load-asd asd)
           (funcall function asd "insert-proof"))
      ;; Forget the fixture systems, or a second run in the same image
      ;; would plan against the previous fixture's deleted pathnames.
      (dolist (name '("insert-proof" "insert-proof/tests" "insert-proof/extra"
                      "insert-proof/new" "insert-proof/local"
                      "insert-proof/foreign" "insert-proof/fresh"))
        (ignore-errors (asdf:clear-system name)))
      (uiop:delete-directory-tree root :validate t
                                       :if-does-not-exist :ignore))))

(defun %proposed (name)
  (read-from-string
   (format nil "(defsystem ~S :depends-on (\"insert-proof\"))" name)))

(defun %signals (thunk)
  (handler-case (progn (funcall thunk) nil)
    (error (condition) (princ-to-string condition))))

(defun %plan (asd system proposed anchor)
  (a::plan-insertion system asd (wf:form-key proposed) proposed
                     (list :system anchor)))

(defun test-rejects-a-key-that-already-exists (asd system)
  ;; An insertion is not a disguised replacement.
  (let ((message (%signals (lambda ()
                             (%plan asd system (%proposed "insert-proof/tests")
                                    "insert-proof/extra")))))
    (assert message)
    (assert (search "replacement, not an insertion" message))
    t))

(defun test-rejects-a-missing-anchor (asd system)
  (let ((message (%signals (lambda ()
                             (%plan asd system (%proposed "insert-proof/new")
                                    "insert-proof/absent")))))
    (assert message)
    (assert (search "exactly once" message))
    t))

(defun test-rejects-an-ambiguous-anchor (asd system)
  ;; Two forms carrying the anchor key: the operation must not choose.
  (uiop:with-output-file (stream asd :external-format :utf-8
                                     :if-exists :supersede)
    (write-string +fixture-asd+ stream)
    (write-string "
(defsystem \"insert-proof/extra\" :depends-on (\"insert-proof\"))
" stream))
  (let ((message (%signals (lambda ()
                             (%plan asd system (%proposed "insert-proof/new")
                                    "insert-proof/extra")))))
    (assert message)
    (assert (search "exactly once" message))
    ;; Restore the fixture for the tests that follow.
    (uiop:with-output-file (stream asd :external-format :utf-8
                                       :if-exists :supersede)
      (write-string +fixture-asd+ stream))
    t))

(defun test-rejects-a-disturbed-neighbour (asd system)
  "The reason a structural insert exists rather than a text edit."
  (let* ((proposed (%proposed "insert-proof/new"))
         (plan (%plan asd system proposed "insert-proof/tests"))
         (before (a::insertion-plan-before plan))
         (index 1)
         (honest (a::%inserted-sequence before proposed index))
         (damaged (let ((copy (copy-tree honest)))
                    ;; Change something in a form the insertion never named.
                    (setf (getf (cddr (first copy)) :components)
                          '((:file "somewhere-else")))
                    copy))
         (reordered (let ((copy (copy-tree honest)))
                      (rotatef (first copy) (second copy))
                      copy))
         (extra (append (copy-tree honest) (list (%proposed "insert-proof/x")))))
    ;; Positive control: the honest sequence is accepted, so a rejection
    ;; below is about the damage and not about the checker being blind.
    (assert (a::verify-insertion plan index honest))
    (let ((message (%signals (lambda () (a::verify-insertion plan index damaged)))))
      (assert message)
      (assert (search "other than the inserted one changed" message)))
    (let ((message (%signals (lambda () (a::verify-insertion plan index reordered)))))
      (assert message))
    (let ((message (%signals (lambda () (a::verify-insertion plan index extra)))))
      (assert message)
      (assert (search "more than one form" message)))
    t))

(defun test-inserts-and-leaves-the-rest-alone (asd system environment)
  (let* ((proposed (%proposed "insert-proof/new"))
         (plan (%plan asd system proposed "insert-proof/tests"))
         (before (a::insertion-plan-before plan))
         (after (a::insert-owned-form plan environment)))
    (assert (= (1+ (length before)) (length after)))
    (assert (= 1 (count '(:system "insert-proof/new") after
                        :key #'wf:form-key :test #'equal)))
    ;; Order preserved, and every earlier form still structurally itself.
    (assert (every #'wf:form-equal before (remove '(:system "insert-proof/new")
                                                  after :key #'wf:form-key
                                                        :test #'equal)))
    ;; The new form sits before its anchor, not merely somewhere.
    (let ((keys (mapcar #'wf:form-key after)))
      (assert (< (position '(:system "insert-proof/new") keys :test #'equal)
                 (position '(:system "insert-proof/tests") keys :test #'equal))))
    ;; The authority is still readable as a whole.
    (assert (= (length after) (length (wf:source-forms asd))))
    t))

;;; Target readability, and that a refusal costs the authority nothing

(defpackage #:insert-proof-absent-package
  (:use #:cl)
  (:documentation
   "A package this image has and a plain SBCL does not.
The falsifier is about a printed package prefix the consumer cannot
resolve, not about any particular package of this repository."))

(defun %authority-text (asd)
  (uiop:read-file-string asd :external-format :utf-8))

(defun %proposed-with-foreign-symbol (name)
  "Structurally a fine DEFSYSTEM; one symbol belongs to a package the
ordinary ASDF reader has never heard of."
  (list (intern "DEFSYSTEM" :asdf-user) name
        :depends-on '("insert-proof")
        :perform (list (intern "TEST-OP" :asdf-user)
                       (list (intern "OPERATION" :insert-proof-absent-package)
                             (intern "COMPONENT" :insert-proof-absent-package))
                       t)))

(defun %proposed-with-local-symbol (name)
  "The same shape, with symbols the consumer can read."
  (list (intern "DEFSYSTEM" :asdf-user) name
        :depends-on '("insert-proof")
        :perform (list (intern "TEST-OP" :asdf-user)
                       (list (intern "OPERATION" :asdf-user)
                             (intern "COMPONENT" :asdf-user))
                       t)))

(defun test-refuses-a-candidate-the-consumer-cannot-read (asd system)
  (let* ((before (%authority-text asd))
         (proposed (%proposed-with-foreign-symbol "insert-proof/foreign"))
         (plan (%plan asd system proposed "insert-proof/tests"))
         (message (%signals (lambda ()
                              (a::insert-into-candidate plan)))))
    (assert message)
    (assert (search "not readable by its ordinary consumer" message))
    ;; The authority was never written to.
    (assert (string= before (%authority-text asd)))
    ;; Positive control: the same form with readable symbols is accepted,
    ;; so the rejection is about the package prefix and not the shape.
    (let* ((honest (%proposed-with-local-symbol "insert-proof/local"))
           (honest-plan (%plan asd system honest "insert-proof/tests"))
           (after (a::insert-into-candidate honest-plan)))
      (assert (= 1 (count '(:system "insert-proof/local") after
                          :key #'wf:form-key :test #'equal)))
      (assert (= (length after) (a::read-in-target-reader-context asd))))
    ;; No candidate file left behind beside the authority.
    (assert (null (remove-if-not
                   (lambda (file)
                     (search "candidate" (or (pathname-type file) "")))
                   (directory (make-pathname :name :wild :type :wild
                                             :defaults asd)))))
    t))

(defun test-a-refusal-leaves-the-authority-untouched (asd system)
  (dolist (attempt (list (lambda ()
                           (%plan asd system (%proposed "insert-proof/tests")
                                  "insert-proof/extra"))
                         (lambda ()
                           (%plan asd system (%proposed "insert-proof/fresh")
                                  "insert-proof/absent"))))
    (let ((before (%authority-text asd)))
      (assert (%signals attempt))
      (assert (string= before (%authority-text asd)))))
  t)

(defun run-insert-tests ()
  (let ((environment (a:make-authoring-environment)))
    (call-with-fixture
     (lambda (asd system)
       (test-rejects-a-key-that-already-exists asd system)
       (test-rejects-a-missing-anchor asd system)
       (test-rejects-an-ambiguous-anchor asd system)
       (test-rejects-a-disturbed-neighbour asd system)
       (test-a-refusal-leaves-the-authority-untouched asd system)
       (test-refuses-a-candidate-the-consumer-cannot-read asd system)
       (test-inserts-and-leaves-the-rest-alone asd system environment))))
  (format t "~&INSERT-OWNED-FORM-PASS: duplicate key, missing and ambiguous ~
anchor refused with the authority byte-identical; a changed, reordered or ~
extra neighbour fails verification; a candidate its consumer cannot read is ~
refused while the same shape with readable symbols is accepted; one form ~
inserted before its anchor and nothing else touched.~%")
  t)
