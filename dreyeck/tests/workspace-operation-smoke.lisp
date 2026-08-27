(in-package #:dreyeck/workspace-operation/tests)

(defun run-workspace-operation-core-test ()
  (let* ((probe-symbol (gensym "WORKSPACE-OPERATION-TEST-"))
         (subject (list :probe :subject))
         (received nil)
         (operation
          (make-instance 'dreyeck/workspace-operation:workspace-operation :id
                         "operation:workspace-operation-test" :label
                         "Workspace operation test" :subject-topic-id
                         "topic:subject" :subject subject :function-symbol
                         probe-symbol :result-topic-id "topic:result"
                         :intention :query :perlocutionary-action :none
                         :propositional-object (list :proposition :different))))
    (unwind-protect
        (progn
         (setf (symbol-function probe-symbol)
                 (lambda (argument) (setf received argument) :first-result))
         (let ((result
                (dreyeck/workspace-operation:invoke-workspace-operation
                 operation)))
           (unless
               (and (eq :first-result result) (eq subject received)
                    (eq :first-result
                        (dreyeck/workspace-operation:workspace-operation-last-result-of
                         operation)))
             (error
              "Successful workspace-operation invocation violates its contract.")))
         (setf (symbol-function probe-symbol)
                 (lambda (argument)
                   (declare (ignore argument))
                   (error "Direct invocation failure.")))
         (let ((signaled-p nil))
           (handler-case
            (dreyeck/workspace-operation:invoke-workspace-operation operation)
            (error nil (setf signaled-p t)))
           (unless
               (and signaled-p
                    (eq :first-result
                        (dreyeck/workspace-operation:workspace-operation-last-result-of
                         operation)))
             (error "Failed direct invocation changed LAST-RESULT.")))
         (let ((failure
                (dreyeck/workspace-operation:invoke-workspace-operation-recording-result
                 operation)))
           (unless
               (and
                (typep failure
                       'dreyeck/workspace-operation:workspace-operation-invocation)
                (eq operation
                    (dreyeck/workspace-operation:workspace-operation-invocation-operation-of
                     failure))
                (eq :failed
                    (dreyeck/workspace-operation:workspace-operation-invocation-status-of
                     failure))
                (null
                 (dreyeck/workspace-operation:workspace-operation-invocation-value-of
                  failure))
                (typep
                 (dreyeck/workspace-operation:workspace-operation-invocation-condition-of
                  failure)
                 'error)
                (eq :first-result
                    (dreyeck/workspace-operation:workspace-operation-last-result-of
                     operation)))
             (error "Failed recorded invocation violates its contract.")))
         (setf (symbol-function probe-symbol)
                 (lambda (argument)
                   (declare (ignore argument))
                   :second-result))
         (let ((success
                (dreyeck/workspace-operation:invoke-workspace-operation-recording-result
                 operation)))
           (unless
               (and
                (eq :returned
                    (dreyeck/workspace-operation:workspace-operation-invocation-status-of
                     success))
                (eq :second-result
                    (dreyeck/workspace-operation:workspace-operation-invocation-value-of
                     success))
                (null
                 (dreyeck/workspace-operation:workspace-operation-invocation-condition-of
                  success))
                (eq :second-result
                    (dreyeck/workspace-operation:workspace-operation-last-result-of
                     operation))
                (search "Workspace operation test"
                        (prin1-to-string operation)))
             (error "Successful recorded invocation violates its contract.")))
         t)
      (when (fboundp probe-symbol) (fmakunbound probe-symbol)))))

(defun run-workspace-operation-tests () (run-workspace-operation-core-test))
