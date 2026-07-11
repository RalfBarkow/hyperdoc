(:artifact
 (:id add-plan-then-perform-session-state-to-dreyeck-build)
 (:title "Add Plan-Then-Perform Session State to Dreyeck Build")
 (:type :shop3-plan)
 (:status :seed-or-projection-for-later-dmx-persistence)
 (:created-for-slice "refactor(build): add plan-then-perform session state")
 (:repo-root "/Users/rgb/workspace/hyperdoc")
 (:production-store dreyeck-dmx-sqlite-production-db)
 (:plan-topic add-plan-then-perform-session-state-to-dreyeck-build)

 :knowledge
 ((source-idea
   ((author "DOMKIN, Vsevolod")
    (year 2017)
    (title "Loading Multiple Versions of an ASDF System in the Same Lisp Image")
    (lesson "ASDF 3.3 separates action planning, validity checking, and performing inside a session.")))
  (core-rule
   ((codex is-not build-system)
    (codex plans-inspects-explains-and-chooses-next-moves)
    (dreyeck-build plans-checks-performs-and-records-deterministic-task-state)))
  (action-status-dimensions
   ((up-to-date-before-session independent)
    (needed-in-session independent)
    (done-in-session independent)))
  (constraints
   ((status-checks-do-not-mutate)
    (inspection-does-not-perform-unneeded-actions)
    (perform-mode-runs-only-needed-actions)
    (referee-role implemented-as-inspectable-common-lisp-form)
    (codex-displays-referee-result-but-does-not-decide-next-move)
    (existing-run-build-task-remains-compatibility-api))))

 :input
 ((previous-slice
   ("fbe19796" "feat(codex): inspect DMX materialized learning topics"))
  (existing-build-tasks
   (:dmx-durable-note-materialization-status
    :inspect-dmx-learning-topics
    :validate-dmx-learning-topics))
  (existing-codex-entry-points
   ("dreyeck/codex:codex-dmx-learning-topics"
    "dreyeck/codex:codex-dmx-learning-topic-status"))
  (target-apis
   ("dreyeck/build:make-build-session"
    "dreyeck/build:plan-build-task"
    "dreyeck/build:check-build-task"
    "dreyeck/build:perform-build-task"
    "dreyeck/build:build-session-status"
    "dreyeck/build:build-session-next-action"
    "dreyeck/build:run-build-task")))

 :shop3
 ((:task add-plan-then-perform-session-state-to-dreyeck-build
   :goal
   ((dreyeck-build supports plan-then-perform-session)
    (build-action tracks up-to-date-before-session)
    (build-action tracks needed-in-session)
    (build-action tracks done-in-session)
    (inspection-does-not-perform-unneeded-actions)
    (status-checks-do-not-mutate)
    (perform-mode-runs-only-needed-actions)
    (referee-selects next-admissible-action)
    (session-records action-state)
    (learned-pattern persisted-as-topic)))

  (:operator inspect-existing-dreyeck-build-layer
   :preconditions ((system-exists :dreyeck/build))
   :effects ((known build-task-registry)
             (known existing-task-return-shape)
             (known current-codex-call-sites)
             (known validation-tests)))

  (:operator define-build-session-model
   :preconditions ((known build-task-registry))
   :effects ((build-session available)
             (build-action-state available)
             (action-status-dimensions up-to-date-before-session
                                       needed-in-session
                                       done-in-session)))

  (:operator separate-plan-check-perform
   :preconditions ((build-session available))
   :effects ((plan-build-task available)
             (check-build-task available)
             (perform-build-task available)
             (status-traversal non-mutating)))

  (:operator define-build-referee-form
   :preconditions ((build-session available)
                   (status-traversal non-mutating))
   :effects ((build-session-next-action available)
             (referee-result inspectable-common-lisp-data)
             (next-move-decision represented-in-lisp)))

  (:operator migrate-existing-build-tasks
   :preconditions ((known existing-build-tasks)
                   (build-session-next-action available))
   :effects ((existing-build-tasks wrapped-in-session-model)
             (codex-surfaces use-session-api)
             (compatibility preserved)))

  (:operator validate-plan-then-perform-session
   :preconditions ((build-session available)
                   (existing-build-tasks migrated))
   :effects ((validation-passed plan-then-perform-build-session))))

 :output-contract
 ((new-build-session-apis
   ("dreyeck/build:make-build-session"
    "dreyeck/build:plan-build-task"
    "dreyeck/build:check-build-task"
    "dreyeck/build:perform-build-task"
    "dreyeck/build:build-session-status"
    "dreyeck/build:build-session-next-action"))
  (preserved-compatibility-api
   ("dreyeck/build:run-build-task"))
  (learned-topic
   (plan-then-perform-build-session
    :title "Plan-Then-Perform Build Session"
    :type :learned-build-pattern))
  (required-associations
   ((plan-then-perform-build-session refines
     codex-is-not-the-build-system)
    (plan-then-perform-build-session supports
     reusable-common-lisp-build-tasks-for-codex)
    (plan-then-perform-build-session inspired-by
     asdf-3-3-session-action-model)
    (asdf-3-3-session-action-model described-by
     domkin-2017)))
  (validation
   ((shop3-plan-artifact-exists
     "dreyeck/build/add-plan-then-perform-session-state-to-dreyeck-build-plan.sexp")
    (session-can-be-created t)
    (plan-records-needed-state-without-performing t)
    (check-status-does-not-mutate t)
    (perform-marks-needed-task-done t)
    (same-session-second-perform-does-not-duplicate-work t)
    (referee-selects-next-admissible-action-as-lisp-data t)
    (codex-displays-referee-result-without-owning-decision t)
    (run-build-task-compatibility-preserved t)
    (codex-dmx-learning-topic-inspection-still-loads t)
    (materialization-status-passed t)
    (materializer-replay-idempotent t)
    (git-diff-check-passes t)))))
