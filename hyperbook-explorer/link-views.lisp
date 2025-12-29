;;;; Views for links and backlinks
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook)

(views:defview 👀links (page page)
  (when-let (links (links-of page))
    (views:html-view :title "Links" :priority 10
      (views:add-asset-path "/hyperbook/"
                            (asdf:system-relative-pathname
                             :hyperbook
                             "assets/hyperbook/"))
      (views:include-css "/hyperbook/css/hyperbook.css")
      (views:html
        (:div :class "hyperbook-page"
              (when-let (links (page-links-of links))
                (views:html
                  (:h2 (views:esc "Pages")))
                (page-link-section
                 (mapcar #'(lambda (link)
                             (-> link thunk-of views:eval-thunk))
                         links)))
              (when-let (links (hyperbook-links-of links))
                (views:html
                  (:h2 (views:esc "HyperDocs")))
                (views:html-table (mapcar #'(lambda (link)
                                              (-> link thunk-of views:eval-thunk))
                                          links)))
              (when-let (links (web-links-of links))
                (views:html
                  (:h2 (views:esc "Web links"))
                  (:table :class "inspector-table"
                    (dolist (link (mapcar #'url-of links))
                      (views:html
                        (:tr (:td (:a :href link :target "_blank"
                                      (views:esc link)))))))))))
      (unless (and links
                   (or (page-links-of links)
                       (hyperbook-links-of links)
                       (web-links-of links)))
        (views:html (views:esc "None"))))))

(views:defview 👀backlinks (page page)
  (views:html-view :title "Backlinks" :priority 11
    (views:add-asset-path "/hyperbook/"
                          (asdf:system-relative-pathname
                           :hyperbook
                           "assets/hyperbook/"))
    (views:include-css "/hyperbook/css/hyperbook.css")
    (let* ((pages (find-backlink-sources (-> page hyperbook-of id-of)
                                         (-> page id-of)))
           (page-links (mapcar #'(lambda (page)
                                   (make-page-link page
                                                   (-> page hyperbook-of id-of)
                                                   (-> page id-of)))
                               pages)))
      (views:html
        (:div :class "hyperbook-page"
              (if page-links
                  (page-link-section pages)
                  (views:html (views:esc "None"))))))))

(defmethod page-link-section (pages)
  (let ((by-hyperdoc (make-hash-table))
        lookup-failures)
    (dolist (page pages)
      (if (typep page 'page)
          (let ((hd (-> page hyperbook-of)))
            (alexandria:ensure-gethash hd by-hyperdoc nil)
            (pushnew page (gethash hd by-hyperdoc)))
          (pushnew page lookup-failures)))
    (loop for hd being the hash-keys of by-hyperdoc
            using (hash-value pages)
          do (views:html
               (:table :class "inspector-table"
                 (:tr (:td (:i (views:object-ref hd))))
                 (:tr (:td (views:html-table pages))))))
    (when lookup-failures
      (views:html
        (:h4 "Bad links")
        (views:html-table lookup-failures)))))

