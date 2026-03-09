;;;; Views for Topics hyperbook pages
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(views:defview 👀overview (hb topics-hyperbook)
  (declare (ignore hb))
  (views:html-view :title "Overview" :priority 1
    (views:add-asset-path "/hyperbook/"
                          (asdf:system-relative-pathname
                           :hyperbook
                           "assets/hyperbook/"))
    (views:include-css "/hyperbook/css/hyperbook.css")
    (views:html
      (:div :class "hyperbook-page"
            (:h1 (views:esc "Topics"))
            (:p (views:esc "Each page in this hyperbook wraps one HyperDoc topic object."))
            (:p (views:esc "Page to topic relations are authored explicitly in HyperDoc page markup through links to this hyperbook. Topic to page relations are derived automatically through backlinks."))
            (:p (views:esc "Optional editorial references remain available on topic objects, but they are not the primary mechanism for internal topic-to-page association."))))))

(views:defview views:👀content (page topic-page)
  (let* ((topic (topic-of page))
         (backlinks (find-backlink-sources "topics" (id-of page)))
         (references (references-of topic)))
    (views:html-view :title "Content" :priority 1
      (views:add-asset-path "/hyperbook/"
                            (asdf:system-relative-pathname
                             :hyperbook
                             "assets/hyperbook/"))
      (views:include-css "/hyperbook/css/hyperbook.css")
      (views:html
        (:div :class "hyperbook-page"
              (:h1 (views:esc (title-of topic)))
              (:p (views:esc (summary-of topic)))
              (:table :class "inspector-table"
                      (:tr (:th "Stable key")
                           (:td (:tt (views:esc (id-of topic)))))
                      (:tr (:th "Topic object")
                           (:td (views:object-ref topic))))
              (:h2 (views:esc "Referencing pages"))
              (if backlinks
                  (views:html-table backlinks)
                  (views:html (views:esc "None")))
              (:h2 (views:esc "Editorial references"))
              (if references
                  (views:html-table
                   (mapcar (lambda (reference)
                             (list reference))
                           references))
                  (views:html (views:esc "None"))))))))

(views:defview 👀topic-object (page topic-page)
  (let ((topic (topic-of page)))
    (views:html-view :title "Topic object" :priority 5
      (views:add-asset-path "/hyperbook/"
                            (asdf:system-relative-pathname
                             :hyperbook
                             "assets/hyperbook/"))
      (views:include-css "/hyperbook/css/hyperbook.css")
      (views:html
        (:div :class "hyperbook-page"
              (:h1 (views:esc "Topic object"))
              (:p (views:object-ref topic)))))))

(views:defview views:👀content (topic topic)
  (views:html-view :title "Topic" :priority 1
    (views:add-asset-path "/hyperbook/"
                          (asdf:system-relative-pathname
                           :hyperbook
                           "assets/hyperbook/"))
    (views:include-css "/hyperbook/css/hyperbook.css")
    (views:html
      (:div :class "hyperbook-page"
            (:h1 (views:esc (title-of topic)))
            (:p (views:esc (summary-of topic)))
            (:table :class "inspector-table"
                    (:tr (:th "Stable key")
                         (:td (:tt (views:esc (id-of topic)))))
                    (:tr (:th "Topic page")
                         (:td (views:object-ref
                               (find-page *topics* (title-of topic) :signal-error? t)))))
            (:h2 (views:esc "Editorial references"))
            (if (references-of topic)
                (views:html-table
                 (mapcar (lambda (reference)
                           (list reference))
                         (references-of topic)))
                (views:html (views:esc "None")))))))
