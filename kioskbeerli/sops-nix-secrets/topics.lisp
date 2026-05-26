;;;; Concept, reference, guard, failure, and recovery topics.

(in-package :kioskbeerli/sops-nix-secrets)

(defun %topic (id title summary category &key references related-task-ids)
  (make-instance 'sops-nix-secrets-topic
                 :id id
                 :title title
                 :summary summary
                 :category category
                 :references references
                 :related-task-ids related-task-ids))

(defparameter *sops-nix-secrets-concept-topic-data*
  '(("encrypted-secret" "encrypted secret"
     "Secret value stored only in encrypted form at rest and never represented in Lisp output."
     ("create-encrypted-secret-file" "verify-secret-file-is-encrypted"))
    ("sops-nix" "sops-nix"
     "NixOS integration that decrypts sops-managed secrets at activation time for declared consumers."
     ("patch-host-module-enable-secrets" "run-nixos-rebuild-test"))
    ("age-recipient" "age recipient"
     "Public encryption recipient used by sops to encrypt secret material."
     ("derive-pi-age-recipient" "draft-sops-yaml"))
    ("operator-age-identity" "operator age identity"
     "Local private identity used by the operator for editing encrypted files, never printed in transcripts."
     ("check-local-age-identity"))
    ("pi-ssh-host-key-recipient" "Pi SSH host key recipient"
     "Recipient derived from public Pi host-key material so the Pi can decrypt at activation time."
     ("derive-pi-age-recipient"))
    ("secret-consumer" "secret consumer"
     "NixOS module option or service that reads a decrypted runtime path rather than an inline value."
     ("patch-host-module-enable-secrets" "verify-run-secrets"))
    ("hashed-password-file" "hashed password file"
     "Runtime file path containing the guest password hash; the value itself is never documented."
     ("create-encrypted-secret-file" "verify-run-secrets"))
    ("cleartext-boundary" "cleartext boundary"
     "Boundary that prevents secret values and password hashes from entering source, docs, commits, and transcripts."
     ("verify-secret-file-is-encrypted" "stage-secret-files"))
    ("root-boundary" "root boundary"
     "Explicit privileged copy/application step for /etc/nixos, separate from planning and inspection."
     ("apply-secret-files-through-root-boundary"))
    ("activation-time-decryption" "activation-time decryption"
     "Runtime behavior where encrypted source is decrypted into /run/secrets during activation."
     ("run-nixos-rebuild-test" "verify-run-secrets"))
    ("rollback-point" "rollback point"
     "Known-good system generation or backup boundary used before test, switch, and reboot."
     ("verify-den-base-milestone" "switch-secrets-configuration"))))

(defparameter *sops-nix-secrets-reference-topic-data*
  '(("etc-nixos-sops-yaml" "/etc/nixos/.sops.yaml"
     "Recipient policy file for sops-managed Kioskbeerli secrets.")
    ("etc-nixos-secrets-kioskbeerli-yaml" "/etc/nixos/secrets/kioskbeerli.yaml"
     "Encrypted Kioskbeerli secret payload file; never committed in cleartext.")
    ("secrets-sops-module" "/etc/nixos/nix/nixos/modules/secrets-sops.nix"
     "Staged but currently inactive NixOS module for sops-nix secret declarations.")
    ("kioskbeerli-pi-host-module" "/etc/nixos/nix/nixos/hosts/kioskbeerli-pi.nix"
     "Dendritic host module where the secrets module import can be enabled later.")
    ("operator-age-keys" "~/.config/sops/age/keys.txt"
     "Operator identity file path; contents are private and never printed.")
    ("runtime-hashed-password" "/run/secrets/users/guest/hashed-password"
     "Runtime decrypted path consumed by NixOS user configuration; value is never shown.")
    ("local-pi-backup" "var/kioskbeerli-pi-backup/"
     "Local operator backup of the verified Den base-system milestone; not committed.")))

(defparameter *sops-nix-secrets-failure-topic-data*
  '(("missing-tools" "missing tools"
     "Required local tooling is missing, so no secret material should be created.")
    ("plaintext-detected" "plaintext detected"
     "A cleartext value or password hash appeared outside the allowed editing boundary.")
    ("eval-failed" "eval failed"
     "The flake or host configuration failed evaluation after secret-module changes.")
    ("rebuild-test-failed" "rebuild test failed"
     "The test activation failed; switch remains blocked.")
    ("decryption-failed" "decryption failed"
     "Activation or runtime verification could not decrypt the expected runtime secret path.")))

(defparameter *sops-nix-secrets-recovery-topic-data*
  '(("recover-missing-tools" "Recover from missing tools"
     "Install or enter an environment with sops and age before continuing.")
    ("recover-plaintext-detected" "Recover from plaintext detection"
     "Remove exposed material, rotate affected values, and preserve only redacted evidence.")
    ("recover-eval-failed" "Recover from eval failure"
     "Inspect the flake/module error and return to the host-module patch step.")
    ("recover-rebuild-test-failed" "Recover from rebuild test failure"
     "Do not switch; fix the module or encrypted payload and rerun test activation.")
    ("recover-decryption-failed" "Recover from decryption failure"
     "Inspect recipients and activation logs without printing secret values.")))

(defun %make-concept-topic (spec)
  (destructuring-bind (id title summary related-task-ids) spec
    (%topic id title summary :concept :related-task-ids related-task-ids)))

(defun %make-reference-topic (spec)
  (destructuring-bind (id title summary) spec
    (%topic id title summary :reference)))

(defun %make-guard-topic (guard)
  (%topic (id-of guard)
          (title-of guard)
          (summary-of guard)
          :guard
          :references (list (recovery-of guard))))

(defun %make-failure-topic (spec)
  (destructuring-bind (id title summary) spec
    (%topic id title summary :failure)))

(defun %make-recovery-topic (spec)
  (destructuring-bind (id title summary) spec
    (%topic id title summary :recovery)))

(defun sops-nix-secrets-concept-topics ()
  (mapcar #'%make-concept-topic *sops-nix-secrets-concept-topic-data*))

(defun sops-nix-secrets-reference-topics ()
  (mapcar #'%make-reference-topic *sops-nix-secrets-reference-topic-data*))

(defun sops-nix-secrets-guard-topics ()
  (mapcar #'%make-guard-topic (sops-nix-secrets-guards)))

(defun sops-nix-secrets-failure-topics ()
  (mapcar #'%make-failure-topic *sops-nix-secrets-failure-topic-data*))

(defun sops-nix-secrets-recovery-topics ()
  (mapcar #'%make-recovery-topic *sops-nix-secrets-recovery-topic-data*))

(defun sops-nix-secrets-topic-bundle
    (&key (plan (make-sops-nix-secrets-plan)))
  (make-instance
   'sops-nix-secrets-topic-bundle
   :id "kioskbeerli-sops-nix-secrets-topic-bundle"
   :title "Kioskbeerli sops-nix secrets topic bundle"
   :summary "Inspectable task, concept, reference, guard, failure, and recovery topics for the plan-only encrypted secrets milestone."
   :tasks (sops-nix-secrets-task-topics plan)
   :concepts (sops-nix-secrets-concept-topics)
   :references (sops-nix-secrets-reference-topics)
   :guards (sops-nix-secrets-guard-topics)
   :failures (sops-nix-secrets-failure-topics)
   :recoveries (sops-nix-secrets-recovery-topics)))
