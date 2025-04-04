;;;; HTML pages
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; An HTML page stores the page contents as the parse tree
;; returned by the plump parser.
;;

(defclass html-page (page)
  ((parse-tree :reader parse-tree :initform nil)))

;;
;; The page class for file type "html" is html-page.
;;

(defmethod page-class ((filetype (eql :html)))
  (find-class 'html-page))

;;
;; Load an HTML page (which implies parsing it)
;;

(defmethod load-page ((page html-page))
  (with-slots (file parse-tree) page
    (let ((plump:*tag-dispatchers* plump:*html-tags*))
      (setf parse-tree (plump:parse file))))
  page)

;;
;; Obtain the title of an HTML page as the value of the
;; TITLE tag, if one exists, or else as the value of the
;; highest-level header tag in the page. If neither TITLE
;; nor any header tag exists, return "Untitled".
;;

(defmethod page-title ((page html-page))
  (or (loop for tag in '("title" "h1" "h2" "h3" "h4" "h5" "h6")
            do (let ((elements (-> page
                                   parse-tree
                                   (plump:get-elements-by-tag-name tag))))
                 (when elements
                   (return (-> elements first plump:text)))))
      "Untitled"))

;;
;; Render HTML pages
;;

;; A class for holding the renderer state.

(defclass page-state ()
  ((package :initarg :package)
   (page :initarg :page)))

;; The current renderer state.

(defvar *page-state* nil)

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
      (html
        (:span :class "hyperdoc-computed-value"
               :title text
               (html-representation value)))
      t))

  ;; view-transclusion elements are rendered here.
  (:method ((tag (eql :view-transclusion)) element)
    (let* ((*package* (slot-value *page-state* 'package))
           (expr (plump:text element))
           (value (parse-and-eval expr)))
      (transclusion value))
    t)

  ;; source-of-class elements are rendered here.
  (:method ((tag (eql :source-of-class)) element)
    (let* ((*package* (slot-value *page-state* 'package))
           (name (plump:text element))
           (class (parse-and-eval (format nil "(find-class '~a)" name))))
      (transclusion (html-inspector-views/standard:source-code-view class)))
    t)

  ;; source-of-function elements are rendered here.
  (:method ((tag (eql :source-of-function)) element)
    (let* ((*package* (slot-value *page-state* 'package))
           (name (plump:text element))
           (fn (parse-and-eval (format nil "(function ~a)" name))))
      (transclusion (html-inspector-views/standard:source-code-view fn)))
    t)

  ;; a elements with hyperdoc-specific attributes are
  ;; rendered here. Others are handled by plump:serialize-object.
  (:method ((tag (eql :a)) element)
    (let ((expr (plump:attribute element "expr"))
          (view (plump:attribute element "view"))
          (hyperdoc (plump:attribute element "hyperdoc"))
          (page (plump:attribute element "page"))
          (text (plump:text element)))
      (cond
        (expr
         (assert (and (null hyperdoc) (null page)))
         (let* ((*package* (slot-value *page-state* 'package))
                (value (parse-and-eval expr)))
           (html
             (:span :class "hyperdoc-reference"
                    :title expr
                    (object-ref value :display text :select view)))
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
               (html
                 (:span :class "hyperdoc-reference"
                        :title (format nil "Page \"~A\"~%HyperDoc \"~A\""
                                       page
                                       (title hyperdoc))
                        (object-ref value :display text :select view))))
           (lookup-failure (c)
             (html
               (:span :class "hyperdoc-reference hyperdoc-error"
                      (object-ref c :display text)))))
         t)
        (hyperdoc
         (handler-case
             (let ((value (find-hyperdoc hyperdoc :signal-error? t)))
               (html
                 (:span :class "hyperdoc-reference"
                        :title (format nil "HyperDoc \"~A\"" hyperdoc)
                        (object-ref value :display text :select view))))
           (lookup-failure (c)
             (html
               (:span :class "hyperdoc-reference hyperdoc-error"
                      (object-ref c :display text))))))

        ;; Add target="_blank" to href links that don't specify a target
        (t (unless (plump:attribute element "target")
             (plump:set-attribute element "target" "_blank"))
           nil)))))

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

(defview 👀content (page html-page)
  (html-view :title "Content" :priority 1
    (add-asset-path "/hyperdoc/"
                    (asdf:system-relative-pathname
                     :hyperdoc
                     "assets/hyperdoc"))
    (include-css "/hyperdoc/css/hyperdoc.css")
    (let ((*page-state* (make-instance 'page-state
                                       :package (find-package "CL-USER")
                                       :page page)))
      (html
        (:div :class "hyperdoc-page"
              (plump:serialize (parse-tree page)
                               html-inspector-views::*html-stream*)
              (:br))))))

;;
;; Parse tree view
;;

(defview 👀parse-tree (page html-page)
  (-> page
      parse-tree
      plump-inspector-views::👀children
      (rename :title "Parse tree" :priority 4)))
