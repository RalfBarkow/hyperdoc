(REFACTOR-HYPERDOC-SEVENTH-DREYECK-EXTRACTION-POST-REVIEW
 (:OPERATION (!RECORD-SEVENTH-EXTRACTION-POST-REVIEW-WITH-DEFERRED-HYPERDOC-LOAD-BOUNDARY-REPAIR)
  :BASE "2842bd22" :SELECTION
  "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp" :REVIEW
  "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-review.sexp" :RESULT
  #1="hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-result.sexp" :OLD-PATH
  "hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp" :NEW-PATH
  #2="dreyeck/build/add-build-referee-subgraph-inspector-view-plan.sexp" :TARGET-SYSTEM
  ":dreyeck/build" :EXECUTOR-ROLE :COHERENT-LIVE-LISP-IMAGE :CODEX-ROLE
  :LEGACY-COMPATIBILITY-OR-READER-DISPLAY-SURFACE :SHAPE-VERDICT :PASSED :OLD-PATH-PRESENT-P NIL
  :NEW-PATH-PRESENT-P T :OLD-PATH-LIVE-REFERENCES NIL :OLD-PATH-LIVE-REFERENCES-COUNT 0
  :NEW-PATH-REFERENCES
  ("dreyeck/build/add-build-referee-subgraph-inspector-view-plan.sexp:100:     \"dreyeck/build/add-build-referee-subgraph-inspector-view-plan.sexp\")"
   "hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:92:   \"dreyeck/build/add-build-referee-subgraph-inspector-view-plan.sexp\" :SELECTED-PERSISTENCE-OWNER"
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-result.sexp:6:  #1=\"dreyeck/build/add-build-referee-subgraph-inspector-view-plan.sexp\" :TARGET-SYSTEM"
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-result.sexp:9:  (\"dreyeck/build/add-build-referee-subgraph-inspector-view-plan.sexp\") :OLD-PATH-REFERENCES-BEFORE"
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-result.sexp:317:  (\"dreyeck/build/add-build-referee-subgraph-inspector-view-plan.sexp:100:     \\\"dreyeck/build/add-build-referee-subgraph-inspector-view-plan.sexp\\\")\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-result.sexp:318:   \"hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:92:   \\\"dreyeck/build/add-build-referee-subgraph-inspector-view-plan.sexp\\\" :SELECTED-PERSISTENCE-OWNER\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-result.sexp:319:   \"hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-review.sexp:9:  \\\"dreyeck/build/add-build-referee-subgraph-inspector-view-plan.sexp\\\" :TARGET-SYSTEM\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-result.sexp:320:   \"hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-review.sexp:44:   (:PATTERN \\\"dreyeck/build/add-build-referee-subgraph-inspector-view-plan.sexp\\\" :MATCH-COUNT 2\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-result.sexp:321:   \"hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-review.sexp:46:    (\\\"hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:92:   \\\\\\\"dreyeck/build/add-build-referee-subgraph-inspector-view-plan.sexp\\\\\\\" :SELECTED-PERSISTENCE-OWNER\\\"\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-result.sexp:322:   \"hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-review.sexp:47:     \\\"hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:9:   \\\\\\\"dreyeck/build/add-build-referee-subgraph-inspector-view-plan.sexp\\\\\\\" :CAPABILITY-OWNER\\\"))\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-result.sexp:323:   \"hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:9:   \\\"dreyeck/build/add-build-referee-subgraph-inspector-view-plan.sexp\\\" :CAPABILITY-OWNER\")"
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-result.sexp:328:  Stream: #<SB-SYS:FD-STREAM for \\\"file /Users/rgb/workspace/hyperdoc/dreyeck/build/add-build-referee-subgraph-inspector-view-plan.sexp\\\" {7017558F53}>\")"
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-review.sexp:9:  \"dreyeck/build/add-build-referee-subgraph-inspector-view-plan.sexp\" :TARGET-SYSTEM"
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-review.sexp:44:   (:PATTERN \"dreyeck/build/add-build-referee-subgraph-inspector-view-plan.sexp\" :MATCH-COUNT 2"
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-review.sexp:46:    (\"hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:92:   \\\"dreyeck/build/add-build-referee-subgraph-inspector-view-plan.sexp\\\" :SELECTED-PERSISTENCE-OWNER\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-review.sexp:47:     \"hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:9:   \\\"dreyeck/build/add-build-referee-subgraph-inspector-view-plan.sexp\\\" :CAPABILITY-OWNER\"))"
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:9:   \"dreyeck/build/add-build-referee-subgraph-inspector-view-plan.sexp\" :CAPABILITY-OWNER")
  :NEW-PATH-REFERENCE-COUNT 17 :MOVED-READ-CHECK
  (:FILE #2# :PRESENT-P T :STATUS :READABLE :HEAD :ARTIFACT) :EXECUTION-RESULT-READ-CHECK
  (:FILE #1# :PRESENT-P T :STATUS :READABLE :HEAD
   REFACTOR-HYPERDOC-SEVENTH-DREYECK-EXTRACTION-RESULT)
  :ASDF-GATES
  ((:KIND :LOAD :SYSTEM :HYPERDOC :STATUS :PASSED :DURATION-SECONDS 4)
   (:KIND :LOAD :SYSTEM :DREYECK/BUILD :STATUS :PASSED :DURATION-SECONDS 0)
   (:KIND :LOAD :SYSTEM :DREYECK/DMX/SQLITE :STATUS :PASSED :DURATION-SECONDS 0)
   (:KIND :TEST :SYSTEM :HYPERDOC/SHOP3-PROVIDER-BOUNDARY/TESTS :STATUS :PASSED :DURATION-SECONDS
    19)
   (:KIND :TEST :SYSTEM :DREYECK/BUILD/TESTS :STATUS :PASSED :DURATION-SECONDS 106)
   (:KIND :TEST :SYSTEM :DREYECK/DMX/SQLITE/TESTS :STATUS :PASSED :DURATION-SECONDS 221))
  :FAILED-ASDF-GATES NIL :GLOBAL-HYPERDOC-LOAD-BOUNDARY (:STATUS :NOT-DEFERRED)
  :POST-REVIEW-VERDICT :ACCEPTED :SEVENTH-EXTRACTION-ACCEPTED
  (:ACCEPTED :ACCEPTED-WITH-DEFERRED-GLOBAL-HYPERDOC-LOAD-BOUNDARY-REPAIR) :NEXT
  (!ASSIMILATE-SEVENTH-EXTRACTION-INTO-REUSABLE-HTN)))
