;;;; SCXML statechart accessors for the Kioskbeerli sops-nix secrets plan.

(in-package :kioskbeerli/sops-nix-secrets)

(defun sops-nix-secrets-scxml-pathname ()
  (asdf:system-relative-pathname
   :kioskbeerli/sops-nix-secrets
   "kioskbeerli/sops-nix-secrets/sops-nix-secrets.scxml"))

(defun sops-nix-secrets-scxml-chart ()
  (hyperdoc/scxml:parse-scxml-file (sops-nix-secrets-scxml-pathname)))

(defun sops-nix-secrets-scxml-state-ids
    (&optional (chart (sops-nix-secrets-scxml-chart)))
  (mapcar #'hyperdoc/scxml:scxml-state-id-of
          (hyperdoc/scxml:scxml-chart-states-of chart)))

(defun sops-nix-secrets-task-state-links
    (&key (plan (make-sops-nix-secrets-plan)))
  (mapcar
   (lambda (task)
     (make-instance 'sops-nix-secrets-task-state-link
                    :task-id (id-of task)
                    :scxml-event (scxml-event-of task)
                    :scxml-state (state-id-of task)
                    :summary (format nil "~A advances to ~A."
                                     (id-of task)
                                     (state-id-of task))))
   (tasks-of plan)))
