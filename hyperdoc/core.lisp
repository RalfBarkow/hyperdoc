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

(defclass hyperdoc (abstract-hyperdoc)
  ((asdf-system-name :reader asdf-system-name-of :initarg :asdf-system-name)
   (directory :reader directory-of :initarg :directory)
   (writable :reader writable-of :initarg :writable)
   (title :reader title-of :initarg :title)
   (entry :reader entry-of :initarg :entry)
   ;; Slots holding the pages (or their sources) of the HyperDoc
   (text-pages :reader text-pages-of :initarg :text-pages)
   (code-pages :reader code-pages-of :initarg :code-pages)
   (tools :reader tools-of :initarg :tools)
   (data :reader data-of :initarg :data)
   (pages :reader pages-of :initarg :pages)
   ;; The packages used in the HyperDoc are deduced
   ;; from the code files in hyperdoc-explorer.
   (packages :reader packages-of :initform nil)))

;; Accessor for the ASDF system
;; (a generic function to ensure it appears in the "Operations" view)

(defgeneric asdf-system-of (hd)
  (:method ((hd hyperdoc))
    (-> hd
      asdf-system-name-of
      asdf:find-system)))

;;
;; Page classes. text-class is still quite abstract, concrete
;; subclasses for HTML and Markdown pages follow later.
;;

(defclass page (abstract-page)
  ((hyperdoc :accessor hyperdoc-of :initarg :hyperdoc)
   (title :reader title-of :initarg :title)
   (links :reader links-of :initarg :links :initform nil)))

(defclass text-page (page)
  ((file :reader file-of :initarg :file)))

(defclass code-page (page)
  ((file :reader file-of :initarg :file)))

;;
;; Create a HyperDoc instance.
;;

(defun make-hyperdoc (&key id title asdf-system-name subdirectory entry tools data)
  "Create a HyperDoc instance with TITLE for the text and code pages
located in SUBDIRECTORY relative to the base directory for ASDF-SYSTEM-NAME.
The entry page for the HyperDoc is the one whose titles is ENTRY.
TOOLS is a list of symbols naming HyperDoc tools. DATA is a list of
(SYMBOL . STRING) cons pairs in which SYMBOL names a global variable
and STRING is the title under which the variable's data is listed in
the HyperDoc's list of datasets.

Note that the recommended way to create and register a HyperDoc is
the macro DEFHYPERDOC."
  (let* ((system (asdf:find-system asdf-system-name))
         (directory (asdf:system-relative-pathname
                     asdf-system-name
                     (concatenate 'string subdirectory "/")))
         (writable (is-writable? directory))
         (component (asdf:find-component system subdirectory))
         (code-files (when component
                       (remove-if-not #'(lambda (c)
                                          (typep c 'asdf:cl-source-file))
                                      (asdf:component-children component))))
         (pages (make-hash-table :test #'equal))
         (code-pages (make-array (length code-files)
                                 :element-type '(or null code-page)
                                 :initial-element nil)))
    (let ((hyperdoc (make-instance 'hyperdoc
                                   :id (or id (gensym "HYPERDOC"))
                                   :asdf-system-name asdf-system-name
                                   :directory directory
                                   :writable writable
                                   :title title
                                   :entry entry
                                   :code-pages code-pages
                                   :tools tools
                                   :data data
                                   :text-pages (make-hash-table :test #'equal)
                                   :pages pages)))
      ;; Initialize code and tool pages. Text pages are *not* loaded.
      ;; This happens only when they are actually required, via a call
      ;; to ensure-pages-loaded. This avoids both spurious error messages
      ;; and needless resource use for HyperDocs that are loaded for their
      ;; code, without the presence of the HyperDoc explorer machinery that
      ;; manages the user interface.
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

;; This is most probably not the best way to test if the HyperDoc
;; directory is writeable, but Common Lisp doesn't have an obvious
;; good way to do this and I'd like to avoid OS-dependent dependencies
;; such as osicat.
(defun is-writable? (directory)
  (let ((filename (merge-pathnames directory "unlikely-filename.xxx")))
    (handler-case
        (when-let (stream (open filename :direction :output :if-exists nil))
          (close stream)
          (delete-file filename)
          t)
      (file-error nil))))

;;
;; Create page instances
;;

(defun make-text-page (hdoc file)
  "Create a page instance in HyperDoc HDOC for the page stored in FILE."
  (let* ((type (pathname-type file))
         (type-as-kw (alexandria:make-keyword (string-upcase type)))
         (page (make-instance (page-class type-as-kw)
                              :hyperdoc hdoc
                              :file file)))
    (load-page page)
    page))

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
;; The implementations of these two generic functions
;; are in hyperdoc/explorer.
;;

(defgeneric page-class (filetype))
(defgeneric load-page (page))
