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

(defun get-tool (name)
  (gethash name *tools*))

(defun make-tool (symbol title)
  (let ((tool (make-instance 'tool
                             :title title
                             :package *package*)))
    (setf (gethash symbol *tools*) tool)
    (push (cons :html (str:concat "<h1>" title "</h1>"))
          (parts-of tool))
    tool))

(defvar *current-tool*)

(defmacro deftool (symbol title &body body)
  `(let ((*current-tool* (make-tool ',symbol, title)))
     ,@body))

(defun html-generator* (fn)
  (assert (typep *current-tool* 'tool))
  (push (cons :generator fn)
        (parts-of *current-tool*)))

(defmacro html-generator (&body body)
  `(html-generator* #'(lambda () ,@body)))

(defun html (s)
  (assert (typep *current-tool* 'tool))
  (push (cons :html s)
        (parts-of *current-tool*)))

(defun markdown (s)
  (assert (typep *current-tool* 'tool))
  (push (cons :markdown s)
        (parts-of *current-tool*)))
