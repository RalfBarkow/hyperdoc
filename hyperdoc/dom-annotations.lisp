;;;; DOM relation annotations
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

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

(defclass dom-connect-pane-state-snapshot ()
  ((id :initarg :id :reader id-of)
   (title :initarg :title :reader title-of)
   (summary :initarg :summary :reader summary-of)
   (pane-id :initarg :pane-id :reader pane-id-of)
   (active-tab :initarg :active-tab :initform nil :reader active-tab-of)
   (context-view-title :initarg :context-view-title
                       :initform nil
                       :reader context-view-title-of)
   (provider-kind :initarg :provider-kind
                  :initform nil
                  :reader provider-kind-of)
   (available :initarg :available :initform nil :reader available-p-of)
   (enabled :initarg :enabled :initform nil :reader enabled-p-of)
   (local-phase :initarg :local-phase :initform "dormant" :reader local-phase-of)
   (help-open :initarg :help-open :initform nil :reader help-open-p-of)
   (selected-source-label :initarg :selected-source-label
                          :initform nil
                          :reader selected-source-label-of)
   (selected-source-pane :initarg :selected-source-pane
                         :initform nil
                         :reader selected-source-pane-p-of)
   (pending-request-id :initarg :pending-request-id
                       :initform nil
                       :reader pending-request-id-of)))

(defclass dom-connect-transition-entry ()
  ((id :initarg :id :reader id-of)
   (title :initarg :title :reader title-of)
   (summary :initarg :summary :reader summary-of)
   (request-id :initarg :request-id :initform nil :reader request-id-of)
   (stage :initarg :stage :initform nil :reader stage-of)
   (timestamp :initarg :timestamp :initform nil :reader timestamp-of)
   (timestamp-label :initarg :timestamp-label
                    :initform nil
                    :reader timestamp-label-of)
   (pane-id :initarg :pane-id :initform nil :reader pane-id-of)
   (provider-kind :initarg :provider-kind
                  :initform nil
                  :reader provider-kind-of)
   (anchor :initarg :anchor :initform nil :reader anchor-of)
   (source-anchor :initarg :source-anchor :initform nil :reader source-anchor-of)
   (target-anchor :initarg :target-anchor :initform nil :reader target-anchor-of)
   (details :initarg :details :initform nil :reader details-of)))

(defclass dom-connect-session-snapshot ()
  ((id :initarg :id :reader id-of)
   (title :initarg :title :reader title-of)
   (summary :initarg :summary :reader summary-of)
   (context-object :initarg :context-object :initform nil
                   :reader context-object-of)
   (context-view-title :initarg :context-view-title :initform nil
                       :reader context-view-title-of)
   (captured-at :initarg :captured-at :initform nil :reader captured-at-of)
   (captured-at-label :initarg :captured-at-label
                      :initform nil
                      :reader captured-at-label-of)
   (session-id :initarg :session-id :initform nil :reader session-id-of)
   (phase :initarg :phase :initform "idle" :reader phase-of)
   (origin-pane-id :initarg :origin-pane-id
                   :initform nil
                   :reader origin-pane-id-of)
   (source-pane-id :initarg :source-pane-id
                   :initform nil
                   :reader source-pane-id-of)
   (source-provider-kind :initarg :source-provider-kind
                         :initform nil
                         :reader source-provider-kind-of)
   (source-anchor :initarg :source-anchor :initform nil :reader source-anchor-of)
   (target-pane-id :initarg :target-pane-id
                   :initform nil
                   :reader target-pane-id-of)
   (target-provider-kind :initarg :target-provider-kind
                         :initform nil
                         :reader target-provider-kind-of)
   (target-anchor :initarg :target-anchor :initform nil :reader target-anchor-of)
   (panes :initarg :panes :initform nil :reader panes-of)
   (transitions :initarg :transitions :initform nil :reader transitions-of)
   (pending-request-id :initarg :pending-request-id
                       :initform nil
                       :reader pending-request-id-of)
   (pending-request-state :initarg :pending-request-state
                          :initform nil
                          :reader pending-request-state-of)
   (last-transition :initarg :last-transition
                    :initform nil
                    :reader last-transition-of)))

(defclass dom-connect-request-evidence ()
  ((id :initarg :id :reader id-of)
   (title :initarg :title :accessor title-of)
   (summary :initarg :summary :accessor summary-of)
   (context-object :initarg :context-object :initform nil
                   :reader context-object-of)
   (context-view-title :initarg :context-view-title :initform nil
                       :reader context-view-title-of)
   (request-id :initarg :request-id :reader request-id-of)
   (transport :initarg :transport :initform nil :accessor transport-of)
   (inspection-pane-id :initarg :inspection-pane-id
                       :initform nil
                       :accessor inspection-pane-id-of)
   (source-pane-id :initarg :source-pane-id
                   :initform nil
                   :accessor source-pane-id-of)
   (target-pane-id :initarg :target-pane-id
                   :initform nil
                   :accessor target-pane-id-of)
   (source-provider-kind :initarg :source-provider-kind
                         :initform nil
                         :accessor source-provider-kind-of)
   (target-provider-kind :initarg :target-provider-kind
                         :initform nil
                         :accessor target-provider-kind-of)
   (source-anchor :initarg :source-anchor
                  :initform nil
                  :accessor source-anchor-of)
   (target-anchor :initarg :target-anchor
                  :initform nil
                  :accessor target-anchor-of)
   (session-snapshot :initarg :session-snapshot
                     :initform nil
                     :accessor session-snapshot-of)
   (submitted-at :initarg :submitted-at
                 :initform nil
                 :accessor submitted-at-of)
   (submitted-at-label :initarg :submitted-at-label
                       :initform nil
                       :accessor submitted-at-label-of)
   (updated-at :initarg :updated-at :initform nil :accessor updated-at-of)
   (updated-at-label :initarg :updated-at-label
                     :initform nil
                     :accessor updated-at-label-of)
   (server-status :initarg :server-status
                  :initform "submitted"
                  :accessor server-status-of)
   (server-message :initarg :server-message
                   :initform nil
                   :accessor server-message-of)
   (server-detail :initarg :server-detail
                  :initform nil
                  :accessor server-detail-of)
   (server-acknowledged :initarg :server-acknowledged
                        :initform nil
                        :accessor server-acknowledged-p-of)
   (browser-failure-kind :initarg :browser-failure-kind
                         :initform nil
                         :accessor browser-failure-kind-of)
   (browser-message :initarg :browser-message
                    :initform nil
                    :accessor browser-message-of)
   (browser-detail :initarg :browser-detail
                   :initform nil
                   :accessor browser-detail-of)))

