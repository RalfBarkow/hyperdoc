(:REFACTOR-HYPERDOC-THIRD-DREYECK-EXTRACTION-REVIEW
 (:OPERATION (!REVIEW-THIRD-SLICE-SELECTION-BEFORE-EXECUTION) :SELECTION-COMMIT "d4d839c7"
  :SELECTION-ARTIFACT
  "/Users/rgb/workspace/hyperdoc/hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-selection.sexp"
  :SELECTION
  (:REFACTOR-HYPERDOC-THIRD-DREYECK-EXTRACTION-SELECTION
   (:OPERATION (!SELECT-THIRD-LOW-RISK-DREYECK-EXTRACTION-SLICE)) (:BASE-REVIEW-COMMIT "35418853")
   (:SOURCE-PLAN "hyperdoc/refactor-hyperdoc-to-upstream-core-and-dreyeck-systems-plan.sexp")
   (:PREVIOUS-SLICES
    ((:TARGET-SYSTEM :DREYECK/CODEX :STATUS :ACCEPTED)
     (:TARGET-SYSTEM :DREYECK/DMX/SQLITE :STATUS :ACCEPTED)))
   (:SELECTION-CRITERIA
    ((:MUST-BE-CLASSIFIED :DREYECK-OWNED-SITUATED-SURFACE) (:MUST-NOT-BE-CLASSIFIED :MANUAL-REVIEW)
     (:MUST-NOT-BE-CLASSIFIED :NECESSARY-LOCAL-CORE-DELTA)
     (:MUST-NOT-BE-REQUIRED-BY (:HYPERDOC :HYPERBOOK :HYPERBOOK/SERVER))
     (:MUST-BE-COHERENT-GROUP T) (:MAX-FILES 7)
     (:PREFER
      (:ALREADY-CLASSIFIED-DOWNSTREAM-PLAN-ARTIFACT :DREYECK-DMX-ARTIFACT :DREYECK-CODEX-ARTIFACT
       :HAUPTSACHE-OR-KIOSKBEERLI-TOPIC-ARTIFACT :LOCAL-DEPLOYMENT-RUNBOOK
       :NON-ASDF-DATA-OR-EVIDENCE-FILE))
     (:AVOID
      (:LISP-SOURCE-WITH-UNCLEAR-CALLERS :ASDF-SYSTEM-DEFINITION :PACKAGE-DEFINITION
       :HYPERDOC-CORE-SERVER-OR-VIEW-CODE :HYPERBOOK-CORE-CODE :SHOP3-PROVIDER-BOUNDARY-CODE
       :ANYTHING-REQUIRING-COMPATIBILITY-SHELL-UNLESS-VERY-SMALL))))
   (:CANDIDATE-GROUPS
    ((:NAME :DREYECK-DMX-BUILD-REFEREE-LEARNING-PLAN :FILES
      (("dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp" :KIND :SHOP3-PLAN-ARTIFACT
        :CLASSIFICATION :DREYECK-OWNED-SITUATED-SURFACE :CLASSIFICATION-BASIS
        (:TARGET-STORE DREYECK-DMX-SQLITE-PRODUCTION-DB :MATERIALIZER
         "dreyeck.dmx.sqlite:materialize-durable-notes-into-production-db" :TARGET-SYSTEM
         :DREYECK/DMX/SQLITE)))
      :REFERENCE-COUNT 4 :WHY-CANDIDATE
      "Single data-only SHOP3 plan artifact for materializing build-referee learning topics into the Dreyeck DMX SQLite store; not ASDF, package, HyperDoc core, HyperBook core, or provider-boundary code.")
     (:NAME :DREYECK-BUILD-PLAN-THEN-PERFORM-PLAN :FILES
      (("hyperdoc/add-plan-then-perform-session-state-to-dreyeck-build-plan.sexp"))
      :REFERENCE-COUNT 7 :WHY-REJECTED-FOR-THIS-SLICE
      "Downstream-owned, but has a larger reference surface and is more tightly coupled to Dreyeck build task APIs than the selected DMX materialization plan.")
     (:NAME :DREYECK-BUILD-REFEREE-ROUTE-PLAN :FILES
      (("hyperdoc/render-build-referee-decisions-as-routes-plan.sexp")) :REFERENCE-COUNT 5
      :WHY-REJECTED-FOR-THIS-SLICE
      "Downstream-owned, but depends on build-referee route API and inspector/Codex surfaces; the selected DMX materialization plan is narrower.")
     (:NAME :DREYECK-CODEX-DMX-LEARNING-INSPECTION-PLAN :FILES
      (("hyperdoc/inspect-dmx-materialized-learning-topics-plan.sexp")) :REFERENCE-COUNT 7
      :WHY-REJECTED-FOR-THIS-SLICE
      "Downstream-owned, but spans Codex, build-task, and DMX inspection surfaces with more active source references.")
     (:NAME :DREYECK-DEPLOYMENT-RUNBOOK-PAGES :FILES
      (("hyperdoc/Back up dreyeck.ch before deployment.html")
       ("hyperdoc/Record dreyeck.ch generation before rebuild.html")
       ("hyperdoc/Verify HyperDoc locally before deployment.html")
       ("hyperdoc/Rehearse dreyeck.ch deployment with runner.html")
       ("hyperdoc/Deploy dreyeck.ch from the local flake.html")
       ("hyperdoc/Verify HyperDoc on dreyeck.ch.html")
       ("hyperdoc/Roll back HyperDoc on dreyeck.ch.html"))
      :WHY-REJECTED-FOR-THIS-SLICE
      "Classified by the page-content-overlays bucket, but HTML page discovery and registry/config references make it a larger execution slice.")))
   (:SELECTED-GROUP
    (:NAME :DREYECK-DMX-BUILD-REFEREE-LEARNING-PLAN :FILES
     ((:FROM "dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp" :TO
       "dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp" :KIND
       :SHOP3-PLAN-ARTIFACT :CLASSIFICATION :DREYECK-OWNED-SITUATED-SURFACE))
     :CURRENT-OWNER :HYPERDOC :TARGET-OWNER :DREYECK/DMX/SQLITE :TARGET-SYSTEM :DREYECK/DMX/SQLITE
     :TARGET-DIRECTORY "dreyeck/dmx/sqlite/" :WHY-LOW-RISK
     ((:FILE-COUNT 1) (:DATA-ONLY-PLAN-ARTIFACT T) (:NOT-MANUAL-REVIEW T)
      (:NOT-NECESSARY-LOCAL-CORE-DELTA T) (:NOT-ASDF-COMPONENT T) (:NOT-PACKAGE-DEFINITION T)
      (:NOT-LISP-SOURCE-WITH-UNCLEAR-CALLERS T)
      (:NOT-REQUIRED-BY (:HYPERDOC :HYPERBOOK :HYPERBOOK/SERVER))
      (:COHERENT-GROUP
       "Materialize Build Referee Learning Topics is a single SHOP3 plan whose production store and materializer are Dreyeck DMX SQLite surfaces."))
     :INBOUND-REFERENCE-SUMMARY
     ((:COMMANDS
       ("git grep -n \"materialize-build-referee-learning-topics-plan\" || true"
        "git grep -n \"dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp\" || true"))
      (:EXACT-SOURCE-PATH-REFERENCES
       ((:FILE "dreyeck/dmx/sqlite/durable-notes.lisp" :LINE 89 :CLASSIFICATION
         :ACTIVE-DREYECK-DMX-SOURCE)
        (:FILE "hyperdoc/kernighan-plauger-critical-reading-style-plan.sexp" :LINE 93
         :CLASSIFICATION :PLAN-CROSS-REFERENCE)
        (:FILE "hyperdoc/the-1998-ai-planning-systems-competition-fedwiki-asdf-system-plan.sexp"
         :LINE 52 :CLASSIFICATION :PLAN-CROSS-REFERENCE)
        (:FILE "dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp" :LINE 126
         :CLASSIFICATION :SELECTED-FILE-SELF-REFERENCE)))
      (:HYPERDOC-CORE-REQUIRED-BY-ASDF NIL) (:HYPERBOOK-REQUIRED-BY-ASDF NIL)
      (:HYPERBOOK-SERVER-REQUIRED-BY-ASDF NIL) (:SOURCE-REFERENCE-REPAIR-LIKELY-REQUIRED-P T))
     :COMPATIBILITY-SHELL-LIKELY-REQUIRED-P NIL :ASDF-UPDATE-LIKELY-REQUIRED-P NIL
     :SOURCE-REFERENCE-UPDATE-LIKELY-REQUIRED-P T))
   (:REJECTED-GROUPS
    ((:NAME :DREYECK-BUILD-PLAN-THEN-PERFORM-PLAN :REASON
      :LARGER-REFERENCE-SURFACE-AND-BUILD-API-COUPLING)
     (:NAME :DREYECK-BUILD-REFEREE-ROUTE-PLAN :REASON :ROUTE-API-AND-INSPECTOR-COUPLING)
     (:NAME :DREYECK-CODEX-DMX-LEARNING-INSPECTION-PLAN :REASON :CODEX-BUILD-DMX-CROSS-SURFACE)
     (:NAME :DREYECK-DEPLOYMENT-RUNBOOK-PAGES :REASON
      :HTML-PAGE-DISCOVERY-AND-REGISTRY-REFERENCE-SURFACE)))
   (:DECISION :SELECTED)
   (:VALIDATIONS
    ((:GIT-DIFF-CHECK :PASSED) (:HYPERDOC-LOAD :PASSED) (:SHOP3-PROVIDER-BOUNDARY-TESTS :PASSED)
     (:TARGET-DREYECK-SYSTEM-LOAD :PASSED)))
   (:ACTIONS-NOT-PERFORMED
    ((:FILE-MOVES T) (:DELETIONS T) (:BULK-MIGRATION T) (:PI-ACTIONS T) (:SSH T) (:SUDO T)
     (:NIXOS-REBUILD T) (:WIFI-SECRET-PROMPT T)))
   (:NEXT
    (:IF-SELECTED (!REVIEW-THIRD-SLICE-SELECTION-BEFORE-EXECUTION) :IF-NO-SAFE-CANDIDATE
     (!MANUAL-REVIEW-DOWNSTREAM-CANDIDATE-INVENTORY))))
  :SELECTED-FILE
  (:FROM "dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp" :TO
   "dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp" :CLASSIFICATION
   :DREYECK-OWNED-SITUATED-SURFACE :TARGET-SYSTEM :DREYECK/DMX/SQLITE)
  :FILE-STATE (:OLD-FILE-PRESENT-P T :TARGET-DIRECTORY-PRESENT-P T :NEW-FILE-PRESENT-P NIL)
  :REFERENCE-SCAN
  (:OLD-PATH-REFERENCES
   (#1=(:PATH #2="dreyeck/dmx/sqlite/durable-notes.lisp" :LINE 89 :TEXT
        "     :source \"dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp\"")
    (:PATH "hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-selection.sexp" :LINE 34
     :TEXT "    ((\"dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp\"")
    (:PATH "hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-selection.sexp" :LINE 76
     :TEXT "   ((:from \"dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp\"")
    (:PATH "hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-selection.sexp" :LINE 98
     :TEXT
     "      \"git grep -n \\\"dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp\\\" || true\"))")
    (:PATH "hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-selection.sexp" :LINE 109
     :TEXT "      (:file \"dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp\"")
    #3=(:PATH #4="hyperdoc/kernighan-plauger-critical-reading-style-plan.sexp" :LINE 93 :TEXT
        "     \"dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp\"")
    #5=(:PATH #6="dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp" :LINE 126 :TEXT
        "     \"dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp\")")
    #7=(:PATH #8="hyperdoc/the-1998-ai-planning-systems-competition-fedwiki-asdf-system-plan.sexp"
        :LINE 52 :TEXT "    \"dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp\"))"))
   :TRACKED-SOURCE-OLD-PATH-REFERENCES (#1# #3# #5# #7#) :BASENAME-REFERENCES
   ((:PATH "dreyeck/dmx/sqlite/durable-notes.lisp" :LINE 89 :TEXT
     "     :source \"dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp\"")
    (:PATH "hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-selection.sexp" :LINE 34
     :TEXT "    ((\"dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp\"")
    (:PATH "hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-selection.sexp" :LINE 76
     :TEXT "   ((:from \"dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp\"")
    (:PATH "hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-selection.sexp" :LINE 77
     :TEXT "     :to \"dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp\"")
    (:PATH "hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-selection.sexp" :LINE 97
     :TEXT "     (\"git grep -n \\\"materialize-build-referee-learning-topics-plan\\\" || true\"")
    (:PATH "hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-selection.sexp" :LINE 98
     :TEXT
     "      \"git grep -n \\\"dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp\\\" || true\"))")
    (:PATH "hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-selection.sexp" :LINE 109
     :TEXT "      (:file \"dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp\"")
    (:PATH "hyperdoc/kernighan-plauger-critical-reading-style-plan.sexp" :LINE 93 :TEXT
     "     \"dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp\"")
    (:PATH "dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp" :LINE 126 :TEXT
     "     \"dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp\")")
    (:PATH "hyperdoc/the-1998-ai-planning-systems-competition-fedwiki-asdf-system-plan.sexp" :LINE
     52 :TEXT "    \"dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp\"))"))
   :NEW-PATH-REFERENCES
   ((:PATH "hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-selection.sexp" :LINE 77
     :TEXT "     :to \"dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp\"")))
  :EXECUTION-REQUIREMENTS
  (:SOURCE-REFERENCE-UPDATE-REQUIRED-P T :REFERENCES-TO-UPDATE (#2# #4# #6# #8#)
   :COMPATIBILITY-SHELL-REQUIRED-P NIL :ASDF-UPDATE-REQUIRED-P NIL)
  :REVIEW-VERDICT :ACCEPTED :NEXT (!EXECUTE-THIRD-LOW-RISK-DREYECK-EXTRACTION-SLICE)))
