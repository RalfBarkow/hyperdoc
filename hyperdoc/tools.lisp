;;;; Support for tools
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

(defclass tool-page (page)
  ((symbol :reader symbol-of :initarg :symbol)
   (package :reader package-of :initarg :package)
   (parts :accessor parts-of :initform nil)))

(defvar *tools* (make-hash-table :test #'eq))

(defun get-tool (name)
  (or (gethash name *tools*)
      (error "No tool named ~A" name)))

(defun make-tool (symbol id)
  (let ((tool (make-instance 'tool-page
                             :id id
                             :symbol symbol
                             :package *package*)))
    (setf (gethash symbol *tools*) tool)
    (push (cons :html (concatenate 'string "<h1>" id "</h1>"))
          (parts-of tool))
    tool))

(defvar *current-tool*)

(defmacro deftool (symbol title &body body)
  `(progn
     (defvar ,symbol)
     (let ((*current-tool* (make-tool ',symbol ,title)))
       (setf ,symbol *current-tool*)
       ,@body)))

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

(defun make-playground (symbol id initial-content)
  (let ((page (make-instance symbol
                             :id id
                             :initial-content initial-content)))
    (setf (gethash symbol *tools*) page)
    page))

(defmacro defplayground (symbol title initial-content)
  `(progn (defclass ,symbol (playground-page) ())
          (make-playground ',symbol ,title ,initial-content)))

(defun system-repository-root-info (system)
  "Return the Git root for SYSTEM and the source used to discover it."
  (let* ((system (asdf:find-system system))
         (source-file (ignore-errors (asdf:system-source-file system))))
    (unless source-file
      (error "ASDF system ~A has no source file for repository lookup."
             (asdf:component-name system)))
    (values
     (uiop:ensure-directory-pathname
      (pathname
       (string-right-trim
        '(#\Newline #\Return)
        (uiop:run-program
         (list "git" "-C"
               (namestring
                (uiop:pathname-directory-pathname source-file))
               "rev-parse" "--show-toplevel")
         :output :string
         :error-output :output))))
     :system-source-default)))
