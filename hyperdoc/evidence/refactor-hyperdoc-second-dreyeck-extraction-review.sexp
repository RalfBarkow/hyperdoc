(:refactor-hyperdoc-second-dreyeck-extraction-review
 (:operation (!review-second-slice-selection-before-execution))
 (:selection-commit "e2c66936")
 (:selected-file
  (:from "hyperdoc/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp"
   :to "dreyeck/dmx/sqlite/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp"
   :classification :dreyeck-owned-situated-surface
   :target-system :dreyeck/dmx/sqlite
   :target-directory "dreyeck/dmx/sqlite/"))
 (:review-questions
  ((:is-selected-file-dreyeck-owned-situated-surface-p t)
   (:is-target-system-dreyeck-dmx-sqlite-correct-p t)
   (:does-file-belong-to-hyperdoc-core-p nil)
   (:does-hyperdoc-core-load-require-old-path-p nil)
   (:are-there-source-references-to-old-path-p t)
   (:which-references-must-change-during-execution
    ("dreyeck/dmx/sqlite/durable-notes.lisp"
     "hyperdoc/the-1998-ai-planning-systems-competition-fedwiki-asdf-system-plan.sexp"
     "hyperdoc/materialize-and-verify-operation-documentation-topics-shop3-plan.sexp"
     "hyperdoc/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp"))
   (:is-compatibility-shell-required-p nil)
   (:is-asdf-update-required-p nil)
   (:is-the-move-still-low-risk-p t)))
 (:ownership-review
  ((:selection-artifact
    "hyperdoc/evidence/refactor-hyperdoc-second-dreyeck-extraction-selection.sexp")
   (:umbrella-plan
    "hyperdoc/refactor-hyperdoc-to-upstream-core-and-dreyeck-systems-plan.sexp"
    :bucket :durable-note-or-topic-projection
    :target ":dreyeck/dmx/sqlite")
   (:asdf-owner
    "hyperdoc/evidence/refactor-hyperdoc-asdf-ownership-inventory.sexp"
    :system :dreyeck/dmx/sqlite
    :ownership
    "Situated collaboration, DMX, build/referee, zettelkasten, and local server scaffold surfaces.")
   (:selected-artifact-kind :shop3-plan-artifact)
   (:selected-artifact-load-role :data-only)
   (:selected-artifact-asdf-component-p nil)
   (:reason
    "The plan describes durable Markdown-note projection into the Dreyeck DMX SQLite topic store and names :dreyeck/dmx/sqlite as its validation target. It is not HyperDoc rendering, HyperBook substrate, or SHOP3 provider-boundary code.")))
 (:reference-scan
  (:commands
   ("grep -R \"materialize-durable-notes-into-dreyeck-dmx-sqlite-plan\" -n . --exclude-dir=.git --exclude='repomix-output*'"
    "grep -R \"hyperdoc/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp\" -n . --exclude-dir=.git --exclude='repomix-output*'"
    "grep -R \"dreyeck/dmx/sqlite/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp\" -n . --exclude-dir=.git --exclude='repomix-output*'")
   :old-path-references
   ((:file "dreyeck/dmx/sqlite/durable-notes.lisp"
     :lines (20 65)
     :classification :source-reference-must-update)
    (:file "hyperdoc/the-1998-ai-planning-systems-competition-fedwiki-asdf-system-plan.sexp"
     :lines (51)
     :classification :source-reference-must-update)
    (:file "hyperdoc/materialize-and-verify-operation-documentation-topics-shop3-plan.sexp"
     :lines (11)
     :classification :source-reference-must-update)
    (:file "hyperdoc/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp"
     :lines (102)
     :classification :selected-file-self-reference-must-update-after-move)
    (:file "hyperdoc/evidence/refactor-hyperdoc-second-dreyeck-extraction-selection.sexp"
     :classification :historical-selection-evidence
     :must-update-during-execution nil)
    (:file "var/dmx-associative-mirror.sqlite"
     :classification :binary-mirror-match
     :tracked-source-p nil
     :must-update-during-execution nil))
   :basename-references
   ((:file "tests/refactor-hyperdoc-upstream-core-plan-smoke.lisp"
     :lines (77)
     :classification :basename-smoke-assertion
     :must-update-during-execution nil)
    (:file "hyperdoc/refactor-hyperdoc-to-upstream-core-and-dreyeck-systems-plan.sexp"
     :lines (42 85)
     :classification :umbrella-plan-basename-reference
     :must-update-during-execution :optional-if-execution-records-canonical-target)
    (:file "hyperdoc/evidence/refactor-hyperdoc-second-dreyeck-extraction-selection.sexp"
     :classification :historical-selection-evidence
     :must-update-during-execution nil))
   :new-path-references
   ((:file "hyperdoc/evidence/refactor-hyperdoc-second-dreyeck-extraction-selection.sexp"
     :line 58
     :classification :selected-target-record)
    (:file "source-tree"
     :classification :target-file-not-yet-created
     :expected-before-execution t))))
 (:execution-requirements
  (:source-reference-update-required-p t
   :references-to-update
   ((:file "dreyeck/dmx/sqlite/durable-notes.lisp"
     :lines (20 65)
     :replace "hyperdoc/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp"
     :with "dreyeck/dmx/sqlite/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp")
    (:file "hyperdoc/the-1998-ai-planning-systems-competition-fedwiki-asdf-system-plan.sexp"
     :lines (51)
     :replace "hyperdoc/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp"
     :with "dreyeck/dmx/sqlite/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp")
    (:file "hyperdoc/materialize-and-verify-operation-documentation-topics-shop3-plan.sexp"
     :lines (11)
     :replace "hyperdoc/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp"
     :with "dreyeck/dmx/sqlite/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp")
    (:file "dreyeck/dmx/sqlite/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp"
     :lines (:after-move 102)
     :replace "hyperdoc/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp"
     :with "dreyeck/dmx/sqlite/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp"))
   :references-not-required-to-update
   ((:file "tests/refactor-hyperdoc-upstream-core-plan-smoke.lisp"
     :reason "basename assertion remains valid if the basename is unchanged")
    (:file "hyperdoc/evidence/refactor-hyperdoc-second-dreyeck-extraction-selection.sexp"
     :reason "historical selection evidence records the old and target paths")
    (:file "var/dmx-associative-mirror.sqlite"
     :reason "binary mirror match is not tracked source"))
   :compatibility-shell-required-p nil
   :asdf-update-required-p nil))
 (:review-verdict :accepted)
 (:validation
  ((:git-diff-check :passed)
   (:hyperdoc-load :passed)
   (:dreyeck/dmx/sqlite-load :passed)
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
  (:if-accepted (!execute-second-low-risk-dreyeck-extraction-slice)
   :if-needs-repair (!repair-second-slice-selection-before-execution))))
