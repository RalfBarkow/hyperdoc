;;;; System definitions
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
  :depends-on (#:alexandria
               #:arrow-macros
               #:asdf #:uiop)
  :components ((:module "hyperdoc"
                :serial t
                :components ((:file "package")
                             (:file "errors")
                             (:file "core")
                             (:file "links-in-code")
                             (:file "catalog")
                             (:file "defining")
                             (:file "examples")
                             (:file "hyperdoc")))))

(defsystem #:hyperdoc/explorer
  :description "Explorer for HyperDocs"
  :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
  :license  "BSD"
  :version "0.0.1"
  :homepage "https://codeberg.org/khinsen/hyperdoc"
  :source-control (:git "https://codeberg.org/khinsen/hyperdoc.git")
  :serial t
  :depends-on (#:hyperdoc
               #:html-inspector-views
               #:html-inspector-views/standard
               #:alexandria
               #:arrow-macros
               #:njson/jzon
               #:plump
               #:plump-inspector-views
               #:3bmd
               #:trivial-package-local-nicknames
               #:asdf #:uiop)
  :components ((:module "hyperdoc-explorer"
                :serial t
                :components ((:file "import")
                             (:file "explorer")
                             (:file "packages")
                             (:file "catalog")
                             (:file "parse-expr")
                             (:file "html-pages")
                             (:file "markdown-pages")
                             (:file "links-in-code")
                             (:file "codemeta")
                             (:file "examples")
                             (:file "hyperdoc")))))

(defsystem #:hyperdoc/server
  :description "Web server for HyperDocs"
  :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
  :license  "BSD"
  :version "0.0.1"
  :homepage "https://codeberg.org/khinsen/hyperdoc"
  :source-control (:git "https://codeberg.org/khinsen/hyperdoc.git")
  :serial t
  :depends-on (#:hyperdoc
               #:hyperdoc/explorer
               #:html-inspector-views
               #:babel
               #:clog
               #:clog-moldable-inspector
               #:cl-slug
               #:sha1
               #:trivial-package-local-nicknames)
  :components ((:module "hyperdoc-server"
                :serial t
                :components ((:file "package")
                             (:file "server")
                             (:file "hyperdoc")))))
