;;;; Canonical ASDF systems for Kioskbeerli.

(asdf:defsystem #:kioskbeerli
  :description "Kioskbeerli dashboard, planner, trace, SCXML, FedWiki assets, inspector views, and optional SQLite store."
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
  :in-order-to ((asdf:test-op (asdf:test-op "kioskbeerli/tests")))
  :components
  ((:module "kioskbeerli"
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
     (:file "dmx-associative-mirror")
     (:file "dmx-sql-topicmap")
     (:file "dmx-sql-topicmap-hyperdoc")
     (:file "fedwiki-assets")
     (:file "core")
     (:file "views")
     (:static-file "kioskbeerli.scxml")
     (:static-file "README.md")))))

(asdf:defsystem #:kioskbeerli/tests
  :description "Smoke tests for the canonical Kioskbeerli system."
  :author "Ralf Barkow"
  :license "BSD"
  :version "0.1.0"
  :serial t
  :depends-on (#:kioskbeerli)
  :components
  ((:module "kioskbeerli/tests"
    :serial t
    :components
    ((:file "package")
     (:file "smoke"))))
  :perform (asdf:test-op (op system)
             (declare (ignore op system))
             (uiop:symbol-call :kioskbeerli/tests
                               :run-kioskbeerli-smoke-tests)))
