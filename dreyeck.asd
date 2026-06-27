;;;; Minimal dreyeck scaffold systems
;;
;;;; Copyright (c) 2026

(defsystem #:dreyeck/server
    :description "Minimal downstream dreyeck server scaffold"
    :author "Codex"
    :license "BSD"
    :version "0.0.1"
    :serial t
    :depends-on (#:hyperdoc/server)
    :components ((:module "dreyeck"
                          :serial t
                          :components ((:file "package")
                                       (:file "server")))))

(defsystem #:dreyeck
    :description "Downstream Dreyeck collaboration and server scaffold"
    :depends-on (#:dreyeck/server
                 #:dreyeck/codex))

(defsystem #:dreyeck/codex
    :description "Dreyeck-owned Codex collaboration and review surface"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license "BSD"
    :version "0.0.1"
    :serial t
    :depends-on (#:hyperdoc
                 #:dreyeck/build)
    :components ((:module "dreyeck"
                  :serial t
                  :components ((:file "package")
                               (:file "codex")))))

(defsystem #:dreyeck/codex/examples
    :description "Inspectable Dreyeck Codex collaboration examples"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license "BSD"
    :version "0.0.1"
    :serial t
    :depends-on (#:dreyeck/codex)
    :components ((:module "dreyeck"
                  :serial t
                  :components ((:file "codex-examples")))))

(defsystem #:dreyeck/codex/explorer
    :description "Explorer views for the Dreyeck Codex collaboration surface"
    :author "Ralf Barkow <ralf.barkow@me.com>"
    :license "BSD"
    :version "0.0.1"
    :serial t
    :depends-on (#:dreyeck/codex
                 #:hyperdoc/explorer)
    :components ((:module "dreyeck-explorer"
                  :serial t
                  :components ((:file "codex")))))

(defsystem #:dreyeck/dmx/workspace-selection
  :description "Live SHOP3 selection of the Dreyeck DMX SQLite ASDF owner."
  :author "Ralf Barkow"
  :license "BSD"
  :version "0.1.0"
  :serial t
  :depends-on (#:shop3)
  :components
  ((:module "dreyeck/dmx/workspace-selection"
    :serial t
    :components
    ((:file "package")
     (:file "domain")
     (:file "problem")
     (:file "selection")
     (:file "views")))))

(defsystem #:dreyeck/dmx/workspace-selection/tests
  :description "Smoke tests for the live Dreyeck DMX SQLite workspace selection."
  :author "Ralf Barkow"
  :license "BSD"
  :version "0.1.0"
  :serial t
  :depends-on (#:dreyeck/dmx/workspace-selection)
  :components
  ((:module "dreyeck/dmx/workspace-selection/tests"
    :serial t
    :components
    ((:file "package")
     (:file "smoke"))))
  :perform (asdf:test-op (operation component)
             (declare (ignore operation component))
             (uiop:symbol-call :dreyeck.dmx.workspace-selection/tests
                               :run-workspace-selection-smoke-tests)))

(defsystem #:dreyeck/dmx/sqlite
  :description "Dreyeck-owned DMX-shaped SQLite schema, value API, and integrity checks."
  :author "Ralf Barkow"
  :license "BSD"
  :version "0.1.0"
  :serial t
  :in-order-to ((asdf:test-op (asdf:test-op "dreyeck/dmx/sqlite/tests")))
  :components
  ((:module "dreyeck/dmx/sqlite"
    :serial t
    :components
    ((:file "package")
     (:file "store")
     (:file "durable-notes")))))

(defsystem #:dreyeck/dmx/sqlite/tests
  :description "Tests for the Dreyeck-owned DMX-shaped SQLite store."
  :author "Ralf Barkow"
  :license "BSD"
  :version "0.1.0"
  :serial t
  :depends-on (#:dreyeck/dmx/sqlite)
  :components
  ((:module "dreyeck/dmx/sqlite/tests"
    :serial t
    :components
    ((:file "package")
     (:file "smoke"))))
  :perform (asdf:test-op (operation component)
             (declare (ignore operation component))
             (uiop:symbol-call :dreyeck.dmx.sqlite/tests
                               :run-dmx-sqlite-smoke-tests)))

(defsystem #:dreyeck/build
  :description "Reusable Dreyeck build/check tasks for Codex and inspectors."
  :author "Ralf Barkow"
  :license "BSD"
  :version "0.1.0"
  :serial t
  :in-order-to ((asdf:test-op (asdf:test-op "dreyeck/build/tests")))
  :depends-on (#:dreyeck/dmx/sqlite)
  :components
  ((:module "dreyeck/build"
    :serial t
    :components
    ((:file "package")
     (:file "tasks")))))

(defsystem #:dreyeck/build/tests
  :description "Smoke tests for reusable Dreyeck build/check tasks."
  :author "Ralf Barkow"
  :license "BSD"
  :version "0.1.0"
  :serial t
  :depends-on (#:dreyeck/build)
  :components
  ((:module "dreyeck/build/tests"
    :serial t
    :components
    ((:file "package")
     (:file "smoke"))))
  :perform (asdf:test-op (operation component)
             (declare (ignore operation component))
             (uiop:symbol-call :dreyeck/build/tests
                               :run-dreyeck-build-smoke-tests)))
