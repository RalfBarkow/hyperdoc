;;;; What a targeted CST-source replacement must refuse, and what it must
;;;; leave exactly as it found it.
(defpackage #:dreyeck/workflow/cst-replace/tests
  (:use #:cl)
  (:local-nicknames (#:a #:dreyeck/workflow/authoring)
                    (#:wf #:dreyeck/workflow))
  (:export #:run-cst-replace-tests))

(in-package #:dreyeck/workflow/cst-replace/tests)

(defparameter +fixture-asd+
  "(defsystem \"cst-probe\" :components ((:file \"answer\")))
")

(defparameter +fixture-source+
  "(in-package :cl-user)

(defun probed ()
  ;; This comment explains why the value is seven.
  (let ((x 7))   ; trailing note
    x))

(defun untouched ()
  ;; A neighbour whose text must survive byte for byte.
  (list 1 2 3))
")

(defparameter +expected-source+
  "(in-package :cl-user)

(defun probed ()
  ;; This comment explains why the value is seven.
  (let ((x 8))   ; trailing note
    x))

(defun untouched ()
  ;; A neighbour whose text must survive byte for byte.
  (list 1 2 3))
"
  "Byte for byte, the fixture with one token changed and nothing else.")

(defun call-with-fixture (function &key (source +fixture-source+))
  (let* ((root (merge-pathnames (format nil "cst-replace-probe-~D-~D/"
                                        (get-universal-time) (random 100000))
                                (uiop:temporary-directory)))
         (asd (merge-pathnames "cst-probe.asd" root))
         (path (merge-pathnames "answer.lisp" root)))
    (ensure-directories-exist root)
    (unwind-protect
         (progn
           (uiop:with-output-file (stream asd :external-format :utf-8)
             (write-string +fixture-asd+ stream))
           (uiop:with-output-file (stream path :external-format :utf-8)
             (write-string source stream))
           (asdf:load-asd asd)
           (funcall function path))
      (ignore-errors (asdf:clear-system "cst-probe"))
      (uiop:delete-directory-tree root :validate t
                                       :if-does-not-exist :ignore))))

(defun %signals (thunk)
  (handler-case (progn (funcall thunk) nil)
    (error (condition) (princ-to-string condition))))

(defun %text (path) (uiop:read-file-string path :external-format :utf-8))

(defun %plan (path expected replacement value)
  (a::plan-cst-source-replacement
   "cst-probe" path '(:definition cl-user::probed) expected replacement value))

;;; The positive control, through the repository-level operation

(defun test-targeted-replacement-preserves-everything-else (environment)
  (call-with-fixture
   (lambda (path)
     (let* ((before (%text path))
            (plan (%plan path 7 "8" 8)))
       (a::replace-owned-cst-source plan environment)
       (let ((after (%text path)))
         ;; One comparison covers comments, spelling and whitespace at once.
         (assert (string= +expected-source+ after))
         (assert (not (string= before after)))
         ;; Named individually as well, so a failure says which property.
         (assert (search "why the value is seven" after))
         (assert (search "; trailing note" after))
         (assert (search "(defun probed ()" after))
         (assert (search "whose text must survive byte for byte" after))
         (assert (search "(list 1 2 3)" after)))))))

;;; A. The target occurs more than once

(defun test-rejects-a-duplicate-target ()
  (call-with-fixture
   (lambda (path)
     (let* ((before (%text path))
            (message (%signals (lambda () (%plan path 7 "8" 8)))))
       (assert message)
       (assert (search "exactly once" message))
       (assert (string= before (%text path)))))
   :source "(in-package :cl-user)

(defun probed ()
  ;; Seven twice: the address is ambiguous and must not be guessed.
  (list 7 7))
"))

;;; B. The target is not there

(defun test-rejects-a-missing-target ()
  (call-with-fixture
   (lambda (path)
     (let* ((before (%text path))
            (message (%signals (lambda () (%plan path 9 "8" 8)))))
       (assert message)
       (assert (search "occurs 0 times" message))
       (assert (string= before (%text path)))))))

;;; C.-E. Collateral damage is caught by the byte comparison

(defun test-verification-catches-collateral-change (environment)
  (declare (ignore environment))
  (call-with-fixture
   (lambda (path)
     (let ((plan (%plan path 7 "8" 8)))
       ;; The honest result is accepted, so a rejection below is about the
       ;; damage rather than the checker being blind.
       (assert (a::verify-cst-source-replacement plan +expected-source+))
       (dolist (case (list
                      (list "internal comment removed"
                            (remove-comment +expected-source+
                                            "why the value is seven"))
                      (list "trailing comment removed"
                            (remove-comment +expected-source+
                                            "trailing note"))
                      (list "() respelled as NIL outside the target"
                            (replace-once +expected-source+
                                          "(defun probed ()"
                                          "(defun probed nil"))
                      (list "one byte of whitespace outside the target"
                            (replace-once +expected-source+
                                          "    x))" "     x))"))
                      (list "a neighbouring form's text changed"
                            (replace-once +expected-source+
                                          "(list 1 2 3)" "(list 1 2 4)"))))
         (destructuring-bind (label damaged) case
           (let ((message (%signals
                           (lambda ()
                             (a::verify-cst-source-replacement plan
                                                               damaged)))))
             (assert message)
             (assert (search "outside the targeted range" message)
                     () "~A was not rejected" label))))))))

(defun replace-once (text from to)
  (let ((pos (search from text)))
    (assert pos)
    (concatenate 'string (subseq text 0 pos) to
                 (subseq text (+ pos (length from))))))

(defun remove-comment (text fragment)
  "Drop the whole line carrying FRAGMENT, as a careless rewrite would."
  (let* ((pos (search fragment text))
         (start (1+ (or (position #\Newline text :from-end t :end pos) -1)))
         (end (1+ (or (position #\Newline text :start pos) (1- (length text))))))
    (concatenate 'string (subseq text 0 start) (subseq text end))))

;;; F. The replacement text is not valid source

(defun test-rejects-malformed-replacement (environment)
  (call-with-fixture
   (lambda (path)
     (let* ((before (%text path))
            (plan (%plan path 7 "(((" 8))
            (message (%signals (lambda ()
                                 (a::replace-owned-cst-source plan
                                                              environment)))))
       (assert message)
       ;; The authority is exactly as it was, and no candidate is left.
       (assert (string= before (%text path)))
       (assert (null (remove-if-not
                      (lambda (file)
                        (search "candidate" (or (pathname-type file) "")))
                      (directory (make-pathname :name :wild :type :wild
                                                :defaults path)))))))))

;;; The replacement must read as what the caller said it would

(defun test-rejects-a-replacement-that-reads-as-something-else (environment)
  (call-with-fixture
   (lambda (path)
     (let* ((before (%text path))
            (plan (%plan path 7 "9" 8))
            (message (%signals (lambda ()
                                 (a::replace-owned-cst-source plan
                                                              environment)))))
       (assert message)
       (assert (search "reads as" message))
       (assert (string= before (%text path)))))))

(defun run-cst-replace-tests ()
  (let ((environment (a:make-authoring-environment)))
    (test-targeted-replacement-preserves-everything-else environment)
    (test-rejects-a-duplicate-target)
    (test-rejects-a-missing-target)
    (test-verification-catches-collateral-change environment)
    (test-rejects-malformed-replacement environment)
    (test-rejects-a-replacement-that-reads-as-something-else environment))
  (format t "~&CST-SOURCE-REPLACEMENT-PASS: one token changed and every other ~
byte kept; duplicate, missing and malformed targets refused with the ~
authority untouched; comment, spelling, whitespace and neighbour damage all ~
fail verification.~%")
  t)
