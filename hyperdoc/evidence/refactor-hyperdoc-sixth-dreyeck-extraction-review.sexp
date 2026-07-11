(:refactor-hyperdoc-sixth-dreyeck-extraction-review
 (:operation (!review-sixth-slice-selection-before-execution))
 (:selection-commit "491ac513")
 (:selection-artifact "hyperdoc/evidence/refactor-hyperdoc-sixth-dreyeck-extraction-selection.sexp")
 (:selected-file
  (:from "hyperdoc/inspect-dmx-materialized-learning-topics-plan.sexp"
   :to "dreyeck/codex/inspect-dmx-materialized-learning-topics-plan.sexp"
   :classification :dreyeck-owned-situated-surface
   :target-owner :dreyeck/codex
   :target-system :dreyeck/codex
   :target-directory "dreyeck/codex/"))
 (:review-questions
  ((:is-selected-file-dreyeck-owned-situated-surface-p t)
   (:is-target-system-dreyeck-codex-correct-p t)
   (:does-file-belong-to-hyperdoc-core-p nil)
   (:does-hyperdoc-core-load-require-old-path-p nil)
   (:does-hyperbook-core-load-require-old-path-p nil)
   (:are-there-source-references-to-old-path-p t)
   (:is-compatibility-shell-required-p nil)
   (:is-asdf-update-required-p nil)
   (:is-the-move-still-low-risk-p t)))
 (:reference-scan
  (:commands
   ("git grep -n \"hyperdoc/inspect-dmx-materialized-learning-topics-plan.sexp\""
    "git grep -n \"inspect-dmx-materialized-learning-topics-plan\""
    "git grep -n \"dreyeck/codex/inspect-dmx-materialized-learning-topics-plan.sexp\""))
  (:old-path-references
   ((:file "dreyeck/codex.lisp"
     :line 994
     :classification :active-dreyeck-codex-source
     :required-action :update-to-new-path)
    (:file "dreyeck/dmx/sqlite/durable-notes.lisp"
     :line 71
     :classification :active-dreyeck-dmx-source
     :required-action :update-to-new-path)
    (:file "dreyeck/dmx/sqlite/durable-notes.lisp"
     :line 117
     :classification :active-dreyeck-dmx-source
     :required-action :update-to-new-path)
    (:file "dreyeck/dmx/sqlite/durable-notes.lisp"
     :line 123
     :classification :active-dreyeck-dmx-source
     :required-action :update-to-new-path)
    (:file "dreyeck/dmx/sqlite/durable-notes.lisp"
     :line 129
     :classification :active-dreyeck-dmx-source
     :required-action :update-to-new-path)
    (:file "dreyeck/dmx/sqlite/durable-notes.lisp"
     :line 135
     :classification :active-dreyeck-dmx-source
     :required-action :update-to-new-path)
    (:file "hyperdoc/inspect-dmx-materialized-learning-topics-plan.sexp"
     :line 112
     :classification :selected-file-self-reference
     :required-action :update-after-move)))
  (:historical-evidence-old-path-references
   (:allowed-files
    ("hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-selection.sexp"
     "hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-review.sexp"
     "hyperdoc/evidence/refactor-hyperdoc-fourth-dreyeck-extraction-selection.sexp"
     "hyperdoc/evidence/refactor-hyperdoc-fifth-dreyeck-extraction-selection.sexp"
     "hyperdoc/evidence/refactor-hyperdoc-sixth-dreyeck-extraction-selection.sexp"
     "hyperdoc/evidence/refactor-hyperdoc-upstream-core-dreyeck-extraction-result.sexp")))
  (:basename-references
   (:expected-old-path-plus-selection-evidence t))
  (:new-path-references
   ((:file "hyperdoc/evidence/refactor-hyperdoc-sixth-dreyeck-extraction-selection.sexp"
     :classification :selection-evidence))))
 (:execution-requirements
  (:source-reference-update-required-p t)
  (:references-to-update
   ("dreyeck/codex.lisp"
    "dreyeck/dmx/sqlite/durable-notes.lisp"
    "dreyeck/codex/inspect-dmx-materialized-learning-topics-plan.sexp"))
  (:compatibility-shell-required-p nil)
  (:asdf-update-required-p nil)
  (:move-command
   "git mv hyperdoc/inspect-dmx-materialized-learning-topics-plan.sexp dreyeck/codex/inspect-dmx-materialized-learning-topics-plan.sexp"))
 (:review-verdict :accepted)
 (:validations
  ((:git-diff-check :passed)
   (:review-artifact-read :passed)
   (:hyperdoc-load :passed)
   (:dreyeck/codex-load :passed)
   (:dreyeck/dmx/sqlite-load :passed)
   (:hyperdoc/shop3-provider-boundary/tests :passed)
   (:dreyeck/codex/tests :passed)
   (:dreyeck/dmx/sqlite/tests :passed)))
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
  (:if-accepted (!execute-sixth-low-risk-dreyeck-extraction-slice)
   :if-needs-repair (!repair-sixth-slice-selection-before-execution))))
