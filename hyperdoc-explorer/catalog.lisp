;;;; Views on the catalog
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

(defmethod text-representation ((catalog catalog))
  "Registered HyperDocs")

(defview 👀items (catalog catalog)
  (-> catalog
      hyperdocs
      (sort #'string< :key #'title)
      👀items
      (rename :title "HyperDocs" :priority 1)))

;; Add a Catalog view to HyperDoc objects

(defview 👀catalog (hd hyperdoc)
  (ensure-pages-loaded hd)
  (-> *catalog*
      👀items
      (rename :title "Catalog" :priority 5)))
