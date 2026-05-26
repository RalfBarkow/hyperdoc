;;;; SCXML-like behavior artifact for the Kioskbeerli lifecycle
;;
;;;; Copyright (c) 2026

(in-package :kioskbeerli)

(defun %first-existing-kioskbeerli-pathname (&rest relative-paths)
  (loop for relative-path in relative-paths
        for pathname = (asdf:system-relative-pathname :kioskbeerli
                                                      relative-path)
        when (probe-file pathname)
          return pathname
        finally (return (asdf:system-relative-pathname
                         :kioskbeerli
                         (first relative-paths)))))

(defun kioskbeerli-behavior-scxml-pathname ()
  (%first-existing-kioskbeerli-pathname
   "kioskbeerli/kioskbeerli.scxml"
   "src/kioskbeerli.scxml"))

(defun kioskbeerli-behavior-chart ()
  (hyperdoc/scxml:parse-scxml-file (kioskbeerli-behavior-scxml-pathname)))

(defun kioskbeerli-behavior-state-ids (&optional (chart (kioskbeerli-behavior-chart)))
  (mapcar #'hyperdoc/scxml:scxml-state-id-of
          (hyperdoc/scxml:scxml-chart-states-of chart)))

(defun kioskbeerli-behavior-events (&optional (chart (kioskbeerli-behavior-chart)))
  (remove-duplicates
   (loop for state in (hyperdoc/scxml:scxml-chart-states-of chart)
         append (mapcar #'hyperdoc/scxml:scxml-transition-event-of
                        (hyperdoc/scxml:scxml-state-transitions-of state)))
   :test #'string=))
