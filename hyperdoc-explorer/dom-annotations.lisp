;;;; DOM relation annotation explorer views
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defun maybe-dom-object-ref (value &key (fallback-empty ""))
  (cond
    ((null value)
     (views:html (views:esc fallback-empty)))
    ((or (stringp value)
         (pathnamep value)
         (keywordp value)
         (numberp value))
     (views:html (:tt (views:esc (format nil "~A" value)))))
    (t
     (views:object-ref value))))

(defun render-workspace-annotation-binding-player-row (binding player-key)
  (let ((player (and binding (gethash player-key binding))))
    (when player
      (views:html
        (:tr (:th (views:esc (format nil "~A role" player-key)))
             (:td (:tt (views:esc (or (gethash "role" player) "-")))))
        (:tr (:th (views:esc (format nil "~A ref kind" player-key)))
             (:td (:tt (views:esc (or (gethash "refKind" player) "-")))))
        (:tr (:th (views:esc (format nil "~A ref value" player-key)))
             (:td (:tt (views:esc (format nil "~A"
                                          (or (gethash "refValue" player) "-"))))))))))

(defun render-workspace-annotation-binding-table (binding)
  (if binding
      (views:html
        (:table :class "inspector-table"
                (:tr (:th "Binding type")
                     (:td (:tt (views:esc (or (gethash "bindingType" binding)
                                              "-")))))
                (render-workspace-annotation-binding-player-row binding "player1")
                (render-workspace-annotation-binding-player-row binding "player2")))
      (views:html
        (:p (:tt "-")))))

(defun workspace-annotation-persistence-client-label (client)
  (cond
    ((null client)
     "default live client")
    (t
     (format nil "~(~A~)" (class-name (class-of client))))))

(defun workspace-annotation-destination-label (destination source-slot)
  (when destination
    (workspace-annotation-render-value
     (dmx-workspace-annotation-destination-source-label
      (ecase source-slot
        (:source
         (dmx-workspace-annotation-destination-source destination))
        (:workspace-source
         (dmx-workspace-annotation-destination-workspace-source destination))
        (:topicmap-source
         (dmx-workspace-annotation-destination-topicmap-source destination)))))))

(defun render-workspace-annotation-destination-rows
    (&key workspace-id workspace-topicmap-id workspace-label
       workspace-topicmap-label destination-source-label
       workspace-source-label topicmap-source-label destination-rationale)
  (let ((resolved-workspace-label
          (or workspace-label
              (dmx-workspace-annotation-workspace-label workspace-id)))
        (resolved-topicmap-label
          (or workspace-topicmap-label
              (dmx-workspace-annotation-topicmap-label
               workspace-topicmap-id))))
    (views:html
      (:tr (:th "Workspace")
           (:td (:tt (views:esc
                      (workspace-annotation-render-value
                       resolved-workspace-label)))))
      (:tr (:th "Topicmap")
           (:td (:tt (views:esc
                      (workspace-annotation-render-value
                       resolved-topicmap-label)))))
      (:tr (:th "Workspace id")
           (:td (:tt (views:esc
                      (workspace-annotation-render-value workspace-id)))))
      (:tr (:th "Topicmap id")
           (:td (:tt (views:esc
                      (workspace-annotation-render-value
                       workspace-topicmap-id)))))
      (:tr (:th "Destination source")
           (:td (:tt (views:esc
                      (workspace-annotation-render-value
                       destination-source-label)))))
      (:tr (:th "Workspace source")
           (:td (:tt (views:esc
                      (workspace-annotation-render-value
                       workspace-source-label)))))
      (:tr (:th "Topicmap source")
           (:td (:tt (views:esc
                      (workspace-annotation-render-value
                       topicmap-source-label)))))
      (:tr (:th "Destination rationale")
           (:td (views:esc
                 (workspace-annotation-render-value
                  destination-rationale)))))))

(defun workspace-annotation-persistence-preview-journal-count (preview)
  (let ((events (and preview (getf preview :journal-event-preview))))
    (if events
        (length (hyperdoc::json-array-elements events))
        0)))

(defun render-workspace-annotation-persistence-preview (preview preview-error)
  (if preview-error
      (views:html
        (:h4 "Dry-run preview error")
        (:pre :style "white-space: pre-wrap"
              (views:esc (format nil "~A" preview-error))))
      (if preview
          (views:html
            (:table :class "inspector-table"
                    (:tr (:th "Annotation key")
                         (:td (:tt (views:esc (or (getf preview :annotation-key)
                                                  "-")))))
                    (:tr (:th "Storage mode")
                         (:td (:tt (views:esc
                                    (workspace-annotation-storage-mode-label
                                     (getf preview :storage-mode))))))
                    (:tr (:th "Carrier type")
                         (:td (:tt (views:esc
                                    (workspace-annotation-render-value
                                     (getf preview :carrier-type-uri))))))
                    (:tr (:th "Topic type")
                         (:td (:tt (views:esc
                                    (workspace-annotation-render-value
                                     (getf preview :topic-type-uri))))))
                    (render-workspace-annotation-destination-rows
                     :workspace-id (getf preview :workspace-id)
                     :workspace-topicmap-id
                     (getf preview :workspace-topicmap-id)
                     :destination-source-label
                     (getf preview :destination-source-label)
                     :workspace-source-label
                     (getf preview :workspace-source-label)
                     :topicmap-source-label
                     (getf preview :topicmap-source-label)
                     :destination-rationale
                     (getf preview :destination-rationale))
                    (:tr (:th "Topic action")
                         (:td (:tt (views:esc (format nil "~A"
                                                      (or (getf preview :topic-action)
                                                          "-"))))))
                    (:tr (:th "Workspace action")
                         (:td (:tt (views:esc (format nil "~A"
                                                      (or (getf preview :workspace-action)
                                                          "-"))))))
                    (:tr (:th "Topicmap action")
                         (:td (:tt (views:esc (format nil "~A"
                                                      (or (getf preview :topicmap-action)
                                                          "-"))))))
                    (:tr (:th "Validation")
                         (:td (:tt (views:esc
                                    (format nil "~A"
                                            (or (getf preview :payload-validation-status)
                                                "-"))))))
                    (:tr (:th "Preview journal events")
                         (:td (:tt (views:esc
                                    (format nil "~D"
                                            (workspace-annotation-persistence-preview-journal-count
                                             preview))))))))
          (views:html
            (:p (:span :style "opacity: 0.55;"
                       "No dry-run preview available."))))))

(defun render-workspace-annotation-saved-topic-surface (report)
  (let* ((plan (workspace-annotation-persistence-report-plan-of report))
         (saved-topic-id
           (workspace-annotation-persistence-report-saved-topic-id-of report))
         (saved-annotation
           (workspace-annotation-persistence-report-saved-annotation-of
            report))
         (saved-carrier-topic
           (workspace-annotation-persistence-report-saved-carrier-topic-proxy-of
            report))
         (destination (and plan
                           (dmx-workspace-annotation-write-plan-destination
                            plan))))
    (when saved-topic-id
      (views:html
        (:h4 "Saved annotation topic")
        (:p (views:esc
             "This annotation was already saved before the current live update attempt. The saved carrier topic is the physical DMX object; reopening the same topic id reconstructs the semantic workspace annotation object."))
        (:table :class "inspector-table"
                (:tr (:th "Saved workspace topic id")
                     (:td (:tt (views:esc
                                (workspace-annotation-render-value
                                 saved-topic-id)))))
                (render-workspace-annotation-destination-rows
                 :workspace-id
                 (and plan
                      (dmx-workspace-annotation-write-plan-workspace-id plan))
                 :workspace-topicmap-id
                 (workspace-annotation-persistence-report-workspace-topicmap-id-of
                  report)
                 :workspace-label
                 (and destination
                      (dmx-workspace-annotation-workspace-label
                       (dmx-workspace-annotation-destination-workspace-id
                        destination)))
                 :workspace-topicmap-label
                 (dmx-workspace-annotation-topicmap-label
                  (workspace-annotation-persistence-report-workspace-topicmap-id-of
                   report))
                 :destination-source-label
                 (workspace-annotation-render-value
                  (and destination
                       (dmx-workspace-annotation-destination-source-label
                        (dmx-workspace-annotation-destination-source
                         destination))))
                 :workspace-source-label
                 (workspace-annotation-render-value
                  (and destination
                       (dmx-workspace-annotation-destination-source-label
                        (dmx-workspace-annotation-destination-workspace-source
                         destination))))
                 :topicmap-source-label
                 (workspace-annotation-render-value
                  (and destination
                       (dmx-workspace-annotation-destination-source-label
                        (dmx-workspace-annotation-destination-topicmap-source
                         destination))))
                 :destination-rationale
                 (and destination
                      (dmx-workspace-annotation-destination-rationale
                       destination)))
                (:tr (:th "Storage mode")
                     (:td (:tt (views:esc
                                (workspace-annotation-storage-mode-label
                                 (workspace-annotation-persistence-report-saved-storage-mode-of
                                  report))))))
                (:tr (:th "Carrier type")
                     (:td (:tt (views:esc
                                (workspace-annotation-render-value
                                 (workspace-annotation-persistence-report-saved-carrier-type-uri-of
                                  report)))))))
        (when saved-annotation
          (views:html
            (:p (views:object-ref
                 saved-annotation
                 :display "Saved annotation object"))))
        (when saved-carrier-topic
          (views:html
            (:p (views:object-ref
                 saved-carrier-topic
                 :display "Saved carrier topic"))))))))

(defun render-workspace-annotation-journal-preflight-surface (report)
  (let* ((summary
           (workspace-annotation-persistence-report-journal-preflight-summary-of
            report))
         (failure-stage
           (workspace-annotation-persistence-report-failure-stage-of report))
         (plan (workspace-annotation-persistence-report-plan-of report))
         (destination (and plan
                           (dmx-workspace-annotation-write-plan-destination
                            plan)))
         (journal-auth-context
           (workspace-annotation-persistence-report-journal-preflight-auth-context-of
            report))
         (heading
           (if (eq failure-stage :prepare-transition)
               "Workspace journal preflight blocked"
               "Workspace journal preflight"))
         (description
           (if (eq failure-stage :prepare-transition)
               "Before annotation topic upsert could start, HyperDoc could not reconcile the companion workspace journal for this annotation subject. This is the journal preflight boundary, not annotation topic upsert, workspace assignment, or topicmap placement."
               "HyperDoc inspected the companion workspace journal for this annotation subject before topic upsert."))
         (journal-topic-id
           (workspace-annotation-persistence-report-journal-topic-id-of report))
         (journal-topic
           (workspace-annotation-persistence-report-journal-topic-proxy-of
            report)))
    (when summary
      (views:html
        (:h4 (views:esc heading))
        (:p (views:esc description))
        (:table :class "inspector-table"
                (render-workspace-annotation-destination-rows
                 :workspace-id
                 (and plan
                      (dmx-workspace-annotation-write-plan-workspace-id plan))
                 :workspace-topicmap-id
                 (workspace-annotation-persistence-report-workspace-topicmap-id-of
                  report)
                 :workspace-label
                 (and destination
                      (dmx-workspace-annotation-workspace-label
                       (dmx-workspace-annotation-destination-workspace-id
                        destination)))
                 :workspace-topicmap-label
                 (and destination
                      (dmx-workspace-annotation-topicmap-label
                       (dmx-workspace-annotation-destination-workspace-topicmap-id
                        destination)))
                 :destination-source-label
                 (workspace-annotation-render-value
                  (and destination
                       (dmx-workspace-annotation-destination-source-label
                        (dmx-workspace-annotation-destination-source
                         destination))))
                 :workspace-source-label
                 (workspace-annotation-render-value
                  (and destination
                       (dmx-workspace-annotation-destination-source-label
                        (dmx-workspace-annotation-destination-workspace-source
                         destination))))
                 :topicmap-source-label
                 (workspace-annotation-render-value
                  (and destination
                       (dmx-workspace-annotation-destination-source-label
                        (dmx-workspace-annotation-destination-topicmap-source
                         destination))))
                 :destination-rationale
                 (and destination
                      (dmx-workspace-annotation-destination-rationale
                       destination)))
                (:tr (:th "Journal companion")
                     (:td (:tt (views:esc
                                (workspace-annotation-render-value
                                 (workspace-annotation-journal-preflight-label
                                  summary))))))
                (:tr (:th "Journal topic id")
                     (:td (:tt (views:esc
                                (workspace-annotation-render-value
                                 journal-topic-id)))))
                (:tr (:th "Journal note key")
                     (:td (:tt (views:esc
                                (workspace-annotation-render-value
                                 (getf summary :note-key))))))
                (:tr (:th "Journal note uri")
                     (:td (:tt (views:esc
                                (workspace-annotation-render-value
                                 (getf summary :note-uri))))))
                (:tr (:th "Journal revision")
                     (:td (:tt (views:esc
                                (workspace-annotation-render-value
                                 (getf summary :current-revision))))))
                (:tr (:th "Subject key")
                     (:td (:tt (views:esc
                                (workspace-annotation-render-value
                                 (getf summary :subject-key))))))
                (:tr (:th "Subject lookup")
                     (:td (:tt (views:esc
                                (format nil "~A: ~A"
                                        (workspace-annotation-render-value
                                         (getf summary :subject-lookup-kind))
                                        (workspace-annotation-render-value
                                         (getf summary :subject-lookup-value)))))))
                (when-let (lookup-condition (getf summary :lookup-condition))
                  (views:html
                    (:tr (:th "Journal lookup detail")
                         (:td (views:esc
                               (workspace-annotation-render-value
                                lookup-condition)))))))
        (when journal-topic
          (views:html
            (:p (views:object-ref
                 journal-topic
                 :display "Journal companion topic"))))
        (when journal-auth-context
          (let ((http-evidence (getf journal-auth-context :http-evidence))
                mode-cell username-cell password-cell header-cell token-cell)
            (views:html
              (:h4 "Journal companion auth blocked")
              (:p (views:esc
                   "The current blocker is the journal companion topic write/auth boundary. The saved annotation carrier topic and the journal companion topic are different objects. Because this preflight failed before annotation topic upsert, explicit-auth continuation reruns the same staged persist from the start, beginning with workspace journal preflight."))
              (:table :class "inspector-table"
                      (:tr (:th "Journal companion")
                           (:td (:tt (views:esc
                                      (workspace-annotation-render-value
                                       (getf journal-auth-context
                                             :journal-companion-label))))))
                      (:tr (:th "Journal endpoint")
                           (:td (:tt (views:esc
                                      (workspace-annotation-render-value
                                       (getf journal-auth-context
                                             :journal-endpoint-path))))))
                      (:tr (:th "Env auth present")
                           (:td (:tt (views:esc
                                      (format nil "~A"
                                              (getf journal-auth-context
                                                    :environment-auth-present-p))))))
                      (:tr (:th "Env auth summary")
                           (:td (:tt (views:esc
                                      (workspace-annotation-render-value
                                       (getf journal-auth-context
                                             :environment-auth-mode-summary))))))
                      (:tr (:th "Bootstrap/login needed")
                           (:td (:tt (views:esc
                                      (format nil "~A"
                                              (getf journal-auth-context
                                                    :session-login-required-p))))))
                      (:tr (:th "Missing auth keys")
                           (:td (:tt (views:esc
                                      (if-let (missing
                                               (getf journal-auth-context
                                                     :auth-missing-keys))
                                        (format nil "~{~A~^, ~}" missing)
                                        "-")))))
                      (:tr (:th "Available auth modes")
                           (:td (:tt (views:esc
                                      (if-let (modes
                                               (getf journal-auth-context
                                                     :available-auth-modes))
                                        (format nil
                                                "~{~A~^, ~}"
                                                (mapcar #'workspace-annotation-auth-mode-label
                                                        modes))
                                        "-")))))
                      (:tr (:th "Journal preflight boundary")
                           (:td (views:esc
                                 "This boundary happens before annotation topic upsert. Workspace assignment and topicmap placement are later separate guarded steps."))))
              (when-let (explicit-condition
                           (getf journal-auth-context :explicit-auth-condition))
                (views:html
                  (:h4 "Explicit auth input problem")
                  (:pre :style "white-space: pre-wrap"
                        (views:esc explicit-condition))))
              (when http-evidence
                (views:html
                  (:h4 "Journal preflight HTTP evidence")
                  (render-workspace-annotation-http-evidence-table
                   http-evidence)))
              (:h4 "Continue journal preflight with explicit auth")
              (setf mode-cell
                    (hvr:select '(("Username + password" . "basic")
                                  ("Authorization header" . "header")
                                  ("Bearer token" . "token"))
                                :label "Credential mode: "))
              (:br)
              (setf username-cell
                    (hvr:input :label "Username: "
                               :initial-value ""
                               :size "24"))
              (:br)
              (setf password-cell
                    (hvr:input :label "Password: "
                               :initial-value ""
                               :size "24"
                               :type :password))
              (:br)
              (setf header-cell
                    (hvr:input :label "Authorization header: "
                               :initial-value ""
                               :size "64"))
              (:br)
              (setf token-cell
                    (hvr:input :label "Bearer token: "
                               :initial-value ""
                               :size "48"
                               :type :password))
              (:p (views:esc
                   "Only the fields required by the active credential mode are used for the next action. This continuation reruns the same staged persist from the start, beginning with workspace journal preflight and then proceeding to topic upsert, workspace assignment, topicmap placement, journal transition, and reopen."))
              (views:action-button
               "Continue journal preflight with explicit auth"
               (views:thunk
                 (continue-workspace-annotation-journal-preflight-with-explicit-auth
                  report
                  :auth-mode (lwcells:cell-ref mode-cell)
                  :username (lwcells:cell-ref username-cell)
                  :password (lwcells:cell-ref password-cell)
                  :authorization-header (lwcells:cell-ref header-cell)
                  :auth-token (lwcells:cell-ref token-cell))
                 t)
               "Retry the journal companion preflight and remaining guarded live write with one-shot explicit credentials."))))))))

