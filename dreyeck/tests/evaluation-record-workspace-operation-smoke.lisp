(in-package #:dreyeck/evaluation-record/workspace-operation/tests)

(defun run-workspace-operation-evaluation-record-projection-test ()
  (let* ((subject '(:subject :evaluation-record-test))
         (operation
          (make-instance 'dreyeck/workspace-operation:workspace-operation :id
                         "operation:evaluation-record-test" :label
                         "Evaluation record workspace operation test"
                         :subject-topic-id "topic:subject" :subject subject
                         :function-symbol 'identity :result-topic-id
                         "topic:result" :intention :query
                         :perlocutionary-action :none :propositional-object
                         '(:proposition :evaluation-record-test)))
         (returned
          (make-instance
           'dreyeck/workspace-operation:workspace-operation-invocation
           :operation operation :status :returned :value :returned-value))
         (condition
          (make-condition 'simple-error :format-control
                          "Evaluation record test failure." :format-arguments
                          nil))
         (failed
          (make-instance
           'dreyeck/workspace-operation:workspace-operation-invocation
           :operation operation :status :failed :condition condition)))
    (unless
        (and
         (eq operation
             (dreyeck/evaluation-record:evaluation-specification-of returned))
         (equal subject
                (dreyeck/evaluation-record:evaluation-input-of returned))
         (eq :returned
             (dreyeck/evaluation-record:evaluation-status-of returned))
         (eq :returned-value
             (dreyeck/evaluation-record:evaluation-result-of returned))
         (null (dreyeck/evaluation-record:evaluation-trace-of returned))
         (null (dreyeck/evaluation-record:evaluation-evidence-of returned))
         (null (dreyeck/evaluation-record:evaluation-failure-of returned))
         (null (dreyeck/evaluation-record:evaluation-started-at-of returned))
         (null (dreyeck/evaluation-record:evaluation-finished-at-of returned))
         (null (dreyeck/evaluation-record:evaluation-identity-of returned))
         (null (dreyeck/evaluation-record:evaluation-annotation-of returned)))
      (error
       "Returned workspace invocation violates the evaluation-record contract."))
    (unless
        (and
         (eq operation
             (dreyeck/evaluation-record:evaluation-specification-of failed))
         (equal subject (dreyeck/evaluation-record:evaluation-input-of failed))
         (eq :failed (dreyeck/evaluation-record:evaluation-status-of failed))
         (null (dreyeck/evaluation-record:evaluation-result-of failed))
         (null (dreyeck/evaluation-record:evaluation-trace-of failed))
         (eq condition
             (dreyeck/evaluation-record:evaluation-evidence-of failed))
         (eq condition
             (dreyeck/evaluation-record:evaluation-failure-of failed))
         (null (dreyeck/evaluation-record:evaluation-started-at-of failed))
         (null (dreyeck/evaluation-record:evaluation-finished-at-of failed))
         (null (dreyeck/evaluation-record:evaluation-identity-of failed))
         (null (dreyeck/evaluation-record:evaluation-annotation-of failed)))
      (error
       "Failed workspace invocation violates the evaluation-record contract."))
    t))

(defun run-workspace-operation-evaluation-record-tests ()
  (run-workspace-operation-evaluation-record-projection-test))
