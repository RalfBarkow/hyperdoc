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
    :description "Compatibility alias for the canonical kioskberrli system"
    :author "Ralf Barkow"
    :license "BSD"
    :version "0.0.1"
    :serial t
    :depends-on (#:kioskberrli)
    :in-order-to ((test-op (test-op "dreyeck/kioskbeerli/tests"))))

(defsystem #:dreyeck/kioskbeerli/tests
    :description "Compatibility alias for the canonical Kioskberrli smoke tests"
    :author "Ralf Barkow"
    :license "BSD"
    :version "0.0.1"
    :serial t
    :depends-on (#:kioskberrli/tests)
    :perform (test-op (op c)
                      (declare (ignore op c))
                      (uiop:symbol-call :kioskberrli/tests
                                        :run-kioskberrli-smoke-tests)))

(defsystem #:dreyeck
    :description "Minimal downstream dreyeck scaffold"
    :depends-on (#:dreyeck/server
                 #:dreyeck/kioskbeerli))
