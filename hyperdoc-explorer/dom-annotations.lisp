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
   "(function initHyperdocDomConnect(attempt) {
      if (window.hyperdocDomConnect &&
          typeof window.hyperdocDomConnect.initCurrentView === 'function') {
        window.hyperdocDomConnect.initCurrentView();
        return;
      }
      if ((attempt || 0) >= 40) {
        return;
      }
      window.setTimeout(function () {
        initHyperdocDomConnect((attempt || 0) + 1);
      }, 50);
    }(0));"))

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
         (snapshot-cell (lwcells:cell ""))
         (request-id-cell (lwcells:cell ""))
         (browser-failure-kind-cell (lwcells:cell ""))
         (browser-message-cell (lwcells:cell ""))
         (browser-detail-cell (lwcells:cell ""))
         (source-input-id (html-inspector-views/reactive:input-id
                           source-cell :event :change))
         (target-input-id (html-inspector-views/reactive:input-id
                           target-cell :event :change))
         (snapshot-input-id (html-inspector-views/reactive:input-id
                             snapshot-cell :event :change))
         (request-id-input-id (html-inspector-views/reactive:input-id
                               request-id-cell :event :change))
         (browser-failure-kind-input-id
           (html-inspector-views/reactive:input-id
            browser-failure-kind-cell :event :change))
         (browser-message-input-id
           (html-inspector-views/reactive:input-id
            browser-message-cell :event :change))
         (browser-detail-input-id
           (html-inspector-views/reactive:input-id
            browser-detail-cell :event :change)))
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
                    :data-snapshot-input-id snapshot-input-id
                    :data-request-id-input-id request-id-input-id
                    :data-browser-failure-kind-input-id
                    browser-failure-kind-input-id
                    :data-browser-message-input-id
                    browser-message-input-id
                    :data-browser-detail-input-id
                    browser-detail-input-id
                    (:input :type "hidden" :id source-input-id :value "")
                    (:input :type "hidden" :id target-input-id :value "")
                    (:input :type "hidden" :id snapshot-input-id :value "")
                    (:input :type "hidden" :id request-id-input-id :value "")
                    (:input :type "hidden"
                            :id browser-failure-kind-input-id
                            :value "")
                    (:input :type "hidden"
                            :id browser-message-input-id
                            :value "")
                    (:input :type "hidden"
                            :id browser-detail-input-id
                            :value "")
                    (:span :class "hyperdoc-dom-connect-submit"
                           :style "display:none"
                           (views:eval-button
                            "Open association"
                            (views:thunk
                              (make-dom-relation-annotation-from-json
                               :context-object context-object
                               :context-view-title view-title
                               :source-json (lwcells:cell-ref source-cell)
                               :target-json (lwcells:cell-ref target-cell)))))
                    (:span :class "hyperdoc-dom-connect-inspect-submit"
                           :style "display:none"
                           (views:eval-button
                            "Inspect Connect state"
                            (views:thunk
                              (make-dom-connect-session-snapshot-from-json
                               :context-object context-object
                               :context-view-title view-title
                               :snapshot-json (lwcells:cell-ref snapshot-cell)))))
                    (:span :class "hyperdoc-dom-connect-evidence-submit"
                           :style "display:none"
                           (views:eval-button
                            "Inspect request evidence"
                            (views:thunk
                              (make-dom-connect-request-evidence-from-values
                               :context-object context-object
                               :context-view-title view-title
                               :request-id (lwcells:cell-ref request-id-cell)
                               :snapshot-json (lwcells:cell-ref snapshot-cell)
                               :browser-failure-kind
                               (lwcells:cell-ref browser-failure-kind-cell)
                               :browser-message
                               (lwcells:cell-ref browser-message-cell)
                               :browser-detail
                               (lwcells:cell-ref browser-detail-cell))))))
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
                  "Click the part of the page you want to connect."
                  :help-detail
                  "Connect resolves visible clicks to headings, list items, or paragraphs when it can. Authored ids stay strongest when present; DOM-path data is fallback metadata only."
                  :body-thunk body-thunk)
   context-object
   view-title))

