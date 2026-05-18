;;;; Smoke tests for the optional Zotero runtime boundary
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-ZOTERO-OPTIONAL-SMOKE-TESTS" :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun zotero-optional-asd-source ()
  (uiop:read-file-string
   (asdf:system-relative-pathname :hyperdoc "hyperdoc.asd")))

(defun zotero-optional-asd-system-block (source system-marker)
  (let ((start (search system-marker source :test #'char=)))
    (assert-true start (format nil "hyperdoc.asd must define ~A" system-marker))
    (let ((next (search "(defsystem "
                        source
                        :start2 (1+ start)
                        :test #'char=)))
      (subseq source start next))))

(defun zotero-optional-assert-search (needle haystack message)
  (assert-true
   (search needle haystack :test #'char=)
   (format nil "~A -- missing ~S" message needle)))

(defun zotero-optional-assert-not-search (needle haystack message)
  (assert-true
   (not (search needle haystack :test #'char=))
   (format nil "~A -- unexpected ~S" message needle)))

(defun run-zotero-optional-asdf-boundary-smoke-test ()
  (let* ((source (zotero-optional-asd-source))
         (support
          (zotero-optional-asd-system-block
           source
           "(defsystem #:hyperdoc/zotero-support"))
         (bibliography
          (zotero-optional-asd-system-block
           source
           "(defsystem #:hyperdoc/bibliography"))
         (zotero
          (zotero-optional-asd-system-block
           source
           "(defsystem #:hyperdoc/zotero
")))
    (zotero-optional-assert-search
     "#:hyperdoc/zotero-support"
     bibliography
     "Bibliography system must depend on the optional-support boundary")
    (zotero-optional-assert-search
     "(:file \"zotero-support\")"
     support
     "Zotero support system must load the support wrappers")
    (zotero-optional-assert-not-search
     "(:file \"zotero-bridge\")"
     bibliography
     "Bibliography system must not load the Zotero backend implementation")
    (zotero-optional-assert-search
     "#:hyperdoc/bibliography"
     zotero
     "Optional Zotero backend must layer on the bibliography system")
    (zotero-optional-assert-search
     "(:file \"zotero-bridge\")"
     zotero
     "Optional Zotero backend must own the live bridge implementation")))

(defun run-zotero-disabled-unavailable-object-smoke-test ()
  (hyperdoc::with-zotero-support-mode (:disabled)
    (let ((runtime-status
            (hyperdoc::make-zotero-backend-unavailable
             "runtime Zotero support")))
      (assert-true
       (hyperdoc::zotero-backend-unavailable-p runtime-status)
       "Disabled configuration must expose an explicit unavailable object")
      (assert-equal
       :disabled-by-configuration
       (hyperdoc::zotero-backend-unavailable-reason-of runtime-status)
       "Runtime startup seam must report configuration-disabled Zotero support"))))

(defun run-zotero-optional-smoke-tests ()
  (run-zotero-optional-asdf-boundary-smoke-test)
  (run-zotero-disabled-unavailable-object-smoke-test)
  (format t "~&Optional Zotero boundary smoke tests passed.~%")
  t)
