;;;; Inspectable iconic retrieval objects for HyperDoc
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defclass world-state-proxy ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (evidence-pages :reader world-state-proxy-evidence-pages-of
                   :initarg :evidence-pages
                   :initform nil)
   (source-kind :reader world-state-proxy-source-kind-of
                :initarg :source-kind
                :initform :grounded-semantic-state)
   (temporal-note :reader world-state-proxy-temporal-note-of
                  :initarg :temporal-note
                  :initform nil)))

(defclass linguistic-retrieval-cue ()
  ((id :reader id-of
       :initarg :id)
   (cue-text :reader linguistic-retrieval-cue-text-of
             :initarg :cue-text)
   (symbolic-role :reader linguistic-retrieval-cue-symbolic-role-of
                  :initarg :symbolic-role
                  :initform :retrieval-trigger)
   (related-pages :reader linguistic-retrieval-cue-related-pages-of
                  :initarg :related-pages
                  :initform nil)
   (modality :reader linguistic-retrieval-cue-modality-of
             :initarg :modality
             :initform :linguistic)))

(defclass iconic-state-trajectory ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (states :reader iconic-state-trajectory-states-of
           :initarg :states
           :initform nil)
   (transitions :reader iconic-state-trajectory-transitions-of
                :initarg :transitions
                :initform nil)
   (interpretation-note :reader iconic-state-trajectory-interpretation-note-of
                        :initarg :interpretation-note
                        :initform nil)
   (case-role-note :reader iconic-state-trajectory-case-role-note-of
                   :initarg :case-role-note
                   :initform nil)))

(defclass iconic-state-definition ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (world-state-proxy :reader iconic-state-world-state-proxy-of
                      :initarg :world-state-proxy
                      :initform nil)
   (sensory-pattern-note :reader iconic-state-sensory-pattern-note-of
                         :initarg :sensory-pattern-note
                         :initform nil)
   (grounded-p :reader iconic-state-grounded-p-of
               :initarg :grounded-p
               :initform t)
   (reentrant-p :reader iconic-state-reentrant-p-of
                :initarg :reentrant-p
                :initform nil)
   (modalities :reader iconic-state-modalities-of
               :initarg :modalities
               :initform nil)
   (cue-set :reader iconic-state-cue-set-of
            :initarg :cue-set
            :initform nil)
   (trajectory :reader iconic-state-trajectory-of
               :initarg :trajectory
               :initform nil)
   (grounding-note :reader iconic-state-grounding-note-of
                   :initarg :grounding-note
                   :initform nil)))

(defclass reentrant-iconic-state (iconic-state-definition) ())

(defclass early-processing-stage ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (functions :reader early-processing-stage-functions-of
              :initarg :functions
              :initform nil)
   (modalities :reader early-processing-stage-modalities-of
               :initarg :modalities
               :initform nil)
   (pre-fashioned-p :reader early-processing-stage-pre-fashioned-p-of
                    :initarg :pre-fashioned-p
                    :initform t)))

(defclass iconic-retrieval-route ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (cue :reader iconic-retrieval-route-cue-of
        :initarg :cue
        :initform nil)
   (source-state :reader iconic-retrieval-route-source-state-of
                 :initarg :source-state
                 :initform nil)
   (iconic-state :reader iconic-retrieval-route-iconic-state-of
                 :initarg :iconic-state
                 :initform nil)
   (retrieval-mode :reader iconic-retrieval-route-retrieval-mode-of
                   :initarg :retrieval-mode
                   :initform :symbolic-to-grounded)
   (trajectory :reader iconic-retrieval-route-trajectory-of
               :initarg :trajectory
               :initform nil)
   (inspectable-path :reader iconic-retrieval-route-inspectable-path-of
                     :initarg :inspectable-path
                     :initform nil)
   (lay-label :reader iconic-retrieval-route-lay-label-of
              :initarg :lay-label
              :initform "Lay route")
   (follow-label :reader iconic-retrieval-route-follow-label-of
                 :initarg :follow-label
                 :initform "Follow route")))

(defclass neural-state-machine-model-definition ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (early-processing :reader neural-state-machine-model-early-processing-of
                     :initarg :early-processing
                     :initform nil)
   (symbolic-cues :reader neural-state-machine-model-symbolic-cues-of
                  :initarg :symbolic-cues
                  :initform nil)
   (iconic-states :reader neural-state-machine-model-iconic-states-of
                  :initarg :iconic-states
                  :initform nil)
   (trajectories :reader neural-state-machine-model-trajectories-of
                 :initarg :trajectories
                 :initform nil)
   (motor-action-note :reader neural-state-machine-model-motor-action-note-of
                      :initarg :motor-action-note
                      :initform nil)
   (dual-operation-note :reader neural-state-machine-model-dual-operation-note-of
                        :initarg :dual-operation-note
                        :initform nil)
   (grounding-claim :reader neural-state-machine-model-grounding-claim-of
                    :initarg :grounding-claim
                    :initform nil)))

(defclass multimodal-association-example ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (world-state-proxy :reader multimodal-association-example-world-state-proxy-of
                      :initarg :world-state-proxy)
   (iconic-state :reader multimodal-association-example-iconic-state-of
                 :initarg :iconic-state)
   (cues :reader multimodal-association-example-cues-of
         :initarg :cues
         :initform nil)
   (routes :reader multimodal-association-example-routes-of
           :initarg :routes
           :initform nil)
   (trajectory :reader multimodal-association-example-trajectory-of
               :initarg :trajectory
               :initform nil)
   (nsmm :reader multimodal-association-example-nsmm-of
         :initarg :nsmm
         :initform nil)
   (motor-action-note :reader multimodal-association-example-motor-action-note-of
                      :initarg :motor-action-note
                      :initform nil)
   (association-note :reader multimodal-association-example-association-note-of
                     :initarg :association-note
                     :initform nil)))

