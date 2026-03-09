;;;; Inspector views for DMX-backed HyperDoc topic proxies
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc/inspector)

(defun relation-field (relation key)
  (and (hash-table-p relation)
       (gethash key relation)))

(defun relation-assoc-id (relation)
  (let ((assoc (relation-field relation "assoc")))
    (and (hash-table-p assoc)
         (gethash "id" assoc))))

(defmethod views:text-representation ((page hyperdoc::dmx-topic-proxy))
  (format nil "DMX topic ~D (topicmap ~D)"
          (hyperdoc::dmx-topic-id-of page)
          (hyperdoc::dmx-topicmap-id-of page)))

(defmethod views:title-bar-action-buttons ((page hyperdoc::dmx-topic-proxy))
  (views:html
    (views:action-button "Reload"
                         (views:thunk
                           (hyperdoc::ensure-dmx-topic-data page :force? t)
                           (hyperdoc::ensure-dmx-topicmap-data page :force? t)
                           (hyperdoc::ensure-dmx-related-topics page :force? t)
                           t))
    " "
    (views:action-button html-inspector-views/standard:*icon-open-external*
                         (views:thunk
                           (clog:open-browser
                            :url (hyperdoc::dmx-webclient-url page)))
                         nil)))

(views:defview 👀overview (page hyperdoc::dmx-topic-proxy)
  (hyperdoc::ensure-dmx-topic-data page)
  (hyperdoc::ensure-dmx-topicmap-data page)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "HyperBook"))
                   (:td (views:object-ref (hyperbook:hyperbook-of page))))
              (:tr (:td (views:esc "Base URL"))
                   (:td (:code (views:esc (hyperdoc::dmx-base-url-of
                                           (hyperbook:hyperbook-of page))))))
              (:tr (:td (views:esc "Topicmap ID"))
                   (:td (views:object-ref (hyperdoc::dmx-topicmap-id-of page))))
              (:tr (:td (views:esc "Topic ID"))
                   (:td (views:object-ref (hyperdoc::dmx-topic-id-of page))))
              (:tr (:td (views:esc "DMX webclient"))
                   (:td (:a :href (hyperdoc::dmx-webclient-url page)
                            :target "_blank"
                            (views:esc (hyperdoc::dmx-webclient-url page)))))
              (when-let (topic-data (hyperdoc::dmx-topic-data-of page))
                (views:html
                  (:tr (:td (views:esc "Type URI"))
                       (:td (views:object-ref (gethash "typeUri" topic-data))))
                  (:tr (:td (views:esc "Value"))
                       (:td (views:object-ref (gethash "value" topic-data))))
                  (:tr (:td (views:esc "Children keys"))
                       (:td (views:object-ref
                             (let ((children (gethash "children" topic-data)))
                               (if (hash-table-p children)
                                   (sort (alexandria:hash-table-keys children)
                                         #'string<)
                                   nil)))))))
              (when-let (condition (hyperdoc::dmx-load-error-of page))
                (views:html
                  (:tr (:td (views:esc "Load error"))
                       (:td (views:object-ref condition)))))))))

(views:defview 👀raw-fetched-data (page hyperdoc::dmx-topic-proxy)
  (hyperdoc::ensure-dmx-topic-data page)
  (hyperdoc::ensure-dmx-topicmap-data page)
  (hyperdoc::ensure-dmx-related-topics page)
  (views:html-view :title "Raw fetched data" :priority 2
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Topic JSON"))
                   (:td (views:object-ref
                         (or (hyperdoc::dmx-topic-data-of page)
                             (hyperdoc::dmx-load-error-of page)
                             "not loaded"))))
              (:tr (:td (views:esc "Topicmap JSON"))
                   (:td (views:object-ref
                         (or (hyperdoc::dmx-topicmap-data-of page)
                             (hyperdoc::dmx-load-error-of page)
                             "not loaded"))))
              (:tr (:td (views:esc "Related topics JSON"))
                   (:td (views:object-ref
                         (or (hyperdoc::dmx-related-topics-of page)
                             (hyperdoc::dmx-load-error-of page)
                             "not loaded"))))))))

(views:defview 👀relations (page hyperdoc::dmx-topic-proxy)
  (hyperdoc::ensure-dmx-related-topics page)
  (views:html-view :title "Relations" :priority 3
    (let ((relations (hyperdoc::dmx-related-topics-of page)))
      (if (and relations (> (length relations) 0))
          (views:html
            (:table :class "inspector-table"
                    (:tr (:th (views:esc "Topic ID"))
                         (:th (views:esc "Type"))
                         (:th (views:esc "Value"))
                         (:th (views:esc "Assoc ID")))
                    (loop for relation across relations
                          do (views:html
                               (:tr (:td (views:object-ref
                                          (relation-field relation "id")))
                                    (:td (views:object-ref
                                          (relation-field relation "typeUri")))
                                    (:td (views:object-ref
                                          (relation-field relation "value")))
                                    (:td (views:object-ref
                                          (relation-assoc-id relation))))))))
          (if-let (condition (hyperdoc::dmx-load-error-of page))
            (views:object-ref condition)
            (views:html (views:esc "No related topics returned by DMX")))))))

(views:defview 👀external (page hyperdoc::dmx-topic-proxy)
  (views:html-view :title "External" :priority 4
    (views:html
      (:a :href (hyperdoc::dmx-webclient-url page)
          :target "_blank"
          (views:esc "Open topic in DMX webclient")))))
