;;;; SHOP3-like Kioskberrli plan-only planner objects
;;
;;;; Copyright (c) 2026

(in-package :kioskberrli)

(defparameter *kioskbeerli-required-task-ids*
  '("declare-target"
    "verify-source-tree"
    "verify-nix-lock"
    "evaluate-sd-image"
    "remove-obsolete-sdimage-option"
    "verify-obsolete-option-correction"
    "resolve-cross-host-build"
    "provision-linux-builder"
    "build-aarch64-image"
    "flash-sd-card"
    "boot-pi"
    "verify-network"
    "verify-kiosk-session"
    "verify-landing-page"
    "record-evidence"
    "mark-dashboard-status"))

(defclass kioskbeerli-plan-task ()
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (plan-run :accessor plan-run-of :initarg :plan-run :initform nil)
   (dependencies :accessor dependencies-of :initarg :dependencies :initform nil)
   (preconditions :accessor preconditions-of :initarg :preconditions :initform nil)
   (effects :accessor effects-of :initarg :effects :initform nil)
   (status :accessor status-of :initarg :status :initform "declared")
   (evidence-paths :accessor evidence-paths-of
                   :initarg :evidence-paths
                   :initform nil)))

(defclass kioskbeerli-plan-run ()
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (summary :accessor summary-of :initarg :summary)
   (planner-kind :accessor planner-kind-of
                 :initarg :planner-kind
                 :initform :shop3-like)
   (execution-mode :accessor execution-mode-of
                   :initarg :execution-mode
                   :initform :plan-only)
   (dry-run-p :accessor dry-run-p :initarg :dry-run-p :initform t)
   (tasks :accessor tasks-of :initarg :tasks)))

(defclass kioskbeerli-task-state-link ()
  ((task-id :accessor task-id-of :initarg :task-id)
   (from-state :accessor from-state-of :initarg :from-state :initform nil)
   (scxml-event :accessor scxml-event-of :initarg :scxml-event)
   (scxml-state :accessor scxml-state-of :initarg :scxml-state)
   (summary :accessor summary-of :initarg :summary)))

