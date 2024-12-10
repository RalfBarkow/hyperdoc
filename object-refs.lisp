;;;; Embedded object references 
;;
;;;; Copyright (c) 2024 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :html-inspector-views/hyperdoc)

(common-doc:define-node object-reference (common-doc.macro:macro-node)
  ((label :reader ref-label
          :initarg :label
          :type string
          :attribute-name "label"
          :documentation "Label on the reference button")
   (package :reader ref-package
            :initarg :package
            :type string
            :attribute-name "package"
            :documentation "Package in which the code is evaluated"))
  (:tag-name "object")
  (:documentation "Reference to a Lisp object"))

(defmethod common-doc.macro:expand-macro ((ref object-reference))
  (let* ((text (common-doc.ops:collect-all-text ref))
         (label (slot-value ref 'label))
         (package-name (str:upcase (slot-value ref 'package)))
         (*package* (if-let (p (find-package package-name))
                      p
                      (find-package :cl-user)))
         (form (with-input-from-string (input text) (read input)))
         (value (eval form)))
    (common-doc:make-text (if label
                              label
                              (format nil "~a -> ~a~%" form value)))))

