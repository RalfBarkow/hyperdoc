;;;; Topic factories for the Kioskbeerli dreyeck subsystem
;;
;;;; Copyright (c) 2026

(in-package :kioskbeerli)

(defun %topic (&key id title summary references)
  (hyperdoc::make-topic
   :id id
   :title title
   :summary summary
   :references references))

(defun kioskbeerli-topic ()
  (%topic
   :id "kioskbeerli"
   :title "Kioskbeerli"
   :summary "Raspberry Pi 4 based kiosk case study for making the hauptsache landing page physically present in the salon."
   :references '("Kioskbeerli Dashboard"
                 "Kioskbeerli Planner and Trace"
                 "Kioskbeerli"
                 "Salon Pi 4 Kiosk Hardening Checklist"
                 "Runbook - Build and Flash NixOS SD Image for Kioskbeerli"
                 "Hauptsache Entry Model")))

(defun kioskbeerli-dashboard-topic ()
  (%topic
   :id "kioskbeerli-dashboard"
   :title "Kioskbeerli Dashboard"
   :summary "Root dashboard for Kioskbeerli status, blockers, evidence gaps, plan-only planner run, behavior state machine, trace, and related topic stations."
   :references '("Kioskbeerli"
                 "Kioskbeerli Planner and Trace"
                 "Kioskbeerli Cross-Host Build Failure"
                 "Salon Pi 4 Kiosk Hardening Checklist"
                 "Runbook - Build and Flash NixOS SD Image for Kioskbeerli")))

(defun kioskbeerli-planner-and-trace-topic ()
  (%topic
   :id "kioskbeerli-planner-and-trace"
   :title "Kioskbeerli Planner and Trace"
   :summary "Reference page for the Kioskbeerli plan-only workflow, SCXML-like lifecycle chart, and explicit evidence/missing-evidence trace."
   :references '("Kioskbeerli Dashboard"
                 "Kioskbeerli"
                 "Kioskbeerli Cross-Host Build Failure"
                 "Runbook - Build and Flash NixOS SD Image for Kioskbeerli")))

(defun kioskbeerli-sdimage-imagesize-failure-topic ()
  (%topic
   :id "kioskbeerli-sdimage-imagesize-failure"
   :title "Kioskbeerli sdImage imageSize Failure"
   :summary "Completed correction topic for the obsolete sdImage.imageSize option in the Kioskbeerli SD-image configuration."
   :references '("Kioskbeerli Dashboard"
                 "Kioskbeerli sdImage imageSize Failure"
                 "Kioskbeerli Cross-Host Build Failure")))

(defun kioskbeerli-cross-host-build-failure-topic ()
  (%topic
   :id "kioskbeerli-cross-host-build-failure"
   :title "Kioskbeerli Cross-Host Build Failure"
   :summary "Active Kioskbeerli blocker: the aarch64-linux SD-image target needs a valid Linux builder rather than the current x86_64-darwin host."
   :references '("Kioskbeerli Dashboard"
                 "Kioskbeerli Planner and Trace"
                 "Kioskbeerli Cross-Host Build Failure"
                 "Runbook - Build and Flash NixOS SD Image for Kioskbeerli")))

(defun salon-pi-4-kiosk-hardening-checklist-topic ()
  (%topic
   :id "salon-pi-4-kiosk-hardening-checklist"
   :title "Salon Pi 4 Kiosk Hardening Checklist"
   :summary "Checklist for turning the declared Kioskbeerli SD-image target into a credible maintained salon kiosk."
   :references '("Kioskbeerli Dashboard"
                 "Salon Pi 4 Kiosk Hardening Checklist"
                 "Kioskbeerli"
                 "Hauptsache Entry Model")))

(defun kioskbeerli-preconfigured-headless-image-topic ()
  (%topic
   :id "kioskbeerli-preconfigured-headless-image"
   :title "Kioskbeerli preconfigured headless image"
   :summary "Preferred maintenance target: a custom image enables OpenSSH, declares a normal admin user, seeds authorized keys, and avoids password/root SSH on first boot."
   :references '("Salon Pi 4 Kiosk Hardening Checklist"
                 "Runbook - Build and Flash NixOS SD Image for Kioskbeerli"
                 "Official Tutorial: NixOS SD Image on Raspberry Pi 4/400"
                 "Two Installation Models: SD Image vs Classic Installer")))

(defun runbook-build-and-flash-sd-image-topic ()
  (%topic
   :id "runbook-build-and-flash-sd-image"
   :title "Runbook - Build and Flash NixOS SD Image for Kioskbeerli"
   :summary "Operational sequence to obtain a named .img.zst artifact, decompress to .img, flash the .img, boot, and validate on Pi 4."
   :references '("Kioskbeerli Dashboard"
                 "Kioskbeerli Planner and Trace"
                 "Prepare the AArch64 image")))

(defun preflight-rpi-sd-image-checklist-topic ()
  (%topic
   :id "preflight-rpi-sd-image-checklist"
   :title "Pre-flight Checklist for Raspberry Pi NixOS SD Images"
   :summary "Checks before reboot to verify boot partition state, extlinux files, and partition labels."
   :references '("Kioskbeerli Dashboard"
                 "Prepare the AArch64 image")))

(defun official-rpi-sd-image-tutorial-topic ()
  (%topic
   :id "official-rpi-sd-image-tutorial"
   :title "Official Tutorial: NixOS SD Image on Raspberry Pi 4/400"
   :summary "Upstream nix.dev SD-image workflow: preinstalled image, first rebuild with nixos-rebuild boot, then reboot."
   :references '("Kioskbeerli Dashboard"
                 "Prepare the AArch64 image")))

(defun two-installation-models-topic ()
  (%topic
   :id "two-installation-models-sd-vs-classic"
   :title "Two Installation Models: SD Image vs Classic Installer"
   :summary "Distinguishes prebuilt SD-image workflow from classic installer workflow to avoid command-model drift."
   :references '("Kioskbeerli Dashboard"
                 "Prepare the AArch64 image")))

(defun invariant-boot-partition-must-be-big-enough-topic ()
  (%topic
   :id "invariant-boot-partition-must-be-big-enough"
   :title "Invariant: Boot Partition Must Be Big Enough"
   :summary "Operational invariant that the Raspberry Pi SD-image boot partition must have enough capacity for kernels, initrds, extlinux state, and generations."
   :references '("Kioskbeerli Dashboard"
                 "Invariant: Boot Partition Must Be Big Enough"
                 "Pre-flight Checklist for Raspberry Pi NixOS SD Images")))

(defun prepare-aarch64-image-topic ()
  (%topic
   :id "prepare-aarch64-image"
   :title "Prepare the AArch64 image"
   :summary "Preparation phase for obtaining and validating an aarch64 NixOS SD-image artifact before flashing."
   :references '("Kioskbeerli Dashboard"
                 "Runbook - Build and Flash NixOS SD Image for Kioskbeerli"
                 "Official Tutorial: NixOS SD Image on Raspberry Pi 4/400"
                 "Pre-flight Checklist for Raspberry Pi NixOS SD Images"
                 "Two Installation Models: SD Image vs Classic Installer")))

(defun hauptsache-entry-model-topic ()
  (%topic
   :id "hauptsache-entry-model"
   :title "Hauptsache Entry Model"
   :summary "Public-entry model that separates the landing page, FedWiki workspace, and physical Kioskbeerli device."
   :references '("Kioskbeerli Dashboard"
                 "Kioskbeerli Planner and Trace"
                 "Hauptsache Entry Model"
                 "Kioskbeerli")))
