;;;; HyperDoc core
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; The core consists of just the definitions that are required to
;; create HyperDocs, in order to keep the system "hyperdoc" a small
;; dependency.  The code for viewing and navigation is in
;; "hyperdoc/explorer".
;;

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
         (directory (asdf:system-relative-pathname
                       asdf-system-name
                       (concatenate 'string subdirectory "/")))
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

(defun load-pages (hdoc)
  (with-slots (directory pages) hdoc
    (let ((page-files))
      (dolist (file (uiop:directory-files directory))
        (cond
          ;; Pages can be HTML or Markdown files
          ((member (pathname-type file) '("html" "md") :test #'string=)
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

(defun find-page (hdoc title &key signal-error?)
  (unless hdoc
    (error 'page-lookup-failure :hyperdoc hdoc :title title))
  (ensure-pages-loaded hdoc)
  (or (loop for page being the hash-values of (pages hdoc)
            when (equal title (page-title page))
              do (return page))
      (loop for code-file in (code-files hdoc)
            when (equal title (code-file-title code-file))
              do (return code-file))
      (and signal-error?
           (error 'page-lookup-failure :hyperdoc hdoc :title title))))

(defun code-file-title (cl-source-file)
  (->> cl-source-file
    asdf:component-pathname
    uiop:read-file-lines
    first
    (string-left-trim " ;")
    (string-right-trim " ")))

;;
;; A page instance refers to a file in the
;; hyperdoc directory.
;;

(defclass page ()
  ((hyperdoc :initarg :hyperdoc)
   (file :initarg :file)))

(defun make-page (hdoc file)
  (let* ((type (pathname-type file))
         (type-as-kw (alexandria:make-keyword (string-upcase type))))
    (make-instance (page-class type-as-kw) :hyperdoc hdoc :file file)))

;;
;; The implementations of these two generic functions
;; are in hyperdoc/explorer.
;;

(defgeneric page-class (filetype))

(defgeneric load-page (page))

(defgeneric page-title (page))

;;
;; The HyperDoc catalog has only one global instance.
;;

(defclass catalog ()
  ((hyperdocs :accessor hyperdocs :initform nil)))

(defvar *catalog*
  (make-instance 'catalog))

;;
;; Registration of HyperDocs
;;

(defun register (hdoc)
  (push hdoc (hyperdocs *catalog*)))

;;
;; Catalog lookup
;;

(defun find-hyperdoc (title &key signal-error?)
  (or (dolist (hd (hyperdocs *catalog*))
        (when (string= title (title hd))
          (return hd)))
      (and signal-error?
           (error 'hyperdoc-lookup-failure :title title))))

(defun find-hyperdoc-in-directory (pathname  &key signal-error?)
  (or (dolist (hd (hyperdocs *catalog*))
        (when (equal pathname (hyperdoc-directory hd))
          (return hd)))
      (and signal-error?
           (error 'directory-lookup-failure :catalog *catalog* :pathname pathname))))

;;
;; This variable can be set to nil when HyperDoc is run in a public
;; Web server. Page reloading is then disabled. HyperDocs can also query
;; this variable to selectively enable development functionality.
;;

(defvar *development-features* t)
