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

(defun dmx-journal-call-graph-overview-diagram ()
  (format nil
          "read-dmx-workspace-journal(reconcile=t)~%  -> dmx-workspace-journal-reconcile-workspace(:persist-events-p nil)~%     -> dmx-workspace-journal-reconcile-subject~%        -> dmx-workspace-journal-transition-events~%        -> dmx-workspace-journal-apply-events-to-stream  ; active~%        X> dmx-workspace-journal-append-events       ; suppressed during read~%            -> dmx-workspace-journal-persist-stream~%               -> companion journal note 924694~%~%read-dmx-topic-journal(reconcile=t)~%  -> dmx-workspace-journal-locate-stream~%     -> dmx-workspace-journal-reconcile-workspace(:persist-events-p nil)"))

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

(defun dmx-topic-proxy-workspace-assignment-repairable-p (diagnostics)
  (and diagnostics
       (hyperdoc::dmx-topic-diagnostics-repair-needed-p diagnostics)
       (hyperdoc::dmx-topic-diagnostics-hyperdoc-owned-p diagnostics)
       (hyperdoc::dmx-topic-diagnostics-selected-topicmap-membership-p
        diagnostics)
       (null (hyperdoc::dmx-topic-diagnostics-workspace-id diagnostics))))

(defparameter +dmx-topic-proxy-public-assignment-blocked-message+
  "Public assignment blocked; use privileged initial assignment repair")

(defun dmx-topic-proxy-public-assignment-blocked-p (diagnostics)
  (dmx-topic-proxy-workspace-assignment-repairable-p diagnostics))

(defun render-workspace-reference-with-repair-link (page diagnostics)
  (views:html
   (render-workspace-reference page diagnostics)
   (when (dmx-topic-proxy-workspace-assignment-repairable-p diagnostics)
     (views:html
      " "
      (views:object-ref page
                        :display
                        (format nil "[~A]"
                                +dmx-topic-proxy-public-assignment-blocked-message+)
                        :select "Workspace diagnostics")))))

(defun dmx-topic-proxy-assignment-target-label (workspace-id)
  (format nil "context-window / ~D" workspace-id))

(defun dmx-topic-proxy-assignment-path (page workspace-id)
  (hyperdoc::dmx-workspace-assign-object-path
   workspace-id
   (hyperdoc::dmx-topic-id-of page)))

(defun dmx-topic-proxy-launch-expression (page)
  (format nil
          "(make-dmx-topic-proxy :topic-id ~D :topicmap-id ~D)"
          (hyperdoc::dmx-topic-id-of page)
          (hyperdoc::dmx-topicmap-id-of page)))

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

(defun dmx-meta-na ()
  "n/a")

(defun dmx-meta-present-string (value)
  (cond
    ((null value) nil)
    ((and (stringp value)
          (string= value ""))
     nil)
    (t
     (format nil "~A" value))))

(defun dmx-meta-field (object key)
  (and (hash-table-p object)
       (gethash key object)))