(defclass dom-connect-submit-path ()
  ((id :initarg :id :reader id-of)
   (title :initarg :title :reader title-of)
   (summary :initarg :summary :reader summary-of)
   (trigger :initarg :trigger :initform nil :reader trigger-of)
   (purpose :initarg :purpose :initform nil :reader purpose-of)
   (transport-tag :initarg :transport-tag
                  :initform nil
                  :reader transport-tag-of)
   (payload-bearing-element :initarg :payload-bearing-element
                            :initform nil
                            :reader payload-bearing-element-of)
   (authoritative-payload-fields :initarg :authoritative-payload-fields
                                 :initform nil
                                 :reader authoritative-payload-fields-of)
   (snapshot-carrier :initarg :snapshot-carrier
                     :initform nil
                     :reader snapshot-carrier-of)
   (snapshot-handling :initarg :snapshot-handling
                      :initform nil
                      :reader snapshot-handling-of)
   (snapshot-transport-status :initarg :snapshot-transport-status
                              :initform nil
                              :reader snapshot-transport-status-of)
   (hidden-field-dependency :initarg :hidden-field-dependency
                            :initform nil
                            :reader hidden-field-dependency-of)
   (server-parse-order :initarg :server-parse-order
                       :initform nil
                       :reader server-parse-order-of)
   (object-opened :initarg :object-opened
                  :initform nil
                  :reader object-opened-of)
   (typical-interpretation :initarg :typical-interpretation
                           :initform nil
                           :reader typical-interpretation-of)
   (lineage :initarg :lineage :initform nil :reader lineage-of)))

(defclass dom-connect-submit-path-comparison ()
  ((id :initarg :id :reader id-of)
   (title :initarg :title :reader title-of)
   (summary :initarg :summary :reader summary-of)
   (normal-path :initarg :normal-path :reader normal-path-of)
   (evidence-path :initarg :evidence-path :reader evidence-path-of)
   (server-seam :initarg :server-seam :initform nil :reader server-seam-of)
   (no-snapshot-message-meaning :initarg :no-snapshot-message-meaning
                                :initform nil
                                :reader no-snapshot-message-meaning-of)
   (lineage :initarg :lineage :initform nil :reader lineage-of)))

(defclass dom-connect-snapshot-transport-path ()
  ((id :initarg :id :reader id-of)
   (title :initarg :title :reader title-of)
   (summary :initarg :summary :reader summary-of)
   (producer :initarg :producer :initform nil :reader producer-of)
   (carrier :initarg :carrier :initform nil :reader carrier-of)
   (payload-bearing-element :initarg :payload-bearing-element
                            :initform nil
                            :reader payload-bearing-element-of)
   (authority-status :initarg :authority-status
                     :initform nil
                     :reader authority-status-of)
   (hidden-field-dependency :initarg :hidden-field-dependency
                            :initform nil
                            :reader hidden-field-dependency-of)
   (server-parse-order :initarg :server-parse-order
                       :initform nil
                       :reader server-parse-order-of)
   (absence-interpretation :initarg :absence-interpretation
                           :initform nil
                           :reader absence-interpretation-of)
   (downstream-object :initarg :downstream-object
                      :initform nil
                      :reader downstream-object-of)
   (lineage :initarg :lineage :initform nil :reader lineage-of)))

(defclass dom-connect-snapshot-transport ()
  ((id :initarg :id :reader id-of)
   (title :initarg :title :reader title-of)
   (summary :initarg :summary :reader summary-of)
   (normal-path :initarg :normal-path :reader normal-path-of)
   (evidence-path :initarg :evidence-path :reader evidence-path-of)
   (operational-definition :initarg :operational-definition
                           :initform nil
                           :reader operational-definition-of)
   (server-seam :initarg :server-seam :initform nil :reader server-seam-of)
   (absence-interpretation :initarg :absence-interpretation
                           :initform nil
                           :reader absence-interpretation-of)
   (lineage :initarg :lineage :initform nil :reader lineage-of)))

(defmethod print-object ((object dom-annotation-anchor) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (or (label-of object)
                            (anchor-value-of object)))))

(defmethod print-object ((object dom-relation-annotation) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object dom-connect-pane-state-snapshot) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object dom-connect-transition-entry) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object dom-connect-session-snapshot) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object dom-connect-request-evidence) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object dom-connect-submit-path) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object dom-connect-submit-path-comparison) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object dom-connect-snapshot-transport-path) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object dom-connect-snapshot-transport) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defun normal-dom-association-submit-path ()
  (make-instance
   'dom-connect-submit-path
   :id "dom-connect-submit-path/normal-association"
   :title "Normal association submit path"
   :summary
   "The standard Connect submit path authoritatively transports source and target association data, but not the submit-boundary session snapshot."
   :trigger
   "Open association after the browser has resolved source and target anchors."
   :purpose
   "Create or open the association object."
   :transport-tag
   "button-payload-v2"
   :payload-bearing-element
   "The clicked submit button in the normal Connect submit affordance."
   :authoritative-payload-fields
   '("request id"
     "context object id"
     "context view title"
     "source-json"
     "target-json"
     "source field id"
     "target field id"
     "source pane id"
     "target pane id"
     "source provider kind"
     "target provider kind")
   :snapshot-carrier
   "Not the authoritative payload element; snapshot JSON stays only in the hidden inspect field if that field exists."
   :snapshot-handling
   "writeSubmitPayload() writes source/target/context/provider data onto the button but does not attach data-dom-connect-snapshot-json."
   :snapshot-transport-status
   "Fallback or best-effort only."
   :hidden-field-dependency
   "Yes. Snapshot recovery depends on the hidden inspect field referenced by data-dom-connect-snapshot-field-id if that field is present and readable."
   :server-parse-order
   "dom-association-submit-payload reads data-dom-connect-snapshot-json from the payload-bearing element first, then falls back to the hidden snapshot field. In the normal path, snapshot recovery usually depends on that fallback."
   :object-opened
   "Association object or association pane."
   :typical-interpretation
   "Association creation can succeed even when no submit-boundary session snapshot is reconstructed later. The later message about a missing snapshot does not by itself mean the request failed."
   :lineage
   '("writeSubmitPayload()"
     "dom-association-submit-payload"
     "ensure-dom-connect-request-evidence"
     "maybe-dom-connect-session-snapshot-from-json-string")))

