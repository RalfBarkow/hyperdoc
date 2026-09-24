;;;; Reading the two continuations of one interaction.
;;;;
;;;; Kurtenbach and Buxton describe a single interaction that can end as
;;;; a mark or as a menu selection, and report that the two are not
;;;; separate modes the user chooses in advance. What decides it, in this
;;;; repository, is an order: whether a qualifying move or the report of
;;;; an elapsed wait reaches the reducer first.
;;;;
;;;; Nothing here recognises anything. Every value is read back from an
;;;; object the transport and the reducer already produced, so the page
;;;; that uses it shows evidence rather than a retelling.

(defpackage #:dreyeck/gesture/ordering
  (:use #:cl)
  (:local-nicknames (#:w #:dreyeck/gesture-binding-witness)
                    (#:t* #:dreyeck/gesture/transport)
                    (#:r #:dreyeck/gesture/reading)
                    (#:sm #:dreyeck/state-machine))
  (:export #:race-reading
           #:two-authorities-session))

(in-package #:dreyeck/gesture/ordering)

(defun %binding-id (session)
  (let ((binding (w:gesture-session-selected-binding-of session)))
    (and binding (w:gesture-binding-id binding))))

(defun %operation-id (session)
  (let ((operation (w:gesture-session-selected-operation-of session)))
    (and operation (w:semantic-operation-identity-id operation))))

(defun race-reading (witness)
  "What distinguishes the two continuations, read from one race witness.
Three orders are kept apart because they are three different facts. The
sequence numbers are what the browser assigned; CALLBACK-ARRIVAL is the
order the host's per-event threads happened to enqueue in; and
CONSUMER-DELIVERY is what the queue released. Only the last of these
reached the reducer, and the reducer's own rule is that delivered order
is authoritative.

The Binding and the Operation identity are reported separately on
purpose. Two runs of identical geometry select different Bindings here,
and both Bindings reference the same object."
  (let* ((state (t*:witness-state witness))
         (session (getf state :gesture)))
    (list :callback-arrival (getf state :callback-arrival)
          :consumer-delivery (getf state :consumer-delivery)
          :delivered-kinds (mapcar #'w:gesture-input-sample-kind
                                   (sm:state-machine-run-input-of session))
          :state (sm:state-machine-run-current-state-of session)
          :mode (w:gesture-session-mode-of session)
          :menu-visible-p (w:gesture-session-menu-visible-p-of session)
          :binding (%binding-id session)
          :operation (%operation-id session)
          :operation-is-the-shared-identity
          (eq (w:gesture-session-selected-operation-of session)
              (w:insert-executable-defexample-operation))
          :records (r:gesture-session-reading session))))

(defun %envelope (sequence kind &key (x 0) which)
  (t*:make-transport-envelope
   :sequence sequence :kind kind :x x :y 0 :which which :buttons 2
   :target (list :type :lisp-source-definition :name 'gesture-ordering)))

(defun two-authorities-session ()
  "Two sequencing authorities offered to one transport, and what survives.
Source A presses and moves. Source B is a different browsing context
holding its own counter, so it also starts at one. The numbers agree and
the authorities do not, and nothing in an envelope says which page it
came from -- deliberately, because the remedy is not to label the
envelopes but to keep the streams apart.

Each offer is reported with its outcome. The refusals carry the number
that was repeated and what already stood in its place; what is left
afterwards is source A's own order, unmixed."
  (let* ((witness (t*:make-gesture-transport-witness))
         (transport (t*:witness-transport witness))
         (input (t*:witness-input witness))
         (offered (list (list :a (%envelope 1 :pointer-down :which 3))
                        (list :b (%envelope 1 :pointer-down :which 3))
                        (list :a (%envelope 2 :pointer-move :x 20))
                        (list :b (%envelope 2 :reveal-deadline))))
         (outcomes nil))
    (dolist (entry offered)
      (destructuring-bind (source envelope) entry
        (push (list* :source source
                     :sequence (t*:transport-envelope-sequence envelope)
                     :kind (t*:transport-envelope-kind envelope)
                     (handler-case
                         (progn
                           (t*:enqueue-envelope transport envelope)
                           (t*:drain-transport
                            transport
                            (lambda (delivered)
                              (t*:consume-envelope input delivered)))
                           (list :outcome :accepted))
                       (t*::duplicate-transport-sequence (violation)
                         (list :outcome :refused
                               :next-expected
                               (t*::duplicate-sequence-next-expected violation)
                               :already-present
                               (t*::duplicate-sequence-present-kind violation)))))
              outcomes)))
    (let ((session (t*:input-session-gesture-session input)))
      (list :offered (reverse outcomes)
            :callback-arrival (t*:transport-arrival-order transport)
            :consumer-delivery (t*:transport-delivery-order transport)
            :surviving-samples (mapcar #'w:gesture-input-sample-kind
                                       (sm:state-machine-run-input-of session))
            :mode (w:gesture-session-mode-of session)
            :binding (%binding-id session)))))

(hyperdoc:defexample movement-wins-reading
  (race-reading (t*::movement-wins-witness)))

(hyperdoc:defexample deadline-wins-reading
  (race-reading (t*::deadline-wins-witness)))

(hyperdoc:defexample two-authorities-reading
  (two-authorities-session))
