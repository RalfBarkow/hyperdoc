;;;; System definitions for HyperDoc
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(defsystem #:hyperdoc
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
               #:drakma
               #:shasht
               #:asdf #:uiop
               #:trivial-package-local-nicknames)
  :in-order-to ((test-op (test-op "hyperdoc/tests")))
                :components ((:module "hyperdoc"
                :serial t
                :components ((:file "package")
                             (:file "core")
                             (:file "localhost-fedwiki-page-pipeline")
                             (:file "collective-knowledge-slice")
                             (:file "reproducible-devenv-as-knowledge-artifact-slice")
                             (:file "localhost-fedwiki-page-promotion-plans")
                             (:file "code-path-graphs")
                             (:file "topics")
                             (:file "page-lookup-chunks")
                             (:file "state-machines")
                             (:file "surfaces")
                             (:file "boundaries")
                             (:file "links-in-code")
                             (:file "defining")
                             (:file "check-runner")
                             (:file "example-core")
                             (:file "journal-gate")
                             (:file "validation")
                             (:file "article-allegation-slice")
                             (:file "fedwiki-materialization")
                             (:file "tools")
                             (:file "zotero-support")
                             (:file "bibliography-subcollections")
                             (:file "topic-enrichment-route-data")
                             (:file "topic-enrichment")
                             (:file "static-route-observability")
                             (:file "operational-targets")
                             (:file "neo4j-duplicate-username-repair")
                             (:file "dom-annotations")
                             (:file "dock")
                             (:file "source-pane-layout")
                             (:file "git-relations")
                             (:file "relation-topic-proposals")
                             (:file "git-commit-equivalence")
                             (:file "hyperdoc")))))

(defsystem #:hyperdoc/zotero
  :description "Optional Zotero backend for HyperDoc"
  :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
  :license  "BSD"
  :version "0.0.1"
  :homepage "https://codeberg.org/khinsen/hyperdoc"
  :source-control (:git "https://codeberg.org/khinsen/hyperdoc.git")
  :serial t
  :depends-on (#:hyperdoc)
  :components ((:module "hyperdoc"
                :serial t
                :components ((:file "zotero-bridge")
                             (:file "bibliography-zotero")
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

(defsystem #:hyperdoc/dmx-import
  :description "FedWiki to DMX import support for HyperDoc"
  :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
  :license  "BSD"
  :version "0.0.1"
  :homepage "https://codeberg.org/khinsen/hyperdoc"
  :source-control (:git "https://codeberg.org/khinsen/hyperdoc.git")
  :serial t
  :depends-on (#:hyperdoc
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
                             (:file "dmx-workspace-notes")
                             (:file "dmx-annotations")
                             (:file "dmx-workspace-topics")
                             (:file "dmx-workspace-journal")))))

(defsystem #:hyperdoc/mcp
  :description "Streamable HTTP MCP server for the DMX shared workspace"
  :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
  :license  "BSD"
  :version "0.0.1"
  :homepage "https://codeberg.org/khinsen/hyperdoc"
  :source-control (:git "https://codeberg.org/khinsen/hyperdoc.git")
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
               #:hyperdoc/dmx-import
               #:hyperbook/server
               #:hyperbook/wikipedia
               #:html-inspector-views
               #:html-inspector-views/reactive
               #:clog-moldable-inspector
               #:trivial-package-local-nicknames)
                :components ((:module "hyperdoc-inspector"
                :serial t
                :components ((:file "package")
                             (:file "code-path-graphs")
                             (:file "state-machines")
                             (:file "surfaces")
                             (:file "boundaries")
                             (:file "dmx-topics")
                             (:file "bibliography-subcollections")
                             (:file "topic-enrichment")
                             (:file "fedwiki-materialization")
                             (:file "playground-debug")
                             (:file "web-debugger")
                             (:file "playground-eval")
                             (:file "inspector")))))

(defsystem #:hyperdoc/inspector/zotero
  :description "Zotero-backed inspector views for HyperDoc"
  :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
  :license  "BSD"
  :version "0.0.1"
  :homepage "https://codeberg.org/khinsen/hyperdoc"
  :source-control (:git "https://codeberg.org/khinsen/hyperdoc.git")
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
               #:hyperbook/explorer
               #:hyperbook/fedwiki
               #:html-inspector-views
               #:html-inspector-views/standard
               #:cl-who
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
                             (:file "static-route-observability")
                             (:file "operational-targets")
                             (:file "neo4j-duplicate-username-repair")
                             (:file "git-relations")
                             (:file "git-commit-equivalence")
                             (:file "packages")
                             (:file "parse-expr")
                             (:file "lookup-repairs")
                             (:file "dom-annotations")
                             (:file "dock")
                             (:file "source-pane-layout")
                             (:file "html-pages")
                             (:file "markdown-pages")
                             (:file "code-pages")
                             (:file "topics")
                             (:file "topic-enrichment")
                             (:file "links-in-code")
                             (:file "localhost-fedwiki-page-promotion-plans")
                             (:file "tools")
                             (:file "codemeta")
                             (:file "example-core")
                             (:file "check-runner")
                             (:file "hyperdoc")))))

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
               #:hyperdoc/explorer)
  :components ((:module "tests"
                :serial t
                :components ((:file "package")
                             (:file "compile-order-smoke")
                             (:file "dmx-topic-proxy-smoke")
                             (:file "code-path-graphs-smoke")
                             (:file "state-machine-smoke")
                             (:file "surface-smoke")
                             (:file "boundary-smoke")
                             (:file "relation-topic-proposals-smoke")
                             (:file "dock-presentation-smoke")
                             (:file "dock-annotation-smoke")
                             (:file "dmx-annotations-smoke")
                             (:file "zotero-optional-smoke")
                             (:file "article-allegation-slice-smoke")
                             (:file "fedwiki-materialization-smoke")
                             (:file "authored-html-render-safety-smoke")
                             (:file "lookup-issue-docs-render-smoke")
                             (:file "page-lookup-issues-smoke")
                             (:file "function-lookup-issues-smoke")
                             (:file "collective-knowledge-slice-smoke")
                             (:file "reproducible-devenv-as-knowledge-artifact-slice-smoke")
                             (:file "localhost-fedwiki-page-pipeline-smoke")
                             (:file "localhost-fedwiki-page-promotion-plans-smoke")
                             (:file "topic-factory-snippet-dmx-smoke")
                             (:file "dmx-mcp-smoke")
                             (:file "dmx-incident-arc-smoke")
                             (:file "dmx-shared-workspace-docs-smoke")
                             (:file "neo4j-duplicate-username-repair-smoke")
                             (:file "fedwiki-site-dmx-import")
                             (:file "check-runner-smoke")
                             (:file "fedwiki-story-items-smoke")
                             (:file "inspector-performance-smoke")
                             (:file "merged-doc-slices-smoke")
                             (:file "git-commit-assimilation-smoke")
                             (:file "py4dmx-cluster-smoke")
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
