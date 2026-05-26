;;;; SHOP3-style plan-only domain for creating Kioskbeerli sops-nix secrets.

(in-package :kioskbeerli/sops-nix-secrets)

(defparameter *sops-nix-secrets-task-ids*
  '("verify-den-base-milestone"
    "check-local-sops-tools"
    "check-local-age-identity"
    "derive-pi-age-recipient"
    "draft-sops-yaml"
    "create-encrypted-secret-file"
    "verify-secret-file-is-encrypted"
    "patch-host-module-enable-secrets"
    "stage-secret-files"
    "apply-secret-files-through-root-boundary"
    "evaluate-flake-secrets"
    "run-nixos-rebuild-test"
    "verify-run-secrets"
    "switch-secrets-configuration"
    "reboot-verify-secrets"
    "record-sops-milestone"))

(defparameter *sops-nix-secrets-blocked-state-ids*
  '("missing-tools"
    "plaintext-detected"
    "eval-failed"
    "rebuild-test-failed"
    "decryption-failed"))

(defparameter *sops-nix-secrets-task-data*
  '(("verify-den-base-milestone"
     "Verify Den base-system milestone"
     "Confirm the documented survived-reboot Den base-system milestone before any secret work."
     nil
     ("Kioskbeerli Den base-system runbook exists"
      "Pi baseline evidence is already recorded")
     ("Base-system evidence is the starting point for the secrets milestone")
     :verified
     ("kioskbeerli/raspberry-pi-den-base-system.md"
      "hyperdoc/Kioskbeerli.html"
      "var/kioskbeerli-pi-backup/MILESTONE.txt")
     "den-base-verified"
     "DEN_BASE_VERIFIED")
    ("check-local-sops-tools"
     "Check local sops tools"
     "Inspect whether required local tooling is available without creating secrets."
     ("verify-den-base-milestone")
     ("Operator machine is in the repo's Nix/dev context")
     ("Missing tools block the milestone before any Pi mutation")
     :planned
     ("missing: sops tool availability check"
      "missing: age tool availability check")
     "tools-available"
     "TOOLS_AVAILABLE")
    ("check-local-age-identity"
     "Check local age identity"
     "Confirm the operator has an age identity without printing private key material."
     ("check-local-sops-tools")
     ("sops and age tooling are available")
     ("Operator identity is available for encryption policy design")
     :planned
     ("missing: ~/.config/sops/age/keys.txt presence check")
     "age-identity-ready"
     "AGE_IDENTITY_READY")
    ("derive-pi-age-recipient"
     "Derive Pi age recipient"
     "Derive a recipient for the Pi from public material only."
     ("check-local-age-identity")
     ("Operator age identity boundary is understood"
      "Public Pi SSH host-key material is available")
     ("Recipient list can be drafted without exposing secrets")
     :planned
     ("missing: Pi age recipient fingerprint record")
     "recipients-ready"
     "RECIPIENTS_READY")
    ("draft-sops-yaml"
     "Draft .sops.yaml"
     "Draft the sops creation policy for the Kioskbeerli NixOS tree."
     ("derive-pi-age-recipient")
     ("Operator and Pi recipients are known")
     ("/etc/nixos/.sops.yaml can be reviewed before any encrypted payload is created")
     :planned
     ("missing: reviewed .sops.yaml patch")
     "policy-drafted"
     "POLICY_DRAFTED")
    ("create-encrypted-secret-file"
     "Create encrypted secret file"
     "Create the encrypted Kioskbeerli secret file without recording cleartext."
     ("draft-sops-yaml")
     ("/etc/nixos/.sops.yaml policy is reviewed"
      "The first secret key path is users/guest/hashed-password")
     ("Encrypted file exists; cleartext and hashes remain outside repo output")
     :planned
     ("missing: /etc/nixos/secrets/kioskbeerli.yaml encrypted file")
     "secret-encrypted"
     "SECRET_ENCRYPTED")
    ("verify-secret-file-is-encrypted"
     "Verify secret file is encrypted"
     "Verify the file is encrypted and contains no exposed values before staging."
     ("create-encrypted-secret-file")
     ("Encrypted secret file exists")
     ("Plaintext exposure is blocked before host-module edits")
     :planned
     ("missing: encrypted-file inspection result")
     "secret-encrypted"
     "SECRET_FILE_VERIFIED")
    ("patch-host-module-enable-secrets"
     "Patch host module to enable secrets"
     "Patch the host/module wiring so sops-nix can consume the encrypted file."
     ("verify-secret-file-is-encrypted")
     ("Encrypted file is verified")
     ("secrets-sops.nix and host imports can be reviewed")
     :planned
     ("missing: secrets module patch")
     "host-module-patched"
     "HOST_MODULE_PATCHED")
    ("stage-secret-files"
     "Stage secret files"
     "Stage only encrypted and policy files, never cleartext or generated local state."
     ("patch-host-module-enable-secrets")
     ("Host/module patch is reviewed")
     ("Git boundary contains only allowed source and encrypted material")
     :planned
     ("missing: staged encrypted/policy files")
     "files-staged"
     "FILES_STAGED")
    ("apply-secret-files-through-root-boundary"
     "Apply secret files through root boundary"
     "Copy reviewed files into /etc/nixos through an explicit root boundary."
     ("stage-secret-files")
     ("Only encrypted/policy/module files are staged")
     ("Pi /etc/nixos can evaluate the secrets configuration")
     :planned
     ("missing: root-boundary copy transcript without secret values")
     "root-applied"
     "ROOT_APPLIED")
    ("evaluate-flake-secrets"
     "Evaluate flake secrets"
     "Evaluate the Pi flake after the secrets wiring is present."
     ("apply-secret-files-through-root-boundary")
     ("Updated /etc/nixos flake is present")
     ("Flake exposes kioskbeerli-pi with secrets wiring")
     :planned
     ("missing: nix flake show output")
     "flake-evaluated"
     "FLAKE_EVALUATED")
    ("run-nixos-rebuild-test"
     "Run nixos-rebuild test"
     "Run test activation before any switch."
     ("evaluate-flake-secrets")
     ("Flake evaluation succeeded")
     ("Runtime can test secrets configuration without switching permanently")
     :planned
     ("missing: nixos-rebuild test output")
     "test-activated"
     "TEST_ACTIVATED")
    ("verify-run-secrets"
     "Verify runtime secrets"
     "Verify the runtime secret path exists and is consumed without revealing contents."
     ("run-nixos-rebuild-test")
     ("Test activation succeeded")
     ("The runtime path /run/secrets/users/guest/hashed-password exists with safe permissions")
     :planned
     ("missing: redacted runtime secret verification")
     "runtime-secret-verified"
     "RUNTIME_SECRET_VERIFIED")
    ("switch-secrets-configuration"
     "Switch secrets configuration"
     "Switch only after test activation and runtime verification pass."
     ("verify-run-secrets")
     ("Test activation succeeded"
      "Runtime secret verification succeeded")
     ("Secrets configuration becomes the booted generation")
     :planned
     ("missing: nixos-rebuild switch output")
     "switched"
     "SWITCHED")
    ("reboot-verify-secrets"
     "Reboot and verify secrets"
     "Reboot and verify the secrets configuration survives restart."
     ("switch-secrets-configuration")
     ("Switch succeeded")
     ("Secrets milestone survives reboot")
     :planned
     ("missing: post-reboot secret verification")
     "complete"
     "REBOOT_VERIFIED")
    ("record-sops-milestone"
     "Record sops milestone"
     "Record the completed encrypted secrets milestone without recording secret values."
     ("reboot-verify-secrets")
     ("Post-reboot verification succeeded")
     ("Durable milestone evidence exists")
     :planned
     ("missing: sops milestone record")
     "complete"
     "MILESTONE_RECORDED")))

