(:refactor-hyperdoc-fifth-dreyeck-extraction-review
 (:operation (!review-fifth-slice-selection-before-execution))
 (:selection-commit "cb858849")
 (:selection-artifact
  "hyperdoc/evidence/refactor-hyperdoc-fifth-dreyeck-extraction-selection.sexp")
 (:selected-file
  (:from "hyperdoc/render-build-referee-decisions-as-routes-plan.sexp"
   :to "dreyeck/build/render-build-referee-decisions-as-routes-plan.sexp"
   :classification :dreyeck-owned-situated-surface
   :target-system :dreyeck/build
   :target-directory "dreyeck/build/"))
 (:review-questions
  ((:is-selected-file-dreyeck-owned-situated-surface-p t)
   (:is-target-system-dreyeck-build-correct-p t)
   (:does-file-belong-to-hyperdoc-core-p nil)
   (:does-hyperdoc-core-load-require-old-path-p nil)
   (:are-there-source-references-to-old-path-p t)
   (:is-compatibility-shell-required-p nil)
   (:is-asdf-update-required-p nil)
   (:is-the-move-still-low-risk-p t)))
 (:reference-scan
  (:commands
   ("git grep -n \"hyperdoc/render-build-referee-decisions-as-routes-plan.sexp\" -- ':!hyperdoc/evidence/*' || true"
    "git grep -n \"render-build-referee-decisions-as-routes-plan\" || true"
    "git grep -n \"dreyeck/build/render-build-referee-decisions-as-routes-plan.sexp\" || true"))
  (:live-old-path-references
   ((:file "dreyeck/dmx/sqlite/durable-notes.lisp" :line 83 :classification :active-dreyeck-dmx-source)
    (:file "dreyeck/dmx/sqlite/durable-notes.lisp" :line 148 :classification :active-dreyeck-dmx-source)
    (:file "dreyeck/dmx/sqlite/durable-notes.lisp" :line 155 :classification :active-dreyeck-dmx-source)
    (:file "dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp"
     :line 37
     :classification :active-dreyeck-dmx-plan)
    (:file "hyperdoc/render-build-referee-decisions-as-routes-plan.sexp"
     :line 113
     :classification :selected-file-self-reference)))
  (:historical-old-path-references
   ((:file "hyperdoc/evidence/refactor-hyperdoc-fourth-dreyeck-extraction-selection.sexp"
     :line 66)
    (:file "hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-review.sexp"
     :line 39)
    (:file "hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-selection.sexp"
     :line 52)))
  (:new-path-references nil))
 (:execution-requirements
  (:source-reference-update-required-p t)
  (:references-to-update
   ("dreyeck/dmx/sqlite/durable-notes.lisp"
    "dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp"
    "hyperdoc/render-build-referee-decisions-as-routes-plan.sexp"))
  (:compatibility-shell-required-p nil)
  (:asdf-update-required-p nil)
  (:validation-policy
   (:old-path-blockers-only-live-source-or-executable-references t)
   (:data-only-plan-artifact-not-asdf-component t)))
 (:review-verdict :accepted)
 (:validations
  ((:git-diff-check :passed)
   (:review-artifact-read :passed)
   (:hyperdoc-load :passed)
   (:target-dreyeck-system-load :passed)
   (:shop3-provider-boundary-tests :passed)))
 (:actions-not-performed
  ((:file-move t)
   (:deletion t)
   (:bulk-migration t)
   (:pi-actions t)
   (:ssh t)
   (:sudo t)
   (:nixos-rebuild t)
   (:wifi-secret-prompt t)))
 (:next
  (:if-accepted (!execute-fifth-low-risk-dreyeck-extraction-slice)
   :if-needs-repair (!repair-fifth-slice-selection-before-execution))))
