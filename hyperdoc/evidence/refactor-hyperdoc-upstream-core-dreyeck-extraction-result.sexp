(:hyperdoc-upstream-core-dreyeck-extraction-result
 (:base-start "a05ef1c5")
 (:checkpoint-before-result "c1a54ed4")
 (:final-head :commit-containing-this-result)
 (:worktree-clean-at-result-write-p t)
 (:completed-slices
  ((:slice :fourth
    :target-system :dreyeck/build
    :moved-file
    ("hyperdoc/add-plan-then-perform-session-state-to-dreyeck-build-plan.sexp"
     "dreyeck/build/add-plan-then-perform-session-state-to-dreyeck-build-plan.sexp")
    :selection "a9a3f7c1"
    :review "4d199239"
    :execution "965822bd"
    :post-review "7bd1c15a"
    :assimilation "32b875f1"
    :status :accepted)
   (:slice :fifth
    :target-system :dreyeck/build
    :moved-file
    ("hyperdoc/render-build-referee-decisions-as-routes-plan.sexp"
     "dreyeck/build/render-build-referee-decisions-as-routes-plan.sexp")
    :selection "cb858849"
    :review "c87debef"
    :execution "98550d52"
    :post-review "2bcbd513"
    :assimilation "2f14d9ec"
    :status :accepted)
   (:slice :sixth
    :target-system :dreyeck/codex
    :moved-file
    ("hyperdoc/inspect-dmx-materialized-learning-topics-plan.sexp"
     "dreyeck/codex/inspect-dmx-materialized-learning-topics-plan.sexp")
    :selection "491ac513"
    :review "8750d551"
    :execution "5e4896bc"
    :post-review "40ec30c1"
    :assimilation "c1a54ed4"
    :status :accepted)))
 (:live-old-path-references
  ((:path "hyperdoc/add-plan-then-perform-session-state-to-dreyeck-build-plan.sexp"
    :non-evidence-matches nil)
   (:path "hyperdoc/render-build-referee-decisions-as-routes-plan.sexp"
    :non-evidence-matches nil)
   (:path "hyperdoc/inspect-dmx-materialized-learning-topics-plan.sexp"
    :non-evidence-matches nil)))
 (:hyperdoc-core-scope-reviewed t)
 (:dreyeck-owned-artifacts-moved-or-classified
  (:moved-this-run
   ("dreyeck/build/add-plan-then-perform-session-state-to-dreyeck-build-plan.sexp"
    "dreyeck/build/render-build-referee-decisions-as-routes-plan.sexp"
    "dreyeck/codex/inspect-dmx-materialized-learning-topics-plan.sexp")
   :remaining-classified-candidates
   (("hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp"
     :classification :dreyeck-owned-situated-surface
     :target-system-decision-required
     (:candidates (:dreyeck-explorer :dreyeck/codex :explicit-asdf-subsystem))
     :live-reference-surface
     ("hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp"))
    (:deployment-runbook-pages
     :classification :dreyeck-owned-situated-surface
     :likely-target-system :dreyeck/server-or-release-runbook
     :status :defer-to-dedicated-page-discovery-slice))))
 (:reusable-htn-updated t)
 (:dreyeck-target-systems-touched
  (:dreyeck/build :dreyeck/codex :dreyeck/dmx/sqlite))
 (:validations-passed
  (:git-diff-check
   :hyperdoc-load
   :dreyeck/codex-load
   :dreyeck/build-load
   :dreyeck/dmx/sqlite-load
   :hyperdoc/shop3-provider-boundary/tests
   :dreyeck/codex/tests
   :dreyeck/build/tests
   :dreyeck/dmx/sqlite/tests
   :pre-commit-load-gate))
 (:remaining-hyperdoc-local-deltas
  (:manual-review-required
   ("hyperdoc/codex-compat.lisp"
    "hyperdoc/codex-examples-compat.lisp"
    "hyperdoc/dmx-*.lisp and dmx-*.scxml surfaces"
    "HyperDoc/FedWiki page overlays and deployment HTML pages"))
  (:already-classified-next-low-risk-candidates
   ("hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp")))
 (:remaining-manual-review-candidates
  (:reason
   "The remaining obvious Dreyeck-owned artifacts include Codex/DMX/explorer and deployment-page surfaces whose target directory conventions or page-discovery behavior should be selected before movement.")
  (:next-safe-slice (!decide-build-referee-subgraph-owner-before-seventh-slice)))
 (:actions-not-performed
  ((:bulk-migration t)
   (:deletions t)
   (:pi-actions t)
   (:ssh t)
   (:sudo t)
   (:nixos-rebuild t)
   (:wifi-secret-prompt t)))
 (:next (!decide-build-referee-subgraph-owner-before-seventh-slice)))
