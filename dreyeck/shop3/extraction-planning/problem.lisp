;;;; Durable SHOP3 problem for the eighth extraction commit-3 localization.

(in-package #:dreyeck/shop3)

(defproblem eighth-dreyeck-extraction-commit-3-localization
    eighth-dreyeck-extraction-commit-3-localization-domain
  ((repository "/Users/rgb/workspace/hyperdoc/")
   (target-branch hauptsache)
   (basis-commit "59639866a1bb4aa9f27ddc43c383bd2907d196b3")
   (canonical-shop3-owner dreyeck/shop3)
   (compatibility-system hyperdoc/shop3)
   (legacy-implementation-copy "hyperdoc-shop3/package.lisp")
   (legacy-implementation-copy "hyperdoc-shop3/manual-topics.lisp")
   (legacy-implementation-copy "hyperdoc-shop3/plan-objects.lisp")
   (legacy-implementation-copy
    "hyperdoc-shop3/hyperdoc-maintenance-domain.lisp")
   (legacy-implementation-copy "hyperdoc-shop3/examples.lisp")
   (legacy-implementation-copy "hyperdoc-shop3/views.lisp")
   (legacy-implementation-copy-count 6)
   (legacy-implementation-copies-live-asdf-components false)
   (tracked-shop3-reference-path-count 45)
   (new-code-contradictory-reference-count 0)
   (compatibility-reference-policy-preserved)
   (provider-boundary-move-deferred)
   (documentation-workflow-move-deferred)
   (projection-repair-deferred)
   (specialized-removal-lint-plan-found false))
  ((localize-eighth-dreyeck-extraction-commit-3
    "/Users/rgb/workspace/hyperdoc/"
    hauptsache
    "59639866a1bb4aa9f27ddc43c383bd2907d196b3")))
