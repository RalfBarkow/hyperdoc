;;;; Node for defining the package for embedded Lisp code
;;
;;;; Copyright (c) 2024 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

(common-doc:define-node package-reference (common-doc:content-node)
  ()
  (:tag-name "package")
  (:documentation "Package specification for embedded Lisp code"))

(common-html.emitter::define-emitter (ref package-reference)
  (let* ((text (common-doc.ops:collect-all-text ref))
         (package-identifier (str:upcase text))
         (package (find-package package-identifier)))
    (setf (slot-value *emitter-state* 'package) package)))
