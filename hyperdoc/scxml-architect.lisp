;;;; Architect-style SCXML session surfaces for Workspace behavior
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defclass dmx-annotation-workspace-architect-view-model ()
  ((source-run
    :reader dmx-annotation-workspace-architect-view-model-source-run-of
    :initarg :source-run
    :initform nil)
   (local-lane
    :reader dmx-annotation-workspace-architect-view-model-local-lane-of
    :initarg :local-lane
    :initform nil)
   (dmx-lane
    :reader dmx-annotation-workspace-architect-view-model-dmx-lane-of
    :initarg :dmx-lane
    :initform nil)
   (active-state-path
    :reader dmx-annotation-workspace-architect-view-model-active-state-path-of
    :initarg :active-state-path
    :initform nil)
   (next-legal-event
    :reader dmx-annotation-workspace-architect-view-model-next-legal-event-of
    :initarg :next-legal-event
    :initform nil)
   (preview-path
    :reader dmx-annotation-workspace-architect-view-model-preview-path-of
    :initarg :preview-path
    :initform nil)
   (event-groups
    :reader dmx-annotation-workspace-architect-view-model-event-groups-of
    :initarg :event-groups
    :initform nil)
   (primary-event-plan
    :reader dmx-annotation-workspace-architect-view-model-primary-event-plan-of
    :initarg :primary-event-plan
    :initform nil)
   (target-workspace-id
    :reader dmx-annotation-workspace-architect-view-model-target-workspace-id-of
    :initarg :target-workspace-id
    :initform 919815)
   (target-topicmap-id
    :reader dmx-annotation-workspace-architect-view-model-target-topicmap-id-of
    :initarg :target-topicmap-id
    :initform 919822)
   (projection-surface-label
    :reader dmx-annotation-workspace-architect-view-model-projection-surface-label-of
    :initarg :projection-surface-label
    :initform "workspace 919815, topicmap 919822")))

(defclass scxml-architect-session ()
  ((scxml-path
    :reader scxml-architect-session-scxml-path-of
    :initarg :scxml-path)
   (chart :reader scxml-architect-session-chart-of
          :initarg :chart
          :initform nil)
   (active-state-path
    :reader scxml-architect-session-active-state-path-of
    :initarg :active-state-path
    :initform nil)
   (selected-event
    :reader scxml-architect-session-selected-event-of
    :initarg :selected-event
    :initform nil)
   (preview-path
    :reader scxml-architect-session-preview-path-of
    :initarg :preview-path
    :initform nil)
   (enabled-events
    :reader scxml-architect-session-enabled-events-of
    :initarg :enabled-events
    :initform nil)
   (inherited-events
    :reader scxml-architect-session-inherited-events-of
    :initarg :inherited-events
    :initform nil)
   (leaf-events
    :reader scxml-architect-session-leaf-events-of
    :initarg :leaf-events
    :initform nil)
   (transition-effects
    :reader scxml-architect-session-transition-effects-of
    :initarg :transition-effects
    :initform nil)
   (state-metadata
    :reader scxml-architect-session-state-metadata-of
    :initarg :state-metadata
    :initform nil)
   (transition-metadata
    :reader scxml-architect-session-transition-metadata-of
    :initarg :transition-metadata
    :initform nil)
   (graphviz-dot
    :reader scxml-architect-session-graphviz-dot-of
    :initarg :graphviz-dot
    :initform nil)
   (render-target
    :reader scxml-architect-session-render-target-of
    :initarg :render-target
    :initform :graphviz-snippet)
   (findings
    :reader scxml-architect-session-findings-of
    :initarg :findings
    :initform nil)
   (diagnostics
    :reader scxml-architect-session-diagnostics-of
    :initarg :diagnostics
    :initform nil)
   (source-object
    :reader scxml-architect-session-source-object-of
    :initarg :source-object
    :initform nil)
   (presentation-binding
    :reader scxml-architect-session-presentation-binding-of
    :initarg :presentation-binding
    :initform nil)))

