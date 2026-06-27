(in-package #:dreyeck.dmx.sqlite/tests)

(defun assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A: expected ~S, got ~S" message expected actual)))

(defun assert-true (value message)
  (unless value
    (error "~A" message)))

(defun assert-sql-ok (db-path sql message)
  (multiple-value-bind (stdout stderr exit-code)
      (sqlite-run db-path sql)
    (declare (ignore stdout))
    (unless (zerop exit-code)
      (error "~A: ~A" message stderr))))

(defun temporary-dmx-sqlite-path ()
  (merge-pathnames
   (format nil "dreyeck-dmx-sqlite-~D.sqlite" (random 1000000))
   (uiop:temporary-directory)))

(defun run-dmx-sqlite-smoke-tests ()
  (let ((db (temporary-dmx-sqlite-path)))
    (unwind-protect
         (progn
           (initialize-dmx-associative-mirror :db-path db :clear t)
           (assert-equal :created
                         (record-dmx-topic-value db "topic:left" "dmx.test.topic" "Left")
                         "First topic value must be created")
           (assert-equal :unchanged
                         (record-dmx-topic-value db "topic:left" "dmx.test.topic" "Left")
                         "Matching topic value must be unchanged")
           (assert-equal :conflict
                         (record-dmx-topic-value db "topic:left" "dmx.test.topic" "Changed")
                         "Different topic value must conflict by default")
           (assert-equal :updated
                         (record-dmx-topic-value db "topic:left" "dmx.test.topic" "Changed"
                                                 :replace-existing? t)
                         "Explicit topic replacement must update")
           (assert-equal :created
                         (record-dmx-topic-value db "topic:right" "dmx.test.topic" "Right")
                         "Second topic value must be created")
           (assert-true (not (dmx-sqlite-relationship-exists-p
                              db "topic:left" "topic:right"))
                        "Topic existence alone must not be relationship evidence")
           (assert-true
            (handler-case
                (progn
                  (record-dmx-association-value
                   db "assoc:invalid" "dmx.test.relationship"
                   :players
                   (list (list :player-no 1 :role-type-uri "dmx.role.left"
                               :player-kind "topic" :player-local-id "topic:missing")))
                  nil)
              (error () t))
            "Association players must name an existing object of their declared kind")
           (assert-equal :created
                         (record-dmx-association-value
                          db "assoc:left-right" "dmx.test.relationship"
                          :players
                          (list (list :player-no 1 :role-type-uri "dmx.role.left"
                                      :player-kind "topic" :player-local-id "topic:left")
                                (list :player-no 2 :role-type-uri "dmx.role.right"
                                      :player-kind "topic" :player-local-id "topic:right")))
                         "Association with role-bearing players must be created")
           (assert-equal :unchanged
                         (record-dmx-association-value
                          db "assoc:left-right" "dmx.test.relationship"
                          :players
                          (list (list :player-no 1 :role-type-uri "dmx.role.left"
                                      :player-kind "topic" :player-local-id "topic:left")
                                (list :player-no 2 :role-type-uri "dmx.role.right"
                                      :player-kind "topic" :player-local-id "topic:right")))
                         "Matching association value must be unchanged")
           (assert-equal :conflict
                         (record-dmx-association-value
                          db "assoc:left-right" "dmx.test.relationship.changed"
                          :players
                          (list (list :player-no 1 :role-type-uri "dmx.role.left"
                                      :player-kind "topic" :player-local-id "topic:left")
                                (list :player-no 2 :role-type-uri "dmx.role.right"
                                      :player-kind "topic" :player-local-id "topic:right")))
                         "Different association value must conflict by default")
           (assert-equal :updated
                         (record-dmx-association-value
                          db "assoc:left-right" "dmx.test.relationship.changed"
                          :players
                          (list (list :player-no 1 :role-type-uri "dmx.role.left"
                                      :player-kind "topic" :player-local-id "topic:left")
                                (list :player-no 2 :role-type-uri "dmx.role.right"
                                      :player-kind "topic" :player-local-id "topic:right"))
                          :replace-existing? t)
                         "Explicit association replacement must update")
           (assert-true (dmx-sql-association-has-role-bearing-players-p db "assoc:left-right")
                        "Association-player integrity must be queryable")
           (assert-true (dmx-sqlite-relationship-exists-p db "topic:left" "topic:right")
                        "Only role-bearing association players establish a relationship")
           (assert-equal :created
                         (record-dmx-sync-identity-value
                          db "topic:left" "local" :remote-id 1
                          :remote-uri "dmx://local/topic/left"
                          :remote-type-uri "dmx.test.topic")
                         "First sync identity must be created")
           (assert-equal :unchanged
                         (record-dmx-sync-identity-value
                          db "topic:left" "local" :remote-id 1
                          :remote-uri "dmx://local/topic/left"
                          :remote-type-uri "dmx.test.topic")
                         "Matching sync identity must be unchanged")
           (assert-equal :conflict
                         (record-dmx-sync-identity-value
                          db "topic:left" "local" :remote-id 1
                          :remote-uri "dmx://local/topic/left"
                          :remote-type-uri "dmx.test.topic.changed")
                         "Different sync identity must conflict by default")
           (assert-equal :updated
                         (record-dmx-sync-identity-value
                          db "topic:left" "local" :remote-id 1
                          :remote-uri "dmx://local/topic/left"
                          :remote-type-uri "dmx.test.topic.changed"
                          :replace-existing? t)
                         "Explicit sync identity replacement must update")
           (assert-equal :created
                         (record-dmx-property-value
                          db "property:left-title" "topic:left" "dmx.test.title"
                          :value "Left title" :target-object-id "topic:right"
                          :sync-state "observed")
                         "First property value must be created")
           (assert-equal :unchanged
                         (record-dmx-property-value
                          db "property:left-title" "topic:left" "dmx.test.title"
                          :value "Left title" :target-object-id "topic:right"
                          :sync-state "observed")
                         "Matching property replay must be unchanged")
           (assert-equal :conflict
                         (record-dmx-property-value
                          db "property:left-title" "topic:left" "dmx.test.title"
                          :value "Changed" :target-object-id "topic:right")
                         "Different property replay must conflict")
           (assert-equal :updated
                         (record-dmx-property-value
                          db "property:left-title" "topic:left" "dmx.test.title"
                          :value "Changed" :target-object-id "topic:right"
                          :replace-existing? t)
                         "Explicit property replacement must update")
           (assert-equal :created
                         (record-dmx-query-run-value
                          db "query:neighborhood:left" "dmx.query.neighborhood"
                          :local-object-id "topic:left" :result-json "{\"count\":1}")
                         "Query-run recording must create")
           (assert-equal :created
                         (record-dmx-journal-entry-value
                          db "journal:neighborhood:left" "dmx.journal.query"
                          "read" "observed" :local-object-id "topic:left"
                          :query-run-id "query:neighborhood:left")
                         "Journal recording must create")
           (let ((object (dmx-sqlite-object db "topic:left"))
                 (topic (dmx-sqlite-topic db "topic:left"))
                 (association (dmx-sqlite-association db "assoc:left-right"))
                 (association-players
                   (dmx-sqlite-association-players db "assoc:left-right"))
                 (topics (dmx-sqlite-topics db))
                 (associations (dmx-sqlite-associations db))
                 (neighborhood (dmx-sqlite-object-neighborhood db "topic:left"))
                 (identities (dmx-sqlite-sync-identities
                              db :local-object-id "topic:left"))
                 (remote-identities (dmx-sqlite-sync-identities-for-remote
                                     db "local" :remote-id 1))
                 (properties (dmx-sqlite-object-properties db "topic:left"))
                 (query-run (dmx-sqlite-query-run db "query:neighborhood:left"))
                 (journal (dmx-sqlite-journal-entries db
                                                       :query-run-id "query:neighborhood:left"))
                 (workflow (dmx-sqlite-sync-workflow-summary db))
                 (report (dmx-sqlite-integrity-report db)))
             (assert-equal "topic:left" (getf object :local-id)
                           "Logical object lookup must use local id")
             (assert-equal "topic" (getf topic :object-kind)
                           "Logical topic lookup must reject non-topics")
             (assert-equal 2 (length topics)
                           "Logical topic listing must return both topics")
             (assert-equal "assoc:left-right" (getf association :local-id)
                           "Logical association lookup must return the association")
             (assert-equal 2 (length association-players)
                           "Logical association player listing must preserve both players")
             (assert-equal 2 (length (getf association :players))
                           "Logical association must carry its ordered players")
             (assert-equal 1 (length associations)
                           "Logical association listing must return the created association")
             (assert-equal "topic:left"
                           (getf (getf neighborhood :object) :local-id)
                           "Logical neighborhood must retain the queried object")
             (assert-equal 1 (length (getf neighborhood :associations))
                           "Logical neighborhood must contain the role-bearing association")
             (assert-true
              (member "topic:right" (getf neighborhood :neighbors)
                      :key (lambda (neighbor) (getf neighbor :local-id))
                      :test #'string=)
              "Logical neighborhood must include the other association player")
             (assert-equal 1 (length identities)
                           "Logical sync identity lookup must find the local identity")
             (assert-equal 1 (getf (first identities) :remote-id)
                           "Logical sync identity lookup must preserve remote id")
             (assert-equal 1 (length remote-identities)
                           "Remote sync identity lookup must preserve the identity")
             (assert-equal 1 (length properties)
                           "Object property listing must return the property")
             (assert-equal "topic:right" (getf (first properties) :target-object-id)
                           "Property target-object reference must be readable")
             (assert-equal "query:neighborhood:left" (getf query-run :id)
                           "Query-run lookup must return the recorded observation")
             (assert-equal 1 (length journal)
                           "Journal read model must return the query-run journal entry")
             (assert-equal 1 (getf workflow :query-run-count)
                           "Sync workflow summary must count query runs")
             (assert-true (getf report :ok-p)
                          "A writer-produced store must have an empty integrity report"))
           (let* ((first-run
                    (materialize-durable-notes-into-production-db
                     :db-path db))
                  (second-run
                    (materialize-durable-notes-into-production-db
                     :db-path db))
                  (status
                    (durable-note-materialization-status :db-path db))
                  (learning-topics
                    (dmx-materialized-learning-topics :db-path db)))
             (assert-equal :durable-note-materialization
                           (getf first-run :kind)
                           "Materializer must return a structured run object")
             (assert-true (dmx-sqlite-topic db "hyperdoc-core")
                          "Materializer must create the HyperDoc Core topic")
             (assert-true
              (dmx-sqlite-topic
               db "ownership-extraction-with-compatibility-shell")
              "Materializer must create the ownership extraction pattern topic")
             (assert-true (dmx-sqlite-topic db "codex-belongs-to-dreyeck")
                          "Materializer must create the Codex/Dreyeck decision topic")
             (assert-true
              (dmx-sqlite-association
               db
               "assoc:hyperdoc-core:supplies-boundary-for:ownership-extraction-with-compatibility-shell")
              "Materializer must create the HyperDoc boundary association")
             (assert-true
              (dmx-sqlite-topic db "codex-is-not-the-build-system")
              "Materializer must create the Codex/build-system boundary topic")
             (assert-true
              (dmx-sqlite-topic
               db "reusable-common-lisp-build-tasks-for-codex")
              "Materializer must create the reusable build-task topic")
             (assert-true
              (dmx-sqlite-topic db "dmx-learning-topic-inspection")
              "Materializer must create the DMX learning inspection topic")
             (assert-true
              (dmx-sqlite-topic db "codex-dmx-learning-topics")
              "Materializer must create the Codex DMX learning topic surface")
             (assert-true
              (dmx-sqlite-topic db "plan-then-perform-build-session")
              "Materializer must create the plan-then-perform learned pattern topic")
             (assert-true
              (dmx-sqlite-topic db "build-referee-decision-route")
              "Materializer must create the build referee route pattern topic")
             (assert-true
              (dmx-sqlite-topic db "dreyeck/build:build-session-next-action")
              "Materializer must create the Lisp referee function topic")
             (dolist (topic-id '("add-plan-then-perform-session-state-to-dreyeck-build"
                                 "render-build-referee-decisions-as-routes"
                                 "plan-then-perform-build-session"
                                 "build-referee-decision-route"
                                 "lisp-referee-form"
                                 "dreyeck/build:build-session-next-action"
                                 "asdf-3-3-session-action-model"
                                 "domkin-2017"))
               (assert-true
                (dmx-sqlite-topic db topic-id)
                (format nil
                        "Materializer must create required build/referee topic ~A"
                        topic-id)))
             (assert-true
              (dmx-sqlite-association
               db
               "assoc:codex-is-not-the-build-system:recommends:reusable-common-lisp-build-tasks-for-codex")
              "Materializer must create the Codex/build-task recommendation")
             (assert-true
              (dmx-sqlite-association
               db
               "assoc:plan-then-perform-build-session:inspired-by:asdf-3-3-session-action-model")
              "Materializer must create the plan/session ASDF source association")
             (assert-true
              (dmx-sqlite-association
               db
               "assoc:build-referee-decision-route:inspects:dreyeck/build:build-session-next-action")
              "Materializer must create the referee route/function inspection association")
             (dolist (association-id
                      '("assoc:plan-then-perform-build-session:refines:codex-is-not-the-build-system"
                        "assoc:plan-then-perform-build-session:supports:reusable-common-lisp-build-tasks-for-codex"
                        "assoc:plan-then-perform-build-session:inspired-by:asdf-3-3-session-action-model"
                        "assoc:asdf-3-3-session-action-model:described-by:domkin-2017"
                        "assoc:build-referee-decision-route:renders:lisp-referee-form"
                        "assoc:build-referee-decision-route:explains:plan-then-perform-build-session"
                        "assoc:build-referee-decision-route:supports:codex-is-not-the-build-system"
                        "assoc:build-referee-decision-route:inspects:dreyeck/build:build-session-next-action"))
               (assert-true
                (dmx-sqlite-association db association-id)
                (format nil
                        "Materializer must create required build/referee association ~A"
                        association-id)))
             (assert-equal
              :passed
              (getf status :last-validation-status)
              "Materialization status must validate the seeded topic store")
             (assert-equal
              :dmx-materialized-learning-topics
              (getf learning-topics :kind)
              "Learning-topic query must return a structured inspection object")
             (assert-equal
              :passed
              (getf learning-topics :status)
              "Learning-topic query must validate present learning topics")
             (assert-equal
              (namestring db)
              (getf learning-topics :production-db-path)
              "Learning-topic query must expose the selected DB path")
             (assert-true
              (every (lambda (result)
                       (eq (getf result :state) :unchanged))
                     (getf second-run :topic-results))
              "Second materializer run must not duplicate or rewrite topics")
             (assert-true
              (every (lambda (result)
                       (eq (getf result :state) :unchanged))
                     (getf second-run :association-results))
              "Second materializer run must not duplicate or rewrite associations"))
           (assert-sql-ok
            db
            "PRAGMA foreign_keys = OFF; INSERT INTO dmx_sql_assoc_player(assoc_id, player_no, role_type_uri, player_kind, player_local_id) VALUES('assoc:left-right', 99, 'dmx.role.broken', 'topic', 'topic:missing');"
            "Fixture insertion of a broken association player must succeed")
           (assert-sql-ok
           db
           "PRAGMA foreign_keys = OFF; INSERT INTO dmx_sql_sync_identity(id, local_object_id, host, remote_id, sync_state) VALUES('identity:broken', 'topic:missing', 'broken-host', 7, 'observed');"
            "Fixture insertion of a broken sync identity must succeed")
           (assert-sql-ok
            db
            "PRAGMA foreign_keys = OFF; INSERT INTO dmx_sql_property(id, object_id, property_uri) VALUES('property:broken', 'topic:missing', 'dmx.test.title');"
            "Fixture insertion of a broken property owner must succeed")
           (assert-sql-ok
            db
            "PRAGMA foreign_keys = OFF; UPDATE dmx_sql_property_target SET target_object_id = 'topic:missing' WHERE property_id = 'property:left-title';"
            "Fixture update of a broken property target must succeed")
           (let ((report (dmx-sqlite-integrity-report db)))
             (assert-true (not (getf report :ok-p))
                          "Broken imported references must fail the integrity report")
             (assert-equal 1 (length (getf report :broken-association-players))
                           "Integrity report must identify broken association players")
             (assert-equal 1 (length (getf report :broken-sync-identities))
                           "Integrity report must identify broken sync identity references")
             (assert-equal 1 (length (getf report :broken-property-owners))
                           "Integrity report must identify broken property owners")
             (assert-equal 1 (length (getf report :broken-property-targets))
                           "Integrity report must identify broken property targets"))
           (multiple-value-bind (counts error exit-code) (dmx-sql-counts :db-path db)
             (declare (ignore error))
             (assert-equal 0 exit-code "Count query must succeed")
             (assert-true (search "topic" counts) "Count query must include topics"))
           (format t "~&Dreyeck DMX SQLite smoke tests passed.~%")
           t)
      (when (probe-file db)
        (delete-file db)))))
