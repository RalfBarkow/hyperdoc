;;;; Plan objects for optional HyperDoc SHOP3 planning layer
;;
;;;; Copyright (c) 2026

(in-package #:hyperdoc/shop3)

(defclass hyperdoc-htn-plan-result ()
  ((problem-name :initarg :problem-name
                 :reader problem-name-of)
   (plans :initarg :plans
          :reader plans-of)
   (raw-plans :initarg :raw-plans
              :reader raw-plans-of)
   (plan-trees :initarg :plan-trees
               :reader plan-trees-of)
   (final-states :initarg :final-states
                 :reader final-states-of)
   (time :initarg :time
         :reader time-of)
   (execution-mode :initarg :execution-mode
                   :initform :plan-only
                   :reader execution-mode-of)))

(defun %plan-step-p (value)
  (and (consp value)
       (symbolp (first value))))

(defun %operator-name (operator)
  (string-upcase (symbol-name operator)))

(defun %verification-operator-name-p (operator-name)
  (or (string= operator-name "!LOAD-SYSTEM")
      (string= operator-name "!RUN-SMOKE-TEST")))

(defun %source->plan (source)
  (cond
    ((typep source 'hyperdoc-htn-plan-result)
     (or (first (plans-of source))
         '()))
    ((null source)
     '())
    ((and (listp source)
          (or (null source)
              (every #'%plan-step-p source)))
     source)
    ((and (listp source)
          (consp source)
          (listp (first source))
          (or (null (first source))
              (every #'%plan-step-p (first source))))
     (first source))
    (t
     (error "Cannot derive a SHOP3 plan from source: ~S" source))))

(defun plan-tree->safe-sexp (plan-tree)
  (cond
    ((null plan-tree)
     nil)
    ((and (find-package '#:plan-tree)
          (fboundp 'plan-tree:plan-tree->sexp))
     (handler-case
         (plan-tree:plan-tree->sexp plan-tree)
       (error (condition)
         (list :plan-tree-conversion-failed
               (princ-to-string condition)))))
    (t
     (list :plan-tree-api-unavailable
           (type-of plan-tree)))))

(defun classify-hyperdoc-plan-step (step)
  (unless (%plan-step-p step)
    (error "Not a valid SHOP3 plan step: ~S" step))
  (let ((operator-name (%operator-name (first step))))
    (cond
      ((string= operator-name "!COMMIT-STAGE")
       :commit)
      ((%verification-operator-name-p operator-name)
       :verification)
      (t
       :source-edit))))

(defun normalize-hyperdoc-plan-step (step index)
  (destructuring-bind (operator &rest arguments) step
    (let ((operator-name (%operator-name operator)))
      (ecase (classify-hyperdoc-plan-step step)
        (:source-edit
         (list :index index
               :kind :source-edit
               :operator operator
               :arguments arguments
               :manual? t))
        (:commit
         (destructuring-bind (stage message &rest ignored) arguments
           (declare (ignore ignored))
           (list :index index
                 :kind :commit
                 :stage stage
                 :message message
                 :manual? t)))
        (:verification
         (cond
           ((string= operator-name "!LOAD-SYSTEM")
            (list :index index
                  :kind :verification
                  :action :load-system
                  :system (first arguments)
                  :manual? t))
           ((string= operator-name "!RUN-SMOKE-TEST")
            (list :index index
                  :kind :verification
                  :action :run-smoke-test
                  :test (first arguments)
                  :manual? t))
           (t
            (list :index index
                  :kind :verification
                  :operator operator
                  :arguments arguments
                  :manual? t))))))))

(defun normalize-hyperdoc-plan (plan)
  (loop for step in plan
        for index from 1
        collect (normalize-hyperdoc-plan-step step index)))

(defun hyperdoc-plan-checklist (source)
  (normalize-hyperdoc-plan (%source->plan source)))

(defun hyperdoc-plan-summary (source)
  (let* ((checklist (hyperdoc-plan-checklist source))
         (result (and (typep source 'hyperdoc-htn-plan-result)
                      source))
         (source-edits (count :source-edit checklist :key (lambda (item) (getf item :kind))))
         (commits (count :commit checklist :key (lambda (item) (getf item :kind))))
         (verifications (count :verification checklist :key (lambda (item) (getf item :kind)))))
    (list :problem-name (and result (problem-name-of result))
          :execution-mode (if result
                              (execution-mode-of result)
                              :plan-only)
          :plan-count (if result
                          (length (plans-of result))
                          (if checklist 1 0))
          :step-count (length checklist)
          :source-edits source-edits
          :commits commits
          :verifications verifications
          :manual-steps (count-if (lambda (item) (getf item :manual?)) checklist))))