(defun render-source-connect-surface (context-object view-title pathname)
  (render-anchor-provider-surface
   (make-instance 'source-view-anchor-provider
                  :kind "source-v1"
                  :view-kind "source"
                  :help-summary
                  "Click the source lines you want to connect."
                  :help-detail
                  "Connect stores file path plus line and column range. These anchors stay useful for the same file revision, but line numbers can drift when the source changes."
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
                    "Click the story item you want to connect."
                    :help-detail
                    "Connect stores durable story-item identity when it can: site, page slug, and story-item id. DOM location is fallback metadata only."
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

(defmethod views:text-representation ((snapshot dom-connect-pane-state-snapshot))
  (format nil "~A (~A)"
          (or (pane-id-of snapshot) "pane")
          (or (local-phase-of snapshot) "dormant")))

(defmethod views:text-representation ((entry dom-connect-transition-entry))
  (or (stage-of entry)
      (title-of entry)))

(defmethod views:text-representation ((snapshot dom-connect-session-snapshot))
  (shorten-dom-association-label (title-of snapshot)))

(defmethod views:text-representation ((evidence dom-connect-request-evidence))
  (shorten-dom-association-label (title-of evidence)))

(defmethod views:text-representation ((path dom-connect-submit-path))
  (shorten-dom-association-label (title-of path)))

(defmethod views:text-representation ((comparison dom-connect-submit-path-comparison))
  (shorten-dom-association-label (title-of comparison)))

(defmethod views:text-representation ((path dom-connect-snapshot-transport-path))
  (shorten-dom-association-label (title-of path)))

(defmethod views:text-representation ((transport dom-connect-snapshot-transport))
  (shorten-dom-association-label (title-of transport)))

(defmethod views:text-representation ((proposal relation-topic-proposal))
  (shorten-dom-association-label (proposed-title-of proposal)))

(defun render-anchor-field-rows (rows)
  (loop for (label . value) in rows
        do (views:html
             (:tr (:th (views:esc label))
                  (:td (maybe-dom-object-ref value :fallback-empty "-"))))))

(defun render-connect-field-row (label value &key (fallback "-"))
  (views:html
    (:tr (:th (views:esc label))
         (:td (maybe-dom-object-ref value :fallback-empty fallback)))))

(defun render-connect-data-cell (value &key (fallback "-"))
  (cond
    ((null value)
     (views:html
       (:span :style "opacity: 0.55;" (views:esc fallback))))
    ((listp value)
     (views:html
       (:ul
        (loop for item in value
              do (views:html
                   (:li (maybe-dom-object-ref item :fallback-empty fallback)))))))
    (t
     (maybe-dom-object-ref value :fallback-empty fallback))))

(defun render-connect-rich-field-row (label value &key (fallback "-"))
  (views:html
    (:tr (:th (views:esc label))
         (:td (render-connect-data-cell value :fallback fallback)))))

(defun render-connect-comparison-row (label normal-value evidence-value
                                      &key (normal-fallback "-")
                                        (evidence-fallback "-"))
  (views:html
    (:tr (:th (views:esc label))
         (:td (render-connect-data-cell normal-value
                                        :fallback normal-fallback))
         (:td (render-connect-data-cell evidence-value
                                        :fallback evidence-fallback)))))

(defun connect-provider-label (value)
  (or value "-"))

(defun render-connect-anchor-section (heading anchor)
  (views:html
    (:h4 (views:esc heading))
    (if anchor
        (let* ((semantic-fields
                 (append
                  (list (cons "Provider kind"
                              (connect-provider-label (provider-kind-of anchor))))
                  (semantic-anchor-identity-fields anchor)
                  (list (cons "Human label"
                              (or (label-of anchor) "-")))))
               (presentation-fields (presentation-anchor-fallback-fields anchor)))
          (views:html
            (:p (maybe-dom-object-ref anchor))
            (:table :class "inspector-table hyperdoc-dom-connect-anchor-table"
                    (render-anchor-field-rows semantic-fields))
            (:h5 "Fallback diagnostics")
            (:table :class "inspector-table hyperdoc-dom-connect-anchor-diagnostics-table"
                    (if presentation-fields
                        (render-anchor-field-rows presentation-fields)
                        (views:html
                          (:tr (:th "Captured fallback")
                               (:td (:span :style "opacity: 0.55;"
                                           "none"))))))))
        (views:html
          (:p (:span :style "opacity: 0.55;"
                     "No active anchor in the current session."))))))

(defun render-connect-transition-anchor-ref (entry)
  (or (anchor-of entry)
      (source-anchor-of entry)
      (target-anchor-of entry)))

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

(views:defview 👀topic-proposal (annotation dom-relation-annotation)
  (views:html-view :title "Topic proposal" :priority 2
    (views:html
      (:h3 "Reviewed topic proposal")
      (:p "Use the Operations view to inspect the promotion result without mutating authored topic factories or page files.")
      (:p (views:object-ref (promote-relation-to-topic-proposal annotation))))))

(views:defview 👀summary (snapshot dom-connect-pane-state-snapshot)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of snapshot)))
      (:p (views:esc (summary-of snapshot)))
      (:table :class "inspector-table hyperdoc-dom-connect-pane-summary-table"
              (render-connect-field-row "Pane id" (pane-id-of snapshot))
              (render-connect-field-row "Visible tab" (active-tab-of snapshot))
              (render-connect-field-row "View title"
                                        (context-view-title-of snapshot))
              (render-connect-field-row "Provider kind"
                                        (provider-kind-of snapshot))
              (render-connect-field-row "Available"
                                        (dom-connect-bool-label
                                         (available-p-of snapshot)))
              (render-connect-field-row "Enabled"
                                        (dom-connect-bool-label
                                         (enabled-p-of snapshot)))
              (render-connect-field-row "Local phase" (local-phase-of snapshot))
              (render-connect-field-row "Help open"
                                        (dom-connect-bool-label
                                         (help-open-p-of snapshot)))
              (render-connect-field-row "Selected source label"
                                        (selected-source-label-of snapshot))
              (render-connect-field-row "Selected source pane"
                                        (dom-connect-bool-label
                                         (selected-source-pane-p-of snapshot)))
              (render-connect-field-row "Pending request id"
                                        (pending-request-id-of snapshot))))))

