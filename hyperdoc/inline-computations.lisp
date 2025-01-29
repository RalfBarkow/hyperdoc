;;;; In-line computations
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; Define a new node "value" for in-line computations.
;; The text of the node is interpreted as Lisp code in the
;; current package and evaluated. The HTML representation
;; of the value is inserted into the document.
;;

(common-doc:define-node inline-value (common-doc:content-node)
  ()
  (:tag-name "value")
  (:documentation "Value computed from an expression, inserted into the text"))

(common-html.emitter::define-emitter (node inline-value)
  (let* ((text (common-doc.ops:collect-all-text node))
         (*package* (slot-value *emitter-state* 'package))
         (value (parse-and-eval text)))
    (html
      (:span :class "hyperdoc-computed-value"
             :title text
             (html-representation value)))))
