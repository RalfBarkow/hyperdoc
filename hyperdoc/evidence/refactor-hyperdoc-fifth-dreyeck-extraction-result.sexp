(:refactor-hyperdoc-fifth-dreyeck-extraction-result
 (:operation (!execute-fifth-low-risk-dreyeck-extraction-slice))
 (:base "c87debef")
 (:selection-commit "cb858849")
 (:review-commit "c87debef")
 (:moved-file
  ("hyperdoc/render-build-referee-decisions-as-routes-plan.sexp"
   "dreyeck/build/render-build-referee-decisions-as-routes-plan.sexp"))
 (:updated-live-references
  ("dreyeck/dmx/sqlite/durable-notes.lisp"
   "dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp"
   "dreyeck/build/render-build-referee-decisions-as-routes-plan.sexp"))
 (:compatibility-shells nil)
 (:asdf-updates nil)
 (:reference-review
  (:live-old-path-references nil)
  (:old-path-references-remaining
   (:historical-evidence-only
    ("hyperdoc/evidence/refactor-hyperdoc-fifth-dreyeck-extraction-review.sexp"
     "hyperdoc/evidence/refactor-hyperdoc-fifth-dreyeck-extraction-selection.sexp"
     "hyperdoc/evidence/refactor-hyperdoc-fourth-dreyeck-extraction-selection.sexp"
     "hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-review.sexp"
     "hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-selection.sexp")))
  (:new-path-references
   ("dreyeck/build/render-build-referee-decisions-as-routes-plan.sexp"
    "dreyeck/dmx/sqlite/durable-notes.lisp"
    "dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp")))
 (:validations
  ((:git-diff-check :passed)
   (:moved-plan-minimal-read :text-fallback-required-package-qualified-symbol)
   (:moved-plan-text-fallback :passed)
   (:result-artifact-read :passed)
   (:old-path-live-reference-check :passed)
   (:new-path-reference-check :passed)
   (:hyperdoc-load :passed)
   (:target-dreyeck-system-load :passed)
   (:dreyeck-dmx-sqlite-load :passed)
   (:shop3-provider-boundary-tests :passed)
   (:dreyeck-build-tests :passed)
   (:dreyeck-dmx-sqlite-tests :passed)))
 (:actions-not-performed
  ((:deletions t)
   (:bulk-migration t)
   (:pi-actions t)
   (:ssh t)
   (:sudo t)
   (:nixos-rebuild t)
   (:wifi-secret-prompt t)))
 (:next (!review-fifth-extraction-slice-after-execution)))
