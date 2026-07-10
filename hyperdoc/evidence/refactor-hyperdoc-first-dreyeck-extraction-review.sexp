(:refactor-hyperdoc-first-dreyeck-extraction-review
 (:reviewed-commit "b0b7be61")
 (:operation (!review-first-extraction-slice-before-continuing))
 (:moved-files
  ((:from "hyperdoc/contact-db-codex-next-htn.sexp"
    :to "dreyeck/codex/contact-db/contact-db-codex-next-htn.sexp"
    :classification :dreyeck-owned-situated-surface)
   (:from "hyperdoc/contact-db-codex-next-prompt.md"
    :to "dreyeck/codex/contact-db/contact-db-codex-next-prompt.md"
    :classification :dreyeck-owned-situated-surface)
   (:from "hyperdoc/contact-db-codex-next-shop3-plan.sexp"
    :to "dreyeck/codex/contact-db/contact-db-codex-next-shop3-plan.sexp"
    :classification :dreyeck-owned-situated-surface)))
 (:semantic-ownership-review
  ((:verdict :dreyeck-owned)
   (:reason
    "The artifacts are Codex continuation and handoff data for Contact DB materialization. They describe project collaboration state, deferred tasks, page-attached ASDF materialization, local SQLite schema planning, and native-store boundaries; they are not reusable HyperDoc rendering, HyperBook, or SHOP3-provider substrate.")
   (:target-owner :dreyeck/codex)
   (:placement "dreyeck/codex/contact-db/")
   (:placement-review
    "The existing :dreyeck/codex system owns Codex context, next-task, handoff, and collaboration surfaces. The contact-db subdirectory keeps non-ASDF handoff artifacts under that owner without changing the load graph.")))
 (:old-path-references
  ((:command
    "grep -R \"hyperdoc/contact-db-codex-next\" -n . --exclude-dir=.git --exclude='repomix-output*' || true")
   (:matches
    ((:file "tests/refactor-hyperdoc-first-dreyeck-extraction-smoke.lisp"
      :classification :absence-assertion
      :stale nil)
     (:file "hyperdoc/evidence/refactor-hyperdoc-first-dreyeck-extraction-review.sexp"
      :classification :review-record
      :stale nil)
     (:file "hyperdoc/evidence/refactor-hyperdoc-first-dreyeck-extraction-selection.sexp"
      :classification :historical-from-path
      :stale nil)
     (:file "hyperdoc/evidence/refactor-hyperdoc-first-dreyeck-extraction-result.sexp"
      :classification :historical-from-path
      :stale nil)))
   (:stale-old-path-references nil)
   (:hyperdoc-core-assumes-old-path nil)
   (:asdf-system-assumes-old-path nil)
   (:test-load-path-assumes-old-path nil)
   (:topic-registry-assumes-old-path nil)))
 (:new-path-references
  ((:command
    "grep -R \"contact-db-codex-next\" -n . --exclude-dir=.git --exclude='repomix-output*' || true")
   (:active-new-paths
    ("dreyeck/codex/contact-db/contact-db-codex-next-htn.sexp"
     "dreyeck/codex/contact-db/contact-db-codex-next-prompt.md"
     "dreyeck/codex/contact-db/contact-db-codex-next-shop3-plan.sexp"))
   (:supporting-artifacts
    ("tests/refactor-hyperdoc-first-dreyeck-extraction-smoke.lisp"
     "hyperdoc/evidence/refactor-hyperdoc-first-dreyeck-extraction-review.sexp"
     "hyperdoc/evidence/refactor-hyperdoc-first-dreyeck-extraction-selection.sexp"
     "hyperdoc/evidence/refactor-hyperdoc-first-dreyeck-extraction-result.sexp"))))
 (:asdf-review
  ((:target-system :dreyeck/codex)
   (:target-system-loads :passed-before-review-artifact)
   (:selected-files-asdf-components nil)
   (:hyperdoc-asd-updates-required nil)
   (:dreyeck-asd-updates-required nil)
   (:compatibility-shell-required-p nil)
   (:why-no-compatibility-shell
    "No loader, ASDF component, HyperDoc core file, HyperBook core file, or topic registry entry uses the old hyperdoc/contact-db-codex-next-* paths. Remaining old-path mentions are historical or test absence assertions.")))
 (:evidence-artifacts-review
  ((:selection-artifact
    "hyperdoc/evidence/refactor-hyperdoc-first-dreyeck-extraction-selection.sexp"
    :records-selection t)
   (:result-artifact
    "hyperdoc/evidence/refactor-hyperdoc-first-dreyeck-extraction-result.sexp"
    :records-move-and-validation t)
   (:umbrella-plan
    "hyperdoc/refactor-hyperdoc-to-upstream-core-and-dreyeck-systems-plan.sexp"
    :first-slice-task-recorded t)))
 (:validation
  ((:git-status-before-review "")
   (:git-diff-check :passed)
   (:hyperdoc-load :passed)
   (:dreyeck/codex-load :passed)
   (:shop3-provider-boundary-tests :passed)))
 (:review-verdict :accepted)
 (:compatibility-shell-required-p nil)
 (:asdf-updates-required-p nil)
 (:stale-old-path-references nil)
 (:repairs-required nil)
 (:actions-not-performed
  ((:file-moves nil)
   (:deletions nil)
   (:second-extraction-slice nil)
   (:pi-actions nil)
   (:ssh nil)
   (:sudo nil)
   (:nixos-rebuild nil)
   (:wifi-secret-prompt nil)))
 (:next
  (:if-accepted (!select-second-low-risk-dreyeck-extraction-slice)
   :if-needs-repair (!repair-first-dreyeck-extraction-slice))))
