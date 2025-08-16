;;;; Support for tools
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

(defclass tool ()
  ((hyperdoc :accessor hyperdoc-of :initarg :hyperdoc)
   (title :reader title-of :initarg :title)
   (package :reader package-of :initarg :package)
   (parts :accessor parts-of :initform nil)))

(defvar *tools* (make-hash-table :test #'eq))

(defun find-tool (package-or-name)
  (if (typep package-or-name 'package)
      (gethash package-or-name *tools*)
      (gethash (find-package package-or-name) *tools*)))

(defun tool (title)
  (setf (gethash *package* *tools*) 
        (make-instance 'tool
                       :title title
                       :package *package*))
  (html (str:concat "<h1>" title "</h1>")))

(defun html-generator* (fn)
  (push (cons :generator fn)
        (parts-of (find-tool *package*))))

(defmacro html-generator (&body body)
  `(html-generator* #'(lambda () ,@body)))

(defun html (s)
  (push (cons :html s)
        (parts-of (find-tool *package*))))

(defun markdown (s)
  (push (cons :markdown s)
        (parts-of (find-tool *package*))))
