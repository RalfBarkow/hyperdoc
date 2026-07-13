;;;; Live SHOP3 domain for the eighth extraction commit-3 preparation.

(in-package #:dreyeck/shop3)

(defdomain eighth-dreyeck-extraction-commit-3-preparation-domain
  ((:op (!confirm-live-localization-basis
         ?repository ?target-branch ?basis-commit)
    :precond
    (and
     (repository ?repository)
     (target-branch ?target-branch)
     (basis-commit ?basis-commit)
     (commit-3-localization-problem-materialized
      eighth-dreyeck-extraction-commit-3-localization)
     (live-localization-plan-length 5)
     (live-localization-final-state-confirmed)
     (canonical-shop3-system dreyeck/shop3)
     (canonical-shop3-package dreyeck/shop3)
     (compatibility-shop3-system hyperdoc/shop3)
     (legacy-shop3-package-nickname hyperdoc/shop3))
    :delete
    ((commit-3-localization-problem-materialized
      eighth-dreyeck-extraction-commit-3-localization))
    :add
    ((live-localization-basis-confirmed
      ?repository ?target-branch ?basis-commit)))

   (:op (!select-legacy-copy-deletion-set
         ?repository ?target-branch ?basis-commit)
    :precond
    (and
     (live-localization-basis-confirmed
      ?repository ?target-branch ?basis-commit)
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
     (content-equivalent-modulo-recorded-boundary-edits true))
    :delete
    ((live-localization-basis-confirmed
      ?repository ?target-branch ?basis-commit))
    :add
    ((legacy-copy-deletion-set-selected
      ?repository ?target-branch ?basis-commit)))

   (:op (!select-reference-lint-design
         ?repository ?target-branch ?basis-commit)
    :precond
    (and
     (legacy-copy-deletion-set-selected
      ?repository ?target-branch ?basis-commit)
     (reference-lint-checker-path
      "tools/check-shop3-reference-boundary.lisp")
     (reference-lint-gate-path "tools/pre-commit-gate.sh")
     (reference-lint-test-path
      "tools/testdata/shop3-reference-boundary/allowed-added-lines.diff")
     (reference-lint-test-path
      "tools/testdata/shop3-reference-boundary/rejected-added-lines.diff")
     (reference-lint-language common-lisp)
     (reference-lint-input staged-added-lines)
     (reference-lint-shell-adapter-only-at-gate true))
    :delete
    ((legacy-copy-deletion-set-selected
      ?repository ?target-branch ?basis-commit))
    :add
    ((reference-lint-design-selected
      ?repository ?target-branch ?basis-commit)))

   (:op (!classify-reference-policy
         ?repository ?target-branch ?basis-commit)
    :precond
    (and
     (reference-lint-design-selected
      ?repository ?target-branch ?basis-commit)
     (reference-policy added-lines-only)
     (reference-classification-uses-path-and-kind true)
     (forbidden-new-live-reference
      new-asdf-dependency ":HYPERDOC/SHOP3")
     (forbidden-new-live-reference
      new-asdf-dependency "#:HYPERDOC/SHOP3")
     (forbidden-new-live-reference
      new-package-qualifier "HYPERDOC/SHOP3:")
     (forbidden-new-live-reference
      new-package-qualifier "HYPERDOC/SHOP3::")
     (forbidden-new-live-reference
      new-in-package ":HYPERDOC/SHOP3")
     (forbidden-new-live-reference
      new-in-package "#:HYPERDOC/SHOP3")
     (forbidden-new-live-reference
      new-in-package "\"HYPERDOC/SHOP3\"")
     (forbidden-new-live-reference
      new-asdf-component-root "hyperdoc-shop3/")
     (forbidden-new-live-reference
      new-primary-owner-claim "(DEFPACKAGE #:HYPERDOC/SHOP3")
     (allowed-reference-class compatibility-system-definition)
     (allowed-reference-class provider-boundary-files-pending-later-extraction)
     (allowed-reference-class compatibility-tests)
     (allowed-reference-class historical-evidence)
     (allowed-reference-class deferred-documentation)
     (allowed-reference-class deferred-plan-and-scxml-artifacts)
     (allowed-reference-class lint-purpose-test-fixtures)
     (allowlist-narrow-and-explicit true))
    :delete
    ((reference-lint-design-selected
      ?repository ?target-branch ?basis-commit))
    :add
    ((reference-policy-classified
      ?repository ?target-branch ?basis-commit)))

   (:op (!define-commit-3-execution-contract
         ?repository ?target-branch ?basis-commit)
    :precond
    (and
     (reference-policy-classified
      ?repository ?target-branch ?basis-commit)
     (execution-changed-path-contract-complete true)
     (execution-acceptance-contract-complete true)
     (provider-boundary-move-deferred)
     (documentation-workflow-move-deferred)
     (projection-repair-deferred))
    :delete
    ((reference-policy-classified
      ?repository ?target-branch ?basis-commit))
    :add
    ((commit-3-execution-contract-defined
      ?repository ?target-branch ?basis-commit)))

   (:op (!record-commit-3-preparation
         ?repository ?target-branch ?basis-commit)
    :precond
    (and
     (commit-3-execution-contract-defined
      ?repository ?target-branch ?basis-commit))
    :delete
    ((commit-3-execution-contract-defined
      ?repository ?target-branch ?basis-commit))
    :add
    ((commit-3-prepared ?repository ?target-branch ?basis-commit)
     (next-task execute-eighth-dreyeck-extraction-commit-3)))

   (:method
    (prepare-eighth-dreyeck-extraction-commit-3
     ?repository ?target-branch ?basis-commit)
    (and
     (repository ?repository)
     (target-branch ?target-branch)
     (basis-commit ?basis-commit)
     (commit-3-localization-problem-materialized
      eighth-dreyeck-extraction-commit-3-localization))
    ((!confirm-live-localization-basis
      ?repository ?target-branch ?basis-commit)
     (!select-legacy-copy-deletion-set
      ?repository ?target-branch ?basis-commit)
     (!select-reference-lint-design
      ?repository ?target-branch ?basis-commit)
     (!classify-reference-policy
      ?repository ?target-branch ?basis-commit)
     (!define-commit-3-execution-contract
      ?repository ?target-branch ?basis-commit)
     (!record-commit-3-preparation
      ?repository ?target-branch ?basis-commit)))))
