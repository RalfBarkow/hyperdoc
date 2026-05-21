;;;; Package definition for the canonical Kioskberrli subsystem
;;
;;;; Copyright (c) 2026

(defpackage :kioskberrli
  (:use :cl)
  (:nicknames :dreyeck/kioskbeerli :kioskbeerli)
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
   #:scxml-event-of
   #:scxml-state-of
   #:note-of
   #:path-of
   #:kind-of
   #:plan-run-of

   ;; Dashboard objects.
   #:kioskberrli-dashboard-status
   #:kioskberrli-topic-dashboard
   #:kioskberrli-dashboard
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
   #:kioskberrli-plan-task
   #:kioskberrli-plan-run
   #:kioskberrli-task-state-link
   #:kioskberrli-plan-task-ids
   #:kioskbeerli-plan-task
   #:kioskbeerli-plan-run
   #:kioskbeerli-planner-run
   #:kioskberrli-planner-run
   #:kioskbeerli-plan-task-ids
   #:kioskbeerli-lookup-plan-task
   #:kioskberrli-lookup-plan-task
   #:kioskbeerli-task-plan
   #:kioskberrli-task-plan
   #:kioskbeerli-task-progress
   #:kioskberrli-task-progress
   #:kioskbeerli-task-state-link
   #:kioskberrli-task-state-link
   #:kioskbeerli-task-dependents
   #:kioskberrli-task-dependents
   #:kioskbeerli-current-scxml-state
   #:kioskberrli-current-scxml-state
   #:kioskbeerli-next-missing-evidence-tasks
   #:kioskberrli-next-missing-evidence-tasks
   #:kioskbeerli-record-boot-observed
   #:kioskberrli-record-boot-observed
   #:execution-mode-of
   #:dry-run-p
   #:planner-kind-of
   #:preconditions-of
   #:effects-of

   ;; Behavior chart.
   #:kioskbeerli-behavior-chart
   #:kioskberrli-behavior-chart
   #:kioskbeerli-behavior-scxml-pathname
   #:kioskberrli-behavior-scxml-pathname
   #:kioskbeerli-behavior-state-ids
   #:kioskberrli-behavior-state-ids
   #:kioskbeerli-behavior-events
   #:kioskberrli-behavior-events

   ;; Trace.
   #:kioskberrli-project-trace
   #:kioskberrli-trace-entry
   #:kioskberrli-evidence-reference
   #:kioskberrli-trace-status-vocabulary
   #:kioskbeerli-project-trace
   #:kioskbeerli-trace-entry
   #:kioskbeerli-evidence-reference
   #:kioskbeerli-trace-status-vocabulary
   #:kioskbeerli-latest-progress
   #:record-kioskbeerli-progress
   #:kioskberrli-latest-progress
   #:record-kioskberrli-progress
   #:record-trace-event
   #:evidence-references-of

   ;; FedWiki asset materialization.
   #:kioskberrli-fedwiki-asset-manifest
   #:asset-root-of
   #:page-slug-of
   #:page-url-of
   #:asset-url-prefix-of
   #:asset-files-of
   #:make-kioskberrli-fedwiki-asset-spec
   #:materialize-fedwiki-assets

   ;; Optional SQLite store.
   #:kioskberrli-sqlite-store
   #:kioskberrli-sqlite-unavailable
   #:sqlite-unavailable-program-of
   #:sqlite-unavailable-detail-of
   #:sqlite-store-db-path-of
   #:sqlite-store-program-of
   #:sqlite-store-schema-status-of
   #:sqlite-available-p
   #:open-or-create-sqlite-store
   #:ensure-sqlite-schema
   #:persist-dashboard-snapshot
   #:persist-plan
   #:persist-task
   #:persist-trace-event

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
   #:make-demo-dashboard
   #:make-demo-plan
   #:make-demo-trace
   #:inspect-demo-dashboard
   #:kioskbeerli-dashboard-example
   #:kioskbeerli-plan-only-example
   #:kioskbeerli-scxml-example
   #:kioskbeerli-record-progress-example

   ;; DITA-style task topics.
   #:kioskbeerli-dita-task-topic
   #:kioskbeerli-dita-task-step
   #:kioskbeerli-dita-task-view
   #:kioskbeerli-semi-headless-set-password-task
   #:kioskbeerli-lookup-task-topic
   #:kioskbeerli-task-topic-plan-task
   #:kioskbeerli-task-topic-prerequisite-plan-task
   #:kioskbeerli-task-topic-progress
   #:kioskbeerli-task-topic-state-link
   #:kioskbeerli-task-topic-dita-view
   #:kioskbeerli-open-semi-headless-password-task-inspector
   #:kioskberrli-semi-headless-set-password-task
   #:kioskberrli-lookup-task-topic
   #:kioskberrli-task-topic-plan-task
   #:kioskberrli-task-topic-progress
   #:kioskberrli-task-topic-state-link
   #:kioskberrli-task-topic-dita-view
   #:kioskberrli-open-semi-headless-password-task-inspector))

(in-package :kioskberrli)

(trivial-package-local-nicknames:add-package-local-nickname
 :views :html-inspector-views :kioskberrli)
