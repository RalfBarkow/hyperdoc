;;;; DMX writer for HyperDoc topic-factory snippets
;;
;;;; Part of HyperDoc
;;;; See LICENSE for licensing information.

(in-package :hyperdoc)

(defparameter *dmx-topic-factory-snippet-type-uri*
  "hyperdoc.topic_factory_snippet")
(defparameter *dmx-topic-factory-snippet-text-type-uri*
  "hyperdoc.topic_factory_snippet.text")
(defparameter *dmx-topic-factory-snippet-source-file-type-uri*
  "hyperdoc.topic_factory_snippet.source_file")
(defparameter *dmx-topic-factory-snippet-page-title-type-uri*
  "hyperdoc.topic_factory_snippet.related_hyperdoc_page")
(defparameter *dmx-topic-factory-snippet-topic-id-type-uri*
  "hyperdoc.topic_factory_snippet.related_topic_id")
(defparameter *dmx-topic-factory-snippet-provenance-type-uri*
  "hyperdoc.topic_factory_snippet.provenance_json")
(defparameter *dmx-topic-factory-snippet-workspace-topicmap-type-uri*
  "hyperdoc.topic_factory_snippet.workspace_topicmap_id")
(defparameter *dmx-zettelkasten-zettel-type-uri*
  "zettelkasten.zettel")
(defparameter *dmx-zettelkasten-zettel-title-type-uri*
  "zettelkasten.zettel.title")
(defparameter *dmx-zettelkasten-zettel-content-type-uri*
  "zettelkasten.zettel.content")
(defparameter *dmx-notes-note-type-uri*
  "dmx.notes.note")
(defparameter *dmx-notes-title-type-uri*
  "dmx.notes.title")
(defparameter *dmx-notes-text-type-uri*
  "dmx.notes.text")
