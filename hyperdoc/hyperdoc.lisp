;;;; HyperDoc's own HyperDoc
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; The HyperDoc for HyperDoc
;;

(defhyperdoc *hyperdoc*
  ;; The title and id of the HyperDoc
  :title "HyperDoc"
  :id :hyperdoc
  ;; The ASDF system in which it is located
  :asdf-system-name "hyperdoc"
  ;; The subdirectory and ASDF module name containing the  text and code pages
  :subdirectory "hyperdoc"
  ;; The title of the page to be displayed as the main entry point
  :entry "HyperDoc")