(defun render-workspace-annotation-persistence-stage-table (report)
  (let ((stages (workspace-annotation-persistence-report-stage-results-of report)))
    (views:html
      (:table :class "inspector-table"
              (:thead
               (:tr (:th "Stage")
                    (:th "Status")
                    (:th "Summary")
                    (:th "Detail")))
              (:tbody
               (dolist (entry stages)
                 (views:html
                   (:tr
                    (:td (:tt (views:esc (or (getf entry :label)
                                             (format nil "~A" (getf entry :stage))))))
                    (:td (:tt (views:esc (format nil "~A"
                                                 (or (getf entry :status)
                                                     "-")))))
                    (:td (views:esc (or (getf entry :summary) "")))
                    (:td (views:esc (or (getf entry :detail) "")))))))))))

(defun render-workspace-annotation-path-diff-table (comparison)
  (let ((rows (workspace-annotation-path-diff-stage-rows comparison))
        (raw-report (workspace-annotation-path-diff-raw-report-of comparison))
        (consequences (workspace-annotation-path-diff-consequences-of
                       comparison)))
    (views:html
      (:p (views:esc
           "This compare surface keeps the raw annotation persist path and the guarded continuation / MCP path on one stage vocabulary. The guarded path maps continue_workspace_annotation onto workspace-assignment, topicmap-placement, journal-transition, and reopen; repair_workspace_topic_assignment only covers workspace-assignment; upsert_workspace_topicmap_context only covers topicmap placement."))
      (:p (views:esc
           "Workspace assignment and topicmap placement are separate facts. Guarded topicmap success does not prove workspace ownership."))
      (when raw-report
        (views:html
          (:p
           (views:object-ref raw-report
                             :display "Open preserved raw persistence report"
                             :select "Overview"))))
      (:table :class "inspector-table"
              (:thead
               (:tr (:th "Stage label")
                    (:th "Annotation persist path behavior")
                    (:th "Guarded continuation / MCP path behavior")
                    (:th "Shared vs divergent")
                    (:th "Auth expectation")
                    (:th "Executor / tool name")
                    (:th "Live status")))
              (:tbody
               (dolist (row rows)
                 (views:html
                   (:tr
                    (:td (:tt (views:esc
                               (workspace-annotation-render-value
                                (getf row :label)))))
                    (:td (views:esc
                          (workspace-annotation-render-value
                           (getf row :annotation-persist-path)
                           :default "")))
                    (:td (views:esc
                          (workspace-annotation-render-value
                           (getf row :guarded-path)
                           :default "")))
                    (:td (:tt (views:esc
                               (workspace-annotation-render-value
                                (getf row :shared-vs-divergent)))))
                    (:td (:tt (views:esc
                               (workspace-annotation-render-value
                                (getf row :auth-expectation)))))
                    (:td (:tt (views:esc
                               (workspace-annotation-render-value
                                (getf row :executor-or-tool)))))
                    (:td (:tt (views:esc
                               (workspace-annotation-render-value
                                (getf row :live-status)))))))))))
      (render-workspace-annotation-path-consequence-table
       consequences
       :heading "Next steps")))

(defun render-workspace-annotation-path-next-step-target (target)
  (let ((object (workspace-annotation-path-next-step-target-object-of target))
        (label (workspace-annotation-path-next-step-target-label-of target))
        (select (workspace-annotation-path-next-step-target-select-of target)))
    (if object
        (views:html
          (views:object-ref object
                            :display label
                            :select select))
        (views:html
          (:tt (views:esc label))))))

(defun render-workspace-annotation-path-next-step-targets (targets)
  (if targets
      (views:html
        (:ul
         (dolist (target targets)
           (views:html
             (:li
              (render-workspace-annotation-path-next-step-target target)
              (views:esc
               (format nil
                       " -> ~A; mode ~A; auth required: ~A; stage scope: ~{~A~^, ~}"
                       (workspace-annotation-path-next-step-target-executor-or-surface-name-of
                        target)
                       (workspace-annotation-path-next-step-mode-label
                        (workspace-annotation-path-next-step-target-mode-of
                         target))
                       (if (workspace-annotation-path-next-step-target-auth-required-p-of
                            target)
                           "yes"
                           "no")
                       (mapcar #'workspace-annotation-persistence-stage-label
                               (workspace-annotation-path-next-step-target-stage-scope-of
                                target)))))))))
      (views:html (:tt "-"))))

(defun render-workspace-annotation-path-consequence-triggering-data
    (consequence)
  (let ((stages
          (workspace-annotation-path-consequence-triggering-stages-of
           consequence))
        (evidence
          (workspace-annotation-path-consequence-triggering-evidence-of
           consequence)))
    (views:html
      (:ul
       (when stages
         (views:html
           (:li
            (views:esc
             (format nil
                     "stages: ~{~A~^, ~}"
                     (mapcar #'workspace-annotation-persistence-stage-label
                             stages))))))
       (dolist (entry evidence)
         (views:html
           (:li
            (:tt (views:esc
                  (workspace-annotation-render-value
                   (getf entry :kind))))
            (views:esc
             (format nil ": ~A"
                     (workspace-annotation-render-value
                      (getf entry :value)))))))))))

(defun render-workspace-annotation-path-consequence-table
    (consequences &key (heading "Consequences"))
  (views:html
    (:h4 (views:esc heading))
    (:table :class "inspector-table"
            (:thead
             (:tr (:th "Consequence kind")
                  (:th "Summary")
                  (:th "Triggering stages / evidence")
                  (:th "Next-step surface or tool")
                  (:th "Actionability")
                  (:th "Auth required")))
            (:tbody
             (dolist (consequence consequences)
               (views:html
                 (:tr
                  (:td (:tt (views:esc
                             (workspace-annotation-path-consequence-kind-label
                              (workspace-annotation-path-consequence-kind-of
                               consequence)))))
                  (:td (views:esc (summary-of consequence)))
                  (:td
                   (render-workspace-annotation-path-consequence-triggering-data
                    consequence))
                  (:td
                   (render-workspace-annotation-path-next-step-targets
                    (workspace-annotation-path-consequence-next-step-targets-of
                     consequence)))
                  (:td (:tt (views:esc
                             (workspace-annotation-path-consequence-actionability-label
                              (workspace-annotation-path-consequence-actionability-of
                               consequence)))))
                  (:td (:tt (views:esc
                             (if (workspace-annotation-path-consequence-auth-required-p-of
                                  consequence)
                                 "yes"
                                 "no")))))))))))

(defun render-workspace-annotation-http-response-headers (headers)
  (if headers
      (views:html
        (:table :class "inspector-table"
                (dolist (entry headers)
                  (views:html
                    (:tr (:th (views:esc
                               (workspace-annotation-render-value (car entry))))
                         (:td (:tt (views:esc
                                    (workspace-annotation-render-value
                                     (cdr entry))))))))))
      (views:html
        (:p (:tt "-")))))

(defun workspace-annotation-render-value (value &key (default "-"))
  (cond
    ((null value)
     default)
    ((stringp value)
     value)
    (t
     (format nil "~A" value))))

