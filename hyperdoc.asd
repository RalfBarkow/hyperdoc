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
                             (:file "topicmap")
                             (:file "links-in-code")
                             (:file "defining")
                             (:file "examples")
                             (:file "tools")
                             (:file "hyperdoc")))))

(defsystem #:hyperdoc/inspector
  :description "HyperDoc for the moldable inspector"
  :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
  :license  "BSD"
  :version "0.0.1"
  :homepage "https://codeberg.org/khinsen/hyperdoc"
  :source-control (:git "https://codeberg.org/khinsen/hyperdoc.git")
  :serial t
  :in-order-to
  ((asdf:test-op
    (asdf:test-op "hyperdoc/inspector/tests")))
  :depends-on (#:hyperdoc
               #:hyperbook/wikipedia
               #:html-inspector-views
               #:clog-moldable-inspector
               #:trivial-package-local-nicknames)
  :components ((:module "inspector-hyperdoc"
                :serial t
                :components ((:file "package")
                             (:file "hyperspec")
                             (:file "topicmap")
                             (:file "hyperdoc")))))

(defsystem #:hyperdoc/inspector/tests
  :description "Tests for HyperDoc inspector adaptations"
  :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
  :license "BSD"
  :version "0.0.1"
  :pathname "tests/"
  :serial t
  :depends-on (#:hyperdoc/inspector
               #:hyperbook/server
               #:clack-handler-hunchentoot
               #:usocket)
  :components ((:file "local-hyperspec")
               (:file "topicmap-view-smoke"))
  :perform
  (asdf:test-op
   (operation component)
   (declare (ignore operation component))
   (uiop:symbol-call
    :hyperdoc/inspector/tests
    :run-local-hyperspec-tests)
   (uiop:symbol-call
    :hyperdoc/inspector/topicmap-tests
    :run-topicmap-view-smoke-tests)))

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
