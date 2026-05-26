;;;; Test package for the Kioskbeerli sops-nix secrets subsystem.

(defpackage :kioskbeerli/sops-nix-secrets/tests
  (:use :cl :kioskbeerli/sops-nix-secrets)
  (:export #:run-sops-nix-secrets-smoke-tests))
