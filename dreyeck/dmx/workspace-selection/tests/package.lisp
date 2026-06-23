;;;; Test package for the live Dreyeck DMX SQLite workspace selection.

(defpackage #:dreyeck.dmx.workspace-selection/tests
  (:use #:common-lisp)
  (:import-from #:dreyeck.dmx.workspace-selection
                #:*shop3-find-plans-call-count*
                #:select-dmx-sqlite-workspace-with-shop3
                #:select-dmx-sqlite-next-task-with-shop3
                #:dmx-sqlite-workspace-plan-action-p
                #:dmx-sqlite-next-task-plan-action-p)
  (:export #:run-workspace-selection-smoke-tests))

(in-package #:dreyeck.dmx.workspace-selection/tests)
