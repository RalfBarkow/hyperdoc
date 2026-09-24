;;;; Every test here was first a measurement that contradicted an assumption.
(defpackage #:dreyeck/gesture/transport/tests
  (:use #:cl)
  (:local-nicknames (#:t* #:dreyeck/gesture/transport)
                    (#:w #:dreyeck/gesture-binding-witness)
                    (#:r #:dreyeck/gesture/reading)
                    (#:sm #:dreyeck/state-machine)
                    (#:bt #:bordeaux-threads))
  (:export #:run-gesture-transport-tests))

(in-package #:dreyeck/gesture/transport/tests)

(defun %envelope (sequence kind &key (x 0) (y 0) which buttons)
  (t*:make-transport-envelope
   :sequence sequence :kind kind :x x :y y :which which :buttons buttons
   :target (list :type :lisp-source-definition :name 'gesture-transport)))

(defun %signals (thunk)
  (handler-case (progn (funcall thunk) nil)
    (error (condition) (princ-to-string condition))))

;;; A. The callback order is not the browser order

(defun test-unordered-arrival-is-delivered-in-order ()
  (let* ((transport (t*:make-ordered-transport))
         (arrival '(1 2 4 5 3 6 9 7 8 10))
         (delivered nil))
    (dolist (sequence arrival)
      (t*:enqueue-envelope transport (%envelope sequence :pointer-move
                                                         :buttons 2))
      (t*:drain-transport transport
                          (lambda (envelope)
                            (push (t*:transport-envelope-sequence envelope)
                                  delivered))))
    ;; The arrival list is used as written: sorting it first would test
    ;; nothing.
    (assert (equal arrival (t*:transport-arrival-order transport)))
    (assert (notevery #'< arrival (rest arrival)))
    (assert (equal '(1 2 3 4 5 6 7 8 9 10) (nreverse delivered)))
    (assert (equal '(1 2 3 4 5 6 7 8 9 10)
                   (t*:transport-delivery-order transport)))
    (assert (= 11 (t*:transport-next-expected transport)))
    (assert (null (t*:transport-pending-sequences transport)))
    t))

;;; B. A missing sequence blocks everything behind it

(defun test-contiguous-blocking ()
  (let* ((transport (t*:make-ordered-transport))
         (delivered nil)
         (consumer (lambda (envelope)
                     (push (t*:transport-envelope-sequence envelope)
                           delivered))))
    (loop for sequence in '(1 2 3 4 5 6)
          do (t*:enqueue-envelope transport (%envelope sequence :pointer-move
                                                                :buttons 2))
             (t*:drain-transport transport consumer))
    ;; Seven is withheld while everything after it arrives.
    (loop for sequence from 8 to 20
          do (t*:enqueue-envelope transport (%envelope sequence :pointer-move
                                                                :buttons 2))
             (t*:drain-transport transport consumer))
    (assert (equal '(1 2 3 4 5 6) (reverse delivered)))
    (assert (= 7 (t*:transport-next-expected transport)))
    (assert (equal (loop for i from 8 to 20 collect i)
                   (t*:transport-pending-sequences transport)))
    ;; A sorting implementation would have delivered 8..20 by now.
    (t*:enqueue-envelope transport (%envelope 7 :pointer-move :buttons 2))
    (t*:drain-transport transport consumer)
    (assert (equal (loop for i from 1 to 20 collect i) (reverse delivered)))
    (assert (= 21 (t*:transport-next-expected transport)))
    (assert (null (t*:transport-pending-sequences transport)))
    t))

;;; C. Enqueueing changes nothing the gesture session owns

(defun test-enqueue-does-not-touch-the-session ()
  (let* ((transport (t*:make-ordered-transport))
         (input (t*:make-gesture-input-session)))
    (t*:enqueue-envelope transport (%envelope 1 :pointer-down :which 3
                                                :buttons 2))
    (t*:enqueue-envelope transport (%envelope 2 :pointer-move :x 20
                                                :buttons 2))
    (assert (eq :idle (t*:input-session-status input)))
    (assert (null (t*:input-session-prefix input)))
    (assert (null (t*:input-session-gesture-session input)))
    (assert (null (t*:input-session-held-mask input)))
    ;; Positive control: the consumer does change them.
    (t*:drain-transport transport
                        (lambda (envelope) (t*:consume-envelope input envelope)))
    (assert (eq :active (t*:input-session-status input)))
    (assert (= 2 (t*:input-session-held-mask input)))
    (assert (t*:input-session-gesture-session input))
    t))

;;; D./G. A genuine release still completes, and the crossing move still
;;; produces both transitions in order

(defun %feed (input transport envelopes)
  (dolist (envelope envelopes)
    (t*:enqueue-envelope transport envelope)
    (t*:drain-transport transport
                        (lambda (e) (t*:consume-envelope input e)))))

(defun test-real-pointer-up-completes ()
  (let* ((transport (t*:make-ordered-transport))
         (input (t*:make-gesture-input-session)))
    (%feed input transport
           (list (%envelope 1 :pointer-down :which 3 :buttons 2)
                 (%envelope 2 :pointer-move :x 2 :buttons 2)
                 (%envelope 3 :pointer-move :x 20 :buttons 2)
                 (%envelope 4 :pointer-up :x 20 :which 3 :buttons 0)))
    (let ((session (t*:input-session-gesture-session input)))
      (assert (eq :completed (sm:state-machine-run-current-state-of session)))
      (assert (string= "binding/mark-insert-defexample"
                       (w:gesture-binding-id
                        (w:gesture-session-selected-binding-of session))))
      (assert (eq (w:insert-executable-defexample-operation)
                  (w:gesture-session-selected-operation-of session)))
      ;; The BUTTONS rule did not capture a real release.
      (assert (equal '((:as :pointer-up :on :browser-reported-release))
                     (reverse (t*:input-session-closures input))))
      ;; G: the crossing move still yields both transitions, in order.
      (let* ((reading (r:gesture-session-reading session))
             (crossing (find-if (lambda (record)
                                  (< 1 (length (r:reading-record-effects
                                                record))))
                                reading)))
        (assert crossing)
        (assert (equal '(:pressed->marking :marking->sector-selected)
                       (mapcar (lambda (effect) (getf effect :transition))
                               (r:reading-record-effects crossing))))))
    t))

;;; E. The button vanishes and nothing is committed

(defun test-vanished-button-cancels ()
  (let* ((transport (t*:make-ordered-transport))
         (input (t*:make-gesture-input-session)))
    (%feed input transport
           (list (%envelope 1 :pointer-down :which 3 :buttons 2)
                 (%envelope 2 :pointer-move :x 20 :buttons 2)
                 ;; No pointerup is ever delivered; the bit is simply gone.
                 (%envelope 3 :pointer-move :x 30 :buttons 0)))
    (let ((session (t*:input-session-gesture-session input)))
      (assert (eq :cancelled (sm:state-machine-run-current-state-of session)))
      (assert (null (w:gesture-session-selected-binding-of session)))
      (assert (null (w:gesture-session-selected-operation-of session)))
      (assert (equal '((:as :pointer-cancel
                        :on :initiating-button-no-longer-held))
                     (reverse (t*:input-session-closures input))))
      ;; Nothing synthesised a release.
      (assert (notany (lambda (sample)
                        (eq :pointer-up (w:gesture-input-sample-kind sample)))
                      (sm:state-machine-run-input-of session))))
    t))

;;; F. Capture loss with the button still down is not the end

(defun test-capture-loss-alone-is-not-terminal ()
  (let* ((transport (t*:make-ordered-transport))
         (input (t*:make-gesture-input-session)))
    (%feed input transport
           (list (%envelope 1 :pointer-down :which 3 :buttons 2)
                 (%envelope 2 :pointer-move :x 20 :buttons 2)
                 (%envelope 3 :lost-pointer-capture :x 20 :buttons 2)))
    (assert (eq :active (t*:input-session-status input)))
    (assert (null (t*:input-session-closures input)))
    (assert (eq :sector-selected
                (sm:state-machine-run-current-state-of
                 (t*:input-session-gesture-session input))))
    ;; Positive control: the same event with the bit gone does end it.
    (%feed input transport
           (list (%envelope 4 :lost-pointer-capture :x 20 :buttons 0)))
    (assert (eq :closed (t*:input-session-status input)))
    (assert (equal '((:as :pointer-cancel :on :capture-lost-without-release))
                   (reverse (t*:input-session-closures input))))
    t))

;;; H. The race that used to crash the reducer

(defun test-concurrent-enqueue-has-no-terminal-race ()
  (let* ((transport (t*:make-ordered-transport))
         (input (t*:make-gesture-input-session))
         (envelopes (append
                     (list (%envelope 1 :pointer-down :which 3 :buttons 2))
                     (loop for i from 2 to 30
                           collect (%envelope i :pointer-move :x (+ 10 i)
                                                              :buttons 2))
                     (list (%envelope 31 :pointer-up :x 41 :which 3
                                         :buttons 0))))
         (threads (mapcar (lambda (envelope)
                            (bt:make-thread
                             (lambda () (t*:enqueue-envelope transport
                                                             envelope))))
                          envelopes)))
    (mapc #'bt:join-thread threads)
    ;; One consumer, after arbitrary concurrent arrival.
    (t*:drain-transport transport
                        (lambda (e) (t*:consume-envelope input e)))
    (assert (equal (loop for i from 1 to 31 collect i)
                   (t*:transport-delivery-order transport)))
    (assert (eq :completed
                (sm:state-machine-run-current-state-of
                 (t*:input-session-gesture-session input))))
    ;; And the reducer's terminal check was not weakened to get here.
    (let ((message (%signals
                    (lambda ()
                      (w:run-gesture-trace
                       (append (reverse (t*:input-session-prefix input))
                               (list (w:make-gesture-input-sample
                                      :kind :pointer-move :x 1.0d0 :y 1.0d0
                                      :timestamp 9999))))))))
      (assert message)
      (assert (search "after terminal state" message)))
    t))

;;; The browser bridge, as data

(defun test-browser-bridge-contract ()
  (let ((script (t*:forwarding-script "HOST"))
        (kinds (t*:transport-event-kinds)))
    (assert (search "e.buttons" script))
    ;; One counter, for every forwarded kind. A second counter would
    ;; number the deadline independently of the pointer events, and the
    ;; contiguous queue would then wait forever for a sequence that the
    ;; other counter had already used.
    (let ((counters (loop with start = 0
                          for position = (search "window.__" script
                                                 :start2 start)
                          while position
                          collect (subseq script position
                                          (position-if-not #'alphanumericp
                                                           script
                                                           :start (+ position 9)))
                          do (setf start (1+ position)))))
      (assert (= 2 (length counters)))
      (assert (every (lambda (name) (string= "window.__gestureSeq" name))
                     counters)))
    (assert (not (search "e.type" script)))
    ;; The counter runs over exactly the forwarded kinds, named here so
    ;; the number stays attached to its reason.
    (assert (equal '("pointerdown" "pointermove" "pointerup" "pointercancel"
                     "lostpointercapture" "gesturerevealdeadline")
                   (mapcar #'car kinds)))
    (assert (equal :reveal-deadline (cdr (assoc "gesturerevealdeadline" kinds
                                                :test #'string=))))
    ;; CONTEXTMENU is suppressed in the browser and never numbered: a hole
    ;; in the sequence is a consumer that waits forever.
    (assert (null (assoc "contextmenu" kinds :test #'string=))))
  ;; The press-and-wait threshold has exactly one owner, and it is here.
  (let ((timer (t*:reveal-timer-script "document.body")))
    (assert (search "setTimeout" timer))
    (assert (search "clearTimeout" timer))
    (assert (search "gesturerevealdeadline" timer))
    (assert (search ", 500)" timer))
    ;; Cleared on a browser-observed release, and on nothing else: if the
    ;; callback runs after movement won, the reducer calls it obsolete.
    (assert (search "pointerup" timer))
    (assert (search "pointercancel" timer))
    (assert (not (search "marking" timer)))
    ;; And the threshold is configuration, not a constant of the model.
    (assert (search ", 333)" (t*:reveal-timer-script "document.body"
                                                     :reveal-delay-ms 333))))
  (multiple-value-bind (buttons sequence)
      (t*:trailing-transport-fields "12:34:56:2:41")
    (assert (= 2 buttons))
    (assert (= 41 sequence)))
  t)

;;; The witness an inspector opens

(defun test-witness ()
  (let* ((witness (t*:scrambled-expert-marking-witness))
         (state (t*:witness-state witness)))
    (assert (equal '(1 3 2 5 4) (getf state :callback-arrival)))
    (assert (equal '(1 2 3 4 5) (getf state :consumer-delivery)))
    (assert (null (getf state :pending)))
    (assert (= 6 (getf state :next-expected)))
    (assert (eq :completed (sm:state-machine-run-current-state-of
                            (getf state :gesture))))
    t))

;;; The files this slice created

(defun test-created-source-authorities ()
  (dolist (entry '(("dreyeck/src/gesture-clog-transport.lisp"
                    :dreyeck/gesture/transport "dreyeck/gesture/transport")
                   ("dreyeck/tests/gesture-clog-transport-smoke.lisp"
                    :dreyeck/gesture/transport/tests
                    "dreyeck/gesture/transport/tests"))
           t)
    (assert (uiop:symbol-call :dreyeck/gesture-binding-witness/tests
                              :check-created-source-authority
                              (asdf:system-relative-pathname
                               "dreyeck" (first entry))
                              (second entry) (third entry)))))

(defun test-press-and-wait-is-ordered-by-the-browser ()
  "Kurtenbach and Buxton describe one interaction with two continuations:
press and wait, or move at once. Which one happened is decided by the
browser's own order, and these two traces differ in nothing else."
  (let* ((moving (t*::movement-wins-witness))
         (waiting (t*::deadline-wins-witness))
         (m (t*:witness-state moving))
         (w* (t*:witness-state waiting)))
    (assert (equal '(1 3 2) (getf m :callback-arrival)))
    (assert (equal '(1 2 3) (getf m :consumer-delivery)))
    (assert (eq :marking (w:gesture-session-mode-of (getf m :gesture))))
    (assert
     (equal '(:idle->pressed :pressed->marking :marking->sector-selected)
            (mapcar (lambda (s) (getf s :transition-id))
                    (sm:state-machine-run-transition-trace-of
                     (getf m :gesture)))))
    (assert
     (member :obsolete-reveal-deadline
             (mapcar (lambda (o) (getf o :reason))
                     (w:gesture-session-observations-of (getf m :gesture)))))
    (assert
     (string= "binding/mark-insert-defexample"
              (w:gesture-binding-id
               (w:gesture-session-selected-binding-of (getf m :gesture)))))
    (assert (equal '(1 2 3) (getf w* :consumer-delivery)))
    (assert (eq :menu-visible (w:gesture-session-mode-of (getf w* :gesture))))
    (assert
     (equal
      '(:idle->pressed :pressed->menu-visible :menu-visible->sector-selected)
      (mapcar (lambda (s) (getf s :transition-id))
              (sm:state-machine-run-transition-trace-of (getf w* :gesture)))))
    (assert
     (string= "binding/radial-insert-defexample"
              (w:gesture-binding-id
               (w:gesture-session-selected-binding-of (getf w* :gesture)))))
    (assert
     (eq (w:gesture-session-selected-operation-of (getf m :gesture))
         (w:gesture-session-selected-operation-of (getf w* :gesture))))
    (assert
     (not
      (eq (w:gesture-session-selected-binding-of (getf m :gesture))
          (w:gesture-session-selected-binding-of (getf w* :gesture)))))
    t))

(defun test-a-closed-session-drops-a-late-deadline ()
  "The cancelled-timer boundary, established rather than assumed.
The bridge clears a timeout on a browser-observed release, so an ordinary
interaction produces no late deadline at all. When the session closed for
some other reason -- the initiating button vanishing, say -- the adapter
is what refuses the deadline, and no feedback from Lisp to the browser is
invented to prevent it. The reducer's own condition stays a contract and
is exercised directly below."
  (dolist (terminator '(:pointer-up :pointer-cancel))
    (let* ((transport (t*:make-ordered-transport))
           (input (t*:make-gesture-input-session)))
      (%feed input transport
             (list (%envelope 1 :pointer-down :which 3 :buttons 2)
                   (%envelope 2 :pointer-move :x 20 :buttons 2)
                   (%envelope 3 terminator :x 20 :which 3 :buttons 0)
                   (%envelope 4 :reveal-deadline :x 20 :buttons 0)))
      (assert (eq :closed (t*:input-session-status input)))
      (assert
       (notany
        (lambda (s) (eq :reveal-deadline (w:gesture-input-sample-kind s)))
        (sm:state-machine-run-input-of
         (t*:input-session-gesture-session input))))))
  (let* ((transport (t*:make-ordered-transport))
         (input (t*:make-gesture-input-session)))
    (%feed input transport
           (list (%envelope 1 :pointer-down :which 3 :buttons 2)
                 (%envelope 2 :pointer-move :x 20 :buttons 2)
                 (%envelope 3 :pointer-move :x 30 :buttons 0)
                 (%envelope 4 :reveal-deadline :x 30 :buttons 0)))
    (assert (eq :closed (t*:input-session-status input)))
    (assert
     (eq :cancelled
         (sm:state-machine-run-current-state-of
          (t*:input-session-gesture-session input))))
    (assert
     (notany (lambda (s) (eq :reveal-deadline (w:gesture-input-sample-kind s)))
             (sm:state-machine-run-input-of
              (t*:input-session-gesture-session input))))
    (let ((message
           (%signals
            (lambda ()
              (w:run-gesture-trace
               (append (reverse (t*:input-session-prefix input))
                       (list
                        (w:make-gesture-input-sample :kind :reveal-deadline :x
                                                     30.0d0 :y 0.0d0 :timestamp
                                                     9999))))))))
      (assert message)
      (assert (search "after terminal state" message))))
  t)

(defun test-no-state-depends-on-a-timestamp ()
  "The clock regression for 6bf842bd, at transport level.
The consumer stamps a sample when it gets round to it. Here the deadline
is stamped earlier than the old REVEAL-AT would have allowed, and it
still reveals the menu, because nothing compares it to anything."
  (let* ((transport (t*:make-ordered-transport))
         (input (t*:make-gesture-input-session)))
    (%feed input transport
           (list (%envelope 1 :pointer-down :which 3 :buttons 2)
                 (%envelope 2 :reveal-deadline :x 0 :buttons 2)))
    (let* ((session (t*:input-session-gesture-session input))
           (stamps
            (mapcar #'w:gesture-input-sample-timestamp
                    (sm:state-machine-run-input-of session))))
      (assert (eq :menu-visible (w:gesture-session-mode-of session)))
      (assert (every #'integerp stamps))
      (assert (< (second stamps) 500))))
  t)

(defun %violation (thunk)
  "The condition object, not its text: the slots are the evidence."
  (handler-case (progn (funcall thunk) nil)
                (t*:duplicate-transport-sequence (condition) condition)))

(defun test-two-authorities-cannot-share-one-transport ()
  "The two-window collision, preserved as the failure it is.
Source A numbers DOWN 1 and MOVE 2. Source B is a different page with its
own counter and numbers DOWN 1 and DEADLINE 2. Fed into one transport
this was measured to deliver A's press followed by B's deadline as one
interaction, and to strand A's move for good. The numbers agree; the
authorities do not."
  (let* ((transport (t*:make-ordered-transport))
         (input (t*:make-gesture-input-session))
         (a-down (%envelope 1 :pointer-down :which 3 :buttons 2))
         (a-move (%envelope 2 :pointer-move :x 20 :buttons 2))
         (b-down (%envelope 1 :pointer-down :which 3 :buttons 2))
         (b-deadline (%envelope 2 :reveal-deadline :buttons 2)))
    (%feed input transport (list a-down))
    (let ((violation
           (%violation (lambda () (t*:enqueue-envelope transport b-down)))))
      (assert violation)
      (assert (eql 1 (t*:duplicate-sequence-number violation)))
      (assert (eql 2 (t*:duplicate-sequence-next-expected violation)))
      (assert
       (eq :pointer-down (t*:duplicate-sequence-offered-kind violation))))
    (%feed input transport (list a-move))
    (assert
     (%violation (lambda () (t*:enqueue-envelope transport b-deadline))))
    (let ((session (t*:input-session-gesture-session input)))
      (assert (eq :marking (w:gesture-session-mode-of session)))
      (assert
       (equal '(:pointer-down :pointer-move)
              (mapcar #'w:gesture-input-sample-kind
                      (reverse (t*:input-session-prefix input))))))
    (assert (equal '(1 2) (t*:transport-arrival-order transport)))
    (assert (equal '(1 2) (t*:transport-delivery-order transport)))
    t))

(defun test-a-repeated-sequence-is-refused-in-both-positions ()
  "Delivered and still pending are both 'already seen by this transport'."
  (let ((transport (t*:make-ordered-transport)))
    (t*:enqueue-envelope transport
                         (%envelope 1 :pointer-down :which 3 :buttons 2))
    (t*:take-contiguous transport)
    (let ((violation
           (%violation
            (lambda ()
              (t*:enqueue-envelope transport
                                   (%envelope 1 :pointer-move :buttons 2))))))
      (assert violation)
      (assert (null (t*:duplicate-sequence-present-kind violation))))
    (t*:enqueue-envelope transport
                         (%envelope 3 :pointer-move :x 30 :buttons 2))
    (let ((violation
           (%violation
            (lambda ()
              (t*:enqueue-envelope transport
                                   (%envelope 3 :reveal-deadline :buttons
                                              2))))))
      (assert violation)
      (assert (eq :pointer-move (t*:duplicate-sequence-present-kind violation)))
      (assert
       (eq :reveal-deadline (t*:duplicate-sequence-offered-kind violation))))
    t))

(defun test-a-refused-envelope-changes-nothing ()
  "Signalled before any mutation, so the refusal is not half-applied."
  (let ((transport (t*:make-ordered-transport)))
    (t*:enqueue-envelope transport
                         (%envelope 1 :pointer-down :which 3 :buttons 2))
    (t*:enqueue-envelope transport
                         (%envelope 3 :pointer-move :x 30 :buttons 2))
    (let ((arrival (t*:transport-arrival-order transport))
          (pending (t*:transport-pending-sequences transport))
          (next (t*:transport-next-expected transport)))
      (assert
       (%violation
        (lambda ()
          (t*:enqueue-envelope transport
                               (%envelope 3 :reveal-deadline :buttons 2)))))
      (assert (equal arrival (t*:transport-arrival-order transport)))
      (assert (equal pending (t*:transport-pending-sequences transport)))
      (assert (eql next (t*:transport-next-expected transport))))
    t))

(defun test-one-authority-may-number-across-interactions ()
  "The invariant is uniqueness, not one interaction per transport.
A page keeps counting across releases, and both interactions go through
the same queue with no repetition anywhere."
  (let* ((transport (t*:make-ordered-transport))
         (input (t*:make-gesture-input-session)))
    (%feed input transport
           (list (%envelope 1 :pointer-down :which 3 :buttons 2)
                 (%envelope 2 :pointer-move :x 20 :buttons 2)
                 (%envelope 3 :pointer-up :x 20 :which 3 :buttons 0)
                 (%envelope 4 :pointer-down :which 3 :buttons 2)
                 (%envelope 5 :reveal-deadline :buttons 2)
                 (%envelope 6 :pointer-move :x 20 :buttons 2)
                 (%envelope 7 :pointer-up :x 20 :which 3 :buttons 0)))
    (assert (equal '(1 2 3 4 5 6 7) (t*:transport-delivery-order transport)))
    (let ((session (t*:input-session-gesture-session input)))
      (assert (eq :completed (sm:state-machine-run-current-state-of session)))
      (assert (eq :menu-visible (w:gesture-session-mode-of session)))
      (assert
       (string= "binding/radial-insert-defexample"
                (w:gesture-binding-id
                 (w:gesture-session-selected-binding-of session)))))
    t))

(defun test-the-duplicate-failure-is-selectively-catchable ()
  "The documented failure, answered by name through the package contract.
Catching ERROR would also catch the reducer's terminal-input contract,
which is a different fault with a different remedy. So the handler binds
the specific type, reads the evidence through the exported readers, and a
neighbouring error is shown passing straight through the same handler."
  (let ((transport (t*:make-ordered-transport)))
    (t*:enqueue-envelope transport
                         (%envelope 1 :pointer-down :which 3 :buttons 2))
    (let ((answered
           (handler-case
            (progn
             (t*:enqueue-envelope transport
                                  (%envelope 1 :pointer-move :x 20 :buttons 2))
             :not-signalled)
            (t*:duplicate-transport-sequence (condition)
             (list (t*:duplicate-sequence-number condition)
                   (t*:duplicate-sequence-next-expected condition)
                   (t*:duplicate-sequence-present-kind condition)
                   (t*:duplicate-sequence-offered-kind condition))))))
      (assert (equal '(1 1 :pointer-down :pointer-move) answered)))
    (assert (equal '(1) (t*:transport-arrival-order transport)))
    (assert (equal '(1) (t*:transport-pending-sequences transport))))
  (let ((leaked
         (handler-case
          (w:run-gesture-trace
           (append (w:make-expert-marking-trace)
                   (list
                    (w:make-gesture-input-sample :kind :pointer-move :x 1.0d0
                                                 :y 1.0d0 :timestamp 9999))))
          (t*:duplicate-transport-sequence nil :wrongly-caught)
          (error nil :passed-through))))
    (assert (eq :passed-through leaked)))
  t)

(defun run-gesture-transport-tests ()
  (test-unordered-arrival-is-delivered-in-order)
  (test-contiguous-blocking)
  (test-enqueue-does-not-touch-the-session)
  (test-real-pointer-up-completes)
  (test-vanished-button-cancels)
  (test-capture-loss-alone-is-not-terminal)
  (test-concurrent-enqueue-has-no-terminal-race)
  (test-browser-bridge-contract)
  (test-press-and-wait-is-ordered-by-the-browser)
  (test-a-closed-session-drops-a-late-deadline)
  (test-no-state-depends-on-a-timestamp)
  (test-two-authorities-cannot-share-one-transport)
  (test-a-repeated-sequence-is-refused-in-both-positions)
  (test-a-refused-envelope-changes-nothing)
  (test-one-authority-may-number-across-interactions)
  (test-the-duplicate-failure-is-selectively-catchable)
  (test-witness)
  (test-created-source-authorities)
  (format t "~&GESTURE-TRANSPORT-PASS: out-of-order arrival delivered in ~
browser order, a missing sequence blocks the ones behind it, only the ~
consumer mutates, a real release completes, a vanished button cancels, ~
press-and-wait wins or loses the race by the browser's order alone, and a ~
sequence number offered twice is refused before anything is mutated and ~
can be answered by name through the package contract, so two authorities ~
can no longer be fused into one interaction.~%")
  t)
