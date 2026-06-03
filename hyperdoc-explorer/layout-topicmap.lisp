;;;; Inspector layout topicmap editor view.

(in-package :hyperdoc)

(defun include-layout-topicmap-assets ()
  (views:add-asset-path "/hyperdoc/"
                        (asdf:system-relative-pathname
                         :hyperdoc
                         "assets/hyperdoc/"))
  (views:include-css "/hyperdoc/css/layout-topicmap.css")
  (views:include-js "/hyperdoc/js/layout-topicmap.js")
  (views:include-script
   "window.hyperdocLayoutTopicmap && window.hyperdocLayoutTopicmap.init(window.currentInspectorView || document);"))

(defun layout-topicmap-view-string (value)
  (cond
    ((null value) "")
    ((keywordp value) (string-downcase (symbol-name value)))
    ((symbolp value)
     (if (symbol-package value)
         (format nil "~A::~A"
                 (package-name (symbol-package value))
                 (symbol-name value))
         (symbol-name value)))
    ((listp value) (format nil "~{~A~^, ~}" value))
    (t (format nil "~A" value))))

(defun render-layout-topicmap-field (label value)
  (views:html
   (:div :class "hyperdoc-layout-topic__field"
         (:dt (views:esc label))
         (:dd (views:esc (layout-topicmap-view-string value))))))

(defun render-layout-topic-card (topic topicmap)
  (let* ((topic-id (id-of topic))
         (drag-source-p (string= topic-id "hyperdoc-reel__buttons"))
         (drop-target-p (string= topic-id "inspector-pane"))
         (parent-id (layout-topicmap-parent-of topicmap topic-id))
         (class
           (format nil "hyperdoc-layout-topic~@[ ~A~]~@[ ~A~]"
                   (and drag-source-p "hyperdoc-layout-topic--drag-source")
                   (and drop-target-p "hyperdoc-layout-topic--drop-target"))))
    (views:html
     (:article
      :class class
      :tabindex "0"
      :draggable (if drag-source-p "true" "false")
      :data-layout-topic-id topic-id
      :data-layout-selector (layout-topic-selector-of topic)
      :data-layout-kind (layout-topicmap-view-string (kind-of topic))
      :data-layout-draggable (if drag-source-p "true" "false")
      :data-layout-drop-target (if drop-target-p "true" "false")
      (:header
       (:strong (views:esc (title-of topic)))
       (:code (views:esc topic-id)))
      (:dl
       (render-layout-topicmap-field "Kind" (kind-of topic))
       (render-layout-topicmap-field "Selector"
                                     (layout-topic-selector-of topic))
       (render-layout-topicmap-field "Parent" parent-id)
       (render-layout-topicmap-field "Role" (layout-topic-role-of topic))
       (render-layout-topicmap-field "Stability"
                                     (layout-topic-stability-of topic)))
      (:p :class "hyperdoc-layout-topic__measurement"
          (views:esc "Bounding box: awaiting runtime evidence"))))))

(defun render-layout-relation-table (topicmap &key (title "Relations"))
  (views:html
   (:section :class "hyperdoc-layout-section"
             (:h2 (views:esc title))
             (:table :class "inspector-table hyperdoc-layout-relations"
                     (:tr (:th (views:esc "Kind"))
                          (:th (views:esc "From"))
                          (:th (views:esc "To"))
                          (:th (views:esc "Evidence")))
                     (loop for relation in (relations-of topicmap)
                           do (views:html
                               (:tr
                                (:td (:code (views:esc
                                             (layout-topicmap-view-string
                                              (kind-of relation)))))
                                (:td (:code (views:esc (from-of relation))))
                                (:td (:code (views:esc (to-of relation))))
                                (:td (views:esc
                                      (layout-topicmap-view-string
                                       (evidence-of relation)))))))))))

(defun render-layout-topology-table (topicmap title)
  (views:html
   (:section :class "hyperdoc-layout-section"
             (:h3 (views:esc title))
             (:table :class "inspector-table hyperdoc-layout-topology"
                     (:tr (:th (views:esc "Parent box"))
                          (:th (views:esc "Child topic")))
                     (loop for edge in (layout-topicmap-contains-edges topicmap)
                           do (views:html
                               (:tr
                                (:td (:code (views:esc (first edge))))
                                (:td (:code (views:esc (second edge)))))))))))

