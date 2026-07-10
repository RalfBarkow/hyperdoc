(:artifact
 (:id materialize-durable-notes-into-dreyeck-dmx-sqlite)
 (:title "Materialize Durable Notes into Dreyeck DMX SQLite")
 (:type :shop3-plan)
 (:status :seed-or-projection-for-later-dmx-persistence)
 (:created-for-slice "feat(dmx): materialize durable notes into production topic store")
 (:repo-root "/Users/rgb/workspace/hyperdoc")
 (:production-store dreyeck-dmx-sqlite-production-db)
 (:plan-topic materialize-durable-notes-into-dreyeck-dmx-sqlite)

 :knowledge
 ((current-architecture
   ((hyperdoc-core upstream-substrate)
    (dreyeck owns-situated-collaboration-surfaces)
    (dreyeck-dmx-sqlite-production-db stores durable-project-topics)
    (markdown-notes classified-as seeds-or-projections)))
  (constraints
   ((do-not-invent-second-persistence-layer)
    (use-existing-dmx-sqlite-topic-writer-if-present)
    (use-existing-dmx-sqlite-association-writer-if-present)
    (materializer idempotent)
    (markdown-notes preserved-as-human-readable-seeds)
    (codex-can-inspect topic-db-status))))

 :input
 ((seed-notes
   (("hyperdoc/HyperDoc Core.md" hyperdoc-core)
    ("hyperdoc/Codex Belongs to Dreyeck.md" codex-belongs-to-dreyeck)
    ("hyperdoc/Ownership Extraction with Compatibility Shell.md"
     ownership-extraction-with-compatibility-shell)))
  (commit-anchors
   ((hyperdoc-core "1f4e6298")
    (codex-belongs-to-dreyeck "afa829b9")
    (ownership-extraction-with-compatibility-shell
     "afa829b9 refactor(codex): move collaboration surface into dreyeck"))))

 :shop3
 ((:task materialize-durable-notes-into-dreyeck-dmx-sqlite
   :goal
   ((durable-project-topics stored-in dreyeck-dmx-sqlite-production-db)
    (markdown-notes classified-as seeds-or-projections)
    (codex-can-inspect topic-db-status)
    (hyperdoc-core-boundary-topic persisted-as-dmx-topic)
    (ownership-extraction-pattern persisted-as-dmx-topic)
    (codex-belongs-to-dreyeck-topic persisted-as-dmx-topic)))

  (:operator inspect-existing-dmx-sqlite-writers
   :preconditions ((repo-root "/Users/rgb/workspace/hyperdoc"))
   :effects ((known existing-dmx-topic-writer)
             (known existing-dmx-association-writer)
             (known production-db-path-or-config)))

  (:operator define-note-to-topic-mapping
   :preconditions ((known durable-note-seed-set))
   :effects ((mapping markdown-note dmx-topic)
             (mapping note-links dmx-associations)
             (mapping pattern-cards dmx-topic-types)))

  (:operator materialize-seed-note-as-topic
   :parameters ("?note" "?topic-id")
   :preconditions ((markdown-note "?note")
                   (production-db available))
   :effects ((dmx-topic "?topic-id")
             (source-note "?topic-id" "?note")
             (projection-status "?topic-id" :seeded-from-markdown)))

  (:operator materialize-learned-pattern
   :parameters ("?pattern-topic")
   :preconditions ((pattern-note "?pattern-topic"))
   :effects ((dmx-topic "?pattern-topic")
             (dmx-associations "?pattern-topic")
             (learned-pattern persisted)))

  (:operator validate-topic-materialization
   :preconditions ((dmx-topic hyperdoc-core)
                   (dmx-topic ownership-extraction-with-compatibility-shell)
                   (dmx-topic codex-belongs-to-dreyeck))
   :effects ((validation-passed durable-note-materialization))))

 :output-contract
 ((required-topics
   (hyperdoc-core
    ownership-extraction-with-compatibility-shell
    substrate-situated-surface-split
    codex-belongs-to-dreyeck
    materialize-durable-notes-into-dreyeck-dmx-sqlite
    markdown-note-as-seed-or-projection
    hyperdoc-core-vs-local-hyperdoc-path
    optional-provider-becomes-inspectable-data))
  (required-associations
   ((hyperdoc-core supplies-boundary-for
     ownership-extraction-with-compatibility-shell)
    (ownership-extraction-with-compatibility-shell applied-in
     codex-belongs-to-dreyeck)
    (hyperdoc-core distinguishes hyperdoc-core-patch)
    (hyperdoc-core distinguishes hyperdoc-compatibility-shell)
    (hyperdoc-core excludes project-owned-extension)
    (markdown-note-as-seed-or-projection materializes-to dmx-topic)
    (dreyeck-dmx-sqlite-production-db stores durable-project-topics)))
  (validation
   ((shop3-plan-artifact-exists
     "dreyeck/dmx/sqlite/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp")
    (asdf-load-system dreyeck/dmx/sqlite)
    (materializer-idempotent t)
    (status-object-inspectable t)
    (git-diff-check-passes t)))))
