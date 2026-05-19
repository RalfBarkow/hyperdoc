;;;; First-class dashboard objects for the Kioskberrli case study
;;
;;;; Copyright (c) 2026

(in-package :dreyeck/kioskbeerli)

(defparameter *kioskberrli-dashboard-status-vocabulary*
  '("declared" "blocked" "corrected" "missing evidence" "verified" "unknown"))

(defclass kioskberrli-dashboard-status ()
  ((id :accessor id-of :initarg :id)
   (section :accessor section-of :initarg :section)
   (status :accessor status-of :initarg :status)
   (summary :accessor summary-of :initarg :summary)
   (evidence :accessor evidence-of :initarg :evidence :initform nil)
   (missing-evidence :accessor missing-evidence-of
                     :initarg :missing-evidence
                     :initform nil)
   (next-action :accessor next-action-of :initarg :next-action :initform nil)
   (related-stations :accessor related-stations-of
                     :initarg :related-stations
                     :initform nil)))

(defclass kioskberrli-topic-dashboard ()
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (summary :accessor summary-of :initarg :summary)
   (status-vocabulary :accessor status-vocabulary-of
                      :initarg :status-vocabulary)
   (sections :accessor sections-of :initarg :sections)
   (stations :accessor stations-of :initarg :stations)
   (planner-run :accessor planner-run-of :initarg :planner-run)
   (behavior-chart :accessor behavior-chart-of :initarg :behavior-chart)
   (project-trace :accessor project-trace-of :initarg :project-trace)))

(defmethod print-object ((object kioskberrli-dashboard-status) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A: ~A" (section-of object) (status-of object))))

(defmethod print-object ((object kioskberrli-topic-dashboard) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defun kioskberrli-dashboard-status-vocabulary ()
  (copy-list *kioskberrli-dashboard-status-vocabulary*))

(defun ensure-kioskberrli-dashboard-status (status)
  (unless (member status *kioskberrli-dashboard-status-vocabulary*
                  :test #'string=)
    (error "Unknown Kioskberrli dashboard status ~S" status))
  status)

(defun make-kioskberrli-dashboard-status
    (&key id section status summary evidence missing-evidence next-action
       related-stations)
  (make-instance 'kioskberrli-dashboard-status
                 :id id
                 :section section
                 :status (ensure-kioskberrli-dashboard-status status)
                 :summary summary
                 :evidence evidence
                 :missing-evidence missing-evidence
                 :next-action next-action
                 :related-stations related-stations))

(defun kioskberrli-dashboard-stations ()
  '("Kioskberrli"
    "Kioskberrli sdImage imageSize Failure"
    "Kioskberrli Cross-Host Build Failure"
    "Salon Pi 4 Kiosk Hardening Checklist"
    "Runbook - Build and Flash NixOS SD Image for Kioskberrli"
    "Pre-flight Checklist for Raspberry Pi NixOS SD Images"
    "Official Tutorial: NixOS SD Image on Raspberry Pi 4/400"
    "Two Installation Models: SD Image vs Classic Installer"
    "Invariant: Boot Partition Must Be Big Enough"
    "Prepare the AArch64 image"
    "Hauptsache Entry Model"))

(defun kioskberrli-dashboard-status ()
  (make-kioskberrli-dashboard-status
   :id "kioskberrli-current-status"
   :section "Current status"
   :status "blocked"
   :summary "The Kioskberrli system is declared, the obsolete sdImage.imageSize source error is corrected, and the current blocker is the missing valid Linux build environment for the aarch64 SD image."
   :evidence '("Kioskberrli sdImage imageSize Failure records the corrected source-level option removal."
               "Kioskberrli Cross-Host Build Failure records the active aarch64-linux build-host mismatch."
               "Operator reported being logged in as nixos on the booted Raspberry Pi, which verifies first boot only.")
   :missing-evidence '("successful project SD-image build on a valid Linux builder"
                       "flash, network, kiosk-session, and landing-page evidence from the physical Pi")
   :next-action "Rerun the project SD-image build on a valid Linux builder or through a configured remote Linux builder, then record the resulting artifact."
   :related-stations '("Kioskberrli Cross-Host Build Failure"
                       "Runbook - Build and Flash NixOS SD Image for Kioskberrli")))

