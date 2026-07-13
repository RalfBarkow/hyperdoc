(:eighth-dreyeck-extraction-commit-2-preparation
 (:task
  (!prepare-eighth-dreyeck-extraction-commit-2))
 (:mode :preparation-only)
 (:basis
  (:provider-hardening-commit
   "4660f46ff3d489b30c85382bcd8e39ccfc81097f"
   :canonical-merge
   "011d004802a2a1f82205542c371e06c62396d0af")
  (:hyperdoc-revision
   "90b8104bd89290cca7fea8be8af00dd5e9895b96"))
 (:plan-location
  (:eighth-extraction-plan-location
   (:htn
    "hyperdoc/refactor-hyperdoc-reusable-extraction-htn.sexp")
   (:current-slice
    (!select-eighth-low-risk-dreyeck-extraction-slice
     :instantiated-as
     (!extract-shop3-layer-to-dreyeck-with-gap-canary-preserved)))
   (:previous-completed-slice
    (:provider-hardening-commit
     "4660f46ff3d489b30c85382bcd8e39ccfc81097f"
     :canonical-merge
     "011d004802a2a1f82205542c371e06c62396d0af"))
   (:selection-mechanism
    (:kind :static-or-heuristic
     :resolver :repository-native-htn-task-library
     :resolver-call :static
     :heuristic-fallback t
     :evidence-strength :weaker-than-live-shop3))
   (:selection-evidence
    (:seventh-continuation
     "hyperdoc/evidence/refactor-hyperdoc-seventh-extraction-htn-assimilation.sexp"
     :next (!select-eighth-low-risk-dreyeck-extraction-slice))
    (:commit-1-selection
     "/Users/rgb/workspace/hauptsache/docs/operations/evidence/kioskbeerli-shop3-provider-nix-gap-canary.sexp"
     :role :provider-hardening-before-shop3-ownership-extraction)
    (:asdf-owner-inventory
     (:system :hyperdoc/shop3
      :definition "hyperdoc.asd"
      :component-module "hyperdoc-shop3")))
   (:classification :eighth-extraction-commit-2-located)))
 (:repository-boundary
  (:planning-repo "/Users/rgb/workspace/hauptsache/")
  (:extraction-repo "/Users/rgb/workspace/hyperdoc/")
  (:source-branch "hauptsache")
  (:target-branch "hauptsache")
  (:basis
   "hyperdoc/refactor-hyperdoc-reusable-extraction-htn.sexp")
  (:hauptsache-role
   :external-persistent-canary-consumer)
  (:hyperdoc-role
   :authoritative-shop3-extraction-owner))
 (:plan-search-result
  (:problem-topic :eighth-dreyeck-extraction)
  (:task-topic (!select-eighth-low-risk-dreyeck-extraction-slice))
  (:resolver :repository-native-htn-task-library)
  (:resolver-call :static)
  (:heuristic-fallback t)
  (:evidence-strength :weaker-than-live-shop3)
  (:selected-plan-topic :reusable-refactoring-slice-cycle)
  (:selected-task-topic
   (!extract-shop3-layer-to-dreyeck-with-gap-canary-preserved))
  (:allowed-gate :preparation-only))
 (:current-state
  ((hyperdoc-revision
    "90b8104bd89290cca7fea8be8af00dd5e9895b96")
   (implementation-system :hyperdoc/shop3)
   (implementation-owner :hyperdoc)
   (compatibility-system nil)
   (persistent-gap-canary "shop3-asdf-gap-canary")
   (persistent-gap-canary-load-system :hyperdoc/shop3)
   (source-files-moved nil)))
 (:goal-state
  ((implementation-system :dreyeck/shop3)
   (implementation-owner :dreyeck)
   (compatibility-system :hyperdoc/shop3)
   (existing-consumers-load-without-change t)
   (direct-provider-canary-passes t)
   (compatibility-provider-canary-passes t)
   (expected-gap-plan-unchanged t)
   (projection-repair-performed nil)
   (runtime-mutation-performed nil)))
 (:plan
  ((!reuse-existing-eighth-extraction-htn-cycle)
   (!classify-current-hyperdoc-shop3-asdf-components)
   (!select-copy-then-verify-implementation-slice)
   (!specify-dreyeck-shop3-asdf-owner)
   (!specify-hyperdoc-shop3-compatibility-system)
   (!require-direct-and-compatibility-gap-canaries)
   (!record-explicit-deferrals)
   (!validate-and-commit-preparation-artifact)))
 (:candidate-surface-inventory
  ((:file-classification
    (:path "hyperdoc-shop3/package.lisp")
    (:current-owner :hyperdoc)
    (:semantic-role :provider-boundary)
    (:selected-for-commit-2-p t)
    (:reason
     "Defines the current public planner package; execution copies the public API to DREYECK/SHOP3 and retains HYPERDOC/SHOP3 as a legacy package nickname or equally thin wrapper."))
   (:file-classification
    (:path "hyperdoc-shop3/manual-topics.lisp")
    (:current-owner :hyperdoc)
    (:semantic-role :manual-topic)
    (:selected-for-commit-2-p t)
    (:reason
     "It is an ordered component of the current :HYPERDOC/SHOP3 implementation system and must remain available from the new owner."))
   (:file-classification
    (:path "hyperdoc-shop3/plan-objects.lisp")
    (:current-owner :hyperdoc)
    (:semantic-role :plan-object-model)
    (:selected-for-commit-2-p t)
    (:reason
     "Defines HYPERDOC-HTN-PLAN-RESULT and plan normalization; implementation ownership moves unchanged before any projection repair."))
   (:file-classification
    (:path "hyperdoc-shop3/hyperdoc-maintenance-domain.lisp")
    (:current-owner :hyperdoc)
    (:semantic-role :domain-model)
    (:selected-for-commit-2-p t)
    (:reason
     "Defines the SHOP3 domain, problem, live FIND-PLANS runner, and plan-result construction used to prove the new owner."))
   (:file-classification
    (:path "hyperdoc-shop3/examples.lisp")
    (:current-owner :hyperdoc)
    (:semantic-role :example)
    (:selected-for-commit-2-p t)
    (:reason
     "It is loaded by the current planner system and exercises the public plan and manual-topic APIs; excluding it would narrow compatibility."))
   (:file-classification
    (:path "hyperdoc-shop3/views.lisp")
    (:current-owner :hyperdoc)
    (:semantic-role :view-projection)
    (:selected-for-commit-2-p t)
    (:reason
     "The existing PRINT-OBJECT projection follows the plan object to Dreyeck unchanged; plan-tree shape repair remains explicitly deferred."))
   (:file-classification
    (:path "hyperdoc-shop3/provider-boundary-package.lisp")
    (:current-owner :hyperdoc)
    (:semantic-role :provider-boundary)
    (:selected-for-commit-2-p nil)
    (:reason
     "Belongs to the separate :HYPERDOC/SHOP3-PROVIDER-BOUNDARY system, which must remain loadable before SHOP3 and HyperDoc."))
   (:file-classification
    (:path "hyperdoc-shop3/provider-boundary.lisp")
    (:current-owner :hyperdoc)
    (:semantic-role :provider-boundary)
    (:selected-for-commit-2-p nil)
    (:reason
     "Retains the narrow ASDF source-registry boundary and its existing tests; it is not planner implementation ownership."))
   (:file-classification
    (:path "hyperdoc-shop3/shop3-parser-documentation-plan.sexp")
    (:current-owner :hyperdoc)
    (:semantic-role :example)
    (:selected-for-commit-2-p nil)
    (:reason
     "Documentation workflow artifact with legacy paths and system names; migrate or revise in commit 3 or later."))
   (:file-classification
    (:path "hyperdoc-shop3/shop3-parser-documentation-workflow.scxml")
    (:current-owner :hyperdoc)
    (:semantic-role :example)
    (:selected-for-commit-2-p nil)
    (:reason
     "Manual plan-only projection is not an ASDF component and is deferred with its paired plan artifact."))
   (:file-classification
    (:path "hyperdoc.asd")
    (:current-owner :hyperdoc)
    (:semantic-role :compatibility-shell)
    (:selected-for-commit-2-p t)
    (:reason
     "Execution replaces the implementation definition of :HYPERDOC/SHOP3 with a dependency-only or thin compatibility definition while retaining the provider-boundary systems."))
   (:file-classification
    (:path "dreyeck.asd")
    (:current-owner :dreyeck)
    (:semantic-role :provider-boundary)
    (:selected-for-commit-2-p t)
    (:reason
     "Execution defines the new :DREYECK/SHOP3 implementation system and its ordered component list."))
   (:file-classification
    (:path "flake.nix")
    (:current-owner :hyperdoc)
    (:semantic-role :provider-boundary)
    (:selected-for-commit-2-p nil)
    (:reason
     "Already pins and registers SHOP3 and its dependencies; no flake-input or registry change is required for the ownership extraction."))
   (:file-classification
    (:path "flake.lock")
    (:current-owner :hyperdoc)
    (:semantic-role :provider-boundary)
    (:selected-for-commit-2-p nil)
    (:reason
     "Already pins SHOP3 revision 180ec5b5a664f14b609459449cc0a703f929decb; ownership extraction changes no input revision."))
   (:file-classification
    (:path "tests/shop3-provider-boundary-smoke.lisp")
    (:current-owner :hyperdoc)
    (:semantic-role :test)
    (:selected-for-commit-2-p nil)
    (:reason
     "Tests the separate pre-SHOP3 provider boundary and remains unchanged as a compatibility-boundary regression test."))))
 (:selected-source-files
  ("hyperdoc-shop3/package.lisp"
   "hyperdoc-shop3/manual-topics.lisp"
   "hyperdoc-shop3/plan-objects.lisp"
   "hyperdoc-shop3/hyperdoc-maintenance-domain.lisp"
   "hyperdoc-shop3/examples.lisp"
   "hyperdoc-shop3/views.lisp"
   "hyperdoc.asd"
   "dreyeck.asd"))
 (:deferred-source-files
  ((:path "hyperdoc-shop3/provider-boundary-package.lisp"
    :disposition :retain-under-hyperdoc-provider-boundary)
   (:path "hyperdoc-shop3/provider-boundary.lisp"
    :disposition :retain-under-hyperdoc-provider-boundary)
   (:path "tests/shop3-provider-boundary-smoke.lisp"
    :disposition :retain-provider-boundary-test)
   (:path "hyperdoc-shop3/shop3-parser-documentation-plan.sexp"
    :disposition :commit-3-or-later-documentation-migration)
   (:path "hyperdoc-shop3/shop3-parser-documentation-workflow.scxml"
    :disposition :commit-3-or-later-documentation-migration)
   (:path "hyperdoc/SHOP3 ASDF Refactor Plan Example.html"
    :disposition :commit-3-or-later-reference-migration)
   (:path "hyperdoc/Parsing SHOP3 Introduction into Topics.html"
    :disposition :commit-3-or-later-reference-migration)
   (:path "hyperdoc/SHOP3 Parser Documentation Plan and SCXML.html"
    :disposition :commit-3-or-later-reference-migration)
   (:path "hyperdoc/SHOP3 Planning API Reference.html"
    :disposition :commit-3-or-later-reference-migration)
   (:path "hyperdoc/Using SHOP3 Planning in HyperDoc.html"
    :disposition :commit-3-or-later-reference-migration)
   (:path "hyperdoc/Debug SHOP3 find-plans.html"
    :disposition :commit-3-or-later-reference-migration)
   (:path "tests/projection-pipeline-dmx-annotation-smoke.lisp"
    :disposition :existing-consumer-preserved-through-compatibility)))
 (:target-directories
  ((:path "dreyeck/shop3/"
    :status :create-during-execution
    :owner :dreyeck/shop3)
   (:path "./"
    :status :existing
    :role :asdf-definition-root)
   (:path "hyperdoc-shop3/"
    :status :existing
    :role :legacy-compatibility-and-deferred-cleanup)))
 (:commit-2-extraction-mapping
  (:mapping-field :source-target-mapping)
  (:allowed-operations
   (:copy-then-verify :move :compatibility-wrapper))
  (:selected-operations
   (:copy-then-verify :compatibility-wrapper))
  (:executed-during-preparation nil))
 (:source-target-mapping
  ((:source "hyperdoc-shop3/package.lisp"
    :target "dreyeck/shop3/package.lisp"
    :operation :copy-then-verify
    :reason
    "Create the primary DREYECK/SHOP3 package and expose HYPERDOC/SHOP3 only as the legacy compatibility name or thin wrapper.")
   (:source "hyperdoc-shop3/package.lisp"
    :target "hyperdoc-shop3/package.lisp"
    :operation :compatibility-wrapper
    :reason
    "Retain a minimal source surface for existing HYPERDOC/SHOP3 package consumers if the package-nickname design alone is insufficient.")
   (:source "hyperdoc-shop3/manual-topics.lisp"
    :target "dreyeck/shop3/manual-topics.lisp"
    :operation :copy-then-verify
    :reason "Move loaded manual-topic implementation ownership to Dreyeck.")
   (:source "hyperdoc-shop3/plan-objects.lisp"
    :target "dreyeck/shop3/plan-objects.lisp"
    :operation :copy-then-verify
    :reason
    "Move plan-object ownership without repairing PLAN-TREE->SAFE-SEXP in this slice.")
   (:source "hyperdoc-shop3/hyperdoc-maintenance-domain.lisp"
    :target "dreyeck/shop3/hyperdoc-maintenance-domain.lisp"
    :operation :copy-then-verify
    :reason "Move the domain, problem, and live FIND-PLANS runner together.")
   (:source "hyperdoc-shop3/examples.lisp"
    :target "dreyeck/shop3/examples.lisp"
    :operation :copy-then-verify
    :reason "Preserve loaded examples and public behavior under the new owner.")
   (:source "hyperdoc-shop3/views.lisp"
    :target "dreyeck/shop3/views.lisp"
    :operation :copy-then-verify
    :reason "Keep the existing plan-result print projection with its owner.")
   (:source "hyperdoc.asd"
    :target "hyperdoc.asd"
    :operation :compatibility-wrapper
    :reason
    "Replace :HYPERDOC/SHOP3 implementation components with a dependency on :DREYECK/SHOP3 while retaining the legacy system name.")))
 (:mapping-properties
  (:implementation-ownership-moving-to-dreyeck t)
  (:compatibility-retained-under-hyperdoc/shop3 t)
  (:old-unloaded-implementation-source-cleanup :commit-3-or-later)
  (:documentation-and-reference-migration :commit-3-or-later)
  (:projection-repair :explicitly-deferred)
  (:duplicate-targets nil))
 (:asdf-transition
  (:before
   (:consumer-system :hyperdoc/shop3
    :implementation-owner :hyperdoc
    :definition-file "hyperdoc.asd"
    :provider-boundary-system :hyperdoc/shop3-provider-boundary))
  (:after-commit-2
   (:implementation-system :dreyeck/shop3
    :implementation-owner :dreyeck
    :definition-file "dreyeck.asd"
    :component-root "dreyeck/shop3/")
   (:compatibility-system :hyperdoc/shop3
    :definition-file "hyperdoc.asd"
    :compatibility-kind :depends-on-or-thin-wrapper
    :selected-design :depends-on-with-legacy-package-nickname
    :depends-on :dreyeck/shop3)
   (:provider-boundary-system :hyperdoc/shop3-provider-boundary
    :disposition :unchanged))
  (:invariants
   (:existing-consumers-load-without-change t)
   (:gap-canary-still-loads :hyperdoc/shop3)
   (:no-new-code-should-prefer-hyperdoc/shop3 t)
   (:hyperdoc-core-still-does-not-depend-on-shop3 t)
   (:provider-boundary-still-loads-before-shop3 t)))
 (:new-reference-policy
  (:preferred-system :dreyeck/shop3)
  (:preferred-package :dreyeck/shop3)
  (:legacy-system :hyperdoc/shop3)
  (:legacy-package :hyperdoc/shop3)
  (:legacy-allowed-for
   (:compatibility-tests
    :existing-consumers))
  (:future-lint-rule-required t)
  (:future-lint-rule-in-commit-2 nil))
 (:gap-canary-preservation
  (:check "shop3-asdf-gap-canary")
  (:check-repository "/Users/rgb/workspace/hauptsache/")
  (:current-provider-system :hyperdoc/shop3)
  (:contract-source
   "docs/operations/kioskbeerli-salon-switching-contract.shop3.lisp")
  (:expected-plan
   ((!record-salon-secret-contract-gap
     "/var/lib/kioskbeerli-secrets/kioskbeerli-wifi.env")))
  (:canary-resolution
   (:resolver "SHOP3:FIND-PLANS"
    :resolver-call :live
    :heuristic-fallback nil))
  (:execution-commit-requirements
   (:run-before-file-changes t)
   (:run-after-dreyeck-system-load t)
   (:run-through-compatibility-system t)
   (:expected-plan-unchanged t)
   (:update-hauptsache-pinned-hyperdoc-revision-after-hyperdoc-execution t)))
 (:post-extraction-canaries
  (:decision :both)
  (:direct-provider
   (:system :dreyeck/shop3
    :system-definition "dreyeck.asd"
    :expected-plan-unchanged t)
   :reason
   "Proves the new owner loads and resolves the contract without selecting the legacy ASDF system.")
  (:compatibility-provider
   (:system :hyperdoc/shop3
    :system-definition "hyperdoc.asd"
    :check "shop3-asdf-gap-canary"
    :expected-plan-unchanged t)
   :reason
   "Preserves the committed consumer contract and detects compatibility regressions."))
 (:projection-policy
  (:file "hyperdoc-shop3/plan-objects.lisp")
  (:function "PLAN-TREE->SAFE-SEXP")
  (:commit-2-action :copy-current-behavior-unchanged)
  (:repair-task
   (!repair-hyperdoc-shop3-plan-tree-projection-for-returned-shape))
  (:repair-status :deferred-not-an-acceptance-criterion))
 (:deferred
  ((!repair-hyperdoc-shop3-plan-tree-projection-for-returned-shape)
   (!extend-salon-switching-domain-with-blocked-approved-source-plan)
   (!model-salon-contract-unblocker-as-shop3-problem)
   (!identify-approved-salon-secret-source)
   (!restore-pi-route-for-metadata-only-runtime-gate)
   (!bind-salon-secret-contract))
  (:hidden-acceptance-criteria-for-commit-2 nil))
 (:execution-task
  (!execute-eighth-dreyeck-extraction-commit-2
   :from-this-preparation-artifact
   "hyperdoc/evidence/refactor-hyperdoc-eighth-dreyeck-extraction-commit-2-preparation.sexp"))
 (:validation-contract
  ((:preparation-artifact-reads-as-lisp-data :required)
   (:all-selected-source-paths-exist :required)
   (:all-proposed-target-directories-identified :required)
   (:source-target-mapping-has-no-duplicate-targets :required)
   (:existing-shop3-asdf-gap-canary-passes :required)
   (:git-diff-check :required)
   (:documentation-gate :make-check-docs-if-applicable)
   (:pi-build :forbidden)
   (:deployment-validation :forbidden)))
 (:validation
  ((:preparation-artifact-reads-as-lisp-data
    :passed
    :read-eval nil
    :single-form t)
   (:all-selected-source-paths-exist :passed)
   (:all-proposed-target-directories-identified :passed)
   (:source-target-mapping-has-no-duplicate-targets :passed)
   (:existing-shop3-asdf-gap-canary
    "shop3-asdf-gap-canary"
    :passed)
   (:git-diff-check :passed)
   (:documentation-gate
    :not-applicable
    :reason "The HyperDoc Makefile exposes no check-docs target; the extraction evidence convention uses a safe Lisp-data read.")))
 (:result
  (:classification :eighth-extraction-commit-2-prepared)
  (:source-files-moved nil)
  (:gap-canary-preserved t)
  (:next-task
   (!execute-eighth-dreyeck-extraction-commit-2)))
 (:classification :eighth-extraction-commit-2-prepared)
 (:non-actions
  (:no-source-file-move
   :no-source-file-deletion
   :no-asdf-system-rename
   :no-plan-tree-projection-repair
   :no-salon-domain-extension
   :no-pi-contact
   :no-secret-values
   :no-runtime-mutation)))
