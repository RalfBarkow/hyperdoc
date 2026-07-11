(:refactor-hyperdoc-third-dreyeck-extraction-selection
 (:operation (!select-third-low-risk-dreyeck-extraction-slice))
 (:base-review-commit "35418853")
 (:source-plan
  "hyperdoc/refactor-hyperdoc-to-upstream-core-and-dreyeck-systems-plan.sexp")
 (:previous-slices
  ((:target-system :dreyeck/codex :status :accepted)
   (:target-system :dreyeck/dmx/sqlite :status :accepted)))
 (:selection-criteria
  ((:must-be-classified :dreyeck-owned-situated-surface)
   (:must-not-be-classified :manual-review)
   (:must-not-be-classified :necessary-local-core-delta)
   (:must-not-be-required-by (:hyperdoc :hyperbook :hyperbook/server))
   (:must-be-coherent-group t)
   (:max-files 7)
   (:prefer
    (:already-classified-downstream-plan-artifact
     :dreyeck-dmx-artifact
     :dreyeck-codex-artifact
     :hauptsache-or-kioskbeerli-topic-artifact
     :local-deployment-runbook
     :non-asdf-data-or-evidence-file))
   (:avoid
    (:lisp-source-with-unclear-callers
     :asdf-system-definition
     :package-definition
     :hyperdoc-core-server-or-view-code
     :hyperbook-core-code
     :shop3-provider-boundary-code
     :anything-requiring-compatibility-shell-unless-very-small))))
 (:candidate-groups
  ((:name :dreyeck-dmx-build-referee-learning-plan
    :files
    (("dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp"
      :kind :shop3-plan-artifact
      :classification :dreyeck-owned-situated-surface
      :classification-basis
      (:target-store dreyeck-dmx-sqlite-production-db
       :materializer "dreyeck.dmx.sqlite:materialize-durable-notes-into-production-db"
       :target-system :dreyeck/dmx/sqlite)))
    :reference-count 4
    :why-candidate
    "Single data-only SHOP3 plan artifact for materializing build-referee learning topics into the Dreyeck DMX SQLite store; not ASDF, package, HyperDoc core, HyperBook core, or provider-boundary code.")
   (:name :dreyeck-build-plan-then-perform-plan
    :files
    (("hyperdoc/add-plan-then-perform-session-state-to-dreyeck-build-plan.sexp"))
    :reference-count 7
    :why-rejected-for-this-slice
    "Downstream-owned, but has a larger reference surface and is more tightly coupled to Dreyeck build task APIs than the selected DMX materialization plan.")
   (:name :dreyeck-build-referee-route-plan
    :files
    (("hyperdoc/render-build-referee-decisions-as-routes-plan.sexp"))
    :reference-count 5
    :why-rejected-for-this-slice
    "Downstream-owned, but depends on build-referee route API and inspector/Codex surfaces; the selected DMX materialization plan is narrower.")
   (:name :dreyeck-codex-dmx-learning-inspection-plan
    :files
    (("hyperdoc/inspect-dmx-materialized-learning-topics-plan.sexp"))
    :reference-count 7
    :why-rejected-for-this-slice
    "Downstream-owned, but spans Codex, build-task, and DMX inspection surfaces with more active source references.")
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
    "Classified by the page-content-overlays bucket, but HTML page discovery and registry/config references make it a larger execution slice.")))
 (:selected-group
  (:name :dreyeck-dmx-build-referee-learning-plan
   :files
   ((:from "dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp"
     :to "dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp"
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
     "Materialize Build Referee Learning Topics is a single SHOP3 plan whose production store and materializer are Dreyeck DMX SQLite surfaces."))
   :inbound-reference-summary
   ((:commands
     ("git grep -n \"materialize-build-referee-learning-topics-plan\" || true"
      "git grep -n \"dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp\" || true"))
    (:exact-source-path-references
     ((:file "dreyeck/dmx/sqlite/durable-notes.lisp"
       :line 89
       :classification :active-dreyeck-dmx-source)
      (:file "hyperdoc/kernighan-plauger-critical-reading-style-plan.sexp"
       :line 93
       :classification :plan-cross-reference)
      (:file "hyperdoc/the-1998-ai-planning-systems-competition-fedwiki-asdf-system-plan.sexp"
       :line 52
       :classification :plan-cross-reference)
      (:file "dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp"
       :line 126
       :classification :selected-file-self-reference)))
    (:hyperdoc-core-required-by-asdf nil)
    (:hyperbook-required-by-asdf nil)
    (:hyperbook-server-required-by-asdf nil)
    (:source-reference-repair-likely-required-p t))
   :compatibility-shell-likely-required-p nil
   :asdf-update-likely-required-p nil
   :source-reference-update-likely-required-p t))
 (:rejected-groups
  ((:name :dreyeck-build-plan-then-perform-plan
    :reason :larger-reference-surface-and-build-api-coupling)
   (:name :dreyeck-build-referee-route-plan
    :reason :route-api-and-inspector-coupling)
   (:name :dreyeck-codex-dmx-learning-inspection-plan
    :reason :codex-build-dmx-cross-surface)
   (:name :dreyeck-deployment-runbook-pages
    :reason :html-page-discovery-and-registry-reference-surface)))
 (:decision :selected)
 (:validations
  ((:git-diff-check :passed)
   (:hyperdoc-load :passed)
   (:shop3-provider-boundary-tests :passed)
   (:target-dreyeck-system-load :passed)))
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
  (:if-selected (!review-third-slice-selection-before-execution)
   :if-no-safe-candidate (!manual-review-downstream-candidate-inventory))))