(defclass case-role-trajectory-example ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (sentence-variants :reader case-role-trajectory-example-sentence-variants-of
                      :initarg :sentence-variants
                      :initform nil)
   (routes :reader case-role-trajectory-example-routes-of
           :initarg :routes
           :initform nil)
   (trajectories :reader case-role-trajectory-example-trajectories-of
                 :initarg :trajectories
                 :initform nil)
   (nsmm :reader case-role-trajectory-example-nsmm-of
         :initarg :nsmm
         :initform nil)
   (distinction-note :reader case-role-trajectory-example-distinction-note-of
                     :initarg :distinction-note
                     :initform nil)))

(defun iconic-retrieval--ensure-list (value)
  (cond ((null value) nil)
        ((listp value) value)
        (t (list value))))

(defun iconic-retrieval--cue-texts (cues)
  (loop for cue in cues
        when cue
        collect (if (typep cue 'linguistic-retrieval-cue)
                    (linguistic-retrieval-cue-text-of cue)
                    cue)))

(defun iconic-retrieval--titles (objects)
  (loop for object in objects
        for title = (cond ((null object) nil)
                          ((stringp object) object)
                          ((ignore-errors (title-of object))))
        when title
        collect title))

(defun iconic-retrieval--grounded-mode-p (mode)
  (member mode
          '(:grounded
            :grounded-retrieval
            :symbolic-to-grounded
            :symbolic-and-grounded)
          :test #'eq))

(defun iconic-retrieval--push-page-titles (target titles)
  (dolist (title titles target)
    (when (and (stringp title)
               (plusp (length title)))
      (pushnew title target :test #'string=))))

(defun iconic-retrieval--route-sequence (object)
  (typecase object
    (iconic-retrieval-route
     (list object))
    (multimodal-association-example
     (multimodal-association-example-routes-of object))
    (case-role-trajectory-example
     (case-role-trajectory-example-routes-of object))
    (list
     (loop for item in object
           append (iconic-retrieval--route-sequence item)))
    (otherwise nil)))

(defun iconic-retrieval--cue-matches-p (cue-spec cue)
  (cond ((typep cue-spec 'linguistic-retrieval-cue)
         (eq cue-spec cue))
        ((stringp cue-spec)
         (string-equal cue-spec (linguistic-retrieval-cue-text-of cue)))
        ((symbolp cue-spec)
         (string-equal (symbol-name cue-spec)
                       (linguistic-retrieval-cue-text-of cue)))
        (t nil)))

(defmethod title-of ((cue linguistic-retrieval-cue))
  (linguistic-retrieval-cue-text-of cue))

(defmethod summary-of ((cue linguistic-retrieval-cue))
  (format nil
          "Symbolic cue with modality ~A that can start a retrieval route into grounded/iconic state."
          (linguistic-retrieval-cue-modality-of cue)))

(defmethod summary-of ((trajectory iconic-state-trajectory))
  (or (iconic-state-trajectory-interpretation-note-of trajectory)
      (format nil
              "Trajectory with ~D states and ~D transitions."
              (length (iconic-state-trajectory-states-of trajectory))
              (length (iconic-state-trajectory-transitions-of trajectory)))))

(defmethod summary-of ((route iconic-retrieval-route))
  (format nil
          "Retrieval route from cue ~A to grounded/iconic state ~A."
          (title-of (iconic-retrieval-route-cue-of route))
          (title-of (iconic-retrieval-route-iconic-state-of route))))

(defmethod print-object ((object world-state-proxy) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object linguistic-retrieval-cue) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object iconic-state-trajectory) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object iconic-state-definition) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object early-processing-stage) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object iconic-retrieval-route) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object neural-state-machine-model-definition) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object multimodal-association-example) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object case-role-trajectory-example) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defun make-world-state-proxy
    (&key id title summary evidence-pages
       (source-kind :grounded-semantic-state)
       temporal-note)
  (make-instance 'world-state-proxy
                 :id id
                 :title title
                 :summary summary
                 :evidence-pages (copy-list (iconic-retrieval--ensure-list
                                             evidence-pages))
                 :source-kind source-kind
                 :temporal-note temporal-note))

(defun make-linguistic-retrieval-cue
    (&key id cue-text (symbolic-role :retrieval-trigger)
       related-pages (modality :linguistic))
  (make-instance 'linguistic-retrieval-cue
                 :id id
                 :cue-text cue-text
                 :symbolic-role symbolic-role
                 :related-pages (copy-list (iconic-retrieval--ensure-list
                                            related-pages))
                 :modality modality))

(defun make-iconic-state-trajectory
    (&key id title states transitions interpretation-note case-role-note)
  (make-instance 'iconic-state-trajectory
                 :id id
                 :title title
                 :states (copy-list (iconic-retrieval--ensure-list states))
                 :transitions (copy-list (iconic-retrieval--ensure-list
                                          transitions))
                 :interpretation-note interpretation-note
                 :case-role-note case-role-note))

