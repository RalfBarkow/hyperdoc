;;;; Pane-local Dock capabilities and generic annotations
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defclass dock-annotation (dom-relation-annotation)
  ((dock-capability :reader dock-capability-of
                    :initarg :dock-capability
                    :initform "Annotation")
   (registry-key :reader registry-key-of
                 :initarg :registry-key
                 :initform nil)))

(defparameter *dock-annotations* (make-hash-table :test #'equal))

(defgeneric dock-primary-object (object)
  (:documentation
   "Return the current inspectable thing that Dock actions should treat as
the primary pane-local object in this slice."))

(defmethod dock-primary-object ((page topic-page))
  (topic-of page))

(defmethod dock-primary-object ((object t))
  object)

(defun dock-object-label (object)
  (or (ignore-errors (title-of object))
      (ignore-errors (id-of object))
      (format nil "~A" object)))

(defun dock-object-stable-id (object)
  (or (ignore-errors (id-of object))
      (ignore-errors (title-of object))
      (format nil "~A" object)))

(defun dock-annotation-topic ()
  (annotation-topic))

(defun make-dock-capability-anchor (capability context-object context-view-title)
  (let ((annotation-topic (dock-annotation-topic)))
    (make-instance 'dom-annotation-anchor
                   :provider-kind "dock-v1"
                   :view-kind "dock"
                   :view-title context-view-title
                   :context-object-id (dock-object-stable-id context-object)
                   :strategy "dock-capability"
                   :value (string-downcase capability)
                   :label capability
                   :durability-tier "strong"
                   :durability-note
                   "Dock capability anchors are synthetic authored anchors for pane-local actions."
                   :object-id (dock-object-stable-id annotation-topic))))

(defun make-dock-object-anchor (object context-object context-view-title)
  (make-instance 'dom-annotation-anchor
                 :provider-kind "dock-v1"
                 :view-kind "dock-target"
                 :view-title context-view-title
                 :context-object-id (dock-object-stable-id context-object)
                 :strategy "current-object"
                 :value (dock-object-stable-id object)
                 :label (dock-object-label object)
                 :durability-tier "medium"
                 :durability-note
                 "This first Dock slice targets the current pane object rather than a specific DOM anchor."
                 :object-id (dock-object-stable-id object)))

(defun dock-annotation-default-note (target-object context-view-title)
  (format nil
          "Draft annotation for ~A.~@[ Captured from the ~A pane view.~] This first Dock slice targets the current pane object rather than a specific DOM anchor."
          (dock-object-label target-object)
          context-view-title))

(defun dock-annotation-title (target-object)
  (format nil "Annotation: ~A" (dock-object-label target-object)))

(defun dock-annotation-summary (target-object context-view-title)
  (format nil
          "Generic Dock annotation for ~A.~@[ The annotation was opened from the ~A pane view.~]"
          (dock-object-label target-object)
          context-view-title))

(defun dock-annotation-key (context-object context-view-title &optional target-anchor)
  (let* ((target-object (dock-primary-object context-object))
         (source-anchor (make-dock-capability-anchor
                         "Annotation"
                         context-object
                         context-view-title))
         (resolved-target-anchor
           (or target-anchor
               (make-dock-object-anchor
                target-object context-object context-view-title))))
    (dom-relation-annotation-id source-anchor resolved-target-anchor)))

(defun make-dock-annotation (&key context-object
                                  context-view-title
                                  target-anchor
                                  target-object
                                  relation-kind
                                  note)
  (let* ((resolved-target-object
           (or target-object
               (dock-primary-object context-object)))
         (source-topic (dock-annotation-topic))
         (source-anchor
           (make-dock-capability-anchor
            "Annotation"
            context-object
            context-view-title))
         (resolved-target-anchor
           (or target-anchor
               (make-dock-object-anchor
                resolved-target-object
                context-object
                context-view-title)))
         (registry-key
           (dom-relation-annotation-id source-anchor resolved-target-anchor)))
    (make-dom-relation-annotation
     :class 'dock-annotation
     :id registry-key
     :title (dock-annotation-title resolved-target-object)
     :summary (dock-annotation-summary
               resolved-target-object
               context-view-title)
     :context-object context-object
     :context-view-title context-view-title
     :source-anchor source-anchor
     :target-anchor resolved-target-anchor
     :source-object source-topic
     :target-object resolved-target-object
     :relation-kind (or relation-kind "annotation")
     :note (or note
               (dock-annotation-default-note
                resolved-target-object
                context-view-title))
     :registry-key registry-key
     :dock-capability "Annotation")))

(defun dock-annotation-for-context (context-object &key context-view-title
                                                   target-anchor
                                                   target-object
                                                   relation-kind
                                                   note)
  (let* ((annotation
           (make-dock-annotation
            :context-object context-object
            :context-view-title context-view-title
            :target-anchor target-anchor
            :target-object target-object
            :relation-kind relation-kind
            :note note))
         (registry-key (id-of annotation)))
    (or (gethash registry-key *dock-annotations*)
        (setf (gethash registry-key *dock-annotations*) annotation))))

(defun dock-inspect-object-for-context (context-object)
  (dock-primary-object context-object))

(defun dock-zotero-capability-available-p (context-object)
  (and (typep (dock-primary-object context-object) 'topic)
       (let ((bridge (ignore-errors (make-default-zotero-library-bridge))))
         (and bridge
              (not (zotero-backend-unavailable-p bridge))))))

(defun chunk-dock-annotation ()
  (dock-annotation-for-context
   (find-page *topics* "Chunk" :signal-error? t)
   :context-view-title "Content"))

(defclass dock-presentation-model ()
  ((id :reader id-of :initarg :id)
   (title :reader title-of :initarg :title)
   (summary :reader summary-of :initarg :summary)
   (states :reader states-of :initarg :states :initform nil)
   (transitions :reader transitions-of :initarg :transitions :initform nil)
   (claims :reader claims-of :initarg :claims :initform nil)))

(defclass dock-presentation-state ()
  ((id :reader id-of :initarg :id)
   (title :reader title-of :initarg :title)
   (summary :reader summary-of :initarg :summary)
   (compact-representation :reader compact-representation-of
                           :initarg :compact-representation
                           :initform nil)
   (expanded-representation :reader expanded-representation-of
                            :initarg :expanded-representation
                            :initform nil)
   (entry-triggers :reader entry-triggers-of :initarg :entry-triggers :initform nil)
   (exit-conditions :reader exit-conditions-of :initarg :exit-conditions :initform nil)
   (capabilities :reader capabilities-of :initarg :capabilities :initform nil)
   (claims :reader claims-of :initarg :claims :initform nil)))

(defclass dock-presentation-transition ()
  ((id :reader id-of :initarg :id)
   (title :reader title-of :initarg :title)
   (summary :reader summary-of :initarg :summary)
   (from-state :reader from-state-of :initarg :from-state)
   (to-state :reader to-state-of :initarg :to-state)
   (trigger :reader trigger-of :initarg :trigger :initform nil)
   (exit-condition :reader exit-condition-of :initarg :exit-condition :initform nil)
   (claims :reader claims-of :initarg :claims :initform nil)))

(defclass dock-claim-code-relation ()
  ((id :reader id-of :initarg :id)
   (title :reader title-of :initarg :title)
   (summary :reader summary-of :initarg :summary)
   (claim-text :reader claim-text-of :initarg :claim-text)
   (evidence :reader evidence-of :initarg :evidence :initform nil)))

(defclass dock-implementation-evidence ()
  ((id :reader id-of :initarg :id)
   (title :reader title-of :initarg :title)
   (summary :reader summary-of :initarg :summary)
   (surface-kind :reader surface-kind-of :initarg :surface-kind :initform nil)
   (relative-path :reader relative-path-of :initarg :relative-path :initform nil)
   (target-name :reader target-name-of :initarg :target-name :initform nil)))

(defmethod print-object ((object dock-presentation-model) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object dock-presentation-state) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object dock-presentation-transition) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object dock-claim-code-relation) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object dock-implementation-evidence) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defun make-dock-implementation-evidence (id title summary surface-kind relative-path
                                          &key target-name)
  (make-instance 'dock-implementation-evidence
                 :id id
                 :title title
                 :summary summary
                 :surface-kind surface-kind
                 :relative-path relative-path
                 :target-name target-name))

(defun dock-js-coachmark-evidence ()
  (make-dock-implementation-evidence
   "dock-evidence/js-coachmark"
   "Dock coachmark runtime state"
   "The pane-local presentation state machine, compact-row behavior, and provider handoff rules live in the browser-side Dock runtime."
   "source file"
   "assets/hyperdoc/js/dom-annotation-connect.js"
   :target-name "dock presentation runtime"))

(defun dock-css-coachmark-evidence ()
  (make-dock-implementation-evidence
   "dock-evidence/css-coachmark"
   "Dock coachmark chrome styling"
   "The compact-versus-expanded Dock appearance and degraded chrome styling are defined in the Dock CSS."
   "source file"
   "assets/hyperdoc/css/dom-annotation-connect.css"
   :target-name "dock coachmark styling"))

(defun dock-pane-snapshot-evidence ()
  (make-dock-implementation-evidence
   "dock-evidence/pane-snapshot"
   "Dock presentation state snapshot"
   "The current pane snapshot exposes the active Dock presentation state and reason through the existing Connect inspection seam."
   "source file"
   "hyperdoc/dom-annotations.lisp"
   :target-name "dom-connect-pane-state-snapshot"))

(defun dock-pane-view-evidence ()
  (make-dock-implementation-evidence
   "dock-evidence/pane-view"
   "Dock presentation inspection view"
   "Explorer views render the inspectable Dock state-model and current pane snapshot fields."
   "source file"
   "hyperdoc-explorer/dock.lisp"
   :target-name "dock presentation explorer views"))

(defun dock-touch-fahrplan-evidence ()
  (make-dock-implementation-evidence
   "dock-evidence/touch-fahrplan"
   "Touch-Fahrplan body workflow"
   "The richer Touch-Fahrplan route workflow remains in the topic-pane body surface instead of becoming a permanent Dock identity."
   "source file"
   "hyperdoc-explorer/topic-enrichment.lisp"
   :target-name "Touch-Fahrplan topic view"))

(defun dock-dmx-evidence ()
  (make-dock-implementation-evidence
   "dock-evidence/dmx-external"
   "DMX body handoff"
   "DMX traversal remains in the DMX pane surfaces such as the External tab rather than a permanent Dock toolbar identity."
   "source file"
   "hyperdoc-inspector/dmx-topics.lisp"
   :target-name "DMX topic proxy inspector views"))

(defun dock-playwright-evidence ()
  (make-dock-implementation-evidence
   "dock-evidence/playwright"
   "Dock coachmark browser regression"
   "A focused browser regression proves introduction, active, degraded, and Touch-Fahrplan handoff behavior without relying on toolbar permanence."
   "test"
   "tests/playwright/dock-presentation.spec.js"
   :target-name "Dock coachmark states degrade chrome without removing capability"))

(defun dock-smoke-evidence ()
  (make-dock-implementation-evidence
   "dock-evidence/smoke"
   "Dock model smoke coverage"
   "Focused Lisp smoke coverage keeps the inspectable Dock state model and its claim-code evidence chain materialized."
   "test"
   "tests/dock-presentation-smoke.lisp"
   :target-name "run-dock-presentation-smoke-tests"))

(defun dock-degrade-chrome-claim ()
  (make-instance 'dock-claim-code-relation
                 :id "dock-claim/degrade-chrome"
                 :title "Degrade chrome, not capability"
                 :summary "When the Dock recedes, Connect, Inspect, and Annotation stay available in compact form."
                 :claim-text
                 "The steady-state pane keeps a compact capability strip while removing introduction prose and expanded Dock chrome."
                 :evidence (list (dock-js-coachmark-evidence)
                                 (dock-css-coachmark-evidence)
                                 (dock-playwright-evidence))))

(defun dock-connect-active-claim ()
  (make-instance 'dock-claim-code-relation
                 :id "dock-claim/connect-active"
                 :title "Active Connect keeps task state visible"
                 :summary "During an in-flight Connect gesture, the expanded Dock stays visible with source, next step, clear/cancel, and state inspection."
                 :claim-text
                 "Connect uses the expanded coachmark only while the interaction is stateful, and the same pane snapshot exposes why the Dock is visible now."
                 :evidence (list (dock-js-coachmark-evidence)
                                 (dock-pane-snapshot-evidence)
                                 (dock-pane-view-evidence)
                                 (dock-playwright-evidence))))

(defun dock-provider-handoff-claim ()
  (make-instance 'dock-claim-code-relation
                 :id "dock-claim/provider-handoff"
                 :title "Provider-specific workflows stay in the pane body"
                 :summary "Touch-Fahrplan and DMX are introduced from the Dock only as contextual handoffs; their richer workflow remains in the body-level surface."
                 :claim-text
                 "The Dock may surface a newly relevant provider handoff, but the route or traversal UI belongs to its own pane surface."
                 :evidence (list (dock-js-coachmark-evidence)
                                 (dock-touch-fahrplan-evidence)
                                 (dock-dmx-evidence)
                                 (dock-playwright-evidence))))

(defun dock-runtime-inspection-claim ()
  (make-instance 'dock-claim-code-relation
                 :id "dock-claim/runtime-inspection"
                 :title "Dock presentation state is inspectable"
                 :summary "The current pane snapshot and the durable Dock model make the runtime presentation state and its implementation evidence inspectable."
                 :claim-text
                 "The Dock state model is not only prose; it is reified as inspectable objects and current pane snapshots carry the active presentation state."
                 :evidence (list (dock-pane-snapshot-evidence)
                                 (dock-pane-view-evidence)
                                 (dock-smoke-evidence))))

(defun dock-latent-state ()
  (make-instance 'dock-presentation-state
                 :id "dock-state/latent"
                 :title "latent"
                 :summary "No expanded coachmark is visible, but compact Connect, Inspect, and Annotation actions remain in the pane chrome."
                 :compact-representation "Compact capability strip with Connect, Inspect, Annotation, and Guide."
                 :expanded-representation "None."
                 :entry-triggers '("Capability is available but no active gesture or coachmark teaching is currently shown.")
                 :exit-conditions '("A newly relevant capability triggers introduction."
                                    "Guide requests rediscovery."
                                    "Connect starts and makes the interaction active.")
                 :capabilities '("Connect" "Inspect" "Annotation")
                 :claims (list (dock-degrade-chrome-claim))))

(defun dock-introduction-state ()
  (make-instance 'dock-presentation-state
                 :id "dock-state/introduction"
                 :title "introduction"
                 :summary "The Dock expands because a capability has become newly relevant and needs teaching."
                 :compact-representation "Compact capability strip remains visible underneath the teaching layer."
                 :expanded-representation "Coachmark summary, explanation, and contextual handoff actions."
                 :entry-triggers '("First newly relevant Dock capability in the current browser session.")
                 :exit-conditions '("Dismiss coachmark."
                                    "Start Connect."
                                    "Switch to a steady-state pane where only compact access remains.")
                 :capabilities '("Connect" "Inspect" "Annotation" "Touch-Fahrplan handoff" "DMX handoff")
                 :claims (list (dock-degrade-chrome-claim)
                               (dock-provider-handoff-claim))))

