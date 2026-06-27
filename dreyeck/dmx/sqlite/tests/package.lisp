(defpackage #:dreyeck.dmx.sqlite/tests
  (:use #:cl)
  (:import-from #:dreyeck.dmx.sqlite
                #:initialize-dmx-associative-mirror
                #:record-dmx-topic-value
                #:record-dmx-association-value
                #:record-dmx-sync-identity-value
                #:record-dmx-property-value
                #:record-dmx-query-run-value
                #:record-dmx-journal-entry-value
                #:sqlite-run
                #:dmx-sqlite-object
                #:dmx-sqlite-topic
                #:dmx-sqlite-association
                #:dmx-sqlite-association-players
                #:dmx-sqlite-topics
                #:dmx-sqlite-associations
                #:dmx-sqlite-object-neighborhood
                #:dmx-sqlite-relationship-exists-p
                #:dmx-sqlite-sync-identities
                #:dmx-sqlite-properties
                #:dmx-sqlite-object-properties
                #:dmx-sqlite-query-runs
                #:dmx-sqlite-query-run
                #:dmx-sqlite-journal-entries
                #:dmx-sqlite-sync-identities-for-remote
                #:dmx-sqlite-sync-workflow-summary
                #:dmx-sqlite-integrity-report
                #:materialize-durable-notes-into-production-db
                #:durable-note-materialization-status
                #:dmx-materialized-learning-topics
                #:dmx-sql-association-has-role-bearing-players-p
                #:dmx-sql-counts)
  (:export #:run-dmx-sqlite-smoke-tests))
