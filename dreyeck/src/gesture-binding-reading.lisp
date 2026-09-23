;;;; Reading the Gesture/Binding witness through the evidence it kept.
;;;;
;;;; Everything here is derived. The session's EVIDENCE-TRACE stays the
;;;; authority, is not rewritten, and every derived field carries the raw
;;;; entry it came from.
;;;;
;;;; The join is the order of the trace, not the timestamps in it. One
;;;; pointer-move can cross the dead zone and enter a sector in the same
;;;; sample, producing two transitions that share a timestamp, so a
;;;; timestamp-keyed table would silently merge them.

(defpackage #:dreyeck/gesture/reading
  (:use #:cl)
  (:local-nicknames (#:w #:dreyeck/gesture-binding-witness)
                    (#:sm #:dreyeck/state-machine))
  (:export #:gesture-session-reading
           #:reading-record-effects
           #:disabled-then-enabled-session
           #:obsolete-deadline-session))

(in-package #:dreyeck/gesture/reading)

(dreyeck/hyperdoc:defhyperdoc *gesture-reading*
  :title "Falsifying a Gesture/Binding Witness"
  :id "dreyeck/gesture/reading"
  :asdf-system-name "dreyeck/gesture/reading"
  :subdirectory "dreyeck/pages/gesture"
  :code-subdirectory "dreyeck/src"
  :main-page-id "Falsifying a Gesture/Binding Witness")

(hyperdoc:see (hyperdoc:page "Falsifying a Gesture/Binding Witness"))

(defun %transition-detail (detail)
  "What a transition's DETAIL says, by the shapes the witness writes.
The reducer stores whatever was most informative at the point of the
transition, so the case distinction belongs here, in the reading layer,
rather than in the trace. A shape that is not recognised is carried
through untouched instead of being dropped or renamed."
  (cond ((null detail) nil)
        ((keywordp detail) (list :reason detail))
        ((typep detail 'w:gesture-binding)
         (list :binding-id (w:gesture-binding-id detail)))
        ((and (consp detail) (getf detail :binding))
         (list :binding-id (w:gesture-binding-id (getf detail :binding))
               :angle (getf detail :angle)))
        ((and (consp detail) (getf detail :type))
         (list :target-type (getf detail :type)))
        (t (list :detail detail))))

(defun %observation-detail (entry)
  "An observation names its own reason; only its DETAIL needs reading."
  (let ((reason (getf entry :reason))
        (detail (getf entry :detail)))
    (append (list :reason reason)
            (cond ((null detail) nil)
                  ((eq :disabled-sector-entered reason)
                   (list :binding-id detail))
                  (t (list :detail detail))))))

(defun %effect (entry state)
  "One effect of the input that is being read, beside its raw entry."
  (ecase (getf entry :kind)
    (:transient-gesture-transition
     (append (list :disposition :transition
                   :transition (getf entry :transition-id)
                   :state-after (getf entry :state-id))
             (%transition-detail (getf entry :detail))
             (list :evidence entry)))
    (:observation-without-transition
     (append (list :disposition :observation
                   :state-after state)
             (%observation-detail entry)
             (list :evidence entry)))))

(defun gesture-session-reading (session)
  "One derived record per delivered input sample.
Each record is (:SAMPLE s :STATE-BEFORE b :EFFECTS (...) :STATE-AFTER a
:EVIDENCE raw). An input that changed nothing has effects too; that is
the point of reading the trace rather than the outcome."
  (let ((state nil) (record nil) (records nil))
    (labels ((close-record ()
               (when record
                 (push (append record (list :state-after state)) records)
                 (setf record nil))))
      (dolist (entry (sm:state-machine-run-evidence-trace-of session))
        (case (getf entry :kind)
          (:state-entry
           (setf state (getf entry :state-id)))
          (:synthetic-input-sample
           (close-record)
           (setf record (list :sample (getf entry :sample)
                              :state-before state
                              :effects nil
                              :evidence entry)))
          (t
           (let ((effect (%effect entry state)))
             (setf (getf record :effects)
                   (append (getf record :effects) (list effect)))
             (when (eq :transition (getf effect :disposition))
               (setf state (getf effect :state-after)))))))
      (close-record))
    (nreverse records)))

(defun reading-record-effects (record)
  (getf record :effects))

;;; The sessions the page reads

(defun %target ()
  (list :type :lisp-source-definition :name 'gesture-binding-witness))

(defun %down ()
  (w:make-gesture-input-sample :kind :pointer-down :target (%target)
                               :x 0.0d0 :y 0.0d0 :button :secondary
                               :timestamp 0))

(defun %at (kind x y timestamp)
  (w:make-gesture-input-sample :kind kind :x (float x 1.0d0) :y (float y 1.0d0)
                               :timestamp timestamp))

(defun disabled-then-enabled-session ()
  "The counterexample that falsified the first witness.
The pointer crosses the disabled sector on its way to an enabled one and
releases there."
  (w:run-gesture-trace
   (list (%down)
         (w:make-gesture-input-sample :kind :reveal-deadline :timestamp 500)
         (%at :pointer-move -20 0 600)
         (%at :pointer-move 20 0 700)
         (%at :pointer-up 20 0 720))))

(defun obsolete-deadline-session ()
  "A reveal deadline delivered after marking has already begun.
The timer is a real environment event, so it arrives whatever the
recognizer is doing; it is consumed and recorded, and changes nothing."
  (w:run-gesture-trace
   (list (%down)
         (%at :pointer-move 20 0 100)
         (w:make-gesture-input-sample :kind :reveal-deadline :timestamp 500)
         (%at :pointer-up 20 0 520))))

(hyperdoc:defexample expert-marking-reading
  (gesture-session-reading (w:make-expert-marking-trace)))

(hyperdoc:defexample disabled-then-enabled-reading
  (gesture-session-reading (disabled-then-enabled-session)))
