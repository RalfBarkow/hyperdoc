;;;; Optional Zotero-backed smoke suite entrypoint
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-HYPERDOC-ZOTERO-TESTS" :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun run-hyperdoc-zotero-tests ()
  (run-zotero-bridge-smoke-tests)
  (run-zotero-bridge-live-tests)
  (run-bibliography-subcollections-smoke-tests)
  t)
