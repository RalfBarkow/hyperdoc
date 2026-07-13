(:REFACTOR-HYPERDOC-EIGHTH-EXTRACTION-COMMIT-3-LOCALIZATION
 (:TASK
  (!LOCALIZE-EIGHTH-DREYECK-EXTRACTION-COMMIT-3
   :REPOSITORY "/Users/rgb/workspace/hyperdoc/"
   :TARGET-BRANCH "hauptsache"
   :BASIS-COMMIT "59639866a1bb4aa9f27ddc43c383bd2907d196b3"
   :WORKTREE-MODE :TEMPORARY-CLEAN-WORKTREE))

 (:CANDIDATE
  (!REMOVE-LEGACY-SHOP3-IMPLEMENTATION-COPIES
   :WITH-NEW-REFERENCE-LINT
   :DEFER-PROVIDER-BOUNDARY-MOVE T
   :DEFER-DOCUMENTATION-WORKFLOW-MOVE T
   :DEFER-PROJECTION-REPAIR T))

 (:PLAN-LOCATION-DISCIPLINE
  (:CHECK-HTN-AND-SHOP3-ARTIFACTS-FIRST T)
  (:SPECIALIZED-PLAN-FOUND NIL)
  (:SOURCE-ANCHOR-SEARCH-AFTER-PLAN-SEARCH-ALLOWED T)
  (:SEARCH-SEQUENCE
   (:HTN-AND-SHOP3-PLAN-SEARCH :COMPLETED-FIRST)
   (:SOURCE-ANCHOR-SEARCH :COMPLETED-SECOND)))

 (:AUTHORITATIVE-LOCALIZATION-EVIDENCE
  ((:REUSABLE-EXTRACTION-HTN
    "hyperdoc/refactor-hyperdoc-reusable-extraction-htn.sexp"
    :RESULT :GENERIC-CYCLE-ONLY)
   (:TASK-LOCATION-HTN
    "hyperdoc/task-location-problem-determined-htn.sexp"
    :RESULT :LOCALIZATION-REQUIRED-BEFORE-NEW-METHOD)
   (:PLAN-LOCATION-DISCIPLINE
    "hyperdoc/llm-wiki-note-8892-shop3-plan-location-discipline.sexp"
    :RESULT :SHOP3-FIRST-SOURCE-SEARCH-SECOND)
   (:TASK-LOCATION-ASSIMILATION
    "hyperdoc/llm-wiki-note-8892-task-location-htn-assimilation-result.sexp")
   (:CANONICAL-SHOP3-OPERATOR-SOURCE
    "dreyeck/shop3/hyperdoc-maintenance-domain.lisp"
    :SOURCE-ANCHOR (:LINES 23 77)
    :OPERATORS
    (!ADD-RECURSIVE-COMPONENT-COLLECTOR
     !COMMIT-STAGE
     !CREATE-ASDF-SYSTEM
     !SPLIT-TOPIC-FAMILY
     !LOAD-SYSTEM
     !RUN-SMOKE-TEST)
    :RESULT :NO-REMOVAL-PLUS-LINT-OPERATOR)
   (:LEGACY-SHOP3-OPERATOR-COPY
    "hyperdoc-shop3/hyperdoc-maintenance-domain.lisp"
    :STATUS :UNLOADED-NONCANONICAL-COPY)
   (:DEFERRED-DOCUMENTATION-PLAN
    "hyperdoc-shop3/shop3-parser-documentation-plan.sexp"
    :RESULT :NOT-A-COMMIT-3-IMPLEMENTATION-PLAN)
   (:DEFERRED-DOCUMENTATION-WORKFLOW
    "hyperdoc-shop3/shop3-parser-documentation-workflow.scxml"
    :RESULT :NOT-A-COMMIT-3-IMPLEMENTATION-WORKFLOW)))

 (:SPECIALIZED-METHOD-SEARCH
  (:EXISTING-SPECIALIZED-COMMIT-3-TASK NIL)
  (:EXISTING-REMOVAL-PLUS-LINT-OPERATOR NIL)
  (:EXISTING-REMOVAL-PLUS-LINT-PLAN NIL)
  (:EXISTING-REMOVAL-PLUS-LINT-METHOD NIL)
  (:RESULT :NO-REUSABLE-SPECIALIZED-METHOD-FOUND)
  (:NEW-METHOD-DESIGN-AUTHORIZED-FOR-PREPARATION T)
  (:IMPLEMENTATION-AUTHORIZED-NOW NIL))

 (:LEGACY-IMPLEMENTATION-COPY-SET
  (:EXPECTED-COUNT 6)
  (:ACTUAL-COUNT 6)
  (:PATHS
   ("hyperdoc-shop3/package.lisp"
    "hyperdoc-shop3/manual-topics.lisp"
    "hyperdoc-shop3/plan-objects.lisp"
    "hyperdoc-shop3/hyperdoc-maintenance-domain.lisp"
    "hyperdoc-shop3/examples.lisp"
    "hyperdoc-shop3/views.lisp"))
  (:ALL-TRACKED-AT-BASIS T)
  (:ALL-STILL-PRESENT T)
  (:LIVE-ASDF-COMPONENTS NIL)
  (:CLASSIFICATION :DEAD-SOURCE-COPY))

 (:ASDF-OWNERSHIP-ANCHORS
  ((:PATH "dreyeck.asd"
    :LINES (5 23)
    :FACTS
    (:CANONICAL-SYSTEM :DREYECK/SHOP3
     :CANONICAL-MODULE "dreyeck/shop3"
     :DIRECT-COMPONENTS 6))
   (:PATH "hyperdoc.asd"
    :LINES (271 309)
    :FACTS
    (:PROVIDER-BOUNDARY-COMPONENTS
     ("hyperdoc-shop3/provider-boundary-package.lisp"
      "hyperdoc-shop3/provider-boundary.lisp")
     :COMPATIBILITY-SYSTEM :HYPERDOC/SHOP3
     :COMPATIBILITY-DIRECT-COMPONENTS 0
     :COMPATIBILITY-DEPENDS-ON (:DREYECK/SHOP3)))
   (:PATH "dreyeck/shop3/package.lisp"
    :LINES (5 6)
    :FACTS
    (:PRIMARY-PACKAGE :DREYECK/SHOP3
     :LEGACY-PACKAGE-NICKNAME :HYPERDOC/SHOP3))))

 (:CURRENT-REFERENCE-INVENTORY
  (:SEARCH
   (:NEEDLES
    ("HYPERDOC/SHOP3" "hyperdoc/shop3" "hyperdoc-shop3/"))
   (:TRACKED-PATHS 45)
   (:ALL-PATHS-CLASSIFIED T))
  (:LIVE-COMPATIBILITY
   ("dreyeck.asd"
    "dreyeck/shop3/package.lisp"
    "hyperdoc-shop3/provider-boundary-package.lisp"
    "hyperdoc-shop3/provider-boundary.lisp"
    "hyperdoc.asd"))
  (:NEW-CODE-CONTRADICTORY NIL)
  (:DEFERRED-DOCUMENTATION
   ("hyperdoc-shop3/shop3-parser-documentation-plan.sexp"
    "hyperdoc-shop3/shop3-parser-documentation-workflow.scxml"
    "hyperdoc/Debug SHOP3 find-plans.html"
    "hyperdoc/Kioskbeerli Pi simulation.html"
    "hyperdoc/Kioskbeerli sops-nix secrets.html"
    "hyperdoc/Parsing SHOP3 Introduction into Topics.html"
    "hyperdoc/Projection Pipeline Operator Plan.html"
    "hyperdoc/SHOP3 ASDF Refactor Plan Example.html"
    "hyperdoc/SHOP3 Parser Documentation Plan and SCXML.html"
    "hyperdoc/SHOP3 Planning API Reference.html"
    "hyperdoc/SHOP3 Planning Layer for HyperDoc.html"
    "hyperdoc/Using SHOP3 Planning in HyperDoc.html"
    "hyperdoc/kernighan-plauger-critical-reading-style-plan.sexp"
    "hyperdoc/projection-pipeline-operator.lisp"))
  (:HISTORICAL-EVIDENCE
   ("hyperdoc/evidence/refactor-hyperdoc-asdf-ownership-inventory.sexp"
    "hyperdoc/evidence/refactor-hyperdoc-eighth-dreyeck-extraction-commit-2-execution.sexp"
    "hyperdoc/evidence/refactor-hyperdoc-eighth-dreyeck-extraction-commit-2-preparation.sexp"
    "hyperdoc/evidence/refactor-hyperdoc-eighth-dreyeck-extraction-commit-2-review.sexp"
    "hyperdoc/evidence/refactor-hyperdoc-eighth-extraction-commit-2-htn-assimilation.sexp"
    "hyperdoc/evidence/refactor-hyperdoc-local-delta-inventory.sexp"
    "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-post-review.sexp"
    "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp"
    "hyperdoc/evidence/refactor-hyperdoc-sixth-dreyeck-extraction-post-review.sexp"
    "hyperdoc/evidence/refactor-hyperdoc-sixth-dreyeck-extraction-result.sexp"
    "hyperdoc/evidence/refactor-hyperdoc-sixth-dreyeck-extraction-review.sexp"
    "hyperdoc/evidence/refactor-hyperdoc-sixth-dreyeck-extraction-selection.sexp"
    "hyperdoc/evidence/refactor-hyperdoc-upstream-core-dreyeck-extraction-result.sexp"
    "hyperdoc/refactor-hyperdoc-reusable-extraction-htn.sexp"
    "hyperdoc/zettel-9182-shop3-provider-boundary-repair-plan.sexp"))
  (:TEST-FIXTURE
   ("tests/executable-dita-tasks-smoke.lisp"
    "tests/projection-pipeline-dmx-annotation-smoke.lisp"
    "tests/refactor-hyperdoc-upstream-core-plan-smoke.lisp"
    "tests/runtime-coherence-smoke.lisp"
    "tests/shop3-provider-boundary-smoke.lisp"))
  (:DEAD-SOURCE-COPY
   ("hyperdoc-shop3/package.lisp"
    "hyperdoc-shop3/manual-topics.lisp"
    "hyperdoc-shop3/plan-objects.lisp"
    "hyperdoc-shop3/hyperdoc-maintenance-domain.lisp"
    "hyperdoc-shop3/examples.lisp"
    "hyperdoc-shop3/views.lisp")))

 (:REFERENCE-POLICY
  (:ALLOWED
   (:COMPATIBILITY-SYSTEM-REFERENCE
    :LEGACY-PACKAGE-NICKNAME-IN-EXISTING-CONSUMERS
    :HISTORICAL-EVIDENCE
    :DEFERRED-DOCUMENTATION))
  (:FORBIDDEN-FOR-NEW-CODE
   ((:DIRECT-DEPENDENCY-ON :HYPERDOC/SHOP3)
    (:NEW-IN-PACKAGE :HYPERDOC/SHOP3)
    (:NEW-ASDF-COMPONENT-UNDER "hyperdoc-shop3/")))
  (:DELETION-TARGET
   :ONLY-THE-SIX-UNLOADED-IMPLEMENTATION-COPIES))

 (:EXISTING-REPOSITORY-LINT-INFRASTRUCTURE
  (:IMPLEMENTATION-ADDED NIL)
  (:ANCHORS
   ((:PATH ".git/hooks/pre-commit"
     :LINES (1 4)
     :ROLE :DELEGATES-TO-REPOSITORY-PRE-COMMIT-GATE)
    (:PATH "tools/pre-commit-gate.sh"
     :LINES (46 74)
     :ROLE :PATH-CLASSIFICATION-AND-FULL-GATE-SELECTION)
    (:PATH "tools/pre-commit-gate.sh"
     :LINES (143 188)
     :ROLE :FULL-GATE-DISPATCH-TO-LISP-LOAD-GATE)
    (:PATH "tools/check-lisp-load-gate.sh"
     :LINES (1 17)
     :ROLE :AUTHORITATIVE-NIX-DEVELOP-FRESH-SBCL-LOAD-GATE)
    (:PATH "tests/shop3-provider-boundary-smoke.lisp"
     :LINES (86 130)
     :ROLE :SOURCE-FRAGMENT-AND-ASDF-DEPENDENCY-BOUNDARY-ASSERTIONS)
    (:PATH "tests/executable-dita-tasks-smoke.lisp"
     :LINES (27 91)
     :ROLE :FORBIDDEN-SYSTEM-SET-AND-DEPENDENCY-CLOSURE-ASSERTIONS)))
  (:PREPARATION-USE
   :DESIGN-A-DEDICATED-REFERENCE-BOUNDARY-CHECK-THAT-CAN-BE-CALLED-BY-THE-EXISTING-GATE)
  (:DO-NOT-IMPLEMENT-LINT T))

 (:COMMIT-3-PREPARATION-BOUNDARY
  (:DELETE-ONLY-DEAD-IMPLEMENTATION-COPIES T)
  (:DELETE-PATHS
   ("hyperdoc-shop3/package.lisp"
    "hyperdoc-shop3/manual-topics.lisp"
    "hyperdoc-shop3/plan-objects.lisp"
    "hyperdoc-shop3/hyperdoc-maintenance-domain.lisp"
    "hyperdoc-shop3/examples.lisp"
    "hyperdoc-shop3/views.lisp"))
  (:PRESERVE-PROVIDER-BOUNDARY-FILES T)
  (:PRESERVE-DOCUMENTATION-WORKFLOWS T)
  (:PRESERVE-COMPATIBILITY-ASDF-SYSTEM T)
  (:PRESERVE-LEGACY-PACKAGE-NICKNAME T)
  (:PRESERVE-HISTORICAL-EVIDENCE T)
  (:LINT-NEW-CONTRADICTORY-REFERENCES-ONLY T)
  (:DEFER-PROVIDER-BOUNDARY-MOVE T)
  (:DEFER-DOCUMENTATION-WORKFLOW-MOVE T)
  (:DEFER-PROJECTION-REPAIR T))

 (:HTN-ADVANCE
  (:FROM :CANDIDATE-PENDING-TASK-LOCALIZATION)
  (:TO :LOCALIZED-NO-SPECIALIZED-PLAN-FOUND)
  (:LOCALIZATION-SPECIALIZES
   !LOCATE-REUSABLE-HTN-TASKS-BEFORE-SPECIALIZATION)
  (:NEXT
   (!PREPARE-EIGHTH-DREYECK-EXTRACTION-COMMIT-3)))

 (:CHANGED-PATH-CONTRACT
  ("hyperdoc/refactor-hyperdoc-reusable-extraction-htn.sexp"
   "hyperdoc/evidence/refactor-hyperdoc-eighth-extraction-commit-3-localization.sexp"))

 (:VALIDATION
  ((:CHECK :LOCALIZATION-ARTIFACT-SAFE-SINGLE-FORM :STATUS :PASSED)
   (:CHECK :REUSABLE-HTN-SAFE-SINGLE-FORM :STATUS :PASSED)
   (:CHECK :ONLY-EXPECTED-PATHS-CHANGED :EXPECTED 2 :ACTUAL 2 :STATUS :PASSED)
   (:CHECK :SIX-LEGACY-COPIES-STILL-PRESENT :STATUS :PASSED)
   (:CHECK :NO-LINT-IMPLEMENTATION-ADDED :STATUS :PASSED)
   (:CHECK :NO-ASDF-DEFINITION-CHANGED :STATUS :PASSED)
   (:CHECK :NO-PROVIDER-BOUNDARY-FILE-CHANGED :STATUS :PASSED)
   (:CHECK :NO-DOCUMENTATION-WORKFLOW-CHANGED :STATUS :PASSED)
   (:CHECK :GIT-DIFF-CHECK :COMMAND "git diff --check" :STATUS :PASSED)
   (:CHECK :REPOSITORY-LOAD-GATE
    :COMMAND "tools/check-lisp-load-gate.sh :hyperbook/server"
    :ENVIRONMENT :NIX-DEVELOP
    :MARKER "LOAD_GATE_OK"
    :STATUS :PASSED)
   (:CHECK :ORIGINAL-WORKTREE-STAGED-FILES-PRESERVED
    :PATHS
    ("hyperdoc/shop3-zettel-journey-contract.lisp"
     "hyperdoc/shop3-zettel-plan-provenance-index.sexp"
     "tests/shop3-zettel-journey-smoke.lisp")
    :INDEX-BLOB-IDS
    ("fec17cb44b315313f256f5fd1e647ecee049af95"
     "13289505c477d0bf84d66ed28d97f629683de3bd"
     "c7746ca7cee24ce18a0f1d819e8ede402b602ea5")
    :STATUS :PASSED)
   (:CHECK :TEMPORARY-WORKTREE-REMOVED
    :STATUS :PERFORMED-AFTER-COMMIT-VERIFICATION)))

 (:NON-ACTIONS
  (:IMPLEMENTATION-CHANGES NIL)
  (:NO-LEGACY-COPY-DELETION T)
  (:NO-REFERENCE-LINT-IMPLEMENTATION T)
  (:NO-ASDF-DEFINITION-CHANGE T)
  (:NO-PROVIDER-BOUNDARY-MOVE T)
  (:NO-DOCUMENTATION-PLAN-OR-WORKFLOW-CHANGE T)
  (:NO-HYPERDOC-PAGE-CHANGE T)
  (:NO-LISP-TOPIC-OR-VIEW-CHANGE T)
  (:NO-FEDWIKI-CHANGE T)
  (:NO-PLAN-TREE-PROJECTION-REPAIR T)
  (:NO-PUSH T))

 (:ANSWER-RECONSTRUCTION
  (:SURFACE
   (:PROCESS-TRACE
    (:INSPECTED :HTN-AND-SHOP3-PLANS :FIRST)
    (:INSPECTED :SOURCE-ANCHORS-AND-TRACKED-REFERENCES :SECOND)
    (:INFERRED :SPECIALIZED-METHOD-GAP)
    (:DECIDED :ADVANCE-TO-PREPARATION))
   (:RESULT :EIGHTH-DREYECK-EXTRACTION-COMMIT-3-LOCALIZED))
  (:ARTIFACT
   (:HYPERDOC-PAGE-DELTA NIL)
   (:LISP-SOURCE-DELTA
    ("hyperdoc/refactor-hyperdoc-reusable-extraction-htn.sexp"))
   (:LISP-TOPIC-OR-VIEW-DEFINITIONS NIL)
   (:FEDWIKI-TWIN-DELTA NIL)
   (:DAILY-ANCHOR-DELTA NIL)
   (:EVIDENCE
    "hyperdoc/evidence/refactor-hyperdoc-eighth-extraction-commit-3-localization.sexp")
   (:REPLAY-CHECKS
    (:SAFE-SINGLE-FORM
     :EXACT-CHANGED-PATHS
     :GIT-DIFF-CHECK
     :NIX-DEVELOP-LOAD-GATE
     :ORIGINAL-INDEX-BLOB-IDENTITY))))

 (:CLASSIFICATION :EIGHTH-DREYECK-EXTRACTION-COMMIT-3-LOCALIZED)
 (:NEXT
  (!PREPARE-EIGHTH-DREYECK-EXTRACTION-COMMIT-3)))
