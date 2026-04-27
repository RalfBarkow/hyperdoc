;;;; SCXML chart validator for HyperDoc compiler MVP
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc/scxml)

(defclass scxml-validation-finding ()
  ((severity :reader scxml-validation-finding-severity-of
             :initarg :severity)
   (code :reader scxml-validation-finding-code-of
         :initarg :code)
   (message :reader scxml-validation-finding-message-of
            :initarg :message)
   (context :reader scxml-validation-finding-context-of
            :initarg :context
            :initform nil)))

(defun %make-finding (severity code message &optional context)
  (make-instance 'scxml-validation-finding
                 :severity severity
                 :code code
                 :message message
                 :context context))

(defun %append-finding (findings severity code message &optional context)
  (push (%make-finding severity code message context) findings)
  findings)

(defun %error-finding-p (finding)
  (eq :error (scxml-validation-finding-severity-of finding)))

(defun %state-index-by-id (chart)
  (let ((index (make-hash-table :test #'equal)))
    (dolist (state (scxml-chart-states-of chart))
      (setf (gethash (scxml-state-id-of state) index) state))
    index))

(defun %transition-target-ids (transition)
  (remove-if (lambda (token)
               (string= token ""))
             (uiop:split-string (or (scxml-transition-target-of transition) "")
                                :separator '(#\Space #\Tab #\Newline #\Return))))

(defun validate-scxml-chart (chart)
  (let ((findings '())
        (seen-state-ids (make-hash-table :test #'equal)))
    (dolist (problem (scxml-chart-parse-problems-of chart))
      (setf findings
            (%append-finding findings
                             (or (getf problem :severity) :error)
                             (or (getf problem :code) :parse-problem)
                             (or (getf problem :message)
                                 "SCXML parse problem")
                             (getf problem :context))))

    (let ((initial-state (scxml-chart-initial-state-of chart)))
      (when (or (null initial-state)
                (string= ""
                         (string-trim '(#\Space #\Tab #\Newline #\Return)
                                      initial-state)))
        (setf findings
              (%append-finding findings
                               :error
                               :missing-initial-state
                               "SCXML chart must define a non-empty initial state."))))

    (dolist (state (scxml-chart-states-of chart))
      (let ((state-id (scxml-state-id-of state)))
        (when (or (null state-id)
                  (string= ""
                           (string-trim '(#\Space #\Tab #\Newline #\Return)
                                        state-id)))
          (setf findings
                (%append-finding findings
                                 :error
                                 :state-missing-id
                                 "State/final must define a non-empty id attribute.")))
        (when state-id
          (if (gethash state-id seen-state-ids)
              (setf findings
                    (%append-finding findings
                                     :error
                                     :duplicate-state-id
                                     (format nil "Duplicate state id ~S." state-id)
                                     (list :state-id state-id)))
              (setf (gethash state-id seen-state-ids) t)))))

    (let* ((initial-state (scxml-chart-initial-state-of chart))
           (state-index (%state-index-by-id chart)))
      (when (and initial-state
                 (not (gethash initial-state state-index)))
        (setf findings
              (%append-finding findings
                               :error
                               :initial-state-missing
                               (format nil "Initial state ~S is not defined." initial-state)
                               (list :initial-state initial-state)))))

    (let ((state-index (%state-index-by-id chart)))
      (dolist (state (scxml-chart-states-of chart))
        (let ((state-id (scxml-state-id-of state)))
          (when (and (scxml-state-final-p-of state)
                     (scxml-state-transitions-of state))
            (setf findings
                  (%append-finding
                   findings
                   :error
                   :final-state-has-transitions
                   (format nil "Final state ~S must not have outgoing transitions in MVP subset."
                           state-id)
                   (list :state-id state-id))))
          (dolist (transition (scxml-state-transitions-of state))
            (let* ((target (scxml-transition-target-of transition))
                   (target-ids (%transition-target-ids transition)))
              (dolist (target-id target-ids)
                (unless (gethash target-id state-index)
                  (setf findings
                        (%append-finding findings
                                         :error
                                         :unknown-transition-target
                                         (format nil "Transition target ~S from state ~S is not defined."
                                                 target-id
                                                 state-id)
                                         (list :state-id state-id
                                               :target target-id
                                               :transition-id
                                               (scxml-transition-id-of transition))))))
              (when (and target
                         (null target-ids))
                (setf findings
                      (%append-finding findings
                                       :error
                                       :transition-missing-target
                                       (format nil "Transition from state ~S has an empty target."
                                               state-id)
                                       (list :state-id state-id
                                             :transition-id
                                             (scxml-transition-id-of transition))))))))))

    (nreverse findings)))

(defun scxml-chart-valid-p (chart)
  (notany #'%error-finding-p
          (validate-scxml-chart chart)))
