;;;; Runtime-only hooks for the HyperDoc server system
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

;; Register optional runtime integrations only when the server stack is loaded.
(eval-when (:load-toplevel :execute)
  (maybe-register-zotero-startup-hook))
