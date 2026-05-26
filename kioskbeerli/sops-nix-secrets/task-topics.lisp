;;;; DITA-like task topics for the Kioskbeerli sops-nix secrets milestone.

(in-package :kioskbeerli/sops-nix-secrets)

(defun %task-topic-id (task-id)
  (format nil "kioskbeerli-sops-nix-task-~A" task-id))

(defun %task-topic-steps (task)
  (list
   (format nil "Inspect the plan task ~A and its guards." (id-of task))
   "Confirm that the task boundary contains no cleartext values or password hashes."
   "Record evidence by path or status only; do not paste secret material into Lisp, docs, commits, or transcripts."))

(defun %make-task-topic (task)
  (make-instance 'sops-nix-secrets-task-topic
                 :id (%task-topic-id (id-of task))
                 :title (title-of task)
                 :summary (summary-of task)
                 :task-id (id-of task)
                 :state-id (state-id-of task)
                 :preconditions (preconditions-of task)
                 :steps (%task-topic-steps task)
                 :result (format nil "Task ~A reaches SCXML state ~A without exposing secret material."
                                 (id-of task)
                                 (state-id-of task))
                 :postrequisites
                 '("Keep command execution manual and explicit."
                   "Re-inspect guards before moving to the next task."
                   "Never promote switch before a successful test activation.")))

(defun sops-nix-secrets-task-topics
    (&optional (plan (make-sops-nix-secrets-plan)))
  (mapcar #'%make-task-topic (tasks-of plan)))
