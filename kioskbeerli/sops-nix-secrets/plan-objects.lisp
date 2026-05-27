;;;; Inspectable object model for the Kioskbeerli sops-nix secrets plan.

(in-package :kioskbeerli/sops-nix-secrets)

(defclass sops-nix-secrets-plan-task ()
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (summary :accessor summary-of :initarg :summary)
   (dependencies :accessor dependencies-of :initarg :dependencies :initform nil)
   (preconditions :accessor preconditions-of :initarg :preconditions :initform nil)
   (effects :accessor effects-of :initarg :effects :initform nil)
   (status :accessor status-of :initarg :status :initform :planned)
   (evidence :accessor evidence-of :initarg :evidence :initform nil)
   (state-id :accessor state-id-of :initarg :state-id)
   (scxml-event :accessor scxml-event-of :initarg :scxml-event)
   (command-specs :accessor command-specs-of :initarg :command-specs :initform nil)
   (related-task-ids :accessor related-task-ids-of
                     :initarg :related-task-ids
                     :initform nil)))

(defclass sops-nix-secrets-plan (hyperdoc/shop3:hyperdoc-htn-plan-result)
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (summary :accessor summary-of :initarg :summary)
   (dry-run-p :accessor dry-run-p :initarg :dry-run-p :initform t)
   (tasks :accessor tasks-of :initarg :tasks)
   (guards :accessor guards-of :initarg :guards :initform nil)
   (command-specs :accessor command-specs-of
                  :initarg :command-specs
                  :initform nil)))

(defclass sops-nix-secrets-session ()
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (summary :accessor summary-of :initarg :summary)
   (execution-mode :accessor execution-mode-of
                   :initarg :execution-mode
                   :initform :plan-only)
   (plan :accessor plan-of :initarg :plan)
   (chart :accessor chart-of :initarg :chart)
   (topic-bundle :accessor topic-bundle-of :initarg :topic-bundle)
   (next-actions :accessor next-actions-of :initarg :next-actions)))

(defclass sops-nix-secrets-command-spec ()
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (summary :accessor summary-of :initarg :summary)
   (task-id :accessor task-id-of :initarg :task-id)
   (command-text :accessor command-text-of :initarg :command-text :initform nil)
   (argv :accessor argv-of :initarg :argv :initform nil)
   (working-directory :accessor working-directory-of
                      :initarg :working-directory
                      :initform "/etc/nixos")
   (requires-sudo-p :accessor requires-sudo-p
                    :initarg :requires-sudo-p
                    :initform nil)
   (mutates-p :accessor mutates-p :initarg :mutates-p :initform nil)
   (execution-mode :accessor execution-mode-of
                   :initarg :execution-mode
                   :initform :manual-only)
   (executed-p :accessor executed-p :initarg :executed-p :initform nil)
   (safety-boundary :accessor safety-boundary-of
                    :initarg :safety-boundary
                    :initform "Inspectable command specification only; never executed by this subsystem.")))

(defclass sops-nix-secrets-task-state-link ()
  ((task-id :accessor task-id-of :initarg :task-id)
   (scxml-event :accessor scxml-event-of :initarg :scxml-event)
   (scxml-state :accessor scxml-state-of :initarg :scxml-state)
   (summary :accessor summary-of :initarg :summary)))

(defclass sops-nix-secrets-task-topic ()
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (summary :accessor summary-of :initarg :summary)
   (task-id :accessor task-id-of :initarg :task-id)
   (state-id :accessor state-id-of :initarg :state-id)
   (preconditions :accessor preconditions-of :initarg :preconditions :initform nil)
   (steps :accessor steps-of :initarg :steps :initform nil)
   (result :accessor result-of :initarg :result)
   (postrequisites :accessor postrequisites-of
                   :initarg :postrequisites
                   :initform nil)))

(defclass sops-nix-secrets-topic ()
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (summary :accessor summary-of :initarg :summary)
   (category :accessor category-of :initarg :category)
   (references :accessor references-of :initarg :references :initform nil)
   (related-task-ids :accessor related-task-ids-of
                     :initarg :related-task-ids
                     :initform nil)))

(defclass sops-nix-secrets-topic-bundle ()
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (summary :accessor summary-of :initarg :summary)
   (tasks :accessor tasks-of :initarg :tasks)
   (concepts :accessor concepts-of :initarg :concepts)
   (references :accessor references-of :initarg :references)
   (guards :accessor guards-of :initarg :guards)
   (failures :accessor failures-of :initarg :failures)
   (recoveries :accessor recoveries-of :initarg :recoveries)))

(defclass sops-nix-secrets-guard ()
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (summary :accessor summary-of :initarg :summary)
   (status :accessor status-of :initarg :status :initform :active)
   (recovery :accessor recovery-of :initarg :recovery)
   (blocked-state-id :accessor blocked-state-id-of
                     :initarg :blocked-state-id
                     :initform nil)))

(defclass sops-nix-secrets-problem ()
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (summary :accessor summary-of :initarg :summary)
   (plan :accessor plan-of :initarg :plan)
   (guards :accessor guards-of :initarg :guards)
   (references :accessor references-of :initarg :references)))

(defmethod execution-mode-of ((object sops-nix-secrets-plan))
  (hyperdoc/shop3:execution-mode-of object))

(defmethod print-object ((object sops-nix-secrets-plan-task) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A ~A" (id-of object) (status-of object))))

(defmethod print-object ((object sops-nix-secrets-plan) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A tasks=~D mode=~A"
            (id-of object)
            (length (tasks-of object))
            (execution-mode-of object))))

(defmethod print-object ((object sops-nix-secrets-session) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A next=~D"
            (id-of object)
            (length (next-actions-of object)))))

(defmethod print-object ((object sops-nix-secrets-command-spec) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A mode=~A executed=~A"
            (id-of object)
            (execution-mode-of object)
            (executed-p object))))

(defmethod print-object ((object sops-nix-secrets-topic) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A ~A" (category-of object) (id-of object))))

(defmethod print-object ((object sops-nix-secrets-topic-bundle) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "tasks=~D concepts=~D references=~D"
            (length (tasks-of object))
            (length (concepts-of object))
            (length (references-of object)))))

(defmethod print-object ((object sops-nix-secrets-guard) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A ~A" (id-of object) (status-of object))))

(defun normalize-sops-nix-secrets-id (id)
  (etypecase id
    (string (string-downcase id))
    (symbol (string-downcase (symbol-name id)))))

(defun %clog-inspect (object)
  (let* ((pkg (find-package "CLOG-MOLDABLE-INSPECTOR"))
         (sym (and pkg (find-symbol "CLOG-INSPECT" pkg))))
    (unless (and sym (fboundp sym))
      (error "CLOG-MOLDABLE-INSPECTOR:CLOG-INSPECT is not available. Load :hyperdoc/server first."))
    (funcall sym :object object)))
