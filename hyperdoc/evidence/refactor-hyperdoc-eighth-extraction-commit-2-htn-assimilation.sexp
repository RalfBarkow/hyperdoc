(:refactor-hyperdoc-eighth-extraction-commit-2-htn-assimilation
 (:task
  (!assimilate-eighth-dreyeck-extraction-into-reusable-htn))
 (:repository "/Users/rgb/workspace/hyperdoc/")
 (:target-branch "hauptsache")
 (:worktree-mode :temporary-clean-worktree)
 (:merge-commit
  "24fc9b0243d50d939741983d10ee5eeb8f68ead6")
 (:basis
  ((:role :preparation
    :path
    "hyperdoc/evidence/refactor-hyperdoc-eighth-dreyeck-extraction-commit-2-preparation.sexp"
    :commit "c13fc0803ed5c8a7226da67692f0013b5e9af1ea")
   (:role :execution
    :path
    "hyperdoc/evidence/refactor-hyperdoc-eighth-dreyeck-extraction-commit-2-execution.sexp"
    :commit "1ef7608498df2b9b372e0ac058ce65210ecb4868")
   (:role :review
    :path
    "hyperdoc/evidence/refactor-hyperdoc-eighth-dreyeck-extraction-commit-2-review.sexp"
    :commit "5133c6c98c790664ec0fd8fe9ab22d8823ca99fb")
   (:role :reusable-htn
    :path "hyperdoc/refactor-hyperdoc-reusable-extraction-htn.sexp")))
 (:input-validation
  (:all-basis-artifacts-safe-single-form t)
  (:read-eval nil)
  (:authoritative-input-state
   "24fc9b0243d50d939741983d10ee5eeb8f68ead6"))
 (:episode-closure
  (:episode :eighth-dreyeck-extraction-commit-2)
  (:preparation-commit
   "c13fc0803ed5c8a7226da67692f0013b5e9af1ea")
  (:execution-commit
   "1ef7608498df2b9b372e0ac058ce65210ecb4868")
  (:review-commit
   "5133c6c98c790664ec0fd8fe9ab22d8823ca99fb")
  (:merge-commit
   "24fc9b0243d50d939741983d10ee5eeb8f68ead6")
  (:canonical-state
   (:asdf-system :dreyeck/shop3)
   (:primary-package :dreyeck/shop3)
   (:implementation-components 6))
  (:compatibility-state
   (:asdf-system :hyperdoc/shop3)
   (:direct-components 0)
   (:depends-on (:dreyeck/shop3))
   (:legacy-package-nickname :hyperdoc/shop3))
  (:validation
   (:direct-canary :passed)
   (:compatibility-canary :passed)
   (:duplicate-implementation-load nil)
   (:merge-tree-equals-reviewed-tree t))
  (:pushed nil)
  (:classification
   :eighth-dreyeck-extraction-commit-2-merged))
 (:required-assimilation
  ((!record-eighth-extraction-commit-2-as-completed
    :preparation-commit
    "c13fc0803ed5c8a7226da67692f0013b5e9af1ea"
    :execution-commit
    "1ef7608498df2b9b372e0ac058ce65210ecb4868"
    :review-commit
    "5133c6c98c790664ec0fd8fe9ab22d8823ca99fb"
    :merge-commit
    "24fc9b0243d50d939741983d10ee5eeb8f68ead6"
    :status :recorded)
   (!record-canonical-shop3-ownership
    :implementation-system :dreyeck/shop3
    :implementation-components 6
    :primary-package :dreyeck/shop3
    :compatibility-system :hyperdoc/shop3
    :compatibility-components 0
    :legacy-package-nickname :hyperdoc/shop3
    :status :recorded)
   (!record-copy-then-verify-as-intermediate-extraction
    :canonical-ownership-moved t
    :legacy-physical-copies-may-remain t
    :legacy-copies-must-not-be-live-asdf-components t
    :status :recorded)
   (!record-live-reference-policy
    :reject-contradictory-live-references t
    :allow-compatibility-references t
    :allow-deferred-source-copies t
    :allow-historical-evidence-references t
    :allow-deferred-documentation-references t
    :status :recorded)
   (!record-package-aware-plan-canary-rule
    :expected-operator-package :resolve-from-domain
    :observed-package :dreyeck/shop3
    :do-not-default-to :cl-user
    :compare-symbol-identity t
    :printed-plan-equality-alone-insufficient t
    :status :recorded)
   (!record-baseline-comparison-for-unrelated-test-failures
    :observed-classification :pre-existing-stale-test-harness-expectation
    :require-base-and-head-comparison t
    :do-not-broaden-current-slice t
    :status :recorded)
   (!update-htn-status-through-eighth-extraction-commit-2
    :status :recorded)
   (!record-remaining-shop3-extraction-debt
    :legacy-implementation-copies 6
    :provider-boundary-move :deferred
    :documentation-workflow-move :deferred
    :reference-lint :missing
    :plan-tree-projection-repair :deferred
    :status :recorded)
   (!record-eighth-extraction-commit-3-candidate
    :candidate
    (!remove-legacy-shop3-implementation-copies
     :with-new-reference-lint
     :defer-provider-boundary-move t
     :defer-documentation-workflow-move t
     :defer-projection-repair t)
    :status :candidate-pending-task-localization)))
 (:reusable-htn-delta
  (:status
   (:from
    :draft-filed-out-from-temporary-topic-db-updated-through-sixth-extraction)
   (:to
    :draft-filed-out-from-temporary-topic-db-updated-through-eighth-extraction-commit-2))
  (:last-completed-episode :eighth-dreyeck-extraction-commit-2)
  (:new-specializations
   ((!prepare-eighth-dreyeck-extraction-commit-2)
    (!execute-eighth-dreyeck-extraction-commit-2)
    (!review-eighth-dreyeck-extraction-commit-2)
    (!assimilate-eighth-dreyeck-extraction-commit-2-into-reusable-htn)))
  (:new-reusable-rules
   ((!record-copy-then-verify-as-intermediate-extraction)
    (!record-live-reference-policy)
    (!record-package-aware-plan-canary-rule)
    (!record-baseline-comparison-for-unrelated-test-failures)))
  (:episode-assimilation-added t)
  (:remaining-debt-recorded t)
  (:commit-3-candidate-recorded t)
  (:commit-3-task-localized nil)
  (:next-slice-selected nil))
 (:package-aware-plan-canary-rule
  (:expectation
   "A plan whose printed operator name and arguments match the expected plan should compare equal.")
  (:observed-reality
   "The first merged direct-canary wrapper interned the expected operator in CL-USER while SHOP3 returned the operator owned by DREYECK/SHOP3; EQUAL correctly reported different symbols despite identical printed names and arguments.")
  (:why-this-expectation-was-plausible
   "The printed plan suppressed or visually de-emphasized the package distinction, making the two operator forms appear equivalent.")
  (:classification :false-validator-expectation)
  (:semantic-mismatch t)
  (:operational-planner-failure nil)
  (:resolution
   "Resolve the expected operator package from the planning domain, then construct, read, or intern the expected operator there; the package-aware rerun observed DREYECK/SHOP3 and passed with the unchanged plan.")
  (:prevention
   "Future plan canaries must derive the package from the owning domain rather than defaulting to CL-USER or hard-coding the package observed in this episode; normalize only when symbol-package identity is explicitly outside the contract."))
 (:remaining-shop3-extraction-debt
  (:legacy-implementation-copies
   ("hyperdoc-shop3/package.lisp"
    "hyperdoc-shop3/manual-topics.lisp"
    "hyperdoc-shop3/plan-objects.lisp"
    "hyperdoc-shop3/hyperdoc-maintenance-domain.lisp"
    "hyperdoc-shop3/examples.lisp"
    "hyperdoc-shop3/views.lisp"))
  (:provider-boundary
   (:system :hyperdoc/shop3-provider-boundary)
   (:move-deferred t))
  (:documentation-workflows
   (:move-or-rewrite-deferred t))
  (:reference-policy
   (:new-hyperdoc/shop3-references-lint-missing t))
  (:plan-tree-projection
   (:returned-shape-repair-deferred t)))
 (:eighth-extraction-commit-3-candidate
  (:candidate
   (!remove-legacy-shop3-implementation-copies
    :with-new-reference-lint
    :defer-provider-boundary-move t
    :defer-documentation-workflow-move t
    :defer-projection-repair t))
  (:status :candidate-pending-task-localization))
 (:preliminary-commit-3-task-localization
  (:mode :read-only)
  (:search-existing-htn-and-plan-artifacts-first t)
  (:artifacts-found
   ((:path "hyperdoc/refactor-hyperdoc-reusable-extraction-htn.sexp"
     :kind :reusable-htn-task-library
     :relevance
     "Provides the generic reviewed extraction-cycle method and now records the pending commit-3 candidate; it does not yet contain a localized removal-plus-lint routine.")
    (:path "hyperdoc/task-location-problem-determined-htn.sexp"
     :kind :task-localization-htn
     :relevance
     "Requires task localization before declaring a method gap or designing a new method.")
    (:path
     "hyperdoc/llm-wiki-note-8892-shop3-plan-location-discipline.sexp"
     :kind :htn-plan-location-correction
     :relevance
     "Requires the SHOP3/HTN route to be checked before text search is used as secondary source-anchor evidence.")
    (:path
     "hyperdoc/llm-wiki-note-8892-task-location-htn-assimilation-result.sexp"
     :kind :htn-assimilation-result
     :relevance
     "Makes durable task-location artifacts part of the slice-closure and repository-hygiene contract.")
    (:path "dreyeck/shop3/hyperdoc-maintenance-domain.lisp"
     :kind :canonical-shop3-domain-and-operator-source
     :operators
     (!add-recursive-component-collector
      !commit-stage
      !create-asdf-system
      !split-topic-family
      !load-system
      !run-smoke-test)
     :relevance
     "Owns the live HyperDoc maintenance planning domain, but defines no legacy-copy-removal or reference-lint operator.")
    (:path "hyperdoc-shop3/hyperdoc-maintenance-domain.lisp"
     :kind :deferred-legacy-operator-source-copy
     :relevance
     "Contains the same generic maintenance operators but is an unloaded legacy copy and cannot be the canonical commit-3 owner.")
    (:path "hyperdoc-shop3/shop3-parser-documentation-plan.sexp"
     :kind :plan-only-documentation-workflow
     :relevance
     "Plans parser-documentation editing and still names legacy paths; its migration is explicitly deferred and it is not a removal-plus-lint implementation plan.")
    (:path "hyperdoc-shop3/shop3-parser-documentation-workflow.scxml"
     :kind :plan-only-scxml-projection
     :relevance
     "Projects the deferred parser-documentation plan and is outside the commit-3 implementation candidate.")
    (:path
     "hyperdoc/evidence/refactor-hyperdoc-eighth-dreyeck-extraction-commit-2-preparation.sexp"
     :kind :source-target-and-reference-policy-plan
     :relevance
     "Records the six copy mappings, the preferred Dreyeck references, and deferred cleanup boundaries.")
    (:path
     "hyperdoc/evidence/refactor-hyperdoc-eighth-dreyeck-extraction-commit-2-execution.sexp"
     :kind :deferred-task-evidence
     :relevance
     "Names deletion of old implementation files and the new reference lint as deferred tasks.")
    (:path
     "hyperdoc/evidence/refactor-hyperdoc-eighth-dreyeck-extraction-commit-2-review.sexp"
     :kind :old-reference-classification-evidence
     :relevance
     "Provides the live-compatibility, deferred-copy, historical-evidence, and documentation-workflow reference classes required by a future lint.")))
  (:existing-specialized-commit-3-task nil)
  (:existing-removal-plus-lint-operator nil)
  (:existing-removal-plus-lint-plan nil)
  (:localization-result :method-gap-requires-dedicated-localization-task)
  (:candidate-status :candidate-pending-task-localization)
  (:implementation-changes-performed nil))
 (:changed-path-contract
  ("hyperdoc/refactor-hyperdoc-reusable-extraction-htn.sexp"
   "hyperdoc/evidence/refactor-hyperdoc-eighth-extraction-commit-2-htn-assimilation.sexp"))
 (:validation
  ((:check :both-output-artifacts-safe-single-form
    :read-eval nil
    :status :passed)
   (:check :only-expected-paths-changed
    :expected 2
    :actual 2
    :status :passed)
   (:check :git-diff-check
    :command "git diff --check"
    :status :passed)
   (:check :repository-load-gate
    :command "tools/check-lisp-load-gate.sh :hyperbook/server"
    :environment :nix-develop
    :status :passed
    :marker "LOAD_GATE_OK")
   (:check :merge-commit-reachable-from-hauptsache
    :commit "24fc9b0243d50d939741983d10ee5eeb8f68ead6"
    :status :passed)
   (:check :original-worktree-staged-files-preserved
    :paths
    ("hyperdoc/shop3-zettel-journey-contract.lisp"
     "hyperdoc/shop3-zettel-plan-provenance-index.sexp"
     "tests/shop3-zettel-journey-smoke.lisp")
    :index-blob-ids
    ("fec17cb44b315313f256f5fd1e647ecee049af95"
     "13289505c477d0bf84d66ed28d97f629683de3bd"
     "c7746ca7cee24ce18a0f1d819e8ede402b602ea5")
    :status :passed)
   (:check :temporary-worktree-removed
    :status :performed-after-commit-verification)))
 (:non-actions
  (:no-legacy-copy-deletion
   :no-reference-lint-implementation
   :no-provider-boundary-move
   :no-documentation-workflow-move
   :no-projection-repair
   :no-hyperdoc-page-change
   :no-topic-function-change
   :no-fedwiki-change
   :no-push))
 (:decision :assimilated)
 (:classification
  :eighth-dreyeck-extraction-commit-2-assimilated)
 (:next
  (!localize-eighth-dreyeck-extraction-commit-3
   :candidate
   (!remove-legacy-shop3-implementation-copies
    :with-new-reference-lint)
   :search-existing-htn-and-plan-artifacts-first t))
 (:reconstruction
  (:surface-answer
   (:episode :eighth-dreyeck-extraction-commit-2)
   (:status :assimilated)
   (:next (!localize-eighth-dreyeck-extraction-commit-3)))
  (:process-trace
   (:inspected
    (:preparation :execution :review :merge :reusable-htn
     :prior-seventh-assimilation :task-location-htn
     :shop3-plan-location-discipline :canonical-shop3-operator-source
     :deferred-documentation-plan :original-worktree-index))
   (:inferred
    (:copy-then-verify-is-valid-when-old-copies-are-not-live-components
     :reference-classes-must-be-distinguished
     :plan-canaries-must-preserve-symbol-package-identity
     :baseline-comparison-prevents-unrelated-repair-scope))
   (:decided
    (:record-episode-and-debt
     :record-dead-copy-removal-plus-reference-lint-as-candidate
     :defer-selection-until-task-localization)))
  (:hyperdoc-reconstruction
   (:pages-created-or-updated nil)
   (:section-level-content-delta nil)
   (:inspectable-objects-added nil)
   (:related-links-added nil)
   (:reason :htn-and-evidence-only-changed-path-contract))
  (:lisp-source-reconstruction
   (:implementation-definitions-added-or-updated nil)
   (:topic-functions-added-or-updated nil)
   (:durable-program-updated
    "hyperdoc/refactor-hyperdoc-reusable-extraction-htn.sexp")
   (:evidence-added
    "hyperdoc/evidence/refactor-hyperdoc-eighth-extraction-commit-2-htn-assimilation.sexp"))
  (:fedwiki-twin-reconstruction
   (:pages-created-or-updated nil)
   (:daily-anchor-updated nil)
   (:reason :cross-repository-mutation-out-of-scope))
  (:replayability-checks
   (:safe-single-form-required t)
   (:read-eval nil)
   (:changed-path-contract-required t)
   (:git-diff-check-required t)
   (:repository-load-gate-required t)
   (:json-parse-checks :not-applicable-no-fedwiki-json-changed)
   (:journal-integrity-checks :not-applicable-no-fedwiki-json-changed))))
