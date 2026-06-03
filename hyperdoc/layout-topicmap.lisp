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