(defun sops-nix-secrets-plan-task-ids ()
  (copy-list *sops-nix-secrets-task-ids*))

(defun sops-nix-secrets-blocked-state-ids ()
  (copy-list *sops-nix-secrets-blocked-state-ids*))

(defun %make-sops-nix-secrets-task (spec)
  (destructuring-bind
      (id title summary dependencies preconditions effects status evidence
          state-id event)
      spec
    (make-instance 'sops-nix-secrets-plan-task
                   :id id
                   :title title
                   :summary summary
                   :dependencies dependencies
                   :preconditions preconditions
                   :effects effects
                   :status status
                   :evidence evidence
                   :state-id state-id
                   :scxml-event event
                   :command-specs (%command-specs-for-task id))))

(defun make-sops-nix-secrets-plan (&key (execution-mode :plan-only))
  "Return the inspectable plan for the next Kioskbeerli Pi mutation.

The default and only supported execution mode is :PLAN-ONLY. This function
does not ssh, sudo, rebuild, switch, run sops, write DMX, or mutate the Pi."
  (unless (eq execution-mode :plan-only)
    (error "Kioskbeerli sops-nix secrets planning only supports :PLAN-ONLY, not ~S."
           execution-mode))
  (make-instance 'sops-nix-secrets-plan
                 :id "kioskbeerli-sops-nix-secrets-plan"
                 :title "Create encrypted sops-nix secrets"
                 :summary "Plan-only SHOP3-style task graph for the next Kioskbeerli Pi mutation: encrypted sops-nix secrets, starting with users/guest/hashed-password."
                 :execution-mode execution-mode
                 :dry-run-p t
                 :tasks (mapcar #'%make-sops-nix-secrets-task
                                 *sops-nix-secrets-task-data*)
                 :guards (sops-nix-secrets-guards)
                 :command-specs (sops-nix-secrets-command-specs)))

(defun sops-nix-secrets-lookup-plan-task
    (task-or-id &key (plan (make-sops-nix-secrets-plan)))
  (if (typep task-or-id 'sops-nix-secrets-plan-task)
      task-or-id
      (let ((task-id (normalize-sops-nix-secrets-id task-or-id)))
        (find task-id (tasks-of plan) :key #'id-of :test #'string=))))

(defun %completed-task-p (task)
  (member (status-of task) '(:verified :complete) :test #'eq))

(defun %task-dependencies-satisfied-p (task plan)
  (every (lambda (dependency-id)
           (let ((dependency
                   (sops-nix-secrets-lookup-plan-task dependency-id :plan plan)))
             (and dependency (%completed-task-p dependency))))
         (dependencies-of task)))

(defun sops-nix-secrets-next-actions
    (&key (plan (make-sops-nix-secrets-plan)))
  "Return currently available plan actions without executing them."
  (remove-if-not
   (lambda (task)
     (and (not (%completed-task-p task))
          (%task-dependencies-satisfied-p task plan)))
   (tasks-of plan)))

(defun inspect-sops-nix-secrets-plan
    (&optional (plan (make-sops-nix-secrets-plan)))
  "Open PLAN in the CLOG inspector when available."
  (%clog-inspect plan))
