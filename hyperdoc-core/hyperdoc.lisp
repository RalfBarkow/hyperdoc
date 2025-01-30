;;;; Hyperdoc classes and views
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc/core)

;;
;; A Hyperdoc instance refers to a collection of pages and code files
;; stored in a directory.
;;

(defclass hyperdoc ()
  ((directory :reader hyperdoc-directory :initarg :directory)
   (title :reader title :initarg :title)
   (pages :reader pages :initarg :pages)
   (code-files :reader code-files :initarg :code-files)
   (entry :reader entry :initarg :entry)))

(defun make-hyperdoc (&key title asdf-system-name subdirectory entry)
  (let* ((system (asdf:find-system asdf-system-name))
         (directory (asdf:system-relative-pathname asdf-system-name
                                                   (str:concat subdirectory "/")))
         (component (asdf:find-component system subdirectory))
         (code-files (when component
                       (remove-if-not #'(lambda (c) (typep c 'asdf:cl-source-file))
                                      (asdf:component-children component)))))
    (make-instance 'hyperdoc
                   :directory directory
                   :title title
                   :pages nil
                   :code-files code-files
                   :entry entry)))
