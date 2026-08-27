(defpackage #:dreyeck/workspace-operation
  (:use #:cl)
  (:export #:workspace-operation
           #:workspace-operation-id-of
           #:workspace-operation-label-of
           #:workspace-operation-subject-topic-id-of
           #:workspace-operation-subject-of
           #:workspace-operation-function-symbol-of
           #:workspace-operation-result-topic-id-of
           #:workspace-operation-last-result-of
           #:workspace-operation-intention-of
           #:workspace-operation-perlocutionary-action-of
           #:workspace-operation-propositional-object-of
           #:workspace-operation-invocation
           #:workspace-operation-invocation-operation-of
           #:workspace-operation-invocation-status-of
           #:workspace-operation-invocation-value-of
           #:workspace-operation-invocation-condition-of
           #:invoke-workspace-operation
           #:invoke-workspace-operation-recording-result))
