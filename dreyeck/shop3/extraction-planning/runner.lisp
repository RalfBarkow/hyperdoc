;;;; Live SHOP3 runner for the eighth extraction commit-3 localization.

(in-package #:dreyeck/shop3)

(defun run-eighth-dreyeck-extraction-commit-3-localization-plan ()
  "Run the registered SHOP3 problem without a heuristic fallback."
  (multiple-value-bind (raw-plans run-time plan-trees final-states)
      (shop3:find-plans
       'dreyeck/shop3::eighth-dreyeck-extraction-commit-3-localization
       :which :first
       :verbose 0
       :plan-tree t)
    (unless raw-plans
      (error "SHOP3:FIND-PLANS found no commit-3 localization plan."))
    (list
     :planner :shop3
     :planner-call :live
     :find-plans-symbol "SHOP3:FIND-PLANS"
     :heuristic-fallback nil
     :domain
     'eighth-dreyeck-extraction-commit-3-localization-domain
     :problem
     'eighth-dreyeck-extraction-commit-3-localization
     :problem-symbol
     'dreyeck/shop3::eighth-dreyeck-extraction-commit-3-localization
     :plans raw-plans
     :raw-plans raw-plans
     :shorter-plans (mapcar #'shop3:shorter-plan raw-plans)
     :plan-trees plan-trees
     :plan-tree-projection :raw-shop3-plan-trees
     :final-states (mapcar #'%state->atoms final-states)
     :final-state-projection :state-atoms
     :run-time run-time)))

(defun run-eighth-dreyeck-extraction-commit-3-preparation-plan ()
  "Run the registered SHOP3 preparation problem without a heuristic fallback."
  (multiple-value-bind (raw-plans run-time plan-trees final-states)
      (shop3:find-plans
       'dreyeck/shop3::eighth-dreyeck-extraction-commit-3-preparation
       :which :first
       :verbose 0
       :plan-tree t)
    (unless raw-plans
      (error "SHOP3:FIND-PLANS found no commit-3 preparation plan."))
    (list
     :planner :shop3
     :planner-call :live
     :find-plans-symbol "SHOP3:FIND-PLANS"
     :heuristic-fallback nil
     :domain
     'eighth-dreyeck-extraction-commit-3-preparation-domain
     :problem
     'eighth-dreyeck-extraction-commit-3-preparation
     :problem-symbol
     'dreyeck/shop3::eighth-dreyeck-extraction-commit-3-preparation
     :plans raw-plans
     :raw-plans raw-plans
     :shorter-plans (mapcar #'shop3:shorter-plan raw-plans)
     :plan-trees plan-trees
     :plan-tree-projection :raw-shop3-plan-trees
     :final-states (mapcar #'%state->atoms final-states)
     :final-state-projection :state-atoms
     :run-time run-time)))

(defun run-eighth-dreyeck-extraction-commit-3-execution-plan ()
  "Run the registered SHOP3 execution problem without invoking an executor."
  (multiple-value-bind (raw-plans run-time plan-trees final-states)
      (shop3:find-plans
       'dreyeck/shop3::eighth-dreyeck-extraction-commit-3-execution
       :which :first
       :verbose 0
       :plan-tree t)
    (unless raw-plans
      (error "SHOP3:FIND-PLANS found no commit-3 execution plan."))
    (list
     :planner :shop3
     :planner-call :live
     :executor-invoked nil
     :find-plans-symbol "SHOP3:FIND-PLANS"
     :heuristic-fallback nil
     :domain
     'eighth-dreyeck-extraction-commit-3-execution-domain
     :problem
     'eighth-dreyeck-extraction-commit-3-execution
     :problem-symbol
     'dreyeck/shop3::eighth-dreyeck-extraction-commit-3-execution
     :plans raw-plans
     :raw-plans raw-plans
     :shorter-plans (mapcar #'shop3:shorter-plan raw-plans)
     :plan-trees plan-trees
     :plan-tree-projection :raw-shop3-plan-trees
     :final-states (mapcar #'%state->atoms final-states)
     :final-state-projection :state-atoms
     :run-time run-time)))
