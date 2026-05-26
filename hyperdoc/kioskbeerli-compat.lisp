;;;; Compatibility wrappers for authored Kioskbeerli HyperDoc links
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

;; The concrete dashboard/topic implementation lives in the canonical
;; KIOSKBEERLI system/package. DREYECK/KIOSKBEERLI remains a package nickname
;; and ASDF compatibility system only.
;; These wrappers preserve existing hyperdoc::kioskbeerli-* page expressions
;; and the canonical visible Kioskbeerli spelling.

(defun %dreyeck-kioskbeerli-call (name &rest args)
  (let* ((package (find-package :kioskbeerli))
         (symbol (and package (find-symbol (string name) package))))
    (unless (and symbol (fboundp symbol))
      (asdf:load-system :kioskbeerli)
      (setf package (find-package :kioskbeerli)
            symbol (and package (find-symbol (string name) package))))
    (unless (and symbol (fboundp symbol))
      (error "Missing kioskbeerli entry point ~A" name))
    (apply (symbol-function symbol) args)))

(defun kioskbeerli-dashboard-status-vocabulary ()
  (%dreyeck-kioskbeerli-call 'kioskbeerli-dashboard-status-vocabulary))

(defun kioskbeerli-dashboard-stations ()
  (%dreyeck-kioskbeerli-call 'kioskbeerli-dashboard-stations))

(defun kioskbeerli-dashboard-status ()
  (%dreyeck-kioskbeerli-call 'kioskbeerli-dashboard-status))

(defun kioskbeerli-current-blocker ()
  (%dreyeck-kioskbeerli-call 'kioskbeerli-current-blocker))

(defun kioskbeerli-build-evidence-status ()
  (%dreyeck-kioskbeerli-call 'kioskbeerli-build-evidence-status))

(defun kioskbeerli-flash-boot-evidence-status ()
  (%dreyeck-kioskbeerli-call 'kioskbeerli-flash-boot-evidence-status))

(defun kioskbeerli-public-display-layout-status ()
  (%dreyeck-kioskbeerli-call 'kioskbeerli-public-display-layout-status))

(defun kioskbeerli-dashboard ()
  (%dreyeck-kioskbeerli-call 'kioskbeerli-dashboard))

(defun kioskbeerli-topic ()
  (%dreyeck-kioskbeerli-call 'kioskbeerli-topic))

(defun kioskbeerli-dashboard-topic ()
  (%dreyeck-kioskbeerli-call 'kioskbeerli-dashboard-topic))

(defun kioskbeerli-sdimage-imagesize-failure-topic ()
  (%dreyeck-kioskbeerli-call 'kioskbeerli-sdimage-imagesize-failure-topic))

(defun kioskbeerli-cross-host-build-failure-topic ()
  (%dreyeck-kioskbeerli-call 'kioskbeerli-cross-host-build-failure-topic))

(defun salon-pi-4-kiosk-hardening-checklist-topic ()
  (%dreyeck-kioskbeerli-call 'salon-pi-4-kiosk-hardening-checklist-topic))

(defun kioskbeerli-preconfigured-headless-image-topic ()
  (%dreyeck-kioskbeerli-call 'kioskbeerli-preconfigured-headless-image-topic))

(defun runbook-build-and-flash-sd-image-topic ()
  (%dreyeck-kioskbeerli-call 'runbook-build-and-flash-sd-image-topic))

(defun preflight-rpi-sd-image-checklist-topic ()
  (%dreyeck-kioskbeerli-call 'preflight-rpi-sd-image-checklist-topic))

(defun official-rpi-sd-image-tutorial-topic ()
  (%dreyeck-kioskbeerli-call 'official-rpi-sd-image-tutorial-topic))

(defun two-installation-models-topic ()
  (%dreyeck-kioskbeerli-call 'two-installation-models-topic))

(defun invariant-boot-partition-must-be-big-enough-topic ()
  (%dreyeck-kioskbeerli-call 'invariant-boot-partition-must-be-big-enough-topic))

(defun prepare-aarch64-image-topic ()
  (%dreyeck-kioskbeerli-call 'prepare-aarch64-image-topic))

(defun hauptsache-entry-model-topic ()
  (%dreyeck-kioskbeerli-call 'hauptsache-entry-model-topic))

(defun kioskbeerli-planner-and-trace-topic ()
  (%dreyeck-kioskbeerli-call 'kioskbeerli-planner-and-trace-topic))

(defun kioskbeerli-planner-run (&rest args &key &allow-other-keys)
  (apply #'%dreyeck-kioskbeerli-call 'kioskbeerli-planner-run args))

(defun kioskbeerli-behavior-chart ()
  (%dreyeck-kioskbeerli-call 'kioskbeerli-behavior-chart))

(defun kioskbeerli-project-trace ()
  (%dreyeck-kioskbeerli-call 'kioskbeerli-project-trace))

(defun kioskbeerli-latest-progress ()
  (%dreyeck-kioskbeerli-call 'kioskbeerli-latest-progress))

(defun record-kioskbeerli-progress (&rest args &key &allow-other-keys)
  (apply #'%dreyeck-kioskbeerli-call 'record-kioskbeerli-progress args))

(defun kioskbeerli-lookup-plan-task
    (task-or-id &rest args &key &allow-other-keys)
  (apply #'%dreyeck-kioskbeerli-call
         'kioskbeerli-lookup-plan-task
         task-or-id
         args))

(defun kioskbeerli-task-plan
    (task-or-id &rest args &key &allow-other-keys)
  (apply #'%dreyeck-kioskbeerli-call
         'kioskbeerli-task-plan
         task-or-id
         args))

(defun kioskbeerli-task-progress
    (task-or-id &rest args &key &allow-other-keys)
  (apply #'%dreyeck-kioskbeerli-call
         'kioskbeerli-task-progress
         task-or-id
         args))

(defun kioskbeerli-task-state-link
    (task-or-id &rest args &key &allow-other-keys)
  (apply #'%dreyeck-kioskbeerli-call
         'kioskbeerli-task-state-link
         task-or-id
         args))

(defun kioskbeerli-task-dependents
    (task-or-id &rest args &key &allow-other-keys)
  (apply #'%dreyeck-kioskbeerli-call
         'kioskbeerli-task-dependents
         task-or-id
         args))

(defun kioskbeerli-current-scxml-state (&rest args &key &allow-other-keys)
  (apply #'%dreyeck-kioskbeerli-call 'kioskbeerli-current-scxml-state args))

(defun kioskbeerli-next-missing-evidence-tasks (&rest args &key &allow-other-keys)
  (apply #'%dreyeck-kioskbeerli-call 'kioskbeerli-next-missing-evidence-tasks args))

(defun kioskbeerli-record-boot-observed (&rest args &key &allow-other-keys)
  (apply #'%dreyeck-kioskbeerli-call 'kioskbeerli-record-boot-observed args))