(setf (find-class 'kioskberrli-plan-task) (find-class 'kioskbeerli-plan-task)
      (find-class 'kioskberrli-plan-run) (find-class 'kioskbeerli-plan-run)
      (find-class 'kioskberrli-task-state-link)
      (find-class 'kioskbeerli-task-state-link))

(defmethod print-object ((object kioskbeerli-plan-task) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A: ~A" (id-of object) (status-of object))))

(defmethod print-object ((object kioskbeerli-plan-run) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A ~A" (planner-kind-of object) (execution-mode-of object))))

(defmethod print-object ((object kioskbeerli-task-state-link) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A ~A -> ~A"
            (task-id-of object)
            (scxml-event-of object)
            (scxml-state-of object))))

(defun kioskbeerli-plan-task-ids ()
  (copy-list *kioskbeerli-required-task-ids*))

(defun kioskberrli-plan-task-ids ()
  (kioskbeerli-plan-task-ids))

(defparameter *kioskbeerli-task-state-links*
  '(("declare-target" nil "declared" "Kioskberrli target is declared.")
    ("verify-source-tree" "SOURCE_REVIEWED" "source-inspected" "Source tree review is recorded.")
    ("verify-nix-lock" "SOURCE_REVIEWED" "source-inspected" "Pinned Nix lock is part of source inspection evidence.")
    ("evaluate-sd-image" "BUILD_ATTEMPTED" "cross-host-build-blocked" "The SD-image target is evaluated or attempted.")
    ("remove-obsolete-sdimage-option" "OBSOLETE_OPTION_REMOVED" "obsolete-option-corrected" "The removed sdImage.imageSize option is no longer set.")
    ("verify-obsolete-option-correction" "OBSOLETE_OPTION_REMOVED" "obsolete-option-corrected" "The obsolete-option correction is verified.")
    ("resolve-cross-host-build" "BUILD_HOST_REJECTED" "linux-builder-required" "The aarch64 image realization blocker requires a suitable Linux builder.")
    ("provision-linux-builder" "LINUX_BUILDER_AVAILABLE" "image-built" "A suitable Linux builder becomes available.")
    ("build-aarch64-image" "IMAGE_BUILD_SUCCEEDED" "image-built" "The aarch64 SD-image artifact is built.")
    ("flash-sd-card" "FLASH_COMPLETED" "sd-flashed" "The SD card is flashed.")
    ("boot-pi" "PI_BOOTED" "first-boot-observed" "The physical Raspberry Pi first boot is observed.")
    ("verify-network" "NETWORK_OK" "network-verified" "Network reachability is verified.")
    ("verify-kiosk-session" "KIOSK_SESSION_OK" "kiosk-session-running" "The kiosk session is running.")
    ("verify-landing-page" "LANDING_PAGE_OK" "landing-page-visible" "The landing page is visible on the public display.")
    ("record-evidence" "EVIDENCE_RECORDED" "maintenance-ready" "Evidence is recorded in the project trace.")
    ("mark-dashboard-status" "EVIDENCE_RECORDED" "maintenance-ready" "The dashboard status can be updated from recorded evidence.")))

(defparameter *kioskbeerli-scxml-state-ranks*
  '(("unknown" . -1)
    ("failed-with-evidence" . -1)
    ("declared" . 0)
    ("source-inspected" . 1)
    ("obsolete-option-corrected" . 2)
    ("cross-host-build-blocked" . 3)
    ("linux-builder-required" . 4)
    ("image-built" . 5)
    ("sd-flashed" . 6)
    ("first-boot-observed" . 7)
    ("network-verified" . 8)
    ("kiosk-session-running" . 9)
    ("landing-page-visible" . 10)
    ("maintenance-ready" . 11)))

(defun normalize-kioskbeerli-task-id (task-or-id)
  (etypecase task-or-id
    (kioskbeerli-plan-task (id-of task-or-id))
    (string (string-downcase task-or-id))
    (symbol (string-downcase (symbol-name task-or-id)))))

(defun %task (id title &key dependencies preconditions effects status
                evidence-paths)
  (make-instance 'kioskbeerli-plan-task
                 :id id
                 :title title
                 :dependencies dependencies
                 :preconditions preconditions
                 :effects effects
                 :status status
                 :evidence-paths evidence-paths))

(defun %kioskbeerli-plan-tasks ()
  (list
   (%task "declare-target"
          "Declare physical Kioskberrli target"
          :status "declared"
          :effects '("Raspberry Pi 4 Model B target and landing-page URL are in scope.")
          :evidence-paths '("hyperdoc/Kioskberrli.html"))
   (%task "verify-source-tree"
          "Verify kiosk source tree"
          :dependencies '("declare-target")
          :preconditions '("hauptsache/kioskberrli source tree is available")
          :effects '("source tree can be inspected before build planning")
          :status "declared"
          :evidence-paths '("/Users/rgb/workspace/hauptsache/kioskberrli"))
   (%task "verify-nix-lock"
          "Verify pinned nixpkgs lock"
          :dependencies '("verify-source-tree")
          :preconditions '("flake.lock is present")
          :effects '("nixpkgs revision is part of build evidence")
          :status "declared"
          :evidence-paths '("/Users/rgb/workspace/hauptsache/kioskberrli/flake.lock"))
   (%task "evaluate-sd-image"
          "Evaluate SD-image target"
          :dependencies '("verify-nix-lock")
          :preconditions '("sdImage target is declared")
          :effects '("obsolete option failure is visible or cleared")
          :status "corrected"
          :evidence-paths '("hyperdoc/Kioskberrli sdImage imageSize Failure.html"))
   (%task "remove-obsolete-sdimage-option"
          "Remove obsolete sdImage.imageSize option"
          :dependencies '("evaluate-sd-image")
          :preconditions '("pinned module set lacks sdImage.imageSize")
          :effects '("kiosk.nix no longer sets removed option")
          :status "corrected"
          :evidence-paths '("hyperdoc/Kioskberrli sdImage imageSize Failure.html"))
   (%task "verify-obsolete-option-correction"
          "Verify obsolete option correction"
          :dependencies '("remove-obsolete-sdimage-option")
          :preconditions '("obsolete option edit is applied")
          :effects '("original sdImage.imageSize failure no longer blocks evaluation")
          :status "corrected"
          :evidence-paths '("hyperdoc/Kioskberrli sdImage imageSize Failure.html"))
   (%task "resolve-cross-host-build"
          "Resolve cross-host build blocker"
          :dependencies '("verify-obsolete-option-correction")
          :preconditions '("aarch64-linux image realization is attempted")
          :effects '("valid Linux builder requirement is explicit")
          :status "blocked"
          :evidence-paths '("hyperdoc/Kioskberrli Cross-Host Build Failure.html"))
   (%task "provision-linux-builder"
          "Provision suitable Linux builder"
          :dependencies '("resolve-cross-host-build")
          :preconditions '("local x86_64-darwin cannot realize target directly")
          :effects '("a valid Linux or remote builder is available")
          :status "missing-evidence"
          :evidence-paths '("missing: linux builder configuration record"))
   (%task "build-aarch64-image"
          "Build aarch64 SD image"
          :dependencies '("provision-linux-builder")
          :preconditions '("suitable builder exists")
          :effects '("result/sd-image artifact exists with provenance")
          :status "missing-evidence"
          :evidence-paths '("missing: successful nix build output"
                            "missing: artifact path"))
   (%task "flash-sd-card"
          "Flash SD card"
          :dependencies '("build-aarch64-image")
          :preconditions '("verified image artifact exists")
          :effects '("selected SD card contains image")
          :status "missing-evidence"
          :evidence-paths '("missing: flash record"))
   (%task "boot-pi"
          "Boot physical Raspberry Pi"
          :dependencies '("flash-sd-card")
          :preconditions '("flashed SD card is inserted")
          :effects '("first boot observed")
          :status "missing-evidence"
          :evidence-paths '("missing: first boot observation"))
   (%task "verify-network"
          "Verify network"
          :dependencies '("boot-pi")
          :preconditions '("Pi has booted")
          :effects '("network reachability is recorded")
          :status "missing-evidence"
          :evidence-paths '("missing: network check"))
   (%task "verify-kiosk-session"
          "Verify kiosk session"
          :dependencies '("verify-network")
          :preconditions '("network is up")
          :effects '("browser or kiosk shell starts automatically")
          :status "missing-evidence"
          :evidence-paths '("missing: kiosk session observation"))
   (%task "verify-landing-page"
          "Verify landing page"
          :dependencies '("verify-kiosk-session")
          :preconditions '("kiosk session is running")
          :effects '("hauptsache landing page is visible on display")
          :status "missing-evidence"
          :evidence-paths '("missing: landing-page display observation"))
   (%task "record-evidence"
          "Record evidence"
          :dependencies '("verify-landing-page")
          :preconditions '("observations exist")
          :effects '("trace records evidence or missing-evidence explicitly")
          :status "missing-evidence"
          :evidence-paths '("kioskberrli/trace.lisp"))
   (%task "mark-dashboard-status"
          "Mark dashboard status"
          :dependencies '("record-evidence")
          :preconditions '("trace has current progress")
          :effects '("dashboard can summarize blocked, corrected, verified, or missing-evidence state")
          :status "blocked"
          :evidence-paths '("hyperdoc/Kioskberrli Dashboard.html"))))

(defun %kioskbeerli-trace-entry-evidence-paths (entry)
  (mapcar #'path-of (evidence-references-of entry)))

(defun %kioskbeerli-task-progress-entry (task-id trace)
  (loop for entry in (reverse (entries-of trace))
        when (string= task-id (task-id-of entry))
          return entry))

(defun %apply-kioskbeerli-trace-to-task (task trace)
  (let ((entry (%kioskbeerli-task-progress-entry (id-of task) trace)))
    (when entry
      (setf (status-of task) (status-of entry)
            (evidence-paths-of task)
            (or (%kioskbeerli-trace-entry-evidence-paths entry)
                (evidence-paths-of task)))))
  task)

(defun %attach-kioskbeerli-plan-run (run)
  (dolist (task (tasks-of run) run)
    (setf (plan-run-of task) run)))

(defun kioskbeerli-planner-run (&key (execution-mode :plan-only)
                                  (trace (and (fboundp 'kioskbeerli-project-trace)
                                              (kioskbeerli-project-trace))))
  "Return a SHOP3-like plan object. This never runs Nix, flashes devices, or mutates external systems."
  (unless (eq execution-mode :plan-only)
    (error "Kioskberrli planner only supports :PLAN-ONLY execution, not ~S."
           execution-mode))
  (let ((tasks (%kioskbeerli-plan-tasks)))
    (when trace
      (dolist (task tasks)
        (%apply-kioskbeerli-trace-to-task task trace)))
    (%attach-kioskbeerli-plan-run
     (make-instance 'kioskbeerli-plan-run
                    :id "kioskbeerli-plan-only-run"
                    :title "Kioskberrli plan-only operational workflow"
                    :summary "Plan-only SHOP3-like task graph for source review, builder resolution, image build, flash, boot, display verification, and evidence recording."
                    :planner-kind :shop3-like
                    :execution-mode execution-mode
                    :dry-run-p t
                    :tasks tasks))))

(defun kioskberrli-planner-run (&rest args &key &allow-other-keys)
  (apply #'kioskbeerli-planner-run args))

(defun kioskbeerli-lookup-plan-task (task-or-id
                                      &key (run (kioskbeerli-planner-run)))
  (if (typep task-or-id 'kioskbeerli-plan-task)
      task-or-id
      (let ((task-id (normalize-kioskbeerli-task-id task-or-id)))
        (find task-id (tasks-of run) :key #'id-of :test #'string=))))

(defun kioskberrli-lookup-plan-task
    (task-or-id &rest args &key &allow-other-keys)
  (apply #'kioskbeerli-lookup-plan-task task-or-id args))

(defun kioskbeerli-task-plan (task-or-id &key (run (kioskbeerli-planner-run)))
  (let ((task (kioskbeerli-lookup-plan-task task-or-id :run run)))
    (or (and task (plan-run-of task))
        run)))

(defun kioskberrli-task-plan (task-or-id &rest args &key &allow-other-keys)
  (apply #'kioskbeerli-task-plan task-or-id args))

(defun kioskbeerli-task-progress
    (task-or-id &key (trace (kioskbeerli-project-trace)))
  (let ((task-id (normalize-kioskbeerli-task-id task-or-id)))
    (remove-if-not
     (lambda (entry)
       (string= task-id (task-id-of entry)))
     (entries-of trace))))

(defun kioskberrli-task-progress
    (task-or-id &rest args &key &allow-other-keys)
  (apply #'kioskbeerli-task-progress task-or-id args))

(defun kioskbeerli-task-state-link (task-or-id)
  (let* ((task-id (normalize-kioskbeerli-task-id task-or-id))
         (spec (find task-id *kioskbeerli-task-state-links*
                     :key #'first
                     :test #'string=)))
    (when spec
      (destructuring-bind (id event state summary) spec
        (make-instance 'kioskbeerli-task-state-link
                       :task-id id
                       :from-state nil
                       :scxml-event event
                       :scxml-state state
                       :summary summary)))))

(defun kioskberrli-task-state-link
    (task-or-id &rest args &key &allow-other-keys)
  (apply #'kioskbeerli-task-state-link task-or-id args))

(defun kioskbeerli-task-dependents
    (task-or-id &key (run (kioskbeerli-planner-run)))
  (let ((task-id (normalize-kioskbeerli-task-id task-or-id)))
    (remove-if-not
     (lambda (task)
       (member task-id (dependencies-of task) :test #'string=))
     (tasks-of run))))

(defun kioskberrli-task-dependents
    (task-or-id &rest args &key &allow-other-keys)
  (apply #'kioskbeerli-task-dependents task-or-id args))

(defun %kioskbeerli-state-rank (state)
  (or (cdr (assoc state *kioskbeerli-scxml-state-ranks* :test #'string=))
      -1))

(defun %kioskbeerli-progress-state-entry (trace)
  (loop with best-entry = nil
        with best-rank = -2
        for entry in (entries-of trace)
        for rank = (%kioskbeerli-state-rank (to-state-of entry))
        when (and (/= rank -1)
                  (not (string= "missing-evidence" (status-of entry)))
                  (> rank best-rank))
          do (setf best-entry entry
                   best-rank rank)
        finally (return best-entry)))

(defun kioskbeerli-current-scxml-state
    (&key (trace (kioskbeerli-project-trace)))
  (let ((entry (%kioskbeerli-progress-state-entry trace)))
    (if entry
        (to-state-of entry)
        (hyperdoc/scxml:scxml-chart-initial-state-of
         (kioskbeerli-behavior-chart)))))

(defun kioskberrli-current-scxml-state (&rest args &key &allow-other-keys)
  (apply #'kioskbeerli-current-scxml-state args))

(defun %kioskbeerli-task-order-index (task-id)
  (position task-id *kioskbeerli-required-task-ids* :test #'string=))

(defun kioskbeerli-next-missing-evidence-tasks
    (&key (trace (kioskbeerli-project-trace))
       (run (kioskbeerli-planner-run :trace trace)))
  (let* ((entry (%kioskbeerli-progress-state-entry trace))
         (anchor-index (and entry
                            (%kioskbeerli-task-order-index
                             (task-id-of entry)))))
    (remove-if-not
     (lambda (task)
       (and (or (null anchor-index)
                (> (or (%kioskbeerli-task-order-index (id-of task)) -1)
                   anchor-index))
            (member (status-of task) '("blocked" "missing-evidence")
                    :test #'string=)))
     (tasks-of run))))

(defun kioskberrli-next-missing-evidence-tasks (&rest args &key &allow-other-keys)
  (apply #'kioskbeerli-next-missing-evidence-tasks args))
