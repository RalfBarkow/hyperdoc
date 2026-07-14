(:commit-3-pre-mutation-validation-contract-correction
 (:date "2026-07-14")
 (:repository "/Users/rgb/workspace/hyperdoc/")
 (:branch "hauptsache")
 (:basis-failed-execution-head
  "aa4d5a570201d984843e6b98b100fecb09745751")
 (:classification :pre-mutation-plan-precondition-contradiction)
 (:first-failed-execution
  (:authorized-p t)
  (:attempted-p t)
  (:original-planned-action-count 6)
  (:executed-action-count 0)
  (:failed-operator "!RUN-SHOP3-REFERENCE-BOUNDARY-FIXTURES")
  (:failure-type :handler-failure)
  (:failure-reason :runtime-dependency-unavailable)
  (:repository-unchanged-p t)
  (:mutations-performed nil))
 (:correction
  (:corrected-pre-mutation-action-count 5)
  (:canonical-pre-mutation-plan
   ("!RUN-DIRECT-SHOP3-LOAD-AND-GAP-CANARY"
    "!RUN-COMPATIBILITY-SHOP3-LOAD-AND-GAP-CANARY"
    "!RUN-DUAL-LOAD-IDENTITY-CANARY"
    "!RUN-SHOP3-PROVIDER-BOUNDARY-TESTS"
    "!RUN-REPOSITORY-LOAD-GATE"))
  (:deferred-post-materialization-action
   "!RUN-SHOP3-REFERENCE-BOUNDARY-FIXTURES")
  (:required-predecessors
   ("!WRITE-SHOP3-REFERENCE-BOUNDARY-CHECKER"
    "!WRITE-SHOP3-REFERENCE-BOUNDARY-FIXTURE"
    "!WIRE-SHOP3-REFERENCE-BOUNDARY-CHECKER")))
 (:preserved-contracts
  (:production-reference-handler-fails-closed-p t)
  (:temporary-command-resolver-remains-test-only-p t)
  (:operator-registry-changed-p nil)
  (:handler-identity-changed-p nil)
  (:authorization-architecture-changed-p nil)
  (:mutation-handlers-added-p nil)
  (:commit-3-performed-p nil))
 (:changed-paths
  ("dreyeck/shop3/extraction-planning/executor.lisp"
   "dreyeck/shop3/extraction-planning/tests/executor-smoke.lisp"
   "hyperdoc/evidence/refactor-hyperdoc-eighth-extraction-commit-3-pre-mutation-validation-contract-correction.sexp"))
 (:historical-authorization-evidence-rewritten-p nil)
 (:validation
  (:fresh-external-sbcl-required-p t)
  (:expected-pre-mutation-action-count 5)
  (:expected-executed-action-count 5)
  (:expected-mutations nil))
 (:commit-policy
  (:subject "fix(shop3): correct pre-mutation validation contract")
  (:push-p nil)))
