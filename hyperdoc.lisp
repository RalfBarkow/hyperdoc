;;;; Hyperdoc
;;
;;;; Copyright (c) 2024 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :html-inspector-views/hyperdoc)

;;
;; A Hyperdoc instance refers to a collection of pages
;; stored in a directory.
;;

(defclass hyperdoc ()
  ((directory :initarg :directory)
   (pages :initform nil)))

(defclass hyperdoc-page ()
  ((file :initarg :file)))

(defun make-hyperdoc (directory)
  (let ((hd (make-instance 'hyperdoc :directory directory)))
    (dolist (page-file (uiop:directory-files directory))
      (let ((page (make-instance 'hyperdoc-page :file page-file)))
        (push page (slot-value hd 'pages))))
    hd))

(defview 👀items (hd hyperdoc)
  (with-slots (pages) hd
    (-> pages
      👀items
      (rename :title "Pages" :priority 1))))

(defvar *doc*
  (make-hyperdoc (asdf:system-relative-pathname
                  :html-inspector-views-hyperdoc "doc")))

