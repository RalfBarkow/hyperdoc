;;;; First-class layout topicmap objects for inspector Reel layout editing.

(in-package :hyperdoc)

(defclass layout-topic ()
  ((id :initarg :id :reader id-of)
   (title :initarg :title :reader title-of)
   (selector :initarg :selector :reader layout-topic-selector-of)
   (element-id :initarg :element-id :initform nil
               :reader layout-topic-element-id-of)
   (class-list :initarg :class-list :initform nil
               :reader layout-topic-class-list-of)
   (bounding-box :initarg :bounding-box :initform nil
                 :reader layout-topic-bounding-box-of)
   (scroll-context :initarg :scroll-context :initform nil
                   :reader layout-topic-scroll-context-of)
   (kind :initarg :kind :reader kind-of)
   (role :initarg :role :initform nil :reader layout-topic-role-of)
   (stability :initarg :stability :initform :selector-and-class-contract
              :reader layout-topic-stability-of)
   (evidence :initarg :evidence :initform nil :reader evidence-of)))

(defclass layout-relation ()
  ((id :initarg :id :reader id-of)
   (kind :initarg :kind :reader kind-of)
   (from :initarg :from :reader from-of)
   (to :initarg :to :reader to-of)
   (evidence :initarg :evidence :initform nil :reader evidence-of)))

(defclass layout-topicmap ()
  ((id :initarg :id :reader id-of)
   (title :initarg :title :reader title-of)
   (source :initarg :source :initform "HyperDoc inspector Reel"
           :reader source-of)
   (topics :initarg :topics :initform nil :reader topics-of)
   (relations :initarg :relations :initform nil :reader relations-of)
   (layout :initarg :layout :initform nil :reader layout-of)
   (captured-at :initarg :captured-at :initform :static-reel-subset
                :reader layout-topicmap-captured-at-of)
   (evidence :initarg :evidence :initform nil :reader evidence-of)))

(defclass layout-patch ()
  ((id :initarg :id :reader id-of)
   (title :initarg :title :reader title-of)
   (before-topicmap :initarg :before-topicmap
                    :reader layout-patch-before-topicmap-of)
   (after-topicmap :initarg :after-topicmap
                   :reader layout-patch-after-topicmap-of)
   (source-evidence :initarg :source-evidence :initform nil
                    :reader layout-patch-source-evidence-of)
   (target-evidence :initarg :target-evidence :initform nil
                    :reader layout-patch-target-evidence-of)
   (proposed-implementation-effect
    :initarg :proposed-implementation-effect
    :reader layout-patch-proposed-implementation-effect-of)
   (apply-policy :initarg :apply-policy
                 :initform :create-durable-layout-override
                 :reader layout-patch-apply-policy-of)))

(defclass move-topic-into-box-patch (layout-patch)
  ((topic-id :initarg :topic-id :reader layout-patch-topic-id-of)
   (from-parent-id :initarg :from-parent-id
                   :reader layout-patch-from-parent-id-of)
   (to-parent-id :initarg :to-parent-id
                 :reader layout-patch-to-parent-id-of)
   (relation-kind :initarg :relation-kind :initform :contains
                  :reader layout-patch-relation-kind-of)
   (placement :initarg :placement :initform :bottom-control-rail
              :reader layout-patch-placement-of)
   (preserve :initarg :preserve :initform nil
             :reader layout-patch-preserve-of)))

(defclass layout-rule ()
  ((id :initarg :id :reader id-of)
   (title :initarg :title :reader title-of)
   (description :initarg :description :reader layout-rule-description-of)
   (invariant :initarg :invariant :reader layout-rule-invariant-of)
   (severity :initarg :severity :initform :hard
             :reader layout-rule-severity-of)
   (evidence :initarg :evidence :initform nil :reader evidence-of)))

(defclass layout-renderer-effect ()
  ((id :initarg :id :reader id-of)
   (title :initarg :title :reader title-of)
   (phase :initarg :phase :reader layout-renderer-effect-phase-of)
   (kind :initarg :kind :reader kind-of)
   (target :initarg :target :reader layout-renderer-effect-target-of)
   (placement :initarg :placement :initform nil
              :reader layout-renderer-effect-placement-of)
   (style-property :initarg :style-property :initform nil
                   :reader layout-renderer-effect-style-property-of)
   (style-value :initarg :style-value :initform nil
                :reader layout-renderer-effect-style-value-of)
   (attributes :initarg :attributes :initform nil
               :reader layout-renderer-effect-attributes-of)
   (replay :initarg :replay :initform nil
           :reader layout-renderer-effect-replay-of)
   (evidence :initarg :evidence :initform nil :reader evidence-of)))

(defclass layout-rule-failure ()
  ((id :initarg :id :reader id-of)
   (title :initarg :title :reader title-of)
   (rule-id :initarg :rule-id :reader layout-rule-failure-rule-id-of)
   (message :initarg :message :reader layout-rule-failure-message-of)
   (evidence :initarg :evidence :initform nil :reader evidence-of)))

(defclass layout-rule-result ()
  ((id :initarg :id :reader id-of)
   (title :initarg :title :reader title-of)
   (rule :initarg :rule :reader layout-rule-result-rule-of)
   (status :initarg :status :reader layout-rule-result-status-of)
   (message :initarg :message :reader layout-rule-result-message-of)
   (renderer-effects :initarg :renderer-effects :initform nil
                     :reader layout-rule-result-renderer-effects-of)
   (failure :initarg :failure :initform nil
            :reader layout-rule-result-failure-of)
   (evidence :initarg :evidence :initform nil :reader evidence-of)))

