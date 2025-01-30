;;;; HyperDoc references
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

(common-doc:define-node hyperdoc-reference (common-doc.macro:macro-node)
  ((text :reader text
          :initarg :text
          :type string
          :attribute-name "text"
          :documentation "Text displayed in the reference, replacing the HyperDoc's title"))
  (:tag-name "hyperdoc")
  (:documentation "Reference to a HyperDoc"))

(defmethod common-doc.macro:expand-macro ((ref hyperdoc-reference))
  (let* ((hyperdoc-title (common-doc.ops:collect-all-text ref))
         (text (or (text ref) hyperdoc-title))
         (expr (common-doc:make-text
                (format nil
                        "(hyperdoc:find-hyperdoc \"~a\")"
                        hyperdoc-title))))
    (make-instance 'object-reference
                   :children (list expr)
                   :metadata nil
                   :reference nil
                   :display nil
                   :text text
                   :view nil)))
