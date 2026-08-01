;;;; Views for links and backlinks
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook)

(views:defview 👀links (links links)
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
                                         (let ((result (-> link thunk-of views:eval-thunk)))
                                           (if (typep result 'lookup-failure)
                                               (enrich-lookup-issue
                                                (make-basic-page-lookup-issue result link))
                                               result)))
                                     links)))
                          (when-let (links (hyperbook-links-of links))
                            (views:html
                             (:h2 (views:esc "HyperDocs")))
                            (views:html-table
                             (mapcar #'(lambda (link)
                                         (let ((result (-> link thunk-of views:eval-thunk)))
                                           (if (typep result 'lookup-failure)
                                               (enrich-lookup-issue
                                                (make-basic-hyperbook-lookup-issue
                                                 result))
                                               result)))
                                     links)))
                          (when-let (links (web-links-of links))
                            (views:html
                             (:h2 (views:esc "Web links"))
                             (:table :class "inspector-table"
                                     (dolist (link (mapcar #'url-of links))
                                       (views:html
                                        (:tr
                                         (:td
                                          (if (local-file-url-p link)
                                              (views:html
                                               (:span
                                                :class "hyperbook-local-file-path"
                                                :title "Local file path (not available from this HTTP page)"
                                                (views:esc link)))
                                              (views:html
                                               (:a :href link :target "_blank"
                                                   (views:esc link)))))))))))))
                   (when (no-links? links)
                     (views:html (views:esc "None")))))

(views:defview 👀links (page page)
  (when-let (links (links-of page))
    (👀links links)))

(views:defview 👀lookup-issues (page page)
  (when-let (issues (lookup-issues-of page))
    (views:list-view issues :title "Lookup issues" :priority 12)))

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
  (let ((by-hyperbook (make-hash-table))
        lookup-issues)
    (dolist (page pages)
      (if (typep page 'page)
          (let ((hb (-> page hyperbook-of)))
            (alexandria:ensure-gethash hb by-hyperbook nil)
            (pushnew page (gethash hb by-hyperbook)))
          (pushnew page lookup-issues)))
    (loop for hb being the hash-keys of by-hyperbook
          using (hash-value pages)
          do (views:html
              (:table :class "inspector-table"
                      (:tr (:td (:i (views:object-ref hb))))
                      (:tr (:td (views:html-table pages))))))
    (when lookup-issues
      (views:html
       (:h4 "Bad links")
       (views:html-table lookup-issues)))))
