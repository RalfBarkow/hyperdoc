(REFACTOR-HYPERDOC-SEVENTH-DREYECK-EXTRACTION-REVIEW
 (:OPERATION (!REVIEW-SEVENTH-SLICE-SELECTION-BEFORE-EXECUTION) :BASE "80bb18e2" :SELECTION
  #1="hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp"
  :ARCHITECTURE-DECISION
  "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp"
  :OWNER-REDECISION
  "hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp"
  :CANDIDATE "hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp" :TARGET
  "dreyeck/build/add-build-referee-subgraph-inspector-view-plan.sexp" :TARGET-SYSTEM
  ":dreyeck/build" :EXECUTOR-ROLE :COHERENT-LIVE-LISP-IMAGE :CODEX-ROLE
  :LEGACY-COMPATIBILITY-OR-READER-DISPLAY-SURFACE :SELECTION-READ-CHECK
  (:FILE #1# :PRESENT-P T :STATUS :READABLE :HEAD
   REFACTOR-HYPERDOC-SEVENTH-DREYECK-EXTRACTION-SELECTION)
  :CONTEXT-READ-CHECKS
  ((:FILE "hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp" :PRESENT-P T :STATUS
    :TEXT-FALLBACK :CONDITION-TYPE SB-INT:SIMPLE-READER-PACKAGE-ERROR :MESSAGE
    "Package DREYECK/BUILD does not exist.

  Stream: #<SB-SYS:FD-STREAM for \"file /Users/rgb/workspace/hyperdoc/hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\" {7026990E63}>")
   (:FILE "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp"
    :PRESENT-P T :STATUS :READABLE :HEAD REFACTOR-HYPERDOC-SEVENTH-DREYECK-EXTRACTION-SELECTION)
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
  :REVIEW-SIGNALS
  ((:PATTERN "selected-plan-artifact-target" :MATCH-COUNT 0 :SAMPLE NIL)
   (:PATTERN "coherent-live-lisp-image" :MATCH-COUNT 3 :SAMPLE
    ("hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:88:   (:PATTERN \"coherent-live-lisp-image\" :MATCH-COUNT 0 :SAMPLE NIL))"
     "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:81:   (:PATTERN \"coherent-live-lisp-image\" :MATCH-COUNT 1 :SAMPLE"
     "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:82:    (\"hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:88:   (:PATTERN \\\"coherent-live-lisp-image\\\" :MATCH-COUNT 0 :SAMPLE NIL))\")))"))
   (:PATTERN "legacy-compatibility-or-reader-display-surface" :MATCH-COUNT 0 :SAMPLE NIL)
   (:PATTERN "dreyeck/build/add-build-referee-subgraph-inspector-view-plan.sexp" :MATCH-COUNT 2
    :SAMPLE
    ("hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:92:   \"dreyeck/build/add-build-referee-subgraph-inspector-view-plan.sexp\" :SELECTED-PERSISTENCE-OWNER"
     "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:9:   \"dreyeck/build/add-build-referee-subgraph-inspector-view-plan.sexp\" :CAPABILITY-OWNER"))
   (:PATTERN "hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp" :MATCH-COUNT 69 :SAMPLE
    ("hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:100:     \"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\")"
     "hyperdoc/evidence/refactor-hyperdoc-fifth-dreyeck-extraction-selection.sexp:33:    ((\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\"))"
     "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:4:  ((:FILE \"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\" :PRESENT-P T :STATUS"
     "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:8:  Stream: #<SB-SYS:FD-STREAM for \\\"file /Users/rgb/workspace/hyperdoc/hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\\\" {7020298E63}>\")"
     "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:52:     \"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:94:   (\\\"dreyeck/codex:codex-dmx-build-referee-subgraph\\\"))\"))"
     "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:57:     \"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:3: (:title \\\"Add Build Referee Subgraph Inspector View\\\")\""
     "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:58:     \"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:18:   ((tab-title \\\"Build Referee Subgraph\\\")\""
     "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:59:     \"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:97:    :title \\\"Build Referee Subgraph\\\"))\")))"))
   (:PATTERN "Build Referee Subgraph" :MATCH-COUNT 46 :SAMPLE
    ("dreyeck-explorer/codex.lisp:1020:      (views:html-view :title \"Build Referee Subgraph\" :priority 1"
     "dreyeck-explorer/codex.lisp:1028:                              (:h1 \"Build Referee Subgraph\")"
     "dreyeck/codex/tests/smoke.lisp:162:              \"Explorer load must install the Build Referee Subgraph view\")"
     "hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:3: (:title \"Add Build Referee Subgraph Inspector View\")"
     "hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:18:   ((tab-title \"Build Referee Subgraph\")"
     "hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:97:    :title \"Build Referee Subgraph\"))"
     "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:53:   (:PATTERN \"Build Referee Subgraph\" :MATCH-COUNT 6 :SAMPLE"
     "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:54:    (\"dreyeck-explorer/codex.lisp:1020:      (views:html-view :title \\\"Build Referee Subgraph\\\" :priority 1\"")))
  :OLD-PATH-REFERENCES-AT-REVIEW
  (#2="hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:100:     \"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\")"
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
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:8:  (:OLD-PATH \"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\" :NEW-PATH"
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:15:  ((:FILE \"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\" :PRESENT-P T :STATUS"
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:19:  Stream: #<SB-SYS:FD-STREAM for \\\"file /Users/rgb/workspace/hyperdoc/hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\\\" {7024B38E63}>\")"
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:37:    (\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:100:     \\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\\\")\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:38:     \"hyperdoc/evidence/refactor-hyperdoc-fifth-dreyeck-extraction-selection.sexp:33:    ((\\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\\\"))\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:39:     \"hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:4:  ((:FILE \\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\\\" :PRESENT-P T :STATUS\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:40:     \"hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:8:  Stream: #<SB-SYS:FD-STREAM for \\\\\\\"file /Users/rgb/workspace/hyperdoc/hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\\\\\\\" {7020298E63}>\\\")\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:41:     \"hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:52:     \\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:94:   (\\\\\\\"dreyeck/codex:codex-dmx-build-referee-subgraph\\\\\\\"))\\\"))\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:42:     \"hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:57:     \\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:3: (:title \\\\\\\"Add Build Referee Subgraph Inspector View\\\\\\\")\\\"\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:43:     \"hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:58:     \\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:18:   ((tab-title \\\\\\\"Build Referee Subgraph\\\\\\\")\\\"\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:44:     \"hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:59:     \\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:97:    :title \\\\\\\"Build Referee Subgraph\\\\\\\"))\\\")))\"))"
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:53:     \"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:94:   (\\\"dreyeck/codex:codex-dmx-build-referee-subgraph\\\"))\"))"
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:58:     \"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:3: (:title \\\"Add Build Referee Subgraph Inspector View\\\")\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:59:     \"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:18:   ((tab-title \\\"Build Referee Subgraph\\\")\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:60:     \"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:97:    :title \\\"Build Referee Subgraph\\\"))\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:84:  (\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:100:     \\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\\\")\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:85:   \"hyperdoc/evidence/refactor-hyperdoc-fifth-dreyeck-extraction-selection.sexp:33:    ((\\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\\\"))\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:86:   \"hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:4:  ((:FILE \\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\\\" :PRESENT-P T :STATUS\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:87:   \"hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:8:  Stream: #<SB-SYS:FD-STREAM for \\\\\\\"file /Users/rgb/workspace/hyperdoc/hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\\\\\\\" {7020298E63}>\\\")\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:88:   \"hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:52:     \\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:94:   (\\\\\\\"dreyeck/codex:codex-dmx-build-referee-subgraph\\\\\\\"))\\\"))\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:89:   \"hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:57:     \\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:3: (:title \\\\\\\"Add Build Referee Subgraph Inspector View\\\\\\\")\\\"\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:90:   \"hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:58:     \\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:18:   ((tab-title \\\\\\\"Build Referee Subgraph\\\\\\\")\\\"\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:91:   \"hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:59:     \\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:97:    :title \\\\\\\"Build Referee Subgraph\\\\\\\"))\\\")))\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:92:   \"hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:5:  #1=\\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\\\" :CANDIDATE-READ-POLICY\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:93:   \"hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:7:  ((:FILE \\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\\\" :PRESENT-P T :STATUS\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:94:   \"hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:11:  Stream: #<SB-SYS:FD-STREAM for \\\\\\\"file /Users/rgb/workspace/hyperdoc/hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\\\\\\\" {70222C0E63}>\\\")\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:95:   \"hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:26:    (\\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:100:     \\\\\\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\\\\\\\")\\\"\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:96:   \"hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:27:     \\\"hyperdoc/evidence/refactor-hyperdoc-fifth-dreyeck-extraction-selection.sexp:33:    ((\\\\\\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\\\\\\\"))\\\"\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:97:   \"hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:28:     \\\"hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:4:  ((:FILE \\\\\\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\\\\\\\" :PRESENT-P T :STATUS\\\"\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:98:   \"hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:29:     \\\"hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:8:  Stream: #<SB-SYS:FD-STREAM for \\\\\\\\\\\\\\\"file /Users/rgb/workspace/hyperdoc/hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\\\\\\\\\\\\\\\" {7020298E63}>\\\\\\\")\\\"\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:99:   \"hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:30:     \\\"hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:52:     \\\\\\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:94:   (\\\\\\\\\\\\\\\"dreyeck/codex:codex-dmx-build-referee-subgraph\\\\\\\\\\\\\\\"))\\\\\\\"))\\\"\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:100:   \"hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:31:     \\\"hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:57:     \\\\\\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:3: (:title \\\\\\\\\\\\\\\"Add Build Referee Subgraph Inspector View\\\\\\\\\\\\\\\")\\\\\\\"\\\"\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:101:   \"hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:32:     \\\"hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:58:     \\\\\\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:18:   ((tab-title \\\\\\\\\\\\\\\"Build Referee Subgraph\\\\\\\\\\\\\\\")\\\\\\\"\\\"\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:102:   \"hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:33:     \\\"hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:59:     \\\\\\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:97:    :title \\\\\\\\\\\\\\\"Build Referee Subgraph\\\\\\\\\\\\\\\"))\\\\\\\")))\\\"))\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:103:   \"hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:42:     \\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:94:   (\\\\\\\"dreyeck/codex:codex-dmx-build-referee-subgraph\\\\\\\"))\\\"))\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:104:   \"hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:47:     \\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:3: (:title \\\\\\\"Add Build Referee Subgraph Inspector View\\\\\\\")\\\"\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:105:   \"hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:48:     \\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:18:   ((tab-title \\\\\\\"Build Referee Subgraph\\\\\\\")\\\"\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:106:   \"hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp:49:     \\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:97:    :title \\\\\\\"Build Referee Subgraph\\\\\\\"))\\\"\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:107:   \"hyperdoc/evidence/refactor-hyperdoc-sixth-dreyeck-extraction-selection.sexp:37:    ((\\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\\\"))\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:108:   \"hyperdoc/evidence/refactor-hyperdoc-upstream-core-dreyeck-extraction-result.sexp:54:   ((\\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\\\"\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:109:   \"hyperdoc/evidence/refactor-hyperdoc-upstream-core-dreyeck-extraction-result.sexp:59:     (\\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\\\"))\""
   "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp:110:   \"hyperdoc/evidence/refactor-hyperdoc-upstream-core-dreyeck-extraction-result.sexp:85:   (\\\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\\\")))\")"
   "hyperdoc/evidence/refactor-hyperdoc-sixth-dreyeck-extraction-selection.sexp:37:    ((\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\"))"
   "hyperdoc/evidence/refactor-hyperdoc-upstream-core-dreyeck-extraction-result.sexp:54:   ((\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\""
   "hyperdoc/evidence/refactor-hyperdoc-upstream-core-dreyeck-extraction-result.sexp:59:     (\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\"))"
   "hyperdoc/evidence/refactor-hyperdoc-upstream-core-dreyeck-extraction-result.sexp:85:   (\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\")))")
  :OLD-PATH-LIVE-REFERENCES-AT-REVIEW (#2#) :OLD-PATH-POLICY
  (:BEFORE-EXECUTION-OLD-PATH-MAY-EXIST T :AFTER-EXECUTION-LIVE-OLD-PATH-REFERENCES-MUST-BE-NIL T
   :HISTORICAL-OLD-PATH-REFERENCES-IN-EVIDENCE-ALLOWED T)
  :CANDIDATE-READ-POLICY (:TEXT-FALLBACK-OK-WHEN-DREYECK/BUILD-PACKAGE-IS-ABSENT) :REVIEW-VERDICT
  :ACCEPTED :SEVENTH-EXTRACTION-EXECUTED NIL :NEXT
  (!EXECUTE-SEVENTH-LOW-RISK-DREYECK-EXTRACTION-SLICE)))
