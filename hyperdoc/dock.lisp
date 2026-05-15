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

(defun station-p (object)
  (or (typep object 'dom-annotation-anchor)
      (typep object 'topic)
      (typep object 'topic-page)
      (and object
           (or (ignore-errors (title-of object))
               (ignore-errors (id-of object))))))

(defun operation-station-p (object)
  (cond
    ((typep object 'dom-annotation-anchor)
     (annotation-target-anchor-p object))
    ((and object
          (ignore-errors (eq object (dock-annotation-topic))))
     t)
    ((stringp object)
     (string= object "Annotation"))
    (t
     (string= (dock-object-label object) "Annotation"))))

(defun station-title (station)
  (cond
    ((typep station 'dom-annotation-anchor)
     (or (label-of station)
         (anchor-value-of station)
         (anchor-object-id-of station)
         "station"))
    (t
     (dock-object-label station))))

(defun station-summary (station)
  (cond
    ((typep station 'dom-annotation-anchor)
     (or (text-snippet-of station)
         (durability-note-of station)
         (format nil "Route station anchored by ~A."
                 (station-title station))))
    ((ignore-errors (summary-of station)))
    (t
     (format nil "Route station ~A." (station-title station)))))

(defun available-destinations (source &key context-object)
  (declare (ignore context-object))
  (when (station-p source)
    nil))

(defun available-operations (source &key context-object context-view-title)
  (declare (ignore context-object context-view-title))
  (when (station-p source)
    (list (dock-annotation-topic))))

(defun route-allowed-p (source destination &key context-object)
  (declare (ignore context-object))
  (and (station-p source)
       (or (station-p destination)
           (operation-station-p destination))
       (not (and (typep source 'dom-annotation-anchor)
                 (typep destination 'dom-annotation-anchor)
                 (string= (or (anchor-value-of source) "")
                          (or (anchor-value-of destination) ""))))))

(defun route-safety-level (source destination &key context-object)
  (declare (ignore context-object))
  (cond
    ((not (route-allowed-p source destination))
     :blocked)
    ((operation-station-p destination)
     :safe)
    (t
     :safe)))

(defun create-or-open-operation-route (source operation &key context-object
                                                        context-view-title
                                                        target-anchor
                                                        relation-kind
                                                        note)
  (unless (route-allowed-p source operation :context-object context-object)
    (error "Route from ~A to ~A is not allowed."
           (station-title source)
           (station-title operation)))
  (let* ((resolved-context (or context-object source))
         (source-anchor
          (if (typep source 'dom-annotation-anchor)
              source
              (make-dock-current-object-anchor
               (dock-primary-object source)
               resolved-context
               context-view-title))))
    (cond
      ((or (operation-station-p operation)
           (and target-anchor (annotation-target-anchor-p target-anchor)))
       (dock-annotation-for-source-anchor
        resolved-context
        source-anchor
        :context-view-title context-view-title
        :source-object (dock-annotation-source-object
                        resolved-context
                        source-anchor)
        :target-anchor target-anchor
        :relation-kind relation-kind
        :note note))
      (t
       (error "Unsupported operation route target ~S." operation)))))

(defun create-or-open-route (source destination &key context-object
                                                  context-view-title)
  (unless (route-allowed-p source destination :context-object context-object)
    (error "Route from ~A to ~A is not allowed."
           (station-title source)
           (station-title destination)))
  (if (operation-station-p destination)
      (create-or-open-operation-route
       source
       destination
       :context-object context-object
       :context-view-title context-view-title)
      (let* ((resolved-context (or context-object source))
             (source-anchor
              (if (typep source 'dom-annotation-anchor)
                  source
                  (make-dock-current-object-anchor
                   (dock-primary-object source)
                   resolved-context
                   context-view-title)))
             (target-anchor
              (if (typep destination 'dom-annotation-anchor)
                  destination
                  (make-instance 'dom-annotation-anchor
                                 :provider-kind "dock-v1"
                                 :view-kind "dock-target"
                                 :view-title context-view-title
                                 :context-object-id
                                 (dock-object-stable-id resolved-context)
                                 :strategy "station-object"
                                 :value (dock-object-stable-id destination)
                                 :label (station-title destination)
                                 :durability-tier "medium"
                                 :durability-note
                                 "Dock station-object anchors identify an inspectable station by its current object id or title."
                                 :object-id
                                 (dock-object-stable-id destination)))))
        (make-dom-relation-annotation
         :context-object resolved-context
         :context-view-title context-view-title
         :source-anchor source-anchor
         :target-anchor target-anchor))))

(defun route-evidence (route)
  (cond
    ((typep route 'dock-annotation)
     (list (dock-annotation-model-evidence)
           (dock-annotation-smoke-evidence)))
    ((typep route 'dom-relation-annotation)
     (list (dock-js-coachmark-evidence)
           (dock-css-coachmark-evidence)))
    (t
     nil)))

(defun dock-annotation-topic ()
  (annotation-topic))

(defun make-dock-current-object-anchor (object context-object context-view-title)
  (make-instance 'dom-annotation-anchor
                 :provider-kind "dock-v1"
                 :view-kind "dock-source"
                 :view-title context-view-title
                 :context-object-id (dock-object-stable-id context-object)
                 :strategy "current-object"
                 :value (dock-object-stable-id object)
                 :label (dock-object-label object)
                 :durability-tier "medium"
                 :durability-note
                 "Current-object Dock anchors are synthetic shortcuts for annotating the current inspectable object when no more specific source anchor has been selected."
                 :object-id (dock-object-stable-id object)))

(defun make-dock-annotation-target-anchor (context-object context-view-title)
  (let ((annotation-topic (dock-annotation-topic)))
    (make-instance 'dom-annotation-anchor
                   :provider-kind "dock-v1"
                   :view-kind "dock-target"
                   :view-title context-view-title
                   :context-object-id (dock-object-stable-id context-object)
                   :strategy "annotation-topic"
                   :value (dock-object-stable-id annotation-topic)
                   :label (dock-object-label annotation-topic)
                   :durability-tier "strong"
                   :durability-note
                   "The generic Annotation target is a synthetic authored anchor that classifies the relation as an annotation."
                   :object-id (dock-object-stable-id annotation-topic))))

(defun annotation-target-anchor-p (anchor)
  (and anchor
       (string= (provider-kind-of anchor) "dock-v1")
       (string= (anchor-strategy-of anchor) "annotation-topic")
       (let ((annotation-topic (dock-annotation-topic)))
         (or (string= (or (anchor-object-id-of anchor) "")
                      (dock-object-stable-id annotation-topic))
             (string= (or (anchor-value-of anchor) "")
                      (dock-object-stable-id annotation-topic))))))

(defun dock-current-object-anchor-p (anchor)
  (and anchor
       (string= (provider-kind-of anchor) "dock-v1")
       (string= (anchor-strategy-of anchor) "current-object")))

(defun dock-annotation-source-label (source-anchor)
  (or (label-of source-anchor)
      (anchor-value-of source-anchor)
      "source"))

(defun dock-annotation-default-note (source-anchor context-view-title)
  (format nil
          "Draft annotation for ~A.~@[ Captured from the ~A pane view.~] The selected source remains the thing being annotated, while Annotation is the generic target topic."
          (dock-annotation-source-label source-anchor)
          context-view-title))

(defun dock-annotation-title (source-anchor)
  (format nil "Annotation: ~A" (dock-annotation-source-label source-anchor)))

(defun dock-annotation-summary (source-anchor context-view-title)
  (format nil
          "Annotation relation for ~A.~@[ The relation was opened from the ~A pane view.~] Annotation is the generic target topic."
          (dock-annotation-source-label source-anchor)
          context-view-title))

(defun dock-annotation-key (source-anchor context-object context-view-title
                            &optional target-anchor)
  (let* ((resolved-source-anchor
          (or source-anchor
              (make-dock-current-object-anchor
               (dock-primary-object context-object)
               context-object
               context-view-title)))
         (resolved-target-anchor
          (or target-anchor
              (make-dock-annotation-target-anchor
               context-object
               context-view-title))))
    (dom-relation-annotation-id resolved-source-anchor
                                resolved-target-anchor)))

(defun dock-annotation-source-object (context-object source-anchor)
  (or (and (dock-current-object-anchor-p source-anchor)
           (dock-primary-object context-object))
      (maybe-official-step-for-anchor source-anchor)))

(defun make-dock-annotation (&key context-object
                               context-view-title
                               source-anchor
                               source-object
                               target-anchor
                               relation-kind
                               note)
  (let* ((resolved-source-anchor
          (or source-anchor
              (make-dock-current-object-anchor
               (dock-primary-object context-object)
               context-object
               context-view-title)))
         (annotation-topic (dock-annotation-topic))
         (resolved-target-anchor
          (or target-anchor
              (make-dock-annotation-target-anchor
               context-object
               context-view-title)))
         (registry-key
          (dom-relation-annotation-id resolved-source-anchor
                                      resolved-target-anchor)))
    (make-dom-relation-annotation
     :class 'dock-annotation
     :id registry-key
     :title (dock-annotation-title resolved-source-anchor)
     :summary (dock-annotation-summary
               resolved-source-anchor
               context-view-title)
     :context-object context-object
     :context-view-title context-view-title
     :source-anchor resolved-source-anchor
     :target-anchor resolved-target-anchor
     :source-object (or source-object
                        (dock-annotation-source-object
                         context-object
                         resolved-source-anchor))
     :target-object annotation-topic
     :relation-kind (or relation-kind "annotation")
     :note (or note
               (dock-annotation-default-note
                resolved-source-anchor
                context-view-title))
     :registry-key registry-key
     :dock-capability "Annotation")))

(defun dock-annotation-for-source-anchor (context-object source-anchor
                                          &key context-view-title
                                            source-object
                                            target-anchor
                                            relation-kind
                                            note)
  (let* ((annotation
          (make-dock-annotation
           :context-object context-object
           :context-view-title context-view-title
           :source-anchor source-anchor
           :source-object source-object
           :target-anchor target-anchor
           :relation-kind relation-kind
           :note note))
         (registry-key (id-of annotation)))
    (or (gethash registry-key *dock-annotations*)
        (setf (gethash registry-key *dock-annotations*) annotation))))

(defun find-dock-annotation-for-source-anchor (context-object source-anchor
                                               &key context-view-title
                                                 target-anchor)
  (gethash (dock-annotation-key source-anchor
                                context-object
                                context-view-title
                                target-anchor)
           *dock-annotations*))

(defun dock-annotation-for-context (context-object &key context-view-title
                                                     relation-kind
                                                     note)
  (dock-annotation-for-source-anchor
   context-object
   (make-dock-current-object-anchor
    (dock-primary-object context-object)
    context-object
    context-view-title)
   :context-view-title context-view-title
   :source-object (dock-primary-object context-object)
   :relation-kind relation-kind
   :note note))

(defun find-dock-annotation-for-context (context-object &key context-view-title)
  (find-dock-annotation-for-source-anchor
   context-object
   (make-dock-current-object-anchor
    (dock-primary-object context-object)
    context-object
    context-view-title)
   :context-view-title context-view-title))

(defun annotation-capability-semantic-target (&key context-object
                                                context-view-title
                                                source-json)
  (let* ((source-anchor
          (and source-json
               (maybe-dom-connect-anchor-from-json-string source-json)))
         (existing-annotation
          (cond
            (source-anchor
             (find-dock-annotation-for-source-anchor
              context-object
              source-anchor
              :context-view-title context-view-title))
            (t
             (find-dock-annotation-for-context
              context-object
              :context-view-title context-view-title)))))
    (or existing-annotation
        (annotation-topic))))

(defun dock-zotero-capability-available-p (context-object)
  (and (typep (dock-primary-object context-object) 'topic)
       (zotero-support-enabled-p)
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
   "The current pane snapshot exposes the active Dock presentation state, capability-scoped reason, and introduced capability through the existing Connect inspection seam."
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
   "A focused browser regression proves capability-scoped introduction, Connect active-state ownership, Snippet degraded/rediscovery behavior, and provider handoff behavior without relying on toolbar permanence."
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

(defun dock-annotation-runtime-evidence ()
  (make-dock-implementation-evidence
   "dock-evidence/annotation-runtime"
   "Dock Annotation capability runtime"
   "The Dock capability buttons dispatch plain, Shift, and Option/Alt clicks to semantic annotation or claim/evidence targets without introducing a separate visible Inspect control."
   "source file"
   "assets/hyperdoc/js/dom-annotation-connect.js"
   :target-name "Dock Annotation expert dispatch"))

(defun dock-annotation-model-evidence ()
  (make-dock-implementation-evidence
   "dock-evidence/annotation-model"
   "Dock Annotation semantic model"
   "Current-object Annotation and source->Annotation relations materialize as reusable dock-annotation objects keyed by source and target anchors."
   "source file"
   "hyperdoc/dock.lisp"
   :target-name "annotation-capability-semantic-target"))

(defun dock-annotation-views-evidence ()
  (make-dock-implementation-evidence
   "dock-evidence/annotation-views"
   "Dock Annotation hidden inspection bridges"
   "The connectable surface exposes hidden expert targets so Dock modifier-clicks can inspect Annotation semantics or claim/evidence objects through the existing inspector wiring."
   "source file"
   "hyperdoc-explorer/dom-annotations.lisp"
   :target-name "hyperdoc-dock-annotation-semantic-submit"))

(defun dock-annotation-smoke-evidence ()
  (make-dock-implementation-evidence
   "dock-evidence/annotation-smoke"
   "Dock Annotation smoke coverage"
   "Focused smoke coverage keeps the Dock Annotation relation model stable and reusable across current-object and source->Annotation paths."
   "test"
   "tests/dock-annotation-smoke.lisp"
   :target-name "run-dock-annotation-smoke-tests"))

(defun annotation-capability-evidence-target ()
  (make-instance 'dock-claim-code-relation
                 :id "dock-claim/annotation-capability"
                 :title "Annotation capability stays a semantic relation"
                 :summary "Modifier-click inspection on Annotation opens either the existing semantic relation or the supporting claim/evidence side without adding a permanent Dock Inspect control."
                 :claim-text
                 "Annotation remains a first-class semantic relation anchored in the current pane context; expert inspection can jump either to that relation or to the implementation evidence that explains how the Dock resolves it."
                 :evidence (list (dock-annotation-runtime-evidence)
                                 (dock-annotation-model-evidence)
                                 (dock-annotation-views-evidence)
                                 (dock-annotation-smoke-evidence))))

(defun dock-degrade-chrome-claim ()
  (make-instance 'dock-claim-code-relation
                 :id "dock-claim/degrade-chrome"
                 :title "Degrade chrome, not capability"
                 :summary "When the Dock recedes, Connect and Annotation stay available in compact form while inspection remains in the inspector tabs."
                 :claim-text
                 "The steady-state pane keeps a compact capability strip while removing introduction prose and expanded Dock chrome."
                 :evidence (list (dock-js-coachmark-evidence)
                                 (dock-css-coachmark-evidence)
                                 (dock-playwright-evidence))))

(defun dock-connect-active-claim ()
  (make-instance 'dock-claim-code-relation
                 :id "dock-claim/connect-active"
                 :title "Active Connect keeps task state visible"
                 :summary "During an in-flight Connect gesture, the expanded Dock stays visible with source, next step, and clear/cancel controls."
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
                 :summary "DMX is introduced from the Dock only as a contextual handoff; richer traversal remains in the body-level surface."
                 :claim-text
                 "The Dock may surface a newly relevant provider handoff, but the traversal UI belongs to its own pane surface."
                 :evidence (list (dock-js-coachmark-evidence)
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

(defun dock-mobile-route-strip-claim ()
  (make-instance 'dock-claim-code-relation
                 :id "dock-claim/mobile-route-strip"
                 :title "Mobile Dock uses route-first two-tap flow"
                 :summary "On narrow viewports the Dock collapses to a route strip: tap a source station, then tap a target station or operation."
                 :claim-text
                 "Mobile Dock presentation exposes the Touch-Fahrplan route language first. Connect remains the internal capability, but the visible flow is a compact route strip that latches a source station, accepts a destination station or operation such as Annotation, and opens the first-class route object."
                 :evidence (list (dock-js-coachmark-evidence)
                                 (dock-css-coachmark-evidence)
                                 (dock-playwright-evidence)
                                 (dock-annotation-smoke-evidence))))

(defun dock-latent-state ()
  (make-instance 'dock-presentation-state
                 :id "dock-state/latent"
                 :title "latent"
                 :summary "No expanded coachmark is visible, but compact Dock actions remain available in pane chrome."
                 :compact-representation "Compact capability strip with Connect, Annotation, optional Snippet, and Guide."
                 :expanded-representation "None."
                 :entry-triggers '("Capability is available but no active gesture or coachmark teaching is currently shown.")
                 :exit-conditions '("A newly relevant capability triggers introduction."
                                    "Guide requests rediscovery."
                                    "Connect starts and makes the interaction active.")
                 :capabilities '("Connect" "Annotation" "Snippet")
                 :claims (list (dock-degrade-chrome-claim))))

(defun dock-introduction-state ()
  (make-instance 'dock-presentation-state
                 :id "dock-state/introduction"
                 :title "introduction"
                 :summary "The Dock expands for first contextual teaching of one capability at the chosen presentation-memory scope."
                 :compact-representation "Compact capability strip remains visible underneath the teaching layer."
                 :expanded-representation "Coachmark summary, explanation, and contextual handoff actions."
                 :entry-triggers
                 '("capability.newly_relevant guard: available && teachable && !introduced(capability, scope) && !active_session.")
                 :exit-conditions '("Dismiss coachmark."
                                    "Acknowledge the capability teaching and recede to degraded."
                                    "Start Connect (stateful capability only)."
                                    "Switch to a steady-state pane where only compact access remains.")
                 :capabilities '("Connect" "Annotation" "Snippet" "DMX handoff")
                 :claims (list (dock-degrade-chrome-claim)
                               (dock-provider-handoff-claim))))

(defun dock-active-state ()
  (make-instance 'dock-presentation-state
                 :id "dock-state/active"
                 :title "active"
                 :summary "The Dock stays expanded only for Dock-owned stateful capability sessions."
                 :compact-representation "Compact capability strip remains present, but active Connect state owns the expanded surface."
                 :expanded-representation "Status, next expected step, selected source summary, clear, and cancel."
                 :entry-triggers '("Connect enters choose-source, choose-target, or submitting.")
                 :exit-conditions '("Association succeeds."
                                    "Connect is cancelled."
                                    "Selected source is cleared and the gesture returns to choose-source.")
                 :capabilities '("Connect" "Annotation")
                 :claims (list (dock-connect-active-claim))))

(defun dock-degraded-state ()
  (make-instance 'dock-presentation-state
                 :id "dock-state/degraded"
                 :title "degraded"
                 :summary "The expanded Dock has receded after use, dismissal, or acknowledgement, while the introduced capability remains compactly available."
                 :compact-representation "Compact capability strip only."
                 :expanded-representation "None until rediscovery is requested."
                 :entry-triggers '("Coachmark dismissed."
                                   "Capability acknowledged."
                                   "Connect used once."
                                   "Snippet handoff used once.")
                 :exit-conditions '("Guide requests rediscovery."
                                    "Connect becomes active again (stateful capability).")
                 :capabilities '("Connect" "Annotation" "Snippet")
                 :claims (list (dock-degrade-chrome-claim))))

(defun dock-rediscovery-state ()
  (make-instance 'dock-presentation-state
                 :id "dock-state/rediscovery"
                 :title "rediscovery"
                 :summary "The richer coachmark layer reappears on demand for the currently introduced capability without changing compact availability."
                 :compact-representation "Compact capability strip remains visible."
                 :expanded-representation "Coachmark explanation and contextual handoff actions reopened from Guide."
                 :entry-triggers '("Guide clicked from latent or degraded state for the introduced capability.")
                 :exit-conditions '("Guide closes again."
                                    "Dismiss coachmark."
                                    "Connect becomes active.")
                 :capabilities '("Connect" "Annotation" "Snippet" "DMX handoff")
                 :claims (list (dock-degrade-chrome-claim)
                               (dock-provider-handoff-claim))))

(defun dock-mobile-route-idle-state ()
  (make-instance 'dock-presentation-state
                 :id "dock-mobile-route-state/idle"
                 :title "idle"
                 :summary "The narrow Dock route strip is waiting for the first tap on a source station."
                 :compact-representation "Tap a station"
                 :expanded-representation "No coachmark overlay by default on mobile."
                 :entry-triggers '("Narrow viewport with no latched source or pending route.")
                 :exit-conditions '("Tap a station.")
                 :capabilities '("Lay route")
                 :claims (list (dock-mobile-route-strip-claim))))

(defun dock-mobile-route-source-latched-state ()
  (make-instance 'dock-presentation-state
                 :id "dock-mobile-route-state/source-latched"
                 :title "source-latched"
                 :summary "A source station is latched and the route strip asks for a destination station or operation."
                 :compact-representation "From: <source> -- tap target or operation."
                 :expanded-representation "Only the route operation choices required now, plus Cancel."
                 :entry-triggers '("Tap a source station while the mobile route strip is idle.")
                 :exit-conditions '("Tap destination station."
                                    "Tap destination operation."
                                    "Cancel.")
                 :capabilities '("Lay route" "Annotation" "Cancel")
                 :claims (list (dock-mobile-route-strip-claim))))

(defun dock-mobile-route-destination-candidate-state ()
  (make-instance 'dock-presentation-state
                 :id "dock-mobile-route-state/destination-candidate"
                 :title "destination-candidate"
                 :summary "A destination station or operation has been selected and the route can either complete directly or move to confirmation."
                 :compact-representation "<source> -> <destination>."
                 :expanded-representation "Snap highlight or operation candidate feedback only."
                 :entry-triggers '("Tap destination station or operation from source-latched.")
                 :exit-conditions '("Safe non-mutating route completes."
                                    "Operation that requires confirmation enters confirming.")
                 :capabilities '("Lay route")
                 :claims (list (dock-mobile-route-strip-claim))))

(defun dock-mobile-route-confirming-state ()
  (make-instance 'dock-presentation-state
                 :id "dock-mobile-route-state/confirming"
                 :title "confirming"
                 :summary "A destination operation route is waiting for explicit dry-run or confirmation when the operation is not a safe direct-open route."
                 :compact-representation "<source> -> <operation> with Dry run, Confirm, and Cancel when required."
                 :expanded-representation "No large coachmark overlay by default on mobile."
                 :entry-triggers '("Tap an operation whose safety level requires confirmation.")
                 :exit-conditions '("Dry run keeps confirming with evidence."
                                    "Confirm opens or saves the route."
                                    "Cancel returns to idle.")
                 :capabilities '("Dry run" "Confirm" "Cancel" "Evidence")
                 :claims (list (dock-mobile-route-strip-claim))))

(defun dock-mobile-route-completed-state ()
  (make-instance 'dock-presentation-state
                 :id "dock-mobile-route-state/completed"
                 :title "completed"
                 :summary "The route has been saved or reopened as a first-class inspectable object."
                 :compact-representation "Route saved, with Open route and Evidence when available."
                 :expanded-representation "Normal inspection resumes in inspector tabs or the opened route pane."
                 :entry-triggers '("Safe route completes."
                                   "Confirmed operation route completes.")
                 :exit-conditions '("Open route."
                                    "Open evidence."
                                    "Tap another station.")
                 :capabilities '("Open route" "Evidence" "Lay route")
                 :claims (list (dock-mobile-route-strip-claim))))

(defun dock-introduction-to-active-transition ()
  (make-instance 'dock-presentation-transition
                 :id "dock-transition/introduction-active"
                 :title "Introduction -> Active"
                 :summary "Starting a Dock-owned stateful capability session (Connect) turns teaching into task-state chrome."
                 :from-state (dock-introduction-state)
                 :to-state (dock-active-state)
                 :trigger "Connect clicked while stateful session ownership remains in the Dock."
                 :exit-condition "The pane enters choose-source, choose-target, or submitting."
                 :claims (list (dock-connect-active-claim))))

(defun dock-introduction-to-degraded-transition ()
  (make-instance 'dock-presentation-transition
                 :id "dock-transition/introduction-degraded"
                 :title "Introduction -> Degraded"
                 :summary "Dismissing or acknowledging the capability introduction retracts the Dock to compact capabilities."
                 :from-state (dock-introduction-state)
                 :to-state (dock-degraded-state)
                 :trigger "Dismiss clicked, outside-click dismiss, or explicit acknowledgement."
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

(defun dock-degraded-to-active-transition ()
  (make-instance 'dock-presentation-transition
                 :id "dock-transition/degraded-active"
                 :title "Degraded -> Active"
                 :summary "Direct use of a Dock-owned stateful capability (Connect) re-enters active task-state chrome."
                 :from-state (dock-degraded-state)
                 :to-state (dock-active-state)
                 :trigger "Connect clicked from degraded state."
                 :exit-condition "The pane enters choose-source, choose-target, or submitting."
                 :claims (list (dock-connect-active-claim))))

(defun dock-active-to-degraded-transition ()
  (make-instance 'dock-presentation-transition
                 :id "dock-transition/active-degraded"
                 :title "Active -> Degraded"
                 :summary "When the stateful Connect gesture ends, the Dock recedes to compact capabilities without changing Snippet's non-stateful model."
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

(defun dock-route-idle-to-source-latched-transition ()
  (make-instance 'dock-presentation-transition
                 :id "dock-mobile-route-transition/idle-source-latched"
                 :title "Idle -> Source latched"
                 :summary "The first mobile tap latches a source station without exposing a separate Connect toolbar step."
                 :from-state (dock-mobile-route-idle-state)
                 :to-state (dock-mobile-route-source-latched-state)
                 :trigger "Tap source station."
                 :exit-condition "Route strip shows From: <source> and asks for target or operation."
                 :claims (list (dock-mobile-route-strip-claim))))

(defun dock-route-source-latched-to-destination-candidate-transition ()
  (make-instance 'dock-presentation-transition
                 :id "dock-mobile-route-transition/source-latched-destination-candidate"
                 :title "Source latched -> Destination candidate"
                 :summary "The second mobile tap chooses either a destination station or a destination operation."
                 :from-state (dock-mobile-route-source-latched-state)
                 :to-state (dock-mobile-route-destination-candidate-state)
                 :trigger "Tap destination station or operation."
                 :exit-condition "Route target is known and safety can be evaluated."
                 :claims (list (dock-mobile-route-strip-claim))))

(defun dock-route-destination-candidate-to-completed-transition ()
  (make-instance 'dock-presentation-transition
                 :id "dock-mobile-route-transition/destination-candidate-completed"
                 :title "Destination candidate -> Completed"
                 :summary "Safe non-mutating routes complete directly and open or reuse the first-class route object."
                 :from-state (dock-mobile-route-destination-candidate-state)
                 :to-state (dock-mobile-route-completed-state)
                 :trigger "route-safety-level returns :safe."
                 :exit-condition "Route saved and normal inspection resumes."
                 :claims (list (dock-mobile-route-strip-claim))))

(defun dock-route-destination-candidate-to-confirming-transition ()
  (make-instance 'dock-presentation-transition
                 :id "dock-mobile-route-transition/destination-candidate-confirming"
                 :title "Destination candidate -> Confirming"
                 :summary "Operation routes that are mutating or dangerous require explicit confirmation."
                 :from-state (dock-mobile-route-destination-candidate-state)
                 :to-state (dock-mobile-route-confirming-state)
                 :trigger "route-safety-level requires confirmation."
                 :exit-condition "Dry run, Confirm, and Cancel are the only required controls."
                 :claims (list (dock-mobile-route-strip-claim))))

(defun dock-route-confirming-dry-run-transition ()
  (make-instance 'dock-presentation-transition
                 :id "dock-mobile-route-transition/confirming-dry-run"
                 :title "Confirming -> Confirming"
                 :summary "Dry run keeps the operation route in confirming state while adding evidence."
                 :from-state (dock-mobile-route-confirming-state)
                 :to-state (dock-mobile-route-confirming-state)
                 :trigger "Dry run."
                 :exit-condition "Evidence is available without committing the operation route."
                 :claims (list (dock-mobile-route-strip-claim))))

(defun dock-route-confirming-to-completed-transition ()
  (make-instance 'dock-presentation-transition
                 :id "dock-mobile-route-transition/confirming-completed"
                 :title "Confirming -> Completed"
                 :summary "Confirm commits or opens the operation route and returns inspection to the normal pane surface."
                 :from-state (dock-mobile-route-confirming-state)
                 :to-state (dock-mobile-route-completed-state)
                 :trigger "Confirm."
                 :exit-condition "Route saved or reopened."
                 :claims (list (dock-mobile-route-strip-claim))))

(defun dock-route-completed-to-idle-transition ()
  (make-instance 'dock-presentation-transition
                 :id "dock-mobile-route-transition/completed-idle"
                 :title "Completed -> Idle"
                 :summary "Opening the route or evidence clears the compact completed state and normal inspection continues."
                 :from-state (dock-mobile-route-completed-state)
                 :to-state (dock-mobile-route-idle-state)
                 :trigger "Open route, open evidence, or start another route."
                 :exit-condition "Route strip returns to Tap a station."
                 :claims (list (dock-mobile-route-strip-claim))))

(defun dock-presentation-model ()
  (make-instance 'dock-presentation-model
                 :id "dock-presentation-model"
                 :title "Dock presentation model"
                 :summary "Inspectable SCXML-style state model for Dock presentation: desktop coachmark behavior plus the mobile route-first strip."
                 :states (list (dock-latent-state)
                               (dock-introduction-state)
                               (dock-active-state)
                               (dock-degraded-state)
                               (dock-rediscovery-state)
                               (dock-mobile-route-idle-state)
                               (dock-mobile-route-source-latched-state)
                               (dock-mobile-route-destination-candidate-state)
                               (dock-mobile-route-confirming-state)
                               (dock-mobile-route-completed-state))
                 :transitions (list (dock-introduction-to-active-transition)
                                    (dock-introduction-to-degraded-transition)
                                    (dock-degraded-to-active-transition)
                                    (dock-active-to-degraded-transition)
                                    (dock-degraded-to-rediscovery-transition)
                                    (dock-rediscovery-to-degraded-transition)
                                    (dock-route-idle-to-source-latched-transition)
                                    (dock-route-source-latched-to-destination-candidate-transition)
                                    (dock-route-destination-candidate-to-completed-transition)
                                    (dock-route-destination-candidate-to-confirming-transition)
                                    (dock-route-confirming-dry-run-transition)
                                    (dock-route-confirming-to-completed-transition)
                                    (dock-route-completed-to-idle-transition))
                 :claims (list (dock-degrade-chrome-claim)
                               (dock-connect-active-claim)
                               (dock-provider-handoff-claim)
                               (dock-runtime-inspection-claim)
                               (dock-mobile-route-strip-claim))))

(defun chunk-dock-presentation-model ()
  (dock-presentation-model))

(defun guide-capability-model-target ()
  (dock-presentation-model))

(defun guide-capability-evidence-target ()
  (dock-runtime-inspection-claim))
