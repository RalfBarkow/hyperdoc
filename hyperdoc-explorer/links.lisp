;;;; Link and backlink views
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; Link view
;;

(views:defview 👀links (page page)
  (when-let (links (links-of page))
    (views:html-view :title "Links" :priority 5
      (when-let (local-pages (cdr (assoc :page links)))
        (views:html
          (:details :open t
                    (:summary "Local pages")
                    (views:html-table (mapcar #'second local-pages)))))
      (when-let (hyperdocs (cdr (assoc :hyperdoc links)))
        (views:html
          (:details :open t
                    (:summary "HyperDocs")
                    (views:html-table hyperdocs
                                      :display (list #'first)
                                      :inspect #'second))))
      (when-let (hyperdoc-pages (cdr (assoc :hyperdoc-page links)))
        (views:html
          (:details :open t
                    (:summary "HyperDoc pages")
                    (views:html-table hyperdoc-pages
                                      :columns '("HyperDoc" "Page")
                                      :display (list #'(lambda (spec)
                                                         (-> spec first first
                                                                  find-hyperdoc))
                                                     #'second)
                                      :inspect-items :by-column))))
      (when-let (exprs (cdr (assoc :expr links)))
        (views:html
          (:details :open t
                    (:summary "Expressions")
                    (views:html-table exprs
                                      :inspect #'second
                                      :columns '("Expr" "Package")
                                      :display (list #'caar #'cdar)))))
      (when-let (web-links (cdr (assoc :web links)))
        (views:html
          (:details :open t
                    (:summary "Web links")
                    (:table :class "inspector-table"
                      (dolist (link (mapcar #'first web-links))
                        (views:html
                          (:tr (:td (:a :href link :target "_blank"
                                        (views:esc link)))))))))))))

(views:defview 👀backlinks (page page)
  (-> (find-backlink-sources (-> page hyperdoc-of id-of) (-> page title-of))
      views:👀items
      (views:rename :title "Backlinks" :priority 6)))

;;
;; Find links to pages
;;

(defmethod find-link-sources ((hd hyperdoc) hyperdoc-id page-title)
  (loop for page being the hash-values of (pages-of hd)
        append (find-link-sources page hyperdoc-id page-title)))

(defmethod find-link-sources ((page page) hyperdoc-id page-title)
  (let ((links (links-of page))
        (link-sources ()))
    (dolist (page-link (and (eq hyperdoc-id (-> page hyperdoc-of id-of))
                            (cdr (assoc :page links))))
      (let ((linked-page (second page-link)))
        (when (equal page-title (title-of linked-page))
          (pushnew page link-sources :test #'eq))))
    (dolist (hyperdoc-page-link (cdr (assoc :hyperdoc-page links)))
      (let* ((linked-page (second hyperdoc-page-link))
             (linked-hyperdoc (hyperdoc-of linked-page)))
        (when (and (eq hyperdoc-id (id-of linked-hyperdoc))
                   (equal page-title (title-of linked-page)))
          (pushnew page link-sources :test #'eq))))
    link-sources))

