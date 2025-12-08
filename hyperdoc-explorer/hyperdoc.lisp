;;;; HyperDoc Explorer's HyperDoc
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc/explorer)

;;
;; The HyperDoc for HyperDoc
;;

(defhyperdoc *hyperdoc*
  ;; The title of the HyperDoc
  :id "hyperdoc/explorer"
  :title "HyperDoc Explorer"
  ;; The ASDF system in which it is located
  :asdf-system-name "hyperdoc/explorer"
  ;; The subdirectory and ASDF module name containing the  text and code pages
  :subdirectory "hyperdoc-explorer"
  ;; The title of the page to be displayed as the main entry point
  :entry "HyperDoc Explorer")
