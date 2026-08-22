(in-package #:dreyeck/shop3)

(defmethod print-object ((result hyperdoc-htn-plan-result) stream)
  (print-unreadable-object (result stream :type t)
    (format stream "~S ~D plan~:P mode ~S" (problem-name-of result)
            (length (plans-of result)) (execution-mode-of result))))
