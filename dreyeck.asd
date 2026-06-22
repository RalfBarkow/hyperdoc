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
    :description "Minimal downstream dreyeck scaffold"
    :depends-on (#:dreyeck/server))

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
