;;;; Optional SHOP3 experiment: simulated documentation stages, never execution.
(defpackage #:dreyeck/work/planning
  (:use #:cl)
  (:export #:documentation-plan-example))
(in-package #:dreyeck/work/planning)

(shop3:defdomain document-d2-concept
  ((:operator (!record-stage ?concept ?before ?after)
    ((modeled-stage ?concept ?before))
    ((modeled-stage ?concept ?before))
    ((modeled-stage ?concept ?after)))
   (:method (document-one-D2-concept ?concept)
    ((source-known ?concept))
    ((!record-stage ?concept unstarted source-identified)
     (!record-stage ?concept source-identified text-formulated)
     (!record-stage ?concept text-formulated example-created)
     (!record-stage ?concept example-created rendered)
     (!record-stage ?concept rendered verified)
     (!record-stage ?concept verified inspector-exposed)
     (!record-stage ?concept inspector-exposed topicmap-related)
     (!record-stage ?concept topicmap-related reviewed)))))

(shop3:defproblem connections-documentation document-d2-concept
  ((source-known connections) (modeled-stage connections unstarted))
  ((document-one-D2-concept connections)))

(shop3:defproblem connections-without-source document-d2-concept
  ((modeled-stage connections unstarted))
  ((document-one-D2-concept connections)))

(defun documentation-plan-example ()
  "Return an existing HyperDoc plan-result object. All stages are hypothetical.
There are no external actions, callbacks or authoring executor in this domain."
  (multiple-value-bind (raw time trees states)
      (shop3:find-plans 'connections-documentation :which :first
                        :verbose 0 :plan-tree t)
    (unless raw (error "SHOP3 returned no documentation plan."))
    (make-instance 'dreyeck/shop3:hyperdoc-htn-plan-result
                   :problem-name 'connections-documentation
                   :plans (mapcar #'shop3:shorter-plan raw) :raw-plans raw
                   :plan-trees trees :final-states states :time time
                   :execution-mode :plan-only)))
