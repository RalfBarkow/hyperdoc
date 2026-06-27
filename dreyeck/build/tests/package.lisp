;;;; Tests for Dreyeck build/check tasks.

(defpackage #:dreyeck/build/tests
  (:use #:cl)
  (:import-from #:dreyeck/build
                #:list-build-tasks
                #:run-build-task)
  (:export #:run-dreyeck-build-smoke-tests))
