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

(defun dmx-diagnostic-ownership-label (diagnostics)
  (format nil "~(~A~)"
          (hyperdoc::dmx-topic-diagnostics-ownership-class diagnostics)))

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

(defun dmx-repair-console-auth-mode-label (mode)
  (case (hyperdoc::normalize-http-dmx-import-auth-mode
         mode
         'dmx-repair-console-auth-mode-label)
    (:basic "username/password")
    (:header "authorization header")
    (:token "bearer token")))

(defun dmx-repair-console-outcome-label (result)
  (cond
    ((not (getf result :success-p))
     "error")
    ((getf result :dry-run)
     "dry-run")
    ((eql (getf result :workspace-action) :already-assigned)
     "already assigned")
    ((and (eql (getf result :result-workspace-id)
               hyperdoc::*dmx-context-window-workspace-id*)
          (getf result :result-in-topicmap-p))
     "verified")
    (t
     "completed")))

(defun dmx-repair-console-eligible-p (diagnostics)
  (and diagnostics
       (hyperdoc::dmx-topic-diagnostics-repair-needed-p diagnostics)
       (hyperdoc::dmx-topic-diagnostics-hyperdoc-owned-p diagnostics)))

(defun ensure-dmx-topic-proxy-readbacks (page)
  (hyperdoc::ensure-dmx-topic-data page :force? t)
  (hyperdoc::ensure-dmx-workspace-data page :force? t)
  (hyperdoc::ensure-dmx-topicmap-memberships page :force? t)
  (hyperdoc::ensure-dmx-topicmap-data page :force? t)
  (hyperdoc::ensure-dmx-topic-diagnostics page :force? t)
  page)

(defun make-explicit-dmx-repair-client (page &key auth-mode username password
                                               authorization-header auth-token)
  (hyperdoc::make-http-dmx-import-client-from-explicit-auth
   :base-url (hyperdoc::dmx-base-url-of (hyperbook:hyperbook-of page))
   :workspace-id hyperdoc::*dmx-context-window-workspace-id*
   :auth-mode auth-mode
   :username username
   :password password
   :authorization-header authorization-header
   :auth-token auth-token
   :verbose nil))

(defun sanitize-dmx-repair-result (topic-id diagnostics result
                                    &key dry-run auth-mode success-p message)
  (list :topic-id topic-id
        :topic-title (or (getf result :topic-title)
                         (and diagnostics
                              (hyperdoc::dmx-topic-diagnostics-topic-title
                               diagnostics))
                         "n/a")
        :topic-uri (or (getf result :topic-uri)
                       (and diagnostics
                            (hyperdoc::dmx-topic-diagnostics-topic-uri
                             diagnostics)))
        :ownership-class
        (or (getf result :ownership-class)
            (and diagnostics
                 (hyperdoc::dmx-topic-diagnostics-ownership-class diagnostics)))
        :auth-mode
        (hyperdoc::normalize-http-dmx-import-auth-mode
         auth-mode
         'sanitize-dmx-repair-result)
        :dry-run (and dry-run t)
        :success-p (and success-p t)
        :workspace-action (getf result :workspace-action)
        :result-workspace-id (getf result :result-workspace-id)
        :result-workspace-title (getf result :result-workspace-title)
        :result-in-topicmap-p (getf result :result-in-topicmap-p)
        :message message))

(defun repair-topic-proxy-with-client (page client &key dry-run auth-mode)
  (hyperdoc::ensure-dmx-topic-diagnostics page :force? t)
  (let* ((topic-id (hyperdoc::dmx-topic-id-of page))
         (diagnostics (hyperdoc::dmx-diagnostics-of page))
         (result
           (handler-case
               (let* ((execution
                        (hyperdoc::execute-dmx-workspace-topic-workspace-assignment-repair
                         topic-id
                         :workspace-id hyperdoc::*dmx-context-window-workspace-id*
                         :workspace-topicmap-id hyperdoc::*dmx-context-window-topicmap-id*
                         :client client
                         :dry-run dry-run))
                      (message
                        (cond
                          (dry-run
                           "Dry-run completed; the guarded repair path is ready but no mutation was performed.")
                          ((eql (getf execution :workspace-action) :already-assigned)
                           "The topic already had the requested workspace assignment.")
                          (t
                           "Workspace assignment repair completed and read back live."))))
                 (sanitize-dmx-repair-result topic-id
                                             diagnostics
                                             execution
                                             :dry-run dry-run
                                             :auth-mode auth-mode
                                             :success-p t
                                             :message message))
             (error (condition)
               (sanitize-dmx-repair-result topic-id
                                           diagnostics
                                           nil
                                           :dry-run dry-run
                                           :auth-mode auth-mode
                                           :success-p nil
                                           :message (princ-to-string condition))))))
    (handler-case
        (ensure-dmx-topic-proxy-readbacks page)
      (error (condition)
        (setf result
              (append result
                      (list :message
                            (format nil
                                    "~A Readback refresh failed: ~A"
                                    (or (getf result :message) "")
                                    condition))))))
    (setf (hyperdoc::dmx-repair-results-of page) (list result))
    result))

(defun repair-topic-proxy-with-explicit-auth (page &key dry-run auth-mode
                                                     username password
                                                     authorization-header
                                                     auth-token)
  (let ((client (make-explicit-dmx-repair-client
                 page
                 :auth-mode auth-mode
                 :username username
                 :password password
                 :authorization-header authorization-header
                 :auth-token auth-token)))
    (repair-topic-proxy-with-client page
                                    client
                                    :dry-run dry-run
                                    :auth-mode auth-mode)))

(defun repair-workspace-triage-topic-ids (page)
  (hyperdoc::ensure-dmx-workspace-repair-triage page :force? t)
  (mapcar #'hyperdoc::dmx-topic-id-of
          (hyperdoc::dmx-repair-topic-proxies-of page)))

(defun find-repair-triage-proxy (page topic-id)
  (find topic-id
        (hyperdoc::dmx-repair-topic-proxies-of page)
        :key #'hyperdoc::dmx-topic-id-of
        :test #'eql))

(defun repair-triage-topic-with-client (page topic-id client &key dry-run auth-mode)
  (let* ((proxy (or (find-repair-triage-proxy page topic-id)
                    (hyperdoc::make-dmx-shared-workspace-topic-proxy
                     topic-id
                     :topicmap-id (hyperdoc::dmx-topicmap-id-of page)
                     :base-url (hyperdoc::dmx-base-url-of
                                (hyperbook:hyperbook-of page))))))
    (repair-topic-proxy-with-client proxy
                                    client
                                    :dry-run dry-run
                                    :auth-mode auth-mode)))

(defun repair-workspace-triage-backlog-with-client (page client &key dry-run auth-mode)
  (let* ((topic-ids (repair-workspace-triage-topic-ids page))
         (results (loop for topic-id in topic-ids
                        collect (repair-triage-topic-with-client page
                                                                 topic-id
                                                                 client
                                                                 :dry-run dry-run
                                                                 :auth-mode auth-mode))))
    (setf (hyperdoc::dmx-repair-results-of page) results
          (hyperdoc::dmx-repair-summary-of page)
          (list :count (length results)
                :dry-run (and dry-run t)
                :success-count (count-if (lambda (result)
                                           (getf result :success-p))
                                         results)
                :error-count (count-if-not (lambda (result)
                                             (getf result :success-p))
                                           results)))
    (handler-case
        (hyperdoc::ensure-dmx-workspace-repair-triage page :force? t)
      (error (condition)
        (setf (hyperdoc::dmx-repair-summary-of page)
              (append (hyperdoc::dmx-repair-summary-of page)
                      (list :message
                            (format nil
                                    "Repair triage refresh failed: ~A"
                                    condition))))))
    results))

(defun repair-workspace-triage-backlog-with-explicit-auth
    (page &key dry-run auth-mode username password authorization-header auth-token)
  (let ((client (make-explicit-dmx-repair-client
                 page
                 :auth-mode auth-mode
                 :username username
                 :password password
                 :authorization-header authorization-header
                 :auth-token auth-token)))
    (repair-workspace-triage-backlog-with-client page
                                                 client
                                                 :dry-run dry-run
                                                 :auth-mode auth-mode)))

(defun render-dmx-repair-results-table (results &key topicmap-id)
  (if results
      (views:html
        (:table :class "inspector-table"
                (:tr (:th (views:esc "Topic"))
                     (:th (views:esc "Title/value"))
                     (:th (views:esc "Auth mode"))
                     (:th (views:esc "Dry-run"))
                     (:th (views:esc "Workspace readback"))
                     (:th (views:esc "In topicmap 919822"))
                     (:th (views:esc "Outcome"))
                     (:th (views:esc "Message")))
                (loop for result in results
                      do (let ((topic-id (getf result :topic-id))
                               (workspace-id (getf result :result-workspace-id))
                               (workspace-title (getf result :result-workspace-title)))
                           (views:html
                             (:tr
                              (:td
                               (if topic-id
                                   (views:object-ref
                                    (hyperdoc::make-dmx-shared-workspace-topic-proxy
                                     topic-id
                                     :topicmap-id (or topicmap-id
                                                      hyperdoc::*dmx-context-window-topicmap-id*))
                                    :display (format nil "~D" topic-id))
                                   (render-maybe-code nil)))
                              (:td (views:esc (or (getf result :topic-title) "n/a")))
                              (:td (:tt (views:esc
                                         (dmx-repair-console-auth-mode-label
                                          (getf result :auth-mode)))))
                              (:td (:tt (views:esc
                                         (yes/no-label (getf result :dry-run)))))
                              (:td
                               (if workspace-id
                                   (views:esc (format nil "~D (~A)"
                                                      workspace-id
                                                      (or workspace-title "workspace")))
                                   (views:html (:span :style "opacity: 0.55;" "n/a"))))
                              (:td (:tt (views:esc
                                         (yes/no-label
                                          (getf result :result-in-topicmap-p)))))
                              (:td (:tt (views:esc
                                         (dmx-repair-console-outcome-label result))))
                              (:td (views:esc (or (getf result :message) "n/a")))))))))
      (views:html (:span :style "opacity: 0.55;" "No repair attempts recorded yet."))))

(defmethod views:text-representation ((page hyperdoc::dmx-topic-proxy))
  (format nil "DMX topic ~D (topicmap ~D)"
          (hyperdoc::dmx-topic-id-of page)
          (hyperdoc::dmx-topicmap-id-of page)))

(defmethod views:text-representation ((page hyperdoc::dmx-workspace-repair-triage))
  (format nil "DMX workspace repair triage (topicmap ~D)"
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

(defmethod views:title-bar-action-buttons ((page hyperdoc::dmx-workspace-repair-triage))
  (views:html
    (views:action-button "Reload"
                         (views:thunk
                           (hyperdoc::ensure-dmx-workspace-repair-triage
                            page
                            :force? t)
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
  (views:html-view :title "External" :priority 7
    (views:html
      (:a :href (hyperdoc::dmx-topicmap-webclient-url page)
          :target "_blank"
          (views:esc "Open topicmap entry in DMX webclient")))))

(views:defview 👀repair-console (page hyperdoc::dmx-topic-proxy)
  (hyperdoc::ensure-dmx-topic-diagnostics page)
  (views:html-view :title "Repair console" :priority 6
    (let ((diagnostics (hyperdoc::dmx-diagnostics-of page)))
      (views:html
        (:p (views:esc
             "This repair console stays separate from the read-only diagnostics. It uses explicit credentials only for the current action, threads them into the existing guarded workspace-assignment repair executor, and then refreshes the live readback without persisting the credentials anywhere in topic content or long-lived service configuration."))
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Target workspace assignment"))
                     (:td (render-maybe-code
                           hyperdoc::*dmx-context-window-workspace-id*)))
                (:tr (:td (views:esc "Selected topicmap placement"))
                     (:td (render-maybe-code
                           hyperdoc::*dmx-context-window-topicmap-id*)))
                (:tr (:td (views:esc "Selected topic"))
                     (:td (render-maybe-code (hyperdoc::dmx-topic-id-of page))))
                (:tr (:td (views:esc "Eligible for repair"))
                     (:td (:tt (views:esc
                                (yes/no-label
                                 (dmx-repair-console-eligible-p diagnostics)))))))
        (cond
          ((null diagnostics)
           (views:html
             (:p (views:esc
                  "The topic diagnostics are not available yet, so the repair console cannot decide whether this topic is eligible."))))
          ((not (dmx-repair-console-eligible-p diagnostics))
           (views:html
             (:p (views:esc
                  "This object is not currently an actionable workspace-assignment repair candidate. Foreign topics stay excluded, and already-correct topics stay excluded as controls."))))
          (t
           (let (mode-cell username-cell password-cell header-cell token-cell)
             (views:html (:h4 "Authentication"))
             (setf mode-cell
                   (hvr:select '(("Username + password" . "basic")
                                 ("Authorization header" . "header")
                                 ("Bearer token" . "token"))
                               :label "Credential mode: "))
             (views:html (:br))
             (setf username-cell
                   (hvr:input :label "Username: " :initial-value "" :size "24"))
             (views:html (:br))
             (setf password-cell
                   (hvr:input :label "Password: "
                              :initial-value ""
                              :size "24"
                              :type :password))
             (views:html (:br))
             (setf header-cell
                   (hvr:input :label "Authorization header: "
                              :initial-value ""
                              :size "64"))
             (views:html (:br))
             (setf token-cell
                   (hvr:input :label "Bearer token: "
                              :initial-value ""
                              :size "48"
                              :type :password))
             (views:html
               (:p (views:esc
                    "Only the fields required by the active credential mode are used for the next action. Username/password, header, and token inputs are cleared again when the pane refreshes after the action."))
               (:table :class "inspector-table"
                       (:tr (:td (views:esc "Active mode"))
                            (:td (:tt (views:esc
                                       (dmx-repair-console-auth-mode-label
                                        (lwcells:cell-ref mode-cell))))))
                       (:tr (:td (views:esc "Current diagnostic status"))
                            (:td (:tt (views:esc
                                       (dmx-diagnostic-status-label
                                        (hyperdoc::dmx-topic-diagnostics-status
                                         diagnostics)))))))
               (views:action-button
                "Dry-run selected topic"
                (views:thunk
                  (repair-topic-proxy-with-explicit-auth
                   page
                   :dry-run t
                   :auth-mode (lwcells:cell-ref mode-cell)
                   :username (lwcells:cell-ref username-cell)
                   :password (lwcells:cell-ref password-cell)
                   :authorization-header (lwcells:cell-ref header-cell)
                   :auth-token (lwcells:cell-ref token-cell))
                  t)
                "Run the guarded repair path without mutating DMX")
               " "
               (views:action-button
                "Repair selected topic"
                (views:thunk
                  (repair-topic-proxy-with-explicit-auth
                   page
                   :dry-run nil
                   :auth-mode (lwcells:cell-ref mode-cell)
                   :username (lwcells:cell-ref username-cell)
                   :password (lwcells:cell-ref password-cell)
                   :authorization-header (lwcells:cell-ref header-cell)
                   :auth-token (lwcells:cell-ref token-cell))
                  t)
                "Assign workspace 919815 in place while preserving topicmap 919822 placement")))))
        (:h4 "Result readback")
        (render-dmx-repair-results-table (hyperdoc::dmx-repair-results-of page)
                                         :topicmap-id (hyperdoc::dmx-topicmap-id-of page))))))

(views:defview 👀overview (page hyperdoc::dmx-workspace-repair-triage)
  (hyperdoc::ensure-dmx-workspace-repair-triage page)
  (views:html-view :title "Repair triage" :priority 1
    (let* ((projection (hyperdoc::dmx-topicmap-projection-of page))
           (topic-proxies (hyperdoc::dmx-triage-topic-proxies-of page))
           (repair-proxies (hyperdoc::dmx-repair-topic-proxies-of page))
           (repair-topic-ids
             (mapcar #'hyperdoc::dmx-topic-id-of repair-proxies)))
      (if projection
          (views:html
            (:p (views:esc
                 "Read-only triage for HyperDoc-owned objects in the selected topicmap that still lack workspace assignment. Workspace assignment and topicmap placement remain separate diagnostics."))
            (:table :class "inspector-table"
                    (:tr (:td (views:esc "Selected topicmap"))
                         (:td (views:object-ref
                               (hyperdoc::make-dmx-topicmap-proxy
                                (hyperdoc::dmx-topicmap-id-of page)))))
                    (:tr (:td (views:esc "Projection source"))
                         (:td (render-dmx-diagnostic-url
                               (hyperdoc::dmx-topicmap-projection-url page))))
                    (:tr (:td (views:esc "Projected topic count"))
                         (:td (render-maybe-code (length topic-proxies))))
                    (:tr (:td (views:esc "Actionable repair candidates"))
                         (:td (render-maybe-code (length repair-proxies))))
                    (:tr (:td (views:esc "Candidate topic ids"))
                         (:td (views:object-ref repair-topic-ids))))
            (if repair-proxies
                (views:html
                  (:table :class "inspector-table"
                          (:tr (:th (views:esc "Topic"))
                               (:th (views:esc "Title/value"))
                               (:th (views:esc "Ownership"))
                               (:th (views:esc "In selected topicmap"))
                               (:th (views:esc "Workspace assignment"))
                               (:th (views:esc "Derived status")))
                          (dolist (proxy repair-proxies)
                            (let ((diagnostics (hyperdoc::dmx-diagnostics-of proxy)))
                              (views:html
                                (:tr (:td (views:object-ref
                                           proxy
                                           :display (format nil "~D"
                                                            (hyperdoc::dmx-topic-id-of
                                                             proxy))))
                                     (:td (views:esc
                                           (or (hyperdoc::dmx-topic-diagnostics-topic-title
                                                diagnostics)
                                               "n/a")))
                                     (:td (:tt (views:esc
                                                (dmx-diagnostic-ownership-label
                                                 diagnostics))))
                                     (:td (:tt (views:esc
                                                (yes/no-label
                                                 (hyperdoc::dmx-topic-diagnostics-selected-topicmap-membership-p
                                                  diagnostics)))))
                                     (:td (render-workspace-reference page diagnostics))
                                     (:td (:tt (views:esc
                                                (dmx-diagnostic-status-label
                                                 (hyperdoc::dmx-topic-diagnostics-status
                                                  diagnostics))))))))))
                (views:html
                  (:p (views:esc
                       "No HyperDoc-owned topics in the selected topicmap currently match the missing-workspace-assignment defect.")))))
          (views:html
            (:p (views:esc
                 "Repair triage could not be derived from the current read-only DMX fetches."))
            (if-let (condition (hyperdoc::dmx-load-error-of page))
              (views:object-ref condition)
              (views:html
                (:span :style "opacity: 0.55;"
                       "No topicmap projection available.")))))))))

(views:defview 👀raw-fetched-data (page hyperdoc::dmx-workspace-repair-triage)
  (hyperdoc::ensure-dmx-workspace-repair-triage page)
  (views:html-view :title "Raw projection" :priority 2
    (let ((projection (hyperdoc::dmx-topicmap-projection-of page))
          (repair-proxies (hyperdoc::dmx-repair-topic-proxies-of page))
          (condition (hyperdoc::dmx-load-error-of page)))
      (views:html
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Projection source"))
                     (:td (render-dmx-diagnostic-url
                           (hyperdoc::dmx-topicmap-projection-url page))))
                (:tr (:td (views:esc "Projected topic ids"))
                     (:td (views:object-ref
                           (and projection
                                (hyperdoc::dmx-topicmap-projection-topic-ids
                                 projection)))))
                (:tr (:td (views:esc "Repair topic ids"))
                     (:td (views:object-ref
                           (mapcar #'hyperdoc::dmx-topic-id-of repair-proxies))))
                (:tr (:td (views:esc "Topicmap projection JSON"))
                     (:td (views:object-ref
                           (or projection
                               condition
                               "not loaded"))))
                (when condition
                  (views:html
                    (:tr (:td (views:esc "Load error"))
                         (:td (views:object-ref condition))))))))))

(views:defview 👀external (page hyperdoc::dmx-workspace-repair-triage)
  (views:html-view :title "External" :priority 4
    (views:html
      (:a :href (hyperdoc::dmx-topicmap-webclient-url page)
          :target "_blank"
          (views:esc "Open selected topicmap in DMX webclient")))))

(views:defview 👀repair-console (page hyperdoc::dmx-workspace-repair-triage)
  (hyperdoc::ensure-dmx-workspace-repair-triage page)
  (views:html-view :title "Repair console" :priority 3
    (let ((repair-proxies (hyperdoc::dmx-repair-topic-proxies-of page)))
      (views:html
        (:p (views:esc
             "This repair console reuses the same guarded workspace-assignment repair executor as the MCP tool, but it builds an authenticated DMX client from explicit credentials entered here for the current action only. Diagnosis remains read-only above; mutation stays deliberate here."))
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Target workspace assignment"))
                     (:td (render-maybe-code
                           hyperdoc::*dmx-context-window-workspace-id*)))
                (:tr (:td (views:esc "Selected topicmap placement"))
                     (:td (render-maybe-code
                           hyperdoc::*dmx-context-window-topicmap-id*)))
                (:tr (:td (views:esc "Current backlog size"))
                     (:td (render-maybe-code (length repair-proxies)))))
        (if repair-proxies
            (let (mode-cell username-cell password-cell header-cell token-cell
                  selected-topic-cell)
              (views:html (:h4 "Authentication"))
              (setf mode-cell
                    (hvr:select '(("Username + password" . "basic")
                                  ("Authorization header" . "header")
                                  ("Bearer token" . "token"))
                                :label "Credential mode: "))
              (views:html (:br))
              (setf username-cell
                    (hvr:input :label "Username: " :initial-value "" :size "24"))
              (views:html (:br))
              (setf password-cell
                    (hvr:input :label "Password: "
                               :initial-value ""
                               :size "24"
                               :type :password))
              (views:html (:br))
              (setf header-cell
                    (hvr:input :label "Authorization header: "
                               :initial-value ""
                               :size "64"))
              (views:html (:br))
              (setf token-cell
                    (hvr:input :label "Bearer token: "
                               :initial-value ""
                               :size "48"
                               :type :password))
              (views:html (:h4 "Repair scope"))
              (setf selected-topic-cell
                    (hvr:select
                     (mapcar (lambda (proxy)
                               (cons (format nil "~D (~A)"
                                             (hyperdoc::dmx-topic-id-of proxy)
                                             (or (hyperdoc::dmx-topic-diagnostics-topic-title
                                                  (hyperdoc::dmx-diagnostics-of proxy))
                                                 "n/a"))
                                     (format nil "~D"
                                             (hyperdoc::dmx-topic-id-of proxy))))
                             repair-proxies)
                     :label "Selected topic: "))
              (views:html
                (:p (views:esc
                     "Only the fields required by the active credential mode are used for the current action. The current backlog already excludes foreign objects such as 922451 and already-correct objects such as 922586."))
                (:table :class "inspector-table"
                        (:tr (:td (views:esc "Active mode"))
                             (:td (:tt (views:esc
                                        (dmx-repair-console-auth-mode-label
                                         (lwcells:cell-ref mode-cell))))))
                        (:tr (:td (views:esc "Selected topic for one-object repair"))
                             (:td (render-maybe-code
                                   (lwcells:cell-ref selected-topic-cell)))))
                (views:action-button
                 "Dry-run selected topic"
                 (views:thunk
                   (let ((client (make-explicit-dmx-repair-client
                                  page
                                  :auth-mode (lwcells:cell-ref mode-cell)
                                  :username (lwcells:cell-ref username-cell)
                                  :password (lwcells:cell-ref password-cell)
                                  :authorization-header (lwcells:cell-ref header-cell)
                                  :auth-token (lwcells:cell-ref token-cell))))
                     (let ((result (repair-triage-topic-with-client
                                    page
                                    (parse-integer (lwcells:cell-ref selected-topic-cell))
                                    client
                                    :dry-run t
                                    :auth-mode (lwcells:cell-ref mode-cell))))
                       (setf (hyperdoc::dmx-repair-results-of page)
                             (list result)
                             (hyperdoc::dmx-repair-summary-of page)
                             (list :count 1
                                   :dry-run t
                                   :success-count (if (getf result :success-p) 1 0)
                                   :error-count (if (getf result :success-p) 0 1))))
                     (hyperdoc::ensure-dmx-workspace-repair-triage page :force? t)
                     t))
                 "Run the guarded repair path for the selected backlog topic without mutating DMX")
                " "
                (views:action-button
                 "Repair selected topic"
                 (views:thunk
                   (let ((client (make-explicit-dmx-repair-client
                                  page
                                  :auth-mode (lwcells:cell-ref mode-cell)
                                  :username (lwcells:cell-ref username-cell)
                                  :password (lwcells:cell-ref password-cell)
                                  :authorization-header (lwcells:cell-ref header-cell)
                                  :auth-token (lwcells:cell-ref token-cell))))
                     (let ((result (repair-triage-topic-with-client
                                    page
                                    (parse-integer (lwcells:cell-ref selected-topic-cell))
                                    client
                                    :dry-run nil
                                    :auth-mode (lwcells:cell-ref mode-cell))))
                       (setf (hyperdoc::dmx-repair-results-of page)
                             (list result)
                             (hyperdoc::dmx-repair-summary-of page)
                             (list :count 1
                                   :dry-run nil
                                   :success-count (if (getf result :success-p) 1 0)
                                   :error-count (if (getf result :success-p) 0 1))))
                     (hyperdoc::ensure-dmx-workspace-repair-triage page :force? t)
                     t))
                 "Repair only the selected backlog topic")
                " "
                (views:action-button
                 "Dry-run backlog"
                 (views:thunk
                   (repair-workspace-triage-backlog-with-explicit-auth
                    page
                    :dry-run t
                    :auth-mode (lwcells:cell-ref mode-cell)
                    :username (lwcells:cell-ref username-cell)
                    :password (lwcells:cell-ref password-cell)
                    :authorization-header (lwcells:cell-ref header-cell)
                    :auth-token (lwcells:cell-ref token-cell))
                   t)
                 "Run the guarded repair path for the whole backlog without mutating DMX")
                " "
                (views:action-button
                 "Repair backlog"
                 (views:thunk
                   (repair-workspace-triage-backlog-with-explicit-auth
                    page
                    :dry-run nil
                    :auth-mode (lwcells:cell-ref mode-cell)
                    :username (lwcells:cell-ref username-cell)
                    :password (lwcells:cell-ref password-cell)
                    :authorization-header (lwcells:cell-ref header-cell)
                    :auth-token (lwcells:cell-ref token-cell))
                   t)
                 "Repair the current triage backlog in place")))
            (views:html
              (:p (views:esc
                   "There are currently no actionable backlog items, so the repair console has nothing to mutate."))))
        (:h4 "Per-topic live result readback")
        (when-let (summary (hyperdoc::dmx-repair-summary-of page))
          (views:html
            (:table :class "inspector-table"
                    (:tr (:td (views:esc "Recorded result count"))
                         (:td (render-maybe-code (getf summary :count))))
                    (:tr (:td (views:esc "Dry-run"))
                         (:td (:tt (views:esc
                                    (yes/no-label (getf summary :dry-run))))))
                    (:tr (:td (views:esc "Success count"))
                         (:td (render-maybe-code (getf summary :success-count))))
                    (:tr (:td (views:esc "Error count"))
                         (:td (render-maybe-code (getf summary :error-count))))
                    (when-let (message (getf summary :message))
                      (views:html
                        (:tr (:td (views:esc "Summary note"))
                             (:td (views:esc message))))))))
        (render-dmx-repair-results-table (hyperdoc::dmx-repair-results-of page)
                                         :topicmap-id (hyperdoc::dmx-topicmap-id-of page))))))
