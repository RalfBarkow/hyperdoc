;;;; Hyperdoc classes and views
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; A Hyperdoc instance refers to a collection of pages
;; stored in a directory.
;;

(defclass hyperdoc ()
  ((directory :initarg :directory)
   (title :initarg :title)
   (pages :initarg :pages)
   (code-files :initarg :code-files)))

(defun make-hyperdoc (&key title asdf-system-name subdirectory)
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
                                  :code-files code-files)))
    (load-pages hyperdoc)
    hyperdoc))

(defmethod text-representation ((hdoc hyperdoc))
  (slot-value hdoc 'title))

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
          ;; Scriba and VerTeX files store the pages
          ((member (pathname-type file) '("scr" "tex") :test #'string=)
           (let ((page (gethash file pages)))
             (unless page
               (setf page (make-page file))
               (setf (gethash file pages) page))
             (load-page page)
             (push file page-files)))))
      (loop for file being the hash-keys in pages
            do (unless (member file page-files :test #'equal)
                 (remhash file pages))))))

(defun find-page (hdoc title)
  (with-slots (pages) hdoc
    (loop for page being the hash-values of pages
          when (equal title (page-title page))
            do (return page))))

(defview 👀items (hd hyperdoc)
  (with-slots (pages) hd
    (-> pages
      alexandria:hash-table-values
      (list-view :title "Pages" :priority 1))))

(defview 👀code (hd hyperdoc)
  (with-slots (code-files) hd
    (enumerated-list-view code-files
                          :title "Code"
                          :priority 2
                          :display #'code-file-title)))

(defun code-file-title (cl-source-file)
  (-> cl-source-file
    asdf:component-pathname
    uiop:read-file-lines
    first
    (str:trim-left :char-bag " ;")))

(defview 👀files (hd hyperdoc)
  (with-slots (directory) hd
    (-> directory
      👀items
      (rename :title "Files" :priority 3))))

;;
;; A hyperdoc-page instance refers to a Scriba or VerTeX file in the
;; hyperdoc directory.
;;

(defclass hyperdoc-page ()
  ((file :initarg :file)
   (document :initarg :document :initform nil)))

(defun make-page (file)
  (make-instance 'hyperdoc-page :file file))

(defun load-page (page)
  (with-slots (file document) page
    (setf document (parse-and-expand file)))
  page)

(defun parse-and-expand (file)
  (let* ((format (if (string= (pathname-type file) "scr")
                     (make-instance 'scriba:scriba)
                     (make-instance 'vertex:vertex)))
         (document (common-doc.format:parse-document format file))
         ;; CommonDoc macro expansion is not used in plain Hyperdoc,
         ;; but it makes the syntax extensible by other packages.
         (expanded (common-doc.macro:expand-macros document)))
    expanded))

(defun page-title (page)
  (common-doc:title (slot-value page 'document)))

(defmethod title-bar-action-buttons ((page hyperdoc-page))
  (action-button "Reload"
                 (thunk (load-page page)
                        t)))

(defmethod text-representation ((page hyperdoc-page))
  (page-title page))

(defview 👀content (page hyperdoc-page)
  (html-view :title "Content" :priority 1
    (emit-html (slot-value page 'document))))

(defclass emitter-state ()
  ((package :initarg :package)))

(defvar *emitter-state* nil)

(defun emit-html (document)
  (let ((*emitter-state* (make-instance 'emitter-state
                                        :package (find-package "CL-USER"))))
    ;; Don't use common-doc.format:emit-document here. It creates an
    ;; HTML string for the document and in the end sends it to the
    ;; specified output string. This interferes with the implementation
    ;; of object references. Moreover, it creates a !DOCTYPE tag for
    ;; an independent document, whereas we want a snippet that goes
    ;; into a view.
    (common-html.emitter:node-to-stream (common-doc:children document)
                                        html-inspector-views::*html-stream*)))

(defview 👀source (page hyperdoc-page)
  (-> page
    (slot-value 'file)
    👀content
    (rename :title "Source" :priority 3)))

(defview 👀document (page hyperdoc-page)
  (-> page
    (slot-value 'document)
    👀items
    (rename :title "CommonDoc" :priority 4)))
