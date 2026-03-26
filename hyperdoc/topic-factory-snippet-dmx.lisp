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
(defparameter *topic-factory-snippet-dmx-default-view-props*
  '(:x 160 :y 120 :visibility t :pinned nil))

(defstruct topic-factory-snippet-dmx-write-plan
  snippet-id
  uri
  workspace-topicmap-id
  view-props
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
  (let ((plist (or view-props *topic-factory-snippet-dmx-default-view-props*)))
    (list :x (or (getf plist :x) 160)
          :y (or (getf plist :y) 120)
          :visibility (if (null (getf plist :visibility)) t (getf plist :visibility))
          :pinned (if (null (getf plist :pinned)) nil (getf plist :pinned)))))

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

(defun topic-factory-snippet-dmx-children (definition workspace-topicmap-id)
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

(defun topic-factory-snippet-dmx-payload (definition workspace-topicmap-id
                                           &key topic-type-uri)
  (let ((uri (make-the-life-cycle-of-collective-knowledge-dmx-snippet-uri
              (snippet-id-of definition))))
    (list :uri uri
          :external-key uri
          :type-uri (or topic-type-uri
                        *dmx-topic-factory-snippet-type-uri*)
          :value (snippet-id-of definition)
          :children (topic-factory-snippet-dmx-children definition
                                                        workspace-topicmap-id))))

(defun dmx-topicmap-memberships-path (object-id)
  (format nil "/topicmaps/object/~D" object-id))

(defun dmx-topicmap-add-topic-path (topicmap-id topic-id)
  (format nil "/topicmaps/~D/topic/~D" topicmap-id topic-id))

(defun dmx-topicmap-set-topic-view-props-path (topicmap-id topic-id)
  (format nil "/topicmaps/~D/topic/~D" topicmap-id topic-id))

(defun topic-factory-snippet-view-props-json (view-props)
  (let ((hash (make-hash-table :test #'equal)))
    (setf (gethash "x" hash) (getf view-props :x)
          (gethash "y" hash) (getf view-props :y)
          (gethash "visibility" hash) (getf view-props :visibility)
          (gethash "pinned" hash) (getf view-props :pinned))
    hash))

(defun http-topic-present-in-topicmap-p (client topicmap-id topic-id)
  (let ((topicmaps (http-request-json client
                                      :get
                                      (dmx-topicmap-memberships-path topic-id))))
    (find topicmap-id
          (json-array-elements topicmaps)
          :key #'dmx-import-object-id
          :test #'eql)))

(defmethod dmx-import-topic-in-topicmap-p ((client http-dmx-import-client) topicmap-id topic-id)
  (validate-http-dmx-import-client client)
  (and topic-id
       (http-topic-present-in-topicmap-p client topicmap-id topic-id)))

(defmethod dmx-import-add-topic-to-topicmap ((client http-dmx-import-client)
                                             topicmap-id topic-id view-props)
  (validate-http-dmx-import-client client :live? t)
  (http-request-json client
                     :post
                     (dmx-topicmap-add-topic-path topicmap-id topic-id)
                     :body-object (topic-factory-snippet-view-props-json view-props)))

(defmethod dmx-import-set-topic-view-props ((client http-dmx-import-client)
                                            topicmap-id topic-id view-props)
  (validate-http-dmx-import-client client :live? t)
  (http-request-json client
                     :put
                     (dmx-topicmap-set-topic-view-props-path topicmap-id topic-id)
                     :body-object (topic-factory-snippet-view-props-json view-props)))

(defun plan-topic-factory-snippet-dmx-write
    (snippet-source
     &key workspace-topicmap-id client topic-type-uri view-props)
  (let* ((definition (normalize-topic-factory-snippet-source snippet-source))
         (resolved-topicmap-id
           (normalize-required-workspace-topicmap-id workspace-topicmap-id))
         (resolved-view-props
           (normalize-topic-factory-snippet-view-props view-props))
         (resolved-client
           (or client
               (make-default-dmx-import-client :dry-run t :verbose nil)))
         (payload (topic-factory-snippet-dmx-payload definition
                                                     resolved-topicmap-id
                                                     :topic-type-uri topic-type-uri))
         (existing-topic (dmx-import-find-existing-topic resolved-client
                                                         (getf payload :external-key)))
         (existing-topic-id (dmx-import-object-id existing-topic))
         (in-topicmap-p (and existing-topic-id
                             (dmx-import-topic-in-topicmap-p resolved-client
                                                            resolved-topicmap-id
                                                            existing-topic-id))))
    (make-topic-factory-snippet-dmx-write-plan
     :snippet-id (snippet-id-of definition)
     :uri (getf payload :uri)
     :workspace-topicmap-id resolved-topicmap-id
     :view-props resolved-view-props
     :topic-action (if existing-topic :update :create)
     :topicmap-action (if in-topicmap-p :already-present :add)
     :payload payload
     :existing-topic existing-topic
     :existing-topic-id existing-topic-id
     :source-path (source-path-of definition)
     :related-hyperdoc-page-title
     (related-hyperdoc-page-title-of definition)
     :related-topic-id (related-topic-id-of definition)
     :provenance (copy-tree (provenance-of definition)))))

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
          "TOPIC_FACTORY_SNIPPET_DMX_DETAILS related-page=~S related-topic-id=~S source=~A~%"
          (topic-factory-snippet-dmx-write-plan-related-hyperdoc-page-title plan)
          (topic-factory-snippet-dmx-write-plan-related-topic-id plan)
          (topic-factory-snippet-dmx-write-plan-source-path plan))
  (format stream
          "TOPIC_FACTORY_SNIPPET_DMX_VIEW x=~D y=~D visibility=~:[NIL~;T~] pinned=~:[NIL~;T~]~%"
          (getf (topic-factory-snippet-dmx-write-plan-view-props plan) :x)
          (getf (topic-factory-snippet-dmx-write-plan-view-props plan) :y)
          (getf (topic-factory-snippet-dmx-write-plan-view-props plan) :visibility)
          (getf (topic-factory-snippet-dmx-write-plan-view-props plan) :pinned)))

(defun execute-topic-factory-snippet-dmx-write
    (snippet-source
     &key workspace-topicmap-id client (dry-run t) topic-type-uri view-props
       (stream *standard-output*))
  (let* ((resolved-client
           (or client
               (make-default-dmx-import-client :dry-run dry-run :verbose nil)))
         (plan (plan-topic-factory-snippet-dmx-write
                snippet-source
                :workspace-topicmap-id workspace-topicmap-id
                :client resolved-client
                :topic-type-uri topic-type-uri
                :view-props view-props)))
    (when (and dry-run
               (typep resolved-client 'null-dmx-import-client))
      (format stream
              "TOPIC_FACTORY_SNIPPET_DMX note=no DMX base URL configured; dry-run assumes CREATE for unmatched snippet URIs and ADD for missing topicmap membership.~%"))
    (when (and (not dry-run)
               (typep resolved-client 'null-dmx-import-client))
      (error 'dmx-import-config-error
             :message "Live topic-factory snippet DMX write requested without a configured HTTP client"
             :missing-keys '("HYPERDOC_DMX_IMPORT_BASE_URL")))
    (render-topic-factory-snippet-dmx-plan plan :stream stream :dry-run dry-run)
    (unless dry-run
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
          :uri (topic-factory-snippet-dmx-write-plan-uri plan)
          :workspace-topicmap-id
          (topic-factory-snippet-dmx-write-plan-workspace-topicmap-id plan))))
