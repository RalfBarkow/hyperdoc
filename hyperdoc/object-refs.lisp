;;;; Embedded object references 
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; Define a new node "object" for embedded object references.
;; The text of the node is interpreted as Lisp code in the
;; current package and evaluated.
;; An inspector reference to the result is inserted vie
;; html-inspector-views:object-ref.
;;

(common-doc:define-node object-reference (common-doc:content-node)
  ((display :reader ref-display
            :initarg :display
            :type string
            :attribute-name "display"
            :documentation "Function that computes the displayed text")
   (text :reader ref-text
          :initarg :text
          :type string
          :attribute-name "text"
          :documentation "Text displayed in the reference, replacing the object's print string")
   (view :reader ref-view
         :initarg :view
         :type string
         :attribute-name "view"
         :documentation "The view to preselect for inspecting the value"))
  (:tag-name "object")
  (:documentation "Inspectable reference to a Lisp object"))

(common-html.emitter::define-emitter (ref object-reference)
  (let* ((*package* (slot-value *emitter-state* 'package))
         (expr (common-doc.ops:collect-all-text ref))
         (value (parse-and-eval expr))
         (text (ref-text ref))
         (display-expr (ref-display ref))
         (display (if text
                      text
                      (when display-expr
                        (parse-and-eval (str:replace-all "\\" ""  display-expr)))))
         (view (ref-view ref)))
    (object-ref value :display display :select view :highlight t)))

(defun parse-and-eval (string)
  (let ((form (with-input-from-string (input string) (read input))))
    (eval form)))