(defun workspace-annotation-auth-mode-label (mode)
  (case (hyperdoc::normalize-http-dmx-import-auth-mode
         mode
         'workspace-annotation-auth-mode-label)
    (:basic "username/password")
    (:header "authorization header")
    (:token "bearer token")))

(defun render-workspace-annotation-http-evidence-table
    (evidence &key payload-json planned-topic-action planned-workspace-action
      planned-topicmap-action)
  (views:html
    (:table :class "inspector-table"
            (:tr (:th "Method")
                 (:td (:tt (views:esc (format nil "~A"
                                              (or (getf evidence :method) "-"))))))
            (:tr (:th "Path")
                 (:td (:tt (views:esc
                            (workspace-annotation-render-value
                             (or (getf evidence :path)
                                 (getf evidence :url)))))))
            (:tr (:th "Auth mode")
                 (:td (:tt (views:esc
                            (workspace-annotation-render-value
                             (getf evidence :auth-mode-summary))))))
            (:tr (:th "Authorization scheme")
                 (:td (:tt (views:esc
                            (workspace-annotation-render-value
                             (getf evidence :authorization-scheme))))))
            (:tr (:th "Bootstrap/login happened")
                 (:td (:tt (views:esc (format nil "~A"
                                              (or (getf evidence :bootstrap-ran-p)
                                                  nil))))))
            (:tr (:th "Bootstrap status")
                 (:td (:tt (views:esc (format nil "~A"
                                              (or (getf evidence :bootstrap-status-code)
                                                  "-"))))))
            (:tr (:th "Session cookie captured")
                 (:td (:tt (views:esc (format nil "~A"
                                              (or (getf evidence :session-cookie-captured-p)
                                                  nil))))))
            (:tr (:th "Cookie shape")
                 (:td (:tt (views:esc
                            (workspace-annotation-render-value
                             (getf evidence :cookie-shape))))))
            (:tr (:th "Request content type")
                 (:td (:tt (views:esc
                            (workspace-annotation-render-value
                             (getf evidence :request-content-type))))))
            (:tr (:th "Request content length")
                 (:td (:tt (views:esc (format nil "~A"
                                              (or (getf evidence :request-content-length)
                                                  "-"))))))
            (when planned-topic-action
              (views:html
                (:tr (:th "Planned topic action")
                     (:td (:tt (views:esc (format nil "~A" planned-topic-action)))))))
            (when planned-workspace-action
              (views:html
                (:tr (:th "Planned workspace action")
                     (:td (:tt (views:esc (format nil "~A" planned-workspace-action)))))))
            (when planned-topicmap-action
              (views:html
                (:tr (:th "Planned topicmap action")
                     (:td (:tt (views:esc (format nil "~A" planned-topicmap-action)))))))
            (:tr (:th "Response status")
                 (:td (:tt (views:esc (format nil "~A"
                                              (or (getf evidence :response-status-code)
                                                  "-"))))))
            (:tr (:th "Response reason")
                 (:td (:tt (views:esc
                            (workspace-annotation-render-value
                             (getf evidence :response-reason-phrase)))))))
    (when payload-json
      (views:html
        (:h4 "Request payload JSON")
        (:pre :style "white-space: pre-wrap"
              (views:esc
               (workspace-annotation-render-value payload-json :default "")))))
    (when-let (request-body (getf evidence :request-body))
      (views:html
        (:h4 "Request body sent")
        (:pre :style "white-space: pre-wrap"
              (views:esc
               (workspace-annotation-render-value request-body :default "")))))
    (when-let (response-body (getf evidence :response-body))
      (views:html
        (:h4 "Response body")
        (:pre :style "white-space: pre-wrap"
              (views:esc
               (workspace-annotation-render-value response-body :default "")))))
    (:h4 "Relevant response headers")
    (render-workspace-annotation-http-response-headers
     (getf evidence :response-headers))))

(defun render-workspace-annotation-backend-support-results (results)
  (if results
      (views:html
        (:table :class "inspector-table"
                (:thead
                 (:tr (:th "Type URI")
                      (:th "Kind")
                      (:th "Supported")
                      (:th "Topic id")
                      (:th "Probe status")
                      (:th "Probe path")))
                (:tbody
                 (dolist (entry results)
                   (let* ((evidence (getf entry :http-evidence))
                          (status-code (and evidence
                                            (getf evidence :response-status-code))))
                     (views:html
                       (:tr
                        (:td (:tt (views:esc (or (getf entry :type-uri) "-"))))
                        (:td (:tt (views:esc (format nil "~A"
                                                     (or (getf entry :kind)
                                                         "-")))))
                        (:td (:tt (views:esc (format nil "~A"
                                                     (or (getf entry :supported-p)
                                                         nil)))))
                        (:td (:tt (views:esc (format nil "~A"
                                                     (or (getf entry :topic-id)
                                                         "-")))))
                        (:td (:tt (views:esc (format nil "~A"
                                                     (or status-code "-")))))
                        (:td (:tt (views:esc (or (and evidence
                                                      (getf evidence :path))
                                                 "-")))))))))))
      (views:html
        (:p (:tt "-")))))

(defun include-dom-annotation-connect-assets ()
  (views:add-asset-path "/hyperdoc/"
                        (asdf:system-relative-pathname
                         :hyperdoc
                         "assets/hyperdoc/"))
  (views:include-css "/hyperdoc/css/dom-annotation-connect.css")
  (views:include-js "/hyperdoc/js/dom-annotation-connect.js")
  (views:include-script
   "(function initHyperdocDomConnect(attempt) {
      if (window.hyperdocDomConnect &&
          typeof window.hyperdocDomConnect.initCurrentView === 'function') {
        window.hyperdocDomConnect.initCurrentView();
        return;
      }
      if ((attempt || 0) >= 40) {
        return;
      }
      window.setTimeout(function () {
        initHyperdocDomConnect((attempt || 0) + 1);
      }, 50);
    }(0));"))

(defun dom-connect-context-object-id (object)
  (or (ignore-errors (id-of object))
      (ignore-errors (title-of object))
      (format nil "~A" object)))

(defclass view-anchor-provider ()
  ((kind :initarg :kind :reader anchor-provider-kind-of)
   (view-kind :initarg :view-kind :reader anchor-provider-view-kind-of)
   (selection-mode :initarg :selection-mode
                   :initform "click"
                   :reader anchor-provider-selection-mode-of)
   (help-summary :initarg :help-summary :reader anchor-provider-help-summary-of)
   (help-detail :initarg :help-detail :reader anchor-provider-help-detail-of)
   (body-thunk :initarg :body-thunk :initform nil
               :reader anchor-provider-body-thunk-of)))

(defclass dom-view-anchor-provider (view-anchor-provider) ())

(defclass source-view-anchor-provider (view-anchor-provider)
  ((pathname :initarg :pathname :reader anchor-provider-pathname-of)
   (context-object :initarg :context-object
                   :reader anchor-provider-context-object-of)))

(defclass fedwiki-view-anchor-provider (view-anchor-provider)
  ((page :initarg :page :reader anchor-provider-page-of)))

(defgeneric anchor-provider-connectable-p (provider))

(defgeneric render-anchor-provider-body (provider))

(defmethod anchor-provider-connectable-p ((provider view-anchor-provider))
  (declare (ignore provider))
  t)

(defmethod render-anchor-provider-body ((provider dom-view-anchor-provider))
  (funcall (anchor-provider-body-thunk-of provider)))

(defmethod render-anchor-provider-body ((provider fedwiki-view-anchor-provider))
  (funcall (anchor-provider-body-thunk-of provider)))

(defun source-line-label (line-number line-text)
  (let ((snippet (string-trim '(#\Space #\Tab)
                              (or line-text ""))))
    (if (> (length snippet) 0)
        (format nil "Line ~D: ~A"
                line-number
                (shorten-dom-association-label snippet 96))
        (format nil "Line ~D" line-number))))

(defun render-source-anchor-line (provider line-number line-text)
  (let* ((pathname (namestring (anchor-provider-pathname-of provider)))
         (column-end (+ 1 (length line-text)))
         (value (format nil "~A#L~D" pathname line-number)))
    (views:html
      (:button :type "button"
               :class "hyperdoc-source-connect-line"
               :data-hyperdoc-connect-source-anchor "true"
               :data-hyperdoc-source-path pathname
               :data-hyperdoc-source-start-line line-number
               :data-hyperdoc-source-end-line line-number
               :data-hyperdoc-source-start-column "1"
               :data-hyperdoc-source-end-column column-end
               :data-hyperdoc-source-value value
               :data-hyperdoc-source-label (source-line-label line-number line-text)
               :data-hyperdoc-source-object-id
               (dom-connect-context-object-id
                (anchor-provider-context-object-of provider))
               (:span :class "hyperdoc-source-connect-line-number"
                      (views:esc (format nil "~D" line-number)))
               (:span :class "hyperdoc-source-connect-line-text"
                      (views:esc line-text))))))

(defmethod render-anchor-provider-body ((provider source-view-anchor-provider))
  (let ((lines (uiop:read-file-lines (anchor-provider-pathname-of provider))))
    (views:html
      (:div :class "hyperdoc-source-connect-view"
            (loop for line-text in lines
                  for line-number from 1
                  do (render-source-anchor-line
                      provider line-number line-text))))))

(defun render-anchor-provider-surface (provider context-object view-title)
  (let* ((source-cell (lwcells:cell ""))
         (target-cell (lwcells:cell ""))
         (snapshot-cell (lwcells:cell ""))
         (request-id-cell (lwcells:cell ""))
         (browser-failure-kind-cell (lwcells:cell ""))
         (browser-message-cell (lwcells:cell ""))
         (browser-detail-cell (lwcells:cell ""))
         (source-input-id (html-inspector-views/reactive:input-id
                           source-cell :event :change))
         (target-input-id (html-inspector-views/reactive:input-id
                           target-cell :event :change))
         (snapshot-input-id (html-inspector-views/reactive:input-id
                             snapshot-cell :event :change))
         (request-id-input-id (html-inspector-views/reactive:input-id
                               request-id-cell :event :change))
         (browser-failure-kind-input-id
           (html-inspector-views/reactive:input-id
            browser-failure-kind-cell :event :change))
         (browser-message-input-id
           (html-inspector-views/reactive:input-id
            browser-message-cell :event :change))
         (browser-detail-input-id
           (html-inspector-views/reactive:input-id
            browser-detail-cell :event :change)))
    (include-dom-annotation-connect-assets)
    (when (anchor-provider-connectable-p provider)
      (views:html
        (:div :class "hyperdoc-dom-connect-surface hyperdoc-connect-provider-surface"
              :data-hyperdoc-connect-provider-kind
              (anchor-provider-kind-of provider)
              :data-hyperdoc-connect-view-kind
              (anchor-provider-view-kind-of provider)
              :data-hyperdoc-connect-selection-mode
              (anchor-provider-selection-mode-of provider)
              :data-hyperdoc-connect-help-summary
              (anchor-provider-help-summary-of provider)
              :data-hyperdoc-connect-help-detail
              (anchor-provider-help-detail-of provider)
              :data-hyperdoc-dock-zotero-available
              (if (dock-zotero-capability-available-p context-object)
                  "true"
                  "false")
              :data-hyperdoc-dock-annotation-topic-id
              (id-of (annotation-topic))
              :data-context-object-id (dom-connect-context-object-id context-object)
              :data-context-view-title view-title
              (:div :class "hyperdoc-dom-connect-controls"
                    :style "display:none"
                    :data-source-input-id source-input-id
                    :data-target-input-id target-input-id
                    :data-snapshot-input-id snapshot-input-id
                    :data-request-id-input-id request-id-input-id
                    :data-browser-failure-kind-input-id
                    browser-failure-kind-input-id
                    :data-browser-message-input-id
                    browser-message-input-id
                    :data-browser-detail-input-id
                    browser-detail-input-id
                    (:input :type "hidden" :id source-input-id :value "")
                    (:input :type "hidden" :id target-input-id :value "")
                    (:input :type "hidden" :id snapshot-input-id :value "")
                    (:input :type "hidden" :id request-id-input-id :value "")
                    (:input :type "hidden"
                            :id browser-failure-kind-input-id
                            :value "")
                    (:input :type "hidden"
                            :id browser-message-input-id
                            :value "")
                    (:input :type "hidden"
                            :id browser-detail-input-id
                            :value "")
                    (:span :class "hyperdoc-dom-connect-submit"
                           :style "display:none"
                           (views:eval-button
                            "Open association"
                            (views:thunk
                              (make-dom-relation-annotation-from-json
                               :context-object context-object
                               :context-view-title view-title
                               :source-json (lwcells:cell-ref source-cell)
                               :target-json (lwcells:cell-ref target-cell)))))
                    (:span :class "hyperdoc-dom-connect-evidence-submit"
                           :style "display:none"
                           (views:eval-button
                            "Inspect request evidence"
                            (views:thunk
                              (make-dom-connect-request-evidence-from-values
                               :context-object context-object
                               :context-view-title view-title
                               :request-id (lwcells:cell-ref request-id-cell)
                               :snapshot-json (lwcells:cell-ref snapshot-cell)
                               :browser-failure-kind
                               (lwcells:cell-ref browser-failure-kind-cell)
                               :browser-message
                               (lwcells:cell-ref browser-message-cell)
                               :browser-detail
                               (lwcells:cell-ref browser-detail-cell)))))
                    (:span :class "hyperdoc-dock-annotation-submit"
                           :style "display:none"
                           (views:eval-button
                            "Open current-object annotation"
                            (views:thunk
                              (dock-annotation-for-context
                               context-object
                               :context-view-title view-title))))
                    (:span :class "hyperdoc-dock-connect-runtime-submit"
                           :style "display:none"
                           :data-dom-association-transport
                           "dock-capability-inspection-v1"
                           (views:eval-button
                            "Inspect current Connect runtime"
                            (views:thunk
                              (connect-capability-runtime-target
                               :context-object context-object
                               :context-view-title view-title
                               :snapshot-json (lwcells:cell-ref snapshot-cell)))))
                    (:span :class "hyperdoc-dock-connect-evidence-submit"
                           :style "display:none"
                           :data-dom-association-transport
                           "dock-capability-inspection-v1"
                           (views:eval-button
                            "Inspect Connect model and evidence"
                            (views:thunk
                              (connect-capability-evidence-target))))
                    (:span :class "hyperdoc-dock-annotation-semantic-submit"
                           :style "display:none"
                           :data-dom-association-transport
                           "dock-capability-inspection-v1"
                           (views:eval-button
                            "Inspect current Annotation semantic target"
                            (views:thunk
                              (annotation-capability-semantic-target
                               :context-object context-object
                               :context-view-title view-title
                               :source-json (lwcells:cell-ref source-cell)))))
                    (:span :class "hyperdoc-dock-annotation-evidence-submit"
                           :style "display:none"
                           :data-dom-association-transport
                           "dock-capability-inspection-v1"
                           (views:eval-button
                            "Inspect Annotation claim and evidence"
                            (views:thunk
                              (annotation-capability-evidence-target))))
                    (:span :class "hyperdoc-dock-guide-model-submit"
                           :style "display:none"
                           :data-dom-association-transport
                           "dock-capability-inspection-v1"
                           (views:eval-button
                            "Inspect Dock presentation model"
                            (views:thunk
                              (guide-capability-model-target))))
                    (:span :class "hyperdoc-dock-guide-evidence-submit"
                           :style "display:none"
                           :data-dom-association-transport
                           "dock-capability-inspection-v1"
                           (views:eval-button
                            "Inspect Dock runtime claim and evidence"
                            (views:thunk
                              (guide-capability-evidence-target)))))
              (:svg :class "hyperdoc-dom-connect-overlay"
                    :hidden "hidden"
                    :xmlns "http://www.w3.org/2000/svg"
                    :aria-hidden "true"
                    (:line :class "hyperdoc-dom-connect-line"
                           :x1 "0"
                           :y1 "0"
                           :x2 "0"
                           :y2 "0"))
              (:div :class "hyperdoc-dom-connect-root hyperdoc-connect-provider-root"
                    (render-anchor-provider-body provider)))))))

(defun render-dom-connect-surface (context-object view-title body-thunk)
  (render-anchor-provider-surface
   (make-instance 'dom-view-anchor-provider
                  :kind "dom-v1"
                  :view-kind "content"
                  :help-summary
                  "Click the part of the page you want to connect."
                  :help-detail
                  "Connect resolves visible clicks to headings, list items, or paragraphs when it can. Authored ids stay strongest when present; DOM-path data is fallback metadata only."
                  :body-thunk body-thunk)
   context-object
   view-title))

(defun render-source-connect-surface (context-object view-title pathname)
  (render-anchor-provider-surface
   (make-instance 'source-view-anchor-provider
                  :kind "source-v1"
                  :view-kind "source"
                  :help-summary
                  "Click the source lines you want to connect."
                  :help-detail
                  "Connect stores file path plus line and column range. These anchors stay useful for the same file revision, but line numbers can drift when the source changes."
                  :pathname pathname
                  :context-object context-object)
   context-object
   view-title))

(defun fedwiki-story-item-type-label (item)
  (-> item
      hyperbook/fedwiki::item-type-of
      symbol-name
      string-downcase))

(defun fedwiki-story-item-anchor-label (item)
  (let* ((type-label (fedwiki-story-item-type-label item))
         (text (string-trim '(#\Space #\Tab #\Newline #\Return)
                            (or (hyperbook/fedwiki::text-of item)
                                ""))))
    (if (> (length text) 0)
        (shorten-dom-association-label
         (format nil "~A: ~A" type-label text)
         96)
        (format nil "~A item ~A"
                (string-capitalize type-label)
                (hyperbook/fedwiki::id-of item)))))

(defun render-fedwiki-story-item-anchor (page item)
  (let* ((wiki (hyperbook/fedwiki::origin-of page))
         (site-domain (hyperbook/fedwiki::domain-name-of wiki))
         (page-slug (hyperbook/fedwiki::origin-id-of page))
         (page-title (hb:title-of page))
         (item-type (fedwiki-story-item-type-label item))
         (item-id (hyperbook/fedwiki::id-of item))
         (label (fedwiki-story-item-anchor-label item)))
    (views:html
      (:div :class "hyperdoc-fedwiki-story-item-anchor"
            :title item-type
            :data-hyperdoc-fedwiki-story-item-anchor "true"
            :data-hyperdoc-fedwiki-site-domain site-domain
            :data-hyperdoc-fedwiki-page-slug page-slug
            :data-hyperdoc-fedwiki-page-title page-title
            :data-hyperdoc-fedwiki-story-item-id item-id
            :data-hyperdoc-fedwiki-story-item-type item-type
            :data-hyperdoc-fedwiki-story-item-label label
            (hyperbook/fedwiki::render-story-item
             (hyperbook/fedwiki::item-type-of item)
             item
             page)))))

(defun render-fedwiki-connect-surface (page view-title)
  (let* ((wiki (hyperbook/fedwiki::origin-of page))
         (domain (hyperbook/fedwiki::domain-name-of wiki))
         (protocol (hyperbook/fedwiki::protocol-of wiki)))
    (render-anchor-provider-surface
     (make-instance 'fedwiki-view-anchor-provider
                    :kind "fedwiki-v1"
                    :view-kind "story"
                    :help-summary
                    "Click the story item you want to connect."
                    :help-detail
                    "Connect stores durable story-item identity when it can: site, page slug, and story-item id. DOM location is fallback metadata only."
                    :page page
                    :body-thunk
                    (lambda ()
                      (views:add-asset-path "/hyperbook/"
                                            (asdf:system-relative-pathname
                                             :hyperbook
                                             "assets/hyperbook/"))
                      (views:include-css "/hyperbook/css/hyperbook.css")
                      (views:html
                        (:div :class "hyperbook-page"
                              (:h1 (:img :src (hyperbook/fedwiki::wiki-url
                                               domain
                                               protocol
                                               "/favicon.png"))
                                   (views:esc " ")
                                   (views:esc (hb:title-of page)))
                              (loop for item across (hyperbook/fedwiki::story-of page)
                                    do (render-fedwiki-story-item-anchor
                                        page item))))))
     page
     view-title)))

(views:defview 👀story (page hyperbook/fedwiki::fedwiki-page)
  (hyperbook/fedwiki::load-page page)
  (views:html-view :title "Story" :priority 2
    (render-fedwiki-connect-surface page "Story")))

(defmethod views:text-representation ((anchor dom-annotation-anchor))
  (or (label-of anchor)
      (anchor-value-of anchor)))

(defmethod views:text-representation ((annotation dom-relation-annotation))
  (shorten-dom-association-label (title-of annotation)))

(defmethod views:text-representation ((annotation dock-annotation))
  (shorten-dom-association-label (title-of annotation)))

(defmethod views:text-representation
    ((debug workspace-annotation-persistence-debug))
  (format nil "Workspace persistence debug (~A)"
          (or (workspace-annotation-persistence-debug-annotation-key-of debug)
              (id-of (workspace-annotation-persistence-debug-annotation-of debug))
              "annotation")))

(defmethod views:text-representation
    ((report workspace-annotation-persistence-report))
  (format nil "Workspace persistence ~A (~A)"
          (string-downcase
           (format nil "~A"
                   (workspace-annotation-persistence-report-status-of report)))
          (or (workspace-annotation-persistence-report-annotation-key-of report)
              (workspace-annotation-persistence-report-runtime-relation-id-of
               report)
              "annotation")))

(defmethod views:text-representation
    ((report workspace-annotation-create-topic-probe-report))
  (format nil "Create-topic probe ~A (~A)"
          (string-downcase
           (format nil "~A"
                   (workspace-annotation-create-topic-probe-status-of report)))
          (or (and (workspace-annotation-create-topic-probe-plan-of report)
                   (hyperdoc::dmx-workspace-annotation-write-plan-annotation-key
                    (workspace-annotation-create-topic-probe-plan-of report)))
              "annotation")))

(defmethod views:text-representation
    ((report workspace-annotation-backend-compatibility-report))
  (format nil "Annotation backend compatibility ~A (~A)"
          (string-downcase
           (format nil "~A"
                   (workspace-annotation-backend-compatibility-report-status-of
                    report)))
          (or (and (workspace-annotation-backend-compatibility-report-plan-of
                    report)
                   (hyperdoc::dmx-workspace-annotation-write-plan-annotation-key
                    (workspace-annotation-backend-compatibility-report-plan-of
                     report)))
              "annotation")))

(defmethod views:text-representation
    ((comparison workspace-annotation-path-diff))
  (format nil "Workspace path diff (~A)"
          (or (and (workspace-annotation-path-diff-plan-of comparison)
                   (dmx-workspace-annotation-write-plan-annotation-key
                    (workspace-annotation-path-diff-plan-of comparison)))
              (and (workspace-annotation-path-diff-annotation-of comparison)
                   (id-of (workspace-annotation-path-diff-annotation-of
                           comparison)))
              "annotation")))

(defmethod views:text-representation ((snapshot dom-connect-pane-state-snapshot))
  (format nil "~A (~A / ~A)"
          (or (pane-id-of snapshot) "pane")
          (or (local-phase-of snapshot) "dormant")
          (or (presentation-state-of snapshot) "latent")))

(defmethod views:text-representation ((entry dom-connect-transition-entry))
  (or (stage-of entry)
      (title-of entry)))

(defmethod views:text-representation ((snapshot dom-connect-session-snapshot))
  (shorten-dom-association-label (title-of snapshot)))

(defmethod views:text-representation ((evidence dom-connect-request-evidence))
  (shorten-dom-association-label (title-of evidence)))

(defmethod views:text-representation ((path dom-connect-submit-path))
  (shorten-dom-association-label (title-of path)))

(defmethod views:text-representation ((comparison dom-connect-submit-path-comparison))
  (shorten-dom-association-label (title-of comparison)))

(defmethod views:text-representation ((path dom-connect-snapshot-transport-path))
  (shorten-dom-association-label (title-of path)))

(defmethod views:text-representation ((transport dom-connect-snapshot-transport))
  (shorten-dom-association-label (title-of transport)))

(defmethod views:text-representation ((proposal relation-topic-proposal))
  (shorten-dom-association-label (proposed-title-of proposal)))

(defmethod views:text-representation ((plan relation-topic-patch-plan))
  (shorten-dom-association-label (title-of plan)))

(defmethod views:text-representation
    ((application approved-relation-topic-patch-application))
  (shorten-dom-association-label (title-of application)))

(defun render-anchor-field-rows (rows)
  (loop for (label . value) in rows
        do (views:html
             (:tr (:th (views:esc label))
                  (:td (maybe-dom-object-ref value :fallback-empty "-"))))))

(defun render-connect-field-row (label value &key (fallback "-"))
  (views:html
    (:tr (:th (views:esc label))
         (:td (maybe-dom-object-ref value :fallback-empty fallback)))))

(defun render-connect-data-cell (value &key (fallback "-"))
  (cond
    ((null value)
     (views:html
       (:span :style "opacity: 0.55;" (views:esc fallback))))
    ((listp value)
     (views:html
       (:ul
        (loop for item in value
              do (views:html
                   (:li (maybe-dom-object-ref item :fallback-empty fallback)))))))
    (t
     (maybe-dom-object-ref value :fallback-empty fallback))))

(defun render-connect-rich-field-row (label value &key (fallback "-"))
  (views:html
    (:tr (:th (views:esc label))
         (:td (render-connect-data-cell value :fallback fallback)))))

(defun render-connect-comparison-row (label normal-value evidence-value
                                      &key (normal-fallback "-")
                                        (evidence-fallback "-"))
  (views:html
    (:tr (:th (views:esc label))
         (:td (render-connect-data-cell normal-value
                                        :fallback normal-fallback))
         (:td (render-connect-data-cell evidence-value
                                        :fallback evidence-fallback)))))

(defun connect-provider-label (value)
  (or value "-"))

(defun render-connect-anchor-section (heading anchor)
  (views:html
    (:h4 (views:esc heading))
    (if anchor
        (let* ((semantic-fields
                 (append
                  (list (cons "Provider kind"
                              (connect-provider-label (provider-kind-of anchor))))
                  (semantic-anchor-identity-fields anchor)
                  (list (cons "Human label"
                              (or (label-of anchor) "-")))))
               (presentation-fields (presentation-anchor-fallback-fields anchor)))
          (views:html
            (:p (maybe-dom-object-ref anchor))
            (:table :class "inspector-table hyperdoc-dom-connect-anchor-table"
                    (render-anchor-field-rows semantic-fields))
            (:h5 "Fallback diagnostics")
            (:table :class "inspector-table hyperdoc-dom-connect-anchor-diagnostics-table"
                    (if presentation-fields
                        (render-anchor-field-rows presentation-fields)
                        (views:html
                          (:tr (:th "Captured fallback")
                               (:td (:span :style "opacity: 0.55;"
                                           "none"))))))))
        (views:html
          (:p (:span :style "opacity: 0.55;"
                     "No active anchor in the current session."))))))

(defun render-connect-transition-anchor-ref (entry)
  (or (anchor-of entry)
      (source-anchor-of entry)
      (target-anchor-of entry)))

(views:defview 👀summary (anchor dom-annotation-anchor)
  (views:html-view :title "Summary" :priority 1
    (let ((semantic-fields (semantic-anchor-identity-fields anchor))
          (presentation-fields (presentation-anchor-fallback-fields anchor)))
      (views:html
        (:h3 (views:esc (or (label-of anchor)
                            (semantic-anchor-identity-of anchor))))
        (:h4 "Context")
        (:table :class "inspector-table"
                (:tr (:th "Provider")
                     (:td (:tt (views:esc (or (provider-kind-of anchor)
                                              "-")))))
                (:tr (:th "Pane")
                     (:td (:tt (views:esc (or (pane-id-of anchor)
                                              "-")))))
                (:tr (:th "Context object")
                     (:td (:tt (views:esc (or (context-object-id-of anchor)
                                              "-")))))
                (:tr (:th "View kind")
                     (:td (:tt (views:esc (or (view-kind-of anchor)
                                              "-")))))
                (:tr (:th "View title")
                     (:td (:tt (views:esc (or (view-title-of anchor)
                                              "-"))))))
        (:h4 "Semantic anchor")
        (:table :class "inspector-table"
                (render-anchor-field-rows semantic-fields))
        (:h4 "Presentation fallback")
        (:table :class "inspector-table"
                (if presentation-fields
                    (render-anchor-field-rows presentation-fields)
                    (views:html
                      (:tr (:th "Captured fallback")
                           (:td (:span :style "opacity: 0.55;"
                                       "none"))))))
        (:h4 "Durability")
        (:table :class "inspector-table"
                (:tr (:th "Tier")
                     (:td (:tt (views:esc (or (durability-tier-of anchor)
                                              "-")))))
                (:tr (:th "Note")
                     (:td (views:esc (or (durability-note-of anchor)
                                         "-")))))))))

(views:defview 👀items (anchor dom-annotation-anchor)
  (views:html-view :title "Items" :priority 10
    (views:html
      (:h4 "Text snippet")
      (:pre :style "white-space: pre-wrap"
            (views:esc (or (text-snippet-of anchor)
                           "No text snippet captured."))))))

(views:defview 👀summary (annotation dom-relation-annotation)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 :class "hyperdoc-dom-association-title"
           (views:esc (title-of annotation)))
      (:p :class "hyperdoc-dom-association-summary"
          (views:esc (summary-of annotation)))
      (:table :class "inspector-table"
              (:tr (:th "Association kind")
                   (:td (:tt (views:esc (or (relation-kind-of annotation)
                                            "-")))))
              (:tr (:th "Context view")
                   (:td (:tt (views:esc (or (context-view-title-of annotation)
                                            "-")))))
              (:tr (:th "Context object")
                   (:td (maybe-dom-object-ref (context-object-of annotation))))
              (:tr (:th "Matching patch target")
                   (:td (if (matching-patch-target-of annotation)
                            (views:object-ref
                             (matching-patch-target-of annotation))
                            (views:html (:span :style "opacity: 0.55;"
                                               "none"))))))
      (when (note-of annotation)
        (views:html
          (:h4 "Note")
          (:pre :style "white-space: pre-wrap"
                (views:esc (note-of annotation))))))))

