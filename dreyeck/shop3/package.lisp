;;;; Package definition for optional Dreyeck SHOP3 planning layer
;;
;;;; Copyright (c) 2026

(defpackage #:hyperdoc/shop3
  (:nicknames #:dreyeck/shop3)
  (:use #:common-lisp
        #:shop3)
  (:import-from #:hyperdoc/shop3-provider
   #:register-shop3-provider-source-registry
   #:shop3-provider-boundary-report-selected-directories
   #:shop3-provider-boundary-report-rejected-directories)
  (:export
   #:register-shop3-provider-source-registry
   #:shop3-provider-boundary-report-selected-directories
   #:shop3-provider-boundary-report-rejected-directories
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
   #:*shop3-introduction-source-url*
   #:parse-shop3-introduction-topics
   #:run-hyperdoc-asdf-refactor-plan-object
   #:*hyperdoc-asdf-refactor-plan-steps*
   #:*hyperdoc-asdf-refactor-checklist-fixture-pathname*
   #:read-hyperdoc-asdf-refactor-checklist-fixture
   #:hyperdoc-asdf-refactor-checklist-example))

(in-package #:dreyeck/shop3)
