(:refactor-hyperdoc-second-dreyeck-extraction-post-review
 (:operation (!review-second-extraction-slice-after-execution))
 (:reviewed-commit "7ea57454")
 (:moved-file
  (:from "hyperdoc/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp"
   :to "dreyeck/dmx/sqlite/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp"
   :classification :dreyeck-owned-situated-surface
   :target-system :dreyeck/dmx/sqlite))
 (:semantic-ownership-review
  ((:verdict :dreyeck/dmx/sqlite-owned)
   (:reason
    "The moved artifact is a SHOP3-shaped plan for materializing durable Markdown-note seeds into the Dreyeck DMX SQLite topic store. The plan names dreyeck-dmx-sqlite-production-db, validates :dreyeck/dmx/sqlite, and is referenced by Dreyeck DMX durable-note source data rather than HyperDoc or HyperBook core loaders.")
   (:core-load-path-required-p nil)
   (:hyperdoc-core-file-p nil)
   (:hyperbook-core-file-p nil)))
 (:reference-review
  (:tracked-source-old-path-references nil)
  (:historical-old-path-references
   ((:file "hyperdoc/evidence/refactor-hyperdoc-second-dreyeck-extraction-selection.sexp"
     :classification :selection-history)
    (:file "hyperdoc/evidence/refactor-hyperdoc-second-dreyeck-extraction-review.sexp"
     :classification :pre-execution-review-history)
    (:file "hyperdoc/evidence/refactor-hyperdoc-second-dreyeck-extraction-result.sexp"
     :classification :execution-result-history)
    (:file "hyperdoc/evidence/refactor-hyperdoc-second-dreyeck-extraction-post-review.sexp"
     :classification :post-review-history)))
  (:untracked-or-runtime-old-path-references
   ((:file "var/dmx-associative-mirror.sqlite"
     :tracked-source-p nil
     :classification :runtime-database-mirror)))
  (:new-path-references
   ((:file "dreyeck/dmx/sqlite/durable-notes.lisp"
     :lines (20 65)
     :classification :active-dreyeck-dmx-source)
    (:file "dreyeck/dmx/sqlite/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp"
     :lines (102)
     :classification :moved-plan-self-validation)
    (:file "hyperdoc/materialize-and-verify-operation-documentation-topics-shop3-plan.sexp"
     :lines (11)
     :classification :plan-cross-reference)
    (:file "hyperdoc/the-1998-ai-planning-systems-competition-fedwiki-asdf-system-plan.sexp"
     :lines (51)
     :classification :plan-cross-reference)
    (:file "tests/refactor-hyperdoc-second-dreyeck-extraction-smoke.lisp"
     :lines (54)
     :classification :focused-smoke)
    (:file "hyperdoc/evidence/refactor-hyperdoc-second-dreyeck-extraction-result.sexp"
     :classification :execution-result)
    (:file "hyperdoc/evidence/refactor-hyperdoc-second-dreyeck-extraction-selection.sexp"
     :classification :historical-target-record)
    (:file "hyperdoc/evidence/refactor-hyperdoc-second-dreyeck-extraction-review.sexp"
     :classification :historical-target-record)
    (:file "hyperdoc/evidence/refactor-hyperdoc-second-dreyeck-extraction-post-review.sexp"
     :classification :post-review-target-record)))
  (:commands
   ((:git-grep-old-path
     "git grep -n \"hyperdoc/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp\" || true")
    (:git-grep-new-path
     "git grep -n \"dreyeck/dmx/sqlite/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp\" || true")
    (:tracked-source-old-path-negative-check
     "git grep -n \"hyperdoc/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp\" -- . ':!hyperdoc/evidence/refactor-hyperdoc-second-dreyeck-extraction-selection.sexp' ':!hyperdoc/evidence/refactor-hyperdoc-second-dreyeck-extraction-review.sexp' ':!hyperdoc/evidence/refactor-hyperdoc-second-dreyeck-extraction-result.sexp' ':!hyperdoc/evidence/refactor-hyperdoc-second-dreyeck-extraction-post-review.sexp' || true")
    (:filesystem-old-path-check
     "grep -R \"hyperdoc/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp\" -n . --exclude-dir=.git --exclude='repomix-output*' || true"))))
 (:compatibility-shell-required-p nil)
 (:asdf-update-required-p nil)
 (:review-verdict :accepted)
 (:validations
  ((:git-diff-check :passed)
   (:hyperdoc-load :passed)
   (:dreyeck/dmx/sqlite-load :passed)
   (:shop3-provider-boundary-tests :passed)
   (:second-extraction-smoke :passed)))
 (:actions-not-performed
  ((:file-moves t)
   (:deletions t)
   (:third-slice-selection t)
   (:bulk-migration t)
   (:pi-actions t)
   (:ssh t)
   (:sudo t)
   (:nixos-rebuild t)
   (:wifi-secret-prompt t)))
 (:next
  (:if-accepted (!select-third-low-risk-dreyeck-extraction-slice)
   :if-needs-repair (!repair-second-dreyeck-extraction-slice))))
