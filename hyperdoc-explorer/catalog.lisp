;;;; Views on the catalog
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; Title bar and items view for catalog inspectors
;;

(defmethod text-representation ((catalog catalog))
  "Registered HyperDocs")

(views:defview views:👀items (catalog catalog)
  (-> catalog
    hyperdocs
    (sort #'string< :key #'title)
    views:👀items
    (views:rename :title "HyperDocs" :priority 1)))
