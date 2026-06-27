(:artifact
 (:id inspect-dmx-materialized-learning-topics)
 (:title "Inspect DMX Materialized Learning Topics")
 (:type :shop3-plan)
 (:status :seed-or-projection-for-later-dmx-persistence)
 (:created-for-slice "feat(codex): inspect DMX materialized learning topics")
 (:repo-root "/Users/rgb/workspace/hyperdoc")
 (:production-store dreyeck-dmx-sqlite-production-db)
 (:plan-topic inspect-dmx-materialized-learning-topics)

 :knowledge
 ((current-architecture
   ((codex plans-inspects-explains-and-chooses-next-moves)
    (reusable-common-lisp-build-tasks execute-deterministic-checks)
    (dreyeck-dmx-sqlite-production-db stores durable-project-topics)
    (dmx-materialized-learning-topics are-inspectable-project-memory)))
  (constraints
   ((codex-not-used-as-build-system)
    (reuse-existing-dmx-materialization-api)
    (reuse-existing-validation-functions-where-available)
    (build-task-results structured-data)
    (missing-optional-providers become-inspectable-data-not-debugger-entries))))

 :input
 ((prior-commits
   (("afa829b9" "refactor(codex): move collaboration surface into dreyeck")
    ("1f4e6298" "docs(hyperdoc): define core ownership boundary")
    ("0a3ba45e" "feat(dmx): materialize durable notes into production topic store")))
  (existing-apis
   ("dreyeck.dmx.sqlite:materialize-durable-notes-into-production-db"
    "dreyeck.dmx.sqlite:durable-note-materialization-status"
    "dreyeck.dmx.sqlite:*dreyeck-dmx-production-db-path*"))
  (required-learning-topic-ids
   (hyperdoc-core
    ownership-extraction-with-compatibility-shell
    substrate-situated-surface-split
    codex-belongs-to-dreyeck
    materialize-durable-notes-into-dreyeck-dmx-sqlite
    markdown-note-as-seed-or-projection
    hyperdoc-core-vs-local-hyperdoc-path
    optional-provider-becomes-inspectable-data
    codex-is-not-the-build-system
    reusable-common-lisp-build-tasks-for-codex
    dmx-learning-topic-inspection
    codex-dmx-learning-topics)))

 :shop3
 ((:task inspect-dmx-materialized-learning-topics
   :goal
   ((codex-can-inspect dmx-materialized-learning-topics)
    (codex-can-inspect durable-note-materialization-status)
    (codex-uses reusable-common-lisp-build-tasks)
    (learned-build-system-boundary persisted-as-topic)
    (dmx-learning-topic-surface available)))

  (:operator inspect-existing-dmx-materialization-api
   :preconditions ((system-exists :dreyeck/dmx/sqlite))
   :effects ((known durable-note-materialization-status-api)
             (known production-db-path)
             (known materialized-topic-schema)
             (known association-schema)))

  (:operator define-common-lisp-build-task-layer
   :preconditions ((known existing-validation-functions))
   :effects ((build-task-registry available)
             (codex-can-call deterministic-build-tasks)
             (codex-not-used-as-build-system)))

  (:operator define-dmx-learning-topic-query
   :preconditions ((production-db available))
   :effects ((query materialized-learning-topics)
             (query topic-source-provenance)
             (query topic-associations)
             (query materialization-replay-status)))

  (:operator expose-codex-dmx-learning-topic-surface
   :preconditions ((query materialized-learning-topics)
                   (status durable-note-materialization-status))
   :effects ((codex-surface dmx-learning-topics)
             (inspector-view dmx-learning-topics)))

  (:operator validate-dmx-learning-topic-inspection
   :preconditions ((codex-surface dmx-learning-topics))
   :effects ((validation-passed dmx-learning-topic-inspection))))

 :output-contract
 ((codex-entry-points
   ("dreyeck/codex:codex-dmx-learning-topics"
    "dreyeck/codex:codex-dmx-learning-topic-status"))
  (build-task-entry-points
   ("dreyeck/build:list-build-tasks"
    "dreyeck/build:run-build-task"))
  (required-build-tasks
   (:dmx-durable-note-materialization-status
    :inspect-dmx-learning-topics
    :validate-dmx-learning-topics))
  (required-new-topics
   (codex-is-not-the-build-system
    reusable-common-lisp-build-tasks-for-codex
    dmx-learning-topic-inspection
    codex-dmx-learning-topics))
  (required-new-associations
   ((codex-is-not-the-build-system recommends
     reusable-common-lisp-build-tasks-for-codex)
    (reusable-common-lisp-build-tasks-for-codex supports
     codex-dmx-learning-topics)
    (codex-dmx-learning-topics inspects dreyeck-dmx-sqlite-production-db)
    (dmx-learning-topic-inspection depends-on
     durable-note-materialization-status)))
  (validation
   ((shop3-plan-artifact-exists
     "hyperdoc/inspect-dmx-materialized-learning-topics-plan.sexp")
    (codex-surface-loads t)
    (build-task-layer-loads t)
    (materialization-status-passed t)
    (materializer-second-replay-unchanged t)
    (git-diff-check-passes t)))))
