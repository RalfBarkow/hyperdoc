;;;; HTML pages
;;
;;;; Copyright (c) 2025-2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; An HTML page stores the page contents as the parse tree
;; returned by the plump parser.
;;

(defclass html-page (text-page)
  ((parse-tree :reader dom-of :initform nil)))

;;
;; The page class for file type "html" is html-page.
;;

(defmethod page-class ((filetype (eql :html)))
  (find-class 'html-page))

;;
;; Load an HTML page, parse it, set the title, and compile a
;; list of the links it contains.
;;
;; The title is given by a TITLE tag, if one exists, or else as the text
;; of the highest-level header tag in the page. If neither TITLE
;; nor any header tag exists, return "Untitled".
;;

(defmethod load-page ((page html-page))
  (with-slots (links file parse-tree title) page
    (let ((plump:*tag-dispatchers* plump:*html-tags*))
      (setf parse-tree (plump:parse file))
      (set-title page)
      (setf links (hb:extract-links page))))
  page)

(defun set-title (page)
  (with-slots (parse-tree id) page
    (setf id (or (loop for tag in '("title" "h1" "h2" "h3" "h4" "h5" "h6")
                          do (let ((elements (-> (dom-of page)
                                               (plump:get-elements-by-tag-name tag))))
                               (when elements
                                 (return (-> elements first plump:text str:trim)))))
                    "Untitled"))))

;;
;; Render HTML pages
;;

;; The tags with special treatment in serialization

(defvar *hyperdoc-tags* nil)

;; A special variable holding the current package

(defvar *current-package* nil)

;;
;; Process special tags
;;

;; in-package: set the current package, do not render

(plump:define-tag-dispatcher (in-package-tag *hyperdoc-tags*) (name)
  (string-equal name "in-package"))

(plump:define-tag-printer in-package-tag (element)
  (setf *current-package*
        (-> element plump:text string-upcase find-package))
  t)

;; value-of: parse and eval text, render result

(plump:define-tag-dispatcher (value-of *hyperdoc-tags*) (name)
  (string-equal name "value-of"))

(plump:define-tag-printer value-of (element)
  (let* ((*package* *current-package*)
         (text (-> element plump:text))
         (value (-> text parse-and-eval)))
    (views:html
      (:span :class "hyperdoc-computed-value"
             :title text
             (views:html-representation value))))
  t)

;; html-expr: parse and eval text, insert result as HTML

(plump:define-tag-dispatcher (html-expr *hyperdoc-tags*) (name)
  (string-equal name "html-expr"))

(plump:define-tag-printer html-expr (element)
  (let* ((*package* *current-package*)
         (text (-> element plump:text))
         (value (-> text parse-and-eval)))
    (if (typep value 'condition)
        (views:html-representation value)
        (views:html (views:str value))))
  t)

;; html-generator: parse and eval text, which generates HTML as an effect

(plump:define-tag-dispatcher (html-generator *hyperdoc-tags*) (name)
  (string-equal name "html-generator"))

(plump:define-tag-printer html-generator (element)
  (let* ((*package* *current-package*)
         (expr (plump:text element)))
    (let ((result (parse-and-eval expr)))
      (when (typep result 'condition)
        (views:html-representation result))))
  t)

;; view-transclusion: parse and eval text, transclude result

(plump:define-tag-dispatcher (view-transclusion *hyperdoc-tags*) (name)
  (string-equal name "view-transclusion"))

(plump:define-tag-printer view-transclusion (element)
  (let* ((*package* *current-package*)
         (expr (plump:text element))
         (value (parse-and-eval expr)))
    (if (typep value 'condition)
        (views:html-representation value)
        (views:transclusion value)))
  t)

;; source-of-class: find class named by text, transclude its source view

(plump:define-tag-dispatcher (source-of-class *hyperdoc-tags*) (name)
  (string-equal name "source-of-class"))

(plump:define-tag-printer source-of-class (element)
  (let* ((*package* *current-package*)
         (name (plump:text element))
         (class (parse-and-eval (format nil "(find-class '~a)" name))))
    (if (typep class 'condition)
        (views:html-representation class)
        (views:transclusion
         (html-inspector-views/standard:source-code-view class))))
  t)

;; source-of-class: find function named by text, transclude its source view

(plump:define-tag-dispatcher (source-of-function *hyperdoc-tags*) (name)
  (string-equal name "source-of-function"))

(plump:define-tag-printer source-of-function (element)
  (let* ((*package* *current-package*)
         (name (plump:text element))
         (fn (parse-and-eval (format nil "(function ~a)" name))))
    (if (typep fn 'condition)
        (views:html-representation fn)
        (views:transclusion
         (html-inspector-views/standard:source-code-view fn))))
  t)

;; lisp-code: parse text as Lisp, render with syntax highlighting

(plump:define-tag-dispatcher (lisp-code *hyperdoc-tags*) (name)
  (string-equal name "lisp-code"))

(plump:define-tag-printer lisp-code (element)
  (let* ((package-name (plump:attribute element "package"))
         (package (or (and package-name
                           (find-package (str:upcase package-name)))
                      *current-package*)))
    (-> element
        plump:text
        str:trim
        (views/standard:parse-lisp-code package)
        views/standard:render-as-html))
  t)


(plump:define-tag-dispatcher (img *hyperdoc-tags*) (name)
  (string-equal name "img"))

(plump:define-tag-printer img (element)
  (let* ((src (plump:attribute element "src"))
         (uri (puri:parse-uri src)))
    ;; If the src has a URI scheme, leave as a img element.  If the
    ;; src starts with "/", do the same.  Otherwise, it's a local file
    ;; that a browser cannot access, replace it with a data URL.
    (unless (or (puri:uri-scheme uri) (str:starts-with? "/" src))
      (let* ((hyperdoc hb::*current-hyperbook*)
             (directory (directory-of hyperdoc))
             (pathname (merge-pathnames src directory))
             (bytes (alexandria:read-file-into-byte-vector pathname))
             (encoded (base64:usb8-array-to-base64-string bytes))
             (image-type (-> pathname pathname-type str:downcase))
             (mime-type (if (equal image-type "jpg") "jpeg" image-type))
             (data-url (str:concat "data:image/" mime-type ";base64," encoded)))
        (plump:set-attribute element "src" data-url)
        (hb:render-node element))))
  t)

(defmethod hb:serialize-a-element ((attr (eql ':expr)) element)
  (serialize-a-expr-element element))

(defmethod hb:serialize-a-element ((attr (eql ':expr.view)) element)
  (serialize-a-expr-element element))

(defun serialize-a-expr-element (element)
  (let* ((expr-attr (plump:attribute element "expr"))
         (view-attr (plump:attribute element "view"))
         (*package* *current-package*)
         (value (parse-and-eval expr-attr))
         (render-children (let ((children (plump:children element)))
                            (unless (zerop (length children))
                              (make-instance 'hb:html-nodes
                                             :nodes children)))))
    (views:html
      (:span :class "hyperbook-reference"
             :title (cl-who:escape-string-all expr-attr)
             (views:object-ref value :display render-children :select view-attr)))))

;;
;; Customize the content view on HyperBook HTML pages
;;

(defvar *hyperdoc-html-page-assets*
  (make-instance 'hb:html-page-assets
                 :inherit hb:*hyperbook-html-page-assets*
                 :paths (list (cons "/hyperdoc/"
                                    (asdf:system-relative-pathname
                                     :hyperdoc
                                     "assets/hyperdoc/")))
                 :css '("/hyperdoc/css/hyperdoc.css")
                 :tag-dispatchers '*hyperdoc-tags*))

(defmethod hb:html-page-assets-of ((hd hyperdoc))
  *hyperdoc-html-page-assets*)

(defmethod hb:serialize-page-dom ((page page))
  (let ((*current-package* (find-package "CL-USER")))
    (call-next-method)))

;;
;; Parse tree view
;;

(views:defview 👀parse-tree (page html-page)
  (-> (dom-of page)
      plump-inspector-views::👀children
      (views:rename :title "Parse tree" :priority 11)))