(views:defview 👀items (annotation dom-relation-annotation)
  (views:html-view :title "Items" :priority 10
    (views:html
      (:h4 "Source anchor")
      (maybe-dom-object-ref (source-anchor-of annotation))
      (when (source-object-of annotation)
        (views:html
          (:h4 "Source object")
          (maybe-dom-object-ref (source-object-of annotation))))
      (:h4 "Target anchor")
      (maybe-dom-object-ref (target-anchor-of annotation))
      (when (target-object-of annotation)
        (views:html
          (:h4 "Target object")
          (maybe-dom-object-ref (target-object-of annotation))))
      (when (matching-defect-of annotation)
        (views:html
          (:h4 "Matching defect")
          (maybe-dom-object-ref (matching-defect-of annotation))))
      (when (matching-inserted-step-of annotation)
        (views:html
          (:h4 "Suggested inserted step")
          (maybe-dom-object-ref (matching-inserted-step-of annotation)))))))

(views:defview 👀topic-proposal (annotation dom-relation-annotation)
  (views:html-view :title "Topic proposal" :priority 2
    (views:html
      (:h3 "Reviewed topic proposal")
      (:p "Use the Operations view to inspect the promotion result without mutating authored topic factories or page files.")
      (:p (views:object-ref (promote-relation-to-topic-proposal annotation))))))

(defmethod views:title-bar-action-buttons ((annotation dock-annotation))
  (views:html
    (when (source-object-of annotation)
      (views:html
        (views:eval-button
         "Open source object"
         (views:thunk (source-object-of annotation))
         "Open the current inspectable object that this annotation relation annotates.")))
    (views:eval-button
     "Open Annotation topic"
     (views:thunk (target-object-of annotation))
     "Open the generic Annotation topic that classifies this relation.")))

(views:defview 👀overview (annotation dock-annotation)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:h3 :class "hyperdoc-dom-association-title"
           (views:esc (title-of annotation)))
      (:p :class "hyperdoc-dom-association-summary"
          (views:esc (summary-of annotation)))
      (:table :class "inspector-table"
              (:tr (:th "Stable key")
                   (:td (:tt (views:esc (id-of annotation)))))
              (:tr (:th "Dock capability")
                   (:td (:tt (views:esc (dock-capability-of annotation)))))
              (:tr (:th "Relation kind")
                   (:td (:tt (views:esc (or (relation-kind-of annotation)
                                            "-")))))
              (:tr (:th "Context view")
                   (:td (:tt (views:esc (or (context-view-title-of annotation)
                                            "-")))))
              (:tr (:th "Context object")
                   (:td (maybe-dom-object-ref (context-object-of annotation))))
              (:tr (:th "Annotated source object")
                   (:td (maybe-dom-object-ref (source-object-of annotation))))
              (:tr (:th "Annotation topic")
                   (:td (maybe-dom-object-ref (target-object-of annotation)))))
      (:h4 "Note")
      (:pre :style "white-space: pre-wrap"
            (views:esc (or (note-of annotation) ""))))))

(views:defview 👀source (annotation dock-annotation)
  (views:html-view :title "Source" :priority 2
    (views:html
      (:h4 "Annotated source object")
      (maybe-dom-object-ref (source-object-of annotation))
      (:h4 "Source anchor")
      (maybe-dom-object-ref (source-anchor-of annotation))
      (:h4 "Annotation target")
      (maybe-dom-object-ref (target-anchor-of annotation)))))

(views:defview 👀raw-data (annotation dock-annotation)
  (views:html-view :title "Raw data" :priority 3
    (views:html
      (:table :class "inspector-table"
              (render-anchor-field-rows
               (list (cons "Registry key" (registry-key-of annotation))
                     (cons "Source object id"
                           (and (source-object-of annotation)
                                (ignore-errors
                                  (id-of (source-object-of annotation)))))
                     (cons "Annotation topic id"
                           (and (target-object-of annotation)
                                (ignore-errors
                                  (id-of (target-object-of annotation)))))
                     (when (workspace-dock-annotation-p annotation)
                       (cons "Workspace topic id"
                             (workspace-annotation-topic-id-of annotation)))))))))

(views:defview 👀workspace (annotation dock-annotation)
  (views:html-view :title "Workspace" :priority 4
    (let* ((persisted-p (workspace-dock-annotation-p annotation))
           (default-client
             (resolve-dmx-workspace-annotation-client
              :dry-run nil
              :verbose nil))
           (destination
             (resolve-dmx-workspace-annotation-destination
              annotation
              :client default-client))
           (workspace-id
             (dmx-workspace-annotation-destination-workspace-id destination))
           (workspace-topicmap-id
             (dmx-workspace-annotation-destination-workspace-topicmap-id
              destination)))
      (views:html
        (:p (views:esc
             "Workspace persistence stays typed and dry-run-first. Saving this annotation writes a HyperDoc-owned workspace annotation object with a resolved workspace destination. Workspace assignment remains distinct from topicmap placement; visibility in the shared blackboard is not a substitute for belonging to workspace 919815."))
        (:table :class "inspector-table"
                (:tr (:th "Workspace state")
                     (:td (:tt (views:esc (if persisted-p
                                              "persisted"
                                              "draft")))))
                (render-workspace-annotation-destination-rows
                 :workspace-id workspace-id
                 :workspace-topicmap-id workspace-topicmap-id
                 :destination-source-label
                 (workspace-annotation-destination-label destination :source)
                 :workspace-source-label
                 (workspace-annotation-destination-label
                  destination
                  :workspace-source)
                 :topicmap-source-label
                 (workspace-annotation-destination-label
                  destination
                  :topicmap-source)
                 :destination-rationale
                 (dmx-workspace-annotation-destination-rationale destination)))
        (when persisted-p
          (views:html
            (:table :class "inspector-table"
                    (:tr (:th "Workspace topic id")
                         (:td (:tt (views:esc
                                    (format nil "~D"
                                            (workspace-annotation-topic-id-of
                                             annotation))))))
                    (:tr (:th "Workspace topic uri")
                         (:td (:tt (views:esc
                                    (workspace-annotation-topic-uri-of
                                     annotation)))))
                    (:tr (:th "Storage mode")
                         (:td (:tt (views:esc
                                    (workspace-annotation-storage-mode-label
                                     (workspace-annotation-storage-mode-of
                                      annotation))))))
                    (:tr (:th "Carrier type")
                         (:td (:tt (views:esc
                                    (workspace-annotation-render-value
                                     (workspace-annotation-carrier-type-uri-of
                                      annotation))))))
                    (:tr (:th "Workspace status")
                         (:td (:tt (views:esc
                                    (or (workspace-annotation-status-of annotation)
                                        "-"))))))))
        (:p
         (views:eval-button
          "Inspect workspace write plan"
          (views:thunk
            (plan-dmx-workspace-annotation-write-from-object
             annotation
             :workspace-topicmap-id workspace-topicmap-id
             :workspace-id workspace-id))
          "Render the typed DMX write plan without mutating DMX."))
        (:p
         (views:eval-button
          "Debug workspace persistence"
          (views:thunk
            (debug-dock-annotation-workspace-persistence
             annotation
             :workspace-topicmap-id workspace-topicmap-id
             :workspace-id workspace-id
             :client default-client))
          "Open the exact persist form, a dry-run preview, and a step-through debug surface for the live write path."))
        (:p
         (views:eval-button
          "Trace workspace persistence path"
          (views:thunk
            (trace-dock-annotation-workspace-persistence-path
             annotation
             :workspace-topicmap-id workspace-topicmap-id
             :workspace-id workspace-id
             :client default-client))
          "Inspect the persistence boundary as a reusable code-path graph before running the live write."))
        (:p
         (views:eval-button
          "Compare with guarded workspace path"
          (views:thunk
            (compare-dock-annotation-with-guarded-workspace-path
             annotation
             :workspace-topicmap-id workspace-topicmap-id
             :workspace-id workspace-id
             :client default-client))
          "Compare the raw annotation persist path against the guarded continuation / MCP path while keeping workspace assignment distinct from topicmap placement."))
        (:p
         (views:eval-button
          "Probe live annotation type support"
          (views:thunk
            (probe-live-workspace-annotation-type-support
             annotation
             :workspace-topicmap-id workspace-topicmap-id
             :workspace-id workspace-id
             :client default-client))
          "Check whether the live DMX backend exposes raw hyperdoc.annotation and whether the deliberate compatibility carrier is available for the normal persist path."))
        (:p
         (views:eval-button
          "Probe live create-topic"
          (views:thunk
            (probe-live-create-topic-for-dock-annotation
             annotation
             :workspace-topicmap-id workspace-topicmap-id
             :workspace-id workspace-id
             :client default-client))
          "Stop after the raw hyperdoc.annotation create-topic request and inspect the exact request/response boundary without assignment, topicmap placement, or journaling."))
        (:p
         (views:eval-button
          (if persisted-p
              "Update workspace topic"
              "Persist to workspace")
          (views:thunk
            (persist-dock-annotation-to-workspace
             annotation
             :workspace-topicmap-id workspace-topicmap-id
             :workspace-id workspace-id
             :client default-client
             :dry-run nil))
          "Preflight the live backend first. If raw hyperdoc.annotation is unsupported but compatibility storage is available, persist through the deliberate carrier instead of issuing a doomed raw create-topic write."))
        (when persisted-p
          (views:html
            (:p
             (views:eval-button
              "Reopen by workspace topic id"
              (views:thunk
                (read-dmx-workspace-annotation
                 :topic-id (workspace-annotation-topic-id-of annotation)
                 :workspace-topicmap-id workspace-topicmap-id
                 :client default-client))
              "Reopen the persisted annotation through its stable DMX topic id."))
            (:p
             (views:eval-button
              "Inspect workspace journal"
              (views:thunk
                (read-dmx-topic-journal
                 :workspace-topicmap-id workspace-topicmap-id
                 :client default-client
                 :topic-id (workspace-annotation-topic-id-of annotation)
                 :reconcile nil))
              "Inspect the stored workspace journal stream for this annotation topic."))))))))

