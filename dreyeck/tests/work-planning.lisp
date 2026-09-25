(in-package #:dreyeck/work/planning)

(defun check-plan ()
  (let* ((result (documentation-plan-example))
         (plan (first (dreyeck/shop3:plans-of result))))
    (assert (eq :plan-only (dreyeck/shop3:execution-mode-of result)))
    (assert (= 1 (length (dreyeck/shop3:plans-of result))))
    (assert (equal '(source-identified text-formulated example-created rendered
                     verified inspector-exposed topicmap-related reviewed)
                   (mapcar #'fourth plan)))
    (assert (every (lambda (step) (eq '!record-stage (first step))) plan)))
  (assert (null (shop3:find-plans 'connections-without-source :verbose 0)))
  (format t "~&DOCUMENTATION-PLAN-PASS: eight modeled stages; no-source refused; verdict B, fixed sequence only.~%")
  t)
