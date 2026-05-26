;;;; Manual command specifications for the Kioskbeerli sops-nix secrets plan.

(in-package :kioskbeerli/sops-nix-secrets)

(defparameter *sops-nix-secrets-command-spec-data*
  '(("check-local-sops-tools"
     "Check local sops tooling"
     "Inspect whether sops and age tooling are available on the operator machine."
     "check-local-sops-tools"
     "operator reads tool availability; no secret material is printed"
     nil nil)
    ("check-local-age-identity"
     "Check local age identity"
     "Inspect whether the operator has an age identity file without printing key material."
     "check-local-age-identity"
     "operator checks for ~/.config/sops/age/keys.txt; contents remain private"
     nil nil)
    ("derive-pi-age-recipient"
     "Derive Pi age recipient"
     "Derive or inspect the Pi recipient from a public host-key path only."
     "derive-pi-age-recipient"
     "operator uses public key material only; private keys remain outside transcripts"
     nil nil)
    ("draft-sops-yaml"
     "Draft .sops.yaml"
     "Draft the recipient policy for /etc/nixos/.sops.yaml."
     "draft-sops-yaml"
     "manual edit only; policy contains recipients and paths, not secret values"
     nil t)
    ("create-encrypted-secret-file"
     "Create encrypted secret file"
     "Create /etc/nixos/secrets/kioskbeerli.yaml through sops in an operator-controlled shell."
     "create-encrypted-secret-file"
     "manual command shape only; this subsystem never invokes sops or captures secret values"
     nil t)
    ("verify-secret-file-is-encrypted"
     "Verify encrypted secret file"
     "Inspect the secret file structure and verify it is encrypted before any commit."
     "verify-secret-file-is-encrypted"
     "manual inspection only; cleartext values and password hashes must not appear"
     nil nil)
    ("evaluate-flake-secrets"
     "Evaluate flake secrets wiring"
     "Run flake evaluation for the kioskbeerli-pi host after secret-module edits."
     "evaluate-flake-secrets"
     "nix flake show"
     ("nix" "flake" "show")
     nil)
    ("run-nixos-rebuild-test"
     "Run test activation"
     "Run nixos-rebuild test before any switch."
     "run-nixos-rebuild-test"
     "nixos-rebuild test --flake .#kioskbeerli-pi"
     ("nixos-rebuild" "test" "--flake" ".#kioskbeerli-pi")
     t)
    ("switch-secrets-configuration"
     "Switch secrets configuration"
     "Switch only after the test activation and runtime verification have succeeded."
     "switch-secrets-configuration"
     "nixos-rebuild switch --flake .#kioskbeerli-pi"
     ("nixos-rebuild" "switch" "--flake" ".#kioskbeerli-pi")
     t)))

(defun %make-command-spec (spec)
  (destructuring-bind (id title summary task-id command-text argv mutates-p) spec
    (make-instance 'sops-nix-secrets-command-spec
                   :id id
                   :title title
                   :summary summary
                   :task-id task-id
                   :command-text command-text
                   :argv argv
                   :requires-sudo-p (and argv
                                         (string= "nixos-rebuild" (first argv)))
                   :mutates-p mutates-p
                   :execution-mode :manual-only
                   :executed-p nil)))

(defun sops-nix-secrets-command-specs ()
  "Return inspectable command specs. They are never executed by this subsystem."
  (mapcar #'%make-command-spec *sops-nix-secrets-command-spec-data*))

(defun %command-specs-for-task (task-id)
  (remove-if-not
   (lambda (spec)
     (string= task-id (task-id-of spec)))
   (sops-nix-secrets-command-specs)))
