;;;; HyperDoc Server's HyperDoc
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc/server)

;;
;; The HyperDoc for HyperDoc
;;

(hyperdoc:defhyperdoc *hyperdoc*
  ;; The title of the HyperDoc
  :title "HyperDoc Server"
  ;; The ASDF system in which it is located
  :asdf-system-name "hyperdoc/server"
  ;; The subdirectory and ASDF module name containing the  text and code pages
  :subdirectory "hyperdoc-server"
  ;; The title of the page to be displayed as the main entry point
  :entry "HyperDoc Server")