(defun connect-request-evidence-submit-path ()
  (make-instance
   'dom-connect-submit-path
   :id "dom-connect-submit-path/request-evidence"
   :title "Evidence path"
   :summary
   "The request-evidence submit path authoritatively transports snapshot JSON on the evidence button, so request evidence can usually reconstruct the session snapshot directly from the submitted payload."
   :trigger
   "Inspect request evidence or open browser failure evidence at the submit boundary."
   :purpose
   "Open Connect request evidence or browser failure evidence."
   :transport-tag
   "connect-request-evidence-v1"
   :payload-bearing-element
   "The evidence button prepared for the request-evidence submit."
   :authoritative-payload-fields
   '("request id"
     "context object id"
     "context view title"
     "snapshot field id"
     "request evidence request id"
     "browser failure kind"
     "browser message"
     "browser detail"
     "snapshot JSON")
   :snapshot-carrier
   "The evidence button itself via data-dom-connect-snapshot-json, mirrored secondarily into the hidden inspect field."
   :snapshot-handling
   "prepareEvidenceButton() writes data-dom-connect-snapshot-json directly onto the evidence button and also mirrors the same JSON into the hidden inspect field."
   :snapshot-transport-status
   "Authoritative on the payload-bearing element."
   :hidden-field-dependency
   "No for the primary payload contract. The hidden inspect field is only a secondary mirror."
   :server-parse-order
   "dom-association-submit-payload reads data-dom-connect-snapshot-json from the payload-bearing element first. In the evidence path, that first branch usually already contains the snapshot JSON."
   :object-opened
   "Connect request evidence or browser failure evidence."
   :typical-interpretation
   "If the request-evidence submit succeeds and the inline snapshot JSON is parseable, the evidence object can usually reconstruct the submit-boundary session snapshot directly from the submitted payload."
   :lineage
   '("prepareEvidenceButton()"
     "dom-association-submit-payload"
     "ensure-dom-connect-request-evidence"
     "maybe-dom-connect-session-snapshot-from-json-string")))

(defun dom-connect-submit-path-comparison ()
  (make-instance
   'dom-connect-submit-path-comparison
   :id "dom-connect-submit-path-comparison"
   :title "Normal association submit path vs evidence path"
   :summary
   "Operational comparison of the standard association submit path and the request-evidence path at the submit boundary, with emphasis on where source/target data is authoritative and where snapshot JSON is authoritative."
   :normal-path (normal-dom-association-submit-path)
   :evidence-path (connect-request-evidence-submit-path)
   :server-seam
   "At the server seam, dom-association-submit-payload always tries snapshot JSON on the payload-bearing element first and only then falls back to the hidden control referenced by data-dom-connect-snapshot-field-id. Snapshot reconstruction in ensure-dom-connect-request-evidence therefore depends on whether snapshot JSON was actually transported and parseable."
   :no-snapshot-message-meaning
   "The message \"No submit-boundary session snapshot was captured.\" does not necessarily mean the request failed. In the normal association path, source-json and target-json can be authoritative and sufficient for association creation even when snapshot JSON never travelled authoritatively on the payload-bearing element."
   :lineage
   '("writeSubmitPayload()"
     "prepareEvidenceButton()"
     "dom-association-submit-payload"
     "ensure-dom-connect-request-evidence"
     "maybe-dom-connect-session-snapshot-from-json-string")))

(defun normal-dom-connect-snapshot-transport-path ()
  (make-instance
   'dom-connect-snapshot-transport-path
   :id "dom-connect-snapshot-transport/normal-association"
   :title "Normal association snapshot transport"
   :summary
   "The normal association path can build a browser snapshot, but snapshot JSON crosses the submit boundary only through the hidden inspect field fallback."
   :producer "writeSubmitPayload()"
   :carrier
   "The hidden inspect field named by data-dom-connect-snapshot-field-id if that field remains present and readable."
   :payload-bearing-element
   "The clicked normal association submit button carries button-payload-v2, but it does not carry data-dom-connect-snapshot-json itself."
   :authority-status
   "Fallback only. Snapshot transport is not authoritative on the payload-bearing button."
   :hidden-field-dependency
   "Yes. Later reconstruction depends on the hidden inspect field mirror."
   :server-parse-order
   "dom-association-submit-payload reads data-dom-connect-snapshot-json from the payload-bearing element first, then falls back to the hidden field named by data-dom-connect-snapshot-field-id. The normal path usually reaches only that second branch."
   :absence-interpretation
   "The browser may have built a snapshot successfully, while later evidence still lacks a reconstructed submit-boundary session snapshot because snapshot JSON never crossed the boundary authoritatively."
   :downstream-object
   "Association object first; request evidence may later exist without a reconstructed dom-connect-session-snapshot."
   :lineage
   '("debugSnapshot()"
     "writeSubmitPayload()"
     "dom-association-submit-payload"
     "ensure-dom-connect-request-evidence"
     "maybe-dom-connect-session-snapshot-from-json-string")))

(defun evidence-dom-connect-snapshot-transport-path ()
  (make-instance
   'dom-connect-snapshot-transport-path
   :id "dom-connect-snapshot-transport/request-evidence"
   :title "Evidence-path snapshot transport"
   :summary
   "The evidence path carries snapshot JSON directly on the payload-bearing evidence button, so submit-boundary reconstruction can usually use the inline carrier without needing the hidden-field fallback."
   :producer "prepareEvidenceButton()"
   :carrier
   "The evidence button itself via data-dom-connect-snapshot-json, mirrored secondarily into the hidden inspect field."
   :payload-bearing-element
   "The evidence button tagged with connect-request-evidence-v1."
   :authority-status
   "Authoritative inline carrier on the payload-bearing element."
   :hidden-field-dependency
   "No for the primary transport contract. The hidden inspect field is only a secondary mirror."
   :server-parse-order
   "dom-association-submit-payload reads data-dom-connect-snapshot-json from the payload-bearing element first. On the evidence path, that first branch already carries the submit-boundary snapshot JSON."
   :absence-interpretation
   "If snapshot JSON is absent or unparsable here, request evidence can still exist, but it will lack the reconstructed dom-connect-session-snapshot despite carrying request metadata and browser failure classification."
   :downstream-object
   "Connect request evidence or direct Connect snapshot inspection with reconstructed submit-boundary state."
   :lineage
   '("debugSnapshot()"
     "prepareEvidenceButton()"
     "dom-association-submit-payload"
     "ensure-dom-connect-request-evidence"
     "maybe-dom-connect-session-snapshot-from-json-string")))

