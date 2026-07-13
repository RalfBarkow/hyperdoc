(:refactor-hyperdoc-eighth-dreyeck-extraction-commit-2-review
 (:task
  (!review-eighth-dreyeck-extraction-commit-2))
 (:repository "/Users/rgb/workspace/hyperdoc/")
 (:branch "codex/eighth-dreyeck-extraction-commit-2")
 (:base
  "c13fc0803ed5c8a7226da67692f0013b5e9af1ea")
 (:head
  "1ef7608498df2b9b372e0ac058ce65210ecb4868")
 (:review-contract
  (:mode :read-only)
  (:implementation-mutations-allowed nil)
  (:implementation-mutations-performed nil)
  (:written-artifacts
   ("hyperdoc/evidence/refactor-hyperdoc-eighth-dreyeck-extraction-commit-2-review.sexp")))
 (:authoritative-artifacts
  ((:role :preparation
    :path
    "hyperdoc/evidence/refactor-hyperdoc-eighth-dreyeck-extraction-commit-2-preparation.sexp"
    :safe-read (:read-eval nil :single-form t))
   (:role :execution
    :path
    "hyperdoc/evidence/refactor-hyperdoc-eighth-dreyeck-extraction-commit-2-execution.sexp"
    :safe-read (:read-eval nil :single-form t))))
 (:package-rename
  (:classification :authorized-by-preparation)
  (:explicitly-authorized-by-preparation t)
  (:direct-evidence
   ((:preparation-location
     (:candidate-surface-inventory
      (:path "hyperdoc-shop3/package.lisp")
      :reason)
     :text
     "Defines the current public planner package; execution copies the public API to DREYECK/SHOP3 and retains HYPERDOC/SHOP3 as a legacy package nickname or equally thin wrapper.")
    (:preparation-location
     (:source-target-mapping
      (:source "hyperdoc-shop3/package.lisp")
      (:target "dreyeck/shop3/package.lisp")
      :reason)
     :text
     "Create the primary DREYECK/SHOP3 package and expose HYPERDOC/SHOP3 only as the legacy compatibility name or thin wrapper.")
    (:preparation-location
     (:asdf-transition :compatibility-system :selected-design)
     :value :depends-on-with-legacy-package-nickname)
    (:preparation-location
     (:new-reference-policy)
     :preferred-package :dreyeck/shop3
     :legacy-package :hyperdoc/shop3)))
  (:package-transition
   (:primary-name
    (:from :hyperdoc/shop3 :to :dreyeck/shop3))
   (:legacy-compatibility
    (:kind :package-nickname)
    (:name :hyperdoc/shop3)))
  (:primary-package :dreyeck/shop3)
  (:legacy-nickname :hyperdoc/shop3)
  (:same-package-object t)
  (:review-conclusion
   "The execution report's inference is replaced by direct preparation evidence; the rename is not an unapproved scope expansion."))
 (:asdf-ownership
  (:dreyeck/shop3
   (:definition "dreyeck.asd")
   (:direct-components 6)
   (:component-root "dreyeck/shop3/")
   (:component-order
    ("package"
     "manual-topics"
     "plan-objects"
     "hyperdoc-maintenance-domain"
     "examples"
     "views"))
   (:canonical-owner t))
  (:hyperdoc/shop3
   (:definition "hyperdoc.asd")
   (:direct-components 0)
   (:depends-on (:dreyeck/shop3))
   (:compatibility-only t))
  (:provider-boundary
   (:system :hyperdoc/shop3-provider-boundary)
   (:component-root "hyperdoc-shop3/")
   (:files
    ("provider-boundary-package.lisp"
     "provider-boundary.lisp"))
   (:disposition :unchanged-and-deferred)))
 (:preservation
  (:copy-equivalence-modulo-boundary-edits t)
  (:component-order-preserved t)
  (:boundary-edits
   ((:target "dreyeck/shop3/package.lisp"
     :edits
     ((:header-owner :from :hyperdoc :to :dreyeck)
      (:defpackage :from :hyperdoc/shop3 :to :dreyeck/shop3)
      (:legacy-package-nickname :hyperdoc/shop3)
      (:in-package :from :hyperdoc/shop3 :to :dreyeck/shop3)))
    (:target "dreyeck/shop3/manual-topics.lisp"
     :edits
     ((:in-package :from :hyperdoc/shop3 :to :dreyeck/shop3)))
    (:target "dreyeck/shop3/plan-objects.lisp"
     :edits
     ((:in-package :from :hyperdoc/shop3 :to :dreyeck/shop3)))
    (:target "dreyeck/shop3/hyperdoc-maintenance-domain.lisp"
     :edits
     ((:in-package :from :hyperdoc/shop3 :to :dreyeck/shop3)))
    (:target "dreyeck/shop3/examples.lisp"
     :edits
     ((:in-package :from :hyperdoc/shop3 :to :dreyeck/shop3)
      (:fixture-reader-package :from :hyperdoc/shop3 :to :dreyeck/shop3)))
    (:target "dreyeck/shop3/views.lisp"
     :edits
     ((:in-package :from :hyperdoc/shop3 :to :dreyeck/shop3)))))
  (:gap-plan
   (:expected
    ((!record-salon-secret-contract-gap
      "/var/lib/kioskbeerli-secrets/kioskbeerli-wifi.env")))
   (:direct-actual
    ((!record-salon-secret-contract-gap
      "/var/lib/kioskbeerli-secrets/kioskbeerli-wifi.env")))
   (:compatibility-actual
    ((!record-salon-secret-contract-gap
      "/var/lib/kioskbeerli-secrets/kioskbeerli-wifi.env")))
   (:unchanged t))
  (:direct-canary :passed)
  (:compatibility-canary :passed)
  (:dual-load-canary
   (:direct-components 6)
   (:compatibility-components 0)
   (:compatibility-depends-on :dreyeck/shop3)
   (:same-package-object t)
   (:same-class-identity t)
   (:same-function-identity t)
   (:duplicate-implementation-load nil)
   (:status :passed)))
 (:old-path-policy
  (:contradictory-live-references nil)
  (:classifications
   ((:classification :deferred-source-copy
     :count 6
     :paths
     ("hyperdoc-shop3/package.lisp"
      "hyperdoc-shop3/manual-topics.lisp"
      "hyperdoc-shop3/plan-objects.lisp"
      "hyperdoc-shop3/hyperdoc-maintenance-domain.lisp"
      "hyperdoc-shop3/examples.lisp"
      "hyperdoc-shop3/views.lisp")
     :reason
     "The old implementations remain present for copy-then-verify but are not ASDF components of the compatibility system.")
    (:classification :live-compatibility
     :paths
     ("hyperdoc.asd"
      "dreyeck/shop3/package.lisp"
      "tests/projection-pipeline-dmx-annotation-smoke.lisp")
     :reason
     "These references deliberately exercise the dependency-only compatibility system or its legacy package nickname.")
    (:classification :live-compatibility
     :paths
     ("hyperdoc-shop3/provider-boundary-package.lisp"
      "hyperdoc-shop3/provider-boundary.lisp")
     :reason
     "These files implement the separately owned provider boundary explicitly retained by preparation.")
    (:classification :documentation-workflow
     :paths
     ("hyperdoc-shop3/shop3-parser-documentation-plan.sexp"
      "hyperdoc-shop3/shop3-parser-documentation-workflow.scxml"
      "hyperdoc/Debug SHOP3 find-plans.html"
      "hyperdoc/Parsing SHOP3 Introduction into Topics.html"
      "hyperdoc/SHOP3 ASDF Refactor Plan Example.html"
      "hyperdoc/SHOP3 Planning API Reference.html"
      "hyperdoc/Using SHOP3 Planning in HyperDoc.html")
     :reason
     "Preparation explicitly defers these legacy path and reference migrations to commit 3 or later.")
    (:classification :historical-evidence
     :paths
     ("hyperdoc/evidence/refactor-hyperdoc-eighth-dreyeck-extraction-commit-2-preparation.sexp"
      "hyperdoc/evidence/refactor-hyperdoc-eighth-dreyeck-extraction-commit-2-execution.sexp")
     :reason
     "These references record the before/after boundary and remain replay evidence.")))
  (:deferred-source-copies 6)
  (:provider-boundary-files-deferred t)
  (:historical-references-allowed t))
 (:projection-smoke
  (:expectation
   "The broad projection smoke opens hyperdoc/Projection Pipeline for DMX Annotations.html.")
  (:base-observed-reality
   (:status :failed)
   (:condition :file-does-not-exist)
   (:pathname "hyperdoc/Projection Pipeline for DMX Annotations.html"))
  (:head-observed-reality
   (:status :failed)
   (:condition :file-does-not-exist)
   (:pathname "hyperdoc/Projection Pipeline for DMX Annotations.html"))
  (:test-source-blob
   (:base "c30da68d316ca930bec7f6886759eb519ecf08a5")
   (:head "c30da68d316ca930bec7f6886759eb519ecf08a5")
   (:identical t))
  (:baseline-failure-confirmed t)
  (:required-classification :pre-existing-stale-harness)
  (:classification :pre-existing-stale-test-harness-expectation)
  (:introduced-regression nil)
  (:shop3-specific-subtest :passed)
  (:shop3-specific-subtest-detail
   (:status :passed-with-existing-soft-skip)
   (:message
    "SHOP3 projection pipeline plan object not defined yet; skipping."))
  (:resolution
   "Do not change the extraction to restore an unrelated page; repair or retire the stale broad harness in a later projection-test slice."))
 (:scope-boundary
  (:prepared-path-and-mutation-boundary-preserved t)
  (:committed-paths
   ("dreyeck.asd"
    "dreyeck/shop3/examples.lisp"
    "dreyeck/shop3/hyperdoc-maintenance-domain.lisp"
    "dreyeck/shop3/manual-topics.lisp"
    "dreyeck/shop3/package.lisp"
    "dreyeck/shop3/plan-objects.lisp"
    "dreyeck/shop3/views.lisp"
    "hyperdoc.asd"
    "hyperdoc/evidence/refactor-hyperdoc-eighth-dreyeck-extraction-commit-2-execution.sexp"))
  (:all-six-old-source-files-still-present t)
  (:all-six-new-target-files-present t)
  (:old-source-deletion-performed nil)
  (:provider-boundary-move-performed nil)
  (:documentation-workflow-move-performed nil)
  (:projection-repair-performed nil)
  (:hauptsache-mutated nil)
  (:reviewer-implementation-mutation-performed nil))
 (:validation
  ((:check :authoritative-artifact-safe-read
    :command
    "SBCL read of both artifacts with *READ-EVAL* NIL and a second read required to return EOF"
    :status :passed)
   (:check :committed-scope
    :command
    "git diff --name-status c13fc0803ed5c8a7226da67692f0013b5e9af1ea..1ef7608498df2b9b372e0ac058ce65210ecb4868"
    :status :passed
    :changed-paths 9)
   (:check :committed-diff-whitespace
    :command
    "git diff --check c13fc0803ed5c8a7226da67692f0013b5e9af1ea..1ef7608498df2b9b372e0ac058ce65210ecb4868"
    :status :passed)
   (:check :copy-equivalence
    :command
    "git diff c13fc0803ed5c8a7226da67692f0013b5e9af1ea:<old-source> 1ef7608498df2b9b372e0ac058ce65210ecb4868:<new-target> for each of the six mappings"
    :status :passed
    :differences :recorded-boundary-edits-only)
   (:check :old-reference-classification
    :command
    "git grep at 1ef7608498df2b9b372e0ac058ce65210ecb4868 for HYPERDOC/SHOP3, :hyperdoc/shop3, and the six hyperdoc-shop3 implementation paths"
    :status :passed
    :contradictory-live-references 0)
   (:check :direct-gap-canary
    :environment :nix-develop
    :cache "/tmp/hyperdoc-eighth-shop3-review-direct-cache"
    :status :passed)
   (:check :compatibility-gap-canary
    :environment :nix-develop
    :source
    "/Users/rgb/workspace/hauptsache/nix/shop3-asdf-gap-canary.lisp"
    :status :passed
    :marker "SHOP3_GAP_CANARY_STATUS=:PASS")
   (:check :parallel-canary-first-attempt
    :status :environment-failure
    :reason
    "Concurrent clean-image processes shared one XDG cache and raced on a temporary FASL; the compatibility canary still passed."
    :resolution
    "Reran the direct canary with an isolated XDG cache."
    :slice-failure nil)
   (:check :dual-system-load
    :environment :nix-develop
    :cache "/tmp/hyperdoc-eighth-shop3-review-direct-cache"
    :status :passed
    :markers
    ("REVIEW_DIRECT_COMPONENTS=6"
     "REVIEW_COMPAT_COMPONENTS=0"
     "REVIEW_COMPAT_DEPENDS_ON=:DREYECK/SHOP3"
     "REVIEW_DUPLICATE_IMPLEMENTATION_LOAD=NIL"
     "REVIEW_DUAL_LOAD=:PASS"))
   (:check :base-broad-projection-smoke
    :command
    "git archive the base into /tmp/hyperdoc-eighth-review-base-c13fc080, then run run-projection-pipeline-page-smoke-test in nix develop with that archive as CL_SOURCE_REGISTRY"
    :status :failed-as-baseline
    :condition :file-does-not-exist)
   (:check :head-broad-projection-smoke
    :command
    "run run-projection-pipeline-page-smoke-test in nix develop at HEAD"
    :status :failed-identically-to-base
    :condition :file-does-not-exist)
   (:check :shop3-projection-subtest
    :command
    "nix develop -c env XDG_CACHE_HOME=/tmp/hyperdoc-eighth-shop3-review-projection-cache sbcl --no-userinit --non-interactive --eval '(require :asdf)' --eval '(asdf:load-system :hyperdoc/scxml)' --eval '(asdf:load-system :hyperdoc/shop3)' --load tests/projection-pipeline-dmx-annotation-smoke.lisp --eval '(assert (hyperdoc/tests::run-projection-pipeline-shop3-smoke-test))' --eval '(format t \"REVIEW_SHOP3_PROJECTION_SUBTEST=:PASS~%\")' --eval '(uiop:quit 0)'"
    :status :passed-with-existing-soft-skip)
   (:check :review-artifact-safe-read-first-wrapper
    :expectation
    "The safe-reader command should read one form and exit successfully."
    :observed-reality
    "The safe read printed REVIEW_ARTIFACT_SAFE_SINGLE_FORM=:PASS, then the wrapper exited 1 because UIOP:QUIT was read without first loading ASDF."
    :classification :validation-wrapper-error
    :resolution "Load ASDF before invoking UIOP:QUIT and rerun."
    :slice-failure nil)
   (:check :review-artifact-safe-read
    :command
    "nix develop -c sbcl --no-userinit --non-interactive --eval '(require :asdf)' --eval '<read review artifact with *READ-EVAL* NIL; require exactly one form>' --eval '(uiop:quit 0)'"
    :status :passed
    :marker "REVIEW_ARTIFACT_SAFE_SINGLE_FORM=:PASS")
   (:check :review-artifact-trailing-whitespace
    :command
    "! rg -n '[[:blank:]]+$' hyperdoc/evidence/refactor-hyperdoc-eighth-dreyeck-extraction-commit-2-review.sexp"
    :status :passed)
   (:check :hauptsache-cleanliness
    :command
    "git -C /Users/rgb/workspace/hauptsache status --short --branch"
    :status :passed
    :output "## main...gitweb/main")))
 (:decision :accept)
 (:classification
  :eighth-dreyeck-extraction-commit-2-reviewed-and-accepted)
 (:next-task
  (!merge-eighth-dreyeck-extraction-commit-2-into-hauptsache))
 (:reconstruction
  (:surface-answer
   (:decision :accept)
   (:package-rename :explicitly-authorized)
   (:next
    (!merge-eighth-dreyeck-extraction-commit-2-into-hauptsache)))
  (:process-trace
   (:inspected
    (:immutable-base-and-head
     :preparation-artifact
     :execution-artifact
     :asdf-definitions
     :six-source-target-pairs
     :old-path-references
     :base-and-head-projection-smokes
     :direct-compatibility-and-dual-load-canaries
     :committed-path-boundary))
   (:inferred
    (:package-rename-is-explicitly-authorized
     :old-live-references-are-compatible-or-deferred
     :projection-failure-predates-execution))
   (:decided
    (:accept-without-repair)))
  (:hyperdoc-reconstruction
   (:pages-created-or-updated nil)
   (:section-level-content-delta nil)
   (:inspectable-objects-added nil)
   (:related-links-added nil)
   (:reason :read-only-review-and-documentation-migration-deferred))
  (:lisp-source-reconstruction
   (:implementation-definitions-added-or-updated nil)
   (:topic-functions-added-or-updated nil)
   (:review-evidence
    "hyperdoc/evidence/refactor-hyperdoc-eighth-dreyeck-extraction-commit-2-review.sexp")
   (:reason :implementation-mutations-forbidden))
  (:fedwiki-twin-reconstruction
   (:pages-created-or-updated nil)
   (:slug nil)
   (:title nil)
   (:summary nil)
   (:references nil)
   (:daily-anchor-updated nil)
   (:reason :cross-repository-mutation-out-of-scope))
  (:replayability-checks
   (:review-evidence-safe-read-required t)
   (:review-evidence-single-form-required t)
   (:git-diff-check-required t)
   (:json-parse-checks :not-applicable-no-fedwiki-json-changed)
   (:journal-integrity-checks :not-applicable-no-fedwiki-json-changed))))
