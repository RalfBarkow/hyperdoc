;;;; DOM relation annotation explorer views
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defun maybe-dom-object-ref (value &key (fallback-empty ""))
  (cond
    ((null value)
     (views:html (views:esc fallback-empty)))
    ((or (stringp value)
         (pathnamep value)
         (keywordp value)
         (numberp value))
     (views:html (:tt (views:esc (format nil "~A" value)))))
    (t
     (views:object-ref value))))

(defun include-dom-annotation-connect-assets ()
  (views:add-asset-path "/hyperdoc/"
                        (asdf:system-relative-pathname
                         :hyperdoc
                         "assets/hyperdoc/"))
  (views:include-css "/hyperdoc/css/dom-annotation-connect.css")
  (views:include-js "/hyperdoc/js/dom-annotation-connect.js")
  (views:include-script
   "window.hyperdocDomConnect && window.hyperdocDomConnect.initCurrentView()"))

(defun dom-connect-context-object-id (object)
  (or (ignore-errors (id-of object))
      (ignore-errors (title-of object))
      (format nil "~A" object)))

(defun render-dom-connect-surface (context-object view-title body-thunk)
  (let* ((source-cell (lwcells:cell ""))
         (target-cell (lwcells:cell ""))
         (source-input-id (html-inspector-views/reactive:input-id
                           source-cell :event :change))
         (target-input-id (html-inspector-views/reactive:input-id
                           target-cell :event :change)))
    (include-dom-annotation-connect-assets)
    (views:html
      (:div :class "hyperdoc-dom-connect-surface"
            :data-context-object-id (dom-connect-context-object-id context-object)
            :data-context-view-title view-title
            (:div :class "hyperdoc-dom-connect-toolbar"
                  (:button :type "button"
                           :class "hyperdoc-dom-connect-toggle"
                           "Connect")
                  (:button :type "button"
                           :class "hyperdoc-dom-connect-cancel"
                           :hidden "hidden"
                           "Cancel")
                  (:span :class "hyperdoc-dom-connect-status"
                         "Direction matters: click source first, then target."))
            (:div :class "hyperdoc-dom-connect-controls"
                  :style "display:none"
                  :data-source-input-id source-input-id
                  :data-target-input-id target-input-id
                  (:input :type "hidden" :id source-input-id :value "")
                  (:input :type "hidden" :id target-input-id :value "")
                  (:span :class "hyperdoc-dom-connect-submit"
                         :style "display:none"
                         (views:eval-button
                          "Open DOM relation annotation"
                          (views:thunk
                            (make-dom-relation-annotation-from-json
                             :context-object context-object
                             :context-view-title view-title
                             :source-json (lwcells:cell-ref source-cell)
                             :target-json (lwcells:cell-ref target-cell))))))
            (:svg :class "hyperdoc-dom-connect-overlay"
                  :hidden "hidden"
                  :xmlns "http://www.w3.org/2000/svg"
                  :aria-hidden "true"
                  (:line :class "hyperdoc-dom-connect-line"
                         :x1 "0"
                         :y1 "0"
                         :x2 "0"
                         :y2 "0"))
            (:div :class "hyperdoc-dom-connect-root"
                  (funcall body-thunk))))))

(defmethod views:text-representation ((anchor dom-annotation-anchor))
  (or (label-of anchor)
      (anchor-value-of anchor)))

(defmethod views:text-representation ((annotation dom-relation-annotation))
  (title-of annotation))

(views:defview 👀summary (anchor dom-annotation-anchor)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (or (label-of anchor)
                          (anchor-value-of anchor))))
      (:table :class "inspector-table"
              (:tr (:th "Strategy")
                   (:td (:tt (views:esc (anchor-strategy-of anchor)))))
              (:tr (:th "Value")
                   (:td (:tt (views:esc (anchor-value-of anchor)))))
              (:tr (:th "Selector")
                   (:td (:tt (views:esc (or (selector-of anchor)
                                            "-")))))
              (:tr (:th "Tag")
                   (:td (:tt (views:esc (or (tag-name-of anchor)
                                            "-")))))
              (:tr (:th "Object id")
                   (:td (:tt (views:esc (or (anchor-object-id-of anchor)
                                            "-")))))))))

(views:defview 👀items (anchor dom-annotation-anchor)
  (views:html-view :title "Items" :priority 10
    (views:html
      (:h4 "Text snippet")
      (:pre :style "white-space: pre-wrap"
            (views:esc (or (text-snippet-of anchor)
                           "No text snippet captured."))))))

(views:defview 👀summary (annotation dom-relation-annotation)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of annotation)))
      (:p (views:esc (summary-of annotation)))
      (:table :class "inspector-table"
              (:tr (:th "Relation kind")
                   (:td (:tt (views:esc (or (relation-kind-of annotation)
                                            "-")))))
              (:tr (:th "Context view")
                   (:td (:tt (views:esc (or (context-view-title-of annotation)
                                            "-")))))
              (:tr (:th "Context object")
                   (:td (maybe-dom-object-ref (context-object-of annotation))))
              (:tr (:th "Matching patch target")
                   (:td (if (matching-patch-target-of annotation)
                            (views:object-ref
                             (matching-patch-target-of annotation))
                            (views:html (:span :style "opacity: 0.55;"
                                               "none"))))))
      (when (note-of annotation)
        (views:html
          (:h4 "Note")
          (:pre :style "white-space: pre-wrap"
                (views:esc (note-of annotation))))))))

(views:defview 👀items (annotation dom-relation-annotation)
  (views:html-view :title "Items" :priority 10
    (views:html
      (:h4 "Source anchor")
      (maybe-dom-object-ref (source-anchor-of annotation))
      (when (source-object-of annotation)
        (views:html
          (:h4 "Source object")
          (maybe-dom-object-ref (source-object-of annotation))))
      (:h4 "Target anchor")
      (maybe-dom-object-ref (target-anchor-of annotation))
      (when (target-object-of annotation)
        (views:html
          (:h4 "Target object")
          (maybe-dom-object-ref (target-object-of annotation))))
      (when (matching-defect-of annotation)
        (views:html
          (:h4 "Matching defect")
          (maybe-dom-object-ref (matching-defect-of annotation))))
      (when (matching-inserted-step-of annotation)
        (views:html
          (:h4 "Suggested inserted step")
          (maybe-dom-object-ref (matching-inserted-step-of annotation)))))))
