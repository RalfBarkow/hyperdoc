(:refactor-hyperdoc-fifth-dreyeck-extraction-post-review
 (:operation (!review-fifth-extraction-slice-after-execution))
 (:reviewed-commit "98550d52")
 (:moved-file
  (:from "hyperdoc/render-build-referee-decisions-as-routes-plan.sexp"
   :to "dreyeck/build/render-build-referee-decisions-as-routes-plan.sexp"
   :classification :dreyeck-owned-situated-surface
   :target-system :dreyeck/build))
 (:reference-review
  (:tracked-live-old-path-references nil)
  (:historical-old-path-references
   (:expected
    ("hyperdoc/evidence/refactor-hyperdoc-fifth-dreyeck-extraction-result.sexp"
     "hyperdoc/evidence/refactor-hyperdoc-fifth-dreyeck-extraction-review.sexp"
     "hyperdoc/evidence/refactor-hyperdoc-fifth-dreyeck-extraction-selection.sexp"
     "hyperdoc/evidence/refactor-hyperdoc-fourth-dreyeck-extraction-selection.sexp"
     "hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-review.sexp"
     "hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-selection.sexp")))
  (:new-path-live-references
   ("dreyeck/build/render-build-referee-decisions-as-routes-plan.sexp"
    "dreyeck/dmx/sqlite/durable-notes.lisp"
    "dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp")))
 (:compatibility-shell-required-p nil)
 (:asdf-update-required-p nil)
 (:review-verdict :accepted)
 (:validations
  ((:git-diff-check :passed)
   (:moved-plan-text-fallback :passed)
   (:old-path-live-reference-check :passed)
   (:new-path-reference-check :passed)
   (:hyperdoc-load :passed)
   (:dreyeck-build-load :passed)
   (:dreyeck-dmx-sqlite-load :passed)
   (:shop3-provider-boundary-tests :passed)
   (:dreyeck-build-tests :passed)
   (:dreyeck-dmx-sqlite-tests :passed)
   (:pre-commit-load-gate :passed)))
 (:actions-not-performed
  ((:deletions t)
   (:bulk-migration t)
   (:pi-actions t)
   (:ssh t)
   (:sudo t)
   (:nixos-rebuild t)
   (:wifi-secret-prompt t)))
 (:next
  (:if-accepted (!assimilate-fifth-refactoring-episode-into-htn)
   :if-needs-repair (!repair-fifth-dreyeck-extraction-slice))))
