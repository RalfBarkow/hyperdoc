(:refactor-hyperdoc-eighth-extraction-commit-3-executor-arming-gate-and-context
 (:classification :commit-3-executor-arming-gate-materialized)
 (:basis-head "6265f68e1c6cd27c74773a7589819bad0f75f06b")
 (:approval :revised-contract-approved)
 (:implementation-commit :this-commit)
 (:perform-commit-3 nil)

 (:changed-paths
  ("dreyeck/shop3/extraction-planning/executor-package.lisp"
   "dreyeck/shop3/extraction-planning/executor.lisp"
   "dreyeck/shop3/extraction-planning/tests/executor-smoke.lisp"
   "hyperdoc/evidence/refactor-hyperdoc-eighth-extraction-commit-3-executor-arming-gate-and-context.sexp"))

 (:public-api
  (:preserved
   ("COMMIT-3-EXECUTION-PLAN"
    "EXECUTE-PLAN"
    "EXECUTE-PLAN-ACTION"
    "MAKE-COMMIT-3-EXECUTOR"
    "NORMALIZE-SHOP3-PLAN"
    "OPERATOR-REGISTRY"
    "RESOLVE-OPERATOR-HANDLER"))
  (:added
   ("EXECUTE-PLAN-ARMED"
    "MAKE-COMMIT-3-EXECUTION-CONTEXT"
    "COMMIT-3-EXECUTION-CONTEXT-REPORT"))
  (:not-exported
   (:context-structure-type
    :context-accessors
    :low-level-context-constructor
    :private-test-context-constructor
    :private-authorization-object)))

 (:context
  (:representation :private-opaque-structure)
  (:public-constructor-call
   "(make-commit-3-execution-context executor plan repository-root expected-head expected-branch provenance-commit)")
  (:success-values "(values context nil)")
  (:failure-values "(values nil structured-failure)")
  (:slots
   (:executor
    :repository-root
    :expected-head
    :expected-branch
    :provenance-commit
    :canonical-plan
    :canonical-plan-fingerprint
    :authorization-object
    :creation-report))
  (:authorization-object
   (:visibility :private)
   (:identity-semantics :capability-identity)
   (:caller-supplied nil)
   (:public-report-purpose :perform-eighth-dreyeck-extraction-commit-3))
  (:canonical-plan
   (:normalizer "NORMALIZE-SHOP3-PLAN")
   (:comparison "EQUAL")
   (:action-order-preserved t)
   (:fresh-proper-list t)
   (:idempotent t)
   (:fingerprint-algorithm :sha-256)
   (:fingerprint-authoritative nil)
   (:sha-256-facility
    (:program "shasum -a 256")
    (:repository-precedent "HYPERDOC/MECH-DEPLOYMENT-PROVENANCE.LISP")
    (:asdf-dependency-added nil))))

 (:gate-order
  ((1 :normalize-plan)
   (2 :validate-all-actions)
   (3 :require-execute-handler-for-every-action)
   (4 :validate-context-type)
   (5 :validate-executor-identity)
   (6 :validate-authorization-object)
   (7 :validate-canonical-plan-match)
   (8 :reobserve-repository-state)
   (9 :verify-provenance-integrity)
   (10 :bind-private-dynamic-execution-authority)
   (11 :invoke-first-handler)))

 (:repository-observation-matrix
  ((:command ("git" "rev-parse" "--is-inside-work-tree")
    :require "true")
   (:command ("git" "rev-parse" "--show-toplevel")
    :require :canonical-executor-root)
   (:command ("git" "rev-parse" "HEAD")
    :require :expected-head)
   (:command ("git" "branch" "--show-current")
    :require "hauptsache")
   (:command ("git" "status" "--porcelain=v2" "--untracked-files=all")
    :require :empty-output)
   (:command ("git" "diff" "--name-only" "--diff-filter=U")
    :require :empty-output)
   (:command ("git" "rev-parse" "--verify" "-q" "MERGE_HEAD")
    :require :nonzero-exit)
   (:command ("git" "rev-parse" "--git-path" "rebase-merge")
    :require :path-absent)
   (:command ("git" "rev-parse" "--git-path" "rebase-apply")
    :require :path-absent)
   (:command ("git" "rev-parse" "--verify" "-q" "CHERRY_PICK_HEAD")
    :require :nonzero-exit)
   (:command ("git" "rev-parse" "--verify" "-q" "REVERT_HEAD")
    :require :nonzero-exit)))

 (:provenance-verification
  (:commit "6265f68e1c6cd27c74773a7589819bad0f75f06b")
  (:commands
   (("git" "cat-file" "-e"
     "6265f68e1c6cd27c74773a7589819bad0f75f06b^{commit}")
    ("git" "merge-base" "--is-ancestor"
     "6265f68e1c6cd27c74773a7589819bad0f75f06b" "HEAD")
    ("git" "log" "-1" "--pretty=%s"
     "6265f68e1c6cd27c74773a7589819bad0f75f06b")
    ("git" "diff-tree" "--no-commit-id" "--name-only" "-r"
     "6265f68e1c6cd27c74773a7589819bad0f75f06b")))
  (:expected-subject "fix(shop3): preserve HyperDoc package identity")
  (:expected-paths ("dreyeck/shop3/package.lisp"))
  (:exists-p t)
  (:reachable-p t)
  (:subject-match-p t)
  (:paths-match-p t))

 (:failure-matrix
  ((:case :plan-only-without-context :result :passes)
   (:case :legacy-execute-plan
    :failure-type :armed-entry-point-required
    :execution-authorized-p nil
    :handler-invoked-p nil)
   (:case :armed-entry-point-without-context :signals :program-error)
   (:case :wrong-context-type :failure-type :execution-context-wrong-type)
   (:case :other-executor-context
    :failure-type :execution-context-executor-mismatch)
   (:case :noncanonical-public-constructor-plan
    :failure-type :execution-context-plan-mismatch)
   (:case :different-plan-at-execution
    :failure-type :execution-context-plan-mismatch)
   (:case :dirty-fixture
    :failure-type :execution-context-worktree-dirty)
   (:case :merge-in-progress
    :failure-type :execution-context-repository-operation-in-progress)
   (:case :rebase-in-progress
    :failure-type :execution-context-repository-operation-in-progress)
   (:case :head-moved :failure-type :execution-context-head-mismatch)
   (:case :missing-provenance
    :failure-type :execution-context-provenance-missing)
   (:case :unreachable-provenance
    :failure-type :execution-context-provenance-unreachable)
   (:case :current-eighteen-action-plan
    :failure-type :execute-handler-unavailable
    :executed-action-count 0
    :mutations-performed nil)
   (:case :first-action-missing-handler
    :failure-type :execute-handler-unavailable
    :handler-invoked-p nil)
   (:case :direct-action-execute
    :failure-type :execute-plan-required
    :handler-invoked-p nil
    :action-started-event-count 0)
   (:case :normalization-idempotent :result :passes)
   (:case :raw-and-shorter-plan-canonical-forms :equal-p t)
   (:case :single-provider-handler-through-private-test-context
    :executed-action-count 1
    :mutations-performed nil)
   (:case :intentional-provider-handler-failure
    :failure-type :handler-failure
    :later-handler-invoked-p nil)
   (:case :registry-readiness
    :registered 12
    :implemented 1
    :missing 11)))

 (:example-gate-report
  (:status :failed
   :failure
   (:type :execute-handler-unavailable
    :missing-handler-count 11
    :execution-authorized-p nil
    :handler-invoked-p nil
    :executed-action-count 0
    :mutations-performed nil
    :action-started-event-count 0)
   :execution-authorized-p nil
   :executor-identity-match-p nil
   :repository-root nil
   :observed-head nil
   :observed-branch nil
   :worktree-clean-p nil
   :repository-operation-state-clean-p nil
   :provenance-commit nil
   :provenance-exists-p nil
   :provenance-reachable-p nil
   :provenance-subject-match-p nil
   :provenance-paths-match-p nil
   :canonical-plan-action-count 18
   :canonical-plan-fingerprint
   "915314418203322befb1a7a9caec90a708cadc42f997cc27e036ebd0cb6dc201"
   :canonical-plan-match-p nil
   :registered-operator-count 12
   :implemented-handler-count 1
   :missing-handler-count 11
   :missing-action-indexes (1 2 3 4 5 6 7 8 9 10 11 12 13 14 16 17 18)
   :missing-operators
   ("!DELETE-LEGACY-SHOP3-COPY"
    "!WRITE-SHOP3-REFERENCE-BOUNDARY-CHECKER"
    "!WRITE-SHOP3-REFERENCE-BOUNDARY-FIXTURE"
    "!WIRE-SHOP3-REFERENCE-BOUNDARY-CHECKER"
    "!RUN-SHOP3-REFERENCE-BOUNDARY-FIXTURES"
    "!RUN-DIRECT-SHOP3-LOAD-AND-GAP-CANARY"
    "!RUN-COMPATIBILITY-SHOP3-LOAD-AND-GAP-CANARY"
    "!RUN-DUAL-LOAD-IDENTITY-CANARY"
    "!RUN-REPOSITORY-LOAD-GATE"
    "!WRITE-COMMIT-3-EXECUTION-EVIDENCE"
    "!RECORD-COMMIT-3-EXECUTION-COMPLETE")
   :gate-steps
   ((:step-number 1 :name :normalize-plan :status :passed
     :failure-type nil)
    (:step-number 2 :name :validate-all-actions :status :passed
     :failure-type nil)
    (:step-number 3 :name :require-execute-handler-for-every-action
     :status :failed :failure-type :execute-handler-unavailable)
    (:step-number 4 :name :validate-context-type :status :not-reached
     :failure-type nil)
    (:step-number 5 :name :validate-executor-identity :status :not-reached
     :failure-type nil)
    (:step-number 6 :name :validate-authorization-object :status :not-reached
     :failure-type nil)
    (:step-number 7 :name :validate-canonical-plan-match :status :not-reached
     :failure-type nil)
    (:step-number 8 :name :reobserve-repository-state :status :not-reached
     :failure-type nil)
    (:step-number 9 :name :verify-provenance-integrity :status :not-reached
     :failure-type nil)
    (:step-number 10 :name :bind-private-dynamic-execution-authority
     :status :not-reached :failure-type nil)
    (:step-number 11 :name :invoke-first-handler :status :not-reached
     :failure-type nil)))

 (:test-results
  ((:check :git-diff-check :status :passed)
   (:check :lisp-parenthesis-checker
    :paths :exact-changed-lisp-and-sexp-paths
    :status :passed)
   (:check :load-dreyeck-shop3-extraction-planning
    :fresh-sbcl t :status :passed)
   (:check :test-dreyeck-shop3-extraction-planning
    :fresh-sbcl t :status :passed)
   (:check :test-hyperdoc-shop3-provider-boundary
    :fresh-sbcl t :status :passed)
   (:check :direct-dreyeck-shop3-package-aware-gap-canary
    :fresh-sbcl t :marker "DIRECT_DREYECK_SHOP3_GAP_CANARY=:PASS"
    :status :passed)
   (:check :compatibility-hyperdoc-shop3-package-aware-gap-canary
    :fresh-sbcl t
    :marker "COMPATIBILITY_HYPERDOC_SHOP3_GAP_CANARY=:PASS"
    :status :passed)
   (:check :dual-load-package-identity-canary
    :fresh-sbcl t :marker "DUAL_LOAD_PACKAGE_IDENTITY_CANARY=:PASS"
    :status :passed)
   (:check :repository-load-gate
    :system :hyperbook/server :fresh-sbcl t :marker "LOAD_GATE_OK"
    :status :passed)
   (:check :safe-single-form-evidence-read
    :read-eval nil :status :passed)))

 (:validation-expectation-record
  (:expectation
   "The exact post-validation readiness assertion will confirm that the direct-action bypass is closed.")
  (:observed-reality
   "The first wrapper passed :TYPE as GETF's default argument instead of reading :TYPE from the nested :CONDITION plist, so it reported NIL.")
  (:plausibility
   "The wrapper expression visually contained all three keywords and the dedicated direct-action smoke test had already passed.")
  (:classification :validation-wrapper-error)
  (:resolution
   :read-action-result-then-condition-then-type-and-rerun)
  (:corrected-result :passed)
  (:slice-failure nil))

 (:registry-counts
  (:before (:registered 12 :implemented 1 :missing 11)
   :after (:registered 12 :implemented 1 :missing 11)))

 (:safety-result
  (:registered-operator-count 12
   :implemented-handler-count 1
   :missing-handler-count 11
   :current-full-plan-executable-p nil
   :legacy-execute-entry-closed-p t
   :direct-action-bypass-closed-p t
   :existing-handler-remains-non-mutating-p t
   :legacy-files-deleted-p nil
   :handlers-added-p nil
   :commit-3-executed-action-count 0
   :mutations-performed nil
   :perform-commit-3 nil))

 (:expectation-record
  (:expectation
   "Passing :MODE :EXECUTE to EXECUTE-PLAN, or calling EXECUTE-PLAN-ACTION directly, can execute an available handler.")
  (:observed-reality
   "Both legacy paths now fail before handler dispatch and require the opaque armed entry point.")
  (:plausibility
   "The previous public executor and its tests explicitly allowed both execute-mode paths.")
  (:classification :disappointed-expectation)
  (:resolution
   :close-both-legacy-authority-paths-and-add-explicit-context-bound-entry)
  (:prevention
   :ordered-gate-report-tests-and-private-dynamic-capability))

 (:answer-reconstruction
  (:surface-answer
   (:classification :commit-3-executor-arming-gate-materialized-and-committed)
   (:perform-commit-3 nil))
  (:process-trace
   (:inspected
    (:basis-head
     :branch-and-cleanliness
     :executor-api-and-dispatch
     :live-eighteen-action-plan
     :sha-256-precedent
     :repository-validation-canaries))
   (:inferred
    (:handler-preflight-must-count-distinct-missing-operators
     :repository-context-must-be-reobserved-at-execution
     :fingerprint-is-diagnostic-only))
   (:decided
    (:opaque-private-capability-context
     :legacy-entry-closed
     :direct-action-bypass-closed
     :no-commit-3-execution)))
  (:hyperdoc-reconstruction
   (:genre :reference-contract-evidence)
   (:artifact
    "hyperdoc/evidence/refactor-hyperdoc-eighth-extraction-commit-3-executor-arming-gate-and-context.sexp")
   (:sections
    (:public-api
     :context
     :gate-order
     :repository-observation-matrix
     :provenance-verification
     :failure-matrix
     :validation
     :safety-result)))
  (:lisp-source-reconstruction
   (:package-api
    "dreyeck/shop3/extraction-planning/executor-package.lisp")
   (:context-gates-and-dispatch
    "dreyeck/shop3/extraction-planning/executor.lisp")
   (:fixture-and-failure-tests
    "dreyeck/shop3/extraction-planning/tests/executor-smoke.lisp"))
  (:fedwiki-twin-reconstruction
   (:status :not-modified)
   (:reason :exact-four-path-authorization-excludes-fedwiki-pages)
   (:daily-anchor :not-added))
  (:replayability-checks
   (:fresh-external-sbcl-only t)
   (:safe-single-form-read t)
   (:load-gate "LOAD_GATE_OK")
   (:commit-3-performed nil)))))
