;;;; Zotero-specific inspector views for bibliography subcollections
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc/inspector)

(defmethod views:text-representation ((source hyperdoc::zotero-bibliography-source))
  (format nil "Bibliography source (~A)"
          (or (bibliography-path-string
               (hyperdoc::zotero-db-path-of
                (hyperdoc::bibliography-source-bridge-of source)))
              "no Zotero db")))

(defmethod views:title-bar-action-buttons ((source hyperdoc::zotero-bibliography-source))
  (views:html
    (views:action-button
     "Open coachmark"
     (views:thunk
       (hyperdoc::coachmark-bibliography-subcollection :source source))
     "Load the live coachmark Zotero subcollection through the bibliography HyperBook interface.")))

(views:defview 👀overview (source hyperdoc::zotero-bibliography-source)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Source system"))
                   (:td (:tt (views:esc "Zotero"))))
              (:tr (:td (views:esc "Zotero DB"))
                   (:td (:code
                         (views:esc
                          (or (bibliography-path-string
                               (hyperdoc::zotero-db-path-of
                                (hyperdoc::bibliography-source-bridge-of source)))
                              "")))))
              (:tr (:td (views:esc "Storage root"))
                   (:td (:code
                         (views:esc
                          (or (bibliography-path-string
                               (hyperdoc::zotero-storage-root-of
                                (hyperdoc::bibliography-source-bridge-of source)))
                              "")))))
              (:tr (:td (views:esc "Default collection"))
                   (:td (:tt
                         (views:esc
                          (hyperdoc::bibliography-source-default-collection-of source)))))
              (:tr (:td (views:esc "Materialization root"))
                   (:td (:code
                         (views:esc
                          (bibliography-path-string
                           (hyperdoc::bibliography-source-materialization-root-of source))))))
              (:tr (:td (views:esc "Live coachmark plan"))
                   (:td (views:object-ref
                         (hyperdoc::coachmark-bibliography-authoring-plan :source source))))))))

(defmethod views:text-representation ((collection hyperdoc::zotero-collection-hit))
  (format nil "Zotero collection ~A"
          (hyperdoc::zotero-collection-path-of collection)))

(views:defview 👀overview (collection hyperdoc::zotero-collection-hit)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Collection ID"))
                   (:td (views:object-ref
                         (hyperdoc::zotero-collection-id-of collection))))
              (:tr (:td (views:esc "Collection key"))
                   (:td (:tt
                         (views:esc
                          (hyperdoc::zotero-collection-key-of collection)))))
              (:tr (:td (views:esc "Collection name"))
                   (:td (views:esc
                         (hyperdoc::zotero-collection-name-of collection))))
              (:tr (:td (views:esc "Collection path"))
                   (:td (:tt
                         (views:esc
                          (hyperdoc::zotero-collection-path-of collection)))))
              (:tr (:td (views:esc "Library ID"))
                   (:td (views:object-ref
                         (hyperdoc::zotero-collection-library-id-of collection))))
              (:tr (:td (views:esc "Parent collection ID"))
                   (:td (views:object-ref
                         (hyperdoc::zotero-collection-parent-id-of collection))))
              (:tr (:td (views:esc "Path components"))
                   (:td (views:object-ref
                         (hyperdoc::zotero-collection-path-components-of collection))))))))

(defmethod views:text-representation ((query hyperdoc::zotero-collection-query))
  (format nil "Zotero collection query ~A (~D matches)"
          (hyperdoc::zotero-collection-query-text-of query)
          (length (hyperdoc::zotero-collection-query-matched-collections-of query))))

(views:defview 👀overview (query hyperdoc::zotero-collection-query)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr
               (:td (views:esc "Query text"))
               (:td (:tt
                     (views:esc
                      (hyperdoc::zotero-collection-query-text-of query)))))
              (:tr
               (:td (views:esc "Bridge"))
               (:td (views:object-ref
                     (hyperdoc::zotero-collection-query-bridge-of query))))
              (:tr
               (:td (views:esc "Matched collections"))
               (:td (views:object-ref
                     (hyperdoc::zotero-collection-query-matched-collections-of query))))
              (:tr
               (:td (views:esc "Raw SQL query"))
               (:td (:pre
                     (views:esc
                      (hyperdoc::zotero-query-sql-of query)))))))))
