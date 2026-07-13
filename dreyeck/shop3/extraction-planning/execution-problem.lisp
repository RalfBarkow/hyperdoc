;;;; Ground SHOP3 execution problem for eighth extraction commit 3.

(in-package #:dreyeck/shop3)

(defproblem eighth-dreyeck-extraction-commit-3-execution
    eighth-dreyeck-extraction-commit-3-execution-domain
  ((repository "/Users/rgb/workspace/hyperdoc/")
   (target-branch hauptsache)
   (basis-commit "fc3293d3308d66033ed4549a9e6d9ca071f2fcd3")

   (commit-3-prepared
    "/Users/rgb/workspace/hyperdoc/"
    hauptsache
    "ab1926eb807e5e8721b888a34736ada458209a40")
   (preparation-problem-materialized-at
    "fc3293d3308d66033ed4549a9e6d9ca071f2fcd3")
   (preparation-plan-length 6)
   (preparation-final-state-confirmed)
   (execution-contract-defined)

   (canonical-shop3-direct-component-count 6)
   (compatibility-shop3-direct-component-count 0)
   (compatibility-shop3-depends-on dreyeck/shop3)
   (primary-shop3-package dreyeck/shop3)
   (legacy-shop3-package-nickname hyperdoc/shop3)
   (provider-boundary-files-preserved)
   (documentation-workflows-preserved)
   (projection-repair-deferred)

   (legacy-implementation-copy "hyperdoc-shop3/package.lisp")
   (legacy-implementation-copy "hyperdoc-shop3/manual-topics.lisp")
   (legacy-implementation-copy "hyperdoc-shop3/plan-objects.lisp")
   (legacy-implementation-copy
    "hyperdoc-shop3/hyperdoc-maintenance-domain.lisp")
   (legacy-implementation-copy "hyperdoc-shop3/examples.lisp")
   (legacy-implementation-copy "hyperdoc-shop3/views.lisp")
   (selected-deletion-target "hyperdoc-shop3/package.lisp")
   (selected-deletion-target "hyperdoc-shop3/manual-topics.lisp")
   (selected-deletion-target "hyperdoc-shop3/plan-objects.lisp")
   (selected-deletion-target
    "hyperdoc-shop3/hyperdoc-maintenance-domain.lisp")
   (selected-deletion-target "hyperdoc-shop3/examples.lisp")
   (selected-deletion-target "hyperdoc-shop3/views.lisp")
   (pending-legacy-copy-deletion "hyperdoc-shop3/package.lisp")
   (pending-legacy-copy-deletion "hyperdoc-shop3/manual-topics.lisp")
   (pending-legacy-copy-deletion "hyperdoc-shop3/plan-objects.lisp")
   (pending-legacy-copy-deletion
    "hyperdoc-shop3/hyperdoc-maintenance-domain.lisp")
   (pending-legacy-copy-deletion "hyperdoc-shop3/examples.lisp")
   (pending-legacy-copy-deletion "hyperdoc-shop3/views.lisp")

   (selected-reference-boundary-checker
    "tools/check-shop3-reference-boundary.lisp")
   (pending-reference-boundary-checker-write
    "tools/check-shop3-reference-boundary.lisp")
   (selected-reference-boundary-fixture
    :allowed
    "tools/testdata/shop3-reference-boundary/allowed-added-lines.diff")
   (selected-reference-boundary-fixture
    :rejected
    "tools/testdata/shop3-reference-boundary/rejected-added-lines.diff")
   (pending-reference-boundary-fixture-write
    :allowed
    "tools/testdata/shop3-reference-boundary/allowed-added-lines.diff")
   (pending-reference-boundary-fixture-write
    :rejected
    "tools/testdata/shop3-reference-boundary/rejected-added-lines.diff")
   (selected-reference-boundary-gate "tools/pre-commit-gate.sh")
   (pending-reference-boundary-gate-wiring "tools/pre-commit-gate.sh")
   (pending-reference-boundary-fixture-validation)

   (reference-policy added-lines-only)
   (reference-classification-uses-path-and-kind true)
   (forbidden-new-live-reference new-asdf-dependency ":HYPERDOC/SHOP3")
   (forbidden-new-live-reference new-asdf-dependency "#:HYPERDOC/SHOP3")
   (forbidden-new-live-reference
    new-package-qualifier "HYPERDOC/SHOP3:")
   (forbidden-new-live-reference
    new-package-qualifier "HYPERDOC/SHOP3::")
   (forbidden-new-live-reference new-in-package ":HYPERDOC/SHOP3")
   (forbidden-new-live-reference new-in-package "#:HYPERDOC/SHOP3")
   (forbidden-new-live-reference new-in-package "\"HYPERDOC/SHOP3\"")
   (forbidden-new-live-reference
    new-asdf-component-root "hyperdoc-shop3/")
   (forbidden-new-live-reference
    new-primary-owner-claim "(DEFPACKAGE #:HYPERDOC/SHOP3")

   (execution-contract-delete-path "hyperdoc-shop3/package.lisp")
   (execution-contract-delete-path "hyperdoc-shop3/manual-topics.lisp")
   (execution-contract-delete-path "hyperdoc-shop3/plan-objects.lisp")
   (execution-contract-delete-path
    "hyperdoc-shop3/hyperdoc-maintenance-domain.lisp")
   (execution-contract-delete-path "hyperdoc-shop3/examples.lisp")
   (execution-contract-delete-path "hyperdoc-shop3/views.lisp")
   (execution-contract-modify-path "tools/pre-commit-gate.sh")
   (execution-contract-add-path
    "tools/check-shop3-reference-boundary.lisp")
   (execution-contract-add-path
    "tools/testdata/shop3-reference-boundary/allowed-added-lines.diff")
   (execution-contract-add-path
    "tools/testdata/shop3-reference-boundary/rejected-added-lines.diff")
   (execution-contract-add-path
    "hyperdoc/evidence/refactor-hyperdoc-eighth-extraction-commit-3-execution.sexp")

   (pending-direct-shop3-canary)
   (pending-compatibility-shop3-canary)
   (pending-dual-load-identity-canary)
   (pending-shop3-provider-boundary-tests)
   (pending-repository-load-gate)
   (selected-commit-3-execution-evidence-path
    "hyperdoc/evidence/refactor-hyperdoc-eighth-extraction-commit-3-execution.sexp")
   (pending-commit-3-execution-evidence-write
    "hyperdoc/evidence/refactor-hyperdoc-eighth-extraction-commit-3-execution.sexp")
   (pending-commit-3-execution-completion-record))
  ((execute-eighth-dreyeck-extraction-commit-3
    "/Users/rgb/workspace/hyperdoc/"
    hauptsache
    "fc3293d3308d66033ed4549a9e6d9ca071f2fcd3")))