(defun dock-active-state ()
  (make-instance 'dock-presentation-state
                 :id "dock-state/active"
                 :title "active"
                 :summary "The Dock stays expanded while the user is mid-gesture so task state remains visible."
                 :compact-representation "Compact capability strip remains present, but active Connect state owns the expanded surface."
                 :expanded-representation "Status, next expected step, selected source summary, clear, cancel, and Connect-state inspection."
                 :entry-triggers '("Connect enters choose-source, choose-target, or submitting.")
                 :exit-conditions '("Association succeeds."
                                    "Connect is cancelled."
                                    "Selected source is cleared and the gesture returns to choose-source.")
                 :capabilities '("Connect" "Inspect" "Annotation")
                 :claims (list (dock-connect-active-claim))))

(defun dock-degraded-state ()
  (make-instance 'dock-presentation-state
                 :id "dock-state/degraded"
                 :title "degraded"
                 :summary "The expanded Dock has receded after use or dismissal, but the same capability remains available in lighter form."
                 :compact-representation "Compact capability strip only."
                 :expanded-representation "None until rediscovery is requested."
                 :entry-triggers '("Coachmark dismissed."
                                    "Connect used once."
                                    "A sibling Dock action demonstrated the capability cluster.")
                 :exit-conditions '("Guide requests rediscovery."
                                    "Connect becomes active again.")
                 :capabilities '("Connect" "Inspect" "Annotation")
                 :claims (list (dock-degrade-chrome-claim))))

