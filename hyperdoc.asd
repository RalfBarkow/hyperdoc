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
                             (:file "topics")
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
                             (:file "static-route-observability")
                             (:file "operational-targets")
                             (:file "dom-annotations")
                             (:file "git-relations")
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
                             (:file "bibliography-zotero")))))

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
               #:cl-ppcre
               #:drakma
               #:shasht
               #:uiop)
  :components ((:module "hyperdoc"
                :serial t
                :components ((:file "dmx-import")))))

(defsystem #:hyperdoc/inspector
  :description "HyperDoc for the moldable inspector"
  :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
  :license  "BSD"
  :version "0.0.1"
  :homepage "https://codeberg.org/khinsen/hyperdoc"
  :source-control (:git "https://codeberg.org/khinsen/hyperdoc.git")
  :serial t
  :depends-on (#:hyperdoc
               #:hyperbook/server
               #:hyperbook/wikipedia
               #:html-inspector-views
               #:clog-moldable-inspector
               #:trivial-package-local-nicknames)
  :components ((:module "hyperdoc-inspector"
                :serial t
                :components ((:file "package")
                             (:file "dmx-topics")
                             (:file "bibliography-subcollections")
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
                             (:file "explorer")
                             (:file "static-route-observability")
                             (:file "operational-targets")
                             (:file "git-relations")
                             (:file "git-commit-equivalence")
                             (:file "packages")
                             (:file "parse-expr")
                             (:file "lookup-repairs")
                             (:file "dom-annotations")
                             (:file "html-pages")
                             (:file "markdown-pages")
                             (:file "code-pages")
                             (:file "topics")
                             (:file "links-in-code")
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
  :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
  :license  "BSD"
  :version "0.0.1"
  :serial t
  :depends-on (#:hyperdoc/dmx-import
               #:hyperdoc/explorer)
  :components ((:module "tests"
                :serial t
                :components ((:file "dmx-topic-proxy-smoke")
                             (:file "zotero-optional-smoke")
                             (:file "article-allegation-slice-smoke")
                             (:file "fedwiki-materialization-smoke")
                             (:file "page-lookup-issues-smoke")
                             (:file "fedwiki-site-dmx-import")
                             (:file "check-runner-smoke")
                             (:file "fedwiki-story-items-smoke")
                             (:file "inspector-performance-smoke")
                             (:file "merged-doc-slices-smoke"))))
  :perform (test-op (op c)
             (declare (ignore op c))
             (uiop:symbol-call :hyperdoc/tests
                               :run-hyperdoc-tests)))

(defsystem #:hyperdoc/tests/zotero
  :description "Zotero-backed smoke tests for HyperDoc"
  :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
  :license  "BSD"
  :version "0.0.1"
  :serial t
  :depends-on (#:hyperdoc/tests
               #:hyperdoc/inspector/zotero)
  :components ((:module "tests"
                :serial t
                :components ((:file "zotero-bridge-smoke")
                             (:file "bibliography-subcollections-smoke")
                             (:file "zotero-suite"))))
  :perform (test-op (op c)
             (declare (ignore op c))
             (uiop:symbol-call :hyperdoc/tests
                               :run-hyperdoc-zotero-tests)))
