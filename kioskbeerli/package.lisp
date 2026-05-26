;;;; Package definition for the canonical Kioskbeerli subsystem
;;
;;;; Copyright (c) 2026

(defpackage :kioskbeerli
  (:use :cl)
  (:nicknames :dreyeck/kioskbeerli)
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
   #:kioskbeerli-dashboard-status
   #:kioskbeerli-topic-dashboard
   #:kioskbeerli-dashboard
   #:kioskbeerli-dashboard-status-vocabulary
   #:kioskbeerli-dashboard-stations
   #:kioskbeerli-current-blocker
   #:kioskbeerli-build-evidence-status
   #:kioskbeerli-flash-boot-evidence-status
   #:kioskbeerli-public-display-layout-status
   #:kioskbeerli-dashboard
   #:kioskbeerli-dashboard-status
   #:kioskbeerli-dashboard-status-vocabulary
   #:kioskbeerli-dashboard-stations
   #:kioskbeerli-current-blocker
   #:kioskbeerli-build-evidence-status

   ;; Topic factories.
   #:kioskbeerli-topic
   #:kioskbeerli-dashboard-topic
   #:kioskbeerli-sdimage-imagesize-failure-topic
   #:kioskbeerli-cross-host-build-failure-topic
   #:salon-pi-4-kiosk-hardening-checklist-topic
   #:kioskbeerli-preconfigured-headless-image-topic
   #:runbook-build-and-flash-sd-image-topic
   #:preflight-rpi-sd-image-checklist-topic
   #:official-rpi-sd-image-tutorial-topic
   #:two-installation-models-topic
   #:invariant-boot-partition-must-be-big-enough-topic
   #:prepare-aarch64-image-topic
   #:hauptsache-entry-model-topic
   #:kioskbeerli-planner-and-trace-topic

   ;; Planner.
   #:kioskbeerli-plan-task
   #:kioskbeerli-plan-run
   #:kioskbeerli-task-state-link
   #:kioskbeerli-plan-task-ids
   #:kioskbeerli-plan-task
   #:kioskbeerli-plan-run
   #:kioskbeerli-planner-run
   #:kioskbeerli-planner-run
   #:kioskbeerli-plan-task-ids
   #:kioskbeerli-lookup-plan-task
   #:kioskbeerli-lookup-plan-task
   #:kioskbeerli-task-plan
   #:kioskbeerli-task-plan
   #:kioskbeerli-task-progress
   #:kioskbeerli-task-progress
   #:kioskbeerli-task-state-link
   #:kioskbeerli-task-state-link
   #:kioskbeerli-task-dependents
   #:kioskbeerli-task-dependents
   #:kioskbeerli-current-scxml-state
   #:kioskbeerli-current-scxml-state
   #:kioskbeerli-next-missing-evidence-tasks
   #:kioskbeerli-next-missing-evidence-tasks
   #:kioskbeerli-record-boot-observed
   #:kioskbeerli-record-boot-observed
   #:execution-mode-of
   #:dry-run-p
   #:planner-kind-of
   #:preconditions-of
   #:effects-of

   ;; Behavior chart.
   #:kioskbeerli-behavior-chart
   #:kioskbeerli-behavior-chart
   #:kioskbeerli-behavior-scxml-pathname
   #:kioskbeerli-behavior-scxml-pathname
   #:kioskbeerli-behavior-state-ids
   #:kioskbeerli-behavior-state-ids
   #:kioskbeerli-behavior-events
   #:kioskbeerli-behavior-events

   ;; Trace.
   #:kioskbeerli-project-trace
   #:kioskbeerli-trace-entry
   #:kioskbeerli-evidence-reference
   #:kioskbeerli-trace-status-vocabulary
   #:kioskbeerli-project-trace
   #:kioskbeerli-trace-entry
   #:kioskbeerli-evidence-reference
   #:kioskbeerli-trace-status-vocabulary
   #:kioskbeerli-latest-progress
   #:record-kioskbeerli-progress
   #:kioskbeerli-latest-progress
   #:record-kioskbeerli-progress
   #:kioskbeerli-den-dendritic-nix-learning-checkpoint
   #:record-trace-event
   #:evidence-references-of

   ;; FedWiki asset materialization.
   #:kioskbeerli-fedwiki-asset-manifest
   #:asset-root-of
   #:page-slug-of
   #:page-url-of
   #:asset-url-prefix-of
   #:asset-files-of
   #:make-kioskbeerli-fedwiki-asset-spec
   #:materialize-fedwiki-assets

   ;; Optional SQLite store.
   #:kioskbeerli-sqlite-store
   #:kioskbeerli-sqlite-unavailable
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
   #:kioskbeerli-option-existence-evidence
   #:kioskbeerli-sd-image-failure-context
   #:kioskbeerli-patch-suggestion
   #:kioskbeerli-build-command
   #:kioskbeerli-correction-path
   #:kioskbeerli-flake-lock-pathname
   #:kioskbeerli-nixpkgs-lock-object
   #:kioskbeerli-sd-image-module-reference
   #:kioskbeerli-sd-image-module-references
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
   #:kioskbeerli-semi-headless-set-password-task
   #:kioskbeerli-lookup-task-topic
   #:kioskbeerli-task-topic-plan-task
   #:kioskbeerli-task-topic-progress
   #:kioskbeerli-task-topic-state-link
   #:kioskbeerli-task-topic-dita-view
   #:kioskbeerli-open-semi-headless-password-task-inspector))

(in-package :kioskbeerli)

(trivial-package-local-nicknames:add-package-local-nickname
 :views :html-inspector-views :kioskbeerli)
