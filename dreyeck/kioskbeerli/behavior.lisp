;;;; SCXML-like behavior artifact for the Kioskberrli lifecycle
;;
;;;; Copyright (c) 2026

(in-package :dreyeck/kioskbeerli)

(defun kioskbeerli-behavior-scxml-pathname ()
  (asdf:system-relative-pathname
   :dreyeck/kioskbeerli
   "dreyeck/kioskbeerli/kioskbeerli.scxml"))

(defun kioskbeerli-behavior-chart ()
  (hyperdoc/scxml:parse-scxml-file (kioskbeerli-behavior-scxml-pathname)))

(defun kioskberrli-behavior-chart ()
  (kioskbeerli-behavior-chart))

(defun kioskbeerli-behavior-state-ids (&optional (chart (kioskbeerli-behavior-chart)))
  (mapcar #'hyperdoc/scxml:scxml-state-id-of
          (hyperdoc/scxml:scxml-chart-states-of chart)))

(defun kioskbeerli-behavior-events (&optional (chart (kioskbeerli-behavior-chart)))
  (remove-duplicates
   (loop for state in (hyperdoc/scxml:scxml-chart-states-of chart)
         append (mapcar #'hyperdoc/scxml:scxml-transition-event-of
                        (hyperdoc/scxml:scxml-state-transitions-of state)))
   :test #'string=))
