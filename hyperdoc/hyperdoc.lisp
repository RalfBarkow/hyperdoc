;;;; Hyperdoc classes and views
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; A Hyperdoc instance refers to a collection of pages
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
         (pages (make-hash-table :test #'equal))
         (component (asdf:find-component system subdirectory))
         (code-files (when component
                       (remove-if-not #'(lambda (c) (typep c 'asdf:cl-source-file))
                                      (asdf:component-children component))))
         (hyperdoc (make-instance 'hyperdoc
                                  :directory directory
                                  :title title
                                  :pages pages
                                  :code-files code-files
                                  :entry entry)))
    (load-pages hyperdoc)
    hyperdoc))

(defmethod text-representation ((hdoc hyperdoc))
  (title hdoc))

(defmethod title-bar-action-buttons ((hdoc hyperdoc))
  (action-button "Reload"
                 (thunk (load-pages hdoc)
                        t)))

(defun load-pages (hdoc)
  (with-slots (directory pages) hdoc
    (let ((common-doc.file:*base-directory* directory)
          (page-files))
      (dolist (file (uiop:directory-files directory))
        (cond
          ;; Scriba files store the pages
          ((member (pathname-type file) '("scr") :test #'string=)
           (let ((page (gethash file pages)))
             (unless page
               (setf page (make-page hdoc file))
               (setf (gethash file pages) page))
             (load-page page)
             (push file page-files)))))
      (loop for file being the hash-keys in pages
            do (unless (member file page-files :test #'equal)
                 (remhash file pages))))))

(defun find-page (hdoc title)
  (loop for page being the hash-values of (pages hdoc)
        when (equal title (page-title page))
          do (return page)))

(defview 👀entry (hd hyperdoc)
  (when-let (entry (entry hd))
    (when-let (entry-page (find-page hd entry))
      (👀content entry-page))))

(defview 👀items (hd hyperdoc)
  (-> hd
      pages
      alexandria:hash-table-values
      (list-view :title "Pages" :priority 2)))

(defview 👀code (hd hyperdoc)
  (-> hd
      code-files
      (enumerated-list-view :title "Code"
                            :priority 3
                            :display #'code-file-title)))

(defun code-file-title (cl-source-file)
  (-> cl-source-file
    asdf:component-pathname
    uiop:read-file-lines
    first
    (str:trim-left :char-bag " ;")))

(defview 👀files (hd hyperdoc)
  (-> hd
      hyperdoc-directory
      👀items
      (rename :title "Files" :priority 5)))

;;
;; A page instance refers to a Scriba file in the
;; hyperdoc directory.
;;

(defclass page ()
  ((hyperdoc :reader hyperdoc :initarg :hyperdoc)
   (file :reader file :initarg :file)
   (document :reader document :initarg :document :initform nil)))

(defun make-page (hdoc file)
  (make-instance 'page :hyperdoc hdoc :file file))

(defvar *current-page* nil)

(defun load-page (page)
  (with-slots (document) page
    (let ((*current-page* page))
      (setf document (parse-and-expand (file page)))))
  page)

(defun parse-and-expand (file)
  (let* ((format (make-instance 'scriba:scriba))
         (document (common-doc.format:parse-document format file))
         (expanded (common-doc.macro:expand-macros document)))
    expanded))

(defun page-title (page)
  (-> page
      document
      common-doc:title))

(defmethod title-bar-action-buttons ((page page))
  (action-button "Reload"
                 (thunk (load-page page)
                        t)))

(defmethod text-representation ((page page))
  (page-title page))

(defclass emitter-state ()
  ((package :initarg :package)
   (page :initarg :page)))

(defvar *emitter-state* nil)

(defview 👀content (page page)
  (html-view :title "Content" :priority 1
    (add-asset-path "/hyperdoc/"
                    (asdf:system-relative-pathname
                     :hyperdoc
                     "assets/hyperdoc"))
    (include-css "/hyperdoc/css/hyperdoc.css")
    (html
      (:h1 :class "hyperdoc-page-title"
           (esc (page-title page))))
    (let ((*emitter-state* (make-instance 'emitter-state
                                          :package (find-package "CL-USER")
                                          :page page)))
      ;; Don't use common-doc.format:emit-document here. It creates an
      ;; HTML string for the document and in the end sends it to the
      ;; specified output string. This interferes with the implementation
      ;; of object references. Moreover, it creates a !DOCTYPE tag for
      ;; an independent document, whereas we want a snippet that goes
      ;; into a view.
      (common-html.emitter:node-to-stream (common-doc:children (document page))
                                          html-inspector-views::*html-stream*))))

(defview 👀source (page page)
  (-> page
    file
    👀content
    (rename :title "Source" :priority 3)))

(defview 👀document (page page)
  (-> page
    document
    👀items
    (rename :title "CommonDoc" :priority 4)))