(views:defview 👀summary (entry dom-connect-transition-entry)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of entry)))
      (:p (views:esc (summary-of entry)))
      (:table :class "inspector-table hyperdoc-dom-connect-transition-summary-table"
              (render-connect-field-row "Stage" (stage-of entry))
              (render-connect-field-row "Request id" (request-id-of entry))
              (render-connect-field-row "Time" (timestamp-label-of entry))
              (render-connect-field-row "Pane id" (pane-id-of entry))
              (render-connect-field-row "Provider kind"
                                        (provider-kind-of entry))
              (render-connect-field-row "Anchor"
                                        (render-connect-transition-anchor-ref
                                         entry))))))

(views:defview 👀summary (snapshot dom-connect-session-snapshot)
  (views:html-view :title "Summary" :priority 1
    (let* ((source-anchor (source-anchor-of snapshot))
           (target-anchor (target-anchor-of snapshot))
           (last-transition (last-transition-of snapshot)))
      (views:html
        (:h3 (views:esc (title-of snapshot)))
        (:p (views:esc (summary-of snapshot)))
        (:table :class "inspector-table hyperdoc-dom-connect-session-summary-table"
                (render-connect-field-row "Session id"
                                          (or (session-id-of snapshot)
                                              "idle"))
                (render-connect-field-row "Global phase" (phase-of snapshot))
                (render-connect-field-row "Origin pane"
                                          (origin-pane-id-of snapshot))
                (render-connect-field-row "Source pane"
                                          (source-pane-id-of snapshot))
                (render-connect-field-row "Source provider kind"
                                          (or (source-provider-kind-of snapshot)
                                              (and source-anchor
                                                   (provider-kind-of
                                                    source-anchor))))
                (render-connect-field-row "Source semantic label"
                                          (dom-connect-anchor-label
                                           source-anchor))
                (render-connect-field-row "Target pane"
                                          (target-pane-id-of snapshot))
                (render-connect-field-row "Target provider kind"
                                          (or (target-provider-kind-of snapshot)
                                              (and target-anchor
                                                   (provider-kind-of
                                                    target-anchor))))
                (render-connect-field-row "Target semantic label"
                                          (dom-connect-anchor-label
                                           target-anchor))
                (render-connect-field-row "Pending request id"
                                          (or (pending-request-id-of snapshot)
                                              "none"))
                (render-connect-field-row "Pending request state"
                                          (or (pending-request-state-of snapshot)
                                              "none"))
                (render-connect-field-row "Last transition"
                                          (and last-transition
                                               (stage-of last-transition)))
                (render-connect-field-row "Last transition time"
                                          (and last-transition
                                               (timestamp-label-of
                                                last-transition)))
                (render-connect-field-row "Captured at"
                                          (captured-at-label-of snapshot))
                (render-connect-field-row "Context view"
                                          (context-view-title-of snapshot))
                (render-connect-field-row "Context object"
                                          (context-object-of snapshot)))))))

