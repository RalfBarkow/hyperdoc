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
   (title :initarg :title
   (pages :initform (make-hash-table :test #'equal))))

(defun make-hyperdoc (directory)
  (-> (make-instance 'hyperdoc :directory directory)
    load-hyperdoc))

(defmethod text-representation ((hdoc hyperdoc))
  (slot-value hdoc 'title))

(defmethod title-bar-action-buttons ((hdoc hyperdoc))
  (action-button "Reload"
                 (thunk (load-hyperdoc hdoc)
                        t)))

(defun load-hyperdoc (hdoc)
  (with-slots (directory title pages) hdoc
    (setf title "(untitled)")
    (let ((page-files))
      (dolist (file (uiop:directory-files directory))
        (cond
          ;; File "title.txt" stores the title
          ((and (string= "title" (pathname-name file))
                (string= "txt" (pathname-type file)))
           (setf (slot-value hdoc 'title)
                 (-> file
                   alexandria:read-file-into-string
                   str:trim)))
          ;; Scriba files store the pages
          ((string= "scr" (pathname-type file))
           (let ((page (gethash file pages)))
             (unless page
               (setf page (make-page hdoc file))
               (setf (gethash file pages) page))
             (load-page page)
             (push file page-files)))))
      (loop for file being the hash-keys in pages
            do (unless (member file page-files :test #'equal)
                 (remhash file pages)))))  
  hdoc)

(defview 👀items (hd hyperdoc)
  (with-slots (pages) hd
    (-> pages
      alexandria:hash-table-values
      👀items
      (rename :title "Pages" :priority 1))))

(defview 👀files (hd hyperdoc)
  (with-slots (directory) hd
    (-> directory
      👀items
      (rename :title "Files" :priority 3))))

;;
;; A hyperdoc-page instance refers to a Scriba file in the
;; hyperdoc directory.
;;

(defclass hyperdoc-page ()
  ((hyperdoc :initarg :hyperdoc)
   (file :initarg :file)
   (document :initarg :document :initform nil)))

(defun make-page (hdoc file)
  (make-instance 'hyperdoc-page :hyperdoc hdoc :file file))

(defun load-page (page)
  (with-slots (hyperdoc file document) page
    (let ((common-doc.file:*base-directory* (slot-value hyperdoc 'directory)))
      (setf document (parse-and-expand file))))
  page)

(defun parse-and-expand (file)
  (let* ((document (common-doc.format:parse-document (make-instance 'scriba:scriba)
                                                     file))
         ;; CommonDoc macro expansion is not used in plain Hyperdoc,
         ;; but it makes the syntax extensible by other packages.
         (expanded (common-doc.macro:expand-macros document)))
    expanded))

(defmethod title-bar-action-buttons ((page hyperdoc-page))
  (action-button "Reload"
                 (thunk (load-page page)
                        t)))

(defmethod text-representation ((page hyperdoc-page))
  (common-doc:title (slot-value page 'document)))

(defview 👀content (page hyperdoc-page)
  (html-view :title "Content" :priority 1
    (let ((document (slot-value page 'document)))
      ;; Don't use common-doc.format:emit-document here. It creates an
      ;; HTML string for the document and in the end sends it to the
      ;; specified output string. This interferes with the implementation
      ;; of object references. Moreover, it creates a !DOCTYPE tag for
      ;; an independent document, whereas we want a snippet that goes
      ;; into a view.
      (common-html.emitter:node-to-stream (common-doc:children document)
                                          html-inspector-views::*html-stream*))))

(defview 👀source (page hyperdoc-page)
  (-> page
    (slot-value 'file)
    👀content
    (rename :title "Source" :priority 3)))

(defview 👀document (page hyperdoc-page)
  (-> page
    (slot-value 'document)
    👀items
    (rename :title "Document" :priority 4)))

(defvar *doc*
  (make-hyperdoc (asdf:system-relative-pathname
                  :html-inspector-views-hyperdoc "doc/")))
