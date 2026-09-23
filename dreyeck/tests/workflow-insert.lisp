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

(defun run-insert-tests ()
  (let ((environment (a:make-authoring-environment)))
    (call-with-fixture
     (lambda (asd system)
       (test-rejects-a-key-that-already-exists asd system)
       (test-rejects-a-missing-anchor asd system)
       (test-rejects-an-ambiguous-anchor asd system)
       (test-rejects-a-disturbed-neighbour asd system)
       (test-inserts-and-leaves-the-rest-alone asd system environment))))
  (format t "~&INSERT-OWNED-FORM-PASS: duplicate key, missing and ambiguous ~
anchor refused; a changed, reordered or extra neighbour fails verification; ~
one form inserted before its anchor and nothing else touched.~%")
  t)
