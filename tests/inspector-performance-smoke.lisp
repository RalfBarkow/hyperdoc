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

(defun inspector-assert-contains (substring string message)
  (unless (search substring string)
    (error "~A -- missing substring: ~S" message substring)))

(defun clog-empty-id-normalizer-available-p ()
  (let ((sym (find-symbol "NORMALIZE-HTML-ID-FOR-ATTACH" :clog)))
    (and sym (fboundp sym))))

(defun ensure-patched-clog-empty-id-guards-loaded ()
  (unless (clog-empty-id-normalizer-available-p)
    (let* ((clog-src (uiop:getenv "CLOG_SRC"))
           (clog-dir (and clog-src
                          (uiop:ensure-directory-pathname clog-src)))
           (clog-element-source
            (and clog-dir
                 (merge-pathnames "source/clog-element.lisp" clog-dir))))
      (unless (and clog-element-source (probe-file clog-element-source))
        (error "CLOG_SRC does not expose source/clog-element.lisp: ~S" clog-src))
      ;; Loading the patched CLOG element source avoids nested ASDF :force
      ;; during :asdf:test-system while still rebinding attach helpers
      ;; to the patched empty-id normalizer contract.
      (load clog-element-source)))
  (inspector-assert-true
   (clog-empty-id-normalizer-available-p)
   "Patched CLOG runtime must expose NORMALIZE-HTML-ID-FOR-ATTACH"))

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

(defun run-clog-empty-html-id-emission-smoke-test ()
  (asdf:load-system :hyperdoc/server)
  ;; Keep the patched CLOG methods active after loading :hyperdoc/server.
  (ensure-patched-clog-empty-id-guards-loaded)
  (inspector-assert-equal
   "undefined"
   (funcall (intern "NORMALIZE-HTML-ID-FOR-ATTACH" :clog) "")
   "Blank html ids must normalize before any websocket payload is considered")
  (let ((root (clog::make-clog-obj "test-connection" "root")))
    (let ((clog::*connection-cache* (list :cache)))
      (let ((child (clog:attach-as-child root "")))
        (inspector-assert-equal
         "undefined"
         (clog:html-id child)
         "Blank attach-as-child ids must normalize to the shared undefined sentinel")
        (inspector-assert-equal
         '(:cache)
         clog::*connection-cache*
         "Blank attach-as-child ids must not queue websocket eval payloads"))))
  (let ((clog::*connection-cache* (list :cache)))
    (let ((child (clog::attach "test-connection" "")))
      (inspector-assert-equal
       "undefined"
       (clog:html-id child)
       "Blank attach ids must normalize to the shared undefined sentinel")
      (inspector-assert-equal
       '(:cache)
       clog::*connection-cache*
       "Blank attach ids must not queue websocket eval payloads")))
  (let ((root (clog::make-clog-obj "test-connection" "root"))
        (clog::*connection-cache* (list :cache)))
    (let ((child (clog:attach-as-child root "view817")))
      (inspector-assert-equal
       "view817"
       (clog:html-id child)
       "Non-blank attach-as-child ids must still attach normally")
      (inspector-assert-contains
       "clog['view817']=$('#view817').get(0)"
       (first clog::*connection-cache*)
       "Non-blank attach-as-child ids must still emit the expected websocket payload"))))

(defun run-inspector-performance-smoke-tests ()
  (run-dom-node-count-query-script-smoke-test)
  (run-clog-empty-html-id-emission-smoke-test)
  (format t "~&Inspector performance smoke tests passed.~%")
  t)
