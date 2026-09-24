;;;; Counterexamples first: every trace here once falsified the witness.
(defpackage #:dreyeck/gesture-binding-witness/tests
  (:use #:cl)
  (:local-nicknames (#:w #:dreyeck/gesture-binding-witness)
                    (#:sm #:dreyeck/state-machine)
                    (#:tm #:dreyeck/topicmap))
  (:export #:run-gesture-binding-witness-tests))

(in-package #:dreyeck/gesture-binding-witness/tests)

;;; CREATE-LISP-SOURCE acceptance
;;;
;;; Both files of this system were created textually, which the current
;;; authoring contract permits for a path that was not yet a persisted
;;; source authority. It requires these postconditions in exchange. The
;;; check lives here, beside the two files it was granted for; it moves
;;; somewhere shared when a second caller needs it.

(defun %read-forms-with-packages (path)
  "Every top-level form beside the package it was read in.
Signals rather than recovering, so a file needing reader recovery fails."
  (with-open-file (stream path :external-format :utf-8)
    (let ((*package* (find-package :cl-user)) (*read-eval* nil) (entries nil))
      (loop for form = (read stream nil :eof)
            until (eq form :eof)
            do (push (cons form *package*) entries)
               (when (and (consp form) (symbolp (first form))
                          (string= "IN-PACKAGE" (symbol-name (first form))))
                 (setf *package* (find-package (second form)))))
      (values (nreverse entries) *package*))))

(defun %symbol-identity (symbol)
  (let ((home (symbol-package symbol)))
    (list (if home (package-name home) :uninterned) (symbol-name symbol))))

(defun %structurally-equal (a b)
  "Compare forms by structure and symbol identity.
EQUAL is wrong here: #:FOO reads as a fresh uninterned symbol each time
and would report a difference the source does not have."
  (cond ((and (symbolp a) (symbolp b))
         (equal (%symbol-identity a) (%symbol-identity b)))
        ((and (consp a) (consp b))
         (and (%structurally-equal (car a) (car b))
              (%structurally-equal (cdr a) (cdr b))))
        ((and (stringp a) (stringp b)) (string= a b))
        ;; SBCL reads a backquote into comma objects, which are structures,
        ;; and every read makes new ones. Slot by slot they are the same
        ;; form; by EQL they never were, and every backquote was refused.
        ((and (typep a 'structure-object) (typep b 'structure-object)
              (eq (class-of a) (class-of b)))
         (every (lambda (slot)
                  (let ((name (sb-mop:slot-definition-name slot)))
                    (%structurally-equal (slot-value a name) (slot-value b name))))
                (sb-mop:class-slots (class-of a))))
        (t (eql a b))))

(defun %round-trips-p (form package)
  (let ((*package* package) (*read-eval* nil))
    (handler-case (%structurally-equal form (read-from-string
                                             (prin1-to-string form)))
      (error () nil))))

(defun %definition-identity (form)
  "The structural identity a declared definition can be named by."
  (and (consp form) (symbolp (first form))
       (let ((head (symbol-name (first form)))
             (subject (second form)))
         (when (member head '("DEFUN" "DEFCLASS" "DEFSTRUCT" "DEFVAR"
                              "DEFMETHOD" "DEFPACKAGE" "DEFGENERIC")
                       :test #'string=)
           (list head (let ((name (if (consp subject)
                                      (first subject)
                                      subject)))
                        (if (symbolp name) (symbol-name name) name)))))))

(defun %asdf-owns-p (path system-name)
  (let ((here (probe-file path)))
    (some (lambda (component)
            (equal here (ignore-errors
                         (probe-file (asdf:component-pathname component)))))
          (remove-if-not (lambda (component)
                           (typep component 'asdf:cl-source-file))
                         (asdf:required-components (asdf:find-system system-name)
                                                   :other-systems nil)))))

(defun check-created-source-authority (path package-name system-name)
  (multiple-value-bind (entries final-package) (%read-forms-with-packages path)
    (let* ((forms (mapcar #'car entries))
           (unstable (remove-if (lambda (entry)
                                  (%round-trips-p (car entry) (cdr entry)))
                                entries))
           (identities (remove nil (mapcar #'%definition-identity forms)))
           (duplicates (remove-if (lambda (identity)
                                    (= 1 (count identity identities
                                                :test #'equal)))
                                  identities)))
      ;; No reader recovery: reaching this point without a condition is
      ;; the whole of that postcondition.
      (assert forms)
      ;; Intended package identity.
      (assert (eq final-package (find-package package-name)))
      ;; Structural round-trip, package-aware.
      (assert (null unstable))
      ;; Each declared definition individually identifiable, exactly once.
      (assert identities)
      (assert (null duplicates))
      ;; Explicit ASDF ownership.
      (assert (%asdf-owns-p path system-name))
      identities)))

(defun test-created-source-authority ()
  (let ((source (check-created-source-authority
                 (asdf:system-relative-pathname
                  "dreyeck" "dreyeck/src/gesture-binding-witness.lisp")
                 :dreyeck/gesture-binding-witness
                 "dreyeck/gesture-binding-witness"))
        (tests (check-created-source-authority
                (asdf:system-relative-pathname
                 "dreyeck" "dreyeck/tests/gesture-binding-witness-smoke.lisp")
                :dreyeck/gesture-binding-witness/tests
                "dreyeck/gesture-binding-witness/tests")))
    ;; Positive control: the check can tell the two files apart, and can
    ;; reject a file it does not own.
    (assert (not (equal source tests)))
    (assert (member '("DEFUN" "RUN-GESTURE-TRACE") source :test #'equal))
    (assert (member '("DEFCLASS" "GESTURE-SESSION") source :test #'equal))
    (assert (not (%asdf-owns-p
                  (asdf:system-relative-pathname
                   "dreyeck" "dreyeck/src/gesture-binding-witness.lisp")
                  "dreyeck/gesture-binding-witness/tests")))
    (format t "~&CREATE-LISP-SOURCE-ACCEPTED: ~D and ~D top-level definitions, ~
each named once, both files owned by their system.~%"
            (length source) (length tests))
    t))

;;; Building traces

(defun %target (&optional (type :lisp-source-definition))
  (list :type type :name 'gesture-probe))

(defun %down (&key (target (%target)) (timestamp 0) (button :secondary))
  (w:make-gesture-input-sample :kind :pointer-down :target target
                               :x 0.0d0 :y 0.0d0 :button button
                               :timestamp timestamp))

(defun %at (kind x y timestamp)
  (w:make-gesture-input-sample :kind kind :x (float x 1.0d0) :y (float y 1.0d0)
                               :timestamp timestamp))

(defun %deadline (timestamp)
  (w:make-gesture-input-sample :kind :reveal-deadline :timestamp timestamp))

(defun %state-of (session)
  (sm:state-machine-run-current-state-of session))

(defun %transition-ids (session)
  (mapcar (lambda (step) (getf step :transition-id))
          (sm:state-machine-run-transition-trace-of session)))

(defun %reasons (session)
  (mapcar (lambda (entry) (getf entry :reason))
          (w:gesture-session-observations-of session)))

(defun %ok (findings)
  (every (lambda (finding) (eq :ok (getf finding :status))) findings))

(defun %structurally-well-formed-p (session)
  "Known states, guards and events, and no outgoing terminal transition.
This is all the generic validator checks. It says nothing about event
coverage, reachability, acyclicity or the documented notes."
  (and (%ok (sm:state-machine-definition-findings
             (sm:state-machine-run-machine-of session)))
       (%ok (sm:state-machine-run-findings session))))

(defun %signals-error (thunk)
  (handler-case (progn (funcall thunk) nil)
    (error (condition) (princ-to-string condition))))

;;; The surviving claim

(defun test-binding-identity ()
  (let* ((bindings (w:make-gesture-binding-catalog))
         (radial (find :radial-menu bindings :key #'w:gesture-binding-kind))
         (mark (find :learned-mark bindings :key #'w:gesture-binding-kind))
         (inspector (find :inspector-action bindings
                          :key #'w:gesture-binding-kind))
         (operation (w:insert-executable-defexample-operation)))
    (assert (and radial mark inspector))
    (assert (not (eq radial mark)))
    (assert (not (eq radial inspector)))
    (assert (not (eq mark inspector)))
    (assert (eq operation (w:gesture-binding-operation radial)))
    (assert (eq operation (w:gesture-binding-operation mark)))
    (assert (eq operation (w:gesture-binding-operation inspector)))
    t))

(defun test-operation-is-data ()
  "What is observable is that the identity cannot be called, not that a
call was watched and did not happen."
  (let ((operation (w:insert-executable-defexample-operation)))
    (assert (typep operation 'w:semantic-operation-identity))
    (assert (not (functionp operation)))
    (assert (notany #'functionp
                    (list (w:semantic-operation-identity-id operation)
                          (w:semantic-operation-identity-title operation))))
    (assert (eq operation (w:gesture-session-selected-operation-of
                           (w:make-expert-marking-trace))))
    t))

(defun test-expert ()
  (let* ((session (w:make-expert-marking-trace))
         (binding (w:gesture-session-selected-binding-of session)))
    (assert (eq :completed (%state-of session)))
    (assert (eq :marking (w:gesture-session-mode-of session)))
    (assert (eq :learned-mark (w:gesture-binding-kind binding)))
    (assert (eq (w:insert-executable-defexample-operation)
                (w:gesture-session-selected-operation-of session)))
    (assert (not (w:gesture-session-menu-visible-p-of session)))
    (assert (not (find :menu-visible
                       (sm:state-machine-run-visited-states-of session))))
    (assert (%structurally-well-formed-p session))
    t))

(defun test-novice ()
  (let* ((session (w:make-novice-visible-menu-trace))
         (binding (w:gesture-session-selected-binding-of session)))
    (assert (eq :completed (%state-of session)))
    (assert (eq :menu-visible (w:gesture-session-mode-of session)))
    (assert (eq :radial-menu (w:gesture-binding-kind binding)))
    (assert (w:gesture-session-menu-visible-p-of session))
    (assert (find :menu-visible
                  (sm:state-machine-run-visited-states-of session)))
    (assert (eq (w:insert-executable-defexample-operation)
                (w:gesture-session-selected-operation-of session)))
    (assert (%structurally-well-formed-p session))
    t))

;;; A. Exact reveal boundary
;;;
;;; The move used to be dropped because its timestamp was not strictly
;;; less than the nominal deadline, and the release was then recorded as
;;; a dead-zone release although the pointer was twenty units out.

(defun test-exact-reveal-boundary ()
  (let ((session (w:run-gesture-trace
                  (list (%down) (%at :pointer-move 20 0 500)
                        (%at :pointer-up 20 0 520)))))
    (assert (eq :completed (%state-of session)))
    (assert (eq :marking (w:gesture-session-mode-of session)))
    (assert (member :pressed->marking (%transition-ids session)))
    ;; The move was not swallowed.
    (assert (not (member :within-dead-zone (%reasons session))))
    (assert (null (w:gesture-session-cancellation-reason-of session)))
    ;; Positive control: one millisecond earlier behaves the same way, so
    ;; the equality case is not passing for an unrelated reason.
    (let ((earlier (w:run-gesture-trace
                    (list (%down) (%at :pointer-move 20 0 499)
                          (%at :pointer-up 20 0 520)))))
      (assert (equal (%transition-ids earlier) (%transition-ids session))))
    ;; And a delivered deadline still opens the menu at the same instant.
    (let ((revealed (w:run-gesture-trace
                     (list (%down) (%deadline 500) (%at :pointer-move 20 0 600)
                           (%at :pointer-up 20 0 620)))))
      (assert (eq :menu-visible (w:gesture-session-mode-of revealed)))
      (assert (eq :completed (%state-of revealed))))
    t))

;;; B. Exact dead-zone boundary
;;;
;;; distance <= dead-zone is inside; strictly greater has crossed.

(defun test-exact-dead-zone-boundary ()
  (let ((at-radius (w:run-gesture-trace
                    (list (%down) (%at :pointer-move 5 0 100)
                          (%at :pointer-up 5 0 120)))))
    (assert (eq :cancelled (%state-of at-radius)))
    (assert (eq :released-in-dead-zone
                (w:gesture-session-cancellation-reason-of at-radius)))
    ;; The move is recorded rather than discarded.
    (assert (member :within-dead-zone (%reasons at-radius)))
    (assert (null (w:gesture-session-mode-of at-radius))))
  (let ((beyond (w:run-gesture-trace
                 (list (%down) (%at :pointer-move 5.0001d0 0 100)
                       (%at :pointer-up 20 0 120)))))
    (assert (eq :completed (%state-of beyond)))
    (assert (eq :marking (w:gesture-session-mode-of beyond))))
  t)

;;; C. Honest release evidence
;;;
;;; A release outside the dead zone may not be called a dead-zone release.

(defun test-release-evidence-is-honest ()
  (let ((inside (w:run-gesture-trace
                 (list (%down) (%at :pointer-up 2 0 20))))
        (outside (w:run-gesture-trace
                  (list (%down) (%at :pointer-up 20 0 20)))))
    (assert (eq :released-in-dead-zone
                (w:gesture-session-cancellation-reason-of inside)))
    (assert (member :pressed->cancelled-in-dead-zone
                    (%transition-ids inside)))
    (assert (eq :released-without-recognized-movement
                (w:gesture-session-cancellation-reason-of outside)))
    (assert (member :pressed->cancelled-without-movement
                    (%transition-ids outside)))
    ;; Positive control: the two traces differ only in the geometry, so
    ;; the classification cannot be a constant.
    (assert (not (eq (w:gesture-session-cancellation-reason-of inside)
                     (w:gesture-session-cancellation-reason-of outside))))
    t))

;;; D. Disabled sector, then enabled sector, then release
;;;
;;; "Cannot become active" is not "cancels the gesture".

(defun test-disabled-sector-is-not-terminal ()
  (let* ((session (w:run-gesture-trace
                   (list (%down) (%deadline 500)
                         (%at :pointer-move -20 0 600)
                         (%at :pointer-move 20 0 700)
                         (%at :pointer-up 20 0 720))))
         (binding (w:gesture-session-selected-binding-of session))
         (entered (find :disabled-sector-entered
                        (w:gesture-session-observations-of session)
                        :key (lambda (entry) (getf entry :reason)))))
    (assert (eq :completed (%state-of session)))
    (assert (string= "binding/radial-insert-defexample"
                     (w:gesture-binding-id binding)))
    (assert (eq (w:insert-executable-defexample-operation)
                (w:gesture-session-selected-operation-of session)))
    ;; Positive control: the disabled Binding really was encountered, so
    ;; completing did not merely mean the pointer missed it.
    (assert entered)
    (assert (string= "binding/radial-disabled-sector" (getf entered :detail)))
    ;; And it was never selected on the way.
    (assert (not (member :disabled-sector-entered
                         (%transition-ids session))))
    ;; Releasing while still inside the disabled sector cancels for the
    ;; truthful reason: nothing enabled was active.
    (let ((stopped (w:run-gesture-trace
                    (list (%down) (%deadline 500)
                          (%at :pointer-move -20 0 600)
                          (%at :pointer-up -20 0 620)))))
      (assert (eq :cancelled (%state-of stopped)))
      (assert (eq :no-active-enabled-sector
                  (w:gesture-session-cancellation-reason-of stopped)))
      (assert (null (w:gesture-session-selected-binding-of stopped))))
    t))

;;; E./F. An obsolete timer is accepted and ignored

(defun %two-enabled-radial-catalog ()
  "A catalog with two enabled radial sectors, so reselection has a target."
  (let ((operation (w:insert-executable-defexample-operation)))
    (list (dreyeck/gesture-binding-witness::%make-gesture-binding
           :id "binding/radial-east" :kind :radial-menu :sector-center 0.0d0
           :sector-half-width 30.0d0 :target-type :lisp-source-definition
           :enabled-p t :operation operation)
          (dreyeck/gesture-binding-witness::%make-gesture-binding
           :id "binding/radial-north" :kind :radial-menu
           :sector-center 90.0d0 :sector-half-width 30.0d0
           :target-type :lisp-source-definition :enabled-p t
           :operation operation))))

(defun test-obsolete-deadline-is-ignored ()
  ;; E. after marking has begun
  (let ((marking (w:run-gesture-trace
                  (list (%down) (%at :pointer-move 20 0 100)
                        (%deadline 500) (%at :pointer-up 20 0 520)))))
    (assert (eq :completed (%state-of marking)))
    (assert (eq :marking (w:gesture-session-mode-of marking)))
    (assert (not (w:gesture-session-menu-visible-p-of marking)))
    ;; Positive control: the deadline event was consumed and recorded, so
    ;; "ignored" does not mean "never delivered".
    (assert (member :obsolete-reveal-deadline (%reasons marking)))
    (assert (find :reveal-deadline (sm:state-machine-run-input-of marking)
                  :key #'w:gesture-input-sample-kind))
    (assert (not (member :pressed->menu-visible (%transition-ids marking)))))
  ;; F. after a sector is already selected
  (let ((selected (w:run-gesture-trace
                   (list (%down) (%at :pointer-move 20 0 100)
                         (%deadline 500) (%at :pointer-move 21 0 600)
                         (%at :pointer-up 21 0 620)))))
    (assert (eq :completed (%state-of selected)))
    (assert (member :obsolete-reveal-deadline (%reasons selected))))
  ;; The clock falsifier. A deadline whose consumer-assigned timestamp is
  ;; earlier than the old REVEAL-AT would have been is now accepted: the
  ;; reducer no longer knows a threshold, so there is nothing for a second
  ;; clock to disagree with. Restoring that guard makes this line fail.
  (let ((early (w:run-gesture-trace (list (%down) (%deadline 499)))))
    (assert (eq :menu-visible (w:gesture-session-mode-of early)))
    (assert (member :pressed->menu-visible (%transition-ids early))))
  t)

;;; G. Target mismatch

(defun test-target-mismatch ()
  (let ((session (w:run-gesture-trace
                  (list (%down :target (%target :something-else))
                        (%at :pointer-move 20 0 100)
                        (%at :pointer-up 20 0 120)))))
    (assert (eq :cancelled (%state-of session)))
    (assert (eq :no-active-enabled-sector
                (w:gesture-session-cancellation-reason-of session)))
    (assert (eq :marking (w:gesture-session-mode-of session)))
    (assert (member :no-enabled-sector-at-angle (%reasons session)))
    (assert (null (w:gesture-session-selected-binding-of session)))
    ;; Positive control: the same geometry on the eligible target selects.
    (assert (w:gesture-session-selected-binding-of
             (w:run-gesture-trace (list (%down) (%at :pointer-move 20 0 100)
                                        (%at :pointer-up 20 0 120)))))
    t))

;;; H. Reselection, and leaving every enabled sector

(defun test-reselection ()
  (let* ((bindings (%two-enabled-radial-catalog))
         (session (w:run-gesture-trace
                   (list (%down) (%deadline 500)
                         (%at :pointer-move 20 0 600)
                         (%at :pointer-move 0 20 700)
                         (%at :pointer-up 0 20 720))
                   :bindings bindings))
         (binding (w:gesture-session-selected-binding-of session)))
    (assert (eq :completed (%state-of session)))
    (assert (member :sector-selected->reselected (%transition-ids session)))
    (assert (string= "binding/radial-north" (w:gesture-binding-id binding)))
    ;; Positive control: the second sector is a different Binding, and the
    ;; first one was genuinely selected before it.
    (let ((first-selected
            (find-if (lambda (step)
                       (eq :menu-visible->sector-selected
                           (getf step :transition-id)))
                     (sm:state-machine-run-transition-trace-of session))))
      (assert first-selected)
      (assert (not (eq binding (getf (getf first-selected :detail) :binding))))
      (assert (string= "binding/radial-east"
                       (w:gesture-binding-id
                        (getf (getf first-selected :detail) :binding))))))
  ;; Leaving every enabled sector clears the selection without ending the
  ;; gesture; the release then cancels for the truthful reason.
  (let ((session (w:run-gesture-trace
                  (list (%down) (%deadline 500)
                        (%at :pointer-move 20 0 600)
                        (%at :pointer-move 0 -20 700)
                        (%at :pointer-up 0 -20 720))
                  :bindings (%two-enabled-radial-catalog))))
    (assert (eq :cancelled (%state-of session)))
    (assert (member :sector-selected->menu-visible (%transition-ids session)))
    (assert (eq :no-active-enabled-sector
                (w:gesture-session-cancellation-reason-of session)))
    (assert (null (w:gesture-session-selected-binding-of session)))
    (assert (null (w:gesture-session-selected-operation-of session))))
  t)

;;; I. A terminal state is still a contract

(defun test-terminal-state-is-a-contract ()
  (let ((message (%signals-error
                  (lambda ()
                    (w:run-gesture-trace
                     (list (%down) (%at :pointer-move 20 0 100)
                           (%at :pointer-up 20 0 120)
                           (%at :pointer-move 20 0 200)))))))
    ;; Positive control: the condition is signalled, with the state named.
    (assert message)
    (assert (search "after terminal state" message))
    (assert (search "COMPLETED" message))
    ;; And the same prefix without the extra sample completes normally.
    (assert (eq :completed
                (%state-of (w:run-gesture-trace
                            (list (%down) (%at :pointer-move 20 0 100)
                                  (%at :pointer-up 20 0 120))))))
    t))

;;; Other transient outcomes

(defun test-cancellation ()
  (let ((cancelled (w:run-gesture-trace
                    (list (%down) (w:make-gesture-input-sample
                                   :kind :pointer-cancel :x 0.0d0 :y 0.0d0
                                   :timestamp 20))))
        (ineligible (w:run-gesture-trace
                     (list (%down :button :primary)))))
    (assert (eq :cancelled (%state-of cancelled)))
    (assert (eq :pointer-cancelled
                (w:gesture-session-cancellation-reason-of cancelled)))
    (assert (eq :cancelled (%state-of ineligible)))
    (assert (eq :no-target-or-wrong-button
                (w:gesture-session-cancellation-reason-of ineligible)))
    ;; Movement before any pointer-down is recorded, not mistaken for an
    ;; ineligible press.
    (let ((stray (w:run-gesture-trace (list (%at :pointer-move 20 0 10)))))
      (assert (eq :idle (%state-of stray)))
      (assert (member :input-before-any-gesture (%reasons stray)))
      (assert (null (w:gesture-session-cancellation-reason-of stray))))
    t))

(defun test-projection ()
  (let* ((session (w:make-expert-marking-trace))
         (projection (tm:topicmap-projection-of session))
         (associations (tm:topicmap-projection-associations-of projection)))
    (assert (eq session (tm:topicmap-projection-source-of projection)))
    (assert (= 3 (length (tm:topicmap-projection-topics-of projection))))
    (assert (equal '(:selects :references)
                   (mapcar #'tm:topicmap-association-type-of associations)))
    (assert (every (lambda (association)
                     (eq :directly-observed
                         (getf (tm:topicmap-association-properties-of
                                association)
                               :epistemic-status)))
                   associations))
    ;; Positive control: a session that selected nothing projects neither
    ;; relation, so the two above are not unconditional.
    (let ((cancelled (tm:topicmap-projection-of
                      (w:run-gesture-trace
                       (list (%down) (%at :pointer-up 2 0 20))))))
      (assert (= 1 (length (tm:topicmap-projection-topics-of cancelled))))
      (assert (null (tm:topicmap-projection-associations-of cancelled))))
    t))

(defun test-backquote-round-trips ()
  "The documented false negative, closed where it arose: in the check.
A backquoted form now survives its own round trip, and a difference inside
a comma is still a difference."
  (let ((form
         (read-from-string
          "(defun probe (path) `(open ,path :direction :output))"))
        (other
         (read-from-string
          "(defun probe (path) `(open ,paths :direction :output))")))
    (assert (%round-trips-p form (find-package :cl-user)))
    (assert (not (%structurally-equal form other))))
  t)

(defun run-gesture-binding-witness-tests ()
  (test-backquote-round-trips)
  (test-created-source-authority)
  (test-binding-identity)
  (test-operation-is-data)
  (test-expert)
  (test-novice)
  (test-exact-reveal-boundary)
  (test-exact-dead-zone-boundary)
  (test-release-evidence-is-honest)
  (test-disabled-sector-is-not-terminal)
  (test-obsolete-deadline-is-ignored)
  (test-target-mismatch)
  (test-reselection)
  (test-terminal-state-is-a-contract)
  (test-cancellation)
  (test-projection)
  (format t "~&GESTURE-BINDING-PASS: one operation identity behind three ~
Bindings; nine counterexamples modeled; terminal input still a contract.~%")
  t)