(views:defview 👀overview (debug workspace-annotation-persistence-debug)
  (views:html-view :title "Overview" :priority 1
    (let ((annotation (workspace-annotation-persistence-debug-annotation-of debug))
          (preview (workspace-annotation-persistence-debug-dry-run-preview-of debug))
          (preview-error (workspace-annotation-persistence-debug-preview-error-of
                          debug)))
      (views:html
        (:p (views:esc
             "This debug surface keeps the current annotation bound to * for Playground stepping, shows the exact persist form the workspace button would use, and turns the live write into a staged report instead of an opaque eval action."))
        (:table :class "inspector-table"
                (:tr (:th "Annotation")
                     (:td (views:object-ref annotation)))
                (:tr (:th "Annotation key")
                     (:td (:tt (views:esc
                                (or (workspace-annotation-persistence-debug-annotation-key-of
                                     debug)
                                    "-")))))
                (:tr (:th "Runtime relation id")
                     (:td (:tt (views:esc
                                (or (workspace-annotation-persistence-debug-runtime-relation-id-of
                                     debug)
                                    "-")))))
                (render-workspace-annotation-destination-rows
                 :workspace-id
                 (workspace-annotation-persistence-debug-workspace-id-of debug)
                 :workspace-topicmap-id
                 (workspace-annotation-persistence-debug-workspace-topicmap-id-of
                  debug)
                 :destination-source-label
                 (workspace-annotation-destination-label
                  (workspace-annotation-persistence-debug-destination-of debug)
                  :source)
                 :workspace-source-label
                 (workspace-annotation-destination-label
                  (workspace-annotation-persistence-debug-destination-of debug)
                  :workspace-source)
                 :topicmap-source-label
                 (workspace-annotation-destination-label
                  (workspace-annotation-persistence-debug-destination-of debug)
                  :topicmap-source)
                 :destination-rationale
                 (and (workspace-annotation-persistence-debug-destination-of
                       debug)
                      (dmx-workspace-annotation-destination-rationale
                       (workspace-annotation-persistence-debug-destination-of
                        debug))))
                (:tr (:th "Execution client")
                     (:td (:tt (views:esc
                                (workspace-annotation-persistence-client-label
                                 (workspace-annotation-persistence-debug-client-of
                                  debug)))))))
        (:p
         (views:eval-button
          "Open persistence stepper"
          (views:thunk
            (clog-moldable-inspector::make-playground-stepper
             annotation
             (workspace-annotation-persistence-debug-stepper-source-of debug)))
          "Step the dry-run plan form first and then the exact live persist form with the current annotation bound to *."))
        (:p
         (views:eval-button
          "Run live persistence report"
          (views:thunk
            (run-dock-annotation-workspace-persistence-debug
             annotation
             :workspace-topicmap-id
             (workspace-annotation-persistence-debug-workspace-topicmap-id-of
              debug)
             :workspace-id
             (workspace-annotation-persistence-debug-workspace-id-of debug)
             :client
             (workspace-annotation-persistence-debug-client-of debug)
             :view-props
             (workspace-annotation-persistence-debug-view-props-of debug)
             :status
             (workspace-annotation-persistence-debug-requested-status-of debug)
             :supersedes-topic-id
             (workspace-annotation-persistence-debug-supersedes-topic-id-of
              debug)
             :annotation-key
             (workspace-annotation-persistence-debug-annotation-key-override-of
              debug)
             :provenance-json
             (workspace-annotation-persistence-debug-provenance-json-of debug)))
          "Execute the live persistence path and classify which write stage succeeded or failed."))
        (:p
         (views:eval-button
          "Trace workspace persistence path"
          (views:thunk
            (workspace-annotation-persistence-debug-graph debug))
          "Open the reusable code-path graph for this annotation persistence path."))
        (when (workspace-annotation-persistence-debug-last-report-of debug)
          (views:html
            (:p
             (views:object-ref
              (workspace-annotation-persistence-debug-last-report-of debug)
              :display "Last live persistence report"))))
        (:h4 "Dry-run preview")
        (render-workspace-annotation-persistence-preview preview preview-error)))))

(views:defview 👀form (debug workspace-annotation-persistence-debug)
  (views:html-view :title "Form" :priority 2
    (views:html
      (:h4 "Exact persist form")
      (:pre :style "white-space: pre-wrap"
            (views:esc
             (workspace-annotation-persistence-debug-exact-form-of debug)))
      (:h4 "Stepper source")
      (:pre :style "white-space: pre-wrap"
            (views:esc
             (workspace-annotation-persistence-debug-stepper-source-of debug))))))

(views:defview 👀overview (report workspace-annotation-persistence-report)
  (views:html-view :title "Overview" :priority 1
    (let* ((plan (workspace-annotation-persistence-report-plan-of report))
           (comparison
             (compare-dock-annotation-with-guarded-workspace-path
              (workspace-annotation-persistence-report-annotation-of report)
              :workspace-topicmap-id
              (workspace-annotation-persistence-report-workspace-topicmap-id-of
               report)
              :workspace-id
              (or (and plan
                       (dmx-workspace-annotation-write-plan-workspace-id plan))
                  (workspace-annotation-persistence-report-workspace-id-of
                   report))
              :client (workspace-annotation-persistence-report-client-of report)
              :report report
              :view-props (and plan
                               (dmx-workspace-annotation-write-plan-view-props
                                plan))
              :status (and plan
                           (dmx-workspace-annotation-write-plan-status plan))
              :supersedes-topic-id
              (and plan
                   (dmx-workspace-annotation-write-plan-supersedes-topic-id
                    plan))
              :annotation-key
              (workspace-annotation-persistence-report-annotation-key-of report)
              :provenance-json
              (and plan
                   (dmx-workspace-annotation-write-plan-provenance-json plan))
              :storage-mode
              (and plan
                   (dmx-workspace-annotation-write-plan-storage-mode plan))))
           (consequences
             (and comparison
                  (workspace-annotation-path-diff-consequences-of comparison)))
          (assignment-auth-context
            (workspace-annotation-persistence-report-assignment-auth-context-of
             report)))
      (views:html
      (:p (views:esc
           "Live workspace persistence report with exact form, dry-run preview, and explicit stage classification. This surfaces whether failure happened during topic upsert, workspace assignment, topicmap placement, journal recording, or reopen, and whether live persistence used native typing or the compatibility carrier."))
      (:table :class "inspector-table"
              (:tr (:th "Status")
                   (:td (:tt (views:esc
                              (format nil "~A"
                                      (workspace-annotation-persistence-report-status-of
                                       report))))))
              (:tr (:th "Storage mode")
                   (:td (:tt (views:esc
                              (workspace-annotation-storage-mode-label
                               (and plan
                                    (dmx-workspace-annotation-write-plan-storage-mode
                                     plan)))))))
              (:tr (:th "Carrier type")
                   (:td (:tt (views:esc
                              (workspace-annotation-render-value
                               (and plan
                                    (dmx-workspace-annotation-write-plan-carrier-type-uri
                                     plan)))))))
              (:tr (:th "Planned topic type")
                   (:td (:tt (views:esc
                              (workspace-annotation-render-value
                               (and plan
                                    (getf (dmx-workspace-annotation-write-plan-payload
                                           plan)
                                          :type-uri)))))))
              (:tr (:th "Failure stage")
                   (:td (:tt (views:esc
                              (format nil "~A"
                                      (or (workspace-annotation-persistence-report-failure-stage-of
                                           report)
                                          "-"))))))
              (:tr (:th "Annotation key")
                   (:td (:tt (views:esc
                              (or (workspace-annotation-persistence-report-annotation-key-of
                                   report)
                                  "-")))))
              (:tr (:th "Runtime relation id")
                   (:td (:tt (views:esc
                              (or (workspace-annotation-persistence-report-runtime-relation-id-of
                                   report)
                                  "-")))))
              (render-workspace-annotation-destination-rows
               :workspace-id
               (and plan
                    (dmx-workspace-annotation-write-plan-workspace-id plan))
               :workspace-topicmap-id
               (workspace-annotation-persistence-report-workspace-topicmap-id-of
                report)
               :destination-source-label
               (workspace-annotation-render-value
                (and plan
                     (dmx-workspace-annotation-destination-source-label
                      (dmx-workspace-annotation-destination-source
                       (dmx-workspace-annotation-write-plan-destination plan)))))
               :workspace-source-label
               (workspace-annotation-render-value
                (and plan
                     (dmx-workspace-annotation-destination-source-label
                      (dmx-workspace-annotation-destination-workspace-source
                       (dmx-workspace-annotation-write-plan-destination plan)))))
               :topicmap-source-label
               (workspace-annotation-render-value
                (and plan
                     (dmx-workspace-annotation-destination-source-label
                      (dmx-workspace-annotation-destination-topicmap-source
                       (dmx-workspace-annotation-write-plan-destination plan)))))
               :destination-rationale
               (and plan
                    (dmx-workspace-annotation-destination-rationale
                     (dmx-workspace-annotation-write-plan-destination plan))))
              (:tr (:th "Workspace topic id")
                   (:td (:tt (views:esc
                              (format nil "~A"
                                      (or (workspace-annotation-persistence-report-saved-topic-id-of
                                           report)
                                          "-")))))))
      (when consequences
        (render-workspace-annotation-path-consequence-table
         consequences
         :heading "Operational consequences"))
      (if (workspace-annotation-persistence-report-existing-saved-topic-p
           report)
          (render-workspace-annotation-saved-topic-surface report)
          (when-let (persisted
                       (workspace-annotation-persistence-report-persisted-annotation-of
                        report))
            (views:html
              (:p (views:object-ref
                   persisted
                   :display "Persisted workspace annotation")))))
      (when (or (eq (workspace-annotation-persistence-report-failure-stage-of
                     report)
                    :prepare-transition)
                (workspace-annotation-persistence-report-journal-topic-id-of
                 report))
        (render-workspace-annotation-journal-preflight-surface report))
      (when-let (condition
                   (workspace-annotation-persistence-report-condition-of report))
        (views:html
          (:h4 "Condition")
          (:pre :style "white-space: pre-wrap"
                (views:esc (format nil "~A" condition)))))
      (when-let (diagnostics
                   (workspace-annotation-persistence-report-transport-diagnostics-of
                    report))
        (views:html
          (:h4 "Transport diagnostics")
          (:table :class "inspector-table"
                  (:tr (:th "Transport stage")
                       (:td (:tt (views:esc
                                  (format nil "~A"
                                          (getf diagnostics :transport-stage))))))
                  (:tr (:th "Failing field")
                       (:td (:tt (views:esc
                                  (format nil "~A"
                                          (getf diagnostics :field))))))
                  (:tr (:th "Character")
                       (:td (:tt (views:esc
                                  (or (getf diagnostics :character) "-")))))
                  (:tr (:th "Code point")
                       (:td (:tt (views:esc
                                  (format nil "~A"
                                          (or (getf diagnostics :code-point)
                                              "-"))))))
                  (:tr (:th "Position")
                       (:td (:tt (views:esc
                                  (format nil "~A"
                                          (or (getf diagnostics :position)
                                              "-")))))))))
      (when-let (evidence
                   (workspace-annotation-persistence-report-topic-upsert-evidence-of
                    report))
        (views:html
          (:h4 "Topic upsert failure evidence")
          (render-workspace-annotation-http-evidence-table
           evidence
           :payload-json (getf evidence :payload-json)
           :planned-topic-action (getf evidence :planned-topic-action)
           :planned-workspace-action (getf evidence :planned-workspace-action)
           :planned-topicmap-action (getf evidence :planned-topicmap-action))))
      (when (workspace-annotation-pending-auth-p report)
        (let (mode-cell username-cell password-cell header-cell token-cell)
          (views:html
            (:h4 "Workspace assignment blocked")
            (:p (views:esc
                 "Topic creation already succeeded for the selected annotation carrier, but assignment to the selected workspace could not start because DMX auth is missing. This is the designed pending-auth boundary. Workspace assignment and topicmap placement remain separate guarded steps; visibility in the topicmap is not a substitute for belonging to the workspace."))
            (:table :class "inspector-table"
                    (:tr (:th "Created topic")
                         (:td (:tt (views:esc
                                    (workspace-annotation-render-value
                                     (getf assignment-auth-context
                                           :created-topic-id))))))
                    (render-workspace-annotation-destination-rows
                     :workspace-id
                     (getf assignment-auth-context :workspace-id)
                     :workspace-topicmap-id
                     (getf assignment-auth-context :workspace-topicmap-id)
                     :destination-source-label
                     (getf assignment-auth-context :destination-source-label)
                     :workspace-source-label
                     (getf assignment-auth-context :workspace-source-label)
                     :topicmap-source-label
                     (getf assignment-auth-context :topicmap-source-label)
                     :destination-rationale
                     (getf assignment-auth-context :destination-rationale))
                    (:tr (:th "Assignment endpoint")
                         (:td (:tt (views:esc
                                    (workspace-annotation-render-value
                                     (getf assignment-auth-context
                                           :assignment-endpoint-path))))))
                    (:tr (:th "Env auth present")
                         (:td (:tt (views:esc
                                    (format nil "~A"
                                            (getf assignment-auth-context
                                                  :environment-auth-present-p))))))
                    (:tr (:th "Env auth summary")
                         (:td (:tt (views:esc
                                    (workspace-annotation-render-value
                                     (getf assignment-auth-context
                                           :environment-auth-mode-summary))))))
                    (:tr (:th "Bootstrap/login needed")
                         (:td (:tt (views:esc
                                    (format nil "~A"
                                            (getf assignment-auth-context
                                                  :session-login-required-p))))))
                    (:tr (:th "Missing auth keys")
                         (:td (:tt (views:esc
                                    (if-let (missing
                                             (getf assignment-auth-context
                                                   :auth-missing-keys))
                                      (format nil "~{~A~^, ~}" missing)
                                      "-")))))
                    (:tr (:th "Available auth modes")
                         (:td (:tt (views:esc
                                    (if-let (modes
                                             (getf assignment-auth-context
                                                   :available-auth-modes))
                                      (format nil
                                              "~{~A~^, ~}"
                                      (mapcar #'workspace-annotation-auth-mode-label
                                                      modes))
                                      "-")))))
                    (:tr (:th "Assignment boundary")
                         (:td (views:esc
                               "Workspace assignment is not the same as topicmap placement. Topicmap visibility alone is not a saved-enough outcome."))))
            (when-let (explicit-condition
                         (getf assignment-auth-context :explicit-auth-condition))
              (views:html
                (:h4 "Explicit auth input problem")
                (:pre :style "white-space: pre-wrap"
                      (views:esc explicit-condition))))
            (:h4 "Continue with explicit auth")
            (setf mode-cell
                  (hvr:select '(("Username + password" . "basic")
                                ("Authorization header" . "header")
                                ("Bearer token" . "token"))
                              :label "Credential mode: "))
            (:br)
            (setf username-cell
                  (hvr:input :label "Username: " :initial-value "" :size "24"))
            (:br)
            (setf password-cell
                  (hvr:input :label "Password: "
                             :initial-value ""
                             :size "24"
                             :type :password))
            (:br)
            (setf header-cell
                  (hvr:input :label "Authorization header: "
                             :initial-value ""
                             :size "64"))
            (:br)
            (setf token-cell
                  (hvr:input :label "Bearer token: "
                             :initial-value ""
                             :size "48"
                             :type :password))
            (:p (views:esc
                 "Only the fields required by the active credential mode are used for the next action. This continuation reuses the already-created topic and only performs the remaining guarded assignment, topicmap placement, journal, and reopen steps."))
            (views:action-button
             "Continue with explicit auth"
             (views:thunk
               (continue-workspace-annotation-persistence-with-explicit-auth
                report
                :auth-mode (lwcells:cell-ref mode-cell)
                :username (lwcells:cell-ref username-cell)
                :password (lwcells:cell-ref password-cell)
                :authorization-header (lwcells:cell-ref header-cell)
                :auth-token (lwcells:cell-ref token-cell))
               t)
             "Continue the remaining guarded live write with one-shot explicit credentials."))))
      (:p
       (views:eval-button
        "Compare with guarded workspace path"
        (views:thunk
          (compare-dock-annotation-with-guarded-workspace-path
           (workspace-annotation-persistence-report-annotation-of report)
           :workspace-topicmap-id
           (workspace-annotation-persistence-report-workspace-topicmap-id-of
            report)
           :workspace-id
           (or (and plan
                    (dmx-workspace-annotation-write-plan-workspace-id plan))
               (workspace-annotation-persistence-report-workspace-id-of
                report))
           :client (workspace-annotation-persistence-report-client-of report)
           :report report
           :view-props (and plan
                            (dmx-workspace-annotation-write-plan-view-props
                             plan))
           :status (and plan
                        (dmx-workspace-annotation-write-plan-status plan))
           :supersedes-topic-id
           (and plan
                (dmx-workspace-annotation-write-plan-supersedes-topic-id
                 plan))
           :annotation-key
           (workspace-annotation-persistence-report-annotation-key-of report)
           :provenance-json
           (and plan
                (dmx-workspace-annotation-write-plan-provenance-json plan))
           :storage-mode
           (and plan
                (dmx-workspace-annotation-write-plan-storage-mode plan))))
        "Compare the raw annotation persist path against the guarded continuation / MCP path using the preserved report and topic id when available."))
      (:p
       (views:eval-button
        "Open persistence stepper"
        (views:thunk
          (clog-moldable-inspector::make-playground-stepper
           (workspace-annotation-persistence-report-annotation-of report)
           (workspace-annotation-persistence-report-stepper-source-of report)))
        "Replay the same stepper source with the current annotation bound to *."))
      (:p
       (views:eval-button
        "Trace workspace persistence path"
        (views:thunk
          (workspace-annotation-persistence-report-graph report))
        "Open the staged code-path graph for this live persistence report."))
      (:h4 "Dry-run preview")
      (render-workspace-annotation-persistence-preview
       (workspace-annotation-persistence-report-dry-run-preview-of report)
       nil)))))

