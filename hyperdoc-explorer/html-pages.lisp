;;;; HTML pages
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; An HTML page stores the page contents as the parse tree
;; returned by the plump parser.
;;

(defclass html-page (text-page)
  ((parse-tree :reader parse-tree-of :initform nil)))

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
  (with-slots (file parse-tree title) page
    (let ((plump:*tag-dispatchers* plump:*html-tags*))
      (setf parse-tree (plump:parse file))
      (set-title page)
      (extract-links page)))
  page)

(defun set-title (page)
  (with-slots (parse-tree title) page
    (setf title (or (loop for tag in '("title" "h1" "h2" "h3" "h4" "h5" "h6")
                          do (let ((elements (-> (parse-tree-of page)
                                               (plump:get-elements-by-tag-name tag))))
                               (when elements
                                 (return (-> elements first plump:text)))))
                    "Untitled"))))

(defun extract-links (page)
  (let ((current-package (find-package "CL-USER"))
        page-links hyperdoc-links web-links expr-links)
    (labels ((walk (node)
               (loop for child across (plump:children node)
                     do (when (plump:element-p child)
                          (cond
                            ((string-equal "in-package" (plump:tag-name child))
                             (setf current-package
                                   (-> child plump:text string-upcase find-package)))
                            ((string-equal "a" (plump:tag-name child))
                             (collect-link child)))
                          (walk child))))
             (collect-link (element)
               (let ((href-attr (plump:attribute element "href"))
                     (expr-attr (plump:attribute element "expr"))
                     (hyperdoc-attr (plump:attribute element "hyperdoc"))
                     (page-attr (plump:attribute element "page"))
                     (view-attr (plump:attribute element "view")))
                 (cond
                   ;; Expression link
                   (expr-attr
                    (pushnew (make-expr-link page expr-attr current-package view-attr)
                             expr-links
                             :test #'equal :key #'key-of))
                   ;; Web link
                   (href-attr
                    (pushnew (make-web-link page href-attr) web-links
                             :test #'equal :key #'key-of))
                   ;; Remaining link types are combinations of page and
                   ;; hyperdoc attributes, so if there's neither, raise
                   ;; an error.
                   ((not (or page-attr hyperdoc-attr))
                    (error "Unknown link type: ~A" element))
                   ;; Page link
                   (page-attr
                    (pushnew (make-page-link page
                                             (if hyperdoc-attr
                                                 hyperdoc-attr
                                                 (-> page hyperdoc-of id-of))
                                             page-attr
                                             view-attr)
                             page-links :test #'equal :key #'key-of))
                   ;; HyperDoc link
                   (t
                    (pushnew (make-hyperdoc-link page hyperdoc-attr view-attr)
                             hyperdoc-links :test #'equal :key #'key-of))))))
      (walk (parse-tree-of page))
      (with-slots (links) page
        (setf links nil)
        (when page-links
          (push (cons :page (nreverse page-links)) links))
        (when hyperdoc-links
          (push (cons :hyperdoc (nreverse hyperdoc-links)) links))
        (when web-links
          (push (cons :web (nreverse web-links)) links))
        (when expr-links
          (push (cons :expr (nreverse expr-links)) links))))))

;;
;; Render HTML pages
;;

;; A class for holding the renderer state.

(defclass page-state ()
  ((package :initarg :package)
   (page :initarg :page)))

;; The current renderer state.

(defvar *page-state* nil)

;; A wrapper for rendering HTML trees as objects

(defclass html-expr ()
  ((nodes :accessor nodes-of :initarg :nodes)
   (style :accessor style-of :initarg :style)))

(defmethod views:html-representation ((html-expr html-expr) &optional id)
  (views:html
    (:span :id id
           (if (eql (style-of html-expr) :code)
               (views:html
                 (:tt
                  (:code
                   (loop for node across (nodes-of html-expr)
                         do (plump:serialize-object node)))))
               (loop for node across (nodes-of html-expr)
                     do (plump:serialize-object node))))))

;; Render special tags

(defgeneric serialize-hyperdoc-element (tag element)
  (:documentation "Render ELEMENT by dispatching on its TAG. Return
T if the element has been rendered, NIL if it should be rendered as a
standard HTML tag.")

  ;; Most elements are handled by plump:serialize-object.
  (:method ((tag t) element)
    nil)

  ;; in-package elements set the current package but
  ;; are not rendered.
  (:method ((tag (eql :in-package)) element)
    (setf (slot-value *page-state* 'package)
          (-> element plump:text string-upcase find-package))
    t)

  ;; value-of elements are rendered here.
  (:method ((tag (eql :value-of)) element)
    (let* ((*package* (slot-value *page-state* 'package))
           (text (-> element plump:text))
           (value (-> text parse-and-eval)))
      (views:html
        (:span :class "hyperdoc-computed-value"
               :title text
               (views:html-representation value)))
      t))

  ;; html-expr elements are rendered here.
  (:method ((tag (eql :html-expr)) element)
    (let* ((*package* (slot-value *page-state* 'package))
           (text (-> element plump:text))
           (value (-> text parse-and-eval)))
      (if (typep value 'condition)
          (views:html-representation value)
          (views:html (views:str value)))
      t))

  ;; view-transclusion elements are rendered here.
  (:method ((tag (eql :view-transclusion)) element)
    (let* ((*package* (slot-value *page-state* 'package))
           (expr (plump:text element))
           (value (parse-and-eval expr)))
      (if (typep value 'condition)
          (views:html-representation value)
          (views:transclusion value)))
    t)

  ;; source-of-class elements are rendered here.
  (:method ((tag (eql :source-of-class)) element)
    (let* ((*package* (slot-value *page-state* 'package))
           (name (plump:text element))
           (class (parse-and-eval (format nil "(find-class '~a)" name))))
      (if (typep class 'condition)
          (views:html-representation class)
          (views:transclusion
           (html-inspector-views/standard:source-code-view class))))
    t)

  ;; source-of-function elements are rendered here.
  (:method ((tag (eql :source-of-function)) element)
    (let* ((*package* (slot-value *page-state* 'package))
           (name (plump:text element))
           (fn (parse-and-eval (format nil "(function ~a)" name))))
      (if (typep fn 'condition)
          (views:html-representation fn)
          (views:transclusion
           (html-inspector-views/standard:source-code-view fn))))
    t)

  ;; unloaded Lisp code with syntax highlighting
  (:method ((tag (eql :lisp-code)) element)
    (let* ((package-name (plump:attribute element "package"))
           (package (or (and package-name
                             (find-package (str:upcase package-name)))
                        (slot-value *page-state* 'package))))
      (-> element
          plump:text
          str:trim
          (views/standard:parse-lisp-code package)
          views/standard:render-as-html))
    t)

  ;; html-generator elements are rendered here.
  (:method ((tag (eql :html-generator)) element)
    (let* ((*package* (slot-value *page-state* 'package))
           (expr (plump:text element)))
      (let ((result (parse-and-eval expr)))
        (when (typep result 'condition)
          (views:html-representation result))))
    t)

  ;; a elements with hyperdoc-specific attributes are
  ;; rendered here. Others are handled by plump:serialize-object.
  (:method ((tag (eql :a)) element)
    (let ((expr (plump:attribute element "expr"))
          (view (plump:attribute element "view"))
          (hyperdoc (plump:attribute element "hyperdoc"))
          (page (plump:attribute element "page"))
          (text (plump:text element))
          (render-children (let ((children (plump:children element)))
                             (unless (zerop (length children))
                               (make-instance 'html-expr
                                              :nodes children
                                              :style :normal)))))
      (cond
        (expr
         (assert (and (null hyperdoc) (null page)))
         (let* ((*package* (slot-value *page-state* 'package))
                (value (parse-and-eval expr)))
           (views:html
             (:span :class "hyperdoc-reference"
                    :title (cl-who:escape-string-all expr)
                    (views:object-ref value :display render-children :select view)))
           t))
        (page
         (handler-case
             (let* ((hyperdoc (or (and hyperdoc
                                       (find-hyperdoc hyperdoc
                                                      :signal-error? t))
                                  (-> *page-state*
                                      (slot-value 'page)
                                      (slot-value 'hyperdoc))))
                    (value (find-page hyperdoc page :signal-error? t)))
               (views:html
                 (:span :class "hyperdoc-reference"
                        :title (format nil "Page \"~A\"~%HyperDoc \"~A\""
                                       page
                                       (title-of hyperdoc))
                        (views:object-ref value :display render-children :select view))))
           (lookup-failure (c)
             (views:html
               (:span :class "hyperdoc-reference hyperdoc-error"
                      (views:object-ref c :display render-children)))))
         t)
        (hyperdoc
         (handler-case
             (let ((value (find-hyperdoc hyperdoc :signal-error? t)))
               (views:html
                 (:span :class "hyperdoc-reference"
                        :title (format nil "HyperDoc \"~A\"" hyperdoc)
                        (views:object-ref value :display render-children :select view))))
           (lookup-failure (c)
             (views:html
               (:span :class "hyperdoc-reference hyperdoc-error"
                      (views:object-ref c :display text))))))

        ;; Add target="_blank" to href links that don't specify a target
        (t (unless (plump:attribute element "target")
             (plump:set-attribute element "target" "_blank"))
           nil))))

  (:method ((tag (eql :img)) element)
    (let* ((src (plump:attribute element "src"))
           (uri (puri:parse-uri src)))
      ;; If the src has a URI scheme, leave as a img element.
      ;; If the src starts with "/", do the same.
      ;; Otherwise, it's a local file that a browser cannot access,
      ;; replace it with a data URL.
      (unless (or (puri:uri-scheme uri) (str:starts-with? "/" src))
        (let* ((hyperdoc (-> *page-state*
                             (slot-value 'page)
                             (slot-value 'hyperdoc)))
               (directory (directory-of hyperdoc))
               (pathname (merge-pathnames src directory))
               (bytes (alexandria:read-file-into-byte-vector pathname))
               (encoded (base64:usb8-array-to-base64-string bytes))
               (image-type (-> pathname pathname-type str:downcase))
               (mime-type (if (equal image-type "jpg") "jpeg" image-type))
               (data-url (str:concat "data:image/" mime-type ";base64," encoded)))
          (plump:set-attribute element "src" data-url)))
      nil)))

;; Add the special-tag renderer to plump's generic serializer.

(defmethod plump:serialize-object :around ((element plump:element))
  (let ((tag-as-kw (-> element
                       plump:tag-name
                       string-upcase
                       alexandria:make-keyword)))
    (unless (serialize-hyperdoc-element tag-as-kw element)
      (call-next-method))))

;;
;; Content view on HTML pages
;;

(views:defview views:👀content (page html-page)
  (views:html-view :title "Content" :priority 1
    (views:add-asset-path "/hyperdoc/"
                          (asdf:system-relative-pathname
                           :hyperdoc
                           "assets/hyperdoc/"))
    (views:include-css "/hyperdoc/css/hyperdoc.css")
    (let ((*page-state* (make-instance 'page-state
                                       :package (find-package "CL-USER")
                                       :page page)))
      (views:html
        (:div :class "hyperdoc-page"
              (plump:serialize (parse-tree-of page)
                               views::*html-stream*)
              (:br))))))

;;
;; Parse tree view
;;

(views:defview 👀parse-tree (page html-page)
  (-> (parse-tree-of page)
      plump-inspector-views::👀children
      (views:rename :title "Parse tree" :priority 11)))