(defun dom-connect-snapshot-transport ()
  (make-instance
   'dom-connect-snapshot-transport
   :id "dom-connect-snapshot-transport"
   :title "Snapshot transport"
   :summary
   "Snapshot transport is the submit-boundary carrier seam by which browser-captured Connect snapshot JSON crosses from pane UI state into the server-side payload, enabling later request evidence or direct snapshot inspection to reconstruct the exact browser-side session state."
   :normal-path (normal-dom-connect-snapshot-transport-path)
   :evidence-path (evidence-dom-connect-snapshot-transport-path)
   :operational-definition
   "Snapshot construction is not snapshot transport. debugSnapshot() may succeed in the browser, yet later evidence still lacks a dom-connect-session-snapshot unless snapshot JSON actually crosses the submit boundary."
   :server-seam
   "Transport authority is path-dependent because dom-association-submit-payload reads data-dom-connect-snapshot-json from the payload-bearing element first and only then falls back to the hidden field named by data-dom-connect-snapshot-field-id."
   :absence-interpretation
   "\"No submit-boundary session snapshot was captured.\" means the reconstruction seam lacked transported snapshot JSON, not necessarily that the original Connect request failed."
   :lineage
   '("debugSnapshot()"
     "writeSubmitPayload()"
     "prepareEvidenceButton()"
     "dom-association-submit-payload"
     "ensure-dom-connect-request-evidence"
     "maybe-dom-connect-session-snapshot-from-json-string")))

(defun shorten-dom-association-label (value &optional (max-length 88))
  (if (<= (length value) max-length)
      value
      (let* ((room (- max-length 3))
             (front (ceiling room 2))
             (back (floor room 2)))
        (format nil "~A...~A"
                (subseq value 0 front)
                (subseq value (- (length value) back))))))

(defun dom-annotation-json-keyword (value)
  (intern (string-upcase value) :keyword))

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

(defun parse-dom-annotation-json (json-string)
  (let ((trimmed (and json-string
                      (string-trim '(#\Space #\Tab #\Newline #\Return)
                                   json-string))))
    (when (and trimmed (> (length trimmed) 0))
      (with-input-from-string (stream trimmed)
        (normalize-dom-annotation-json (shasht:read-json stream))))))

(defun anchor-label-for-json (json)
  (or (getf json :label)
      (getf json :textSnippet)
      (getf json :value)
      "<unnamed-anchor>"))

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

(defun anchor-surface-label (anchor)
  (let ((context-object-id (or (page-title-of anchor)
                               (context-object-id-of anchor)))
        (view-title (view-title-of anchor)))
    (cond
      ((and context-object-id view-title)
       (format nil "~A / ~A" context-object-id view-title))
      (context-object-id
       context-object-id)
      (view-title
       view-title)
      (t
       "current surface"))))

(defun semantic-anchor-kind-of (anchor)
  (anchor-strategy-of anchor))

(defun semantic-anchor-identity-of (anchor)
  (anchor-value-of anchor))

(defun section-path-summary (section-path)
  (when section-path
    (format nil "~{~A~^ / ~}"
            (mapcar (lambda (entry)
                      (or (getf entry :label)
                          (getf entry :slug)
                          "?"))
                    section-path))))

(defun source-line-range-summary (anchor)
  (when (start-line-of anchor)
    (format nil "~D:~D - ~D:~D"
            (start-line-of anchor)
            (or (start-column-of anchor) 1)
            (or (end-line-of anchor)
                (start-line-of anchor))
            (or (end-column-of anchor)
                (or (start-column-of anchor) 1)))))

(defun semantic-anchor-identity-fields (anchor)
  (remove nil
          (list
           (cons "Semantic kind" (semantic-anchor-kind-of anchor))
           (cons "Semantic identity" (semantic-anchor-identity-of anchor))
           (and (anchor-object-id-of anchor)
                (cons "Object id" (anchor-object-id-of anchor)))
           (and (page-title-of anchor)
                (cons "Page title" (page-title-of anchor)))
           (and (site-domain-of anchor)
                (cons "Site domain" (site-domain-of anchor)))
           (and (page-slug-of anchor)
                (cons "Page slug" (page-slug-of anchor)))
           (and (story-item-id-of anchor)
                (cons "Story item id" (story-item-id-of anchor)))
           (and (story-item-type-of anchor)
                (cons "Story item type" (story-item-type-of anchor)))
           (and (path-of anchor)
                (cons "Path" (format nil "~A" (path-of anchor))))
           (and (section-path-of anchor)
                (cons "Section path"
                      (section-path-summary (section-path-of anchor))))
           (and (start-line-of anchor)
                (cons "Line range" (source-line-range-summary anchor))))))

(defun presentation-anchor-fallback-fields (anchor)
  (remove nil
          (list
           (and (selector-of anchor)
                (cons "Selector" (selector-of anchor)))
           (and (fallback-strategy-of anchor)
                (cons "Fallback strategy" (fallback-strategy-of anchor)))
           (and (fallback-value-of anchor)
                (cons "Fallback value" (fallback-value-of anchor)))
           (and (tag-name-of anchor)
                (cons "Tag" (tag-name-of anchor))))))

(defun dom-connect-anchor-label (anchor)
  (when anchor
    (or (label-of anchor)
        (anchor-value-of anchor)
        (text-snippet-of anchor))))

(defun dom-connect-present-p (value)
  (and value
       (not (and (stringp value)
                 (zerop (length (string-trim '(#\Space #\Tab #\Newline #\Return)
                                             value)))))))

(defun dom-connect-bool-label (value)
  (if value "yes" "no"))

(defun dom-connect-transition-stage-summary (stage details source-anchor
                                              target-anchor anchor)
  (let ((stage (or stage "")))
    (labels ((anchor-label (anchor-object)
             (or (dom-connect-anchor-label anchor-object) "anchor")))
      (cond
        ((string= stage "session-started")
         (format nil "Session started in ~A."
                 (or (getf details :originPaneId)
                     (getf details :paneId)
                     "the current pane")))
        ((string= stage "source-selected")
         (format nil "Source selected: ~A."
                 (anchor-label (or anchor source-anchor))))
        ((string= stage "target-selected")
         (format nil "Target selected: ~A."
                 (anchor-label (or anchor target-anchor))))
        ((string= stage "request-payload-written")
         (format nil "Request payload written for ~A -> ~A."
                 (or (getf details :sourceProviderKind) "source")
                 (or (getf details :targetProviderKind) "target")))
        ((string= stage "association-payload-assembled")
         (format nil "Association payload assembled for ~A -> ~A."
                 (anchor-label source-anchor)
                 (anchor-label target-anchor)))
        ((string= stage "pane-open-succeeded")
         "Association pane opened.")
        ((string= stage "session-cancelled")
         "Connect session cancelled.")
        ((string= stage "source-cleared")
         "Selected source cleared.")
        ((string= stage "request-failed")
         (or (getf details :message)
             "Association request failed."))
        (t
         (format nil "~A" stage))))))

