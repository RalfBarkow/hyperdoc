;;;; SCXML statechart accessors for Kioskbeerli Pi simulation.

(in-package :kioskbeerli/pi-simulation)

(defun pi-simulation-scxml-pathname ()
  (asdf:system-relative-pathname
   :kioskbeerli/pi-simulation
   "kioskbeerli/pi-simulation/kioskbeerli-pi-simulation.scxml"))

(defun pi-simulation-scxml-chart ()
  (hyperdoc/scxml:parse-scxml-file (pi-simulation-scxml-pathname)))

(defun pi-simulation-scxml-state-ids
    (&optional (chart (pi-simulation-scxml-chart)))
  (mapcar #'hyperdoc/scxml:scxml-state-id-of
          (hyperdoc/scxml:scxml-chart-states-of chart)))

(defun pi-simulation-task-state-links
    (&key (plan (make-pi-simulation-plan)))
  (mapcar
   (lambda (task)
     (make-instance 'pi-simulation-task-state-link
                    :task-id (id-of task)
                    :scxml-event (scxml-event-of task)
                    :scxml-state (state-id-of task)
                    :summary (format nil "~A advances to ~A."
                                     (id-of task)
                                     (state-id-of task))))
   (tasks-of plan)))
