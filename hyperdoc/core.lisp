;;;; HyperDoc core
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; A Hyperdoc instance refers to a collection of pages (text, code, tool).
;; stored in a directory. It also has a title, used for references,
;; and optionally the title of an entry page that is shown by default
;; in an inspector.
;;
;; Text pages are stored in HTML or Markdown files. They can be reloaded
;; in order to detect new or deleted pages. Code pages are listed in a
;; system definition, meaning that their list is fixed at load time. Tool
;; pages are created by code, so their list is also fixed at load time.
;;

(defclass hyperdoc ()
  ((asdf-system-name :reader asdf-system-name-of :initarg :asdf-system-name)
   (directory :reader directory-of :initarg :directory)
   (title :reader title-of :initarg :title)
   (entry :reader entry-of :initarg :entry)
   ;; Slots holding the pages (or their sources) of the HyperDoc
   (text-pages :reader text-pages-of :initarg :text-pages)
   (code-pages :reader code-pages-of :initarg :code-pages)
   (tools :reader tools-of :initarg :tools)
   (pages :reader pages-of :initarg :pages)
   ;; The packages used in the HyperDoc are deduced
   ;; from the code files in hyperdoc-explorer.
   (packages :reader packages-of :initform nil)))

;; Accessor for the ASDF system
;; (a generic function that appears in the "Operations" view)

(defgeneric asdf-system (hd)
  (:method ((hd hyperdoc))
    (-> hd
      asdf-system-name-of
      asdf:find-system)))

;;
;; Create a HyperDoc instance.
;;

(defun make-hyperdoc (&key title asdf-system-name subdirectory entry tools)
  "Create a HyperDoc instance with TITLE for the text and code pages
located in SUBDIRECTORY relative to the base directory for ASDF-SYSTEM-NAME.
The entry page for the HyperDoc is the one whose titles is ENTRY.
TOOLS is a list of symbols naming HyperDoc tools.

Note that the recommended way to create and register a HyperDoc is
the macro DEFHYPERDOC."
  (let* ((system (asdf:find-system asdf-system-name))
         (directory (asdf:system-relative-pathname
                     asdf-system-name
                     (concatenate 'string subdirectory "/")))
         (component (asdf:find-component system subdirectory))
         (code-files (when component
                       (remove-if-not #'(lambda (c)
                                          (typep c 'asdf:cl-source-file))
                                      (asdf:component-children component))))
         (pages (make-hash-table :test #'equal))
         (code-pages (make-array (length code-files)
                                 :element-type 'code-page)))
    (let ((hyperdoc (make-instance 'hyperdoc
                                   :asdf-system-name asdf-system-name
                                   :directory directory
                                   :title title
                                   :entry entry
                                   :code-pages code-pages
                                   :tools tools
                                   :text-pages (make-hash-table :test #'equal)
                                   :pages pages)))
      (loop for file in code-files
            for index from 0
            do (let ((page (make-code-page hyperdoc file)))
                 (setf (gethash (title-of page) pages) page)
                 (setf (elt code-pages index) page)))
      (dolist (tool-name tools)
        (let* ((tool (get-tool tool-name))
               (title (title-of tool)))
          (setf (hyperdoc-of tool) hyperdoc)
          (setf (gethash title pages) tool)))
      hyperdoc)))

;;
;; Load text pages.
;;

(defun load-text-pages (hdoc)
  "Load all text pages of the HyperDoc HDOC, replacing the pages
that were loaded previously."
  ;; The simplest strategy would be to reconstruct the internal
  ;; representation of text pages completely. However, this would
  ;; invalidate page objects that the user has opened in an inspector.
  ;; Therefore we keep the in-memory object tree and only update what
  ;; must be updated.
  (with-slots (directory text-pages) hdoc
    (unless text-pages
      (setf text-pages (make-hash-table :test #'equal)))
    (let ((page-files))
      (dolist (file (uiop:directory-files directory))
        (cond
          ;; Pages can be HTML or Markdown files
          ((member (pathname-type file) '("html" "md") :test #'string=)
           (let ((page (gethash file text-pages)))
             (unless page
               (setf page (make-text-page hdoc file))
               (setf (gethash file text-pages) page))
             (load-page page)
             (push file page-files)))))
      ;; Remove pages whose files have been deleted.
      (loop for file being the hash-keys in text-pages
            do (unless (member file page-files :test #'equal)
                 (remhash file text-pages))))))

(defun reload-pages (hdoc)
  "Reload the text pages of HyperDoc HDOC."
  (load-text-pages hdoc)
  (with-slots (pages text-pages) hdoc
    ;; Remove the stale text page entries
    (loop for file being the hash-keys of pages 
          using (hash-value page)
          when (typep page 'text-page)
          do (remhash file pages))
    ;; Add fresh text page entries
    (loop for page being the hash-values of text-pages
          do (setf (gethash (title-of page) pages) page))))

(defun ensure-pages-loaded (hdoc)
  "Load the pages of HyperDoc HDOC unless they have already been loaded."
  (when (zerop (hash-table-count (text-pages-of hdoc)))
    (reload-pages hdoc)))

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
  (or (gethash title (pages-of hdoc))
      (and signal-error?
           (error 'page-lookup-failure :hyperdoc hdoc :title title))))

;;
;; An abstract page class. Concrete classes, defined later, add
;; slot(s) for storing the page's content.
;;

(defclass page ()
  ((hyperdoc :accessor hyperdoc-of :initarg :hyperdoc)
   (title :reader title-of :initarg :title)))

(defclass text-page (page)
  ((file :reader file-of :initarg :file)))

(defun make-text-page (hdoc file)
  "Create a page instance in HyperDoc HDOC for the page stored in FILE."
  (let* ((type (pathname-type file))
         (type-as-kw (alexandria:make-keyword (string-upcase type)))
         (page (make-instance (page-class type-as-kw)
                              :hyperdoc hdoc
                              :file file)))
    (load-page page)
    (setf (slot-value page 'title) (page-title page))
    page))

(defclass code-page (page)
  ((file :reader file-of :initarg :file)))

(defun make-code-page (hdoc code-file)
  "Create a page instance in HyperDoc HDOC for CODE-FILE"
  (make-instance 'code-page
                 :hyperdoc hdoc
                 :title (code-file-title code-file)
                 :file code-file))

(defun code-file-title (cl-source-file)
  (->> cl-source-file
    asdf:component-pathname
    uiop:read-file-lines
    first
    (string-left-trim " ;")
    (string-right-trim " ")))

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
