;;;; HyperDoc core
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; A Hyperdoc instance refers to a collection of pages and code files
;; stored in a directory. It also has a title, used for references,
;; and optionally the title of an entry page that is shown by default
;; in an inspector.
;;

(defclass hyperdoc ()
  ((asdf-system-name :reader asdf-system-name :initarg :asdf-system-name)
   (directory :reader hyperdoc-directory :initarg :directory)
   (title :reader title :initarg :title)
   (pages :reader pages :initarg :pages)
   (code-files :reader code-files :initarg :code-files)
   (entry :reader entry :initarg :entry)))

;;
;; Create a HyperDoc instance.
;;

(defun make-hyperdoc (&key title asdf-system-name subdirectory entry)
  "Create a HyperDoc instance with TITLE for the text and code pages
located in SUBDIRECTORY relative to the base directory for ASDF-SYSTEM-NAME.
The entry page for the HyperDoc is the one whose titles is ENTRY.

Note that the recommended way to create and register a HyperDoc is
the macro DEFHYPERDOC."
  (let* ((system (asdf:find-system asdf-system-name))
         (directory (asdf:system-relative-pathname
                       asdf-system-name
                       (concatenate 'string subdirectory "/")))
         (component (asdf:find-component system subdirectory))
         (code-files (when component
                       (remove-if-not #'(lambda (c) (typep c 'asdf:cl-source-file))
                                      (asdf:component-children component)))))
    (make-instance 'hyperdoc
                   :asdf-system-name asdf-system-name
                   :directory directory
                   :title title
                   :pages nil
                   :code-files code-files
                   :entry entry)))

;;
;; Load text and code pages.
;;

(defun load-pages (hdoc)
  "Load all text and code pages of the HyperDoc HDOC, replacing the pages
that were loaded previously."
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
  "Load the pages of HyperDoc HDOC unless they have already been loaded."
  (unless (pages hdoc)
    (setf (slot-value hdoc 'pages) (make-hash-table :test #'equal))
    (load-pages hdoc)))

;;
;; Look up a page in a HyperDoc
;;

(defun find-page (hdoc title &key signal-error?)
  "Look up TITLE in HyperDoc HDOC and return the page if found. If no page with
TITLE exists, return NIL if SIGNAL-ERROR is NIL, otherwise signal
PAGE-LOOKUP-FAILURE."
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
;; An abstract page class. Concrete classes, defined later, add
;; slot(s) for storing the page's content.
;;

(defclass page ()
  ((hyperdoc :initarg :hyperdoc)
   (file :initarg :file)))

(defun make-page (hdoc file)
  "Create a page instace in HyperDoc HDOC for the page stored in FILE."
  (let* ((type (pathname-type file))
         (type-as-kw (alexandria:make-keyword (string-upcase type))))
    (make-instance (page-class type-as-kw) :hyperdoc hdoc :file file)))

;;
;; The implementations of these three generic functions
;; are in hyperdoc/explorer.
;;

(defgeneric page-class (filetype))

(defgeneric load-page (page))

(defgeneric page-title (page))

;;
;; This variable can be set to nil when HyperDoc is run in a public
;; Web server. Page reloading is then disabled. HyperDocs can also query
;; this variable to selectively enable development functionality.
;;

(defvar *development-features* t)