(defun dmx-meta-seq (value)
  (cond
    ((null value) '())
    ((vectorp value) (coerce value 'list))
    ((listp value) value)
    (t (list value))))

(defun dmx-meta-child-topic (topic-data type-uri)
  (let ((children (dmx-meta-field topic-data "children")))
    (cond
      ((hash-table-p children)
       (or (gethash type-uri children)
           (loop for child being the hash-values of children
                 when (and (hash-table-p child)
                           (string= type-uri
                                    (or (dmx-meta-field child "typeUri") "")))
                 return child)))
      ((or (vectorp children)
           (listp children))
       (find type-uri
             (dmx-meta-seq children)
             :key (lambda (child)
                    (and (hash-table-p child)
                         (dmx-meta-field child "typeUri")))
             :test #'string=)))))

(defun dmx-meta-child-value (topic-data type-uri)
  (let ((child (dmx-meta-child-topic topic-data type-uri)))
    (cond
      ((hash-table-p child)
       (dmx-meta-field child "value"))
      (child child)
      (t nil))))

(defun dmx-meta-topic-title (topic-data)
  (or (dmx-meta-field topic-data "value")
      (dmx-meta-child-value topic-data "dmx.notes.title")))

(defun dmx-meta-known-topic-type-label (type-uri)
  (cond
    ((string= (or type-uri "") "dmx.notes.note")
     "Note")
    ((string= (or type-uri "") "dmx.workspaces.workspace")
     "Workspace")
    ((string= (or type-uri "") "dmx.topicmaps.topicmap")
     "Topicmap")
    (t nil)))

(defun dmx-meta-instantiation-type-topics (page)
  (let ((type-uri (and (hyperdoc::dmx-topic-data-of page)
                       (dmx-meta-field (hyperdoc::dmx-topic-data-of page)
                                       "typeUri"))))
    (loop for topic in (dmx-meta-seq (hyperdoc::dmx-related-topics-of page))
          when (and (hash-table-p topic)
                    (or (equal type-uri (dmx-meta-field topic "uri"))
                        (equal type-uri (dmx-meta-field topic "topicUri"))
                        (equal "dmx.core.topic_type"
                               (dmx-meta-field topic "typeUri"))))
          collect topic)))

(defun dmx-meta-topic-type-label (page type-uri)
  (or (loop for topic in (dmx-meta-instantiation-type-topics page)
            for value = (dmx-meta-field topic "value")
            when value
            return value)
      (dmx-meta-known-topic-type-label type-uri)
      type-uri
      (dmx-meta-na)))

(defun dmx-meta-timestamp-raw (topic-data field-name child-type-uri)
  (or (dmx-meta-field topic-data field-name)
      (dmx-meta-child-value topic-data child-type-uri)))

(defun dmx-meta-unix-millis->universal-time (millis)
  (+ (floor millis 1000) 2208988800))

(defun dmx-meta-parse-integer (value)
  (cond
    ((integerp value) value)
    ((stringp value)
     (ignore-errors (parse-integer value :junk-allowed t)))
    (t nil)))

(defun dmx-meta-format-timestamp (raw)
  (let ((millis (dmx-meta-parse-integer raw)))
    (if millis
        (multiple-value-bind (second minute hour day month year)
            (decode-universal-time
             (dmx-meta-unix-millis->universal-time millis))
          (format nil "~4,'0D-~2,'0D-~2,'0D ~2,'0D:~2,'0D:~2,'0D"
                  year month day hour minute second))
        (dmx-meta-present-string raw))))

(defun dmx-meta-note-text (topic-data)
  (or (dmx-meta-child-value topic-data "dmx.notes.text")
      (dmx-meta-field topic-data "dmx.notes.text")))

(defun dmx-meta-parse-json-text (text)
  (when (and (stringp text)
             (plusp (length (string-trim '(#\Space #\Tab #\Newline #\Return)
                                         text))))
    (handler-case
        (shasht:read-json text)
      (error ()
        nil))))

(defun dmx-meta-hyperdoc-annotation-carrier (topic-data)
  (let ((carrier (dmx-meta-parse-json-text (dmx-meta-note-text topic-data))))
    (when (and (hash-table-p carrier)
               (or (equal "hyperdoc.annotation"
                          (dmx-meta-field carrier "nativeTypeUri"))
                   (dmx-meta-field carrier "annotationKey")))
      carrier)))

(defun dmx-meta-json-list-label (value)
  (cond
    ((null value)
     nil)
    ((or (vectorp value)
         (listp value))
     (format nil "~{~A~^ -> ~}" (dmx-meta-seq value)))
    (t
     (format nil "~A" value))))

(defun dmx-meta-source-anchor (native-payload)
  (or (dmx-meta-field native-payload "sourceAnchor")
      (dmx-meta-field native-payload "source")
      (dmx-meta-field native-payload "sourceRef")))

(defun dmx-meta-target-anchor (native-payload)
  (or (dmx-meta-field native-payload "targetAnchor")
      (dmx-meta-field native-payload "target")
      (dmx-meta-field native-payload "targetRef")))

(defun dmx-meta-anchor-field (anchor &rest keys)
  (loop for key in keys
        for value = (dmx-meta-field anchor key)
        when value
        return value))

(defun dmx-meta-table-row (label value &key code raw)
  (views:html
   (:tr (:td (views:esc label))
        (:td (cond
               (raw
                (views:object-ref value))
               (code
                (render-maybe-code value))
               (t
                (views:esc (or (dmx-meta-present-string value)
                               (dmx-meta-na)))))))))

(defun render-dmx-meta-identity-block (page topic-data)
  (let* ((type-uri (dmx-meta-field topic-data "typeUri"))
         (type-label (dmx-meta-topic-type-label page type-uri)))
    (views:html
     (:h4 "Identity")
     (:table :class "inspector-table"
             (dmx-meta-table-row "ID" (hyperdoc::dmx-topic-id-of page)
                                 :code t)
             (dmx-meta-table-row "URI" (dmx-meta-field topic-data "uri")
                                 :code t)
             (dmx-meta-table-row "Topic value/title"
                                 (dmx-meta-topic-title topic-data))
             (dmx-meta-table-row "Type" type-label)
             (dmx-meta-table-row "Type URI" type-uri :code t)))))

(defun render-dmx-meta-timestamps-block (topic-data)
  (let ((created (dmx-meta-timestamp-raw topic-data
                                         "created"
                                         "dmx.timestamps.created"))
        (modified (dmx-meta-timestamp-raw topic-data
                                          "modified"
                                          "dmx.timestamps.modified")))
    (views:html
     (:h4 "Timestamps")
     (:table :class "inspector-table"
             (dmx-meta-table-row "Created"
                                 (dmx-meta-format-timestamp created))
             (dmx-meta-table-row "Created raw" created :code t)
             (dmx-meta-table-row "Modified"
                                 (dmx-meta-format-timestamp modified))
             (dmx-meta-table-row "Modified raw" modified :code t)))))

(defun render-dmx-meta-ownership-block (page diagnostics)
  (views:html
   (:h4 "Ownership / workspace")
   (:table :class "inspector-table"
           (dmx-meta-table-row "Created user"
                               (or (and (hyperdoc::dmx-topic-data-of page)
                                        (dmx-meta-field
                                         (hyperdoc::dmx-topic-data-of page)
                                         "creator"))
                                   (and (hyperdoc::dmx-topic-data-of page)
                                        (dmx-meta-child-value
                                         (hyperdoc::dmx-topic-data-of page)
                                         "dmx.accesscontrol.creator"))))
           (dmx-meta-table-row "Modified user"
                               (or (and (hyperdoc::dmx-topic-data-of page)
                                        (dmx-meta-field
                                         (hyperdoc::dmx-topic-data-of page)
                                         "modifier"))
                                   (and (hyperdoc::dmx-topic-data-of page)
                                        (dmx-meta-child-value
                                         (hyperdoc::dmx-topic-data-of page)
                                         "dmx.accesscontrol.modifier"))))
           (:tr (:td (views:esc "Workspace"))
                (:td (if diagnostics
                         (render-workspace-reference-with-repair-link
                          page
                          diagnostics)
                         (views:esc (dmx-meta-na)))))
           (dmx-meta-table-row "Owner"
                               (and diagnostics
                                    (hyperdoc::dmx-topic-diagnostics-workspace-owner
                                     diagnostics))
                               :code t)
           (:tr (:td (views:esc "Topicmap membership"))
                (:td (if diagnostics
                         (render-topicmap-memberships page diagnostics)
                         (views:esc (dmx-meta-na))))))))

(defun render-dmx-meta-topic-type-block (page topic-data)
  (let* ((type-uri (dmx-meta-field topic-data "typeUri"))
         (type-label (dmx-meta-topic-type-label page type-uri))
         (type-topics (dmx-meta-instantiation-type-topics page)))
    (views:html
     (:h4 "Topic type")
     (:table :class "inspector-table"
             (dmx-meta-table-row "Resolved label" type-label)
             (dmx-meta-table-row "Machine-readable type URI"
                                 type-uri
                                 :code t)
             (:tr (:td (views:esc "Instantiation association"))
                  (:td (if type-topics
                           (views:object-ref type-topics)
                           (views:esc (dmx-meta-na)))))))))

(defun render-dmx-meta-annotation-block (carrier)
  (let* ((native-payload (dmx-meta-field carrier "nativePayload"))
         (source (dmx-meta-source-anchor native-payload))
         (target (dmx-meta-target-anchor native-payload)))
    (views:html
     (:h4 "HyperDoc annotation carrier")
     (:table :class "inspector-table"
             (dmx-meta-table-row "annotationKey"
                                 (dmx-meta-field carrier "annotationKey")
                                 :code t)
             (dmx-meta-table-row "runtimeRelationId"
                                 (dmx-meta-field carrier "runtimeRelationId")
                                 :code t)
             (dmx-meta-table-row "workspaceTopicmapId"
                                 (dmx-meta-field carrier "workspaceTopicmapId")
                                 :code t)
             (dmx-meta-table-row "Native payload type URI"
                                 (dmx-meta-field carrier "nativeTypeUri")
                                 :code t)
             (dmx-meta-table-row "Source page"
                                 (dmx-meta-anchor-field source
                                                        "page"
                                                        "pageTitle"))
             (dmx-meta-table-row "Source heading path"
                                 (dmx-meta-json-list-label
                                  (dmx-meta-anchor-field source
                                                         "headingPath"
                                                         "headings")))
             (dmx-meta-table-row "Source list container"
                                 (dmx-meta-anchor-field source
                                                        "listContainer"
                                                        "listSelector"))
             (dmx-meta-table-row "Source item index"
                                 (dmx-meta-anchor-field source
                                                        "itemIndex"
                                                        "index")
                                 :code t)
             (dmx-meta-table-row "Target"
                                 (dmx-meta-anchor-field target
                                                        "target"
                                                        "id"
                                                        "key")
                                 :code t)
             (dmx-meta-table-row "Target label"
                                 (dmx-meta-anchor-field target
                                                        "label"
                                                        "title"))))))

(defun find-dmx-repair-result-for-topic (page topic-id)
  (find topic-id
        (hyperdoc::dmx-repair-results-of page)
        :key (lambda (result) (getf result :topic-id))
        :test #'eql))

(defun dmx-repair-result-auth-boundary-failed-p (result)
  (let ((debug-report (getf result :debug-report)))
    (or (member (getf debug-report :bootstrap-status-code) '(401 403))
        (member (getf debug-report :guarded-put-status-code) '(401 403)))))

(defun dmx-repair-result-permission-denied-p (result)
  (let ((debug-report (getf result :debug-report)))
    (and (member (getf debug-report :guarded-put-status-code) '(401 403))
         (or (getf debug-report :bootstrap-ran-p)
             (getf debug-report :session-cookie-captured-p)
             (getf debug-report :guarded-put-jsessionid-cookie-p)))))

(defun dmx-repair-result-operational-state-label (page result)
  (cond
    ((null result)
     nil)
    ((and (getf result :success-p)
          (not (getf result :dry-run))
          (or (eql (getf result :workspace-action) :already-assigned)
              (and (eql (getf result :result-workspace-id)
                        (hyperdoc::dmx-workspace-id-of page))
                   (getf result :result-in-topicmap-p))))
     (if (eql (getf result :workspace-action) :already-assigned)
         "healthy"
         "repair-succeeded"))
    ((and (not (getf result :success-p))
          (dmx-repair-result-permission-denied-p result))
     "permission-denied")
    ((and (not (getf result :success-p))
          (dmx-repair-result-auth-boundary-failed-p result))
     "credentials-pending")
    ((not (getf result :success-p))
     "repair-failed-non-auth")
    (t
     "in-topicmap-but-unassigned")))

(defun dmx-topic-proxy-operational-status-label (page proxy)
  (let* ((result
          (find-dmx-repair-result-for-topic page
                                            (hyperdoc::dmx-topic-id-of proxy)))
         (result-label (dmx-repair-result-operational-state-label page result))
         (diagnostics (hyperdoc::dmx-diagnostics-of proxy)))
    (or result-label
        (cond
          ((null diagnostics)
           "n/a")
          ((not (hyperdoc::dmx-topic-diagnostics-hyperdoc-owned-p diagnostics))
           "foreign-no-action")
          ((and (eql (hyperdoc::dmx-topic-diagnostics-workspace-id diagnostics)
                     (hyperdoc::dmx-workspace-id-of page))
                (hyperdoc::dmx-topic-diagnostics-selected-topicmap-membership-p
                 diagnostics))
           "healthy")
          ((and (hyperdoc::dmx-topic-diagnostics-selected-topicmap-membership-p
                 diagnostics)
                (null (hyperdoc::dmx-topic-diagnostics-workspace-id diagnostics)))
           "in-topicmap-but-unassigned")
          (t
           (dmx-diagnostic-status-label
            (hyperdoc::dmx-topic-diagnostics-status diagnostics)))))))

(defun dmx-operational-status-count (page proxies status-label)
  (count status-label
         proxies
         :key (lambda (proxy)
                (dmx-topic-proxy-operational-status-label page proxy))
         :test #'string=))

(defun render-dmx-operational-topic-proxy-table
    (page proxies &key empty-message)
  (if proxies
      (views:html
       (:table :class "inspector-table"
               (:tr (:th (views:esc "Topic"))
                    (:th (views:esc "Title/value"))
                    (:th (views:esc "Workspace assignment"))
                    (:th (views:esc "Ownership"))
                    (:th (views:esc "Operational state")))
               (dolist (proxy proxies)
                 (let ((diagnostics (hyperdoc::dmx-diagnostics-of proxy)))
                   (views:html
                    (:tr
                     (:td (views:object-ref
                           proxy
                           :display (format nil "~D"
                                            (hyperdoc::dmx-topic-id-of proxy))
                           :select "Workspace diagnostics"))
                     (:td (views:esc
                           (or (and diagnostics
                                    (hyperdoc::dmx-topic-diagnostics-topic-title
                                     diagnostics))
                               "n/a")))
                     (:td (if diagnostics
                              (render-workspace-reference page diagnostics)
                              (render-maybe-code nil)))
                     (:td (:tt (views:esc
                                (if diagnostics
                                    (dmx-diagnostic-ownership-label diagnostics)
                                    "n/a"))))
                     (:td (:tt (views:esc
                                (dmx-topic-proxy-operational-status-label
                                 page
                                 proxy))))))))))
      (views:html
       (:p (views:esc (or empty-message
                          "No topics match the current filter."))))))

(defun render-dmx-shared-workspace-context-summary-table (page)
  (let* ((visible-proxies (hyperdoc::dmx-visible-topic-proxies page))
         (assigned-proxies (hyperdoc::dmx-visible-assigned-topic-proxies page))
         (missing-proxies
          (hyperdoc::dmx-visible-but-unassigned-topic-proxies page))
         (repair-proxies (hyperdoc::dmx-repair-topic-proxies-of page))
         (workspace-id (hyperdoc::dmx-workspace-id-of page))
         (topicmap-id (hyperdoc::dmx-topicmap-id-of page)))
    (views:html
     (:table :class "inspector-table"
             (:tr (:td (views:esc "Workspace"))
                  (:td (views:object-ref
                        (hyperdoc::make-dmx-shared-workspace-topic-proxy
                         workspace-id
                         :topicmap-id topicmap-id)
                        :display (hyperdoc::dmx-workspace-display-label
                                  workspace-id))))
             (:tr (:td (views:esc "Topicmap"))
                  (:td (views:object-ref
                        (hyperdoc::make-dmx-topicmap-proxy topicmap-id)
                        :display (hyperdoc::dmx-topicmap-display-label
                                  topicmap-id))))
             (:tr (:td (views:esc "Visible topics"))
                  (:td (render-maybe-code (length visible-proxies))))
             (:tr (:td (views:esc "Assigned topics"))
                  (:td (render-maybe-code (length assigned-proxies))))
             (:tr (:td (views:esc "Visible but unassigned"))
                  (:td (render-maybe-code (length missing-proxies))))
             (:tr (:td (views:esc "Actionable repair candidates"))
                  (:td (render-maybe-code (length repair-proxies))))
             (:tr (:td (:tt (views:esc "healthy")))
                  (:td (render-maybe-code
                        (dmx-operational-status-count
                         page
                         visible-proxies
                         "healthy"))))
             (:tr (:td (:tt (views:esc "foreign-no-action")))
                  (:td (render-maybe-code
                        (dmx-operational-status-count
                         page
                         visible-proxies
                         "foreign-no-action"))))
             (:tr (:td (:tt (views:esc "in-topicmap-but-unassigned")))
                  (:td (render-maybe-code
                        (dmx-operational-status-count
                         page
                         visible-proxies
                         "in-topicmap-but-unassigned"))))
             (:tr (:td (:tt (views:esc "credentials-pending")))
                  (:td (render-maybe-code
                        (dmx-operational-status-count
                         page
                         visible-proxies
                         "credentials-pending"))))
             (:tr (:td (:tt (views:esc "repair-succeeded")))
                  (:td (render-maybe-code
                        (dmx-operational-status-count
                         page
                         visible-proxies
                         "repair-succeeded"))))
             (:tr (:td (:tt (views:esc "repair-failed-non-auth")))
                  (:td (render-maybe-code
                        (dmx-operational-status-count
                         page
                         visible-proxies
                         "repair-failed-non-auth"))))))))

(defun dmx-repair-console-auth-mode-label (mode)
  (case mode
    ((nil :rehearsal) "localhost rehearsal")
    (otherwise
     (case (hyperdoc::normalize-http-dmx-import-auth-mode
            mode
            'dmx-repair-console-auth-mode-label)
       (:basic "username/password")
       (:header "authorization header")
       (:token "bearer token")))))

(defparameter *dmx-repair-auth-state-specs*
  '((:state :s0
     :label "S0 no credentials entered"
     :file "hyperdoc-inspector/dmx-topics.lisp"
     :functions ("views:defview 👀repair-console"))
    (:state :s1
     :label "S1 credentials captured in UI"
     :file "hyperdoc-inspector/dmx-topics.lisp"
     :functions ("views:defview 👀repair-console"
                 "build-dmx-repair-auth-context"))
    (:state :s2
     :label "S2 auth mode selected"
     :file "hyperdoc-inspector/dmx-topics.lisp"
     :functions ("views:defview 👀repair-console"
                 "build-dmx-repair-auth-context"))
    (:state :s3
     :label "S3 explicit auth client built"
     :file "hyperdoc/dmx-import.lisp"
     :functions ("make-http-dmx-import-client-from-explicit-auth"))
    (:state :s4
     :label "S4 bootstrap request prepared"
     :file "hyperdoc/dmx-import.lisp"
     :functions ("ensure-http-dmx-import-authenticated-operation"))
    (:state :s5
     :label "S5 bootstrap request sent"
     :file "hyperdoc/dmx-import.lisp"
     :functions ("bootstrap-http-dmx-import-session"))
    (:state :s6
     :label "S6 bootstrap response received"
     :file "hyperdoc/dmx-import.lisp"
     :functions ("bootstrap-http-dmx-import-session"))
    (:state :s7
     :label "S7 session material extracted"
     :file "hyperdoc/dmx-import.lisp"
     :functions ("bootstrap-http-dmx-import-session"))
    (:state :s8
     :label "S8 guarded repair request prepared"
     :file "hyperdoc/dmx-import.lisp"
     :functions ("dmx-import-assign-topic-to-workspace"))
    (:state :s9
     :label "S9 guarded repair request sent"
     :file "hyperdoc/dmx-import.lisp"
     :functions ("http-request-json"))
    (:state :s10
     :label "S10 guarded repair response received"
     :file "hyperdoc/dmx-import.lisp"
     :functions ("http-request-json"))
    (:state :s11
     :label "S11 result readback refreshed"
     :file "hyperdoc-inspector/dmx-topics.lisp"
     :functions ("capture-dmx-repair-client-readbacks"
                 "repair-topic-proxy-with-client"))
    (:state :s12
     :label "S12 terminal success"
     :file "hyperdoc-inspector/dmx-topics.lisp"
     :functions ("sanitize-dmx-repair-result"
                 "render-dmx-repair-results-table"))
    (:state :s13
     :label "S13 terminal failure"
     :file "hyperdoc-inspector/dmx-topics.lisp"
     :functions ("sanitize-dmx-repair-result"
                 "render-dmx-repair-results-table"))))

(defun dmx-repair-auth-state-spec (state)
  (find state
        *dmx-repair-auth-state-specs*
        :key (lambda (spec) (getf spec :state))
        :test #'eq))

(defun dmx-repair-auth-state-label (state)
  (or (getf (dmx-repair-auth-state-spec state) :label)
      (string-downcase (format nil "~A" state))))


(defun dmx-repair-auth-source-evidence ()
  (mapcar
   (lambda (spec)
     (list :label (getf spec :label)
           :detail
           (format nil "~A :: ~{~A~^, ~}"
                   (or (getf spec :file) "unknown-file")
                   (or (getf spec :functions) '()))))
   *dmx-repair-auth-state-specs*))

(defun dmx-repair-auth-state-object (spec)
  (hyperdoc::make-state-machine-state
   :id (getf spec :state)
   :title (getf spec :label)
   :summary (getf spec :label)
   :role (cond
           ((eq (getf spec :state) :s12) :terminal)
           ((eq (getf spec :state) :s13) :failure)
           (t :intermediate))
   :notes
   (remove nil
           (list
            (when (getf spec :file)
              (format nil "Source file: ~A" (getf spec :file)))
            (when (getf spec :functions)
              (format nil "Functions: ~{~A~^, ~}" (getf spec :functions)))))))

(defun dmx-repair-auth-transition-objects ()
  (list
   (hyperdoc::make-state-machine-transition
    :id "s0->s1" :title "Credentials captured"
    :from-state :s0 :to-state :s1
    :trigger "credentials entered"
    :guard "selected credential material present")
   (hyperdoc::make-state-machine-transition
    :id "s1->s2" :title "Auth mode selected"
    :from-state :s1 :to-state :s2
    :trigger "select auth mode"
    :guard "auth mode normalized")
   (hyperdoc::make-state-machine-transition
    :id "s2->s3" :title "Explicit auth client built"
    :from-state :s2 :to-state :s3
    :trigger "build client"
    :guard "credentials sufficient for selected mode")
   (hyperdoc::make-state-machine-transition
    :id "s3->s4" :title "Bootstrap prepared"
    :from-state :s3 :to-state :s4
    :trigger "prepare bootstrap"
    :guard "bootstrap requested or required")
   (hyperdoc::make-state-machine-transition
    :id "s4->s5" :title "Bootstrap request sent"
    :from-state :s4 :to-state :s5
    :trigger "send login bootstrap"
    :guard "bootstrap path active")
   (hyperdoc::make-state-machine-transition
    :id "s5->s6" :title "Bootstrap response received"
    :from-state :s5 :to-state :s6
    :trigger "receive bootstrap response"
    :guard "HTTP response returned")
   (hyperdoc::make-state-machine-transition
    :id "s6->s7" :title "Session material extracted"
    :from-state :s6 :to-state :s7
    :trigger "extract JSESSIONID"
    :guard "Set-Cookie contains JSESSIONID")
   (hyperdoc::make-state-machine-transition
    :id "s7->s8" :title "Guarded repair request prepared"
    :from-state :s7 :to-state :s8
    :trigger "prepare guarded request"
    :guard "workspace assignment request formed")
   (hyperdoc::make-state-machine-transition
    :id "s8->s9" :title "Guarded repair request sent"
    :from-state :s8 :to-state :s9
    :trigger "send guarded request"
    :guard "HTTP request emitted")
   (hyperdoc::make-state-machine-transition
    :id "s9->s10" :title "Guarded repair response received"
    :from-state :s9 :to-state :s10
    :trigger "receive guarded response"
    :guard "HTTP response returned")
   (hyperdoc::make-state-machine-transition
    :id "s10->s11" :title "Readback refreshed"
    :from-state :s10 :to-state :s11
    :trigger "refresh readbacks"
    :guard "workspace/topicmap readbacks completed")
   (hyperdoc::make-state-machine-transition
    :id "s11->s12" :title "Terminal success"
    :from-state :s11 :to-state :s12
    :trigger "classify success"
    :guard "verified success")
   (hyperdoc::make-state-machine-transition
    :id "s4->s13" :title "Terminal failure before bootstrap"
    :from-state :s4 :to-state :s13
    :trigger "bootstrap unavailable"
    :guard "bootstrap never ran or failed")
   (hyperdoc::make-state-machine-transition
    :id "s5->s13" :title "Terminal failure on bootstrap"
    :from-state :s5 :to-state :s13
    :trigger "bootstrap failed"
    :guard "non-success login response")
   (hyperdoc::make-state-machine-transition
    :id "s6->s13" :title "Terminal failure without session"
    :from-state :s6 :to-state :s13
    :trigger "session extraction failed"
    :guard "no usable JSESSIONID")
   (hyperdoc::make-state-machine-transition
    :id "s8->s13" :title "Terminal failure before guarded send"
    :from-state :s8 :to-state :s13
    :trigger "guarded request blocked"
    :guard "request could not be sent")
   (hyperdoc::make-state-machine-transition
    :id "s9->s13" :title "Terminal failure on guarded response"
    :from-state :s9 :to-state :s13
    :trigger "guarded request failed"
    :guard "non-success guarded response")
   (hyperdoc::make-state-machine-transition
    :id "s10->s13" :title "Terminal failure after guarded response"
    :from-state :s10 :to-state :s13
    :trigger "classify failure"
    :guard "terminal failure")
   (hyperdoc::make-state-machine-transition
    :id "s11->s13" :title "Terminal failure after readback"
    :from-state :s11 :to-state :s13
    :trigger "readback contradiction"
    :guard "readback indicates failure")))

(defun make-dmx-repair-auth-state-machine-definition ()
  (hyperdoc::make-state-machine-definition
   :id "state-machine-definition/dmx-repair-auth"
   :title "DMX repair-console authentication path"
   :summary "Reusable definition for the repair-console auth/bootstrap/session flow."
   :states (mapcar #'dmx-repair-auth-state-object
                   *dmx-repair-auth-state-specs*)
   :transitions (dmx-repair-auth-transition-objects)
   :initial-state :s0
   :terminal-states '(:s12)
   :failure-states '(:s13)
   :source-evidence (dmx-repair-auth-source-evidence)
   :multi-initial-p nil
   :multi-current-p nil
   :allow-terminal-outgoing-p nil
   :acyclic-p t))

(defun repair-auth-debug-event->transition-trace-entry (event)
  (case (getf event :event)
    (:s5-bootstrap-request-sent
     (list :timestamp (getf event :timestamp)
           :kind :transition
           :transition-id "s4->s5"
           :from-state :s4
           :to-state :s5
           :detail (format nil "~A ~A"
                           (or (getf event :method) :post)
                           (or (getf event :path) "n/a"))))
    (:s6-bootstrap-response-received
     (list :timestamp (getf event :timestamp)
           :kind :transition
           :transition-id "s5->s6"
           :from-state :s5
           :to-state :s6
           :detail (format nil "status=~A reason=~A"
                           (or (getf event :status-code) "n/a")
                           (or (getf event :reason-phrase) "n/a"))))
    (:s7-session-material-extracted
     (list :timestamp (getf event :timestamp)
           :kind :transition
           :transition-id "s6->s7"
           :from-state :s6
           :to-state :s7
           :detail (format nil "cookie-shape=~A"
                           (or (getf event :cookie-shape) "n/a"))))
    (otherwise nil)))

(defun repair-auth-debug-event->evidence-trace-entry (event)
  (case (getf event :event)
    (:s5-bootstrap-request-sent
     (list :timestamp (getf event :timestamp)
           :kind :evidence
           :transition-id "s4->s5"
           :from-state :s4
           :to-state :s5
           :evidence
           (format nil "auth=~A scheme=~A content-type=~A length=~A empty-body=~A"
                   (or (getf event :auth-mode-summary) "n/a")
                   (or (getf event :authorization-scheme) "n/a")
                   (or (getf event :content-type) "n/a")
                   (or (getf event :content-length) "n/a")
                   (or (getf event :empty-body-p) "n/a"))))
    (:s6-bootstrap-response-received
     (list :timestamp (getf event :timestamp)
           :kind :evidence
           :transition-id "s5->s6"
           :from-state :s5
           :to-state :s6
           :evidence
           (format nil "status=~A jsessionid-set-cookie=~A"
                   (or (getf event :status-code) "n/a")
                   (or (getf event :set-cookie-jsessionid-p) "n/a"))))
    (:s7-session-material-extracted
     (list :timestamp (getf event :timestamp)
           :kind :evidence
           :transition-id "s6->s7"
           :from-state :s6
           :to-state :s7
           :evidence
           (format nil "session-cookie-captured=~A cookie-shape=~A"
                   (or (getf event :session-cookie-captured-p) "n/a")
                   (or (getf event :cookie-shape) "n/a"))))
    (otherwise nil)))

(defun make-dmx-repair-auth-state-machine-run
    (&key result auth-context client debug-events)
  (let* ((machine (make-dmx-repair-auth-state-machine-definition))
         (events (hyperdoc::bounded-http-dmx-import-debug-events
                  (or debug-events
                      (and client
                           (typep client 'hyperdoc::http-dmx-import-client)
                           (copy-list
                            (hyperdoc::dmx-import-debug-events-of client)))
                      '())))
         (transition-trace
          (remove nil (mapcar #'repair-auth-debug-event->transition-trace-entry
                              events)))
         (evidence-trace
          (remove nil (mapcar #'repair-auth-debug-event->evidence-trace-entry
                              events)))
         (visited-states
          (remove-duplicates
           (remove nil
                   (append (mapcar (lambda (e) (getf e :from-state)) transition-trace)
                           (mapcar (lambda (e) (getf e :to-state)) transition-trace)
                           (mapcar (lambda (e) (getf e :to-state)) evidence-trace)))
           :test #'equal))
         (current-state
          (or (getf result :trace-state)
              (getf result :state)
              (and result
                   (if (getf result :success-p) :s12 :s13))
              (car (last visited-states))
              :s0))
         (run-status
          (cond ((eq current-state :s13) :failed)
                ((eq current-state :s12) :finished)
                (t :running))))
    (hyperdoc::make-state-machine-run
     :id "state-machine-run/dmx-repair-auth"
     :title "DMX repair-console authentication run"
     :summary "Concrete repair-console auth/bootstrap/session traversal."
     :machine machine
     :input auth-context
     :current-state current-state
     :visited-states visited-states
     :transition-trace transition-trace
     :evidence-trace evidence-trace
     :status run-status
     :failure-classification
     (and (eq run-status :failed)
          (or (getf result :outcome) :repair-failed))
     :notes
     (remove nil
             (list
              (when auth-context
                (list :label "Auth mode"
                      :detail (getf auth-context :auth-mode)))
              (when result
                (list :label "Outcome"
                      :detail (or (getf result :message)
                                  (getf result :outcome)))))))))


(defun dmx-repair-nonblank-string-p (value)
  (let ((string (and value
                     (string-trim '(#\Space #\Tab #\Newline #\Return)
                                  (princ-to-string value)))))
    (and string
         (> (length string) 0))))

(defun build-dmx-repair-auth-context (&key auth-mode username password
                                        authorization-header auth-token)
  (let* ((normalized-auth-mode
          (hyperdoc::normalize-http-dmx-import-auth-mode
           auth-mode
           'build-dmx-repair-auth-context))
         (username-provided-p (and (dmx-repair-nonblank-string-p username) t))
         (password-provided-p (and (dmx-repair-nonblank-string-p password) t))
         (header-provided-p
          (and (dmx-repair-nonblank-string-p authorization-header) t))
         (token-provided-p (and (dmx-repair-nonblank-string-p auth-token) t)))
    (list :auth-mode normalized-auth-mode
          :username-provided-p username-provided-p
          :password-provided-p password-provided-p
          :authorization-header-provided-p header-provided-p
          :auth-token-provided-p token-provided-p
          :credentials-captured-p
          (case normalized-auth-mode
            (:basic (and username-provided-p password-provided-p))
            (:header header-provided-p)
            (:token token-provided-p)))))

(defun find-dmx-repair-debug-event (events state)
  (find state
        events
        :key (lambda (event) (getf event :state))
        :test #'eq))

(defun capture-dmx-repair-client-readbacks (client topic-id topicmap-id)
  (let ((workspace nil)
        (workspace-read-p nil)
        (in-topicmap-p nil)
        (topicmap-read-p nil))
    (when (typep client 'hyperdoc::http-dmx-import-client)
      (handler-case
          (setf workspace
                (hyperdoc::dmx-import-read-topic-workspace client topic-id)
                workspace-read-p t)
        (error ()
          (setf workspace nil
                workspace-read-p nil)))
      (when topicmap-id
        (handler-case
            (setf in-topicmap-p
                  (and (hyperdoc::dmx-import-topic-in-topicmap-p
                        client
                        topicmap-id
                        topic-id)
                       t)
                  topicmap-read-p t)
          (error ()
            (setf in-topicmap-p nil
                  topicmap-read-p nil)))))
    (list :workspace workspace
          :workspace-read-p workspace-read-p
          :in-topicmap-p in-topicmap-p
          :topicmap-read-p topicmap-read-p)))

(defun dmx-repair-debug-request-summary (event)
  (when event
    (format nil
            "~@[~A~]~@[ ~A~]~@[; auth=~A~]~@[; cookie=~A~]~@[; Accept=~A~]~@[; Content-Type=~A~]~@[; Content-Length=~D~]~@[; empty-body=~A~]"
            (and (getf event :method)
                 (string-upcase (symbol-name (getf event :method))))
            (getf event :path)
            (getf event :authorization-scheme)
            (getf event :cookie-shape)
            (getf event :accept-header)
            (getf event :content-type)
            (getf event :content-length)
            (and (member :empty-body-p event)
                 (yes/no-label (getf event :empty-body-p))))))

(defun dmx-repair-debug-response-summary (event)
  (when event
    (format nil
            "~@[status ~D~]~@[; JSESSIONID-cookie-observed=~A~]~@[; session-captured=~A~]"
            (getf event :status-code)
            (and (member :set-cookie-jsessionid-p event)
                 (yes/no-label (getf event :set-cookie-jsessionid-p)))
            (and (member :session-cookie-captured-p event)
                 (yes/no-label (getf event :session-cookie-captured-p))))))

(defun dmx-repair-debug-event-pair-summary (events)
  (let ((request-parts (remove nil
                               (mapcar #'dmx-repair-debug-request-summary
                                       events)))
        (response-parts (remove nil
                                (mapcar #'dmx-repair-debug-response-summary
                                        events))))
    (values (and request-parts
                 (format nil "~{~A~^ | ~}" request-parts))
            (and response-parts
                 (format nil "~{~A~^ | ~}" response-parts)))))

(defun dmx-repair-debug-ui-evidence (state auth-context result)
  (case state
    (:s0
     (if (getf auth-context :credentials-captured-p)
         "The repair action fired after credentials were already entered, so the blank-input idle state is not part of this captured run."
         "The repair action fired without the selected credentials present."))
    (:s1
     (format nil
             "UI inputs captured for ~A: username=~A, password=~A, header=~A, token=~A."
             (dmx-repair-console-auth-mode-label (getf auth-context :auth-mode))
             (yes/no-label (getf auth-context :username-provided-p))
             (yes/no-label (getf auth-context :password-provided-p))
             (yes/no-label (getf auth-context :authorization-header-provided-p))
             (yes/no-label (getf auth-context :auth-token-provided-p))))
    (:s2
     (format nil
             "Active mode row selected ~A."
             (dmx-repair-console-auth-mode-label (getf auth-context :auth-mode))))
    (:s11
     (format nil
             "Result readback currently shows workspace ~:[n/a~;present~] and selected topicmap membership ~A."
             (getf result :result-workspace-id)
             (yes/no-label (getf result :result-in-topicmap-p))))
    ((:s12 :s13)
     (format nil
             "Outcome row shows ~A with message: ~A"
             (dmx-repair-console-outcome-label result)
             (or (getf result :message) "n/a")))
    (otherwise
     "See the redacted request/response trace for this transition.")))

(defun dmx-repair-debug-summary-status (debug-report key)
  (getf debug-report key))

(defun dmx-repair-debug-current-state (success-p state-rows)
  (cond
    (success-p :s12)
    ((some (lambda (row)
             (and (eq (getf row :state) :s13)
                  (getf row :reached-p)))
           state-rows)
     :s13)
    (t
     (loop for state in '(:s11 :s10 :s9 :s8 :s7 :s6 :s5 :s4 :s3 :s2 :s1 :s0)
           thereis (and (let ((row (find state state-rows
                                         :key (lambda (entry) (getf entry :state))
                                         :test #'eq)))
                          (and row (getf row :reached-p)))
                        state)))))

(defun dmx-repair-debug-failure-transition
    (auth-context debug-report success-p)
  (cond
    (success-p nil)
    ((and (getf debug-report :bootstrap-ran-p)
          (let ((status (getf debug-report :bootstrap-status-code)))
            (and status (not (<= 200 status 299)))))
     (format nil
             "S5 -> S6 (bootstrap response returned ~D)"
             (getf debug-report :bootstrap-status-code)))
    ((and (getf debug-report :bootstrap-status-code)
          (not (getf debug-report :session-cookie-captured-p)))
     "S6 -> S7 (login returned without a captured JSESSIONID)")
    ((and (getf debug-report :guarded-put-status-code)
          (= (getf debug-report :guarded-put-status-code) 401)
          (not (getf debug-report :guarded-put-jsessionid-cookie-p)))
     "S8 -> S9 (guarded PUT was prepared without JSESSIONID)")
    ((and (getf debug-report :guarded-put-status-code)
          (= (getf debug-report :guarded-put-status-code) 401)
          (getf debug-report :guarded-put-jsessionid-cookie-p))
     "S9 -> S10 (guarded PUT reached DMX with JSESSIONID but returned 401)")
    ((and (null (getf debug-report :guarded-put-status-code))
          (getf debug-report :bootstrap-ran-p))
     "S8 -> S9 (guarded PUT was never sent after bootstrap)")
    ((and (eq (getf auth-context :auth-mode) :basic)
          (not (getf debug-report :bootstrap-ran-p)))
     "S4 -> S5 (basic-auth bootstrap never ran)")
    (t
     "S10 -> S13 (guarded repair terminated in error; inspect request and readback rows)")))

(defun build-dmx-repair-debug-state-row
    (state auth-context events result success-p)
  (let* ((spec (dmx-repair-auth-state-spec state))
         (event-list
          (case state
            (:s5 (remove nil (list (find-dmx-repair-debug-event
                                    events
                                    :s5-bootstrap-request-sent))))
            (:s6 (remove nil (list (find-dmx-repair-debug-event
                                    events
                                    :s6-bootstrap-response-received))))
            (:s7 (remove nil (list (find-dmx-repair-debug-event
                                    events
                                    :s7-session-material-extracted))))
            (:s8 (remove nil (list (find-dmx-repair-debug-event
                                    events
                                    :s8-guarded-repair-request-prepared))))
            (:s9 (remove nil (list (find-dmx-repair-debug-event
                                    events
                                    :s9-guarded-repair-request-sent))))
            (:s10 (remove nil (list (find-dmx-repair-debug-event
                                     events
                                     :s10-guarded-repair-response-received))))
            (:s11 (remove nil (list (find-dmx-repair-debug-event
                                     events
                                     :s11-workspace-readback)
                                    (find-dmx-repair-debug-event
                                     events
                                     :s11-topicmap-readback))))
            (:s3 (remove nil (list (find-dmx-repair-debug-event
                                    events
                                    :s3-explicit-auth-client-built))))
            (:s4 (remove nil (list (find-dmx-repair-debug-event
                                    events
                                    :s4-bootstrap-request-prepared))))
            (otherwise nil)))
         (reached-p
          (case state
            (:s0 (not (getf auth-context :credentials-captured-p)))
            (:s1 (and (getf auth-context :credentials-captured-p) t))
            (:s2 (and (getf auth-context :auth-mode) t))
            (:s3 (and event-list t))
            (:s4 (and event-list t))
            (:s5 (and event-list t))
            (:s6 (and event-list t))
            (:s7 (and event-list t))
            (:s8 (and event-list t))
            (:s9 (and event-list t))
            (:s10 (and event-list t))
            (:s11 (and event-list t))
            (:s12
             (and success-p
                  (eql (getf result :result-workspace-id)
                       hyperdoc::*dmx-context-window-workspace-id*)
                  (getf result :result-in-topicmap-p)))
            (:s13 (not success-p))
            (otherwise nil))))
    (multiple-value-bind (request-summary response-summary)
        (dmx-repair-debug-event-pair-summary event-list)
      (list :state state
            :label (getf spec :label)
            :reached-p reached-p
            :evidence
            (cond
              ((and (member state '(:s3 :s4 :s5 :s6 :s7 :s8 :s9 :s10 :s11))
                    event-list)
               (or response-summary request-summary "Event captured."))
              ((eq state :s12)
               (if reached-p
                   "Guarded repair finished with verified workspace assignment and preserved topicmap placement."
                   "The verified-success terminal state was not reached."))
              ((eq state :s13)
               (if reached-p
                   (or (getf result :message) "The guarded repair ended in error.")
                   "The guarded repair did not terminate in failure."))
              (t
               (dmx-repair-debug-ui-evidence state auth-context result)))
            :file (getf spec :file)
            :functions (getf spec :functions)
            :request request-summary
            :response response-summary
            :ui (dmx-repair-debug-ui-evidence state auth-context result)))))

(defun build-dmx-repair-debug-report (client auth-context result success-p)
  (let* ((events (and (typep client 'hyperdoc::http-dmx-import-client)
                      (hyperdoc::bounded-http-dmx-import-debug-events
                       (copy-tree (hyperdoc::dmx-import-debug-events-of
                                   client)))))
         (bootstrap-response
          (find-dmx-repair-debug-event events :s6-bootstrap-response-received))
         (session-extracted
          (find-dmx-repair-debug-event events :s7-session-material-extracted))
         (guarded-request
          (find-dmx-repair-debug-event events :s9-guarded-repair-request-sent))
         (guarded-response
          (find-dmx-repair-debug-event events :s10-guarded-repair-response-received))
         (workspace-readback
          (find-dmx-repair-debug-event events :s11-workspace-readback))
         (topicmap-readback
          (find-dmx-repair-debug-event events :s11-topicmap-readback))
         (state-rows
          (mapcar (lambda (state)
                    (build-dmx-repair-debug-state-row
                     state
                     auth-context
                     events
                     result
                     success-p))
                  '(:s0 :s1 :s2 :s3 :s4 :s5 :s6 :s7 :s8 :s9 :s10 :s11 :s12 :s13)))
         (current-state (dmx-repair-debug-current-state success-p state-rows))
         (summary
          (list :auth-mode (getf auth-context :auth-mode)
                :credentials-captured-p
                (getf auth-context :credentials-captured-p)
                :bootstrap-ran-p
                (and (find-dmx-repair-debug-event events
                                                  :s5-bootstrap-request-sent)
                     t)
                :bootstrap-status-code
                (getf bootstrap-response :status-code)
                :bootstrap-set-cookie-jsessionid-p
                (and bootstrap-response
                     (getf bootstrap-response :set-cookie-jsessionid-p))
                :session-cookie-captured-p
                (and session-extracted
                     (getf session-extracted :session-cookie-captured-p))
                :guarded-put-authorization-scheme
                (getf guarded-request :authorization-scheme)
                :guarded-put-cookie-shape
                (getf guarded-request :cookie-shape)
                :guarded-put-jsessionid-cookie-p
                (and guarded-request
                     (getf guarded-request :jsessionid-cookie-p))
                :guarded-put-workspace-cookie-p
                (and guarded-request
                     (getf guarded-request :workspace-cookie-p))
                :guarded-put-accept-header
                (getf guarded-request :accept-header)
                :guarded-put-content-type
                (getf guarded-request :content-type)
                :guarded-put-content-length
                (getf guarded-request :content-length)
                :guarded-put-empty-body-p
                (and guarded-request
                     (member :empty-body-p guarded-request)
                     (getf guarded-request :empty-body-p))
                :guarded-put-status-code
                (getf guarded-response :status-code)
                :workspace-readback-status-code
                (getf workspace-readback :status-code)
                :topicmap-readback-status-code
                (getf topicmap-readback :status-code)
                :current-state current-state
                :current-state-label
                (dmx-repair-auth-state-label current-state)
                :states state-rows
                :raw-events events)))
    (append summary
            (list :failure-transition
                  (dmx-repair-debug-failure-transition
                   auth-context
                   summary
                   success-p)))))

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

(defun make-explicit-dmx-repair-client
    (page &key auth-mode username password authorization-header auth-token
            (workspace-id hyperdoc::*dmx-context-window-workspace-id*))
  (hyperdoc::make-http-dmx-import-client-from-explicit-auth
   :base-url (hyperdoc::dmx-base-url-of (hyperbook:hyperbook-of page))
   :workspace-id workspace-id
   :auth-mode auth-mode
   :username username
   :password password
   :authorization-header authorization-header
   :auth-token auth-token
   :verbose nil))

(defun dmx-topic-proxy-assignment-topicmap-json (page workspace-topicmap-id)
  (let ((candidate (hyperdoc::dmx-topicmap-data-of page)))
    (if (and (hash-table-p candidate)
             (hyperdoc::dmx-import-object-id candidate))
        candidate
        (let ((topicmap (make-hash-table :test #'equal)))
          (setf (gethash "id" topicmap) workspace-topicmap-id
                (gethash "uri" topicmap) ""
                (gethash "typeUri" topicmap) "dmx.topicmaps.topicmap"
                (gethash "value" topicmap) "context-window"
                (gethash "children" topicmap) (make-hash-table :test #'equal)
                (gethash "topics" topicmap) #()
                (gethash "assocs" topicmap) #())
          topicmap))))

(defun make-dmx-topic-proxy-assignment-dry-run-client
    (page &key workspace-id workspace-topicmap-id)
  (let* ((topic (or (hyperdoc::dmx-topic-data-of page)
                    (error "Dry-run assignment requires fetched topic JSON")))
         (snapshot
          (hyperdoc::make-dmx-workspace-assignment-rehearsal-snapshot
           :topic topic
           :workspace-id workspace-id
           :workspace-topicmap-id workspace-topicmap-id
           :workspace-assignment (hyperdoc::dmx-workspace-data-of page)
           :topicmap-memberships
           (or (hyperdoc::dmx-topicmap-memberships-of page) #())
           :workspace-topicmap
           (dmx-topic-proxy-assignment-topicmap-json page
                                                     workspace-topicmap-id)
           :workspace-owner (hyperdoc::dmx-workspace-owner-of page))))
    (hyperdoc::make-memory-dmx-import-client-from-workspace-assignment-rehearsal-snapshot
     snapshot
     :next-topic-id 951000)))

(defun dmx-repair-result-with-overrides (result &rest overrides)
  (let ((copy (copy-list result)))
    (loop for (key value) on overrides by #'cddr
          do (setf (getf copy key) value))
    copy))

(defun sanitize-dmx-repair-result (topic-id diagnostics result
                                   &key dry-run auth-mode success-p message
                                     debug-report)
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
        (if (or (null auth-mode)
                (eq auth-mode :rehearsal))
            :rehearsal
            (hyperdoc::normalize-http-dmx-import-auth-mode
             auth-mode
             'sanitize-dmx-repair-result))
        :dry-run (and dry-run t)
        :success-p (and success-p t)
        :workspace-action (getf result :workspace-action)
        :result-workspace-id (getf result :result-workspace-id)
        :result-workspace-title (getf result :result-workspace-title)
        :result-in-topicmap-p (getf result :result-in-topicmap-p)
        :debug-report debug-report
        :message message))

(defun repair-topic-proxy-with-client
    (page client &key dry-run auth-mode auth-context
                   (workspace-id hyperdoc::*dmx-context-window-workspace-id*)
                   (workspace-topicmap-id (hyperdoc::dmx-topicmap-id-of page))
                   (refresh-page-p t) (record-result-p t) (force-diagnostics-p t))
  (when force-diagnostics-p
    (hyperdoc::ensure-dmx-topic-diagnostics page :force? t))
  (let* ((topic-id (hyperdoc::dmx-topic-id-of page))
         (diagnostics (hyperdoc::dmx-diagnostics-of page))
         (normalized-auth-context
          (or auth-context
              (list :auth-mode
                    (if (or (null auth-mode)
                            (eq auth-mode :rehearsal))
                        :rehearsal
                        (hyperdoc::normalize-http-dmx-import-auth-mode
                         auth-mode
                         'repair-topic-proxy-with-client))
                    :credentials-captured-p nil
                    :username-provided-p nil
                    :password-provided-p nil
                    :authorization-header-provided-p nil
                    :auth-token-provided-p nil)))
         (execution nil)
         (readbacks nil)
         (success-p nil)
         (message nil)
         (result nil))
    (handler-case
        (setf execution
              (hyperdoc::execute-dmx-workspace-topic-workspace-assignment-repair
               topic-id
               :workspace-id workspace-id
               :workspace-topicmap-id workspace-topicmap-id
               :client client
               :dry-run dry-run)
              success-p t
              message
              (cond
                (dry-run
                 "Dry-run completed; the guarded repair path is ready but no mutation was performed.")
                ((eql (getf execution :workspace-action) :already-assigned)
                 "The topic already had the requested workspace assignment.")
                (t
                 "Workspace assignment repair completed and read back live.")))
      (error (condition)
        (setf success-p nil
              message (princ-to-string condition))))
    (setf readbacks
          (capture-dmx-repair-client-readbacks client
                                               topic-id
                                               workspace-topicmap-id))
    (let* ((result-workspace
            (and (getf readbacks :workspace-read-p)
                 (getf readbacks :workspace)))
           (result-workspace-id
            (cond
              ((getf readbacks :workspace-read-p)
               (hyperdoc::dmx-import-object-id result-workspace))
              (t
               (and execution
                    (getf execution :result-workspace-id)))))
           (result-workspace-title
            (cond
              ((getf readbacks :workspace-read-p)
               (hyperdoc::dmx-workspace-title-from-topic result-workspace))
              (t
               (and execution
                    (getf execution :result-workspace-title)))))
           (result-in-topicmap-p
            (cond
              ((getf readbacks :topicmap-read-p)
               (and (getf readbacks :in-topicmap-p) t))
              (t
               (and execution
                    (getf execution :result-in-topicmap-p)))))
           (result-payload
            (append (or execution '())
                    (list :result-in-topicmap-p result-in-topicmap-p
                          :result-workspace-id result-workspace-id
                          :result-workspace-title result-workspace-title
                          :message message))))
      (setf result
            (sanitize-dmx-repair-result topic-id
                                        diagnostics
                                        result-payload
                                        :dry-run dry-run
                                        :auth-mode auth-mode
                                        :success-p success-p
                                        :debug-report
                                        (build-dmx-repair-debug-report
                                         client
                                         normalized-auth-context
                                         result-payload
                                         success-p)
                                        :message message)))
    (when refresh-page-p
      (handler-case
          (ensure-dmx-topic-proxy-readbacks page)
        (error (condition)
          (setf result
                (dmx-repair-result-with-overrides
                 result
                 :message
                 (format nil
                         "~A Readback refresh failed: ~A"
                         (or (getf result :message) "")
                         condition))))))
    (when record-result-p
      (setf (hyperdoc::dmx-repair-results-of page) (list result)))
    result))

(defun make-repair-triage-topic-localhost-rehearsal-snapshot (page topic-id)
  (hyperdoc::ensure-dmx-workspace-repair-triage page :force? t)
  (let ((proxy (or (find-repair-triage-proxy page topic-id)
                   (error "Topic ~D is not in the current shared-workspace repair backlog"
                          topic-id))))
    (hyperdoc::make-dmx-workspace-assignment-rehearsal-snapshot
     :topic (or (hyperdoc::dmx-topic-data-of proxy)
                (error "Missing captured topic JSON for rehearsal topic ~D"
                       topic-id))
     :workspace-id hyperdoc::*dmx-context-window-workspace-id*
     :workspace-topicmap-id (hyperdoc::dmx-topicmap-id-of page)
     :workspace-assignment (hyperdoc::dmx-workspace-data-of proxy)
     :topicmap-memberships (hyperdoc::dmx-topicmap-memberships-of proxy)
     :workspace-topicmap (or (hyperdoc::dmx-topicmap-projection-of page)
                             (error "Missing captured topicmap projection for rehearsal topic ~D"
                                    topic-id))
     :workspace-owner (hyperdoc::dmx-workspace-owner-of proxy))))

(defun repair-triage-topic-with-localhost-rehearsal (page topic-id &key dry-run)
  (let* ((proxy (or (find-repair-triage-proxy page topic-id)
                    (error "Topic ~D is not in the current shared-workspace repair backlog"
                           topic-id)))
         (snapshot
          (make-repair-triage-topic-localhost-rehearsal-snapshot page topic-id))
         (client
          (hyperdoc::make-memory-dmx-import-client-from-workspace-assignment-rehearsal-snapshot
           snapshot
           :next-topic-id 951000)))
    (let ((hyperdoc::*dmx-workspace-journal-suppressed-p* t))
      (declare (special hyperdoc::*dmx-workspace-journal-suppressed-p*))
      (repair-topic-proxy-with-client proxy
                                      client
                                      :dry-run dry-run
                                      :auth-mode :rehearsal
                                      :auth-context
                                      (list :auth-mode :rehearsal
                                            :credentials-captured-p nil
                                            :username-provided-p nil
                                            :password-provided-p nil
                                            :authorization-header-provided-p nil
                                            :auth-token-provided-p nil)
                                      :refresh-page-p nil
                                      :record-result-p nil))))

(defun repair-workspace-triage-backlog-with-localhost-rehearsal
    (page &key dry-run)
  (loop for topic-id in (repair-workspace-triage-topic-ids page)
        collect (repair-triage-topic-with-localhost-rehearsal page
                                                              topic-id
                                                              :dry-run dry-run)))

(defun dmx-repair-result-with-localhost-rehearsal
    (result rehearsal-result &key remote-attempted-p)
  (dmx-repair-result-with-overrides
   result
   :localhost-rehearsal-ran-p t
   :localhost-rehearsal-result rehearsal-result
   :localhost-rehearsal-success-p
   (and (getf rehearsal-result :success-p) t)
   :message
   (if remote-attempted-p
       (format nil "Localhost rehearsal succeeded. ~A"
               (or (getf result :message) "n/a"))
       (format nil
               "Localhost rehearsal failed; remote repair not attempted. ~A"
               (or (getf rehearsal-result :message) "n/a")))))

(defun repair-triage-topic-with-explicit-auth
    (page topic-id &key dry-run auth-mode username password
                     authorization-header auth-token)
  (let* ((rehearsal-result
          (repair-triage-topic-with-localhost-rehearsal page
                                                        topic-id
                                                        :dry-run dry-run))
         (result
          (if (getf rehearsal-result :success-p)
              (let* ((auth-context
                      (build-dmx-repair-auth-context
                       :auth-mode auth-mode
                       :username username
                       :password password
                       :authorization-header authorization-header
                       :auth-token auth-token))
                     (client
                      (make-explicit-dmx-repair-client
                       page
                       :auth-mode auth-mode
                       :username username
                       :password password
                       :authorization-header authorization-header
                       :auth-token auth-token))
                     (remote-result
                      (repair-triage-topic-with-client page
                                                       topic-id
                                                       client
                                                       :dry-run dry-run
                                                       :auth-mode auth-mode
                                                       :auth-context
                                                       auth-context)))
                (dmx-repair-result-with-localhost-rehearsal
                 remote-result
                 rehearsal-result
                 :remote-attempted-p t))
              (dmx-repair-result-with-localhost-rehearsal
               rehearsal-result
               rehearsal-result
               :remote-attempted-p nil))))
    (setf (hyperdoc::dmx-repair-results-of page) (list result)
          (hyperdoc::dmx-repair-summary-of page)
          (list :count 1
                :dry-run (and dry-run t)
                :success-count (if (getf result :success-p) 1 0)
                :error-count (if (getf result :success-p) 0 1)
                :message (getf result :message)))
    (hyperdoc::ensure-dmx-workspace-repair-triage page :force? t)
    result))

(defun repair-topic-proxy-with-explicit-auth (page &key dry-run auth-mode
                                                     username password
                                                     authorization-header
                                                     auth-token
                                                     (workspace-id
                                                      hyperdoc::*dmx-context-window-workspace-id*)
                                                     (workspace-topicmap-id
                                                      (hyperdoc::dmx-topicmap-id-of
                                                       page)))
  (let* ((auth-context
          (build-dmx-repair-auth-context
           :auth-mode auth-mode
           :username username
           :password password
           :authorization-header authorization-header
           :auth-token auth-token))
         (client (make-explicit-dmx-repair-client
                  page
                  :auth-mode auth-mode
                  :username username
                  :password password
                  :authorization-header authorization-header
                  :auth-token auth-token
                  :workspace-id workspace-id)))
    (repair-topic-proxy-with-client page
                                    client
                                    :dry-run dry-run
                                    :auth-mode auth-mode
                                    :auth-context auth-context
                                    :workspace-id workspace-id
                                    :workspace-topicmap-id
                                    workspace-topicmap-id)))

(defun repair-topic-proxy-assignment-dry-run
    (page &key (workspace-id hyperdoc::*dmx-context-window-workspace-id*)
            (workspace-topicmap-id (hyperdoc::dmx-topicmap-id-of page)))
  (handler-case
      (let ((client
             (make-dmx-topic-proxy-assignment-dry-run-client
              page
              :workspace-id workspace-id
              :workspace-topicmap-id workspace-topicmap-id)))
        (let ((hyperdoc::*workspace-journal-sink* :hyperdoc-local)
              (hyperdoc::*allow-dmx-workspace-journal-writes* nil))
          (repair-topic-proxy-with-client
           page
           client
           :dry-run t
           :auth-mode :rehearsal
           :auth-context
           (list :auth-mode :rehearsal
                 :credentials-captured-p nil
                 :username-provided-p nil
                 :password-provided-p nil
                 :authorization-header-provided-p nil
                 :auth-token-provided-p nil)
           :workspace-id workspace-id
           :workspace-topicmap-id workspace-topicmap-id
           :refresh-page-p nil
           :force-diagnostics-p nil)))
    (error (condition)
      (let* ((topic-id (hyperdoc::dmx-topic-id-of page))
             (diagnostics (hyperdoc::dmx-diagnostics-of page))
             (result
              (sanitize-dmx-repair-result
               topic-id
               diagnostics
               (list :workspace-action :assign
                     :result-in-topicmap-p
                     (and diagnostics
                          (hyperdoc::dmx-topic-diagnostics-selected-topicmap-membership-p
                           diagnostics)))
               :dry-run t
               :auth-mode :rehearsal
               :success-p nil
               :debug-report
               (list :auth-mode :rehearsal
                     :current-state-label "local-dry-run-unavailable"
                     :failure-transition :missing-fetched-data)
               :message
               (format nil
                       "Local dry-run could not be built from fetched proxy data: ~A"
                       condition))))
        (setf (hyperdoc::dmx-repair-results-of page) (list result))
        result))))

(defun run-dmx-topic-proxy-inline-workspace-assignment
    (page &key dry-run auth-mode username password authorization-header
            auth-token
            (workspace-id hyperdoc::*dmx-context-window-workspace-id*)
            (workspace-topicmap-id (hyperdoc::dmx-topicmap-id-of page)))
  (if dry-run
      (repair-topic-proxy-assignment-dry-run
       page
       :workspace-id workspace-id
       :workspace-topicmap-id workspace-topicmap-id)
      (let ((hyperdoc::*workspace-journal-sink* :hyperdoc-local)
            (hyperdoc::*allow-dmx-workspace-journal-writes* nil))
        (repair-topic-proxy-with-explicit-auth
         page
         :dry-run nil
         :auth-mode auth-mode
         :username username
         :password password
         :authorization-header authorization-header
         :auth-token auth-token
         :workspace-id workspace-id
         :workspace-topicmap-id workspace-topicmap-id))))

(defun repair-workspace-triage-topic-ids (page)
  (hyperdoc::ensure-dmx-workspace-repair-triage page :force? t)
  (mapcar #'hyperdoc::dmx-topic-id-of
          (hyperdoc::dmx-repair-topic-proxies-of page)))

(defun find-repair-triage-proxy (page topic-id)
  (find topic-id
        (hyperdoc::dmx-repair-topic-proxies-of page)
        :key #'hyperdoc::dmx-topic-id-of
        :test #'eql))

(defun repair-triage-topic-with-client (page topic-id client
                                        &key dry-run auth-mode auth-context)
  (let* ((proxy (or (find-repair-triage-proxy page topic-id)
                    (hyperdoc::make-dmx-shared-workspace-topic-proxy
                     topic-id
                     :topicmap-id (hyperdoc::dmx-topicmap-id-of page)
                     :base-url (hyperdoc::dmx-base-url-of
                                (hyperbook:hyperbook-of page))))))
    (repair-topic-proxy-with-client proxy
                                    client
                                    :dry-run dry-run
                                    :auth-mode auth-mode
                                    :auth-context auth-context)))

(defun repair-workspace-triage-backlog-with-client
    (page client &key dry-run auth-mode auth-context)
  (let* ((topic-ids (repair-workspace-triage-topic-ids page))
         (results (loop for topic-id in topic-ids
                        collect (repair-triage-topic-with-client page
                                                                 topic-id
                                                                 client
                                                                 :dry-run dry-run
                                                                 :auth-mode auth-mode
                                                                 :auth-context auth-context))))
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
  (let* ((auth-context nil)
         (client nil))
    (let* ((rehearsal-results
            (repair-workspace-triage-backlog-with-localhost-rehearsal
             page
             :dry-run dry-run))
           (all-rehearsals-succeeded-p
            (every (lambda (result) (getf result :success-p))
                   rehearsal-results))
           (remote-results
            (and all-rehearsals-succeeded-p
                 (setf auth-context
                       (build-dmx-repair-auth-context
                        :auth-mode auth-mode
                        :username username
                        :password password
                        :authorization-header authorization-header
                        :auth-token auth-token)
                       client
                       (make-explicit-dmx-repair-client
                        page
                        :auth-mode auth-mode
                        :username username
                        :password password
                        :authorization-header authorization-header
                        :auth-token auth-token))
                 (repair-workspace-triage-backlog-with-client page
                                                              client
                                                              :dry-run dry-run
                                                              :auth-mode auth-mode
                                                              :auth-context
                                                              auth-context)))
           (final-results
            (if all-rehearsals-succeeded-p
                (loop for remote-result in remote-results
                      for rehearsal-result in rehearsal-results
                      collect (dmx-repair-result-with-localhost-rehearsal
                               remote-result
                               rehearsal-result
                               :remote-attempted-p t))
                (mapcar (lambda (rehearsal-result)
                          (dmx-repair-result-with-localhost-rehearsal
                           rehearsal-result
                           rehearsal-result
                           :remote-attempted-p nil))
                        rehearsal-results))))
      (setf (hyperdoc::dmx-repair-results-of page) final-results
            (hyperdoc::dmx-repair-summary-of page)
            (list :count (length final-results)
                  :dry-run (and dry-run t)
                  :success-count (count-if (lambda (result)
                                             (getf result :success-p))
                                           final-results)
                  :error-count (count-if-not (lambda (result)
                                               (getf result :success-p))
                                             final-results)
                  :message
                  (if all-rehearsals-succeeded-p
                      "Localhost rehearsal succeeded before the remote backlog action."
                      "Localhost rehearsal failed for at least one backlog item, so remote repair was not attempted.")))
      final-results)))

(defun render-dmx-shared-workspace-repair-console-body (page)
  (let ((repair-proxies (hyperdoc::dmx-repair-topic-proxies-of page)))
    (views:html
     (:p (views:esc
          "Diagnosis stays read-only in the other views. This console is the separate authenticated mutation surface for repair_workspace_topic_assignment, and the batch affordance is only a guarded wrapper over repeated repair_workspace_topic_assignment calls."))
     (:table :class "inspector-table"
             (:tr (:td (views:esc "Target workspace assignment"))
                  (:td (render-maybe-code
                        (hyperdoc::dmx-workspace-id-of page))))
             (:tr (:td (views:esc "Selected topicmap placement"))
                  (:td (render-maybe-code
                        (hyperdoc::dmx-topicmap-id-of page))))
             (:tr (:td (views:esc "Selected row operation"))
                  (:td (:tt (views:esc "repair_workspace_topic_assignment"))))
             (:tr (:td (views:esc "Guarded batch wrapper"))
                  (:td (:tt (views:esc
                             "repair all missing workspace assignments"))))
             (:tr (:td (views:esc "Current actionable missing assignments"))
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
                 "Only the fields required by the active credential mode are used for the current action. Foreign objects stay excluded from this console, and already-correct objects stay out of the actionable missing-assignment set."))
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
              (repair-triage-topic-with-explicit-auth
               page
               (parse-integer (lwcells:cell-ref selected-topic-cell))
               :dry-run t
               :auth-mode (lwcells:cell-ref mode-cell)
               :username (lwcells:cell-ref username-cell)
               :password (lwcells:cell-ref password-cell)
               :authorization-header (lwcells:cell-ref header-cell)
               :auth-token (lwcells:cell-ref token-cell))
              t)
             "Run repair_workspace_topic_assignment for the selected topic without mutating DMX")
            " "
            (views:action-button
             "Repair selected topic"
             (views:thunk
              (repair-triage-topic-with-explicit-auth
               page
               (parse-integer (lwcells:cell-ref selected-topic-cell))
               :dry-run nil
               :auth-mode (lwcells:cell-ref mode-cell)
               :username (lwcells:cell-ref username-cell)
               :password (lwcells:cell-ref password-cell)
               :authorization-header (lwcells:cell-ref header-cell)
               :auth-token (lwcells:cell-ref token-cell))
              t)
             "Run repair_workspace_topic_assignment for the selected topic")
            " "
            (views:action-button
             "Dry-run all missing workspace assignments"
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
             "Run the guarded batch wrapper without mutating DMX")
            " "
            (views:action-button
             "Repair all missing workspace assignments"
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
             "Repair the actionable missing-assignment set via repeated repair_workspace_topic_assignment")))
         (views:html
          (:p (views:esc
               "There are currently no actionable missing assignments, so the repair console has nothing to mutate."))))
     (:h4 "Per-topic live result readback")
     (when-let (summary (hyperdoc::dmx-repair-summary-of page))
       (views:html
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Recorded result count"))
                     (:td (render-maybe-code (getf summary :count))))
                (:tr (:td (views:esc "Dry-run"))
                     (:td (:tt (views:esc
                                (yes/no-label (getf summary :dry-run))))))
                (:tr (:td (views:esc "Successful results"))
                     (:td (render-maybe-code (getf summary :success-count))))
                (:tr (:td (views:esc "Error results"))
                     (:td (render-maybe-code (getf summary :error-count))))
                (when-let (message (getf summary :message))
                  (views:html
                   (:tr (:td (views:esc "Summary"))
                        (:td (views:esc message))))))))
     (render-dmx-repair-results-table page
                                      (hyperdoc::dmx-repair-results-of page)
                                      :topicmap-id (hyperdoc::dmx-topicmap-id-of page))
     (render-dmx-repair-debug-traces
      (hyperdoc::dmx-repair-results-of page)))))

(defun render-dmx-repair-results-table (page results &key topicmap-id)
  (if results
      (views:html
       (:table :class "inspector-table"
               (:tr (:th (views:esc "Topic"))
                    (:th (views:esc "Title/value"))
                    (:th (views:esc "Operational state"))
                    (:th (views:esc "Auth mode"))
                    (:th (views:esc "Dry-run"))
                    (:th (views:esc "Workspace readback"))
                    (:th (views:esc
                          (format nil "In topicmap ~D"
                                  (or topicmap-id
                                      (hyperdoc::dmx-topicmap-id-of page)))))
                    (:th (views:esc "Outcome"))
                    (:th (views:esc "Trace state"))
                    (:th (views:esc "Message")))
               (loop for result in results
                     do (let ((topic-id (getf result :topic-id))
                              (workspace-id (getf result :result-workspace-id))
                              (workspace-title (getf result :result-workspace-title))
                              (debug-report (getf result :debug-report)))
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
                                       (or (dmx-repair-result-operational-state-label
                                            page
                                            result)
                                           "n/a"))))
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
                            (:td (:tt (views:esc
                                       (or (and debug-report
                                                (getf debug-report
                                                      :current-state-label))
                                           "n/a"))))
                            (:td (views:esc (or (getf result :message) "n/a")))))))))
      (views:html (:span :style "opacity: 0.55;" "No repair attempts recorded yet."))))

(defun render-dmx-repair-debug-summary (debug-report)
  (when debug-report
    (views:html
     (:table :class "inspector-table"
             (:tr (:td (views:esc "Current state"))
                  (:td (:tt (views:esc
                             (or (getf debug-report :current-state-label)
                                 "n/a")))))
             (:tr (:td (views:esc "Failing transition"))
                  (:td (:tt (views:esc
                             (or (getf debug-report :failure-transition)
                                 "n/a")))))
             (:tr (:td (views:esc "Login bootstrap ran"))
                  (:td (:tt (views:esc
                             (yes/no-label
                              (getf debug-report :bootstrap-ran-p))))))
             (:tr (:td (views:esc "Bootstrap status"))
                  (:td (render-maybe-code
                        (getf debug-report :bootstrap-status-code))))
             (:tr (:td (views:esc "Set-Cookie JSESSIONID received"))
                  (:td (:tt (views:esc
                             (yes/no-label
                              (getf debug-report
                                    :bootstrap-set-cookie-jsessionid-p))))))
             (:tr (:td (views:esc "JSESSIONID captured in memory"))
                  (:td (:tt (views:esc
                             (yes/no-label
                              (getf debug-report :session-cookie-captured-p))))))
             (:tr (:td (views:esc "Guarded PUT auth"))
                  (:td (:tt (views:esc
                             (or (getf debug-report
                                       :guarded-put-authorization-scheme)
                                 "none")))))
             (:tr (:td (views:esc "Guarded PUT cookie shape"))
                  (:td (:tt (views:esc
                             (or (getf debug-report :guarded-put-cookie-shape)
                                 "n/a")))))
             (:tr (:td (views:esc "Guarded PUT carries JSESSIONID"))
                  (:td (:tt (views:esc
                             (yes/no-label
                              (getf debug-report
                                    :guarded-put-jsessionid-cookie-p))))))
             (:tr (:td (views:esc "Guarded PUT carries dmx_workspace_id=919815"))
                  (:td (:tt (views:esc
                             (yes/no-label
                              (getf debug-report
                                    :guarded-put-workspace-cookie-p))))))
             (:tr (:td (views:esc "Guarded PUT Accept"))
                  (:td (views:html
                        (:code (views:esc
                                (or (getf debug-report
                                          :guarded-put-accept-header)
                                    "n/a"))))))
             (:tr (:td (views:esc "Guarded PUT body"))
                  (:td (views:esc
                        (format nil
                                "empty=~A, content-length=~A, content-type=~A"
                                (yes/no-label
                                 (getf debug-report
                                       :guarded-put-empty-body-p))
                                (or (getf debug-report
                                          :guarded-put-content-length)
                                    "n/a")
                                (or (getf debug-report
                                          :guarded-put-content-type)
                                    "none")))))
             (:tr (:td (views:esc "Guarded PUT status"))
                  (:td (render-maybe-code
                        (getf debug-report :guarded-put-status-code))))
             (:tr (:td (views:esc "Workspace readback status"))
                  (:td (render-maybe-code
                        (getf debug-report
                              :workspace-readback-status-code))))
             (:tr (:td (views:esc "Topicmap readback status"))
                  (:td (render-maybe-code
                        (getf debug-report
                              :topicmap-readback-status-code))))))))

(defun render-dmx-repair-debug-state-table (debug-report)
  (when-let (states (and debug-report
                         (getf debug-report :states)))
    (views:html
     (:table :class "inspector-table"
             (:tr (:th (views:esc "State"))
                  (:th (views:esc "Reached"))
                  (:th (views:esc "Evidence"))
                  (:th (views:esc "Source"))
                  (:th (views:esc "Request"))
                  (:th (views:esc "Response"))
                  (:th (views:esc "UI/readback")))
             (dolist (state-row states)
               (views:html
                (:tr
                 (:td (:tt (views:esc (getf state-row :label))))
                 (:td (:tt (views:esc
                            (yes/no-label (getf state-row :reached-p)))))
                 (:td (views:esc (or (getf state-row :evidence) "n/a")))
                 (:td
                  (views:html
                   (:div (:code (views:esc (or (getf state-row :file)
                                               "n/a"))))
                   (:div (:tt (views:esc
                               (format nil
                                       "~{~A~^, ~}"
                                       (or (getf state-row :functions)
                                           '("n/a"))))))))
                 (:td (views:esc (or (getf state-row :request) "n/a")))
                 (:td (views:esc (or (getf state-row :response) "n/a")))
                 (:td (views:esc (or (getf state-row :ui) "n/a"))))))))))

(defun render-dmx-repair-debug-traces (results)
  (when (some (lambda (result) (getf result :debug-report)) results)
    (views:html
     (:h4 "Redacted auth trace")
     (:p (views:esc
          "This debug surface keeps credentials redacted while exposing the current repair-console state machine, the bootstrap/session transitions, the guarded PUT contract, and the live readback statuses for workspace assignment and topicmap membership."))
     (dolist (result results)
       (let ((debug-report (getf result :debug-report))
             (topic-id (getf result :topic-id)))
         (when debug-report
           (views:html
            (:h5 (views:esc (format nil "Topic ~D" topic-id)))
            (render-dmx-repair-debug-summary debug-report)
            (render-dmx-repair-debug-state-table debug-report))))))))

(defun dmx-auth-example-display-value (value &key (fallback "n/a"))
  (cond
    ((null value)
     (views:html (:span :style "opacity: 0.55;" (views:esc fallback))))
    ((or (stringp value)
         (numberp value)
         (keywordp value)
         (symbolp value))
     (views:html (:code (views:esc (format nil "~A" value)))))
    (t
     (views:html (:code (views:esc (princ-to-string value)))))))

(defun render-dmx-auth-key-value-rows (rows)
  (dolist (row rows)
    (views:html
     (:tr (:th (views:esc (car row)))
          (:td (dmx-auth-example-display-value (cdr row)))))))

(defun render-dmx-auth-key-value-table (rows &key empty-label)
  (if rows
      (views:html
       (:table :class "inspector-table"
               (render-dmx-auth-key-value-rows rows)))
      (views:html
       (:p (:span :style "opacity: 0.55;"
                  (views:esc (or empty-label "n/a")))))))

(defun render-dmx-auth-state-machine-table (steps)
  (if steps
      (views:html
       (:table :class "inspector-table"
               (:tr (:th "Step")
                    (:th "Classification")
                    (:th "Detail"))
               (dolist (step steps)
                 (views:html
                  (:tr (:td (:code (views:esc (or (getf step :label) "-"))))
                       (:td (:code (views:esc
                                    (or (getf step :classification) "-"))))
                       (:td (views:esc (or (getf step :detail) "-"))))))))
      (views:html
       (:p (:span :style "opacity: 0.55;" "No state-machine steps.")))))

(defun render-dmx-auth-contract-notes-table (notes)
  (if notes
      (views:html
       (:table :class "inspector-table"
               (:tr (:th "Note")
                    (:th "Classification")
                    (:th "Detail"))
               (dolist (note notes)
                 (views:html
                  (:tr (:td (:code (views:esc (or (getf note :label) "-"))))
                       (:td (:code (views:esc
                                    (or (getf note :classification) "-"))))
                       (:td (views:esc (or (getf note :detail) "-"))))))))
      (views:html
       (:p (:span :style "opacity: 0.55;" "No backend contract notes.")))))

(defun render-dmx-auth-source-evidence-table (entries)
  (if entries
      (views:html
       (:table :class "inspector-table"
               (:tr (:th "Layer")
                    (:th "Reference")
                    (:th "Detail"))
               (dolist (entry entries)
                 (views:html
                  (:tr (:td (:code (views:esc (or (getf entry :layer) "-"))))
                       (:td (:code (views:esc
                                    (or (getf entry :reference) "-"))))
                       (:td (views:esc (or (getf entry :detail) "-"))))))))
      (views:html
       (:p (:span :style "opacity: 0.55;" "No source evidence.")))))

(defun dmx-auth-bootstrap-path-label (example)
  (if (hyperdoc::dmx-auth-path-example-bootstrap-required-p-of example)
      "bootstrap-capable"
      "direct-header only"))

(defun dmx-auth-example-backend-note (example)
  (let* ((notes (hyperdoc::dmx-auth-path-example-notes-of example))
         (backend-note
          (find "Backend contract"
                notes
                :test #'string=
                :key (lambda (note) (getf note :label)))))
    (or (and backend-note (getf backend-note :detail))
        (let ((first-note (first notes)))
          (and first-note
               (getf first-note :detail)))
        "-")))

(defun render-dmx-auth-crosswalk-example-rows (examples)
  (dolist (example examples)
    (views:html
     (:tr (:td (views:object-ref example))
          (:td (:code (views:esc
                       (hyperdoc::dmx-auth-mode-label
                        (hyperdoc::dmx-auth-path-example-normalized-mode-of
                         example)))))
          (:td (:code (views:esc
                       (or (hyperdoc::dmx-auth-mode-example-detected-authorization-scheme-of
                            example)
                           "-"))))
          (:td (:code (views:esc
                       (or (hyperdoc::dmx-auth-mode-example-derived-authorization-header-of
                            example)
                           "-"))))
          (:td (:code (views:esc
                       (hyperdoc::dmx-auth-mode-example-summarized-request-auth-mode-of
                        example))))
          (:td (:code (views:esc
                       (dmx-auth-bootstrap-path-label example))))
          (:td (views:esc (dmx-auth-example-backend-note example)))))))

(defun render-dmx-auth-crosswalk-overview-table (crosswalk)
  (let ((examples (hyperdoc::dmx-auth-crosswalk-examples-of crosswalk)))
    (views:html
     (:table :class "inspector-table"
             (:tr (:th "Example")
                  (:th "Normalized mode")
                  (:th "Detected scheme")
                  (:th "Derived Authorization header")
                  (:th "Summarized request auth mode")
                  (:th "Path shape")
                  (:th "Backend note"))
             (render-dmx-auth-crosswalk-example-rows examples)))))

(defun render-dmx-auth-crosswalk-credentials-table (crosswalk)
  (let ((examples (hyperdoc::dmx-auth-crosswalk-examples-of crosswalk)))
    (views:html
     (:table :class "inspector-table"
             (:tr (:th "Example")
                  (:th "Raw fields")
                  (:th "Derived Credentials-like structure")
                  (:th "Expected cookie shape"))
             (dolist (example examples)
               (views:html
                (:tr (:td (views:object-ref example))
                     (:td (render-dmx-auth-key-value-table
                           (hyperdoc::dmx-auth-path-example-raw-input-of
                            example)
                           :empty-label "No raw fields."))
                     (:td (render-dmx-auth-key-value-table
                           (hyperdoc::dmx-auth-path-example-dmx-credentials-shape-of
                            example)
                           :empty-label
                           "No Credentials-like structure for this mode."))
                     (:td (:code (views:esc
                                  (hyperdoc::dmx-auth-mode-example-expected-cookie-shape-of
                                   example)))))))))))

(defmethod views:text-representation ((page hyperdoc::dmx-topic-proxy))
  (format nil "DMX topic ~D (topicmap ~D)"
          (hyperdoc::dmx-topic-id-of page)
          (hyperdoc::dmx-topicmap-id-of page)))

(defmethod views:text-representation ((page hyperdoc::dmx-workspace-repair-triage))
  (format nil "DMX workspace repair triage (topicmap ~D)"
          (hyperdoc::dmx-topicmap-id-of page)))

(defmethod views:text-representation
    ((graph hyperdoc::dmx-workspace-journal-reconcile-call-graph))
  (format nil "DMX workspace journal reconcile call graph (topicmap ~D)"
          (hyperdoc::dmx-workspace-journal-reconcile-call-graph-workspace-topicmap-id
           graph)))

(defmethod views:text-representation ((example hyperdoc::dmx-auth-path-example))
  (format nil "~A"
          (hyperdoc::title-of example)))

(defmethod views:text-representation ((crosswalk hyperdoc::dmx-auth-crosswalk))
  (format nil "~A"
          (hyperdoc::title-of crosswalk)))

(views:defview 👀overview (crosswalk hyperdoc::dmx-auth-crosswalk)
  (views:html-view :title "Overview" :priority 1
                   (views:html
                    (:p (views:esc (hyperdoc::summary-of crosswalk)))
                    (:p (views:esc
                         "This learning surface keeps the three HyperDoc DMX auth input modes explicit without widening the guarded write boundary or claiming live service auth."))
                    (render-dmx-auth-crosswalk-overview-table crosswalk))))

(views:defview 👀credentials-crosswalk (crosswalk hyperdoc::dmx-auth-crosswalk)
  (views:html-view :title "Credentials crosswalk" :priority 2
                   (views:html
                    (:p (views:esc
                         "The three-mode crosswalk keeps raw user-entered fields, derived Authorization headers, decoded Credentials-like summaries where safe, and the later cookie shape visible side by side."))
                    (render-dmx-auth-crosswalk-credentials-table crosswalk))))

(views:defview 👀overview (example hyperdoc::dmx-auth-path-example)
  (views:html-view :title "Overview" :priority 1
                   (views:html
                    (:p (views:esc (hyperdoc::summary-of example)))
                    (:table :class "inspector-table"
                            (:tr (:th "Input mode")
                                 (:td (:code (views:esc
                                              (format nil "~A"
                                                      (hyperdoc::dmx-auth-path-example-input-mode-of
                                                       example))))))
                            (:tr (:th "Normalized mode")
                                 (:td (:code (views:esc
                                              (hyperdoc::dmx-auth-mode-label
                                               (hyperdoc::dmx-auth-path-example-normalized-mode-of
                                                example))))))
                            (:tr (:th "Detected Authorization scheme")
                                 (:td (:code (views:esc
                                              (or (hyperdoc::dmx-auth-mode-example-detected-authorization-scheme-of
                                                   example)
                                                  "-")))))
                            (:tr (:th "AuthorizationMethod name")
                                 (:td (:code (views:esc
                                              (or (hyperdoc::dmx-auth-path-example-authorization-method-name-of
                                                   example)
                                                  "-")))))
                            (:tr (:th "Bootstrap path")
                                 (:td (:code (views:esc
                                              (dmx-auth-bootstrap-path-label example)))))
                            (:tr (:th "Derived Authorization header")
                                 (:td (:code (views:esc
                                              (or (hyperdoc::dmx-auth-mode-example-derived-authorization-header-of
                                                   example)
                                                  "-")))))
                            (:tr (:th "Expected cookie shape")
                                 (:td (:code (views:esc
                                              (hyperdoc::dmx-auth-mode-example-expected-cookie-shape-of
                                               example)))))
                            (:tr (:th "Summarized request auth mode")
                                 (:td (:code (views:esc
                                              (hyperdoc::dmx-auth-mode-example-summarized-request-auth-mode-of
                                               example)))))
                            (:tr (:th "Workspace id")
                                 (:td (:code (views:esc
                                              (format nil "~A"
                                                      (hyperdoc::dmx-auth-mode-example-workspace-id-of
                                                       example))))))
                            (:tr (:th "Topic id")
                                 (:td (:code (views:esc
                                              (format nil "~A"
                                                      (hyperdoc::dmx-auth-mode-example-topic-id-of
                                                       example)))))))
                    (:h4 "Raw user-entered fields")
                    (render-dmx-auth-key-value-table
                     (hyperdoc::dmx-auth-path-example-raw-input-of example)
                     :empty-label "No raw fields."))))

(views:defview 👀state-machine (example hyperdoc::dmx-auth-path-example)
  (views:html-view :title "State machine" :priority 2
                   (views:html
                    (:p (views:esc
                         "These steps keep UI capture, derived request shaping, DMX-core-native credential/session handling, and the later guarded request boundary separate."))
                    (render-dmx-auth-state-machine-table
                     (hyperdoc::dmx-auth-path-example-state-trace-of example)))))

(views:defview 👀derived-request-shapes (example hyperdoc::dmx-auth-path-example)
  (views:html-view :title "Derived request shapes" :priority 3
                   (views:html
                    (:h4 "Derived request summary")
                    (render-dmx-auth-key-value-table
                     (hyperdoc::dmx-auth-path-example-derived-request-shape-of example)
                     :empty-label "No derived request summary.")
                    (:h4 "Bootstrap request shape")
                    (render-dmx-auth-key-value-table
                     (hyperdoc::dmx-auth-mode-example-bootstrap-request-shape-of example)
                     :empty-label "No bootstrap request for this mode.")
                    (:h4 "Session transition")
                    (render-dmx-auth-key-value-table
                     (hyperdoc::dmx-auth-path-example-session-transition-of example)
                     :empty-label "No session transition for this mode.")
                    (:h4 "Post-bootstrap or guarded request shape")
                    (render-dmx-auth-key-value-table
                     (hyperdoc::dmx-auth-path-example-post-login-request-shape-of example)
                     :empty-label "No guarded request shape.")
                    (:p (views:esc
                         "JSESSIONID is shown only as the later session-backed aftermath of username/password bootstrap. It is not a primary input mode.")))))

(views:defview 👀credentials-crosswalk (example hyperdoc::dmx-auth-path-example)
  (views:html-view :title "Credentials crosswalk" :priority 4
                   (views:html
                    (:h4 "Raw user-entered fields")
                    (render-dmx-auth-key-value-table
                     (hyperdoc::dmx-auth-path-example-raw-input-of example)
                     :empty-label "No raw fields.")
                    (:h4 "Derived Authorization header")
                    (render-dmx-auth-key-value-table
                     (list (cons "Authorization header"
                                 (or (hyperdoc::dmx-auth-mode-example-derived-authorization-header-of
                                      example)
                                     "-"))
                           (cons "Detected scheme"
                                 (or (hyperdoc::dmx-auth-mode-example-detected-authorization-scheme-of
                                      example)
                                     "-"))
                           (cons "Path shape"
                                 (dmx-auth-bootstrap-path-label example))))
                    (:h4 "Derived Credentials-like structure")
                    (render-dmx-auth-key-value-table
                     (hyperdoc::dmx-auth-path-example-dmx-credentials-shape-of example)
                     :empty-label
                     "No DMX-core-native Credentials-like structure is assumed for this mode."))))

(views:defview 👀backend-contract-notes (example hyperdoc::dmx-auth-path-example)
  (views:html-view :title "DMX backend contract" :priority 5
                   (views:html
                    (:p (views:esc
                         "These notes keep DMX-core-native behavior, HyperDoc-derived operator inputs, and installation-dependent backend assumptions separate."))
                    (:h4 "Contract notes")
                    (render-dmx-auth-contract-notes-table
                     (hyperdoc::dmx-auth-path-example-notes-of example))
                    (:h4 "Installation dependencies")
                    (render-dmx-auth-contract-notes-table
                     (hyperdoc::dmx-auth-path-example-installation-dependencies-of example)))))

(views:defview 👀source-evidence-code-path (example hyperdoc::dmx-auth-path-example)
  (views:html-view :title "Source evidence / code path" :priority 6
                   (views:html
                    (:p (views:esc
                         "The crosswalk is grounded in the current HyperDoc auth normalizers and the DMX platform Credentials, AuthorizationMethod, and AnonymousAccessFilter path."))
                    (render-dmx-auth-source-evidence-table
                     (hyperdoc::dmx-auth-path-example-source-evidence-of example)))))

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
                          :url (hyperdoc::dmx-webclient-url page)))
                        nil)))

(defun render-dmx-topicmap-backed-title-bar-buttons (page)
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

(defmethod views:title-bar-action-buttons ((page hyperdoc::dmx-workspace-repair-triage))
  (render-dmx-topicmap-backed-title-bar-buttons page))

(defmethod views:title-bar-action-buttons
    ((page hyperdoc::dmx-shared-workspace-object))
  (render-dmx-topicmap-backed-title-bar-buttons page))

(defmethod views:title-bar-action-buttons
    ((page hyperdoc::dmx-shared-topicmap-object))
  (render-dmx-topicmap-backed-title-bar-buttons page))

(views:defview 👀meta (page hyperdoc::dmx-topic-proxy)
  (hyperdoc::ensure-dmx-topic-diagnostics page)
  (hyperdoc::ensure-dmx-related-topics page)
  (views:html-view :title "Meta" :priority 2
                   (let* ((topic-data (hyperdoc::dmx-topic-data-of page))
                          (diagnostics (hyperdoc::dmx-diagnostics-of page))
                          (carrier (and topic-data
                                        (dmx-meta-hyperdoc-annotation-carrier topic-data))))
                     (if topic-data
                         (views:html
                          (:p (views:esc
                               "Read-only DMX-inspired metadata view. The field groups mirror the DMX webclient Meta tab while preserving HyperDoc-specific annotation carrier evidence."))
                          (render-dmx-meta-identity-block page topic-data)
                          (render-dmx-meta-timestamps-block topic-data)
                          (render-dmx-meta-ownership-block page diagnostics)
                          (render-dmx-meta-topic-type-block page topic-data)
                          (when carrier
                            (render-dmx-meta-annotation-block carrier)))
                         (views:html
                          (:p (views:esc
                               "No fetched DMX topic data is available for the Meta view."))
                          (if-let (condition (hyperdoc::dmx-load-error-of page))
                              (views:object-ref condition)
                            (views:html (:span :style "opacity: 0.55;" "n/a"))))))))

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

(defun render-dmx-topic-proxy-workspace-assignment-repair-card
    (page diagnostics)
  (let* ((target-workspace-id hyperdoc::*dmx-context-window-workspace-id*)
         (topicmap-id (hyperdoc::dmx-topicmap-id-of page))
         (path (dmx-topic-proxy-assignment-path page target-workspace-id))
         (eligible-p
          (dmx-topic-proxy-workspace-assignment-repairable-p diagnostics))
         (public-assignment-blocked-p
          (dmx-topic-proxy-public-assignment-blocked-p diagnostics)))
    (views:html
     (:h4 "Workspace assignment")
     (:p (views:esc
          "Object-local assignment control. The dry-run uses the already fetched proxy data in a memory client; the live public assignment action is suppressed when DMX requires privileged initial assignment."))
     (when public-assignment-blocked-p
       (views:html
        (:p (:strong (views:esc
                      +dmx-topic-proxy-public-assignment-blocked-message+))
            (views:esc
             ". DMX's public REST route checks object WRITE before the initial workspace assignment exists, so this case must be repaired inside the DMX runtime."))))
     (:table :class "inspector-table"
             (:tr (:td (views:esc "Current workspace"))
                  (:td (if diagnostics
                           (render-workspace-reference page diagnostics)
                           (views:html
                            (:span :style "opacity: 0.55;" "n/a")))))
             (:tr (:td (views:esc "Selected topicmap"))
                  (:td (render-maybe-code topicmap-id)))
             (:tr (:td (views:esc "Target workspace default"))
                  (:td (views:esc
                        (dmx-topic-proxy-assignment-target-label
                         target-workspace-id))))
             (:tr (:td (views:esc "Operation preview"))
                  (:td (:code (views:esc
                               (format nil "PUT ~A" path)))))
             (:tr (:td (views:esc "Body"))
                  (:td (:code (views:esc
                               "zero-length body (Content-Length: 0)"))))
             (:tr (:td (views:esc "Accept"))
                  (:td (:code (views:esc "application/json"))))
             (:tr (:td (views:esc "Session/workspace cookie shape"))
                  (:td (:code
                        (views:esc
                         (format nil
                                 "JSESSIONID=<redacted>; dmx_workspace_id=~D"
                                 target-workspace-id)))))
             (:tr (:td (views:esc "Forbidden side effects"))
                  (:td (views:esc
                        "No topic upsert; no topicmap placement; no full annotation continuation; no DMX workspace-journal write.")))
             (:tr (:td (views:esc "Repair boundary"))
                  (:td (views:esc
                        (if public-assignment-blocked-p
                            +dmx-topic-proxy-public-assignment-blocked-message+
                            "Guarded public workspace assignment path"))))
             (:tr (:td (views:esc "Eligible"))
                  (:td (:tt (views:esc (yes/no-label eligible-p))))))
     (if eligible-p
         (let (workspace-cell mode-cell username-cell password-cell
                              header-cell token-cell)
           (views:html (:h5 "Guarded action"))
           (setf workspace-cell
                 (hvr:select
                  (list (cons (dmx-topic-proxy-assignment-target-label
                               target-workspace-id)
                              (format nil "~D" target-workspace-id)))
                  :label "Target workspace: "))
           (views:html (:br))
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
                 "Credential fields are ephemeral UI inputs for the next action only. Raw Authorization headers, cookies, tokens, passwords, and response bodies are not rendered in the result table."))
            (views:action-button
             "Dry-run assignment"
             (views:thunk
              (run-dmx-topic-proxy-inline-workspace-assignment
               page
               :dry-run t
               :auth-mode (lwcells:cell-ref mode-cell)
               :workspace-id
               (parse-integer (lwcells:cell-ref workspace-cell))
               :workspace-topicmap-id topicmap-id)
              t)
             "Plan the workspace assignment with a local memory client; no live HTTP call is made")
            (if public-assignment-blocked-p
                (views:html
                 (:p (views:esc
                      +dmx-topic-proxy-public-assignment-blocked-message+)
                     (views:esc
                      ". Do not run the public PUT from this inspector for the initial-assignment case.")))
                (views:html
                 " "
                 (views:action-button
                  "Assign workspace"
                  (views:thunk
                   (run-dmx-topic-proxy-inline-workspace-assignment
                    page
                    :dry-run nil
                    :auth-mode (lwcells:cell-ref mode-cell)
                    :username (lwcells:cell-ref username-cell)
                    :password (lwcells:cell-ref password-cell)
                    :authorization-header (lwcells:cell-ref header-cell)
                    :auth-token (lwcells:cell-ref token-cell)
                    :workspace-id
                    (parse-integer (lwcells:cell-ref workspace-cell))
                    :workspace-topicmap-id topicmap-id)
                   t)
                  (format nil
                          "Run the guarded zero-body PUT ~A through the existing explicit-auth repair executor"
                          path))))))
         (views:html
          (:p (views:esc
               "This topic is not currently an actionable missing-assignment candidate. The control remains read-only for already assigned or foreign topics.")))))))

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
                          (render-dmx-topic-proxy-workspace-assignment-repair-card
                           page
                           diagnostics)
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
                    (:a :href (hyperdoc::dmx-webclient-url page)
                        :target "_blank"
                        (views:esc "Open selected topic in DMX webclient")))))

(views:defview 👀url (page hyperdoc::dmx-topic-proxy)
  (views:html-view :title "URL" :priority 20
                   (views:html
                    (:p (views:esc
                         "Local deep links for DMX topic proxy objects are not routable yet. Use the launch expression below or the DMX webclient link instead of the generic HyperBook local route."))
                    (:table :class "inspector-table"
                            (:tr (:td (views:esc "Local route"))
                                 (:td (views:esc "not routable yet")))
                            (:tr (:td (views:esc "Launch expression"))
                                 (:td (:code
                                       (views:esc
                                        (dmx-topic-proxy-launch-expression page)))))
                            (:tr (:td (views:esc "DMX webclient"))
                                 (:td (:a :href (hyperdoc::dmx-webclient-url page)
                                          :target "_blank"
                                          (:code
                                           (views:esc
                                            (hyperdoc::dmx-webclient-url page))))))))))

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
                              (run-dmx-topic-proxy-inline-workspace-assignment
                               page
                               :dry-run t
                               :auth-mode (lwcells:cell-ref mode-cell)
                               :username (lwcells:cell-ref username-cell)
                               :password (lwcells:cell-ref password-cell)
                               :authorization-header (lwcells:cell-ref header-cell)
                               :auth-token (lwcells:cell-ref token-cell))
                              t)
                             "Run the guarded repair path without mutating DMX")
                            (if (dmx-topic-proxy-public-assignment-blocked-p diagnostics)
                                (views:html
                                 (:p (:strong
                                      (views:esc
                                       +dmx-topic-proxy-public-assignment-blocked-message+))
                                     (views:esc
                                      ". Use the DMX-side Gogo command runbook instead of the public workspace assignment route.")))
                                (views:html
                                 " "
                                 (views:action-button
                                  "Repair selected topic"
                                  (views:thunk
                                   (run-dmx-topic-proxy-inline-workspace-assignment
                                    page
                                    :dry-run nil
                                    :auth-mode (lwcells:cell-ref mode-cell)
                                    :username (lwcells:cell-ref username-cell)
                                    :password (lwcells:cell-ref password-cell)
                                    :authorization-header (lwcells:cell-ref header-cell)
                                    :auth-token (lwcells:cell-ref token-cell))
                                   t)
                                  (format nil
                                          "Assign workspace ~D in place while preserving topicmap ~D placement"
                                          (hyperdoc::dmx-workspace-id-of page)
                                          (hyperdoc::dmx-topicmap-id-of page)))))))))
                      (:h4 "Result readback")
                      (render-dmx-repair-results-table page
                                                       (hyperdoc::dmx-repair-results-of page)
                                                       :topicmap-id (hyperdoc::dmx-topicmap-id-of page))
                      (render-dmx-repair-debug-traces
                       (hyperdoc::dmx-repair-results-of page))))))

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
                   (render-dmx-shared-workspace-repair-console-body page)))

(views:defview 👀overview (page hyperdoc::dmx-shared-workspace-object)
  (hyperdoc::ensure-dmx-workspace-repair-triage page)
  (views:html-view :title "Overview" :priority 1
                   (views:html
                    (:p (views:esc
                         (format nil
                                 "This first-class workspace object keeps workspace assignment distinct from topicmap placement while centering the visible context-window blackboard in topicmap ~D."
                                 (hyperdoc::dmx-topicmap-id-of page))))
                    (render-dmx-shared-workspace-context-summary-table page))))

(views:defview 👀topics-missing-workspace-assignment
    (page hyperdoc::dmx-shared-workspace-object)
  (hyperdoc::ensure-dmx-workspace-repair-triage page)
  (views:html-view :title "Topics missing workspace assignment" :priority 2
                   (views:html
                    (:p (views:esc
                         (format nil
                                 "These topics are visible in topicmap ~D but still lack workspace assignment for workspace ~D. Foreign rows stay read-only as foreign-no-action; HyperDoc-owned rows stay read-only here as in-topicmap-but-unassigned until you move to Repair console."
                                 (hyperdoc::dmx-topicmap-id-of page)
                                 (hyperdoc::dmx-workspace-id-of page))))
                    (render-dmx-operational-topic-proxy-table
                     page
                     (hyperdoc::dmx-visible-but-unassigned-topic-proxies page)
                     :empty-message
                     "Every visible topic currently has workspace assignment or is outside the selected topicmap context."))))

(views:defview 👀assigned-topics (page hyperdoc::dmx-shared-workspace-object)
  (hyperdoc::ensure-dmx-workspace-repair-triage page)
  (views:html-view :title "Assigned topics" :priority 3
                   (views:html
                    (:p (views:esc
                         (format nil
                                 "These topics are visible in topicmap ~D and currently assigned to workspace ~D."
                                 (hyperdoc::dmx-topicmap-id-of page)
                                 (hyperdoc::dmx-workspace-id-of page))))
                    (render-dmx-operational-topic-proxy-table
                     page
                     (hyperdoc::dmx-visible-assigned-topic-proxies page)
                     :empty-message
                     (format nil
                             "No visible topics currently read back as assigned to workspace ~D."
                             (hyperdoc::dmx-workspace-id-of page))))))

(views:defview 👀repair-console (page hyperdoc::dmx-shared-workspace-object)
  (hyperdoc::ensure-dmx-workspace-repair-triage page)
  (views:html-view :title "Repair console" :priority 4
                   (render-dmx-shared-workspace-repair-console-body page)))

(views:defview 👀overview (page hyperdoc::dmx-shared-topicmap-object)
  (hyperdoc::ensure-dmx-workspace-repair-triage page)
  (views:html-view :title "Overview" :priority 1
                   (views:html
                    (:p (views:esc
                         (format nil
                                 "This first-class topicmap object models topicmap ~D as the visible context-window shared blackboard while keeping workspace assignment diagnosis separate from topicmap placement."
                                 (hyperdoc::dmx-topicmap-id-of page))))
                    (render-dmx-shared-workspace-context-summary-table page))))

(views:defview 👀visible-but-unassigned (page hyperdoc::dmx-shared-topicmap-object)
  (hyperdoc::ensure-dmx-workspace-repair-triage page)
  (views:html-view :title "Visible but unassigned" :priority 2
                   (views:html
                    (:p (views:esc
                         (format nil
                                 "This is the key triage view for topicmap ~D: visible topics that still lack workspace assignment for workspace ~D. Each row opens the existing single-topic Workspace diagnostics surface."
                                 (hyperdoc::dmx-topicmap-id-of page)
                                 (hyperdoc::dmx-workspace-id-of page))))
                    (render-dmx-operational-topic-proxy-table
                     page
                     (hyperdoc::dmx-visible-but-unassigned-topic-proxies page)
                     :empty-message
                     "No visible topics are currently missing workspace assignment."))))

(views:defview 👀visible-topics (page hyperdoc::dmx-shared-topicmap-object)
  (hyperdoc::ensure-dmx-workspace-repair-triage page)
  (views:html-view :title "Visible topics" :priority 3
                   (views:html
                    (:p (views:esc
                         (format nil
                                 "All currently visible topics in topicmap ~D, classified with the shared read-only operational vocabulary."
                                 (hyperdoc::dmx-topicmap-id-of page))))
                    (render-dmx-operational-topic-proxy-table
                     page
                     (hyperdoc::dmx-visible-topic-proxies page)
                     :empty-message
                     "No visible topics are currently available from the selected topicmap projection."))))

(views:defview 👀repair-console (page hyperdoc::dmx-shared-topicmap-object)
  (hyperdoc::ensure-dmx-workspace-repair-triage page)
  (views:html-view :title "Repair console" :priority 4
                   (render-dmx-shared-workspace-repair-console-body page)))

(defmethod code-path-graph-overview-extra-html
    ((graph hyperdoc::dmx-workspace-journal-reconcile-call-graph))
  (let ((topicmap-id
         (hyperdoc::dmx-workspace-journal-reconcile-call-graph-workspace-topicmap-id
          graph))
        (workspace-id
         (hyperdoc::dmx-workspace-journal-reconcile-call-graph-workspace-id
          graph))
        (note-topic-id
         (hyperdoc::dmx-workspace-journal-reconcile-call-graph-resolved-note-topic-id
          graph))
        (companion-topic-id
         (hyperdoc::dmx-workspace-journal-reconcile-call-graph-companion-journal-topic-id
          graph)))
    (views:html
     (:p (views:esc
          "The healthy handover note 923609 resolves and reads cleanly; the defect lives lower in reconcile-time handling of the companion workspace-journal note 924694. This view keeps the read path, the suppressed write edge, and the still-legitimate explicit write paths visible in one place."))
     (:table :class "inspector-table"
             (:tr (:td (views:esc "Workspace topicmap"))
                  (:td (views:object-ref
                        (hyperdoc::make-dmx-topicmap-proxy topicmap-id)
                        :display (format nil "~D" topicmap-id))))
             (:tr (:td (views:esc "Workspace"))
                  (:td (views:object-ref
                        (hyperdoc::make-dmx-topic-proxy
                         :topic-id workspace-id
                         :topicmap-id topicmap-id)
                        :display (format nil "~D" workspace-id))))
             (:tr (:td (views:esc "Healthy resolved note topic"))
                  (:td (views:object-ref
                        (hyperdoc::make-dmx-shared-workspace-topic-proxy
                         note-topic-id)
                        :display (format nil "~D" note-topic-id)
                        :select "Workspace diagnostics")))
             (:tr (:td (views:esc "Healthy topicmap-context assoc"))
                  (:td (render-maybe-code
                        (hyperdoc::dmx-workspace-journal-reconcile-call-graph-resolved-topicmap-context-assoc-id
                         graph))))
             (:tr (:td (views:esc "Healthy noteKey"))
                  (:td (render-maybe-code
                        (hyperdoc::dmx-workspace-journal-reconcile-call-graph-resolved-note-key
                         graph))))
             (:tr (:td (views:esc "Companion journal note"))
                  (:td (views:object-ref
                        (hyperdoc::make-dmx-shared-workspace-topic-proxy
                         companion-topic-id)
                        :display (format nil "~D" companion-topic-id)
                        :select "Workspace diagnostics"))))
     (:h4 "Call graph")
     (:pre :style "white-space: pre-wrap;"
           (views:esc (dmx-journal-call-graph-overview-diagram)))
     (:h4 "Observed failure surfaces")
     (:table :class "inspector-table"
             (:thead
              (:tr (:th (views:esc "Surface"))
                   (:th (views:esc "Endpoint"))
                   (:th (views:esc "Status"))
                   (:th (views:esc "Why it matters"))))
             (:tbody
              (dolist (row
                        (hyperdoc::dmx-workspace-journal-reconcile-call-graph-failing-endpoints
                         graph))
                (views:html
                 (:tr
                  (:td (views:esc (getf row :surface)))
                  (:td (:code (views:esc (getf row :endpoint))))
                  (:td (:tt (views:esc (getf row :status))))
                  (:td (views:esc (getf row :summary))))))))
     (:ul
      (:li (views:esc
            "reconcile=false remains the storage-preserving control path; it reads existing journal streams without synthesizing or persisting anything."))
      (:li (views:esc
            "reconcile=true may still synthesize diff events, but those events now stay in memory on the read path."))
      (:li (views:esc
            "Explicit write paths such as guarded updates and restores still use the append/persist edge intentionally."))))))

(views:defview 👀read-flow
    (graph hyperdoc::dmx-workspace-journal-reconcile-call-graph)
  (views:html-view :title "Read flow" :priority 2
                   (views:html
                    (:p (views:esc
                         "These are the active nodes and edges for reconcile-on-read after the patch. The path stays side-effect free by routing synthesized diff events to the in-memory apply helper instead of the append/persist path."))
                    (:table :class "inspector-table"
                            (:thead
                             (:tr (:th (views:esc "Node"))
                                  (:th (views:esc "Role"))
                                  (:th (views:esc "Source"))
                                  (:th (views:esc "Summary"))))
                            (:tbody
                             (dolist (node
                                       (remove-if (lambda (node)
                                                    (member (getf node :role)
                                                            '(:write-helper :write-entry
                                                              :backend-target)
                                                            :test #'eq))
                                                  (hyperdoc::code-path-graph-node-seq graph)))
                               (views:html
                                (:tr
                                 (:td (:tt (views:esc (getf node :label))))
                                 (:td (:tt (views:esc
                                            (hyperdoc::code-path-graph-role-label
                                             (getf node :role)))))
                                 (:td (render-code-path-graph-source node))
                                 (:td (views:esc (getf node :summary))))))))
                    (:h4 "Active reconcile-on-read edges")
                    (:table :class "inspector-table"
                            (:thead
                             (:tr (:th (views:esc "From"))
                                  (:th (views:esc "To"))
                                  (:th (views:esc "Kind"))
                                  (:th (views:esc "Summary"))))
                            (:tbody
                             (dolist (edge (hyperdoc::code-path-graph-active-edges graph))
                               (views:html
                                (:tr
                                 (:td (:tt (views:esc
                                            (hyperdoc::code-path-graph-node-label
                                             graph
                                             (getf edge :from)))))
                                 (:td (:tt (views:esc
                                            (hyperdoc::code-path-graph-node-label
                                             graph
                                             (getf edge :to)))))
                                 (:td (:tt (views:esc
                                            (hyperdoc::code-path-graph-edge-kind-label
                                             (getf edge :kind)))))
                                 (:td (views:esc (getf edge :summary)))))))))))

(views:defview 👀write-capable-edges
    (graph hyperdoc::dmx-workspace-journal-reconcile-call-graph)
  (views:html-view :title "Write-capable edges" :priority 3
                   (views:html
                    (:p (views:esc
                         "These edges can mutate or reattach the companion journal note. The first row is the edge that must stay suppressed during reconcile-on-read; the remaining rows are still legitimate on explicit write paths."))
                    (:table :class "inspector-table"
                            (:thead
                             (:tr (:th (views:esc "From"))
                                  (:th (views:esc "To"))
                                  (:th (views:esc "Edge kind"))
                                  (:th (views:esc "Reconcile-on-read status"))
                                  (:th (views:esc "Summary"))))
                            (:tbody
                             (dolist (edge
                                       (hyperdoc::code-path-graph-write-capable-edges graph))
                               (views:html
                                (:tr
                                 (:td (:tt (views:esc
                                            (hyperdoc::code-path-graph-node-label
                                             graph
                                             (getf edge :from)))))
                                 (:td (:tt (views:esc
                                            (hyperdoc::code-path-graph-node-label
                                             graph
                                             (getf edge :to)))))
                                 (:td (:tt (views:esc
                                            (hyperdoc::code-path-graph-edge-kind-label
                                             (getf edge :kind)))))
                                 (:td (:tt (views:esc
                                            (hyperdoc::code-path-graph-edge-status-label
                                             (getf edge :status)))))
                                 (:td (views:esc (getf edge :summary))))))))
                    (:ul
                     (:li (views:esc
                           "reconcile-subject -> append-events is the specific edge that used to let read reconciliation write-touch companion note 924694."))
                     (:li (views:esc
                           "append-events -> persist-stream remains valid for explicit guarded writes and restore journaling."))
                     (:li (views:esc
                           "persist-stream is the last HyperDoc-owned boundary before DMX update/create and topicmap reattach requests are sent."))))))

(defmethod code-path-graph-source-references-extra-html
    ((graph hyperdoc::dmx-workspace-journal-reconcile-call-graph))
  (views:html
   (:h4 "Open live DMX objects")
   (:ul
    (:li
     (views:object-ref
      (hyperdoc::make-dmx-topicmap-proxy
       (hyperdoc::dmx-workspace-journal-reconcile-call-graph-workspace-topicmap-id
        graph))
      :display "Topicmap 919822"))
    (:li
     (views:object-ref
      (hyperdoc::make-dmx-shared-workspace-topic-proxy
       (hyperdoc::dmx-workspace-journal-reconcile-call-graph-resolved-note-topic-id
        graph))
      :display "Healthy note topic 923609"
      :select "Workspace diagnostics"))
    (:li
     (views:object-ref
      (hyperdoc::make-dmx-shared-workspace-topic-proxy
       (hyperdoc::dmx-workspace-journal-reconcile-call-graph-companion-journal-topic-id
        graph))
      :display "Companion journal note 924694"
      :select "Workspace diagnostics")))))
