(in-package #:dreyeck/workspace-operation)

(defclass workspace-operation nil
          ((id :initarg :id :initform nil :reader workspace-operation-id-of)
           (label :initarg :label :initform nil :reader
            workspace-operation-label-of)
           (subject-topic-id :initarg :subject-topic-id :initform nil :reader
            workspace-operation-subject-topic-id-of)
           (subject :initarg :subject :initform nil :reader
            workspace-operation-subject-of)
           (function-symbol :initarg :function-symbol :initform nil :reader
            workspace-operation-function-symbol-of)
           (result-topic-id :initarg :result-topic-id :initform nil :reader
            workspace-operation-result-topic-id-of)
           (last-result :initform nil :accessor
            workspace-operation-last-result-of)
           (intention :initarg :intention :initform nil :accessor
            workspace-operation-intention-of)
           (perlocutionary-action :initarg :perlocutionary-action :initform nil
            :accessor workspace-operation-perlocutionary-action-of)
           (propositional-object :initarg :propositional-object :initform nil
            :accessor workspace-operation-propositional-object-of)))

(defmethod print-object ((object workspace-operation) stream)
  (print-unreadable-object (object stream :type t :identity t)
    (princ (workspace-operation-label-of object) stream)))

(defclass workspace-operation-invocation nil
          ((operation :initarg :operation :initform nil :reader
            workspace-operation-invocation-operation-of)
           (status :initarg :status :initform nil :reader
            workspace-operation-invocation-status-of)
           (value :initarg :value :initform nil :reader
            workspace-operation-invocation-value-of)
           (condition :initarg :condition :initform nil :reader
            workspace-operation-invocation-condition-of)))

(defun invoke-workspace-operation (operation)
  (setf (workspace-operation-last-result-of operation)
          (funcall
           (symbol-function (workspace-operation-function-symbol-of operation))
           (workspace-operation-subject-of operation))))

(defun invoke-workspace-operation-recording-result (operation)
  (handler-case
   (let ((value (invoke-workspace-operation operation)))
     (make-instance 'workspace-operation-invocation :operation operation
                    :status :returned :value value))
   (error (condition)
          (make-instance 'workspace-operation-invocation :operation operation
                         :status :failed :condition condition))))
