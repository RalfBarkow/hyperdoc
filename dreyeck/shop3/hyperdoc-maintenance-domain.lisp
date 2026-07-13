;;;; SHOP3 domain for HyperDoc maintenance planning
;;
;;;; Copyright (c) 2026

(in-package #:dreyeck/shop3)

(defparameter *hyperdoc-asdf-refactor-plan-steps*
  '((!add-recursive-component-collector)
    (!commit-stage recursive-component-collector-added
     add-recursive-hyperdoc-source-component-discovery)
    (!create-asdf-system hyperdoc/kernel)
    (!create-asdf-system hyperdoc/topics)
    (!commit-stage hyperdoc/topics
     introduce-hyperdoc-kernel-and-topics-systems)
    (!split-topic-family asdf)
    (!load-system hyperdoc)
    (!run-smoke-test compile-order-smoke)
    (!commit-stage compile-order-smoke
     split-asdf-topic-family-and-verify-load-order)))

;; Keep the operator argument order exactly:
;; (:operator task preconditions delete-list add-list)
(defdomain hyperdoc-maintenance
  ((:operator (!add-recursive-component-collector)
    ((step 1))
    ((step 1))
    ((step 2)))

   (:operator (!commit-stage ?stage ?message)
    ((step ?index)
     (commit-step ?index ?stage ?message)
     (next-step ?index ?next))
    ((step ?index))
    ((step ?next)))

   (:operator (!create-asdf-system ?system)
    ((step ?index)
     (create-system-step ?index ?system)
     (next-step ?index ?next))
    ((step ?index))
    ((step ?next)))

   (:operator (!split-topic-family ?family)
    ((step ?index)
     (split-topic-family-step ?index ?family)
     (next-step ?index ?next))
    ((step ?index))
    ((step ?next)))

   (:operator (!load-system ?system)
    ((step ?index)
     (load-system-step ?index ?system)
     (next-step ?index ?next))
    ((step ?index))
    ((step ?next)))

   (:operator (!run-smoke-test ?test-name)
    ((step ?index)
     (smoke-test-step ?index ?test-name)
     (next-step ?index ?next))
    ((step ?index))
    ((step ?next)))

   (:method (apply-hyperdoc-asdf-refactor-plan)
    ((step 1))
    ((!add-recursive-component-collector)
     (!commit-stage recursive-component-collector-added
      add-recursive-hyperdoc-source-component-discovery)
     (!create-asdf-system hyperdoc/kernel)
     (!create-asdf-system hyperdoc/topics)
     (!commit-stage hyperdoc/topics
      introduce-hyperdoc-kernel-and-topics-systems)
     (!split-topic-family asdf)
     (!load-system hyperdoc)
     (!run-smoke-test compile-order-smoke)
     (!commit-stage compile-order-smoke
      split-asdf-topic-family-and-verify-load-order)))))

(defproblem hyperdoc-asdf-refactor-001
  hyperdoc-maintenance
  ((step 1)
   (next-step 1 2)
   (next-step 2 3)
   (next-step 3 4)
   (next-step 4 5)
   (next-step 5 6)
   (next-step 6 7)
   (next-step 7 8)
   (next-step 8 9)
   (next-step 9 10)
   (commit-step 2 recursive-component-collector-added
                add-recursive-hyperdoc-source-component-discovery)
   (create-system-step 3 hyperdoc/kernel)
   (create-system-step 4 hyperdoc/topics)
   (commit-step 5 hyperdoc/topics
                introduce-hyperdoc-kernel-and-topics-systems)
   (split-topic-family-step 6 asdf)
   (load-system-step 7 hyperdoc)
   (smoke-test-step 8 compile-order-smoke)
   (commit-step 9 compile-order-smoke
                split-asdf-topic-family-and-verify-load-order))
  ((apply-hyperdoc-asdf-refactor-plan)))

(defun %state->atoms (state)
  (handler-case
      (state-atoms state)
    (error ()
      state)))

(defun run-hyperdoc-asdf-refactor-plan-object ()
  (multiple-value-bind (raw-plans run-time plan-trees final-states)
      (find-plans 'hyperdoc-asdf-refactor-001
                  :which :first
                  :verbose 0
                  :plan-tree t)
    (make-instance 'hyperdoc-htn-plan-result
                   :problem-name 'hyperdoc-asdf-refactor-001
                   :plans (mapcar #'shorter-plan raw-plans)
                   :raw-plans raw-plans
                   :plan-trees (mapcar #'plan-tree->safe-sexp plan-trees)
                   :final-states (mapcar #'%state->atoms final-states)
                   :time run-time
                   :execution-mode :plan-only)))
