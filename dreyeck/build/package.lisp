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
           #:build-session-next-action-route
           #:build-referee-decision-route
           #:build-referee-decision-route-id-of
           #:build-referee-decision-route-title-of
           #:build-referee-decision-route-summary-of
           #:build-referee-decision-route-session-id-of
           #:build-referee-decision-route-requested-goal-of
           #:build-referee-decision-route-candidate-actions-of
           #:build-referee-decision-route-selected-task-of
           #:build-referee-decision-route-selected-action-of
           #:build-referee-decision-route-decoded-operation-of
           #:build-referee-decision-route-dependencies-of
           #:build-referee-decision-route-up-to-date-before-session-p-of
           #:build-referee-decision-route-needed-in-session-p-of
           #:build-referee-decision-route-done-in-session-p-of
           #:build-referee-decision-route-reason-of
           #:build-referee-decision-route-safe-to-perform-p-of
           #:build-referee-decision-route-safe-to-perform-reason-of
           #:build-referee-decision-route-perform-entry-point-of
           #:build-referee-decision-route-source-of
           #:build-referee-decision-route-referee-result-of
           #:build-referee-decision-route-session-status-of
           #:list-build-tasks
           #:run-build-task))
