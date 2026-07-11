(:refactor-hyperdoc-sixth-dreyeck-extraction-selection
 (:operation (!select-sixth-low-risk-dreyeck-extraction-slice))
 (:base "e8b33c9c")
 (:precondition
  (:fourth-extraction :accepted)
  (:fifth-extraction :accepted)
  (:checkpoint "hyperdoc/evidence/refactor-hyperdoc-upstream-core-dreyeck-extraction-result.sexp")
  (:reusable-task-library "hyperdoc/refactor-hyperdoc-reusable-extraction-htn.sexp"))
 (:required-reusable-task-location
  (:task !locate-reusable-htn-tasks-before-specialization)
  (:status :performed)
  (:reused-method reusable-refactoring-slice-cycle)
  (:generalization-required-p nil))
 (:candidate-groups
  ((:name :dreyeck-codex-dmx-learning-inspection-plan
    :files
    ((:from "hyperdoc/inspect-dmx-materialized-learning-topics-plan.sexp"
      :to "dreyeck/codex/inspect-dmx-materialized-learning-topics-plan.sexp"
      :kind :shop3-plan-artifact
      :classification :dreyeck-owned-situated-surface
      :classification-basis
      (:codex-entry-points
       ("dreyeck/codex:codex-dmx-learning-topics"
        "dreyeck/codex:codex-dmx-learning-topic-status")
       :dmx-sqlite-dependencies
       ("dreyeck.dmx.sqlite:materialize-durable-notes-into-production-db"
        "dreyeck.dmx.sqlite:durable-note-materialization-status"
        "dreyeck.dmx.sqlite:*dreyeck-dmx-production-db-path*")
       :build-task-dependencies
       ("dreyeck/build:list-build-tasks"
        "dreyeck/build:run-build-task"))))
    :exact-source-path-reference-count 7
    :why-candidate
    "Single data-only SHOP3 plan artifact for a Codex-facing DMX learning-topic inspection surface; not ASDF, package, HyperDoc core, HyperBook core, or provider-boundary code.")
   (:name :dreyeck-codex-build-referee-subgraph-view-plan
    :files
    (("hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp"))
    :why-rejected-for-this-slice
    "The next candidate is downstream-owned, but its correct owner must be decided between dreyeck-explorer, dreyeck/codex, and an explicit subsystem before movement.")))
 (:selected-group
  (:name :dreyeck-codex-dmx-learning-inspection-plan
   :files
   ((:from "hyperdoc/inspect-dmx-materialized-learning-topics-plan.sexp"
     :to "dreyeck/codex/inspect-dmx-materialized-learning-topics-plan.sexp"
     :kind :shop3-plan-artifact
     :classification :dreyeck-owned-situated-surface))
   :current-owner :hyperdoc
   :target-owner :dreyeck/codex
   :target-system :dreyeck/codex
   :target-directory "dreyeck/codex/"
   :why-low-risk
   ((:file-count 1)
    (:data-only-plan-artifact t)
    (:not-manual-review t)
    (:not-necessary-local-core-delta t)
    (:not-asdf-component t)
    (:not-package-definition t)
    (:not-lisp-source-with-unclear-callers t)
    (:not-required-by (:hyperdoc :hyperbook :hyperbook/server))
    (:coherent-group
     "The artifact plans a Codex-facing inspection surface and names Codex entry points as the output contract while treating DMX SQLite as the materialized-topic store."))
   :inbound-reference-summary
   ((:commands
     ("git grep -n \"hyperdoc/inspect-dmx-materialized-learning-topics-plan.sexp\" || true"
      "git grep -n \"inspect-dmx-materialized-learning-topics-plan\" || true"
      "git grep -n \"dreyeck/codex/inspect-dmx-materialized-learning-topics-plan.sexp\" || true"))
    (:exact-source-path-references
     ((:file "dreyeck/codex.lisp"
       :line 994
       :classification :active-dreyeck-codex-source)
      (:file "dreyeck/dmx/sqlite/durable-notes.lisp"
       :line 71
       :classification :active-dreyeck-dmx-source)
      (:file "dreyeck/dmx/sqlite/durable-notes.lisp"
       :line 117
       :classification :active-dreyeck-dmx-source)
      (:file "dreyeck/dmx/sqlite/durable-notes.lisp"
       :line 123
       :classification :active-dreyeck-dmx-source)
      (:file "dreyeck/dmx/sqlite/durable-notes.lisp"
       :line 129
       :classification :active-dreyeck-dmx-source)
      (:file "dreyeck/dmx/sqlite/durable-notes.lisp"
       :line 135
       :classification :active-dreyeck-dmx-source)
      (:file "hyperdoc/inspect-dmx-materialized-learning-topics-plan.sexp"
       :line 112
       :classification :selected-file-self-reference)))
    (:historical-evidence-old-path-references :allowed)
    (:hyperdoc-core-required-by-asdf nil)
    (:hyperbook-required-by-asdf nil)
    (:hyperbook-server-required-by-asdf nil)
    (:source-reference-repair-likely-required-p t))
   :compatibility-shell-likely-required-p nil
   :asdf-update-likely-required-p nil
   :source-reference-update-likely-required-p t))
 (:decision :selected)
 (:validations
  ((:git-diff-check :passed)
   (:selection-artifact-read :passed)
   (:hyperdoc-load :passed)
   (:dreyeck/codex-load :passed)
   (:dreyeck/dmx/sqlite-load :passed)
   (:hyperdoc/shop3-provider-boundary/tests :passed)
   (:dreyeck/codex/tests :passed)
   (:dreyeck/dmx/sqlite/tests :passed)))
 (:actions-not-performed
  ((:file-moves t)
   (:deletions t)
   (:bulk-migration t)
   (:pi-actions t)
   (:ssh t)
   (:sudo t)
   (:nixos-rebuild t)
   (:wifi-secret-prompt t)))
 (:next
  (:if-selected (!review-sixth-slice-selection-before-execution)
   :if-no-safe-candidate (!manual-review-downstream-candidate-inventory))))
