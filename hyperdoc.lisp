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
    (let ((common-doc.file:*base-directory* directory))
      (dolist (page-file (uiop:directory-files directory))
        (let ((page (make-page page-file)))
          (push page (slot-value hd 'pages)))))
    hd))

(defun make-page (file)
  (make-instance 'hyperdoc-page:file file))

(defun page-document (page)
  (let* ((document (common-doc.format:parse-document (make-instance 'scriba:scriba)
                                                     (slot-value page 'file)))
         (expanded (common-doc.macro:expand-macros document)))
    expanded))

(defview 👀items (hd hyperdoc)
  (with-slots (pages) hd
    (-> pages
      👀items
      (rename :title "Pages" :priority 1))))

(defmethod text-representation ((page hyperdoc-page))
  (common-doc:title (slot-value page 'document)))

(defview 👀content (page hyperdoc-page)
  (let ((document (page-document page)))
    (html-view :title "Content" :priority 1
               (html
                 (object-ref (common-doc.format:parse-document (make-instance 'scriba:scriba)
                                                               (slot-value page 'file))
                             :display #'(lambda (_)
                                          (declare (ignore _))
                                          "Document")
                             :highlight t)
                 (:span "&nbsp;")
                 (object-ref document
                             :display #'(lambda (_)
                                          (declare (ignore _))
                                          "Expanded document")
                             :highlight t)
                 (:hr))
               (common-doc.format:emit-document (make-instance 'common-html:html)
                                                document
                                                html-inspector-views::*html-stream*))))

(defview 👀source (page hyperdoc-page)
  (-> page
    (slot-value 'file)
    👀content
    (rename :title "Source" :priority 3)))

(defvar *doc*
  (make-hyperdoc (asdf:system-relative-pathname
                  :html-inspector-views-hyperdoc "doc")))