(defun dock-rediscovery-state ()
  (make-instance 'dock-presentation-state
                 :id "dock-state/rediscovery"
                 :title "rediscovery"
                 :summary "The richer coachmark layer reappears on demand without changing the underlying compact capability model."
                 :compact-representation "Compact capability strip remains visible."
                 :expanded-representation "Coachmark explanation and contextual handoff actions reopened from Guide."
                 :entry-triggers '("Guide clicked from latent or degraded state.")
                 :exit-conditions '("Guide closes again."
                                    "Dismiss coachmark."
                                    "Connect becomes active.")
                 :capabilities '("Connect" "Inspect" "Annotation" "Touch-Fahrplan handoff" "DMX handoff")
                 :claims (list (dock-degrade-chrome-claim)
                               (dock-provider-handoff-claim))))

(defun dock-introduction-to-active-transition ()
  (make-instance 'dock-presentation-transition
                 :id "dock-transition/introduction-active"
                 :title "Introduction -> Active"
                 :summary "Starting Connect turns the teaching layer into task-state chrome."
                 :from-state (dock-introduction-state)
                 :to-state (dock-active-state)
                 :trigger "Connect clicked."
                 :exit-condition "The pane enters choose-source or choose-target."
                 :claims (list (dock-connect-active-claim))))