(views:defview 👀panes (snapshot dom-connect-session-snapshot)
  (views:html-view :title "Panes" :priority 2
    (views:html
      (:table :class "inspector-table hyperdoc-dom-connect-panes-table"
              (:tr (:th "Pane id")
                   (:th "Snapshot")
                   (:th "Visible tab")
                   (:th "View title")
                   (:th "Provider")
                   (:th "Available")
                   (:th "Enabled")
                   (:th "Local phase")
                   (:th "Help open")
                   (:th "Selected source label")
                   (:th "Pending request"))
              (if (panes-of snapshot)
                  (loop for pane-state in (panes-of snapshot)
                        do (views:html
                             (:tr (:td (:tt (views:esc
                                             (or (pane-id-of pane-state)
                                                 "-"))))
                                  (:td (maybe-dom-object-ref pane-state))
                                  (:td (views:esc
                                        (or (active-tab-of pane-state)
                                            "-")))
                                  (:td (views:esc
                                        (or (context-view-title-of pane-state)
                                            "-")))
                                  (:td (:tt (views:esc
                                             (or (provider-kind-of pane-state)
                                                 "-"))))
                                  (:td (views:esc
                                        (dom-connect-bool-label
                                         (available-p-of pane-state))))
                                  (:td (views:esc
                                        (dom-connect-bool-label
                                         (enabled-p-of pane-state))))
                                  (:td (:tt (views:esc
                                             (or (local-phase-of pane-state)
                                                 "-"))))
                                  (:td (views:esc
                                        (dom-connect-bool-label
                                         (help-open-p-of pane-state))))
                                  (:td (views:esc
                                        (or (selected-source-label-of
                                             pane-state)
                                            "-")))
                                  (:td (:tt (views:esc
                                             (or (pending-request-id-of
                                                  pane-state)
                                                 "-")))))))
                  (views:html
                    (:tr (:td :colspan "11"
                              (:span :style "opacity: 0.55;"
                                     "No live panes are registered.")))))))))

(views:defview 👀transitions (snapshot dom-connect-session-snapshot)
  (views:html-view :title "Transitions" :priority 3
    (views:html
      (:table :class "inspector-table hyperdoc-dom-connect-transitions-table"
              (:tr (:th "Time")
                   (:th "Stage")
                   (:th "Request id")
                   (:th "Pane id")
                   (:th "Provider")
                   (:th "Anchor")
                   (:th "Transition")
                   (:th "Summary"))
              (if (transitions-of snapshot)
                  (loop for entry in (transitions-of snapshot)
                        do (views:html
                             (:tr (:td (:tt (views:esc
                                             (or (timestamp-label-of entry)
                                                 "-"))))
                                  (:td (:tt (views:esc
                                             (or (stage-of entry)
                                                 "-"))))
                                  (:td (:tt (views:esc
                                             (or (request-id-of entry)
                                                 "-"))))
                                  (:td (:tt (views:esc
                                             (or (pane-id-of entry)
                                                 "-"))))
                                  (:td (:tt (views:esc
                                             (or (provider-kind-of entry)
                                                 "-"))))
                                  (:td (maybe-dom-object-ref
                                        (render-connect-transition-anchor-ref
                                         entry)
                                        :fallback-empty "-"))
                                  (:td (maybe-dom-object-ref entry))
                                  (:td (views:esc (summary-of entry))))))
                  (views:html
                    (:tr (:td :colspan "8"
                              (:span :style "opacity: 0.55;"
                                     "No Connect transitions have been recorded.")))))))))

(views:defview 👀payload (snapshot dom-connect-session-snapshot)
  (views:html-view :title "Payload / Anchors" :priority 4
    (views:html
      (render-connect-anchor-section "Source anchor"
                                     (source-anchor-of snapshot))
      (render-connect-anchor-section "Target anchor"
                                     (target-anchor-of snapshot)))))

