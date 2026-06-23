;;;; Public API for the Dreyeck-owned DMX SQLite workspace selection.

(defpackage #:dreyeck.dmx.workspace-selection
  (:use #:common-lisp #:shop3)
  (:export
   #:*shop3-find-plans-call-count*
   #:select-dmx-sqlite-workspace-with-shop3
   #:select-dmx-sqlite-next-task-with-shop3
   #:select-dmx-sqlite-first-consumer-with-shop3
   #:inspect-dmx-sqlite-workspace-selection
   #:inspect-dmx-sqlite-next-task-selection
   #:dmx-sqlite-workspace-plan-action-p
   #:dmx-sqlite-next-task-plan-action-p))

(in-package #:dreyeck.dmx.workspace-selection)
