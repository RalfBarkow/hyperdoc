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

(defun make-tool (symbol id)
  (let ((tool (make-instance 'tool-page
                             :id id
                             :package *package*)))
    (setf (gethash symbol *tools*) tool)
    (push (cons :html (concatenate 'string "<h1>" id "</h1>"))
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

(defun make-playground (symbol id initial-content)
  (let ((page (make-instance symbol
                             :id id
                             :initial-content initial-content)))
    (setf (gethash symbol *tools*) page)
    page))

(defmacro defplayground (symbol title initial-content)
  `(progn (defclass ,symbol (playground-page) ())
          (make-playground ',symbol ,title ,initial-content)))

(defclass git-commit-target ()
  ((system :reader system-of :initarg :system :type asdf:system)
   (repo-root :reader repo-root-of :initarg :repo-root :type pathname)
   (commit-hash :reader commit-hash-of :initarg :commit-hash :type string)))

(defun full-git-commit-hash-p (string)
  (and (stringp string)
       (= 40 (length string))
       (every #'(lambda (char)
                  (not (null (digit-char-p char 16))))
              string)))

(defun trim-line-endings (string)
  (string-right-trim '(#\Newline #\Return) string))

(defun system-repository-root (system)
  (let ((source-file (ignore-errors (asdf:system-source-file system))))
    (unless source-file
      (error "ASDF system ~A has no source file for repository lookup."
             (asdf:component-name system)))
    (pathname
     (trim-line-endings
      (uiop:run-program
       (list "git" "-C" (namestring (uiop:pathname-directory-pathname source-file))
             "rev-parse" "--show-toplevel")
       :output :string
       :error-output :output)))))

(defun system-git-commit-target (system-designator full-commit-hash)
  (let ((system (etypecase system-designator
                  (asdf:system
                   system-designator)
                  ((or string symbol)
                   (asdf:find-system system-designator)))))
    (unless (full-git-commit-hash-p full-commit-hash)
      (error "Expected a full 40-character Git commit hash, got ~S."
             full-commit-hash))
    (make-instance 'git-commit-target
                   :system system
                   :repo-root (system-repository-root system)
                   :commit-hash (string-downcase full-commit-hash))))

(defun git-command-output (repo-root &rest args)
  (trim-line-endings
   (uiop:run-program (append (list "git" "-C" (namestring repo-root)) args)
                     :output :string
                     :error-output :output)))

(defun git-commit-metadata (target)
  (let* ((output (git-command-output
                  (repo-root-of target)
                  "show" "--no-patch" "--date=iso-strict"
                  "--format=%H%n%an%n%ae%n%ad%n%s"
                  (commit-hash-of target)))
         (lines (uiop:split-string output :separator '(#\Newline))))
    (list (cons "Repository root" (namestring (repo-root-of target)))
          (cons "System" (asdf:component-name (system-of target)))
          (cons "Commit" (or (first lines) (commit-hash-of target)))
          (cons "Author" (or (second lines) ""))
          (cons "Email" (or (third lines) ""))
          (cons "Date" (or (fourth lines) ""))
          (cons "Subject" (or (fifth lines) "")))))
