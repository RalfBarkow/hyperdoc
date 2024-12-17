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
  ((display :reader ref-display
          :initarg :display
          :type string
          :attribute-name "display"
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
  (let* ((package-name (str:upcase (slot-value ref 'package)))
         (*package* (if-let (p (find-package package-name))
                      p
                      (slot-value *emitter-state* 'package)))
         (text (common-doc.ops:collect-all-text ref))
         (value (parse-and-eval text))
         (display-text (slot-value ref 'display))
         (display (when display-text
                    (parse-and-eval (str:replace-all "\\" ""  display-text))))
         (view (slot-value ref 'view)))
    (object-ref value :display display :select view :highlight t)))

(defun parse-and-eval (string)
  (let ((form (with-input-from-string (input string) (read input))))
    (eval form)))
