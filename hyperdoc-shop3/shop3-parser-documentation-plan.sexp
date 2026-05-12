
((!ABORT-DEBUGGER-TO-CL-USER)
 (!INSTALL-CLICKABLE-PARSER-EXAMPLES "hyperdoc-shop3/examples.lisp")
 (!RELOAD-HYPERDOC-SHOP3 :SYSTEM :HYPERDOC/SHOP3 :FORCE T)
 (!RUN-PARSER-EXAMPLES)
 (!WRITE-PARSER-DEMO-PAGE
  "hyperdoc/Parsing SHOP3 Introduction into Topics.html")
 (!WRITE-PLAN-SCXML-LINK-PAGE
  "hyperdoc/SHOP3 Parser Documentation Plan and SCXML.html")
 (!OPEN-PLAN-SCXML-LINK-PAGE-IN-HYPERDOC-INSPECTOR
  "SHOP3 Parser Documentation Plan and SCXML")
 (!CHECK-GIT-STATUS "git status --short --branch")
 (!COMMIT-PARSER-DOCUMENTATION
  "shop3: add parser documentation plan and SCXML workflow"))
