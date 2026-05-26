;;;; Trace/progress recording for Kioskbeerli
;;
;;;; Copyright (c) 2026

(in-package :kioskbeerli)

(defparameter *kioskbeerli-trace-status-vocabulary*
  '("declared" "blocked" "corrected" "missing-evidence" "verified" "unknown"))

(defclass kioskbeerli-evidence-reference ()
  ((path :accessor path-of :initarg :path)
   (kind :accessor kind-of :initarg :kind :initform :hyperdoc-page)
   (status :accessor status-of :initarg :status :initform "unknown")
   (note :accessor note-of :initarg :note :initform nil)))

(defclass kioskbeerli-trace-entry ()
  ((id :accessor id-of :initarg :id)
   (timestamp :accessor timestamp-of :initarg :timestamp)
   (actor :accessor actor-of :initarg :actor)
   (task-id :accessor task-id-of :initarg :task-id)
   (from-state :accessor from-state-of :initarg :from-state)
   (to-state :accessor to-state-of :initarg :to-state)
   (scxml-event :accessor scxml-event-of :initarg :scxml-event :initform nil)
   (status :accessor status-of :initarg :status)
   (evidence-references :accessor evidence-references-of
                        :initarg :evidence-references
                        :initform nil)
   (note :accessor note-of :initarg :note :initform nil)))

(defclass kioskbeerli-project-trace ()
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (summary :accessor summary-of :initarg :summary)
   (entries :accessor entries-of :initarg :entries :initform nil)))

(defmethod print-object ((object kioskbeerli-evidence-reference) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A ~A" (status-of object) (path-of object))))

(defmethod print-object ((object kioskbeerli-trace-entry) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A ~A -> ~A ~A"
            (task-id-of object)
            (from-state-of object)
            (to-state-of object)
            (status-of object))))

(defmethod print-object ((object kioskbeerli-project-trace) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A (~D entries)"
            (title-of object)
            (length (entries-of object)))))

(defun kioskbeerli-trace-status-vocabulary ()
  (copy-list *kioskbeerli-trace-status-vocabulary*))

(defun ensure-kioskbeerli-trace-status (status)
  (unless (member status *kioskbeerli-trace-status-vocabulary*
                  :test #'string=)
    (error "Unknown Kioskbeerli trace status ~S" status))
  status)

(defun %evidence-reference (path &key (kind :hyperdoc-page) (status "unknown")
                              note)
  (make-instance 'kioskbeerli-evidence-reference
                 :path path
                 :kind kind
                 :status (ensure-kioskbeerli-trace-status status)
                 :note note))

(defun %evidence-references (paths status)
  (loop for path in paths
        collect (%evidence-reference path :status status)))

(defun make-kioskbeerli-trace-entry
    (&key id (timestamp "stable-placeholder") (actor "codex")
       task-id from-state to-state scxml-event status evidence-paths note)
  (make-instance 'kioskbeerli-trace-entry
                 :id id
                 :timestamp timestamp
                 :actor actor
                 :task-id task-id
                 :from-state from-state
                 :to-state to-state
                 :scxml-event scxml-event
                 :status (ensure-kioskbeerli-trace-status status)
                 :evidence-references (%evidence-references evidence-paths status)
                 :note note))

(defun kioskbeerli-den-dendritic-nix-learning-checkpoint ()
  "Return the Den/Dendritic Nix learning checkpoint.

This is an inspectable source object only. It performs no Nix, device, SQLite,
DMX, flake, or nixos-rebuild mutation."
  (make-kioskbeerli-trace-entry
   :id "trace-den-dendritic-nix-learning-checkpoint"
   :actor "codex"
   :task-id "learn-den-dendritic-nix"
   :from-state "maintenance-access-verified"
   :to-state "implementation-path-deferred"
   :scxml-event "IMPLEMENTATION_PATH_DEFERRED"
   :status "blocked"
   :evidence-paths
   '("definition: Den is a data transformation pipeline over infrastructure entities"
     "definition: Dendritic Nix is based on flake-parts modules option"
     "boundary: Den/Dendritic Nix is not yet accepted as the Kioskbeerli implementation path"
     "boundary: nixos-rebuild test/switch remains deferred"
     "boundary: flake activation remains deferred"
     "next: learning/inspection, not deployment")
   :note
   (concatenate
    'string
    "Learning checkpoint: Den is a data transformation pipeline over "
    "infrastructure entities, to which functions/aspects are applied to "
    "produce configurations. Dendritic Nix is a pattern for writing Nix "
    "configurations based on flake-parts' modules option. Den/Dendritic Nix "
    "is not yet accepted as the Kioskbeerli implementation path. "
    "nixos-rebuild test/switch remains deferred. flake activation remains "
    "deferred. The next task is learning/inspection, not deployment.")))

