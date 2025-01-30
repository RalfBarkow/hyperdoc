;;;; System definitions
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(defsystem #:hyperdoc
  :description "Hypertext documentation system"
  :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
  :license  "BSD"
  :version "0.0.1"
  :serial t
  :depends-on (#:html-inspector-views
               #:html-inspector-views/standard
               #:arrow-macros
               #:common-doc
               #:common-html
               #:scriba
               #:common-doc-inspector-views
               #:fset
               #:uiop)
  :components ((:module "hyperdoc"
                :serial t
                :components ((:file "package")
                             (:file "hyperdoc")
                             (:file "in-package")
                             (:file "object-refs")
                             (:file "page-refs")
                             (:file "hyperdoc-refs")
                             (:file "inline-computations")
                             (:file "catalog")
                             (:file "hyperdoc-hyperdoc")))))
