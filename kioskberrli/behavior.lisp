;;;; SCXML-like behavior artifact for the Kioskberrli lifecycle
;;
;;;; Copyright (c) 2026

(in-package :kioskberrli)

(defun %first-existing-kioskberrli-pathname (&rest relative-paths)
  (loop for relative-path in relative-paths
        for pathname = (asdf:system-relative-pathname :kioskberrli
                                                      relative-path)
        when (probe-file pathname)
          return pathname
        finally (return (asdf:system-relative-pathname
                         :kioskberrli
                         (first relative-paths)))))

(defun kioskberrli-behavior-scxml-pathname ()
  (%first-existing-kioskberrli-pathname
   "kioskberrli/kioskberrli.scxml"
   "src/kioskberrli.scxml"))

(defun kioskbeerli-behavior-scxml-pathname ()
  (kioskberrli-behavior-scxml-pathname))

(defun kioskbeerli-behavior-chart ()
  (hyperdoc/scxml:parse-scxml-file (kioskbeerli-behavior-scxml-pathname)))

(defun kioskberrli-behavior-chart ()
  (kioskbeerli-behavior-chart))

(defun kioskbeerli-behavior-state-ids (&optional (chart (kioskbeerli-behavior-chart)))
  (mapcar #'hyperdoc/scxml:scxml-state-id-of
          (hyperdoc/scxml:scxml-chart-states-of chart)))

(defun kioskberrli-behavior-state-ids (&optional (chart (kioskberrli-behavior-chart)))
  (kioskbeerli-behavior-state-ids chart))

(defun kioskbeerli-behavior-events (&optional (chart (kioskbeerli-behavior-chart)))
  (remove-duplicates
   (loop for state in (hyperdoc/scxml:scxml-chart-states-of chart)
         append (mapcar #'hyperdoc/scxml:scxml-transition-event-of
                        (hyperdoc/scxml:scxml-state-transitions-of state)))
   :test #'string=))

(defun kioskberrli-behavior-events (&optional (chart (kioskberrli-behavior-chart)))
  (kioskbeerli-behavior-events chart))
