;;;; Transclusions of views
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; Define a new node "transclusion" for embedded views.
;; The text of the node is interpreted as Lisp code in the
;; current package and evaluated.
;; A transclusion reference to the result is inserted vie
;; html-inspector-views:transclusion.
;;

(common-doc:define-node transclusion (common-doc:content-node)
  ()
  (:tag-name "transclusion")
  (:documentation "Transclusion of a view on an object"))

(common-html.emitter::define-emitter (ref transclusion)
  (let* ((*package* (slot-value *emitter-state* 'package))
         (expr (common-doc.ops:collect-all-text ref))
         (value (parse-and-eval expr)))
    (transclusion value)))

