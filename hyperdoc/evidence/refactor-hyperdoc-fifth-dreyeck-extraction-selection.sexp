(:refactor-hyperdoc-fifth-dreyeck-extraction-selection
 (:operation (!select-fifth-low-risk-dreyeck-extraction-slice))
 (:base "32b875f1")
 (:precondition
  (:fourth-extraction-post-review :accepted)
  (:fourth-assimilation "hyperdoc/evidence/refactor-hyperdoc-fourth-extraction-htn-assimilation.sexp")
  (:reusable-task-library "hyperdoc/refactor-hyperdoc-reusable-extraction-htn.sexp"))
 (:required-reusable-task-location
  (:task !locate-reusable-htn-tasks-before-specialization)
  (:status :performed)
  (:reused-method reusable-refactoring-slice-cycle))
 (:candidate-groups
  ((:name :dreyeck-build-referee-route-plan
    :files
    (("hyperdoc/render-build-referee-decisions-as-routes-plan.sexp"
      :kind :shop3-plan-artifact
      :classification :dreyeck-owned-situated-surface
      :classification-basis
      (:target-system :dreyeck/build
       :target-apis
       ("dreyeck/build:build-session-next-action-route"
        "dreyeck/codex:codex-build-referee-route"))))
    :exact-source-path-reference-count 5
    :why-candidate
    "Single data-only SHOP3 plan artifact whose authoritative referee and route API live in Dreyeck build; not ASDF, package, HyperDoc core, HyperBook core, or provider-boundary code.")
   (:name :dreyeck-codex-dmx-learning-inspection-plan
    :files
    (("hyperdoc/inspect-dmx-materialized-learning-topics-plan.sexp"))
    :why-rejected-for-this-slice
    "Downstream-owned, but it spans Codex, build-task, and DMX inspection surfaces with a larger active source-reference surface.")
   (:name :dreyeck-codex-build-referee-subgraph-view-plan
    :files
    (("hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp"))
    :why-rejected-for-this-slice
    "Very small, but its target directory convention for Codex explorer plan artifacts should be selected deliberately after the build-owned route plan is moved.")))
 (:selected-group
  (:name :dreyeck-build-referee-route-plan
   :files
   ((:from "hyperdoc/render-build-referee-decisions-as-routes-plan.sexp"
     :to "dreyeck/build/render-build-referee-decisions-as-routes-plan.sexp"
     :kind :shop3-plan-artifact
     :classification :dreyeck-owned-situated-surface))
   :current-owner :hyperdoc
   :target-owner :dreyeck/build
   :target-system :dreyeck/build
   :target-directory "dreyeck/build/"
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
     "The route plan renders Dreyeck build referee decisions and names the build-owned route API as the authoritative decision surface."))
   :inbound-reference-summary
   ((:commands
     ("git grep -n \"hyperdoc/render-build-referee-decisions-as-routes-plan.sexp\" -- ':!hyperdoc/evidence/*' || true"
      "git grep -n \"render-build-referee-decisions-as-routes-plan\" || true"
      "git grep -n \"dreyeck/build/render-build-referee-decisions-as-routes-plan.sexp\" || true"))
    (:exact-source-path-references
     ((:file "dreyeck/dmx/sqlite/durable-notes.lisp"
       :line 83
       :classification :active-dreyeck-dmx-source)
      (:file "dreyeck/dmx/sqlite/durable-notes.lisp"
       :line 148
       :classification :active-dreyeck-dmx-source)
      (:file "dreyeck/dmx/sqlite/durable-notes.lisp"
       :line 155
       :classification :active-dreyeck-dmx-source)
      (:file "dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp"
       :line 37
       :classification :active-dreyeck-dmx-plan)
      (:file "hyperdoc/render-build-referee-decisions-as-routes-plan.sexp"
       :line 113
       :classification :selected-file-self-reference)))
    (:hyperdoc-core-required-by-asdf nil)
    (:hyperbook-required-by-asdf nil)
    (:hyperbook-server-required-by-asdf nil)
    (:source-reference-repair-likely-required-p t))
   :compatibility-shell-likely-required-p nil
   :asdf-update-likely-required-p nil
   :source-reference-update-likely-required-p t))
 (:decision :selected)
 (:validations
  ((:git-diff-check :passed)
   (:selection-artifact-read :passed)
   (:hyperdoc-load :passed)
   (:target-dreyeck-system-load :passed)
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
  (:if-selected (!review-fifth-slice-selection-before-execution)
   :if-no-safe-candidate (!manual-review-downstream-candidate-inventory))))
