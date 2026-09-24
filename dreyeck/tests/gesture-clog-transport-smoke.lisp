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
  (let ((script (t*:forwarding-script "HOST")))
    (assert (search "e.buttons" script))
    (assert (search "__gestureSeq" script))
    ;; The counter runs over exactly the forwarded kinds.
    (assert (= 5 (length (t*:transport-event-kinds))))
    (assert (null (assoc "contextmenu" (t*:transport-event-kinds)
                         :test #'string=))))
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

(defun run-gesture-transport-tests ()
  (test-unordered-arrival-is-delivered-in-order)
  (test-contiguous-blocking)
  (test-enqueue-does-not-touch-the-session)
  (test-real-pointer-up-completes)
  (test-vanished-button-cancels)
  (test-capture-loss-alone-is-not-terminal)
  (test-concurrent-enqueue-has-no-terminal-race)
  (test-browser-bridge-contract)
  (test-witness)
  (test-created-source-authorities)
  (format t "~&GESTURE-TRANSPORT-PASS: out-of-order arrival delivered in ~
browser order, a missing sequence blocks the ones behind it, only the ~
consumer mutates, a real release completes and a vanished button cancels.~%")
  t)
