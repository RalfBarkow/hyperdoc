;;;; Runtime model for generated SCXML runs
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc/scxml)

(defstruct generated-scxml-run
  trace
  final-state
  done-p
  machine)

(defun generated-scxml-run-trace-of (run)
  (generated-scxml-run-trace run))

(defun generated-scxml-run-final-state-of (run)
  (generated-scxml-run-final-state run))

(defun generated-scxml-run-machine-of (run)
  (generated-scxml-run-machine run))
