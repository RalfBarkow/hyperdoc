;;;; Smoke tests for the Kernighan/Plauger critical-reading style slice.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-PROGRAMMING-STYLE-CRITICAL-READING-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun programming-style-critical-reading-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun programming-style-critical-reading-string (value)
  (with-output-to-string (stream)
    (prin1 value stream)))

(defun programming-style-critical-reading-search (needle value)
  (search needle
          (programming-style-critical-reading-string value)
          :test #'char-equal))

(defun programming-style-critical-reading-exported-function-p (name)
  (multiple-value-bind (symbol status)
      (find-symbol name :hyperdoc)
    (and symbol
         (eq status :external)
         (fboundp symbol))))

(defun programming-style-critical-reading-plan-single-form-p ()
  (let ((path (asdf:system-relative-pathname
               :hyperdoc
               "hyperdoc/kernighan-plauger-critical-reading-style-plan.sexp")))
    (with-open-file (stream path)
      (read stream)
      (eq (read stream nil :eof) :eof))))

(defun run-programming-style-critical-reading-export-smoke-test ()
  (dolist (name '("KERNIGHAN-PLAUGER-CRITICAL-READING-SUMMARY"
                  "MAKE-CRITICAL-READING-EXAMPLE"
                  "CRITICAL-READING-EXAMPLES"
                  "CRITICAL-READING-PLAN"
                  "CRITICIZE-PROGRAM-FRAGMENT"
                  "REWRITE-PROGRAM-FRAGMENT"
                  "DERIVE-STYLE-RULE"
                  "CRITICAL-READING-REPORT"
                  "PROGRAMMING-STYLE-COVERAGE-REPORT"
                  "GOLDBERG-LONG-RECOGNIZED-PROBLEM-CROSSWALK"
                  "KNUTH-WEB-PROJECTION-CROSSWALK"
                  "INSPECT-KERNIGHAN-PLAUGER-CRITICAL-READING"))
    (programming-style-critical-reading-assert-true
     (programming-style-critical-reading-exported-function-p name)
     (format nil "Expected exported HyperDoc function ~A" name))))

(defun run-programming-style-critical-reading-example-smoke-test ()
  (let ((examples (hyperdoc:critical-reading-examples)))
    (programming-style-critical-reading-assert-true
     (some (lambda (example)
             (string= "identity-matrix"
                      (hyperdoc::critical-reading-example-id-of example)))
           examples)
     "Built-in identity-matrix critical-reading example must exist.")))

(defun run-programming-style-critical-reading-report-smoke-test ()
  (let ((report (hyperdoc:critical-reading-report)))
    (dolist (needle '("ORIGINAL"
                      "READABILITY-PROBLEM"
                      "REWRITE"
                      "RULE"
                      "integer-division"
                      "Write clearly"))
      (programming-style-critical-reading-assert-true
       (programming-style-critical-reading-search needle report)
       (format nil "Critical-reading report must include ~S" needle)))))

(defun run-programming-style-critical-reading-crosswalk-smoke-test ()
  (let ((goldberg (hyperdoc:goldberg-long-recognized-problem-crosswalk))
        (knuth (hyperdoc:knuth-web-projection-crosswalk)))
    (dolist (needle '("exploratory-environment-restatement"
                      "exploratory programming environments"))
      (programming-style-critical-reading-assert-true
       (programming-style-critical-reading-search needle goldberg)
       (format nil "Goldberg crosswalk must include ~S" needle)))
    (dolist (needle '("reader-order"
                      "machine-order-projection"))
      (programming-style-critical-reading-assert-true
       (programming-style-critical-reading-search needle knuth)
       (format nil "Knuth crosswalk must include ~S" needle)))))

(defun run-programming-style-critical-reading-plan-artifact-smoke-test ()
  (programming-style-critical-reading-assert-true
   (programming-style-critical-reading-plan-single-form-p)
   "Plan artifact must remain a single S-expression."))

(defun run-programming-style-critical-reading-smoke-tests ()
  (run-programming-style-critical-reading-export-smoke-test)
  (run-programming-style-critical-reading-example-smoke-test)
  (run-programming-style-critical-reading-report-smoke-test)
  (run-programming-style-critical-reading-crosswalk-smoke-test)
  (run-programming-style-critical-reading-plan-artifact-smoke-test)
  (format t "~&Programming style critical-reading smoke tests passed.~%")
  t)
