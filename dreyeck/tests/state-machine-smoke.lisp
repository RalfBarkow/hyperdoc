(in-package #:dreyeck/state-machine/tests)

(defun example-state-machine-source-evidence ()
  (list
   (list :layer "HyperDoc page" :reference
         "Operational definition: state machine, state, transition, guard, run trace"
         :detail "Durable definition of the reusable machine/run split.")
   (list :layer "HyperDoc topic" :reference "State machine" :detail
         "Stable semantic anchor for the generic abstraction.")
   (list :layer "Lisp source" :reference "hyperdoc/state-machines.lisp" :detail
         "Runtime definition objects and run objects.")
   (list :layer "Test" :reference "tests/state-machine-smoke.lisp" :detail
         "Smoke coverage for the generic definition/run objects.")))

(defun make-example-state-machine-definition ()
  (make-state-machine-definition :id "state-machine-definition/example" :title
                                 "Example evidence-bearing state machine"
                                 :summary
                                 "Small generic example machine that keeps definition, guards, failure branches, and evidence trace distinct from any one DMX-specific use case."
                                 :states
                                 (list
                                  (make-state-machine-state :id "captured"
                                                            :title "Captured"
                                                            :summary
                                                            "Input has been captured and can be checked."
                                                            :entry-condition
                                                            "Input bundle present"
                                                            :exit-condition
                                                            "Validation step begins")
                                  (make-state-machine-state :id "validated"
                                                            :title "Validated"
                                                            :summary
                                                            "Required support conditions are satisfied."
                                                            :entry-condition
                                                            "Support condition proved"
                                                            :exit-condition
                                                            "Commit step begins")
                                  (make-state-machine-state :id "committed"
                                                            :title "Committed"
                                                            :summary
                                                            "Result is terminal and durable."
                                                            :entry-condition
                                                            "Commit event accepted"
                                                            :notes
                                                            "Terminal success state.")
                                  (make-state-machine-state :id "rejected"
                                                            :title "Rejected"
                                                            :summary
                                                            "The run stopped at an explicit failure branch."
                                                            :entry-condition
                                                            "Guard failed"
                                                            :notes
                                                            "Failure state."))
                                 :transitions
                                 (list
                                  (make-state-machine-transition :id
                                                                 "capture->validate"
                                                                 :from-state
                                                                 "captured"
                                                                 :to-state
                                                                 "validated"
                                                                 :trigger
                                                                 "validate"
                                                                 :guard
                                                                 "support-available"
                                                                 :emitted-evidence
                                                                 "validation-report"
                                                                 :side-effects
                                                                 "none"
                                                                 :reversible-p
                                                                 nil)
                                  (make-state-machine-transition :id
                                                                 "validate->commit"
                                                                 :from-state
                                                                 "validated"
                                                                 :to-state
                                                                 "committed"
                                                                 :trigger
                                                                 "commit"
                                                                 :guard
                                                                 "invariants-hold"
                                                                 :emitted-evidence
                                                                 "commit-record"
                                                                 :side-effects
                                                                 "durable artifact written"
                                                                 :reversible-p
                                                                 nil)
                                  (make-state-machine-transition :id
                                                                 "validate->reject"
                                                                 :from-state
                                                                 "validated"
                                                                 :to-state
                                                                 "rejected"
                                                                 :trigger
                                                                 "reject"
                                                                 :guard
                                                                 "support-missing"
                                                                 :emitted-evidence
                                                                 "failure-report"
                                                                 :side-effects
                                                                 "no durable write"
                                                                 :reversible-p
                                                                 nil))
                                 :initial-state "captured" :terminal-states
                                 '("committed") :guards
                                 '("support-available" "invariants-hold"
                                   "support-missing")
                                 :events '("validate" "commit" "reject")
                                 :invariants
                                 (list
                                  (list :label "Single current state" :detail
                                        "Exactly one current state is permitted in ordinary runs.")
                                  (list :label "Known-state transitions"
                                        :detail
                                        "Every transition must reference known states.")
                                  (list :label "Terminal stop" :detail
                                        "Terminal states have no outgoing transitions."))
                                 :failure-states '("rejected") :source-evidence
                                 (example-state-machine-source-evidence) :notes
                                 (list
                                  (list :label "Generic example" :detail
                                        "This machine is intentionally small so the generic views are inspectable immediately."))
                                 :multi-initial-p nil :multi-current-p nil
                                 :allow-terminal-outgoing-p nil :acyclic-p t))

(defun make-example-state-machine-run ()
  (let ((machine (make-example-state-machine-definition)))
    (make-state-machine-run :id "state-machine-run/example" :title
                            "Example state-machine run" :summary
                            "Concrete successful run of the generic example state machine."
                            :machine machine :input
                            (list (cons "input-id" "example-42")
                                  (cons "support-bundle" "present"))
                            :current-state "committed" :visited-states
                            '("captured" "validated" "committed")
                            :transition-trace
                            (list
                             (list :timestamp 1 :kind :transition
                                   :transition-id "capture->validate"
                                   :from-state "captured" :to-state "validated"
                                   :trigger "validate" :guard
                                   "support-available")
                             (list :timestamp 2 :kind :transition
                                   :transition-id "validate->commit"
                                   :from-state "validated" :to-state
                                   "committed" :trigger "commit" :guard
                                   "invariants-hold")
                             (list :timestamp 3 :kind :skipped-branch
                                   :transition-id "validate->reject"
                                   :from-state "validated" :to-state "rejected"
                                   :detail
                                   "Failure branch was not taken because support remained available."))
                            :evidence-trace
                            (list
                             (list :timestamp 0 :kind :state-entry :state-id
                                   "captured" :evidence
                                   "Input bundle recorded.")
                             (list :timestamp 1 :kind :transition
                                   :transition-id "capture->validate" :evidence
                                   "Validation report emitted.")
                             (list :timestamp 2 :kind :transition
                                   :transition-id "validate->commit" :evidence
                                   "Commit record persisted."))
                            :start-time 0 :end-time 2 :status :success
                            :failure-classification nil :notes
                            (list
                             (list :label "Example run" :detail
                                   "Successful trace for the generic example machine.")))))

(defun run-state-machine-runtime-test ()
  (let* ((machine (make-example-state-machine-definition))
         (run (make-example-state-machine-run))
         (machine-findings (state-machine-definition-findings machine))
         (run-findings (state-machine-run-findings run)))
    (assert (typep machine 'state-machine-definition))
    (assert (typep run 'state-machine-run))
    (assert
     (every (lambda (finding) (eq :ok (getf finding :status)))
            machine-findings))
    (assert
     (every (lambda (finding) (eq :ok (getf finding :status))) run-findings))
    (assert (eq :success (state-machine-run-status-of run)))
    (assert (= 3 (length (state-machine-run-transition-trace-of run))))
    (assert (= 3 (length (state-machine-run-evidence-trace-of run))))
    t))

(defun run-state-machine-tests () (run-state-machine-runtime-test))
