(in-package #:dreyeck/state-machine)

(defclass state-machine-state nil
          ((id :reader id-of :initarg :id)
           (title :reader title-of :initarg :title)
           (summary :reader summary-of :initarg :summary :initform nil)
           (role :reader state-machine-state-role-of :initarg :role :initform
            :intermediate)
           (entry-condition :reader state-machine-state-entry-condition-of
            :initarg :entry-condition :initform nil)
           (exit-condition :reader state-machine-state-exit-condition-of
            :initarg :exit-condition :initform nil)
           (notes :reader state-machine-state-notes-of :initarg :notes
            :initform nil)))

(defclass state-machine-transition nil
          ((id :reader id-of :initarg :id)
           (title :reader title-of :initarg :title :initform nil)
           (from-state :reader state-machine-transition-from-state-of :initarg
            :from-state)
           (to-state :reader state-machine-transition-to-state-of :initarg
            :to-state)
           (trigger :reader state-machine-transition-trigger-of :initarg
            :trigger :initform nil)
           (guard :reader state-machine-transition-guard-of :initarg :guard
            :initform nil)
           (emitted-evidence :reader
            state-machine-transition-emitted-evidence-of :initarg
            :emitted-evidence :initform nil)
           (side-effects :reader state-machine-transition-side-effects-of
            :initarg :side-effects :initform nil)
           (reversible-p :reader state-machine-transition-reversible-p-of
            :initarg :reversible-p :initform nil)
           (notes :reader state-machine-transition-notes-of :initarg :notes
            :initform nil)))

(defclass state-machine-definition nil
          ((id :reader id-of :initarg :id)
           (title :reader title-of :initarg :title)
           (summary :reader summary-of :initarg :summary :initform nil)
           (states :reader state-machine-definition-states-of :initarg :states
            :initform nil)
           (transitions :reader state-machine-definition-transitions-of
            :initarg :transitions :initform nil)
           (initial-state :reader state-machine-definition-initial-state-of
            :initarg :initial-state)
           (terminal-states :reader state-machine-definition-terminal-states-of
            :initarg :terminal-states :initform nil)
           (guards :reader state-machine-definition-guards-of :initarg :guards
            :initform nil)
           (events :reader state-machine-definition-events-of :initarg :events
            :initform nil)
           (invariants :reader state-machine-definition-invariants-of :initarg
            :invariants :initform nil)
           (failure-states :reader state-machine-definition-failure-states-of
            :initarg :failure-states :initform nil)
           (source-evidence :reader state-machine-definition-source-evidence-of
            :initarg :source-evidence :initform nil)
           (notes :reader state-machine-definition-notes-of :initarg :notes
            :initform nil)
           (multi-initial-p :reader state-machine-definition-multi-initial-p-of
            :initarg :multi-initial-p :initform nil)
           (multi-current-p :reader state-machine-definition-multi-current-p-of
            :initarg :multi-current-p :initform nil)
           (allow-terminal-outgoing-p :reader
            state-machine-definition-allow-terminal-outgoing-p-of :initarg
            :allow-terminal-outgoing-p :initform nil)
           (acyclic-p :reader state-machine-definition-acyclic-p-of :initarg
            :acyclic-p :initform nil)))

(defclass state-machine-run nil
          ((id :reader id-of :initarg :id :initform nil)
           (title :reader title-of :initarg :title :initform nil)
           (summary :reader summary-of :initarg :summary :initform nil)
           (machine :reader state-machine-run-machine-of :initarg :machine)
           (input :reader state-machine-run-input-of :initarg :input :initform
            nil)
           (current-state :reader state-machine-run-current-state-of :initarg
            :current-state :initform nil)
           (visited-states :reader state-machine-run-visited-states-of :initarg
            :visited-states :initform nil)
           (transition-trace :reader state-machine-run-transition-trace-of
            :initarg :transition-trace :initform nil)
           (evidence-trace :reader state-machine-run-evidence-trace-of :initarg
            :evidence-trace :initform nil)
           (start-time :reader state-machine-run-start-time-of :initarg
            :start-time :initform nil)
           (end-time :reader state-machine-run-end-time-of :initarg :end-time
            :initform nil)
           (status :reader state-machine-run-status-of :initarg :status
            :initform :running)
           (failure-classification :reader
            state-machine-run-failure-classification-of :initarg
            :failure-classification :initform nil)
           (notes :reader state-machine-run-notes-of :initarg :notes :initform
            nil)))

(defun make-state-machine-state
       (&key id title summary role entry-condition exit-condition notes)
  (make-instance 'state-machine-state :id id :title title :summary summary
                 :role role :entry-condition entry-condition :exit-condition
                 exit-condition :notes notes))

(defun make-state-machine-transition
       (
        &key id title from-state to-state trigger guard emitted-evidence
        side-effects reversible-p notes)
  (make-instance 'state-machine-transition :id id :title title :from-state
                 from-state :to-state to-state :trigger trigger :guard guard
                 :emitted-evidence emitted-evidence :side-effects side-effects
                 :reversible-p reversible-p :notes notes))

(defun make-state-machine-definition
       (
        &key id title summary states transitions initial-state terminal-states
        guards events invariants failure-states source-evidence notes
        multi-initial-p multi-current-p allow-terminal-outgoing-p acyclic-p)
  (make-instance 'state-machine-definition :id id :title title :summary summary
                 :states states :transitions transitions :initial-state
                 initial-state :terminal-states terminal-states :guards guards
                 :events events :invariants invariants :failure-states
                 failure-states :source-evidence source-evidence :notes notes
                 :multi-initial-p multi-initial-p :multi-current-p
                 multi-current-p :allow-terminal-outgoing-p
                 allow-terminal-outgoing-p :acyclic-p acyclic-p))

(defun make-state-machine-run
       (
        &key id title summary machine input current-state visited-states
        transition-trace evidence-trace start-time end-time status
        failure-classification notes)
  (make-instance 'state-machine-run :id id :title title :summary summary
                 :machine machine :input input :current-state current-state
                 :visited-states visited-states :transition-trace
                 transition-trace :evidence-trace evidence-trace :start-time
                 start-time :end-time end-time :status status
                 :failure-classification failure-classification :notes notes))

(defmethod print-object ((object state-machine-state) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object state-machine-transition) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A -> ~A" (state-machine-transition-from-state-of object)
            (state-machine-transition-to-state-of object))))

