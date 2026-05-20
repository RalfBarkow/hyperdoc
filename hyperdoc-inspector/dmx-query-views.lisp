;;;; Inspector views for DMX query runs, SQLite journal, and sync plans

(in-package :hyperdoc/inspector)

(defun dmx-query-view-string (value)
  (cond
    ((null value) "n/a")
    ((keywordp value) (string-downcase (symbol-name value)))
    (t (format nil "~A" value))))

(defun dmx-query-row-count-label (rows)
  (format nil "~D" (length rows)))

(defmethod views:text-representation ((target hyperdoc::dmx-store-target))
  (format nil "~A (~A)"
          (hyperdoc::title-of target)
          (dmx-query-view-string (hyperdoc::kind-of target))))

(defmethod views:text-representation ((run hyperdoc::dmx-query-run))
  (format nil "~A: ~A, ~D rows"
          (hyperdoc::title-of (hyperdoc::dmx-query-run-query-of run))
          (dmx-query-view-string (hyperdoc::dmx-query-run-status-of run))
          (length (hyperdoc::dmx-query-run-rows-of run))))

(defmethod views:text-representation ((plan hyperdoc::dmx-sync-plan))
  (format nil "~A -> ~A: ~D items"
          (hyperdoc::id-of (hyperdoc::dmx-sync-plan-source-target-of plan))
          (hyperdoc::id-of (hyperdoc::dmx-sync-plan-target-target-of plan))
          (length (hyperdoc::dmx-sync-plan-items-of plan))))

(views:defview 👀overview (run hyperdoc::dmx-query-run)
  (views:html-view :title "Overview" :priority 1
    (views:html
     (:table :class "inspector-table"
             (:tr (:td "Query")
                  (:td (views:esc
                        (hyperdoc::title-of
                         (hyperdoc::dmx-query-run-query-of run)))))
             (:tr (:td "Target")
                  (:td (views:esc
                        (hyperdoc::title-of
                         (hyperdoc::dmx-query-run-source-target-of run)))))
             (:tr (:td "Status")
                  (:td (:code
                        (views:esc
                         (dmx-query-view-string
                          (hyperdoc::dmx-query-run-status-of run))))))
             (:tr (:td "Executed")
                  (:td (:code
                        (views:esc
                         (hyperdoc::dmx-query-run-executed-at-of run)))))
             (:tr (:td "Rows")
                  (:td (views:esc
                        (dmx-query-row-count-label
                         (hyperdoc::dmx-query-run-rows-of run)))))
             (:tr (:td "Safety")
                  (:td (views:esc
                        "Read-only query run; no DMX mutation path.")))))))

(views:defview 👀rows (run hyperdoc::dmx-query-run)
  (views:html-view :title "Rows" :priority 2
    (views:html
     (if (hyperdoc::dmx-query-run-rows-of run)
         (views:html
          (:table :class "inspector-table"
                  (:tr (:th "Topic ID")
                       (:th "URI")
                       (:th "Type")
                       (:th "Value")
                       (:th "Workspace")
                       (:th "Topicmaps")
                       (:th "Ownership"))
                  (dolist (row (hyperdoc::dmx-query-run-rows-of run))
                    (views:html
                     (:tr
                      (:td (:code
                            (views:esc
                             (dmx-query-view-string
                              (hyperdoc::dmx-topic-row-topic-id-of row)))))
                      (:td (:code
                            (views:esc
                             (dmx-query-view-string
                              (hyperdoc::dmx-topic-row-uri-of row)))))
                      (:td (:code
                            (views:esc
                             (dmx-query-view-string
                              (hyperdoc::dmx-topic-row-type-uri-of row)))))
                      (:td (views:esc
                            (dmx-query-view-string
                             (hyperdoc::dmx-topic-row-value-of row))))
                      (:td (:code
                            (views:esc
                             (dmx-query-view-string
                              (hyperdoc::dmx-topic-row-workspace-status-of row)))))
                      (:td (:code
                            (views:esc
                             (format nil "~{~A~^, ~}"
                                     (hyperdoc::dmx-topic-row-topicmap-ids-of
                                      row)))))
                      (:td (:code
                            (views:esc
                             (dmx-query-view-string
                              (hyperdoc::dmx-topic-row-ownership-class-of
                               row)))))))))
         (views:html (:p "No rows.")))))))

(views:defview 👀evidence (run hyperdoc::dmx-query-run)
  (views:html-view :title "Evidence" :priority 3
    (views:html
     (:h4 "Raw request")
     (:pre (views:esc
            (dmx-query-view-string
             (hyperdoc::dmx-query-run-raw-request-of run))))
     (:h4 "Raw response")
     (:pre (views:esc
            (dmx-query-view-string
             (hyperdoc::dmx-query-run-raw-response-of run))))
     (:h4 "Command records")
     (:pre (views:esc
            (prin1-to-string
             (hyperdoc::dmx-query-run-command-records-of run)))))))

