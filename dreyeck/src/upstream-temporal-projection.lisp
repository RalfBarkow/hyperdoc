;;;; The page-loading history as a Topicmap, and that Topicmap as D2.
;;
;; Four projections of one subject, and the order of authority matters.
;;
;;     history observations    the frozen Git facts and their attributions
;;     Topicmap projection     those facts as topics and associations
;;     D2 source               that projection as text
;;     TALA layout             that text given positions
;;
;; Authority runs left to right and never back. The diagram is a reading
;; of the Topicmap; the Topicmap is a reading of the history. Nothing is
;; typed in twice: every topic, every association and every interval
;; here is computed from the observations that already exist, so a
;; drifting record cannot leave a stale picture behind.
;;
;; Two things are deliberately not in the diagram.
;;
;; The intervals are not. They are the finding the dates were added for
;; — five hundred and forty-two days, then twenty-five seconds — and a
;; graph layout would have to either ignore them or imply a metric it
;; does not have. They are shown beside the diagram instead, as numbers,
;; which is the representation that can be checked.
;;
;; Grouping is not. Mechanism and contract are properties of the
;; records, so they are carried as topics with ordinary relation
;; associations rather than as D2 containers. The layer is then true in
;; the Topicmap, where it can be inspected, instead of being true only
;; because a renderer drew a box around something.

