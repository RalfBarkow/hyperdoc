;;;; Embedded object references 
;;
;;;; Copyright (c) 2024 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :html-inspector-views/hyperdoc)

;;
;; Define a new node for embedded object references.
;; The text of the node is interpreted as Lisp code in the
;; specified package (defaults to cl-user) and evaluated.
;; An inspector reference to the result is inserted vie
;; html-inspector-views:object-ref.
;;

(common-doc:define-node object-reference (common-doc:content-node)
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
  (:documentation "Inspectable reference to a Lisp object"))

(common-html.emitter::define-emitter (ref object-reference)
  (let* ((text (common-doc.ops:collect-all-text ref))
         (label (slot-value ref 'label))
         (view (slot-value ref 'view))
         (package-name (str:upcase (slot-value ref 'package)))
         (*package* (if-let (p (find-package package-name))
                      p
                      (find-package :cl-user)))
         (form (with-input-from-string (input text) (read input)))
         (value (eval form))
         (html-id (inspect-id value :select view)))
    (format t "common-html.emitter::*output-stream*: ~A~%html-inspector-views::*html-stream*:~A~%"
            common-html.emitter::*output-stream*
            html-inspector-views::*html-stream*)
    (object-ref value :select view :highlight t)))


(defmethod common-html.emitter::emit :before ((node t))
  (format t "Emitting ~A~%" node))