(defparameter *topic-factory-snippet-dmx-default-view-props*
  '(:x 160 :y 120 :visibility t :pinned nil))

(defstruct topic-factory-snippet-dmx-write-plan
  snippet-id
  uri
  topic-type-uri
  topic-value
  workspace-topicmap-id
  view-props
  view-props-normalization
  topic-action
  topicmap-action
  payload
  existing-topic
  existing-topic-id
  source-path
  related-hyperdoc-page-title
  related-topic-id
  provenance)

(defmethod print-object ((plan topic-factory-snippet-dmx-write-plan) stream)
  (print-unreadable-object (plan stream :type t)
    (format stream "~A topic=~A topicmap=~A"
            (topic-factory-snippet-dmx-write-plan-snippet-id plan)
            (topic-factory-snippet-dmx-write-plan-topic-action plan)
            (topic-factory-snippet-dmx-write-plan-topicmap-action plan))))

(defun normalize-topic-factory-snippet-source (snippet-source)
  (cond
    ((null snippet-source)
     (the-life-cycle-of-collective-knowledge-topic-definition-chunk))
    ((typep snippet-source 'topic-definition-chunk)
     snippet-source)
    ((or (stringp snippet-source)
         (pathnamep snippet-source))
     (let ((namestring (namestring (pathname snippet-source)))
           (default-namestring
            (namestring
             (the-life-cycle-of-collective-knowledge-topic-asset-path))))
       (if (or (string= namestring default-namestring)
               (string= namestring
                        *the-life-cycle-of-collective-knowledge-topic-asset*))
           (the-life-cycle-of-collective-knowledge-topic-definition-chunk)
           (error "Unsupported topic-factory snippet source ~S." snippet-source))))
    (t
     (error "Unsupported topic-factory snippet source ~S." snippet-source))))

(defun normalize-required-workspace-topicmap-id (workspace-topicmap-id)
  (or (parse-positive-integer workspace-topicmap-id)
      (error 'fedwiki-dmx-import-error
             :message "Topic-factory snippet DMX write requires an explicit workspace topicmap id")))

(defun normalize-topic-factory-snippet-view-props (view-props)
  (if view-props
      (normalize-dmx-topicmap-view-props
       view-props
       :boundary 'plan-topic-factory-snippet-dmx-write)
      (values
       (make-dmx-topicmap-view-props-json-object
        :x (getf *topic-factory-snippet-dmx-default-view-props* :x)
        :y (getf *topic-factory-snippet-dmx-default-view-props* :y)
        :visibility (getf *topic-factory-snippet-dmx-default-view-props* :visibility)
        :pinned (getf *topic-factory-snippet-dmx-default-view-props* :pinned))
       (list :status :canonical
             :forbidden-short-keys nil))))

(defun plist->json-hash (plist)
  (let ((hash (make-hash-table :test #'equal)))
    (loop for (key value) on plist by #'cddr
          do (setf (gethash (string-downcase
                             (substitute #\_ #\- (string key)))
                            hash)
                   value))
    hash))

(defun topic-factory-snippet-provenance-json (definition workspace-topicmap-id)
  (encode-json-string
   (plist->json-hash
    (append (copy-list (provenance-of definition))
            (list :workspace-topicmap-id workspace-topicmap-id
                  :snippet-id (snippet-id-of definition)
                  :related-hyperdoc-page-title
                  (related-hyperdoc-page-title-of definition)
                  :related-topic-id (related-topic-id-of definition)
                  :source-file (source-path-of definition))))))

(defun zettelkasten-zettel-topic-type-uri-p (topic-type-uri)
  (string= (or topic-type-uri "")
           *dmx-zettelkasten-zettel-type-uri*))

(defun dmx-notes-note-topic-type-uri-p (topic-type-uri)
  (string= (or topic-type-uri "")
           *dmx-notes-note-type-uri*))

(defun topic-factory-snippet-dmx-title-content-carrier-spec (topic-type-uri)
  (cond
    ((zettelkasten-zettel-topic-type-uri-p topic-type-uri)
     (list :title-type-uri *dmx-zettelkasten-zettel-title-type-uri*
           :content-type-uri *dmx-zettelkasten-zettel-content-type-uri*))
    ((dmx-notes-note-topic-type-uri-p topic-type-uri)
     (list :title-type-uri *dmx-notes-title-type-uri*
           :content-type-uri *dmx-notes-text-type-uri*))))

(defun topic-factory-snippet-dmx-topic-workspace-id (client topic-id)
  (and topic-id
       (dmx-import-object-id
        (dmx-import-read-topic-workspace client topic-id))))

(defun ensure-topic-factory-snippet-dmx-workspace-assignment
    (client workspace-id topic-id)
  (when workspace-id
    (let ((current-workspace-id
           (topic-factory-snippet-dmx-topic-workspace-id client topic-id)))
      (cond
        ((eql current-workspace-id workspace-id)
         :already-assigned)
        ((and current-workspace-id
              (not (eql current-workspace-id workspace-id)))
         (error 'fedwiki-dmx-import-error
                :message
                (format nil
                        "Topic-factory snippet upsert refuses to move topic ~D from workspace ~D to workspace ~D"
                        topic-id
                        current-workspace-id
                        workspace-id)))
        (t
         (dmx-import-assign-topic-to-workspace client workspace-id topic-id)
         :assign)))))

(defun topic-factory-snippet-dmx-default-children
    (definition workspace-topicmap-id)
  (let ((children (make-hash-table :test #'equal)))
    (setf (gethash *dmx-topic-factory-snippet-text-type-uri* children)
          (snippet-text-of definition)
          (gethash *dmx-topic-factory-snippet-source-file-type-uri* children)
          (source-path-of definition)
          (gethash *dmx-topic-factory-snippet-page-title-type-uri* children)
          (related-hyperdoc-page-title-of definition)
          (gethash *dmx-topic-factory-snippet-topic-id-type-uri* children)
          (related-topic-id-of definition)
          (gethash *dmx-topic-factory-snippet-workspace-topicmap-type-uri* children)
          (write-to-string workspace-topicmap-id)
          (gethash *dmx-topic-factory-snippet-provenance-type-uri* children)
          (topic-factory-snippet-provenance-json definition workspace-topicmap-id))
    children))

(defun topic-factory-snippet-dmx-title-content-children
    (definition topic-value title-type-uri content-type-uri)
  (let ((children (make-hash-table :test #'equal)))
    (setf (gethash title-type-uri children)
          (or topic-value
              (title-of definition))
          (gethash content-type-uri children)
          (snippet-text-of definition))
    children))

(defun topic-factory-snippet-dmx-children
    (definition workspace-topicmap-id &key topic-type-uri topic-value)
  (if-let (carrier-spec
           (topic-factory-snippet-dmx-title-content-carrier-spec topic-type-uri))
      (topic-factory-snippet-dmx-title-content-children
       definition
       topic-value
       (getf carrier-spec :title-type-uri)
       (getf carrier-spec :content-type-uri))
    (topic-factory-snippet-dmx-default-children
     definition
     workspace-topicmap-id)))

(defun topic-factory-snippet-dmx-payload (definition workspace-topicmap-id
                                          &key topic-type-uri topic-value)
  (let ((uri (make-the-life-cycle-of-collective-knowledge-dmx-snippet-uri
              (snippet-id-of definition))))
    (list :uri uri
          :external-key uri
          :type-uri (or topic-type-uri
                        *dmx-topic-factory-snippet-type-uri*)
          :value (or topic-value
                     (snippet-id-of definition))
          :children (topic-factory-snippet-dmx-children
                     definition
                     workspace-topicmap-id
                     :topic-type-uri topic-type-uri
                     :topic-value topic-value))))

(defun plan-topic-factory-snippet-dmx-write
    (snippet-source
     &key workspace-topicmap-id client topic-type-uri view-props topic-value)
  (let* ((definition (normalize-topic-factory-snippet-source snippet-source))
         (resolved-topicmap-id
          (normalize-required-workspace-topicmap-id workspace-topicmap-id))
         (resolved-client
          (or client
              (make-default-dmx-import-client :dry-run t :verbose nil)))
         (payload (topic-factory-snippet-dmx-payload definition
                                                     resolved-topicmap-id
                                                     :topic-type-uri topic-type-uri
                                                     :topic-value topic-value))
         (existing-topic (dmx-import-find-existing-topic resolved-client
                                                         (getf payload :external-key)))
         (existing-topic-id (dmx-import-object-id existing-topic))
         (in-topicmap-p (and existing-topic-id
                             (dmx-import-topic-in-topicmap-p resolved-client
                                                             resolved-topicmap-id
                                                             existing-topic-id))))
    (multiple-value-bind (resolved-view-props view-props-normalization)
        (normalize-topic-factory-snippet-view-props view-props)
      (make-topic-factory-snippet-dmx-write-plan
       :snippet-id (snippet-id-of definition)
       :uri (getf payload :uri)
       :topic-type-uri (getf payload :type-uri)
       :topic-value (getf payload :value)
       :workspace-topicmap-id resolved-topicmap-id
       :view-props resolved-view-props
       :view-props-normalization view-props-normalization
       :topic-action (if existing-topic :update :create)
       :topicmap-action (if in-topicmap-p :already-present :add)
       :payload payload
       :existing-topic existing-topic
       :existing-topic-id existing-topic-id
       :source-path (source-path-of definition)
       :related-hyperdoc-page-title
       (related-hyperdoc-page-title-of definition)
       :related-topic-id (related-topic-id-of definition)
       :provenance (copy-tree (provenance-of definition))))))

(defun render-topic-factory-snippet-dmx-plan (plan
                                              &key
                                                (stream *standard-output*)
                                                dry-run)
  (format stream
          "~&TOPIC_FACTORY_SNIPPET_DMX uri=~A snippet-id=~A dry-run=~:[NIL~;T~] topic-action=~A topicmap-action=~A workspace-topicmap-id=~D~%"
          (topic-factory-snippet-dmx-write-plan-uri plan)
          (topic-factory-snippet-dmx-write-plan-snippet-id plan)
          dry-run
          (string-upcase
           (symbol-name
            (topic-factory-snippet-dmx-write-plan-topic-action plan)))
          (string-upcase
           (symbol-name
            (topic-factory-snippet-dmx-write-plan-topicmap-action plan)))
          (topic-factory-snippet-dmx-write-plan-workspace-topicmap-id plan))
  (format stream
          "TOPIC_FACTORY_SNIPPET_DMX_TOPIC value=~S~%"
          (topic-factory-snippet-dmx-write-plan-topic-value plan))
  (format stream
          "TOPIC_FACTORY_SNIPPET_DMX_TYPE uri=~S~%"
          (topic-factory-snippet-dmx-write-plan-topic-type-uri plan))
  (format stream
          "TOPIC_FACTORY_SNIPPET_DMX_DETAILS related-page=~S related-topic-id=~S source=~A~%"
          (topic-factory-snippet-dmx-write-plan-related-hyperdoc-page-title plan)
          (topic-factory-snippet-dmx-write-plan-related-topic-id plan)
          (topic-factory-snippet-dmx-write-plan-source-path plan))
  (let ((view-props (topic-factory-snippet-dmx-write-plan-view-props plan))
        (normalization
         (topic-factory-snippet-dmx-write-plan-view-props-normalization plan)))
    (format stream
            "TOPIC_FACTORY_SNIPPET_DMX_VIEW x=~D y=~D visibility=~:[NIL~;T~] pinned=~:[NIL~;T~]~%"
            (dmx-topicmap-view-props-value view-props :x)
            (dmx-topicmap-view-props-value view-props :y)
            (dmx-topicmap-view-props-value view-props :visibility)
            (dmx-topicmap-view-props-value view-props :pinned))
    (format stream
            "TOPIC_FACTORY_SNIPPET_DMX_VIEW_VALIDATION status=~A forbidden-short-keys=~S~%"
            (string-upcase
             (symbol-name
              (getf normalization :status)))
            (getf normalization :forbidden-short-keys))
    (format stream
            "TOPIC_FACTORY_SNIPPET_DMX_VIEW_PAYLOAD ~A~%"
            (dmx-topicmap-view-props-json-string view-props))))

(defun execute-topic-factory-snippet-dmx-write
    (snippet-source
     &key workspace-topicmap-id client (dry-run t) topic-type-uri view-props
       topic-value
       workspace-id
       (stream *standard-output*))
  (let* ((resolved-client
          (or client
              (make-default-dmx-import-client :dry-run dry-run :verbose nil)))
         (plan (plan-topic-factory-snippet-dmx-write
                snippet-source
                :workspace-topicmap-id workspace-topicmap-id
                :client resolved-client
                :topic-type-uri topic-type-uri
                :view-props view-props
                :topic-value topic-value)))
    (when (and dry-run
               (typep resolved-client 'null-dmx-import-client))
      (format stream
              "TOPIC_FACTORY_SNIPPET_DMX note=no DMX base URL configured; dry-run assumes CREATE for unmatched snippet URIs and ADD for missing topicmap membership.~%"))
    (when (and (not dry-run)
               (typep resolved-client 'null-dmx-import-client))
      (error 'dmx-import-config-error
             :message "Live topic-factory snippet DMX write requested without a configured HTTP client"
             :missing-keys '("HYPERDOC_DMX_IMPORT_BASE_URL")))
    (when (and (not dry-run)
               workspace-id
               (typep resolved-client 'http-dmx-import-client)
               (or (eql (topic-factory-snippet-dmx-write-plan-topic-action plan)
                        :create)
                   (null
                    (topic-factory-snippet-dmx-topic-workspace-id
                     resolved-client
                     (topic-factory-snippet-dmx-write-plan-existing-topic-id
                      plan)))))
      ;; Preflight before a live create so an auth-blocked assignment cannot
      ;; leave behind an unassigned topic that later idempotent updates cannot
      ;; modify.
      (ensure-http-dmx-import-authenticated-operation
       resolved-client
       :topic-factory-snippet-workspace-assignment))
    (render-topic-factory-snippet-dmx-plan plan :stream stream :dry-run dry-run)
    (unless dry-run
      (when (and workspace-id
                 (eql (topic-factory-snippet-dmx-write-plan-topic-action plan)
                      :update))
        (ensure-topic-factory-snippet-dmx-workspace-assignment
         resolved-client
         workspace-id
         (topic-factory-snippet-dmx-write-plan-existing-topic-id plan)))
      (ecase (topic-factory-snippet-dmx-write-plan-topic-action plan)
        (:create
         (dmx-import-create-topic resolved-client
                                  (topic-factory-snippet-dmx-write-plan-payload plan)))
        (:update
         (dmx-import-update-topic resolved-client
                                  (topic-factory-snippet-dmx-write-plan-existing-topic plan)
                                  (topic-factory-snippet-dmx-write-plan-payload plan))))
      (let* ((topic (dmx-import-find-existing-topic
                     resolved-client
                     (getf (topic-factory-snippet-dmx-write-plan-payload plan)
                           :external-key)))
             (topic-id (dmx-import-object-id topic)))
        (unless topic-id
          (error 'fedwiki-dmx-import-error
                 :message (format nil
                                  "Topic-factory snippet DMX write could not resolve a topic id for ~A after topic upsert"
                                  (topic-factory-snippet-dmx-write-plan-uri plan))))
        (when (and workspace-id
                   (eql (topic-factory-snippet-dmx-write-plan-topic-action plan)
                        :create))
          (ensure-topic-factory-snippet-dmx-workspace-assignment
           resolved-client
           workspace-id
           topic-id))
        (ecase (topic-factory-snippet-dmx-write-plan-topicmap-action plan)
          (:add
           (dmx-import-add-topic-to-topicmap
            resolved-client
            (topic-factory-snippet-dmx-write-plan-workspace-topicmap-id plan)
            topic-id
            (topic-factory-snippet-dmx-write-plan-view-props plan)))
          (:already-present
           nil))))
    (format stream
            "~&TOPIC_FACTORY_SNIPPET_DMX_SUMMARY dry-run=~:[NIL~;T~] topic-action=~A topicmap-action=~A uri=~A~%"
            dry-run
            (string-upcase
             (symbol-name
              (topic-factory-snippet-dmx-write-plan-topic-action plan)))
            (string-upcase
             (symbol-name
              (topic-factory-snippet-dmx-write-plan-topicmap-action plan)))
            (topic-factory-snippet-dmx-write-plan-uri plan))
    (list :dry-run dry-run
          :plan plan
          :topic-action
          (topic-factory-snippet-dmx-write-plan-topic-action plan)
          :topicmap-action
          (topic-factory-snippet-dmx-write-plan-topicmap-action plan)
          :view-props-validation-status
          (getf (topic-factory-snippet-dmx-write-plan-view-props-normalization plan)
                :status)
          :forbidden-short-keys
          (copy-list
           (getf (topic-factory-snippet-dmx-write-plan-view-props-normalization plan)
                 :forbidden-short-keys))
          :normalized-view-props-json
          (dmx-topicmap-view-props-json-string
           (topic-factory-snippet-dmx-write-plan-view-props plan))
          :uri (topic-factory-snippet-dmx-write-plan-uri plan)
          :workspace-topicmap-id
          (topic-factory-snippet-dmx-write-plan-workspace-topicmap-id plan))))
