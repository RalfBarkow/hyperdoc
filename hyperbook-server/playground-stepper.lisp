;;;; Playground stepper (GT-inspired, but pragmatic)
;;
;;;; This is not SBCL's instruction-level stepper.
;;;; It steps through the *top-level forms* of the current Playground selection:
;;;;   - parse selection into a list of forms
;;;;   - evaluate one form at a time (with * bound to the current object)
;;;;   - keep last value / last error as inspectable objects
;;
;;;; This gives you a "moldable" stepping experience in HyperBook's own terms.
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :clog-moldable-inspector)

(defclass playground-stepper ()
  ((object     :initarg :object   :reader playground-stepper-object)
   (package    :initarg :package  :reader playground-stepper-package)
   (source     :initarg :source   :reader playground-stepper-source)
   (forms      :initarg :forms    :accessor playground-stepper-forms)
   (index      :initform 0        :accessor playground-stepper-index)
   (last-value :initform nil      :accessor playground-stepper-last-value)
   (last-error :initform nil      :accessor playground-stepper-last-error)
   (done?      :initform nil      :accessor playground-stepper-done?)))

(defmethod hv:text-representation ((s playground-stepper))
  (format nil "Step (~D/~D)"
          (playground-stepper-index s)
          (length (playground-stepper-forms s))))

(defun read-all-forms (source package)
  (let ((*package* package))
    (with-input-from-string (in source)
      (loop for form = (read in nil :eof)
            until (eq form :eof)
            collect form))))

(defun stepper-wrapped-form (stepper form)
  (let* ((pkg (playground-stepper-package stepper))
         (star (intern "*" pkg))
         (obj (playground-stepper-object stepper)))
    `(let ((,star ',obj))
       ,form)))

(defun make-playground-stepper (object source)
  (let* ((pkg (or (ignore-errors (html-inspector-views/standard:playground-package object))
                  (find-package "CL-USER")))
         (forms (handler-case
                    (read-all-forms source pkg)
                  (error (e)
                    (declare (ignore e))
                    nil))))
    (make-instance 'playground-stepper
                   :object object
                   :package pkg
                   :source source
                   :forms (or forms '()))))

(defun playground-stepper-reset (stepper)
  (setf (playground-stepper-index stepper) 0
        (playground-stepper-last-value stepper) nil
        (playground-stepper-last-error stepper) nil
        (playground-stepper-done? stepper) nil)
  t)

(defun playground-stepper-step (stepper)
  (when (playground-stepper-done? stepper)
    (return-from playground-stepper-step t))
  (let* ((forms (playground-stepper-forms stepper))
         (i (playground-stepper-index stepper)))
    (cond
      ((>= i (length forms))
       (setf (playground-stepper-done? stepper) t)
       t)
      (t
       (let* ((form (nth i forms))
              (wrapped (stepper-wrapped-form stepper form)))
         (handler-case
             (let ((value (eval wrapped)))
               (setf (playground-stepper-last-value stepper) value
                     (playground-stepper-last-error stepper) nil)
               (incf (playground-stepper-index stepper))
               (when (>= (playground-stepper-index stepper) (length forms))
                 (setf (playground-stepper-done? stepper) t))
               t)
           (error (e)
             (setf (playground-stepper-last-error stepper)
                   (make-playground-debug-report e (prin1-to-string form)))
             (setf (playground-stepper-done? stepper) t)
             t)))))))

(defun playground-stepper-run (stepper &key (limit 1000))
  (loop repeat limit
        while (not (playground-stepper-done? stepper))
        do (playground-stepper-step stepper))
  t)

(hv:defview 👀stepper (s playground-stepper)
  (hv:html-view :title "Step" :priority 1
    (hv:html
      (:h3 "Controls")
      (:p
       (hv:action-button "Reset"
                         (hv:thunk (playground-stepper-reset s) t)
                         "Reset to first form")
       " "
       (hv:action-button "Next"
                         (hv:thunk (playground-stepper-step s) t)
                         "Evaluate the next form")
       " "
       (hv:action-button "Run"
                         (hv:thunk (playground-stepper-run s) t)
                         "Run until completion or first error"))
      (:h3 "Progress")
      (:pre (hv:esc (format nil "~D / ~D~%Package: ~A~%"
                            (playground-stepper-index s)
                            (length (playground-stepper-forms s))
                            (package-name (playground-stepper-package s)))))
      (:h3 "Source selection")
      (:pre :style "white-space: pre-wrap"
            (hv:esc (or (playground-stepper-source s) "")))
      (:h3 "Last value")
      (:pre :style "white-space: pre-wrap"
            (hv:esc (format nil "~S" (playground-stepper-last-value s))))
      (let ((err (playground-stepper-last-error s)))
        (when err
          (hv:html
            (:h3 "Last error")
            (hv:eval-button "Inspect error report"
                            (hv:thunk err)
                            "Open the captured error and backtrace")))))))