(defun make-iconic-state-definition
    (&key id title summary world-state-proxy sensory-pattern-note cue-set
       trajectory (grounded-p t) (reentrant-p nil) modalities grounding-note)
  (make-instance (if reentrant-p
                     'reentrant-iconic-state
                     'iconic-state-definition)
                 :id id
                 :title title
                 :summary summary
                 :world-state-proxy world-state-proxy
                 :sensory-pattern-note sensory-pattern-note
                 :grounded-p grounded-p
                 :reentrant-p reentrant-p
                 :modalities (copy-list (iconic-retrieval--ensure-list
                                         modalities))
                 :cue-set (copy-list (iconic-retrieval--ensure-list cue-set))
                 :trajectory trajectory
                 :grounding-note grounding-note))

(defun make-early-processing-stage
    (&key id title summary functions modalities (pre-fashioned-p t))
  (make-instance 'early-processing-stage
                 :id id
                 :title title
                 :summary summary
                 :functions (copy-list (iconic-retrieval--ensure-list functions))
                 :modalities (copy-list (iconic-retrieval--ensure-list
                                         modalities))
                 :pre-fashioned-p pre-fashioned-p))

(defun make-iconic-retrieval-route
    (&key id title cue source-state iconic-state
       (retrieval-mode :symbolic-to-grounded)
       trajectory
       inspectable-path
       (lay-label "Lay route")
       (follow-label "Follow route"))
  (make-instance 'iconic-retrieval-route
                 :id id
                 :title title
                 :cue cue
                 :source-state source-state
                 :iconic-state iconic-state
                 :retrieval-mode retrieval-mode
                 :trajectory trajectory
                 :inspectable-path (copy-list (iconic-retrieval--ensure-list
                                               inspectable-path))
                 :lay-label lay-label
                 :follow-label follow-label))

(defun make-neural-state-machine-model-definition
    (&key id title summary early-processing symbolic-cues iconic-states
       trajectories motor-action-note dual-operation-note grounding-claim)
  (make-instance 'neural-state-machine-model-definition
                 :id id
                 :title title
                 :summary summary
                 :early-processing early-processing
                 :symbolic-cues (copy-list (iconic-retrieval--ensure-list
                                            symbolic-cues))
                 :iconic-states (copy-list (iconic-retrieval--ensure-list
                                            iconic-states))
                 :trajectories (copy-list (iconic-retrieval--ensure-list
                                           trajectories))
                 :motor-action-note motor-action-note
                 :dual-operation-note dual-operation-note
                 :grounding-claim grounding-claim))

(defun make-multimodal-association-example
    (&key id title summary world-state-proxy iconic-state cues routes trajectory
       nsmm motor-action-note association-note)
  (make-instance 'multimodal-association-example
                 :id id
                 :title title
                 :summary summary
                 :world-state-proxy world-state-proxy
                 :iconic-state iconic-state
                 :cues (copy-list (iconic-retrieval--ensure-list cues))
                 :routes (copy-list (iconic-retrieval--ensure-list routes))
                 :trajectory trajectory
                 :nsmm nsmm
                 :motor-action-note motor-action-note
                 :association-note association-note))

(defun make-case-role-trajectory-example
    (&key id title summary sentence-variants routes trajectories nsmm
       distinction-note)
  (make-instance 'case-role-trajectory-example
                 :id id
                 :title title
                 :summary summary
                 :sentence-variants
                 (copy-list (iconic-retrieval--ensure-list sentence-variants))
                 :routes (copy-list (iconic-retrieval--ensure-list routes))
                 :trajectories (copy-list (iconic-retrieval--ensure-list
                                           trajectories))
                 :nsmm nsmm
                 :distinction-note distinction-note))

(defun grounded-iconic-state-p (object)
  (typecase object
    (iconic-state-definition
     (and (iconic-state-grounded-p-of object)
          (typep (iconic-state-world-state-proxy-of object) 'world-state-proxy)))
    (iconic-retrieval-route
     (grounded-iconic-state-p (iconic-retrieval-route-iconic-state-of object)))
    (multimodal-association-example
     (grounded-iconic-state-p
      (multimodal-association-example-iconic-state-of object)))
    (case-role-trajectory-example
     (every #'grounded-iconic-state-p
            (mapcar #'iconic-retrieval-route-iconic-state-of
                    (case-role-trajectory-example-routes-of object))))
    (neural-state-machine-model-definition
     (some #'grounded-iconic-state-p
           (neural-state-machine-model-iconic-states-of object)))
    (otherwise nil)))

(defun reentrant-iconic-state-p (object)
  (typecase object
    (iconic-state-definition
     (or (typep object 'reentrant-iconic-state)
         (iconic-state-reentrant-p-of object)))
    (iconic-retrieval-route
     (reentrant-iconic-state-p (iconic-retrieval-route-iconic-state-of object)))
    (multimodal-association-example
     (reentrant-iconic-state-p
      (multimodal-association-example-iconic-state-of object)))
    (otherwise nil)))

(defun symbolic-and-grounded-dual-object-p (object)
  (typecase object
    (iconic-state-definition
     (and (grounded-iconic-state-p object)
          (not (null (iconic-state-cue-set-of object)))))
    (iconic-retrieval-route
     (let ((cue (iconic-retrieval-route-cue-of object))
           (source-state (iconic-retrieval-route-source-state-of object))
           (iconic-state (iconic-retrieval-route-iconic-state-of object)))
       (and (typep cue 'linguistic-retrieval-cue)
            (typep source-state 'world-state-proxy)
            (grounded-iconic-state-p iconic-state)
            (eq source-state (iconic-state-world-state-proxy-of iconic-state))
            (member cue (iconic-state-cue-set-of iconic-state) :test #'eq))))
    (multimodal-association-example
     (and (grounded-iconic-state-p object)
          (not (null (multimodal-association-example-cues-of object)))
          (follow-route-retrieves-grounded-state-p object)))
    (case-role-trajectory-example
     (and (= 2 (length (case-role-trajectory-example-sentence-variants-of object)))
          (not (null (case-role-trajectory-example-trajectories-of object)))
          (follow-route-retrieves-grounded-state-p object)))
    (neural-state-machine-model-definition
     (and (typep (neural-state-machine-model-early-processing-of object)
                 'early-processing-stage)
          (not (null (neural-state-machine-model-symbolic-cues-of object)))
          (some #'grounded-iconic-state-p
                (neural-state-machine-model-iconic-states-of object))
          (not (null (neural-state-machine-model-trajectories-of object)))
          (stringp (neural-state-machine-model-motor-action-note-of object))
          (stringp (neural-state-machine-model-dual-operation-note-of object))
          (stringp (neural-state-machine-model-grounding-claim-of object))))
    (otherwise nil)))

(defun iconic-retrieval-route-page-titles (object)
  (let ((titles nil))
    (dolist (route (iconic-retrieval--route-sequence object))
      (let ((cue (iconic-retrieval-route-cue-of route))
            (source-state (iconic-retrieval-route-source-state-of route)))
        (when (typep cue 'linguistic-retrieval-cue)
          (setf titles
                (iconic-retrieval--push-page-titles
                 titles
                 (linguistic-retrieval-cue-related-pages-of cue))))
        (when (typep source-state 'world-state-proxy)
          (setf titles
                (iconic-retrieval--push-page-titles
                 titles
                 (world-state-proxy-evidence-pages-of source-state))))
        (setf titles
              (iconic-retrieval--push-page-titles
               titles
               (iconic-retrieval-route-inspectable-path-of route)))))
    (nreverse titles)))

(defun iconic-retrieval-summary-alist (object)
  (typecase object
    (world-state-proxy
     `((:id . ,(id-of object))
       (:title . ,(title-of object))
       (:source-kind . ,(world-state-proxy-source-kind-of object))
       (:temporal-note . ,(world-state-proxy-temporal-note-of object))
       (:evidence-pages . ,(world-state-proxy-evidence-pages-of object))))
    (linguistic-retrieval-cue
     `((:id . ,(id-of object))
       (:cue-text . ,(linguistic-retrieval-cue-text-of object))
       (:symbolic-role . ,(linguistic-retrieval-cue-symbolic-role-of object))
       (:modality . ,(linguistic-retrieval-cue-modality-of object))
       (:related-pages . ,(linguistic-retrieval-cue-related-pages-of object))))
    (iconic-state-trajectory
     `((:id . ,(id-of object))
       (:title . ,(title-of object))
       (:state-count . ,(length (iconic-state-trajectory-states-of object)))
       (:transition-count
        . ,(length (iconic-state-trajectory-transitions-of object)))
       (:interpretation-note
        . ,(iconic-state-trajectory-interpretation-note-of object))
       (:case-role-note . ,(iconic-state-trajectory-case-role-note-of object))))
    (iconic-state-definition
     `((:id . ,(id-of object))
       (:title . ,(title-of object))
       (:world-state-proxy
        . ,(title-of (iconic-state-world-state-proxy-of object)))
       (:grounded-p . ,(grounded-iconic-state-p object))
       (:reentrant-p . ,(reentrant-iconic-state-p object))
       (:modalities . ,(iconic-state-modalities-of object))
       (:cue-texts . ,(iconic-retrieval--cue-texts
                       (iconic-state-cue-set-of object)))
       (:sensory-pattern-note . ,(iconic-state-sensory-pattern-note-of object))
       (:trajectory . ,(and (iconic-state-trajectory-of object)
                            (title-of (iconic-state-trajectory-of object))))
       (:grounding-note . ,(iconic-state-grounding-note-of object))))
    (early-processing-stage
     `((:id . ,(id-of object))
       (:title . ,(title-of object))
       (:functions . ,(early-processing-stage-functions-of object))
       (:modalities . ,(early-processing-stage-modalities-of object))
       (:pre-fashioned-p . ,(early-processing-stage-pre-fashioned-p-of object))))
    (iconic-retrieval-route
     `((:id . ,(id-of object))
       (:title . ,(title-of object))
       (:cue . ,(title-of (iconic-retrieval-route-cue-of object)))
       (:source-state
        . ,(title-of (iconic-retrieval-route-source-state-of object)))
       (:iconic-state
        . ,(title-of (iconic-retrieval-route-iconic-state-of object)))
       (:retrieval-mode . ,(iconic-retrieval-route-retrieval-mode-of object))
       (:trajectory
        . ,(and (iconic-retrieval-route-trajectory-of object)
                (title-of (iconic-retrieval-route-trajectory-of object))))
       (:follow-label . ,(iconic-retrieval-route-follow-label-of object))
       (:lay-label . ,(iconic-retrieval-route-lay-label-of object))
       (:dual-reading-p . ,(symbolic-and-grounded-dual-object-p object))
       (:page-titles . ,(iconic-retrieval-route-page-titles object))))
    (multimodal-association-example
     `((:id . ,(id-of object))
       (:title . ,(title-of object))
       (:cue-texts . ,(iconic-retrieval--cue-texts
                       (multimodal-association-example-cues-of object)))
       (:route-titles . ,(iconic-retrieval--titles
                          (multimodal-association-example-routes-of object)))
       (:trajectory-title
        . ,(and (multimodal-association-example-trajectory-of object)
                (title-of
                 (multimodal-association-example-trajectory-of object))))
       (:reentrant-p . ,(reentrant-iconic-state-p object))
       (:modalities
        . ,(iconic-state-modalities-of
            (multimodal-association-example-iconic-state-of object)))
       (:association-note
        . ,(multimodal-association-example-association-note-of object))
       (:motor-action-note
        . ,(multimodal-association-example-motor-action-note-of object))))
    (case-role-trajectory-example
     `((:id . ,(id-of object))
       (:title . ,(title-of object))
       (:sentence-variants . ,(case-role-trajectory-example-sentence-variants-of object))
       (:route-titles . ,(iconic-retrieval--titles
                          (case-role-trajectory-example-routes-of object)))
       (:trajectory-titles
        . ,(iconic-retrieval--titles
            (case-role-trajectory-example-trajectories-of object)))
       (:case-role-notes
        . ,(mapcar #'iconic-state-trajectory-case-role-note-of
                   (case-role-trajectory-example-trajectories-of object)))
       (:distinction-note . ,(case-role-trajectory-example-distinction-note-of object))))
    (neural-state-machine-model-definition
     `((:id . ,(id-of object))
       (:title . ,(title-of object))
       (:early-processing
        . ,(and (neural-state-machine-model-early-processing-of object)
                (title-of (neural-state-machine-model-early-processing-of object))))
       (:symbolic-cue-count
        . ,(length (neural-state-machine-model-symbolic-cues-of object)))
       (:iconic-state-count
        . ,(length (neural-state-machine-model-iconic-states-of object)))
       (:trajectory-count
        . ,(length (neural-state-machine-model-trajectories-of object)))
       (:motor-action-note
        . ,(neural-state-machine-model-motor-action-note-of object))
       (:grounding-claim
        . ,(neural-state-machine-model-grounding-claim-of object))
       (:dual-operation-note
        . ,(neural-state-machine-model-dual-operation-note-of object))
       (:dual-reading-p . ,(symbolic-and-grounded-dual-object-p object))))
    (otherwise
     `((:type . ,(type-of object))
       (:summary . "Unsupported iconic retrieval object")))))

(defun follow-route-retrieves-grounded-state-p (object)
  (let ((routes (iconic-retrieval--route-sequence object)))
    (and (not (null routes))
         (every (lambda (route)
                  (and (iconic-retrieval--grounded-mode-p
                        (iconic-retrieval-route-retrieval-mode-of route))
                       (symbolic-and-grounded-dual-object-p route)
                       (stringp (iconic-retrieval-route-follow-label-of route))
                       (plusp
                        (length (iconic-retrieval-route-follow-label-of route)))))
                routes))))

(defun acquire-iconic-representation
    (world-state-proxy &key id title summary sensory-pattern-note cue-set
                         trajectory (grounded-p t) (reentrant-p nil) modalities grounding-note)
  (make-iconic-state-definition
   :id id
   :title (or title
              (format nil "~A iconic state"
                      (title-of world-state-proxy)))
   :summary
   (or summary
       (format nil
               "Grounded iconic representation acquired from world-state proxy ~A."
               (title-of world-state-proxy)))
   :world-state-proxy world-state-proxy
   :sensory-pattern-note sensory-pattern-note
   :cue-set cue-set
   :trajectory trajectory
   :grounded-p grounded-p
   :reentrant-p reentrant-p
   :modalities modalities
   :grounding-note grounding-note))

(defun associate-language-cue-with-iconic-state
    (cue iconic-state &key id title source-state
                        (retrieval-mode :symbolic-to-grounded)
                        trajectory inspectable-path
                        (lay-label "Lay route")
                        (follow-label "Follow route"))
  (let ((resolved-source-state
         (or source-state
             (iconic-state-world-state-proxy-of iconic-state))))
    (make-iconic-retrieval-route
     :id id
     :title (or title
                (format nil "~A retrieves ~A"
                        (title-of cue)
                        (title-of iconic-state)))
     :cue cue
     :source-state resolved-source-state
     :iconic-state iconic-state
     :retrieval-mode retrieval-mode
     :trajectory (or trajectory
                     (iconic-state-trajectory-of iconic-state))
     :inspectable-path inspectable-path
     :lay-label lay-label
     :follow-label follow-label)))

(defun retrieve-iconic-state (cue object)
  (some (lambda (route)
          (and (iconic-retrieval--cue-matches-p
                cue
                (iconic-retrieval-route-cue-of route))
               (follow-route-retrieves-grounded-state-p route)
               (iconic-retrieval-route-iconic-state-of route)))
        (iconic-retrieval--route-sequence object)))

(defun describe-case-role-trajectory (object)
  (typecase object
    (case-role-trajectory-example
     `((:sentence-variants
        . ,(case-role-trajectory-example-sentence-variants-of object))
       (:trajectory-titles
        . ,(iconic-retrieval--titles
            (case-role-trajectory-example-trajectories-of object)))
       (:case-role-notes
        . ,(mapcar #'iconic-state-trajectory-case-role-note-of
                   (case-role-trajectory-example-trajectories-of object)))
       (:distinct-trajectory-p
        . ,(> (length (case-role-trajectory-example-trajectories-of object))
              1))
       (:grounded-symbolic-operation-p
        . ,(symbolic-and-grounded-dual-object-p object))
       (:distinction-note
        . ,(case-role-trajectory-example-distinction-note-of object))))
    (iconic-state-trajectory
     `((:title . ,(title-of object))
       (:states . ,(iconic-state-trajectory-states-of object))
       (:case-role-note . ,(iconic-state-trajectory-case-role-note-of object))))
    (otherwise
     `((:type . ,(type-of object))
       (:summary . "No case-role trajectory description available.")))))

(defun describe-lexical-association-trajectory (object)
  (typecase object
    (multimodal-association-example
     (let ((iconic-state
            (multimodal-association-example-iconic-state-of object))
           (trajectory
            (multimodal-association-example-trajectory-of object)))
       `((:cue-texts
          . ,(iconic-retrieval--cue-texts
              (multimodal-association-example-cues-of object)))
         (:trajectory-states
          . ,(and trajectory
                  (iconic-state-trajectory-states-of trajectory)))
         (:reentrant-p . ,(reentrant-iconic-state-p iconic-state))
         (:modalities . ,(iconic-state-modalities-of iconic-state))
         (:grounded-symbolic-operation-p
          . ,(symbolic-and-grounded-dual-object-p object))
         (:motor-action-note
          . ,(multimodal-association-example-motor-action-note-of object)))))
    (iconic-state-trajectory
     `((:title . ,(title-of object))
       (:states . ,(iconic-state-trajectory-states-of object))
       (:interpretation-note
        . ,(iconic-state-trajectory-interpretation-note-of object))))
    (otherwise
     `((:type . ,(type-of object))
       (:summary . "No lexical association trajectory description available.")))))

(defun make-lexical-iconic-association-example ()
  (let* ((pages '("Iconic route language in HyperDoc"
                  "Inspectable iconic retrieval objects"
                  "Symbols and semantics in Mind and Mechanism"))
         (world-state
          (make-world-state-proxy
           :id "world-state/cup-seen-and-named"
           :title "Cup world state"
           :summary
           "Grounded world-state proxy for a cup encountered while its image, phonemic stream, and written word co-occur."
           :evidence-pages pages
           :source-kind :paper-example
           :temporal-note
           "The example is sequential: heard phonemes and written word co-occur with the cup image across a learned state sequence."))
         (phonemic-cue
          (make-linguistic-retrieval-cue
           :id "cue/phonemic-k-a-p"
           :cue-text "k-a-p"
           :symbolic-role :phonemic-trigger
           :related-pages pages
           :modality :phonemic))
         (written-cue
          (make-linguistic-retrieval-cue
           :id "cue/written-cup"
           :cue-text "cup"
           :symbolic-role :lexical-trigger
           :related-pages pages
           :modality :written))
         (trajectory
          (make-iconic-state-trajectory
           :id "trajectory/cup-multimodal-association"
           :title "Cup multimodal association trajectory"
           :states '("<Ci,Cw,k>"
                     "<Ci,Wi,a>"
                     "<Ci,Wi,p>"
                     "<Ci,Wi,/>")
           :transitions
           '((:from "<Ci,Cw,k>" :to "<Ci,Wi,a>" :label "heard a")
             (:from "<Ci,Wi,a>" :to "<Ci,Wi,p>" :label "heard p")
             (:from "<Ci,Wi,p>" :to "<Ci,Wi,/>" :label "phonetic input stops"))
           :interpretation-note
           "The learned sequence associates the cup image, written word, and phonemic sequence until the final state becomes reentrant."))
         (iconic-state
          (acquire-iconic-representation
           world-state
           :id "iconic-state/cup-multimodal"
           :title "Cup multimodal iconic state"
           :summary
           "Reentrant iconic state that binds the cup image to its phonemic input and written lexical symbol."
           :sensory-pattern-note
           "The iconic state represents the sensory pattern generated by the cup world state while written and phonemic cues are simultaneously available."
           :cue-set (list phonemic-cue written-cue)
           :trajectory trajectory
           :grounded-p t
           :reentrant-p t
           :modalities '(:visual :written :phonemic)
           :grounding-note
           "The multimodal sequence keeps symbolic cues distinct while the grounded cup representation remains the state that is retrieved." ))
         (phonemic-route
          (associate-language-cue-with-iconic-state
           phonemic-cue
           iconic-state
           :id "route/phonemic-k-a-p-to-cup"
           :title "Phonemic cue retrieves cup iconic state"
           :trajectory trajectory
           :inspectable-path pages))
         (written-route
          (associate-language-cue-with-iconic-state
           written-cue
           iconic-state
           :id "route/written-cup-to-cup-state"
           :title "Written cue retrieves cup iconic state"
           :trajectory trajectory
           :inspectable-path pages))
         (early-processing
          (make-early-processing-stage
           :id "early-processing/cup-multimodal"
           :title "Early processing for cup association"
           :summary
           "Pre-fashioned early processing stage for visual feature extraction and auditory frequency encoding before the cup association becomes iconic."
           :functions '("visual feature extraction"
                        "auditory frequency encoding")
           :modalities '(:visual :auditory)))
         (nsmm
          (make-neural-state-machine-model-definition
           :id "nsmm/cup-multimodal-association"
           :title "NSMM support for cup multimodal association"
           :summary
           "Paper-backed support object for the cup example: early processing feeds a reentrant iconic state that can be retrieved by phonemic and written cues."
           :early-processing early-processing
           :symbolic-cues (list phonemic-cue written-cue)
           :iconic-states (list iconic-state)
           :trajectories (list trajectory)
           :motor-action-note
           "Learning to say k-a-p associates heard sounds with sounds emitted through the motor-action neurons."
           :dual-operation-note
           "The same system keeps written and phonemic cues symbolic while the cup representation remains grounded and reentrant."
           :grounding-claim
           "The paper's lexical example depends on a grounded/iconic state rather than on arbitrary label attachment alone.")))
    (make-multimodal-association-example
     :id "example/lexical-iconic-association"
     :title "Lexical iconic association example"
     :summary
     "Paper-backed multimodal example in which a cup world state, phonemic input, and written word converge on one reentrant iconic state."
     :world-state-proxy world-state
     :iconic-state iconic-state
     :cues (list phonemic-cue written-cue)
     :routes (list phonemic-route written-route)
     :trajectory trajectory
     :nsmm nsmm
     :motor-action-note
     "Heard phonemes can be associated with uttered phonemes through the motor-action neurons."
     :association-note
     "This is the paper's lexical/multimodal association pattern rendered as an inspectable HyperDoc object.")))

(defun make-case-role-iconic-trajectory-example ()
  (let* ((pages '("Iconic route language in HyperDoc"
                  "Inspectable iconic retrieval objects"
                  "Symbols and semantics in Mind and Mechanism"))
         (rock-sentence "The boy broke the window with a rock")
         (curtain-sentence "The boy broke the window with a curtain")
         (rock-cue
          (make-linguistic-retrieval-cue
           :id "cue/case-role-rock"
           :cue-text rock-sentence
           :symbolic-role :sentence-trigger
           :related-pages pages
           :modality :sentence))
         (curtain-cue
          (make-linguistic-retrieval-cue
           :id "cue/case-role-curtain"
           :cue-text curtain-sentence
           :symbolic-role :sentence-trigger
           :related-pages pages
           :modality :sentence))
         (rock-world-state
          (make-world-state-proxy
           :id "world-state/boy-breaks-window-with-rock"
           :title "Breaking event with rock instrument"
           :summary
           "Grounded world-state proxy in which the rock functions as instrument in the breaking event."
           :evidence-pages pages
           :source-kind :paper-example
           :temporal-note
           "The event unfolds as an action trajectory in which the rock remains attached to the breaking action."))
         (curtain-world-state
          (make-world-state-proxy
           :id "world-state/window-with-curtain"
           :title "Window scene with curtain modifier"
           :summary
           "Grounded world-state proxy in which the curtain modifies the window scene rather than filling the instrumental role."
           :evidence-pages pages
           :source-kind :paper-example
           :temporal-note
           "The scene remains distinct because the modifier path through the state structure differs from the instrumental path."))
         (rock-trajectory
          (make-iconic-state-trajectory
           :id "trajectory/case-role-rock"
           :title "Rock instrument trajectory"
           :states '("boy as agent"
                     "breaking event"
                     "window as patient"
                     "rock as instrument")
           :transitions
           '((:from "boy as agent" :to "breaking event" :label "broke")
             (:from "breaking event" :to "window as patient" :label "the window")
             (:from "window as patient" :to "rock as instrument" :label "with a rock"))
           :interpretation-note
           "The sentence retrieves a trajectory in which the rock is bound to the action as instrument."
           :case-role-note
           "with a rock fills the instrument role for the breaking event."))
         (curtain-trajectory
          (make-iconic-state-trajectory
           :id "trajectory/case-role-curtain"
           :title "Curtain modifier trajectory"
           :states '("boy as agent"
                     "breaking event"
                     "window as modified patient"
                     "curtain as window modifier")
           :transitions
           '((:from "boy as agent" :to "breaking event" :label "broke")
             (:from "breaking event" :to "window as modified patient" :label "the window")
             (:from "window as modified patient"
              :to "curtain as window modifier"
              :label "with a curtain"))
           :interpretation-note
           "The sentence retrieves a different trajectory in which the curtain modifies the window phrase."
           :case-role-note
           "with a curtain modifies the window description rather than instrumenting the action."))
         (rock-iconic-state
          (acquire-iconic-representation
           rock-world-state
           :id "iconic-state/rock-instrument-reading"
           :title "Rock instrument iconic state"
           :summary
           "Grounded iconic state for the sentence reading in which the rock is the instrument."
           :sensory-pattern-note
           "The state represents the event structure suggested by the sentence when the prepositional phrase is attached instrumentally."
           :cue-set (list rock-cue)
           :trajectory rock-trajectory
           :grounded-p t
           :reentrant-p nil
           :modalities '(:linguistic :event)
           :grounding-note
           "The cue remains symbolic, but the retrieved state is a grounded event reading with a distinct action trajectory."))
         (curtain-iconic-state
          (acquire-iconic-representation
           curtain-world-state
           :id "iconic-state/curtain-modifier-reading"
           :title "Curtain modifier iconic state"
           :summary
           "Grounded iconic state for the sentence reading in which the curtain modifies the window."
           :sensory-pattern-note
           "The state represents the sentence as a window scene with a curtain modifier rather than an instrument."
           :cue-set (list curtain-cue)
           :trajectory curtain-trajectory
           :grounded-p t
           :reentrant-p nil
           :modalities '(:linguistic :event)
           :grounding-note
           "The distinct iconic trajectory preserves a semantic distinction that flat labels would obscure." ))
         (rock-route
          (associate-language-cue-with-iconic-state
           rock-cue
           rock-iconic-state
           :id "route/rock-sentence-to-iconic-state"
           :title "Rock sentence retrieves instrument trajectory"
           :trajectory rock-trajectory
           :inspectable-path pages))
         (curtain-route
          (associate-language-cue-with-iconic-state
           curtain-cue
           curtain-iconic-state
           :id "route/curtain-sentence-to-iconic-state"
           :title "Curtain sentence retrieves modifier trajectory"
           :trajectory curtain-trajectory
           :inspectable-path pages))
         (early-processing
          (make-early-processing-stage
           :id "early-processing/case-role"
           :title "Early processing for case-role distinction"
           :summary
           "Pre-fashioned early processing stage that prepares sentence input before iconic trajectories differentiate the semantic reading."
           :functions '("early lexical segmentation"
                        "auditory frequency encoding")
           :modalities '(:auditory :linguistic)))
         (nsmm
          (make-neural-state-machine-model-definition
           :id "nsmm/case-role-trajectories"
           :title "NSMM support for case-role trajectories"
           :summary
           "Paper-backed support object in which sentence cues retrieve distinct iconic trajectories for the rock and curtain readings."
           :early-processing early-processing
           :symbolic-cues (list rock-cue curtain-cue)
           :iconic-states (list rock-iconic-state curtain-iconic-state)
           :trajectories (list rock-trajectory curtain-trajectory)
           :motor-action-note
           "The model still reserves motor/action output even when the example foregrounds internal semantic discrimination."
           :dual-operation-note
           "The sentence remains a symbolic trigger while the semantic distinction lives in grounded/iconic state trajectories."
           :grounding-claim
           "Distinct semantics are represented as distinct trajectories in iconic state structure, not merely as flat labels.")))
    (make-case-role-trajectory-example
     :id "example/case-role-iconic-trajectories"
     :title "Case-role iconic trajectory example"
     :summary
     "Paper-backed example in which rock and curtain readings become distinct trajectories through iconic state structure."
     :sentence-variants (list rock-sentence curtain-sentence)
     :routes (list rock-route curtain-route)
     :trajectories (list rock-trajectory curtain-trajectory)
     :nsmm nsmm
     :distinction-note
     "The paper's case-role example matters because the semantic difference is preserved as trajectory structure rather than as post hoc label attachment.")))

(defun make-iconic-route-language-example ()
  (let* ((pages '("Iconic route language in HyperDoc"
                  "Inspectable iconic retrieval objects"
                  "Focused semantic source stations"
                  "Symbols and semantics in Mind and Mechanism"
                  "Touch-Fahrplan view for Zotero topic enrichment"))
         (cue
          (make-linguistic-retrieval-cue
           :id "cue/follow-route"
           :cue-text "Follow route"
           :symbolic-role :route-starter
           :related-pages pages
           :modality :linguistic))
         (world-state
          (make-world-state-proxy
           :id "world-state/focused-semantic-source-station"
           :title "Focused semantic source station"
           :summary
           "Grounded world-state proxy for the evidence-bearing semantic station that a HyperDoc route re-enters."
           :evidence-pages pages
           :source-kind :hyperdoc-reading
           :temporal-note
           "The station remains revisitable as later route following re-enters the same grounded state."))
         (trajectory
          (make-iconic-state-trajectory
           :id "trajectory/follow-route-understanding"
           :title "Follow route understanding trajectory"
           :states '("cue received"
                     "grounded station focused"
                     "iconic state re-entered")
           :transitions
           '((:from "cue received" :to "grounded station focused"
              :label "focus grounded station")
             (:from "grounded station focused" :to "iconic state re-entered"
              :label "understanding as retrieval"))
           :interpretation-note
           "Touch-Fahrplan route following is read here as successful retrieval of a grounded/iconic state rather than as bare graph traversal."))
         (iconic-state
          (acquire-iconic-representation
           world-state
           :id "iconic-state/route-language-reentry"
           :title "Route-language reentry iconic state"
           :summary
           "Grounded iconic state recovered when a route cue successfully re-enters the relevant semantic station."
           :sensory-pattern-note
           "The state represents the source station as an inspectable grounded pattern rather than a flat label."
           :cue-set (list cue)
           :trajectory trajectory
           :grounded-p t
           :reentrant-p t
           :modalities '(:linguistic :documentary)
           :grounding-note
           "The symbolic cue and grounded station remain distinct, but the route binds them into one retrieval relation." )))
    (associate-language-cue-with-iconic-state
     cue
     iconic-state
     :id "route/follow-route-to-grounded-state"
     :title "Follow route to grounded iconic state"
     :trajectory trajectory
     :inspectable-path pages
     :lay-label "Lay route"
     :follow-label "Follow route")))

(defun make-neural-state-machine-model-example ()
  (let* ((lexical-example (make-lexical-iconic-association-example))
         (case-role-example (make-case-role-iconic-trajectory-example))
         (route-example (make-iconic-route-language-example))
         (route-iconic-state
          (iconic-retrieval-route-iconic-state-of route-example))
         (route-trajectory
          (iconic-retrieval-route-trajectory-of route-example))
         (route-cue
          (iconic-retrieval-route-cue-of route-example))
         (early-processing
          (make-early-processing-stage
           :id "early-processing/nsmm-paper-support"
           :title "Early processing for paper-backed NSMM support"
           :summary
           "Support-stage object that keeps perceptual input, pre-fashioned preprocessing, iconic internal state, and motor/action output legible in HyperDoc."
           :functions '("edge extraction"
                        "auditory frequency encoding"
                        "early lexical segmentation")
           :modalities '(:visual :auditory :linguistic))))
    (make-neural-state-machine-model-definition
     :id "nsmm/iconic-language-paper-support"
     :title "NSMM support object for iconic language representation"
     :summary
     "Paper-backed support object that formalizes the route-language layer with perceptual input, internal iconic state, early processing, and motor/action output."
     :early-processing early-processing
     :symbolic-cues
     (append (multimodal-association-example-cues-of lexical-example)
             (list route-cue)
             (mapcar #'iconic-retrieval-route-cue-of
                     (case-role-trajectory-example-routes-of case-role-example)))
     :iconic-states
     (append (list (multimodal-association-example-iconic-state-of lexical-example)
                   route-iconic-state)
             (mapcar #'iconic-retrieval-route-iconic-state-of
                     (case-role-trajectory-example-routes-of case-role-example)))
     :trajectories
     (append (list (multimodal-association-example-trajectory-of lexical-example)
                   route-trajectory)
             (case-role-trajectory-example-trajectories-of case-role-example))
     :motor-action-note
     "The paper's general state-machine reading keeps motor/action output available alongside perceptual input and internal iconic state; the lexical example makes this explicit through utterance learning."
     :dual-operation-note
     "The NSMM object remains secondary in HyperDoc: symbolic cues trigger retrieval, grounded/iconic states do the representational work, and trajectories preserve semantic distinction."
     :grounding-claim
     "The paper's two examples plus the local route-language reading show grounded symbolic operation inside one recursive system, not a split between symbolic front-end and grounded back-end.")))
