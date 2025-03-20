;;;; HyperDoc Explorer's HyperDoc
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; The HyperDoc for HyperDoc
;;

(defvar *explorer-hyperdoc*
  (make-hyperdoc
   ;; The title of the HyperDoc
   :title "HyperDoc Explorer"
   ;; The ASDF system in which it is located
   :asdf-system-name "hyperdoc/explorer"
   ;; The subdirectory and ASDF module name containing the  text and code pages
   :subdirectory "hyperdoc-explorer"
   ;; The title of the page to be displayed as the main entry point
   :entry "HyperDoc Explorer"))

(register *explorer-hyperdoc*)