(defclass layout-repair-plan ()
  ((id :initarg :id :reader id-of)
   (title :initarg :title :reader title-of)
   (patch :initarg :patch :reader layout-repair-plan-patch-of)
   (rule-results :initarg :rule-results :reader layout-repair-plan-rule-results-of)
   (renderer-effects :initarg :renderer-effects
                     :reader layout-repair-plan-renderer-effects-of)
   (status :initarg :status :reader layout-repair-plan-status-of)
   (failure-modes :initarg :failure-modes :initform nil
                  :reader layout-repair-plan-failure-modes-of)
   (preview-apply-boundary :initarg :preview-apply-boundary
                           :reader layout-repair-plan-preview-apply-boundary-of)
   (evidence :initarg :evidence :initform nil :reader evidence-of)))

(defclass layout-override ()
  ((id :initarg :id :reader id-of)
   (title :initarg :title :reader title-of)
   (source-patch-id :initarg :source-patch-id
                    :reader layout-override-source-patch-id-of)
   (source-repair-plan-id :initarg :source-repair-plan-id
                          :reader layout-override-source-repair-plan-id-of)
   (topic-id :initarg :topic-id :reader layout-override-topic-id-of)
   (from-parent-id :initarg :from-parent-id
                   :reader layout-override-from-parent-id-of)
   (to-parent-id :initarg :to-parent-id
                 :reader layout-override-to-parent-id-of)
   (relation-kind :initarg :relation-kind :initform :contains
                  :reader layout-override-relation-kind-of)
   (placement :initarg :placement :initform :bottom-control-rail
              :reader layout-override-placement-of)
   (preserve :initarg :preserve :initform nil
             :reader layout-override-preserve-of)
   (before-topicmap :initarg :before-topicmap
                    :reader layout-override-before-topicmap-of)
   (after-topicmap :initarg :after-topicmap
                   :reader layout-override-after-topicmap-of)
   (rule-results :initarg :rule-results :initform nil
                 :reader layout-override-rule-results-of)
   (renderer-effects :initarg :renderer-effects :initform nil
                     :reader layout-override-renderer-effects-of)
   (evidence :initarg :evidence :initform nil :reader evidence-of)
   (created-at :initarg :created-at :reader layout-override-created-at-of)
   (revert-info :initarg :revert-info :initform nil
                :reader layout-override-revert-info-of)
   (replay-status :initarg :replay-status :initform :pending
                  :reader layout-override-replay-status-of)
   (replay-failure :initarg :replay-failure :initform nil
                   :reader layout-override-replay-failure-of)))

(defclass layout-override-store ()
  ((id :initarg :id :initform "layout-override-store" :reader id-of)
   (title :initarg :title :initform "layout-override-store" :reader title-of)
   (storage-kind :initarg :storage-kind :initform :browser-local-storage
                 :reader layout-override-store-storage-kind-of)
   (storage-key :initarg :storage-key
                :initform "hyperdoc.layout.overrides.v1"
                :reader layout-override-store-storage-key-of)
   (overrides :initarg :overrides :initform nil
              :reader layout-override-store-overrides-of)
   (evidence :initarg :evidence :initform nil :reader evidence-of)))

(defmethod print-object ((topic layout-topic) stream)
  (print-unreadable-object (topic stream :type t :identity nil)
    (format stream "~A" (id-of topic))))

(defmethod print-object ((relation layout-relation) stream)
  (print-unreadable-object (relation stream :type t :identity nil)
    (format stream "~A ~A -> ~A"
            (kind-of relation)
            (from-of relation)
            (to-of relation))))

(defmethod print-object ((topicmap layout-topicmap) stream)
  (print-unreadable-object (topicmap stream :type t :identity nil)
    (format stream "~A (~D topics, ~D relations)"
            (title-of topicmap)
            (length (topics-of topicmap))
            (length (relations-of topicmap)))))

(defmethod print-object ((patch move-topic-into-box-patch) stream)
  (print-unreadable-object (patch stream :type t :identity nil)
    (format stream "~A: ~A -> ~A"
            (layout-patch-topic-id-of patch)
            (layout-patch-from-parent-id-of patch)
            (layout-patch-to-parent-id-of patch))))

(defmethod print-object ((rule layout-rule) stream)
  (print-unreadable-object (rule stream :type t :identity nil)
    (format stream "~A" (id-of rule))))

(defmethod print-object ((effect layout-renderer-effect) stream)
  (print-unreadable-object (effect stream :type t :identity nil)
    (format stream "~A ~A" (layout-renderer-effect-phase-of effect) (id-of effect))))

(defmethod print-object ((failure layout-rule-failure) stream)
  (print-unreadable-object (failure stream :type t :identity nil)
    (format stream "~A: ~A"
            (layout-rule-failure-rule-id-of failure)
            (layout-rule-failure-message-of failure))))

(defmethod print-object ((result layout-rule-result) stream)
  (print-unreadable-object (result stream :type t :identity nil)
    (format stream "~A ~A"
            (id-of (layout-rule-result-rule-of result))
            (layout-rule-result-status-of result))))

