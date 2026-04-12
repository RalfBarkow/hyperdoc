;;;; Smoke tests for bounded function-lookup issues
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-FUNCTION-LOOKUP-ISSUES-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun run-function-lookup-issues-smoke-tests ()
  (let* ((symbol (intern "FUNCTION-LOOKUP-ISSUE-SMOKE-MISSING" :hyperdoc))
         (page-id (format nil "~A::~A"
                          (package-name (symbol-package symbol))
                          (symbol-name symbol))))
    (assert-true (not (fboundp symbol))
                 "Focused function-lookup smoke must use a symbol that is not fbound")
    (let* ((issue (hyperbook:find-page hyperbook::*lisp-functions*
                                       page-id
                                       :signal-error? t))
           (condition (hyperbook:lookup-issue-underlying-condition-of issue))
           (message (hyperbook:lookup-issue-underlying-message-of issue)))
      (assert-true (typep issue 'hyperbook:function-lookup-issue)
                   "A missing Lisp function page should surface as a primary function-lookup-issue")
      (assert-true (typep condition 'undefined-function)
                   "A function-lookup-issue should preserve the underlying undefined-function condition")
      (assert-true (search "is undefined" message :test #'char-equal)
                   "A function-lookup-issue should preserve the rendered undefined-function message text")))
  (format t "~&Function lookup issue smoke tests passed.~%")
  t)
