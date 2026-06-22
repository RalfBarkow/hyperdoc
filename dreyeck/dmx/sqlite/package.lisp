;;;; Dreyeck-owned DMX-shaped SQLite store package.

(defpackage #:dreyeck.dmx.sqlite
  (:use #:cl)
  (:export
   #:*default-dmx-associative-mirror-path*
   #:initialize-dmx-associative-mirror
   #:sqlite-run
   #:record-dmx-topic-value
   #:record-dmx-association-value
   #:record-dmx-sync-identity-value
   #:sql-literal
   #:json-object
   #:dmx-sql-scalar
   #:dmx-sql-object-row
   #:dmx-sql-object-exists-p
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
   #:normalize-dmx-association-players
   #:topic-association-players
   #:dmx-sql-association-has-role-bearing-players-p
   #:dmx-sql-relationship-p
   #:dmx-sql-counts))
