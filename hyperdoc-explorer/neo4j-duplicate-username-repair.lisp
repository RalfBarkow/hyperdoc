;;;; Explorer views for the narrow duplicate-username Neo4j repair workflow
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defmethod views:text-representation ((target neo4j-store-target))
  (title-of target))

(defmethod views:text-representation ((target dmx-neo4j-instance-target))
  (title-of target))

(defmethod views:text-representation ((operation neo4j-read-query-operation))
  (title-of operation))

(defmethod views:text-representation ((report neo4j-username-ambiguity-report))
  (format nil "~A (~A)"
          (title-of report)
          (neo4j-username-ambiguity-classification-label
           (neo4j-username-ambiguity-report-classification-of report))))

(defmethod views:text-representation ((plan neo4j-duplicate-username-repair-plan))
  (format nil "~A (~A / ~A / ~A)"
          (title-of plan)
          (neo4j-repair-plan-status-label
           (neo4j-duplicate-username-repair-plan-status-of plan))
          (neo4j-repair-approval-status-label
           (neo4j-duplicate-username-repair-plan-approval-status-of plan))
          (neo4j-offline-confirmation-status-label
           (neo4j-duplicate-username-repair-plan-offline-confirmation-status-of plan))))

(defmethod views:text-representation ((operation neo4j-repair-operation))
  (format nil "~A (~A)"
          (title-of operation)
          (neo4j-repair-operation-status-label
           (neo4j-repair-operation-status-of operation))))

(defun neo4j-view-namestring-or-na (pathname)
  (if pathname
      (namestring pathname)
      "n/a"))

(defun neo4j-view-topic-role-label (report topic)
  (cond
    ((null topic)
     "n/a")
    ((eql (neo4j-topic-node-id topic)
          (neo4j-topic-node-id
           (neo4j-username-ambiguity-report-canonical-topic-of report)))
     "canonical")
    ((eql (neo4j-topic-node-id topic)
          (neo4j-topic-node-id
           (neo4j-username-ambiguity-report-stale-topic-of report)))
     "stale")
    (t
     "match")))

(defun neo4j-view-command-record-kind-label (record)
  (string-downcase (symbol-name (getf record :kind))))

(defun neo4j-view-maybe-code (value)
  (if value
      (views:html (:code (views:esc (format nil "~A" value))))
      (views:html (:span :style "opacity: 0.55;" "n/a"))))

(defun neo4j-view-command-record-table (records)
  (if records
      (views:html
        (:table :class "inspector-table"
                (:thead
                 (:tr (:th (views:esc "Kind"))
                      (:th (views:esc "Exit"))
                      (:th (views:esc "Command"))
                      (:th (views:esc "Output"))))
                (:tbody
                 (dolist (record records)
                   (views:html
                     (:tr
                      (:td (:tt (views:esc
                                 (neo4j-view-command-record-kind-label record))))
                      (:td (views:esc
                            (if (null (getf record :exit-code))
                                "error"
                                (princ-to-string (getf record :exit-code)))))
                      (:td (:code (views:esc (getf record :command-string))))
                      (:td (:pre :style "white-space: pre-wrap;"
                                 (views:esc (or (getf record :output) ""))))))))))
      (views:html
        (:p (views:esc "No command records are present.")))))

(views:defview 👀summary (target neo4j-store-target)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of target)))
      (:p (views:esc (summary-of target)))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "App root"))
                   (:td (:code (views:esc
                                (namestring
                                 (neo4j-store-target-app-root-of target))))))
              (:tr (:td (views:esc "Store path"))
                   (:td (:code (views:esc
                                (namestring
                                 (neo4j-store-target-store-path-of target))))))
              (:tr (:td (views:esc "Java home"))
                   (:td (:code (views:esc
                                (neo4j-view-namestring-or-na
                                 (neo4j-store-target-java-home-of target))))))
              (:tr (:td (views:esc "Tool source"))
                   (:td (:code (views:esc
                                (namestring
                                 (neo4j-store-target-tool-source-path-of target))))))
              (:tr (:td (views:esc "Tool build root"))
                   (:td (:code (views:esc
                                (namestring
                                 (neo4j-store-target-tool-build-root-of target))))))))))

(views:defview 👀adapter (target neo4j-store-target)
  (views:html-view :title "Adapter boundary" :priority 2
    (views:html
      (:p (views:esc "This target keeps the Java helper as a narrow datastore adapter only. Lisp owns classification, refusal, approval, backup planning, and verification."))
      (:ul
       (:li (views:esc "Prepare helper commands"))
       (:li (views:esc "Duplicate-username report command"))
       (:li (views:esc "Rename stale duplicate command")))
      (:p (views:esc "No arbitrary query or generic command surface is exposed from this target.")))))

