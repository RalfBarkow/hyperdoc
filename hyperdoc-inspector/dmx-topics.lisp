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

(defun raw-object-field (object key)
  (and (hash-table-p object)
       (gethash key object)))

(defun raw-object-keys (object)
  (when (hash-table-p object)
    (sort (alexandria:hash-table-keys object) #'string<)))

(defun raw-object-children-keys (object)
  (raw-object-keys (raw-object-field object "children")))

(defun relation-seq (relations)
  (cond
    ((null relations) '())
    ((vectorp relations) (coerce relations 'list))
    ((listp relations) relations)
    (t (list relations))))

(defun yes/no-label (value)
  (if value "yes" "no"))

(defun dmx-diagnostic-status-label (status)
  (case status
    (:ok "OK")
    (:missing-workspace-assignment "missing workspace assignment")
    (:in-topicmap-but-unassigned "in topicmap but unassigned")
    (:foreign-object "foreign object")
    (otherwise
     (string-downcase (format nil "~A" status)))))

(defun render-maybe-code (value)
  (if value
      (views:html (:code (views:esc (format nil "~A" value))))
      (views:html (:span :style "opacity: 0.55;" "n/a"))))

(defun render-dmx-diagnostic-url (url)
  (if url
      (views:html
        (:a :href url
            :target "_blank"
            (:code (views:esc url))))
      (views:html
        (:span :style "opacity: 0.55;" "n/a"))))

(defun render-workspace-reference (page diagnostics)
  (let ((workspace-id (hyperdoc::dmx-topic-diagnostics-workspace-id diagnostics))
        (workspace-title (hyperdoc::dmx-topic-diagnostics-workspace-title diagnostics)))
    (if workspace-id
        (views:object-ref
         (hyperdoc::make-dmx-topic-proxy :topic-id workspace-id
                                         :topicmap-id (hyperdoc::dmx-topicmap-id-of page))
         :display (format nil "~D (~A)"
                          workspace-id
                          (or workspace-title "workspace")))
        (views:html (:span :style "opacity: 0.55;" "n/a")))))

(defun render-topicmap-memberships (page diagnostics)
  (let ((memberships (hyperdoc::dmx-topic-diagnostics-topicmap-memberships diagnostics))
        (selected-topicmap-id (hyperdoc::dmx-topicmap-id-of page)))
    (if memberships
        (views:html
          (:table :class "inspector-table"
                  (:tr (:th (views:esc "Topicmap"))
                       (:th (views:esc "Assoc ID"))
                       (:th (views:esc "Selected?")))
                  (dolist (membership memberships)
                    (let ((topicmap-id (raw-object-field membership "id"))
                          (topicmap-title (or (raw-object-field membership "value")
                                              "topicmap"))
                          (assoc-id (relation-assoc-id membership)))
                      (views:html
                        (:tr (:td (views:object-ref
                                   (hyperdoc::make-dmx-topicmap-proxy topicmap-id)
                                   :display (format nil "~D (~A)"
                                                    topicmap-id
                                                    topicmap-title)))
                             (:td (render-maybe-code assoc-id))
                             (:td (:tt (views:esc
                                        (yes/no-label
                                         (eql topicmap-id
                                              selected-topicmap-id))))))))))
        (views:html (:span :style "opacity: 0.55;" "none"))))))

(defmethod views:text-representation ((page hyperdoc::dmx-topic-proxy))
  (format nil "DMX topic ~D (topicmap ~D)"
          (hyperdoc::dmx-topic-id-of page)
          (hyperdoc::dmx-topicmap-id-of page)))

(defmethod views:title-bar-action-buttons ((page hyperdoc::dmx-topic-proxy))
  (views:html
    (views:action-button "Reload"
                         (views:thunk
                           (hyperdoc::ensure-dmx-topic-data page :force? t)
                           (hyperdoc::ensure-dmx-workspace-data page :force? t)
                           (hyperdoc::ensure-dmx-topicmap-memberships page :force? t)
                           (hyperdoc::ensure-dmx-topicmap-data page :force? t)
                           (hyperdoc::ensure-dmx-related-topics page :force? t)
                           (hyperdoc::ensure-dmx-topic-diagnostics page :force? t)
                           t))
    " "
    (views:action-button html-inspector-views/standard:*icon-open-external*
                         (views:thunk
                           (clog:open-browser
                            :url (hyperdoc::dmx-topicmap-webclient-url page)))
                         nil)))

(views:defview 👀overview (page hyperdoc::dmx-topic-proxy)
  (hyperdoc::ensure-dmx-topic-diagnostics page)
  (views:html-view :title "Overview" :priority 1
    (let ((diagnostics (hyperdoc::dmx-diagnostics-of page)))
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
                     (:td (:a :href (hyperdoc::dmx-topicmap-webclient-url page)
                              :target "_blank"
                              (views:esc (hyperdoc::dmx-topicmap-webclient-url page)))))
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
                (when diagnostics
                  (views:html
                    (:tr (:td (views:esc "Workspace assignment"))
                         (:td (render-workspace-reference page diagnostics)))
                    (:tr (:td (views:esc "Selected topicmap membership"))
                         (:td (:tt (views:esc
                                    (yes/no-label
                                     (hyperdoc::dmx-topic-diagnostics-selected-topicmap-membership-p
                                      diagnostics))))))
                    (:tr (:td (views:esc "Diagnostics status"))
                         (:td (:tt (views:esc
                                    (dmx-diagnostic-status-label
                                     (hyperdoc::dmx-topic-diagnostics-status
                                      diagnostics))))))))
                (when-let (condition (hyperdoc::dmx-load-error-of page))
                  (views:html
                    (:tr (:td (views:esc "Load error"))
                         (:td (views:object-ref condition))))))))))

(views:defview 👀workspace-diagnostics (page hyperdoc::dmx-topic-proxy)
  (hyperdoc::ensure-dmx-topic-diagnostics page)
  (views:html-view :title "Workspace diagnostics" :priority 2
    (let ((diagnostics (hyperdoc::dmx-diagnostics-of page)))
      (if diagnostics
          (views:html
            (:p (views:esc
                 "Workspace assignment and topicmap placement are distinct layers. This view keeps them separate and shows the read-only evidence used for the diagnosis."))
            (:table :class "inspector-table"
                    (:tr (:td (views:esc "Topic ID"))
                         (:td (render-maybe-code
                               (hyperdoc::dmx-topic-diagnostics-topic-id diagnostics))))
                    (:tr (:td (views:esc "URI"))
                         (:td (render-maybe-code
                               (hyperdoc::dmx-topic-diagnostics-topic-uri diagnostics))))
                    (:tr (:td (views:esc "Topic type"))
                         (:td (render-maybe-code
                               (hyperdoc::dmx-topic-diagnostics-topic-type-uri diagnostics))))
                    (:tr (:td (views:esc "Title/value"))
                         (:td (views:esc
                               (or (hyperdoc::dmx-topic-diagnostics-topic-title diagnostics)
                                   "n/a"))))
                    (:tr (:td (views:esc "Workspace assignment"))
                         (:td (render-workspace-reference page diagnostics)))
                    (:tr (:td (views:esc "Workspace owner"))
                         (:td (render-maybe-code
                               (hyperdoc::dmx-topic-diagnostics-workspace-owner diagnostics))))
                    (:tr (:td (views:esc "Topicmap memberships"))
                         (:td (render-topicmap-memberships page diagnostics)))
                    (:tr (:td (views:esc "Ownership class"))
                         (:td (:tt (views:esc
                                    (format nil "~(~A~)"
                                            (hyperdoc::dmx-topic-diagnostics-ownership-class
                                             diagnostics))))))
                    (:tr (:td (views:esc "HyperDoc-owned"))
                         (:td (:tt (views:esc
                                    (yes/no-label
                                     (hyperdoc::dmx-topic-diagnostics-hyperdoc-owned-p
                                      diagnostics))))))
                    (:tr (:td (views:esc "Ownership reason"))
                         (:td (views:esc
                               (or (hyperdoc::dmx-topic-diagnostics-ownership-reason
                                    diagnostics)
                                   "n/a"))))
                    (:tr (:td (views:esc "Note key"))
                         (:td (render-maybe-code
                               (hyperdoc::dmx-topic-diagnostics-note-key diagnostics))))
                    (:tr (:td (views:esc "Handover key"))
                         (:td (render-maybe-code
                               (hyperdoc::dmx-topic-diagnostics-handover-key
                                diagnostics))))
                    (:tr (:td (views:esc "Derived status"))
                         (:td (:tt (views:esc
                                    (dmx-diagnostic-status-label
                                     (hyperdoc::dmx-topic-diagnostics-status
                                      diagnostics))))))
                    (:tr (:td (views:esc "Repair needed"))
                         (:td (:tt (views:esc
                                    (yes/no-label
                                     (hyperdoc::dmx-topic-diagnostics-repair-needed-p
                                      diagnostics))))))
                    (:tr (:td (views:esc "Status reason"))
                         (:td (views:esc
                               (or (hyperdoc::dmx-topic-diagnostics-status-reason
                                    diagnostics)
                                   "n/a")))))
            (:h4 "Source endpoints")
            (:table :class "inspector-table"
                    (:tr (:th (views:esc "Surface"))
                         (:th (views:esc "Endpoint")))
                    (loop for (label . url)
                            in (hyperdoc::dmx-topic-diagnostics-source-endpoints
                                diagnostics)
                          do (views:html
                               (:tr (:td (views:esc label))
                                    (:td (render-dmx-diagnostic-url url))))))
            (:h4 "Diagnostic readouts")
            (:table :class "inspector-table"
                    (:tr (:td (views:esc "Workspace JSON"))
                         (:td (views:object-ref
                               (or (hyperdoc::dmx-workspace-data-of page)
                                   "not assigned"))))
                    (:tr (:td (views:esc "Workspace owner"))
                         (:td (views:object-ref
                               (or (hyperdoc::dmx-workspace-owner-of page)
                                   "not assigned"))))
                    (:tr (:td (views:esc "Topicmap memberships JSON"))
                         (:td (views:object-ref
                               (or (hyperdoc::dmx-topicmap-memberships-of page)
                                   #()))))
                    (:tr (:td (views:esc "Derived diagnostics object"))
                         (:td (views:object-ref diagnostics)))))
          (views:html
            (:p (views:esc
                 "Diagnostics could not be derived from the current read-only DMX fetches."))
            (if-let (condition (hyperdoc::dmx-load-error-of page))
              (views:object-ref condition)
              (views:html (:span :style "opacity: 0.55;" "No diagnostic data available."))))))))

(views:defview 👀raw-fetched-data (page hyperdoc::dmx-topic-proxy)
  (hyperdoc::ensure-dmx-topic-diagnostics page)
  (hyperdoc::ensure-dmx-related-topics page)
  (views:html-view :title "Raw fetched data" :priority 3
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Topic JSON"))
                   (:td (views:object-ref
                         (or (hyperdoc::dmx-topic-data-of page)
                             (hyperdoc::dmx-load-error-of page)
                             "not loaded"))))
              (:tr (:td (views:esc "Workspace JSON"))
                   (:td (views:object-ref
                         (or (hyperdoc::dmx-workspace-data-of page)
                             "not loaded"))))
              (:tr (:td (views:esc "Topicmap memberships JSON"))
                   (:td (views:object-ref
                         (or (hyperdoc::dmx-topicmap-memberships-of page)
                             #()))))
              (:tr (:td (views:esc "Workspace owner"))
                   (:td (views:object-ref
                         (or (hyperdoc::dmx-workspace-owner-of page)
                             "not loaded"))))
              (:tr (:td (views:esc "Topicmap core-topic JSON"))
                   (:td (views:object-ref
                         (or (hyperdoc::dmx-topicmap-data-of page)
                             (hyperdoc::dmx-load-error-of page)
                             "not loaded"))))
              (:tr (:td (views:esc "Topicmap core-topic source"))
                   (:td (:a :href (hyperdoc::dmx-topicmap-core-topic-url page)
                            :target "_blank"
                            (:code
                             (views:esc
                              (hyperdoc::dmx-topicmap-core-topic-url page))))))
              (:tr (:td (views:esc "Related topics JSON"))
                   (:td (views:object-ref
                         (or (hyperdoc::dmx-related-topics-of page)
                             (hyperdoc::dmx-load-error-of page)
                             "not loaded"))))))))

(views:defview 👀topicmap-core-topic (page hyperdoc::dmx-topic-proxy)
  (hyperdoc::ensure-dmx-topicmap-data page)
  (views:html-view :title "Topicmap core topic" :priority 4
    (let ((topicmap-data (hyperdoc::dmx-topicmap-data-of page))
          (source-url (hyperdoc::dmx-topicmap-core-topic-url page))
          (condition (hyperdoc::dmx-load-error-of page)))
      (views:html
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Source URL"))
                     (:td (:a :href source-url
                              :target "_blank"
                              (:code (views:esc source-url)))))
                (:tr (:td (views:esc "Raw object"))
                     (:td (views:object-ref
                           (or topicmap-data
                               condition
                               "not loaded"))))
                (when topicmap-data
                  (views:html
                    (:tr (:td (views:esc "ID"))
                         (:td (views:object-ref
                               (raw-object-field topicmap-data "id"))))
                    (:tr (:td (views:esc "Type URI"))
                         (:td (views:object-ref
                               (raw-object-field topicmap-data "typeUri"))))
                    (:tr (:td (views:esc "Value"))
                         (:td (views:object-ref
                               (raw-object-field topicmap-data "value"))))
                    (:tr (:td (views:esc "Top-level keys"))
                         (:td (views:object-ref
                               (raw-object-keys topicmap-data))))
                    (:tr (:td (views:esc "Children keys"))
                         (:td (views:object-ref
                               (raw-object-children-keys topicmap-data))))))
                (when condition
                  (views:html
                    (:tr (:td (views:esc "Load error"))
                         (:td (views:object-ref condition))))))))))

(views:defview 👀relations (page hyperdoc::dmx-topic-proxy)
  (hyperdoc::ensure-dmx-related-topics page)
  (views:html-view :title "Relations" :priority 5
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
  (views:html-view :title "External" :priority 6
    (views:html
      (:a :href (hyperdoc::dmx-topicmap-webclient-url page)
          :target "_blank"
          (views:esc "Open topicmap entry in DMX webclient")))))
