;;;; Run against the unchanged base checkout with its ASDF registry first.
(require :asdf)
(format t "~&BASELINE-ROOT ~A~%" (uiop:getcwd))
(dolist (system '("dreyeck/work/defederation-planning/tests" "dreyeck/work/planning/tests"
                  "dreyeck/work/remote-control-planning/tests"
                  "dreyeck/work/remote-control-planning/reading/tests"
                  "dreyeck/local-fedwiki-page/tests"
                  "hyperbook/fedwiki/tests"))
  (format t "~&BASELINE TEST-BEGIN ~A~%" system)
  (asdf:test-system system)
  (format t "~&BASELINE TEST-PASS ~A~%" system))

;; A separate upstream edge case, independent of the new Defederation domain.
(defpackage #:defederation-baseline-probe (:use #:cl))
(in-package #:defederation-baseline-probe)
(shop3:defdomain empty-probe-domain
  ((:method (already-ready) ready () ())))
(shop3:defproblem empty-probe-problem empty-probe-domain () ((already-ready)))
(let ((raw (shop3:find-plans 'empty-probe-problem :which :all :verbose 0)))
  (assert raw)
  (assert (equal '(nil) (mapcar #'shop3:shorter-plan raw)))
  (format t "~&BASELINE EMPTY-WITHOUT-TREE PASS: ~S~%" raw))
(handler-case
    (progn (shop3:find-plans 'empty-probe-problem :which :all :verbose 0 :plan-tree t)
           (error "Expected pinned SHOP3 empty-tree defect did not occur."))
  (type-error (condition)
    (format t "~&BASELINE EMPTY-WITH-TREE REPRODUCED: ~A~%" condition)))
