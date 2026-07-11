(:refactor-hyperdoc-sixth-dreyeck-extraction-post-review
 (:operation (!review-sixth-extraction-slice-after-execution))
 (:reviewed-commit "5e4896bc")
 (:moved-file
  (:from "hyperdoc/inspect-dmx-materialized-learning-topics-plan.sexp"
   :to "dreyeck/codex/inspect-dmx-materialized-learning-topics-plan.sexp"
   :classification :dreyeck-owned-situated-surface
   :target-system :dreyeck/codex))
 (:reference-review
  (:tracked-source-old-path-references nil)
  (:historical-old-path-references
   ((:file "hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-selection.sexp"
     :classification :historical-selection-evidence)
    (:file "hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-review.sexp"
     :classification :historical-review-evidence)
    (:file "hyperdoc/evidence/refactor-hyperdoc-fourth-dreyeck-extraction-selection.sexp"
     :classification :historical-selection-evidence)
    (:file "hyperdoc/evidence/refactor-hyperdoc-fifth-dreyeck-extraction-selection.sexp"
     :classification :historical-selection-evidence)
    (:file "hyperdoc/evidence/refactor-hyperdoc-sixth-dreyeck-extraction-selection.sexp"
     :classification :current-slice-selection-evidence)
    (:file "hyperdoc/evidence/refactor-hyperdoc-sixth-dreyeck-extraction-review.sexp"
     :classification :current-slice-review-evidence)
    (:file "hyperdoc/evidence/refactor-hyperdoc-sixth-dreyeck-extraction-result.sexp"
     :classification :current-slice-execution-evidence)
    (:file "hyperdoc/evidence/refactor-hyperdoc-upstream-core-dreyeck-extraction-result.sexp"
     :classification :superseded-checkpoint-evidence-to-update-after-assimilation)))
  (:untracked-or-runtime-old-path-references :not-scanned)
  (:new-path-references
   ((:file "dreyeck/codex.lisp" :classification :active-dreyeck-codex-source)
    (:file "dreyeck/codex/inspect-dmx-materialized-learning-topics-plan.sexp"
     :classification :moved-plan-self-reference)
    (:file "dreyeck/dmx/sqlite/durable-notes.lisp" :classification :active-dreyeck-dmx-source)
    (:file "hyperdoc/evidence/refactor-hyperdoc-sixth-dreyeck-extraction-selection.sexp"
     :classification :selection-evidence)
    (:file "hyperdoc/evidence/refactor-hyperdoc-sixth-dreyeck-extraction-review.sexp"
     :classification :review-evidence)
    (:file "hyperdoc/evidence/refactor-hyperdoc-sixth-dreyeck-extraction-result.sexp"
     :classification :execution-evidence))))
 (:compatibility-shell-required-p nil)
 (:asdf-update-required-p nil)
 (:review-verdict :accepted)
 (:validations
  ((:git-diff-check :passed)
   (:moved-plan-read :passed)
   (:execution-result-read :passed)
   (:old-path-reference-check :passed)
   (:new-path-reference-check :passed)
   (:hyperdoc-load :passed)
   (:dreyeck/codex-load :passed)
   (:dreyeck/dmx/sqlite-load :passed)
   (:hyperdoc/shop3-provider-boundary/tests :passed)
   (:dreyeck/codex/tests :passed)
   (:dreyeck/dmx/sqlite/tests :passed)
   (:pre-commit-load-gate :passed)))
 (:actions-not-performed
  ((:additional-file-moves t)
   (:deletions t)
   (:bulk-migration t)
   (:pi-actions t)
   (:ssh t)
   (:sudo t)
   (:nixos-rebuild t)
   (:wifi-secret-prompt t)))
 (:next
  (:if-accepted (!assimilate-sixth-extraction-slice-into-reusable-htn)
   :if-needs-repair (!repair-sixth-dreyeck-extraction-slice))))
