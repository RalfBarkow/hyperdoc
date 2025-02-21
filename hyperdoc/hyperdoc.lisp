;;;; Hyperdoc classes and views
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; The class hyperdoc and the function make-hyperdoc
;; are defined in hyperdoc/core.
;;

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
          ;; Pages can be Scriba or HTML files
          ((member (pathname-type file) '("scr" "html") :test #'string=)
           (let ((page (gethash file pages)))
             (unless page
               (setf page (make-page hdoc file))
               (setf (gethash file pages) page))
             (load-page page)
             (push file page-files)))))
      (loop for file being the hash-keys in pages
            do (unless (member file page-files :test #'equal)
                 (remhash file pages))))))

(defun ensure-pages-loaded (hdoc)
  (unless (pages hdoc)
    (setf (slot-value hdoc 'pages) (make-hash-table :test #'equal))
    (load-pages hdoc)))

(defun find-page (hdoc title)
  (ensure-pages-loaded hdoc)
  (or (loop for page being the hash-values of (pages hdoc)
            when (equal title (page-title page))
              do (return page))
      (loop for code-file in (code-files hdoc)
            when (equal title (code-file-title code-file))
              do (return code-file))))

(defview 👀entry (hd hyperdoc)
  (ensure-pages-loaded hd)
  (when-let (entry (entry hd))
    (when-let (entry-page (find-page hd entry))
      (👀content entry-page))))

(defview 👀items (hd hyperdoc)
  (ensure-pages-loaded hd)
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
   (file :reader file :initarg :file)))

(defgeneric page-class (filetype))

(defun make-page (hdoc file)
  (let* ((type (pathname-type file))
         (type-as-kw (alexandria:make-keyword (str:upcase type))))
    (make-instance (page-class type-as-kw) :hyperdoc hdoc :file file)))

(defvar *current-page* nil)

(defgeneric load-page (page))

(defgeneric page-title (page))

(defmethod title-bar-action-buttons ((page page))
  (action-button "Reload"
                 (thunk (load-page page)
                        t)))

(defmethod text-representation ((page page))
  (page-title page))

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
