(defpackage #:named-closure
  (:use #:cl)
  (:import-from #:closer-mop
                #:funcallable-standard-class
                #:set-funcallable-instance-function)
  (:export #:defnclo))

(in-package #:named-closure)

(defmacro defnclo (name slots options &body body)
  "Define a callable CLOS class and constructor MAKE-<NAME>."
  (declare (ignore options))
  (let* ((maker (intern (format nil "MAKE-~A" (string-upcase (symbol-name name)))
                        (symbol-package name)))
         (slot-specs (mapcar (lambda (slot)
                               (if (consp slot)
                                   slot
                                   (list slot :initarg (intern (format nil ":~A" slot)))))
                             slots))
         (initargs (mapcan (lambda (slot)
                             (let ((s (if (consp slot) (car slot) slot)))
                               (list (intern (string-upcase (symbol-name s)) :keyword) s)))
                           slots))
         (slot-names (mapcar (lambda (slot)
                               (if (consp slot) (car slot) slot))
                             slots)))
    `(progn
       (defclass ,name ()
         ,slot-specs
         (:metaclass funcallable-standard-class))

       (defun ,maker (,@slot-names)
         (let ((instance (make-instance ',name ,@initargs)))
           (set-funcallable-instance-function
            instance
            (lambda (&rest args)
              (apply (lambda ,slots ,@body)
                     (append
                      (mapcar (lambda (slot-name)
                                (slot-value instance slot-name))
                              ',slot-names)
                      args))))
           instance)))))
