;;;; Ground SHOP3 problem for the eighth extraction commit-3 preparation.

(in-package #:dreyeck/shop3)

(defproblem eighth-dreyeck-extraction-commit-3-preparation
    eighth-dreyeck-extraction-commit-3-preparation-domain
  ((repository "/Users/rgb/workspace/hyperdoc/")
   (target-branch hauptsache)
   (basis-commit "ab1926eb807e5e8721b888a34736ada458209a40")

   (commit-3-localization-problem-materialized
    eighth-dreyeck-extraction-commit-3-localization)
   (live-localization-plan-length 5)
   (live-localization-final-state-confirmed)

   (canonical-shop3-system dreyeck/shop3)
   (canonical-shop3-package dreyeck/shop3)
   (compatibility-shop3-system hyperdoc/shop3)
   (legacy-shop3-package-nickname hyperdoc/shop3)

   (legacy-implementation-copy "hyperdoc-shop3/package.lisp")
   (legacy-implementation-copy "hyperdoc-shop3/manual-topics.lisp")
   (legacy-implementation-copy "hyperdoc-shop3/plan-objects.lisp")
   (legacy-implementation-copy
    "hyperdoc-shop3/hyperdoc-maintenance-domain.lisp")
   (legacy-implementation-copy "hyperdoc-shop3/examples.lisp")
   (legacy-implementation-copy "hyperdoc-shop3/views.lisp")
   (legacy-implementation-copy-count 6)
   (legacy-copies-live-asdf-components false)
   (canonical-equivalents-present true)
   (content-equivalent-modulo-recorded-boundary-edits true)
   (recorded-boundary-edit defpackage-primary-name)
   (recorded-boundary-edit legacy-package-nickname)
   (recorded-boundary-edit in-package-owner)
   (recorded-boundary-edit fixture-reader-package)

   (reference-lint-checker-path
    "tools/check-shop3-reference-boundary.lisp")
   (reference-lint-gate-path "tools/pre-commit-gate.sh")
   (reference-lint-test-path
    "tools/testdata/shop3-reference-boundary/allowed-added-lines.diff")
   (reference-lint-test-path
    "tools/testdata/shop3-reference-boundary/rejected-added-lines.diff")
   (reference-lint-language common-lisp)
   (reference-lint-input staged-added-lines)
   (reference-lint-shell-adapter-only-at-gate true)
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

   (allowed-reference-class compatibility-system-definition)
   (allowed-reference
    compatibility-system-definition "hyperdoc.asd" compatibility-defsystem)
   (allowed-reference-class legacy-package-nickname-definition)
   (allowed-reference
    legacy-package-nickname-definition
    "dreyeck/shop3/package.lisp"
    package-nickname)
   (allowed-reference-class provider-boundary-files-pending-later-extraction)
   (allowed-reference
    provider-boundary-files-pending-later-extraction
    "hyperdoc-shop3/provider-boundary-package.lisp"
    provider-package-definition)
   (allowed-reference
    provider-boundary-files-pending-later-extraction
    "hyperdoc-shop3/provider-boundary.lisp"
    provider-dependency-and-registry)
   (allowed-reference-class compatibility-tests)
   (allowed-reference
    compatibility-tests
    "tests/projection-pipeline-dmx-annotation-smoke.lisp"
    compatibility-load-and-package-lookup)
   (allowed-reference
    compatibility-tests
    "tests/runtime-coherence-smoke.lisp"
    forbidden-core-dependency-assertion)
   (allowed-reference
    compatibility-tests
    "tests/shop3-provider-boundary-smoke.lisp"
    provider-boundary-contract)
   (allowed-reference
    compatibility-tests
    "tests/refactor-hyperdoc-upstream-core-plan-smoke.lisp"
    provider-boundary-inventory)
   (allowed-reference
    compatibility-tests
    "tests/executable-dita-tasks-smoke.lisp"
    existing-forbidden-system-set-only)
   (allowed-reference-class historical-evidence)
   (allowed-reference
    historical-evidence
    "hyperdoc/evidence/refactor-hyperdoc-*.sexp"
    reconstructive-extraction-evidence)
   (allowed-reference-class deferred-documentation)
   (allowed-reference
    deferred-documentation "hyperdoc/Debug SHOP3 find-plans.html"
    deferred-documentation-reference)
   (allowed-reference
    deferred-documentation "hyperdoc/Kioskbeerli Pi simulation.html"
    deferred-documentation-reference)
   (allowed-reference
    deferred-documentation "hyperdoc/Kioskbeerli sops-nix secrets.html"
    deferred-documentation-reference)
   (allowed-reference
    deferred-documentation
    "hyperdoc/Parsing SHOP3 Introduction into Topics.html"
    deferred-documentation-reference)
   (allowed-reference
    deferred-documentation "hyperdoc/Projection Pipeline Operator Plan.html"
    deferred-documentation-reference)
   (allowed-reference
    deferred-documentation "hyperdoc/SHOP3 ASDF Refactor Plan Example.html"
    deferred-documentation-reference)
   (allowed-reference
    deferred-documentation
    "hyperdoc/SHOP3 Parser Documentation Plan and SCXML.html"
    deferred-documentation-reference)
   (allowed-reference
    deferred-documentation "hyperdoc/SHOP3 Planning API Reference.html"
    deferred-documentation-reference)
   (allowed-reference
    deferred-documentation "hyperdoc/SHOP3 Planning Layer for HyperDoc.html"
    deferred-documentation-reference)
   (allowed-reference
    deferred-documentation "hyperdoc/Using SHOP3 Planning in HyperDoc.html"
    deferred-documentation-reference)
   (allowed-reference
    deferred-documentation
    "hyperdoc/kernighan-plauger-critical-reading-style-plan.sexp"
    deferred-plan-reference)
   (allowed-reference
    deferred-documentation "hyperdoc/projection-pipeline-operator.lisp"
    deferred-projection-documentation-reference)
   (allowed-reference-class deferred-plan-and-scxml-artifacts)
   (allowed-reference
    deferred-plan-and-scxml-artifacts
    "hyperdoc-shop3/shop3-parser-documentation-plan.sexp"
    deferred-plan)
   (allowed-reference
    deferred-plan-and-scxml-artifacts
    "hyperdoc-shop3/shop3-parser-documentation-workflow.scxml"
    deferred-scxml)
   (allowed-reference-class lint-purpose-test-fixtures)
   (allowed-reference
    lint-purpose-test-fixtures
    "tools/testdata/shop3-reference-boundary/allowed-added-lines.diff"
    positive-fixture)
   (allowed-reference
    lint-purpose-test-fixtures
    "tools/testdata/shop3-reference-boundary/rejected-added-lines.diff"
    negative-fixture)
   (allowlist-narrow-and-explicit true)

   (execution-delete-path "hyperdoc-shop3/package.lisp")
   (execution-delete-path "hyperdoc-shop3/manual-topics.lisp")
   (execution-delete-path "hyperdoc-shop3/plan-objects.lisp")
   (execution-delete-path
    "hyperdoc-shop3/hyperdoc-maintenance-domain.lisp")
   (execution-delete-path "hyperdoc-shop3/examples.lisp")
   (execution-delete-path "hyperdoc-shop3/views.lisp")
   (execution-modify-path "tools/pre-commit-gate.sh")
   (execution-add-path "tools/check-shop3-reference-boundary.lisp")
   (execution-add-path
    "tools/testdata/shop3-reference-boundary/allowed-added-lines.diff")
   (execution-add-path
    "tools/testdata/shop3-reference-boundary/rejected-added-lines.diff")
   (execution-add-path
    "hyperdoc/evidence/refactor-hyperdoc-eighth-extraction-commit-3-execution.sexp")
   (execution-excluded-path "dreyeck.asd" asdf-definition-unchanged)
   (execution-excluded-path "hyperdoc.asd" compatibility-system-unchanged)
   (execution-excluded-path
    "hyperdoc-shop3/provider-boundary-package.lisp"
    provider-boundary-move-deferred)
   (execution-excluded-path
    "hyperdoc-shop3/provider-boundary.lisp"
    provider-boundary-move-deferred)
   (execution-excluded-path
    "hyperdoc-shop3/shop3-parser-documentation-plan.sexp"
    documentation-workflow-move-deferred)
   (execution-excluded-path
    "hyperdoc-shop3/shop3-parser-documentation-workflow.scxml"
    documentation-workflow-move-deferred)
   (execution-excluded-path
    "dreyeck/shop3/plan-objects.lisp" projection-repair-deferred)
   (execution-excluded-path
    "dreyeck/shop3/hyperdoc-maintenance-domain.lisp"
    projection-repair-deferred)
   (execution-excluded-path
    "dreyeck/shop3/extraction-planning/runner.lisp"
    projection-repair-deferred)
   (execution-excluded-path
    "dreyeck/shop3/extraction-planning/tests/smoke.lisp"
    projection-repair-deferred)
   (execution-changed-path-contract-complete true)

   (execution-acceptance six-legacy-implementation-copies-absent true)
   (execution-acceptance canonical-six-copies-present true)
   (execution-acceptance dreyeck/shop3-direct-components 6)
   (execution-acceptance hyperdoc/shop3-direct-components 0)
   (execution-acceptance hyperdoc/shop3-depends-on-dreyeck/shop3 true)
   (execution-acceptance primary-package dreyeck/shop3)
   (execution-acceptance legacy-package-nickname hyperdoc/shop3)
   (execution-acceptance direct-asdf-load passed)
   (execution-acceptance compatibility-asdf-load passed)
   (execution-acceptance direct-gap-canary passed)
   (execution-acceptance compatibility-gap-canary passed)
   (execution-acceptance dual-load-canary passed)
   (execution-acceptance reference-lint-rejection-fixtures passed)
   (execution-acceptance reference-lint-allowance-fixtures passed)
   (execution-acceptance provider-boundary-tests passed)
   (execution-acceptance provider-boundary-files unchanged)
   (execution-acceptance documentation-workflows unchanged)
   (execution-acceptance projection-repair not-performed)
   (execution-acceptance repository-load-gate passed)
   (execution-acceptance-contract-complete true)

   (provider-boundary-move-deferred)
   (documentation-workflow-move-deferred)
   (projection-repair-deferred))
  ((prepare-eighth-dreyeck-extraction-commit-3
    "/Users/rgb/workspace/hyperdoc/"
    hauptsache
    "ab1926eb807e5e8721b888a34736ada458209a40")))
