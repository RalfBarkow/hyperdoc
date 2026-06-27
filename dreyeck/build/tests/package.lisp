;;;; Tests for Dreyeck build/check tasks.

(defpackage #:dreyeck/build/tests
  (:use #:cl)
  (:import-from #:dreyeck/build
                #:make-build-session
                #:plan-build-task
                #:check-build-task
                #:perform-build-task
                #:build-session-status
                #:build-session-next-action
                #:build-session-next-action-route
                #:build-referee-decision-route
                #:build-referee-decision-route-candidate-actions-of
                #:build-referee-decision-route-selected-task-of
                #:build-referee-decision-route-selected-action-of
                #:build-referee-decision-route-decoded-operation-of
                #:build-referee-decision-route-up-to-date-before-session-p-of
                #:build-referee-decision-route-needed-in-session-p-of
                #:build-referee-decision-route-done-in-session-p-of
                #:build-referee-decision-route-safe-to-perform-p-of
                #:build-referee-decision-route-perform-entry-point-of
                #:list-build-tasks
                #:run-build-task)
  (:export #:run-dreyeck-build-smoke-tests))
