;;;; Public API for the Dreyeck-owned DMX SQLite workspace selection.

(defpackage #:dreyeck.dmx.workspace-selection
  (:use #:common-lisp #:shop3)
  (:export
   #:*shop3-find-plans-call-count*
   #:select-dmx-sqlite-workspace-with-shop3
   #:inspect-dmx-sqlite-workspace-selection
   #:dmx-sqlite-workspace-plan-action-p))

(in-package #:dreyeck.dmx.workspace-selection)
