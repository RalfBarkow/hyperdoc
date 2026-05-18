;;;; Topic factories for the Kioskberrli dreyeck subsystem
;;
;;;; Copyright (c) 2026

(in-package :dreyeck/kioskbeerli)

(defun %topic (&key id title summary references)
  (hyperdoc::make-topic
   :id id
   :title title
   :summary summary
   :references references))

(defun kioskberrli-topic ()
  (%topic
   :id "kioskberrli"
   :title "Kioskberrli"
   :summary "Raspberry Pi 4 based kiosk case study for making the hauptsache landing page physically present in the salon."
   :references '("Kioskberrli Dashboard"
                 "Kioskberrli Planner and Trace"
                 "Kioskberrli"
                 "Salon Pi 4 Kiosk Hardening Checklist"
                 "Runbook - Build and Flash NixOS SD Image for Kioskberrli"
                 "Hauptsache Entry Model")))

(defun kioskberrli-dashboard-topic ()
  (%topic
   :id "kioskberrli-dashboard"
   :title "Kioskberrli Dashboard"
   :summary "Root dashboard for Kioskberrli status, blockers, evidence gaps, plan-only planner run, behavior state machine, trace, and related topic stations."
   :references '("Kioskberrli"
                 "Kioskberrli Planner and Trace"
                 "Kioskberrli Cross-Host Build Failure"
                 "Salon Pi 4 Kiosk Hardening Checklist"
                 "Runbook - Build and Flash NixOS SD Image for Kioskberrli")))

(defun kioskberrli-planner-and-trace-topic ()
  (%topic
   :id "kioskberrli-planner-and-trace"
   :title "Kioskberrli Planner and Trace"
   :summary "Reference page for the Kioskberrli plan-only workflow, SCXML-like lifecycle chart, and explicit evidence/missing-evidence trace."
   :references '("Kioskberrli Dashboard"
                 "Kioskberrli"
                 "Kioskberrli Cross-Host Build Failure"
                 "Runbook - Build and Flash NixOS SD Image for Kioskberrli")))

(defun kioskberrli-sdimage-imagesize-failure-topic ()
  (%topic
   :id "kioskberrli-sdimage-imagesize-failure"
   :title "Kioskberrli sdImage imageSize Failure"
   :summary "Completed correction topic for the obsolete sdImage.imageSize option in the Kioskberrli SD-image configuration."
   :references '("Kioskberrli Dashboard"
                 "Kioskberrli sdImage imageSize Failure"
                 "Kioskberrli Cross-Host Build Failure")))

(defun kioskberrli-cross-host-build-failure-topic ()
  (%topic
   :id "kioskberrli-cross-host-build-failure"
   :title "Kioskberrli Cross-Host Build Failure"
   :summary "Active Kioskberrli blocker: the aarch64-linux SD-image target needs a valid Linux builder rather than the current x86_64-darwin host."
   :references '("Kioskberrli Dashboard"
                 "Kioskberrli Planner and Trace"
                 "Kioskberrli Cross-Host Build Failure"
                 "Runbook - Build and Flash NixOS SD Image for Kioskberrli")))

(defun salon-pi-4-kiosk-hardening-checklist-topic ()
  (%topic
   :id "salon-pi-4-kiosk-hardening-checklist"
   :title "Salon Pi 4 Kiosk Hardening Checklist"
   :summary "Checklist for turning the declared Kioskberrli SD-image target into a credible maintained salon kiosk."
   :references '("Kioskberrli Dashboard"
                 "Salon Pi 4 Kiosk Hardening Checklist"
                 "Kioskberrli"
                 "Hauptsache Entry Model")))

(defun runbook-build-and-flash-sd-image-topic ()
  (%topic
   :id "runbook-build-and-flash-sd-image"
   :title "Runbook - Build and Flash NixOS SD Image for Kioskberrli"
   :summary "Operational sequence to obtain a named .img.zst artifact, decompress to .img, flash the .img, boot, and validate on Pi 4."
   :references '("Kioskberrli Dashboard"
                 "Kioskberrli Planner and Trace"
                 "Prepare the AArch64 image")))

(defun preflight-rpi-sd-image-checklist-topic ()
  (%topic
   :id "preflight-rpi-sd-image-checklist"
   :title "Pre-flight Checklist for Raspberry Pi NixOS SD Images"
   :summary "Checks before reboot to verify boot partition state, extlinux files, and partition labels."
   :references '("Kioskberrli Dashboard"
                 "Prepare the AArch64 image")))

(defun official-rpi-sd-image-tutorial-topic ()
  (%topic
   :id "official-rpi-sd-image-tutorial"
   :title "Official Tutorial: NixOS SD Image on Raspberry Pi 4/400"
   :summary "Upstream nix.dev SD-image workflow: preinstalled image, first rebuild with nixos-rebuild boot, then reboot."
   :references '("Kioskberrli Dashboard"
                 "Prepare the AArch64 image")))

(defun two-installation-models-topic ()
  (%topic
   :id "two-installation-models-sd-vs-classic"
   :title "Two Installation Models: SD Image vs Classic Installer"
   :summary "Distinguishes prebuilt SD-image workflow from classic installer workflow to avoid command-model drift."
   :references '("Kioskberrli Dashboard"
                 "Prepare the AArch64 image")))

(defun invariant-boot-partition-must-be-big-enough-topic ()
  (%topic
   :id "invariant-boot-partition-must-be-big-enough"
   :title "Invariant: Boot Partition Must Be Big Enough"
   :summary "Operational invariant that the Raspberry Pi SD-image boot partition must have enough capacity for kernels, initrds, extlinux state, and generations."
   :references '("Kioskberrli Dashboard"
                 "Invariant: Boot Partition Must Be Big Enough"
                 "Pre-flight Checklist for Raspberry Pi NixOS SD Images")))

(defun prepare-aarch64-image-topic ()
  (%topic
   :id "prepare-aarch64-image"
   :title "Prepare the AArch64 image"
   :summary "Preparation phase for obtaining and validating an aarch64 NixOS SD-image artifact before flashing."
   :references '("Kioskberrli Dashboard"
                 "Runbook - Build and Flash NixOS SD Image for Kioskberrli"
                 "Official Tutorial: NixOS SD Image on Raspberry Pi 4/400"
                 "Pre-flight Checklist for Raspberry Pi NixOS SD Images"
                 "Two Installation Models: SD Image vs Classic Installer")))

(defun hauptsache-entry-model-topic ()
  (%topic
   :id "hauptsache-entry-model"
   :title "Hauptsache Entry Model"
   :summary "Public-entry model that separates the landing page, FedWiki workspace, and physical Kioskberrli device."
   :references '("Kioskberrli Dashboard"
                 "Kioskberrli Planner and Trace"
                 "Hauptsache Entry Model"
                 "Kioskberrli")))