(views:defview 👀summary (evidence dom-connect-request-evidence)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of evidence)))
      (:p (views:esc (summary-of evidence)))
      (:table :class "inspector-table hyperdoc-dom-connect-request-evidence-table"
              (render-connect-field-row "Request id" (request-id-of evidence))
              (render-connect-field-row "Transport" (transport-of evidence))
              (render-connect-field-row "Context view"
                                        (context-view-title-of evidence))
              (render-connect-field-row "Context object"
                                        (context-object-of evidence))
              (render-connect-field-row "Inspection pane id"
                                        (inspection-pane-id-of evidence))
              (render-connect-field-row "Source pane"
                                        (source-pane-id-of evidence))
              (render-connect-field-row "Target pane"
                                        (target-pane-id-of evidence))
              (render-connect-field-row "Source provider kind"
                                        (source-provider-kind-of evidence))
              (render-connect-field-row "Target provider kind"
                                        (target-provider-kind-of evidence))
              (render-connect-field-row "Server status"
                                        (server-status-of evidence))
              (render-connect-field-row "Server acknowledged"
                                        (dom-connect-bool-label
                                         (server-acknowledged-p-of evidence)))
              (render-connect-field-row "Browser failure kind"
                                        (or (dom-connect-evidence-failure-kind-label
                                             (browser-failure-kind-of evidence))
                                            "none"))
              (render-connect-field-row "Submitted at"
                                        (or (submitted-at-label-of evidence)
                                            "submit-boundary"))
              (render-connect-field-row "Last updated"
                                        (or (updated-at-label-of evidence)
                                            "submit-boundary"))))))

(views:defview 👀failure (evidence dom-connect-request-evidence)
  (views:html-view :title "Failure / Boundary" :priority 2
    (views:html
      (:h4 "Browser-side classification")
      (:table :class "inspector-table"
              (render-connect-field-row "Failure kind"
                                        (or (dom-connect-evidence-failure-kind-label
                                             (browser-failure-kind-of evidence))
                                            "none"))
              (render-connect-field-row "Browser message"
                                        (or (browser-message-of evidence)
                                            "none"))
              (render-connect-field-row "Browser detail"
                                        (or (browser-detail-of evidence)
                                            "none")))
      (:h4 "Server-side boundary")
      (:table :class "inspector-table"
              (render-connect-field-row "Server status"
                                        (or (server-status-of evidence)
                                            "submitted"))
              (render-connect-field-row "Server message"
                                        (or (server-message-of evidence)
                                            "none"))
              (render-connect-field-row "Server detail"
                                        (or (server-detail-of evidence)
                                            "none"))))))

(views:defview 👀payload (evidence dom-connect-request-evidence)
  (views:html-view :title "Payload / Snapshot" :priority 3
    (views:html
      (render-connect-anchor-section "Source anchor"
                                     (source-anchor-of evidence))
      (render-connect-anchor-section "Target anchor"
                                     (target-anchor-of evidence))
      (:h4 "Captured session snapshot")
      (if (session-snapshot-of evidence)
          (maybe-dom-object-ref (session-snapshot-of evidence))
          (views:html
            (:p (:span :style "opacity: 0.55;"
                       "No submit-boundary session snapshot was captured.")))))))

(views:defview 👀summary (path dom-connect-submit-path)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of path)))
      (:p (views:esc (summary-of path)))
      (:table :class "inspector-table"
              (render-connect-field-row "Trigger" (trigger-of path))
              (render-connect-field-row "Purpose" (purpose-of path))
              (render-connect-field-row "Transport tag"
                                        (transport-tag-of path))
              (render-connect-field-row "Payload-bearing element"
                                        (payload-bearing-element-of path))
              (render-connect-rich-field-row "Authoritative payload fields"
                                             (authoritative-payload-fields-of
                                              path))
              (render-connect-field-row "Snapshot carrier"
                                        (snapshot-carrier-of path))
              (render-connect-field-row "Snapshot handling"
                                        (snapshot-handling-of path))
              (render-connect-field-row "Snapshot transport status"
                                        (snapshot-transport-status-of path))
              (render-connect-field-row "Hidden-field dependency"
                                        (hidden-field-dependency-of path))
              (render-connect-field-row "Server parse order"
                                        (server-parse-order-of path))
              (render-connect-field-row "Object opened"
                                        (object-opened-of path))
              (render-connect-field-row "Typical interpretation"
                                        (typical-interpretation-of path))
              (render-connect-rich-field-row "Implementation lineage"
                                             (lineage-of path))))))

