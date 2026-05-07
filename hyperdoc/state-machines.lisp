;;;; Generic state-machine runtime objects for HyperDoc
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defclass state-machine-state ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (role :reader state-machine-state-role-of
         :initarg :role
         :initform :intermediate)
   (entry-condition :reader state-machine-state-entry-condition-of
                    :initarg :entry-condition
                    :initform nil)
   (exit-condition :reader state-machine-state-exit-condition-of
                   :initarg :exit-condition
                   :initform nil)
   (notes :reader state-machine-state-notes-of
          :initarg :notes
          :initform nil)))

(defclass state-machine-transition ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title
          :initform nil)
   (from-state :reader state-machine-transition-from-state-of
               :initarg :from-state)
   (to-state :reader state-machine-transition-to-state-of
             :initarg :to-state)
   (trigger :reader state-machine-transition-trigger-of
            :initarg :trigger
            :initform nil)
   (guard :reader state-machine-transition-guard-of
          :initarg :guard
          :initform nil)
   (emitted-evidence :reader state-machine-transition-emitted-evidence-of
                     :initarg :emitted-evidence
                     :initform nil)
   (side-effects :reader state-machine-transition-side-effects-of
                 :initarg :side-effects
                 :initform nil)
   (reversible-p :reader state-machine-transition-reversible-p-of
                 :initarg :reversible-p
                 :initform nil)
   (notes :reader state-machine-transition-notes-of
          :initarg :notes
          :initform nil)))

(defclass state-machine-definition ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (states :reader state-machine-definition-states-of
           :initarg :states
           :initform nil)
   (transitions :reader state-machine-definition-transitions-of
                :initarg :transitions
                :initform nil)
   (initial-state :reader state-machine-definition-initial-state-of
                  :initarg :initial-state)
   (terminal-states :reader state-machine-definition-terminal-states-of
                    :initarg :terminal-states
                    :initform nil)
   (guards :reader state-machine-definition-guards-of
           :initarg :guards
           :initform nil)
   (events :reader state-machine-definition-events-of
           :initarg :events
           :initform nil)
   (invariants :reader state-machine-definition-invariants-of
               :initarg :invariants
               :initform nil)
   (failure-states :reader state-machine-definition-failure-states-of
                   :initarg :failure-states
                   :initform nil)
   (source-evidence :reader state-machine-definition-source-evidence-of
                    :initarg :source-evidence
                    :initform nil)
   (notes :reader state-machine-definition-notes-of
          :initarg :notes
          :initform nil)
   (multi-initial-p :reader state-machine-definition-multi-initial-p-of
                    :initarg :multi-initial-p
                    :initform nil)
   (multi-current-p :reader state-machine-definition-multi-current-p-of
                    :initarg :multi-current-p
                    :initform nil)
   (allow-terminal-outgoing-p
    :reader state-machine-definition-allow-terminal-outgoing-p-of
    :initarg :allow-terminal-outgoing-p
    :initform nil)
   (acyclic-p :reader state-machine-definition-acyclic-p-of
              :initarg :acyclic-p
              :initform nil)))

(defclass state-machine-run ()
  ((id :reader id-of
       :initarg :id
       :initform nil)
   (title :reader title-of
          :initarg :title
          :initform nil)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (machine :reader state-machine-run-machine-of
            :initarg :machine)
   (input :reader state-machine-run-input-of
          :initarg :input
          :initform nil)
   (current-state :reader state-machine-run-current-state-of
                  :initarg :current-state
                  :initform nil)
   (visited-states :reader state-machine-run-visited-states-of
                   :initarg :visited-states
                   :initform nil)
   (transition-trace :reader state-machine-run-transition-trace-of
                     :initarg :transition-trace
                     :initform nil)
   (evidence-trace :reader state-machine-run-evidence-trace-of
                   :initarg :evidence-trace
                   :initform nil)
   (start-time :reader state-machine-run-start-time-of
               :initarg :start-time
               :initform nil)
   (end-time :reader state-machine-run-end-time-of
             :initarg :end-time
             :initform nil)
   (status :reader state-machine-run-status-of
           :initarg :status
           :initform :running)
   (failure-classification :reader state-machine-run-failure-classification-of
                           :initarg :failure-classification
                           :initform nil)
   (notes :reader state-machine-run-notes-of
          :initarg :notes
          :initform nil)))

(defun make-state-machine-state
    (&key id title summary role entry-condition exit-condition notes)
  (make-instance 'state-machine-state
                 :id id
                 :title title
                 :summary summary
                 :role role
                 :entry-condition entry-condition
                 :exit-condition exit-condition
                 :notes notes))

