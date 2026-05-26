;;;; Problem/session entrypoints for the Kioskbeerli sops-nix secrets plan.

(in-package :kioskbeerli/sops-nix-secrets)

(defun make-sops-nix-secrets-session
    (&key (plan (make-sops-nix-secrets-plan)))
  "Return a fully linked inspectable session for the plan-only secrets milestone."
  (let ((chart (sops-nix-secrets-scxml-chart))
        (bundle (sops-nix-secrets-topic-bundle :plan plan)))
    (make-instance
     'sops-nix-secrets-session
     :id "kioskbeerli-sops-nix-secrets-session"
     :title "Kioskbeerli sops-nix secrets planning session"
     :summary "Inspectable plan-only session for creating encrypted sops-nix secrets after the Den base-system milestone."
     :execution-mode (execution-mode-of plan)
     :plan plan
     :chart chart
     :topic-bundle bundle
     :next-actions (sops-nix-secrets-next-actions :plan plan))))

(defun make-sops-nix-secrets-problem
    (&key (plan (make-sops-nix-secrets-plan)))
  (make-instance
   'sops-nix-secrets-problem
   :id "kioskbeerli-sops-nix-secrets-problem"
   :title "Create encrypted sops-nix secrets"
   :summary "Planning problem for the next Kioskbeerli Pi mutation. The default path is inspectable and plan-only."
   :plan plan
   :guards (guards-of plan)
   :references '("kioskbeerli/raspberry-pi-den-base-system.md"
                 "hyperdoc/Kioskbeerli sops-nix secrets.html")))
