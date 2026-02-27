(in-package :clog-moldable-inspector)

(defclass playground-debug-report ()
  ((condition :initarg :condition :reader playground-debug-condition)
   (source    :initarg :source    :reader playground-debug-source)
   (backtrace :initarg :backtrace :reader playground-debug-backtrace)))

(defmethod hv:text-representation ((r playground-debug-report))
  (format nil "Debug: ~A" (playground-debug-condition r)))

(hv:defview 👀debug (r playground-debug-report)
  (hv:html-view :title "Debug" :priority 1
    (hv:html
      (:h3 "Condition")
      (:pre (hv:esc (format nil "~A" (playground-debug-condition r))))
      (:h3 "Source")
      (:pre (hv:esc (or (playground-debug-source r) "")))
      (:h3 "Backtrace")
      (:pre :style "white-space: pre-wrap"
            (hv:esc (or (playground-debug-backtrace r) ""))))))

(defun make-playground-debug-report (condition source)
  (let ((bt (with-output-to-string (s)
              (ignore-errors
                (uiop:print-condition-backtrace condition :stream s)))))
    (make-instance 'playground-debug-report
                   :condition condition
                   :source source
                   :backtrace bt)))

(defun playground-eval-error-condition (error)
  "Temporary shim around HVS internal eval-error slots until HVS exports
an eval-error predicate/accessors. Keep HVS internals contained here."
  (slot-value error 'hvs::condition))

(defun playground-eval-error-stack (error)
  "Temporary shim around HVS internal eval-error slots until HVS exports
an eval-error predicate/accessors. Keep HVS internals contained here."
  (slot-value error 'hvs::stack))

(defun playground-eval-error-p (object)
  "Temporary shim around HVS internal eval-error type until HVS exports a
public predicate/accessors. Keep HVS internals contained here."
  (typep object 'hvs::eval-error))

(defun make-playground-debug-report-from-eval-error (error source)
  (let ((condition (playground-eval-error-condition error))
        (stack (playground-eval-error-stack error)))
    (make-instance 'playground-debug-report
                   :condition condition
                   :source source
                   :backtrace
                   (with-output-to-string (s)
                     (if stack
                         (dolist (frame stack)
                           (princ frame s)
                           (terpri s))
                         (ignore-errors
                           (uiop:print-condition-backtrace condition :stream s)))))))
