;;;; What REMOVE-OWNED-FORM must refuse, and what it must not disturb.
(defpackage #:dreyeck/workflow/remove/tests
  (:use #:cl)
  (:local-nicknames (#:a #:dreyeck/workflow/authoring) (#:wf #:dreyeck/workflow))
  (:export #:run-remove-tests))

(in-package #:dreyeck/workflow/remove/tests)

(defparameter +fixture-asd+
  "(defsystem \"remove-proof\" :components ((:file \"answer\")))

(defsystem \"remove-proof/tests\" :depends-on (\"remove-proof\"))

;;; A comment between forms, which no removal of a form may touch.
(defsystem \"remove-proof/extra\" :depends-on (\"remove-proof\"))

(defsystem \"remove-proof/last\" :depends-on (\"remove-proof\"))
"
  "Four owned DEFSYSTEM forms and a comment, so a removed form has
neighbours on both sides and non-form text nearby.")

(defparameter +fixture-source+
  "(in-package :cl-user)

(defun remove-proof-kept () 1)

(defun remove-proof-doomed () 2)

;;; A comment that stays.
(defun remove-proof-after () 3)
"
  "An ordinary source file the fixture system owns.")

(defparameter +fixture-source-after+
  "(in-package :cl-user)

(defun remove-proof-kept () 1)

;;; A comment that stays.
(defun remove-proof-after () 3)
"
  "+FIXTURE-SOURCE+ without REMOVE-PROOF-DOOMED: nothing else differs.")

(defun %fixture-root ()
  (merge-pathnames (format nil "workflow-remove-proof-~D-~D/"
                           (get-universal-time) (random 100000))
                   (uiop:temporary-directory)))

(defun %write (path text)
  (uiop:with-output-file (stream path :external-format :utf-8 :if-exists :supersede)
    (write-string text stream)))

(defun call-with-fixture (function)
  "Build a throwaway authority, hand it to FUNCTION, then remove it."
  (let* ((root (%fixture-root))
         (asd (merge-pathnames "remove-proof.asd" root))
         (source (merge-pathnames "answer.lisp" root)))
    (ensure-directories-exist root)
    (unwind-protect
         (progn
           (%write asd +fixture-asd+)
           (%write source +fixture-source+)
           (asdf:load-asd asd)
           (funcall function asd source "remove-proof"))
      (dolist (name '("remove-proof" "remove-proof/tests" "remove-proof/extra"
                      "remove-proof/last"))
        (ignore-errors (asdf:clear-system name)))
      (uiop:delete-directory-tree root :validate t :if-does-not-exist :ignore))))

(defun %signals (thunk)
  (handler-case (progn (funcall thunk) nil)
    (error (condition) (princ-to-string condition))))

(defun %text (path) (uiop:read-file-string path :external-format :utf-8))

(defun %system-key (name) (list :system name))

(defun %definition-key (text)
  (wf:form-key (let ((*package* (find-package :cl-user))) (read-from-string text))))

(defun %candidates (path)
  (remove-if-not (lambda (file) (search "candidate" (or (pathname-type file) "")))
                 (directory (make-pathname :name :wild :type :wild :defaults path))))

(defun %replace-once (string old new)
  (let ((at (search old string)))
    (assert (and at (null (search old string :start2 (1+ at)))))
    (concatenate 'string (subseq string 0 at) new (subseq string (+ at (length old))))))

(defun test-refuses-a-missing-target (asd system)
  (let ((before (%text asd))
        (message (%signals (lambda () (a::plan-removal system asd (%system-key "remove-proof/absent"))))))
    (assert (search "exactly one" message))
    (assert (string= before (%text asd))))
  t)

(defun test-refuses-an-ambiguous-target (asd system)
  ;; Two forms carrying the key: the operation must not choose.
  (%write asd (concatenate 'string +fixture-asd+ "
(defsystem \"remove-proof/extra\" :depends-on (\"remove-proof\"))
"))
  (let* ((before (%text asd))
         (message (%signals (lambda () (a::plan-removal system asd (%system-key "remove-proof/extra"))))))
    (assert (search "exactly one" message))
    (assert (string= before (%text asd))))
  (%write asd +fixture-asd+)
  t)

(defun test-refuses-an-unkeyed-target (asd system)
  (assert (search "structural key" (%signals (lambda () (a::plan-removal system asd nil)))))
  t)

(defun test-verification-rejects-damage (asd system)
  "The reason a structural removal exists rather than a text edit."
  (let* ((plan (a::plan-removal system asd (%system-key "remove-proof/extra")))
         (source (a::removal-plan-source plan))
         (range (a::removal-plan-range plan))
         (honest (a::%spliced source range "")))
    ;; Positive control: the honest result is accepted, so each rejection
    ;; below is about its damage and not about a blind checker.
    (assert (a::verify-removal plan honest))
    ;; The removed range is the form and its blank line, nothing more.
    (assert (search ";;; A comment between forms" honest))
    (assert (not (search "remove-proof/extra" honest)))
    (flet ((rejected (after needle)
             (let ((message (%signals (lambda () (a::verify-removal plan after)))))
               (assert (and message (search needle message)) ()
                       "Expected a refusal mentioning ~S, got ~S." needle message))))
      ;; The target is still there.
      (rejected source "still occurs")
      ;; A neighbouring form changed.
      (rejected (%replace-once honest "(defsystem \"remove-proof/tests\" :depends-on (\"remove-proof\"))"
                               "(defsystem \"remove-proof/tests\" :depends-on (\"somewhere-else\"))")
                "other than the removed one changed")
      ;; A neighbour went with it.
      (rejected (%replace-once honest "(defsystem \"remove-proof/last\" :depends-on (\"remove-proof\"))
" "")
                "lost or gained")
      ;; Only bytes outside the range changed: the comment, not a form.
      (rejected (%replace-once honest ";;; A comment between forms" ";;; A comment between the forms")
                "Bytes outside")
      ;; Unreadable.
      (rejected (concatenate 'string honest "(defsystem \"remove-proof/open\"")
                "reader recovery"))
    t))

(defun test-a-refusal-leaves-the-authority-untouched (asd system environment)
  ;; A stale plan: the authority changed after it was observed.
  (let ((plan (a::plan-removal system asd (%system-key "remove-proof/extra"))))
    (%write asd (concatenate 'string +fixture-asd+ ";;; Changed since.
"))
    (let ((before (%text asd)))
      (assert (search "changed since it was observed"
                      (%signals (lambda () (a::remove-owned-form plan environment)))))
      (assert (string= before (%text asd)))
      (assert (null (%candidates asd)))))
  (%write asd +fixture-asd+)
  t)

(defun test-removes-from-a-system-definition (asd system environment)
  (let* ((plan (a::plan-removal system asd (%system-key "remove-proof/extra")))
         (before (a::removal-plan-before plan))
         (expected-text (a::%spliced (a::removal-plan-source plan) (a::removal-plan-range plan) ""))
         (after (a::remove-owned-form plan environment)))
    (assert (string= expected-text (%text asd)))
    (assert (= (1- (length before)) (length after)))
    (assert (zerop (count (%system-key "remove-proof/extra") after :key #'wf:form-key :test #'equal)))
    (assert (equal (mapcar #'wf:form-key (remove (%system-key "remove-proof/extra") before
                                                 :key #'wf:form-key :test #'equal))
                   (mapcar #'wf:form-key after)))
    ;; Readable where ASDF reads it, and no candidate left beside it.
    (assert (= (length after) (a::read-in-target-reader-context asd)))
    (assert (null (%candidates asd))))
  (%write asd +fixture-asd+)
  t)

(defun test-removes-from-a-source-file (source system environment)
  (let* ((key (%definition-key "(defun remove-proof-doomed () 2)"))
         (plan (a::plan-removal system source key))
         (after (a::remove-owned-form plan environment)))
    (assert (string= +fixture-source-after+ (%text source)))
    (assert (= 3 (length after)))
    (assert (null (%candidates source))))
  t)

(defun run-remove-tests ()
  (let ((environment (a:make-authoring-environment)))
    (call-with-fixture
     (lambda (asd source system)
       (test-refuses-a-missing-target asd system)
       (test-refuses-an-ambiguous-target asd system)
       (test-refuses-an-unkeyed-target asd system)
       (test-verification-rejects-damage asd system)
       (test-a-refusal-leaves-the-authority-untouched asd system environment)
       (test-removes-from-a-system-definition asd system environment)
       (test-removes-from-a-source-file source system environment))))
  (format t "~&REMOVE-OWNED-FORM-PASS: a missing, ambiguous or unkeyed target ~
refused with the authority byte-identical; the honest result accepted, and a ~
result that keeps the target, changes or loses a neighbour, changes a byte ~
outside the range or does not read rejected; a stale authority refused with ~
no candidate left; one form removed from a system definition and from a ~
source file, every other byte unchanged, the definition still readable by ASDF.~%")
  t)