(defun dom-connect-pane-state-summary (pane-id local-phase provider-kind
                                       active-tab)
  (format nil "Pane ~A is ~A in ~A (~A)."
          (or pane-id "?")
          (or local-phase "dormant")
          (or active-tab "its current view")
          (or provider-kind "unknown provider")))

(defun dom-connect-transition-title (stage timestamp-label)
  (if (dom-connect-present-p timestamp-label)
      (format nil "Connect transition: ~A @ ~A" stage timestamp-label)
      (format nil "Connect transition: ~A" stage)))

(defun dom-connect-transition-id (request-id stage timestamp)
  (format nil "connect-transition/~A/~A/~A"
          (or request-id "no-request")
          (slugify-dom-relation-fragment (or stage "transition"))
          (or timestamp "now")))

(defun make-dom-connect-pane-state-snapshot-from-json (json)
  (let* ((pane-id (getf json :paneId))
         (active-tab (getf json :activeTab))
         (context-view-title (getf json :contextViewTitle))
         (provider-kind (getf json :providerKind))
         (local-phase (getf json :phase))
         (selected-source-label (getf json :selectedSourceLabel)))
    (make-instance 'dom-connect-pane-state-snapshot
                   :id (format nil "connect-pane/~A" (or pane-id "unknown"))
                   :title (format nil "Connect pane: ~A"
                                  (or pane-id "unknown"))
                   :summary (dom-connect-pane-state-summary
                             pane-id
                             local-phase
                             provider-kind
                             active-tab)
                   :pane-id pane-id
                   :active-tab active-tab
                   :context-view-title context-view-title
                   :provider-kind provider-kind
                   :available (getf json :available)
                   :enabled (getf json :enabled)
                   :local-phase local-phase
                   :help-open (getf json :helpOpen)
                   :selected-source-label selected-source-label
                   :selected-source-pane (getf json :selectedSourcePane)
                   :pending-request-id (getf json :pendingRequestId))))

(defun maybe-dom-connect-anchor-from-json (json)
  (when (and json (listp json))
    (make-dom-annotation-anchor-from-json json)))

(defun maybe-dom-connect-anchor-from-json-string (json-string)
  (let ((json (ignore-errors (parse-dom-annotation-json json-string))))
    (when (and json (listp json))
      (make-dom-annotation-anchor-from-json json))))

(defun dom-connect-evidence-failure-kind-label (failure-kind)
  (cond
    ((string= (or failure-kind "") "websocket-disconnect-before-acknowledgement")
     "websocket disconnect before acknowledgement")
    ((string= (or failure-kind "") "pane-open-timeout")
     "pane-open timeout")
    ((string= (or failure-kind "") "server-failed")
     "server failure")
    (t
     failure-kind)))

(defun make-dom-connect-transition-entry-from-json (json)
  (let* ((details (getf json :details))
         (stage (getf json :stage))
         (request-id (getf json :requestId))
         (timestamp (getf json :timestamp))
         (timestamp-label (getf json :timestampLabel))
         (anchor (maybe-dom-connect-anchor-from-json (getf details :anchor)))
         (source-anchor (maybe-dom-connect-anchor-from-json (getf details :source)))
         (target-anchor (maybe-dom-connect-anchor-from-json (getf details :target)))
         (provider-kind (or (getf details :providerKind)
                            (and anchor (provider-kind-of anchor))
                            (and source-anchor (provider-kind-of source-anchor))
                            (getf details :sourceProviderKind)
                            (getf details :targetProviderKind)))
         (pane-id (or (getf details :paneId)
                      (getf details :sourcePaneId)
                      (getf details :targetPaneId)))
         (summary (dom-connect-transition-stage-summary
                   stage details source-anchor target-anchor anchor)))
    (make-instance 'dom-connect-transition-entry
                   :id (dom-connect-transition-id request-id stage timestamp)
                   :title (dom-connect-transition-title stage timestamp-label)
                   :summary summary
                   :request-id request-id
                   :stage stage
                   :timestamp timestamp
                   :timestamp-label timestamp-label
                   :pane-id pane-id
                   :provider-kind provider-kind
                   :anchor anchor
                   :source-anchor source-anchor
                   :target-anchor target-anchor
                   :details details)))

(defun dom-connect-pending-request-state (phase pending-request-id
                                           last-transition)
  (cond
    (pending-request-id
     (or (and last-transition (stage-of last-transition))
         (and (dom-connect-present-p phase) phase)
         "pending"))
    ((string= (or phase "") "submitting")
     "submitting")
    (t
     nil)))

(defun make-dom-connect-session-snapshot (&key context-object
                                               context-view-title
                                               captured-at
                                               captured-at-label
                                               session-id
                                               phase
                                               origin-pane-id
                                               source-pane-id
                                               source-provider-kind
                                               source-anchor
                                               target-pane-id
                                               target-provider-kind
                                               target-anchor
                                               panes
                                               transitions)
  (let* ((last-transition (car (last transitions)))
         (pending-pane (find-if (lambda (pane)
                                  (dom-connect-present-p
                                   (pending-request-id-of pane)))
                                panes))
         (pending-request-id (and pending-pane
                                  (pending-request-id-of pending-pane)))
         (title (if (dom-connect-present-p session-id)
                    (format nil "Connect session: ~A" session-id)
                    "Connect session"))
         (summary
           (format nil "Snapshot of Connect phase ~A with ~D live pane~:P."
                   (or phase "idle")
                   (length panes))))
    (make-instance 'dom-connect-session-snapshot
                   :id (format nil "connect-session/~A/~A"
                               (or session-id "idle")
                               (or captured-at "now"))
                   :title title
                   :summary summary
                   :context-object context-object
                   :context-view-title context-view-title
                   :captured-at captured-at
                   :captured-at-label captured-at-label
                   :session-id session-id
                   :phase (or phase "idle")
                   :origin-pane-id origin-pane-id
                   :source-pane-id source-pane-id
                   :source-provider-kind source-provider-kind
                   :source-anchor source-anchor
                   :target-pane-id target-pane-id
                   :target-provider-kind target-provider-kind
                   :target-anchor target-anchor
                   :panes panes
                   :transitions transitions
                   :pending-request-id pending-request-id
                   :pending-request-state
                   (dom-connect-pending-request-state
                    phase pending-request-id last-transition)
                   :last-transition last-transition)))

