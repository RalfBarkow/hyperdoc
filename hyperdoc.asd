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

(defsystem #:hyperdoc/inspector
  :description "HyperDoc for the moldable inspector"
  :author "Konrad Hinsen <konrad.hinsen@fastmail.net>"
  :license  "BSD"
  :version "0.0.1"
  :homepage "https://codeberg.org/khinsen/hyperdoc"
  :source-control (:git "https://codeberg.org/khinsen/hyperdoc.git")
  :serial t
  :depends-on (#:hyperdoc
               #:hyperbook/wikipedia
               #:html-inspector-views
               #:clog-moldable-inspector
               #:trivial-package-local-nicknames)
  :components ((:module "inspector-hyperdoc"
                :serial t
                :components ((:file "package")
                             (:file "hyperdoc")))))

(defsystem #:hyperdoc/git
  :description "Git-backed inspection objects for HyperDoc"
  :author "Ralf Barkow <ralf.barkow@me.com>"
  :license "BSD"
  :version "0.0.1"
  :homepage "https://codeberg.org/khinsen/hyperdoc"
  :source-control (:git "https://codeberg.org/rgb/hyperdoc.git")
  :serial t
  :depends-on (#:hyperdoc
               #:uiop)
  :components ((:module "hyperdoc"
                :serial t
                :components ((:file "git-repository-checkout")
                             (:file "git-commit-inspection"))))
  :in-order-to ((test-op (test-op "hyperdoc/git/tests"))))

(defsystem #:hyperdoc/inspector/git
  :description "Inspector views for Git-backed HyperDoc objects"
  :author "Ralf Barkow <ralf.barkow@me.com>"
  :license "BSD"
  :version "0.0.1"
  :homepage "https://codeberg.org/khinsen/hyperdoc"
  :source-control (:git "https://codeberg.org/rgb/hyperdoc.git")
  :serial t
  :depends-on (#:hyperdoc/git
               #:hyperdoc/inspector
               #:html-inspector-views)
  :components ((:module "hyperdoc-inspector"
                :serial t
                :components ((:file "git-commit-inspection-views")))))

(defsystem #:hyperdoc/git/tests
  :description "Stable local-fixture tests for Git-backed HyperDoc objects"
  :author "Ralf Barkow <ralf.barkow@me.com>"
  :license "BSD"
  :version "0.0.1"
  :serial t
  :depends-on (#:hyperdoc/inspector/git)
  :components ((:module "tests"
                :serial t
                :components ((:file "git-commit-inspection-smoke"))))
  :perform (test-op (op c)
             (declare (ignore op c))
             (uiop:symbol-call :hyperdoc/git/tests
                               :run-git-commit-inspection-smoke-tests)))

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
