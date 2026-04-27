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

(defun compile-and-run-scxml-file
    (pathname &key package-name function-name)
  (let* ((resolved-pathname (pathname pathname))
         (chart (parse-scxml-file resolved-pathname))
         (findings (validate-scxml-chart chart)))
    (%signal-validation-errors findings)
    (let* ((resolved-package-name (%resolve-package-name chart package-name))
           (resolved-function-name (%resolve-function-name chart function-name))
           (forms (compile-scxml-chart-to-forms
                   chart
                   :package-name resolved-package-name
                   :function-name resolved-function-name)))
      (dolist (form forms)
        (eval form))
      (let* ((package (find-package resolved-package-name))
             (run-function-symbol (and package
                                       (intern resolved-function-name
                                               package))))
        (unless (and run-function-symbol
                     (fboundp run-function-symbol))
          (error "Generated SCXML run function ~A::~A is not defined."
                 resolved-package-name
                 resolved-function-name))
        (funcall run-function-symbol)))))
