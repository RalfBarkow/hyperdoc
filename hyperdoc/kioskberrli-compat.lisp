;;;; Compatibility wrappers for authored Kioskberrli HyperDoc links
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

;; The concrete dashboard/topic implementation lives in the canonical
;; KIOSKBERRLI system/package. DREYECK/KIOSKBEERLI remains a package nickname
;; and ASDF compatibility system only.
;; These wrappers preserve existing hyperdoc::kioskberrli-* page expressions
;; and the canonical visible Kioskberrli spelling.

(defun %dreyeck-kioskbeerli-call (name &rest args)
  (let* ((package (find-package :kioskberrli))
         (symbol (and package (find-symbol (string name) package))))
    (unless (and symbol (fboundp symbol))
      (asdf:load-system :kioskberrli)
      (setf package (find-package :kioskberrli)
            symbol (and package (find-symbol (string name) package))))
    (unless (and symbol (fboundp symbol))
      (error "Missing kioskberrli entry point ~A" name))
    (apply (symbol-function symbol) args)))

(defun kioskberrli-dashboard-status-vocabulary ()
  (%dreyeck-kioskbeerli-call 'kioskberrli-dashboard-status-vocabulary))

(defun kioskberrli-dashboard-stations ()
  (%dreyeck-kioskbeerli-call 'kioskberrli-dashboard-stations))

(defun kioskberrli-dashboard-status ()
  (%dreyeck-kioskbeerli-call 'kioskberrli-dashboard-status))

(defun kioskberrli-current-blocker ()
  (%dreyeck-kioskbeerli-call 'kioskberrli-current-blocker))

(defun kioskberrli-build-evidence-status ()
  (%dreyeck-kioskbeerli-call 'kioskberrli-build-evidence-status))

(defun kioskberrli-flash-boot-evidence-status ()
  (%dreyeck-kioskbeerli-call 'kioskberrli-flash-boot-evidence-status))

(defun kioskberrli-public-display-layout-status ()
  (%dreyeck-kioskbeerli-call 'kioskberrli-public-display-layout-status))

(defun kioskberrli-dashboard ()
  (%dreyeck-kioskbeerli-call 'kioskberrli-dashboard))

(defun kioskberrli-topic ()
  (%dreyeck-kioskbeerli-call 'kioskberrli-topic))

(defun kioskberrli-dashboard-topic ()
  (%dreyeck-kioskbeerli-call 'kioskberrli-dashboard-topic))

(defun kioskberrli-sdimage-imagesize-failure-topic ()
  (%dreyeck-kioskbeerli-call 'kioskberrli-sdimage-imagesize-failure-topic))

(defun kioskberrli-cross-host-build-failure-topic ()
  (%dreyeck-kioskbeerli-call 'kioskberrli-cross-host-build-failure-topic))

(defun salon-pi-4-kiosk-hardening-checklist-topic ()
  (%dreyeck-kioskbeerli-call 'salon-pi-4-kiosk-hardening-checklist-topic))

(defun kioskberrli-preconfigured-headless-image-topic ()
  (%dreyeck-kioskbeerli-call 'kioskberrli-preconfigured-headless-image-topic))

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

(defun kioskberrli-planner-and-trace-topic ()
  (%dreyeck-kioskbeerli-call 'kioskberrli-planner-and-trace-topic))

(defun kioskbeerli-planner-run (&rest args &key &allow-other-keys)
  (apply #'%dreyeck-kioskbeerli-call 'kioskbeerli-planner-run args))

(defun kioskberrli-planner-run (&rest args &key &allow-other-keys)
  (apply #'%dreyeck-kioskbeerli-call 'kioskberrli-planner-run args))

(defun kioskbeerli-behavior-chart ()
  (%dreyeck-kioskbeerli-call 'kioskbeerli-behavior-chart))

(defun kioskberrli-behavior-chart ()
  (%dreyeck-kioskbeerli-call 'kioskberrli-behavior-chart))

(defun kioskbeerli-project-trace ()
  (%dreyeck-kioskbeerli-call 'kioskbeerli-project-trace))

(defun kioskberrli-project-trace ()
  (%dreyeck-kioskbeerli-call 'kioskberrli-project-trace))

(defun kioskbeerli-latest-progress ()
  (%dreyeck-kioskbeerli-call 'kioskbeerli-latest-progress))

(defun kioskberrli-latest-progress ()
  (%dreyeck-kioskbeerli-call 'kioskberrli-latest-progress))

(defun record-kioskbeerli-progress (&rest args &key &allow-other-keys)
  (apply #'%dreyeck-kioskbeerli-call 'record-kioskbeerli-progress args))

(defun record-kioskberrli-progress (&rest args &key &allow-other-keys)
  (apply #'%dreyeck-kioskbeerli-call 'record-kioskberrli-progress args))

(defun kioskbeerli-lookup-plan-task
    (task-or-id &rest args &key &allow-other-keys)
  (apply #'%dreyeck-kioskbeerli-call
         'kioskbeerli-lookup-plan-task
         task-or-id
         args))

(defun kioskberrli-lookup-plan-task
    (task-or-id &rest args &key &allow-other-keys)
  (apply #'%dreyeck-kioskbeerli-call
         'kioskberrli-lookup-plan-task
         task-or-id
         args))

(defun kioskbeerli-task-plan
    (task-or-id &rest args &key &allow-other-keys)
  (apply #'%dreyeck-kioskbeerli-call
         'kioskbeerli-task-plan
         task-or-id
         args))

(defun kioskberrli-task-plan
    (task-or-id &rest args &key &allow-other-keys)
  (apply #'%dreyeck-kioskbeerli-call
         'kioskberrli-task-plan
         task-or-id
         args))

(defun kioskbeerli-task-progress
    (task-or-id &rest args &key &allow-other-keys)
  (apply #'%dreyeck-kioskbeerli-call
         'kioskbeerli-task-progress
         task-or-id
         args))

(defun kioskberrli-task-progress
    (task-or-id &rest args &key &allow-other-keys)
  (apply #'%dreyeck-kioskbeerli-call
         'kioskberrli-task-progress
         task-or-id
         args))

(defun kioskbeerli-task-state-link
    (task-or-id &rest args &key &allow-other-keys)
  (apply #'%dreyeck-kioskbeerli-call
         'kioskbeerli-task-state-link
         task-or-id
         args))

(defun kioskberrli-task-state-link
    (task-or-id &rest args &key &allow-other-keys)
  (apply #'%dreyeck-kioskbeerli-call
         'kioskberrli-task-state-link
         task-or-id
         args))

(defun kioskbeerli-task-dependents
    (task-or-id &rest args &key &allow-other-keys)
  (apply #'%dreyeck-kioskbeerli-call
         'kioskbeerli-task-dependents
         task-or-id
         args))

(defun kioskberrli-task-dependents
    (task-or-id &rest args &key &allow-other-keys)
  (apply #'%dreyeck-kioskbeerli-call
         'kioskberrli-task-dependents
         task-or-id
         args))

(defun kioskbeerli-current-scxml-state (&rest args &key &allow-other-keys)
  (apply #'%dreyeck-kioskbeerli-call 'kioskbeerli-current-scxml-state args))

(defun kioskberrli-current-scxml-state (&rest args &key &allow-other-keys)
  (apply #'%dreyeck-kioskbeerli-call 'kioskberrli-current-scxml-state args))

(defun kioskbeerli-next-missing-evidence-tasks (&rest args &key &allow-other-keys)
  (apply #'%dreyeck-kioskbeerli-call 'kioskbeerli-next-missing-evidence-tasks args))

(defun kioskberrli-next-missing-evidence-tasks (&rest args &key &allow-other-keys)
  (apply #'%dreyeck-kioskbeerli-call 'kioskberrli-next-missing-evidence-tasks args))

(defun kioskbeerli-record-boot-observed (&rest args &key &allow-other-keys)
  (apply #'%dreyeck-kioskbeerli-call 'kioskbeerli-record-boot-observed args))

(defun kioskberrli-record-boot-observed (&rest args &key &allow-other-keys)
  (apply #'%dreyeck-kioskbeerli-call 'kioskberrli-record-boot-observed args))