(defpackage #:dreyeck/upstream-intake/temporal
  (:use #:cl)
  (:local-nicknames (#:tm #:dreyeck/topicmap)
                    (#:tala #:dreyeck/topicmap/tala)
                    (#:intake #:dreyeck/upstream-intake))
  (:export #:page-loading-history #:make-page-loading-history
           #:page-loading-history-topic-ids
           #:page-loading-temporal-intervals
           #:page-loading-interval-text
           #:page-loading-history-example
           #:page-loading-history-workspace-example
           #:page-loading-d2-source-example
           #:page-loading-temporal-intervals-example
           #:page-loading-tala-rendering-example))

(in-package #:dreyeck/upstream-intake/temporal)

(hyperdoc:see
  (hyperdoc:page "Page-Loading Contract Evolution"))

;;
;; The subject
;;

(defclass page-loading-history ()
  ()
  (:documentation
   "A handle for the observed page-loading history, so it can be projected.

It holds nothing. Everything it stands for is already in the history
layer, and copying any of it into a slot would create a second place for
the same fact to live and a second place for it to go stale. The class
exists because TOPICMAP-PROJECTION-OF dispatches on an object, and this
history had none."))

(defun make-page-loading-history () (make-instance 'page-loading-history))

(defmethod print-object ((object page-loading-history) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~D observed states" (length (intake:page-loading-history-states)))))

;;
;; Identities
;;
;; A commit topic uses the id this repository already gives commits, so
;; the same commit is the same topic here as in every other projection.
;; The invented ids below are for things that have no object of their
;; own — a layer, an attributed capability — and say what they are.
;;

(defun %commit-topic-id (reference)
  (format nil "git-commit:~A" reference))

(defun %layer-topic-id (layer)
  (format nil "page-loading-layer:~(~A~)" layer))

(defun %capability-topic-id (label)
  (format nil "page-loading-capability:~A" label))

(defun page-loading-history-topic-ids ()
  "Every topic id this projection uses, without building the projection."
  (let ((states (intake:page-loading-history-states)))
    (append (mapcar (lambda (state) (%commit-topic-id (getf state :reference)))
                    states)
            (mapcar #'%layer-topic-id
                    (remove-duplicates (mapcar (lambda (state) (getf state :layer))
                                               states)))
            (mapcar (lambda (attribution)
                      (%capability-topic-id (getf attribution :label)))
                    (intake:page-loading-capability-attributions)))))

;;
;; The projection
;;

(defun %commit-topic (state)
  (tm:make-topicmap-topic
   :id (%commit-topic-id (getf state :reference))
   :type :git-commit
   ;; Eight characters, because a diagram that prints forty is unreadable
   ;; and the full hash is one inspection away on the object below.
   :label (subseq (getf state :reference) 0 8)
   :object (intake:page-loading-history-commit (getf state :reference))))

(defun %layer-topic (layer)
  (tm:make-topicmap-topic
   :id (%layer-topic-id layer)
   :type :page-loading-layer
   :label (string-downcase (symbol-name layer))
   :object layer))

(defun %capability-topic (attribution)
  (tm:make-topicmap-topic
   :id (%capability-topic-id (getf attribution :label))
   :type :page-loading-capability
   :label (format nil "~A ~(~A~)" (getf attribution :label)
                  (getf attribution :capability))
   :object attribution))

(defmethod tm:topicmap-projection-of ((history page-loading-history))
  "Project the observed history: states, the layers they fall in, what they
established.

The three association types are three different claims and stay apart.
ANCESTOR-OF is observed from Git. IN-LAYER restates a field of the
frozen record. ESTABLISHES is an attribution, interpreted, and the
capability topics carry the attributions themselves so a reader who
follows one arrives at the basis rather than at a label."
  (let* ((states (intake:page-loading-history-states))
         (attributions (intake:page-loading-capability-attributions))
         (layers (remove-duplicates (mapcar (lambda (state) (getf state :layer))
                                            states)))
         (references (mapcar (lambda (state) (getf state :reference)) states)))
    ;; An attribution pointing outside the projected states would draw an
    ;; edge to a topic that is not there. Refuse rather than draw it.
    (dolist (attribution attributions)
      (unless (member (getf attribution :established-by) references :test #'string=)
        (error "Capability ~S is established by ~S, which is not among the ~
observed states." (getf attribution :label)
               (getf attribution :established-by))))
    (tm:make-topicmap-projection
     :source history
     :topics (append (mapcar #'%commit-topic states)
                     (mapcar #'%layer-topic layers)
                     (mapcar #'%capability-topic attributions))
     :associations
     (append
      ;; Ancestry, in the order the history layer already checked against
      ;; Git. Consecutive pairs only: the chain is what was verified.
      (loop for (state next) on states
            while next
            collect (tm:make-topicmap-association
                     :id (format nil "page-loading-ancestry:~A:~A"
                                 (getf state :reference) (getf next :reference))
                     :type :ancestor-of
                     :from (%commit-topic-id (getf state :reference))
                     :to (%commit-topic-id (getf next :reference))))
      (mapcar (lambda (state)
                (tm:make-topicmap-association
                 :id (format nil "page-loading-layer-membership:~A"
                             (getf state :reference))
                 :type :in-layer
                 :from (%commit-topic-id (getf state :reference))
                 :to (%layer-topic-id (getf state :layer))))
              states)
      (mapcar (lambda (attribution)
                (tm:make-topicmap-association
                 :id (format nil "page-loading-establishes:~A"
                             (getf attribution :label))
                 :type :establishes
                 :from (%commit-topic-id (getf attribution :established-by))
                 :to (%capability-topic-id (getf attribution :label))))
              attributions))
     :view-properties
     (list :presentation :page-loading-contract-evolution
           :point (%commit-topic-id (getf (first (last states)) :reference))
           :width 1200 :height 720))))

;;
;; The intervals, beside the diagram and not inside it
;;

(defun page-loading-interval-text (seconds)
  "Say a duration at the coarsest unit that does not hide what it is.

Twenty-five seconds and five hundred and forty-two days both occur in
this history, so one unit cannot serve. The exact count travels beside
this text rather than being replaced by it."
  (cond ((null seconds) nil)
        ((< seconds 90) (format nil "~D s" seconds))
        ((< seconds 5400) (format nil "~D min" (round seconds 60)))
        ((< seconds 172800) (format nil "~D h" (round seconds 3600)))
        (t (format nil "~D days" (round seconds 86400)))))

(defun page-loading-temporal-intervals ()
  "The gaps between consecutive states, derived from the observed dates.

Derived, and marked so. The dates and the ancestry are observed; a
subtraction of two observed instants is neither a new observation nor an
interpretation, and calling it either would misfile it."
  (let ((states (intake:page-loading-history-states)))
    (list :kind :temporal-intervals
          :states-are-in-date-order-p (intake:page-loading-states-in-date-order-p)
          :steps
          (loop for (state next) on states
                while next
                collect (list :from (getf state :reference)
                              :to (getf next :reference)
                              :from-authored-at (getf state :authored-at)
                              :to-authored-at (getf next :authored-at)
                              :seconds (getf state :seconds-to-next)
                              :text (page-loading-interval-text
                                     (getf state :seconds-to-next))))
          :dates :observed
          :ancestry :observed
          :intervals :derived
          :evidence-status :observed)))

;;
;; Reading
;;

(hyperdoc:defexample page-loading-history-example
  "The observed page-loading history as one inspectable subject."
  (make-page-loading-history))

(hyperdoc:defexample page-loading-history-workspace-example
  "The same history as a Workspace, navigable by its native Topic signs."
  (tm::make-topicmap-workspace-for-object (make-page-loading-history)))

(hyperdoc:defexample page-loading-d2-source-example
  "The D2 text this projection serializes to, with its identity maps.

Ordinary D2: one line per topic, one per association. The identifiers
are the encoded Topic ids, so a label can be changed without changing
what anything is."
  (tala:projection-tala-input
   (tm:topicmap-projection-of (make-page-loading-history))))

(hyperdoc:defexample page-loading-temporal-intervals-example
  "How far apart the states are, which the diagram deliberately does not say."
  (page-loading-temporal-intervals))

(hyperdoc:defexample page-loading-tala-rendering-example
  "The projection laid out by TALA, as a non-interactive image.

The SVG is rendered and its identity coverage validated, and that is
all: no node carries a link or an action. Navigation is the native Topic
signs and the examples beside it, which lead to the real objects rather
than to a picture of them.

D2 is pinned and is not on every runtime, so an absent one is reported
as what it is instead of signalling into a page."
  (let ((dependency (tala:tala-dependency-status)))
    (if (eq :available (getf dependency :status))
        (tala:run-tala (tala:projection-tala-input
                        (tm:topicmap-projection-of (make-page-loading-history))))
        (list :kind :tala-unavailable
              :dependency dependency
              :why "this runtime has no pinned D2 with the bundled TALA engine"
              :remedy "nix develop .#tala"
              :evidence-status :observed))))

(dreyeck/hyperdoc:defhyperdoc *page-loading-contract-evolution*
  :id "dreyeck/upstream-intake/temporal"
  :title "Page-Loading Contract Evolution"
  :asdf-system-name "dreyeck/upstream-intake/temporal"
  :subdirectory "dreyeck/pages/upstream-temporal"
  :main-page-id "Page-Loading Contract Evolution")
