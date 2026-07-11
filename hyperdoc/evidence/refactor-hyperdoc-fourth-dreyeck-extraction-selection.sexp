(:refactor-hyperdoc-fourth-dreyeck-extraction-selection
 (:operation (!select-fourth-low-risk-dreyeck-extraction-slice))
 (:base "a05ef1c5")
 (:precondition
  (:third-extraction-post-review :accepted)
  (:worktree-status-before "")
  (:third-result
   "hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-result.sexp")
  (:third-review
   "hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-review.sexp")
  (:reusable-task-library
   "hyperdoc/refactor-hyperdoc-reusable-extraction-htn.sexp"))
 (:required-reusable-task-location
  (:task !locate-reusable-htn-tasks-before-specialization)
  (:status :performed)
  (:task-location-searches
   ((:pattern "!locate-reusable-htn-tasks-before-specialization" :match-count 9)
    (:pattern "!select-low-risk-downstream-extraction-slice" :match-count 5)
    (:pattern "!review-selected-extraction-slice-before-execution" :match-count 5)
    (:pattern "!execute-reviewed-extraction-slice" :match-count 5)
    (:pattern "!assimilate-refactoring-episode-into-htn" :match-count 5)
    (:pattern "DREYECK-OWNED-SITUATED-SURFACE" :match-count 4))))
 (:selection-criteria
  ((:must-be-classified :dreyeck-owned-situated-surface)
   (:must-not-be-classified :manual-review)
   (:must-not-be-classified :necessary-local-core-delta)
   (:must-not-be-required-by (:hyperdoc :hyperbook :hyperbook/server))
   (:must-be-coherent-group t)
   (:max-files 7)
   (:prefer
    (:already-classified-downstream-plan-artifact
     :dreyeck-build-artifact
     :dreyeck-dmx-artifact
     :dreyeck-codex-artifact
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
  ((:name :dreyeck-build-plan-then-perform-plan
    :files
    (("hyperdoc/add-plan-then-perform-session-state-to-dreyeck-build-plan.sexp"
      :kind :shop3-plan-artifact
      :classification :dreyeck-owned-situated-surface
      :classification-basis
      (:target-system :dreyeck/build
       :target-apis
       ("dreyeck/build:make-build-session"
        "dreyeck/build:plan-build-task"
        "dreyeck/build:check-build-task"
        "dreyeck/build:perform-build-task"
        "dreyeck/build:build-session-status"
        "dreyeck/build:build-session-next-action"
        "dreyeck/build:run-build-task"))))
    :reference-count 22
    :exact-source-path-reference-count 9
    :why-candidate
    "Single data-only SHOP3 plan artifact for Dreyeck build plan/check/perform session state; not ASDF, package, HyperDoc core, HyperBook core, or provider-boundary code.")
   (:name :dreyeck-build-referee-route-plan
    :files
    (("hyperdoc/render-build-referee-decisions-as-routes-plan.sexp"
      :kind :shop3-plan-artifact
      :classification :dreyeck-owned-situated-surface))
    :reference-count 20
    :exact-source-path-reference-count 7
    :why-rejected-for-this-slice
    "Also downstream-owned, but it depends on the plan/check/perform session model selected here and spans build, Codex, inspector, and route-display surfaces.")
   (:name :dreyeck-codex-dmx-learning-inspection-plan
    :files
    (("hyperdoc/inspect-dmx-materialized-learning-topics-plan.sexp"
      :kind :shop3-plan-artifact
      :classification :dreyeck-owned-situated-surface))
    :reference-count 16
    :exact-source-path-reference-count 9
    :why-rejected-for-this-slice
    "Downstream-owned, but it spans Codex, build-task, and DMX inspection surfaces with more active source references.")
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
  (:name :dreyeck-build-plan-then-perform-plan
   :files
   ((:from "hyperdoc/add-plan-then-perform-session-state-to-dreyeck-build-plan.sexp"
     :to "dreyeck/build/add-plan-then-perform-session-state-to-dreyeck-build-plan.sexp"
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
     "The plan introduces and documents Dreyeck build session/referee behavior and names only Dreyeck build APIs as its target implementation surface."))
   :inbound-reference-summary
   ((:commands
     ("git grep -n \"hyperdoc/add-plan-then-perform-session-state-to-dreyeck-build-plan.sexp\" || true"
      "git grep -n \"add-plan-then-perform-session-state-to-dreyeck-build\" || true"
      "git grep -n \"dreyeck/build/add-plan-then-perform-session-state-to-dreyeck-build-plan.sexp\" || true"))
    (:exact-source-path-references
     ((:file "dreyeck/build/tasks.lisp"
       :line 668
       :classification :active-dreyeck-build-source)
      (:file "dreyeck/dmx/sqlite/durable-notes.lisp"
       :line 77
       :classification :active-dreyeck-dmx-source)
      (:file "dreyeck/dmx/sqlite/durable-notes.lisp"
       :line 141
       :classification :active-dreyeck-dmx-source)
      (:file "dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp"
       :line 36
       :classification :active-dreyeck-dmx-plan)
      (:file "hyperdoc/add-plan-then-perform-session-state-to-dreyeck-build-plan.sexp"
       :line 132
       :classification :selected-file-self-reference)
      (:file "hyperdoc/kernighan-plauger-critical-reading-style-plan.sexp"
       :line 92
       :classification :plan-cross-reference))
     :historical-evidence-references
     ((:file "hyperdoc/evidence/refactor-hyperdoc-second-dreyeck-extraction-selection.sexp"
       :line 51)
      (:file "hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-review.sexp"
       :line 35)
      (:file "hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-selection.sexp"
       :line 46)))
    (:hyperdoc-core-required-by-asdf nil)
    (:hyperbook-required-by-asdf nil)
    (:hyperbook-server-required-by-asdf nil)
    (:source-reference-repair-likely-required-p t))
   :compatibility-shell-likely-required-p nil
   :asdf-update-likely-required-p nil
   :source-reference-update-likely-required-p t))
 (:rejected-groups
  ((:name :dreyeck-build-referee-route-plan
    :reason :depends-on-selected-build-session-plan-and-spans-route-display-surfaces)
   (:name :dreyeck-codex-dmx-learning-inspection-plan
    :reason :codex-build-dmx-cross-surface)
   (:name :dreyeck-deployment-runbook-pages
    :reason :html-page-discovery-and-registry-reference-surface)))
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
  (:if-selected (!review-fourth-slice-selection-before-execution)
   :if-no-safe-candidate (!manual-review-downstream-candidate-inventory))))
