;;;; Live SHOP3 execution-planning domain for eighth extraction commit 3.

(in-package #:dreyeck/shop3)

(defdomain eighth-dreyeck-extraction-commit-3-execution-domain
  ((:op (!delete-legacy-shop3-copy ?path)
    :precond
    (and
     (selected-deletion-target ?path)
     (legacy-implementation-copy ?path)
     (pending-legacy-copy-deletion ?path)
     (not (legacy-copy-deletion-performed ?path)))
    :delete
    ((pending-legacy-copy-deletion ?path))
    :add
    ((legacy-copy-deletion-performed ?path)))

   (:op (!write-shop3-reference-boundary-checker ?path)
    :precond
    (and
     (selected-reference-boundary-checker ?path)
     (pending-reference-boundary-checker-write ?path)
     (not (shop3-reference-boundary-checker-written ?path))
     (reference-policy added-lines-only)
     (reference-classification-uses-path-and-kind true))
    :delete
    ((pending-reference-boundary-checker-write ?path))
    :add
    ((shop3-reference-boundary-checker-written ?path)))

   (:op (!write-shop3-reference-boundary-fixture ?kind ?path)
    :precond
    (and
     (selected-reference-boundary-fixture ?kind ?path)
     (pending-reference-boundary-fixture-write ?kind ?path)
     (not (shop3-reference-boundary-fixture-written ?kind ?path))
     (shop3-reference-boundary-checker-written
      "tools/check-shop3-reference-boundary.lisp"))
    :delete
    ((pending-reference-boundary-fixture-write ?kind ?path))
    :add
    ((shop3-reference-boundary-fixture-written ?kind ?path)))

   (:op (!wire-shop3-reference-boundary-checker ?path)
    :precond
    (and
     (selected-reference-boundary-gate ?path)
     (pending-reference-boundary-gate-wiring ?path)
     (not (shop3-reference-boundary-checker-wired ?path))
     (shop3-reference-boundary-checker-written
      "tools/check-shop3-reference-boundary.lisp")
     (shop3-reference-boundary-fixture-written
      :allowed
      "tools/testdata/shop3-reference-boundary/allowed-added-lines.diff")
     (shop3-reference-boundary-fixture-written
      :rejected
      "tools/testdata/shop3-reference-boundary/rejected-added-lines.diff"))
    :delete
    ((pending-reference-boundary-gate-wiring ?path))
    :add
    ((shop3-reference-boundary-checker-wired ?path)))

   (:op (!run-shop3-reference-boundary-fixtures)
    :precond
    (and
     (pending-reference-boundary-fixture-validation)
     (shop3-reference-boundary-checker-wired "tools/pre-commit-gate.sh")
     (shop3-reference-boundary-fixture-written
      :allowed
      "tools/testdata/shop3-reference-boundary/allowed-added-lines.diff")
     (shop3-reference-boundary-fixture-written
      :rejected
      "tools/testdata/shop3-reference-boundary/rejected-added-lines.diff"))
    :delete
    ((pending-reference-boundary-fixture-validation))
    :add
    ((allowed-lint-fixture-passed)
     (rejected-lint-fixture-rejected)))

   (:op (!run-direct-shop3-load-and-gap-canary)
    :precond
    (and
     (pending-direct-shop3-canary)
     (allowed-lint-fixture-passed)
     (rejected-lint-fixture-rejected)
     (canonical-shop3-direct-component-count 6)
     (primary-shop3-package dreyeck/shop3))
    :delete
    ((pending-direct-shop3-canary))
    :add
    ((direct-shop3-canary-passed)))

   (:op (!run-compatibility-shop3-load-and-gap-canary)
    :precond
    (and
     (pending-compatibility-shop3-canary)
     (direct-shop3-canary-passed)
     (compatibility-shop3-direct-component-count 0)
     (compatibility-shop3-depends-on dreyeck/shop3)
     (legacy-shop3-package-nickname hyperdoc/shop3))
    :delete
    ((pending-compatibility-shop3-canary))
    :add
    ((compatibility-shop3-canary-passed)))

   (:op (!run-dual-load-identity-canary)
    :precond
    (and
     (pending-dual-load-identity-canary)
     (direct-shop3-canary-passed)
     (compatibility-shop3-canary-passed))
    :delete
    ((pending-dual-load-identity-canary))
    :add
    ((dual-load-identity-canary-passed)))

   (:op (!run-shop3-provider-boundary-tests)
    :precond
    (and
     (pending-shop3-provider-boundary-tests)
     (dual-load-identity-canary-passed)
     (provider-boundary-files-preserved))
    :delete
    ((pending-shop3-provider-boundary-tests))
    :add
    ((provider-boundary-tests-passed)))

   (:op (!run-repository-load-gate)
    :precond
    (and
     (pending-repository-load-gate)
     (provider-boundary-tests-passed)
     (documentation-workflows-preserved)
     (projection-repair-deferred))
    :delete
    ((pending-repository-load-gate))
    :add
    ((repository-load-gate-passed)))

   (:op (!write-commit-3-execution-evidence ?path)
    :precond
    (and
     (selected-commit-3-execution-evidence-path ?path)
     (pending-commit-3-execution-evidence-write ?path)
     (repository-load-gate-passed))
    :delete
    ((pending-commit-3-execution-evidence-write ?path))
    :add
    ((commit-3-execution-evidence-written ?path)))

   (:op (!record-commit-3-execution-complete)
    :precond
    (and
     (pending-commit-3-execution-completion-record)
     (legacy-copy-deletion-performed "hyperdoc-shop3/package.lisp")
     (legacy-copy-deletion-performed "hyperdoc-shop3/manual-topics.lisp")
     (legacy-copy-deletion-performed "hyperdoc-shop3/plan-objects.lisp")
     (legacy-copy-deletion-performed
      "hyperdoc-shop3/hyperdoc-maintenance-domain.lisp")
     (legacy-copy-deletion-performed "hyperdoc-shop3/examples.lisp")
     (legacy-copy-deletion-performed "hyperdoc-shop3/views.lisp")
     (shop3-reference-boundary-checker-written
      "tools/check-shop3-reference-boundary.lisp")
     (shop3-reference-boundary-checker-wired "tools/pre-commit-gate.sh")
     (allowed-lint-fixture-passed)
     (rejected-lint-fixture-rejected)
     (direct-shop3-canary-passed)
     (compatibility-shop3-canary-passed)
     (dual-load-identity-canary-passed)
     (provider-boundary-tests-passed)
     (repository-load-gate-passed)
     (commit-3-execution-evidence-written
      "hyperdoc/evidence/refactor-hyperdoc-eighth-extraction-commit-3-execution.sexp")
     (canonical-shop3-direct-component-count 6)
     (compatibility-shop3-direct-component-count 0)
     (compatibility-shop3-depends-on dreyeck/shop3)
     (primary-shop3-package dreyeck/shop3)
     (legacy-shop3-package-nickname hyperdoc/shop3)
     (provider-boundary-files-preserved)
     (documentation-workflows-preserved)
     (projection-repair-deferred))
    :delete
    ((pending-commit-3-execution-completion-record))
    :add
    ((commit-3-execution-planned)
     (next-task review-eighth-dreyeck-extraction-commit-3)))

   (:method
    (execute-eighth-dreyeck-extraction-commit-3
     ?repository ?target-branch ?basis-commit)
    (and
     (repository ?repository)
     (target-branch ?target-branch)
     (basis-commit ?basis-commit)
     (commit-3-prepared
      ?repository ?target-branch
      "ab1926eb807e5e8721b888a34736ada458209a40")
     (preparation-problem-materialized-at ?basis-commit)
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
     (projection-repair-deferred))
    ((!delete-legacy-shop3-copy "hyperdoc-shop3/package.lisp")
     (!delete-legacy-shop3-copy "hyperdoc-shop3/manual-topics.lisp")
     (!delete-legacy-shop3-copy "hyperdoc-shop3/plan-objects.lisp")
     (!delete-legacy-shop3-copy
      "hyperdoc-shop3/hyperdoc-maintenance-domain.lisp")
     (!delete-legacy-shop3-copy "hyperdoc-shop3/examples.lisp")
     (!delete-legacy-shop3-copy "hyperdoc-shop3/views.lisp")
     (!write-shop3-reference-boundary-checker
      "tools/check-shop3-reference-boundary.lisp")
     (!write-shop3-reference-boundary-fixture
      :allowed
      "tools/testdata/shop3-reference-boundary/allowed-added-lines.diff")
     (!write-shop3-reference-boundary-fixture
      :rejected
      "tools/testdata/shop3-reference-boundary/rejected-added-lines.diff")
     (!wire-shop3-reference-boundary-checker "tools/pre-commit-gate.sh")
     (!run-shop3-reference-boundary-fixtures)
     (!run-direct-shop3-load-and-gap-canary)
     (!run-compatibility-shop3-load-and-gap-canary)
     (!run-dual-load-identity-canary)
     (!run-shop3-provider-boundary-tests)
     (!run-repository-load-gate)
     (!write-commit-3-execution-evidence
      "hyperdoc/evidence/refactor-hyperdoc-eighth-extraction-commit-3-execution.sexp")
     (!record-commit-3-execution-complete)))))
