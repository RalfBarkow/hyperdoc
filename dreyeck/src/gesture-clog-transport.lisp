;;;; Ordered pointer transport: unordered callbacks to an ordered input.
;;;;
;;;; Measured, not assumed: the host delivers each browser event on its own
;;;; thread, so the order handlers run in is not the order the browser sent.
;;;; A burst of 41 moves numbered 1..41 in the browser arrived in Lisp as
;;;; 1 3 30 24 10 19 16 22 ... A lock around the session would only make
;;;; that wrong order reproducible.
;;;;
;;;; Three responsibilities, kept apart:
;;;;
;;;;   browser bridge    numbers each forwarded event and carries BUTTONS
;;;;   ordered transport releases only the next contiguous number
;;;;   input session     translates ordered envelopes into gesture samples
;;;;
;;;; Nothing here changes RUN-GESTURE-TRACE or the state machine. The
;;;; transport exists so that the reducer's own rule -- delivered order is
;;;; authoritative -- is given an order it can rely on.

(defpackage #:dreyeck/gesture/transport
  (:use #:cl)
  (:local-nicknames (#:w #:dreyeck/gesture-binding-witness)
                    (#:sm #:dreyeck/state-machine)
                    (#:bt #:bordeaux-threads))
  (:export #:transport-envelope #:make-transport-envelope
           #:transport-envelope-sequence #:transport-envelope-kind
           #:transport-envelope-buttons #:transport-envelope-which
           #:transport-envelope-x #:transport-envelope-y
           #:transport-envelope-modifiers #:transport-envelope-target
           #:transport-event-kinds #:forwarding-script
           #:trailing-transport-fields
           #:ordered-transport #:make-ordered-transport
           #:enqueue-envelope #:take-contiguous #:drain-transport
           #:transport-arrival-order #:transport-delivery-order
           #:transport-next-expected #:transport-pending-sequences
           #:gesture-input-session #:make-gesture-input-session
           #:consume-envelope #:input-session-status #:input-session-prefix
           #:input-session-gesture-session #:input-session-closures
           #:input-session-held-mask
           #:gesture-transport-witness #:make-gesture-transport-witness
           #:witness-transport #:witness-input #:witness-state
           #:scrambled-expert-marking-witness))

(in-package #:dreyeck/gesture/transport)

;;; Browser bridge
;;;
;;; The sequence number is assigned in the browser, immediately before an
;;; event is forwarded, and only for the events that enter this queue. A
;;; counter that also ran over events which are not forwarded would open
;;; gaps the consumer could never close.

(defun transport-event-kinds ()
  "The browser event names this transport carries, and their Lisp kinds.
CONTEXTMENU is deliberately absent: it is a browser-side default to
suppress, not an input the gesture consumes, and giving it a sequence
number would put a hole in the queue."
  '(("pointerdown" . :pointer-down)
    ("pointermove" . :pointer-move)
    ("pointerup" . :pointer-up)
    ("pointercancel" . :pointer-cancel)
    ("lostpointercapture" . :lost-pointer-capture)
    ("gesturerevealdeadline" . :reveal-deadline)))

(defun forwarding-script (host-script)
  "HOST-SCRIPT with BUTTONS and a browser-assigned sequence appended.
BUTTONS is the live bitmask of pressed buttons. The host's own pointer
payload carries WHICH, which is 0 during a move and therefore says
nothing about what is still held."
  (concatenate 'string host-script
               " + ':' + e.buttons + ':' + (window.__gestureSeq="
               "(window.__gestureSeq||0)+1)"))

(defun reveal-timer-script (target-expression &key (reveal-delay-ms 500))
  "JavaScript turning press-and-wait into a forwarded transport event.
This is where the threshold lives. The reducer knows no duration and the
queue knows no duration; the browser schedules the wait and reports that
it elapsed, and the report is ordered with the pointer events because it
is dispatched as one of them.

Kurtenbach and Buxton report approximately 1/3 second for press-and-wait.
This witness uses 500 ms. That is our parameter choice, not a reading of
the paper.

The timeout is cleared on a browser-observed release, so an interaction
that ends before the wait elapses produces no deadline at all. It is NOT
cleared when movement begins marking: if the callback still runs, the
event is forwarded and the reducer records it as obsolete, which is
evidence that movement won the ordering race. A deadline that arrives
after the input session closed for any other reason is dropped by the
adapter, so nothing here needs to hear back from Lisp.

The sequence number is not allocated when the timeout is scheduled. It is
allocated by the forwarding script when the callback actually runs."
  (format nil "(function () {
  var target = ~A;
  var timer = null;
  function clear () { if (timer !== null) { clearTimeout(timer); timer = null; } }
  target.addEventListener('pointerdown', function (event) {
    clear();
    timer = setTimeout(function () {
      timer = null;
      target.dispatchEvent(new PointerEvent('gesturerevealdeadline',
        {bubbles: true, clientX: event.clientX, clientY: event.clientY,
         buttons: event.buttons}));
    }, ~D);
  }, true);
  ['pointerup', 'pointercancel'].forEach(function (kind) {
    target.addEventListener(kind, clear, true);
  });
})();"
          target-expression reveal-delay-ms))

(defun trailing-transport-fields (data)
  "The BUTTONS and SEQUENCE this transport appended, as two values.
Read from the end, so the host's own field count stays its business."
  (let* ((fields (uiop:split-string data :separator ":"))
         (n (length fields)))
    (values (and (>= n 2) (ignore-errors (parse-integer (nth (- n 2) fields))))
            (and (>= n 1) (ignore-errors (parse-integer (nth (- n 1) fields)))))))

;;; Envelopes

(defstruct (transport-envelope
            (:constructor make-transport-envelope
                (&key sequence kind buttons which x y modifiers target)))
  "One forwarded browser event. Read by the consumer, rewritten by nobody."
  sequence kind buttons which x y modifiers target)

;;; Ordered transport

(defclass ordered-transport ()
  ((lock :initform (bt:make-lock "gesture-transport") :reader transport-lock)
   (pending :initform (make-hash-table) :reader transport-pending)
   (next-expected :initform 1 :accessor transport-next-expected)
   (arrival :initform nil :accessor transport-arrival)
   (delivery :initform nil :accessor transport-delivery))
  (:documentation
   "A queue that releases envelopes only in browser order.
Callback threads may enqueue. They may not deliver, and they may not
touch anything the gesture session owns."))

(defun make-ordered-transport () (make-instance 'ordered-transport))

(defun enqueue-envelope (transport envelope)
  "All a callback thread is allowed to do."
  (bt:with-lock-held ((transport-lock transport))
    (push (transport-envelope-sequence envelope) (transport-arrival transport))
    (setf (gethash (transport-envelope-sequence envelope)
                   (transport-pending transport))
          envelope))
  envelope)

(defun take-contiguous (transport)
  "The envelopes that are next, in order, and nothing else.
A sequence that arrived early waits for its predecessor; it is not
delivered because it happens to be present."
  (bt:with-lock-held ((transport-lock transport))
    (loop for expected = (transport-next-expected transport)
          for envelope = (gethash expected (transport-pending transport))
          while envelope
          collect (progn (remhash expected (transport-pending transport))
                         (push expected (transport-delivery transport))
                         (incf (transport-next-expected transport))
                         envelope))))

(defun drain-transport (transport function)
  "Hand every currently deliverable envelope to FUNCTION, in order."
  (let ((delivered (take-contiguous transport)))
    (dolist (envelope delivered delivered)
      (funcall function envelope))))

(defun transport-arrival-order (transport)
  (reverse (transport-arrival transport)))

(defun transport-delivery-order (transport)
  (reverse (transport-delivery transport)))

(defun transport-pending-sequences (transport)
  "Sequences that are here but not yet due. A non-empty list beside a
missing NEXT-EXPECTED is the honest picture of a blocked consumer, not an
error to paper over."
  (sort (loop for key being the hash-keys of (transport-pending transport)
              collect key)
        #'<))

;;; Input session
;;;
;;; The only place gesture state is mutated, and only from one thread.

(defclass gesture-input-session ()
  ((status :initform :idle :accessor input-session-status)
   (prefix :initform nil :accessor input-session-prefix)
   (held-mask :initform nil :accessor input-session-held-mask)
   (origin :initform nil :accessor input-session-origin)
   (gesture :initform nil :accessor input-session-gesture-session)
   (closures :initform nil :accessor input-session-closures))
  (:documentation
   "The lifecycle the reducer deliberately does not own.
RUN-GESTURE-TRACE signals on input after a terminal state; that contract
is kept, and closing the input session is what keeps it kept."))

(defun make-gesture-input-session () (make-instance 'gesture-input-session))

(defun %mask-of (which)
  "BUTTONS is a bitmask; WHICH names one button. 1 primary, 3 secondary."
  (case which (1 1) (2 4) (3 2) (t nil)))

(defun %held-p (session envelope)
  (let ((mask (input-session-held-mask session))
        (buttons (transport-envelope-buttons envelope)))
    (and mask buttons (logtest buttons mask))))

(defun %timestamp (session)
  (let ((origin (input-session-origin session)))
    (if origin
        (round (* 1000 (/ (- (get-internal-real-time) origin)
                          internal-time-units-per-second)))
        0)))

(defun %sample (session kind envelope)
  (w:make-gesture-input-sample
   :kind kind
   :target (when (eq kind :pointer-down) (transport-envelope-target envelope))
   :x (float (or (transport-envelope-x envelope) 0) 1.0d0)
   :y (float (or (transport-envelope-y envelope) 0) 1.0d0)
   :button (when (eq kind :pointer-down)
             (case (transport-envelope-which envelope)
               (1 :primary) (2 :middle) (3 :secondary)))
   :modifiers (transport-envelope-modifiers envelope)
   :timestamp (%timestamp session)))

(defun %reduce (session)
  (setf (input-session-gesture-session session)
        (w:run-gesture-trace (reverse (input-session-prefix session))))
  (when (member (sm:state-machine-run-current-state-of
                 (input-session-gesture-session session))
                '(:completed :cancelled))
    (setf (input-session-status session) :closed))
  (input-session-gesture-session session))

(defun %append (session kind envelope)
  (push (%sample session kind envelope) (input-session-prefix session))
  (%reduce session))

(defun %close (session kind envelope reason)
  (%append session kind envelope)
  (push (list :as kind :on reason) (input-session-closures session))
  (setf (input-session-status session) :closed))

(defun consume-envelope (session envelope)
  "Translate one ordered envelope. The caller guarantees the order."
  (let ((kind (transport-envelope-kind envelope)))
    (case kind
      (:pointer-down
       (unless (eq (input-session-status session) :active)
         (setf (input-session-status session) :active
               (input-session-prefix session) nil
               (input-session-held-mask session)
               (%mask-of (transport-envelope-which envelope))
               (input-session-origin session) (get-internal-real-time))
         (%append session :pointer-down envelope)))
      ((:pointer-up :pointer-cancel)
       (when (eq (input-session-status session) :active)
         (%close session kind envelope :browser-reported-release)))
      (:pointer-move
       (when (eq (input-session-status session) :active)
         (if (and (input-session-held-mask session)
                  (transport-envelope-buttons envelope)
                  (not (%held-p session envelope)))
             ;; The browser never reported a release. POINTER-UP out of
             ;; SECTOR-SELECTED means COMPLETED, which commits a Binding
             ;; and its operation identity; that is not warranted here.
             (%close session :pointer-cancel envelope
                     :initiating-button-no-longer-held)
             (%append session :pointer-move envelope))))
      (:reveal-deadline
       ;; Press-and-wait, as the browser observed it. Whether it reveals a
       ;; menu or is merely obsolete is the reducer's business and depends
       ;; only on where this envelope sits in the delivered order. A
       ;; deadline arriving after the session closed is dropped here, which
       ;; is why a cancelled timer needs no feedback from Lisp to the
       ;; browser: the adapter already refuses it.
       (when (eq (input-session-status session) :active)
         (%append session :reveal-deadline envelope)))
      (:lost-pointer-capture
       ;; Never terminal by itself. A host that releases capture on every
       ;; pointerup produces this on an ordinary completion too.
       (when (and (eq (input-session-status session) :active)
                  (input-session-held-mask session)
                  (transport-envelope-buttons envelope)
                  (not (%held-p session envelope)))
         (%close session :pointer-cancel envelope
                 :capture-lost-without-release)))))
  session)

;;; A witness for the Inspector

(defclass gesture-transport-witness ()
  ((transport :initarg :transport :reader witness-transport)
   (input :initarg :input :reader witness-input))
  (:documentation "One transport and the input session it feeds."))

(defun make-gesture-transport-witness ()
  (make-instance 'gesture-transport-witness
                 :transport (make-ordered-transport)
                 :input (make-gesture-input-session)))

(defun witness-state (witness)
  (let ((transport (witness-transport witness))
        (input (witness-input witness)))
    (list :callback-arrival (transport-arrival-order transport)
          :consumer-delivery (transport-delivery-order transport)
          :next-expected (transport-next-expected transport)
          :pending (transport-pending-sequences transport)
          :status (input-session-status input)
          :held-mask (input-session-held-mask input)
          :closures (reverse (input-session-closures input))
          :gesture (input-session-gesture-session input))))

(defun %envelope (sequence kind &key (x 0) (y 0) which buttons)
  (make-transport-envelope
   :sequence sequence :kind kind :x x :y y :which which :buttons buttons
   :target (list :type :lisp-source-definition :name 'gesture-transport)))

(defun %race-witness (kinds arrival)
  "Feed one ordered transport from a deliberately scrambled arrival.
KINDS is the browser order; ARRIVAL is the order the callback threads
happened to enqueue in. The two lists are kept apart in the witness so
the difference is readable rather than asserted."
  (let* ((witness (make-gesture-transport-witness))
         (transport (witness-transport witness))
         (input (witness-input witness))
         (envelopes
          (loop for (kind . arguments) in kinds
                for sequence from 1
                collect (apply #'%envelope sequence kind arguments))))
    (dolist (sequence arrival witness)
      (enqueue-envelope transport
                        (find sequence envelopes :key
                              #'transport-envelope-sequence))
      (drain-transport transport
                       (lambda (envelope) (consume-envelope input envelope))))))

(defun movement-wins-witness ()
  "The pointer left the dead zone before the browser reported the wait.
The deadline callback's own envelope arrives at Lisp before the move's,
which changes nothing: the queue releases them in browser order, so the
move makes a mark and the deadline is merely obsolete."
  (%race-witness
   '((:pointer-down :which 3 :buttons 2) (:pointer-move :x 20 :buttons 2)
     (:reveal-deadline :x 20 :buttons 2))
   '(1 3 2)))

(defun deadline-wins-witness ()
  "The same movement, after the browser reported that the wait elapsed.
Identical geometry to MOVEMENT-WINS-WITNESS; the only difference is where
the deadline sits in the browser's own order, and that is enough to select
a different Binding."
  (%race-witness
   '((:pointer-down :which 3 :buttons 2) (:reveal-deadline :x 0 :buttons 2)
     (:pointer-move :x 20 :buttons 2))
   '(1 3 2)))

(defun scrambled-expert-marking-witness ()
  "The expert marking trace, enqueued out of order and delivered in order.
The arrival list and the delivery list are both kept, so the difference
between them is readable rather than asserted."
  (let* ((witness (make-gesture-transport-witness))
         (transport (witness-transport witness))
         (input (witness-input witness))
         (envelopes (list (%envelope 1 :pointer-down :x 0 :y 0
                                       :which 3 :buttons 2)
                          (%envelope 2 :pointer-move :x 2 :y 0 :buttons 2)
                          (%envelope 3 :pointer-move :x 20 :y 0 :buttons 2)
                          (%envelope 4 :pointer-move :x 30 :y 0 :buttons 2)
                          (%envelope 5 :pointer-up :x 30 :y 0
                                       :which 3 :buttons 0))))
    (dolist (sequence '(1 3 2 5 4))
      (enqueue-envelope transport
                        (find sequence envelopes
                              :key #'transport-envelope-sequence))
      (drain-transport transport
                       (lambda (envelope) (consume-envelope input envelope))))
    witness))