(views:defview 👀stages (report workspace-annotation-persistence-report)
  (views:html-view :title "Stages" :priority 2
    (render-workspace-annotation-persistence-stage-table report)))

(views:defview 👀form (report workspace-annotation-persistence-report)
  (views:html-view :title "Form" :priority 3
    (views:html
      (:h4 "Exact persist form")
      (:pre :style "white-space: pre-wrap"
            (views:esc
             (workspace-annotation-persistence-report-exact-form-of report)))
      (:h4 "Stepper source")
      (:pre :style "white-space: pre-wrap"
            (views:esc
             (workspace-annotation-persistence-report-stepper-source-of report))))))        

(views:defview 👀overview (comparison workspace-annotation-path-diff)
  (views:html-view :title "Overview" :priority 1
    (let* ((annotation (workspace-annotation-path-diff-annotation-of comparison))
           (plan (workspace-annotation-path-diff-plan-of comparison))
           (destination (workspace-annotation-path-diff-destination-of comparison))
           (raw-report (workspace-annotation-path-diff-raw-report-of comparison))
           (graph (workspace-annotation-path-diff-graph comparison)))
      (views:html
        (:p (views:esc
             "Inspectable comparison between the raw annotation persist path and the guarded continuation / MCP path. The goal is to keep typed planning and staging as the entrypoint while making the workspace-assignment auth divergence explicit."))
        (:p (views:esc
             "Workspace assignment and topicmap placement remain separate facts throughout this comparison. Topicmap visibility is not workspace ownership."))
        (:table :class "inspector-table"
                (:tr (:th "Annotation")
                     (:td (views:object-ref annotation)))
                (render-workspace-annotation-destination-rows
                 :workspace-id
                 (or (and plan
                          (dmx-workspace-annotation-write-plan-workspace-id
                           plan))
                     (workspace-annotation-path-diff-workspace-id-of
                      comparison))
                 :workspace-topicmap-id
                 (workspace-annotation-path-diff-workspace-topicmap-id-of
                  comparison)
                 :destination-source-label
                 (workspace-annotation-destination-label destination :source)
                 :workspace-source-label
                 (workspace-annotation-destination-label
                  destination
                  :workspace-source)
                 :topicmap-source-label
                 (workspace-annotation-destination-label
                  destination
                  :topicmap-source)
                 :destination-rationale
                 (and destination
                      (dmx-workspace-annotation-destination-rationale
                       destination)))
                (:tr (:th "Continuation topic id")
                     (:td (:tt (views:esc
                                (workspace-annotation-render-value
                                 (workspace-annotation-path-diff-continuation-topic-id-of
                                  comparison))))))
                (:tr (:th "Typed storage mode")
                     (:td (:tt (views:esc
                                (workspace-annotation-storage-mode-label
                                 (and plan
                                      (dmx-workspace-annotation-write-plan-storage-mode
                                       plan)))))))
                (:tr (:th "Typed carrier type")
                     (:td (:tt (views:esc
                                (workspace-annotation-render-value
                                 (and plan
                                      (dmx-workspace-annotation-write-plan-carrier-type-uri
                                       plan))))))))
        (when raw-report
          (views:html
            (:p
             (views:object-ref raw-report
                               :display "Open preserved persistence report"
                               :select "Overview"))))
        (:ul
         (:li
          (views:object-ref comparison
                            :display "Open consequences"
                            :select "Consequences"))
         (:li
          (views:object-ref graph
                            :display "Open graph overview"
                            :select "Overview"))
         (:li
          (views:object-ref graph
                            :display "Open Graphviz"
                            :select "Graphviz"))
         (:li
          (views:object-ref graph
                            :display "Open focused paths"
                            :select "Focused paths")))))))

(views:defview 👀path-diff (comparison workspace-annotation-path-diff)
  (views:html-view :title "Path diff" :priority 2
    (render-workspace-annotation-path-diff-table comparison)))

(views:defview 👀consequences (comparison workspace-annotation-path-diff)
  (views:html-view :title "Consequences" :priority 3
    (render-workspace-annotation-path-consequence-table
     (workspace-annotation-path-diff-consequences-of comparison)
     :heading "Consequences")))

(views:defview 👀graph (comparison workspace-annotation-path-diff)
  (views:html-view :title "Graph" :priority 4
    (let ((graph (workspace-annotation-path-diff-graph comparison))
          (consequences
            (workspace-annotation-path-diff-consequences-of comparison)))
      (views:html
        (:p (views:esc
             "Reusable code-path graph for the compared raw and guarded paths. The divergence point is the workspace-assignment auth boundary."))
        (:table :class "inspector-table"
                (:tr (:th "Focused path")
                     (:td (views:esc "Main annotation persist path")))
                (:tr (:th "Focused path")
                     (:td (views:esc "Guarded continuation path")))
                (:tr (:th "Contrast branch")
                     (:td (views:esc "Raw pending-auth stop")))
                (:tr (:th "Divergence node")
                     (:td (:tt (views:esc
                                "workspace-assignment auth boundary"))))
                (:tr (:th "Consequence label")
                     (:td (views:esc
                           (or (workspace-annotation-path-consequence-summary-for-stages
                                comparison
                                '(:topic-upsert :workspace-assignment))
                               "No extra divergence consequence")))))
        (:p (views:esc
             "Workspace assignment and topicmap placement stay separate here too. Guarded topicmap success must not be read as proof of workspace ownership."))
        (render-workspace-annotation-path-consequence-table
         consequences
         :heading "Divergence consequences")
        (:ul
         (:li
          (views:object-ref graph
                            :display "Open graph overview"
                            :select "Overview"))
         (:li
          (views:object-ref graph
                            :display "Open Graphviz"
                            :select "Graphviz"))
         (:li
          (views:object-ref graph
                            :display "Open focused paths"
                            :select "Focused paths")))))))

(views:defview 👀overview (report workspace-annotation-create-topic-probe-report)
  (views:html-view :title "Overview" :priority 1
    (let ((plan (workspace-annotation-create-topic-probe-plan-of report))
          (evidence (workspace-annotation-create-topic-probe-http-evidence-of report)))
      (views:html
        (:p (views:esc
             "Live DMX create-topic probe for the current Dock annotation. This is the explicit raw hyperdoc.annotation diagnostic, not the compatibility carrier path used by normal live persistence."))
        (:table :class "inspector-table"
                (:tr (:th "Status")
                     (:td (:tt (views:esc
                                (format nil "~A"
                                        (workspace-annotation-create-topic-probe-status-of
                                         report))))))
                (:tr (:th "Storage mode")
                     (:td (:tt (views:esc
                                (workspace-annotation-storage-mode-label
                                 (and plan
                                      (dmx-workspace-annotation-write-plan-storage-mode
                                       plan)))))))
                (:tr (:th "Planned topic type")
                     (:td (:tt (views:esc
                                (workspace-annotation-render-value
                                 (and plan
                                      (getf (dmx-workspace-annotation-write-plan-payload
                                             plan)
                                            :type-uri)))))))
                (:tr (:th "Workspace topicmap")
                     (:td (:tt (views:esc
                                (format nil "~D"
                                        (workspace-annotation-create-topic-probe-workspace-topicmap-id-of
                                         report))))))
                (:tr (:th "Planned topic action")
                     (:td (:tt (views:esc
                                (format nil "~A"
                                        (and plan
                                             (dmx-workspace-annotation-write-plan-topic-action
                                              plan)))))))
                (:tr (:th "Created topic id")
                     (:td (:tt (views:esc
                                (format nil "~A"
                                        (or (workspace-annotation-create-topic-probe-created-topic-id-of
                                             report)
                                            "-")))))))
        (when-let (condition
                     (workspace-annotation-create-topic-probe-condition-of report))
          (views:html
            (:h4 "Condition")
            (:pre :style "white-space: pre-wrap"
                  (views:esc (format nil "~A" condition)))))
        (when evidence
          (render-workspace-annotation-http-evidence-table
           evidence
           :payload-json
           (workspace-annotation-create-topic-probe-payload-json-of report)
           :planned-topic-action
           (and plan
                (dmx-workspace-annotation-write-plan-topic-action plan))
           :planned-workspace-action
           (and plan
                (dmx-workspace-annotation-write-plan-workspace-action plan))
           :planned-topicmap-action
           (and plan
                (dmx-workspace-annotation-write-plan-topicmap-action plan))))
        (:h4 "Dry-run preview")
        (render-workspace-annotation-persistence-preview
         (workspace-annotation-create-topic-probe-dry-run-preview-of report)
         nil)))))

(views:defview 👀form (report workspace-annotation-create-topic-probe-report)
  (views:html-view :title "Form" :priority 2
    (views:html
      (:h4 "Exact create-topic probe form")
      (:pre :style "white-space: pre-wrap"
            (views:esc
             (workspace-annotation-create-topic-probe-exact-form-of report)))
      (:h4 "Planned payload JSON")
      (:pre :style "white-space: pre-wrap"
            (views:esc
             (or (workspace-annotation-create-topic-probe-payload-json-of report)
                 ""))))))

(views:defview 👀overview (report workspace-annotation-backend-compatibility-report)
  (views:html-view :title "Overview" :priority 1
    (let ((plan (workspace-annotation-backend-compatibility-report-plan-of report))
          (evidence
            (workspace-annotation-backend-compatibility-report-http-evidence-of
             report)))
      (views:html
        (:p (views:esc
             "Live backend compatibility preflight for workspace annotations. The normal Persist to workspace action uses this check to choose deliberate compatibility storage when raw hyperdoc.annotation is missing, and to block only when neither the native type family nor the chosen carrier path is available."))
        (:table :class "inspector-table"
                (:tr (:th "Status")
                     (:td (:tt (views:esc
                                (format nil "~A"
                                        (workspace-annotation-backend-compatibility-report-status-of
                                         report))))))
                (:tr (:th "Selected storage mode")
                     (:td (:tt (views:esc
                                (workspace-annotation-storage-mode-label
                                 (workspace-annotation-backend-compatibility-report-selected-storage-mode-of
                                  report))))))
                (:tr (:th "Compatibility carrier")
                     (:td (:tt (views:esc
                                (workspace-annotation-render-value
                                 (workspace-annotation-backend-compatibility-report-carrier-type-uri-of
                                  report))))))
                (:tr (:th "Native type supported")
                     (:td (:tt (views:esc
                                (format nil "~A"
                                        (workspace-annotation-backend-compatibility-report-native-supported-p-of
                                         report))))))
                (:tr (:th "Carrier supported")
                     (:td (:tt (views:esc
                                (format nil "~A"
                                        (workspace-annotation-backend-compatibility-report-carrier-supported-p-of
                                         report))))))
                (:tr (:th "Workspace topicmap")
                     (:td (:tt (views:esc
                                (format nil "~D"
                                        (workspace-annotation-backend-compatibility-report-workspace-topicmap-id-of
                                         report))))))
                (:tr (:th "Create endpoint")
                     (:td (:tt (views:esc
                                (or (workspace-annotation-backend-compatibility-report-endpoint-path-of
                                     report)
                                    "-")))))
                (:tr (:th "Failing type URI")
                     (:td (:tt (views:esc
                                (or (workspace-annotation-backend-compatibility-report-failing-type-uri-of
                                     report)
                                    "-")))))
                (:tr (:th "Native missing type URI")
                     (:td (:tt (views:esc
                                (or (workspace-annotation-backend-compatibility-report-native-failing-type-uri-of
                                     report)
                                    "-")))))
                (:tr (:th "Planned topic action")
                     (:td (:tt (views:esc
                                (format nil "~A"
                                        (and plan
                                             (dmx-workspace-annotation-write-plan-topic-action
                                              plan))))))))
        (when-let (condition
                     (workspace-annotation-backend-compatibility-report-condition-of
                      report))
          (views:html
            (:h4 "Condition")
            (:pre :style "white-space: pre-wrap"
                  (views:esc (format nil "~A" condition)))))
        (when evidence
          (views:html
            (:h4 "Type support probe evidence")
            (render-workspace-annotation-http-evidence-table
             evidence
             :payload-json
             (workspace-annotation-backend-compatibility-report-payload-json-of
              report)
             :planned-topic-action
             (and plan
                  (dmx-workspace-annotation-write-plan-topic-action plan))
             :planned-workspace-action
             (and plan
                  (dmx-workspace-annotation-write-plan-workspace-action plan))
             :planned-topicmap-action
             (and plan
                  (dmx-workspace-annotation-write-plan-topicmap-action plan)))))
        (when-let (known-body
                     (workspace-annotation-backend-compatibility-report-known-create-topic-response-body-of
                      report))
          (views:html
            (:h4 "Known live create-topic response")
            (:p (views:esc
                 "Previously observed direct create-topic probe result for this backend/type combination."))
            (:pre :style "white-space: pre-wrap"
                  (views:esc known-body))))
        (when-let (actions
                     (workspace-annotation-backend-compatibility-report-next-actions-of
                      report))
          (views:html
            (:h4 "Next actions")
            (:ul
             (dolist (action actions)
               (views:html
                 (:li (views:esc action)))))))
        (:p
         (views:eval-button
          "Probe live create-topic"
          (views:thunk
            (probe-live-create-topic-for-dock-annotation
             (workspace-annotation-backend-compatibility-report-annotation-of
              report)
             :workspace-topicmap-id
             (workspace-annotation-backend-compatibility-report-workspace-topicmap-id-of
              report)
             :client
             (workspace-annotation-backend-compatibility-report-client-of
              report)))
          "Run the explicit create-topic diagnostic anyway and inspect the exact POST /core/topic failure boundary."))
        (:h4 "Dry-run preview")
        (render-workspace-annotation-persistence-preview
         (workspace-annotation-backend-compatibility-report-dry-run-preview-of
          report)
         nil)))))

(views:defview 👀type-results (report workspace-annotation-backend-compatibility-report)
  (views:html-view :title "Type results" :priority 2
    (views:html
      (:p (views:esc
           "URI-based probe results for the raw annotation type family and, when selected, the compatibility carrier type family."))
      (render-workspace-annotation-backend-support-results
       (workspace-annotation-backend-compatibility-report-type-results-of
        report)))))

(views:defview 👀form (report workspace-annotation-backend-compatibility-report)
  (views:html-view :title "Form" :priority 3
    (views:html
      (:h4 "Exact compatibility probe form")
      (:pre :style "white-space: pre-wrap"
            (views:esc
             (workspace-annotation-backend-compatibility-report-exact-form-of
              report)))
      (:h4 "Planned payload JSON")
      (:pre :style "white-space: pre-wrap"
            (views:esc
             (or (workspace-annotation-backend-compatibility-report-payload-json-of
                  report)
                 ""))))))

(views:defview 👀bindings (annotation workspace-dock-annotation)
  (views:html-view :title "Bindings" :priority 5
    (views:html
      (:h4 "Source binding")
      (render-workspace-annotation-binding-table
       (workspace-annotation-source-binding-of annotation))
      (:h4 "Target binding")
      (render-workspace-annotation-binding-table
       (workspace-annotation-target-binding-of annotation))
      (:h4 "Context binding")
      (render-workspace-annotation-binding-table
       (workspace-annotation-context-binding-of annotation))
      (when (workspace-annotation-supersedes-binding-of annotation)
        (views:html
          (:h4 "Supersedes")
          (render-workspace-annotation-binding-table
           (workspace-annotation-supersedes-binding-of annotation)))))))

(views:defview 👀summary (snapshot dom-connect-pane-state-snapshot)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of snapshot)))
      (:p (views:esc (summary-of snapshot)))
      (:table :class "inspector-table hyperdoc-dom-connect-pane-summary-table"
              (render-connect-field-row "Pane id" (pane-id-of snapshot))
              (render-connect-field-row "Visible tab" (active-tab-of snapshot))
              (render-connect-field-row "View title"
                                        (context-view-title-of snapshot))
              (render-connect-field-row "Provider kind"
                                        (provider-kind-of snapshot))
              (render-connect-field-row "Available"
                                        (dom-connect-bool-label
                                         (available-p-of snapshot)))
              (render-connect-field-row "Enabled"
                                        (dom-connect-bool-label
                                         (enabled-p-of snapshot)))
              (render-connect-field-row "Local phase" (local-phase-of snapshot))
              (render-connect-field-row "Help open"
                                        (dom-connect-bool-label
                                         (help-open-p-of snapshot)))
              (render-connect-field-row "Presentation state"
                                        (presentation-state-of snapshot))
              (render-connect-field-row "Presentation reason"
                                        (presentation-reason-of snapshot))
              (render-connect-field-row "Coachmark visible"
                                        (dom-connect-bool-label
                                         (coachmark-visible-p-of snapshot)))
              (render-connect-field-row "Selected source label"
                                        (selected-source-label-of snapshot))
              (render-connect-field-row "Selected source pane"
                                        (dom-connect-bool-label
                                         (selected-source-pane-p-of snapshot)))
              (render-connect-rich-field-row "Compact capabilities"
                                             (compact-capabilities-of snapshot))
              (render-connect-rich-field-row "Coachmark capabilities"
                                             (coachmark-capabilities-of snapshot))
              (render-connect-rich-field-row "Provider handoffs"
                                             (provider-handoffs-of snapshot))
              (render-connect-field-row "Pending request id"
                                        (pending-request-id-of snapshot))))))

