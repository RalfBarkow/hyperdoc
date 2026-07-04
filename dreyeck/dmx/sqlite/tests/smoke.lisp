(in-package #:dreyeck.dmx.sqlite/tests)

(defun assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A: expected ~S, got ~S" message expected actual)))

(defun assert-true (value message)
  (unless value
    (error "~A" message)))

(defun entry-by-id (entries id)
  (find id entries
        :key (lambda (entry) (getf entry :id))
        :test #'equal))

(defun plist-key-present-p (plist key)
  (loop for tail on plist by #'cddr
        thereis (eql (first tail) key)))

(defun topic-entry-by-id (topics id)
  (entry-by-id topics id))

(defun result-fragment-texts (result)
  (loop for fragment in (getf result :extracted-fragments)
        collect (getf fragment :text)))

(defun assert-plist-has-keys (plist keys message)
  (dolist (key keys)
    (assert-true
     (plist-key-present-p plist key)
     (format nil "~A must include key ~S" message key))))

(defun assert-source-reader-result (result reader message)
  (assert-equal
   :source-reader-result
   (getf result :kind)
   (format nil "~A kind" message))
  (assert-equal reader
                (getf result :reader)
                (format nil "~A reader" message))
  (assert-equal nil
                (getf result :network-required-p)
                (format nil "~A network requirement" message))
  (assert-plist-has-keys
   result
   '(:kind :reader :source-identity :provenance :extracted-fragments
     :derived-topics :failure-state :network-required-p)
   message)
  (assert-true
   (getf result :source-identity)
   (format nil "~A must include source identity" message))
  (assert-true
   (getf result :provenance)
   (format nil "~A must include provenance" message))
  (assert-true
   (getf result :extracted-fragments)
   (format nil "~A must include extracted fragments" message))
  (assert-true
   (getf result :derived-topics)
   (format nil "~A must include derived topics" message)))

(defun assert-any-text-contains (texts needle message)
  (assert-true
   (some (lambda (text)
           (and (stringp text)
                (search needle text :test #'char-equal)))
         texts)
   message))

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

(defun assert-error (thunk message)
  (assert-true
   (handler-case
       (progn
         (funcall thunk)
         nil)
     (error () t))
   message))

(defun record-test-described-by-edge (db target)
  (record-dmx-association-value
   db
   (format nil "assoc:a:described-by:~A" target)
   "dreyeck.dmx.association.described-by"
   :players
   (topic-association-players
    "a" "dmx.role.player1" target "dmx.role.player2")
   :value "described-by"))

(defun association-edge-reassignment-fixture-db
    (&key (old-edge-present-p t) (new-edge-present-p nil))
  (let ((db (temporary-dmx-sqlite-path)))
    (initialize-dmx-associative-mirror :db-path db :clear t)
    (dolist (topic-id '("a" "old-source" "new-source"))
      (record-dmx-topic-value db topic-id "dmx.test.topic" topic-id))
    (when old-edge-present-p
      (record-test-described-by-edge db "old-source"))
    (when new-edge-present-p
      (record-test-described-by-edge db "new-source"))
    db))

(defun assert-edge-reassignment-report-delta
    (report removed-association-ids added-association-ids message)
  (assert-equal
   removed-association-ids
   (getf (getf report :expected-graph-delta) :removed-association-ids)
   (format nil "~A expected removed ids" message))
  (assert-equal
   added-association-ids
   (getf (getf report :expected-graph-delta) :added-association-ids)
   (format nil "~A expected added ids" message))
  (assert-equal
   removed-association-ids
   (getf (getf report :actual-graph-delta) :removed-association-ids)
   (format nil "~A actual removed ids" message))
  (assert-equal
   added-association-ids
   (getf (getf report :actual-graph-delta) :added-association-ids)
   (format nil "~A actual added ids" message))
  (assert-equal
   nil
   (getf report :unexpected-graph-delta)
   (format nil "~A unexpected delta" message)))

(defun assert-edge-reassignment-outcome
    (db report old-present-p new-present-p message)
  (assert-equal :passed
                (getf report :status)
                (format nil "~A status" message))
  (assert-equal old-present-p
                (not
                 (not
                  (association-edge-present-p
                   db
                   '("a" "described-by" "old-source"))))
                (format nil "~A old edge presence" message))
  (assert-equal new-present-p
                (not
                 (not
                  (association-edge-present-p
                   db
                   '("a" "described-by" "new-source"))))
                (format nil "~A new edge presence" message)))

(defun run-association-edge-reassignment-case-a-test ()
  (let ((db (association-edge-reassignment-fixture-db
             :old-edge-present-p t
             :new-edge-present-p nil)))
    (unwind-protect
         (let ((report
                 (reassign-association-edge
                  db
                  '("a" "described-by" "old-source")
                  '("a" "described-by" "new-source")
                  :reason
                  "Fixture source correction for one association edge.")))
           (assert-edge-reassignment-outcome
            db report nil t "Case A")
           (assert-edge-reassignment-report-delta
            report
            '("assoc:a:described-by:old-source")
            '("assoc:a:described-by:new-source")
            "Case A")
           (assert-error
            (lambda ()
              (reassign-association-edge
               db
               '("a" "described-by" "old-source")
               '("changed-source" "described-by" "new-source")
               :require-old-edge-p nil))
            "Edge reassignment must reject source changes")
           (assert-error
            (lambda ()
              (reassign-association-edge
               db
               '("a" "described-by" "old-source")
               '("a" "changed-predicate" "new-source")
               :require-old-edge-p nil))
            "Edge reassignment must reject predicate changes")
           (assert-error
            (lambda ()
              (reassign-association-edge
               db
               '("a" "described-by" "old-source")
               '("a" "described-by" "missing-target")
               :require-old-edge-p nil))
            "Edge reassignment must reject a missing new target topic"))
      (when (probe-file db)
        (delete-file db)))))

(defun run-association-edge-reassignment-case-b-test ()
  (let ((db (association-edge-reassignment-fixture-db
             :old-edge-present-p t
             :new-edge-present-p t)))
    (unwind-protect
         (let ((report
                 (reassign-association-edge
                  db
                  '("a" "described-by" "old-source")
                  '("a" "described-by" "new-source")
                  :reason
                  "Fixture converges when the replacement edge already exists.")))
           (assert-edge-reassignment-outcome
            db report nil t "Case B")
           (assert-edge-reassignment-report-delta
            report
            '("assoc:a:described-by:old-source")
            nil
            "Case B")
           (assert-equal
            nil
            (getf (getf report :atomic-change) :added)
            "Case B must not report an inserted edge")
           (assert-equal
            '("a" "described-by" "new-source")
            (getf (getf report :atomic-change) :already-present)
            "Case B must report the already-present replacement edge")
           (assert-equal
            t
            (getf (getf report :convergence) :new-edge-already-present-p)
            "Case B convergence must report the preexisting new edge"))
      (when (probe-file db)
        (delete-file db)))))

(defun run-association-edge-reassignment-case-c-test ()
  (let ((db (association-edge-reassignment-fixture-db
             :old-edge-present-p nil
             :new-edge-present-p t)))
    (unwind-protect
         (let ((report
                 (reassign-association-edge
                  db
                  '("a" "described-by" "old-source")
                  '("a" "described-by" "new-source")
                  :reason
                  "Fixture accepts already-completed convergence."
                  :require-old-edge-p nil)))
           (assert-edge-reassignment-outcome
            db report nil t "Case C")
           (assert-edge-reassignment-report-delta
            report nil nil "Case C")
           (assert-equal
            nil
            (getf (getf report :atomic-change) :removed)
            "Case C must not report a removed edge")
           (assert-equal
            nil
            (getf (getf report :atomic-change) :added)
            "Case C must not report an inserted edge")
           (assert-equal
            t
            (getf (getf report :convergence) :already-completed-p)
            "Case C must report already-completed convergence")
           (assert-error
            (lambda ()
              (reassign-association-edge
               db
               '("a" "described-by" "old-source")
               '("a" "described-by" "new-source")))
            "Case E must still reject absent old edge when required"))
      (when (probe-file db)
        (delete-file db)))))

(defun run-association-edge-reassignment-case-d-test ()
  (let ((db (association-edge-reassignment-fixture-db
             :old-edge-present-p nil
             :new-edge-present-p nil)))
    (unwind-protect
         (let ((report
                 (reassign-association-edge
                  db
                  '("a" "described-by" "old-source")
                  '("a" "described-by" "new-source")
                  :reason
                  "Fixture inserts the replacement edge when old is optional."
                  :require-old-edge-p nil)))
           (assert-edge-reassignment-outcome
            db report nil t "Case D")
           (assert-edge-reassignment-report-delta
            report nil '("assoc:a:described-by:new-source") "Case D"))
      (when (probe-file db)
        (delete-file db)))))

(defun run-association-edge-reassignment-fixture-test ()
  (run-association-edge-reassignment-case-a-test)
  (run-association-edge-reassignment-case-b-test)
  (run-association-edge-reassignment-case-c-test)
  (run-association-edge-reassignment-case-d-test))

(defun run-operation-documentation-topic-materialization-test ()
  (let ((db (temporary-dmx-sqlite-path))
        (operation "bounded-convergent-association-edge-reassignment")
        (required-topic-ids
          '("bounded-convergent-association-edge-reassignment"
            "operation-reader-surface-documentation-pattern"
            "expected-vs-actual-graph-delta"
            "atomic-vs-derivative-effects"
            "single-source-of-truth-for-maintained-graph"
            "operation-reader-question"
            "bounded-convergent-association-edge-reassignment-fedwiki-page"))
        (required-association-ids
          '("assoc:bounded-convergent-association-edge-reassignment:instantiates:operation-reader-surface-documentation-pattern"
            "assoc:bounded-convergent-association-edge-reassignment:uses:expected-vs-actual-graph-delta"
            "assoc:bounded-convergent-association-edge-reassignment:separates:atomic-vs-derivative-effects"
            "assoc:bounded-convergent-association-edge-reassignment:respects:single-source-of-truth-for-maintained-graph"
            "assoc:operation-reader-surface-documentation-pattern:answers:operation-reader-question"
            "assoc:bounded-convergent-association-edge-reassignment:documented-by:bounded-convergent-association-edge-reassignment-fedwiki-page")))
    (unwind-protect
         (progn
           (initialize-dmx-associative-mirror :db-path db :clear t)
           (dolist (topic-id required-topic-ids)
             (assert-true
              (member topic-id
                      (required-operation-documentation-topic-ids operation)
                      :test #'equal)
              (format nil
                      "Required operation documentation topic ids must include ~A"
                      topic-id)))
           (let* ((materialization
                    (materialize-operation-documentation-topics
                     db
                     operation))
                  (status
                    (operation-documentation-topic-materialization-status
                     db
                     operation))
                  (operation-reader-surface-topics
                    (dmx-materialized-operation-reader-surface-topics
                     :db-path db)))
             (assert-equal
              :operation-documentation-topic-materialization
              (getf materialization :kind)
              "Operation documentation materializer must return a structured report")
             (assert-equal
              :passed
              (getf status :status)
              "Operation documentation materialization status must pass")
             (assert-equal
              nil
              (getf status :missing-topic-ids)
              "Operation documentation materialization must report no missing topics")
             (assert-equal
              nil
              (getf status :missing-association-ids)
              "Operation documentation materialization must report no missing associations")
             (dolist (topic-id required-topic-ids)
               (assert-true
                (dmx-sqlite-topic db topic-id)
                (format nil
                        "Operation documentation materializer must create topic ~A"
                        topic-id)))
             (dolist (association-id required-association-ids)
               (assert-true
                (dmx-sqlite-association db association-id)
                (format nil
                        "Operation documentation materializer must create association ~A"
                        association-id)))
             (assert-equal
              :passed
              (getf operation-reader-surface-topics :status)
              "Operation reader-surface topic query must pass after explicit materialization")))
      (when (probe-file db)
        (delete-file db)))))

(defun run-source-reader-task-topic-materialization-test ()
  (let ((db (temporary-dmx-sqlite-path)))
    (unwind-protect
         (progn
           (initialize-dmx-associative-mirror :db-path db :clear t)
           (let* ((first-run
                    (materialize-source-reader-task-topics :db-path db))
                  (second-run
                    (materialize-source-reader-task-topics :db-path db))
                  (status
                    (source-reader-task-topic-materialization-status
                     :db-path db))
                  (inspection
                    (dmx-materialized-source-reader-task-topics
                     :db-path db)))
             (assert-equal
              :source-reader-task-topic-materialization
              (getf first-run :kind)
              "Source-reader task materializer must return a structured report")
             (assert-equal
              :passed
              (getf status :status)
              "Source-reader task topic materialization must pass")
             (assert-equal
              nil
              (getf status :missing-topic-ids)
              "Source-reader task topic materialization must report no missing topics")
             (assert-equal
              nil
              (getf status :missing-association-ids)
              "Source-reader task topic materialization must report no missing associations")
             (assert-equal
              nil
              (getf status :network-required-p)
              "Source-reader task topic materialization must be local-only")
             (dolist (topic-id (source-reader-task-topic-ids))
               (assert-true
                (dmx-sqlite-topic db topic-id)
                (format nil
                        "Source-reader materializer must create topic ~A"
                        topic-id)))
             (dolist (association-id (getf status :required-association-ids))
               (assert-true
                (dmx-sqlite-association db association-id)
                (format nil
                        "Source-reader materializer must create association ~A"
                        association-id)))
             (assert-true
              (every (lambda (result)
                       (eq (getf result :state) :unchanged))
                     (getf second-run :topic-results))
              "Second source-reader materializer run must not rewrite topics")
             (assert-true
              (every (lambda (result)
                       (eq (getf result :state) :unchanged))
                     (getf second-run :association-results))
              "Second source-reader materializer run must not rewrite associations")
             (assert-equal
              :dmx-materialized-source-reader-task-topics
              (getf inspection :kind)
              "Source-reader task inspection must return a structured object")
             (assert-equal
              :passed
              (getf inspection :status)
              "Source-reader task inspection must validate present topics")
             (assert-true
              (entry-by-id
               (getf inspection :topics)
               "read-zettel-6537-and-advice-taker")
              "Source-reader task inspection must include the plan topic")
             (assert-true
              (entry-by-id
               (getf inspection :topics)
               "zettel-6537-source-station")
              "Source-reader task inspection must include the Zettel source station")
             (assert-true
             (entry-by-id
              (getf inspection :topics)
              "physics-not-advice-source-station")
             "Source-reader task inspection must include the FedWiki source station")
            (assert-true
             (entry-by-id
              (getf inspection :topics)
              "advice-taker-source-station")
             "Source-reader task inspection must include the Advice Taker source station")))
      (when (probe-file db)
        (delete-file db)))))

(defun run-source-reader-surface-test ()
  (let* ((zettel (read-zettel-6537-source))
         (physics (read-physics-not-advice-source))
         (advice-taker (read-advice-taker-source))
         (surface-set (read-zettel-6537-and-advice-taker-sources)))
    (assert-source-reader-result
     zettel
     :zettel-reader
     "Zettel 6537 reader")
    (assert-equal
     "zettel-6537"
     (getf (getf zettel :source-identity) :id)
     "Zettel 6537 reader source id")
    (assert-equal
     "zettel-6537-source-station"
     (getf (getf zettel :source-identity) :source-station)
     "Zettel 6537 reader source station")
    (assert-true
     (topic-entry-by-id (getf zettel :derived-topics) "zettel-6537")
     "Zettel 6537 reader must derive the Zettel topic")
    (assert-any-text-contains
     (result-fragment-texts zettel)
     "Zettel 6537"
     "Zettel 6537 reader must retain readable source text")
    (assert-source-reader-result
     physics
     :fedwiki-page-reader
     "Physics, Not Advice reader")
    (assert-equal
     "physics-not-advice"
     (getf (getf physics :source-identity) :slug)
     "Physics, Not Advice reader slug")
    (assert-true
     (topic-entry-by-id (getf physics :derived-topics) "zettel-6537")
     "Physics, Not Advice reader must derive the Zettel 6537 bridge")
    (assert-any-text-contains
     (result-fragment-texts physics)
     "Advice Taker"
     "Physics, Not Advice reader must retain Advice Taker source text")
    (assert-source-reader-result
     advice-taker
     :advice-taker-note-reader
     "Advice Taker reader")
    (assert-equal
     "advice-taker-source-station"
     (getf (getf advice-taker :source-identity) :source-station)
     "Advice Taker reader source station")
    (assert-true
     (topic-entry-by-id (getf advice-taker :derived-topics) "advice-taker")
     "Advice Taker reader must derive the Advice Taker topic")
    (assert-any-text-contains
     (result-fragment-texts advice-taker)
     "Advice Taker"
     "Advice Taker reader must retain local page or topicmap text")
    (if (getf (getf advice-taker :provenance) :transcript-present-p)
        (assert-equal
         nil
         (getf advice-taker :failure-state)
         "Advice Taker reader must be complete when transcript is present")
        (progn
          (assert-equal
           :partial
           (getf (getf advice-taker :failure-state) :status)
           "Advice Taker reader must report partial status without transcript")
          (assert-equal
           :transcript-missing
           (getf (getf advice-taker :failure-state) :reason)
           "Advice Taker reader must preserve transcript-missing reason")))
    (assert-equal
     :source-reader-surface-set
     (getf surface-set :kind)
     "Combined source-reader surface set kind")
    (assert-equal
     "read-zettel-6537-and-advice-taker"
     (getf surface-set :plan)
     "Combined source-reader surface set plan id")
    (assert-equal
     nil
     (getf surface-set :network-required-p)
     "Combined source-reader surface set must be local-only")
    (assert-equal
     3
     (length (getf surface-set :sources))
     "Combined source-reader surface set must include three sources")))

(defun run-dmx-sqlite-smoke-tests ()
  (run-association-edge-reassignment-fixture-test)
  (run-operation-documentation-topic-materialization-test)
  (run-source-reader-task-topic-materialization-test)
  (run-source-reader-surface-test)
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
                    (dmx-materialized-learning-topics :db-path db))
                  (operation-reader-surface-topics
                    (dmx-materialized-operation-reader-surface-topics
                     :db-path db))
                  (domkin-source-topics
                    (dmx-materialized-domkin-2017-source-topics
                     :db-path db))
                  (fedwiki-page-path
                    #p"/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/bounded-convergent-association-edge-reassignment")
                  (reader-surface
                    (association-edge-reassignment-reader-surface
                     :old-edge '("a" "described-by" "old-source")
                     :new-edge '("a" "described-by" "new-source"))))
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
             (dolist (topic-id '("domkin-2017-loading-multiple-asdf-versions"
                                 "common-lisp-dependency-hell"
                                 "package-name-conflict"
                                 "global-package-registry"
                                 "asdf-unversioned-system-registry"
                                 "package-renaming-conflict-resolution"
                                 "load-system-with-renamings"
                                 "asdf-public-api-gap"
                                 "asdf-plan-api-underdocumented"
                                 "implicit-transitive-dependency-limitation"
                                 "runtime-intern-eval-renaming-limitation"
                                 "hyperdoc-asdf-session-action-reading"))
               (assert-true
                (dmx-sqlite-topic db topic-id)
                (format nil
                        "Materializer must create required Domkin 2017 topic ~A"
                        topic-id)))
             (dolist (association-id
                      '("assoc:domkin-2017-loading-multiple-asdf-versions:addresses:common-lisp-dependency-hell"
                        "assoc:common-lisp-dependency-hell:manifests-as:package-name-conflict"
                        "assoc:package-name-conflict:occurs-in:global-package-registry"
                        "assoc:load-system-with-renamings:implements:package-renaming-conflict-resolution"
                        "assoc:load-system-with-renamings:performs:dependency-tree-conflict-analysis"
                        "assoc:asdf-public-api-gap:limits:load-system-with-renamings"
                        "assoc:asdf-plan-api-underdocumented:limits:alternative-asdf-system-strategies"
                        "assoc:implicit-transitive-dependency-limitation:constrains:load-system-with-renamings"
                        "assoc:runtime-intern-eval-renaming-limitation:constrains:load-system-with-renamings"
                        "assoc:hyperdoc-asdf-session-action-reading:derived-from:domkin-2017-loading-multiple-asdf-versions"
                        "assoc:build-referee-decision-route:responds-to:asdf-plan-api-underdocumented"
                        "assoc:lisp-referee-form:responds-to:asdf-monolithic-loading-strategy"))
               (assert-true
                (dmx-sqlite-association db association-id)
                (format nil
                        "Materializer must create required Domkin 2017 association ~A"
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
             (assert-equal
              :dmx-materialized-operation-reader-surface-topics
              (getf operation-reader-surface-topics :kind)
              "Operation reader-surface query must return a structured inspection object")
             (assert-equal
              :passed
              (getf operation-reader-surface-topics :status)
              "Operation reader-surface query must validate present topics")
             (dolist (topic-id '("operation-reader-surface-documentation-pattern"
                                 "bounded-convergent-association-edge-reassignment"
                                 "expected-vs-actual-graph-delta"
                                 "atomic-vs-derivative-effects"))
               (assert-true
                (entry-by-id
                 (getf operation-reader-surface-topics :topics)
                 topic-id)
                (format nil
                        "Operation reader-surface topic query must include ~A"
                        topic-id))
               (assert-true
                (dmx-sqlite-topic db topic-id)
                (format nil
                        "Materializer must create operation reader-surface topic ~A"
                        topic-id)))
             (dolist (association-id
                      '("assoc:bounded-convergent-association-edge-reassignment:instantiates:operation-reader-surface-documentation-pattern"
                        "assoc:bounded-convergent-association-edge-reassignment:uses:expected-vs-actual-graph-delta"
                        "assoc:bounded-convergent-association-edge-reassignment:separates:atomic-vs-derivative-effects"
                        "assoc:bounded-convergent-association-edge-reassignment:respects:single-source-of-truth-for-maintained-graph"
                        "assoc:operation-reader-surface-documentation-pattern:answers:operation-reader-question"
                        "assoc:bounded-convergent-association-edge-reassignment:documented-by:bounded-convergent-association-edge-reassignment-fedwiki-page"
                        "assoc:bounded-convergent-association-edge-reassignment-fedwiki-page:documents:bounded-convergent-association-edge-reassignment"))
               (assert-true
                (dmx-sqlite-association db association-id)
                (format nil
                        "Materializer must create operation reader-surface association ~A"
                        association-id)))
             (assert-true
              (entry-by-id
               (getf operation-reader-surface-topics :topics)
               "bounded-convergent-association-edge-reassignment-fedwiki-page")
              "Operation reader-surface query must include the FedWiki page artifact topic")
             (assert-true
              (probe-file fedwiki-page-path)
              "FedWiki page artifact must exist")
             (assert-true
              (search "dreyeck.dmx.sqlite:reassign-association-edge"
                      (uiop:read-file-string fedwiki-page-path))
              "FedWiki page artifact must mention the operation")
             (assert-equal
              :association-edge-reassignment-reader-surface
              (getf reader-surface :kind)
              "Reader-surface constructor must return a structured object")
             (assert-equal
              :reassign-association-edge
              (getf (getf reader-surface :primary-answer) :operation)
              "Reader surface primary answer must name the operation")
             (assert-equal
              '("a" "described-by" "new-source")
              (getf (getf (getf reader-surface :primary-answer)
                          :atomic-change)
                    :added-or-confirmed)
              "Reader surface primary answer must expose the added-or-confirmed edge")
             (assert-equal
              nil
              (getf (getf reader-surface :secondary-evidence) :raw-report)
              "Reader surface primary answer must not require a raw materializer dump")
             (assert-equal
              :dmx-materialized-domkin-2017-source-topics
              (getf domkin-source-topics :kind)
              "Domkin source query must return a structured inspection object")
             (assert-equal
              :passed
              (getf domkin-source-topics :status)
              "Domkin source query must validate present source topics")
             (assert-equal
              nil
              (getf domkin-source-topics :missing-topic-ids)
              "Domkin source query must report no missing topics")
             (assert-equal
              nil
              (getf domkin-source-topics :missing-association-ids)
              "Domkin source query must report no missing associations")
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
