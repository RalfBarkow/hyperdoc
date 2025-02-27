;;;; Views on the catalog
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

(defmethod text-representation ((catalog catalog))
  "Registered HyperDocs")

(defview 👀items (catalog catalog)
  (-> catalog
      hyperdocs
      (fset:sort #'string< :key #'title)
      👀items
      (rename :title "HyperDocs" :priority 1)))