(views:defview 👀comparison (comparison dom-connect-submit-path-comparison)
  (views:html-view :title "Comparison" :priority 1
    (let ((normal-path (normal-path-of comparison))
          (evidence-path (evidence-path-of comparison)))
      (views:html
        (:h3 (views:esc (title-of comparison)))
        (:p (views:esc (summary-of comparison)))
        (:table :class "inspector-table"
                (:tr (:th "Operational field")
                     (:th (views:esc (title-of normal-path)))
                     (:th (views:esc (title-of evidence-path))))
                (render-connect-comparison-row "Trigger"
                                               (trigger-of normal-path)
                                               (trigger-of evidence-path))
                (render-connect-comparison-row "Purpose"
                                               (purpose-of normal-path)
                                               (purpose-of evidence-path))
                (render-connect-comparison-row "Transport tag"
                                               (transport-tag-of normal-path)
                                               (transport-tag-of evidence-path))
                (render-connect-comparison-row
                 "Payload-bearing element"
                 (payload-bearing-element-of normal-path)
                 (payload-bearing-element-of evidence-path))
                (render-connect-comparison-row
                 "Authoritative payload fields"
                 (authoritative-payload-fields-of normal-path)
                 (authoritative-payload-fields-of evidence-path))
                (render-connect-comparison-row "Snapshot carrier"
                                               (snapshot-carrier-of normal-path)
                                               (snapshot-carrier-of evidence-path))
                (render-connect-comparison-row
                 "Snapshot handling"
                 (snapshot-handling-of normal-path)
                 (snapshot-handling-of evidence-path))
                (render-connect-comparison-row
                 "Snapshot transport status"
                 (snapshot-transport-status-of normal-path)
                 (snapshot-transport-status-of evidence-path))
                (render-connect-comparison-row
                 "Hidden-field dependency"
                 (hidden-field-dependency-of normal-path)
                 (hidden-field-dependency-of evidence-path))
                (render-connect-comparison-row "Server parse order"
                                               (server-parse-order-of normal-path)
                                               (server-parse-order-of evidence-path))
                (render-connect-comparison-row "Object opened"
                                               (object-opened-of normal-path)
                                               (object-opened-of evidence-path))
                (render-connect-comparison-row
                 "Typical success/failure interpretation"
                 (typical-interpretation-of normal-path)
                 (typical-interpretation-of evidence-path)))))))

(views:defview 👀server-seam (comparison dom-connect-submit-path-comparison)
  (views:html-view :title "Server seam" :priority 2
    (views:html
      (:h4 "Submit-boundary parse seam")
      (:table :class "inspector-table"
              (render-connect-field-row "Server seam"
                                        (server-seam-of comparison))
              (render-connect-field-row
               "Interpretation of missing snapshot message"
               (no-snapshot-message-meaning-of comparison))
              (render-connect-rich-field-row "Implementation lineage"
                                             (lineage-of comparison))))))

(views:defview 👀paths (comparison dom-connect-submit-path-comparison)
  (views:html-view :title "Paths" :priority 3
    (views:html
      (:h4 (views:esc (title-of (normal-path-of comparison))))
      (:p (maybe-dom-object-ref (normal-path-of comparison)))
      (:h4 (views:esc (title-of (evidence-path-of comparison))))
      (:p (maybe-dom-object-ref (evidence-path-of comparison))))))

(views:defview 👀summary (path dom-connect-snapshot-transport-path)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of path)))
      (:p (views:esc (summary-of path)))
      (:table :class "inspector-table"
              (render-connect-field-row "Producer" (producer-of path))
              (render-connect-field-row "Carrier" (carrier-of path))
              (render-connect-field-row "Payload-bearing element"
                                        (payload-bearing-element-of path))
              (render-connect-field-row "Authority / fallback status"
                                        (authority-status-of path))
              (render-connect-field-row "Hidden-field dependency"
                                        (hidden-field-dependency-of path))
              (render-connect-field-row "Server parse order"
                                        (server-parse-order-of path))
              (render-connect-field-row "Parse absence interpretation"
                                        (absence-interpretation-of path))
              (render-connect-field-row "Downstream object enabled"
                                        (downstream-object-of path))
              (render-connect-rich-field-row "Implementation lineage"
                                             (lineage-of path))))))

