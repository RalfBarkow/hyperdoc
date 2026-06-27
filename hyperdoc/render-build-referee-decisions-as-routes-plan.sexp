(:artifact
 (:id render-build-referee-decisions-as-routes)
 (:title "Render Build Referee Decisions as Routes")
 (:type :shop3-plan)
 (:status :seed-or-projection-for-later-dmx-persistence)
 (:created-for-slice "feat(inspector): render build referee decisions as routes")
 (:repo-root "/Users/rgb/workspace/hyperdoc")
 (:production-store dreyeck-dmx-sqlite-production-db)
 (:plan-topic render-build-referee-decisions-as-routes)

 :knowledge
 ((core-rule
   ((codex is-not referee)
    (dreyeck-build owns-referee-selection)
    (build-session-next-action selects-next-admissible-action)
    (route-projection decodes-and-renders-referee-result)
    (codex-and-inspector display-route-without-owning-decision)))
  (route-language
   ((requested-goal station)
    (candidate-actions routes)
    (selected-action chosen-route)
    (perform-entry-point command-destination)
    (status-dimensions route-state)))
  (non-mutating-invariants
   ((route-rendering calls-plan-check-referee-only)
    (route-rendering never-calls perform-build-task)
    (safe-to-perform-p is-data-not-execution)
    (perform-requires explicit-perform-api))))

 :input
 ((previous-slice
   ("5b5bc025" "refactor(build): add plan-then-perform session state"))
  (authoritative-referee
   "dreyeck/build:build-session-next-action")
  (display-surfaces
   ("dreyeck/codex:codex-dmx-learning-topics"
    "dreyeck-explorer/codex.lisp"))
  (target-artifacts
   ("dreyeck/build:build-session-next-action-route"
    "dreyeck/codex:codex-build-referee-route"
    "build-referee-decision-route")))

 :shop3
 ((:task render-build-referee-decisions-as-routes
   :goal
   ((inspector-can-render build-referee-decision-route)
    (codex-can-display referee-result-without-owning-decision)
    (route-shows selected-action decoded-operation dependencies)
    (route-shows up-to-date needed done status)
    (route-shows reason safe-to-perform perform-entry-point)
    (learned-pattern persisted-as-topic)))

  (:operator inspect-existing-referee-result-shape
   :preconditions ((system-exists :dreyeck/build)
                   (function-exists dreyeck/build:build-session-next-action))
   :effects ((known referee-result-shape)
             (known build-session-status-shape)
             (known inspector-view-conventions)))

  (:operator define-referee-route-object
   :preconditions ((known referee-result-shape))
   :effects ((object build-referee-decision-route)
             (route-fields requested-goal candidate-actions selected-action decoded-operation)
             (route-fields dependencies needed done up-to-date reason safe-to-perform)))

  (:operator render-referee-route-in-inspector
   :preconditions ((object build-referee-decision-route))
   :effects ((inspector-view build-referee-decision-route)
             (codex-surface displays-referee-route)))

  (:operator integrate-route-with-codex-dmx-learning-surface
   :preconditions ((codex-surface dmx-learning-topics)
                   (object build-referee-decision-route))
   :effects ((codex-shows referee-result-as-route)
             (codex-does-not-select-next-action)))

  (:operator validate-referee-route-rendering
   :preconditions ((inspector-view build-referee-decision-route))
   :effects ((validation-passed referee-route-rendering))))

 :output-contract
 ((new-build-owned-route-api
   ("dreyeck/build:build-session-next-action-route"))
  (codex-display-api
   ("dreyeck/codex:codex-build-referee-route"))
  (route-object
   (build-referee-decision-route
    :required-fields
    (:session-id
     :requested-goal
     :candidate-actions
     :selected-action
     :decoded-operation
     :dependencies
     :up-to-date-before-session-p
     :needed-in-session-p
     :done-in-session-p
     :reason
     :safe-to-perform-p
     :perform-entry-point
     :source)))
  (learned-topic
   (build-referee-decision-route
    :title "Build Referee Decision Route"
    :type :learned-inspector-pattern))
  (required-associations
   ((build-referee-decision-route renders lisp-referee-form)
    (build-referee-decision-route explains plan-then-perform-build-session)
    (build-referee-decision-route supports codex-is-not-the-build-system)
    (build-referee-decision-route inspects dreyeck/build:build-session-next-action)))
  (validation
   ((shop3-plan-artifact-exists
     "hyperdoc/render-build-referee-decisions-as-routes-plan.sexp")
    (route-can-be-created-from-build-session t)
    (route-includes-selected-action-and-decoded-operation t)
    (route-includes-session-status-dimensions t)
    (route-creation-does-not-mark-action-done t)
    (explicit-perform-can-mark-action-done t)
    (codex-api-returns-route-as-structured-data t)
    (inspector-explorer-views-load t)
    (compatibility-wrappers-load t)
    (git-diff-check-passes t)))))
