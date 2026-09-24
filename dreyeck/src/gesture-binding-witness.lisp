;;;; A transient Gesture/Binding recognizer that stops at operation identity.
(defpackage #:dreyeck/gesture-binding-witness
  (:use #:cl)
  (:local-nicknames (#:sm #:dreyeck/state-machine) (#:tm #:dreyeck/topicmap))
  (:export #:semantic-operation-identity
           #:semantic-operation-identity-id
           #:semantic-operation-identity-title
           #:insert-executable-defexample-operation
           #:gesture-input-sample
           #:make-gesture-input-sample
           #:gesture-input-sample-kind
           #:gesture-input-sample-target
           #:gesture-input-sample-x
           #:gesture-input-sample-y
           #:gesture-input-sample-button
           #:gesture-input-sample-modifiers
           #:gesture-input-sample-timestamp
           #:gesture-binding
           #:gesture-binding-id
           #:gesture-binding-kind
           #:gesture-binding-sector-center
           #:gesture-binding-sector-half-width
           #:gesture-binding-target-type
           #:gesture-binding-enabled-p
           #:gesture-binding-operation
           #:make-gesture-binding-catalog
           #:gesture-session
           #:gesture-session-binding-catalog-of
           #:gesture-session-mode-of
           #:gesture-session-selected-binding-of
           #:gesture-session-selected-operation-of
           #:gesture-session-cancellation-reason-of
           #:gesture-session-menu-visible-p-of
           #:gesture-session-observations-of
           #:make-gesture-state-machine-definition
           #:run-gesture-trace
           #:make-expert-marking-trace
           #:make-novice-visible-menu-trace))

(in-package #:dreyeck/gesture-binding-witness)

;;; Operation identity
;;;
;;; The identity is data. It holds no executor and is not FUNCALLable, so
;;; this witness cannot run the operation it selects even by accident.
;;; That is a structural property of the object, not a measurement: there
;;; is no execution seam in this repository that could be watched, and
;;; inventing one in order to observe its silence would be the same
;;; mistake as asserting a constructor-time NIL.

(defstruct (semantic-operation-identity
            (:constructor %make-operation-identity (id title)))
  "An opaque semantic operation identity, deliberately without an executor."
  id
  title)

(defvar *insert-executable-defexample-operation*
  (%make-operation-identity "operation/insert-executable-defexample"
                            "Insert executable DEFEXAMPLE")
  "The EQ operation identity shared by the alternative Bindings.")

(defun insert-executable-defexample-operation ()
  *insert-executable-defexample-operation*)

;;; Transient input

(defstruct (gesture-input-sample
            (:constructor make-gesture-input-sample
                (&key kind target x y button modifiers timestamp)))
  "A synthetic transient input sample, not semantic-operation evidence."
  kind
  target
  x
  y
  button
  modifiers
  timestamp)

(defstruct (gesture-binding
            (:constructor %make-gesture-binding
                (&key id kind sector-center sector-half-width target-type
                      enabled-p operation)))
  "An experiment-local target/criterion mapping to an opaque operation."
  id
  kind
  sector-center
  sector-half-width
  target-type
  enabled-p
  operation)

(defun make-gesture-binding-catalog ()
  "Three alternative Bindings for one operation, and one disabled sector.
The disabled sector shows that a Binding can be present and not
selectable. There is deliberately no disabled learned-mark Binding: no
observation asks for one."
  (let ((operation (insert-executable-defexample-operation)))
    (list
     (%make-gesture-binding :id "binding/radial-insert-defexample"
                            :kind :radial-menu :sector-center 0.0d0
                            :sector-half-width 30.0d0
                            :target-type :lisp-source-definition
                            :enabled-p t :operation operation)
     (%make-gesture-binding :id "binding/mark-insert-defexample"
                            :kind :learned-mark :sector-center 0.0d0
                            :sector-half-width 30.0d0
                            :target-type :lisp-source-definition
                            :enabled-p t :operation operation)
     (%make-gesture-binding :id "binding/inspector-insert-defexample"
                            :kind :inspector-action
                            :target-type :lisp-source-definition
                            :enabled-p t :operation operation)
     (%make-gesture-binding :id "binding/radial-disabled-sector"
                            :kind :radial-menu :sector-center 180.0d0
                            :sector-half-width 30.0d0
                            :target-type :lisp-source-definition
                            :enabled-p nil :operation operation))))

;;; The run

(defclass gesture-session (sm:state-machine-run)
  ((binding-catalog :initarg :binding-catalog
                    :reader gesture-session-binding-catalog-of)
   (mode :initarg :mode :initform nil :reader gesture-session-mode-of)
   (selected-binding :initarg :selected-binding :initform nil
                     :reader gesture-session-selected-binding-of)
   (selected-operation :initarg :selected-operation :initform nil
                       :reader gesture-session-selected-operation-of)
   (cancellation-reason :initarg :cancellation-reason :initform nil
                        :reader gesture-session-cancellation-reason-of)
   (menu-visible-p :initarg :menu-visible-p :initform nil
                   :reader gesture-session-menu-visible-p-of)
   (observations :initarg :observations :initform nil
                 :reader gesture-session-observations-of))
  (:documentation
   "A transient gesture run that stops after Binding selection.
OBSERVATIONS records the samples that were consumed without causing a
transition, so that no input is dropped in silence."))

(defmethod print-object ((session gesture-session) stream)
  (print-unreadable-object (session stream :type t)
    (format stream "~A / ~A / ~A"
            (sm:state-machine-run-current-state-of session)
            (or (gesture-session-mode-of session) :no-mode)
            (let ((binding (gesture-session-selected-binding-of session)))
              (if binding
                  (gesture-binding-id binding)
                  :no-binding)))))

;;; The definition

(defun %state (id title role)
  (sm:make-state-machine-state :id id :title title :role role))

(defun %transition (id from to trigger guard)
  (sm:make-state-machine-transition :id id :from-state from :to-state to
                                    :trigger trigger :guard guard
                                    :emitted-evidence
                                    :transient-gesture-observation
                                    :side-effects :transient-session-only
                                    :reversible-p nil))

(defun make-gesture-state-machine-definition ()
  (sm:make-state-machine-definition
   :id "state-machine/gesture-binding-witness"
   :title "Gesture/Binding marking-menu witness"
   :summary "A transient protocol ending at an opaque operation identity."
   :states (list (%state :idle "Idle" :initial)
                 (%state :pressed "Pressed" :intermediate)
                 (%state :marking "Hidden marking mode" :intermediate)
                 (%state :menu-visible "Visible menu mode" :intermediate)
                 (%state :sector-selected "Enabled sector selected"
                         :intermediate)
                 (%state :completed "Binding selection completed" :terminal)
                 (%state :cancelled "Gesture cancelled" :failure))
   :transitions
   (list
    (%transition :idle->pressed :idle :pressed
                 :pointer-down :secondary-button-on-a-target)
    (%transition :idle->cancelled :idle :cancelled
                 :pointer-down :no-target-or-wrong-button)
    ;; Being in PRESSED means the reveal deadline has not been delivered,
    ;; so this guard states a fact about the order of events rather than a
    ;; comparison of timestamps.
    (%transition :pressed->marking :pressed :marking
                 :pointer-move :dead-zone-crossed-before-deadline)
    (%transition :pressed->menu-visible :pressed :menu-visible
                 :reveal-deadline :reveal-deadline-delivered)
    (%transition :pressed->cancelled-on-cancel :pressed :cancelled
                 :pointer-cancel :cancelled-by-input)
    ;; Two releases out of PRESSED, because the recorded reason has to
    ;; follow the geometry that was actually observed.
    (%transition :pressed->cancelled-in-dead-zone :pressed :cancelled
                 :pointer-up :released-in-dead-zone)
    (%transition :pressed->cancelled-without-movement :pressed :cancelled
                 :pointer-up :released-without-recognized-movement)
    (%transition :marking->sector-selected :marking :sector-selected
                 :pointer-move :enabled-mark-sector)
    (%transition :marking->cancelled-on-cancel :marking :cancelled
                 :pointer-cancel :cancelled-by-input)
    (%transition :marking->cancelled-on-release :marking :cancelled
                 :pointer-up :no-active-enabled-sector)
    (%transition :menu-visible->sector-selected :menu-visible :sector-selected
                 :pointer-move :enabled-visible-sector)
    (%transition :menu-visible->cancelled-on-cancel :menu-visible :cancelled
                 :pointer-cancel :cancelled-by-input)
    (%transition :menu-visible->cancelled-on-release :menu-visible :cancelled
                 :pointer-up :no-active-enabled-sector)
    (%transition :sector-selected->completed :sector-selected :completed
                 :pointer-up :active-enabled-binding)
    (%transition :sector-selected->cancelled :sector-selected :cancelled
                 :pointer-cancel :cancelled-by-input)
    ;; Reselection before release. A marking menu allows it, so the model
    ;; represents it instead of refusing the input.
    (%transition :sector-selected->reselected :sector-selected :sector-selected
                 :pointer-move :enabled-sector-reselected)
    (%transition :sector-selected->marking :sector-selected :marking
                 :pointer-move :no-active-enabled-sector)
    (%transition :sector-selected->menu-visible :sector-selected :menu-visible
                 :pointer-move :no-active-enabled-sector))
   :initial-state :idle
   :terminal-states '(:completed :cancelled)
   :guards '(:secondary-button-on-a-target
             :no-target-or-wrong-button
             :dead-zone-crossed-before-deadline
             :reveal-deadline-delivered
             :cancelled-by-input
             :released-in-dead-zone
             :released-without-recognized-movement
             :enabled-mark-sector
             :no-active-enabled-sector
             :enabled-visible-sector
             :enabled-sector-reselected
             :active-enabled-binding)
   :events '(:pointer-down :pointer-move :pointer-up :pointer-cancel
             :reveal-deadline)
   :failure-states '(:cancelled)
   :source-evidence
   (list (list :layer :lisp-source :reference
               "dreyeck/src/gesture-binding-witness.lisp")
         (list :layer :test :reference
               "dreyeck/tests/gesture-binding-witness-smoke.lisp"))
   :notes
   (list (list :scope :experiment-local
               :detail "Not a generic event-driven executor.")
         ;; These read as invariants but nothing validates them, so they
         ;; are filed as documentation rather than as a checked property.
         (list :scope :documentation
               :detail
               "No transition executes an Operation or changes a Workspace.")
         (list :scope :documentation
               :detail
               "Completion records a Binding and an opaque operation identity.")
         (list :scope :documentation
               :detail "Terminal states have no outgoing transitions."))
   :multi-initial-p nil
   :multi-current-p nil
   :allow-terminal-outgoing-p nil
   ;; Reselection is a cycle. The declaration follows the model instead of
   ;; forbidding an interaction the model is supposed to represent.
   :acyclic-p nil))

;;; Geometry

(defun %transition-by-id (machine id)
  (or (find id (sm:state-machine-definition-transitions-of machine)
            :key #'sm:id-of)
      (error "Unknown witness transition ~S." id)))

(defun %distance (x y sample)
  (sqrt (+ (expt (- (gesture-input-sample-x sample) x) 2)
           (expt (- (gesture-input-sample-y sample) y) 2))))

(defun %angle (x y sample)
  (mod (+ (* 180.0d0
             (/ (atan (- (gesture-input-sample-y sample) y)
                      (- (gesture-input-sample-x sample) x))
                pi))
          360.0d0)
       360.0d0))

(defun %angular-distance (a b)
  (let ((distance (abs (- a b))))
    (min distance (- 360.0d0 distance))))

(defun %outside-dead-zone-p (x y sample dead-zone)
  "Exactly at the radius counts as inside. The boundary is a decision."
  (> (%distance x y sample) dead-zone))

(defun %binding-at (bindings kind target angle)
  (find-if (lambda (binding)
             (and (eq kind (gesture-binding-kind binding))
                  (eq (gesture-binding-target-type binding) (getf target :type))
                  (numberp (gesture-binding-sector-center binding))
                  (<= (%angular-distance angle
                                         (gesture-binding-sector-center binding))
                      (gesture-binding-sector-half-width binding))))
           bindings))

;;; The reducer

(defun run-gesture-trace (samples &key (bindings (make-gesture-binding-catalog))
                                       (dead-zone 5.0d0))
  "Reduce synthetic samples locally and stop at the selected identity.
The selected operation is data and not FUNCALLable, so this reducer has
no means of running it; no execution mechanism is part of this witness.
The session advances on the events it receives. A sample timestamp later
than the nominal deadline does not stand in for a REVEAL-DEADLINE event
that was never delivered."
  (let* ((machine (make-gesture-state-machine-definition))
         (state :idle)
         (visited (list :idle))
         (transitions nil)
         (evidence (list (list :kind :state-entry :state-id :idle
                               :scope :transient-gesture)))
         (observations nil)
         (consumed nil)
         (origin-x nil)
         (origin-y nil)
         (target nil)
         (mode nil)
         (selected-binding nil)
         (selected-operation nil)
         (cancellation-reason nil)
         (menu-visible-p nil))
    (labels
        ((take (id sample &optional detail)
           (let ((transition (%transition-by-id machine id)))
             (unless (eq state (sm:state-machine-transition-from-state-of
                                transition))
               (error "Transition ~S cannot leave ~S." id state))
             (push (list :timestamp (gesture-input-sample-timestamp sample)
                         :kind :transition :transition transition
                         :transition-id id :from-state state
                         :to-state (sm:state-machine-transition-to-state-of
                                    transition)
                         :trigger (gesture-input-sample-kind sample)
                         :detail detail)
                   transitions)
             (setf state (sm:state-machine-transition-to-state-of transition))
             (push state visited)
             (push (list :timestamp (gesture-input-sample-timestamp sample)
                         :kind :transient-gesture-transition :transition-id id
                         :state-id state :detail detail)
                   evidence)))
         (observe (sample reason &optional detail)
           ;; A consumed sample that caused no transition is still part of
           ;; the record. Nothing is dropped in silence.
           (let ((entry (list :timestamp (gesture-input-sample-timestamp sample)
                              :kind :observation-without-transition
                              :state-id state :reason reason :detail detail)))
             (push entry observations)
             (push entry evidence)))
         (cancel (id sample reason)
           (setf cancellation-reason reason
                 selected-binding nil
                 selected-operation nil)
           (take id sample reason))
         (active-kind ()
           (if (eq mode :marking) :learned-mark :radial-menu))
         (binding-under (sample)
           (%binding-at bindings (active-kind) target
                        (%angle origin-x origin-y sample)))
         (select-at (sample success)
           ;; A disabled Binding is not selectable. It is not terminal.
           (let ((binding (binding-under sample)))
             (cond ((null binding)
                    (observe sample :no-enabled-sector-at-angle)
                    nil)
                   ((not (gesture-binding-enabled-p binding))
                    (observe sample :disabled-sector-entered
                             (gesture-binding-id binding))
                    nil)
                   (t
                    (setf selected-binding binding
                          selected-operation
                          (gesture-binding-operation binding))
                    (take success sample
                          (list :angle (%angle origin-x origin-y sample)
                                :binding binding))
                    t))))
         (handle-deadline (sample)
           ;; The deadline is an observed delivered fact. It used to be
           ;; revalidated here against a Lisp clock, which asked the same
           ;; question twice and gave the second asker the worse evidence:
           ;; a consumer-assigned timestamp says when Lisp got round to
           ;; the event, not when the browser fired it.
           (if (eq state :pressed)
               (progn (setf mode :menu-visible
                            menu-visible-p t)
                      (take :pressed->menu-visible sample
                            :reveal-deadline-delivered))
               (observe sample :obsolete-reveal-deadline)))
         (handle-move-while-selected (sample)
           (let ((binding (binding-under sample)))
             (cond ((and binding
                         (gesture-binding-enabled-p binding)
                         (eq binding selected-binding))
                    (observe sample :same-sector-still-active))
                   ((and binding (gesture-binding-enabled-p binding))
                    (setf selected-binding binding
                          selected-operation
                          (gesture-binding-operation binding))
                    (take :sector-selected->reselected sample
                          (list :angle (%angle origin-x origin-y sample)
                                :binding binding)))
                   (t
                    ;; Leaving the active sector clears the selection and
                    ;; returns to the mode the gesture is in.
                    (setf selected-binding nil
                          selected-operation nil)
                    (take (if (eq mode :marking)
                              :sector-selected->marking
                              :sector-selected->menu-visible)
                          sample
                          (if binding
                              :disabled-sector-entered
                              :no-enabled-sector-at-angle)))))))
      (dolist (sample samples)
        (when (member state '(:completed :cancelled))
          ;; A contract violation, not a modeled outcome.
          (error "Input remains after terminal state ~S." state))
        (push sample consumed)
        (push (list :timestamp (gesture-input-sample-timestamp sample)
                    :kind :synthetic-input-sample :sample sample
                    :scope :transient-gesture)
              evidence)
        (if (eq :reveal-deadline (gesture-input-sample-kind sample))
            (handle-deadline sample)
            (case state
              (:idle
               (case (gesture-input-sample-kind sample)
                 (:pointer-down
                  (if (and (gesture-input-sample-target sample)
                           (eq :secondary (gesture-input-sample-button sample)))
                      (progn
                        (setf target (gesture-input-sample-target sample)
                              origin-x (gesture-input-sample-x sample)
                              origin-y (gesture-input-sample-y sample))
                        (take :idle->pressed sample target))
                      (cancel :idle->cancelled sample
                              :no-target-or-wrong-button)))
                 (otherwise
                  ;; No gesture has begun, so there is nothing to cancel.
                  (observe sample :input-before-any-gesture))))
              (:pressed
               (case (gesture-input-sample-kind sample)
                 (:pointer-move
                  (if (%outside-dead-zone-p origin-x origin-y sample dead-zone)
                      (progn
                        (setf mode :marking)
                        (take :pressed->marking sample
                              :dead-zone-crossed-before-deadline)
                        (select-at sample :marking->sector-selected))
                      (observe sample :within-dead-zone)))
                 (:pointer-up
                  ;; The reason follows the geometry of this very sample.
                  (if (%outside-dead-zone-p origin-x origin-y sample dead-zone)
                      (cancel :pressed->cancelled-without-movement sample
                              :released-without-recognized-movement)
                      (cancel :pressed->cancelled-in-dead-zone sample
                              :released-in-dead-zone)))
                 (:pointer-cancel
                  (cancel :pressed->cancelled-on-cancel sample
                          :pointer-cancelled))
                 (otherwise
                  (error "Unexpected ~S in pressed."
                         (gesture-input-sample-kind sample)))))
              (:marking
               (case (gesture-input-sample-kind sample)
                 (:pointer-move (select-at sample :marking->sector-selected))
                 (:pointer-up
                  (cancel :marking->cancelled-on-release sample
                          :no-active-enabled-sector))
                 (:pointer-cancel
                  (cancel :marking->cancelled-on-cancel sample
                          :pointer-cancelled))
                 (otherwise
                  (error "Unexpected ~S in marking."
                         (gesture-input-sample-kind sample)))))
              (:menu-visible
               (case (gesture-input-sample-kind sample)
                 (:pointer-move
                  (select-at sample :menu-visible->sector-selected))
                 (:pointer-up
                  (cancel :menu-visible->cancelled-on-release sample
                          :no-active-enabled-sector))
                 (:pointer-cancel
                  (cancel :menu-visible->cancelled-on-cancel sample
                          :pointer-cancelled))
                 (otherwise
                  (error "Unexpected ~S in menu-visible."
                         (gesture-input-sample-kind sample)))))
              (:sector-selected
               (case (gesture-input-sample-kind sample)
                 (:pointer-move (handle-move-while-selected sample))
                 (:pointer-up
                  (take :sector-selected->completed sample selected-binding))
                 (:pointer-cancel
                  (cancel :sector-selected->cancelled sample
                          :pointer-cancelled))
                 (otherwise
                  (error "Unexpected ~S in sector-selected."
                         (gesture-input-sample-kind sample))))))))
      (make-instance
       'gesture-session
       :id "gesture-session/synthetic"
       :title "Synthetic Gesture/Binding session"
       :summary "A transient run ending before semantic execution."
       :machine machine :input (nreverse consumed) :current-state state
       :visited-states (nreverse visited)
       :transition-trace (nreverse transitions)
       :evidence-trace (nreverse evidence)
       :start-time (and samples
                        (gesture-input-sample-timestamp (first samples)))
       :end-time (and samples (member state '(:completed :cancelled))
                      (gesture-input-sample-timestamp (car (last samples))))
       :status (case state
                 (:completed :success)
                 (:cancelled :cancelled)
                 (otherwise :running))
       :failure-classification cancellation-reason
       :notes (list (list :scope :transient-gesture-session)
                    (list :boundary
                          "This witness stops at operation identity selection."))
       :binding-catalog bindings :mode mode :selected-binding selected-binding
       :selected-operation selected-operation
       :cancellation-reason cancellation-reason :menu-visible-p menu-visible-p
       :observations (nreverse observations)))))

;;; The two interaction traces the surviving claim is about

(defun %target ()
  (list :type :lisp-source-definition :name 'gesture-binding-witness))

(defun %down ()
  (make-gesture-input-sample :kind :pointer-down :target (%target)
                             :x 0.0d0 :y 0.0d0 :button :secondary
                             :modifiers nil :timestamp 0))

(defun make-expert-marking-trace ()
  "The hidden mark: the pointer leaves the dead zone before any menu."
  (run-gesture-trace
   (list (%down)
         (make-gesture-input-sample :kind :pointer-move :x 20.0d0 :y 0.0d0
                                    :timestamp 100)
         (make-gesture-input-sample :kind :pointer-up :x 20.0d0 :y 0.0d0
                                    :timestamp 120))))

(defun make-novice-visible-menu-trace ()
  "The visible menu: the reveal deadline is delivered before any movement."
  (run-gesture-trace
   (list (%down)
         (make-gesture-input-sample :kind :reveal-deadline :timestamp 500)
         (make-gesture-input-sample :kind :pointer-move :x 20.0d0 :y 0.0d0
                                    :timestamp 600)
         (make-gesture-input-sample :kind :pointer-up :x 20.0d0 :y 0.0d0
                                    :timestamp 620))))

;;; Projection
;;;
;;; Only the relations the session stores in its own slots.

(defmethod tm:topicmap-projection-of ((session gesture-session))
  (let* ((binding (gesture-session-selected-binding-of session))
         (operation (gesture-session-selected-operation-of session))
         (session-id "gesture-session:synthetic")
         (binding-id (and binding
                          (format nil "gesture-binding:~A"
                                  (gesture-binding-id binding))))
         (operation-id (and operation
                            (semantic-operation-identity-id operation))))
    (tm:make-topicmap-projection
     :source session
     :topics
     (append
      (list (tm:make-topicmap-topic :id session-id :type :gesture-session
                                    :label "Synthetic Gesture Session"
                                    :object session))
      (when binding
        (list (tm:make-topicmap-topic :id binding-id :type :binding
                                      :label (gesture-binding-id binding)
                                      :object binding)))
      (when operation
        (list (tm:make-topicmap-topic
               :id operation-id :type :opaque-operation-identity
               :label (semantic-operation-identity-title operation)
               :object operation))))
     :associations
     (append
      (when binding
        (list (tm:make-topicmap-association
               :id "gesture-session:selects:binding" :type :selects
               :from session-id :to binding-id
               :properties (list :epistemic-status :directly-observed
                                 :warrant
                                 "GESTURE-SESSION-SELECTED-BINDING-OF slot."))))
      (when operation
        (list (tm:make-topicmap-association
               :id "gesture-binding:references:operation" :type :references
               :from binding-id :to operation-id
               :properties (list :epistemic-status :directly-observed
                                 :warrant
                                 "GESTURE-BINDING-OPERATION EQ identity.")))))
     :view-properties (list :presentation :gesture-binding-witness
                            :point session-id :width 900 :height 420))))
