;;;; Package definition for the Kioskbeerli sops-nix secrets planning subsystem.

(defpackage :kioskbeerli/sops-nix-secrets
  (:use :cl)
  (:export
   ;; Classes.
   #:sops-nix-secrets-plan
   #:sops-nix-secrets-plan-task
   #:sops-nix-secrets-session
   #:sops-nix-secrets-command-spec
   #:sops-nix-secrets-task-state-link
   #:sops-nix-secrets-task-topic
   #:sops-nix-secrets-topic
   #:sops-nix-secrets-topic-bundle
   #:sops-nix-secrets-guard
   #:sops-nix-secrets-problem

   ;; Shared accessors.
   #:id-of
   #:title-of
   #:summary-of
   #:dependencies-of
   #:preconditions-of
   #:effects-of
   #:status-of
   #:evidence-of
   #:execution-mode-of
   #:dry-run-p
   #:tasks-of
   #:guards-of
   #:concepts-of
   #:failures-of
   #:recoveries-of
   #:command-specs-of
   #:task-id-of
   #:state-id-of
   #:blocked-state-id-of
   #:scxml-event-of
   #:scxml-state-of
   #:argv-of
   #:command-text-of
   #:working-directory-of
   #:requires-sudo-p
   #:mutates-p
   #:executed-p
   #:safety-boundary-of
   #:category-of
   #:references-of
   #:related-task-ids-of
   #:steps-of
   #:result-of
   #:postrequisites-of
   #:recovery-of
   #:chart-of
   #:plan-of
   #:topic-bundle-of
   #:next-actions-of

   ;; Public API.
   #:make-sops-nix-secrets-plan
   #:make-sops-nix-secrets-session
   #:sops-nix-secrets-scxml-pathname
   #:sops-nix-secrets-scxml-chart
   #:sops-nix-secrets-scxml-state-ids
   #:sops-nix-secrets-topic-bundle
   #:sops-nix-secrets-next-actions
   #:inspect-sops-nix-secrets-plan
   #:make-sops-nix-secrets-problem

   ;; Inspection helpers used by tests and MREPL work.
   #:sops-nix-secrets-plan-task-ids
   #:sops-nix-secrets-blocked-state-ids
   #:sops-nix-secrets-task-state-links
   #:sops-nix-secrets-lookup-plan-task
   #:sops-nix-secrets-command-specs
   #:sops-nix-secrets-task-topics
   #:sops-nix-secrets-concept-topics
   #:sops-nix-secrets-reference-topics
   #:sops-nix-secrets-guard-topics
   #:sops-nix-secrets-failure-topics
   #:sops-nix-secrets-recovery-topics))

(in-package :kioskbeerli/sops-nix-secrets)