(defun make-state-machine-transition
    (&key id title from-state to-state trigger guard emitted-evidence
       side-effects reversible-p notes)
  (make-instance 'state-machine-transition
                 :id id
                 :title title
                 :from-state from-state
                 :to-state to-state
                 :trigger trigger
                 :guard guard
                 :emitted-evidence emitted-evidence
                 :side-effects side-effects
                 :reversible-p reversible-p
                 :notes notes))

(defun make-state-machine-definition
    (&key id title summary states transitions initial-state terminal-states
       guards events invariants failure-states source-evidence notes
       multi-initial-p multi-current-p allow-terminal-outgoing-p acyclic-p)
  (make-instance 'state-machine-definition
                 :id id
                 :title title
                 :summary summary
                 :states states
                 :transitions transitions
                 :initial-state initial-state
                 :terminal-states terminal-states
                 :guards guards
                 :events events
                 :invariants invariants
                 :failure-states failure-states
                 :source-evidence source-evidence
                 :notes notes
                 :multi-initial-p multi-initial-p
                 :multi-current-p multi-current-p
                 :allow-terminal-outgoing-p allow-terminal-outgoing-p
                 :acyclic-p acyclic-p))

(defun make-state-machine-run
    (&key id title summary machine input current-state visited-states
       transition-trace evidence-trace start-time end-time status
       failure-classification notes)
  (make-instance 'state-machine-run
                 :id id
                 :title title
                 :summary summary
                 :machine machine
                 :input input
                 :current-state current-state
                 :visited-states visited-states
                 :transition-trace transition-trace
                 :evidence-trace evidence-trace
                 :start-time start-time
                 :end-time end-time
                 :status status
                 :failure-classification failure-classification
                 :notes notes))

(defmethod print-object ((object state-machine-state) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object state-machine-transition) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A -> ~A"
            (state-machine-transition-from-state-of object)
            (state-machine-transition-to-state-of object))))

(defmethod print-object ((object state-machine-definition) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object state-machine-run) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (or (title-of object)
                            (title-of (state-machine-run-machine-of object))))))

