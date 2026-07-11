(:refactor-hyperdoc-fourth-dreyeck-extraction-result
 (:operation (!execute-fourth-low-risk-dreyeck-extraction-slice))
 (:base "4d199239")
 (:selection-commit "a9a3f7c1")
 (:review-commit "4d199239")
 (:review-artifact
  "hyperdoc/evidence/refactor-hyperdoc-fourth-dreyeck-extraction-review.sexp")
 (:moved-file
  ("hyperdoc/add-plan-then-perform-session-state-to-dreyeck-build-plan.sexp"
   "dreyeck/build/add-plan-then-perform-session-state-to-dreyeck-build-plan.sexp"))
 (:updated-live-references
  ("dreyeck/build/tasks.lisp"
   "dreyeck/dmx/sqlite/durable-notes.lisp"
   "dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp"
   "hyperdoc/kernighan-plauger-critical-reading-style-plan.sexp"
   "dreyeck/build/add-plan-then-perform-session-state-to-dreyeck-build-plan.sexp"))
 (:compatibility-shells nil)
 (:asdf-updates nil)
 (:reference-review
  (:live-old-path-references nil)
  (:old-path-references-remaining
   (:historical-evidence-only
    ("hyperdoc/evidence/refactor-hyperdoc-fourth-dreyeck-extraction-review.sexp"
     "hyperdoc/evidence/refactor-hyperdoc-fourth-dreyeck-extraction-selection.sexp"
     "hyperdoc/evidence/refactor-hyperdoc-second-dreyeck-extraction-selection.sexp"
     "hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-review.sexp"
     "hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-selection.sexp")))
  (:new-path-references
   ("dreyeck/build/add-plan-then-perform-session-state-to-dreyeck-build-plan.sexp"
    "dreyeck/build/tasks.lisp"
    "dreyeck/dmx/sqlite/durable-notes.lisp"
    "dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp"
    "hyperdoc/kernighan-plauger-critical-reading-style-plan.sexp")))
 (:validations
  ((:git-diff-check :passed)
   (:moved-plan-read :passed)
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
 (:next (!review-fourth-extraction-slice-after-execution)))
