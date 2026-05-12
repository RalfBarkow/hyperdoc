
((!ABORT-DEBUGGER-TO-CL-USER)
 (!INSTALL-CLICKABLE-PARSER-EXAMPLES "hyperdoc-shop3/examples.lisp")
 (!RELOAD-HYPERDOC-SHOP3 :SYSTEM :HYPERDOC/SHOP3 :FORCE T)
 (!RUN-PARSER-EXAMPLES)
 (!WRITE-PARSER-DEMO-PAGE
  "hyperdoc/Parsing SHOP3 Introduction into Topics.html")
 (!RELOAD-AND-INSPECT-PARSER-DEMO-PAGE)
 (!CHECK-GIT-STATUS "git status --short --branch")
 (!COMMIT-PARSER-DOCUMENTATION
  "docs: add runnable SHOP3 introduction parser examples"))
