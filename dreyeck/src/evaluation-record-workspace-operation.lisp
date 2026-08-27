(in-package #:dreyeck/evaluation-record)

(defmethod evaluation-specification-of
           (
            (record
             dreyeck/workspace-operation:workspace-operation-invocation))
  (dreyeck/workspace-operation:workspace-operation-invocation-operation-of
   record))

(defmethod evaluation-input-of
           (
            (record
             dreyeck/workspace-operation:workspace-operation-invocation))
  (dreyeck/workspace-operation:workspace-operation-subject-of
   (dreyeck/workspace-operation:workspace-operation-invocation-operation-of
    record)))

(defmethod evaluation-status-of
           (
            (record
             dreyeck/workspace-operation:workspace-operation-invocation))
  (dreyeck/workspace-operation:workspace-operation-invocation-status-of record))

(defmethod evaluation-result-of
           (
            (record
             dreyeck/workspace-operation:workspace-operation-invocation))
  (dreyeck/workspace-operation:workspace-operation-invocation-value-of record))

(defmethod evaluation-trace-of
           (
            (record
             dreyeck/workspace-operation:workspace-operation-invocation))
  (declare (ignore record))
  nil)

(defmethod evaluation-evidence-of
           (
            (record
             dreyeck/workspace-operation:workspace-operation-invocation))
  (dreyeck/workspace-operation:workspace-operation-invocation-condition-of
   record))

(defmethod evaluation-failure-of
           (
            (record
             dreyeck/workspace-operation:workspace-operation-invocation))
  (dreyeck/workspace-operation:workspace-operation-invocation-condition-of
   record))

(defmethod evaluation-started-at-of
           (
            (record
             dreyeck/workspace-operation:workspace-operation-invocation))
  (declare (ignore record))
  nil)

(defmethod evaluation-finished-at-of
           (
            (record
             dreyeck/workspace-operation:workspace-operation-invocation))
  (declare (ignore record))
  nil)

(defmethod evaluation-identity-of
           (
            (record
             dreyeck/workspace-operation:workspace-operation-invocation))
  (declare (ignore record))
  nil)

(defmethod evaluation-annotation-of
           (
            (record
             dreyeck/workspace-operation:workspace-operation-invocation))
  (declare (ignore record))
  nil)
