(:commit-3-canary-reader-boundary-repair
 (:date "2026-07-14")
 (:repository "/Users/rgb/workspace/hyperdoc/")
 (:branch "hauptsache")
 (:basis-failed-reexecution-head
  "3878890cbb0ab42220d7ab8e1769d444190ac1d2")
 (:classification :package-qualified-symbol-read-before-system-load)
 (:failed-reexecution
  (:canonical-pre-mutation-action-count 5)
  (:failed-operator "!RUN-DIRECT-SHOP3-LOAD-AND-GAP-CANARY")
  (:failure-type :handler-failure)
  (:failure-reason :command-validation-failed)
  (:external-reader-condition :simple-reader-package-error)
  (:missing-package-at-read-time "DREYECK/SHOP3")
  (:handler-semantic-body-entered-p nil)
  (:executed-action-count 0)
  (:mutations-performed nil)
  (:repository-unchanged-p t))
 (:repair
  (:strategy :package-neutral-generated-evaluation-forms)
  (:affected-generators
   ("%GAP-CANARY-EVALUATION-FORM"
    "%DUAL-LOAD-CANARY-EVALUATION-FORM"))
  (:runtime-resolution
   ("FIND-PACKAGE" "FIND-SYMBOL" "FBOUNDP"
    "SYMBOL-FUNCTION" "FIND-CLASS" "FUNCALL"))
  (:generated-reader-prefixes-forbidden
   ("DREYECK/SHOP3:" "HYPERDOC/SHOP3:")))
 (:process-boundary-amendment
  (:classification :nested-nix-asdf-environment-boundary)
  (:observed-validator-failure
   (:fresh-load-passed-p t)
   (:fresh-tests-passed-p t)
   (:default-command-validation-passed-p nil)
   (:condition-message "Only one inherited configuration allowed"))
  (:repair
   (:production-command-specifications-changed-p t)
   (:generic-command-runner-changed-p nil)
   (:validator-command-rewriting-p nil)
   (:clean-environment-variables
    ("CL_SOURCE_REGISTRY"
     "CL_SOURCE_REGISTRY_CONFIG"
     "ASDF_OUTPUT_TRANSLATIONS"
     "ASDF_OUTPUT_TRANSLATIONS_CONFIG"))
   (:affected-command-surfaces
    (:reference-boundary-fixtures
     :direct-shop3-gap-canary
     :compatibility-shop3-gap-canary
     :dual-load-package-identity-canary))))
 (:preserved-contracts
  (:canonical-five-action-plan-changed-p nil)
  (:operator-registry-changed-p nil)
  (:handler-registration-changed-p nil)
  (:authorization-context-changed-p nil)
  (:execute-plan-armed-gates-changed-p nil)
  (:hauptsache-repository-changed-p nil)
  (:mutation-handlers-added-p nil)
  (:commit-3-performed-p nil))
 (:validation
  (:fresh-external-sbcl-required-p t)
  (:direct-default-command-required-p t)
  (:compatibility-default-command-required-p t)
  (:dual-load-default-command-required-p t)
  (:extraction-planning-tests-required-p t)
  (:repository-load-gate-required-p t)
  (:production-command-clean-prefix-required-p t)
  (:expected-pre-mutation-action-count 5)
  (:expected-mutations nil))
 (:changed-paths
  ("dreyeck/shop3/extraction-planning/executor.lisp"
   "dreyeck/shop3/extraction-planning/tests/executor-smoke.lisp"
   "hyperdoc/evidence/refactor-hyperdoc-eighth-extraction-commit-3-canary-reader-boundary-repair.sexp"))
 (:commit-policy
  (:subject "fix(shop3): make validation canaries process-boundary safe")
  (:push-p nil))
 (:generalization-debt
  (:generated-source-as-strings-p t)
  (:nested-nix-command-policy-is-episode-local-p t)
  (:replace-embedded-payload-orchestration-p t)))
