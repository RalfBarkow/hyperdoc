;;;; Live SHOP3 domain for the eighth extraction commit-3 localization.

(in-package #:dreyeck/shop3)

(defdomain eighth-dreyeck-extraction-commit-3-localization-domain
  ((:op (!record-no-specialized-plan-found
         ?repository ?target-branch ?basis-commit)
    :precond
    (and (repository ?repository)
         (target-branch ?target-branch)
         (basis-commit ?basis-commit)
         (specialized-removal-lint-plan-found false))
    :add
    ((no-specialized-removal-lint-plan-recorded
      ?repository ?target-branch ?basis-commit)))

   (:op (!classify-legacy-implementation-copy-set
         ?repository ?target-branch ?basis-commit)
    :precond
    (and
     (no-specialized-removal-lint-plan-recorded
      ?repository ?target-branch ?basis-commit)
     (legacy-implementation-copy "hyperdoc-shop3/package.lisp")
     (legacy-implementation-copy "hyperdoc-shop3/manual-topics.lisp")
     (legacy-implementation-copy "hyperdoc-shop3/plan-objects.lisp")
     (legacy-implementation-copy
      "hyperdoc-shop3/hyperdoc-maintenance-domain.lisp")
     (legacy-implementation-copy "hyperdoc-shop3/examples.lisp")
     (legacy-implementation-copy "hyperdoc-shop3/views.lisp")
     (legacy-implementation-copy-count 6)
     (legacy-implementation-copies-live-asdf-components false))
    :add
    ((legacy-implementation-copy-set-classified
      ?repository ?target-branch ?basis-commit)))

   (:op (!classify-live-and-historical-references
         ?repository ?target-branch ?basis-commit)
    :precond
    (and
     (legacy-implementation-copy-set-classified
      ?repository ?target-branch ?basis-commit)
     (tracked-shop3-reference-path-count 45)
     (new-code-contradictory-reference-count 0)
     (compatibility-reference-policy-preserved))
    :add
    ((shop3-reference-boundary-classified
      ?repository ?target-branch ?basis-commit)))

   (:op (!select-commit-3-preparation-boundary
         ?repository ?target-branch ?basis-commit)
    :precond
    (and
     (shop3-reference-boundary-classified
      ?repository ?target-branch ?basis-commit)
     (canonical-shop3-owner dreyeck/shop3)
     (compatibility-system hyperdoc/shop3)
     (provider-boundary-move-deferred)
     (documentation-workflow-move-deferred)
     (projection-repair-deferred))
    :add
    ((commit-3-preparation-boundary-selected
      ?repository ?target-branch ?basis-commit)))

   (:op (!record-localization-result
         ?repository ?target-branch ?basis-commit)
    :precond
    (and
     (no-specialized-removal-lint-plan-recorded
      ?repository ?target-branch ?basis-commit)
     (commit-3-preparation-boundary-selected
      ?repository ?target-branch ?basis-commit))
    :add
    ((commit-3-localization-recorded
      ?repository ?target-branch ?basis-commit)
     (next-task prepare-eighth-dreyeck-extraction-commit-3)))

   (:method
    (localize-eighth-dreyeck-extraction-commit-3
     ?repository ?target-branch ?basis-commit)
    (and (repository ?repository)
         (target-branch ?target-branch)
         (basis-commit ?basis-commit)
         (canonical-shop3-owner dreyeck/shop3)
         (compatibility-system hyperdoc/shop3)
         (specialized-removal-lint-plan-found false))
    ((!record-no-specialized-plan-found
      ?repository ?target-branch ?basis-commit)
     (!classify-legacy-implementation-copy-set
      ?repository ?target-branch ?basis-commit)
     (!classify-live-and-historical-references
      ?repository ?target-branch ?basis-commit)
     (!select-commit-3-preparation-boundary
      ?repository ?target-branch ?basis-commit)
     (!record-localization-result
      ?repository ?target-branch ?basis-commit)))))
