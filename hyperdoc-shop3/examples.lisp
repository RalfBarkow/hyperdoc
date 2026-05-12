;;;; Examples and fixtures for optional HyperDoc SHOP3 planning layer
;;
;;;; Copyright (c) 2026

(in-package #:hyperdoc/shop3)

(defparameter *hyperdoc-asdf-refactor-checklist-fixture-pathname*
  (asdf:system-relative-pathname
   :hyperdoc
   "hyperdoc-shop3-asdf-refactor-plan.sexp"))

(defun read-hyperdoc-asdf-refactor-checklist-fixture
    (&optional (pathname *hyperdoc-asdf-refactor-checklist-fixture-pathname*))
  (with-open-file (stream pathname :direction :input)
    (let ((*package* (find-package '#:hyperdoc/shop3)))
      (read stream nil nil))))

(defun hyperdoc-asdf-refactor-checklist-example ()
  (let* ((plan-result (run-hyperdoc-asdf-refactor-plan-object))
         (computed-checklist (hyperdoc-plan-checklist plan-result))
         (fixture-checklist (read-hyperdoc-asdf-refactor-checklist-fixture)))
    (list :matches-fixture (equal computed-checklist fixture-checklist)
          :computed-checklist computed-checklist
          :fixture-checklist fixture-checklist
          :summary (hyperdoc-plan-summary plan-result))))
