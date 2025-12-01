;;;; system definitions
;;
;;;; copyright (c) 2025 konrad hinsen <konrad.hinsen@fastmail.net>

(defsystem #:hyperdoc
  :description "hypertext documentation system"
  :author "konrad hinsen <konrad.hinsen@fastmail.net>"
  :license  "bsd"
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
                             (:file "abstract-interface")
                             (:file "catalog")
                             (:file "core")
                             (:file "links-in-code")
                             (:file "defining")
                             (:file "examples")
                             (:file "tools")
                             (:file "hyperdoc")))))


(defsystem #:hyperdoc/wikipedia
  :description "hyperdoc interface to wikipedia"
  :author "konrad hinsen <konrad.hinsen@fastmail.net>"
  :license  "bsd"
  :version "0.0.1"
  :homepage "https://codeberg.org/khinsen/hyperdoc"
  :source-control (:git "https://codeberg.org/khinsen/hyperdoc.git")
  :serial t
  :depends-on (#:hyperdoc
               #:html-inspector-views
               #:plump-inspector-views
               #:trivial-package-local-nicknames
               #:alexandria
               #:arrow-macros
               #:str)
  :components ((:module "hyperdoc-wikipedia"
                :serial t
                :components ((:file "package")
                             (:file "wikipedia")))))

(defsystem #:hyperdoc/inspector
  :description "HyperDoc for the moldable inspector"
  :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
  :license  "BSD"
  :version "0.0.1"
  :homepage "https://codeberg.org/khinsen/hyperdoc"
  :source-control (:git "https://codeberg.org/khinsen/hyperdoc.git")
  :serial t
  :depends-on (#:hyperdoc
               #:hyperdoc/wikipedia
               #:html-inspector-views
               #:clog-moldable-inspector
               #:trivial-package-local-nicknames)
  :components ((:module "inspector-hyperdoc"
                :serial t
                :components ((:file "package")
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
               #:hyperdoc/inspector
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
                :components ((:file "import")
                             (:file "links")
                             (:file "explorer")
                             (:file "packages")
                             (:file "catalog")
                             (:file "parse-expr")
                             (:file "html-pages")
                             (:file "markdown-pages")
                             (:file "code-pages")
                             (:file "links-in-code")
                             (:file "tools")
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
