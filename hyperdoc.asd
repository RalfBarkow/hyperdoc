;;;; System definitions for HyperDoc
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(defsystem #:hyperdoc/kernel
    :description "Hypertext documentation system"
    :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
    :license  "BSD"
    :version "0.0.1"
    :homepage "https://codeberg.org/khinsen/hyperdoc"
    :source-control (:git "https://codeberg.org/khinsen/hyperdoc.git")
    :serial t
    :depends-on (#:hyperbook
                 #:alexandria
                 #:arrow-macros
                 #:asdf #:uiop
                 #:trivial-package-local-nicknames)
    :components ((:module "hyperdoc"
                  :serial t
                  :components ((:file "package")
                               (:file "core")
                               (:file "defining")
                               (:file "links-in-code")
                               (:file "dm6-page-topicmap-api")))))

(defsystem #:hyperdoc/s-expression-prompts
    :description "Pure executable S-expression prompt model and HTML projection core"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license  "BSD"
    :version "0.0.1"
    :homepage "https://codeberg.org/rgb/hyperdoc"
    :source-control (:git "https://codeberg.org/rgb/hyperdoc.git")
    :serial t
    :depends-on (#:hyperdoc/kernel
                 #:plump)
    :components ((:module "hyperdoc"
                  :serial t
                  :components ((:file "s-expression-prompts")))))

(defsystem #:hyperdoc/s-expression-prompts/tests
    :description "Smoke tests for the pure executable S-expression prompt core"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license "BSD"
    :version "0.0.1"
    :serial t
    :depends-on (#:hyperdoc/s-expression-prompts)
    :components ((:module "tests"
                  :serial t
                  :components ((:file "s-expression-prompt-smoke")))))

(defsystem #:hyperdoc/executable-dita-tasks
    :description "Executable DITA task objects with S-expression, DITA, HyperDoc, SCXML, and SQLite projections"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license "BSD"
    :version "0.0.1"
    :serial t
    :depends-on (#:hyperdoc/kernel
                 #:html-inspector-views)
    :components ((:module "hyperdoc"
                  :serial t
                  :components ((:file "shared-sexpression-plans")
                               (:file "executable-dita-tasks")
                               (:file "executable-dita-task-views")))))

(defsystem #:hyperdoc/executable-dita-tasks/tests
    :description "Smoke tests for executable DITA task objects"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license "BSD"
    :version "0.0.1"
    :serial t
    :depends-on (#:hyperdoc/executable-dita-tasks)
    :components ((:module "tests"
                  :serial t
                  :components ((:file "package")
                               (:file "executable-dita-tasks-smoke"))))
    :perform (test-op (op c)
                      (declare (ignore op c))
                      (uiop:symbol-call :hyperdoc/tests
                                        :run-executable-dita-tasks-smoke-test)))

(defsystem #:hyperdoc/topics
    :description "Inspectable authored topic registry for HyperDoc"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license  "BSD"
    :version "0.0.1"
    :homepage "https://codeberg.org/rgb/hyperdoc"
    :source-control (:git "https://codeberg.org/rgb/hyperdoc.git")
    :serial t
    :depends-on (#:hyperdoc/kernel)
    :components ((:module "hyperdoc/topics"
                  :serial t
                  :components ((:file "registry")
                               (:file "core-concepts")
                               (:file "winston-horn")
                               (:file "drew-mcdermott")
                               (:file "asdf")
                               (:file "generated-slices")
                               (:file "runtime")
                               (:file "surfaces")
                               (:file "smalltalk-browser")
                               (:file "capability-reference")
                               (:file "hypercard-documentation")
                               (:file "idiomatic-survey")
                               (:file "identity-risk")
                               (:file "civilian-harm")
                               (:file "interaction-nets")
                               (:file "source-stations")
                               (:file "dm6-inline-proof")
                               (:file "page-systems")
                               (:file "mobile-progressive-chrome")
                               (:file "reel-accessible-carousel")
                               (:file "layout-topicmap")
                               (:file "metagraph-fluree")
                               (:file "topic-files-topicmap")))))

(defsystem #:hyperdoc/dmx-topics
    :description "DMX-backed topic proxy objects for HyperDoc"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license  "BSD"
    :version "0.0.1"
    :homepage "https://codeberg.org/rgb/hyperdoc"
    :source-control (:git "https://codeberg.org/rgb/hyperdoc.git")
    :serial t
    :depends-on (#:hyperdoc/topics
                 #:drakma
                 #:shasht)
    :components ((:module "hyperdoc"
                  :serial t
                  :components ((:file "dmx-topics")))))

(defsystem #:hyperdoc/checks
    :description "In-image example and documentation validation checks for HyperDoc"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license  "BSD"
    :version "0.0.1"
    :homepage "https://codeberg.org/rgb/hyperdoc"
    :source-control (:git "https://codeberg.org/rgb/hyperdoc.git")
    :serial t
                  :depends-on (#:hyperdoc/topics
                 #:shasht)
    :components ((:module "hyperdoc"
                  :serial t
                  :components ((:file "check-runner")
                               (:file "example-source-artifacts")
                               (:file "inspector-path-evidence")
                               (:file "example-core")
                               (:file "journal-gate")
                               (:file "validation")))))

(defsystem #:hyperdoc/state-machines
    :description "Reusable state-machine objects for HyperDoc workflows"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license  "BSD"
    :version "0.0.1"
    :homepage "https://codeberg.org/rgb/hyperdoc"
    :source-control (:git "https://codeberg.org/rgb/hyperdoc.git")
    :serial t
    :depends-on (#:hyperdoc/topics)
    :components ((:module "hyperdoc"
                  :serial t
                  :components ((:file "state-machines")))))

(defsystem #:hyperdoc
    :description "Hypertext documentation system"
    :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
    :license  "BSD"
    :version "0.0.1"
    :homepage "https://codeberg.org/khinsen/hyperdoc"
    :source-control (:git "https://codeberg.org/khinsen/hyperdoc.git")
    :serial t
    :depends-on (#:hyperdoc/topics
                 #:hyperdoc/checks
                 #:hyperdoc/state-machines
                 #:hyperdoc/s-expression-prompts
                 #:hyperdoc/executable-dita-tasks
                 #:shasht)
    :in-order-to ((test-op (test-op "hyperdoc/tests")))
    :components ((:module "hyperdoc"
                          :serial t
                          :components ((:file "kioskbeerli-compat")
                                       (:file "decision-maps")
                                       (:file "code-path-graphs")
                                       (:file "whyline-output-questions")
                                       (:file "skillization")
                                       (:file "mech-deployment-provenance")
                                       (:file "page-lookup-chunks")
                                       (:file "runtime-coherence")
                                       (:file "authored-relation-artifacts")
                                       (:file "page-lookup-issue-authored-source")
                                       (:file "page-lookup-issue-artifacts")
                                       (:file "page-lookup-issue-authored-mutations")
                                       (:file "shared-projection-ir")
                                       (:file "iconic-retrieval")
                                       (:file "surfaces")
                                       (:file "boundaries")
                                       (:file "tools")
                                       (:file "static-route-observability")
                                       (:file "operational-targets")
                                       (:file "neo4j-duplicate-username-repair")
                                       (:file "neo4j-topic-delete-tool-operations")
                                       (:file "dom-annotations")
                                       (:file "dock")
                                       (:file "source-pane-layout")
                                       (:file "git-relations")
                                       (:file "relation-topic-proposals")
                                       (:file "lisp-critic-review-plan")
                                       (:file "lisp-critic-contracts")
                                       (:file "git-commit-equivalence")
                                       (:file "hyperdoc")
                                       (:file "page-systems")
                                       (:file "fedwiki-attached-asdf-system")
                                       (:file "source-artifacts")
                                       (:file "topicmap-projection")
                                       (:file "layout-topicmap")
                                       (:file "topic-files-topicmap")
                                       (:file "dmx-query-layer")
                                       (:file "dmx-query-operations")
                                       (:file "dmx-sqlite-query-store")
                                       (:file "mobile-progressive-chrome")
                                       (:file "reel-accessible-carousel")
                                       (:file "runtime-incidents")
                             (:file "fedwiki-dmx-importer-bug")
                                       (:file "projection-pipeline-operator")
                                       (:file "metagraph-fluree-examples")))))

(defsystem #:hyperdoc/mobile-progressive-chrome
    :description "Mobile progressive chrome documentation and inspection slice for HyperDoc"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license "BSD"
    :version "0.0.1"
    :serial t
    :depends-on (#:hyperdoc)
    :components ((:module "hyperdoc"
                  :serial t
                  :components ((:file "mobile-progressive-chrome")))))

(defsystem #:hyperdoc/page/mobile-progressive-chrome
    :description "Page system for Mobile progressive chrome in HyperDoc"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license "BSD"
    :version "0.0.1"
    :serial t
    :depends-on (#:hyperdoc/mobile-progressive-chrome)
    :components ((:module "hyperdoc/page-systems"
                  :serial t
                  :components ((:file "mobile-progressive-chrome")))))

(defsystem #:hyperdoc/page/dm6-appembed-inline-proof
    :description "Page system for DM6 AppEmbed HyperDoc Inline Proof"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license "BSD"
    :version "0.0.1"
    :serial t
    :depends-on (#:hyperdoc/explorer)
    :components ((:module "hyperdoc/page-systems"
                  :serial t
                  :components ((:file "dm6-appembed-inline-proof")))))

(defsystem #:hyperdoc/fedwiki-asdf-assets
    :description "HyperDoc-native writer for page-local FedWiki ASDF assets"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license "BSD"
    :version "0.0.1"
    :serial t
    :depends-on (#:hyperdoc)
    :components ((:module "hyperdoc"
                  :serial t
                  :components ((:file "fedwiki-asdf-assets")))))

(defsystem #:hyperdoc/codex
    :description "Codex collaboration home topic for HyperDoc"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license "BSD"
    :version "0.0.1"
    :serial t
    :depends-on (#:hyperdoc)
    :components ((:module "hyperdoc"
                  :serial t
                  :components ((:file "codex")))))

(defsystem #:hyperdoc/codex/examples
    :description "Inspectable Codex collaboration examples"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license "BSD"
    :version "0.0.1"
    :serial t
    :depends-on (#:hyperdoc/codex)
    :components ((:module "hyperdoc"
                  :serial t
                  :components ((:file "codex-examples")))))

(defsystem #:hyperdoc/shop3
    :description "SHOP3-backed HTN planning layer for HyperDoc operations"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license "BSD"
    :version "0.0.1"
    :serial t
    :depends-on (#:hyperdoc
                 #:shop3)
    :components
    ((:module "hyperdoc-shop3"
      :serial t
      :components
      ((:file "package")
       (:file "manual-topics")
       (:file "plan-objects")
       (:file "hyperdoc-maintenance-domain")
       (:file "examples")
       (:file "views")))))

(defsystem #:hyperdoc/scxml
    :description "SCXML parser and ANSI Common Lisp code generator for HyperDoc"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license "BSD"
    :version "0.0.1"
    :serial t
    :depends-on (#:plump)
    :components ((:module "hyperdoc-scxml"
                          :serial t
                          :components ((:file "package")
                                       (:file "ast")
                                       (:file "parser")
                                       (:file "validator")
                                       (:file "runtime-model")
                                       (:file "codegen-common-lisp")
                                       (:file "compiler")))))

(defsystem #:hyperdoc/scxml-workflows
    :description "SCXML-backed HyperDoc workflow run objects"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license "BSD"
    :version "0.0.1"
    :serial t
    :depends-on (#:hyperdoc
                 #:hyperdoc/scxml
                 #:hyperdoc/dmx-import
                 #:hyperdoc/fedwiki)
    :components ((:module "hyperdoc"
                  :serial t
                  :components ((:file "scxml-runs")
                               (:file "scxml-architect")))))

(defsystem #:hyperdoc/zotero-support
    :description "Optional Zotero loading boundary and unavailable-backend objects"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license  "BSD"
    :version "0.0.1"
    :homepage "https://codeberg.org/rgb/hyperdoc"
    :source-control (:git "https://codeberg.org/rgb/hyperdoc.git")
    :serial t
    :depends-on (#:hyperdoc/topics)
    :components ((:module "hyperdoc"
                  :serial t
                  :components ((:file "zotero-support")))))

(defsystem #:hyperdoc/bibliography
    :description "Bibliography subcollections and authoring plans for HyperDoc"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license  "BSD"
    :version "0.0.1"
    :homepage "https://codeberg.org/rgb/hyperdoc"
    :source-control (:git "https://codeberg.org/rgb/hyperdoc.git")
    :serial t
    :depends-on (#:hyperdoc/topics
                 #:hyperdoc/zotero-support)
    :components ((:module "hyperdoc"
                  :serial t
                  :components ((:file "bibliography-subcollections")))))

(defsystem #:hyperdoc/zotero
    :description "Optional Zotero backend for HyperDoc"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license  "BSD"
    :version "0.0.1"
    :homepage "https://codeberg.org/rgb/hyperdoc"
    :source-control (:git "https://codeberg.org/rgb/hyperdoc.git")
    :serial t
    :depends-on (#:hyperdoc/bibliography
                 #:shasht)
    :components ((:module "hyperdoc"
                          :serial t
                          :components ((:file "zotero-bridge")
                                       (:file "bibliography-zotero")
                                       (:file "topic-enrichment-route-data")
                                       (:file "topic-enrichment")
                                       (:file "topic-enrichment-zotero")))))

(defsystem #:hyperdoc/examples
    :description "Portable example content for HyperDoc"
    :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
    :license  "BSD"
    :version "0.0.1"
    :homepage "https://codeberg.org/khinsen/hyperdoc"
    :source-control (:git "https://codeberg.org/khinsen/hyperdoc.git")
    :serial t
    :depends-on (#:hyperdoc
                 #:hyperbook/fedwiki)
    :components ((:module "hyperdoc"
                          :serial t
                          :components ((:file "examples-portable")))))

(defsystem #:hyperdoc/examples/ops
    :description "Ops and local example content for HyperDoc"
    :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
    :license  "BSD"
    :version "0.0.1"
    :homepage "https://codeberg.org/khinsen/hyperdoc"
    :source-control (:git "https://codeberg.org/khinsen/hyperdoc.git")
    :serial t
    :depends-on (#:hyperdoc)
    :components ((:module "hyperdoc"
                          :serial t
                          :components ((:file "examples")))))

(defsystem #:hyperdoc/nor-demo
    :description "Teaching slice for the NOR-only matcher demonstration"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license "BSD"
    :version "0.0.1"
    :serial t
    :depends-on (#:hyperdoc)
    :components ((:module "hyperdoc"
                          :serial t
                          :components ((:file "nor-matcher-demo")))))

(defsystem #:hyperdoc/nor-graph-demo
    :description "Graph leaf tests for the NOR matcher teaching demo"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license "BSD"
    :version "0.0.1"
    :serial t
    :depends-on (#:hyperdoc/nor-demo)
    :components ((:module "hyperdoc"
                          :serial t
                          :components ((:file "nor-graph-matcher-demo")))))

(defsystem #:hyperdoc/closures-nor-demo
    :description "Graham closure teaching slice for the NOR graph matcher"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license "BSD"
    :version "0.0.1"
    :serial t
    :depends-on (#:hyperdoc/nor-graph-demo)
    :components ((:module "hyperdoc"
                          :serial t
                          :components ((:file "graham-closures-nor-demo")))))

(defsystem #:hyperdoc/continuation-route-trace
    :description "Inspectable route bridge for closure-backed NOR matcher traces"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license "BSD"
    :version "0.0.1"
    :serial t
    :depends-on (#:hyperdoc/closures-nor-demo)
    :components ((:module "hyperdoc"
                          :serial t
                          :components ((:file "continuation-route-trace")))))

(defsystem #:hyperdoc/dmx-import
    :description "FedWiki to DMX import support for HyperDoc"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license  "BSD"
    :version "0.0.1"
    :homepage "https://codeberg.org/rgb/hyperdoc"
    :source-control (:git "https://codeberg.org/rgb/hyperdoc.git")
    :serial t
    :depends-on (#:hyperdoc
                 #:hyperdoc/dmx-topics
                 #:hyperdoc/state-machines
                 #:hyperbook/fedwiki
                 #:babel
                 #:cl-ppcre
                 #:drakma
                 #:shasht
                 #:uiop)
    :components ((:module "hyperdoc"
                          :serial t
                          :components ((:file "dmx-import")
                                       (:file "topic-factory-snippet-dmx")
                                       (:file "dmx-workspace-topics")
                                       (:file "dmx-workspace-journal")
                                       (:file "dmx-workspace-notes")
                                       (:file "dmx-annotations")))))

(defsystem #:hyperdoc/fedwiki
    :description "FedWiki materialization, promotion, and slice tooling for HyperDoc"
    :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
    :license  "BSD"
    :version "0.0.1"
    :homepage "https://codeberg.org/khinsen/hyperdoc"
    :source-control (:git "https://codeberg.org/khinsen/hyperdoc.git")
    :serial t
    :depends-on (#:hyperdoc
                 #:hyperbook/fedwiki
                 #:shasht)
    :components ((:module "hyperdoc"
                  :serial t
                  :components ((:file "localhost-fedwiki-page-pipeline")
                               (:file "collective-knowledge-slice")
                               (:file "reproducible-devenv-as-knowledge-artifact-slice")
                               (:file "localhost-fedwiki-page-promotion-plans")
                               (:file "article-allegation-slice")
                               (:file "fedwiki-materialization")))))

(defsystem #:hyperdoc/mcp
    :description "Streamable HTTP MCP server for the DMX shared workspace"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license  "BSD"
    :version "0.0.1"
    :homepage "https://codeberg.org/rgb/hyperdoc"
    :source-control (:git "https://codeberg.org/rgb/hyperdoc.git")
    :serial t
    :depends-on (#:hyperdoc/dmx-import
                 #:hunchentoot)
    :components ((:module "hyperdoc"
                          :serial t
                          :components ((:file "mcp-server")))))

(defsystem #:hyperdoc/inspector
    :description "HyperDoc for the moldable inspector"
    :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
    :license  "BSD"
    :version "0.0.1"
    :homepage "https://codeberg.org/khinsen/hyperdoc"
    :source-control (:git "https://codeberg.org/khinsen/hyperdoc.git")
    :serial t
    :depends-on (#:hyperdoc
                 #:hyperdoc/scxml
                 #:hyperdoc/scxml-workflows
                 #:hyperdoc/dmx-import
                 #:hyperdoc/fedwiki
                 #:hyperdoc/bibliography
                 #:hyperdoc/zotero
                 #:hyperbook/server
                 #:hyperbook/wikipedia
                 #:html-inspector-views
                 #:html-inspector-views/reactive
                 #:clog-moldable-inspector
                 #:trivial-package-local-nicknames)
    :components ((:module "hyperdoc-inspector"
                          :serial t
                          :components ((:file "package")
                             (:file "decision-maps")
                                       (:file "code-path-graphs")
                                       (:file "whyline-output-questions")
                                       (:file "state-machines")
                                       (:file "authored-relation-artifacts")
                                       (:file "shared-projection-ir")
                                       (:file "topicmap-views")
                                       (:file "s-expression-prompt-views")
                                       (:file "topic-files-topicmap")
                                       (:file "surfaces")
                                       (:file "lisp-critic-review-plan-views")
                                       (:file "lisp-critic-contract-views")
                                       (:file "boundaries")
                                       (:file "scxml-runs")
                                       (:file "scxml-architect")
                                       (:file "dmx-topics")
                                       (:file "dmx-query-views")
                                       (:file "neo4j-topic-delete-tool-operations")
                                       (:file "bibliography-subcollections")
                                       (:file "topic-enrichment")
                                       (:file "fedwiki-materialization")
                                       (:file "fedwiki-attached-asdf-system")
                             (:file "fedwiki-story-item-rendering-demo")
                                       (:file "playground-debug")
                                       (:file "web-debugger")
                                       (:file "playground-eval")
                                       (:file "snippet-playground-authored-source")
                                       (:file "snippet-playground")
                                       (:file "inspector")))))

(defsystem #:hyperdoc/inspector/zotero
    :description "Zotero-backed inspector views for HyperDoc"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license  "BSD"
    :version "0.0.1"
    :homepage "https://codeberg.org/rgb/hyperdoc"
    :source-control (:git "https://codeberg.org/rgb/hyperdoc.git")
    :serial t
    :depends-on (#:hyperdoc/inspector
                 #:hyperdoc/zotero)
    :components ((:module "hyperdoc-inspector"
                          :serial t
                          :components ((:file "zotero-bridge")
                                       (:file "bibliography-zotero")))))

(defsystem #:hyperdoc/explorer
    :description "Explorer for HyperDocs"
    :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
    :license  "BSD"
    :version "0.0.1"
    :homepage "https://codeberg.org/khinsen/hyperdoc"
    :source-control (:git "https://codeberg.org/khinsen/hyperdoc.git")
    :serial t
    :depends-on (#:hyperdoc
                 #:hyperdoc/inspector
                 #:hyperdoc/fedwiki
                 #:hyperdoc/zotero
                 #:hyperbook/explorer
                 #:hyperbook/fedwiki
                 #:html-inspector-views
                 #:html-inspector-views/standard
                 #:cl-who
                 #:shasht
                 #:alexandria
                 #:arrow-macros
                 #:njson/jzon
                 #:plump
                 #:plump-inspector-views
                 #:puri
                 #:3bmd
                 #:trivial-package-local-nicknames
                 #:asdf #:uiop)
    :components ((:module "hyperdoc-explorer"
                          :serial t
                          :components ((:file "package")
                                       (:file "links")
                                       (:file "source-surfaces")
                                       (:file "explorer")
                                       (:file "layout-topicmap")
                                       (:file "static-route-observability")
                                       (:file "operational-targets")
                                       (:file "neo4j-duplicate-username-repair")
                                       (:file "git-relations")
                                       (:file "git-commit-equivalence")
                                       (:file "packages")
                                       (:file "parse-expr")
                                       (:file "lookup-repairs")
                                       (:file "page-lookup-issue-artifacts")
                                       (:file "runtime-incidents")
                                       (:file "dom-annotations")
                                       (:file "dock")
                                       (:file "page-systems")
                                       (:file "source-pane-layout")
                                       (:file "html-pages")
                                       (:file "markdown-pages")
                                       (:file "../hyperdoc/dm6-page-topicmap")
                                       (:file "code-pages")
                                       (:file "topics")
                                       (:file "links-in-code")
                                       (:file "localhost-fedwiki-page-promotion-plans")
                                       (:file "tools")
                                       (:file "codemeta")
                             (:file "dm6-elm-artifact-inspector")
                                       (:file "example-core")
                                       (:file "check-runner")
                                       (:file "hyperdoc")
                                       (:file "page-lookup-rebuild-gate")))))

(defsystem #:hyperdoc/codex/explorer
    :description "Explorer views for the Codex collaboration home topic"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license "BSD"
    :version "0.0.1"
    :serial t
    :depends-on (#:hyperdoc/codex
                 #:hyperdoc/explorer)
    :components ((:module "hyperdoc-explorer"
                  :serial t
                  :components ((:file "codex")))))

(defsystem #:hyperdoc/explorer/examples/ops
    :description "Explorer views for HyperDoc ops/local examples"
    :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
    :license  "BSD"
    :version "0.0.1"
    :homepage "https://codeberg.org/khinsen/hyperdoc"
    :source-control (:git "https://codeberg.org/khinsen/hyperdoc.git")
    :serial t
    :depends-on (#:hyperdoc/explorer
                 #:hyperdoc/examples/ops)
    :components ((:module "hyperdoc-explorer"
                          :serial t
                          :components ((:file "examples")))))

;; Compatibility alias: runtime server implementation lives in hyperbook/server.
(defsystem #:hyperdoc/server
    :depends-on (#:hyperbook/server
                 #:hyperbook/explorer
                 #:hyperdoc/examples
                 #:hyperdoc/nor-demo
                 #:hyperdoc/nor-graph-demo
                 #:hyperdoc/closures-nor-demo
                 #:hyperdoc/continuation-route-trace
                 #:hyperdoc/explorer
                 #:hyperdoc/explorer/examples/ops
                 #:html-inspector-views/standard)
    :components ((:module "hyperdoc"
                          :serial t
                          :components ((:file "server-runtime")))))

(defsystem #:hyperdoc/tests
    :description "Smoke tests for HyperDoc"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license "BSD"
    :version "0.0.1"
    :serial t
    :depends-on (#:hyperdoc/mcp
                 #:hyperdoc/fedwiki-asdf-assets
                 #:hyperdoc/mobile-progressive-chrome
                 #:hyperdoc/scxml
                 #:hyperdoc/explorer
                 #:kioskbeerli
                 #:hyperdoc/nor-graph-demo
                 #:hyperdoc/closures-nor-demo
                 #:hyperdoc/continuation-route-trace
                 #:interaction-net)
    :components ((:module "tests"
                          :serial t
                          :components ((:file "package")
                                       (:file "compile-order-smoke")
                                       (:file "dmx-topic-proxy-smoke")
                                       (:file "code-path-graphs-smoke")
                                       (:file "whyline-output-questions-smoke")
                                       (:file "state-machine-smoke")
                                       (:file "shared-projection-ir-smoke")
                                       (:file "snippet-playground-artifact-smoke")
                                       (:file "authored-relation-artifact-pattern-smoke")
                                       (:file "surface-smoke")
                                       (:file "boundary-smoke")
                                       (:file "relation-topic-proposals-smoke")
                                       (:file "lisp-critic-review-plan-smoke")
                                       (:file "lisp-critic-contract-smoke")
                                       (:file "dock-presentation-smoke")
                                       (:file "dock-annotation-smoke")
                                       (:file "mobile-progressive-chrome-smoke")
                                       (:file "reel-accessible-carousel-smoke")
                                       (:file "layout-topicmap-smoke")
                                       (:file "page-system-smoke")
                                       (:file "dmx-annotations-smoke")
                                       (:file "dmx-workspace-journal-sink-smoke")
                                       (:file "dmx-auth-session-boundary-smoke")
                                       (:file "dmx-annotation-936040-regression-smoke")
                                       (:file "sly-evidence-bounds-smoke")
                                       (:file "dmx-workspace-assignment-auth-diagnosis-smoke")
                                       (:file "dmx-platform-workspace-assignment-semantics-smoke")
                                       (:file "zotero-optional-smoke")
                                       (:file "article-allegation-slice-smoke")
                                       (:file "fedwiki-materialization-smoke")
                                       (:file "authored-html-render-safety-smoke")
                                       (:file "lookup-issue-docs-render-smoke")
                                       (:file "page-lookup-issues-smoke")
                                       (:file "page-lookup-disconnection-smoke")
                                       (:file "function-lookup-issues-smoke")
                                       (:file "class-lookup-issues-smoke")
                                       (:file "collective-knowledge-slice-smoke")
                                       (:file "reproducible-devenv-as-knowledge-artifact-slice-smoke")
                                       (:file "localhost-fedwiki-page-pipeline-smoke")
                                       (:file "localhost-fedwiki-page-promotion-plans-smoke")
                                       (:file "localhost-fedwiki-page-promotion-workflow-scxml-smoke")
                                       (:file "topic-factory-snippet-dmx-smoke")
                                       (:file "hyperdoc-test-system-runbook-smoke")
                                       (:file "dmx-annotation-acceptance-scxml-runbook-smoke")
                                       (:file "dmx-mcp-smoke")
                                       (:file "dmx-incident-arc-smoke")
                                       (:file "dmx-shared-workspace-docs-smoke")
                                       (:file "dm6-page-topicmap-smoke")
                                       (:file "topicmap-view-smoke")
                                       (:file "topic-files-topicmap-smoke")
                                       (:file "s-expression-prompt-smoke")
                                       (:file "fedwiki-asdf-assets-smoke")
                                       (:file "fedwiki-attached-asdf-system-smoke")
                                       (:file "dmx-query-layer-smoke")
                                       (:file "neo4j-duplicate-username-repair-smoke")
                                       (:file "hyperdoc-neo4j-topic-delete-tool-operation-ir-smoke")
                                       (:file "fedwiki-site-dmx-import")
                                       (:file "check-runner-smoke")
                                       (:file "fedwiki-story-items-smoke")
                                       (:file "view-contract-smoke")
                                       (:file "inspector-performance-smoke")
                                       (:file "merged-doc-slices-smoke")
                                       (:file "iconic-retrieval-smoke")
                                       (:file "git-commit-assimilation-smoke")
                                       (:file "skillization-smoke")
                                       (:file "mech-deployment-provenance-smoke")
                                       (:file "kioskbeerli-dashboard-smoke")
                                       (:file "kioskbeerli-dmx-associative-mirror-smoke")
                                       (:file "py4dmx-cluster-smoke")
                                       (:file "scxml-compiler-smoke")
                                       (:file "runtime-coherence-smoke")
                                       (:file "running-image-coherence-rebuild-smoke")
                                       (:file "page-lookup-topic-repair-scxml-smoke")
                                       (:file "interaction-net-smoke")
                                       (:file "closure-nor-demo-smoke")
                                       (:file "nor-graph-matcher-smoke")
                                       (:file "continuation-route-trace-smoke")
                                       (:file "test-runner"))))
    :perform (test-op (op c)
                      (declare (ignore op c))
                      (uiop:symbol-call :hyperdoc/tests
                                        :run-hyperdoc-tests)))

(defsystem #:hyperdoc/tests/zotero
    :description "Zotero-backed smoke tests for HyperDoc"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license  "BSD"
    :version "0.0.1"
    :serial t
    :depends-on (#:hyperdoc/tests
                 #:hyperdoc/inspector/zotero)
    :components ((:module "tests"
                          :serial t
                          :components ((:file "zotero-bridge-smoke")
                                       (:file "bibliography-subcollections-smoke")
                                       (:file "topic-enrichment-smoke")
                                       (:file "zotero-suite"))))
    :perform (test-op (op c)
                      (declare (ignore op c))
                      (uiop:symbol-call :hyperdoc/tests
                                        :run-hyperdoc-zotero-tests)))


(defsystem #:hyperdoc/git
  :description "Git-backed inspection objects for HyperDoc"
  :author "Ralf Barkow <ralf.barkow@me.com>"
  :license "BSD"
  :version "0.0.1"
  :homepage "https://codeberg.org/khinsen/hyperdoc"
  :source-control (:git "https://codeberg.org/rgb/hyperdoc.git")
  :serial t
  :depends-on (#:hyperdoc
               #:uiop)
  :components ((:module "hyperdoc"
                :serial t
                :components ((:file "git-repository-checkout")
                             (:file "git-commit-inspection")))))

(defsystem #:hyperdoc/inspector/git
  :description "Inspector views for Git-backed HyperDoc objects"
  :author "Ralf Barkow <ralf.barkow@me.com>"
  :license "BSD"
  :version "0.0.1"
  :homepage "https://codeberg.org/khinsen/hyperdoc"
  :source-control (:git "https://codeberg.org/rgb/hyperdoc.git")
  :serial t
  :depends-on (#:hyperdoc/git
               #:hyperdoc/inspector
               #:html-inspector-views)
  :components ((:module "hyperdoc-inspector"
                :serial t
                :components ((:file "git-commit-inspection-views")))))