(defun dock-introduction-to-degraded-transition ()
  (make-instance 'dock-presentation-transition
                 :id "dock-transition/introduction-degraded"
                 :title "Introduction -> Degraded"
                 :summary "Dismissing the coachmark retracts the Dock to compact capabilities."
                 :from-state (dock-introduction-state)
                 :to-state (dock-degraded-state)
                 :trigger "Dismiss clicked or the teaching layer is explicitly closed."
                 :exit-condition "Compact actions remain visible."
                 :claims (list (dock-degrade-chrome-claim))))

(defun dock-degraded-to-rediscovery-transition ()
  (make-instance 'dock-presentation-transition
                 :id "dock-transition/degraded-rediscovery"
                 :title "Degraded -> Rediscovery"
                 :summary "Guide reopens the expanded coachmark without changing the underlying capability set."
                 :from-state (dock-degraded-state)
                 :to-state (dock-rediscovery-state)
                 :trigger "Guide clicked."
                 :exit-condition "The expanded coachmark is visible again."
                 :claims (list (dock-degrade-chrome-claim))))

(defun dock-active-to-degraded-transition ()
  (make-instance 'dock-presentation-transition
                 :id "dock-transition/active-degraded"
                 :title "Active -> Degraded"
                 :summary "When the stateful Connect gesture ends, the Dock recedes to compact capabilities."
                 :from-state (dock-active-state)
                 :to-state (dock-degraded-state)
                 :trigger "Connect succeeds or is cancelled."
                 :exit-condition "No expanded task-state chrome remains."
                 :claims (list (dock-connect-active-claim)
                               (dock-degrade-chrome-claim))))

