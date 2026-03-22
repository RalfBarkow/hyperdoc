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

(defclass view-anchor-provider ()
  ((kind :initarg :kind :reader anchor-provider-kind-of)
   (view-kind :initarg :view-kind :reader anchor-provider-view-kind-of)
   (selection-mode :initarg :selection-mode
                   :initform "click"
                   :reader anchor-provider-selection-mode-of)
   (help-summary :initarg :help-summary :reader anchor-provider-help-summary-of)
   (help-detail :initarg :help-detail :reader anchor-provider-help-detail-of)
   (body-thunk :initarg :body-thunk :initform nil
               :reader anchor-provider-body-thunk-of)))

(defclass dom-view-anchor-provider (view-anchor-provider) ())

(defclass source-view-anchor-provider (view-anchor-provider)
  ((pathname :initarg :pathname :reader anchor-provider-pathname-of)
   (context-object :initarg :context-object
                   :reader anchor-provider-context-object-of)))

(defclass fedwiki-view-anchor-provider (view-anchor-provider)
  ((page :initarg :page :reader anchor-provider-page-of)))

(defgeneric anchor-provider-connectable-p (provider))

(defgeneric render-anchor-provider-body (provider))

(defmethod anchor-provider-connectable-p ((provider view-anchor-provider))
  (declare (ignore provider))
  t)

(defmethod render-anchor-provider-body ((provider dom-view-anchor-provider))
  (funcall (anchor-provider-body-thunk-of provider)))

(defmethod render-anchor-provider-body ((provider fedwiki-view-anchor-provider))
  (funcall (anchor-provider-body-thunk-of provider)))

(defun source-line-label (line-number line-text)
  (let ((snippet (string-trim '(#\Space #\Tab)
                              (or line-text ""))))
    (if (> (length snippet) 0)
        (format nil "Line ~D: ~A"
                line-number
                (shorten-dom-association-label snippet 96))
        (format nil "Line ~D" line-number))))

(defun render-source-anchor-line (provider line-number line-text)
  (let* ((pathname (namestring (anchor-provider-pathname-of provider)))
         (column-end (+ 1 (length line-text)))
         (value (format nil "~A#L~D" pathname line-number)))
    (views:html
      (:button :type "button"
               :class "hyperdoc-source-connect-line"
               :data-hyperdoc-connect-source-anchor "true"
               :data-hyperdoc-source-path pathname
               :data-hyperdoc-source-start-line line-number
               :data-hyperdoc-source-end-line line-number
               :data-hyperdoc-source-start-column "1"
               :data-hyperdoc-source-end-column column-end
               :data-hyperdoc-source-value value
               :data-hyperdoc-source-label (source-line-label line-number line-text)
               :data-hyperdoc-source-object-id
               (dom-connect-context-object-id
                (anchor-provider-context-object-of provider))
               (:span :class "hyperdoc-source-connect-line-number"
                      (views:esc (format nil "~D" line-number)))
               (:span :class "hyperdoc-source-connect-line-text"
                      (views:esc line-text))))))

(defmethod render-anchor-provider-body ((provider source-view-anchor-provider))
  (let ((lines (uiop:read-file-lines (anchor-provider-pathname-of provider))))
    (views:html
      (:div :class "hyperdoc-source-connect-view"
            (loop for line-text in lines
                  for line-number from 1
                  do (render-source-anchor-line
                      provider line-number line-text))))))

