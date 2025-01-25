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
               #:arrow-macros
               #:common-doc
               #:common-html
               #:scriba
               #:vertex
               #:common-doc-inspector-views
               #:uiop)
  :components ((:module "hyperdoc"
                :components ((:file "package")
                             (:file "in-package")
                             (:file "object-refs")
                             (:file "hyperdoc")))))
