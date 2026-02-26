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