(views:defview 👀summary (transport dom-connect-snapshot-transport)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:h3 (views:esc (title-of transport)))
      (:p (views:esc (summary-of transport)))
      (:table :class "inspector-table"
              (render-connect-field-row "Operational definition"
                                        (operational-definition-of transport))
              (render-connect-field-row "Server parse order / authority"
                                        (server-seam-of transport))
              (render-connect-field-row "Absence interpretation"
                                        (absence-interpretation-of transport))
              (render-connect-rich-field-row "Implementation lineage"
                                             (lineage-of transport)))
      (:h4 "Paths")
      (:p (maybe-dom-object-ref (normal-path-of transport)))
      (:p (maybe-dom-object-ref (evidence-path-of transport)))))

(views:defview 👀paths (transport dom-connect-snapshot-transport)
  (views:html-view :title "Paths" :priority 2
    (let ((normal-path (normal-path-of transport))
          (evidence-path (evidence-path-of transport)))
      (views:html
        (:h3 (views:esc (title-of transport)))
        (:p (views:esc (summary-of transport)))
        (:table :class "inspector-table"
                (:tr (:th "Transport field")
                     (:th (views:esc (title-of normal-path)))
                     (:th (views:esc (title-of evidence-path))))
                (render-connect-comparison-row "Producer"
                                               (producer-of normal-path)
                                               (producer-of evidence-path))
                (render-connect-comparison-row "Carrier"
                                               (carrier-of normal-path)
                                               (carrier-of evidence-path))
                (render-connect-comparison-row
                 "Payload-bearing element"
                 (payload-bearing-element-of normal-path)
                 (payload-bearing-element-of evidence-path))
                (render-connect-comparison-row
                 "Authority / fallback status"
                 (authority-status-of normal-path)
                 (authority-status-of evidence-path))
                (render-connect-comparison-row
                 "Hidden-field dependency"
                 (hidden-field-dependency-of normal-path)
                 (hidden-field-dependency-of evidence-path))
                (render-connect-comparison-row
                 "Server parse order"
                 (server-parse-order-of normal-path)
                 (server-parse-order-of evidence-path))
                (render-connect-comparison-row
                 "Parse absence interpretation"
                 (absence-interpretation-of normal-path)
                 (absence-interpretation-of evidence-path))
                (render-connect-comparison-row
                 "Downstream object enabled"
                 (downstream-object-of normal-path)
                 (downstream-object-of evidence-path))))))))

(views:defview 👀overview (proposal relation-topic-proposal)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:h3 (views:esc (proposed-title-of proposal)))
      (:p (views:esc (proposed-summary-of proposal)))
      (:table :class "inspector-table"
              (render-connect-field-row "Relation" (relation-of proposal))
              (render-connect-field-row "Proposed id"
                                        (proposed-id-of proposal))
              (render-connect-field-row "Proposed title"
                                        (proposed-title-of proposal))
              (render-connect-field-row "Merge status"
                                        (merge-status-of proposal))
              (render-connect-field-row "Existing topic"
                                        (existing-topic-of proposal)))
      (:h4 "Proposed references")
      (if (proposed-references-of proposal)
          (views:html
            (:ul
             (loop for reference in (proposed-references-of proposal)
                   do (views:html
                        (:li (:tt (views:esc reference)))))))
          (views:html
            (:p (:span :style "opacity: 0.55;"
                       "No editorial references were inferred.")))))))

(views:defview 👀proposed-topic-factory (proposal relation-topic-proposal)
  (views:html-view :title "Proposed topic factory" :priority 2
    (views:html
      (:h3 "Copy-pasteable topic factory")
      (:p "This is a reviewed proposal surface only. It does not patch hyperdoc/topics.lisp.")
      (:pre :style "white-space: pre-wrap"
            (views:esc (relation-topic-proposal-factory-form proposal))))))

(views:defview 👀merge-guidance (proposal relation-topic-proposal)
  (views:html-view :title "Merge guidance" :priority 3
    (views:html
      (:h3 "Merge guidance")
      (:ul
       (:li "Search hyperdoc/topics.lisp by the exact :title string.")
       (:li "Edit the existing factory in place when the title already exists.")
       (:li "Add a new topic factory only when the exact title does not exist."))
      (:table :class "inspector-table"
              (render-connect-field-row "Exact title candidate"
                                        (proposed-title-of proposal))
              (render-connect-field-row "Current merge status"
                                        (merge-status-of proposal))
              (render-connect-field-row "Existing topic object"
                                        (existing-topic-of proposal))))))
