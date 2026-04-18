;;;; Source surface strategy and policy helpers for HyperDoc text pages
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defclass source-surface-strategy ()
  ((id :reader source-surface-strategy-id
       :initarg :id)
   (connect-capable-p :reader source-surface-connect-capable-p
                      :initarg :connect-capable-p)))

(defclass connect-source-surface-strategy (source-surface-strategy) ())

(defclass plain-source-surface-strategy (source-surface-strategy) ())

(defparameter *connect-source-surface-strategy*
  (make-instance 'connect-source-surface-strategy
                 :id :connect
                 :connect-capable-p t))

(defparameter *plain-source-surface-strategy*
  (make-instance 'plain-source-surface-strategy
                 :id :plain
                 :connect-capable-p nil))

(defparameter *source-surface-strategy-override* nil
  "Dynamic-extent override for Source surface strategy selection.")

(defun make-source-surface-strategy-class-policy-table ()
  (make-hash-table :test #'eq))

(defparameter *source-surface-strategy-class-policies*
  (make-source-surface-strategy-class-policy-table)
  "Class-based Source surface strategy policies keyed by class object.")

(defgeneric source-surface-strategy-for (page))

(defmethod source-surface-strategy-for ((page text-page))
  *connect-source-surface-strategy*)

(defun source-surface-strategy-from-designator (designator)
  (etypecase designator
    (null nil)
    (source-surface-strategy designator)
    ((eql :connect) *connect-source-surface-strategy*)
    ((eql :plain) *plain-source-surface-strategy*)))

(defun source-surface-policy-class-from-designator (designator)
  (etypecase designator
    (class designator)
    (symbol (or (find-class designator nil)
                (error "Unknown Source surface policy class: ~S"
                       designator)))))

(defun copy-source-surface-strategy-class-policies
    (&optional
       (policies *source-surface-strategy-class-policies*))
  (let ((copy (make-source-surface-strategy-class-policy-table)))
    (maphash (lambda (class strategy)
               (setf (gethash class copy) strategy))
             policies)
    copy))

(defun register-source-surface-strategy-policy
    (class-designator strategy-designator)
  (setf (gethash (source-surface-policy-class-from-designator class-designator)
                 *source-surface-strategy-class-policies*)
        (source-surface-strategy-from-designator strategy-designator)))

(defun clear-source-surface-strategy-policy (class-designator)
  (remhash (source-surface-policy-class-from-designator class-designator)
           *source-surface-strategy-class-policies*))

(defun source-surface-strategy-policy-match-for (page)
  (loop for class in (c2mop:class-precedence-list (class-of page))
        for strategy = (gethash class
                                *source-surface-strategy-class-policies*)
        when strategy
          return (values strategy class)))

(defun source-surface-strategy-policy-for (page)
  (nth-value 0 (source-surface-strategy-policy-match-for page)))

(defun source-surface-resolution-report-for (page)
  (multiple-value-bind (class-policy-strategy class-policy-class)
      (source-surface-strategy-policy-match-for page)
    (let* ((override-strategy
             (source-surface-strategy-from-designator
              *source-surface-strategy-override*))
           (default-strategy (source-surface-strategy-for page))
           (winner (cond (override-strategy :override)
                         (class-policy-strategy :class-policy)
                         (t :default)))
           (effective-strategy
             (ecase winner
               (:override override-strategy)
               (:class-policy class-policy-strategy)
               (:default default-strategy))))
      (list :target page
            :target-class (class-name (class-of page))
            :override-present-p (not (null override-strategy))
            :override-strategy override-strategy
            :class-policy-matched-p (not (null class-policy-strategy))
            :class-policy-class (and class-policy-class
                                     (class-name class-policy-class))
            :class-policy-strategy class-policy-strategy
            :default-strategy default-strategy
            :effective-strategy effective-strategy
            :winner winner))))

(defun effective-source-surface-strategy-for (page)
  (getf (source-surface-resolution-report-for page)
        :effective-strategy))

(defmacro with-source-surface-strategy-override ((strategy-designator) &body body)
  `(let ((*source-surface-strategy-override* ,strategy-designator))
     ,@body))

(defmacro with-source-surface-strategy-class-policy
    ((class-designator strategy-designator) &body body)
  `(let ((*source-surface-strategy-class-policies*
           (copy-source-surface-strategy-class-policies)))
     (register-source-surface-strategy-policy
      ,class-designator
      ,strategy-designator)
     ,@body))

(defgeneric render-source-surface-with-strategy
    (strategy page &key title priority))

(defmethod render-source-surface-with-strategy
    ((strategy connect-source-surface-strategy) (page text-page)
     &key (title "Source") (priority 10))
  (views:html-view :title title :priority priority
    (render-source-connect-surface page title (file-of page))))

(defmethod render-source-surface-with-strategy
    ((strategy plain-source-surface-strategy) (page text-page)
     &key (title "Source") (priority 10))
  (views:html-view :title title :priority priority
    (hb:render-file-source-surface (file-of page))))

(defun render-source-surface-for-page (page &key (title "Source") (priority 10))
  (render-source-surface-with-strategy
   (effective-source-surface-strategy-for page)
   page
   :title title
   :priority priority))