(views:defview 👀summary (entry dom-connect-transition-entry)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of entry)))
      (:p (views:esc (summary-of entry)))
      (:table :class "inspector-table hyperdoc-dom-connect-transition-summary-table"
              (render-connect-field-row "Stage" (stage-of entry))
              (render-connect-field-row "Request id" (request-id-of entry))
              (render-connect-field-row "Time" (timestamp-label-of entry))
              (render-connect-field-row "Pane id" (pane-id-of entry))
              (render-connect-field-row "Provider kind"
                                        (provider-kind-of entry))
              (render-connect-field-row "Anchor"
                                        (render-connect-transition-anchor-ref
                                         entry))))))

(views:defview 👀summary (snapshot dom-connect-session-snapshot)
  (views:html-view :title "Summary" :priority 1
    (let* ((source-anchor (source-anchor-of snapshot))
           (target-anchor (target-anchor-of snapshot))
           (last-transition (last-transition-of snapshot)))
      (views:html
        (:h3 (views:esc (title-of snapshot)))
        (:p (views:esc (summary-of snapshot)))
        (:table :class "inspector-table hyperdoc-dom-connect-session-summary-table"
                (render-connect-field-row "Session id"
                                          (or (session-id-of snapshot)
                                              "idle"))
                (render-connect-field-row "Global phase" (phase-of snapshot))
                (render-connect-field-row "Origin pane"
                                          (origin-pane-id-of snapshot))
                (render-connect-field-row "Source pane"
                                          (source-pane-id-of snapshot))
                (render-connect-field-row "Source provider kind"
                                          (or (source-provider-kind-of snapshot)
                                              (and source-anchor
                                                   (provider-kind-of
                                                    source-anchor))))
                (render-connect-field-row "Source semantic label"
                                          (dom-connect-anchor-label
                                           source-anchor))
                (render-connect-field-row "Target pane"
                                          (target-pane-id-of snapshot))
                (render-connect-field-row "Target provider kind"
                                          (or (target-provider-kind-of snapshot)
                                              (and target-anchor
                                                   (provider-kind-of
                                                    target-anchor))))
                (render-connect-field-row "Target semantic label"
                                          (dom-connect-anchor-label
                                           target-anchor))
                (render-connect-field-row "Pending request id"
                                          (or (pending-request-id-of snapshot)
                                              "none"))
                (render-connect-field-row "Pending request state"
                                          (or (pending-request-state-of snapshot)
                                              "none"))
                (render-connect-field-row "Last transition"
                                          (and last-transition
                                               (stage-of last-transition)))
                (render-connect-field-row "Last transition time"
                                          (and last-transition
                                               (timestamp-label-of
                                                last-transition)))
                (render-connect-field-row "Captured at"
                                          (captured-at-label-of snapshot))
                (render-connect-field-row "Context view"
                                          (context-view-title-of snapshot))
                (render-connect-field-row "Context object"
                                          (context-object-of snapshot)))))))

(views:defview 👀panes (snapshot dom-connect-session-snapshot)
  (views:html-view :title "Panes" :priority 2
    (views:html
      (:table :class "inspector-table hyperdoc-dom-connect-panes-table"
              (:tr (:th "Pane id")
                   (:th "Snapshot")
                   (:th "Visible tab")
                   (:th "View title")
                   (:th "Provider")
                   (:th "Available")
                   (:th "Enabled")
                   (:th "Local phase")
                   (:th "Presentation")
                   (:th "Coachmark")
                   (:th "Selected source label")
                   (:th "Compact capabilities")
                   (:th "Provider handoffs")
                   (:th "Pending request"))
              (if (panes-of snapshot)
                  (loop for pane-state in (panes-of snapshot)
                        do (views:html
                             (:tr (:td (:tt (views:esc
                                             (or (pane-id-of pane-state)
                                                 "-"))))
                                  (:td (maybe-dom-object-ref pane-state))
                                  (:td (views:esc
                                        (or (active-tab-of pane-state)
                                            "-")))
                                  (:td (views:esc
                                        (or (context-view-title-of pane-state)
                                            "-")))
                                  (:td (:tt (views:esc
                                             (or (provider-kind-of pane-state)
                                                 "-"))))
                                  (:td (views:esc
                                        (dom-connect-bool-label
                                         (available-p-of pane-state))))
                                  (:td (views:esc
                                        (dom-connect-bool-label
                                         (enabled-p-of pane-state))))
                                  (:td (:tt (views:esc
                                             (or (local-phase-of pane-state)
                                                 "-"))))
                                  (:td (:tt (views:esc
                                             (or (presentation-state-of pane-state)
                                                 "-"))))
                                  (:td (views:esc
                                        (dom-connect-bool-label
                                         (coachmark-visible-p-of pane-state))))
                                  (:td (views:esc
                                        (or (selected-source-label-of
                                             pane-state)
                                            "-")))
                                  (:td (render-connect-data-cell
                                        (compact-capabilities-of pane-state)))
                                  (:td (render-connect-data-cell
                                        (provider-handoffs-of pane-state)))
                                  (:td (:tt (views:esc
                                             (or (pending-request-id-of
                                                  pane-state)
                                                 "-")))))))
                  (views:html
                    (:tr (:td :colspan "13"
                              (:span :style "opacity: 0.55;"
                                     "No live panes are registered.")))))))))

(views:defview 👀transitions (snapshot dom-connect-session-snapshot)
  (views:html-view :title "Transitions" :priority 3
    (views:html
      (:table :class "inspector-table hyperdoc-dom-connect-transitions-table"
              (:tr (:th "Time")
                   (:th "Stage")
                   (:th "Request id")
                   (:th "Pane id")
                   (:th "Provider")
                   (:th "Anchor")
                   (:th "Transition")
                   (:th "Summary"))
              (if (transitions-of snapshot)
                  (loop for entry in (transitions-of snapshot)
                        do (views:html
                             (:tr (:td (:tt (views:esc
                                             (or (timestamp-label-of entry)
                                                 "-"))))
                                  (:td (:tt (views:esc
                                             (or (stage-of entry)
                                                 "-"))))
                                  (:td (:tt (views:esc
                                             (or (request-id-of entry)
                                                 "-"))))
                                  (:td (:tt (views:esc
                                             (or (pane-id-of entry)
                                                 "-"))))
                                  (:td (:tt (views:esc
                                             (or (provider-kind-of entry)
                                                 "-"))))
                                  (:td (maybe-dom-object-ref
                                        (render-connect-transition-anchor-ref
                                         entry)
                                        :fallback-empty "-"))
                                  (:td (maybe-dom-object-ref entry))
                                  (:td (views:esc (summary-of entry))))))
                  (views:html
                    (:tr (:td :colspan "8"
                              (:span :style "opacity: 0.55;"
                                     "No Connect transitions have been recorded.")))))))))

(views:defview 👀payload (snapshot dom-connect-session-snapshot)
  (views:html-view :title "Payload / Anchors" :priority 4
    (views:html
      (render-connect-anchor-section "Source anchor"
                                     (source-anchor-of snapshot))
      (render-connect-anchor-section "Target anchor"
                                     (target-anchor-of snapshot)))))

(views:defview 👀summary (evidence dom-connect-request-evidence)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of evidence)))
      (:p (views:esc (summary-of evidence)))
      (:table :class "inspector-table hyperdoc-dom-connect-request-evidence-table"
              (render-connect-field-row "Request id" (request-id-of evidence))
              (render-connect-field-row "Transport" (transport-of evidence))
              (render-connect-field-row "Context view"
                                        (context-view-title-of evidence))
              (render-connect-field-row "Context object"
                                        (context-object-of evidence))
              (render-connect-field-row "Inspection pane id"
                                        (inspection-pane-id-of evidence))
              (render-connect-field-row "Source pane"
                                        (source-pane-id-of evidence))
              (render-connect-field-row "Target pane"
                                        (target-pane-id-of evidence))
              (render-connect-field-row "Source provider kind"
                                        (source-provider-kind-of evidence))
              (render-connect-field-row "Target provider kind"
                                        (target-provider-kind-of evidence))
              (render-connect-field-row "Server status"
                                        (server-status-of evidence))
              (render-connect-field-row "Server acknowledged"
                                        (dom-connect-bool-label
                                         (server-acknowledged-p-of evidence)))
              (render-connect-field-row "Browser failure kind"
                                        (or (dom-connect-evidence-failure-kind-label
                                             (browser-failure-kind-of evidence))
                                            "none"))
              (render-connect-field-row "Submitted at"
                                        (or (submitted-at-label-of evidence)
                                            "submit-boundary"))
              (render-connect-field-row "Last updated"
                                        (or (updated-at-label-of evidence)
                                            "submit-boundary"))))))

(views:defview 👀failure (evidence dom-connect-request-evidence)
  (views:html-view :title "Failure / Boundary" :priority 2
    (views:html
      (:h4 "Browser-side classification")
      (:table :class "inspector-table"
              (render-connect-field-row "Failure kind"
                                        (or (dom-connect-evidence-failure-kind-label
                                             (browser-failure-kind-of evidence))
                                            "none"))
              (render-connect-field-row "Browser message"
                                        (or (browser-message-of evidence)
                                            "none"))
              (render-connect-field-row "Browser detail"
                                        (or (browser-detail-of evidence)
                                            "none")))
      (:h4 "Server-side boundary")
      (:table :class "inspector-table"
              (render-connect-field-row "Server status"
                                        (or (server-status-of evidence)
                                            "submitted"))
              (render-connect-field-row "Server message"
                                        (or (server-message-of evidence)
                                            "none"))
              (render-connect-field-row "Server detail"
                                        (or (server-detail-of evidence)
                                            "none"))))))

(views:defview 👀payload (evidence dom-connect-request-evidence)
  (views:html-view :title "Payload / Snapshot" :priority 3
    (views:html
      (render-connect-anchor-section "Source anchor"
                                     (source-anchor-of evidence))
      (render-connect-anchor-section "Target anchor"
                                     (target-anchor-of evidence))
      (:h4 "Captured session snapshot")
      (if (session-snapshot-of evidence)
          (maybe-dom-object-ref (session-snapshot-of evidence))
          (views:html
            (:p (:span :style "opacity: 0.55;"
                       "No submit-boundary session snapshot was captured.")))))))