(defun dock-rediscovery-to-degraded-transition ()
  (make-instance 'dock-presentation-transition
                 :id "dock-transition/rediscovery-degraded"
                 :title "Rediscovery -> Degraded"
                 :summary "Closing rediscovery returns the pane to compact capabilities."
                 :from-state (dock-rediscovery-state)
                 :to-state (dock-degraded-state)
                 :trigger "Guide closed or coachmark dismissed."
                 :exit-condition "Compact capability strip remains."
                 :claims (list (dock-degrade-chrome-claim))))

(defun dock-presentation-model ()
  (make-instance 'dock-presentation-model
                 :id "dock-presentation-model"
                 :title "Dock presentation model"
                 :summary "Inspectable state model for the Dock as a progressive enhancement over inspector tabs: introduction and active states expand the coachmark, while latent, degraded, and rediscovery keep capability and chrome separate."
                 :states (list (dock-latent-state)
                               (dock-introduction-state)
                               (dock-active-state)
                               (dock-degraded-state)
                               (dock-rediscovery-state))
                 :transitions (list (dock-introduction-to-active-transition)
                                    (dock-introduction-to-degraded-transition)
                                    (dock-active-to-degraded-transition)
                                    (dock-degraded-to-rediscovery-transition)
                                    (dock-rediscovery-to-degraded-transition))
                 :claims (list (dock-degrade-chrome-claim)
                               (dock-connect-active-claim)
                               (dock-provider-handoff-claim)
                               (dock-runtime-inspection-claim))))

(defun chunk-dock-presentation-model ()
  (dock-presentation-model))
