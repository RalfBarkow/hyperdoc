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
                #:list-build-tasks
                #:run-build-task)
  (:export #:run-dreyeck-build-smoke-tests))
