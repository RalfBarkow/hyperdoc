;;;; Canonical ASDF systems for Kioskberrli.

(asdf:defsystem #:kioskberrli
  :description "Kioskberrli dashboard, planner, trace, SCXML, FedWiki assets, inspector views, and optional SQLite store."
  :author "Ralf Barkow"
  :license "BSD"
  :version "0.1.0"
  :serial t
  :depends-on (#:hyperdoc
               #:hyperdoc/topics
               #:hyperdoc/shop3
               #:hyperdoc/scxml
               #:hyperdoc/scxml-workflows
               #:hyperdoc/fedwiki-asdf-assets
               #:html-inspector-views)
  :in-order-to ((asdf:test-op (asdf:test-op "kioskberrli/tests")))
  :components
  ((:module "kioskberrli"
    :serial t
    :components
    ((:file "package")
     (:file "dashboard")
     (:file "topics")
     (:file "planner")
     (:file "behavior")
     (:file "trace")
     (:file "examples")
     (:file "task-topics")
     (:file "sqlite-store")
     (:file "fedwiki-assets")
     (:file "core")
     (:file "views")
     (:static-file "kioskberrli.scxml")
     (:static-file "README.md")))))

(asdf:defsystem #:kioskberrli/tests
  :description "Smoke tests for the canonical Kioskberrli system."
  :author "Ralf Barkow"
  :license "BSD"
  :version "0.1.0"
  :serial t
  :depends-on (#:kioskberrli)
  :components
  ((:module "kioskberrli/tests"
    :serial t
    :components
    ((:file "package")
     (:file "smoke"))))
  :perform (asdf:test-op (op system)
             (declare (ignore op system))
             (uiop:symbol-call :kioskberrli/tests
                               :run-kioskberrli-smoke-tests)))