(defun render-layout-contract-sections ()
  (views:html
   (:section :class "hyperdoc-layout-section"
             (:h2 (views:esc "Content Model"))
             (:p (views:esc
                  "The source of truth is the Lisp layout-topicmap object: topics, containment relations, control relations, evidence, and stability classifications. Runtime DOM measurements are preview evidence only.")))
   (:section :class "hyperdoc-layout-section"
             (:h2 (views:esc "Box Contract"))
             (:ul
              (:li (views:esc "hyperdoc-reel owns the local viewport."))
              (:li (views:esc "hyperdoc-reel__scrollable remains the native horizontal overflow owner."))
              (:li (views:esc "inspector-pane remains a pane/listitem and may host pane-local chrome."))
              (:li (views:esc "hyperdoc-reel__buttons stays real button chrome with previous/next labels and boundary disabled state."))))
   (:section :class "hyperdoc-layout-section"
             (:h2 (views:esc "Priority Policy"))
             (:ol
              (:li (views:esc "Preserve native horizontal scrollLeft and wheel/trackpad/touch/keyboard scrolling."))
              (:li (views:esc "Keep previous/next controls reachable in the active pane reading context."))
              (:li (views:esc "Make move operations inspectable before applying durable layout changes."))
              (:li (views:esc "Treat direct DOM mutation as preview evidence, not source of truth."))))
   (:section :class "hyperdoc-layout-section"
             (:h2 (views:esc "Failure Modes"))
             (:ul
              (:li (views:esc "A selector-only model becomes stale if CSS class names are repurposed; stability classification records that risk."))
              (:li (views:esc "Moving controls into an inert or offscreen pane can break keyboard reachability; preview checks must keep controls focusable."))
              (:li (views:esc "A custom carousel replacement would violate the native overflow invariant."))
              (:li (views:esc "An apply action without a durable override or renderer patch would make the DOM the source of truth."))))))

(defun render-layout-patch-panel (patch)
  (views:html
   (:section
    :class "hyperdoc-layout-patch"
    :hidden "hidden"
    :data-layout-patch-kind "move-topic-into-box-patch"
    :data-layout-patch-status "template"
    :aria-live "polite"
    (:header
     (:h2 (views:esc "move-topic-into-box-patch"))
     (:p (views:esc
          "Patch object created by dragging the Buttons topic onto the Pane topic.")))
    (:dl :class "hyperdoc-layout-patch__facts"
         (render-layout-topicmap-field "Topic"
                                       (layout-patch-topic-id-of patch))
         (render-layout-topicmap-field "From"
                                       (layout-patch-from-parent-id-of patch))
         (render-layout-topicmap-field "To"
                                       (layout-patch-to-parent-id-of patch))
         (render-layout-topicmap-field "Placement"
                                       (layout-patch-placement-of patch))
         (render-layout-topicmap-field "Preserve"
                                       (layout-patch-preserve-of patch)))
    (render-layout-topology-table
     (layout-patch-before-topicmap-of patch)
     "Before topology")
    (render-layout-topology-table
     (layout-patch-after-topicmap-of patch)
     "After topology")
    (:section :class "hyperdoc-layout-section"
              (:h3 (views:esc "Evidence"))
              (:table :class "inspector-table"
                      (:tr (:th (views:esc "Source"))
                           (:td (:pre (views:esc
                                       (layout-topicmap-view-string
                                        (layout-patch-source-evidence-of
                                         patch))))))
                      (:tr (:th (views:esc "Target"))
                           (:td (:pre (views:esc
                                       (layout-topicmap-view-string
                                        (layout-patch-target-evidence-of
                                         patch))))))
                      (:tr (:th (views:esc "Effect"))
                           (:td (:pre (views:esc
                                       (layout-topicmap-view-string
                                        (layout-patch-proposed-implementation-effect-of
                                         patch))))))))
    (:div :class "hyperdoc-layout-actions"
          (:button :type "button"
                   :class "hyperdoc-layout-preview"
                   (views:esc "Preview"))
          (:button :type "button"
                   :class "hyperdoc-layout-apply"
                   (views:esc "Apply"))
          (:span :class "hyperdoc-layout-apply-status"
                 (views:esc "Apply will create durable override evidence for this patch object.")))
    (:p :class "hyperdoc-layout-inspectable-ref"
        (views:object-ref patch
                          :display "Inspect move-topic-into-box-patch"
                          :select "Overview")))))

(defun render-layout-topicmap-editor (topicmap)
  (let ((patch (make-reel-buttons-into-pane-patch topicmap)))
    (views:html
     (:section
      :class "hyperdoc-layout-topicmap"
      :data-layout-topicmap-id (id-of topicmap)
      (:header :class "hyperdoc-layout-header"
               (:h1 (views:esc "Layout topicmap"))
               (:p (views:esc
                    "Drag the Buttons topic onto the Pane topic to create an inspectable layout patch. Preview may move visible chrome locally; the model remains this layout-topicmap and patch object.")))
      (:section :class "hyperdoc-layout-section"
                (:h2 (views:esc "Topics"))
                (:div :class "hyperdoc-layout-topics"
                      (loop for topic in (topics-of topicmap)
                            do (render-layout-topic-card topic topicmap))))
      (render-layout-relation-table topicmap)
      (:section :class "hyperdoc-layout-section hyperdoc-layout-model-links"
                (:h2 (views:esc "Actions"))
                (:p (views:object-ref topicmap
                                      :display "Inspect layout-topicmap object"
                                      :select "Overview"))
                (:p (views:object-ref
                     (make-inline-topicmap-view
                      (topicmap-projection-of topicmap)
                      :input-owner "Inspector Reel layout topicmap")
                     :display "Inspect generic topicmap projection"
                     :select "Content")))
      (render-layout-patch-panel patch)
      (render-layout-contract-sections)))))

