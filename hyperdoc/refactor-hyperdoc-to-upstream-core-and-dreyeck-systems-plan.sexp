(:artifact
 (:id refactor-hyperdoc-to-upstream-core-and-dreyeck-systems)
 (:title "Refactor HyperDoc to Upstream Core and Dreyeck Systems")
 (:type :shop3-plan)
 (:status :open)
 (:upstream
  (:repo "https://codeberg.org/khinsen/hyperdoc.git"
   :commit "0d5bd1b0fba64f0bf9ab1cea21f01603c058f7cc"
   :verified-by "hyperdoc/evidence/refactor-hyperdoc-upstream-baseline-0d5bd1b0.sexp"))
 (:local
  (:repo-root "/Users/rgb/workspace/hyperdoc"
   :current-head "4f0e75af4bc83e2b8baabe62a05af80a67a88d72"
   :recent-boundary-repair "4f0e75af"))
 (:downstream
  (:primary-owner :dreyeck
   :repo-root "/Users/rgb/workspace/hyperdoc"
   :asdf-root "dreyeck/"
   :existing-target-systems
   (:dreyeck
    :dreyeck/server
    :dreyeck/codex
    :dreyeck/codex/examples
    :dreyeck/codex/explorer
    :dreyeck/dmx/workspace-selection
    :dreyeck/dmx/sqlite
    :dreyeck/build
    :dreyeck/zettelkasten)))
 (:goal
  ((hyperdoc-core-aligned-with-upstream-scope t)
   (necessary-local-core-deltas-justified t)
   (situated-project-surfaces-owned-by-dreyeck t)
   (compatibility-shells-temporary-and-recorded t)
   (kioskbeerli-and-hauptsache-remain-downstream t)))
 (:relationship-to-existing-plans
  ((:reuses "Dreyeck Extraction Plan for upstream main into hauptsache")
   (:reuses "Dreyeck Transition Plan for upstream main into hauptsache")
   (:reuses "Dreyeck Executable Scaffold for upstream main into hauptsache")
   (:reuses "Manual Merge Dossier for upstream main into hauptsache")
   (:reuses "Manual Conflict Resolution Proposals for upstream main into hauptsache")
   (:reuses "Manual Merge Execution Recipes for upstream main into hauptsache")
   (:reuses "refactor-page-systems-to-fedwiki-page-attached-asdf-plan.sexp")
   (:reuses "materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp")
   (:reuses "HyperDoc Core.md")
   (:reuses "Codex Belongs to Dreyeck.md")
   (:reuses "Ownership Extraction with Compatibility Shell.md")
   (:supersedes-none-in-first-slice)
   (:creates-umbrella-plan t)))
 (:classification-model
  (:delta-classes
   (:upstream-core
    "Belongs to Konrad/upstream HyperDoc scope.")
   (:necessary-local-core-delta
    "A reusable HyperDoc substrate improvement that remains in HyperDoc only with explicit justification.")
   (:dreyeck-owned-situated-surface
    "Project/local/collaboration/DMX/FedWiki deployment/Kioskbeerli/Hauptsache/Codex-specific behavior that must move under dreyeck or another downstream ASDF system.")
   (:page-attached-asset
    "Belongs under FedWiki page-attached ASDF asset roots, not HyperDoc core.")
   (:compatibility-shell
    "Temporary wrapper preserving old names while consumers migrate.")
   (:obsolete-delete
    "No longer required after upstream alignment and downstream extraction.")
   (:manual-review
    "Cannot be safely classified without reading code and call sites.")))
 (:reuse-existing-buckets
  ((:runtime-hooks
    :source "dreyeck-extraction-bucket-specs"
    :target ":dreyeck/server"
    :adaptation-mode :replace-with-hook/protocol-seam)
   (:local-deployment
    :source "dreyeck-extraction-bucket-specs"
    :target "dreyeck release and host layer"
    :adaptation-mode :move)
   (:page-content-overlays
    :source "dreyeck-extraction-bucket-specs"
    :target ":dreyeck/content or DMX topic projection"
    :adaptation-mode :move)
   (:glue-code
    :source "dreyeck-extraction-bucket-specs"
    :target ":dreyeck/dev plus release support"
    :adaptation-mode :wrap)
   (:page-attached-asset
    :source "refactor-page-systems-to-fedwiki-page-attached-asdf-plan.sexp"
    :target "FedWiki page-attached ASDF asset roots")
   (:durable-note-or-topic-projection
    :source "materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp"
    :target ":dreyeck/dmx/sqlite")))
 (:hard-constraints
  ((:do-not-move-files-in-first-slice t)
   (:do-not-delete-files-in-first-slice t)
   (:do-not-edit-konrad-upstream-history t)
   (:do-not-run-pi-actions t)
   (:do-not-run-ssh t)
   (:do-not-run-sudo t)
   (:do-not-run-nixos-rebuild t)
   (:do-not-prompt-for-wifi-secrets t)
   (:do-not-register-broad-shop3-tree t)
   (:do-not-mutate-alexandria-packages t)
   (:preserve-hyperdoc-shop3-provider-boundary-repair t)
   (:preserve-hauptsache-kioskbeerli-loader-boundary-repair t)
   (:do-not-call-kioskbeerli-build-only-operator t)))
 (:evidence
  ((:upstream-baseline
    "hyperdoc/evidence/refactor-hyperdoc-upstream-baseline-0d5bd1b0.sexp")
   (:local-delta-inventory
    "hyperdoc/evidence/refactor-hyperdoc-local-delta-inventory.sexp")
   (:asdf-ownership-inventory
    "hyperdoc/evidence/refactor-hyperdoc-asdf-ownership-inventory.sexp")))
 (:shop3
  ((:task refactor-hyperdoc-to-upstream-core-and-dreyeck-systems
    :ordered-subtasks
    ((!record-plan-artifact
      "hyperdoc/refactor-hyperdoc-to-upstream-core-and-dreyeck-systems-plan.sexp")
     (!fetch-and-record-konrad-upstream-baseline)
     (!inventory-current-asdf-systems)
     (!inventory-current-hyperdoc-asdf-systems)
     (!inventory-current-dreyeck-asdf-systems)
     (!diff-local-hyperdoc-against-upstream-baseline)
     (!classify-local-deltas)
     (!classify-path-ownership)
     (!map-dreyeck-owned-deltas-to-target-systems)
     (!identify-necessary-hyperdoc-core-deltas)
     (!identify-temporary-compatibility-shells)
     (!validate-no-downstream-dependency-in-hyperdoc-core)
     (!validate-dreyeck-systems-load)
     (!validate-hyperdoc-core-loads-without-dreyeck)
     (!validate-plan-only-no-file-moves-yet)
     (!write-migration-plan)
     (!commit-plan-artifact)))

   (:op (!fetch-and-record-konrad-upstream-baseline)
    :preconditions ((repo-root "/Users/rgb/workspace/hyperdoc")
                    (no-merge t)
                    (no-reset t))
    :effects ((upstream-baseline-commit-verified t)
              (upstream-baseline-evidence
               "hyperdoc/evidence/refactor-hyperdoc-upstream-baseline-0d5bd1b0.sexp")))

   (:op (!inventory-current-asdf-systems)
    :preconditions ((repo-root "/Users/rgb/workspace/hyperdoc"))
    :effects ((asdf-systems-inventoried t)
              (hyperdoc-asdf-systems-inventoried t)
              (dreyeck-asdf-systems-inventoried t)
              (asdf-ownership-inventory
               "hyperdoc/evidence/refactor-hyperdoc-asdf-ownership-inventory.sexp")))

   (:op (!diff-local-hyperdoc-against-upstream-baseline)
    :preconditions ((upstream-baseline-commit-verified t))
    :effects ((changed-paths-vs-upstream inventoried)
              (local-delta-inventory
               "hyperdoc/evidence/refactor-hyperdoc-local-delta-inventory.sexp")))

   (:op (!classify-path-ownership ?path ?class)
    :preconditions ((changed-path ?path)
                    (member ?class
                            (:upstream-core
                             :necessary-local-core-delta
                             :dreyeck-owned-situated-surface
                             :page-attached-asset
                             :compatibility-shell
                             :obsolete-delete
                             :manual-review)))
    :effects ((path-classification ?path ?class)))

   (:op (!map-path-to-dreyeck-target-system ?path ?system)
    :preconditions ((path-classification ?path :dreyeck-owned-situated-surface)
                    (dreyeck-target-system ?system))
    :effects ((dreyeck-target ?path ?system)
              (dependency-direction ?system :depends-on-hyperdoc)))

   (:op (!mark-necessary-hyperdoc-core-delta ?path ?justification)
    :preconditions ((path-classification ?path :necessary-local-core-delta))
    :effects ((core-delta-justification ?path ?justification)))

   (:op (!mark-temporary-compatibility-shell ?path ?canonical-target)
    :preconditions ((path-classification ?path :compatibility-shell))
    :effects ((compatibility-shell ?path)
              (temporary-shell-target ?path ?canonical-target)
              (cleanup-required ?path)))

   (:op (!validate-no-downstream-dependency-in-hyperdoc-core)
    :preconditions ((classification-complete-or-manual-review t))
    :effects ((hyperdoc-core-does-not-depend-on-dreyeck t)
              (hyperdoc-core-does-not-depend-on-kioskbeerli t)
              (hyperdoc-core-does-not-depend-on-hauptsache t)))

   (:op (!validate-dreyeck-systems-load)
    :preconditions ((dreyeck-target-systems-inventoried t))
    :effects ((dreyeck-systems-load-validation-required t)))

   (:op (!validate-hyperdoc-core-loads-without-dreyeck)
    :preconditions ((hyperdoc-core-candidate-systems-inventoried t))
    :effects ((hyperdoc-core-load-validation-required t)))

   (:op (!validate-plan-only-no-file-moves-yet)
    :preconditions ((hard-constraints-recorded t))
    :effects ((file-moves nil)
              (deletions nil)
              (destructive-edits nil)
              (pi-actions nil)
              (remote-actions nil)))

   (:op (!commit-plan-artifact)
    :preconditions ((plan-artifact-created t)
                    (evidence-artifacts-created t)
                    (git-diff-check-passes t)
                    (hyperdoc-load-smoke-preserved t)
                    (shop3-provider-boundary-smoke-preserved t))
    :effects ((planning-slice-committed t)))))
 (:first-slice-acceptance
  ((:plan-artifact-created t)
   (:upstream-baseline-commit-verified t)
   (:existing-plans-located-and-referenced t)
   (:local-delta-inventory-created t)
   (:all-deltas-classified-or-manual-review t)
   (:no-file-moves-yet t)
   (:no-destructive-edits t)
   (:no-pi-actions t)
   (:git-diff-check-passes t)
   (:hyperdoc-load-smoke-preserved t)
   (:shop3-provider-boundary-smoke-preserved t)))
 (:next
  (!execute-first-low-risk-dreyeck-extraction-slice)))
