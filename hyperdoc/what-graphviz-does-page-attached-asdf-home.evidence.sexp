(:TASK (!REPAIR-PAGE-ATTACHED-ASDF-HOME-OBJECT-EVIDENCE WHAT-GRAPHVIZ-DOES)
 :REPAIRS-TASK (!PLAN-PAGE-ATTACHED-ASDF-HOME-OBJECT WHAT-GRAPHVIZ-DOES)
 :PARENT-TASK (!WRITE-REMOTE-FORK-MATERIALIZATION-ENTRY WHAT-GRAPHVIZ-DOES)
 :STAGE-BOUNDARY
 ((MAY-REPAIR-PAGE-ATTACHED-ASDF-HOME-EVIDENCE T)
  (MAY-CONSTRUCT-HOME-OBJECT-IF-NEEDED T)
  (MAY-RETAIN-LIVE-HOME-OBJECT-VARIABLE T)
  (MAY-WRITE-READABLE-HOME-OBJECT-EVIDENCE-ARTIFACT T)
  (MAY-LOAD-PAGE-ASDF-ASSET-WRITER-SYSTEM NIL)
  (MAY-WRITE-PAGE-ATTACHED-ASDF NIL) (MAY-CREATE-SQLITE NIL) (MAY-COMMIT NIL))
 :REPAIR-REASON
 "Previous evidence attempted to print the live home object or home page readably, causing PRINT-NOT-READABLE."
 :LOCAL-PAGE
 (:PAGE-FILE #1="/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/what-graphviz-does"
  :PAGE-FILE-EXISTS-P T)
 :EXISTING-OPERATORS
 (:MAKE-FEDWIKI-ATTACHED-ASDF-SYSTEM
  #A((43) BASE-CHAR . "HYPERDOC::MAKE-FEDWIKI-ATTACHED-ASDF-SYSTEM")
  :ASDF-SYSTEM-HOME-PAGE-OF
  #A((34) BASE-CHAR . "HYPERDOC::ASDF-SYSTEM-HOME-PAGE-OF"))
 :PAGE-ATTACHED-ASDF-HOME-SPEC
 (:SLUG "what-graphviz-does" :SITE-ROOT
  #A((36) BASE-CHAR . "/Users/rgb/.wiki/wiki.ralfbarkow.ch/") :SYSTEM
  :WHAT-GRAPHVIZ-DOES :SYSTEM-FILE "what-graphviz-does" :TEST-SYSTEM
  :WHAT-GRAPHVIZ-DOES/TESTS :PAGE-FILE #1# :ASSET-DIRECTORY
  "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/what-graphviz-does/"
  :ASDF-ENTRYPOINT
  "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/what-graphviz-does/what-graphviz-does.asd")
 :LIVE-OBJECT-RETENTION
 (:HOME-OBJECT-VARIABLE *WGD-PAGE-ATTACHED-ASDF-HOME-OBJECT*
  :HOME-PAGE-VARIABLE *WGD-PAGE-ATTACHED-ASDF-HOME-PAGE* :HOME-SPEC-VARIABLE
  *WGD-PAGE-ATTACHED-ASDF-HOME-SPEC*)
 :HOME-OBJECT-DESCRIPTOR
 (:PRESENT-P T :REUSED-EXISTING-BINDING-P T :TYPE
  #A((37) BASE-CHAR . "HYPERDOC:FEDWIKI-ATTACHED-ASDF-SYSTEM") :SUMMARY
  "#<HYPERDOC:FEDWIKI-ATTACHED-ASDF-SYSTEM what-graphviz-does -> WHAT-GRAPHVIZ-DOES>")
 :HOME-PAGE-DESCRIPTOR
 (:PRESENT-P T :REUSED-EXISTING-BINDING-P T :TYPE #A((4) BASE-CHAR . "CONS")
  :SUMMARY
  "(:KIND :FEDWIKI-ATTACHED-ASDF-SYSTEM-HOME-PAGE :TITLE \"FedWiki-attached ASDF system home page\" :OBJECT #<HYPERDOC:FEDWIKI-ATTACHED-ASDF-SYSTEM #1=what-graphviz-does -> WHAT-GRAPHVIZ-DOES> :STATE (:PAGE-IDENTITY #1# :ASSET-ROOT #P\"/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/what-graphviz-does/\" :ASDF-ENTRYPOINT #2=#P\"/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/what-graphviz-does/what-graphviz-does.asd\" :SYSTEM :WHAT-GRAPHVIZ-DOES :TEST-SYSTEM :WHAT-GRAPHVIZ-DOES/TESTS :SOURCE-FILE NIL :SOURCE-DIRECTORY NIL :PACKAGE-NAME \"WHAT-GRAPHVIZ-DOES\" :LOADED-P NIL :SYSTEM-FOUND-P NIL :REGISTERED-P NIL :TEST-SYSTEM-FOUND-P NIL :ASSET-ROOT-EXISTS-P NIL :ASD-EXISTS-P NIL :PACKAGE-PRESENT-P NIL :EXAMPLES-COUNT 0 :TESTS-FOUND-P NIL :SQLITE-STATUS :NOT-APPLICABLE) :ACTIONS (\"(asdf:load-asd #p\\\"/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/what-graphviz-does/what-graphviz-does.asd\\\" :name \\\"what-graphviz-does\\\")\" \"(hyperdoc:load-fedwiki-attached-asdf-system *)\" \"(asdf:load-system :WHAT-GRAPHVIZ-DOES)\" \"(asdf:load-system :WHAT-GRAPHVIZ-DOES/TESTS)\" #3=\"(clog-moldable-inspector:clog-inspect :object *)\" #4=\"(hyperdoc/inspector:inspect-system-home-page *)\" #5=\"Inspect Overview, Source, Examples, Tests, Files, Plan, and Dependencies views when present.\") :EXAMPLES NIL :TESTS (\"ASDF test system WHAT-GRAPHVIZ-DOES/TESTS\" \"(asdf:load-system :WHAT-GRAPHVIZ-DOES/TESTS)\") :ROUTE-TRACE (\"FedWiki page identity: what-graphviz-does\" \"Local page asset root: /Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/what-graphviz-does/\" \"ASDF entrypoint pathname: /Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/what-graphviz-does/what-graphviz-does.asd\" \"Load boundary: (asdf:load-asd #p\\\"/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/what-graphviz-does/what-graphviz-does.asd\\\" :name \\\"what-graphviz-does\\\")\" \"ASDF system object: WHAT-GRAPHVIZ-DOES\" #6=\"Inspector object: fedwiki-attached-asdf-system home page\") :CANDIDATE-ROUTES ((:ROUTE :FEDWIKI-ASSET :LABEL \"local FedWiki page asset .asd\" :KIND :PATHNAME :PATHNAME #2# :SYSTEM-NAME NIL :EXISTS-P NIL :AVAILABLE-P NIL :RECOVERY-ACTION \"(asdf:load-asd #p\\\"/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/what-graphviz-does/what-graphviz-does.asd\\\" :name \\\"what-graphviz-does\\\"), then (asdf:load-system :WHAT-GRAPHVIZ-DOES)\" :EXPLANATION \"Preferred SLY route: use the local file-backed asset attached to the FedWiki page identity.\" :TRIED-P NIL :RESULT NIL :CONDITION NIL :CONDITION-MESSAGE #7=\"\") (:ROUTE :WORKSPACE-SOURCE :LABEL \"workspace source .asd\" :KIND :PATHNAME :PATHNAME #P\"/Users/rgb/workspace/hyperdoc/what-graphviz-does.asd\" :SYSTEM-NAME NIL :EXISTS-P NIL :AVAILABLE-P NIL :RECOVERY-ACTION \"(asdf:load-asd #p\\\"/Users/rgb/workspace/hyperdoc/what-graphviz-does.asd\\\" :name \\\"what-graphviz-does\\\")\" :EXPLANATION \"Fallback for repository-local development, not the page-attached route.\" :TRIED-P NIL :RESULT NIL :CONDITION NIL :CONDITION-MESSAGE #7#)) :READING-QUESTIONS ((:QUESTION \"How do I invoke response?\" :ANSWER (\"(asdf:load-asd #p\\\"/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/what-graphviz-does/what-graphviz-does.asd\\\" :name \\\"what-graphviz-does\\\")\" \"(hyperdoc:load-fedwiki-attached-asdf-system *)\" \"(asdf:load-system :WHAT-GRAPHVIZ-DOES)\" \"(asdf:load-system :WHAT-GRAPHVIZ-DOES/TESTS)\" #3# #4# #5#)) (:QUESTION \"What specifically can I do now?\" :ANSWER (\"Inspect Overview\" \"Inspect Source\" \"Inspect Examples\" \"Inspect Tests\" \"Inspect Files\" \"Inspect Plan\" \"Inspect Dependencies\" \"Load tests\" \"Run smoke tests\")) (:QUESTION \"What is needed to do a specific function?\" :ANSWER (\"The asset root must exist.\" \"The page-local .asd must exist.\" \"ASDF must load the .asd or know an equivalent source-registry route.\" \"The package must be created by loading the system before package-qualified calls are readable.\" \"sqlite3 is optional for SQLite-backed persistence.\")) (:QUESTION \"What is that?\" :ANSWER (\"FedWiki page identity: what-graphviz-does\" \"Asset root: /Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/what-graphviz-does/\" \"ASDF entrypoint: /Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/what-graphviz-does/what-graphviz-does.asd\" \"ASDF system: WHAT-GRAPHVIZ-DOES\" \"Package: WHAT-GRAPHVIZ-DOES (missing)\" \"Test system: :WHAT-GRAPHVIZ-DOES/TESTS\")) (:QUESTION \"Where is it?\" :ANSWER (\"Site root: /Users/rgb/.wiki/wiki.ralfbarkow.ch/\" \"Asset root: /Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/what-graphviz-does/\" \"ASDF entrypoint: /Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/what-graphviz-does/what-graphviz-does.asd\" \"Source file: NIL\" \"Source directory: NIL\")) (:QUESTION \"Does any part of the system do this?\" :ANSWER (\"hyperdoc:make-fedwiki-attached-asdf-system constructs the home object.\" \"hyperdoc:fedwiki-page-asset-root resolves the local asset root.\" \"hyperdoc:fedwiki-page-asdf-entrypoint resolves the exact .asd pathname.\" \"hyperdoc:load-fedwiki-attached-asdf-system loads the exact .asd.\" \"hyperdoc/inspector:inspect-system-home-page opens the inspector home surface.\")) (:QUESTION \"What part of the system knows about that?\" :ANSWER (\"ASDF knows systems, components, source files, dependencies, and loaded state.\" \"The FedWiki asset materializer knows page-local asset paths.\" \"The inspector knows the Overview and lookup-failure views.\" \"The Kioskbeerli package knows dashboard, planner, trace, examples, tests, and optional SQLite APIs.\")) (:QUESTION \"How did I get here? What has been happening?\" :ANSWER (\"FedWiki page identity: what-graphviz-does\" \"Local page asset root: /Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/what-graphviz-does/\" \"ASDF entrypoint pathname: /Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/what-graphviz-does/what-graphviz-does.asd\" \"Load boundary: (asdf:load-asd #p\\\"/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/what-graphviz-does/what-graphviz-does.asd\\\" :name \\\"what-graphviz-does\\\")\" \"ASDF system object: WHAT-GRAPHVIZ-DOES\" #6#)) (:QUESTION \"How can I get back?\" :ANSWER (\"Reverse path: system object -> .asd source file -> asset root -> page identity.\" \"Use the Source file and Source directory rows to inspect the loaded entrypoint.\" \"Use the Page identity row to recover the FedWiki slug.\" \"Use the Previous object row when this home was opened from another inspected object.\")) (:QUESTION \"What is the current state of the system?\" :ANSWER (\"asset-root-exists-p: NIL\" \"asd-exists-p: NIL\" \"system-found-p: NIL\" \"loaded-p: NIL\" \"package-present-p: NIL\" \"tests-found-p: NIL\" \"sqlite-status: NOT-APPLICABLE\")) (:QUESTION \"Why did that happen?\" :ANSWER (\"The local .asd is missing at the computed page asset path, so the page-attached route cannot load yet.\")) (:QUESTION \"Why didn't that happen?\" :ANSWER (\"Package WHAT-GRAPHVIZ-DOES is absent because the ASDF system has not loaded or failed during load; reader forms such as kioskbeerli:... fail before evaluation when that package does not exist.\" \"Tests are not available as callable package functions until the test system has been loaded.\" \"ASDF does not yet know the system object until load-asd registers the exact page-local .asd or another source-registry route finds it.\"))))")
 :VALIDATION
 (:HOME-OBJECT-VALID-P
  #P"/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/what-graphviz-does"
  :PAGE-IDENTITY-REMAINS-IN-PAGES-STORE T
  :ASDF-ENTRYPOINT-REMAINS-IN-ASSETS-STORE T
  :EVIDENCE-CONTAINS-READABLE-DESCRIPTORS-NOT-LIVE-OBJECTS T
  :NO-ASDF-WRITER-SYSTEM-LOADED T :NO-ASDF-ASSET-WRITTEN T)
 :ACCEPTANCE-FOR-CURRENT-TASK
 ((PAGE-ATTACHED-ASDF-HOME-OBJECT-PLANNED T) (HOME-OBJECT-RETAINED T)
  (HOME-OBJECT-EVIDENCE-IS-READABLE-DESCRIPTOR T) (LOCAL-PAGE-JSON-EXISTS T)
  (NO-ASDF-WRITER-SYSTEM-LOADED T) (NO-PAGE-ATTACHED-ASDF-WRITTEN T)
  (NO-SQLITE-CREATED T) (NO-COMMIT-PERFORMED T))
 :NEXT-TASK
 (!LOAD-PAGE-ASDF-ASSET-WRITER-SYSTEM :SYSTEM :HYPERDOC/FEDWIKI-ASDF-ASSETS))
