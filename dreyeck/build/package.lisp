;;;; Dreyeck build/check task package.

(defpackage #:dreyeck/build
  (:use #:cl)
  (:import-from #:dreyeck.dmx.sqlite
                #:*dreyeck-dmx-production-db-path*
                #:durable-note-materialization-status
                #:dmx-materialized-learning-topics
                #:materialize-durable-notes-into-production-db)
  (:export #:make-build-session
           #:plan-build-task
           #:check-build-task
           #:perform-build-task
           #:build-session-status
           #:build-session-next-action
           #:list-build-tasks
           #:run-build-task))
