(:refactor-hyperdoc-second-dreyeck-extraction-selection
 (:operation (!select-second-low-risk-dreyeck-extraction-slice))
 (:base-review-commit "62d419b7")
 (:source-plan
  "hyperdoc/refactor-hyperdoc-to-upstream-core-and-dreyeck-systems-plan.sexp")
 (:source-inventories
  ("hyperdoc/evidence/refactor-hyperdoc-local-delta-inventory.sexp"
   "hyperdoc/evidence/refactor-hyperdoc-asdf-ownership-inventory.sexp"
   "hyperdoc/evidence/refactor-hyperdoc-first-dreyeck-extraction-review.sexp"))
 (:selection-criteria
  ((:must-be-classified :dreyeck-owned-situated-surface)
   (:must-not-be-classified :manual-review)
   (:must-not-be-classified :necessary-local-core-delta)
   (:must-not-be-required-by (:hyperdoc :hyperbook :hyperbook/server))
   (:must-be-coherent-group t)
   (:max-files 7)))
 (:candidate-groups
  ((:name :dreyeck-dmx-durable-note-plan
    :files
    (("hyperdoc/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp"
      :kind :shop3-plan-artifact
      :classification :dreyeck-owned-situated-surface
      :classification-basis
      (:umbrella-plan-reuses
       "materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp"
       :reuse-bucket :durable-note-or-topic-projection
       :target-system :dreyeck/dmx/sqlite)))
    :why-candidate
    "Single data-only SHOP3 plan artifact for durable note projection into Dreyeck DMX SQLite; not Lisp source, package, ASDF, HyperDoc core, HyperBook core, or SHOP3 provider boundary code.")
   (:name :codex-handover-source-export-pages
    :files
    (("hyperdoc/Codex Handover Prompt.html" :kind :codex-handover-page)
     ("hyperdoc/Codex handover journal.html" :kind :codex-handover-journal)
     ("hyperdoc/Codex handover journal 2026-03-18.html"
      :kind :codex-handover-journal))
    :why-rejected-for-this-slice
    "Coherent Codex-owned content, but HTML page movement would need page-discovery and title-link review before it is lower risk than a plan artifact.")
   (:name :dreyeck-deployment-runbook-pages
    :files
    (("hyperdoc/Back up dreyeck.ch before deployment.html")
     ("hyperdoc/Record dreyeck.ch generation before rebuild.html")
     ("hyperdoc/Verify HyperDoc locally before deployment.html")
     ("hyperdoc/Rehearse dreyeck.ch deployment with runner.html")
     ("hyperdoc/Deploy dreyeck.ch from the local flake.html")
     ("hyperdoc/Verify HyperDoc on dreyeck.ch.html")
     ("hyperdoc/Roll back HyperDoc on dreyeck.ch.html"))
    :why-rejected-for-this-slice
    "Already classified by the page-content-overlays bucket, but exact path references in repomix deployment config, git-relations, and docs-topic workflow make it a larger execution slice.")
   (:name :dreyeck-build-plan-artifact
    :files
    (("hyperdoc/add-plan-then-perform-session-state-to-dreyeck-build-plan.sexp"))
    :why-rejected-for-this-slice
    "Also downstream-owned, but more tightly coupled to Dreyeck build task APIs than the selected DMX durable-note plan.")))
 (:selected-group
  (:name :dreyeck-dmx-durable-note-plan
   :files
   ((:from "hyperdoc/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp"
     :to "dreyeck/dmx/sqlite/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp"
     :kind :shop3-plan-artifact
     :classification :dreyeck-owned-situated-surface))
   :current-owner :hyperdoc
   :target-owner :dreyeck/dmx/sqlite
   :target-system :dreyeck/dmx/sqlite
   :target-directory "dreyeck/dmx/sqlite/"
   :why-low-risk
   ((:file-count 1)
    (:data-only-plan-artifact t)
    (:not-manual-review t)
    (:not-necessary-local-core-delta t)
    (:not-asdf-component t)
    (:not-package-definition t)
    (:not-lisp-source-with-unclear-callers t)
    (:not-required-by (:hyperdoc :hyperbook :hyperbook/server))
    (:coherent-group
     "Durable-note materialization SHOP3 plan belongs with the existing :dreyeck/dmx/sqlite subsystem that implements durable note and topic projection."))
   :inbound-reference-summary
   ((:commands
     ("grep -R \"materialize-durable-notes-into-dreyeck-dmx-sqlite-plan\" -n . --exclude-dir=.git --exclude-dir=.cache --exclude='repomix-output*' || true"
      "grep -R \"hyperdoc/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp\" -n . --exclude-dir=.git --exclude-dir=.cache --exclude='repomix-output*' || true"
      "rg -n \"materialize-durable-notes-into-dreyeck-dmx-sqlite-plan\" hyperdoc.asd hyperbook.asd dreyeck.asd tests dreyeck hyperdoc --glob '!repomix-output*'"))
    (:exact-source-path-references
     ("dreyeck/dmx/sqlite/durable-notes.lisp"
      "hyperdoc/the-1998-ai-planning-systems-competition-fedwiki-asdf-system-plan.sexp"
      "hyperdoc/materialize-and-verify-operation-documentation-topics-shop3-plan.sexp"
      "hyperdoc/refactor-hyperdoc-to-upstream-core-and-dreyeck-systems-plan.sexp"
      "tests/refactor-hyperdoc-upstream-core-plan-smoke.lisp"
      "hyperdoc/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp"))
    (:binary-mirror-reference
     ("var/dmx-associative-mirror.sqlite" :tracked-source-p nil
      :used-for-selection nil))
    (:hyperdoc-core-required-by-asdf nil)
    (:hyperbook-required-by-asdf nil)
    (:hyperbook-server-required-by-asdf nil)
    (:source-reference-repair-likely-required-p t))
   :compatibility-shell-likely-required-p nil
   :asdf-update-likely-required-p nil
   :source-reference-update-likely-required-p t))
 (:rejected-groups
  ((:name :codex-handover-source-export-pages
    :reason :html-page-discovery-needs-review-before-execution)
   (:name :dreyeck-deployment-runbook-pages
    :reason :larger-reference-surface-than-needed-for-second-slice)
   (:name :dreyeck-build-plan-artifact
    :reason :more-api-coupled-than-selected-plan-artifact)))
 (:decision :selected)
 (:validation
  ((:git-diff-check :passed)
   (:hyperdoc-load :passed)
   (:dreyeck/codex-load :passed)
   (:shop3-provider-boundary-tests :passed)))
 (:actions-not-performed
  ((:file-moves t)
   (:deletions t)
   (:bulk-migration t)
   (:pi-actions t)
   (:ssh t)
   (:sudo t)
   (:nixos-rebuild t)
   (:wifi-secret-prompt t)))
 (:next
  (:if-selected (!review-second-slice-selection-before-execution)
   :if-no-safe-candidate (!manual-review-downstream-candidate-inventory))))
