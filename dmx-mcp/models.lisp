;;;; Required DMX MCP runtime definitions, extracted from f512aa847eab05cc2bdf2e78ef0bd1b516a11926.
;;;; See docs/dmx-mcp-source-manifest.json and LICENSE.
(in-package :hyperdoc)

;; Forward special declaration; value is owned by dmx-annotations.lisp.
(defvar *dmx-workspace-annotation-workspace-topicmap-type-uri*)

;; From hyperdoc/topics/registry.lisp, characters 130..593.
;; Inspectable topic objects used by expr links and the Topics hyperbook.
(defclass topic ()
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (summary :accessor summary-of :initarg :summary)
   ;; Optional editorial metadata. Internal page associations are derived from
   ;; authored page links plus backlink lookup, not primarily from this slot.
   (references :accessor references-of :initarg :references :initform nil)))

;; From hyperdoc/topics/registry.lisp, characters 3093..3149.
(defvar *topics-by-id* (make-hash-table :test #'equal))

;; From hyperdoc/topics/registry.lisp, characters 3149..3208.
(defvar *topics-by-title* (make-hash-table :test #'equal))

;; From hyperdoc/topics/registry.lisp, characters 3800..3955.
(defun %register-topic (topic)
  (setf (gethash (id-of topic) *topics-by-id*) topic)
  (setf (gethash (title-of topic) *topics-by-title*) topic)
  topic)

;; From hyperdoc/topics/registry.lisp, characters 3955..4521.
(defun make-topic (&key id title summary references)
  (let ((topic (or (gethash id *topics-by-id*)
                   (gethash title *topics-by-title*)
                   (make-instance 'topic
                                  :id id
                                  :title title
                                  :summary summary
                                  :references references))))
    (setf (id-of topic) id
          (title-of topic) title
          (summary-of topic) summary
          (references-of topic) references)
    (%register-topic topic)))

;; From hyperdoc/topics/drew-mcdermott.lisp, characters 20130..20617.
(defun annotation-topic ()
  (make-topic
   :id "dock-annotation"
   :title "Annotation"
   :summary "Generic route target/topic-object that classifies annotation relations, so a selected source station such as Text pages can lay a route to Annotation and reopen the same inspectable relation later."
   :references '("Dock capabilities in HyperDoc"
                 "Dock presentation state model"
                 "A DOM-annotation connect gesture"
                 "Associations")))

;; From hyperdoc/dmx-topics.lisp, characters 148..207.
(defparameter *dmx-base-url* "https://dmx.ralfbarkow.ch")

;; From hyperdoc/dmx-topics.lisp, characters 377..433.
(defparameter *dmx-context-window-workspace-id* 919815)

;; From hyperdoc/dmx-topics.lisp, characters 433..488.
(defparameter *dmx-context-window-topicmap-id* 919822)

;; From hyperdoc/dmx-topics.lisp, characters 13137..14112.
(defun parse-positive-integer (designator)
  (labels ((parse-from-string (string)
             (let ((start (position-if #'digit-char-p string)))
               (when start
                 (let ((end (or (position-if-not #'digit-char-p
                                                 string
                                                 :start start)
                                (length string))))
                   (handler-case
                       (let ((value (parse-integer string
                                                   :start start
                                                   :end end)))
                         (and (plusp value) value))
                     (error () nil)))))))
    (cond
      ((integerp designator)
       (and (plusp designator) designator))
      ((stringp designator)
       (parse-from-string designator))
      ((symbolp designator)
       (parse-from-string (symbol-name designator)))
      (t
       nil))))

;; From hyperdoc/dom-annotations.lisp, characters 81..2418.
(defclass dom-annotation-anchor ()
  ((provider-kind :initarg :provider-kind
                  :initform "dom-v1"
                  :reader provider-kind-of)
   (view-kind :initarg :view-kind :initform nil :reader view-kind-of)
   (view-title :initarg :view-title :initform nil :reader view-title-of)
   (pane-id :initarg :pane-id :initform nil :reader pane-id-of)
   (context-object-id :initarg :context-object-id
                      :initform nil
                      :reader context-object-id-of)
   (page-title :initarg :page-title :initform nil :reader page-title-of)
   (site-domain :initarg :site-domain :initform nil :reader site-domain-of)
   (page-slug :initarg :page-slug :initform nil :reader page-slug-of)
   (story-item-id :initarg :story-item-id :initform nil :reader story-item-id-of)
   (story-item-type :initarg :story-item-type
                    :initform nil
                    :reader story-item-type-of)
   (strategy :initarg :strategy :reader anchor-strategy-of)
   (value :initarg :value :reader anchor-value-of)
   (selector :initarg :selector :initform nil :reader selector-of)
   (label :initarg :label :initform nil :reader label-of)
   (tag-name :initarg :tag-name :initform nil :reader tag-name-of)
   (text-snippet :initarg :text-snippet :initform nil :reader text-snippet-of)
   (path :initarg :path :initform nil :reader path-of)
   (start-line :initarg :start-line :initform nil :reader start-line-of)
   (end-line :initarg :end-line :initform nil :reader end-line-of)
   (start-column :initarg :start-column :initform nil :reader start-column-of)
   (end-column :initarg :end-column :initform nil :reader end-column-of)
   (section-path :initarg :section-path :initform nil :reader section-path-of)
   (durability-tier :initarg :durability-tier
                    :initform nil
                    :reader durability-tier-of)
   (durability-note :initarg :durability-note
                    :initform nil
                    :reader durability-note-of)
   (fallback-strategy :initarg :fallback-strategy
                      :initform nil
                      :reader fallback-strategy-of)
   (fallback-value :initarg :fallback-value
                   :initform nil
                   :reader fallback-value-of)
   (object-id :initarg :object-id :initform nil :reader anchor-object-id-of)))

;; From hyperdoc/dom-annotations.lisp, characters 2418..3678.
(defclass dom-relation-annotation ()
  ((id :initarg :id :reader id-of)
   (title :initarg :title :reader title-of)
   (summary :initarg :summary :reader summary-of)
   (context-object :initarg :context-object :initform nil
                   :reader context-object-of)
   (context-view-title :initarg :context-view-title :initform nil
                       :reader context-view-title-of)
   (source-anchor :initarg :source-anchor :reader source-anchor-of)
   (target-anchor :initarg :target-anchor :reader target-anchor-of)
   (source-object :initarg :source-object :initform nil
                  :reader source-object-of)
   (target-object :initarg :target-object :initform nil
                  :reader target-object-of)
   (relation-kind :initarg :relation-kind :initform nil
                  :reader relation-kind-of)
   (note :initarg :note :initform nil :reader note-of)
   (matching-patch-target :initarg :matching-patch-target :initform nil
                          :reader matching-patch-target-of)
   (matching-defect :initarg :matching-defect :initform nil
                    :reader matching-defect-of)
   (matching-inserted-step :initarg :matching-inserted-step :initform nil
                           :reader matching-inserted-step-of)))

;; From hyperdoc/dom-annotations.lisp, characters 30799..30886.
(defun dom-annotation-json-keyword (value)
  (intern (string-upcase value) :keyword))

;; From hyperdoc/dom-annotations.lisp, characters 30886..31491.
(defun normalize-dom-annotation-json (value)
  (cond
    ((stringp value)
     value)
    ((eq value :null)
     nil)
    ((eq value :true)
     t)
    ((eq value :false)
     nil)
    ((hash-table-p value)
     (loop for json-key being each hash-key of value
           using (hash-value json-value)
           append (list (dom-annotation-json-keyword json-key)
                        (normalize-dom-annotation-json json-value))))
    ((vectorp value)
     (map 'list #'normalize-dom-annotation-json value))
    ((listp value)
     (mapcar #'normalize-dom-annotation-json value))
    (t
     value)))

;; From hyperdoc/dom-annotations.lisp, characters 31491..31859.
(defun parse-dom-annotation-json (json-string)
  (let ((trimmed (and json-string
                      (string-trim '(#\Space #\Tab #\Newline #\Return)
                                   json-string))))
    (when (and trimmed (> (length trimmed) 0))
      (with-input-from-string (stream trimmed)
        (normalize-dom-annotation-json (shasht:read-json stream))))))

;; From hyperdoc/dom-annotations.lisp, characters 31859..32004.
(defun anchor-label-for-json (json)
  (or (getf json :label)
      (getf json :textSnippet)
      (getf json :value)
      "<unnamed-anchor>"))

;; From hyperdoc/dom-annotations.lisp, characters 32004..33912.
(defun inferred-anchor-durability-note (provider-kind strategy)
  (cond
    ((or (string= provider-kind "source-v1")
         (string= strategy "source-line-range")
         (string= strategy "source-line"))
     "Source line anchors are durable for the same file path and line range, but line numbers can drift when the source file changes.")
    ((or (string= provider-kind "fedwiki-v1")
         (string= strategy "fedwiki-story-item"))
     "FedWiki story-item anchors resolve clicks to site, slug, and story-item id. They remain durable while the page slug and story-item id are preserved by journal evolution; DOM location is fallback metadata only.")
    ((string= strategy "heading-anchor")
     "Heading anchors resolve to the semantic heading path within the current HyperDoc page. They are more durable than raw DOM paths, but can drift if headings are renamed or restructured.")
    ((string= strategy "list-item-anchor")
     "List-item anchors resolve to heading scope plus list and item position. They are more durable than raw DOM paths, but still depend on recognizable section and list structure.")
    ((string= strategy "paragraph-anchor")
     "Paragraph anchors resolve to heading scope plus paragraph index. They are more durable than raw DOM paths, but can drift when paragraphs are inserted, removed, or reordered.")
    ((string= strategy "data-anchor")
     "Authored anchor ids are the strongest DOM-backed anchors in this slice; durability depends on the id being preserved across page revisions.")
    ((string= strategy "data-object-id")
     "Object-id anchors remain stable while the rendered element continues to represent the same related object.")
    ((string= strategy "element-id")
     "Element-id anchors remain stable while the DOM id is preserved.")
    (t
     "Relative DOM-path anchors are fallback-level and can drift when the rendered tree shape changes.")))

;; From hyperdoc/dom-annotations.lisp, characters 33912..35951.
(defun make-dom-annotation-anchor-from-json (json)
  (let* ((provider-kind (or (getf json :providerKind)
                            "dom-v1"))
         (strategy (or (getf json :strategy)
                       "dom-path")))
    (make-instance 'dom-annotation-anchor
                   :provider-kind provider-kind
                   :view-kind (getf json :viewKind)
                   :view-title (getf json :viewTitle)
                   :pane-id (getf json :paneId)
                   :context-object-id (getf json :contextObjectId)
                   :page-title (getf json :pageTitle)
                   :site-domain (getf json :siteDomain)
                   :page-slug (getf json :pageSlug)
                   :story-item-id (getf json :storyItemId)
                   :story-item-type (getf json :storyItemType)
                   :strategy strategy
                   :value (or (getf json :value)
                              (getf json :fallbackValue)
                              (getf json :selector)
                              "")
                   :selector (getf json :selector)
                   :label (anchor-label-for-json json)
                   :tag-name (getf json :tagName)
                   :text-snippet (getf json :textSnippet)
                   :path (getf json :path)
                   :start-line (getf json :startLine)
                   :end-line (getf json :endLine)
                   :start-column (getf json :startColumn)
                   :end-column (getf json :endColumn)
                   :section-path (getf json :sectionPath)
                   :durability-tier (getf json :durabilityTier)
                   :durability-note (or (getf json :durabilityNote)
                                        (inferred-anchor-durability-note
                                         provider-kind strategy))
                   :fallback-strategy (getf json :fallbackStrategy)
                   :fallback-value (getf json :fallbackValue)
                   :object-id (getf json :objectId))))

;; From hyperdoc/dock.lisp, characters 109..414.
(defclass dock-annotation (dom-relation-annotation)
  ((dock-capability :reader dock-capability-of
                    :initarg :dock-capability
                    :initform "Annotation")
   (registry-key :reader registry-key-of
                 :initarg :registry-key
                 :initform nil)))

;; From hyperdoc/dock.lisp, characters 935..1084.
(defun dock-object-stable-id (object)
  (or (ignore-errors (id-of object))
      (ignore-errors (title-of object))
      (format nil "~A" object)))

;; From hyperdoc/code-path-graphs.lisp, characters 1330..1865.
(defun code-path-graph-human-label (value)
  (let ((text (cond
                ((null value) "")
                ((keywordp value) (symbol-name value))
                ((symbolp value) (symbol-name value))
                ((stringp value) value)
                (t (format nil "~A" value)))))
    (with-output-to-string (stream)
      (loop for char across text
            do (write-char
                (case char
                  ((#\- #\_) #\Space)
                  (otherwise (char-downcase char)))
                stream)))))

;; From hyperdoc/collective-knowledge-slice.lisp, characters 1299..1682.
(defclass collective-knowledge-chunk ()
  ((id :initarg :id :reader id-of)
   (title :initarg :title :reader title-of)
   (summary :initarg :summary :reader summary-of)
   (source-path :initarg :source-path
                :initform nil
                :reader source-path-of)
   (references :initarg :references
               :initform nil
               :reader references-of)))

;; From hyperdoc/collective-knowledge-slice.lisp, characters 4878..5672.
(defclass topic-definition-chunk (collective-knowledge-chunk)
  ((snippet-id :initarg :snippet-id :reader snippet-id-of)
   (snippet-text :initarg :snippet-text :reader snippet-text-of)
   (source-origin-id :initarg :source-origin-id
                     :reader source-origin-id-of)
   (source-origin-path :initarg :source-origin-path
                       :reader source-origin-path-of)
   (related-hyperdoc-page-title :initarg :related-hyperdoc-page-title
                                :reader related-hyperdoc-page-title-of)
   (related-topic-id :initarg :related-topic-id
                     :reader related-topic-id-of)
   (related-topic-ids :initarg :related-topic-ids
                      :reader related-topic-ids-of)
   (provenance :initarg :provenance :reader provenance-of)))

;; From hyperdoc/collective-knowledge-slice.lisp, characters 9923..10118.
(defun dmx-runtime-array-elements (value)
  (cond
    ((null value) nil)
    ((vectorp value) (coerce value 'list))
    ((listp value) value)
    (t
     (error "Expected JSON array, got ~S" value))))

;; From hyperdoc/collective-knowledge-slice.lisp, characters 41355..41499.
(defun make-the-life-cycle-of-collective-knowledge-dmx-snippet-uri (snippet-id)
  (format nil "hyperdoc:topic-factory-snippet/~A" snippet-id))

;; The MCP caller constructs this DTO from explicit arguments. The historical
;; NIL/pathname fallback loads a FedWiki example; it is outside this application.
(defun dmx-mcp-require-snippet-definition (source)
  (check-type source topic-definition-chunk)
  source)

;; Pure formatter formerly only loaded by the Explorer. No UI dependency.
(defun workspace-annotation-render-value (value &key (default "-"))
  (cond ((null value) default) ((stringp value) value) (t (format nil "~A" value))))
