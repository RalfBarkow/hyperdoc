(:refactor-hyperdoc-fourth-dreyeck-extraction-review
 (:operation (!review-fourth-slice-selection-before-execution))
 (:selection-commit "a9a3f7c1")
 (:selection-artifact
  "hyperdoc/evidence/refactor-hyperdoc-fourth-dreyeck-extraction-selection.sexp")
 (:selected-file
  (:from "hyperdoc/add-plan-then-perform-session-state-to-dreyeck-build-plan.sexp"
   :to "dreyeck/build/add-plan-then-perform-session-state-to-dreyeck-build-plan.sexp"
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
   ("git grep -n \"hyperdoc/add-plan-then-perform-session-state-to-dreyeck-build-plan.sexp\" || true"
    "git grep -n \"add-plan-then-perform-session-state-to-dreyeck-build-plan\" || true"
    "git grep -n \"dreyeck/build/add-plan-then-perform-session-state-to-dreyeck-build-plan.sexp\" || true"))
  (:live-old-path-references
   ((:file "dreyeck/build/tasks.lisp"
     :line 668
     :text "\"hyperdoc/add-plan-then-perform-session-state-to-dreyeck-build-plan.sexp\""
     :classification :active-dreyeck-build-source)
    (:file "dreyeck/dmx/sqlite/durable-notes.lisp"
     :line 77
     :text ":source \"hyperdoc/add-plan-then-perform-session-state-to-dreyeck-build-plan.sexp\""
     :classification :active-dreyeck-dmx-source)
    (:file "dreyeck/dmx/sqlite/durable-notes.lisp"
     :line 141
     :text ":source \"hyperdoc/add-plan-then-perform-session-state-to-dreyeck-build-plan.sexp\""
     :classification :active-dreyeck-dmx-source)
    (:file "dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp"
     :line 36
     :text "\"hyperdoc/add-plan-then-perform-session-state-to-dreyeck-build-plan.sexp\""
     :classification :active-dreyeck-dmx-plan)
    (:file "hyperdoc/add-plan-then-perform-session-state-to-dreyeck-build-plan.sexp"
     :line 132
     :text "\"hyperdoc/add-plan-then-perform-session-state-to-dreyeck-build-plan.sexp\""
     :classification :selected-file-self-reference)
    (:file "hyperdoc/kernighan-plauger-critical-reading-style-plan.sexp"
     :line 92
     :text "\"hyperdoc/add-plan-then-perform-session-state-to-dreyeck-build-plan.sexp\""
     :classification :plan-cross-reference)))
  (:historical-old-path-references
   ((:file "hyperdoc/evidence/refactor-hyperdoc-second-dreyeck-extraction-selection.sexp"
     :line 51)
    (:file "hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-review.sexp"
     :line 35)
    (:file "hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-selection.sexp"
     :line 46)
    (:file "hyperdoc/evidence/refactor-hyperdoc-fourth-dreyeck-extraction-selection.sexp"
     :lines (47 96 117 133))))
  (:new-path-references
   ((:file "hyperdoc/evidence/refactor-hyperdoc-fourth-dreyeck-extraction-selection.sexp"
     :lines (97 119)
     :classification :selection-evidence))))
 (:execution-requirements
  (:source-reference-update-required-p t)
  (:references-to-update
   ("dreyeck/build/tasks.lisp"
    "dreyeck/dmx/sqlite/durable-notes.lisp"
    "dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp"
    "hyperdoc/kernighan-plauger-critical-reading-style-plan.sexp"
    "hyperdoc/add-plan-then-perform-session-state-to-dreyeck-build-plan.sexp"))
  (:compatibility-shell-required-p nil)
  (:asdf-update-required-p nil)
  (:validation-policy
   (:treat-package-qualified-sexps-as-text-if-minimal-reader-lacks-package t)
   (:old-path-blockers-only-live-source-or-executable-references t)))
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
  (:if-accepted (!execute-fourth-low-risk-dreyeck-extraction-slice)
   :if-needs-repair (!repair-fourth-slice-selection-before-execution))))
