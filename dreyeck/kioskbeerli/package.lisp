;;;; Package definition for the Kioskberrli dreyeck subsystem
;;
;;;; Copyright (c) 2026

(defpackage :dreyeck/kioskbeerli
  (:use :cl)
  (:import-from :hyperdoc
                #:defexample)
  (:export
   ;; Shared accessors.
   #:id-of
   #:title-of
   #:summary-of
   #:status-of
   #:evidence-paths-of
   #:dependencies-of
   #:tasks-of
   #:entries-of
   #:timestamp-of
   #:actor-of
   #:task-id-of
   #:from-state-of
   #:to-state-of
   #:note-of
   #:path-of
   #:kind-of

   ;; Dashboard objects.
   #:kioskberrli-dashboard-status
   #:kioskberrli-topic-dashboard
   #:kioskberrli-dashboard
   #:kioskberrli-dashboard-status
   #:kioskberrli-dashboard-status-vocabulary
   #:kioskberrli-dashboard-stations
   #:kioskberrli-current-blocker
   #:kioskberrli-build-evidence-status
   #:kioskberrli-flash-boot-evidence-status
   #:kioskberrli-public-display-layout-status
   #:kioskbeerli-dashboard
   #:kioskbeerli-dashboard-status
   #:kioskbeerli-dashboard-status-vocabulary
   #:kioskbeerli-dashboard-stations
   #:kioskbeerli-current-blocker
   #:kioskbeerli-build-evidence-status

   ;; Topic factories.
   #:kioskberrli-topic
   #:kioskberrli-dashboard-topic
   #:kioskberrli-sdimage-imagesize-failure-topic
   #:kioskberrli-cross-host-build-failure-topic
   #:salon-pi-4-kiosk-hardening-checklist-topic
   #:kioskberrli-preconfigured-headless-image-topic
   #:runbook-build-and-flash-sd-image-topic
   #:preflight-rpi-sd-image-checklist-topic
   #:official-rpi-sd-image-tutorial-topic
   #:two-installation-models-topic
   #:invariant-boot-partition-must-be-big-enough-topic
   #:prepare-aarch64-image-topic
   #:hauptsache-entry-model-topic
   #:kioskberrli-planner-and-trace-topic

   ;; Planner.
   #:kioskbeerli-plan-task
   #:kioskbeerli-plan-run
   #:kioskbeerli-planner-run
   #:kioskberrli-planner-run
   #:kioskbeerli-plan-task-ids
   #:execution-mode-of
   #:dry-run-p
   #:planner-kind-of
   #:preconditions-of
   #:effects-of

   ;; Behavior chart.
   #:kioskbeerli-behavior-chart
   #:kioskberrli-behavior-chart
   #:kioskbeerli-behavior-scxml-pathname
   #:kioskbeerli-behavior-state-ids
   #:kioskbeerli-behavior-events

   ;; Trace.
   #:kioskbeerli-project-trace
   #:kioskbeerli-trace-entry
   #:kioskbeerli-evidence-reference
   #:kioskbeerli-trace-status-vocabulary
   #:kioskbeerli-latest-progress
   #:record-kioskbeerli-progress
   #:kioskberrli-project-trace
   #:kioskberrli-latest-progress
   #:record-kioskberrli-progress
   #:evidence-references-of

   ;; sdImage failure reference objects.
   #:kioskberrli-option-existence-evidence
   #:kioskberrli-sd-image-failure-context
   #:kioskberrli-patch-suggestion
   #:kioskberrli-build-command
   #:kioskberrli-correction-path
   #:kioskberrli-flake-lock-pathname
   #:kioskberrli-nixpkgs-lock-object
   #:kioskberrli-sd-image-module-reference
   #:kioskberrli-sd-image-module-references
   #:kioskbeerli-option-exists?
   #:kioskbeerli-suggested-patch
   #:kioskbeerli-repro-build-command
   #:kioskbeerli-correction-path

   ;; Examples.
   #:kioskbeerli-dashboard-example
   #:kioskbeerli-plan-only-example
   #:kioskbeerli-scxml-example
   #:kioskbeerli-record-progress-example))

(in-package :dreyeck/kioskbeerli)
