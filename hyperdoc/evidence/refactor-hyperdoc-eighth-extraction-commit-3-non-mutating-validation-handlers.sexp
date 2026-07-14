(:classification
 :commit-3-non-mutating-validation-handlers-materialized

 :basis-head
 "ce14262674c30964c027e72dae9373eac631414a"

 :implementation-commit
 :this-commit

 :registry-readiness-before
 (:registered 12 :implemented 1 :missing 11)

 :registry-readiness-after
 (:registered 12 :implemented 6 :missing 6)

 :exact-changed-paths
 ("dreyeck/shop3/extraction-planning/executor.lisp"
  "dreyeck/shop3/extraction-planning/tests/executor-smoke.lisp"
  "hyperdoc/evidence/refactor-hyperdoc-eighth-extraction-commit-3-non-mutating-validation-handlers.sexp")

 :new-handler-set
 ("DREYECK/SHOP3::!RUN-SHOP3-REFERENCE-BOUNDARY-FIXTURES"
  "DREYECK/SHOP3::!RUN-DIRECT-SHOP3-LOAD-AND-GAP-CANARY"
  "DREYECK/SHOP3::!RUN-COMPATIBILITY-SHOP3-LOAD-AND-GAP-CANARY"
  "DREYECK/SHOP3::!RUN-DUAL-LOAD-IDENTITY-CANARY"
  "DREYECK/SHOP3::!RUN-REPOSITORY-LOAD-GATE")

 :blocked-handler-set
 ("DREYECK/SHOP3::!DELETE-LEGACY-SHOP3-COPY"
  "DREYECK/SHOP3::!WRITE-SHOP3-REFERENCE-BOUNDARY-CHECKER"
  "DREYECK/SHOP3::!WRITE-SHOP3-REFERENCE-BOUNDARY-FIXTURE"
  "DREYECK/SHOP3::!WIRE-SHOP3-REFERENCE-BOUNDARY-CHECKER"
  "DREYECK/SHOP3::!WRITE-COMMIT-3-EXECUTION-EVIDENCE"
  "DREYECK/SHOP3::!RECORD-COMMIT-3-EXECUTION-COMPLETE")

 :existing-handler-identity-before
 (:operator "DREYECK/SHOP3::!RUN-SHOP3-PROVIDER-BOUNDARY-TESTS"
  :handler "DREYECK/SHOP3/EXECUTOR::%EXECUTE-PROVIDER-BOUNDARY-TESTS")

 :existing-handler-identity-after
 (:operator "DREYECK/SHOP3::!RUN-SHOP3-PROVIDER-BOUNDARY-TESTS"
  :handler "DREYECK/SHOP3/EXECUTOR::%EXECUTE-PROVIDER-BOUNDARY-TESTS"
  :eq-before t)

 :resolved-canary-invocation-surfaces
 ((:name :reference-boundary-fixtures
   :checker "tools/check-shop3-reference-boundary.lisp"
   :fixtures
   ("tools/testdata/shop3-reference-boundary/allowed-added-lines.diff"
    "tools/testdata/shop3-reference-boundary/rejected-added-lines.diff")
   :calling-convention :argv-list
   :authoritative-files-may-be-absent t
   :absent-files-fail-closed t)
  (:name :direct-shop3-gap-canary
   :system :dreyeck/shop3
   :entry-point
   "DREYECK/SHOP3::RUN-KIOSKBEERLI-SALON-SWITCHING-CONTRACT-GAP-PLAN-OBJECT"
   :contract-source
   "/Users/rgb/workspace/hauptsache/docs/operations/kioskbeerli-salon-switching-contract.shop3.lisp"
   :marker "DIRECT_DREYECK_SHOP3_GAP_CANARY=:PASS")
  (:name :compatibility-shop3-gap-canary
   :system :hyperdoc/shop3
   :entry-point
   "DREYECK/SHOP3::RUN-KIOSKBEERLI-SALON-SWITCHING-CONTRACT-GAP-PLAN-OBJECT"
   :contract-source
   "/Users/rgb/workspace/hauptsache/docs/operations/kioskbeerli-salon-switching-contract.shop3.lisp"
   :marker "COMPATIBILITY_HYPERDOC_SHOP3_GAP_CANARY=:PASS")
  (:name :dual-load-package-identity-canary
   :systems (:dreyeck/shop3 :hyperdoc/shop3)
   :identities (:package :class :function)
   :marker "DUAL_LOAD_PACKAGE_IDENTITY_CANARY=:PASS")
  (:name :hyperbook-server-load-gate
   :command ("tools/check-lisp-load-gate.sh" ":hyperbook/server")
   :marker "LOAD_GATE_OK"))

 :dependency-presence-tests
 ((:direct-canary-dependency-present-p t)
  (:compatibility-canary-dependency-present-p t)
  (:dual-load-canary-dependency-present-p t)
  (:load-gate-dependency-present-p t)
  (:missing-direct-canary-dependency :fails :handler-failure)
  (:missing-compatibility-canary-dependency :fails :handler-failure)
  (:missing-dual-load-canary-dependency :fails :handler-failure)
  (:missing-load-gate-dependency :fails :handler-failure)
  (:missing-reference-boundary-dependency :fails :handler-failure))

 :temporary-fixture-isolation-tests
 (:temporary-root-outside-repository-p t
  :temporary-root-not-under-repository-truename-p t
  :cleanup-with-unwind-protect-p t
  :cleanup-after-success-p t
  :cleanup-after-failure-p t
  :temporary-fixture-cleanup-after-success-p t
  :temporary-fixture-cleanup-after-failure-p t
  :temporary-files-visible-to-git-p nil
  :temporary-files-staged-p nil
  :temporary-fixture-never-visible-to-git-p t
  :hyperdoc-repository-snapshot-equal-before-and-after-p t)

 :handler-safety-contract
 (:mutation-class :non-mutating-validation
  :operator-arity 0
  :argv-list-command-p t
  :shell-command-string-p nil
  :directory-from-executor-repository-root-p t
  :capture-stdout-p t
  :capture-stderr-p t
  :capture-exit-status-p t
  :verify-expected-marker-p t
  :verify-repository-unchanged-p t
  :observed-repository-fields
  (:head
   :branch
   :porcelain-v2-status
   :cached-diff
   :unmerged-paths
   :merge-rebase-cherry-pick-revert-state))

 :full-plan-preflight-result
 (:failure-type :execute-handler-unavailable
  :registered-operator-count 12
  :implemented-handler-count 6
  :missing-handler-count 6
  :missing-action-indexes (1 2 3 4 5 6 7 8 9 10 17 18)
  :handler-invoked-p nil
  :action-started-event-count 0
  :executed-action-count 0
  :mutations-performed nil)

 :validation-subplan-preflight-result
 (:plan-valid-p t
  :action-count 6
  :missing-handler-count 0
  :handler-coverage-complete-p t
  :executed-in-authoritative-repository-p nil)

 :handler-success-matrix
 (("DREYECK/SHOP3::!RUN-SHOP3-REFERENCE-BOUNDARY-FIXTURES"
   :status :executed :marker-observed-p t
   :repository-unchanged-p t :mutations-performed nil)
  ("DREYECK/SHOP3::!RUN-DIRECT-SHOP3-LOAD-AND-GAP-CANARY"
   :status :executed :marker-observed-p t
   :repository-unchanged-p t :mutations-performed nil)
  ("DREYECK/SHOP3::!RUN-COMPATIBILITY-SHOP3-LOAD-AND-GAP-CANARY"
   :status :executed :marker-observed-p t
   :repository-unchanged-p t :mutations-performed nil)
  ("DREYECK/SHOP3::!RUN-DUAL-LOAD-IDENTITY-CANARY"
   :status :executed :marker-observed-p t
   :repository-unchanged-p t :mutations-performed nil)
  ("DREYECK/SHOP3::!RUN-REPOSITORY-LOAD-GATE"
   :status :executed :marker-observed-p t
   :repository-unchanged-p t :mutations-performed nil))

 :handler-failure-matrix
 (("DREYECK/SHOP3::!RUN-SHOP3-REFERENCE-BOUNDARY-FIXTURES"
   :failure-type :handler-failure :later-handler-invoked-p nil
   :mutations-performed nil)
  ("DREYECK/SHOP3::!RUN-DIRECT-SHOP3-LOAD-AND-GAP-CANARY"
   :failure-type :handler-failure :later-handler-invoked-p nil
   :mutations-performed nil)
  ("DREYECK/SHOP3::!RUN-COMPATIBILITY-SHOP3-LOAD-AND-GAP-CANARY"
   :failure-type :handler-failure :later-handler-invoked-p nil
   :mutations-performed nil)
  ("DREYECK/SHOP3::!RUN-DUAL-LOAD-IDENTITY-CANARY"
   :failure-type :handler-failure :later-handler-invoked-p nil
   :mutations-performed nil)
  ("DREYECK/SHOP3::!RUN-REPOSITORY-LOAD-GATE"
   :failure-type :handler-failure :later-handler-invoked-p nil
   :mutations-performed nil))

 :repository-unchanged-checks
 (:command-directory-is-executor-root-p t
  :before-and-after-snapshots-retained-p t
  :successful-command-with-state-delta-fails-p t
  :handler-failure-retains-command-and-snapshots-p t
  :existing-provider-handler-identity-unchanged-p t)

 :legacy-execution-closure
 ((:legacy-execute-plan
   :failure-type :armed-entry-point-required
   :handler-invoked-p nil
   :executed-action-count 0
   :mutations-performed nil)
  (:direct-action-execution
   :failure-type :execute-plan-required
   :handler-invoked-p nil))

 :test-results
 ((:check :git-diff-check :status :passed)
  (:check :repository-parenthesis-checker :status :passed)
  (:check :fresh-load :system :dreyeck/shop3/extraction-planning
   :status :passed :registry-counts (12 6 6))
  (:check :fresh-test :system :dreyeck/shop3/extraction-planning/tests
   :status :passed :marker "FRESH_EXTRACTION_PLANNING_TESTS_OK")
  (:check :fresh-test :system :hyperdoc/shop3-provider-boundary/tests
   :status :passed :marker "FRESH_PROVIDER_BOUNDARY_TESTS_OK")
  (:check :direct-gap-canary :status :passed
   :marker "DIRECT_DREYECK_SHOP3_GAP_CANARY=:PASS")
  (:check :compatibility-gap-canary :status :passed
   :marker "COMPATIBILITY_HYPERDOC_SHOP3_GAP_CANARY=:PASS")
  (:check :dual-load-identity-canary :status :passed
   :marker "DUAL_LOAD_PACKAGE_IDENTITY_CANARY=:PASS")
  (:check :repository-load-gate :status :passed
   :marker "LOAD_GATE_OK")
  (:check :safe-single-form-evidence-read :status :passed
   :read-eval nil :one-form-followed-by-eof t)
  (:check :verify-exact-three-changed-paths :status :passed)
  (:check :verify-registry-counts :status :passed
   :registered 12 :implemented 6 :missing 6)
  (:check :verify-full-plan-preflight :status :passed)
  (:check :verify-validation-subplan-handler-coverage :status :passed)
  (:check :targeted-handler-matrix :fresh-process t :status :passed
   :marker "AFTER_EXECUTOR_TEST"))

 :validation-expectation-records
 ((:expectation
   "UIOP exposes FIND-PROGRAM-PATHNAME in the repository's authoritative ASDF version."
   :observed-reality
   "The symbol is not exported by this UIOP version."
   :plausibility
   "Later UIOP variants and remembered APIs provide similarly named executable lookup helpers."
   :classification :validation-helper-portability-failure
   :resolution
   "Probe trusted programs with an argv-list PROGRAM --version invocation."
   :prevention
   "Compile in nix develop before expanding the handler test matrix.")
  (:expectation
   "TRUENAME can verify a unique temporary root immediately after pathname construction."
   :observed-reality
   "TRUENAME failed because the test had not created the directory yet."
   :plausibility
   "The resolver creates fixture files later in the same test path."
   :classification :test-fixture-lifecycle-failure
   :resolution
   "Create the temporary directory before checking its truename."
   :prevention
   "Keep creation, truename isolation assertion, execution, and unwind-protect cleanup ordered explicitly.")
  (:expectation
   "The evidence form is readable in a clean image before executor packages exist."
   :observed-reality
   "Package-qualified identity symbols made the first safe read package-dependent, and a reconstruction parenthesis ended the first form early."
   :plausibility
   "The identity names are valid after loading extraction planning, and visual indentation suggested one enclosing form."
   :classification :evidence-portability-failure
   :resolution
   "Represent package identities as strings, repair the reconstruction nesting, and require one form followed by EOF with *READ-EVAL* NIL."
   :prevention
   "Run the clean-image safe reader before staging evidence.")
  (:expectation
   "GIT DIFF --NAME-ONLY lists all three changed paths."
   :observed-reality
   "The new untracked evidence file is intentionally absent from ordinary diff output."
   :plausibility
   "The two tracked modifications were listed and the desired scope was exactly three paths."
   :classification :validation-wrapper-error
   :resolution
   "Verify the pre-stage path set from GIT STATUS --SHORT, preserving its leading status columns."
   :prevention
   "Use porcelain status when scope includes untracked files."))

 :reconstruction
 (:surface-answer
  (:classification
   :commit-3-non-mutating-validation-handlers-materialized)
 :process-trace
 (:inspected
  (:operator-registry
   :armed-execution-path
   :historical-canary-evidence
   :repository-native-load-gate
   :hauptsache-gap-canary-contract)
 :inferred
 (:one-private-resolver-preserves-closed-dispatch
  :temporary-fixtures-must-remain-outside-git-root)
 :decided
 (:add-five-validation-handlers
  :preserve-six-blocked-handlers
  :do-not-execute-authoritative-validation-subplan))
 :hyperdoc-reconstruction
 (:pages-created-or-updated nil
  :section-level-content-delta nil
  :inspectable-objects-added nil
  :related-links-added nil
  :evidence-file
  "hyperdoc/evidence/refactor-hyperdoc-eighth-extraction-commit-3-non-mutating-validation-handlers.sexp")
 :lisp-source-reconstruction
 (:executor-functions
  ("DREYECK/SHOP3/EXECUTOR::%EXECUTE-REFERENCE-BOUNDARY-FIXTURES"
   "DREYECK/SHOP3/EXECUTOR::%EXECUTE-DIRECT-SHOP3-GAP-CANARY"
   "DREYECK/SHOP3/EXECUTOR::%EXECUTE-COMPATIBILITY-SHOP3-GAP-CANARY"
   "DREYECK/SHOP3/EXECUTOR::%EXECUTE-DUAL-LOAD-IDENTITY-CANARY"
   "DREYECK/SHOP3/EXECUTOR::%EXECUTE-REPOSITORY-LOAD-GATE")
  :test-entry-point
  "DREYECK/SHOP3/EXTRACTION-PLANNING/TESTS::RUN-EIGHTH-EXTRACTION-COMMIT-3-EXECUTOR-SMOKE-TESTS")
 :fedwiki-twin-reconstruction
 (:pages-created-or-updated nil
  :daily-anchor-updated nil
  :reason :executor-only-evidence-slice)
 :replayability-checks
 (:safe-single-form-evidence-read :required
  :fresh-asdf-load :required
  :fresh-asdf-tests :required
  :git-diff-check :required))

 :legacy-files-deleted nil
 :mutation-handlers-added nil
 :commit-3-executed-action-count 0
 :mutations-performed nil
 :perform-commit-3 nil)
