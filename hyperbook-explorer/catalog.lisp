;;;; Views on the catalog
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook)

;;
;; Title bar and items view for catalog inspectors
;;

(defmethod text-representation ((catalog catalog))
  "Registered HyperBooks")

(views:defview views:👀items (catalog catalog)
  (-> (hyperbooks-of catalog)
      copy-list
      (sort #'string< :key #'title-of)
      views:👀items
      (views:rename :title "HyperBooks" :priority 1)))

;; Ensure Playground evaluation has a real package context for the catalog.
;; Without this, the evaluator can end up trying to READ with a NIL package.
(defmethod views/standard:playground-package ((catalog catalog))
  (find-package "CL-USER"))
