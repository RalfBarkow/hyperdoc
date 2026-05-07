;;;; ANSI Common Lisp code generation for SCXML MVP charts
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc/scxml)

(defun %blank-or-empty-string-p (value)
  (or (null value)
      (string= ""
               (string-trim '(#\Space #\Tab #\Newline #\Return)
                            value))))

(defun %sanitize-symbol-token (value &key (fallback "SCXML"))
  (let* ((input (if (%blank-or-empty-string-p value)
                    fallback
                    (string value)))
         (upcase (string-upcase input))
         (sanitized
          (with-output-to-string (stream)
            (loop for char across upcase
                  do (if (or (alphanumericp char)
                             (char= char #\-)
                             (char= char #\_))
                         (write-char char stream)
                         (write-char #\- stream))))))
    (if (or (%blank-or-empty-string-p sanitized)
            (digit-char-p (char sanitized 0)))
        (format nil "SCXML-~A" sanitized)
        sanitized)))

(defun %sanitize-package-token (value &key (fallback "SCXML"))
  (let* ((input (if (%blank-or-empty-string-p value)
                    fallback
                    (string value)))
         (upcase (string-upcase input))
         (sanitized
          (with-output-to-string (stream)
            (loop for char across upcase
                  do (if (or (alphanumericp char)
                             (char= char #\-)
                             (char= char #\_)
                             (char= char #\/))
                         (write-char char stream)
                         (write-char #\- stream))))))
    (if (or (%blank-or-empty-string-p sanitized)
            (digit-char-p (char sanitized 0)))
        (format nil "SCXML-~A" sanitized)
        sanitized)))

(defun %default-generated-package-name (chart)
  (format nil "HYPERDOC/SCXML/GENERATED/~A"
          (%sanitize-package-token (scxml-chart-name-of chart)
                                   :fallback "CHART")))

(defun %default-generated-function-name (chart)
  (format nil "RUN-~A"
          (%sanitize-symbol-token (scxml-chart-name-of chart)
                                  :fallback "SCXML-CHART")))

(defun %resolve-package-name (chart package-name)
  (if package-name
      (%sanitize-package-token package-name
                               :fallback (%default-generated-package-name chart))
      (%default-generated-package-name chart)))

(defun %resolve-function-name (chart function-name)
  (if function-name
      (%sanitize-symbol-token function-name
                              :fallback (%default-generated-function-name chart))
      (%default-generated-function-name chart)))

(defun %chart-error-findings (chart)
  (remove-if-not (lambda (finding)
                   (eq :error
                       (scxml-validation-finding-severity-of finding)))
                 (validate-scxml-chart chart)))

(defun %finding->string (finding)
  (format nil "[~A] ~A: ~A"
          (scxml-validation-finding-severity-of finding)
          (scxml-validation-finding-code-of finding)
          (scxml-validation-finding-message-of finding)))

(defun %assert-chart-valid-for-codegen (chart)
  (let ((errors (%chart-error-findings chart)))
    (when errors
      (error "SCXML chart validation failed before code generation:~%~{~A~%~}"
             (mapcar #'%finding->string errors)))))

(defun %state-id-list (chart)
  (mapcar #'scxml-state-id-of
          (scxml-chart-states-of chart)))

(defun %final-state-id-list (chart)
  (loop for state in (scxml-chart-states-of chart)
        when (scxml-state-final-p-of state)
        collect (scxml-state-id-of state)))

(defun %log-action-message (action)
  (let ((label (getf (scxml-action-attributes-of action) :label))
        (expr (getf (scxml-action-attributes-of action) :expr)))
    (cond
      ((and label expr)
       (format nil "~A ~A" label expr))
      (label
       label)
      (expr
       (format nil "~A" expr))
      (t
       "LOG"))))

(defun %state-onentry-action-data (state)
  (loop for action in (scxml-state-onentry-actions-of state)
        collect
        (ecase (scxml-action-kind-of action)
          (:log
           (list :log
                 (%log-action-message action)))
          (:raise
           (list :raise
                 (getf (scxml-action-attributes-of action) :event))))))

(defun %state-transition-data (state)
  (loop for transition in (scxml-state-transitions-of state)
        collect (cons (scxml-transition-event-of transition)
                      (scxml-transition-target-of transition))))

(defun %chart-state-action-table (chart)
  (loop for state in (scxml-chart-states-of chart)
        collect (list (scxml-state-id-of state)
                      (%state-onentry-action-data state))))

(defun %chart-state-transition-table (chart)
  (loop for state in (scxml-chart-states-of chart)
        collect (list (scxml-state-id-of state)
                      (%state-transition-data state))))

(defun %ensure-symbol-package (package-name)
  (or (find-package package-name)
      (make-package package-name :use '(:cl))))

(defun compile-scxml-chart-to-forms (chart &key package-name function-name)
  (%assert-chart-valid-for-codegen chart)
  (let* ((resolved-package-name (%resolve-package-name chart package-name))
         (resolved-function-name (%resolve-function-name chart function-name))
         (generated-package (%ensure-symbol-package resolved-package-name))
         (run-symbol (intern resolved-function-name generated-package))
         (machine-symbol (intern "SCXML-MACHINE" generated-package))
         (emit-trace-symbol (intern "%EMIT-TRACE" generated-package))
         (raise-event-symbol (intern "%RAISE-EVENT" generated-package))
         (dequeue-event-symbol (intern "%DEQUEUE-EVENT" generated-package))
         (state-actions-symbol (intern "*STATE-ONENTRY-ACTIONS*" generated-package))
         (state-transitions-symbol (intern "*STATE-TRANSITIONS*" generated-package))
         (final-states-symbol (intern "*FINAL-STATES*" generated-package))
         (find-state-actions-symbol (intern "%STATE-ONENTRY-ACTIONS" generated-package))
         (find-transition-target-symbol (intern "%FIND-TRANSITION-TARGET" generated-package))
         (enter-state-symbol (intern "%ENTER-STATE" generated-package))
         (step-machine-symbol (intern "%STEP-MACHINE" generated-package))
         (machine-state-accessor (intern "SCXML-MACHINE-STATE" generated-package))
         (machine-queue-accessor (intern "SCXML-MACHINE-QUEUE" generated-package))
         (machine-trace-accessor (intern "SCXML-MACHINE-TRACE" generated-package))
         (machine-done-accessor (intern "SCXML-MACHINE-DONE-P" generated-package))
         (machine-final-accessor (intern "SCXML-MACHINE-FINAL-STATE" generated-package))
         (machine-constructor (intern "MAKE-SCXML-MACHINE" generated-package))
         (initial-state (scxml-chart-initial-state-of chart))
         (state-actions (%chart-state-action-table chart))
         (state-transitions (%chart-state-transition-table chart))
         (final-states (%final-state-id-list chart)))
    (list
     `(eval-when (:compile-toplevel :load-toplevel :execute)
        (unless (find-package ,resolved-package-name)
          (defpackage ,resolved-package-name
            (:use #:cl)))
        (export (list (intern ,resolved-function-name
                              (find-package ,resolved-package-name)))
                (find-package ,resolved-package-name)))
     `(in-package ,resolved-package-name)

     `(defstruct ,machine-symbol
        (state nil)
        (queue nil)
        (trace nil)
        (done-p nil)
        (final-state nil))

     `(defparameter ,state-actions-symbol ',state-actions)
     `(defparameter ,state-transitions-symbol ',state-transitions)
     `(defparameter ,final-states-symbol ',final-states)

     `(defun ,emit-trace-symbol (machine message)
        (push message (,machine-trace-accessor machine))
        machine)

     `(defun ,raise-event-symbol (machine event)
        (setf (,machine-queue-accessor machine)
              (append (,machine-queue-accessor machine)
                      (list event)))
        machine)

     `(defun ,dequeue-event-symbol (machine)
        (let ((queue (,machine-queue-accessor machine)))
          (if queue
              (values (first queue)
                      (setf (,machine-queue-accessor machine)
                            (rest queue))
                      t)
              (values nil machine nil))))

     `(defun ,find-state-actions-symbol (state)
        (second (assoc state ,state-actions-symbol :test #'string=)))

     `(defun ,find-transition-target-symbol (state event)
        (let ((transitions (second (assoc state
                                          ,state-transitions-symbol
                                          :test #'string=))))
          (cdr (assoc event transitions :test #'string=))) )

     `(defun ,enter-state-symbol (machine state)
        (setf (,machine-state-accessor machine) state)
        (,emit-trace-symbol machine
                            (format nil "Entering: ~A" state))
        (dolist (action (,find-state-actions-symbol state))
          (case (first action)
            (:log
             (,emit-trace-symbol machine (second action)))
            (:raise
             (,raise-event-symbol machine (second action)))))
        (when (member state ,final-states-symbol :test #'string=)
          (setf (,machine-done-accessor machine) t
                (,machine-final-accessor machine) state))
        machine)

     `(defun ,step-machine-symbol (machine)
        (multiple-value-bind (event updated-machine has-event-p)
            (,dequeue-event-symbol machine)
          (declare (ignore updated-machine))
          (if (not has-event-p)
              machine
              (let* ((source-state (,machine-state-accessor machine))
                     (target-state (,find-transition-target-symbol source-state event)))
                (if target-state
                    (progn
                      (,emit-trace-symbol machine
                                          (format nil "Transition: ~A --~A--> ~A"
                                                  source-state
                                                  event
                                                  target-state))
                      (,enter-state-symbol machine target-state))
                    (progn
                      (,emit-trace-symbol machine
                                          (format nil "Ignored event: ~A in ~A"
                                                  event
                                                  source-state))
                      machine))))))

     `(defun ,run-symbol ()
        (let ((machine (,machine-constructor)))
          (,enter-state-symbol machine ,initial-state)
          (loop while (and (not (,machine-done-accessor machine))
                           (,machine-queue-accessor machine))
                do (,step-machine-symbol machine))
          (hyperdoc/scxml:make-generated-scxml-run
           :trace (nreverse (,machine-trace-accessor machine))
           :final-state (,machine-final-accessor machine)
           :done-p (,machine-done-accessor machine)
           :machine machine))))))

(defun compile-scxml-chart-to-string (chart &key package-name function-name)
  (let ((*print-pretty* t)
        (*print-case* :downcase))
    (with-output-to-string (stream)
      (dolist (form (compile-scxml-chart-to-forms
                     chart
                     :package-name package-name
                     :function-name function-name))
        (pprint form stream)
        (terpri stream)))))

(defun compile-scxml-file-to-lisp-file
    (input-path output-path &key package-name function-name)
  (let* ((chart (parse-scxml-file input-path))
         (code (compile-scxml-chart-to-string
                chart
                :package-name package-name
                :function-name function-name))
         (resolved-output (pathname output-path)))
    (ensure-directories-exist resolved-output)
    (with-open-file (stream resolved-output
                            :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create)
      (write-string code stream))
    resolved-output))
