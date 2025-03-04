;;;; System definitions
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(defsystem #:hyperdoc
  :description "Hypertext documentation system"
  :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
  :license  "BSD"
  :version "0.0.1"
  :serial t
  :depends-on (#:alexandria
               #:arrow-macros
               #:fset
               #:asdf #:uiop)
  :components ((:module "hyperdoc"
                :serial t
                :components ((:file "package")
                             (:file "core")
                             (:file "links-in-code")
                             (:file "examples")
                             (:file "hyperdoc")))))

(defsystem #:hyperdoc/explorer
  :description "Explorer for HyperDocs"
  :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
  :license  "BSD"
  :version "0.0.1"
  :serial t
  :depends-on (#:hyperdoc
               #:html-inspector-views
               #:html-inspector-views/standard
               #:alexandria
               #:arrow-macros
               #:plump
               #:plump-inspector-views
               #:3bmd
               #:fset
               #:asdf #:uiop)
  :components ((:module "hyperdoc-explorer"
                :serial t
                :components ((:file "import")
                             (:file "explorer")
                             (:file "catalog")
                             (:file "parse-expr")
                             (:file "html-pages")
                             (:file "markdown-pages")
                             (:file "links-in-code")
                             (:file "examples")))))

(defsystem #:hyperdoc/server
  :description "Web server for HyperDocs"
  :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
  :license  "BSD"
  :version "0.0.1"
  :serial t
  :depends-on (#:hyperdoc
               #:hyperdoc/explorer
               #:clog
               #:clog-moldable-inspector)
  :components ((:module "hyperdoc-server"
                :serial t
                :components ((:file "package")
                             (:file "server")))))
