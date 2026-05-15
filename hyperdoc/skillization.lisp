;;;; Skillization definition objects for HyperDoc
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defclass skill-pattern-step ()
  ((kind :reader skill-pattern-step-kind-of
         :initarg :kind)
   (title :reader title-of
          :initarg :title)
   (purpose :reader skill-pattern-step-purpose-of
            :reader summary-of
            :initarg :purpose
            :initform nil)
   (touched-pages :reader skill-pattern-step-touched-pages-of
                  :initarg :touched-pages
                  :initform nil)
   (topic-growth-allowed-p
    :reader skill-pattern-step-topic-growth-allowed-p-of
    :initarg :topic-growth-allowed-p
    :initform nil)))

(defclass conceptual-center-step (skill-pattern-step) ())

(defclass discoverability-propagation-step (skill-pattern-step) ())

(defclass skill-pattern-definition ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (concept-page :reader skill-pattern-concept-page-of
                 :initarg :concept-page)
   (propagation-target-pages
    :reader skill-pattern-propagation-target-pages-of
    :initarg :propagation-target-pages
    :initform nil)
   (acceptance-rule :reader skill-pattern-acceptance-rule-of
                    :initarg :acceptance-rule
                    :initform nil)
   (boundaries :reader skill-pattern-boundaries-of
               :initarg :boundaries
               :initform nil)
   (steps :reader skill-pattern-steps-of
          :initarg :steps
          :initform nil)))

(defmethod print-object ((object skill-pattern-step) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object skill-pattern-definition) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defun make-conceptual-center-step
    (&key
       (title "Conceptual center")
       purpose
       touched-pages
       (topic-growth-allowed-p t))
  (make-instance 'conceptual-center-step
                 :kind :conceptual-center
                 :title title
                 :purpose purpose
                 :touched-pages touched-pages
                 :topic-growth-allowed-p topic-growth-allowed-p))

(defun make-discoverability-propagation-step
    (&key
       (title "Discoverability propagation")
       purpose
       touched-pages
       (topic-growth-allowed-p nil))
  (make-instance 'discoverability-propagation-step
                 :kind :discoverability-propagation
                 :title title
                 :purpose purpose
                 :touched-pages touched-pages
                 :topic-growth-allowed-p topic-growth-allowed-p))

(defun make-skill-pattern-definition
    (&key id title summary concept-page propagation-target-pages
       acceptance-rule boundaries steps)
  (make-instance 'skill-pattern-definition
                 :id id
                 :title title
                 :summary summary
                 :concept-page concept-page
                 :propagation-target-pages propagation-target-pages
                 :acceptance-rule acceptance-rule
                 :boundaries boundaries
                 :steps steps))

(defun docs-only-skill-pattern-p (pattern)
  (not (null (member :docs-only
                     (skill-pattern-boundaries-of pattern)
                     :test #'eq))))

(defun discoverability-only-step-p (step)
  (and (typep step 'discoverability-propagation-step)
       (not (skill-pattern-step-topic-growth-allowed-p-of step))))

(defun skill-pattern-has-topic-growth-p (pattern)
  (some #'skill-pattern-step-topic-growth-allowed-p-of
        (skill-pattern-steps-of pattern)))

(defun skill-pattern-page-titles (pattern)
  (remove-duplicates
   (append (and (skill-pattern-concept-page-of pattern)
                (list (skill-pattern-concept-page-of pattern)))
           (skill-pattern-propagation-target-pages-of pattern)
           (mapcan #'skill-pattern-step-touched-pages-of
                   (skill-pattern-steps-of pattern)))
   :test #'string=))

(defun skill-pattern-step-summary-alist (step)
  (list (cons :kind (skill-pattern-step-kind-of step))
        (cons :title (title-of step))
        (cons :purpose (skill-pattern-step-purpose-of step))
        (cons :touched-pages (skill-pattern-step-touched-pages-of step))
        (cons :topic-growth-allowed-p
              (skill-pattern-step-topic-growth-allowed-p-of step))))

(defun skill-pattern-summary-alist (pattern)
  (list (cons :id (id-of pattern))
        (cons :title (title-of pattern))
        (cons :summary (summary-of pattern))
        (cons :concept-page (skill-pattern-concept-page-of pattern))
        (cons :propagation-target-pages
              (skill-pattern-propagation-target-pages-of pattern))
        (cons :acceptance-rule (skill-pattern-acceptance-rule-of pattern))
        (cons :boundaries (skill-pattern-boundaries-of pattern))
        (cons :docs-only-p (docs-only-skill-pattern-p pattern))
        (cons :has-topic-growth-p (skill-pattern-has-topic-growth-p pattern))
        (cons :page-titles (skill-pattern-page-titles pattern))
        (cons :steps
              (mapcar #'skill-pattern-step-summary-alist
                      (skill-pattern-steps-of pattern)))))

(defun make-route-language-skill-pattern-definition ()
  (make-skill-pattern-definition
   :id "skill-pattern/route-language-assimilation"
   :title "Route-language assimilation skill pattern"
   :summary
   "Docs-first HyperDoc pattern in which a conceptual center lands first and a later discoverability slice adds one-click propagation from adjacent surfaces without reopening architecture."
   :concept-page "Iconic route language in HyperDoc"
   :propagation-target-pages
   '("Dock capabilities in HyperDoc"
     "Dock presentation state model")
   :acceptance-rule
   "A reader arriving from Dock / inspection surfaces can discover the route-as-retrieval reading in one click, without architectural change or topic growth."
   :boundaries
   '(:docs-only
     :conceptual-center-first
     :discoverability-second
     :propagation-no-topic-growth
     :runtime-follow-up-optional)
   :steps
   (list
    (make-conceptual-center-step
     :purpose
     "Land the local editorial center in HyperDoc's own language and add the minimum new pages and topics needed to make the imported concept durable."
     :touched-pages
     '("Iconic route language in HyperDoc"
       "Focused semantic source stations"
       "Symbols and semantics in Mind and Mechanism")
     :topic-growth-allowed-p t)
    (make-discoverability-propagation-step
     :purpose
     "Add one-click orientation cues from adjacent Dock/inspection surfaces to the new conceptual center while keeping the propagation slice docs-only and conservative."
     :touched-pages
     '("Dock capabilities in HyperDoc"
       "Dock presentation state model")
     :topic-growth-allowed-p nil))))
