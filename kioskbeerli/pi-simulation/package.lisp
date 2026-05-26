;;;; Package definition for the Kioskbeerli Pi simulation planning subsystem.

(defpackage :kioskbeerli/pi-simulation
  (:use :cl)
  (:export
   ;; Classes.
   #:pi-simulation-plan
   #:pi-simulation-plan-task
   #:pi-simulation-session
   #:pi-simulation-fidelity-level
   #:pi-simulation-command-spec
   #:pi-simulation-topic
   #:pi-simulation-topic-bundle
   #:pi-simulation-task-state-link

   ;; Shared accessors.
   #:id-of
   #:title-of
   #:summary-of
   #:level-of
   #:levels-of
   #:dependencies-of
   #:preconditions-of
   #:effects-of
   #:status-of
   #:evidence-of
   #:execution-mode-of
   #:dry-run-p
   #:tasks-of
   #:command-specs-of
   #:task-id-of
   #:state-id-of
   #:scxml-event-of
   #:scxml-state-of
   #:argv-of
   #:command-text-of
   #:working-directory-of
   #:mutates-p
   #:executed-p
   #:safety-boundary-of
   #:category-of
   #:references-of
   #:plan-of
   #:chart-of
   #:topic-bundle-of
   #:next-actions-of
   #:boot-status-of
   #:backend-of
   #:reason-of

   ;; Public API.
   #:make-pi-simulation-plan
   #:make-pi-simulation-session
   #:pi-simulation-scxml-pathname
   #:pi-simulation-scxml-chart
   #:pi-simulation-command-specs
   #:pi-simulation-next-actions
   #:pi-simulation-shop3-plan-result
   #:pi-simulation-shop3-plan-steps
   #:inspect-pi-simulation-plan

   ;; Test/inspection helpers.
   #:pi-simulation-fidelity-levels
   #:pi-simulation-plan-task-ids
   #:pi-simulation-blocked-state-ids
   #:pi-simulation-scxml-state-ids
   #:pi-simulation-task-state-links
   #:pi-simulation-topic-bundle
   #:pi-simulation-vm-boot-status
   #:pi-simulation-lookup-plan-task))

(in-package :kioskbeerli/pi-simulation)
