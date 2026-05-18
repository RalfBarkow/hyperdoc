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

(defsystem #:dreyeck/kioskbeerli
    :description "Kioskberrli dashboard, planner, state machine, and trace objects for dreyeck"
    :author "Ralf Barkow"
    :license "BSD"
    :version "0.0.1"
    :serial t
    :depends-on (#:hyperdoc
                 #:hyperdoc/topics
                 #:hyperdoc/shop3
                 #:hyperdoc/scxml
                 #:hyperdoc/scxml-workflows)
    :in-order-to ((test-op (test-op "dreyeck/kioskbeerli/tests")))
    :components ((:module "dreyeck/kioskbeerli"
                  :serial t
                  :components ((:file "package")
                               (:file "dashboard")
                               (:file "topics")
                               (:file "planner")
                               (:file "behavior")
                               (:file "trace")
                               (:file "examples")
                               (:file "views")
                               (:static-file "kioskbeerli.scxml")))
                 (:module "hyperdoc"
                  :components ((:static-file "Kioskberrli.html")
                               (:static-file "Kioskberrli Dashboard.html")
                               (:static-file "Kioskberrli Planner and Trace.html")
                               (:static-file "Kioskberrli sdImage imageSize Failure.html")
                               (:static-file "Kioskberrli Cross-Host Build Failure.html")
                               (:static-file "Salon Pi 4 Kiosk Hardening Checklist.html")
                               (:static-file "Runbook - Build and Flash NixOS SD Image for Kioskberrli.html")
                               (:static-file "preflight-checklist-for-raspberry-pi-nixos-sd-images.html")
                               (:static-file "official-tutorial-nixos-sd-image-on-raspberry-pi-4-400.html")
                               (:static-file "two-installation-models-sd-image-vs-classic-installer.html")
                               (:static-file "invariant-boot-partition-must-be-big-enough.html")
                               (:static-file "Prepare the AArch64 image.html")
                               (:static-file "Hauptsache Entry Model.html")))))

(defsystem #:dreyeck/kioskbeerli/tests
    :description "Smoke tests for the Kioskberrli dreyeck subsystem"
    :author "Ralf Barkow"
    :license "BSD"
    :version "0.0.1"
    :serial t
    :depends-on (#:dreyeck/kioskbeerli
                 #:hyperdoc/explorer)
    :components ((:module "tests"
                  :serial t
                  :components ((:file "package")
                               (:file "kioskberrli-dashboard-smoke"))))
    :perform (test-op (op c)
                      (declare (ignore op c))
                      (uiop:symbol-call :hyperdoc/tests
                                        :run-kioskberrli-dashboard-smoke-tests)))

(defsystem #:dreyeck
    :description "Minimal downstream dreyeck scaffold"
    :depends-on (#:dreyeck/server
                 #:dreyeck/kioskbeerli))
