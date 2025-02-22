;;;; System definitions
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(defsystem #:hyperdoc/core
  :description "Core of the hypertext documentation system"
  :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
  :license  "BSD"
  :version "0.0.1"
  :serial t
  :depends-on (#:alexandria
               #:arrow-macros
               #:fset
               #:uiop)
  :components ((:module "hyperdoc-core"
                :serial t
                :components ((:file "package")
                             (:file "hyperdoc")
                             (:file "catalog")
                             (:file "core-hyperdoc")))))

(defsystem #:hyperdoc
  :description "Hypertext documentation system"
  :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
  :license  "BSD"
  :version "0.0.1"
  :serial t
  :depends-on (#:hyperdoc/core
               #:html-inspector-views
               #:html-inspector-views/standard
               #:alexandria
               #:arrow-macros
               #:common-doc
               #:common-html
               #:scriba
               #:common-doc-inspector-views
               #:plump
               #:plump-inspector-views
               #:3bmd
               #:fset
               #:uiop)
  :components ((:module "hyperdoc"
                :serial t
                :components ((:file "package")
                             (:file "hyperdoc")
                             (:file "commondoc-pages")
                             (:file "html-pages")
                             (:file "markdown-pages")
                             (:file "catalog")
                             (:file "in-package")
                             (:file "object-refs")
                             (:file "page-refs")
                             (:file "hyperdoc-refs")
                             (:file "inline-computations")
                             (:file "transclusions")
                             (:file "source-transclusions")
                             (:file "hyperdoc-hyperdoc")))))