(defparameter *dmx-annotation-workspace-architect-state-groups*
  '(("localAuthoring"
     "draftLocal"
     "previewLocalSavePlan"
     "savingLocal"
     "locallySaved"
     "previewDmxMaterializationPlan"
     "savingLocalThenMaterializing"
     "localSaveFailed"
     "localSaveFailureReport")
    ("dmxProjection"
     "materializationPreflight"
     "materializeNativeTopic"
     "materializeCompatibilityCarrier"
     "projectionPending"
     "previewContinuationPlan"
     "continuationAuthCheck"
     "authRequired"
     "assignWorkspace"
     "placeTopicmap"
     "recordProjectionJournal"
     "reopenAnnotation"
     "projectedComplete"
     "projectionFailed"
     "projectionFailureReport")))

(defparameter *dmx-annotation-workspace-architect-parent-state-events*
  '(("workspaceView" "INSPECT_PLAN" "BACK" "CANCEL")
    ("localAuthoring" "SAVE_LOCAL" "SAVE_LOCAL_AND_MATERIALIZE")
    ("dmxProjection"
     "MATERIALIZE_DMX"
     "CONTINUE_DMX_PROJECTION"
     "AUTH.REQUIRED"
     "AUTH.SUBMIT"
     "AUTH.CONTINUATION_READY"
     "AUTH.FAILED")))

(defparameter *dmx-annotation-workspace-architect-event-group-order*
  '("Workspace view events"
    "Local journal events"
    "DMX projection events"
    "Advanced diagnostics"))

(defun scxml-architect-chart-states (chart)
  (call-hyperdoc-scxml :scxml-chart-states-of chart))

(defun scxml-architect-state-id (state)
  (call-hyperdoc-scxml :scxml-state-id-of state))

(defun scxml-architect-state-transitions (state)
  (call-hyperdoc-scxml :scxml-state-transitions-of state))

(defun scxml-architect-transition-event (transition)
  (or (call-hyperdoc-scxml :scxml-transition-event-of transition)
      ""))

(defun scxml-architect-transition-target (transition)
  (or (call-hyperdoc-scxml :scxml-transition-target-of transition)
      ""))

(defun scxml-architect-transition-id (transition)
  (call-hyperdoc-scxml :scxml-transition-id-of transition))

(defun scxml-architect-transition-source-state-id (transition)
  (call-hyperdoc-scxml :scxml-transition-source-state-id-of transition))

(defun scxml-architect-event-string= (left right)
  (and (stringp left)
       (stringp right)
       (string= left right)))

