(:refactor-hyperdoc-second-dreyeck-extraction-result
 (:operation (!execute-second-low-risk-dreyeck-extraction-slice))
 (:selection-commit "e2c66936")
 (:review-commit "34260a7e")
 (:moved-file
  (:from "hyperdoc/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp"
   :to "dreyeck/dmx/sqlite/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp"
   :classification :dreyeck-owned-situated-surface
   :target-system :dreyeck/dmx/sqlite))
 (:references-updated
  ("dreyeck/dmx/sqlite/durable-notes.lisp"
   "hyperdoc/the-1998-ai-planning-systems-competition-fedwiki-asdf-system-plan.sexp"
   "hyperdoc/materialize-and-verify-operation-documentation-topics-shop3-plan.sexp"
   "dreyeck/dmx/sqlite/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp"))
 (:compatibility-shells nil)
 (:asdf-updates nil)
 (:smoke
  (:second-extraction-smoke
   (:new-file-exists t)
   (:old-file-absent t)
   (:old-path-references-only-historical-or-absent :passed)
   (:untracked-binary-mirror-old-path-match
    "var/dmx-associative-mirror.sqlite")
   (:dreyeck-dmx-sqlite-loads t)
   (:hyperdoc-loads t)))
 (:invariants
  (:no-bulk-migration t)
  (:no-pi-actions t)
  (:no-ssh t)
  (:no-sudo t)
  (:no-nixos-rebuild t)
  (:no-wifi-secret-prompt t))
 (:validations
  (:git-diff-check :passed)
  (:old-path-reference-check :passed)
  (:new-path-reference-check :passed)
  (:hyperdoc-load :passed)
  (:dreyeck/dmx/sqlite-load :passed)
  (:shop3-provider-boundary-tests :passed)
  (:second-extraction-smoke :passed))
 (:next (!review-second-extraction-slice-after-execution)))
