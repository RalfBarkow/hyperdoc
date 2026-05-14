;;;; Views for Topics hyperbook pages
;;
;;;; Part of HyperDoc
;;;; See LICENSE for licensing information.

(in-package :hyperdoc)

(defun topic-localhost-fedwiki-promotion-plan-view (plan context-label)
  (when plan
    (let ((dmx-summary
           (localhost-fedwiki-page-promotion-plan-dmx-dry-run-summary plan)))
      (views:html-view :title "Promotion plan" :priority 2
                       (views:add-asset-path "/hyperbook/"
                                             (asdf:system-relative-pathname
                                              :hyperbook
                                              "assets/hyperbook/"))
                       (views:include-css "/hyperbook/css/hyperbook.css")
                       (views:html
                        (:div :class "hyperbook-page"
                              (:h1 (views:esc "Promotion plan"))
                              (:p (views:esc context-label))
                              (:table :class "inspector-table"
                                      (:tr (:th "Plan object")
                                           (:td (views:object-ref plan)))
                                      (:tr (:th "Plan id")
                                           (:td (:tt (views:esc
                                                      (localhost-fedwiki-page-promotion-plan-id
                                                       plan)))))
                                      (:tr (:th "Source page")
                                           (:td (:tt (views:esc
                                                      (localhost-fedwiki-page-promotion-plan-source-page-id
                                                       plan)))))
                                      (:tr (:th "Page output synced")
                                           (:td (:tt (views:esc
                                                      (if (localhost-fedwiki-page-promotion-plan-page-output-synced-p
                                                           plan)
                                                          "yes"
                                                          "no")))))
                                      (:tr (:th "Snippet output synced")
                                           (:td (:tt (views:esc
                                                      (if (localhost-fedwiki-page-promotion-plan-snippet-output-synced-p
                                                           plan)
                                                          "yes"
                                                          "no")))))
                                      (:tr (:th "DMX dry-run")
                                           (:td (:tt (views:esc
                                                      (if (getf dmx-summary :available)
                                                          (format nil "~A / ~A"
                                                                  (getf dmx-summary :topic-action)
                                                                  (getf dmx-summary :topicmap-action))
                                                          "unavailable"))))))
                              (:h2 (views:esc "Open"))
                              (:ul
                               (:li (views:object-ref plan
                                                      :display "Overview"
                                                      :select "Overview"))
                               (:li (views:object-ref plan
                                                      :display "Source page"
                                                      :select "Source page"))
                               (:li (views:object-ref plan
                                                      :display "Promoted topics"
                                                      :select "Promoted topics"))
                               (:li (views:object-ref plan
                                                      :display "Page output"
                                                      :select "Page output"))
                               (:li (views:object-ref plan
                                                      :display "Snippet metadata"
                                                      :select "Snippet metadata"))
                               (:li (views:object-ref plan
                                                      :display "DMX dry-run"
                                                      :select "DMX dry-run")))))))))

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

(views:defview views:👀items (hb topics-hyperbook)
  (declare (ignore hb))
  (ensure-topic-indexes)
  (-> (loop for title in (sort (alexandria:hash-table-keys *topics-by-title*) #'string<)
            collect (find-page *topics* title :signal-error? t))
      views:👀items
      (views:rename :title "Topic pages" :priority 3)))

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
                                 (mapcar #'list references))
                                (views:html (views:esc "None"))))))))

(views:defview 👀promotion-plan (page topic-page)
  (topic-localhost-fedwiki-promotion-plan-view
   (find-localhost-fedwiki-page-promotion-plan-for-topic-page page)
   "This topic page has a direct entry point into its localhost FedWiki promotion plan, including provenance, output status, and DMX dry-run evidence."))

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
                               (mapcar #'list (references-of topic)))
                              (views:html (views:esc "None")))))))

(views:defview 👀promotion-plan (topic topic)
  (topic-localhost-fedwiki-promotion-plan-view
   (find-localhost-fedwiki-page-promotion-plan-for-topic topic)
   "This topic object has a direct entry point into its localhost FedWiki promotion plan, including provenance, output status, and DMX dry-run evidence."))