(views:defview 👀failure (run hyperdoc::dmx-query-run)
  (unless (eq (hyperdoc::dmx-query-run-status-of run) :ok)
    (views:html-view :title "Failure/unavailable" :priority 4
      (views:html
       (:table :class "inspector-table"
               (:tr (:td "Status")
                    (:td (:code
                          (views:esc
                           (dmx-query-view-string
                            (hyperdoc::dmx-query-run-status-of run))))))
               (:tr (:td "Detail")
                    (:td (views:esc
                          (dmx-query-view-string
                           (hyperdoc::dmx-query-run-error-detail-of run))))))))))

(views:defview 👀overview (plan hyperdoc::dmx-sync-plan)
  (views:html-view :title "Overview" :priority 1
    (views:html
     (:table :class "inspector-table"
             (:tr (:td "Source")
                  (:td (views:esc
                        (hyperdoc::title-of
                         (hyperdoc::dmx-sync-plan-source-target-of plan)))))
             (:tr (:td "Target")
                  (:td (views:esc
                        (hyperdoc::title-of
                         (hyperdoc::dmx-sync-plan-target-target-of plan)))))
             (:tr (:td "Status")
                  (:td (:code
                        (views:esc
                         (dmx-query-view-string
                          (hyperdoc::dmx-sync-plan-status-of plan))))))
             (:tr (:td "Items")
                  (:td (views:esc
                        (format nil "~D"
                                (length
                                 (hyperdoc::dmx-sync-plan-items-of plan))))))
             (:tr (:td "Execution")
                  (:td (views:esc
                        "Dry-run only; no topic upsert, workspace assignment, or delete is performed.")))))))

(views:defview 👀items (plan hyperdoc::dmx-sync-plan)
  (views:html-view :title "Items by action" :priority 2
    (views:html
     (:table :class "inspector-table"
             (:tr (:th "Action")
                  (:th "URI")
                  (:th "Safe?")
                  (:th "Reason"))
             (dolist (item (hyperdoc::dmx-sync-plan-items-of plan))
               (views:html
                (:tr
                 (:td (:code
                       (views:esc
                        (dmx-query-view-string
                         (hyperdoc::dmx-sync-plan-item-action-of item)))))
                 (:td (:code
                       (views:esc
                        (dmx-query-view-string
                         (hyperdoc::dmx-sync-plan-item-uri-of item)))))
                 (:td (views:esc
                       (if (hyperdoc::dmx-sync-plan-item-safe-p item)
                           "yes"
                           "no")))
                 (:td (views:esc
                       (dmx-query-view-string
                       (hyperdoc::dmx-sync-plan-item-reason-of item)))))))))))

(views:defview 👀unsafe (plan hyperdoc::dmx-sync-plan)
  (let ((unsafe (remove-if #'hyperdoc::dmx-sync-plan-item-safe-p
                           (hyperdoc::dmx-sync-plan-items-of plan))))
    (when unsafe
      (views:html-view :title "Unsafe/unsupported" :priority 3
        (views:html
         (:table :class "inspector-table"
                 (:tr (:th "Action") (:th "URI") (:th "Reason"))
                 (dolist (item unsafe)
                   (views:html
                    (:tr
                     (:td (:code
                           (views:esc
                            (dmx-query-view-string
                             (hyperdoc::dmx-sync-plan-item-action-of item)))))
                     (:td (:code
                           (views:esc
                            (dmx-query-view-string
                             (hyperdoc::dmx-sync-plan-item-uri-of item)))))
                     (:td (views:esc
                           (dmx-query-view-string
                            (hyperdoc::dmx-sync-plan-item-reason-of
                             item)))))))))))))

(views:defview 👀overview (store hyperdoc::dmx-sqlite-query-store)
  (views:html-view :title "Overview" :priority 1
    (views:html
     (:table :class "inspector-table"
             (:tr (:td "DB path")
                  (:td (:code
                        (views:esc
                         (namestring
                          (hyperdoc::dmx-sqlite-query-store-db-path-of
                           store))))))
             (:tr (:td "sqlite3")
                  (:td (:code
                        (views:esc
                         (hyperdoc::dmx-sqlite-query-store-sqlite-program-of
                          store)))))
             (:tr (:td "Purpose")
                  (:td (views:esc
                        "Query definitions, runs, rows, dry-run sync plans, and evidence snapshots.")))))))

(views:defview 👀schema (store hyperdoc::dmx-sqlite-query-store)
  (views:html-view :title "Schema status" :priority 2
    (views:html
     (:pre
      (views:esc
       (handler-case
           (prin1-to-string (hyperdoc::dmx-sqlite-schema-status store))
         (error (condition)
           (format nil "Schema status unavailable: ~A" condition))))))))

(views:defview 👀recent-runs (store hyperdoc::dmx-sqlite-query-store)
  (views:html-view :title "Recent runs" :priority 3
    (views:html
     (:pre
      (views:esc
       (handler-case
           (prin1-to-string
            (hyperdoc::dmx-load-query-runs store :limit 10))
         (error (condition)
           (format nil "Recent runs unavailable: ~A" condition))))))))
