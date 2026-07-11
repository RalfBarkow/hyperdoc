(REFACTOR-HYPERDOC-SEVENTH-BUILD-REFEREE-SUBGRAPH-OWNER-REDECISION
 (:OPERATION (!REDECIDE-BUILD-REFEREE-SUBGRAPH-OWNER-UNDER-LIVE-LISP-EXECUTOR-MODEL) :BASE
  "a3c99588" :ARCHITECTURE-DECISION
  "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp" :CANDIDATE
  #1="hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp" :CANDIDATE-READ-POLICY
  (:TEXT-FALLBACK-OK-WHEN-DREYECK/BUILD-PACKAGE-IS-ABSENT) :CONTEXT-READ-CHECKS
  ((:FILE "hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp" :PRESENT-P T :STATUS
    :TEXT-FALLBACK :CONDITION-TYPE SB-INT:SIMPLE-READER-PACKAGE-ERROR :MESSAGE
    "Package DREYECK/BUILD does not exist.

  Stream: #<SB-SYS:FD-STREAM for \"file /Users/rgb/workspace/hyperdoc/hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\" {70222C0E63}>")
   (:FILE "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp"
    :PRESENT-P T :STATUS :READABLE :HEAD
    REFACTOR-HYPERDOC-LIVE-LISP-EXECUTOR-ARCHITECTURE-DECISION)
   (:FILE "dreyeck.asd" :PRESENT-P T :STATUS :READABLE :HEAD DEFSYSTEM)
   (:FILE "dreyeck/build/tasks.lisp" :PRESENT-P T :STATUS :READABLE :HEAD IN-PACKAGE)
   (:FILE "dreyeck/codex.lisp" :PRESENT-P T :STATUS :READABLE :HEAD IN-PACKAGE)
   (:FILE "dreyeck-explorer/codex.lisp" :PRESENT-P T :STATUS :READABLE :HEAD EVAL-WHEN)
   (:FILE "dreyeck/dmx/sqlite/durable-notes.lisp" :PRESENT-P T :STATUS :READABLE :HEAD IN-PACKAGE)
   (:FILE "hyperdoc/refactor-hyperdoc-reusable-extraction-htn.sexp" :PRESENT-P T :STATUS :READABLE
    :HEAD :ARTIFACT)
   (:FILE "hyperdoc/evidence/refactor-hyperdoc-upstream-core-dreyeck-extraction-result.sexp"
    :PRESENT-P T :STATUS :READABLE :HEAD :HYPERDOC-UPSTREAM-CORE-DREYECK-EXTRACTION-RESULT))
  :OWNERSHIP-SIGNALS
  ((:PATTERN "add-build-referee-subgraph-inspector-view-plan" :MATCH-COUNT 12 :SAMPLE
    ("hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:100:     \"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\")"
     "hyperdoc/evidence/refactor-hyperdoc-fifth-dreyeck-extraction-selection.sexp:33:    ((\"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\"))"
     "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:4:  ((:FILE \"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\" :PRESENT-P T :STATUS"
     "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:8:  Stream: #<SB-SYS:FD-STREAM for \\\"file /Users/rgb/workspace/hyperdoc/hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\\\" {7020298E63}>\")"
     "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:52:     \"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:94:   (\\\"dreyeck/codex:codex-dmx-build-referee-subgraph\\\"))\"))"
     "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:57:     \"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:3: (:title \\\"Add Build Referee Subgraph Inspector View\\\")\""
     "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:58:     \"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:18:   ((tab-title \\\"Build Referee Subgraph\\\")\""
     "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:59:     \"hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:97:    :title \\\"Build Referee Subgraph\\\"))\")))"))
   (:PATTERN "codex-dmx-build-referee-subgraph" :MATCH-COUNT 17 :SAMPLE
    ("dreyeck-explorer/codex.lisp:1019:    (let ((subgraph (codex-dmx-build-referee-subgraph surface)))"
     "dreyeck/codex.lisp:465:(defun codex-dmx-build-referee-subgraph (surface)"
     "dreyeck/codex/tests/package.lisp:6:                #:codex-dmx-build-referee-subgraph"
     "dreyeck/codex/tests/smoke.lisp:98:                    (codex-dmx-build-referee-subgraph surface))"
     "dreyeck/package.lisp:29:           #:codex-dmx-build-referee-subgraph"
     "dreyeck/package.lisp:63:                #:codex-dmx-build-referee-subgraph"
     "dreyeck/package.lisp:76:           #:codex-dmx-build-referee-subgraph"
     "hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:94:   (\"dreyeck/codex:codex-dmx-build-referee-subgraph\"))"))
   (:PATTERN "Build Referee Subgraph" :MATCH-COUNT 13 :SAMPLE
    ("dreyeck-explorer/codex.lisp:1020:      (views:html-view :title \"Build Referee Subgraph\" :priority 1"
     "dreyeck-explorer/codex.lisp:1028:                              (:h1 \"Build Referee Subgraph\")"
     "dreyeck/codex/tests/smoke.lisp:162:              \"Explorer load must install the Build Referee Subgraph view\")"
     "hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:3: (:title \"Add Build Referee Subgraph Inspector View\")"
     "hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:18:   ((tab-title \"Build Referee Subgraph\")"
     "hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:97:    :title \"Build Referee Subgraph\"))"
     "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:53:   (:PATTERN \"Build Referee Subgraph\" :MATCH-COUNT 6 :SAMPLE"
     "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:54:    (\"dreyeck-explorer/codex.lisp:1020:      (views:html-view :title \\\"Build Referee Subgraph\\\" :priority 1\""))
   (:PATTERN "dreyeck/build" :MATCH-COUNT 186 :SAMPLE
    ("dreyeck-explorer/codex.lisp:459:    (route dreyeck/build:build-referee-decision-route)"
     "dreyeck-explorer/codex.lisp:534:                              (dreyeck/build:build-referee-decision-route-title-of"
     "dreyeck-explorer/codex.lisp:538:                              (dreyeck/build:build-referee-decision-route-summary-of"
     "dreyeck-explorer/codex.lisp:542:                             (dreyeck/build:build-referee-decision-route-requested-goal-of"
     "dreyeck-explorer/codex.lisp:546:                             (dreyeck/build:build-referee-decision-route-selected-task-of"
     "dreyeck-explorer/codex.lisp:550:                             (dreyeck/build:build-referee-decision-route-selected-action-of"
     "dreyeck-explorer/codex.lisp:555:                              (dreyeck/build:build-referee-decision-route-decoded-operation-of"
     "dreyeck-explorer/codex.lisp:559:                             (dreyeck/build:build-referee-decision-route-reason-of"))
   (:PATTERN "dreyeck/codex" :MATCH-COUNT 246 :SAMPLE
    ("dreyeck-explorer/codex.lisp:5:   :views :html-inspector-views :dreyeck/codex))"
     "dreyeck-explorer/codex.lisp:7:(in-package :dreyeck/codex)"
     "dreyeck.asd:20:                 #:dreyeck/codex))"
     "dreyeck.asd:22:(defsystem #:dreyeck/codex"
     "dreyeck.asd:35:(defsystem #:dreyeck/codex/examples"
     "dreyeck.asd:41:    :depends-on (#:dreyeck/codex)"
     "dreyeck.asd:46:(defsystem #:dreyeck/codex/explorer"
     "dreyeck.asd:52:    :depends-on (#:dreyeck/codex"))
   (:PATTERN "dreyeck/codex/explorer" :MATCH-COUNT 17 :SAMPLE
    ("dreyeck.asd:46:(defsystem #:dreyeck/codex/explorer"
     "dreyeck.asd:64:    :depends-on (#:dreyeck/codex/explorer"
     "dreyeck/codex.lisp:924:     '(\"nix develop -c sbcl --noinform --disable-debugger --non-interactive --eval '(require :asdf)' --eval '(asdf:load-system :dreyeck/codex/explorer)' --eval '(assert (dreyeck/codex:codex-context-window))' --eval '(uiop:quit)'\""
     "dreyeck/codex.lisp:929:       \"Codex canonical systems are :dreyeck/codex and :dreyeck/codex/explorer.\""
     "dreyeck/codex.lisp:1028:    :evidence '(\":dreyeck/codex, :dreyeck/codex/examples, and :dreyeck/codex/explorer are canonical.\""
     "dreyeck/codex.lisp:1276:                 '(\"nix develop -c sbcl --noinform --disable-debugger --non-interactive --eval '(require :asdf)' --eval '(asdf:load-system :dreyeck/codex/explorer)' --eval '(let ((session (dreyeck/build:make-build-session))) (dreyeck/build:plan-build-task session :validate-dmx-learning-topics) (dreyeck/build:check-build-task session :validate-dmx-learning-topics) (assert (dreyeck/codex:codex-dmx-learning-topics)))' --eval '(uiop:quit)'\""
     "hyperdoc.asd:670:                 #:dreyeck/codex/explorer))"
     "hyperdoc/Codex Belongs to Dreyeck.md:28:- `dreyeck/codex/explorer`"))
   (:PATTERN "dreyeck-explorer/codex.lisp" :MATCH-COUNT 12 :SAMPLE
    ("dreyeck/build/render-build-referee-decisions-as-routes-plan.sexp:37:    \"dreyeck-explorer/codex.lisp\"))"
     "dreyeck/codex.lisp:870:                           \"dreyeck-explorer/codex.lisp\")"
     "dreyeck/codex.lisp:998:                     \"dreyeck-explorer/codex.lisp\")"
     "dreyeck/codex.lisp:1020:                      \"dreyeck-explorer/codex.lisp\""
     "hyperdoc/Codex Belongs to Dreyeck.md:21:- `dreyeck-explorer/codex.lisp` owns inspector/explorer views for Dreyeck Codex"
     "hyperdoc/Ownership Extraction with Compatibility Shell.md:107:dreyeck-explorer/codex.lisp"
     "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:11:   (:FILE \"dreyeck-explorer/codex.lisp\" :PRESENT-P T :STATUS :READABLE :HEAD EVAL-WHEN)"
     "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp:18:    (\"dreyeck-explorer/codex.lisp:5:   :views :html-inspector-views :dreyeck/codex))\""))
   (:PATTERN "coherent-live-lisp-image" :MATCH-COUNT 0 :SAMPLE NIL))
  :REDECISION
  (:EXECUTOR-ROLE :COHERENT-LIVE-LISP-IMAGE :CANDIDATE #1# :SELECTED-CAPABILITY-OWNER
   ":dreyeck/build" :SELECTED-PLAN-ARTIFACT-TARGET
   "dreyeck/build/add-build-referee-subgraph-inspector-view-plan.sexp" :SELECTED-PERSISTENCE-OWNER
   ":dreyeck/dmx/sqlite" :SELECTED-VIEW-OWNER :DREYECK-EXPLORER-OR-HYPERDOC-INSPECTOR
   :CURRENT-VIEW-SOURCE "dreyeck-explorer/codex.lisp" :CURRENT-DOMAIN-FUNCTION-SOURCE
   "dreyeck/codex.lisp" :CODEX-ROLE :LEGACY-COMPATIBILITY-OR-READER-DISPLAY-SURFACE
   :NEW-ASDF-SUBSYSTEM-NEEDED-NOW NIL :REASON
   (:BUILD-REFEREE-SUBGRAPH-IS-REFEREE-DOMAIN-CAPABILITY T :CODEX-IS-NO-LONGER-EXECUTOR T
    :SLY-MREPL-IS-ONLY-ONE-TRANSPORT-INSTANCE T :SBCL-BRIDGE-OR-OTHER-LIVE-IMAGE-MAY-ALSO-EXECUTE T
    :VIEW-SOURCE-CAN-REMAIN-WHERE-IT-IS-UNTIL-A-VIEW-RENAMING-SLICE T
    :PLAN-ARTIFACT-SHOULD-FOLLOW-CAPABILITY-OWNER T))
  :SEVENTH-EXTRACTION-EXECUTED NIL :NEXT (!SELECT-SEVENTH-LOW-RISK-DREYECK-EXTRACTION-SLICE)))