(defun make-dom-connect-session-snapshot-from-json (&key context-object
                                                         context-view-title
                                                         snapshot-json)
  (let* ((data (or (parse-dom-annotation-json snapshot-json)
                   (error "Missing Connect snapshot JSON.")))
         (session (or (getf data :session) '()))
         (panes (mapcar #'make-dom-connect-pane-state-snapshot-from-json
                        (or (getf data :panes) '())))
         (transitions (mapcar #'make-dom-connect-transition-entry-from-json
                              (or (getf data :transitions) '()))))
    (make-dom-connect-session-snapshot
     :context-object context-object
     :context-view-title context-view-title
     :captured-at (getf data :capturedAt)
     :captured-at-label (getf data :capturedAtLabel)
     :session-id (getf session :id)
     :phase (getf session :phase)
     :origin-pane-id (getf session :originPaneId)
     :source-pane-id (getf session :sourcePaneId)
     :source-provider-kind (getf session :sourceProviderKind)
     :source-anchor (maybe-dom-connect-anchor-from-json (getf session :source))
     :target-pane-id (getf session :targetPaneId)
     :target-provider-kind (getf session :targetProviderKind)
     :target-anchor (maybe-dom-connect-anchor-from-json (getf session :target))
     :panes panes
     :transitions transitions)))

(defparameter *dom-connect-request-evidence-max-entries* 160)
(defvar *dom-connect-request-evidence-table* (make-hash-table :test #'equal))
(defvar *dom-connect-request-evidence-order* nil)

(defun dom-connect-request-evidence-title (request-id)
  (format nil "Connect request evidence: ~A"
          (or request-id "unknown")))

(defun dom-connect-request-evidence-summary (request-id server-status
                                             browser-failure-kind)
  (cond
    ((string= (or browser-failure-kind "")
                 "websocket-disconnect-before-acknowledgement")
     (format nil "Request ~A reached the Connect boundary, but the browser lost the websocket before it saw any acknowledgement."
             (or request-id "unknown")))
    ((string= (or browser-failure-kind "") "pane-open-timeout")
     (format nil "Request ~A reached the Connect boundary, but the browser timed out waiting for an acknowledgement."
             (or request-id "unknown")))
    ((string= (or browser-failure-kind "") "server-failed")
     (format nil "Request ~A failed on the server side before the association pane could open."
             (or request-id "unknown")))
    ((string= (or server-status "") "pane-open-succeeded")
     (format nil "Request ~A opened its association pane successfully."
             (or request-id "unknown")))
    ((string= (or server-status "") "failed")
     (format nil "Request ~A failed on the server side before the association pane could open."
             (or request-id "unknown")))
    ((string= (or server-status "") "object-created")
     (format nil "Request ~A created its association object and is waiting for pane-open confirmation."
             (or request-id "unknown")))
    ((string= (or server-status "") "server-received")
     (format nil "Request ~A was received by the server and is waiting for object creation."
             (or request-id "unknown")))
    (t
     (format nil "Request ~A is recorded at the Connect submit boundary."
             (or request-id "unknown")))))

(defun touch-dom-connect-request-evidence-key (request-id)
  (when request-id
    (setf *dom-connect-request-evidence-order*
          (cons request-id
                (remove request-id
                        *dom-connect-request-evidence-order*
                        :test #'equal)))))

(defun trim-dom-connect-request-evidence-registry ()
  (loop while (> (length *dom-connect-request-evidence-order*)
                 *dom-connect-request-evidence-max-entries*)
        do (let ((oldest (car (last *dom-connect-request-evidence-order*))))
             (setf *dom-connect-request-evidence-order*
                   (butlast *dom-connect-request-evidence-order*))
             (when oldest
               (remhash oldest *dom-connect-request-evidence-table*)))))

(defun register-dom-connect-request-evidence (evidence)
  (let ((request-id (request-id-of evidence)))
    (when request-id
      (setf (gethash request-id *dom-connect-request-evidence-table*) evidence)
      (touch-dom-connect-request-evidence-key request-id)
      (trim-dom-connect-request-evidence-registry)))
  evidence)

(defun find-dom-connect-request-evidence (request-id)
  (when request-id
    (let ((evidence (gethash request-id *dom-connect-request-evidence-table*)))
      (when evidence
        (touch-dom-connect-request-evidence-key request-id))
      evidence)))

(defun maybe-dom-connect-session-snapshot-from-json-string (context-object
                                                            context-view-title
                                                            snapshot-json)
  (when snapshot-json
    (ignore-errors
      (make-dom-connect-session-snapshot-from-json
       :context-object context-object
       :context-view-title context-view-title
       :snapshot-json snapshot-json))))

(defun refresh-dom-connect-request-evidence (evidence)
  (setf (title-of evidence)
        (dom-connect-request-evidence-title (request-id-of evidence))
        (summary-of evidence)
        (dom-connect-request-evidence-summary
         (request-id-of evidence)
         (server-status-of evidence)
         (browser-failure-kind-of evidence)))
  evidence)

(defun update-dom-connect-request-evidence-payload (evidence
                                                    &key transport
                                                      inspection-pane-id
                                                      source-pane-id
                                                      target-pane-id
                                                      source-provider-kind
                                                      target-provider-kind
                                                      source-anchor
                                                      target-anchor
                                                      session-snapshot)
  (when transport
    (setf (transport-of evidence) transport))
  (when inspection-pane-id
    (setf (inspection-pane-id-of evidence) inspection-pane-id))
  (when source-pane-id
    (setf (source-pane-id-of evidence) source-pane-id))
  (when target-pane-id
    (setf (target-pane-id-of evidence) target-pane-id))
  (when source-provider-kind
    (setf (source-provider-kind-of evidence) source-provider-kind))
  (when target-provider-kind
    (setf (target-provider-kind-of evidence) target-provider-kind))
  (when source-anchor
    (setf (source-anchor-of evidence) source-anchor))
  (when target-anchor
    (setf (target-anchor-of evidence) target-anchor))
  (when session-snapshot
    (setf (session-snapshot-of evidence) session-snapshot))
  evidence)

(defun ensure-dom-connect-request-evidence (&key context-object
                                                 context-view-title
                                                 request-id
                                                 transport
                                                 inspection-pane-id
                                                 snapshot-json
                                                 source-json
                                                 target-json
                                                 source-pane-id
                                                 target-pane-id
                                                 source-provider-kind
                                                 target-provider-kind)
  (let* ((existing (find-dom-connect-request-evidence request-id))
         (session-snapshot
           (or (and existing (session-snapshot-of existing))
               (maybe-dom-connect-session-snapshot-from-json-string
                context-object context-view-title snapshot-json)))
         (source-anchor (or (and existing (source-anchor-of existing))
                            (maybe-dom-connect-anchor-from-json-string
                             source-json)
                            (and session-snapshot
                                 (source-anchor-of session-snapshot))))
         (target-anchor (or (and existing (target-anchor-of existing))
                            (maybe-dom-connect-anchor-from-json-string
                             target-json)
                            (and session-snapshot
                                 (target-anchor-of session-snapshot)))))
    (if existing
        (progn
          (update-dom-connect-request-evidence-payload
           existing
           :transport transport
           :inspection-pane-id inspection-pane-id
           :source-pane-id source-pane-id
           :target-pane-id target-pane-id
           :source-provider-kind source-provider-kind
           :target-provider-kind target-provider-kind
           :source-anchor source-anchor
           :target-anchor target-anchor
           :session-snapshot session-snapshot)
          (refresh-dom-connect-request-evidence existing)
          existing)
        (register-dom-connect-request-evidence
         (make-instance 'dom-connect-request-evidence
                        :id (format nil "connect-request/~A"
                                    (or request-id "unknown"))
                        :title (dom-connect-request-evidence-title request-id)
                        :summary
                        (dom-connect-request-evidence-summary
                         request-id "submitted" nil)
                        :context-object context-object
                        :context-view-title context-view-title
                        :request-id request-id
                        :transport transport
                        :inspection-pane-id inspection-pane-id
                        :source-pane-id source-pane-id
                        :target-pane-id target-pane-id
                        :source-provider-kind source-provider-kind
                        :target-provider-kind target-provider-kind
                        :source-anchor source-anchor
                        :target-anchor target-anchor
                        :session-snapshot session-snapshot
                        :submitted-at (get-universal-time)
                        :submitted-at-label
                        (or (and session-snapshot
                                 (captured-at-label-of session-snapshot))
                            "submit-boundary")
                        :updated-at (get-universal-time)
                        :updated-at-label
                        (or (and session-snapshot
                                 (captured-at-label-of session-snapshot))
                            "submit-boundary")
                        :server-status "submitted")))))

(defun record-dom-connect-request-evidence-server-status (request-id status
                                                          &key message detail
                                                            acknowledged-p)
  (let ((evidence (ensure-dom-connect-request-evidence :request-id request-id)))
    (setf (server-status-of evidence) (or status "submitted")
          (server-message-of evidence) message
          (server-detail-of evidence) detail
          (server-acknowledged-p-of evidence) acknowledged-p
          (updated-at-of evidence) (get-universal-time)
          (updated-at-label-of evidence)
          (format nil "server ~A" (or status "submitted")))
    (refresh-dom-connect-request-evidence evidence)
    (register-dom-connect-request-evidence evidence)))

(defun record-dom-connect-request-evidence-browser-failure (request-id
                                                            browser-failure-kind
                                                            &key message detail)
  (let ((evidence (ensure-dom-connect-request-evidence :request-id request-id)))
    (setf (browser-failure-kind-of evidence) browser-failure-kind
          (browser-message-of evidence) message
          (browser-detail-of evidence) detail
          (updated-at-of evidence) (get-universal-time)
          (updated-at-label-of evidence)
          (format nil "browser ~A"
                  (or (dom-connect-evidence-failure-kind-label
                       browser-failure-kind)
                      "failure")))
    (refresh-dom-connect-request-evidence evidence)
    (register-dom-connect-request-evidence evidence)))

(defun make-dom-connect-request-evidence-from-values (&key context-object
                                                           context-view-title
                                                           request-id
                                                           snapshot-json
                                                           browser-failure-kind
                                                           browser-message
                                                           browser-detail)
  (let ((evidence
          (ensure-dom-connect-request-evidence
           :context-object context-object
           :context-view-title context-view-title
           :request-id (or request-id
                           (error "Missing Connect request id."))
           :transport "connect-request-evidence-v1"
           :snapshot-json snapshot-json)))
    (when (or browser-failure-kind browser-message browser-detail)
      (record-dom-connect-request-evidence-browser-failure
       request-id
       browser-failure-kind
       :message browser-message
       :detail browser-detail))
    evidence))

(defun call-hyperdoc-runtime (symbol-name &rest arguments)
  (let ((symbol (find-symbol symbol-name :hyperdoc)))
    (when (and symbol (fboundp symbol))
      (ignore-errors
        (apply (symbol-function symbol) arguments)))))

(defun maybe-official-step-for-anchor (anchor)
  (let ((step-id (anchor-object-id-of anchor)))
    (when step-id
      (call-hyperdoc-runtime "OFFICIAL-RPI-TUTORIAL-STEP" step-id))))

(defun official-workflow-patch-target-symbol-name (source-id target-id)
  (cond
    ((and (string= source-id "official-download-prebuilt-image")
          (string= target-id "official-decompress-zstd-to-img"))
     "OFFICIAL-HYDRA-LATEST-FILENAME-HANDOFF-PATCH-TARGET")
    ((and (string= source-id "official-download-prebuilt-image")
          (string= target-id "official-flash-sd-card"))
     "OFFICIAL-ZSTD-TO-IMG-HANDOFF-PATCH-TARGET")
    ((and (string= source-id "official-boot-pi")
          (string= target-id "official-edit-configuration"))
     "OFFICIAL-HEADLESS-SSH-CONNECT-HANDOFF-PATCH-TARGET")
    (t
     nil)))

(defun matched-workflow-patch-target-info (source-anchor target-anchor)
  (let* ((source-id (anchor-object-id-of source-anchor))
         (target-id (anchor-object-id-of target-anchor))
         (patch-symbol-name (and source-id
                                 target-id
                                 (official-workflow-patch-target-symbol-name
                                  source-id
                                  target-id)))
         (patch (and patch-symbol-name
                     (call-hyperdoc-runtime patch-symbol-name))))
    (when patch
      (let ((defect (call-hyperdoc-runtime "DEFECT-OF" patch))
            (inserted-step (call-hyperdoc-runtime "INSERTED-STEP-OF" patch)))
        (list :patch-target patch
              :defect defect
              :inserted-step inserted-step
              :relation-kind "matching workflow patch target"
              :note
              (or (ignore-errors (summary-of patch))
                  (ignore-errors (summary-of defect))
                  "This DOM relation matches an already modeled workflow patch target."))))))

(defun slugify-dom-relation-fragment (value)
  (let* ((value (typecase value
                  (null "anchor")
                  (string value)
                  (t (princ-to-string value))))
         (chars (loop for ch across value
                      collect (cond
                                ((alphanumericp ch)
                                 (char-downcase ch))
                                ((member ch '(#\- #\_ #\. #\/) :test #'char=)
                                 #\-)
                                (t
                                 #\-))))
         (collapsed (coerce chars 'string)))
    (string-trim "-"
                 (with-output-to-string (stream)
                   (loop with previous-dash = nil
                         for ch across collapsed
                         do (cond
                              ((char= ch #\-)
                               (unless previous-dash
                                 (write-char ch stream))
                               (setf previous-dash t))
                              (t
                               (write-char ch stream)
                               (setf previous-dash nil))))))))

(defun dom-relation-annotation-id (source-anchor target-anchor)
  (format nil "dom-relation/~A-to-~A"
          (slugify-dom-relation-fragment
           (or (anchor-object-id-of source-anchor)
               (anchor-value-of source-anchor)
               (label-of source-anchor)))
          (slugify-dom-relation-fragment
           (or (anchor-object-id-of target-anchor)
               (anchor-value-of target-anchor)
               (label-of target-anchor)))))

(defun dom-relation-annotation-title (source-anchor target-anchor)
  (format nil "Association: ~A -> ~A"
          (or (label-of source-anchor)
              (anchor-value-of source-anchor))
          (or (label-of target-anchor)
              (anchor-value-of target-anchor))))

(defun dom-relation-annotation-summary (source-anchor target-anchor patch-target
                                         &optional context-view-title)
  (let* ((source-surface (anchor-surface-label source-anchor))
         (target-surface (anchor-surface-label target-anchor))
         (same-surface-p (string= source-surface target-surface)))
    (if patch-target
        (if same-surface-p
            (format nil "Association between ~A and ~A within ~A; this anchor pair matches an existing workflow patch target."
                    (or (label-of source-anchor)
                        (anchor-value-of source-anchor))
                    (or (label-of target-anchor)
                        (anchor-value-of target-anchor))
                    (or context-view-title source-surface "the active surface"))
            (format nil "Association between ~A in ~A and ~A in ~A; this anchor pair matches an existing workflow patch target."
                    (or (label-of source-anchor)
                        (anchor-value-of source-anchor))
                    source-surface
                    (or (label-of target-anchor)
                        (anchor-value-of target-anchor))
                    target-surface))
        (if same-surface-p
            (format nil "Association between ~A and ~A within ~A."
                    (or (label-of source-anchor)
                        (anchor-value-of source-anchor))
                    (or (label-of target-anchor)
                        (anchor-value-of target-anchor))
                    (or context-view-title source-surface "the active surface"))
            (format nil "Association between ~A in ~A and ~A in ~A."
                    (or (label-of source-anchor)
                        (anchor-value-of source-anchor))
                    source-surface
                    (or (label-of target-anchor)
                        (anchor-value-of target-anchor))
                    target-surface)))))

(defun dom-relation-annotation-durability-note (source-anchor target-anchor)
  (let ((source-note (or (durability-note-of source-anchor)
                         "Source anchor durability is unspecified."))
        (target-note (or (durability-note-of target-anchor)
                         "Target anchor durability is unspecified.")))
    (if (string= source-note target-note)
        source-note
        (format nil "Source anchor durability: ~A Target anchor durability: ~A"
                source-note
                target-note))))

(defun make-dom-relation-annotation (&key context-object
                                          context-view-title
                                          source-anchor
                                          target-anchor
                                          relation-kind
                                          note)
  (let* ((match (matched-workflow-patch-target-info source-anchor target-anchor))
         (patch-target (getf match :patch-target))
         (defect (getf match :defect))
         (inserted-step (getf match :inserted-step))
         (source-object (or (maybe-official-step-for-anchor source-anchor)
                            (and patch-target
                                 (call-hyperdoc-runtime "FROM-STEP-OF" defect))))
         (target-object (or (maybe-official-step-for-anchor target-anchor)
                            (and patch-target
                                 (call-hyperdoc-runtime "TO-STEP-OF" defect)))))
    (make-instance 'dom-relation-annotation
                   :id (dom-relation-annotation-id source-anchor target-anchor)
                   :title (dom-relation-annotation-title source-anchor target-anchor)
                   :summary (dom-relation-annotation-summary
                             source-anchor target-anchor patch-target
                             context-view-title)
                   :context-object context-object
                   :context-view-title context-view-title
                   :source-anchor source-anchor
                   :target-anchor target-anchor
                   :source-object source-object
                   :target-object target-object
                   :relation-kind (or relation-kind
                                      (getf match :relation-kind)
                                      "unclassified association")
                   :note (or note
                             (getf match :note)
                             (dom-relation-annotation-durability-note
                              source-anchor target-anchor))
                   :matching-patch-target patch-target
                   :matching-defect defect
                   :matching-inserted-step inserted-step)))

(defun make-association-annotation-from-json (&key context-object
                                                   context-view-title
                                                   source-json
                                                   target-json)
  (let* ((source-data (or (parse-dom-annotation-json source-json)
                          (error "Missing source anchor JSON.")))
         (target-data (or (parse-dom-annotation-json target-json)
                          (error "Missing target anchor JSON.")))
         (source-anchor (make-dom-annotation-anchor-from-json source-data))
         (target-anchor (make-dom-annotation-anchor-from-json target-data)))
    (make-dom-relation-annotation
     :context-object context-object
     :context-view-title context-view-title
     :source-anchor source-anchor
     :target-anchor target-anchor)))

(defun make-dom-relation-annotation-from-json (&key context-object
                                                    context-view-title
                                                    source-json
                                                    target-json)
  (make-association-annotation-from-json
   :context-object context-object
   :context-view-title context-view-title
   :source-json source-json
   :target-json target-json))
