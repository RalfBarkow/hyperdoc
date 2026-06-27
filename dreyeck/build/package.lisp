;;;; Dreyeck build/check task package.

(defpackage #:dreyeck/build
  (:use #:cl)
  (:import-from #:dreyeck.dmx.sqlite
                #:*dreyeck-dmx-production-db-path*
                #:durable-note-materialization-status
                #:dmx-materialized-learning-topics
                #:materialize-durable-notes-into-production-db)
  (:export #:list-build-tasks
           #:run-build-task))
