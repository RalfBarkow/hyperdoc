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
             (assert-true (getf report :ok-p)
                          "A writer-produced store must have an empty integrity report"))
           (assert-sql-ok
            db
            "PRAGMA foreign_keys = OFF; INSERT INTO dmx_sql_assoc_player(assoc_id, player_no, role_type_uri, player_kind, player_local_id) VALUES('assoc:left-right', 99, 'dmx.role.broken', 'topic', 'topic:missing');"
            "Fixture insertion of a broken association player must succeed")
           (assert-sql-ok
            db
            "PRAGMA foreign_keys = OFF; INSERT INTO dmx_sql_sync_identity(id, local_object_id, host, remote_id, sync_state) VALUES('identity:broken', 'topic:missing', 'broken-host', 7, 'observed');"
            "Fixture insertion of a broken sync identity must succeed")
           (let ((report (dmx-sqlite-integrity-report db)))
             (assert-true (not (getf report :ok-p))
                          "Broken imported references must fail the integrity report")
             (assert-equal 1 (length (getf report :broken-association-players))
                           "Integrity report must identify broken association players")
             (assert-equal 1 (length (getf report :broken-sync-identities))
                           "Integrity report must identify broken sync identity references"))
           (multiple-value-bind (counts error exit-code) (dmx-sql-counts :db-path db)
             (declare (ignore error))
             (assert-equal 0 exit-code "Count query must succeed")
             (assert-true (search "topic" counts) "Count query must include topics"))
           (format t "~&Dreyeck DMX SQLite smoke tests passed.~%")
           t)
      (when (probe-file db)
        (delete-file db)))))
