;;;; Views for links and backlinks
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook)

(views:defview 👀links (page page)
  (when-let (links (links-of page))
    (link-view links)))

(views:defview 👀backlinks (page page)
  (let* ((pages (find-backlink-sources (-> page hyperbook-of id-of)
                                       (-> page title-of)))
         (page-links (mapcar #'(lambda (page)
                                 (make-page-link page
                                                 (-> page hyperbook-of id-of)
                                                 (-> page title-of)))
                             pages)))
    (-> (when page-links `((:page ,@page-links)))
        link-view
        (views:rename :title "Backlinks" :priority 6))))

(defun link-view (links)
  (views:html-view :title "Links" :priority 5
    (views:add-asset-path "/hyperdoc/"
                          (asdf:system-relative-pathname
                           :hyperdoc
                           "assets/hyperdoc/"))
    (views:include-css "/hyperdoc/css/hyperdoc.css")
    (views:html
      (:div :class "hyperdoc-page"
            (when-let (page-links (cdr (assoc :page links)))
              (link-view-section :page page-links))
            (when-let (hyperdoc-links (cdr (assoc :hyperdoc links)))
              (link-view-section :hyperdoc hyperdoc-links))
            (when-let (web-links (cdr (assoc :web links)))
              (link-view-section :web web-links))
            (when-let (expr-links (cdr (assoc :expr links)))
              (link-view-section :expr expr-links))))
    (unless links
      (views:html (views:esc "None"))))  )

(defgeneric link-view-section (kind links))

(defmethod link-view-section ((kind (eql :page)) links)
  (views:html
   (:h2 (views:esc "Pages"))
   (let ((by-hyperdoc (make-hash-table))
         lookup-failures)
     (dolist (page-link links)
       (let ((page (-> page-link thunk-of views:eval-thunk)))
         (if (typep page 'page)
             (let ((hd (-> page hyperbook-of)))
               (alexandria:ensure-gethash hd by-hyperdoc nil)
               (pushnew page (gethash hd by-hyperdoc)))
           (pushnew page lookup-failures))))
     (loop for hd being the hash-keys of by-hyperdoc
           using (hash-value pages)
           do (views:html
               (:table :class "inspector-table"
                       (:tr (:td (:i (views:object-ref hd))))
                       (:tr (:td (views:html-table pages))))))
     (when lookup-failures
       (views:html
        (:h4 "Bad links")
        (views:html-table lookup-failures))))))

(defmethod link-view-section ((kind (eql :hyperdoc)) links)
  (views:html
   (:h2 (views:esc "HyperDocs"))
   (views:html-table (mapcar #'(lambda (l)
                                 (-> l thunk-of views:eval-thunk))
                             links))))

(defmethod link-view-section ((kind (eql :web)) links)
  (views:html
   (:h2 (views:esc "Web links"))
   (:table :class "inspector-table"
           (dolist (link (mapcar #'url-of links))
             (views:html
              (:tr (:td (:a :href link :target "_blank"
                            (views:esc link)))))))))
