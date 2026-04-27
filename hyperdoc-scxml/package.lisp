;;;; Package definition for HyperDoc SCXML compiler
;;
;;;; Copyright (c) 2026

(defpackage :hyperdoc/scxml
  (:use :cl)
  (:export
   #:parse-scxml-file
   #:parse-scxml-string
   #:validate-scxml-chart
   #:scxml-chart-valid-p
   #:compile-scxml-chart-to-forms
   #:compile-scxml-chart-to-string
   #:compile-scxml-file-to-lisp-file
   #:compile-and-run-scxml-file

   #:scxml-chart
   #:scxml-state
   #:scxml-transition
   #:scxml-action
   #:scxml-validation-finding

   #:scxml-chart-name-of
   #:scxml-chart-initial-state-of
   #:scxml-chart-states-of
   #:scxml-chart-source-pathname-of

   #:scxml-state-id-of
   #:scxml-state-final-p-of
   #:scxml-state-onentry-actions-of
   #:scxml-state-transitions-of

   #:scxml-transition-event-of
   #:scxml-transition-target-of
   #:scxml-transition-id-of
   #:scxml-transition-source-state-id-of

   #:scxml-action-kind-of
   #:scxml-action-attributes-of

   #:scxml-validation-finding-severity-of
   #:scxml-validation-finding-code-of
   #:scxml-validation-finding-message-of
   #:scxml-validation-finding-context-of

   #:generated-scxml-run
   #:make-generated-scxml-run
   #:generated-scxml-run-trace-of
   #:generated-scxml-run-final-state-of
   #:generated-scxml-run-done-p
   #:generated-scxml-run-machine-of))
