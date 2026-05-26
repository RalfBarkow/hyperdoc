;;;; Guard records for the Kioskbeerli sops-nix secrets plan.

(in-package :kioskbeerli/sops-nix-secrets)

(defparameter *sops-nix-secrets-guard-data*
  '(("no-cleartext-secret-in-lisp-output"
     "No cleartext secret in Lisp output"
     "Inspectable Lisp objects must describe boundaries and paths without containing secret values."
     "Delete the artifact, rotate the affected secret, and rebuild the plan from redacted records."
     "plaintext-detected")
    ("no-cleartext-secret-in-committed-files"
     "No cleartext secret in committed files"
     "Commits must not contain secret values, decrypted YAML, private keys, or generated secret material."
     "Remove the file from the index, rotate the secret if exposure occurred, and recommit only encrypted material."
     "plaintext-detected")
    ("no-password-hash-in-sly-transcript"
     "No password hash in SLY transcript"
     "The hashed password value must not be printed, stored in docs, or captured in MREPL transcripts."
     "Clear the transcript, rotate the hash, and preserve only path-level evidence."
     "plaintext-detected")
    ("no-switch-before-rebuild-test"
     "No switch before rebuild test"
     "A secrets configuration switch is blocked until nixos-rebuild test has succeeded and been inspected."
     "Return to flake evaluation and test activation before considering switch."
     "rebuild-test-failed")
    ("no-kiosk-enablement"
     "No kiosk enablement"
     "This milestone must not enable Cage, Chromium, kiosk sessions, or browser startup."
     "Back out unrelated kiosk changes and split them into a later milestone."
     nil)
    ("no-hostname-forcing"
     "No hostname forcing"
     "This milestone must not force the runtime hostname from myhostname to kioskbeerli."
     "Remove hostname-forcing changes and keep hostname migration separate."
     nil)
    ("no-dmx-writes"
     "No DMX writes"
     "The subsystem may be inspected locally but must not write to DMX or Neo4j."
     "Discard any attempted DMX write plan and keep only local documentation."
     nil)
    ("no-pi-mutation-in-default-plan-only-path"
     "No Pi mutation in default plan-only path"
     "The default API returns plan objects only and must not ssh, sudo, rebuild, switch, reboot, or edit the Pi."
     "Audit command specs and keep external action behind explicit human operation."
     nil)))

(defun %make-guard (spec)
  (destructuring-bind (id title summary recovery blocked-state-id) spec
    (make-instance 'sops-nix-secrets-guard
                   :id id
                   :title title
                   :summary summary
                   :status :active
                   :recovery recovery
                   :blocked-state-id blocked-state-id)))

(defun sops-nix-secrets-guards ()
  (mapcar #'%make-guard *sops-nix-secrets-guard-data*))