(views:defview 👀summary (path dom-connect-submit-path)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of path)))
      (:p (views:esc (summary-of path)))
      (:table :class "inspector-table"
              (render-connect-field-row "Trigger" (trigger-of path))
              (render-connect-field-row "Purpose" (purpose-of path))
              (render-connect-field-row "Transport tag"
                                        (transport-tag-of path))
              (render-connect-field-row "Payload-bearing element"
                                        (payload-bearing-element-of path))
              (render-connect-rich-field-row "Authoritative payload fields"
                                             (authoritative-payload-fields-of
                                              path))
              (render-connect-field-row "Snapshot carrier"
                                        (snapshot-carrier-of path))
              (render-connect-field-row "Snapshot handling"
                                        (snapshot-handling-of path))
              (render-connect-field-row "Snapshot transport status"
                                        (snapshot-transport-status-of path))
              (render-connect-field-row "Hidden-field dependency"
                                        (hidden-field-dependency-of path))
              (render-connect-field-row "Server parse order"
                                        (server-parse-order-of path))
              (render-connect-field-row "Object opened"
                                        (object-opened-of path))
              (render-connect-field-row "Typical interpretation"
                                        (typical-interpretation-of path))
              (render-connect-rich-field-row "Implementation lineage"
                                             (lineage-of path))))))

(views:defview 👀comparison (comparison dom-connect-submit-path-comparison)
  (views:html-view :title "Comparison" :priority 1
    (let ((normal-path (normal-path-of comparison))
          (evidence-path (evidence-path-of comparison)))
      (views:html
        (:h3 (views:esc (title-of comparison)))
        (:p (views:esc (summary-of comparison)))
        (:table :class "inspector-table"
                (:tr (:th "Operational field")
                     (:th (views:esc (title-of normal-path)))
                     (:th (views:esc (title-of evidence-path))))
                (render-connect-comparison-row "Trigger"
                                               (trigger-of normal-path)
                                               (trigger-of evidence-path))
                (render-connect-comparison-row "Purpose"
                                               (purpose-of normal-path)
                                               (purpose-of evidence-path))
                (render-connect-comparison-row "Transport tag"
                                               (transport-tag-of normal-path)
                                               (transport-tag-of evidence-path))
                (render-connect-comparison-row
                 "Payload-bearing element"
                 (payload-bearing-element-of normal-path)
                 (payload-bearing-element-of evidence-path))
                (render-connect-comparison-row
                 "Authoritative payload fields"
                 (authoritative-payload-fields-of normal-path)
                 (authoritative-payload-fields-of evidence-path))
                (render-connect-comparison-row "Snapshot carrier"
                                               (snapshot-carrier-of normal-path)
                                               (snapshot-carrier-of evidence-path))
                (render-connect-comparison-row
                 "Snapshot handling"
                 (snapshot-handling-of normal-path)
                 (snapshot-handling-of evidence-path))
                (render-connect-comparison-row
                 "Snapshot transport status"
                 (snapshot-transport-status-of normal-path)
                 (snapshot-transport-status-of evidence-path))
                (render-connect-comparison-row
                 "Hidden-field dependency"
                 (hidden-field-dependency-of normal-path)
                 (hidden-field-dependency-of evidence-path))
                (render-connect-comparison-row "Server parse order"
                                               (server-parse-order-of normal-path)
                                               (server-parse-order-of evidence-path))
                (render-connect-comparison-row "Object opened"
                                               (object-opened-of normal-path)
                                               (object-opened-of evidence-path))
                (render-connect-comparison-row
                 "Typical success/failure interpretation"
                 (typical-interpretation-of normal-path)
                 (typical-interpretation-of evidence-path)))))))

(views:defview 👀server-seam (comparison dom-connect-submit-path-comparison)
  (views:html-view :title "Server seam" :priority 2
    (views:html
      (:h4 "Submit-boundary parse seam")
      (:table :class "inspector-table"
              (render-connect-field-row "Server seam"
                                        (server-seam-of comparison))
              (render-connect-field-row
               "Interpretation of missing snapshot message"
               (no-snapshot-message-meaning-of comparison))
              (render-connect-rich-field-row "Implementation lineage"
                                             (lineage-of comparison))))))

(views:defview 👀paths (comparison dom-connect-submit-path-comparison)
  (views:html-view :title "Paths" :priority 3
    (views:html
      (:h4 (views:esc (title-of (normal-path-of comparison))))
      (:p (maybe-dom-object-ref (normal-path-of comparison)))
      (:h4 (views:esc (title-of (evidence-path-of comparison))))
      (:p (maybe-dom-object-ref (evidence-path-of comparison))))))

(views:defview 👀summary (path dom-connect-snapshot-transport-path)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of path)))
      (:p (views:esc (summary-of path)))
      (:table :class "inspector-table"
              (render-connect-field-row "Producer" (producer-of path))
              (render-connect-field-row "Carrier" (carrier-of path))
              (render-connect-field-row "Payload-bearing element"
                                        (payload-bearing-element-of path))
              (render-connect-field-row "Authority / fallback status"
                                        (authority-status-of path))
              (render-connect-field-row "Hidden-field dependency"
                                        (hidden-field-dependency-of path))
              (render-connect-field-row "Server parse order"
                                        (server-parse-order-of path))
              (render-connect-field-row "Parse absence interpretation"
                                        (absence-interpretation-of path))
              (render-connect-field-row "Downstream object enabled"
                                        (downstream-object-of path))
              (render-connect-rich-field-row "Implementation lineage"
                                             (lineage-of path))))))

(views:defview 👀summary (transport dom-connect-snapshot-transport)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of transport)))
      (:p (views:esc (summary-of transport)))
      (:table :class "inspector-table"
              (render-connect-field-row "Operational definition"
                                        (operational-definition-of transport))
              (render-connect-field-row "Server parse order / authority"
                                        (server-seam-of transport))
              (render-connect-field-row "Absence interpretation"
                                        (absence-interpretation-of transport))
              (render-connect-rich-field-row "Implementation lineage"
                                             (lineage-of transport)))
      (:h4 "Paths")
      (:p (maybe-dom-object-ref (normal-path-of transport)))
      (:p (maybe-dom-object-ref (evidence-path-of transport)))))

(views:defview 👀paths (transport dom-connect-snapshot-transport)
  (views:html-view :title "Paths" :priority 2
    (let ((normal-path (normal-path-of transport))
          (evidence-path (evidence-path-of transport)))
      (views:html
        (:h3 (views:esc (title-of transport)))
        (:p (views:esc (summary-of transport)))
        (:table :class "inspector-table"
                (:tr (:th "Transport field")
                     (:th (views:esc (title-of normal-path)))
                     (:th (views:esc (title-of evidence-path))))
                (render-connect-comparison-row "Producer"
                                               (producer-of normal-path)
                                               (producer-of evidence-path))
                (render-connect-comparison-row "Carrier"
                                               (carrier-of normal-path)
                                               (carrier-of evidence-path))
                (render-connect-comparison-row
                 "Payload-bearing element"
                 (payload-bearing-element-of normal-path)
                 (payload-bearing-element-of evidence-path))
                (render-connect-comparison-row
                 "Authority / fallback status"
                 (authority-status-of normal-path)
                 (authority-status-of evidence-path))
                (render-connect-comparison-row
                 "Hidden-field dependency"
                 (hidden-field-dependency-of normal-path)
                 (hidden-field-dependency-of evidence-path))
                (render-connect-comparison-row
                 "Server parse order"
                 (server-parse-order-of normal-path)
                 (server-parse-order-of evidence-path))
                (render-connect-comparison-row
                 "Parse absence interpretation"
                 (absence-interpretation-of normal-path)
                 (absence-interpretation-of evidence-path))
                (render-connect-comparison-row
                 "Downstream object enabled"
                 (downstream-object-of normal-path)
                 (downstream-object-of evidence-path))))))))

(views:defview 👀overview (proposal relation-topic-proposal)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:h3 (views:esc (proposed-title-of proposal)))
      (:p (views:esc (proposed-summary-of proposal)))
      (:table :class "inspector-table"
              (render-connect-field-row "Relation" (relation-of proposal))
              (render-connect-field-row "Proposed id"
                                        (proposed-id-of proposal))
              (render-connect-field-row "Proposed title"
                                        (proposed-title-of proposal))
              (render-connect-field-row "Merge status"
                                        (merge-status-of proposal))
              (render-connect-field-row "Existing topic"
                                        (existing-topic-of proposal)))
      (:h4 "Proposed references")
      (if (proposed-references-of proposal)
          (views:html
            (:ul
             (loop for reference in (proposed-references-of proposal)
                   do (views:html
                        (:li (:tt (views:esc reference)))))))
          (views:html
            (:p (:span :style "opacity: 0.55;"
                       "No editorial references were inferred.")))))))

(views:defview 👀proposed-topic-factory (proposal relation-topic-proposal)
  (views:html-view :title "Proposed topic factory" :priority 2
    (views:html
      (:h3 "Copy-pasteable topic factory")
      (:p "This is a reviewed proposal surface only. It does not patch hyperdoc/topics.lisp.")
      (:pre :style "white-space: pre-wrap"
            (views:esc (relation-topic-proposal-factory-form proposal))))))

(views:defview 👀authoring-bundle (proposal relation-topic-proposal)
  (views:html-view :title "Authoring bundle" :priority 3
    (let ((plan (make-relation-topic-patch-plan proposal)))
      (views:html
      (:h3 "Reviewed authoring bundle")
      (:p "This bundle is advisory output only. It does not write topics.lisp, HyperDoc pages, or FedWiki files.")
      (:table :class "inspector-table"
              (render-connect-field-row "Current merge status"
                                        (merge-status-of proposal))
              (render-connect-field-row "Existing topic object"
                                        (existing-topic-of proposal)))
      (:p "Existing exact-title factories must be edited in place when the proposed title already exists.")
      (:h4 "Proposed topic factory")
      (:pre :style "white-space: pre-wrap"
            (views:esc (relation-topic-proposal-factory-form proposal)))
      (:h4 "Proposed HyperDoc page fragment")
      (:pre :style "white-space: pre-wrap"
            (views:esc (relation-topic-proposal-page-fragment proposal)))
      (:h4 "Advisory FedWiki twin delta")
      (:pre :style "white-space: pre-wrap"
            (views:esc (relation-topic-proposal-fedwiki-twin-delta proposal)))
      (:h4 "Repo patch plan")
      (:p (views:object-ref plan))))))

(views:defview 👀hyperdoc-page-fragment (proposal relation-topic-proposal)
  (views:html-view :title "HyperDoc page fragment" :priority 4
    (views:html
      (:h3 "Copy-pasteable HyperDoc page fragment")
      (:p "Replace the relation expression placeholder with a stable relation expression when the source relation is not already named.")
      (:pre :style "white-space: pre-wrap"
            (views:esc (relation-topic-proposal-page-fragment proposal))))))

(views:defview 👀fedwiki-twin-delta (proposal relation-topic-proposal)
  (views:html-view :title "FedWiki twin delta" :priority 5
    (views:html
      (:h3 "Advisory FedWiki twin delta")
      (:p "This is plain-text guidance only. It does not touch the FedWiki repo.")
      (:pre :style "white-space: pre-wrap"
            (views:esc (relation-topic-proposal-fedwiki-twin-delta proposal))))))

(views:defview 👀patch-plan (proposal relation-topic-proposal)
  (views:html-view :title "Patch plan" :priority 6
    (views:html
      (:h3 "Collision-aware patch plan")
      (:p "This plan identifies authored targets and payloads but does not apply any patch.")
      (:p (views:object-ref (make-relation-topic-patch-plan proposal))))))

(views:defview 👀merge-guidance (proposal relation-topic-proposal)
  (views:html-view :title "Merge guidance" :priority 7
    (views:html
      (:h3 "Merge guidance")
      (:ul
       (:li "Search hyperdoc/topics.lisp by the exact :title string.")
       (:li "Edit the existing factory in place when the title already exists.")
       (:li "Add a new topic factory only when the exact title does not exist."))
      (:table :class "inspector-table"
              (render-connect-field-row "Exact title candidate"
                                        (proposed-title-of proposal))
              (render-connect-field-row "Current merge status"
                                        (merge-status-of proposal))
              (render-connect-field-row "Existing topic object"
                                        (existing-topic-of proposal))))))

(views:defview 👀patch-plan (plan relation-topic-patch-plan)
  (views:html-view :title "Patch plan" :priority 1
    (views:html
      (:h3 (views:esc (title-of plan)))
      (:p (views:esc (summary-of plan)))
      (:table :class "inspector-table"
              (render-connect-field-row "Proposal" (proposal-of plan))
              (render-connect-field-row "topics.lisp target"
                                        (topics-target-path-of plan))
              (render-connect-field-row "topics.lisp action"
                                        (topics-action-of plan))
              (render-connect-field-row "Existing topic"
                                        (existing-topic-of plan))
              (render-connect-field-row "Page target"
                                        (page-target-path-of plan))
              (render-connect-field-row "Page action"
                                        (page-action-of plan))))))

(views:defview 👀topics-lisp-payload (plan relation-topic-patch-plan)
  (views:html-view :title "topics.lisp payload" :priority 2
    (views:html
      (:h3 "Copy-pasteable topics.lisp payload")
      (:p "Use this as the reviewed factory payload for the authored topics file. It is not applied automatically.")
      (:pre :style "white-space: pre-wrap"
            (views:esc (topics-payload-of plan))))))

(views:defview 👀page-payload (plan relation-topic-patch-plan)
  (views:html-view :title "Page payload" :priority 3
    (views:html
      (:h3 "Copy-pasteable page payload")
      (:p "Use this as the reviewed HyperDoc page payload for the candidate page file. It is not applied automatically.")
      (:pre :style "white-space: pre-wrap"
            (views:esc (page-payload-of plan))))))

(views:defview 👀patch-instructions (plan relation-topic-patch-plan)
  (views:html-view :title "Patch instructions" :priority 4
    (views:html
      (:h3 "Repo-native patch instructions")
      (:pre :style "white-space: pre-wrap"
            (views:esc (relation-topic-patch-instructions plan))))))

(views:defview 👀application-result
    (application approved-relation-topic-patch-application)
  (views:html-view :title "Application result" :priority 1
    (views:html
      (:h3 (views:esc (title-of application)))
      (:p (views:esc (summary-of application)))
      (:table :class "inspector-table"
              (render-connect-field-row "Patch plan"
                                        (patch-plan-of application))
              (render-connect-rich-field-row "Patch plan identity"
                                             (patch-plan-identity-of application))
              (render-connect-rich-field-row "Patch plan evidence"
                                             (patch-plan-evidence-of application))
              (render-connect-field-row "Status"
                                        (status-of application))
              (render-connect-field-row "Repo root evidence"
                                        (repo-root-evidence-of application))
              (render-connect-field-row "Timestamp"
                                        (timestamp-of application))
              (render-connect-rich-field-row "Applied paths"
                                             (applied-paths-of application))
              (render-connect-rich-field-row "Actions performed"
                                             (actions-performed-of application))))))

(views:defview 👀applied-payloads
    (application approved-relation-topic-patch-application)
  (views:html-view :title "Applied payloads" :priority 2
    (views:html
      (:h3 "Applied payloads")
      (if (applied-payloads-of application)
          (loop for (kind . payload) in (applied-payloads-of application)
                do (views:html
                     (:h4 (views:esc (string-capitalize
                                      (string-downcase
                                       (symbol-name kind)))))
                     (:pre :style "white-space: pre-wrap"
                           (views:esc payload))))
          (views:html
            (:p (:span :style "opacity: 0.55;"
                       "No payloads were written.")))))))

(views:defview 👀safety-boundary
    (application approved-relation-topic-patch-application)
  (views:html-view :title "Safety boundary / approval evidence" :priority 3
    (views:html
      (:h3 "Safety boundary / approval evidence")
      (:p "This result exists only because apply-relation-topic-patch-plan was called explicitly with a valid approval token.")
      (:table :class "inspector-table"
              (render-connect-field-row "Approval token class"
                                        (approval-token-class-of application))
              (render-connect-rich-field-row "Approval evidence"
                                             (approval-evidence-of application))
              (render-connect-rich-field-row "Patch plan identity"
                                             (patch-plan-identity-of application))
              (render-connect-field-row "Repo root evidence"
                                        (repo-root-evidence-of application))
              (render-connect-field-row "Patch plan"
                                        (patch-plan-of application))
              (render-connect-field-row "Status"
                                        (status-of application))))))