(defun state-machine-known-state-ids (machine)
  (mapcar #'id-of (state-machine-definition-states-of machine)))

(defun state-machine-known-state-p (machine state-id)
  (member state-id
          (state-machine-known-state-ids machine)
          :test #'equal))

(defun state-machine-find-state (machine state-id)
  (find state-id
        (state-machine-definition-states-of machine)
        :key #'id-of
        :test #'equal))

(defun state-machine-transition-label (transition)
  (or (title-of transition)
      (format nil "~A -> ~A"
              (state-machine-transition-from-state-of transition)
              (state-machine-transition-to-state-of transition))))

(defun state-machine-dot-escape (string)
  (with-output-to-string (stream)
    (loop for char across (or string "")
          do (case char
               (#\\ (write-string "\\\\" stream))
               (#\" (write-string "\\\"" stream))
               (#\Newline (write-string "\\n" stream))
               (otherwise (write-char char stream))))))

(defun state-machine-dot-quoted (string)
  (format nil "\"~A\"" (state-machine-dot-escape string)))

(defun state-machine-dot-role-label (role)
  (string-capitalize
   (cond
     ((null role) "state")
     ((keywordp role) (string-downcase (string role)))
     ((symbolp role) (string-downcase (string role)))
     (t (format nil "~A" role)))))

(defun state-machine-definition-dot-state-shape (machine state-id)
  (cond
    ((member state-id
             (state-machine-definition-failure-states-of machine)
             :test #'equal)
     "octagon")
    ((member state-id
             (state-machine-definition-terminal-states-of machine)
             :test #'equal)
     "doublecircle")
    (t
     "ellipse")))

(defun state-machine-definition-dot-state-label (machine state)
  (let* ((role (state-machine-state-role machine state))
         (role-label (unless (eq role :intermediate)
                       (state-machine-dot-role-label role))))
    (format nil "~A~@[\\n(~A)~]"
            (or (title-of state)
                (id-of state))
            role-label)))

(defun state-machine-transition-dot-label (transition)
  (let* ((trigger (state-machine-transition-trigger-of transition))
         (guard (state-machine-transition-guard-of transition))
         (parts
          (remove nil
                  (list (and trigger (format nil "~A" trigger))
                        (and guard (format nil "~A" guard))))))
    (cond
      (parts
       (format nil "~{~A~^ / ~}" parts))
      ((title-of transition)
       (title-of transition))
      (t
       nil))))

(defun state-machine-state-role (machine state)
  (let ((state-id (if (typep state 'state-machine-state)
                      (id-of state)
                      state)))
    (cond
      ((equal state-id (state-machine-definition-initial-state-of machine))
       :initial)
      ((member state-id
               (state-machine-definition-failure-states-of machine)
               :test #'equal)
       :failure)
      ((member state-id
               (state-machine-definition-terminal-states-of machine)
               :test #'equal)
       :terminal)
      (t
       (let ((instance (state-machine-find-state machine state-id)))
         (if instance
             (state-machine-state-role-of instance)
             :intermediate))))))

(defun state-machine-transitions-from-state (machine state-id)
  (remove-if-not (lambda (transition)
                   (equal (state-machine-transition-from-state-of transition)
                          state-id))
                 (state-machine-definition-transitions-of machine)))

(defun state-machine-definition-dot-text (machine &key (rankdir "LR"))
  (with-output-to-string (stream)
    (format stream "digraph ~A {~%"
            (state-machine-dot-quoted
             (or (id-of machine)
                 (title-of machine)
                 "StateMachine")))
    (format stream "  rankdir=~A;~%" rankdir)
    (format stream "  node [fontname=\"Helvetica\"];~%")
    (format stream "  edge [fontname=\"Helvetica\"];~%")
    (when (state-machine-definition-initial-state-of machine)
      (format stream "  __start__ [label=\"\", shape=point];~%"))
    (dolist (state (state-machine-definition-states-of machine))
      (let* ((state-id (id-of state))
             (attributes
              (list
               (format nil "label=~A"
                       (state-machine-dot-quoted
                        (state-machine-definition-dot-state-label
                         machine
                         state)))
               (format nil "shape=~A"
                       (state-machine-definition-dot-state-shape
                        machine
                        state-id)))))
        (when (equal state-id
                     (state-machine-definition-initial-state-of machine))
          (push "style=bold" attributes))
        (when (member state-id
                      (state-machine-definition-failure-states-of machine)
                      :test #'equal)
          (push "color=\"firebrick\"" attributes))
        (format stream "  ~A [~{~A~^, ~}];~%"
                (state-machine-dot-quoted state-id)
                (nreverse attributes))))
    (when (state-machine-definition-initial-state-of machine)
      (format stream "  __start__ -> ~A;~%"
              (state-machine-dot-quoted
               (state-machine-definition-initial-state-of machine))))
    (when (or (state-machine-definition-states-of machine)
              (state-machine-definition-transitions-of machine))
      (terpri stream))
    (dolist (transition (state-machine-definition-transitions-of machine))
      (format stream "  ~A -> ~A"
              (state-machine-dot-quoted
               (state-machine-transition-from-state-of transition))
              (state-machine-dot-quoted
               (state-machine-transition-to-state-of transition)))
      (let ((attributes '()))
        (when-let (label (state-machine-transition-dot-label transition))
          (push (format nil "label=~A" (state-machine-dot-quoted label))
                attributes))
        (when (state-machine-transition-reversible-p-of transition)
          (push "style=dashed" attributes))
        (when attributes
          (format stream " [~{~A~^, ~}]" (nreverse attributes))))
      (format stream ";~%"))
    (format stream "}~%")))

(defun state-machine-known-guard-p (machine guard)
  (or (null guard)
      (member guard
              (state-machine-definition-guards-of machine)
              :test #'equal)))

(defun state-machine-known-event-p (machine event)
  (or (null event)
      (member event
              (state-machine-definition-events-of machine)
              :test #'equal)))

(defun state-machine-definition-findings (machine)
  (let* ((states (state-machine-definition-states-of machine))
         (state-ids (state-machine-known-state-ids machine))
         (transitions (state-machine-definition-transitions-of machine))
         (initial-state (state-machine-definition-initial-state-of machine))
         (terminal-states (state-machine-definition-terminal-states-of machine))
         (failure-states (state-machine-definition-failure-states-of machine))
         (findings '()))
    (labels ((note-finding (label status detail)
               (push (list :label label :status status :detail detail)
                     findings)))
      (if (and initial-state
               (member initial-state state-ids :test #'equal))
          (note-finding "Initial state"
                        :ok
                        (format nil "Initial state ~A is declared and known."
                                initial-state))
          (note-finding "Initial state"
                        :error
                        (format nil
                                "Initial state ~A is missing from the known state set."
                                initial-state)))
      (if (state-machine-definition-multi-initial-p-of machine)
          (note-finding "Multi-initial"
                        :ok
                        "Machine explicitly allows more than one initial branch.")
          (note-finding "Multi-initial"
                        :ok
                        "Machine expects exactly one initial state."))
      (dolist (state-id terminal-states)
        (unless (member state-id state-ids :test #'equal)
          (note-finding "Terminal state declaration"
                        :error
                        (format nil "Terminal state ~A is not a known state."
                                state-id))))
      (dolist (state-id failure-states)
        (unless (member state-id state-ids :test #'equal)
          (note-finding "Failure state declaration"
                        :error
                        (format nil "Failure state ~A is not a known state."
                                state-id))))
      (dolist (transition transitions)
        (unless (member (state-machine-transition-from-state-of transition)
                        state-ids
                        :test #'equal)
          (note-finding "Transition source"
                        :error
                        (format nil "Transition ~A starts from unknown state ~A."
                                (state-machine-transition-label transition)
                                (state-machine-transition-from-state-of transition))))
        (unless (member (state-machine-transition-to-state-of transition)
                        state-ids
                        :test #'equal)
          (note-finding "Transition destination"
                        :error
                        (format nil "Transition ~A points to unknown state ~A."
                                (state-machine-transition-label transition)
                                (state-machine-transition-to-state-of transition))))
        (unless (state-machine-known-guard-p machine
                                             (state-machine-transition-guard-of transition))
          (note-finding "Transition guard"
                        :error
                        (format nil "Transition ~A references unknown guard ~A."
                                (state-machine-transition-label transition)
                                (state-machine-transition-guard-of transition))))
        (unless (state-machine-known-event-p machine
                                             (state-machine-transition-trigger-of transition))
          (note-finding "Transition event"
                        :error
                        (format nil "Transition ~A references unknown event ~A."
                                (state-machine-transition-label transition)
                                (state-machine-transition-trigger-of transition)))))
      (unless (state-machine-definition-allow-terminal-outgoing-p-of machine)
        (dolist (state-id terminal-states)
          (when (state-machine-transitions-from-state machine state-id)
            (note-finding "Terminal outgoing transition"
                          :error
                          (format nil
                                  "Terminal state ~A has outgoing transitions but the machine does not allow that."
                                  state-id)))))
      (unless findings
        (note-finding "Invariant check"
                      :ok
                      "No structural findings."))
      (nreverse findings))))

(defun state-machine-run-findings (run)
  (let* ((machine (state-machine-run-machine-of run))
         (findings '()))
    (labels ((note-finding (label status detail)
               (push (list :label label :status status :detail detail)
                     findings)))
      (unless (typep machine 'state-machine-definition)
        (note-finding "Machine binding"
                      :error
                      "Run does not point to a state-machine-definition."))
      (when (and machine
                 (state-machine-run-current-state-of run)
                 (not (state-machine-known-state-p
                       machine
                       (state-machine-run-current-state-of run))))
        (note-finding "Current state"
                      :error
                      (format nil "Current state ~A is unknown to the machine."
                              (state-machine-run-current-state-of run))))
      (dolist (state-id (state-machine-run-visited-states-of run))
        (unless (state-machine-known-state-p machine state-id)
          (note-finding "Visited state"
                        :error
                        (format nil "Visited state ~A is unknown to the machine."
                                state-id))))
      (dolist (step (state-machine-run-transition-trace-of run))
        (let ((from-state (getf step :from-state))
              (to-state (getf step :to-state)))
          (when (and from-state
                     (not (state-machine-known-state-p machine from-state)))
            (note-finding "Trace source"
                          :error
                          (format nil "Transition trace references unknown source ~A."
                                  from-state)))
          (when (and to-state
                     (not (state-machine-known-state-p machine to-state)))
            (note-finding "Trace destination"
                          :error
                          (format nil "Transition trace references unknown destination ~A."
                                  to-state)))))
      (unless findings
        (note-finding "Run structure"
                      :ok
                      "Run aligns with the declared machine."))
      (nreverse findings))))

(defun example-state-machine-source-evidence ()
  (list
   (list :layer "HyperDoc page"
         :reference "Operational definition: state machine, state, transition, guard, run trace"
         :detail "Durable definition of the reusable machine/run split.")
   (list :layer "HyperDoc topic"
         :reference "State machine"
         :detail "Stable semantic anchor for the generic abstraction.")
   (list :layer "Lisp source"
         :reference "hyperdoc/state-machines.lisp"
         :detail "Runtime definition objects and run objects.")
   (list :layer "Test"
         :reference "tests/state-machine-smoke.lisp"
         :detail "Smoke coverage for the generic definition/run objects.")))

(defun make-example-state-machine-definition ()
  (make-state-machine-definition
   :id "state-machine-definition/example"
   :title "Example evidence-bearing state machine"
   :summary
   "Small generic example machine that keeps definition, guards, failure branches, and evidence trace distinct from any one DMX-specific use case."
   :states
   (list
    (make-state-machine-state
     :id "captured"
     :title "Captured"
     :summary "Input has been captured and can be checked."
     :entry-condition "Input bundle present"
     :exit-condition "Validation step begins")
    (make-state-machine-state
     :id "validated"
     :title "Validated"
     :summary "Required support conditions are satisfied."
     :entry-condition "Support condition proved"
     :exit-condition "Commit step begins")
    (make-state-machine-state
     :id "committed"
     :title "Committed"
     :summary "Result is terminal and durable."
     :entry-condition "Commit event accepted"
     :notes "Terminal success state.")
    (make-state-machine-state
     :id "rejected"
     :title "Rejected"
     :summary "The run stopped at an explicit failure branch."
     :entry-condition "Guard failed"
     :notes "Failure state."))
   :transitions
   (list
    (make-state-machine-transition
     :id "capture->validate"
     :from-state "captured"
     :to-state "validated"
     :trigger "validate"
     :guard "support-available"
     :emitted-evidence "validation-report"
     :side-effects "none"
     :reversible-p nil)
    (make-state-machine-transition
     :id "validate->commit"
     :from-state "validated"
     :to-state "committed"
     :trigger "commit"
     :guard "invariants-hold"
     :emitted-evidence "commit-record"
     :side-effects "durable artifact written"
     :reversible-p nil)
    (make-state-machine-transition
     :id "validate->reject"
     :from-state "validated"
     :to-state "rejected"
     :trigger "reject"
     :guard "support-missing"
     :emitted-evidence "failure-report"
     :side-effects "no durable write"
     :reversible-p nil))
   :initial-state "captured"
   :terminal-states '("committed")
   :guards '("support-available" "invariants-hold" "support-missing")
   :events '("validate" "commit" "reject")
   :invariants
   (list
    (list :label "Single current state"
          :detail "Exactly one current state is permitted in ordinary runs.")
    (list :label "Known-state transitions"
          :detail "Every transition must reference known states.")
    (list :label "Terminal stop"
          :detail "Terminal states have no outgoing transitions."))
   :failure-states '("rejected")
   :source-evidence (example-state-machine-source-evidence)
   :notes
   (list
    (list :label "Generic example"
          :detail "This machine is intentionally small so the generic views are inspectable immediately."))
   :multi-initial-p nil
   :multi-current-p nil
   :allow-terminal-outgoing-p nil
   :acyclic-p t))

(defun make-example-state-machine-run ()
  (let ((machine (make-example-state-machine-definition)))
    (make-state-machine-run
     :id "state-machine-run/example"
     :title "Example state-machine run"
     :summary
     "Concrete successful run of the generic example state machine."
     :machine machine
     :input (list (cons "input-id" "example-42")
                  (cons "support-bundle" "present"))
     :current-state "committed"
     :visited-states '("captured" "validated" "committed")
     :transition-trace
     (list
      (list :timestamp 1
            :kind :transition
            :transition-id "capture->validate"
            :from-state "captured"
            :to-state "validated"
            :trigger "validate"
            :guard "support-available")
      (list :timestamp 2
            :kind :transition
            :transition-id "validate->commit"
            :from-state "validated"
            :to-state "committed"
            :trigger "commit"
            :guard "invariants-hold")
      (list :timestamp 3
            :kind :skipped-branch
            :transition-id "validate->reject"
            :from-state "validated"
            :to-state "rejected"
            :detail "Failure branch was not taken because support remained available."))
     :evidence-trace
     (list
      (list :timestamp 0
            :kind :state-entry
            :state-id "captured"
            :evidence "Input bundle recorded.")
      (list :timestamp 1
            :kind :transition
            :transition-id "capture->validate"
            :evidence "Validation report emitted.")
      (list :timestamp 2
            :kind :transition
            :transition-id "validate->commit"
            :evidence "Commit record persisted."))
     :start-time 0
     :end-time 2
     :status :success
     :failure-classification nil
     :notes
     (list
      (list :label "Example run"
            :detail "Successful trace for the generic example machine.")))))
