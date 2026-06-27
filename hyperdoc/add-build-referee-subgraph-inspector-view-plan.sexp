(:artifact
 (:id add-build-referee-subgraph-inspector-view)
 (:title "Add Build Referee Subgraph Inspector View")
 (:type :shop3-plan)
 (:status :seed-or-projection-for-dmx-persistence)
 (:created-for-slice "feat(inspector): add build referee DMX subgraph view")
 (:repo-root "/Users/rgb/workspace/hyperdoc")
 (:production-store dreyeck-dmx-sqlite-production-db)
 (:plan-topic add-build-referee-subgraph-inspector-view)

 :knowledge
 ((core-rule
   ((codex reader-and-display-surface)
    (dreyeck-codex owns project-specific-inspection-surface)
    (production-dmx-store contains build-referee-learning-subgraph)
    (inspector-view displays-proof-without-owning-referee-decision)))
  (view-contract
   ((tab-title "Build Referee Subgraph")
    (claim "Production DMX SQLite contains the build/referee learned topics.")
    (topic-count 8)
    (association-count 8)
    (missing-topic-ids nil)
    (missing-association-ids nil))))

 :input
 ((canonical-object "dreyeck/codex:codex-dmx-learning-topics")
  (canonical-explorer-system :dreyeck/codex/explorer)
  (compatibility-explorer-system :hyperdoc/codex/explorer)
  (production-db
   "/Users/rgb/workspace/hyperdoc/var/dmx-associative-mirror.sqlite")
  (required-topics
   (plan-then-perform-build-session
    build-referee-decision-route
    add-plan-then-perform-session-state-to-dreyeck-build
    render-build-referee-decisions-as-routes
    lisp-referee-form
    dreyeck/build:build-session-next-action
    asdf-3-3-session-action-model
    domkin-2017))
  (required-associations
   ((plan-then-perform-build-session refines codex-is-not-the-build-system)
    (plan-then-perform-build-session supports reusable-common-lisp-build-tasks-for-codex)
    (plan-then-perform-build-session inspired-by asdf-3-3-session-action-model)
    (asdf-3-3-session-action-model described-by domkin-2017)
    (build-referee-decision-route renders lisp-referee-form)
    (build-referee-decision-route explains plan-then-perform-build-session)
    (build-referee-decision-route supports codex-is-not-the-build-system)
    (build-referee-decision-route inspects dreyeck/build:build-session-next-action))))

 :shop3
 ((:task add-build-referee-subgraph-inspector-view
   :goal
   ((inspector-view code-dmx-learning-topics build-referee-subgraph)
    (view-shows production-dmx-build-referee-topics)
    (view-shows production-dmx-build-referee-associations)
    (view-shows missing-topic-ids)
    (view-shows missing-association-ids)
    (view-validates topic-count 8)
    (view-validates association-count 8)))

  (:operator inspect-existing-codex-dmx-learning-topic-view
   :preconditions ((system-exists :dreyeck/codex/explorer))
   :effects ((known code-dmx-learning-topics-class)
             (known current-inspector-view-registration)
             (known topic-slot-shape)
             (known association-slot-shape)))

  (:operator add-build-referee-subgraph-projection
   :preconditions ((known code-dmx-learning-topics-class)
                   (known topic-slot-shape)
                   (known association-slot-shape))
   :effects ((projection build-referee-topics-in-production-dmx)
             (projection-returns topic-count 8)
             (projection-returns association-count 8)
             (projection-returns missing-topic-ids nil)
             (projection-returns missing-association-ids nil)))

  (:operator add-build-referee-subgraph-view
   :preconditions ((known code-dmx-learning-topics-class)
                   (known current-inspector-view-registration)
                   (projection build-referee-topics-in-production-dmx))
   :effects ((inspector-view code-dmx-learning-topics build-referee-subgraph)))

  (:operator validate-build-referee-subgraph-view
   :preconditions ((inspector-view code-dmx-learning-topics build-referee-subgraph))
   :effects ((view-validates topic-count 8)
             (view-validates association-count 8)
             (missing-topic-ids nil)
             (missing-association-ids nil)
             (existing-dmx-learning-topics-view preserved))))

 :output-contract
 ((new-projection
   ("dreyeck/codex:codex-dmx-build-referee-subgraph"))
  (new-inspector-tab
   (:object code-dmx-learning-topics
    :title "Build Referee Subgraph"))
  (validation
   ((shop3-plan-artifact-exists
     "hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp")
    (subgraph-topic-count 8)
    (subgraph-association-count 8)
    (missing-topic-ids nil)
    (missing-association-ids nil)
    (dreyeck-codex-explorer-loads t)
    (hyperdoc-codex-explorer-loads t)
    (existing-dmx-learning-view-preserved t)
    (git-diff-check-passes t)))))
