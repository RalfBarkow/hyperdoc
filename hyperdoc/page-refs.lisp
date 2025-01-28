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
   (label :reader label
          :initarg :label
          :type string
          :attribute-name "label"
          :documentation "Label displayed in the reference, replacing the page's title"))
  (:tag-name "page")
  (:documentation "Reference to a HyperDoc page"))

(defmethod common-doc.macro:expand-macro ((ref page-reference))
  (let* ((page-title (common-doc.ops:collect-all-text ref))
         (label (or (label ref) page-title))
         (hyperdoc-title (or (hyperdoc-title ref)
                             (title (hyperdoc *current-page*))))
         (text (common-doc:make-text
                (format nil
                        "(hyperdoc:find-page (hyperdoc:find-hyperdoc \"~a\") \"~a\")"
                        hyperdoc-title page-title)))
         (display (when label (str:concat "\"" label "\""))))
    (make-instance 'object-reference
                   :children (list text)
                   :metadata nil
                   :reference nil
                   :display display
                   :package nil
                   :view nil)))
