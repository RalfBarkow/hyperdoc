;;;; Support for tools
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

(defclass tool-page (page)
  ((package :reader package-of :initarg :package)
   (parts :accessor parts-of :initform nil)))

(defvar *tools* (make-hash-table :test #'eq))

(defun get-tool (name)
  (or (gethash name *tools*)
      (error "No tool named ~A" name)))

(defun make-tool (symbol title)
  (let ((tool (make-instance 'tool-page
                             :title title
                             :package *package*)))
    (setf (gethash symbol *tools*) tool)
    (push (cons :html (concatenate 'string "<h1>" title "</h1>"))
          (parts-of tool))
    tool))

(defvar *current-tool*)

(defmacro deftool (symbol title &body body)
  `(let ((*current-tool* (make-tool ',symbol ,title)))
     ,@body))

(defun html-generator* (fn)
  (assert (typep *current-tool* 'tool-page))
  (push (cons :generator fn)
        (parts-of *current-tool*)))

(defmacro html-generator (&body body)
  `(html-generator* #'(lambda () ,@body)))

(defun html (s)
  (assert (typep *current-tool* 'tool-page))
  (push (cons :html s)
        (parts-of *current-tool*)))

(defun markdown (s)
  (assert (typep *current-tool* 'tool-page))
  (push (cons :markdown s)
        (parts-of *current-tool*)))

;;
;; Playgrounds as tool pages
;;

(defclass playground-page (page)
  ((initial-content :reader initial-content-of :initarg :initial-content)))

(defun make-playground (symbol title initial-content)
  (let ((page (make-instance symbol
                             :title title
                             :initial-content initial-content)))
    (setf (gethash symbol *tools*) page)
    page))

(defmacro defplayground (symbol title initial-content)
  `(progn (defclass ,symbol (playground-page) ())
          (make-playground ',symbol ,title ,initial-content)))