(defmethod print-object ((plan layout-repair-plan) stream)
  (print-unreadable-object (plan stream :type t :identity nil)
    (format stream "~A ~A (~D effects)"
            (layout-repair-plan-status-of plan)
            (id-of (layout-repair-plan-patch-of plan))
            (length (layout-repair-plan-renderer-effects-of plan)))))

(defmethod print-object ((override layout-override) stream)
  (print-unreadable-object (override stream :type t :identity nil)
    (format stream "~A: ~A -> ~A"
            (layout-override-topic-id-of override)
            (layout-override-from-parent-id-of override)
            (layout-override-to-parent-id-of override))))

(defmethod print-object ((store layout-override-store) stream)
  (print-unreadable-object (store stream :type t :identity nil)
    (format stream "~A (~D overrides)"
            (layout-override-store-storage-key-of store)
            (length (layout-override-store-overrides-of store)))))

(defun make-layout-topic
    (id title selector kind
     &key element-id class-list bounding-box scroll-context role stability
       evidence)
  (make-instance
   'layout-topic
   :id id
   :title title
   :selector selector
   :element-id element-id
   :class-list class-list
   :bounding-box (or bounding-box
                     '(:capture :client-runtime
                       :status :pending
                       :reason "Measured by the Layout topicmap view at runtime."))
   :scroll-context scroll-context
   :kind kind
   :role role
   :stability (or stability :selector-and-class-contract)
   :evidence evidence))

(defun make-layout-relation (kind from to &key id evidence)
  (make-instance
   'layout-relation
   :id (or id (format nil "~(~A~):~A->~A" kind from to))
   :kind kind
   :from from
   :to to
   :evidence evidence))

(defun reel-inspector-layout-topics ()
  (list
   (make-layout-topic
    "hyperdoc-reel"
    "HyperDoc Reel"
    ".hyperdoc-reel"
    :layout-container
    :class-list '("hyperdoc-reel")
    :role "group"
    :scroll-context '(:owned-by "hyperdoc-reel__scrollable")
    :stability :structural-class-contract
    :evidence
    '(:implementation "hyperbook-server/inspector-performance.lisp"
      :css "assets/hyperdoc/css/hyperdoc-reel.css"
      :accessibility "role=group aria-label=Inspector views"))
   (make-layout-topic
    "hyperdoc-reel__viewport"
    "Reel viewport"
    ".hyperdoc-reel__viewport"
    :layout-viewport
    :class-list '("hyperdoc-reel__viewport")
    :scroll-context '(:clips :none :positions "hyperdoc-reel__buttons")
    :stability :structural-class-contract
    :evidence
    '(:implementation "hyperbook-server/inspector-performance.lisp"
      :css "assets/hyperdoc/css/hyperdoc-reel.css"
      :purpose "Local positioning context for controls and scrollable pane row."))
   (make-layout-topic
    "hyperdoc-reel__buttons"
    "Reel navigation buttons"
    ".hyperdoc-reel__buttons"
    :control-rail
    :class-list '("hyperdoc-reel__buttons")
    :scroll-context '(:controls "hyperdoc-reel__scrollable"
                      :itself-scrollable nil)
    :role "previous-next controls"
    :stability :affordance-class-contract
    :evidence
    '(:implementation "hyperbook-server/inspector-performance.lisp"
      :css "assets/hyperdoc/css/hyperdoc-reel.css"
      :javascript "assets/hyperdoc/js/hyperdoc-reel.js"
      :labels ("previous" "next")
      :boundary-state "disabled at start/end by scrollLeft"))
   (make-layout-topic
    "hyperdoc-reel__scrollable"
    "Native horizontal scroll container"
    ".hyperdoc-reel__scrollable"
    :scroll-container
    :class-list '("hyperdoc-reel__scrollable" "hyperdoc-reel__list")
    :scroll-context '(:overflow-x :auto
                      :overflow-y :hidden
                      :native-horizontal-overflow t)
    :role "list"
    :stability :native-scroll-contract
    :evidence
    '(:implementation "hyperbook-server/inspector-performance.lisp"
      :css "assets/hyperdoc/css/hyperdoc-reel.css"
      :javascript "assets/hyperdoc/js/hyperdoc-reel.js"
      :preserve "Native scrollLeft remains source of horizontal position."))
   (make-layout-topic
    "inspector-pane"
    "Inspector pane"
    ".inspector-pane"
    :pane
    :class-list '("inspector-pane" "hyperdoc-reel__item")
    :scroll-context '(:vertical-reading-scroll ".inspector-body"
                      :horizontal-owner "hyperdoc-reel__scrollable")
    :role "listitem"
    :stability :pane-class-contract
    :evidence
    '(:implementation "hyperbook-server/inspector-performance.lisp"
      :body ".inspector-body"
      :reading-context "The user scrolls the active inspector pane body."))))

(defun reel-inspector-layout-relations ()
  (list
   (make-layout-relation
    :contains
    "hyperdoc-reel"
    "hyperdoc-reel__viewport"
    :evidence "The viewport div is created inside section.hyperdoc-reel.")
   (make-layout-relation
    :contains
    "hyperdoc-reel__viewport"
    "hyperdoc-reel__buttons"
    :evidence "The buttons rail is currently a child of the local viewport.")
   (make-layout-relation
    :contains
    "hyperdoc-reel__viewport"
    "hyperdoc-reel__scrollable"
    :evidence "The scrollable inspector row is currently a child of the local viewport.")
   (make-layout-relation
    :contains
    "hyperdoc-reel__scrollable"
    "inspector-pane"
    :evidence "Inspector panes are direct children of the native horizontal scroll container.")
   (make-layout-relation
    :controls
    "hyperdoc-reel__buttons"
    "hyperdoc-reel__scrollable"
    :evidence "Previous/next buttons update native scrollLeft on the scrollable row.")
   (make-layout-relation
    :scrolls
    "hyperdoc-reel__scrollable"
    "inspector-pane"
    :evidence "Horizontal scroll moves the pane row without replacing native overflow.")))

