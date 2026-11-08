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
               #:asdf #:uiop
               #:trivial-package-local-nicknames)
  :components ((:module "hyperdoc"
                :serial t
                :components ((:file "package")
                             (:file "core")
                             (:file "links-in-code")
                             (:file "defining")
                             (:file "examples")
                             (:file "tools")
                             (:file "hyperdoc")))))

(defsystem #:hyperdoc/inspector :description
           "HyperDoc for the moldable inspector" :author
           "Konrad Hinsen <konrad.hinsen@fastmail.net>" :license "BSD" :version
           "0.0.1" :homepage "https://codeberg.org/khinsen/hyperdoc"
           :source-control (:git "https://codeberg.org/khinsen/hyperdoc.git")
           :serial t :depends-on
           (#:hyperdoc #:hyperbook/wikipedia #:html-inspector-views
                       #:clog-moldable-inspector
                       #:trivial-package-local-nicknames)
           :components
           ((:module "inspector-hyperdoc" :serial t :components
                     ((:file "package") (:file "hyperdoc")))))



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
                             (:file "packages")
                             (:file "parse-expr")
                             (:file "html-pages")
                             (:file "markdown-pages")
                             (:file "code-pages")
                             (:file "links-in-code")
                             (:file "tools")
                             (:file "codemeta")
                             (:file "examples")
                             (:file "hyperdoc")))))

;; Opt-in DMX application. No Catalog, Inspector, FedWiki or ISO Topic Maps dependency.
(defsystem #:hyperdoc/dmx-import
  :description "Required guarded DMX runtime for the independent MCP application"
  :license "BSD" :serial t
  :depends-on (#:hyperdoc #:babel #:cl-ppcre #:drakma #:shasht)
  :components ((:module "dmx-mcp" :serial t
                :components ((:file "models") (:file "dmx-import")
                             (:file "topic-factory-snippet-dmx")
                             (:file "dmx-workspace-topics")
                             (:file "dmx-workspace-journal")
                             (:file "dmx-workspace-notes")
                             (:file "dmx-annotations")))))

(defsystem #:hyperdoc/mcp
  :description "Independent DMX Streamable HTTP MCP server"
  :license "BSD" :serial t
  :depends-on (#:hyperdoc/dmx-import #:hunchentoot)
  :components ((:module "dmx-mcp" :serial t
                :components ((:file "mcp-server")))))
