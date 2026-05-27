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

(asdf:defsystem #:kioskbeerli/sops-nix-secrets
  :description "Inspectable plan-only Kioskbeerli sops-nix secrets milestone subsystem."
  :author "Ralf Barkow"
  :license "BSD"
  :version "0.1.0"
  :serial t
  :depends-on (#:kioskbeerli
               #:hyperdoc/shop3
               #:hyperdoc/scxml
               #:html-inspector-views)
  :in-order-to ((asdf:test-op (asdf:test-op "kioskbeerli/sops-nix-secrets/tests")))
  :components
  ((:module "kioskbeerli/sops-nix-secrets"
    :serial t
    :components
    ((:file "package")
     (:file "plan-objects")
     (:file "commands")
     (:file "guards")
     (:file "domain")
     (:file "task-topics")
     (:file "topics")
     (:file "scxml")
     (:file "problem")
     (:file "views")
     (:static-file "sops-nix-secrets.scxml")))))

(asdf:defsystem #:kioskbeerli/sops-nix-secrets/tests
  :description "Smoke tests for the Kioskbeerli sops-nix secrets planning subsystem."
  :author "Ralf Barkow"
  :license "BSD"
  :version "0.1.0"
  :serial t
  :depends-on (#:kioskbeerli/sops-nix-secrets)
  :components
  ((:module "kioskbeerli/sops-nix-secrets/tests"
    :serial t
    :components
    ((:file "package")
     (:file "smoke"))))
  :perform (asdf:test-op (op system)
             (declare (ignore op system))
             (uiop:symbol-call :kioskbeerli/sops-nix-secrets/tests
                               :run-sops-nix-secrets-smoke-tests)))

(asdf:defsystem #:kioskbeerli/pi-simulation
  :description "Inspectable plan-only Kioskbeerli Pi simulation subsystem."
  :author "Ralf Barkow"
  :license "BSD"
  :version "0.1.0"
  :serial t
  :depends-on (#:kioskbeerli
               #:hyperdoc/shop3
               #:hyperdoc/scxml
               #:html-inspector-views)
  :in-order-to ((asdf:test-op (asdf:test-op "kioskbeerli/pi-simulation/tests")))
  :components
  ((:module "kioskbeerli/pi-simulation"
    :serial t
    :components
    ((:file "package")
     (:file "plan-objects")
     (:file "commands")
     (:file "topics")
     (:file "scxml")
     (:file "views")
     (:static-file "kioskbeerli-pi-simulation.scxml")))))

(asdf:defsystem #:kioskbeerli/pi-simulation/tests
  :description "Smoke tests for the Kioskbeerli Pi simulation planning subsystem."
  :author "Ralf Barkow"
  :license "BSD"
  :version "0.1.0"
  :serial t
  :depends-on (#:kioskbeerli/pi-simulation)
  :components
  ((:module "kioskbeerli/pi-simulation/tests"
    :serial t
    :components
    ((:file "package")
     (:file "smoke"))))
  :perform (asdf:test-op (op system)
             (declare (ignore op system))
             (uiop:symbol-call :kioskbeerli/pi-simulation/tests
                               :run-pi-simulation-smoke-tests)))

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
