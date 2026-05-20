;;;; Smoke tests for the generic DMX topic query layer

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-DMX-QUERY-LAYER-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun dmx-query-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun dmx-query-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun dmx-query-assert-typep (expected-type object message)
  (unless (typep object expected-type)
    (error "~A -- expected type: ~S actual type: ~S"
           message expected-type (type-of object))))

(defun dmx-query-hash-row (&rest entries)
  (let ((row (make-hash-table :test #'equal)))
    (loop for (key value) on entries by #'cddr
          do (setf (gethash key row) value))
    row))

(defun dmx-query-workspace-assignment (&key workspace-id assoc-id)
  (dmx-query-hash-row
   "workspaceId" workspace-id
   "assignmentAssocId" assoc-id))

(defun dmx-query-fixture-rows ()
  (list
   (dmx-query-hash-row
    "topicId" 101
    "uri" "dmx://topic/unassigned"
    "typeUri" "dmx.notes.note"
    "value" "No workspace assignment"
    "topicmapIds" #(919822)
    "ownershipClass" "foreign-or-unsupported")
   (dmx-query-hash-row
    "topicId" 102
    "uri" "dmx://topic/property-assigned"
    "typeUri" "dmx.notes.note"
    "value" "Assigned by property"
    "workspaceId" 919815
    "workspacePropertyExists" t
    "topicmapIds" #(919822))
   (dmx-query-hash-row
    "topicId" 103
    "uri" "dmx://topic/association-assigned"
    "typeUri" "dmx.notes.note"
    "value" "Assigned by association"
    "workspaceAssignment"
    (dmx-query-workspace-assignment :workspace-id 919815
                                    :assoc-id 23001)
    "topicmapIds" #(919822))
   (dmx-query-hash-row
    "topicId" 104
    "uri" "hyperdoc:mcp/workspace-annotation/topicmap-visible-only"
    "typeUri" "dmx.notes.note"
    "value" "Topicmap visible but workspace-unassigned"
    "topicmapIds" #(919822)
    "topicmapMemberships"
    (vector (dmx-query-hash-row "topicmapId" 919822
                                "contextAssocId" 501)))))

(defun dmx-query-row-by-uri (rows uri)
  (find uri rows :key #'hyperdoc:dmx-topic-row-uri-of :test #'equal))

(defun run-dmx-query-layer-workspace-status-smoke-test ()
  (let* ((target (hyperdoc:make-dmx-memory-query-target
                  :raw-rows (dmx-query-fixture-rows)))
         (rows (mapcar (lambda (raw-row)
                         (hyperdoc:dmx-store-topic-row target raw-row))
                       (dmx-query-fixture-rows))))
    (dmx-query-assert-equal
     :unassigned
     (hyperdoc:dmx-topic-row-workspace-status-of
      (dmx-query-row-by-uri rows "dmx://topic/unassigned"))
     "No workspace property and no assignment association must be unassigned")
    (dmx-query-assert-equal
     :assigned-by-property
     (hyperdoc:dmx-topic-row-workspace-status-of
      (dmx-query-row-by-uri rows "dmx://topic/property-assigned"))
     "Workspace property must classify as assigned by property")
    (dmx-query-assert-equal
     :assigned-by-association
     (hyperdoc:dmx-topic-row-workspace-status-of
      (dmx-query-row-by-uri rows "dmx://topic/association-assigned"))
     "Workspace assignment association must classify as assigned by association")
    (let ((visible
            (dmx-query-row-by-uri
             rows
             "hyperdoc:mcp/workspace-annotation/topicmap-visible-only")))
      (dmx-query-assert-equal
       :unassigned
       (hyperdoc:dmx-topic-row-workspace-status-of visible)
       "Topicmap placement must not imply workspace assignment")
      (dmx-query-assert-true
       (member 919822
               (hyperdoc:dmx-topic-row-topicmap-ids-of visible)
               :test #'equal)
       "Topicmap placement remains visible evidence"))))

(defun run-dmx-query-layer-list-filter-smoke-test ()
  (let* ((target (hyperdoc:make-dmx-memory-query-target
                  :raw-rows (dmx-query-fixture-rows)))
         (run (hyperdoc:dmx-list-unassigned-topics
               target
               :topicmap-id 919822
               :ownership-class :hyperdoc-workspace-annotation
               :limit 10)))
    (dmx-query-assert-typep 'hyperdoc:dmx-query-run
                            run
                            "List operation must return an inspectable query run")
    (dmx-query-assert-equal :ok
                            (hyperdoc:dmx-query-run-status-of run)
                            "Memory query must succeed")
    (dmx-query-assert-equal
     1
     (length (hyperdoc:dmx-query-run-rows-of run))
     "Ownership and topicmap filters must keep only the HyperDoc visible-unassigned row")
    (dmx-query-assert-equal
     "hyperdoc:mcp/workspace-annotation/topicmap-visible-only"
     (hyperdoc:dmx-topic-row-uri-of
      (first (hyperdoc:dmx-query-run-rows-of run)))
     "Filtered row identity")))

(defun run-dmx-query-layer-plist-row-smoke-test ()
  (let* ((target (hyperdoc:make-dmx-memory-query-target
                  :raw-rows
                  (list (list :topic-id 301
                              :uri "hyperdoc:mcp/workspace-annotation/plist"
                              :type-uri "dmx.notes.note"
                              :value "Keyword plist row"))))
         (run (hyperdoc:dmx-list-unassigned-topics target :limit 1))
         (row (first (hyperdoc:dmx-query-run-rows-of run))))
    (dmx-query-assert-equal
     :ok
     (hyperdoc:dmx-query-run-status-of run)
     "Keyword plist rows must be accepted by the generic query layer")
    (dmx-query-assert-equal
     :hyperdoc-workspace-annotation
     (hyperdoc:dmx-topic-row-ownership-class-of row)
     "HyperDoc annotation ownership classification must not require DMX import system state")))

(defun run-dmx-query-layer-uri-comparison-smoke-test ()
  (let* ((source (hyperdoc:make-dmx-memory-query-target
                  :id "source"
                  :raw-rows
                  (list (dmx-query-hash-row
                         "topicId" 1
                         "uri" "dmx://topic/shared"
                         "typeUri" "dmx.notes.note"
                         "value" "Shared"
                         "topicmapIds" #(919822)))))
         (target (hyperdoc:make-dmx-memory-query-target
                  :id "target"
                  :raw-rows
                  (list (dmx-query-hash-row
                         "topicId" 99
                         "uri" "dmx://topic/shared"
                         "typeUri" "dmx.notes.note"
                         "value" "Shared"
                         "topicmapIds" #(123456)))))
         (plan (hyperdoc:dmx-plan-topic-sync
                source
                target
                :query (hyperdoc:make-dmx-unassigned-topics-query)
                :identity-key :uri))
         (item (first (hyperdoc:dmx-sync-plan-items-of plan))))
    (dmx-query-assert-typep 'hyperdoc:dmx-sync-plan
                            plan
                            "Comparison must produce an inspectable sync plan")
    (dmx-query-assert-equal
     :same
     (hyperdoc:dmx-sync-plan-item-action-of item)
     "Comparison must use URI identity, not per-store numeric topic ids")
    (dmx-query-assert-equal
     "1"
     (hyperdoc:dmx-topic-row-topic-id-of
      (hyperdoc:dmx-sync-plan-item-source-row-of item))
     "Source topic id remains an observation")
    (dmx-query-assert-equal
     "99"
     (hyperdoc:dmx-topic-row-topic-id-of
      (hyperdoc:dmx-sync-plan-item-target-row-of item))
     "Target topic id remains an observation")))

(defun dmx-query-smoke-temp-db ()
  #P"/tmp/hyperdoc-dmx-query-layer-smoke.sqlite")

(defun dmx-query-sql-count (store table)
  (let* ((rows (hyperdoc::dmx-sqlite-json-query
                store
                (format nil "SELECT COUNT(*) AS n FROM ~A;" table)))
         (row (first rows)))
    (gethash "n" row)))

(defun run-dmx-query-layer-sqlite-smoke-test ()
  (let* ((db (dmx-query-smoke-temp-db))
         (store (hyperdoc:make-dmx-query-sqlite-store :db-path db))
         (source (hyperdoc:make-dmx-memory-query-target
                  :id "sqlite-source"
                  :raw-rows
                  (list (dmx-query-hash-row
                         "topicId" 201
                         "uri" "dmx://topic/sqlite-source"
                         "typeUri" "dmx.notes.note"
                         "value" "Source row"))))
         (target (hyperdoc:make-dmx-memory-query-target
                  :id "sqlite-target"
                  :raw-rows nil))
         (query (hyperdoc:make-dmx-unassigned-topics-query))
         (run (hyperdoc:dmx-run-query source query))
         (plan (hyperdoc:dmx-plan-topic-sync source target :query query)))
    (when (probe-file db)
      (delete-file db))
    (hyperdoc:dmx-persist-query-run store run)
    (hyperdoc:dmx-persist-sync-plan store plan)
    (dmx-query-assert-true
     (probe-file db)
     "SQLite query journal database must be created")
    (dmx-query-assert-equal 1
                            (dmx-query-sql-count store "queries")
                            "SQLite must persist the query definition")
    (dmx-query-assert-equal 1
                            (dmx-query-sql-count store "query_runs")
                            "SQLite must persist the query run")
    (dmx-query-assert-equal 1
                            (dmx-query-sql-count store "topic_answers")
                            "SQLite must persist topic answer rows")
    (dmx-query-assert-equal 1
                            (dmx-query-sql-count store "sync_plans")
                            "SQLite must persist dry-run sync plans")
    (dmx-query-assert-equal 1
                            (dmx-query-sql-count store "sync_plan_items")
                            "SQLite must persist dry-run sync plan items")
    (dmx-query-assert-true
     (hyperdoc:dmx-load-query-runs store :limit 5)
     "SQLite load helper must return persisted runs")))

(defun run-dmx-query-layer-http-unavailable-smoke-test ()
  (let* ((target (hyperdoc:make-remote-dmx-http-query-target
                  :base-url "https://dmx.ralfbarkow.ch"))
         (run (hyperdoc:dmx-list-unassigned-topics target :limit 5)))
    (dmx-query-assert-typep 'hyperdoc:dmx-query-run
                            run
                            "HTTP unavailable result must still be inspectable")
    (dmx-query-assert-equal
     :backend-capability-missing
     (hyperdoc:dmx-query-run-status-of run)
     "Full-store HTTP inventory must report capability missing instead of signalling")
    (dmx-query-assert-true
     (hyperdoc:dmx-query-run-error-detail-of run)
     "HTTP capability-missing run must include a diagnostic detail")))

(defun run-dmx-query-layer-inspector-view-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (let* ((target (hyperdoc:make-dmx-memory-query-target
                  :raw-rows (dmx-query-fixture-rows)))
         (run (hyperdoc:dmx-list-unassigned-topics target :limit 2))
         (plan (hyperdoc:dmx-plan-topic-sync
                target
                (hyperdoc:make-dmx-memory-query-target :id "empty")
                :query (hyperdoc:make-dmx-unassigned-topics-query)))
         (run-views (html-inspector-views:all-views run))
         (plan-views (html-inspector-views:all-views plan)))
    (dolist (title '("Overview" "Rows" "Evidence"))
      (dmx-query-assert-true
       (find title run-views
             :key #'html-inspector-views:view-title
             :test #'string=)
       (format nil "DMX query run must expose inspector view ~A" title)))
    (dolist (title '("Overview" "Items by action" "Unsafe/unsupported"))
      (dmx-query-assert-true
       (find title plan-views
             :key #'html-inspector-views:view-title
             :test #'string=)
       (format nil "DMX sync plan must expose inspector view ~A" title)))))

(defun run-dmx-query-layer-smoke-tests ()
  (run-dmx-query-layer-workspace-status-smoke-test)
  (run-dmx-query-layer-list-filter-smoke-test)
  (run-dmx-query-layer-plist-row-smoke-test)
  (run-dmx-query-layer-uri-comparison-smoke-test)
  (run-dmx-query-layer-sqlite-smoke-test)
  (run-dmx-query-layer-http-unavailable-smoke-test)
  (run-dmx-query-layer-inspector-view-smoke-test)
  (format t "~&DMX query layer smoke tests passed.~%")
  t)