(defmethod print-object ((object state-machine-definition) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object state-machine-run) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A"
            (or (title-of object)
                (title-of (state-machine-run-machine-of object))))))

(defun state-machine-known-state-ids (machine)
  (mapcar #'id-of (state-machine-definition-states-of machine)))

(defun state-machine-known-state-p (machine state-id)
  (member state-id (state-machine-known-state-ids machine) :test #'equal))

(defun state-machine-find-state (machine state-id)
  (find state-id (state-machine-definition-states-of machine) :key #'id-of
        :test #'equal))

(defun state-machine-transition-label (transition)
  (or (title-of transition)
      (format nil "~A -> ~A"
              (state-machine-transition-from-state-of transition)
              (state-machine-transition-to-state-of transition))))

(defun state-machine-state-role (machine state)
  (let ((state-id
         (if (typep state 'state-machine-state)
             (id-of state)
             state)))
    (cond
     ((equal state-id (state-machine-definition-initial-state-of machine))
      :initial)
     ((member state-id (state-machine-definition-failure-states-of machine)
              :test #'equal)
      :failure)
     ((member state-id (state-machine-definition-terminal-states-of machine)
              :test #'equal)
      :terminal)
     (t
      (let ((instance (state-machine-find-state machine state-id)))
        (if instance
            (state-machine-state-role-of instance)
            :intermediate))))))

(defun state-machine-transitions-from-state (machine state-id)
  (remove-if-not
   (lambda (transition)
     (equal (state-machine-transition-from-state-of transition) state-id))
   (state-machine-definition-transitions-of machine)))

(defun state-machine-known-guard-p (machine guard)
  (or (null guard)
      (member guard (state-machine-definition-guards-of machine) :test
              #'equal)))

(defun state-machine-known-event-p (machine event)
  (or (null event)
      (member event (state-machine-definition-events-of machine) :test
              #'equal)))

(defun state-machine-definition-findings (machine)
  (let* ((state-ids (state-machine-known-state-ids machine))
         (transitions (state-machine-definition-transitions-of machine))
         (initial-state (state-machine-definition-initial-state-of machine))
         (terminal-states
          (state-machine-definition-terminal-states-of machine))
         (failure-states (state-machine-definition-failure-states-of machine))
         (findings 'nil))
    (labels ((note-finding (label status detail)
               (push (list :label label :status status :detail detail)
                     findings)))
      (if (and initial-state (member initial-state state-ids :test #'equal))
          (note-finding "Initial state" :ok
           (format nil "Initial state ~A is declared and known."
                   initial-state))
          (note-finding "Initial state" :error
           (format nil "Initial state ~A is missing from the known state set."
                   initial-state)))
      (if (state-machine-definition-multi-initial-p-of machine)
          (note-finding "Multi-initial" :ok
           "Machine explicitly allows more than one initial branch.")
          (note-finding "Multi-initial" :ok
           "Machine expects exactly one initial state."))
      (dolist (state-id terminal-states)
        (unless (member state-id state-ids :test #'equal)
          (note-finding "Terminal state declaration" :error
           (format nil "Terminal state ~A is not a known state." state-id))))
      (dolist (state-id failure-states)
        (unless (member state-id state-ids :test #'equal)
          (note-finding "Failure state declaration" :error
           (format nil "Failure state ~A is not a known state." state-id))))
      (dolist (transition transitions)
        (unless
            (member (state-machine-transition-from-state-of transition)
                    state-ids :test #'equal)
          (note-finding "Transition source" :error
           (format nil "Transition ~A starts from unknown state ~A."
                   (state-machine-transition-label transition)
                   (state-machine-transition-from-state-of transition))))
        (unless
            (member (state-machine-transition-to-state-of transition) state-ids
                    :test #'equal)
          (note-finding "Transition destination" :error
           (format nil "Transition ~A points to unknown state ~A."
                   (state-machine-transition-label transition)
                   (state-machine-transition-to-state-of transition))))
        (unless
            (state-machine-known-guard-p machine
                                         (state-machine-transition-guard-of
                                          transition))
          (note-finding "Transition guard" :error
           (format nil "Transition ~A references unknown guard ~A."
                   (state-machine-transition-label transition)
                   (state-machine-transition-guard-of transition))))
        (unless
            (state-machine-known-event-p machine
                                         (state-machine-transition-trigger-of
                                          transition))
          (note-finding "Transition event" :error
           (format nil "Transition ~A references unknown event ~A."
                   (state-machine-transition-label transition)
                   (state-machine-transition-trigger-of transition)))))
      (unless (state-machine-definition-allow-terminal-outgoing-p-of machine)
        (dolist (state-id terminal-states)
          (when (state-machine-transitions-from-state machine state-id)
            (note-finding "Terminal outgoing transition" :error
             (format nil
                     "Terminal state ~A has outgoing transitions but the machine does not allow that."
                     state-id)))))
      (unless findings
        (note-finding "Invariant check" :ok "No structural findings."))
      (nreverse findings))))

(defun state-machine-run-findings (run)
  (let* ((machine (state-machine-run-machine-of run)) (findings 'nil))
    (labels ((note-finding (label status detail)
               (push (list :label label :status status :detail detail)
                     findings)))
      (unless (typep machine 'state-machine-definition)
        (note-finding "Machine binding" :error
         "Run does not point to a state-machine-definition."))
      (when
          (and machine (state-machine-run-current-state-of run)
               (not
                (state-machine-known-state-p machine
                                             (state-machine-run-current-state-of
                                              run))))
        (note-finding "Current state" :error
         (format nil "Current state ~A is unknown to the machine."
                 (state-machine-run-current-state-of run))))
      (dolist (state-id (state-machine-run-visited-states-of run))
        (unless (state-machine-known-state-p machine state-id)
          (note-finding "Visited state" :error
           (format nil "Visited state ~A is unknown to the machine."
                   state-id))))
      (dolist (step (state-machine-run-transition-trace-of run))
        (let ((from-state (getf step :from-state))
              (to-state (getf step :to-state)))
          (when
              (and from-state
                   (not (state-machine-known-state-p machine from-state)))
            (note-finding "Trace source" :error
             (format nil "Transition trace references unknown source ~A."
                     from-state)))
          (when
              (and to-state
                   (not (state-machine-known-state-p machine to-state)))
            (note-finding "Trace destination" :error
             (format nil "Transition trace references unknown destination ~A."
                     to-state)))))
      (unless findings
        (note-finding "Run structure" :ok
         "Run aligns with the declared machine."))
      (nreverse findings))))
