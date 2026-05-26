;;;; Inspectable object model for Kioskbeerli Pi simulation planning.

(in-package :kioskbeerli/pi-simulation)

(defclass pi-simulation-fidelity-level ()
  ((level :accessor level-of :initarg :level)
   (id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (summary :accessor summary-of :initarg :summary)
   (status :accessor status-of :initarg :status :initform :planned)))

(defclass pi-simulation-plan-task ()
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (summary :accessor summary-of :initarg :summary)
   (level :accessor level-of :initarg :level)
   (dependencies :accessor dependencies-of :initarg :dependencies :initform nil)
   (preconditions :accessor preconditions-of :initarg :preconditions :initform nil)
   (effects :accessor effects-of :initarg :effects :initform nil)
   (status :accessor status-of :initarg :status :initform :planned)
   (evidence :accessor evidence-of :initarg :evidence :initform nil)
   (state-id :accessor state-id-of :initarg :state-id)
   (scxml-event :accessor scxml-event-of :initarg :scxml-event)
   (command-specs :accessor command-specs-of :initarg :command-specs :initform nil)))

(defclass pi-simulation-plan (hyperdoc/shop3:hyperdoc-htn-plan-result)
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (summary :accessor summary-of :initarg :summary)
   (dry-run-p :accessor dry-run-p :initarg :dry-run-p :initform t)
   (levels :accessor levels-of :initarg :levels)
   (tasks :accessor tasks-of :initarg :tasks)
   (command-specs :accessor command-specs-of :initarg :command-specs)))

(defclass pi-simulation-session ()
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (summary :accessor summary-of :initarg :summary)
   (execution-mode :accessor execution-mode-of
                   :initarg :execution-mode
                   :initform :plan-only)
   (plan :accessor plan-of :initarg :plan)
   (chart :accessor chart-of :initarg :chart)
   (topic-bundle :accessor topic-bundle-of :initarg :topic-bundle)
   (next-actions :accessor next-actions-of :initarg :next-actions)
   (boot-status :accessor boot-status-of :initarg :boot-status)))

(defclass pi-simulation-command-spec ()
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (summary :accessor summary-of :initarg :summary)
   (task-id :accessor task-id-of :initarg :task-id)
   (level :accessor level-of :initarg :level)
   (command-text :accessor command-text-of :initarg :command-text)
   (argv :accessor argv-of :initarg :argv)
   (working-directory :accessor working-directory-of
                      :initarg :working-directory
                      :initform "/etc/nixos")
   (mutates-p :accessor mutates-p :initarg :mutates-p :initform nil)
   (execution-mode :accessor execution-mode-of
                   :initarg :execution-mode
                   :initform :manual-only)
   (executed-p :accessor executed-p :initarg :executed-p :initform nil)
   (safety-boundary :accessor safety-boundary-of
                    :initarg :safety-boundary
                    :initform "Inspectable command specification only; never executed by this subsystem.")))

(defclass pi-simulation-task-state-link ()
  ((task-id :accessor task-id-of :initarg :task-id)
   (scxml-event :accessor scxml-event-of :initarg :scxml-event)
   (scxml-state :accessor scxml-state-of :initarg :scxml-state)
   (summary :accessor summary-of :initarg :summary)))

(defclass pi-simulation-topic ()
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (summary :accessor summary-of :initarg :summary)
   (category :accessor category-of :initarg :category)
   (references :accessor references-of :initarg :references :initform nil)))

(defclass pi-simulation-topic-bundle ()
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (summary :accessor summary-of :initarg :summary)
   (topics :accessor topics-of :initarg :topics)))

(defclass pi-simulation-boot-status ()
  ((status :accessor status-of :initarg :status)
   (backend :accessor backend-of :initarg :backend :initform nil)
   (reason :accessor reason-of :initarg :reason)
   (evidence :accessor evidence-of :initarg :evidence :initform nil)))

(defmethod execution-mode-of ((object pi-simulation-plan))
  (hyperdoc/shop3:execution-mode-of object))

(defmethod print-object ((object pi-simulation-fidelity-level) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "level=~D ~A" (level-of object) (id-of object))))

(defmethod print-object ((object pi-simulation-plan-task) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A level=~D ~A"
            (id-of object)
            (level-of object)
            (status-of object))))

(defmethod print-object ((object pi-simulation-plan) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "tasks=~D levels=~D mode=~A"
            (length (tasks-of object))
            (length (levels-of object))
            (execution-mode-of object))))

(defmethod print-object ((object pi-simulation-session) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A next=~D boot=~A"
            (id-of object)
            (length (next-actions-of object))
            (status-of (boot-status-of object)))))

(defmethod print-object ((object pi-simulation-command-spec) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A level=~D executed=~A"
            (id-of object)
            (level-of object)
            (executed-p object))))

(defmethod print-object ((object pi-simulation-boot-status) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A ~A" (status-of object) (or (backend-of object) "no-backend"))))

(defun normalize-pi-simulation-id (id)
  (etypecase id
    (string (string-downcase id))
    (symbol (string-downcase (symbol-name id)))))

(defun %clog-inspect (object)
  (let* ((pkg (find-package "CLOG-MOLDABLE-INSPECTOR"))
         (sym (and pkg (find-symbol "CLOG-INSPECT" pkg))))
    (unless (and sym (fboundp sym))
      (error "CLOG-MOLDABLE-INSPECTOR:CLOG-INSPECT is not available. Load :hyperdoc/server first."))
    (funcall sym :object object)))
