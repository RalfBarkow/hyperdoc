(in-package #:dreyeck/evaluation-record/tests)

(defun run-evaluation-record-protocol-test ()
  (let* ((state-run
          (dreyeck/state-machine/tests::make-example-state-machine-run))
         (contract
          (make-instance 'dreyeck/lisp-critic:lisp-critic-contract :id
                         "evaluation-record-test-contract" :title
                         "Evaluation record test contract"))
         (critic-run
          (make-instance 'dreyeck/lisp-critic:lisp-critic-run-record :id
                         "evaluation-record-test-run" :contract contract
                         :target-paths '("example.lisp") :status :failed
                         :started-at 10 :finished-at 11 :raw-output "raw"
                         :error-output "error" :condition-summary "condition"
                         :invocation-form '(:run "example.lisp") :notes
                         '(:test))))
    (unless
        (and
         (typep
          (dreyeck/evaluation-record:evaluation-specification-of state-run)
          'dreyeck/state-machine:state-machine-definition)
         (equal '(("input-id" . "example-42") ("support-bundle" . "present"))
                (dreyeck/evaluation-record:evaluation-input-of state-run))
         (eq :success
             (dreyeck/evaluation-record:evaluation-status-of state-run))
         (string= "committed"
                  (dreyeck/evaluation-record:evaluation-result-of state-run))
         (not (null (dreyeck/evaluation-record:evaluation-trace-of state-run)))
         (not
          (null (dreyeck/evaluation-record:evaluation-evidence-of state-run)))
         (null (dreyeck/evaluation-record:evaluation-failure-of state-run))
         (= 0 (dreyeck/evaluation-record:evaluation-started-at-of state-run))
         (= 2 (dreyeck/evaluation-record:evaluation-finished-at-of state-run))
         (string= "state-machine-run/example"
                  (dreyeck/evaluation-record:evaluation-identity-of state-run))
         (not
          (null
           (dreyeck/evaluation-record:evaluation-annotation-of state-run))))
      (error
       "State-machine evaluation-record projection violates its contract."))
    (unless
        (and
         (eq contract
             (dreyeck/evaluation-record:evaluation-specification-of
              critic-run))
         (equal '("example.lisp")
                (dreyeck/evaluation-record:evaluation-input-of critic-run))
         (eq :failed
             (dreyeck/evaluation-record:evaluation-status-of critic-run))
         (string= "raw"
                  (dreyeck/evaluation-record:evaluation-result-of critic-run))
         (null (dreyeck/evaluation-record:evaluation-trace-of critic-run))
         (equal
          '(:invocation-form (:run "example.lisp") :raw-output "raw"
            :error-output "error" :condition-summary "condition")
          (dreyeck/evaluation-record:evaluation-evidence-of critic-run))
         (string= "condition"
                  (dreyeck/evaluation-record:evaluation-failure-of critic-run))
         (= 10 (dreyeck/evaluation-record:evaluation-started-at-of critic-run))
         (= 11
            (dreyeck/evaluation-record:evaluation-finished-at-of critic-run))
         (string= "evaluation-record-test-run"
                  (dreyeck/evaluation-record:evaluation-identity-of
                   critic-run))
         (equal '(:test)
                (dreyeck/evaluation-record:evaluation-annotation-of
                 critic-run)))
      (error
       "LISP-CRITIC evaluation-record projection violates its contract."))
    t))

(defun run-evaluation-record-tests () (run-evaluation-record-protocol-test))
