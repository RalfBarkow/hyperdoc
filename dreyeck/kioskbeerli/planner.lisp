;;;; SHOP3-like Kioskberrli plan-only planner objects
;;
;;;; Copyright (c) 2026

(in-package :dreyeck/kioskbeerli)

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

(defmethod print-object ((object kioskbeerli-plan-task) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A: ~A" (id-of object) (status-of object))))

(defmethod print-object ((object kioskbeerli-plan-run) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A ~A" (planner-kind-of object) (execution-mode-of object))))

(defun kioskbeerli-plan-task-ids ()
  (copy-list *kioskbeerli-required-task-ids*))

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
          :evidence-paths '("dreyeck/kioskbeerli/trace.lisp"))
   (%task "mark-dashboard-status"
          "Mark dashboard status"
          :dependencies '("record-evidence")
          :preconditions '("trace has current progress")
          :effects '("dashboard can summarize blocked, corrected, verified, or missing-evidence state")
          :status "blocked"
          :evidence-paths '("hyperdoc/Kioskberrli Dashboard.html"))))

(defun kioskbeerli-planner-run (&key (execution-mode :plan-only))
  "Return a SHOP3-like plan object. This never runs Nix, flashes devices, or mutates external systems."
  (unless (eq execution-mode :plan-only)
    (error "Kioskberrli planner only supports :PLAN-ONLY execution, not ~S."
           execution-mode))
  (make-instance 'kioskbeerli-plan-run
                 :id "kioskbeerli-plan-only-run"
                 :title "Kioskberrli plan-only operational workflow"
                 :summary "Plan-only SHOP3-like task graph for source review, builder resolution, image build, flash, boot, display verification, and evidence recording."
                 :planner-kind :shop3-like
                 :execution-mode execution-mode
                 :dry-run-p t
                 :tasks (%kioskbeerli-plan-tasks)))

(defun kioskberrli-planner-run (&rest args &key &allow-other-keys)
  (apply #'kioskbeerli-planner-run args))