(views:defview 👀summary (target dmx-neo4j-instance-target)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of target)))
      (:p (views:esc (summary-of target)))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Store target"))
                   (:td (views:object-ref
                         (neo4j-instance-target-store-target-of target))))
              (:tr (:td (views:esc "HTTP base URL"))
                   (:td (:code (views:esc
                                (neo4j-instance-target-http-base-url-of target)))))
              (:tr (:td (views:esc "HTTP port"))
                   (:td (:tt (views:esc
                              (princ-to-string
                               (neo4j-instance-target-http-port-of target))))))))))

(views:defview 👀summary (operation neo4j-read-query-operation)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of operation)))
      (:p (views:esc (summary-of operation)))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Instance target"))
                   (:td (views:object-ref
                         (neo4j-read-query-operation-instance-target-of operation))))
              (:tr (:td (views:esc "Query kind"))
                   (:td (:tt (views:esc
                              (neo4j-command-kind-label
                               (neo4j-read-query-operation-kind-of operation))))))
              (:tr (:td (views:esc "Username"))
                   (:td (:code (views:esc
                                (neo4j-read-query-operation-username-of operation)))))))))

(views:defview 👀materialization (operation neo4j-read-query-operation)
  (views:html-view :title "Materialization" :priority 2
    (views:html
      (:p (views:esc "This read-only operation materializes exact commands before execution. It does not expose arbitrary query entry."))
      (render-shell-block (materialization-shell-block operation)))))

(views:defview 👀boundary (operation neo4j-read-query-operation)
  (views:html-view :title "Boundary" :priority 3
    (views:html
      (:p (views:esc "The read operation is fixed to one supported workflow shape."))
      (:ul
       (:li (views:esc "No free-form Cypher"))
       (:li (views:esc "No generic Neo4j shell"))
       (:li (views:esc "Helper details remain behind the adapter protocol"))))))

(views:defview 👀overview (report neo4j-username-ambiguity-report)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:h3 (views:esc (title-of report)))
      (:p (views:esc (summary-of report)))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Read operation"))
                   (:td (views:object-ref
                         (neo4j-username-ambiguity-report-read-operation-of report))))
              (:tr (:td (views:esc "Status"))
                   (:td (:tt (views:esc
                              (string-downcase
                               (symbol-name
                                (neo4j-username-ambiguity-report-status-of report)))))))
              (:tr (:td (views:esc "Classification"))
                   (:td (:tt (views:esc
                              (neo4j-username-ambiguity-classification-label
                               (neo4j-username-ambiguity-report-classification-of report))))))
              (:tr (:td (views:esc "Matching count"))
                   (:td (:tt (views:esc
                              (princ-to-string
                               (neo4j-username-ambiguity-report-matching-count-of report))))))
              (:tr (:td (views:esc "Canonical topic"))
                   (:td (neo4j-view-maybe-code
                         (neo4j-topic-node-id
                          (neo4j-username-ambiguity-report-canonical-topic-of report)))))
              (:tr (:td (views:esc "Stale topic"))
                   (:td (neo4j-view-maybe-code
                         (neo4j-topic-node-id
                          (neo4j-username-ambiguity-report-stale-topic-of report)))))
              (:tr (:td (views:esc "Classification note"))
                   (:td (views:esc
                         (or (neo4j-username-ambiguity-report-classification-note-of report)
                             "n/a"))))))))

(views:defview 👀matching-topics (report neo4j-username-ambiguity-report)
  (views:html-view :title "Matching topics" :priority 2
    (let ((topics (neo4j-username-ambiguity-report-matching-topics-of report)))
      (if topics
          (views:html
            (:table :class "inspector-table"
                    (:thead
                     (:tr (:th (views:esc "Role"))
                          (:th (views:esc "Node"))
                          (:th (views:esc "Workspace"))
                          (:th (views:esc "User accounts"))
                          (:th (views:esc "Password topic"))))
                    (:tbody
                     (dolist (topic topics)
                       (views:html
                         (:tr
                          (:td (:tt (views:esc
                                     (neo4j-view-topic-role-label report topic))))
                          (:td (neo4j-view-maybe-code
                                (neo4j-topic-node-id topic)))
                          (:td (views:esc
                                (or (neo4j-topic-workspace-title topic) "n/a")))
                          (:td (:tt (views:esc
                                     (princ-to-string
                                      (length
                                       (neo4j-user-accounts-for-topic topic))))))
                          (:td (neo4j-view-maybe-code
                                (neo4j-payload-field
                                  (neo4j-topic-password-topic topic)
                                 "passwordTopicId"))))))))
          (views:html
            (:p (views:esc "No matching topics are present in the report."))))))))

(views:defview 👀command-records (report neo4j-username-ambiguity-report)
  (views:html-view :title "Command records" :priority 3
    (neo4j-view-command-record-table
     (neo4j-username-ambiguity-report-command-records-of report))))

