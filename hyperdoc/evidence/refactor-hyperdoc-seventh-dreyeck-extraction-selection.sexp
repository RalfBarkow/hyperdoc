(REFACTOR-HYPERDOC-SEVENTH-DREYECK-EXTRACTION-SELECTION
 (:OPERATION (!SELECT-SEVENTH-LOW-RISK-DREYECK-EXTRACTION-SLICE) :BASE "e7d6ac3f"
  :ARCHITECTURE-DECISION
  "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp"
  :OWNER-REDECISION
  "hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp"
  :SELECTED-SLICE
  (:OLD-PATH "hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp" :NEW-PATH
   "dreyeck/build/add-build-referee-subgraph-inspector-view-plan.sexp" :CAPABILITY-OWNER
   ":dreyeck/build" :TARGET-SYSTEM ":dreyeck/build" :EXECUTOR-ROLE :COHERENT-LIVE-LISP-IMAGE
   :CODEX-ROLE :LEGACY-COMPATIBILITY-OR-READER-DISPLAY-SURFACE :SLICE-KIND
   :SINGLE-PLAN-ARTIFACT-MOVE :BULK-MIGRATION-P NIL :NEW-ASDF-SUBSYSTEM-NEEDED-P NIL)
  :CANDIDATE-READ-POLICY (:TEXT-FALLBACK-OK-WHEN-DREYECK/BUILD-PACKAGE-IS-ABSENT)
  :CONTEXT-READ-CHECKS
  ((:FILE "hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp" :PRESENT-P T :STATUS
    :TEXT-FALLBACK :CONDITION-TYPE SB-INT:SIMPLE-READER-PACKAGE-ERROR :MESSAGE
    "Package DREYECK/BUILD does not exist.

  Stream: #<SB-SYS:FD-STREAM for \"file /Users/rgb/workspace/hyperdoc/hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\" {7024B38E63}>")
   (:FILE "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp"
    :PRESENT-P T :STATUS :READABLE :HEAD
    REFACTOR-HYPERDOC-LIVE-LISP-EXECUTOR-ARCHITECTURE-DECISION)
   (:FILE
    "hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp"
    :PRESENT-P T :STATUS :READABLE :HEAD
    REFACTOR-HYPERDOC-SEVENTH-BUILD-REFEREE-SUBGRAPH-OWNER-REDECISION)
   (:FILE "dreyeck/build/tasks.lisp" :PRESENT-P T :STATUS :READABLE :HEAD IN-PACKAGE)
   (:FILE "dreyeck/codex.lisp" :PRESENT-P T :STATUS :READABLE :HEAD IN-PACKAGE)
   (:FILE "dreyeck-explorer/codex.lisp" :PRESENT-P T :STATUS :READABLE :HEAD EVAL-WHEN)
   (:FILE "dreyeck/dmx/sqlite/durable-notes.lisp" :PRESENT-P T :STATUS :READABLE :HEAD IN-PACKAGE)
   (:FILE "hyperdoc/refactor-hyperdoc-reusable-extraction-htn.sexp" :PRESENT-P T :STATUS :READABLE
    :HEAD :ARTIFACT)
   (:FILE "hyperdoc/evidence/refactor-hyperdoc-upstream-core-dreyeck-extraction-result.sexp"
    :PRESENT-P T :STATUS :READABLE :HEAD :HYPERDOC-UPSTREAM-CORE-DREYECK-EXTRACTION-RESULT))
  :CANDIDATE-SIGNALS
  ((:PATTERN "add-build-referee-subgraph-inspector-view-plan" :MATCH-COUNT 29 :SAMPLE
    ("hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:100:     \"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\")"
     "hyperdoc/evidence/refactor-hyperdoc-fifth-dreyeck-extraction-selection.sexp:33:    ((\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\"))"
     "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:4:  ((:FILE \"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\" :PRESENT-P T :STATUS"
     "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:8:  Stream: #<SB-SYS:FD-STREAM for \\\"file /Users/rgb/workspace/hyperdoc/hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\\\" {7020298E63}>\")"
     "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:52:     \"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:94:   (\\\"dreyeck/codex:codex-dmx-build-referee-subgraph\\\"))\"))"
     "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:57:     \"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:3: (:title \\\"Add Build Referee Subgraph Inspector View\\\")\""
     "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:58:     \"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:18:   ((tab-title \\\"Build Referee Subgraph\\\")\""
     "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:59:     \"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:97:    :title \\\"Build Referee Subgraph\\\"))\")))"))
   (:PATTERN "codex-dmx-build-referee-subgraph" :MATCH-COUNT 27 :SAMPLE
    ("dreyeck-explorer/codex.lisp:1019:    (let ((subgraph (codex-dmx-build-referee-subgraph surface)))"
     "dreyeck/codex.lisp:465:(defun codex-dmx-build-referee-subgraph (surface)"
     "dreyeck/codex/tests/package.lisp:6:                #:codex-dmx-build-referee-subgraph"
     "dreyeck/codex/tests/smoke.lisp:98:                    (codex-dmx-build-referee-subgraph surface))"
     "dreyeck/package.lisp:29:           #:codex-dmx-build-referee-subgraph"
     "dreyeck/package.lisp:63:                #:codex-dmx-build-referee-subgraph"
     "dreyeck/package.lisp:76:           #:codex-dmx-build-referee-subgraph"
     "hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:94:   (\"dreyeck/codex:codex-dmx-build-referee-subgraph\"))"))
   (:PATTERN "Build Referee Subgraph" :MATCH-COUNT 25 :SAMPLE
    ("dreyeck-explorer/codex.lisp:1020:      (views:html-view :title \"Build Referee Subgraph\" :priority 1"
     "dreyeck-explorer/codex.lisp:1028:                              (:h1 \"Build Referee Subgraph\")"
     "dreyeck/codex/tests/smoke.lisp:162:              \"Explorer load must install the Build Referee Subgraph view\")"
     "hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:3: (:title \"Add Build Referee Subgraph Inspector View\")"
     "hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:18:   ((tab-title \"Build Referee Subgraph\")"
     "hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:97:    :title \"Build Referee Subgraph\"))"
     "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:53:   (:PATTERN \"Build Referee Subgraph\" :MATCH-COUNT 6 :SAMPLE"
     "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:54:    (\"dreyeck-explorer/codex.lisp:1020:      (views:html-view :title \\\"Build Referee Subgraph\\\" :priority 1\""))
   (:PATTERN "dreyeck/build" :MATCH-COUNT 200 :SAMPLE
    ("dreyeck-explorer/codex.lisp:459:    (route dreyeck/build:build-referee-decision-route)"
     "dreyeck-explorer/codex.lisp:534:                              (dreyeck/build:build-referee-decision-route-title-of"
     "dreyeck-explorer/codex.lisp:538:                              (dreyeck/build:build-referee-decision-route-summary-of"
     "dreyeck-explorer/codex.lisp:542:                             (dreyeck/build:build-referee-decision-route-requested-goal-of"
     "dreyeck-explorer/codex.lisp:546:                             (dreyeck/build:build-referee-decision-route-selected-task-of"
     "dreyeck-explorer/codex.lisp:550:                             (dreyeck/build:build-referee-decision-route-selected-action-of"
     "dreyeck-explorer/codex.lisp:555:                              (dreyeck/build:build-referee-decision-route-decoded-operation-of"
     "dreyeck-explorer/codex.lisp:559:                             (dreyeck/build:build-referee-decision-route-reason-of"))
   (:PATTERN "dreyeck/codex" :MATCH-COUNT 276 :SAMPLE
    ("dreyeck-explorer/codex.lisp:5:   :views :html-inspector-views :dreyeck/codex))"
     "dreyeck-explorer/codex.lisp:7:(in-package :dreyeck/codex)"
     "dreyeck.asd:20:                 #:dreyeck/codex))"
     "dreyeck.asd:22:(defsystem #:dreyeck/codex"
     "dreyeck.asd:35:(defsystem #:dreyeck/codex/examples"
     "dreyeck.asd:41:    :depends-on (#:dreyeck/codex)"
     "dreyeck.asd:46:(defsystem #:dreyeck/codex/explorer"
     "dreyeck.asd:52:    :depends-on (#:dreyeck/codex"))
   (:PATTERN "coherent-live-lisp-image" :MATCH-COUNT 1 :SAMPLE
    ("hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:88:   (:PATTERN \"coherent-live-lisp-image\" :MATCH-COUNT 0 :SAMPLE NIL))")))
  :OLD-PATH-REFERENCES-AT-SELECTION
  ("hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:100:     \"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\")"
   "hyperdoc/evidence/refactor-hyperdoc-fifth-dreyeck-extraction-selection.sexp:33:    ((\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\"))"
   "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:4:  ((:FILE \"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\" :PRESENT-P T :STATUS"
   "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:8:  Stream: #<SB-SYS:FD-STREAM for \\\"file /Users/rgb/workspace/hyperdoc/hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\\\" {7020298E63}>\")"
   "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:52:     \"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:94:   (\\\"dreyeck/codex:codex-dmx-build-referee-subgraph\\\"))\"))"
   "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:57:     \"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:3: (:title \\\"Add Build Referee Subgraph Inspector View\\\")\""
   "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:58:     \"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:18:   ((tab-title \\\"Build Referee Subgraph\\\")\""
   "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:59:     \"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:97:    :title \\\"Build Referee Subgraph\\\"))\")))"
   "hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:5:  #1=\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\" :CANDIDATE-READ-POLICY"
   "hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:7:  ((:FILE \"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\" :PRESENT-P T :STATUS"
   "hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:11:  Stream: #<SB-SYS:FD-STREAM for \\\"file /Users/rgb/workspace/hyperdoc/hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\\\" {70222C0E63}>\")"
   "hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:26:    (\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:100:     \\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\\\")\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:27:     \"hyperdoc/evidence/refactor-hyperdoc-fifth-dreyeck-extraction-selection.sexp:33:    ((\\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\\\"))\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:28:     \"hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:4:  ((:FILE \\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\\\" :PRESENT-P T :STATUS\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:29:     \"hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:8:  Stream: #<SB-SYS:FD-STREAM for \\\\\\\"file /Users/rgb/workspace/hyperdoc/hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\\\\\\\" {7020298E63}>\\\")\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:30:     \"hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:52:     \\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:94:   (\\\\\\\"dreyeck/codex:codex-dmx-build-referee-subgraph\\\\\\\"))\\\"))\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:31:     \"hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:57:     \\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:3: (:title \\\\\\\"Add Build Referee Subgraph Inspector View\\\\\\\")\\\"\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:32:     \"hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:58:     \\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:18:   ((tab-title \\\\\\\"Build Referee Subgraph\\\\\\\")\\\"\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:33:     \"hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:59:     \\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:97:    :title \\\\\\\"Build Referee Subgraph\\\\\\\"))\\\")))\"))"
   "hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:42:     \"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:94:   (\\\"dreyeck/codex:codex-dmx-build-referee-subgraph\\\"))\"))"
   "hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:47:     \"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:3: (:title \\\"Add Build Referee Subgraph Inspector View\\\")\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:48:     \"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:18:   ((tab-title \\\"Build Referee Subgraph\\\")\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:49:     \"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:97:    :title \\\"Build Referee Subgraph\\\"))\""
   "hyperdoc/evidence/refactor-hyperdoc-sixth-dreyeck-extraction-selection.sexp:37:    ((\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\"))"
   "hyperdoc/evidence/refactor-hyperdoc-upstream-core-dreyeck-extraction-result.sexp:54:   ((\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\""
   "hyperdoc/evidence/refactor-hyperdoc-upstream-core-dreyeck-extraction-result.sexp:59:     (\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\"))"
   "hyperdoc/evidence/refactor-hyperdoc-upstream-core-dreyeck-extraction-result.sexp:85:   (\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\")))")
  :EXPECTED-LIVE-REFERENCE-POLICY
  (:OLD-PATH-LIVE-REFERENCES-MUST-BE-UPDATED T :HISTORICAL-OLD-PATH-REFERENCES-IN-EVIDENCE-ALLOWED
   T :CODEX-NAMES-ARE-NOT-OWNER-AUTHORITY T)
  :EXPECTED-VALIDATION
  (:GIT-DIFF-CHECK T :LISP-DATA-READ-OR-TEXT-FALLBACK T :LIVE-OLD-PATH-REFERENCE-SCAN T
   :ASDF-LOAD-SYSTEM (:HYPERDOC :DREYECK/BUILD :DREYECK/DMX/SQLITE) :ASDF-TEST-SYSTEM
   (:HYPERDOC/SHOP3-PROVIDER-BOUNDARY/TESTS :DREYECK/BUILD/TESTS :DREYECK/DMX/SQLITE/TESTS))
  :SEVENTH-EXTRACTION-EXECUTED NIL :NEXT (!REVIEW-SEVENTH-SLICE-SELECTION-BEFORE-EXECUTION)))
