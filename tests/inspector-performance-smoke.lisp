;;;; Smoke tests for inspector performance JS emission
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-INSPECTOR-PERFORMANCE-SMOKE-TESTS" :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun inspector-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun inspector-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun run-dom-node-count-query-script-smoke-test ()
  (asdf:load-system :hyperdoc/server)
  (let ((string-script
          (clog-moldable-inspector::dom-node-count-query-script "view817"))
        (symbol-id (make-symbol "view817")))
    (inspector-assert-equal
     "view817"
     (clog-moldable-inspector::normalize-dom-html-id "view817")
     "String ids must remain unchanged")
    (inspector-assert-true
     (search "document.getElementById(\"view817\")" string-script)
     "String ids must be emitted as quoted JS strings")
    (inspector-assert-true
     (null (search "document.getElementById(view817)" string-script))
     "String ids must not be emitted as bare JS tokens")
    (let ((symbol-script
            (clog-moldable-inspector::dom-node-count-query-script symbol-id)))
      (inspector-assert-equal
       "view817"
       (clog-moldable-inspector::normalize-dom-html-id symbol-id)
       "Symbol ids must normalize to their symbol-name")
      (inspector-assert-true
       (search "document.getElementById(\"view817\")" symbol-script)
       "Symbol-ish ids must be emitted as quoted JS strings")
      (inspector-assert-true
       (null (search "#:|view817|" symbol-script))
       "Symbol reader syntax must not leak into emitted JS")
      (inspector-assert-true
       (null (search "document.getElementById(view817)" symbol-script))
       "Symbol-ish ids must not be emitted as bare JS tokens"))))

(defun run-inspector-performance-smoke-tests ()
  (run-dom-node-count-query-script-smoke-test)
  (format t "~&Inspector performance smoke tests passed.~%")
  t)