(views:defview 👀overview (plan neo4j-duplicate-username-repair-plan)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:h3 (views:esc (title-of plan)))
      (:p (views:esc (summary-of plan)))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Report"))
                   (:td (views:object-ref
                         (neo4j-duplicate-username-repair-plan-report-of plan))))
              (:tr (:td (views:esc "Plan status"))
                   (:td (:tt (views:esc
                              (neo4j-repair-plan-status-label
                               (neo4j-duplicate-username-repair-plan-status-of plan))))))
              (:tr (:td (views:esc "Approval"))
                   (:td (:tt (views:esc
                              (neo4j-repair-approval-status-label
                               (neo4j-duplicate-username-repair-plan-approval-status-of plan))))))
              (:tr (:td (views:esc "Offline confirmation"))
                   (:td (:tt (views:esc
                              (neo4j-offline-confirmation-status-label
                               (neo4j-duplicate-username-repair-plan-offline-confirmation-status-of plan))))))
              (:tr (:td (views:esc "Canonical topic"))
                   (:td (neo4j-view-maybe-code
                         (neo4j-duplicate-username-repair-plan-expected-canonical-topic-id-of plan))))
              (:tr (:td (views:esc "Stale topic"))
                   (:td (neo4j-view-maybe-code
                         (neo4j-duplicate-username-repair-plan-expected-stale-topic-id-of plan))))
              (:tr (:td (views:esc "Rename target"))
                   (:td (:code (views:esc
                                (neo4j-duplicate-username-repair-plan-replacement-value-of plan)))))
              (:tr (:td (views:esc "Backup path"))
                   (:td (:code (views:esc
                                (neo4j-view-namestring-or-na
                                 (neo4j-duplicate-username-repair-plan-backup-path-of plan))))))
              (:tr (:td (views:esc "Refusal reason"))
                   (:td (views:esc
                         (or (neo4j-duplicate-username-repair-plan-refusal-reason-of plan)
                             "n/a"))))))))

(views:defview 👀materialization (plan neo4j-duplicate-username-repair-plan)
  (views:html-view :title "Materialization" :priority 2
    (views:html
      (:p (views:esc "This plan renders the exact inspection, backup, rename, and verification commands, but it does not execute them."))
      (render-shell-block (materialization-shell-block plan)))))

(views:defview 👀guardrails (plan neo4j-duplicate-username-repair-plan)
  (views:html-view :title "Guardrails" :priority 3
    (views:html
      (:p (views:esc "The single live mutation path remains narrow and Lisp-owned."))
      (:ul
       (:li (views:esc "Unsupported ambiguity shapes stay as inspectable refusals."))
       (:li (views:esc "Approval and offline confirmation are explicit plan-side checks."))
       (:li (views:esc "Execution does not synthesize ids, rename targets, or backup paths."))
       (:li (views:esc "The Java helper remains a replaceable datastore adapter, not the feature center."))))))

(views:defview 👀overview (operation neo4j-repair-operation)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:h3 (views:esc (title-of operation)))
      (:p (views:esc (summary-of operation)))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Plan"))
                   (:td (views:object-ref
                         (neo4j-repair-operation-plan-of operation))))
              (:tr (:td (views:esc "Status"))
                   (:td (:tt (views:esc
                              (neo4j-repair-operation-status-label
                               (neo4j-repair-operation-status-of operation))))))
              (:tr (:td (views:esc "Refusal reason"))
                   (:td (views:esc
                         (or (neo4j-repair-operation-refusal-reason-of operation)
                             "n/a"))))
              (:tr (:td (views:esc "Preflight report"))
                   (:td (views:object-ref
                         (or (neo4j-repair-operation-preflight-report-of operation)
                             "not reached"))))
              (:tr (:td (views:esc "Post-repair report"))
                   (:td (views:object-ref
                         (or (neo4j-repair-operation-post-repair-report-of operation)
                             "not reached"))))
              (:tr (:td (views:esc "Verification"))
                   (:td (views:object-ref
                         (or (neo4j-repair-operation-verification-record-of operation)
                             "not run"))))))))

(views:defview 👀execution (operation neo4j-repair-operation)
  (views:html-view :title "Execution" :priority 2
    (neo4j-view-command-record-table
     (neo4j-repair-operation-execution-records-of operation))))

(views:defview 👀verification (operation neo4j-repair-operation)
  (views:html-view :title "Verification" :priority 3
    (views:html
      (:p (views:esc "Store verification and live verification stay separate. The repair verb records store-side evidence; the later live verification step remains read-only."))
      (when (neo4j-repair-operation-post-repair-report-of operation)
        (views:html
          (:p
           (views:object-ref
            (neo4j-repair-operation-post-repair-report-of operation)))))
      (if (neo4j-repair-operation-verification-record-of operation)
          (neo4j-view-command-record-table
           (list (neo4j-repair-operation-verification-record-of operation)))
          (views:html
            (:p (views:esc "No live verification record is attached yet.")))))))
