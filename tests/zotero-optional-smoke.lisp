;;;; Smoke tests for the optional Zotero runtime boundary
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-ZOTERO-OPTIONAL-SMOKE-TESTS" :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun run-zotero-optional-smoke-tests ()
  (assert-true (null (find-class 'hyperdoc::zotero-library-bridge nil))
               "Core HyperDoc load must not define Zotero bridge classes before the optional Zotero system is loaded")
  (assert-true (null (find-class 'hyperdoc::zotero-bibliography-source nil))
               "Core HyperDoc load must not define Zotero bibliography source classes before the optional Zotero system is loaded")
  (hyperdoc::with-zotero-support-mode (:disabled)
    (let* ((source (hyperdoc::make-default-bibliography-source))
           (subcollection (hyperdoc::coachmark-bibliography-subcollection))
           (runtime-status (hyperdoc::maybe-enable-zotero-runtime-support)))
      (assert-true (hyperdoc::zotero-backend-unavailable-p source)
                   "Disabled configuration must expose an explicit unavailable bibliography source instead of a fake Zotero source")
      (assert-true (hyperdoc::zotero-backend-unavailable-p subcollection)
                   "Disabled configuration must expose an explicit unavailable bibliography subcollection instead of crashing")
      (assert-true (hyperdoc::zotero-backend-unavailable-p runtime-status)
                   "Disabled configuration must let the runtime startup seam degrade explicitly instead of crashing")
      (assert-equal :disabled-by-configuration
                    (hyperdoc::zotero-backend-unavailable-reason-of runtime-status)
                    "Runtime startup seam must report configuration-disabled Zotero support")))
  (format t "~&Optional Zotero boundary smoke tests passed.~%")
  t)
