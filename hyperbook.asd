;;;; System definitions for HyperBook
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(defsystem #:hyperbook
  :description "Hyperbook interface"
  :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
  :license  "BSD"
  :version "0.0.1"
  :homepage "https://codeberg.org/khinsen/hyperdoc"
  :source-control (:git "https://codeberg.org/khinsen/hyperdoc.git")
  :serial t
  :depends-on (#:alexandria
               #:arrow-macros)
  :components ((:module "hyperbook"
                        :serial t
                        :components ((:file "package")
                                     (:file "interface")
                                     (:file "catalog")))))

(defsystem #:hyperbook/wikipedia
  :description "HyperBook interface to Wikipedia"
  :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
  :license  "BSD"
  :version "0.0.1"
  :homepage "https://codeberg.org/khinsen/hyperdoc"
  :source-control (:git "https://codeberg.org/khinsen/hyperdoc.git")
  :serial t
  :depends-on (#:hyperbook
               #:html-inspector-views
               #:plump-inspector-views
               #:trivial-package-local-nicknames
               #:alexandria
               #:arrow-macros
               #:str)
  :components ((:module "hyperbook-wikipedia"
                :serial t
                :components ((:file "package")
                             (:file "wikipedia")))))
