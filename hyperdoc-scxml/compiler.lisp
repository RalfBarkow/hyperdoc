;;;; Compiler entry points for SCXML MVP charts
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc/scxml)

(defun %validation-error-findings (findings)
  (remove-if-not (lambda (finding)
                   (eq :error
                       (scxml-validation-finding-severity-of finding)))
                 findings))

(defun %signal-validation-errors (findings)
  (let ((errors (%validation-error-findings findings)))
    (when errors
      (error "SCXML chart has validation errors:~%~{~A~%~}"
             (mapcar #'%finding->string errors)))))

(defun %compile-chart-and-evaluate
    (chart &key package-name function-name)
  (let* ((resolved-package-name (%resolve-package-name chart package-name))
         (resolved-function-name (%resolve-function-name chart function-name))
         (forms (compile-scxml-chart-to-forms
                 chart
                 :package-name resolved-package-name
                 :function-name resolved-function-name)))
    (dolist (form forms)
      (eval form))
    (values resolved-package-name
            resolved-function-name)))

(defun %resolve-generated-run-function
    (resolved-package-name resolved-function-name)
  (let* ((package (find-package resolved-package-name))
         (run-function-symbol (and package
                                   (intern resolved-function-name
                                           package))))
    (unless (and run-function-symbol
                 (fboundp run-function-symbol))
      (error "Generated SCXML run function ~A::~A is not defined."
             resolved-package-name
             resolved-function-name))
    run-function-symbol))

(defun %generated-function (package symbol-name)
  (let ((symbol (find-symbol symbol-name package)))
    (unless symbol
      (error "Generated SCXML helper ~A is not present in package ~A."
             symbol-name
             (package-name package)))
    (unless (fboundp symbol)
      (error "Generated SCXML helper ~A in package ~A is not callable."
             symbol-name
             (package-name package)))
    (symbol-function symbol)))

(defun run-compiled-scxml-with-events
    (chart events &key package-name function-name)
  (let ((findings (validate-scxml-chart chart)))
    (%signal-validation-errors findings))
  (multiple-value-bind (resolved-package-name resolved-function-name)
      (%compile-chart-and-evaluate
       chart
       :package-name package-name
       :function-name function-name)
    (declare (ignore resolved-function-name))
    (let* ((package (find-package resolved-package-name))
           (machine-constructor (%generated-function package
                                                     "MAKE-SCXML-MACHINE"))
           (enter-state (%generated-function package "%ENTER-STATE"))
           (raise-event (%generated-function package "%RAISE-EVENT"))
           (step-machine (%generated-function package "%STEP-MACHINE"))
           (queue-accessor (%generated-function package "SCXML-MACHINE-QUEUE"))
           (trace-accessor (%generated-function package "SCXML-MACHINE-TRACE"))
           (done-accessor (%generated-function package "SCXML-MACHINE-DONE-P"))
           (final-accessor (%generated-function package "SCXML-MACHINE-FINAL-STATE"))
           (machine (funcall machine-constructor)))
      (funcall enter-state machine (scxml-chart-initial-state-of chart))
      (dolist (event events)
        (funcall raise-event machine event))
      (loop while (and (not (funcall done-accessor machine))
                       (funcall queue-accessor machine))
            do (funcall step-machine machine))
      (make-generated-scxml-run
       :trace (nreverse (copy-list (funcall trace-accessor machine)))
       :final-state (funcall final-accessor machine)
       :done-p (funcall done-accessor machine)
       :machine machine))))

(defun compile-and-run-scxml-file
    (pathname &key package-name function-name)
  (let* ((resolved-pathname (pathname pathname))
         (chart (parse-scxml-file resolved-pathname))
         (findings (validate-scxml-chart chart)))
    (%signal-validation-errors findings)
    (multiple-value-bind (resolved-package-name resolved-function-name)
        (%compile-chart-and-evaluate
         chart
         :package-name package-name
         :function-name function-name)
      (let ((run-function-symbol
             (%resolve-generated-run-function
              resolved-package-name
              resolved-function-name)))
        (funcall run-function-symbol)))))

(defun compile-and-run-scxml-file-with-events
    (pathname events &key package-name function-name)
  (let* ((resolved-pathname (pathname pathname))
         (chart (parse-scxml-file resolved-pathname)))
    (run-compiled-scxml-with-events
     chart
     events
     :package-name package-name
     :function-name function-name)))
