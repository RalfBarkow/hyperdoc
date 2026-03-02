(in-package :clog-moldable-inspector)

(defclass playground-debug-report ()
  ((condition :initarg :condition :reader playground-debug-condition)
   (source    :initarg :source    :reader playground-debug-source)
   (backtrace :initarg :backtrace :reader playground-debug-backtrace)
   (retry     :initarg :retry     :initform nil :reader playground-debug-retry)
   (status    :initform nil       :accessor playground-debug-status)))

(defmethod hv:text-representation ((r playground-debug-report))
  (format nil "Debug: ~A" (playground-debug-condition r)))

(hv:defview 👀debug (r playground-debug-report)
  (hv:html-view :title "Debug" :priority 1
    (hv:html
      (:h3 "Recovery")
      (:p
       (if (playground-debug-retry r)
           (hv:html
             (hv:eval-button
              "Retry"
              (hv:thunk
                (funcall (playground-debug-retry r)))
              "Re-evaluate the captured source with the same object bound to *"))
           (hv:html (:span "Retry unavailable for this error.")))
       " "
       (hv:action-button
        "Abort"
        (hv:thunk
          (setf (playground-debug-status r) "Aborted. No retry was attempted.")
          t)
        "Keep the report, but stop this recovery attempt"))
      (when (playground-debug-status r)
        (hv:html
          (:p (hv:esc (playground-debug-status r)))))
      (:h3 "Condition")
      (:pre (hv:esc (format nil "~A" (playground-debug-condition r))))
      (:h3 "Source")
      (:pre (hv:esc (or (playground-debug-source r) "")))
      (:h3 "Backtrace")
      (:pre :style "white-space: pre-wrap"
            (hv:esc (or (playground-debug-backtrace r) ""))))))

(defun make-playground-debug-report (condition source &key retry)
  (let ((bt (with-output-to-string (s)
              (ignore-errors
                (uiop:print-condition-backtrace condition :stream s)))))
    (make-instance 'playground-debug-report
                   :condition condition
                   :source source
                   :backtrace bt
                   :retry retry)))

(defun playground-read-all-forms (source package)
  (let ((*package* package))
    (with-input-from-string (in source)
      (loop for form = (read in nil :eof)
            until (eq form :eof)
            collect form))))

(defun playground-wrap-form (object package form)
  (let ((star-symbol (intern "*" package)))
    `(let ((,star-symbol ',object))
       ,form)))

(defun playground-eval-source (object source)
  (let* ((package (or (ignore-errors
                        (html-inspector-views/standard:playground-package object))
                      (find-package "CL-USER")))
         (forms (playground-read-all-forms source package))
         (result nil))
    (dolist (form forms result)
      (setf result
            (let ((*package* package))
              (eval (playground-wrap-form object package form)))))))

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

(defun make-playground-retry (object source)
  (labels ((retry ()
             (handler-case
                 (let ((result (playground-eval-source object source)))
                   (if (playground-eval-error-p result)
                       (make-playground-debug-report-from-eval-error result
                                                                     source
                                                                     :retry #'retry)
                       result))
               (error (condition)
                 (make-playground-debug-report condition
                                              source
                                              :retry #'retry)))))
    #'retry))

(defun make-playground-debug-report-from-eval-error (error source &key retry)
  (let ((condition (playground-eval-error-condition error))
        (stack (playground-eval-error-stack error)))
    (make-instance 'playground-debug-report
                   :condition condition
                   :source source
                   :retry retry
                   :backtrace
                   (with-output-to-string (s)
                     (if stack
                         (dolist (frame stack)
                           (princ frame s)
                           (terpri s))
                         (ignore-errors
                           (uiop:print-condition-backtrace condition :stream s)))))))
