(:eighth-dreyeck-extraction-commit-2-execution
 (:task
  (!execute-eighth-dreyeck-extraction-commit-2))
 (:basis
  (:preparation-artifact
   "hyperdoc/evidence/refactor-hyperdoc-eighth-dreyeck-extraction-commit-2-preparation.sexp"
   :preparation-commit
   "c13fc0803ed5c8a7226da67692f0013b5e9af1ea"))
 (:repository "/Users/rgb/workspace/hyperdoc/")
 (:branch "codex/eighth-dreyeck-extraction-commit-2")
 (:source-target-mapping
  ((:source "hyperdoc-shop3/package.lisp"
    :target "dreyeck/shop3/package.lisp"
    :operation :copy-then-verify
    :semantic-role :provider-boundary
    :content-equivalent-before-required-boundary-edits t
    :boundary-edits
    ((:defpackage :from :hyperdoc/shop3 :to :dreyeck/shop3)
     (:legacy-package-nickname :hyperdoc/shop3)
     (:in-package :from :hyperdoc/shop3 :to :dreyeck/shop3)
     (:header-owner :from :hyperdoc :to :dreyeck)))
   (:source "hyperdoc-shop3/manual-topics.lisp"
    :target "dreyeck/shop3/manual-topics.lisp"
    :operation :copy-then-verify
    :semantic-role :manual-topic
    :content-equivalent-before-required-boundary-edits t
    :boundary-edits
    ((:in-package :from :hyperdoc/shop3 :to :dreyeck/shop3)))
   (:source "hyperdoc-shop3/plan-objects.lisp"
    :target "dreyeck/shop3/plan-objects.lisp"
    :operation :copy-then-verify
    :semantic-role :plan-object-model
    :content-equivalent-before-required-boundary-edits t
    :boundary-edits
    ((:in-package :from :hyperdoc/shop3 :to :dreyeck/shop3)))
   (:source "hyperdoc-shop3/hyperdoc-maintenance-domain.lisp"
    :target "dreyeck/shop3/hyperdoc-maintenance-domain.lisp"
    :operation :copy-then-verify
    :semantic-role :domain-model
    :content-equivalent-before-required-boundary-edits t
    :boundary-edits
    ((:in-package :from :hyperdoc/shop3 :to :dreyeck/shop3)))
   (:source "hyperdoc-shop3/examples.lisp"
    :target "dreyeck/shop3/examples.lisp"
    :operation :copy-then-verify
    :semantic-role :example
    :content-equivalent-before-required-boundary-edits t
    :boundary-edits
    ((:in-package :from :hyperdoc/shop3 :to :dreyeck/shop3)
     (:fixture-reader-package :from :hyperdoc/shop3 :to :dreyeck/shop3)))
   (:source "hyperdoc-shop3/views.lisp"
    :target "dreyeck/shop3/views.lisp"
    :operation :copy-then-verify
    :semantic-role :view-projection
    :content-equivalent-before-required-boundary-edits t
    :boundary-edits
    ((:in-package :from :hyperdoc/shop3 :to :dreyeck/shop3)))))
 (:asdf-transition
  (:implementation-system :dreyeck/shop3
   :implementation-definition "dreyeck.asd"
   :implementation-components 6
   :effective-load-order
   ("package" "manual-topics" "plan-objects"
    "hyperdoc-maintenance-domain" "examples" "views")
   :compatibility-system :hyperdoc/shop3
   :compatibility-definition "hyperdoc.asd"
   :compatibility-depends-on (:dreyeck/shop3)
   :compatibility-components 0
   :legacy-package-nickname :hyperdoc/shop3))
 (:direct-provider-canary
  (:system :dreyeck/shop3
   :resolver "SHOP3:FIND-PLANS"
   :heuristic-fallback nil
   :contract-source
   "/Users/rgb/workspace/hauptsache/docs/operations/kioskbeerli-salon-switching-contract.shop3.lisp"
   :expected
   ((!record-salon-secret-contract-gap
     "/var/lib/kioskbeerli-secrets/kioskbeerli-wifi.env"))
   :actual
   ((!record-salon-secret-contract-gap
     "/var/lib/kioskbeerli-secrets/kioskbeerli-wifi.env"))
   :status :passed))
 (:compatibility-provider-canary
  (:system :hyperdoc/shop3
   :resolver "SHOP3:FIND-PLANS"
   :heuristic-fallback nil
   :expected
   ((!record-salon-secret-contract-gap
     "/var/lib/kioskbeerli-secrets/kioskbeerli-wifi.env"))
   :actual
   ((!record-salon-secret-contract-gap
     "/var/lib/kioskbeerli-secrets/kioskbeerli-wifi.env"))
   :status :passed))
 (:dual-load-canary
  (:systems (:dreyeck/shop3 :hyperdoc/shop3)
   :direct-implementation-components 6
   :compatibility-implementation-components 0
   :package-identity :same
   :class-identity :same
   :function-identity :same
   :duplicate-implementation-load nil
   :status :passed))
 (:cross-repository-canary
  (:hauptsache-mutated nil
   :current-persistent-check "shop3-asdf-gap-canary"
   :persistent-canary-rerun-after-pin-update-required t))
 (:validation
  ((:preparation-artifact-safe-read
    :passed :read-eval nil :single-form t)
   (:all-six-copied-targets-exist :passed)
   (:all-six-source-files-remain-present :passed)
   (:copy-equivalence-after-recorded-boundary-edits :passed)
   (:asdf-load-dreyeck/shop3-clean-image :passed)
   (:asdf-load-hyperdoc/shop3-clean-image :passed)
   (:direct-provider-live-gap-plan-canary :passed)
   (:compatibility-provider-live-gap-plan-canary :passed)
   (:dual-system-clean-image-load :passed)
   (:shop3-provider-boundary-tests
    :command
    "nix develop -c sbcl --eval '(asdf:test-system :hyperdoc/shop3-provider-boundary/tests)'"
    :status :passed)
   (:projection-pipeline-shop3-subtest
    :command
    "run-projection-pipeline-shop3-smoke-test"
    :status :passed-with-existing-soft-skip
    :reason
    "The optional projection plan object is not defined on the preparation commit.")
   (:stale-broad-projection-smoke-expectation
    :expectation
    "The unregistered broad smoke entrypoint expected hyperdoc/Projection Pipeline for DMX Annotations.html to exist."
    :observed-reality
    "The page is absent on the preparation commit, before the SHOP3 subtest runs."
    :plausibility
    "The test source names and opens that historical page."
    :classification :false-or-stale-test-harness-expectation
    :resolution
    "Run the SHOP3-specific subtest; do not broaden this extraction by restoring unrelated projection documentation."
    :prevention
    "A later projection-test slice should register the intended test or remove the stale page assumption.")
   (:git-diff-check :passed)
   (:repository-pre-commit-lisp-nix-server-gate
    :command "tools/check-lisp-load-gate.sh :hyperbook/server"
    :sandbox-attempt
    (:status :environment-failure
     :reason "Nix daemon socket access denied by the command sandbox")
    :authoritative-nix-attempt
    (:status :passed :marker "LOAD_GATE_OK"))
   (:execution-artifact-safe-read
    :status :passed :read-eval nil :single-form t)
   (:committed-diff-check
    :command "git show --check --oneline --stat HEAD"
    :status :passed)))
 (:changed-paths
  ("dreyeck.asd"
   "dreyeck/shop3/package.lisp"
   "dreyeck/shop3/manual-topics.lisp"
   "dreyeck/shop3/plan-objects.lisp"
   "dreyeck/shop3/hyperdoc-maintenance-domain.lisp"
   "dreyeck/shop3/examples.lisp"
   "dreyeck/shop3/views.lisp"
   "hyperdoc.asd"
   "hyperdoc/evidence/refactor-hyperdoc-eighth-dreyeck-extraction-commit-2-execution.sexp"))
 (:reconstruction
  (:surface-answer
   (:classification :eighth-dreyeck-extraction-commit-2-executed
    :implementation-system :dreyeck/shop3
    :compatibility-system :hyperdoc/shop3))
  (:process-trace
   (:inspected
    (:preparation-artifact :asdf-definitions :selected-sources
     :hauptsache-gap-contract :repository-gates))
   (:inferred
    (:package-rename-authorized-by-preparation
     :legacy-package-retained-as-nickname))
   (:decided
    (:copy-then-verify :dependency-only-compatibility-system)))
  (:hyperdoc-reconstruction
   (:pages-created-or-updated nil
    :section-delta nil
    :reason :documentation-workflow-move-explicitly-deferred))
  (:lisp-source-reconstruction
   (:implementation-package :dreyeck/shop3
    :legacy-package-nickname :hyperdoc/shop3
    :implementation-files 6
    :asdf-owner :dreyeck/shop3
    :compatibility-consumer :hyperdoc/shop3))
  (:fedwiki-twin-reconstruction
   (:pages-created-or-updated nil
    :daily-anchor-updated nil
    :reason :cross-repository-and-documentation-mutation-out-of-scope))
  (:replayability-checks
   (:lisp-safe-read-required t
    :asdf-clean-image-loads-required t
    :live-gap-canaries-required t
    :json-parse-checks :not-applicable-no-fedwiki-json-changed
    :journal-integrity-checks :not-applicable-no-fedwiki-json-changed)))
 (:classification :eighth-dreyeck-extraction-commit-2-executed)
 (:deferred
  ((!delete-old-hyperdoc-shop3-implementation-files)
   (!move-shop3-provider-boundary-files)
   (!move-shop3-documentation-workflows)
   (!add-new-hyperdoc-shop3-reference-lint)
   (!repair-hyperdoc-shop3-plan-tree-projection-for-returned-shape)
   (!extend-salon-switching-domain-with-blocked-approved-source-plan)
   (!model-salon-contract-unblocker-as-shop3-problem)
   (!identify-approved-salon-secret-source)
   (!restore-pi-route-for-metadata-only-runtime-gate)
   (!bind-salon-secret-contract)))
 (:non-actions
  (:no-old-path-deletion
   :no-provider-boundary-extraction
   :no-documentation-workflow-move
   :no-plan-tree-projection-repair
   :no-new-reference-lint-rule
   :no-salon-domain-extension
   :no-pi-contact
   :no-secret-values
   :no-runtime-mutation)))