(defun kioskberrli-current-blocker ()
  (make-kioskberrli-dashboard-status
   :id "kioskberrli-current-blocker"
   :section "Current blocker"
   :status "blocked"
   :summary "The source correction moved the build past the removed option, but the declared image target still requires an aarch64-linux build result that the current x86_64-darwin host cannot realize locally."
   :evidence '("Required system: aarch64-linux"
               "Current system: x86_64-darwin")
   :missing-evidence '("build log from a valid aarch64-linux or suitable Linux builder")
   :next-action "Build on a Linux machine or configure a remote Linux builder, then rerun the same sdImage target."
   :related-stations '("Kioskberrli Cross-Host Build Failure"
                       "Runbook - Build and Flash NixOS SD Image for Kioskberrli")))

(defun kioskberrli-build-evidence-status ()
  (make-kioskberrli-dashboard-status
   :id "kioskberrli-build-evidence"
   :section "Build evidence"
   :status "missing evidence"
   :summary "The correction for sdImage.imageSize is recorded as corrected, but no successful project SD-image artifact has been recorded from a valid Linux builder."
   :evidence '("sdImage.imageSize correction path is documented as corrected."
               "Runbook names the project build target.")
   :missing-evidence '("successful nix build output for .#nixosConfigurations.kioskberrli.config.system.build.sdImage"
                       "artifact path and exact build provenance")
   :next-action "Capture the successful builder, command, artifact path, and nixpkgs revision once the build completes."
   :related-stations '("Kioskberrli sdImage imageSize Failure"
                       "Kioskberrli Cross-Host Build Failure"
                       "Runbook - Build and Flash NixOS SD Image for Kioskberrli")))

(defun kioskberrli-flash-boot-evidence-status ()
  (make-kioskberrli-dashboard-status
   :id "kioskberrli-flash-boot-evidence"
   :section "Flash / boot evidence"
   :status "missing evidence"
   :summary "Boot evidence is now recorded from the operator's nixos login on the booted Raspberry Pi. Flash, network, kiosk-session, and landing-page evidence remain missing."
   :evidence '("logged in as nixos on the booted Raspberry Pi")
   :missing-evidence '("SD-card flash record"
                       "network reachability"
                       "automatic kiosk session startup")
   :next-action "Record network reachability separately, then kiosk-session startup and landing-page display; do not infer those from first boot alone."
   :related-stations '("Pre-flight Checklist for Raspberry Pi NixOS SD Images"
                       "Invariant: Boot Partition Must Be Big Enough")))

(defun kioskberrli-public-display-layout-status ()
  (make-kioskberrli-dashboard-status
   :id "kioskberrli-public-display-layout"
   :section "Public-display layout state"
   :status "declared"
   :summary "The public-display target is declared as the hauptsache landing page on a salon wall screen, but the physical kiosk display loop has not yet been verified."
   :evidence '("Landing page target: https://hauptsache.dreyeck.ch/assets/home/index.html"
               "Hauptsache Entry Model separates public entry surface, wiki workspace, and kiosk device.")
   :missing-evidence '("browser starts automatically on the Pi"
                       "landing page appears after reboot and after browser/session recovery")
   :next-action "Verify the kiosk session on target hardware after build and boot evidence exists."
   :related-stations '("Hauptsache Entry Model"
                       "Salon Pi 4 Kiosk Hardening Checklist")))

(defun kioskberrli-dashboard ()
  (make-instance 'kioskberrli-topic-dashboard
                 :id "kioskberrli-dashboard"
                 :title "Kioskberrli Dashboard"
                 :summary "Root dashboard object for Kioskberrli operational status, planner, behavior chart, trace, evidence, and related topic stations."
                 :status-vocabulary (kioskberrli-dashboard-status-vocabulary)
                 :sections (list (kioskberrli-dashboard-status)
                                 (kioskberrli-current-blocker)
                                 (kioskberrli-build-evidence-status)
                                 (kioskberrli-flash-boot-evidence-status)
                                 (kioskberrli-public-display-layout-status))
                 :stations (kioskberrli-dashboard-stations)
                 :planner-run (kioskbeerli-planner-run)
                 :behavior-chart (kioskbeerli-behavior-chart)
                 :project-trace (kioskbeerli-project-trace)))

(defun kioskbeerli-dashboard ()
  (kioskberrli-dashboard))

(defun kioskbeerli-dashboard-status ()
  (kioskberrli-dashboard-status))

(defun kioskbeerli-dashboard-status-vocabulary ()
  (kioskberrli-dashboard-status-vocabulary))

(defun kioskbeerli-dashboard-stations ()
  (kioskberrli-dashboard-stations))

(defun kioskbeerli-current-blocker ()
  (kioskberrli-current-blocker))

(defun kioskbeerli-build-evidence-status ()
  (kioskberrli-build-evidence-status))