(defun dmx-annotation-workspace-architect-state-group-of (state-id)
  (or (loop for (group-id . member-state-ids)
            in *dmx-annotation-workspace-architect-state-groups*
            when (member state-id member-state-ids :test #'string=)
            do (return group-id))
      (if (string= state-id "classifyAnnotation")
          "workspaceView"
          nil)))

(defun dmx-annotation-workspace-architect-active-state-path (current-state)
  (let ((group (dmx-annotation-workspace-architect-state-group-of current-state)))
    (cond
      ((string= current-state "classifyAnnotation")
       '("workspaceView" "classifyAnnotation"))
      ((string= group "localAuthoring")
       (list "workspaceView" "localAuthoring" current-state))
      ((string= group "dmxProjection")
       (list "workspaceView" "dmxProjection" current-state))
      (t
       (list "workspaceView" current-state)))))

(defun dmx-annotation-workspace-architect-state-events (state-id)
  (cdr (assoc state-id
              *dmx-annotation-workspace-architect-parent-state-events*
              :test #'string=)))

(defun dmx-annotation-workspace-architect-dot-quoted (value)
  (format nil "\"~A\"" (or value "")))

(defun dmx-annotation-workspace-architect-event-group-label (action-plan)
  (let ((event (dmx-annotation-workspace-view-action-plan-event action-plan)))
    (cond
      ((not (dmx-annotation-workspace-view-action-plan-mapped-from-scxml-p action-plan))
       "Advanced diagnostics")
      ((member event
               '("SAVE_LOCAL" "SAVE_LOCAL_AND_MATERIALIZE")
               :test #'string=)
       "Local journal events")
      ((member event
               '("MATERIALIZE_DMX"
                 "CONTINUE_DMX_PROJECTION"
                 "AUTH_SUBMACHINE"
                 "INSPECT_FAILURE")
               :test #'string=)
       "DMX projection events")
      (t
       "Workspace view events"))))

(defun dmx-annotation-workspace-architect-event-groups (action-plans)
  (let ((ordered-groups '()))
    (dolist (group-label *dmx-annotation-workspace-architect-event-group-order*)
      (let ((plans
             (remove-if-not
              (lambda (plan)
                (string= group-label
                         (dmx-annotation-workspace-architect-event-group-label
                          plan)))
              action-plans)))
        (when plans
          (push (list :group-label group-label
                      :plans plans)
                ordered-groups))))
    (nreverse ordered-groups)))

(defun dmx-annotation-workspace-architect-primary-event-plan
    (event-groups selected-event)
  (or (loop for group in event-groups
            for plans = (getf group :plans)
            thereis (find-if (lambda (plan)
                               (and (dmx-annotation-workspace-view-action-plan-mapped-from-scxml-p
                                     plan)
                                    (string= selected-event
                                             (dmx-annotation-workspace-view-action-plan-event
                                              plan))))
                             plans))
      (loop for group in event-groups
            for plans = (getf group :plans)
            thereis (find-if #'dmx-annotation-workspace-view-action-plan-primary-p
                             plans))
      (loop for group in event-groups
            for plans = (getf group :plans)
            thereis (first plans))))

(defun dmx-annotation-workspace-architect-transition-effects (action-plans)
  (mapcar (lambda (plan)
            (list :event
                  (dmx-annotation-workspace-view-action-plan-event plan)
                  :label
                  (dmx-annotation-workspace-view-action-plan-label plan)
                  :function
                  (dmx-annotation-workspace-view-action-plan-function plan)
                  :group-label
                  (dmx-annotation-workspace-architect-event-group-label plan)
                  :local-mutation-p
                  (and (dmx-annotation-workspace-view-action-plan-local-mutation-p
                        plan)
                       t)
                  :dmx-mutation-p
                  (and (dmx-annotation-workspace-view-action-plan-dmx-mutation-p
                        plan)
                       t)
                  :auth-required-p
                  (and (dmx-annotation-workspace-view-action-plan-auth-required-p
                        plan)
                       t)
                  :topic-upsert-p
                  (and (dmx-annotation-workspace-view-action-plan-topic-upsert-p
                        plan)
                       t)
                  :workspace-assignment-p
                  (and (dmx-annotation-workspace-view-action-plan-workspace-assignment-p
                        plan)
                       t)
                  :topicmap-placement-p
                  (and (dmx-annotation-workspace-view-action-plan-topicmap-placement-p
                        plan)
                       t)
                  :advanced-only-p
                  (and (dmx-annotation-workspace-view-action-plan-advanced-only-p
                        plan)
                       t)))
          action-plans))

(defun dmx-annotation-workspace-architect-event-side-effect-p (event effect)
  (declare (ignore event))
  (or (getf effect :local-mutation-p)
      (getf effect :dmx-mutation-p)
      (getf effect :workspace-assignment-p)
      (getf effect :topicmap-placement-p)))

(defun dmx-annotation-workspace-architect-event-guarded-p (event effect)
  (or (search "AUTH" (or event "") :test #'char-equal)
      (getf effect :auth-required-p)))

(defun dmx-annotation-workspace-architect-transition-metadata
    (chart transition-effects)
  (let ((effect-index (make-hash-table :test #'equal))
        (entries '()))
    (dolist (effect transition-effects)
      (setf (gethash (getf effect :event) effect-index) effect))
    (dolist (state (scxml-architect-chart-states chart))
      (let ((source (scxml-architect-state-id state)))
        (dolist (transition (scxml-architect-state-transitions state))
          (let* ((event (scxml-architect-transition-event transition))
                 (target (scxml-architect-transition-target transition))
                 (effect (gethash event effect-index)))
            (push (list :transition-id
                        (scxml-architect-transition-id transition)
                        :source-state source
                        :target-state target
                        :event event
                        :guarded-p
                        (and (dmx-annotation-workspace-architect-event-guarded-p
                              event
                              effect)
                             t)
                        :side-effect-p
                        (and effect
                             (dmx-annotation-workspace-architect-event-side-effect-p
                              event
                              effect)
                             t))
                  entries)))))
    (nreverse entries)))

(defun dmx-annotation-workspace-architect-state-metadata
    (active-state-path inherited-events leaf-events)
  (let* ((root-id "workspaceView")
         (middle-id (second active-state-path))
         (leaf-id (car (last active-state-path)))
         (entries
          (list (list :state-id root-id
                      :role :root
                      :active-p t
                      :inherited-events
                      (copy-list (dmx-annotation-workspace-architect-state-events
                                  root-id))
                      :leaf-events nil
                      :differences nil)
                (list :state-id middle-id
                      :role :parent
                      :active-p (and middle-id t)
                      :inherited-events inherited-events
                      :leaf-events nil
                      :differences nil)
                (list :state-id leaf-id
                      :role :leaf
                      :active-p t
                      :inherited-events inherited-events
                      :leaf-events leaf-events
                      :differences
                      (set-difference leaf-events
                                      inherited-events
                                      :test #'string=)))))
    (remove-if (lambda (entry)
                 (or (null (getf entry :state-id))
                     (and (eq :parent (getf entry :role))
                          (string= root-id (getf entry :state-id)))))
               entries)))

(defun dmx-annotation-workspace-architect-dot
    (chart current-state selected-event preview-path active-state-path transition-effects)
  (let ((event-effect-index (make-hash-table :test #'equal))
        (active-index (make-hash-table :test #'equal))
        (preview-index (make-hash-table :test #'equal)))
    (dolist (effect transition-effects)
      (setf (gethash (getf effect :event) event-effect-index) effect))
    (dolist (state-id active-state-path)
      (setf (gethash state-id active-index) t))
    (dolist (state-id preview-path)
      (setf (gethash state-id preview-index) t))
    (flet ((emit-state-node (stream state-id)
             (let* ((active-p (gethash state-id active-index))
                    (preview-p (gethash state-id preview-index))
                    (leaf-p (string= state-id current-state))
                    (fillcolor (cond
                                 (leaf-p "#fff2bf")
                                 (active-p "#e7f0ff")
                                 (preview-p "#fde7d6")
                                 (t "#f8f8f8")))
                    (penwidth (cond
                                (leaf-p 3)
                                (active-p 2)
                                (t 1))))
               (format stream
                       "    ~A [label=~A, shape=box, style=\"rounded,filled\", fillcolor=~A, color=\"#404040\", penwidth=~D];~%"
                       (dmx-annotation-workspace-architect-dot-quoted state-id)
                       (dmx-annotation-workspace-architect-dot-quoted state-id)
                       (dmx-annotation-workspace-architect-dot-quoted fillcolor)
                       penwidth))))
      (with-output-to-string (out)
        (format out "digraph ~A {~%"
                (dmx-annotation-workspace-architect-dot-quoted
                 "dmx-annotation-workspace-architect"))
        (format out "  rankdir=LR;~%")
        (format out "  compound=true;~%")
        (format out "  nodesep=0.6;~%")
        (format out "  ranksep=0.8;~%")
        (format out "  fontname=\"Helvetica\";~%")
        (format out "  node [fontname=\"Helvetica\", fontsize=10];~%")
        (format out "  edge [fontname=\"Helvetica\", fontsize=9, color=\"#707070\"];~%")
        (format out "  subgraph cluster_workspaceView {~%")
        (format out "    label=~A;~%"
                (dmx-annotation-workspace-architect-dot-quoted "workspaceView"))
        (format out "    style=rounded; color=\"#909090\";~%")
        (format out "    subgraph cluster_localAuthoring {~%")
        (format out "      label=~A; style=rounded; color=\"#4c78a8\";~%"
                (dmx-annotation-workspace-architect-dot-quoted "localAuthoring"))
        (dolist (state-id (cdr (assoc "localAuthoring"
                                      *dmx-annotation-workspace-architect-state-groups*
                                      :test #'string=)))
          (emit-state-node out state-id))
        (format out "    }~%")
        (format out "    subgraph cluster_dmxProjection {~%")
        (format out "      label=~A; style=rounded; color=\"#e17c05\";~%"
                (dmx-annotation-workspace-architect-dot-quoted "dmxProjection"))
        (dolist (state-id (cdr (assoc "dmxProjection"
                                      *dmx-annotation-workspace-architect-state-groups*
                                      :test #'string=)))
          (emit-state-node out state-id))
        (emit-state-node out "classifyAnnotation")
        (format out "    }~%")
        (format out "  }~%")
        (dolist (state (scxml-architect-chart-states chart))
          (let ((source (scxml-architect-state-id state)))
            (dolist (transition (scxml-architect-state-transitions state))
              (let* ((event (scxml-architect-transition-event transition))
                     (target (scxml-architect-transition-target transition))
                     (effect (gethash event event-effect-index))
                     (selected-p
                      (and (string= source current-state)
                           (scxml-architect-event-string= selected-event event)))
                     (preview-p
                      (and (member source preview-path :test #'string=)
                           (member target preview-path :test #'string=)))
                     (guarded-p
                      (dmx-annotation-workspace-architect-event-guarded-p
                       event effect))
                     (side-effect-p
                      (and effect
                           (dmx-annotation-workspace-architect-event-side-effect-p
                            event
                            effect)))
                     (color (cond
                              (selected-p "#d62728")
                              (preview-p "#ff7f0e")
                              (side-effect-p "#b22222")
                              (guarded-p "#6b4c9a")
                              (t "#808080")))
                     (style (cond
                              (guarded-p "dashed")
                              (t "solid")))
                     (penwidth (cond
                                 (selected-p 3)
                                 (preview-p 2)
                                 (side-effect-p 2)
                                 (t 1))))
                (format out
                        "  ~A -> ~A [label=~A, color=~A, style=~A, penwidth=~D];~%"
                        (dmx-annotation-workspace-architect-dot-quoted source)
                        (dmx-annotation-workspace-architect-dot-quoted target)
                        (dmx-annotation-workspace-architect-dot-quoted event)
                        (dmx-annotation-workspace-architect-dot-quoted color)
                        (dmx-annotation-workspace-architect-dot-quoted style)
                        penwidth)))))
        (format out "}~%")))))

(defun dmx-annotation-workspace-architect-leaf-events (mapped-action-plans)
  (remove-duplicates
   (mapcar #'dmx-annotation-workspace-view-action-plan-event
           mapped-action-plans)
   :test #'string=))

(defun dmx-annotation-workspace-architect-inherited-events (active-state-path)
  (let ((inherited-events '()))
    (dolist (state-id (butlast active-state-path))
      (dolist (event (dmx-annotation-workspace-architect-state-events state-id))
        (pushnew event inherited-events :test #'string=)))
    (nreverse inherited-events)))

(defun make-dmx-annotation-workspace-architect-view-model
    (workspace-view-run event-groups active-state-path preview-path)
  (let ((primary-plan
         (dmx-annotation-workspace-architect-primary-event-plan
          event-groups
          (dmx-annotation-workspace-view-run-selected-preview-event-of
           workspace-view-run))))
    (make-instance
     'dmx-annotation-workspace-architect-view-model
     :source-run workspace-view-run
     :local-lane
     (list :state
           (dmx-annotation-workspace-view-run-local-lane-state-of
            workspace-view-run)
           :event-id
           (dmx-annotation-workspace-view-run-local-journal-event-id-of
            workspace-view-run)
           :event-count
           (dmx-annotation-workspace-view-run-local-journal-event-count-of
            workspace-view-run)
           :object-class
           (dmx-annotation-workspace-view-run-local-object-class-of
            workspace-view-run)
           :authoritative-p
           (and (dmx-annotation-workspace-view-run-local-save-authoritative-p-of
                 workspace-view-run)
                t))
     :dmx-lane
     (list :carrier-topic
           (dmx-annotation-workspace-view-run-carrier-topic-label-of
            workspace-view-run)
           :assignment-status
           (dmx-annotation-workspace-view-run-assignment-status-label-of
            workspace-view-run)
           :topicmap-placement-status
           (dmx-annotation-workspace-view-run-topicmap-placement-status-label-of
            workspace-view-run)
           :reopen-target
           (dmx-annotation-workspace-view-run-reopen-target-class-of
            workspace-view-run)
           :projection-surface
           (dmx-annotation-workspace-view-run-projection-visibility-target-of
            workspace-view-run))
     :active-state-path active-state-path
     :next-legal-event
     (dmx-annotation-workspace-view-run-selected-preview-event-of
      workspace-view-run)
     :preview-path preview-path
     :event-groups event-groups
     :primary-event-plan primary-plan
     :target-workspace-id
     (dmx-annotation-workspace-view-run-workspace-id-of workspace-view-run)
     :target-topicmap-id
     (dmx-annotation-workspace-view-run-workspace-topicmap-id-of
      workspace-view-run)
     :projection-surface-label
     (dmx-annotation-workspace-view-run-projection-visibility-target-of
      workspace-view-run))))

(defun make-dmx-annotation-workspace-architect-session
    (annotation &key workspace-topicmap-id workspace-id client
                  (materialize-to-dmx-p nil))
  (let* ((workspace-view-run
          (make-dmx-annotation-workspace-view-run
           annotation
           :workspace-topicmap-id workspace-topicmap-id
           :workspace-id workspace-id
           :client client
           :materialize-to-dmx-p materialize-to-dmx-p))
         (chart (read-dmx-annotation-workspace-view-scxml))
         (current-state
          (dmx-annotation-workspace-view-run-current-state-of workspace-view-run))
         (selected-event
          (dmx-annotation-workspace-view-run-selected-preview-event-of
           workspace-view-run))
         (preview-path
          (remove-duplicates
           (append (list current-state)
                   (copy-list
                    (or (dmx-annotation-workspace-view-run-next-states-of
                         workspace-view-run)
                        '())))
           :test #'string=))
         (active-state-path
          (dmx-annotation-workspace-architect-active-state-path current-state))
         (all-action-plans
          (copy-list
           (or (dmx-annotation-workspace-view-run-enabled-action-plans-of
                workspace-view-run)
               '())))
         (mapped-action-plans
          (remove-if-not #'dmx-annotation-workspace-view-action-plan-mapped-from-scxml-p
                         all-action-plans))
         (diagnostic-plans
          (remove-if #'dmx-annotation-workspace-view-action-plan-mapped-from-scxml-p
                     all-action-plans))
         (leaf-events
          (dmx-annotation-workspace-architect-leaf-events mapped-action-plans))
         (inherited-events
          (dmx-annotation-workspace-architect-inherited-events
           active-state-path))
         (event-groups
          (dmx-annotation-workspace-architect-event-groups all-action-plans))
         (transition-effects
          (dmx-annotation-workspace-architect-transition-effects all-action-plans))
         (state-metadata
          (dmx-annotation-workspace-architect-state-metadata
           active-state-path
           inherited-events
           leaf-events))
         (transition-metadata
          (dmx-annotation-workspace-architect-transition-metadata
           chart
           transition-effects))
         (dot-text
          (dmx-annotation-workspace-architect-dot
           chart
           current-state
           selected-event
           preview-path
           active-state-path
           transition-effects))
         (view-model
          (make-dmx-annotation-workspace-architect-view-model
           workspace-view-run
           event-groups
           active-state-path
           preview-path)))
    (make-instance 'scxml-architect-session
                   :scxml-path *dmx-annotation-workspace-view-scxml*
                   :chart chart
                   :active-state-path active-state-path
                   :selected-event selected-event
                   :preview-path preview-path
                   :enabled-events
                   (remove-duplicates
                    (mapcar #'dmx-annotation-workspace-view-action-plan-event
                            mapped-action-plans)
                    :test #'string=)
                   :inherited-events inherited-events
                   :leaf-events leaf-events
                   :transition-effects transition-effects
                   :state-metadata state-metadata
                   :transition-metadata transition-metadata
                   :graphviz-dot dot-text
                   :render-target :graphviz-snippet
                   :findings
                   (copy-list
                    (or (dmx-annotation-workspace-view-run-validation-findings-of
                         workspace-view-run)
                        '()))
                   :diagnostics diagnostic-plans
                   :source-object workspace-view-run
                   :presentation-binding view-model)))
