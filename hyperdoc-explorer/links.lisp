;;;; Link and backlink views
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; Link view
;;

(views:defview 👀links (page page)
  (when-let (links (links-of page))
    (link-view links)))

(views:defview 👀backlinks (page page)
  (let* ((pages (find-backlink-sources (-> page hyperdoc-of id-of)
                                       (-> page title-of)))
         (page-links (mapcar #'(lambda (page)
                                 (list (cons (-> page hyperdoc-of title-of)
                                             (-> page title-of))
                                       page
                                       nil))
                             pages)))
    (-> (when page-links `((:page ,@page-links)))
        link-view
        (views:rename :title "Backlinks" :priority 6))))

(defun link-view (links)
  (views:html-view :title "Links" :priority 5
    (when-let (pages (cdr (assoc :page links)))
      (views:html
        (:h3 (views:esc "Pages"))
        (let ((by-hyperdoc (make-hash-table)))
          (dolist (page-link pages)
            (let* ((page (-> page-link second))
                   (hd (-> page hyperdoc-of)))
              (alexandria:ensure-gethash hd by-hyperdoc nil)
              (pushnew page (gethash hd by-hyperdoc))))
          (loop for hd being the hash-keys of by-hyperdoc
                  using (hash-value pages)
                do (views:html
                     (:h4 (views:object-ref hd))
                     (views:html-table pages))))))
    (when-let (hyperdocs (cdr (assoc :hyperdoc links)))
      (views:html
        (:h3 (views:esc "HyperDocs"))
        (views:html-table (mapcar #'second hyperdocs))))
    (when-let (web-links (cdr (assoc :web links)))
      (views:html
        (:h3 (views:esc "Web links"))
        (:table :class "inspector-table"
          (dolist (link (mapcar #'first web-links))
            (views:html
              (:tr (:td (:a :href link :target "_blank"
                            (views:esc link)))))))))
    (when-let (exprs (cdr (assoc :expr links)))
      (views:html
        (:h3 (Views:esc "Expressions"))
        (views:html-table exprs
                          :inspect #'second
                          :display (list #'first))))
    (unless links
      (views:html (views:esc "None"))))  )

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

