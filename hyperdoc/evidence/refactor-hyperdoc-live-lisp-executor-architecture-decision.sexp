(REFACTOR-HYPERDOC-LIVE-LISP-EXECUTOR-ARCHITECTURE-DECISION
 (:OPERATION (!RECORD-LIVE-LISP-EXECUTOR-ARCHITECTURE-DECISION) :BASE "592cb98d"
  :CONTEXT-READ-CHECKS
  ((:FILE "hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp" :PRESENT-P T :STATUS
    :TEXT-FALLBACK :CONDITION-TYPE SB-INT:SIMPLE-READER-PACKAGE-ERROR :MESSAGE
    "Package DREYECK/BUILD does not exist.

  Stream: #<SB-SYS:FD-STREAM for \"file /Users/rgb/workspace/hyperdoc/hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp\" {7020298E63}>")
   (:FILE "dreyeck.asd" :PRESENT-P T :STATUS :READABLE :HEAD DEFSYSTEM)
   (:FILE "dreyeck/codex.lisp" :PRESENT-P T :STATUS :READABLE :HEAD IN-PACKAGE)
   (:FILE "dreyeck-explorer/codex.lisp" :PRESENT-P T :STATUS :READABLE :HEAD EVAL-WHEN)
   (:FILE "hyperdoc/refactor-hyperdoc-reusable-extraction-htn.sexp" :PRESENT-P T :STATUS :READABLE
    :HEAD :ARTIFACT)
   (:FILE "hyperdoc/evidence/refactor-hyperdoc-upstream-core-dreyeck-extraction-result.sexp"
    :PRESENT-P T :STATUS :READABLE :HEAD :HYPERDOC-UPSTREAM-CORE-DREYECK-EXTRACTION-RESULT))
  :CODEX-NAME-SIGNALS
  ((:PATTERN "dreyeck/codex" :MATCH-COUNT 220 :SAMPLE
    ("dreyeck-explorer/codex.lisp:5:   :views :html-inspector-views :dreyeck/codex))"
     "dreyeck-explorer/codex.lisp:7:(in-package :dreyeck/codex)"
     "dreyeck.asd:20:                 #:dreyeck/codex))"
     "dreyeck.asd:22:(defsystem #:dreyeck/codex"
     "dreyeck.asd:35:(defsystem #:dreyeck/codex/examples"
     "dreyeck.asd:41:    :depends-on (#:dreyeck/codex)"
     "dreyeck.asd:46:(defsystem #:dreyeck/codex/explorer"
     "dreyeck.asd:52:    :depends-on (#:dreyeck/codex"))
   (:PATTERN "hyperdoc/codex" :MATCH-COUNT 43 :SAMPLE
    ("dreyeck/codex.lisp:925:       \"nix develop -c sbcl --noinform --disable-debugger --non-interactive --eval '(require :asdf)' --eval '(asdf:load-system :hyperdoc/codex/explorer)' --eval '(assert (hyperdoc::codex-context-window))' --eval '(uiop:quit)'\""
     "dreyeck/codex.lisp:1024:                      \"hyperdoc/codex-compat.lisp\""
     "dreyeck/codex.lisp:1025:                      \"hyperdoc/codex-examples-compat.lisp\""
     "dreyeck/codex.lisp:1029:                \":hyperdoc/codex, :hyperdoc/codex/examples, and :hyperdoc/codex/explorer remain compatibility coordinates.\""
     "dreyeck/codex.lisp:1040:    :affected-files '(\"hyperdoc/codex.lisp\""
     "dreyeck/codex.lisp:1055:    :affected-files '(\"hyperdoc/codex.lisp\""
     "dreyeck/codex.lisp:1058:    :evidence '(\"(hyperdoc::codex-context-window) loads through :hyperdoc/codex.\""
     "dreyeck/codex.lisp:1065:    \"The :hyperdoc/codex/examples system provides deterministic inspectable Codex examples.\""))
   (:PATTERN "Codex Belongs to Dreyeck" :MATCH-COUNT 13 :SAMPLE
    ("dreyeck/codex.lisp:1026:                      \"hyperdoc/Codex Belongs to Dreyeck.md\")"
     "dreyeck/codex.lisp:1027:    :affected-pages '(\"Codex Belongs to Dreyeck\")"
     "dreyeck/codex.lisp:1272:                 :relevant-pages '(\"Codex Belongs to Dreyeck\""
     "dreyeck/dmx/sqlite/durable-notes.lisp:24:    (\"hyperdoc/Codex Belongs to Dreyeck.md\" \"codex-belongs-to-dreyeck\")"
     "dreyeck/dmx/sqlite/durable-notes.lisp:56:     :title \"Codex Belongs to Dreyeck\""
     "dreyeck/dmx/sqlite/durable-notes.lisp:57:     :source \"hyperdoc/Codex Belongs to Dreyeck.md\""
     "dreyeck/dmx/sqlite/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp:28:    (\"hyperdoc/Codex Belongs to Dreyeck.md\" codex-belongs-to-dreyeck)"
     "hyperdoc/Codex Belongs to Dreyeck.md:1:# Codex Belongs to Dreyeck"))
   (:PATTERN "codex-dmx-build-referee-subgraph" :MATCH-COUNT 8 :SAMPLE
    ("dreyeck-explorer/codex.lisp:1019:    (let ((subgraph (codex-dmx-build-referee-subgraph surface)))"
     "dreyeck/codex.lisp:465:(defun codex-dmx-build-referee-subgraph (surface)"
     "dreyeck/codex/tests/package.lisp:6:                #:codex-dmx-build-referee-subgraph"
     "dreyeck/codex/tests/smoke.lisp:98:                    (codex-dmx-build-referee-subgraph surface))"
     "dreyeck/package.lisp:29:           #:codex-dmx-build-referee-subgraph"
     "dreyeck/package.lisp:63:                #:codex-dmx-build-referee-subgraph"
     "dreyeck/package.lisp:76:           #:codex-dmx-build-referee-subgraph"
     "hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:94:   (\"dreyeck/codex:codex-dmx-build-referee-subgraph\"))"))
   (:PATTERN "Build Referee Subgraph" :MATCH-COUNT 6 :SAMPLE
    ("dreyeck-explorer/codex.lisp:1020:      (views:html-view :title \"Build Referee Subgraph\" :priority 1"
     "dreyeck-explorer/codex.lisp:1028:                              (:h1 \"Build Referee Subgraph\")"
     "dreyeck/codex/tests/smoke.lisp:162:              \"Explorer load must install the Build Referee Subgraph view\")"
     "hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:3: (:title \"Add Build Referee Subgraph Inspector View\")"
     "hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:18:   ((tab-title \"Build Referee Subgraph\")"
     "hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp:97:    :title \"Build Referee Subgraph\"))")))
  :DECISION
  (:EXECUTOR-ROLE :COHERENT-LIVE-LISP-IMAGE :EXECUTOR-CONTRACT
   (:CAN-LOAD-PROJECT-SYSTEMS T :CAN-EVALUATE-INSPECTABLE-FORMS T
    :CAN-MAINTAIN-OR-REBUILD-COHERENT-RUNTIME-STATE T :CAN-WRITE-REPO-NATIVE-EVIDENCE T
    :CAN-RUN-VALIDATION-GATES T :CAN-RETURN-STRUCTURED-OPERATION-RESULTS T)
   :CURRENT-INSTANCE
   (:IMPLEMENTATION :SBCL :ENTRY-SURFACE :SLY-MREPL :ENVIRONMENT "current nix dev.sh")
   :ALTERNATIVE-INSTANCES
   (:SBCL-BRIDGE :SCRIPTED-SBCL-ENTRYPOINT :SOCKET-REPL :FUTURE-COHERENT-LIVE-IMAGE)
   :TRANSPORT-SURFACES (:SLY-MREPL :SBCL-BRIDGE :SOCKET-REPL :SCRIPTED-SBCL-ENTRYPOINT)
   :NOT-THE-EXECUTOR (:CODEX :ASDF-SYSTEM-NAME :REPOSITORY-DIRECTORY :NIX-DEV-SHELL)
   :PLANNING-AUTHORITY :SHOP3-HTN :REFEREE-AUTHORITY :DREYECK/BUILD :PERSISTENCE-AUTHORITY
   :DREYECK/DMX/SQLITE :INSPECTION-AUTHORITY :MOLDABLE-INSPECTOR-VIEWS :CODEX-ROLE
   :LEGACY-COLLABORATION-OR-READER-DISPLAY-SURFACE)
  :CONSEQUENCE
  (:DO-NOT-SELECT-DREYECK/CODEX-AS-OWNER-MERELY-BECAUSE-OF-EXISTING-NAMES T
   :REDECIDE-BUILD-REFEREE-SUBGRAPH-OWNER-UNDER-LIVE-LISP-EXECUTOR-MODEL T
   :SEVENTH-EXTRACTION-EXECUTED NIL)
  :NEXT (!REDECIDE-BUILD-REFEREE-SUBGRAPH-OWNER-UNDER-LIVE-LISP-EXECUTOR-MODEL)))
