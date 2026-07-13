(:eighth-extraction-commit-3-live-lisp-executor-materialization
 (:classification
  :eighth-extraction-commit-3-live-lisp-executor-materialized)
 (:repository "/Users/rgb/workspace/hyperdoc/")
 (:branch "codex/eighth-extraction-commit-3-live-lisp-executor")
 (:basis-commit "e0c5a9b3a5b7d7a0fc3769ddf491f8f86063c412")

 (:tooling-repair
  (:branch "fix/darwin-emacsclient-discovery")
  (:commit "b2e5fd14f8cb0b4ff45d5de836c9c4e88a9a5075")
  (:paths ("tools/check-lisp-parens.sh"))
  (:live-emacsclient-probe-passed nil)
  (:batch-emacs-fallback-passed t)
  (:mixed-into-executor-commit nil))

 (:executor-localization
  (:reusable-htn
   "hyperdoc/refactor-hyperdoc-reusable-extraction-htn.sexp")
  (:architecture-decision
   "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp")
  (:seventh-extraction-assimilation
   "hyperdoc/evidence/refactor-hyperdoc-seventh-extraction-htn-assimilation.sexp")
  (:commit-3-localization
   (:commit "bfa06ee9c0307327346d8705800bfcd4fa3b08c3")
   (:basis "59639866a1bb4aa9f27ddc43c383bd2907d196b3")
   (:artifact
    "hyperdoc/evidence/refactor-hyperdoc-eighth-extraction-commit-3-localization.sexp"))
  (:commit-3-live-problem-materialization
   (:commit "ab1926eb807e5e8721b888a34736ada458209a40")
   (:artifact
    "hyperdoc/evidence/refactor-hyperdoc-eighth-extraction-commit-3-localization-problem-materialization.sexp"))
  (:commit-3-preparation
   (:commit "fc3293d3308d66033ed4549a9e6d9ca071f2fcd3")
   (:artifact
    "hyperdoc/evidence/refactor-hyperdoc-eighth-extraction-commit-3-preparation.sexp"))
  (:execution-problem
   (:basis-commit "e0c5a9b3a5b7d7a0fc3769ddf491f8f86063c412")
   (:domain
    "dreyeck/shop3/extraction-planning/execution-domain.lisp")
   (:problem
    "dreyeck/shop3/extraction-planning/execution-problem.lisp")
   (:runner
    "dreyeck/shop3/extraction-planning/runner.lisp")
   (:evidence
    "hyperdoc/evidence/refactor-hyperdoc-eighth-extraction-commit-3-execution-problem-materialization.sexp"))
  (:live-shop3-plan
   (:system :dreyeck/shop3/extraction-planning)
   (:problem "EIGHTH-DREYECK-EXTRACTION-COMMIT-3-EXECUTION")
   (:find-plans-call :live)
   (:raw-plan-representation :alternating-action-and-cost)
   (:raw-plan-cell-count 36)
   (:raw-plan-action-count 18)
   (:shorter-plan-action-count 18)
   (:plan-trees :separate-return-value)
   (:final-states :separate-return-value)
   (:observed-plan-tree-type :cons)
   (:observed-final-state-atom-count 75))
  (:accepted-primitive-actions
   (:normalized-count 18)
   (:distinct-operator-count 12)
   (:legacy-copy-deletions 6))
  (:existing-executor-or-dispatch-seams
   ((:path "dreyeck/build/tasks.lisp"
     :reuse :plan-check-perform-and-structured-result-patterns)
    (:path "dreyeck/shop3/plan-objects.lisp"
     :reuse :shop3-plan-projection-and-plan-only-vocabulary)
    (:path "hyperdoc/executable-dita-tasks.lisp"
     :reuse :guarded-execution-boundary)
    (:path "hyperdoc/shared-sexpression-plans.lisp"
     :boundary :data-only-no-execution)
    (:path "hyperdoc/scxml-runs.lisp"
     :reuse :future-event-adapter-shape-only
     :dependency-added nil))))

 (:architecture
  (:executor-role :coherent-live-lisp-image)
  (:codex-is-executor nil)
  (:layers
   ((:plan-runner :ordered-normalization-preflight-and-iteration)
    (:operator-dispatch :closed-registry-resolution-and-validation)
    (:operator-handler :one-bounded-action-and-observed-evidence)))
  (:default-mode :plan-only)
  (:execute-plan-preflights-all-actions-before-first-handler t)
  (:repository-root "/Users/rgb/workspace/hyperdoc/")
  (:forbidden-techniques
   (:eval-plan-action
    :compile-plan-action
    :symbol-function-of-plan-symbol
    :arbitrary-apply-from-plan-data
    :shell-concatenation-from-plan-arguments
    :unknown-operator-fallback)))

 (:operator-registry
  (:source :live-shop3-plan)
  (:raw-plan-action-count 18)
  (:normalized-plan-action-count 18)
  (:operators
   ((:operator "DREYECK/SHOP3::!DELETE-LEGACY-SHOP3-COPY"
     :arity 1 :arguments :legacy-copy-repository-path
     :mutation-class :repository-delete
     :plan-only-renderer :delete-legacy-shop3-copy
     :execute-handler nil
     :precondition-observer :file-presence
     :postcondition-observer :file-absence)
    (:operator "DREYECK/SHOP3::!WRITE-SHOP3-REFERENCE-BOUNDARY-CHECKER"
     :arity 1 :arguments :accepted-checker-repository-path
     :mutation-class :repository-write
     :plan-only-renderer :write-reference-boundary-checker
     :execute-handler nil
     :precondition-observer :checker-contract
     :postcondition-observer :file-content)
    (:operator "DREYECK/SHOP3::!WRITE-SHOP3-REFERENCE-BOUNDARY-FIXTURE"
     :arity 2 :arguments :fixture-kind-and-accepted-repository-path
     :mutation-class :repository-write
     :plan-only-renderer :write-reference-boundary-fixture
     :execute-handler nil
     :precondition-observer :fixture-contract
     :postcondition-observer :file-content)
    (:operator "DREYECK/SHOP3::!WIRE-SHOP3-REFERENCE-BOUNDARY-CHECKER"
     :arity 1 :arguments :pre-commit-gate-repository-path
     :mutation-class :repository-modification
     :plan-only-renderer :wire-reference-boundary-checker
     :execute-handler nil
     :precondition-observer :gate-content
     :postcondition-observer :gate-content)
    (:operator "DREYECK/SHOP3::!RUN-SHOP3-REFERENCE-BOUNDARY-FIXTURES"
     :arity 0 :arguments :none
     :mutation-class :non-mutating-validation
     :plan-only-renderer :run-reference-boundary-fixtures
     :execute-handler nil
     :precondition-observer :fixture-presence
     :postcondition-observer :fixture-results)
    (:operator "DREYECK/SHOP3::!RUN-DIRECT-SHOP3-LOAD-AND-GAP-CANARY"
     :arity 0 :arguments :none
     :mutation-class :non-mutating-validation
     :plan-only-renderer :run-direct-shop3-canary
     :execute-handler nil
     :precondition-observer :direct-system-loadability
     :postcondition-observer :direct-gap-plan)
    (:operator "DREYECK/SHOP3::!RUN-COMPATIBILITY-SHOP3-LOAD-AND-GAP-CANARY"
     :arity 0 :arguments :none
     :mutation-class :non-mutating-validation
     :plan-only-renderer :run-compatibility-shop3-canary
     :execute-handler nil
     :precondition-observer :compatibility-system-loadability
     :postcondition-observer :compatibility-gap-plan)
    (:operator "DREYECK/SHOP3::!RUN-DUAL-LOAD-IDENTITY-CANARY"
     :arity 0 :arguments :none
     :mutation-class :non-mutating-validation
     :plan-only-renderer :run-dual-load-identity-canary
     :execute-handler nil
     :precondition-observer :dual-system-loadability
     :postcondition-observer :runtime-identities)
    (:operator "DREYECK/SHOP3::!RUN-SHOP3-PROVIDER-BOUNDARY-TESTS"
     :arity 0 :arguments :none
     :mutation-class :non-mutating-validation
     :plan-only-renderer :run-provider-boundary-tests
     :execute-handler :run-provider-boundary-tests
     :precondition-observer :provider-boundary-test-system
     :postcondition-observer :provider-boundary-test-result)
    (:operator "DREYECK/SHOP3::!RUN-REPOSITORY-LOAD-GATE"
     :arity 0 :arguments :none
     :mutation-class :non-mutating-validation
     :plan-only-renderer :run-repository-load-gate
     :execute-handler nil
     :precondition-observer :repository-load-command
     :postcondition-observer :load-gate-marker)
    (:operator "DREYECK/SHOP3::!WRITE-COMMIT-3-EXECUTION-EVIDENCE"
     :arity 1 :arguments :accepted-evidence-repository-path
     :mutation-class :repository-write
     :plan-only-renderer :write-commit-3-execution-evidence
     :execute-handler nil
     :precondition-observer :validation-results
     :postcondition-observer :safe-single-form)
    (:operator "DREYECK/SHOP3::!RECORD-COMMIT-3-EXECUTION-COMPLETE"
     :arity 0 :arguments :none
     :mutation-class :execution-record
     :plan-only-renderer :record-commit-3-execution-complete
     :execute-handler nil
     :precondition-observer :execution-evidence
     :postcondition-observer :next-task))))

 (:accepted-repository-paths
  (:legacy-copies
   ("hyperdoc-shop3/package.lisp"
    "hyperdoc-shop3/manual-topics.lisp"
    "hyperdoc-shop3/plan-objects.lisp"
    "hyperdoc-shop3/hyperdoc-maintenance-domain.lisp"
    "hyperdoc-shop3/examples.lisp"
    "hyperdoc-shop3/views.lisp"))
  (:reference-boundary-checker
   "tools/check-shop3-reference-boundary.lisp")
  (:reference-boundary-fixtures
   ((:allowed
     "tools/testdata/shop3-reference-boundary/allowed-added-lines.diff")
    (:rejected
     "tools/testdata/shop3-reference-boundary/rejected-added-lines.diff")))
  (:pre-commit-gate "tools/pre-commit-gate.sh")
  (:execution-evidence
   "hyperdoc/evidence/refactor-hyperdoc-eighth-extraction-commit-3-execution.sexp"))

 (:event-seam
  (:representation :ordinary-lisp-data)
  (:vocabulary
   (:plan-started :action-planned :action-started :action-succeeded
    :action-failed :plan-completed :plan-stopped))
  (:scxml-dependency nil)
  (:future-scxml-adapter-seam t))

 (:executor-tests
  (:live-plan-shape-observed t)
  (:plan-normalization-preserves-order t)
  (:plan-only-default t)
  (:plan-only-performs-no-mutation t)
  (:all-accepted-operators-resolve t)
  (:unknown-operator-rejected t)
  (:wrong-arity-rejected t)
  (:wrong-argument-type-rejected t)
  (:outside-repository-path-rejected t)
  (:handler-failure-stops-plan t)
  (:structured-action-result-produced t)
  (:ordered-event-trace-produced t)
  (:observed-effects-not-fabricated t)
  (:scxml-not-required t)
  (:non-mutating-handler-full-path
   :run-shop3-provider-boundary-tests))

 (:mrepl-entry-point
  (:form
   "(progn
  (asdf:load-system :dreyeck/shop3/extraction-planning)
  (asdf:load-system :hyperdoc/inspector)
  (let* ((live (dreyeck/shop3/executor:commit-3-execution-plan))
         (plan (getf live :raw-plan))
         (executor (dreyeck/shop3/executor:make-commit-3-executor))
         (result (dreyeck/shop3/executor:execute-plan
                  executor plan :mode :plan-only :context nil)))
    (clog-moldable-inspector:clog-inspect :object result)))"))

 (:reconstruction-surfaces
  (:surface-answer :terminal-codex-session)
  (:artifact-answer
   (:hyperdoc-evidence
    "hyperdoc/evidence/refactor-hyperdoc-eighth-extraction-commit-3-live-lisp-executor-materialization.sexp")
   (:lisp-source
    ("dreyeck/shop3/extraction-planning/executor-package.lisp"
     "dreyeck/shop3/extraction-planning/executor.lisp"))
   (:fedwiki-twin nil
    :reason :executor-only-slice-does-not-migrate-documentation)))

 (:validation
  ((:command "live SHOP3 plan-shape probe" :status :passed)
   (:command
    "nix develop -c sbcl --eval '(asdf:load-system :dreyeck/shop3/extraction-planning)'"
    :status :passed)
   (:command
    "nix develop -c sbcl --eval '(asdf:test-system :dreyeck/shop3/extraction-planning/tests)'"
    :status :passed)
   (:command "git diff --check" :status :passed)
   (:command "tools/check-lisp-parens.sh through staged pre-commit path"
    :status :passed-via-pre-commit-gate)
   (:command
    "nix develop -c sbcl --eval '(asdf:test-system :hyperdoc/shop3-provider-boundary/tests)'"
    :status :passed)
   (:command "direct DREYECK/SHOP3 gap canary" :status :passed)
   (:command "compatibility HYPERDOC/SHOP3 gap canary" :status :passed)
   (:command "dual-load identity canary" :status :passed)
   (:command "tools/check-lisp-load-gate.sh :hyperbook/server"
    :status :passed :marker "LOAD_GATE_OK")
   (:command "safe single-form evidence read" :status :passed)))

 (:changed-path-contract
  ("dreyeck.asd"
   "dreyeck/shop3/extraction-planning/executor-package.lisp"
   "dreyeck/shop3/extraction-planning/executor.lisp"
   "dreyeck/shop3/extraction-planning/tests/package.lisp"
   "dreyeck/shop3/extraction-planning/tests/executor-smoke.lisp"
   "hyperdoc/evidence/refactor-hyperdoc-eighth-extraction-commit-3-live-lisp-executor-materialization.sexp"))

 (:mutations
  (:legacy-files-deleted nil)
  (:canonical-dreyeck/shop3-sources-modified nil)
  (:compatibility-system-changed nil)
  (:extraction-operators-executed nil)
  (:executed-action-count 0)
  (:scxml-dependency-added nil)
  (:pushed nil))

 (:next-task
  (!perform-eighth-dreyeck-extraction-commit-3
   :from-live-shop3-execution-plan t)))
