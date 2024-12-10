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
  ((file :initarg :file)
   (document :initarg :document)))

(defun make-hyperdoc (directory)
  (let ((hd (make-instance 'hyperdoc :directory directory)))
    (let ((common-doc.file:*base-directory* directory))
      (dolist (page-file (uiop:directory-files directory))
        (let ((page (make-page page-file)))
          (push page (slot-value hd 'pages)))))
    hd))

(defun make-page (file)
  (let ((document (common-doc.format:parse-document (make-instance 'scriba:scriba) file)))
    (make-instance 'hyperdoc-page
                   :file file
                   :document document)))

(defview 👀items (hd hyperdoc)
  (with-slots (pages) hd
    (-> pages
      👀items
      (rename :title "Pages" :priority 1))))

(defmethod text-representation ((page hyperdoc-page))
  (common-doc:title (slot-value page 'document)))

(defview 👀content (page hyperdoc-page)
  (-> page
    (slot-value 'document)
    👀content))

(defview 👀source (page hyperdoc-page)
  (-> page
    (slot-value 'file)
    👀content
    (rename :title "Source" :priority 3)))

(defvar *doc*
  (make-hyperdoc (asdf:system-relative-pathname
                  :html-inspector-views-hyperdoc "doc")))

