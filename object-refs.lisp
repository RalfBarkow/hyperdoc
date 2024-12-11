;;;; Embedded object references 
;;
;;;; Copyright (c) 2024 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :html-inspector-views/hyperdoc)

;;
;; Define a new node for raw HTML code inside a document
;; This is what an object reference is transformed to
;; for HTML rendering.
;;

(common-doc:define-node html-node (common-doc:text-node) ())

(defun make-html (string &key metadata reference)
  (make-instance 'html-node
                 :text string
                 :metadata metadata
                 :reference reference))

(common-html.emitter::define-emitter (node html-node)
  (write-string (common-doc:text node) common-html.emitter::*output-stream*))

;;
;; Define a new node for embedded object references.
;; The text of the node is interpreted as Lisp code in the
;; specified package (defaults to cl-user) and evaluated.
;; An inspector reference to the result is inserted vie
;; html-inspector-views:object-ref.
;;

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
            :documentation "Package in which the code is evaluated")
   (view :reader ref-view
            :initarg :view
            :type string
            :attribute-name "view"
            :documentation "The view to preselect for inspecting the value"))
  (:tag-name "object")
  (:documentation "Reference to a Lisp object"))

(defmethod common-doc.macro:expand-macro ((ref object-reference))
  (let* ((text (common-doc.ops:collect-all-text ref))
         (label (slot-value ref 'label))
         (view (slot-value ref 'view))
         (package-name (str:upcase (slot-value ref 'package)))
         (*package* (if-let (p (find-package package-name))
                      p
                      (find-package :cl-user)))
         (form (with-input-from-string (input text) (read input)))
         (value (eval form)))
    (make-html (if label
                   label
                   (object-ref value :highlight t :select view)))))
