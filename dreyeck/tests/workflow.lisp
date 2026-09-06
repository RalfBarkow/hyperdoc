(defpackage #:dreyeck/workflow/tests
  (:use #:cl))

(in-package #:dreyeck/workflow/tests)

(defun run-tests ()
  (let ((specifications
          dreyeck/workflow::*workflow-operation-assembly-specifications*))
    (assert (= 14 (length specifications)))
    (dolist (specification specifications)
      (let ((operation
              (getf specification :operation)))
        (assert operation)
        (dreyeck/workflow::validate-construction-completeness
         operation)
        (dreyeck/workflow::materialize-operation-deterministically
         operation)
        (assert (fboundp operation))))
    (format t "~&Dreyeck workflow generative reconstruction tests passed.~%")
    t))
