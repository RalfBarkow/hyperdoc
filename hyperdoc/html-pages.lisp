;;;; HTML pages
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

(defclass html-page (page)
  ((parse-tree :reader parse-tree :initform nil)))

(defmethod page-class ((filetype (eql :html)))
  (find-class 'html-page))

(defmethod load-page ((page html-page))
  (with-slots (file parse-tree) page
    (let ((plump:*tag-dispatchers* plump:*html-tags*))
      (setf parse-tree (plump:parse file))))
  page)

(defmethod page-title ((page html-page))
  (or (loop for tag in '("title" "h1" "h2" "h3" "h4" "h5" "h6")
            do (let ((elements (-> page
                                   parse-tree
                                   (plump:get-elements-by-tag-name tag))))
                 (when elements
                   (return (-> elements first plump:text)))))
      "Untitled"))

(defclass page-state ()
  ((package :initarg :package)
   (page :initarg :page)))

(defvar *page-state* nil)

(defgeneric serialize-hyperdoc-element (tag element)

  ;; Most elements are handled by plump:serialize-object.
  (:method ((tag t) element)
    nil)

  ;; in-package elements set the current package but
  ;; are not rendered.
  (:method ((tag (eql :in-package)) element)
    (setf (slot-value *page-state* 'package)
          (-> element plump:text str:upcase find-package))
    t)

  ;; value-of elements are rendered here.
  (:method ((tag (eql :value-of)) element)
    (let* ((*package* (slot-value *page-state* 'package))
           (text (-> element plump:text))
           (value (-> text parse-and-eval)))
      (html
        (:span :class "hyperdoc-computed-value"
               :title text
               (html-representation value)))))

  ;; transclusion elements are rendered here.
  (:method ((tag (eql :view-transclusion)) element)
    (let* ((*package* (slot-value *page-state* 'package))
           (expr (plump:text element))
           (value (parse-and-eval expr)))
      (transclusion value)))

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
                    (object-ref value :display text :select view)))
           t))
        (page
         (let* ((hyperdoc (or (and hyperdoc (find-hyperdoc hyperdoc))
                              (hyperdoc (slot-value *page-state* 'page))))
                (value (find-page hyperdoc page)))
           (html
             (:span :class "hyperdoc-reference"
                    (object-ref value :display text :select view)))
           t))
        (hyperdoc
         (let ((value (find-hyperdoc hyperdoc)))
           (html
             (:span :class "hyperdoc-reference"
                    (object-ref value :display text :select view)))
           t))
        (t nil)))))

(defmethod plump:serialize-object :around ((element plump:element))
  (let ((tag-as-kw (-> element
                       plump:tag-name
                       str:upcase
                       alexandria:make-keyword)))
    (unless (serialize-hyperdoc-element tag-as-kw element)
      (call-next-method))))

(defview 👀content (page html-page)
  (html-view :title "Content" :priority 1
    (let ((*page-state* (make-instance 'page-state
                                       :package (find-package "CL-USER")
                                       :page page)))
      (html
        (:div :class "hyperdoc-page"
              (plump:serialize (parse-tree page)
                               html-inspector-views::*html-stream*))))))

(defview 👀parse-tree (page html-page)
  (-> page
      parse-tree
      plump-inspector-views::👀children
      (rename :title "Parse tree" :priority 4)))
