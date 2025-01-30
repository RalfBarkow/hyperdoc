;;;; Catalog of registered HyperDocs
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; The catalog class is defined in hyperdoc/core.
;; Views are defined here, because hyperdoc/core
;; does not depend on html-inspector-views.
;;

(defmethod text-representation ((catalog catalog))
  "Registered HyperDocs")

(defview 👀items (hdcat catalog)
  (-> hdcat
      hyperdocs
      (fset:sort #'string< :key #'title)
      👀items
      (rename :title "HyperDocs" :priority 1)))