(defun reel-inspector-layout-topicmap (&key source)
  "Return the first static layout snapshot for the inspector Reel subset."
  (make-instance
   'layout-topicmap
   :id "inspector-reel-layout-topicmap"
   :title "Inspector Reel layout topicmap"
   :source (or source "HyperDoc inspector Reel")
   :topics (reel-inspector-layout-topics)
   :relations (reel-inspector-layout-relations)
   :layout '(("hyperdoc-reel" :x 80 :y 80)
             ("hyperdoc-reel__viewport" :x 320 :y 80)
             ("hyperdoc-reel__buttons" :x 590 :y 20)
             ("hyperdoc-reel__scrollable" :x 590 :y 150)
             ("inspector-pane" :x 880 :y 210))
   :captured-at :static-reel-subset
   :evidence
   '(:scope "Reel and inspector pane subset only"
     :source-of-truth "Lisp layout-topicmap object"
     :runtime-measurement "Client view records bounding boxes as evidence.")))

(defun layout-topicmap-topic (topicmap topic-id)
  (find topic-id (topics-of topicmap) :key #'id-of :test #'equal))

(defun layout-topicmap-relations-of-kind (topicmap kind)
  (remove-if-not
   (lambda (relation)
     (eq (kind-of relation) kind))
   (relations-of topicmap)))

(defun layout-topicmap-parent-of (topicmap topic-id
                                  &key (relation-kind :contains))
  (when-let ((relation
              (find-if
               (lambda (candidate)
                 (and (eq (kind-of candidate) relation-kind)
                      (equal (to-of candidate) topic-id)))
               (relations-of topicmap))))
    (from-of relation)))

(defun layout-topicmap-children-of (topicmap topic-id
                                    &key (relation-kind :contains))
  (loop for relation in (relations-of topicmap)
        when (and (eq (kind-of relation) relation-kind)
                  (equal (from-of relation) topic-id))
          collect (to-of relation)))

(defun layout-topicmap-contains-edges (topicmap)
  (loop for relation in (relations-of topicmap)
        when (eq (kind-of relation) :contains)
          collect (list (from-of relation) (to-of relation))))

(defun layout-topicmap-with-moved-topic
    (topicmap topic-id target-parent-id
     &key (relation-kind :contains)
       (source-parent-id (layout-topicmap-parent-of
                          topicmap topic-id :relation-kind relation-kind)))
  (unless (layout-topicmap-topic topicmap topic-id)
    (error "No layout topic ~S in ~S." topic-id topicmap))
  (unless (layout-topicmap-topic topicmap target-parent-id)
    (error "No target layout topic ~S in ~S." target-parent-id topicmap))
  (let* ((kept-relations
           (remove-if
            (lambda (relation)
              (and (eq (kind-of relation) relation-kind)
                   (equal (to-of relation) topic-id)))
            (relations-of topicmap)))
         (move-relation
           (make-layout-relation
            relation-kind
            target-parent-id
            topic-id
            :id (format nil "~(~A~):~A->~A:preview"
                        relation-kind
                        target-parent-id
                        topic-id)
            :evidence
            (format nil
                    "Preview topology moves ~A from ~A to ~A."
                    topic-id
                    (or source-parent-id "unknown-parent")
                    target-parent-id))))
    (make-instance
     'layout-topicmap
     :id (format nil "~A-after-~A-in-~A"
                 (id-of topicmap)
                 topic-id
                 target-parent-id)
     :title (format nil "~A after moving ~A into ~A"
                    (title-of topicmap)
                    topic-id
                    target-parent-id)
     :source (source-of topicmap)
     :topics (topics-of topicmap)
     :relations (append kept-relations (list move-relation))
     :layout (layout-of topicmap)
     :captured-at (layout-topicmap-captured-at-of topicmap)
     :evidence
     (append (copy-list (evidence-of topicmap))
             (list :preview-move
                   (list :topic topic-id
                         :from source-parent-id
                         :to target-parent-id
                         :relation relation-kind))))))

(defun make-move-topic-into-box-patch
    (topicmap topic-id target-parent-id
     &key (relation-kind :contains)
       (placement :bottom-control-rail)
       (preserve '(:native-horizontal-overflow
                   :button-labels
                   :disabled-boundary-states
                   :keyboard-reachability)))
  (let* ((source-parent-id
           (layout-topicmap-parent-of topicmap topic-id
                                      :relation-kind relation-kind))
         (source-topic (layout-topicmap-topic topicmap topic-id))
         (target-topic (layout-topicmap-topic topicmap target-parent-id))
         (after-topicmap
           (layout-topicmap-with-moved-topic
            topicmap
            topic-id
            target-parent-id
            :relation-kind relation-kind
            :source-parent-id source-parent-id)))
    (unless source-parent-id
      (error "No ~A parent relation for layout topic ~S."
             relation-kind
             topic-id))
    (make-instance
     'move-topic-into-box-patch
     :id (format nil "move-~A-into-~A" topic-id target-parent-id)
     :title "move-topic-into-box-patch"
     :before-topicmap topicmap
     :after-topicmap after-topicmap
     :source-evidence (and source-topic (evidence-of source-topic))
     :target-evidence (and target-topic (evidence-of target-topic))
     :proposed-implementation-effect
     '(:renderer-effect
       "Place the previous/next control rail in the pane-local visual box as a bottom control rail while preserving native scrollLeft and button semantics."
       :preview-effect
       "Client-side preview aligns the existing rail over the pane and records evidence; the DOM is not the source of truth.")
     :apply-policy :create-durable-layout-override
     :topic-id topic-id
     :from-parent-id source-parent-id
     :to-parent-id target-parent-id
     :relation-kind relation-kind
     :placement placement
     :preserve preserve)))