(defun %default-kioskbeerli-trace ()
  (make-instance
   'kioskbeerli-project-trace
   :id "kioskbeerli-project-trace"
   :title "Kioskbeerli Project Trace"
   :summary "In-memory trace that records Kioskbeerli progress, evidence, and missing evidence without claiming unobserved device work."
   :entries
   (list
    (make-kioskbeerli-trace-entry
     :id "trace-declared-target"
     :task-id "declare-target"
     :from-state "unknown"
     :to-state "declared"
     :scxml-event nil
     :status "declared"
     :evidence-paths '("hyperdoc/Kioskbeerli.html")
     :note "Physical Raspberry Pi kiosk target and landing page are declared.")
    (make-kioskbeerli-trace-entry
     :id "trace-obsolete-option-corrected"
     :task-id "verify-obsolete-option-correction"
     :from-state "source-inspected"
     :to-state "obsolete-option-corrected"
     :scxml-event "OBSOLETE_OPTION_REMOVED"
     :status "corrected"
     :evidence-paths '("hyperdoc/Kioskbeerli sdImage imageSize Failure.html")
     :note "The obsolete sdImage.imageSize problem is documented as corrected.")
    (make-kioskbeerli-trace-entry
     :id "trace-cross-host-blocked"
     :task-id "resolve-cross-host-build"
     :from-state "obsolete-option-corrected"
     :to-state "cross-host-build-blocked"
     :scxml-event "BUILD_HOST_REJECTED"
     :status "blocked"
     :evidence-paths '("hyperdoc/Kioskbeerli Cross-Host Build Failure.html")
     :note "The current blocker is aarch64 image realization without a suitable Linux builder.")
    (make-kioskbeerli-trace-entry
     :id "trace-missing-build-evidence"
     :task-id "build-aarch64-image"
     :from-state "linux-builder-required"
     :to-state "linux-builder-required"
     :scxml-event "EVIDENCE_MISSING"
     :status "missing-evidence"
     :evidence-paths '("missing: successful aarch64 SD-image build artifact")
     :note "No successful build artifact, flash, network, kiosk session, or landing-page evidence is recorded yet.")
    (make-kioskbeerli-trace-entry
     :id "trace-boot-pi-observed"
     :actor "operator"
     :task-id "boot-pi"
     :from-state "sd-flashed"
     :to-state "first-boot-observed"
     :scxml-event "PI_BOOTED"
     :status "verified"
     :evidence-paths '("logged in as nixos on the booted Raspberry Pi")
     :note "Operator reported being logged in as user nixos on the booted Raspberry Pi. This verifies first boot only; it does not verify network, kiosk session, or landing page.")
    (kioskbeerli-den-dendritic-nix-learning-checkpoint))))

(defvar *kioskbeerli-project-trace* nil)

(defun kioskbeerli-project-trace ()
  (or *kioskbeerli-project-trace*
      (setf *kioskbeerli-project-trace* (%default-kioskbeerli-trace))))

(defun kioskbeerli-latest-progress (&optional (trace (kioskbeerli-project-trace)))
  (car (last (entries-of trace))))

(defun record-kioskbeerli-progress
    (&key (trace (kioskbeerli-project-trace))
       id
       (timestamp "stable-placeholder")
       (actor "codex")
       task-id
       from-state
       to-state
       scxml-event
       (status "unknown")
       evidence-paths
       note)
  "Record local in-memory progress. This does not mutate Nix, devices, HTTP, or DMX."
  (let ((entry (make-kioskbeerli-trace-entry
                :id (or id
                        (format nil "trace-~A-~D"
                                (or task-id "progress")
                                (1+ (length (entries-of trace)))))
                :timestamp timestamp
                :actor actor
                :task-id task-id
                :from-state from-state
                :to-state to-state
                :scxml-event scxml-event
                :status status
                :evidence-paths evidence-paths
                :note note)))
    (setf (entries-of trace)
          (append (entries-of trace) (list entry)))
    trace))

(defun kioskbeerli-record-boot-observed
    (&key (trace (kioskbeerli-project-trace))
       (timestamp "stable-placeholder")
       (actor "operator")
       (evidence "logged in as nixos on the booted Raspberry Pi"))
  "Record the operator's first-boot observation only. This performs no SSH, HTTP, flash, build, device, or DMX mutation."
  (record-kioskbeerli-progress
   :trace trace
   :id (format nil "trace-boot-pi-observed-~D"
               (1+ (length (entries-of trace))))
   :timestamp timestamp
   :actor actor
   :task-id "boot-pi"
   :from-state "sd-flashed"
   :to-state "first-boot-observed"
   :scxml-event "PI_BOOTED"
   :status "verified"
   :evidence-paths (list evidence)
   :note "Operator boot observation verifies first boot only; network, kiosk session, landing page, record-evidence, and dashboard-status tasks remain unevidenced unless separately recorded."))
