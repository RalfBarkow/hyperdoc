;;;; HyperDoc for the moldable inspector
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc/inspector)

;;
;; The HyperDoc for the moldable inspector on which HyperDoc is based
;;

(hyperdoc:defhyperdoc *hyperdoc*
    ;; The ID of the HyperDoc
    :id "moldable-inspector"
    ;; The title of the HyperDoc
    :title "Moldable inspector"
    ;; The ASDF system in which it is located
    :asdf-system-name "hyperdoc/inspector"
    ;; The subdirectory and ASDF module name containing the  text and code pages
    :subdirectory "hyperdoc-inspector"
    ;; The id of the page to be displayed as the main entry point
    :main-page-id "Moldable inspector")
