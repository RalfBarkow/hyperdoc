;;;; Safe local examples for the Kioskbeerli subsystem
;;
;;;; Copyright (c) 2026

(in-package :kioskbeerli)

;;
;; sdImage failure reference objects preserved from the existing Kioskbeerli
;; material.
;;

(defclass kioskbeerli-option-existence-evidence ()
  ((option-name :initarg :option-name :reader option-name-of)
   (exists-p :initarg :exists-p :reader exists-p-of)
   (evidence-kind :initarg :evidence-kind :reader evidence-kind-of)
   (explanation :initarg :explanation :reader explanation-of)))

(defmethod print-object ((object kioskbeerli-option-existence-evidence) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A => ~:[absent~;present~]"
            (option-name-of object)
            (exists-p-of object))))

(defclass kioskbeerli-sd-image-failure-context ()
  ((topic :initarg :topic :reader topic-of)
   (flake-lock :initarg :flake-lock :reader flake-lock-of)
   (nixpkgs :initarg :nixpkgs :reader nixpkgs-of)
   (modules :initarg :modules :reader modules-of)
   (removed-option :initarg :removed-option :reader removed-option-of)))

(defmethod print-object ((object kioskbeerli-sd-image-failure-context) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A ~A"
            (topic-of object)
            (removed-option-of object))))

(defclass kioskbeerli-patch-suggestion ()
  ((file :initarg :file :reader file-of)
   (change-kind :initarg :change-kind :reader change-kind-of)
   (target-option :initarg :target-option :reader target-option-of)
   (old-form :initarg :old-form :reader old-form-of)
   (new-form :initarg :new-form :reader new-form-of)
   (explanation :initarg :explanation :reader explanation-of)))

(defmethod print-object ((object kioskbeerli-patch-suggestion) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A in ~A"
            (change-kind-of object)
            (file-of object))))

(defclass kioskbeerli-build-command ()
  ((command :initarg :command :reader command-of)
   (purpose :initarg :purpose :reader purpose-of)))

(defmethod print-object ((object kioskbeerli-build-command) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (command-of object))))

(defclass kioskbeerli-correction-path ()
  ((steps :initarg :steps :reader steps-of)
   (summary :initarg :summary :reader summary-of)))

(defmethod print-object ((object kioskbeerli-correction-path) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (summary-of object))))

(defun kioskbeerli-flake-lock-pathname ()
  #P"/Users/rgb/workspace/hauptsache/kioskbeerli/flake.lock")

(defun kioskbeerli-nixpkgs-lock-object ()
  (list :input "nixpkgs"
        :flake-lock (kioskbeerli-flake-lock-pathname)
        :revision "cf59864ef8aa2e178cccedbe2c178185b0365705"
        :ref "nixos-unstable"
        :repo "NixOS/nixpkgs"))

(defun kioskbeerli-sd-image-module-reference (kind)
  (ecase kind
    (:aarch64
     (list :module :sd-image-aarch64
           :relative-path "nixos/modules/installer/sd-card/sd-image-aarch64.nix"))
    (:core
     (list :module :sd-image
           :relative-path "nixos/modules/installer/sd-card/sd-image.nix"))))

(defun kioskbeerli-sd-image-module-references ()
  (list (kioskbeerli-sd-image-module-reference :aarch64)
        (kioskbeerli-sd-image-module-reference :core)))

(defun kioskbeerli-option-exists? (context)
  (make-instance 'kioskbeerli-option-existence-evidence
                 :option-name (removed-option-of context)
                 :exists-p nil
                 :evidence-kind :failure-context
                 :explanation
                 (format nil
                         "The failure context records ~A as removed or absent in the pinned upstream SD-image API, so setting it should fail option evaluation."
                         (removed-option-of context))))

(defun kioskbeerli-suggested-patch (context)
  (make-instance 'kioskbeerli-patch-suggestion
                 :file #P"/Users/rgb/workspace/hauptsache/kioskbeerli/kiosk.nix"
                 :change-kind :remove-obsolete-option
                 :target-option (removed-option-of context)
                 :old-form "sdImage.imageSize = 4096;"
                 :new-form nil
                 :explanation
                 "Remove the obsolete option from kiosk.nix, then rerun the SD-image build against the pinned flake lock."))

(defun kioskbeerli-repro-build-command (context)
  (declare (ignore context))
  (make-instance 'kioskbeerli-build-command
                 :command "nix build .#nixosConfigurations.kioskbeerli.config.system.build.sdImage"
                 :purpose "Verify that the kiosk SD-image target now evaluates and builds on the pinned module set."))

(defun kioskbeerli-correction-path (context)
  (make-instance 'kioskbeerli-correction-path
                 :summary "visible error -> patch -> verify -> merge"
                 :steps
                 (list
                  (list :step :visible-error
                        :object context)
                  (list :step :patch
                        :object (kioskbeerli-suggested-patch context))
                  (list :step :verify
                        :object (kioskbeerli-repro-build-command context))
                  (list :step :merge
                        :object
                        "After a successful verification build, commit the correction and merge it through the normal repo workflow."))))

(defun kioskbeerli-sd-image-failure-context ()
  (make-instance 'kioskbeerli-sd-image-failure-context
                 :topic :sdimage-imagesize-failure
                 :flake-lock (kioskbeerli-flake-lock-pathname)
                 :nixpkgs (kioskbeerli-nixpkgs-lock-object)
                 :modules (kioskbeerli-sd-image-module-references)
                 :removed-option "sdImage.imageSize"))

(defexample kioskbeerli-dashboard-example
    "Return the first-class Kioskbeerli dashboard object."
  (kioskbeerli-dashboard))

(defexample kioskbeerli-plan-only-example
    "Return the Kioskbeerli SHOP3-like plan-only run object."
  (kioskbeerli-planner-run))

(defexample kioskbeerli-scxml-example
    "Parse and return the Kioskbeerli SCXML-like lifecycle chart."
  (kioskbeerli-behavior-chart))

(defexample kioskbeerli-record-progress-example
    "Record a safe local missing-evidence progress entry on an in-memory trace."
  (let ((trace (%default-kioskbeerli-trace)))
    (record-kioskbeerli-progress
     :trace trace
     :task-id "build-aarch64-image"
     :from-state "linux-builder-required"
     :to-state "linux-builder-required"
     :status "missing-evidence"
     :evidence-paths '("missing: successful aarch64 SD-image artifact")
     :note "Example records missing evidence explicitly and performs no build, flash, SSH, HTTP, or DMX mutation.")
    trace))