(defun make-reel-buttons-into-pane-patch
    (&optional (topicmap (reel-inspector-layout-topicmap)))
  (make-move-topic-into-box-patch
   topicmap
   "hyperdoc-reel__buttons"
   "inspector-pane"
   :relation-kind :contains
   :placement :bottom-control-rail))

(defun make-layout-rule (id title description invariant &key severity evidence)
  (make-instance
   'layout-rule
   :id id
   :title title
   :description description
   :invariant invariant
   :severity (or severity :hard)
   :evidence evidence))

(defun default-layout-rules ()
  (list
   (make-layout-rule
    "preserve-native-horizontal-overflow"
    "Native horizontal overflow is preserved"
    "The horizontal pane row remains a native overflow container; no custom carousel replaces scrollLeft."
    :native-horizontal-overflow
    :evidence '(:source "hyperdoc-reel__scrollable" :preserve-token :native-horizontal-overflow))
   (make-layout-rule
    "preserve-labelled-buttons"
    "Previous/next buttons remain real labelled buttons"
    "The previous and next controls remain button elements with accessible labels and boundary disabled state."
    :labelled-buttons
    :evidence '(:source "hyperdoc-reel__buttons" :labels ("previous" "next")))
   (make-layout-rule
    "keep-controls-keyboard-reachable"
    "Controls remain keyboard reachable"
    "The control rail must be reachable by focus after preview and after horizontal scroll state updates."
    :keyboard-reachability
    :evidence '(:source "hyperdoc-reel__buttons" :preserve-token :keyboard-reachability))
   (make-layout-rule
    "reserve-pane-bottom-clearance"
    "Pane reserves bottom clearance for local control rail"
    "Preview must leave a safe reading area when the control rail is floated inside the pane viewport."
    :pane-bottom-clearance
    :severity :repair
    :evidence '(:target "inspector-pane" :effect "reserve bottom padding in active pane body"))
   (make-layout-rule
    "control-rail-remains-chrome"
    "Control rail remains chrome, not document content"
    "The rail is projected as pane-local chrome; the preview does not make it part of the document body."
    :chrome-not-content
    :evidence '(:target "hyperdoc-reel__buttons" :placement :bottom-control-rail))
   (make-layout-rule
    "preview-is-transient"
    "Preview does not become durable state"
    "Preview effects may set runtime attributes and styles but do not alter the durable topology."
    :preview-transience
    :evidence '(:phase :preview :durable nil))
   (make-layout-rule
    "apply-creates-durable-override"
    "Apply creates a durable replayable artifact"
    "Apply records explicit replay metadata for the renderer override instead of treating preview DOM state as source truth."
    :durable-override
    :severity :repair
    :evidence '(:phase :apply :artifact :layout-repair-plan))))

(defun layout-renderer-effect
    (id title phase kind target
     &key placement style-property style-value attributes replay evidence)
  (make-instance
   'layout-renderer-effect
   :id id
   :title title
   :phase phase
   :kind kind
   :target target
   :placement placement
   :style-property style-property
   :style-value style-value
   :attributes attributes
   :replay replay
   :evidence evidence))

(defun layout-rule-failure (rule message &key evidence)
  (make-instance
   'layout-rule-failure
   :id (format nil "failure-~A" (id-of rule))
   :title (format nil "Failure: ~A" (title-of rule))
   :rule-id (id-of rule)
   :message message
   :evidence evidence))

(defun layout-rule-result
    (rule status message &key renderer-effects failure evidence)
  (make-instance
   'layout-rule-result
   :id (format nil "result-~A" (id-of rule))
   :title (title-of rule)
   :rule rule
   :status status
   :message message
   :renderer-effects renderer-effects
   :failure failure
   :evidence evidence))

(defun layout-topicmap-has-control-relation-p (topicmap from to)
  (some (lambda (relation)
          (and (eq (kind-of relation) :controls)
               (equal (from-of relation) from)
               (equal (to-of relation) to)))
        (relations-of topicmap)))

(defun layout-patch-preserves-p (patch token)
  (member token (layout-patch-preserve-of patch) :test #'eq))

(defun layout-rule-pass (rule message &key evidence)
  (layout-rule-result rule :pass message :evidence evidence))

(defun layout-rule-repair (rule message effects &key evidence)
  (layout-rule-result
   rule
   :repair
   message
   :renderer-effects effects
   :evidence evidence))

(defun layout-rule-fail (rule message &key evidence)
  (layout-rule-result
   rule
   :fail
   message
   :failure (layout-rule-failure rule message :evidence evidence)
   :evidence evidence))

(defun layout-preview-control-rail-effect (patch)
  (layout-renderer-effect
   "position-control-rail-in-pane"
   "Position control rail inside pane viewport"
   :preview
   :position-control-rail
   "hyperdoc-reel__buttons"
   :placement :fixed-bottom-end-inside-pane
   :attributes `(("data-layout-preview" . "buttons-in-pane")
                 ("data-layout-preview-parent" . ,(layout-patch-from-parent-id-of patch)))
   :evidence
   '(:consumes "active inspector pane bounding box"
     :preserves "existing button elements and scrollLeft owner")))

(defun layout-preview-bottom-clearance-effect ()
  (layout-renderer-effect
   "reserve-pane-bottom-clearance"
   "Reserve bottom clearance in active pane body"
   :preview
   :set-style
   "active-pane-body"
   :style-property "paddingBottom"
   :style-value "4.5rem"
   :evidence
   '(:reason "Floating rail must not obscure readable pane content.")))

(defun layout-apply-durable-override-effect (patch)
  (layout-renderer-effect
   "create-durable-layout-override"
   "Create durable replay metadata for layout override"
   :apply
   :durable-override
   "layout-repair-plan"
   :replay `(:artifact-type :layout-renderer-override
             :patch-id ,(id-of patch)
             :topic ,(layout-patch-topic-id-of patch)
             :from ,(layout-patch-from-parent-id-of patch)
             :to ,(layout-patch-to-parent-id-of patch)
             :placement ,(layout-patch-placement-of patch)
             :preserve ,(layout-patch-preserve-of patch))
   :evidence
   '(:policy "apply records replayable metadata; preview DOM styles are transient")))

(defun apply-layout-rule (rule patch)
  (let ((before (layout-patch-before-topicmap-of patch))
        (after (layout-patch-after-topicmap-of patch)))
    (case (layout-rule-invariant-of rule)
      (:native-horizontal-overflow
       (if (and (layout-patch-preserves-p patch :native-horizontal-overflow)
                (layout-topicmap-topic after "hyperdoc-reel__scrollable"))
           (layout-rule-pass
            rule
            "Native scroll container remains present and preserved by patch."
            :evidence (layout-topicmap-topic after "hyperdoc-reel__scrollable"))
           (layout-rule-fail
            rule
            "Patch would remove or stop preserving the native horizontal scroll container."
            :evidence (list :preserve (layout-patch-preserve-of patch)
                            :after-topics (mapcar #'id-of (topics-of after))))))
      (:labelled-buttons
       (let ((buttons (layout-topicmap-topic after "hyperdoc-reel__buttons")))
         (if (and buttons
                  (layout-patch-preserves-p patch :button-labels)
                  (layout-patch-preserves-p patch :disabled-boundary-states))
             (layout-rule-pass
              rule
              "Button topic remains present with labels and boundary-state preservation tokens."
              :evidence (evidence-of buttons))
             (layout-rule-fail
              rule
              "Patch does not preserve labelled previous/next button semantics."
              :evidence (list :buttons buttons
                              :preserve (layout-patch-preserve-of patch))))))
      (:keyboard-reachability
       (if (layout-patch-preserves-p patch :keyboard-reachability)
           (layout-rule-pass
            rule
            "Patch explicitly preserves keyboard reachability for the rail controls."
            :evidence (layout-patch-preserve-of patch))
           (layout-rule-fail
            rule
            "Patch lacks keyboard-reachability preservation evidence."
            :evidence (layout-patch-preserve-of patch))))
      (:pane-bottom-clearance
       (if (layout-topicmap-topic after (layout-patch-to-parent-id-of patch))
           (layout-rule-repair
            rule
            "Renderer must reserve pane body bottom clearance before floating the rail."
            (list (layout-preview-bottom-clearance-effect))
            :evidence (layout-topicmap-topic after
                                             (layout-patch-to-parent-id-of patch)))
           (layout-rule-fail
            rule
            "Cannot reserve bottom clearance because target pane is missing."
            :evidence (layout-patch-to-parent-id-of patch))))
      (:chrome-not-content
       (if (and (equal (layout-patch-topic-id-of patch) "hyperdoc-reel__buttons")
                (eq (layout-patch-placement-of patch) :bottom-control-rail))
           (layout-rule-repair
            rule
            "Renderer positions the existing rail as pane chrome without reparenting it into document content."
            (list (layout-preview-control-rail-effect patch))
            :evidence (list :topic (layout-patch-topic-id-of patch)
                            :placement (layout-patch-placement-of patch)))
           (layout-rule-fail
            rule
            "Patch target is not a known control rail chrome move."
            :evidence (list :topic (layout-patch-topic-id-of patch)
                            :placement (layout-patch-placement-of patch)))))
      (:preview-transience
       (if (equal (layout-topicmap-parent-of before
                                             (layout-patch-topic-id-of patch))
                  (layout-patch-from-parent-id-of patch))
           (layout-rule-pass
            rule
            "Before topology remains available; preview effects are transient renderer instructions."
            :evidence (layout-topicmap-contains-edges before))
           (layout-rule-fail
            rule
            "Before topology no longer records the original parent."
            :evidence (layout-topicmap-contains-edges before))))
      (:durable-override
       (layout-rule-repair
        rule
        "Apply must create replayable durable override metadata from the repair plan."
        (list (layout-apply-durable-override-effect patch))
        :evidence (layout-patch-apply-policy-of patch)))
      (otherwise
       (layout-rule-fail
        rule
        (format nil "No evaluator is registered for layout invariant ~S."
                (layout-rule-invariant-of rule))
        :evidence (layout-rule-invariant-of rule))))))

(defun layout-repair-plan-status (rule-results)
  (cond
    ((some (lambda (result)
             (eq (layout-rule-result-status-of result) :fail))
           rule-results)
     :blocked)
    ((some (lambda (result)
             (eq (layout-rule-result-status-of result) :repair))
           rule-results)
     :previewable)
    (t
     :pass)))

(defun compute-layout-repair-plan-failure-modes (rule-results)
  (loop for result in rule-results
        for failure = (layout-rule-result-failure-of result)
        when failure
          collect failure))

(defun derive-layout-repair-plan (patch &key (rules (default-layout-rules)))
  (let* ((rule-results (mapcar (lambda (rule)
                                 (apply-layout-rule rule patch))
                               rules))
         (effects (loop for result in rule-results
                        append (layout-rule-result-renderer-effects-of result)))
         (status (layout-repair-plan-status rule-results)))
    (make-instance
     'layout-repair-plan
     :id (format nil "repair-plan-for-~A" (id-of patch))
     :title "layout-repair-plan"
     :patch patch
     :rule-results rule-results
     :renderer-effects effects
     :status status
     :failure-modes (compute-layout-repair-plan-failure-modes rule-results)
     :preview-apply-boundary
     '(:preview "consume renderer effects only; runtime styles are transient"
       :apply "create durable replay metadata from apply-phase renderer effect")
     :evidence
     (list :source-patch (id-of patch)
           :rule-count (length rules)
           :effect-count (length effects)
           :status status))))

(defun layout-rule-result-summary (result)
  (let ((rule (layout-rule-result-rule-of result)))
    (list :id (id-of result)
          :rule-id (id-of rule)
          :status (layout-rule-result-status-of result)
          :message (layout-rule-result-message-of result))))

(defun layout-override-replay-failure (message &key evidence)
  (layout-rule-failure
   (make-layout-rule
    "replay-layout-override"
    "Replay layout override"
    "Persisted layout overrides must replay against the expected topology and renderer-effect contract."
    :layout-override-replay
    :severity :hard
    :evidence '(:phase :replay))
   message
   :evidence evidence))

(defun make-layout-override-store
    (&key (id "layout-override-store")
      (title "layout-override-store")
      (storage-kind :browser-local-storage)
      (storage-key "hyperdoc.layout.overrides.v1")
      overrides
      evidence)
  (make-instance
   'layout-override-store
   :id id
   :title title
   :storage-kind storage-kind
   :storage-key storage-key
   :overrides overrides
   :evidence (or evidence
                 '(:boundary "Browser localStorage is the durable session replay store for the inspector Layout topicmap slice."))))

(defun make-layout-override-from-repair-plan
    (plan &key id created-at)
  (let* ((patch (layout-repair-plan-patch-of plan))
         (effects (layout-repair-plan-renderer-effects-of plan))
         (apply-effect (find :durable-override effects :key #'kind-of)))
    (cond
      ((eq (layout-repair-plan-status-of plan) :blocked)
       (layout-override-replay-failure
        "Blocked repair plans cannot create durable layout overrides."
        :evidence (layout-repair-plan-failure-modes-of plan)))
      ((null apply-effect)
       (layout-override-replay-failure
        "Repair plan has no apply-phase durable-override renderer effect."
        :evidence (mapcar #'kind-of effects)))
      (t
       (make-instance
        'layout-override
        :id (or id
                (format nil "layout-override-for-~A" (id-of patch)))
        :title "layout-override"
        :source-patch-id (id-of patch)
        :source-repair-plan-id (id-of plan)
        :topic-id (layout-patch-topic-id-of patch)
        :from-parent-id (layout-patch-from-parent-id-of patch)
        :to-parent-id (layout-patch-to-parent-id-of patch)
        :relation-kind (layout-patch-relation-kind-of patch)
        :placement (layout-patch-placement-of patch)
        :preserve (layout-patch-preserve-of patch)
        :before-topicmap (layout-patch-before-topicmap-of patch)
        :after-topicmap (layout-patch-after-topicmap-of patch)
        :rule-results
        (mapcar #'layout-rule-result-summary
                (layout-repair-plan-rule-results-of plan))
        :renderer-effects effects
        :created-at (or created-at (get-universal-time))
        :revert-info
        (list :artifact-type :layout-override-revert-patch
              :topic (layout-patch-topic-id-of patch)
              :from (layout-patch-to-parent-id-of patch)
              :to (layout-patch-from-parent-id-of patch)
              :relation (layout-patch-relation-kind-of patch)
              :placement :restore-original-parent)
        :evidence
        (list :source-plan (id-of plan)
              :source-patch (id-of patch)
              :apply-effect (id-of apply-effect)
              :before-parent (layout-patch-from-parent-id-of patch)
              :after-parent (layout-patch-to-parent-id-of patch)))))))

(defun persist-layout-override
    (override &optional
      (store (make-layout-override-store)))
  (let ((kept-overrides
          (remove (id-of override)
                  (layout-override-store-overrides-of store)
                  :key #'id-of
                  :test #'equal)))
    (make-layout-override-store
     :id (id-of store)
     :title (title-of store)
     :storage-kind (layout-override-store-storage-kind-of store)
     :storage-key (layout-override-store-storage-key-of store)
     :overrides (append kept-overrides (list override))
     :evidence (append (copy-list (evidence-of store))
                       (list :last-persisted-override (id-of override))))))

(defun load-layout-overrides (store)
  (layout-override-store-overrides-of store))

(defun layout-override-renderer-effects-valid-p (override)
  (and (find :durable-override
             (layout-override-renderer-effects-of override)
             :key #'kind-of)
       (find :position-control-rail
             (layout-override-renderer-effects-of override)
             :key #'kind-of)
       (find :set-style
             (layout-override-renderer-effects-of override)
             :key #'kind-of)))

(defun replay-layout-override (topicmap override)
  (cond
    ((not (typep override 'layout-override))
     (layout-override-replay-failure
      "Replay input is not a layout-override object."
      :evidence override))
    ((not (layout-override-renderer-effects-valid-p override))
     (layout-override-replay-failure
      "Persisted override is missing required renderer effects."
      :evidence (mapcar #'kind-of
                        (layout-override-renderer-effects-of override))))
    ((not (layout-topicmap-topic topicmap
                                 (layout-override-topic-id-of override)))
     (layout-override-replay-failure
      "Replay topic is missing from the base layout topicmap."
      :evidence (list :topic (layout-override-topic-id-of override)
                      :topicmap (id-of topicmap))))
    ((not (layout-topicmap-topic topicmap
                                 (layout-override-to-parent-id-of override)))
     (layout-override-replay-failure
      "Replay target parent is missing from the base layout topicmap."
      :evidence (list :parent (layout-override-to-parent-id-of override)
                      :topicmap (id-of topicmap))))
    (t
     (let ((current-parent
             (layout-topicmap-parent-of
              topicmap
              (layout-override-topic-id-of override)
              :relation-kind (layout-override-relation-kind-of override))))
       (cond
         ((equal current-parent
                 (layout-override-to-parent-id-of override))
          topicmap)
         ((equal current-parent
                 (layout-override-from-parent-id-of override))
          (layout-topicmap-with-moved-topic
           topicmap
           (layout-override-topic-id-of override)
           (layout-override-to-parent-id-of override)
           :relation-kind (layout-override-relation-kind-of override)
           :source-parent-id (layout-override-from-parent-id-of override)))
         (t
          (layout-override-replay-failure
           "Replay source parent no longer matches the persisted before-topology."
           :evidence (list :topic (layout-override-topic-id-of override)
                           :expected-parent
                           (layout-override-from-parent-id-of override)
                           :accepted-replayed-parent
                           (layout-override-to-parent-id-of override)
                           :actual-parent current-parent))))))))

(defun replay-layout-overrides (topicmap overrides-or-store)
  (let ((overrides
          (if (typep overrides-or-store 'layout-override-store)
              (load-layout-overrides overrides-or-store)
              overrides-or-store)))
    (reduce
     (lambda (current override)
       (if (typep current 'layout-rule-failure)
           current
           (replay-layout-override current override)))
     overrides
     :initial-value topicmap)))

(defun layout-override-revert-patch (override)
  (handler-case
      (make-move-topic-into-box-patch
       (layout-override-after-topicmap-of override)
       (layout-override-topic-id-of override)
       (layout-override-from-parent-id-of override)
       :relation-kind (layout-override-relation-kind-of override)
       :placement :restore-original-parent
       :preserve (layout-override-preserve-of override))
    (error (condition)
      (layout-override-replay-failure
       "Cannot create a revert patch from the persisted layout override."
       :evidence (list :override (id-of override)
                       :condition (princ-to-string condition))))))

(defmethod topicmap-view-title-of ((topicmap layout-topicmap))
  (title-of topicmap))

(defmethod topicmap-view-input-owner-of ((topicmap layout-topicmap))
  (id-of topicmap))

(defmethod topicmap-projection-of ((topicmap layout-topicmap))
  (make-instance
   'topicmap-projection
   :source
   (source-content-from-object
    topicmap
    :title (title-of topicmap)
    :text
    (with-output-to-string (stream)
      (format stream "~A~%" (title-of topicmap))
      (dolist (topic (topics-of topicmap))
        (format stream "~A ~A ~A~%"
                (id-of topic)
                (kind-of topic)
                (layout-topic-selector-of topic)))
      (dolist (relation (relations-of topicmap))
        (format stream "~A ~A -> ~A~%"
                (kind-of relation)
                (from-of relation)
                (to-of relation)))))
   :topics
   (loop for topic in (topics-of topicmap)
         collect (make-instance
                  'parsed-topic
                  :id (id-of topic)
                  :title (title-of topic)
                  :kind (kind-of topic)
                  :content (format nil "~A ~A"
                                   (layout-topic-selector-of topic)
                                   (layout-topic-stability-of topic))
                  :source-target topicmap))
   :relations
   (loop for relation in (relations-of topicmap)
         collect (make-instance
                  'parsed-relation
                  :from (from-of relation)
                  :to (to-of relation)
                  :kind (kind-of relation)
                  :evidence (evidence-of relation)))
   :layout (layout-of topicmap)))

(defmethod topicmap-view-title-of ((patch move-topic-into-box-patch))
  (title-of patch))

(defmethod topicmap-view-input-owner-of ((patch move-topic-into-box-patch))
  (id-of patch))

(defmethod topicmap-projection-of ((patch move-topic-into-box-patch))
  (topicmap-projection-of (layout-patch-after-topicmap-of patch)))
