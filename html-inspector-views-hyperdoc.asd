;;;; System definitions
;;
;;;; Copyright (c) 2024 Konrad Hinsen <konrad.hinsen@fastmail.net>

(defsystem #:html-inspector-views-hyperdoc
  :description "Hypertext documentation add-on for HTML inspector views"
  :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
  :license  "BSD"
  :version "0.0.1"
  :serial t
  :depends-on (#:html-inspector-views
               #:arrow-macros
               #:common-doc
               #:common-html
               #:scriba
               #:common-doc-inspector-views)
  :components ((:file "package")
               (:file "hyperdoc")))
