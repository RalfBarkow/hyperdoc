(defpackage #:dreyeck.dmx.sqlite/tests
  (:use #:cl)
  (:import-from #:dreyeck.dmx.sqlite
                #:initialize-dmx-associative-mirror
                #:record-dmx-topic-value
                #:record-dmx-association-value
                #:record-dmx-sync-identity-value
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
                #:dmx-sqlite-integrity-report
                #:dmx-sql-association-has-role-bearing-players-p
                #:dmx-sql-counts)
  (:export #:run-dmx-sqlite-smoke-tests))
