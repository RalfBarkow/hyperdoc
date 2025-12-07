;;;; Views on the catalog
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; Title bar and items view for catalog inspectors
;;

(defmethod text-representation ((catalog catalog))
  "Registered HyperBooks")

(views:defview views:👀items (catalog catalog)
  (-> (hb:hyperbooks-of catalog)
    copy-list
    (sort #'string< :key #'title-of)
    views:👀items
    (views:rename :title "HyperBooks" :priority 1)))
