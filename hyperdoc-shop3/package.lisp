;;;; Package definition for optional HyperDoc SHOP3 planning layer
;;
;;;; Copyright (c) 2026

(defpackage #:hyperdoc/shop3
  (:use #:common-lisp
        #:shop3)
  (:export
   #:hyperdoc-htn-plan-result
   #:problem-name-of
   #:plans-of
   #:raw-plans-of
   #:plan-trees-of
   #:final-states-of
   #:time-of
   #:execution-mode-of
   #:plan-tree->safe-sexp
   #:classify-hyperdoc-plan-step
   #:normalize-hyperdoc-plan-step
   #:normalize-hyperdoc-plan
   #:hyperdoc-plan-checklist
   #:hyperdoc-plan-summary
   #:run-hyperdoc-asdf-refactor-plan-object
   #:*hyperdoc-asdf-refactor-plan-steps*
   #:*hyperdoc-asdf-refactor-checklist-fixture-pathname*
   #:read-hyperdoc-asdf-refactor-checklist-fixture
   #:hyperdoc-asdf-refactor-checklist-example))

(in-package #:hyperdoc/shop3)
