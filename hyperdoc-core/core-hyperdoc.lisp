;;;; The HyperDoc core HyperDoc
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc/core)

;;
;; The HyperDoc for HyperDoc
;;

(defvar *hyperdoc*
  (make-hyperdoc
   ;; The title of the HyperDoc
   :title "HyperDoc Core"
   ;; The ASDF system in which it is located
   :asdf-system-name "hyperdoc/core"
   ;; The subdirectory and ASDF module name containing the  text and code pages
   :subdirectory "hyperdoc-core"
   ;; The title of the page to be displayed as the main entry point
   :entry "HyperDoc Core"))

(register *hyperdoc*)
