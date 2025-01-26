;;;; Exported variables
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

(defvar *hyperdoc*
  (make-hyperdoc :title "HyperDoc"
                 :asdf-system-name "hyperdoc"
                 :subdirectory "hyperdoc"))
