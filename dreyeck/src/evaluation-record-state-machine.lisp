(in-package #:dreyeck/evaluation-record)

(defmethod evaluation-specification-of
           ((record dreyeck/state-machine:state-machine-run))
  (dreyeck/state-machine:state-machine-run-machine-of record))

(defmethod evaluation-input-of
           ((record dreyeck/state-machine:state-machine-run))
  (dreyeck/state-machine:state-machine-run-input-of record))

(defmethod evaluation-status-of
           ((record dreyeck/state-machine:state-machine-run))
  (dreyeck/state-machine:state-machine-run-status-of record))

(defmethod evaluation-result-of
           ((record dreyeck/state-machine:state-machine-run))
  (dreyeck/state-machine:state-machine-run-current-state-of record))

(defmethod evaluation-trace-of
           ((record dreyeck/state-machine:state-machine-run))
  (list :visited-states
        (dreyeck/state-machine:state-machine-run-visited-states-of record)
        :transition-trace
        (dreyeck/state-machine:state-machine-run-transition-trace-of record)))

(defmethod evaluation-evidence-of
           ((record dreyeck/state-machine:state-machine-run))
  (dreyeck/state-machine:state-machine-run-evidence-trace-of record))

(defmethod evaluation-failure-of
           ((record dreyeck/state-machine:state-machine-run))
  (dreyeck/state-machine:state-machine-run-failure-classification-of record))

(defmethod evaluation-started-at-of
           ((record dreyeck/state-machine:state-machine-run))
  (dreyeck/state-machine:state-machine-run-start-time-of record))

(defmethod evaluation-finished-at-of
           ((record dreyeck/state-machine:state-machine-run))
  (dreyeck/state-machine:state-machine-run-end-time-of record))

(defmethod evaluation-identity-of
           ((record dreyeck/state-machine:state-machine-run))
  (dreyeck/state-machine:id-of record))

(defmethod evaluation-annotation-of
           ((record dreyeck/state-machine:state-machine-run))
  (dreyeck/state-machine:state-machine-run-notes-of record))
