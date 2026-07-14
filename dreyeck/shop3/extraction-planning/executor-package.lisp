;;;; Closed-dispatch executor package for accepted SHOP3 extraction plans.

(defpackage #:dreyeck/shop3/executor
  (:use #:common-lisp)
  (:export
   #:commit-3-execution-plan
   #:commit-3-execution-context-report
   #:execute-plan
   #:execute-plan-armed
   #:execute-plan-action
   #:make-commit-3-executor
   #:make-commit-3-execution-context
   #:normalize-shop3-plan
   #:operator-registry
   #:resolve-operator-handler))

(in-package #:dreyeck/shop3/executor)
