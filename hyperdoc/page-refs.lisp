;;;; Page references
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

(common-doc:define-node page-reference (common-doc.macro:macro-node)
  ((hyperdoc-title :reader hyperdoc-title
             :initarg :hyperdoc-title
             :type string
             :attribute-name "hyperdoc"
             :documentation "Title of the hyperdoc containing the page")
   (text :reader text
          :initarg :text
          :type string
          :attribute-name "text"
          :documentation "Text displayed in the reference, replacing the page's title"))
  (:tag-name "page")
  (:documentation "Reference to a HyperDoc page"))

(defmethod common-doc.macro:expand-macro ((ref page-reference))
  (let* ((page-title (common-doc.ops:collect-all-text ref))
         (text (or (text ref) page-title))
         (hyperdoc-title (or (hyperdoc-title ref)
                             (title (hyperdoc *current-page*))))
         (expr (common-doc:make-text
                (format nil
                        "(hyperdoc:find-page (hyperdoc:find-hyperdoc \"~a\") \"~a\")"
                        hyperdoc-title page-title))))
    (make-instance 'object-reference
                   :children (list expr)
                   :metadata nil
                   :reference nil
                   :display nil
                   :text text
                   :view nil)))