(defun render-anchor-provider-surface (provider context-object view-title)
  (let* ((source-cell (lwcells:cell ""))
         (target-cell (lwcells:cell ""))
         (source-input-id (html-inspector-views/reactive:input-id
                           source-cell :event :change))
         (target-input-id (html-inspector-views/reactive:input-id
                           target-cell :event :change)))
    (include-dom-annotation-connect-assets)
    (when (anchor-provider-connectable-p provider)
      (views:html
        (:div :class "hyperdoc-dom-connect-surface hyperdoc-connect-provider-surface"
            :data-hyperdoc-connect-provider-kind
            (anchor-provider-kind-of provider)
            :data-hyperdoc-connect-view-kind
            (anchor-provider-view-kind-of provider)
            :data-hyperdoc-connect-selection-mode
            (anchor-provider-selection-mode-of provider)
            :data-hyperdoc-connect-help-summary
            (anchor-provider-help-summary-of provider)
            :data-hyperdoc-connect-help-detail
            (anchor-provider-help-detail-of provider)
            :data-context-object-id (dom-connect-context-object-id context-object)
            :data-context-view-title view-title
            (:div :class "hyperdoc-dom-connect-controls"
                  :style "display:none"
                  :data-source-input-id source-input-id
                  :data-target-input-id target-input-id
                  (:input :type "hidden" :id source-input-id :value "")
                  (:input :type "hidden" :id target-input-id :value "")
                  (:span :class "hyperdoc-dom-connect-submit"
                         :style "display:none"
                         (views:eval-button
                          "Open association"
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
            (:div :class "hyperdoc-dom-connect-root hyperdoc-connect-provider-root"
                  (render-anchor-provider-body provider)))))))

(defun render-dom-connect-surface (context-object view-title body-thunk)
  (render-anchor-provider-surface
   (make-instance 'dom-view-anchor-provider
                  :kind "dom-v1"
                  :view-kind "content"
                  :help-summary
                  "Connect structural anchors in this view to create an association."
                  :help-detail
                  "Visible clicks resolve to heading, list-item, or paragraph anchors when possible. Authored ids are strongest when present; DOM-path data is fallback metadata only."
                  :body-thunk body-thunk)
   context-object
   view-title))

(defun render-source-connect-surface (context-object view-title pathname)
  (render-anchor-provider-surface
   (make-instance 'source-view-anchor-provider
                  :kind "source-v1"
                  :view-kind "source"
                  :help-summary
                  "Connect source anchors in this view to create an association."
                  :help-detail
                  "Source anchors use file path plus line and column range. They remain durable for the same file revision, but line numbers can drift when the source changes."
                  :pathname pathname
                  :context-object context-object)
   context-object
   view-title))

(defun fedwiki-story-item-type-label (item)
  (-> item
      hyperbook/fedwiki::item-type-of
      symbol-name
      string-downcase))

(defun fedwiki-story-item-anchor-label (item)
  (let* ((type-label (fedwiki-story-item-type-label item))
         (text (string-trim '(#\Space #\Tab #\Newline #\Return)
                            (or (hyperbook/fedwiki::text-of item)
                                ""))))
    (if (> (length text) 0)
        (shorten-dom-association-label
         (format nil "~A: ~A" type-label text)
         96)
        (format nil "~A item ~A"
                (string-capitalize type-label)
                (hyperbook/fedwiki::id-of item)))))

(defun render-fedwiki-story-item-anchor (page item)
  (let* ((wiki (hyperbook/fedwiki::origin-of page))
         (site-domain (hyperbook/fedwiki::domain-name-of wiki))
         (page-slug (hyperbook/fedwiki::origin-id-of page))
         (page-title (hb:title-of page))
         (item-type (fedwiki-story-item-type-label item))
         (item-id (hyperbook/fedwiki::id-of item))
         (label (fedwiki-story-item-anchor-label item)))
    (views:html
      (:div :class "hyperdoc-fedwiki-story-item-anchor"
            :title item-type
            :data-hyperdoc-fedwiki-story-item-anchor "true"
            :data-hyperdoc-fedwiki-site-domain site-domain
            :data-hyperdoc-fedwiki-page-slug page-slug
            :data-hyperdoc-fedwiki-page-title page-title
            :data-hyperdoc-fedwiki-story-item-id item-id
            :data-hyperdoc-fedwiki-story-item-type item-type
            :data-hyperdoc-fedwiki-story-item-label label
            (hyperbook/fedwiki::render-story-item
             (hyperbook/fedwiki::item-type-of item)
             item
             page)))))

(defun render-fedwiki-connect-surface (page view-title)
  (let* ((wiki (hyperbook/fedwiki::origin-of page))
         (domain (hyperbook/fedwiki::domain-name-of wiki))
         (protocol (hyperbook/fedwiki::protocol-of wiki)))
    (render-anchor-provider-surface
     (make-instance 'fedwiki-view-anchor-provider
                    :kind "fedwiki-v1"
                    :view-kind "story"
                    :help-summary
                    "Connect story-item anchors in this view to create an association."
                    :help-detail
                    "Selections resolve to durable story-item identity: site + slug + story-item id. DOM location is fallback metadata only."
                    :page page
                    :body-thunk
                    (lambda ()
                      (views:add-asset-path "/hyperbook/"
                                            (asdf:system-relative-pathname
                                             :hyperbook
                                             "assets/hyperbook/"))
                      (views:include-css "/hyperbook/css/hyperbook.css")
                      (views:html
                        (:div :class "hyperbook-page"
                              (:h1 (:img :src (hyperbook/fedwiki::wiki-url
                                               domain
                                               protocol
                                               "/favicon.png"))
                                   (views:esc " ")
                                   (views:esc (hb:title-of page)))
                              (loop for item across (hyperbook/fedwiki::story-of page)
                                    do (render-fedwiki-story-item-anchor
                                        page item))))))
     page
     view-title)))

(views:defview 👀story (page hyperbook/fedwiki::fedwiki-page)
  (hyperbook/fedwiki::load-page page)
  (views:html-view :title "Story" :priority 2
    (render-fedwiki-connect-surface page "Story")))

(defmethod views:text-representation ((anchor dom-annotation-anchor))
  (or (label-of anchor)
      (anchor-value-of anchor)))

(defmethod views:text-representation ((annotation dom-relation-annotation))
  (shorten-dom-association-label (title-of annotation)))

(defun render-anchor-field-rows (rows)
  (loop for (label . value) in rows
        do (views:html
             (:tr (:th (views:esc label))
                  (:td (maybe-dom-object-ref value :fallback-empty "-"))))))

(views:defview 👀summary (anchor dom-annotation-anchor)
  (views:html-view :title "Summary" :priority 1
    (let ((semantic-fields (semantic-anchor-identity-fields anchor))
          (presentation-fields (presentation-anchor-fallback-fields anchor)))
      (views:html
        (:h3 (views:esc (or (label-of anchor)
                            (semantic-anchor-identity-of anchor))))
        (:h4 "Context")
        (:table :class "inspector-table"
                (:tr (:th "Provider")
                     (:td (:tt (views:esc (or (provider-kind-of anchor)
                                              "-")))))
                (:tr (:th "Pane")
                     (:td (:tt (views:esc (or (pane-id-of anchor)
                                              "-")))))
                (:tr (:th "Context object")
                     (:td (:tt (views:esc (or (context-object-id-of anchor)
                                              "-")))))
                (:tr (:th "View kind")
                     (:td (:tt (views:esc (or (view-kind-of anchor)
                                              "-")))))
                (:tr (:th "View title")
                     (:td (:tt (views:esc (or (view-title-of anchor)
                                              "-"))))))
        (:h4 "Semantic anchor")
        (:table :class "inspector-table"
                (render-anchor-field-rows semantic-fields))
        (:h4 "Presentation fallback")
        (:table :class "inspector-table"
                (if presentation-fields
                    (render-anchor-field-rows presentation-fields)
                    (views:html
                      (:tr (:th "Captured fallback")
                           (:td (:span :style "opacity: 0.55;"
                                       "none"))))))
        (:h4 "Durability")
        (:table :class "inspector-table"
                (:tr (:th "Tier")
                     (:td (:tt (views:esc (or (durability-tier-of anchor)
                                              "-")))))
                (:tr (:th "Note")
                     (:td (views:esc (or (durability-note-of anchor)
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
      (:h3 :class "hyperdoc-dom-association-title"
           (views:esc (title-of annotation)))
      (:p :class "hyperdoc-dom-association-summary"
          (views:esc (summary-of annotation)))
      (:table :class "inspector-table"
              (:tr (:th "Association kind")
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
