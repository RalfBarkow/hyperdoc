;;;; Shared S-expression plan data for executable DITA tasks.
;;;;
;;;; This file intentionally treats PDDL/SHOP3-shaped content as data.  It
;;;; does not load SHOP3 and does not execute planner operators.

(in-package :hyperdoc)

(defparameter *executable-dita-default-sqlite-path*
  #P"/Users/rgb/workspace/hyperdoc/var/shared-sexpression-plans.sqlite")

(defparameter *executable-dita-pddl-domain*
  '(:pddl-domain "hyperdoc-maintenance"
    (:predicates
     ("repo-visible" "?repo")
     ("asdf-system-visible" "?system")
     ("sqlite-db-visible" "?db")
     ("task-object-defined" "?task")
     ("projection-emitted" "?task" "?projection")
     ("smoke-test-passed" "?test")
     ("evidence-recorded" "?task"))
    (:operators
     ((:operator "define-executable-dita-task-object"
       :preconditions (("repo-visible" "hyperdoc"))
       :effects (("task-object-defined" "executable-dita-task")))
      (:operator "emit-dita-projection"
       :preconditions (("task-object-defined" "executable-dita-task"))
       :effects (("projection-emitted" "executable-dita-task" "dita")))
      (:operator "emit-hyperdoc-html-projection"
       :preconditions (("task-object-defined" "executable-dita-task"))
       :effects (("projection-emitted" "executable-dita-task" "hyperdoc-html")))
      (:operator "emit-scxml-projection"
       :preconditions (("task-object-defined" "executable-dita-task"))
       :effects (("projection-emitted" "executable-dita-task" "scxml")))
      (:operator "persist-task-to-sqlite"
       :preconditions (("task-object-defined" "executable-dita-task")
                       ("sqlite-db-visible" "shared-sexpression-plans.sqlite"))
       :effects (("evidence-recorded" "executable-dita-task")))
      (:operator "run-smoke-test"
       :preconditions (("projection-emitted" "executable-dita-task" "dita")
                       ("projection-emitted" "executable-dita-task" "hyperdoc-html")
                       ("projection-emitted" "executable-dita-task" "scxml"))
       :effects (("smoke-test-passed" "executable-dita-tasks-smoke")))))))

(defparameter *executable-dita-default-scxml-contract*
  '(:initial "specified"
    :states ("specified" "planned" "implemented" "tested" "recorded" "blocked")
    :transitions
    ((:state "specified"
      :event "PLAN_LOOKUP_READY"
      :target "planned")
     (:state "planned"
      :event "CODEX_IMPLEMENTED_SLICE"
      :target "implemented")
     (:state "planned"
      :event "MISSING_RUNTIME_DEPENDENCY"
      :target "blocked")
     (:state "planned"
      :event "WRONG_PROJECT_ROOT"
      :target "blocked")
     (:state "implemented"
      :event "SMOKE_TEST_PASSED"
      :target "tested")
     (:state "implemented"
      :event "SMOKE_TEST_FAILED"
      :target "blocked")
     (:state "tested"
      :event "EVIDENCE_RECORDED"
      :target "recorded")
     (:state "blocked"
      :event "REPAIR_APPLIED"
      :target "planned"))
    :final-states ("recorded")))

(defun executable-dita-default-sqlite-path ()
  *executable-dita-default-sqlite-path*)

(defun executable-dita-default-pddl-domain ()
  *executable-dita-pddl-domain*)

(defun executable-dita-default-scxml-contract ()
  *executable-dita-default-scxml-contract*)

(defun executable-dita-next-task-score
    (&key cost risk expected-value &allow-other-keys)
  (- (/ (or expected-value 0.0d0)
        (max (or cost 0.0d0) 1.0d0))
     (or risk 0.0d0)))
