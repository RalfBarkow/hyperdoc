(:classification
 :commit-3-validation-subplan-authorization-materialized

 :basis-head
 "19b910dba02307294164fcb477dc401b2a3f4b35"

 :implementation-commit
 :this-commit

 :new-public-api
 (commit-3-non-mutating-validation-subplan
  make-commit-3-validation-execution-context)

 :authorization-purposes
 (:full-plan
  :perform-eighth-dreyeck-extraction-commit-3

  :validation-subplan
  :execute-commit-3-non-mutating-validation-subplan)

 :validation-scope
 (:action-count 6
  :required-mutation-class :non-mutating-validation
  :nil-mutation-class-accepted-p nil)

 :executor-readiness
 (:registered 12
  :implemented 6
  :missing 6
  :full-plan-executable-p nil)

 :validation-subplan-executed-p nil
 :handlers-added nil
 :mutation-handlers-added nil
 :legacy-files-deleted nil
 :commit-3-executed-action-count 0
 :mutations-performed nil
 :perform-commit-3 nil

 :exact-changed-paths
 ("dreyeck/shop3/extraction-planning/executor-package.lisp"
  "dreyeck/shop3/extraction-planning/executor.lisp"
  "dreyeck/shop3/extraction-planning/tests/executor-smoke.lisp"
  "hyperdoc/evidence/refactor-hyperdoc-eighth-extraction-commit-3-validation-subplan-authorization.sexp")

 :public-api-before
 (commit-3-execution-plan
  commit-3-execution-context-report
  execute-plan
  execute-plan-armed
  execute-plan-action
  make-commit-3-executor
  make-commit-3-execution-context
  normalize-shop3-plan
  operator-registry
  resolve-operator-handler)

 :public-api-after
 (commit-3-execution-plan
  commit-3-execution-context-report
  commit-3-non-mutating-validation-subplan
  execute-plan
  execute-plan-armed
  execute-plan-action
  make-commit-3-executor
  make-commit-3-execution-context
  make-commit-3-validation-execution-context
  normalize-shop3-plan
  operator-registry
  resolve-operator-handler)

 :canonical-validation-subplan
 ("DREYECK/SHOP3::!RUN-SHOP3-REFERENCE-BOUNDARY-FIXTURES"
  "DREYECK/SHOP3::!RUN-DIRECT-SHOP3-LOAD-AND-GAP-CANARY"
  "DREYECK/SHOP3::!RUN-COMPATIBILITY-SHOP3-LOAD-AND-GAP-CANARY"
  "DREYECK/SHOP3::!RUN-DUAL-LOAD-IDENTITY-CANARY"
  "DREYECK/SHOP3::!RUN-SHOP3-PROVIDER-BOUNDARY-TESTS"
  "DREYECK/SHOP3::!RUN-REPOSITORY-LOAD-GATE")

 :capability-pair-matrix
 ((:capability :full-private
   :required-plan :canonical-eighteen-action-commit-3-plan
   :purpose :perform-eighth-dreyeck-extraction-commit-3
   :accepted-p t)
  (:capability :validation-private
   :required-plan :exact-six-action-validation-subplan
   :purpose :execute-commit-3-non-mutating-validation-subplan
   :accepted-p t)
  (:capability :full-private
   :required-plan :exact-six-action-validation-subplan
   :accepted-p nil)
  (:capability :validation-private
   :required-plan :canonical-eighteen-action-commit-3-plan
   :accepted-p nil)
  (:capability :unknown-private
   :required-plan :any-plan
   :purpose nil
   :accepted-p nil))

 :cross-capability-failure-matrix
 ((:case :full-context-with-validation-plan
   :failure-type :execution-context-authorization-mismatch
   :handler-invoked-p nil
   :action-started-event-count 0
   :executed-action-count 0
   :mutations-performed nil)
  (:case :validation-context-with-full-plan
   :failure-type :execution-context-authorization-mismatch
   :handler-invoked-p nil
   :action-started-event-count 0
   :executed-action-count 0
   :mutations-performed nil)
  (:case :validation-context-with-reordered-subplan
   :failure-type :execution-context-plan-mismatch
   :handler-invoked-p nil
   :executed-action-count 0
   :mutations-performed nil)
  (:case :unknown-private-capability
   :authorization-purpose nil
   :failure-type :execution-context-authorization-mismatch
   :handler-invoked-p nil
   :action-started-event-count 0
   :executed-action-count 0
   :mutations-performed nil))

 :mutation-class-guard-matrix
 ((:mutation-class nil
   :accepted-p nil
   :failure-type :execution-context-scope-violation)
  (:mutation-class :mutating
   :accepted-p nil
   :failure-type :execution-context-scope-violation)
  (:mutation-class :destructive
   :accepted-p nil
   :failure-type :execution-context-scope-violation)
  (:mutation-class :repository-write
   :accepted-p nil
   :failure-type :execution-context-scope-violation)
  (:mutation-class :future-unknown-class
   :accepted-p nil
   :failure-type :execution-context-scope-violation))

 :mutation-class-guard-common-result
 (:authorization-purpose
  :execute-commit-3-non-mutating-validation-subplan
  :handler-invoked-p nil
  :action-started-event-count 0
  :executed-action-count 0
  :mutations-performed nil)

 :context-report-examples
 ((:context-kind :full
   :status :available
   :authorization-purpose :perform-eighth-dreyeck-extraction-commit-3
   :capability-object-exposed-p nil)
  (:context-kind :validation
   :status :available
   :authorization-purpose
   :execute-commit-3-non-mutating-validation-subplan
   :canonical-plan-action-count 6
   :capability-object-exposed-p nil)
  (:context-kind :wrong-type
   :status :failed
   :authorization-purpose nil
   :failure (:type :execution-context-wrong-type))
  (:context-kind :unknown-private-capability
   :status :available
   :authorization-purpose nil
   :capability-object-exposed-p nil))

 :repository-and-provenance-tests
 ((:case :validation-context-construction :result :passed)
  (:case :validation-constructor-no-plan-parameter :result :passed)
  (:case :validation-constructor-no-authorization-parameter :result :passed)
  (:case :wrong-executor
   :failure-type :execution-context-invalid-executor)
  (:case :other-executor
   :failure-type :execution-context-executor-mismatch)
  (:case :dirty-worktree
   :failure-type :execution-context-worktree-dirty)
  (:case :head-moved
   :failure-type :execution-context-head-mismatch)
  (:case :wrong-branch
   :failure-type :execution-context-branch-mismatch)
  (:case :wrong-provenance
   :failure-type :execution-context-provenance-commit-mismatch)
  (:fixture-policy
   :clean-no-local-clone-of-basis-repository
   :authoritative-worktree-validation-plan-executed-p nil))

 :full-plan-regression-results
 (:legacy-execute-failure-type :armed-entry-point-required
  :direct-action-execute-failure-type :execute-plan-required
  :full-plan-preflight-failure-type :execute-handler-unavailable
  :missing-handler-count 6
  :registered-operator-count 12
  :implemented-handler-count 6
  :executed-action-count 0
  :mutations-performed nil
  :full-plan-context-semantics-preserved-p t)

 :validation-subplan-preflight-result
 (:plan-valid-p t
  :canonical-plan-action-count 6
  :missing-handler-count 0
  :failure-type :execution-context-wrong-type
  :handler-invoked-p nil
  :action-started-event-count 0
  :executed-action-count 0
  :mutations-performed nil
  :authoritative-execution-attempted-p nil)

 :expectation-artifacts
 ((:expectation
   "The extracted shared context constructor is structurally balanced."
   :observed-reality
   "The first fresh load found one unmatched closing parenthesis."
   :plausibility
   "The refactor preserved the original nested validation sequence."
   :classification :materialization-structure-error
   :resolution
   "Removed the extra closing parenthesis and repeated the fresh load."
   :prevention
   "Compile the extracted constructor in a fresh process before expanding tests.")
  (:expectation
   "Wrong-arity API probes compile as ordinary runtime assertions."
   :observed-reality
   "SBCL emitted compile-time arity warnings and the test system treats warnings as fatal."
   :plausibility
   "The calls were inside HANDLER-CASE and intended to signal PROGRAM-ERROR."
   :classification :test-harness-expectation
   :resolution
   "Resolved the function dynamically with SYMBOL-FUNCTION before APPLY."
   :prevention
   "Use dynamic function resolution for intentional wrong-arity probes in warning-fatal systems.")
  (:expectation
   "Public handler overrides can complete full-plan preflight in a cross-capability fixture."
   :observed-reality
   "The executor correctly rejects overrides for mutating operator specifications."
   :plausibility
   "No handler would be dispatched because authorization-pair validation precedes dispatch."
   :classification :false-test-fixture-expectation
   :resolution
   "Injected no-op handlers only into the private fixture registry specifications."
   :prevention
   "Preserve the public non-mutating override boundary and use private registry fixtures for negative gate tests.")
  (:expectation
   "The staged-only repository parenthesis helper can use a temporary Git index before final staging."
   :observed-reality
   "The restricted environment denied the temporary index operation when Git attempted to write repository objects."
   :plausibility
   "The temporary index itself was under /tmp and the helper reads only staged paths."
   :classification :host-permission-environment-failure
   :resolution
   "Defer the repository helper to the required final staging on the real index."
   :prevention
   "Account for Git object-store writes even when GIT_INDEX_FILE points outside the repository."))

 :test-results
 ((:check :git-diff-check :status :passed)
  (:check :repository-parenthesis-checker
   :status :passed
   :paths :exact-four-authorized-paths)
  (:check :early-fresh-load
   :status :passed
   :marker "EARLY_VALIDATION_AUTHORIZATION_LOAD_OK")
  (:check :fresh-load
   :system :dreyeck/shop3/extraction-planning
   :status :passed
   :marker "FRESH_VALIDATION_AUTHORIZATION_LOAD_OK")
  (:check :fresh-test
   :system :dreyeck/shop3/extraction-planning/tests
   :status :passed
   :marker "FRESH_EXTRACTION_PLANNING_TESTS_OK")
  (:check :fresh-test
   :system :hyperdoc/shop3-provider-boundary/tests
   :status :passed
   :marker "FRESH_PROVIDER_BOUNDARY_TESTS_OK")
  (:check :direct-gap-canary
   :status :passed
   :marker "DIRECT_DREYECK_SHOP3_GAP_CANARY=:PASS")
  (:check :compatibility-gap-canary
   :status :passed
   :marker "COMPATIBILITY_HYPERDOC_SHOP3_GAP_CANARY=:PASS")
  (:check :dual-load-identity-canary
   :status :passed
   :marker "DUAL_LOAD_PACKAGE_IDENTITY_CANARY=:PASS")
  (:check :repository-load-gate
   :system :hyperbook/server
   :status :passed
   :marker "LOAD_GATE_OK")
  (:check :safe-single-form-evidence-read
   :read-eval nil
   :one-form-followed-by-eof t
   :status :passed
   :marker "SAFE_SINGLE_FORM_EVIDENCE_READ_OK")
  (:check :verify-exact-four-changed-paths :status :passed)
  (:check :verify-public-api :status :passed)
  (:check :verify-registry-counts
   :registered 12 :implemented 6 :missing 6
   :status :passed)
  (:check :verify-full-plan-still-fails-before-handler
   :failure-type :execute-handler-unavailable
   :handler-invoked-p nil
   :executed-action-count 0
   :status :passed)
  (:check :verify-validation-context-constructible
   :basis-clone-head
   "19b910dba02307294164fcb477dc401b2a3f4b35"
   :status :passed
   :marker "VALIDATION_PRODUCTION_CONTEXT_CONSTRUCTIBLE_OK")
  (:check :verify-validation-subplan-not-executed
   :preflight-failure-type :execution-context-wrong-type
   :handler-invoked-p nil
   :action-started-event-count 0
   :executed-action-count 0
   :mutations-performed nil
   :status :passed
   :marker "PUBLIC_API_REGISTRY_PREFLIGHT_NONEXECUTION_OK")
  (:check :final-serial-validation :status :passed))

 :process-trace
 (:inspected
  ("materialization request"
   "basis Git state"
   "executor package exports"
   "execution-context construction and armed gate"
   "closed operator registry"
   "executor smoke fixtures")
  :inferred
  ("The validation authority must be a capability-and-plan pair."
   "Mutation-class scope must be checked after complete handler preflight and before repository observation or dispatch."
   "A clean clone is needed to test production context construction while the implementation worktree is dirty.")
  :decided
  ("Add exactly two exports."
   "Keep both capability objects private and identity-distinct."
   "Keep arbitrary fixture plans available only through the private test constructor."
   "Do not execute either authorized plan in this materialization slice."))

 :hyperdoc-reconstruction
 (:genre :execution-evidence
  :artifact
  "hyperdoc/evidence/refactor-hyperdoc-eighth-extraction-commit-3-validation-subplan-authorization.sexp"
  :sections
  (:classification
   :authorization-contract
   :capability-matrices
   :scope-guard
   :context-and-repository-tests
   :regressions
   :non-execution-boundary
   :replayability)
  :additional-hyperdoc-page-changed-p nil
  :reason :exact-four-path-materialization-boundary)

 :lisp-source-reconstruction
 (:package-file
  "dreyeck/shop3/extraction-planning/executor-package.lisp"
  :added-exports
  (commit-3-non-mutating-validation-subplan
   make-commit-3-validation-execution-context)
  :executor-file
  "dreyeck/shop3/extraction-planning/executor.lisp"
  :definitions
  (commit-3-non-mutating-validation-subplan
   make-commit-3-validation-execution-context
   commit-3-execution-context-report
   execute-plan-armed)
  :private-contracts
  (:identity-distinct-validation-capability
   :capability-purpose-resolution
   :capability-plan-pair-validation
   :universal-validation-mutation-class-guard)
  :test-file
  "dreyeck/shop3/extraction-planning/tests/executor-smoke.lisp")

 :fedwiki-twin-reconstruction
 (:changed-p nil
  :daily-anchor-changed-p nil
  :reason :exact-four-path-materialization-boundary)

 :replayability-checks
 (:commands
  ("git diff --check"
   "repository parenthesis checker on staged files"
   "fresh ASDF load of :dreyeck/shop3/extraction-planning"
   "fresh ASDF test of :dreyeck/shop3/extraction-planning/tests"
   "fresh ASDF test of :hyperdoc/shop3-provider-boundary/tests"
   "direct, compatibility, and dual-load canaries"
   "tools/check-lisp-load-gate.sh :hyperbook/server"
   "safe one-form evidence read with *READ-EVAL* NIL"
   "exact changed-path and public API checks"
   "registry, full-plan preflight, validation-context, and non-execution checks")
  :json-parse-check :not-applicable
  :fedwiki-journal-check :not-applicable
  :final-status :passed))