(views:defview layout-topicmap-view (hd hyperdoc)
  (let ((topicmap (reel-inspector-layout-topicmap :source (title-of hd))))
    (views:html-view
     :title "Layout topicmap"
     :priority 5
     (include-layout-topicmap-assets)
     (views:html
      (render-layout-topicmap-editor topicmap)))))

(views:defview layout-topicmap-overview (topicmap layout-topicmap)
  (views:html-view
   :title "Overview"
   :priority 1
   (include-layout-topicmap-assets)
   (views:html
    (:div :class "hyperdoc-layout-topicmap hyperdoc-layout-topicmap--readonly"
          (:h1 (views:esc (title-of topicmap)))
          (:table :class "inspector-table"
                  (:tr (:th (views:esc "Id"))
                       (:td (:code (views:esc (id-of topicmap)))))
                  (:tr (:th (views:esc "Source"))
                       (:td (views:esc (layout-topicmap-view-string
                                        (source-of topicmap)))))
                  (:tr (:th (views:esc "Captured at"))
                       (:td (:code (views:esc
                                    (layout-topicmap-view-string
                                     (layout-topicmap-captured-at-of
                                      topicmap))))))
                  (:tr (:th (views:esc "Topics"))
                       (:td (:code (views:esc
                                    (format nil "~D"
                                            (length (topics-of
                                                     topicmap)))))))
                  (:tr (:th (views:esc "Relations"))
                       (:td (:code (views:esc
                                    (format nil "~D"
                                            (length (relations-of
                                                     topicmap))))))))
          (render-layout-relation-table topicmap)
          (render-layout-contract-sections)))))

(views:defview layout-topicmap-patch-overview (patch move-topic-into-box-patch)
  (views:html-view
   :title "Overview"
   :priority 1
   (include-layout-topicmap-assets)
   (views:html
    (:div :class "hyperdoc-layout-topicmap hyperdoc-layout-topicmap--patch"
          (:h1 (views:esc (title-of patch)))
          (:table :class "inspector-table"
                  (:tr (:th (views:esc "Topic"))
                       (:td (:code (views:esc
                                    (layout-patch-topic-id-of patch)))))
                  (:tr (:th (views:esc "From"))
                       (:td (:code (views:esc
                                    (layout-patch-from-parent-id-of patch)))))
                  (:tr (:th (views:esc "To"))
                       (:td (:code (views:esc
                                    (layout-patch-to-parent-id-of patch)))))
                  (:tr (:th (views:esc "Relation"))
                       (:td (:code (views:esc
                                    (layout-topicmap-view-string
                                     (layout-patch-relation-kind-of
                                      patch))))))
                  (:tr (:th (views:esc "Placement"))
                       (:td (:code (views:esc
                                    (layout-topicmap-view-string
                                     (layout-patch-placement-of patch))))))
                  (:tr (:th (views:esc "Apply policy"))
                       (:td (:code (views:esc
                                    (layout-topicmap-view-string
                                     (layout-patch-apply-policy-of
                                      patch)))))))
          (render-layout-topology-table
           (layout-patch-before-topicmap-of patch)
           "Before topology")
          (render-layout-topology-table
           (layout-patch-after-topicmap-of patch)
           "After topology")))))

(views:defview layout-topicmap-patch-evidence (patch move-topic-into-box-patch)
  (views:html-view
   :title "Evidence"
   :priority 2
   (views:html
    (:table :class "inspector-table"
            (:tr (:th (views:esc "Source evidence"))
                 (:td (:pre (views:esc
                             (layout-topicmap-view-string
                              (layout-patch-source-evidence-of patch))))))
            (:tr (:th (views:esc "Target evidence"))
                 (:td (:pre (views:esc
                             (layout-topicmap-view-string
                              (layout-patch-target-evidence-of patch))))))
            (:tr (:th (views:esc "Proposed implementation effect"))
                 (:td (:pre (views:esc
                             (layout-topicmap-view-string
                              (layout-patch-proposed-implementation-effect-of
                               patch))))))))))
