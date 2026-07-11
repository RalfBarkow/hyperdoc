(:artifact
 (:id materialize-build-referee-learning-topics)
 (:title "Materialize Build Referee Learning Topics")
 (:type :shop3-plan)
 (:status :seed-or-projection-for-dmx-persistence)
 (:created-for-slice "feat(dmx): materialize build referee learning topics")
 (:repo-root "/Users/rgb/workspace/hyperdoc")
 (:production-store dreyeck-dmx-sqlite-production-db)
 (:plan-topic materialize-build-referee-learning-topics)

 :knowledge
 ((core-rule
   ((codex reader-and-display-surface)
    (dreyeck-build owns-next-admissible-action)
    (lisp-referee-form selects-and-decodes-next-action)
    (dmx-store persists-learned-topics-and-associations)
    (durable-note-materializer is-single-materialization-path)))
  (idempotence-rule
   ((first-replay inserts-or-updates-required-seeds)
    (second-replay reports-unchanged)
    (materialization does-not-duplicate-topics-or-associations)))
  (validation-authority
   ((validate-dmx-learning-topics must-pass)
    (build-referee-route reports-no-missing-learning-topics)
    (build-referee-route reports-no-missing-learning-associations))))

 :input
 ((production-db
   "/Users/rgb/workspace/hyperdoc/var/dmx-associative-mirror.sqlite")
  (current-materializer
   ("dreyeck/dmx/sqlite/durable-notes.lisp"
    "dreyeck/dmx/sqlite/store.lisp"
    "dreyeck/dmx/sqlite/tests/smoke.lisp"))
  (build-referee-source
   ("dreyeck/build/tasks.lisp"
    "hyperdoc/add-plan-then-perform-session-state-to-dreyeck-build-plan.sexp"
    "hyperdoc/render-build-referee-decisions-as-routes-plan.sexp"))
  (missing-required-topics
   (add-plan-then-perform-session-state-to-dreyeck-build
    render-build-referee-decisions-as-routes
    plan-then-perform-build-session
    build-referee-decision-route
    lisp-referee-form
    dreyeck/build:build-session-next-action
    asdf-3-3-session-action-model
    domkin-2017))
  (missing-required-associations
   ((plan-then-perform-build-session refines codex-is-not-the-build-system)
    (plan-then-perform-build-session supports reusable-common-lisp-build-tasks-for-codex)
    (plan-then-perform-build-session inspired-by asdf-3-3-session-action-model)
    (asdf-3-3-session-action-model described-by domkin-2017)
    (build-referee-decision-route renders lisp-referee-form)
    (build-referee-decision-route explains plan-then-perform-build-session)
    (build-referee-decision-route supports codex-is-not-the-build-system)
    (build-referee-decision-route inspects dreyeck/build:build-session-next-action))))

 :shop3
 ((:task materialize-build-referee-learning-topics
   :goal
   ((dmx-topic add-plan-then-perform-session-state-to-dreyeck-build)
    (dmx-topic render-build-referee-decisions-as-routes)
    (dmx-topic plan-then-perform-build-session)
    (dmx-topic build-referee-decision-route)
    (dmx-topic lisp-referee-form)
    (dmx-topic dreyeck/build:build-session-next-action)
    (dmx-topic asdf-3-3-session-action-model)
    (dmx-topic domkin-2017)
    (dmx-associations build-referee-learning-associations)
    (validate-dmx-learning-topics passes)
    (materializer-replay idempotent)))

  (:operator inspect-current-materializer
   :preconditions ((system-exists :dreyeck/dmx/sqlite))
   :effects ((known durable-note-materializer)
             (known required-learning-topics)
             (known missing-learning-topics)
             (known missing-learning-associations)))

  (:operator add-build-referee-learning-topic-seeds
   :preconditions ((known durable-note-materializer))
   :effects ((materializer-knows add-plan-then-perform-session-state-to-dreyeck-build)
             (materializer-knows render-build-referee-decisions-as-routes)
             (materializer-knows plan-then-perform-build-session)
             (materializer-knows build-referee-decision-route)
             (materializer-knows lisp-referee-form)
             (materializer-knows dreyeck/build:build-session-next-action)
             (materializer-knows asdf-3-3-session-action-model)
             (materializer-knows domkin-2017)))

  (:operator add-build-referee-learning-associations
   :preconditions ((materializer-knows build-referee-learning-topics))
   :effects ((materializer-knows plan-then-perform-build-session-relations)
             (materializer-knows build-referee-decision-route-relations)
             (materializer-knows asdf-3-3-source-relation)))

  (:operator validate-build-referee-learning-materialization
   :preconditions ((materializer-updated))
   :effects ((validation-passed validate-dmx-learning-topics)
             (build-referee-route reports-no-missing-required-topics)
             (build-referee-route reports-no-missing-required-associations)
             (second-replay unchanged))))

 :output-contract
 ((materializer
   (extends-existing "dreyeck.dmx.sqlite:materialize-durable-notes-into-production-db"))
  (required-topic-seeds
   (add-plan-then-perform-session-state-to-dreyeck-build
    render-build-referee-decisions-as-routes
    plan-then-perform-build-session
    build-referee-decision-route
    lisp-referee-form
    dreyeck/build:build-session-next-action
    asdf-3-3-session-action-model
    domkin-2017))
  (required-association-seeds
   ((assoc:plan-then-perform-build-session:refines:codex-is-not-the-build-system)
    (assoc:plan-then-perform-build-session:supports:reusable-common-lisp-build-tasks-for-codex)
    (assoc:plan-then-perform-build-session:inspired-by:asdf-3-3-session-action-model)
    (assoc:asdf-3-3-session-action-model:described-by:domkin-2017)
    (assoc:build-referee-decision-route:renders:lisp-referee-form)
    (assoc:build-referee-decision-route:explains:plan-then-perform-build-session)
    (assoc:build-referee-decision-route:supports:codex-is-not-the-build-system)
    (assoc:build-referee-decision-route:inspects:dreyeck/build:build-session-next-action)))
  (validation
   ((shop3-plan-artifact-exists
     "dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp")
    (first-production-replay-materializes-required-seeds t)
    (second-production-replay-idempotent t)
    (validate-dmx-learning-topics-passed t)
    (build-referee-route-missing-required-topics nil)
    (build-referee-route-missing-required-associations nil)
    (dreyeck-dmx-sqlite-smoke-tests-pass t)
    (dreyeck-build-tests-pass t)
    (explorer-systems-load t)
    (git-diff-check-passes t)))))
