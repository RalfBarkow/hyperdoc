;;;; HyperDoc-owned journal/versioning layer for shared-workspace topics
;;
;;;; Part of HyperDoc
;;;; See LICENSE for licensing information.

(in-package :hyperdoc)

(defparameter *hyperdoc-workspace-journal-uri-prefix*
  "hyperdoc:mcp/workspace-journal/")
(defparameter *dmx-workspace-journal-schema-version* 1)
(defparameter *dmx-workspace-journal-storage-model*
  "companion-workspace-note")
(defparameter *dmx-workspace-journal-backend-history-status*
  "not-proven")
(defparameter *dmx-workspace-journal-in-band-observation-kind* "in-band")
(defparameter *dmx-workspace-journal-diff-observation-kind*
  "synthesized-from-diff")
(defparameter *dmx-workspace-journal-in-band-actor* "hyperdoc-guarded-write")
(defparameter *dmx-workspace-journal-diff-actor*
  "hyperdoc-snapshot-diff-reconciler")
(defparameter *dmx-unix-epoch-universal-time-offset* 2208988800)
(defvar *dmx-workspace-journal-suppressed-p* nil)

(define-condition dmx-workspace-journal-unassigned-companion-topic-error
    (fedwiki-dmx-import-error)
  ((topic-id
    :reader dmx-workspace-journal-unassigned-companion-topic-id-of
    :initarg :topic-id)
   (journal-uri
    :reader dmx-workspace-journal-unassigned-companion-topic-uri-of
    :initarg :journal-uri
    :initform nil)
   (workspace-topicmap-id
    :reader dmx-workspace-journal-unassigned-companion-workspace-topicmap-id-of
    :initarg :workspace-topicmap-id
    :initform nil)))

(define-condition dmx-workspace-journal-companion-repair-failed-error
    (fedwiki-dmx-import-error)
  ((repair-summary
    :reader dmx-workspace-journal-companion-repair-summary-of
    :initarg :repair-summary
    :initform nil)
   (cause
    :reader dmx-workspace-journal-companion-repair-cause-of
    :initarg :cause
    :initform nil)))

(defparameter *dmx-workspace-journal-auth-config-missing-keys*
  '("HYPERDOC_DMX_IMPORT_AUTH_HEADER"
    "HYPERDOC_DMX_IMPORT_USERNAME"
    "HYPERDOC_DMX_IMPORT_PASSWORD"
    "HYPERDOC_DMX_IMPORT_AUTH_TOKEN"))

(defun dmx-workspace-journal-json-object (&rest key-values)
  (let ((json (make-hash-table :test #'equal)))
    (loop for (key value) on key-values by #'cddr
          do (setf (gethash key json) value))
    json))

(defun dmx-workspace-journal-json-array (&rest items)
  (coerce items 'vector))

(defun dmx-workspace-journal-timestamp-millis ()
  (* 1000 (- (get-universal-time) *dmx-unix-epoch-universal-time-offset*)))

(defun dmx-workspace-journal-deep-copy (value)
  (and value
       (shasht:read-json (encode-json-string value))))

(defun dmx-workspace-journal-hex-encode (string)
  (with-output-to-string (stream)
    (loop for char across (or string "")
          do (format stream "~2,'0X" (char-code char)))))

(defun dmx-workspace-journal-hidden-view-props ()
  (make-dmx-topicmap-view-props-json-object
   :x -32000
   :y -32000
   :visibility nil
   :pinned nil))

(defun dmx-workspace-journal-topic-uri (topic)
  (and topic
       (or (dmx-json-object-value topic "uri")
           (getf topic :uri)
           (getf topic :external-key))))

(defun dmx-workspace-journal-subject-key->note-key (subject-key)
  (format nil "workspace-journal-~A"
          (string-downcase
           (dmx-workspace-journal-hex-encode subject-key))))

(defun dmx-workspace-journal-note-uri (subject-key)
  (format nil "~A~A"
          *hyperdoc-workspace-journal-uri-prefix*
          (dmx-workspace-journal-subject-key->note-key subject-key)))

(defun dmx-workspace-journal-replacement-note-uri (subject-key stale-topic-id)
  (format nil "~A~A/replacement-~D-~D"
          *hyperdoc-workspace-journal-uri-prefix*
          (dmx-workspace-journal-subject-key->note-key subject-key)
          stale-topic-id
          (dmx-workspace-journal-timestamp-millis)))

(defun dmx-workspace-journal-existing-topic-workspace-summary
    (client existing-topic)
  (let ((topic-id (and existing-topic
                       (dmx-import-object-id existing-topic))))
    (cond
      ((null topic-id)
       (list :assigned-workspace-id nil
             :assigned-workspace-title nil
             :assigned-workspace-status :not-applicable))
      (t
       (let* ((workspace (dmx-import-read-topic-workspace client topic-id))
              (workspace-id (and workspace
                                 (dmx-import-object-id workspace))))
         (list :assigned-workspace-id workspace-id
               :assigned-workspace-title
               (and workspace
                    (or (dmx-json-object-value workspace "value")
                        (dmx-json-object-value workspace "uri")))
               :assigned-workspace-status
               (if workspace-id :assigned :none)))))))

(defun dmx-workspace-journal-assigned-workspace-label (summary)
  (when summary
    (let ((workspace-id (getf summary :assigned-workspace-id))
          (workspace-title (getf summary :assigned-workspace-title))
          (workspace-status (getf summary :assigned-workspace-status)))
      (cond
        (workspace-id
         (or workspace-title
             (format nil "workspace (~D)" workspace-id)))
        ((eq workspace-status :none)
         "none")
        (t
         workspace-title)))))

(defun dmx-workspace-journal-hidden-view-props-p (view-props)
  (and view-props
       (dmx-workspace-journal-json-equal-p
        view-props
        (dmx-workspace-journal-hidden-view-props))))

(defun dmx-workspace-journal-ensure-hidden-topicmap-placement
    (client workspace-topicmap-id topic-id)
  (let* ((existing-view-props
           (dmx-workspace-journal-view-props-for-topic
            client
            workspace-topicmap-id
            topic-id))
         (in-topicmap-p
           (and workspace-topicmap-id
                topic-id
                (dmx-import-topic-in-topicmap-p client
                                               workspace-topicmap-id
                                               topic-id)))
         (hidden-view-props
           (dmx-workspace-journal-hidden-view-props))
         (placement-action
           (cond
             ((not in-topicmap-p)
              (dmx-import-add-topic-to-topicmap
               client
               workspace-topicmap-id
               topic-id
               hidden-view-props)
              :add)
             ((not (dmx-workspace-journal-hidden-view-props-p
                    existing-view-props))
              (dmx-import-set-topic-view-props
               client
               workspace-topicmap-id
               topic-id
               hidden-view-props)
              :set-view-props)
             (t
              :already-hidden)))
         (resolved-view-props
           (or (dmx-workspace-journal-view-props-for-topic
                client
                workspace-topicmap-id
                topic-id)
               hidden-view-props)))
    (list :topicmap-placement-action placement-action
          :topicmap-placement-action-label
          (case placement-action
            (:add "add-hidden-topicmap-membership")
            (:set-view-props "reset-hidden-view-props")
            (otherwise "already-hidden"))
          :hidden-placement-enforced-p
          (dmx-workspace-journal-hidden-view-props-p resolved-view-props)
          :hidden-view-props-restored-p
          (dmx-workspace-journal-hidden-view-props-p resolved-view-props)
          :view-props resolved-view-props)))

(defun dmx-workspace-journal-companion-repair-base-summary
    (client existing-topic workspace-topicmap-id &key workspace-id)
  (let* ((existing-topic-id (dmx-import-object-id existing-topic))
         (journal-uri (and existing-topic
                           (or (dmx-json-object-value existing-topic "uri")
                               (getf existing-topic :uri))))
         (existing-assignment
           (dmx-workspace-journal-existing-topic-workspace-summary
            client
            existing-topic))
         (existing-in-topicmap-p
           (and existing-topic-id
                workspace-topicmap-id
                (dmx-import-topic-in-topicmap-p
                 client
                 workspace-topicmap-id
                 existing-topic-id)))
         (existing-view-props
           (and existing-topic-id
                workspace-topicmap-id
                (dmx-workspace-journal-view-props-for-topic
                 client
                 workspace-topicmap-id
                 existing-topic-id)))
         (existing-hidden-view-props-p
           (dmx-workspace-journal-hidden-view-props-p existing-view-props))
         (resolved-workspace-id
           (effective-http-dmx-import-workspace-id
            client
            :workspace-id workspace-id)))
    (list :repair-required-p t
          :repair-status :pending
          :repair-status-label "pending"
          :repair-strategy :create-replacement-and-retain-stale
          :repair-strategy-label "create-replacement-and-retain-stale"
          :repair-step :preflight
          :repair-step-label "preflight"
          :existing-topic-id existing-topic-id
          :existing-journal-uri journal-uri
          :existing-assigned-workspace-id
          (getf existing-assignment :assigned-workspace-id)
          :existing-assigned-workspace-label
          (or (dmx-workspace-journal-assigned-workspace-label
               existing-assignment)
              "none")
          :existing-assigned-workspace-status
          (getf existing-assignment :assigned-workspace-status)
          :existing-in-topicmap-p (and existing-in-topicmap-p t)
          :existing-hidden-view-props-p (and existing-hidden-view-props-p t)
          :stale-direct-update-attempted-p nil
          :stale-direct-update-skipped-p t
          :stale-delete-attempted-p nil
          :stale-delete-succeeded-p nil
          :stale-topic-retained-p nil
          :stale-topic-superseded-p nil
          :replacement-create-attempted-p nil
          :replacement-create-succeeded-p nil
          :hidden-placement-attempted-p nil
          :hidden-placement-succeeded-p nil
          :writable-workspace-context-available-p
          (and resolved-workspace-id t)
          :blocked-endpoint-path
          (and existing-topic-id
               (dmx-topic-update-path existing-topic-id))
          :requested-workspace-id resolved-workspace-id
          :replacement-topic-id nil
          :assigned-workspace-id-after nil
          :assigned-workspace-label-after nil
          :hidden-placement-enforced-p nil
          :hidden-view-props-restored-p nil
          :run-resumed-past-prepare-transition-p nil)))

(defun dmx-workspace-journal-stream-with-retained-stale-metadata
    (stream stale-topic-id replacement-uri)
  (let ((copy (dmx-workspace-journal-deep-copy stream)))
    (setf (gethash "canonicalJournalUri" copy)
          (dmx-workspace-journal-note-uri (gethash "subjectKey" stream))
          (gethash "companionUri" copy)
          replacement-uri
          (gethash "supersedesCompanionTopicId" copy)
          stale-topic-id)
    copy))

(defun dmx-workspace-journal-current-companion-candidate (candidates)
  (when candidates
    (let* ((superseded-topic-ids
             (remove nil
                     (mapcar (lambda (candidate)
                               (getf candidate :supersedes-topic-id))
                             candidates)))
           (unsuperseded
             (remove-if (lambda (candidate)
                          (member (getf candidate :topic-id)
                                  superseded-topic-ids
                                  :test #'eql))
                        candidates))
           (preferred
             (or unsuperseded candidates))
           (assigned
             (remove-if-not
              (lambda (candidate)
                (getf candidate :assigned-workspace-id))
              preferred))
           (pool (or assigned preferred)))
      (car (sort (copy-list pool) #'> :key (lambda (candidate)
                                             (or (getf candidate :topic-id)
                                                 0)))))))

(defun dmx-workspace-journal-companion-candidates-for-subject
    (client workspace-topicmap-id subject-key)
  (when (and workspace-topicmap-id
             (dmx-non-empty-string-p subject-key))
    (let* ((topicmap-json (dmx-import-read-topicmap client workspace-topicmap-id))
           (candidates '()))
      (dolist (topic (json-array-elements (gethash "topics" topicmap-json)))
        (when (dmx-workspace-journal-stream-topic-p topic)
          (let ((stream (dmx-workspace-journal-companion-stream-from-topic topic)))
            (when (and stream
                       (string= subject-key (gethash "subjectKey" stream)))
              (let* ((assignment
                       (dmx-workspace-journal-existing-topic-workspace-summary
                        client
                        topic))
                     (topic-id (dmx-import-object-id topic)))
                (push (list :topic topic
                            :stream stream
                            :topic-id topic-id
                            :topic-uri (dmx-workspace-journal-topic-uri topic)
                            :assigned-workspace-id
                            (getf assignment :assigned-workspace-id)
                            :assigned-workspace-status
                            (getf assignment :assigned-workspace-status)
                            :supersedes-topic-id
                            (gethash "supersedesCompanionTopicId" stream))
                      candidates))))))
      (values (nreverse candidates) topicmap-json))))

(defun dmx-workspace-journal-companion-stream-from-topic (topic)
  (let ((text (and topic
                   (dmx-json-child-value topic *dmx-notes-text-type-uri*))))
    (and (dmx-non-empty-string-p text)
         (shasht:read-json text))))

(defun dmx-workspace-journal-companion-repair-current-topic-id (summary)
  (cond
    ((getf summary :replacement-topic-id)
     (getf summary :replacement-topic-id))
    ((getf summary :stale-delete-succeeded-p)
     nil)
    (t
     (getf summary :existing-topic-id))))

(defun dmx-workspace-journal-missing-auth-config-error-p (condition)
  (and (typep condition 'dmx-import-config-error)
       (let ((missing (dmx-import-missing-keys-of condition)))
         (and missing
              (subsetp missing
                       *dmx-workspace-journal-auth-config-missing-keys*
                       :test #'string=)))))

(defun dmx-workspace-journal-companion-repair-result
    (summary ownership &key dry-run repairable-p repair-completed-p repair-reason
       subject-key subject-uri journal-topic-id)
  (let ((current-topic-id
          (dmx-workspace-journal-companion-repair-current-topic-id summary)))
    (append
     summary
     (list :operation :repair-workspace-journal-companion
           :dry-run dry-run
           :repairable-p (and repairable-p t)
           :repair-completed-p (and repair-completed-p t)
           :repair-reason repair-reason
           :subject-key subject-key
           :subject-uri subject-uri
           :journal-topic-id journal-topic-id
           :stale-topic-id (getf summary :existing-topic-id)
           :current-topic-id current-topic-id
           :ownership-class
           (and ownership
                (dmx-workspace-topic-ownership-class ownership))
           :hyperdoc-owned-p
           (and ownership
                (dmx-workspace-topic-ownership-owned-p ownership))
           :in-topicmap-before (getf summary :existing-in-topicmap-p)
           :in-topicmap-after
           (or (getf summary :replacement-in-topicmap-p)
               (and current-topic-id
                    (eql current-topic-id
                         (getf summary :existing-topic-id))
                    (getf summary :existing-in-topicmap-p)))
           :writable-workspace-context-used-p
           (and (getf summary :writable-workspace-context-available-p) t)))))

(defun resolve-dmx-workspace-journal-companion-repair
    (&key journal-topic-id subject-key subject-uri workspace-topicmap-id client)
  (let* ((boundary 'execute-dmx-workspace-journal-companion-repair)
         (resolved-topicmap-id
           (normalize-required-workspace-topicmap-id workspace-topicmap-id))
         (resolved-client
           (or client
               (make-default-dmx-import-client :dry-run t :verbose nil)))
         (resolved-journal-topic-id
           (and journal-topic-id
                (normalize-dmx-workspace-topic-id
                 journal-topic-id
                 :journal-topic-id
                 boundary
                 :required? t)))
         (resolved-subject-key
           (or (and subject-key
                    (normalize-dmx-workspace-topic-string
                     subject-key
                     :subject-key
                     boundary
                     :required? t))
               (and subject-uri
                    (normalize-dmx-workspace-topic-string
                     subject-uri
                     :subject-uri
                     boundary
                     :required? t))))
         (existing-topic
           (cond
             (resolved-journal-topic-id
              (dmx-import-read-topic resolved-client resolved-journal-topic-id))
             (resolved-subject-key
              (or (getf (dmx-workspace-journal-current-companion-candidate
                         (dmx-workspace-journal-companion-candidates-for-subject
                          resolved-client
                          resolved-topicmap-id
                          resolved-subject-key))
                        :topic)
                  (dmx-import-find-existing-topic
                   resolved-client
                   (dmx-workspace-journal-note-uri resolved-subject-key))))
             (t
              (error 'dmx-workspace-topic-validation-error
                     :message
                     (dmx-workspace-topic-validation-message
                      boundary
                      '(:journal-topic-id :subject-key :subject-uri)
                      nil)
                     :boundary boundary
                     :payload nil
                     :missing-fields
                     '(:journal-topic-id :subject-key :subject-uri)))))
         (ownership
           (and existing-topic
                (classify-dmx-workspace-topic-ownership existing-topic)))
         (stream
           (and existing-topic
                (eq (dmx-workspace-topic-ownership-class ownership)
                    :hyperdoc-workspace-journal)
                (dmx-workspace-journal-companion-stream-from-topic
                 existing-topic))))
    (values existing-topic
            ownership
            stream
            resolved-topicmap-id
            resolved-client
            resolved-subject-key)))

(defun execute-dmx-workspace-journal-companion-repair
    (&key journal-topic-id subject-key subject-uri workspace-topicmap-id
       workspace-id client (dry-run t))
  (multiple-value-bind (existing-topic ownership stream resolved-topicmap-id
                         resolved-client resolved-subject-key)
      (resolve-dmx-workspace-journal-companion-repair
       :journal-topic-id journal-topic-id
       :subject-key subject-key
       :subject-uri subject-uri
       :workspace-topicmap-id workspace-topicmap-id
       :client client)
    (let* ((resolved-subject-uri
             (or subject-uri
                 resolved-subject-key
                 (and stream
                      (gethash "subjectUri" stream))))
           (resolved-journal-topic-id
             (or journal-topic-id
                 (and existing-topic
                      (dmx-import-object-id existing-topic))))
           (resolved-stream
             (or stream
                 (and existing-topic
                      ownership
                      (eq (dmx-workspace-topic-ownership-class ownership)
                          :hyperdoc-workspace-journal)
                      (dmx-workspace-journal-companion-stream-from-topic
                       existing-topic))))
           (current-candidate
             (and resolved-stream
                  (dmx-workspace-journal-current-companion-candidate
                   (dmx-workspace-journal-companion-candidates-for-subject
                    resolved-client
                    resolved-topicmap-id
                    (gethash "subjectKey" resolved-stream)))))
           (already-repaired-current-topic
             (and current-candidate
                  (not (eql (getf current-candidate :topic-id)
                            (dmx-import-object-id existing-topic)))
                  (eql (getf current-candidate :supersedes-topic-id)
                       (dmx-import-object-id existing-topic))))
           (base-summary
             (and existing-topic
                  (dmx-workspace-journal-companion-repair-base-summary
                   resolved-client
                   existing-topic
                   resolved-topicmap-id
                   :workspace-id workspace-id))))
      (cond
        ((null existing-topic)
         (values
          (dmx-workspace-journal-companion-repair-result
           (list :repair-status :rejected
                 :repair-status-label "rejected"
                 :repair-step :resolve-companion
                 :repair-step-label "resolve-companion"
                 :repair-action-taken
                 "Rejected journal companion repair because no existing HyperDoc workspace-journal companion topic was found for the requested subject."
                 :existing-topic-id nil
                 :replacement-topic-id nil
                 :assigned-workspace-id-after nil
                 :hidden-placement-enforced-p nil
                 :hidden-view-props-restored-p nil
                 :stale-delete-attempted-p nil
                 :stale-delete-succeeded-p nil
                 :replacement-create-attempted-p nil
                 :replacement-create-succeeded-p nil
                 :hidden-placement-attempted-p nil
                 :hidden-placement-succeeded-p nil)
           nil
           :dry-run dry-run
           :repairable-p nil
           :repair-completed-p nil
           :repair-reason :missing-companion
           :subject-key resolved-subject-key
           :subject-uri resolved-subject-uri
           :journal-topic-id resolved-journal-topic-id)
          t))
        ((not (and ownership
                   (eq (dmx-workspace-topic-ownership-class ownership)
                       :hyperdoc-workspace-journal)))
         (values
          (dmx-workspace-journal-companion-repair-result
           (append
            (or base-summary
                (list :existing-topic-id resolved-journal-topic-id))
            (list :repair-status :rejected
                  :repair-status-label "rejected"
                  :repair-step :ownership-check
                  :repair-step-label "ownership-check"
                  :repair-action-taken
                  "Rejected journal companion repair because the requested topic is not a HyperDoc-owned workspace-journal companion."
                  :assigned-workspace-id-after nil
                  :hidden-placement-enforced-p nil
                  :hidden-view-props-restored-p nil))
           ownership
           :dry-run dry-run
           :repairable-p nil
           :repair-completed-p nil
           :repair-reason :not-hyperdoc-workspace-journal
           :subject-key resolved-subject-key
           :subject-uri resolved-subject-uri
           :journal-topic-id resolved-journal-topic-id)
          t))
        ((null resolved-stream)
         (values
          (dmx-workspace-journal-companion-repair-result
           (append
            base-summary
            (list :repair-status :rejected
                  :repair-status-label "rejected"
                  :repair-step :read-stream
                  :repair-step-label "read-stream"
                  :repair-action-taken
                  "Rejected journal companion repair because the existing journal companion does not carry a readable HyperDoc workspace-journal stream payload."))
           ownership
           :dry-run dry-run
           :repairable-p nil
           :repair-completed-p nil
           :repair-reason :missing-stream-payload
           :subject-key resolved-subject-key
           :subject-uri resolved-subject-uri
           :journal-topic-id resolved-journal-topic-id)
          t))
        ((not (eq (getf base-summary :existing-assigned-workspace-status) :none))
         (let ((not-needed-summary
                 (append
                  base-summary
                  (list :repair-status :not-needed
                        :repair-status-label "not-needed"
                        :repair-step :assignment-check
                        :repair-step-label "assignment-check"
                        :assigned-workspace-id-after
                        (getf base-summary :existing-assigned-workspace-id)
                        :assigned-workspace-label-after
                        (getf base-summary :existing-assigned-workspace-label)
                        :repair-action-taken
                        "Rejected journal companion repair because the existing companion topic is already assigned and does not need the stale/unassigned repair path."))))
           (values
            (dmx-workspace-journal-companion-repair-result
             not-needed-summary
             ownership
             :dry-run dry-run
             :repairable-p nil
             :repair-completed-p nil
             :repair-reason :already-assigned
             :subject-key (or resolved-subject-key
                              (gethash "subjectKey" resolved-stream))
             :subject-uri resolved-subject-uri
             :journal-topic-id resolved-journal-topic-id)
            t)))
        (already-repaired-current-topic
         (let* ((replacement-topic-id (getf current-candidate :topic-id))
                (replacement-assigned-workspace-id
                  (getf current-candidate :assigned-workspace-id))
                (not-needed-summary
                  (append
                   base-summary
                   (list :repair-status :not-needed
                         :repair-status-label "not-needed"
                         :repair-step :already-replaced
                         :repair-step-label "already-replaced"
                         :stale-topic-retained-p t
                         :stale-topic-superseded-p t
                         :replacement-topic-id replacement-topic-id
                         :assigned-workspace-id-after
                         replacement-assigned-workspace-id
                         :assigned-workspace-label-after
                         (and replacement-assigned-workspace-id
                              (format nil "workspace (~D)"
                                      replacement-assigned-workspace-id))
                         :repair-action-taken
                         "Rejected a second stale-companion repair because a retained-stale replacement companion already exists for this journal stream."))))
           (values
            (dmx-workspace-journal-companion-repair-result
             not-needed-summary
             ownership
             :dry-run dry-run
             :repairable-p nil
             :repair-completed-p nil
             :repair-reason :already-replaced-retained-stale
             :subject-key (or resolved-subject-key
                              (gethash "subjectKey" resolved-stream))
             :subject-uri resolved-subject-uri
             :journal-topic-id resolved-journal-topic-id)
            t)))
        ((null (getf base-summary :writable-workspace-context-available-p))
         (values
          (dmx-workspace-journal-companion-repair-result
           (append
            base-summary
            (list :repair-status :rejected
                  :repair-status-label "rejected"
                  :repair-step :resolve-workspace-context
                  :repair-step-label "resolve-workspace-context"
                  :repair-action-taken
                  "Rejected journal companion repair because no writable workspace context was available for replacement create."))
           ownership
           :dry-run dry-run
           :repairable-p nil
           :repair-completed-p nil
           :repair-reason :missing-writable-workspace-context
           :subject-key (or resolved-subject-key
                            (gethash "subjectKey" resolved-stream))
           :subject-uri resolved-subject-uri
           :journal-topic-id resolved-journal-topic-id)
          t))
        (dry-run
         (let ((planned-summary
                 (append
                  base-summary
                  (list :repair-status :planned
                        :repair-status-label "planned"
                        :repair-step :planned-create-replacement-and-retain-stale
                        :repair-step-label "planned-create-replacement-and-retain-stale"
                        :repair-action-taken
                        "Would create a replacement companion topic under the writable workspace context, retain the stale unassigned companion as history, and restore hidden/off-canvas placement on the replacement."
                        :repair-completed-p nil))))
           (values
            (dmx-workspace-journal-companion-repair-result
             planned-summary
             ownership
             :dry-run t
             :repairable-p t
             :repair-completed-p nil
             :repair-reason :stale-unassigned-companion
             :subject-key (or resolved-subject-key
                              (gethash "subjectKey" resolved-stream))
             :subject-uri resolved-subject-uri
             :journal-topic-id resolved-journal-topic-id)
            nil)))
        (t
         (handler-case
             (multiple-value-bind (_ repaired-summary)
                 (dmx-workspace-journal-repair-unassigned-companion-topic
                  resolved-client
                  resolved-stream
                  existing-topic
                  resolved-topicmap-id
                  :workspace-id workspace-id)
               (declare (ignore _))
               (values
                (dmx-workspace-journal-companion-repair-result
                 repaired-summary
                 ownership
                 :dry-run nil
                 :repairable-p t
                 :repair-completed-p
                 (eq (getf repaired-summary :repair-status) :completed)
                 :repair-reason :stale-unassigned-companion
                 :subject-key (or resolved-subject-key
                                  (gethash "subjectKey" resolved-stream))
                 :subject-uri resolved-subject-uri
                 :journal-topic-id resolved-journal-topic-id)
                nil))
           (dmx-workspace-journal-companion-repair-failed-error
               (condition)
             (let ((repair-summary
                     (dmx-workspace-journal-companion-repair-summary-of condition)))
             (values
              (dmx-workspace-journal-companion-repair-result
               repair-summary
               ownership
               :dry-run nil
               :repairable-p t
               :repair-completed-p nil
               :repair-reason
               (or (getf repair-summary :repair-reason)
                   :repair-failed)
               :subject-key (or resolved-subject-key
                                (and resolved-stream
                                     (gethash "subjectKey" resolved-stream)))
               :subject-uri resolved-subject-uri
               :journal-topic-id resolved-journal-topic-id)
              t)))))))))

(defun dmx-workspace-journal-repair-unassigned-companion-topic
    (client stream existing-topic workspace-topicmap-id &key workspace-id)
  (let* ((existing-topic-id (dmx-import-object-id existing-topic))
         (journal-uri (and existing-topic
                           (or (dmx-json-object-value existing-topic "uri")
                               (getf existing-topic :uri))))
         (resolved-workspace-id
           (effective-http-dmx-import-workspace-id
            client
            :workspace-id workspace-id))
         (repair-summary
           (dmx-workspace-journal-companion-repair-base-summary
            client
            existing-topic
            workspace-topicmap-id
            :workspace-id workspace-id))
         (existing-assignment
           (list :assigned-workspace-id
                 (getf repair-summary :existing-assigned-workspace-id)
                 :assigned-workspace-status
                 (getf repair-summary :existing-assigned-workspace-status)))
         (existing-in-topicmap-p
           (getf repair-summary :existing-in-topicmap-p))
         (existing-hidden-view-props-p
           (getf repair-summary :existing-hidden-view-props-p)))
    (flet ((remember (&rest key-values)
             (loop for (key value) on key-values by #'cddr
                   do (setf (getf repair-summary key) value))
             repair-summary))
    (unless resolved-workspace-id
      (remember :repair-status :failed
                :repair-status-label "failed"
                :repair-step :preflight
                :repair-step-label "preflight"
                :repair-action-taken
                "Could not replace the stale companion because no writable workspace id was available for the create-and-retain-stale path."
                :repair-failure-message
                "No writable workspace id was available for journal companion replacement.")
      (error 'dmx-workspace-journal-companion-repair-failed-error
             :message
             "Workspace journal companion repair requires a writable workspace id for replacement create"
             :repair-summary repair-summary
             :cause nil))
    (handler-case
        (with-http-dmx-import-request-workspace-id
            (resolved-workspace-id)
          (ensure-http-dmx-import-authenticated-operation
           client
           :repair-workspace-journal-companion)
          (let* ((replacement-uri
                   (dmx-workspace-journal-replacement-note-uri
                    (gethash "subjectKey" stream)
                    existing-topic-id))
                 (replacement-stream
                   (dmx-workspace-journal-stream-with-retained-stale-metadata
                    stream
                    existing-topic-id
                    replacement-uri))
                 (payload
                   (dmx-workspace-note-payload
                    (dmx-workspace-journal-visible-title replacement-stream)
                    (encode-json-string replacement-stream)
                    replacement-uri))
                 (repair-step-recorded
                   (remember :repair-step :create-replacement
                             :repair-step-label "create-replacement"
                             :stale-topic-retained-p t
                             :replacement-create-attempted-p t
                             :repair-action-taken
                             "Creating a fresh replacement companion topic under the intended workspace request context while retaining the stale unassigned companion as history."))
                 (replacement-topic
                   (dmx-import-create-topic client payload))
                 (replacement-topic-id
                   (dmx-import-object-id replacement-topic))
                 (assigned-workspace
                   (and replacement-topic-id
                        (dmx-import-read-topic-workspace
                         client
                         replacement-topic-id)))
                 (assigned-workspace-id
                   (and assigned-workspace
                        (dmx-import-object-id assigned-workspace)))
                 (replacement-create-recorded
                   (remember :replacement-topic-id replacement-topic-id
                             :stale-topic-superseded-p t
                             :replacement-create-succeeded-p t))
                 (assignment-action
                   (if assigned-workspace-id
                       :inherited-from-create
                       (progn
                         (remember :repair-step
                                   :assign-replacement-to-workspace
                                   :repair-step-label
                                   "assign-replacement-to-workspace"
                                   :repair-action-taken
                                   "Assigned the replacement companion topic to the intended workspace after create.")
                         (dmx-import-assign-topic-to-workspace
                          client
                          resolved-workspace-id
                          replacement-topic-id)
                         :assign-after-create)))
                 (resolved-assigned-workspace
                   (or (and (eq assignment-action :inherited-from-create)
                            assigned-workspace)
                       (dmx-import-read-topic-workspace
                        client
                        replacement-topic-id)))
                 (resolved-assigned-workspace-id
                   (and resolved-assigned-workspace
                        (dmx-import-object-id resolved-assigned-workspace)))
                 (assignment-recorded
                   (remember :assigned-workspace-id-after
                             resolved-assigned-workspace-id
                             :assigned-workspace-label-after
                             (and resolved-assigned-workspace-id
                                  (or (dmx-workspace-title-from-topic
                                       resolved-assigned-workspace)
                                      (format nil
                                              "workspace (~D)"
                                              resolved-assigned-workspace-id)))
                             :assignment-action assignment-action
                             :assignment-action-label
                             (case assignment-action
                               (:inherited-from-create
                                "workspace assignment inherited from replacement create")
                               (:assign-after-create
                                "assigned replacement topic to workspace after create")
                               (otherwise
                                "workspace assignment updated"))))
                 (hidden-placement-summary
                   (progn
                     (remember :repair-step
                               :enforce-hidden-placement
                               :repair-step-label
                               "enforce-hidden-placement"
                               :hidden-placement-attempted-p t
                               :repair-action-taken
                               "Re-applied the hidden/off-canvas topicmap placement invariant to the replacement companion topic.")
                     (dmx-workspace-journal-ensure-hidden-topicmap-placement
                      client
                      workspace-topicmap-id
                      replacement-topic-id))))
            (declare (ignore repair-step-recorded replacement-create-recorded
                             assignment-recorded))
            (unless resolved-assigned-workspace-id
              (remember :repair-step :verify-workspace-assignment
                        :repair-step-label "verify-workspace-assignment")
              (error 'fedwiki-dmx-import-error
                     :message
                     (format nil
                             "Replacement workspace journal companion topic ~D is still unassigned after the fresh-create repair path"
                             replacement-topic-id)))
            (loop for (key value) on hidden-placement-summary by #'cddr
                  do (setf (getf repair-summary key) value))
            (remember :hidden-placement-succeeded-p
                      (and (getf hidden-placement-summary
                                 :hidden-placement-enforced-p)
                           t))
            (remember :repair-status :completed
                      :repair-status-label "completed"
                      :repair-step :completed
                      :repair-step-label "completed"
                      :repair-action-taken
                      "Created a fresh replacement companion topic under the intended workspace context and retained the stale unassigned companion as history."
                      :replacement-in-topicmap-p
                      (and workspace-topicmap-id
                           (dmx-import-topic-in-topicmap-p
                            client
                            workspace-topicmap-id
                            replacement-topic-id))
                      :repaired-visible-leak-p
                      (and existing-in-topicmap-p
                           (not existing-hidden-view-props-p)
                           (getf hidden-placement-summary
                                 :hidden-view-props-restored-p)))
            (values
             replacement-topic
             repair-summary)))
      (dmx-import-config-error (condition)
        (if (dmx-workspace-journal-missing-auth-config-error-p condition)
            (remember :repair-status :blocked
                      :repair-status-label "blocked"
                      :repair-step :preflight
                      :repair-step-label "preflight"
                      :repair-reason :missing-server-side-dmx-auth-config
                      :repair-action-taken
                      "Blocked journal companion repair because the MCP server has no usable DMX write-auth configuration for the create-and-retain-stale path."
                      :repair-failure-message
                      (format nil "~A" condition))
            (remember :repair-status :failed
                      :repair-status-label "failed"
                      :repair-reason :repair-failed
                      :repair-failure-message
                      (format nil "~A" condition)))
        (error 'dmx-workspace-journal-companion-repair-failed-error
               :message
               (format nil
                       "Workspace journal companion repair failed for stale unassigned topic ~D"
                       existing-topic-id)
               :repair-summary repair-summary
               :cause condition))
      (error (condition)
        (remember :repair-status :failed
                  :repair-status-label "failed"
                  :repair-reason :repair-failed
                  :repair-failure-message
                  (format nil "~A" condition))
        (error 'dmx-workspace-journal-companion-repair-failed-error
               :message
               (format nil
                       "Workspace journal companion repair failed for stale unassigned topic ~D"
                       existing-topic-id)
               :repair-summary repair-summary
               :cause condition))))))

(defun dmx-workspace-journal-assert-existing-topic-assigned
    (client existing-topic journal-uri workspace-topicmap-id)
  (let* ((topic-id (and existing-topic
                        (dmx-import-object-id existing-topic)))
         (assignment
           (and topic-id
                (typep client 'http-dmx-import-client)
                (dmx-workspace-journal-existing-topic-workspace-summary
                 client
                 existing-topic))))
    (when (and topic-id
               (typep client 'http-dmx-import-client)
               (null (getf assignment :assigned-workspace-id)))
      (error 'dmx-workspace-journal-unassigned-companion-topic-error
             :message
             (format nil
                     "Existing workspace journal companion topic ~D is not assigned to any workspace; direct PUT /core/topic/~D will fail until the topic is assigned to a writable workspace"
                     topic-id
                     topic-id)
             :topic-id topic-id
             :journal-uri journal-uri
             :workspace-topicmap-id workspace-topicmap-id))))

(defun dmx-workspace-journal-topic-p (topic)
  (dmx-string-prefix-p *hyperdoc-workspace-journal-uri-prefix*
                       (or (dmx-json-object-value topic "uri") "")))

(defun dmx-workspace-journal-note-summary-p (summary)
  (dmx-string-prefix-p *hyperdoc-workspace-journal-uri-prefix*
                       (or (gethash "uri" summary) "")))

(defun dmx-workspace-journal-note-kind-from-uri (uri)
  (cond
    ((dmx-string-prefix-p *hyperdoc-workspace-note-uri-prefix* uri)
     "workspace-note")
    ((dmx-string-prefix-p *hyperdoc-handover-uri-prefix* uri)
     "handover")
    (t
     nil)))

(defun dmx-workspace-journal-subject-kind-from-topic (topic ownership)
  (declare (ignore topic))
  (case (dmx-workspace-topic-ownership-class ownership)
    (:hyperdoc-workspace-note "workspace-note")
    (:hyperdoc-handover "handover")
    (:hyperdoc-workspace-annotation "workspace-annotation")
    (:hyperdoc-topic-factory-snippet "workspace-topic")
    (:hyperdoc-workspace-journal "workspace-journal")
    (otherwise "workspace-topic")))

(defun dmx-workspace-journal-subject-metadata-from-topic (topic)
  (let* ((topic-id (dmx-import-object-id topic))
         (uri (or (dmx-json-object-value topic "uri") ""))
         (ownership (classify-dmx-workspace-topic-ownership topic))
         (subject-key (if (dmx-non-empty-string-p uri)
                          uri
                          (format nil "dmx:topic/~D" topic-id)))
         (lookup-kind (if (dmx-non-empty-string-p uri) "uri" "topic-id"))
         (lookup-value (if (dmx-non-empty-string-p uri)
                           uri
                           topic-id)))
    (dmx-workspace-journal-json-object
     "subjectKey" subject-key
     "subjectUri" (and (dmx-non-empty-string-p uri) uri)
     "subjectKind" (dmx-workspace-journal-subject-kind-from-topic topic ownership)
     "subjectLookup"
     (dmx-workspace-journal-json-object
      "kind" lookup-kind
      "value" lookup-value)
     "ownershipClass"
     (format nil "~(~A~)" (dmx-workspace-topic-ownership-class ownership))
     "noteKind" (dmx-workspace-journal-note-kind-from-uri uri)
     "noteKey"
     (cond
       ((dmx-string-prefix-p *hyperdoc-workspace-note-uri-prefix* uri)
        (subseq uri (length *hyperdoc-workspace-note-uri-prefix*)))
       ((dmx-string-prefix-p *hyperdoc-handover-uri-prefix* uri)
        (subseq uri (length *hyperdoc-handover-uri-prefix*)))
       (t
        nil)))))

(defun dmx-workspace-journal-topic-json-children (topic)
  (let ((children-json (make-hash-table :test #'equal))
        (children (dmx-json-object-value topic "children")))
    (when (hash-table-p children)
      (maphash (lambda (child-type-uri child)
                 (setf (gethash child-type-uri children-json)
                       (if (hash-table-p child)
                           (gethash "value" child)
                           child)))
               children))
    children-json))

(defun dmx-workspace-journal-payload-json-from-topic (topic)
  (dmx-workspace-journal-json-object
   "uri" (dmx-json-object-value topic "uri")
   "externalKey"
   (or (dmx-json-object-value topic "externalKey")
       (dmx-json-object-value topic "external-key")
       (dmx-json-object-value topic "uri"))
   "typeUri" (dmx-json-object-value topic "typeUri")
   "value" (dmx-json-object-value topic "value")
   "children" (dmx-workspace-journal-topic-json-children topic)))

(defun dmx-workspace-journal-payload-json-from-payload (payload)
  (let ((children-json (make-hash-table :test #'equal))
        (children (getf payload :children)))
    (cond
      ((hash-table-p children)
       (maphash (lambda (child-type-uri value)
                  (setf (gethash child-type-uri children-json) value))
                children))
      ((listp children)
       (loop for (child-type-uri value) on children by #'cddr
             do (setf (gethash child-type-uri children-json) value))))
    (dmx-workspace-journal-json-object
     "uri" (getf payload :uri)
     "externalKey" (or (getf payload :external-key)
                       (getf payload :uri))
     "typeUri" (getf payload :type-uri)
     "value" (getf payload :value)
     "children" children-json)))

(defun dmx-workspace-journal-payload-json->payload (payload-json)
  (let ((children (make-hash-table :test #'equal))
        (children-json (and payload-json (gethash "children" payload-json))))
    (when (hash-table-p children-json)
      (maphash (lambda (child-type-uri value)
                 (setf (gethash child-type-uri children) value))
               children-json))
    (list :uri (and payload-json (gethash "uri" payload-json))
          :external-key
          (and payload-json
               (or (gethash "externalKey" payload-json)
                   (gethash "uri" payload-json)))
          :type-uri (and payload-json (gethash "typeUri" payload-json))
          :value (and payload-json (gethash "value" payload-json))
          :children children)))

(defun dmx-workspace-journal-topic-in-topicmap-entry (topicmap-json topic-id)
  (find topic-id
        (json-array-elements (gethash "topics" topicmap-json))
        :key #'dmx-import-object-id
        :test #'eql))

(defun dmx-workspace-journal-view-props-for-topic
    (client topicmap-id topic-id &optional topicmap-json)
  (let* ((resolved-topicmap-json
           (or topicmap-json
               (and topicmap-id
                    (dmx-import-read-topicmap client topicmap-id))))
         (topic-entry
           (and resolved-topicmap-json
                topic-id
                (dmx-workspace-journal-topic-in-topicmap-entry
                 resolved-topicmap-json
                 topic-id))))
    (and topic-entry
         (gethash "viewProps" topic-entry))))

(defun dmx-workspace-journal-live-snapshot
    (client topic workspace-topicmap-id
     &key subject-meta topicmap-json in-topicmap-p view-props)
  (let* ((topic-id (dmx-import-object-id topic))
         (metadata (or subject-meta
                       (dmx-workspace-journal-subject-metadata-from-topic topic)))
         (workspace (and topic-id
                         (dmx-import-read-topic-workspace client topic-id)))
         (workspace-id (dmx-import-object-id workspace))
         (resolved-in-topicmap-p
           (if (null in-topicmap-p)
               (and workspace-topicmap-id
                    topic-id
                    (dmx-import-topic-in-topicmap-p client
                                                   workspace-topicmap-id
                                                   topic-id))
               in-topicmap-p))
         (resolved-view-props
           (cond
             (view-props
              (dmx-workspace-journal-deep-copy view-props))
             (resolved-in-topicmap-p
              (dmx-workspace-journal-deep-copy
               (dmx-workspace-journal-view-props-for-topic
                client
                workspace-topicmap-id
                topic-id
                topicmap-json)))
             (t
              nil))))
    (dmx-workspace-journal-json-object
     "subjectKey" (gethash "subjectKey" metadata)
     "subjectUri" (gethash "subjectUri" metadata)
     "subjectKind" (gethash "subjectKind" metadata)
     "subjectLookup" (dmx-workspace-journal-deep-copy
                      (gethash "subjectLookup" metadata))
     "ownershipClass" (gethash "ownershipClass" metadata)
     "noteKey" (gethash "noteKey" metadata)
     "noteKind" (gethash "noteKind" metadata)
     "topicExists" t
     "topicId" topic-id
     "topicmapId" workspace-topicmap-id
     "archived" nil
     "inTopicmap" (and resolved-in-topicmap-p t)
     "viewProps" resolved-view-props
     "workspaceId" workspace-id
     "workspaceTitle" (dmx-workspace-title-from-topic workspace)
     "payload" (dmx-workspace-journal-payload-json-from-topic topic))))

(defun dmx-workspace-journal-absent-snapshot
    (subject-key lookup-kind lookup-value workspace-topicmap-id
     &key subject-uri subject-kind ownership-class note-key note-kind)
  (dmx-workspace-journal-json-object
   "subjectKey" subject-key
   "subjectUri" subject-uri
   "subjectKind" subject-kind
   "subjectLookup"
   (dmx-workspace-journal-json-object
    "kind" lookup-kind
    "value" lookup-value)
   "ownershipClass" ownership-class
   "noteKey" note-key
   "noteKind" note-kind
   "topicExists" nil
   "topicId" nil
   "topicmapId" workspace-topicmap-id
   "archived" nil
   "inTopicmap" nil
   "viewProps" nil
   "workspaceId" nil
   "workspaceTitle" nil
   "payload" nil))

(defun dmx-workspace-journal-snapshot-from-payload
    (subject-key lookup-kind lookup-value workspace-topicmap-id payload
     &key subject-uri subject-kind ownership-class note-key note-kind
       topic-id in-topicmap view-props workspace-id workspace-title)
  (dmx-workspace-journal-json-object
   "subjectKey" subject-key
   "subjectUri" subject-uri
   "subjectKind" subject-kind
   "subjectLookup"
   (dmx-workspace-journal-json-object
    "kind" lookup-kind
    "value" lookup-value)
   "ownershipClass" ownership-class
   "noteKey" note-key
   "noteKind" note-kind
   "topicExists" t
   "topicId" topic-id
   "topicmapId" workspace-topicmap-id
   "archived" nil
   "inTopicmap" (and in-topicmap t)
   "viewProps" (dmx-workspace-journal-deep-copy view-props)
   "workspaceId" workspace-id
   "workspaceTitle" workspace-title
   "payload" (dmx-workspace-journal-deep-copy payload)))

(defun dmx-workspace-journal-stream-subject-lookup-kind (stream)
  (gethash "kind" (gethash "subjectLookup" stream)))

(defun dmx-workspace-journal-stream-subject-lookup-value (stream)
  (gethash "value" (gethash "subjectLookup" stream)))

(defun dmx-workspace-journal-make-base-stream
    (subject-key lookup-kind lookup-value workspace-topicmap-id
     &key subject-uri subject-kind ownership-class note-key note-kind)
  (dmx-workspace-journal-json-object
   "journalOwner" "hyperdoc"
   "schemaVersion" *dmx-workspace-journal-schema-version*
   "storageModel" *dmx-workspace-journal-storage-model*
   "workspaceTopicmapId" workspace-topicmap-id
   "subjectKey" subject-key
   "subjectUri" subject-uri
   "subjectKind" subject-kind
   "subjectLookup"
   (dmx-workspace-journal-json-object
    "kind" lookup-kind
    "value" lookup-value)
   "ownershipClass" ownership-class
   "noteKey" note-key
   "noteKind" note-kind
   "currentRevision" 0
   "events" #()))

(defun dmx-workspace-journal-current-snapshot (stream &key revision)
  (loop with current = nil
        for event in (json-array-elements (gethash "events" stream))
        for event-revision = (gethash "revision" event)
        when (or (null revision)
                 (<= event-revision revision))
          do (setf current
                   (dmx-workspace-journal-deep-copy
                    (gethash "nextState" event)))
        finally (return current)))

(defun dmx-workspace-journal-read-stream
    (client subject-key lookup-kind lookup-value workspace-topicmap-id
     &key subject-uri subject-kind ownership-class note-key note-kind)
  (multiple-value-bind (candidates _topicmap-json)
      (dmx-workspace-journal-companion-candidates-for-subject
       client
       workspace-topicmap-id
       subject-key)
    (declare (ignore _topicmap-json))
    (let* ((journal-uri (dmx-workspace-journal-note-uri subject-key))
           (current-candidate
             (dmx-workspace-journal-current-companion-candidate candidates))
           (existing-topic
             (or (getf current-candidate :topic)
                 (dmx-import-find-existing-topic client journal-uri)))
           (existing-text
           (and existing-topic
                (dmx-json-child-value existing-topic *dmx-notes-text-type-uri*)))
           (existing-stream
           (and (dmx-non-empty-string-p existing-text)
                (shasht:read-json existing-text))))
      (values (or existing-stream
                  (dmx-workspace-journal-make-base-stream
                   subject-key
                   lookup-kind
                   lookup-value
                   workspace-topicmap-id
                   :subject-uri subject-uri
                   :subject-kind subject-kind
                   :ownership-class ownership-class
                   :note-key note-key
                   :note-kind note-kind))
              existing-topic))))

(defun dmx-workspace-journal-visible-title (stream)
  (let ((subject-kind (or (gethash "subjectKind" stream) "workspace-topic"))
        (subject-key (or (gethash "subjectKey" stream) "unknown")))
    (format nil "Workspace journal for ~A ~A"
            subject-kind
            (if (> (length subject-key) 72)
                (subseq subject-key 0 72)
                subject-key))))

(defun dmx-workspace-journal-persist-stream
    (client stream existing-topic workspace-topicmap-id &key workspace-id)
  (let* ((*dmx-workspace-journal-suppressed-p* t)
         (subject-key (gethash "subjectKey" stream))
         (repair-summary nil)
         (repaired-existing-topic-p nil))
    (let* ((resolved-existing-topic existing-topic)
           (journal-topic
             (progn
               (when (and resolved-existing-topic
                          (typep client 'http-dmx-import-client)
                          (dmx-import-object-id resolved-existing-topic))
                 (let ((assignment
                         (dmx-workspace-journal-existing-topic-workspace-summary
                          client
                          resolved-existing-topic)))
                   (when (null (getf assignment :assigned-workspace-id))
                     (multiple-value-setq (resolved-existing-topic
                                           repair-summary)
                       (dmx-workspace-journal-repair-unassigned-companion-topic
                        client
                        stream
                        resolved-existing-topic
                        workspace-topicmap-id
                        :workspace-id workspace-id))
                     (setf repaired-existing-topic-p t))))
               (let* ((payload-uri
                        (or (dmx-workspace-journal-topic-uri
                             resolved-existing-topic)
                            (dmx-workspace-journal-note-uri subject-key)))
                      (payload
                        (dmx-workspace-note-payload
                         (dmx-workspace-journal-visible-title stream)
                         (encode-json-string stream)
                         payload-uri)))
                 (cond
                   (repaired-existing-topic-p
                   resolved-existing-topic)
                   (resolved-existing-topic
                    (dmx-import-update-topic client resolved-existing-topic payload))
                   (t
                    (dmx-import-create-topic client payload))))))
           (resolved-journal-topic-id
             (dmx-import-object-id journal-topic)))
      (unless repaired-existing-topic-p
        (dmx-workspace-journal-ensure-hidden-topicmap-placement
         client
         workspace-topicmap-id
         resolved-journal-topic-id))
      (values journal-topic repair-summary))))

(defun dmx-workspace-journal-json-equal-p (left right)
  (cond
    ((and (hash-table-p left) (hash-table-p right))
     (and (= (hash-table-count left) (hash-table-count right))
          (loop for key being the hash-keys of left using (hash-value left-value)
                always (and (nth-value 1 (gethash key right))
                            (dmx-workspace-journal-json-equal-p
                             left-value
                             (gethash key right))))))
    ((and (vectorp left) (vectorp right))
     (and (= (length left) (length right))
          (loop for index below (length left)
                always (dmx-workspace-journal-json-equal-p
                        (aref left index)
                        (aref right index)))))
    ((and (listp left) (listp right))
     (and (= (length left) (length right))
          (loop for left-item in left
                for right-item in right
                always (dmx-workspace-journal-json-equal-p
                        left-item
                        right-item))))
    (t
     (equal left right))))

(defun dmx-workspace-journal-snapshot-equivalent-p (left right)
  (and (equal (gethash "subjectKey" left)
              (gethash "subjectKey" right))
       (equal (gethash "subjectKind" left)
              (gethash "subjectKind" right))
       (equal (gethash "topicExists" left)
              (gethash "topicExists" right))
       (equal (gethash "inTopicmap" left)
              (gethash "inTopicmap" right))
       (equal (gethash "workspaceId" left)
              (gethash "workspaceId" right))
       (dmx-workspace-journal-json-equal-p (gethash "payload" left)
                                           (gethash "payload" right))
       (dmx-workspace-journal-json-equal-p (gethash "viewProps" left)
                                           (gethash "viewProps" right))))

(defun dmx-workspace-journal-topic-exists-p (snapshot)
  (and snapshot (gethash "topicExists" snapshot)))

(defun dmx-workspace-journal-note-subject-p (snapshot)
  (member (gethash "subjectKind" snapshot)
          '("workspace-note" "handover")
          :test #'string=))

(defun dmx-workspace-journal-snapshot-with-payload (base next)
  (let ((snapshot (dmx-workspace-journal-deep-copy base)))
    (setf (gethash "payload" snapshot) (dmx-workspace-journal-deep-copy
                                        (gethash "payload" next))
          (gethash "ownershipClass" snapshot) (gethash "ownershipClass" next)
          (gethash "noteKey" snapshot) (gethash "noteKey" next)
          (gethash "noteKind" snapshot) (gethash "noteKind" next)
          (gethash "workspaceTitle" snapshot) (gethash "workspaceTitle" next)
          (gethash "subjectUri" snapshot) (gethash "subjectUri" next)
          (gethash "topicExists" snapshot) t
          (gethash "topicId" snapshot) (gethash "topicId" next))
    snapshot))

(defun dmx-workspace-journal-snapshot-with-workspace (base next)
  (let ((snapshot (dmx-workspace-journal-deep-copy base)))
    (setf (gethash "workspaceId" snapshot) (gethash "workspaceId" next)
          (gethash "workspaceTitle" snapshot) (gethash "workspaceTitle" next))
    snapshot))

(defun dmx-workspace-journal-snapshot-with-membership (base next)
  (let ((snapshot (dmx-workspace-journal-deep-copy base)))
    (setf (gethash "inTopicmap" snapshot) (gethash "inTopicmap" next)
          (gethash "viewProps" snapshot)
          (dmx-workspace-journal-deep-copy (gethash "viewProps" next))
          (gethash "topicmapId" snapshot) (gethash "topicmapId" next))
    snapshot))

(defun dmx-workspace-journal-snapshot-with-archive-state
    (base archived-p)
  (let ((snapshot (dmx-workspace-journal-deep-copy base)))
    (setf (gethash "archived" snapshot) (and archived-p t))
    snapshot))

(defun dmx-workspace-journal-event
    (event-type previous-state next-state observation-kind actor-classification)
  (let ((subject (or next-state previous-state)))
    (dmx-workspace-journal-json-object
     "eventType" event-type
     "subjectKey" (gethash "subjectKey" subject)
     "subjectUri" (gethash "subjectUri" subject)
     "subjectKind" (gethash "subjectKind" subject)
     "topicId" (or (and next-state (gethash "topicId" next-state))
                   (and previous-state (gethash "topicId" previous-state)))
     "topicmapId" (or (and next-state (gethash "topicmapId" next-state))
                      (and previous-state (gethash "topicmapId" previous-state)))
     "timestamp" (dmx-workspace-journal-timestamp-millis)
     "actorClassification" actor-classification
     "observationKind" observation-kind
     "previousState" (dmx-workspace-journal-deep-copy previous-state)
     "nextState" (dmx-workspace-journal-deep-copy next-state))))

(defun dmx-workspace-journal-transition-events
    (previous-state next-state observation-kind actor-classification)
  (let* ((previous (or previous-state next-state))
         (next (or next-state previous-state))
         (previous-exists-p (dmx-workspace-journal-topic-exists-p previous))
         (next-exists-p (dmx-workspace-journal-topic-exists-p next))
         (events '()))
    (labels ((emit (event-type left right)
               (push (dmx-workspace-journal-event
                      event-type
                      left
                      right
                      observation-kind
                      actor-classification)
                     events)))
      (cond
        ((and (not previous-exists-p)
              (not next-exists-p))
         nil)
        ((and (not previous-exists-p)
              next-exists-p)
         (let ((created (dmx-workspace-journal-deep-copy next)))
           (setf (gethash "inTopicmap" created) nil
                 (gethash "viewProps" created) nil)
           (emit (if (dmx-workspace-journal-note-subject-p next)
                     "note-create"
                     "create-topic")
                 previous
                 created)
           (when (gethash "inTopicmap" next)
             (emit "add-to-topicmap" created next))))
        ((and previous-exists-p
              (not next-exists-p))
         (let ((archived
                 (dmx-workspace-journal-snapshot-with-archive-state
                  previous
                  t)))
           (emit (if (dmx-workspace-journal-note-subject-p previous)
                     "note-archive"
                     "archive-topic")
                 previous
                 archived)
           (emit (if (dmx-workspace-journal-note-subject-p previous)
                     "note-delete"
                     "delete-topic")
                 archived
                 next)))
        (t
         (let ((working (dmx-workspace-journal-deep-copy previous)))
           (unless (dmx-workspace-journal-json-equal-p
                    (gethash "payload" working)
                    (gethash "payload" next))
             (let ((payload-updated
                     (dmx-workspace-journal-snapshot-with-payload working next)))
               (emit (if (dmx-workspace-journal-note-subject-p next)
                         "note-update"
                         "update-topic")
                     working
                     payload-updated)
               (setf working payload-updated)))
           (unless (equal (gethash "workspaceId" working)
                          (gethash "workspaceId" next))
             (let ((workspace-updated
                     (dmx-workspace-journal-snapshot-with-workspace working next)))
               (emit "repair-workspace-assignment"
                     working
                     workspace-updated)
               (setf working workspace-updated)))
           (cond
             ((and (not (gethash "inTopicmap" working))
                   (gethash "inTopicmap" next))
              (let ((membership-added
                      (dmx-workspace-journal-snapshot-with-membership
                       working
                       next)))
                (emit "restore-topicmap-membership"
                      working
                      membership-added)
                (setf working membership-added)))
             ((and (gethash "inTopicmap" working)
                   (not (gethash "inTopicmap" next)))
              (let ((membership-removed
                      (dmx-workspace-journal-snapshot-with-membership
                       working
                       next)))
                (emit "remove-from-topicmap"
                      working
                      membership-removed)
                (setf working membership-removed))))
           (when (and (gethash "inTopicmap" working)
                      (gethash "inTopicmap" next)
                      (not (dmx-workspace-journal-json-equal-p
                            (gethash "viewProps" working)
                            (gethash "viewProps" next))))
             (emit "update-view-props"
                   working
                   (dmx-workspace-journal-snapshot-with-membership
                    working
                    next))))))
      (nreverse events))))

(defun dmx-workspace-journal-stream-events-list (stream)
  (json-array-elements (gethash "events" stream)))

(defun dmx-workspace-journal-apply-events-to-stream (stream events)
  (let* ((current-events (dmx-workspace-journal-stream-events-list stream))
         (next-revision (1+ (or (gethash "currentRevision" stream) 0)))
         (augmented-events
           (loop for event in events
                 for revision from next-revision
                 collect (let ((copy (dmx-workspace-journal-deep-copy event)))
                           (setf (gethash "revision" copy) revision)
                           copy))))
    (setf (gethash "events" stream)
          (coerce (append current-events augmented-events) 'vector)
          (gethash "currentRevision" stream)
          (+ (or (gethash "currentRevision" stream) 0)
             (length augmented-events)))
    stream))

(defun dmx-workspace-journal-append-events
    (client stream existing-topic workspace-topicmap-id events
     &key workspace-id)
  (let ((updated-stream
          (dmx-workspace-journal-apply-events-to-stream stream events)))
    (multiple-value-bind (_ repair-summary)
        (dmx-workspace-journal-persist-stream client
                                              updated-stream
                                              existing-topic
                                              workspace-topicmap-id
                                              :workspace-id workspace-id)
      (declare (ignore _))
      (values updated-stream repair-summary))))

(defun dmx-workspace-journal-subject-snapshot-from-stream (stream)
  (dmx-workspace-journal-absent-snapshot
   (gethash "subjectKey" stream)
   (dmx-workspace-journal-stream-subject-lookup-kind stream)
   (dmx-workspace-journal-stream-subject-lookup-value stream)
   (gethash "workspaceTopicmapId" stream)
   :subject-uri (gethash "subjectUri" stream)
   :subject-kind (gethash "subjectKind" stream)
   :ownership-class (gethash "ownershipClass" stream)
   :note-key (gethash "noteKey" stream)
   :note-kind (gethash "noteKind" stream)))

(defun dmx-workspace-journal-live-snapshot-from-stream
    (client stream &key workspace-topicmap-id topicmap-json live-snapshot)
  (cond
    (live-snapshot
     live-snapshot)
    (t
     (let* ((lookup-kind (dmx-workspace-journal-stream-subject-lookup-kind stream))
            (lookup-value (dmx-workspace-journal-stream-subject-lookup-value stream))
            (resolved-topicmap-id
              (or workspace-topicmap-id
                  (gethash "workspaceTopicmapId" stream)))
            (subject-fallback
              (dmx-workspace-journal-subject-snapshot-from-stream stream))
            (topic
              (cond
                ((string= lookup-kind "uri")
                 (dmx-import-find-existing-topic client lookup-value))
                ((and (string= lookup-kind "topic-id")
                      (integerp lookup-value))
                 (dmx-import-read-topic client lookup-value))
                (t
                 nil))))
       (if topic
           (dmx-workspace-journal-live-snapshot
            client
            topic
            resolved-topicmap-id
            :subject-meta
            (dmx-workspace-journal-subject-metadata-from-topic topic)
            :topicmap-json topicmap-json)
           subject-fallback)))))

(defun dmx-workspace-journal-reconcile-subject
    (client subject-key lookup-kind lookup-value workspace-topicmap-id
     &key subject-uri subject-kind ownership-class note-key note-kind
       live-snapshot
       workspace-id
       (persist-events-p t))
  (multiple-value-bind (stream existing-topic)
      (dmx-workspace-journal-read-stream
       client
       subject-key
       lookup-kind
       lookup-value
       workspace-topicmap-id
       :subject-uri subject-uri
       :subject-kind subject-kind
       :ownership-class ownership-class
       :note-key note-key
       :note-kind note-kind)
    (let* ((previous-state
             (or (dmx-workspace-journal-current-snapshot stream)
                 (dmx-workspace-journal-subject-snapshot-from-stream stream)))
           (current-live-state
             (dmx-workspace-journal-live-snapshot-from-stream
              client
              stream
              :workspace-topicmap-id workspace-topicmap-id
              :live-snapshot live-snapshot))
           (events
             (dmx-workspace-journal-transition-events
              previous-state
              current-live-state
              *dmx-workspace-journal-diff-observation-kind*
              *dmx-workspace-journal-diff-actor*)))
      (let ((repair-summary nil))
      (when events
        (if (or *dmx-workspace-journal-suppressed-p*
                (not persist-events-p))
            ;; Read reconciliation must stay side-effect free. Apply the
            ;; synthesized diff to the in-memory stream only.
            (dmx-workspace-journal-apply-events-to-stream stream events)
            (multiple-value-setq (stream repair-summary)
              (dmx-workspace-journal-append-events client
                                                   stream
                                                   existing-topic
                                                   workspace-topicmap-id
                                                   events
                                                   :workspace-id
                                                   workspace-id))))
      (values current-live-state
              events
              stream
              repair-summary)))))

(defun dmx-workspace-journal-transition-preview
    (previous-state next-state)
  (coerce
   (dmx-workspace-journal-transition-events
    previous-state
    next-state
    *dmx-workspace-journal-in-band-observation-kind*
    *dmx-workspace-journal-in-band-actor*)
   'vector))

(defun dmx-workspace-journal-prepare-transition
    (client subject-key lookup-kind lookup-value workspace-topicmap-id
     &key subject-uri subject-kind ownership-class note-key note-kind
       workspace-id)
  (if *dmx-workspace-journal-suppressed-p*
      (dmx-workspace-journal-absent-snapshot
       subject-key
       lookup-kind
       lookup-value
       workspace-topicmap-id
       :subject-uri subject-uri
       :subject-kind subject-kind
       :ownership-class ownership-class
       :note-key note-key
       :note-kind note-kind)
      (multiple-value-bind (current-live-state ignored-stream ignored-topic repair-summary)
          (dmx-workspace-journal-reconcile-subject
           client
           subject-key
           lookup-kind
           lookup-value
           workspace-topicmap-id
           :subject-uri subject-uri
           :subject-kind subject-kind
           :ownership-class ownership-class
           :note-key note-key
           :note-kind note-kind
           :workspace-id workspace-id)
        (declare (ignore ignored-stream ignored-topic))
        (values current-live-state repair-summary))))

(defun dmx-workspace-journal-preflight-summary
    (client subject-key lookup-kind lookup-value workspace-topicmap-id
     &key subject-uri subject-kind ownership-class note-key note-kind)
  (let* ((fallback-stream
           (dmx-workspace-journal-make-base-stream
            subject-key
            lookup-kind
            lookup-value
            workspace-topicmap-id
            :subject-uri subject-uri
            :subject-kind subject-kind
            :ownership-class ownership-class
            :note-key note-key
            :note-kind note-kind))
         (stream fallback-stream)
         (existing-topic nil)
         (lookup-condition nil)
         (assignment-summary
           (list :assigned-workspace-id nil
                 :assigned-workspace-title nil
                 :assigned-workspace-status :not-applicable))
         (assignment-lookup-condition nil))
    (handler-case
        (multiple-value-setq (stream existing-topic)
          (dmx-workspace-journal-read-stream
           client
           subject-key
           lookup-kind
           lookup-value
           workspace-topicmap-id
           :subject-uri subject-uri
           :subject-kind subject-kind
           :ownership-class ownership-class
           :note-key note-key
           :note-kind note-kind))
      (error (condition)
        (setf lookup-condition condition)))
    (when existing-topic
      (handler-case
          (setf assignment-summary
                (dmx-workspace-journal-existing-topic-workspace-summary
                 client
                 existing-topic))
        (error (condition)
          (setf assignment-lookup-condition condition
                assignment-summary
                (list :assigned-workspace-id nil
                      :assigned-workspace-title nil
                      :assigned-workspace-status :lookup-error)))))
    (let ((resolved-stream (or stream fallback-stream))
          (journal-uri (dmx-workspace-journal-note-uri subject-key)))
      (list :subject-key (gethash "subjectKey" resolved-stream)
            :subject-uri (gethash "subjectUri" resolved-stream)
            :subject-kind (gethash "subjectKind" resolved-stream)
            :subject-lookup-kind
            (dmx-workspace-journal-stream-subject-lookup-kind resolved-stream)
            :subject-lookup-value
            (dmx-workspace-journal-stream-subject-lookup-value resolved-stream)
            :ownership-class (gethash "ownershipClass" resolved-stream)
            :workspace-topicmap-id (gethash "workspaceTopicmapId" resolved-stream)
            :note-key (gethash "noteKey" resolved-stream)
            :note-kind (gethash "noteKind" resolved-stream)
            :note-uri journal-uri
            :note-title (dmx-workspace-journal-visible-title resolved-stream)
            :current-revision (gethash "currentRevision" resolved-stream)
            :existing-topic-id
            (and existing-topic
                 (dmx-import-object-id existing-topic))
            :assigned-workspace-id
            (getf assignment-summary :assigned-workspace-id)
            :assigned-workspace-title
            (getf assignment-summary :assigned-workspace-title)
            :assigned-workspace-status
            (getf assignment-summary :assigned-workspace-status)
            :assigned-workspace-lookup-condition
            (and assignment-lookup-condition
                 (format nil "~A" assignment-lookup-condition))
            :lookup-condition
            (and lookup-condition
                 (format nil "~A" lookup-condition))))))

(defun dmx-workspace-journal-record-transition
    (client previous-state next-state workspace-topicmap-id)
  (unless *dmx-workspace-journal-suppressed-p*
    (multiple-value-bind (stream existing-topic)
        (dmx-workspace-journal-read-stream
         client
         (gethash "subjectKey" next-state)
         (gethash "kind" (gethash "subjectLookup" next-state))
         (gethash "value" (gethash "subjectLookup" next-state))
         workspace-topicmap-id
         :subject-uri (gethash "subjectUri" next-state)
         :subject-kind (gethash "subjectKind" next-state)
         :ownership-class (gethash "ownershipClass" next-state)
         :note-key (gethash "noteKey" next-state)
         :note-kind (gethash "noteKind" next-state))
      (let ((events
              (dmx-workspace-journal-transition-events
               previous-state
               next-state
               *dmx-workspace-journal-in-band-observation-kind*
               *dmx-workspace-journal-in-band-actor*)))
        (when events
          (dmx-workspace-journal-append-events client
                                               stream
                                               existing-topic
                                               workspace-topicmap-id
                                               events))
        events))))

(defun dmx-workspace-journal-locate-live-subject
    (client topic-id workspace-topicmap-id)
  (let ((topic (dmx-import-read-topic client topic-id)))
    (when topic
      (let ((metadata (dmx-workspace-journal-subject-metadata-from-topic topic)))
        (values (gethash "subjectKey" metadata)
                (gethash "kind" (gethash "subjectLookup" metadata))
                (gethash "value" (gethash "subjectLookup" metadata))
                metadata
                (dmx-workspace-journal-live-snapshot
                 client
                 topic
                 workspace-topicmap-id
                 :subject-meta metadata))))))

(defun dmx-workspace-journal-stream-topic-p (topic)
  (dmx-workspace-journal-topic-p topic))

(defun dmx-workspace-journal-collect-streams (client workspace-topicmap-id)
  (let* ((topicmap-json (dmx-import-read-topicmap client workspace-topicmap-id))
         (candidates-by-subject (make-hash-table :test #'equal))
         (streams '()))
    (dolist (topic (json-array-elements (gethash "topics" topicmap-json)))
      (when (dmx-workspace-journal-stream-topic-p topic)
        (let ((stream (dmx-workspace-journal-companion-stream-from-topic topic)))
          (when stream
            (push (list :topic topic
                        :stream stream
                        :topic-id (dmx-import-object-id topic)
                        :assigned-workspace-id
                        (getf (dmx-workspace-journal-existing-topic-workspace-summary
                               client
                               topic)
                              :assigned-workspace-id)
                        :supersedes-topic-id
                        (gethash "supersedesCompanionTopicId" stream))
                  (gethash (gethash "subjectKey" stream)
                           candidates-by-subject)))))
    (maphash (lambda (_subject-key subject-candidates)
               (declare (ignore _subject-key))
               (when-let (current-candidate
                           (dmx-workspace-journal-current-companion-candidate
                            subject-candidates))
                 (push (getf current-candidate :stream) streams)))
             candidates-by-subject)
    (values (nreverse streams) topicmap-json))))

(defun dmx-workspace-journal-live-topic-snapshots (client workspace-topicmap-id topicmap-json)
  (let ((snapshots (make-hash-table :test #'equal)))
    (dolist (topic (json-array-elements (gethash "topics" topicmap-json)))
      (unless (dmx-workspace-journal-topic-p topic)
        (let* ((metadata (dmx-workspace-journal-subject-metadata-from-topic topic))
               (snapshot
                 (dmx-workspace-journal-live-snapshot
                  client
                  topic
                  workspace-topicmap-id
                  :subject-meta metadata
                  :topicmap-json topicmap-json
                  :in-topicmap-p t
                  :view-props (gethash "viewProps" topic))))
          (setf (gethash (gethash "subjectKey" snapshot) snapshots)
                snapshot))))
    snapshots))

(defun dmx-workspace-journal-reconcile-workspace
    (client workspace-topicmap-id &key (persist-events-p t))
  (multiple-value-bind (streams topicmap-json)
      (dmx-workspace-journal-collect-streams client workspace-topicmap-id)
    (let* ((live-snapshots
             (dmx-workspace-journal-live-topic-snapshots
              client
              workspace-topicmap-id
              topicmap-json))
           (stream-table (make-hash-table :test #'equal))
           (reconciled-streams '())
           (synthesized-event-count 0))
      (dolist (stream streams)
        (setf (gethash (gethash "subjectKey" stream) stream-table) stream))
      (maphash
       (lambda (subject-key snapshot)
         (unless (gethash subject-key stream-table)
           (multiple-value-bind (_ events stream)
               (dmx-workspace-journal-reconcile-subject
                client
                subject-key
                (gethash "kind" (gethash "subjectLookup" snapshot))
                (gethash "value" (gethash "subjectLookup" snapshot))
                workspace-topicmap-id
                :subject-uri (gethash "subjectUri" snapshot)
                :subject-kind (gethash "subjectKind" snapshot)
                :ownership-class (gethash "ownershipClass" snapshot)
                :note-key (gethash "noteKey" snapshot)
                :note-kind (gethash "noteKind" snapshot)
                :live-snapshot snapshot
                :persist-events-p persist-events-p)
             (declare (ignore _))
             (incf synthesized-event-count (length events))
             (setf (gethash subject-key stream-table) stream))))
       live-snapshots)
      (maphash
       (lambda (subject-key stream)
         (let ((live-snapshot (gethash subject-key live-snapshots)))
           (multiple-value-bind (_ events reconciled-stream)
               (dmx-workspace-journal-reconcile-subject
                client
                subject-key
                (dmx-workspace-journal-stream-subject-lookup-kind stream)
                (dmx-workspace-journal-stream-subject-lookup-value stream)
                workspace-topicmap-id
                :subject-uri (gethash "subjectUri" stream)
                :subject-kind (gethash "subjectKind" stream)
                :ownership-class (gethash "ownershipClass" stream)
                :note-key (gethash "noteKey" stream)
                :note-kind (gethash "noteKind" stream)
                :live-snapshot live-snapshot
                :persist-events-p persist-events-p)
             (declare (ignore _))
             (incf synthesized-event-count (length events))
             (push reconciled-stream reconciled-streams))))
       stream-table)
      (values (nreverse reconciled-streams)
              (dmx-workspace-journal-json-object
               "workspaceTopicmapId" workspace-topicmap-id
               "streamCount" (length reconciled-streams)
               "synthesizedEventCount" synthesized-event-count
               "observationKind"
               *dmx-workspace-journal-diff-observation-kind*)))))

(defun dmx-workspace-journal-backend-contract-summary ()
  (dmx-workspace-journal-json-object
   "status" *dmx-workspace-journal-backend-history-status*
   "message"
   "No authoritative DMX event stream, revision feed, or replayable topic history contract is proven in the repo-used code path; HyperDoc therefore synthesizes out-of-band history from snapshot diffs for workspace topicmap 919822."
   "observedMetadata"
   (dmx-workspace-journal-json-array
    "dmx.timestamps.created"
    "dmx.timestamps.modified")
   "provenReadContracts"
   (dmx-workspace-journal-json-array
    "/core/topic/<id>?children=true&assocChildren=true"
    "/topicmaps/<id>?children=true"
    "/core/topic/uri/<uri>?children=true&assocChildren=true")
   "unprovenHistoryContracts"
   (dmx-workspace-journal-json-array
    "workspace-wide event stream"
    "topic revision feed"
    "native delete restore"
    "native topicmap membership history")))

(defun dmx-workspace-journal-stream-summary (stream)
  (let* ((events (dmx-workspace-journal-stream-events-list stream))
         (current (or (dmx-workspace-journal-current-snapshot stream)
                      (dmx-workspace-journal-subject-snapshot-from-stream stream))))
    (dmx-workspace-journal-json-object
     "subjectKey" (gethash "subjectKey" stream)
     "subjectUri" (gethash "subjectUri" stream)
     "subjectKind" (gethash "subjectKind" stream)
     "ownershipClass" (gethash "ownershipClass" stream)
     "noteKey" (gethash "noteKey" stream)
     "noteKind" (gethash "noteKind" stream)
     "currentRevision" (gethash "currentRevision" stream)
     "eventCount" (length events)
     "topicExists" (gethash "topicExists" current)
     "topicId" (gethash "topicId" current)
     "inTopicmap" (gethash "inTopicmap" current)
     "workspaceId" (gethash "workspaceId" current)
     "lastEventType" (and events (gethash "eventType" (car (last events))))
     "lastObservationKind"
     (and events (gethash "observationKind" (car (last events)))))))

(defun read-dmx-workspace-journal
    (&key workspace-topicmap-id client (reconcile t))
  (let* ((resolved-topicmap-id
           (normalize-required-workspace-topicmap-id workspace-topicmap-id))
         (resolved-client
           (or client
               (make-default-dmx-import-client :dry-run t :verbose nil))))
    (multiple-value-bind (streams reconciliation)
        (if reconcile
            (dmx-workspace-journal-reconcile-workspace
             resolved-client
             resolved-topicmap-id
             :persist-events-p nil)
            (multiple-value-bind (loaded-streams _)
                (dmx-workspace-journal-collect-streams
                 resolved-client
                 resolved-topicmap-id)
              (declare (ignore _))
              (values loaded-streams
                      (dmx-workspace-journal-json-object
                       "workspaceTopicmapId" resolved-topicmap-id
                       "streamCount" (length loaded-streams)
                       "synthesizedEventCount" 0
                       "observationKind" "none"))))
      (dmx-workspace-journal-json-object
       "workspaceTopicmapId" resolved-topicmap-id
       "storageModel" *dmx-workspace-journal-storage-model*
       "schemaVersion" *dmx-workspace-journal-schema-version*
       "backendHistoryContract" (dmx-workspace-journal-backend-contract-summary)
       "streamCount" (length streams)
       "eventCount"
       (reduce #'+
               (mapcar (lambda (stream)
                         (length (dmx-workspace-journal-stream-events-list stream)))
                       streams)
               :initial-value 0)
       "reconciliation" reconciliation
       "streams"
       (coerce (mapcar #'dmx-workspace-journal-stream-summary streams)
               'vector)))))

(defun dmx-workspace-journal-revision-summaries (stream)
  (coerce
   (mapcar (lambda (event)
             (let ((next (gethash "nextState" event)))
               (dmx-workspace-journal-json-object
                "revision" (gethash "revision" event)
                "eventType" (gethash "eventType" event)
                "timestamp" (gethash "timestamp" event)
                "observationKind" (gethash "observationKind" event)
                "topicId" (gethash "topicId" event)
                "topicExists" (and next (gethash "topicExists" next))
                "archived" (and next (gethash "archived" next))
                "inTopicmap" (and next (gethash "inTopicmap" next)))))
           (dmx-workspace-journal-stream-events-list stream))
   'vector))

(defun dmx-workspace-journal-find-stream-by-subject-key
    (streams subject-key)
  (find subject-key streams :test #'string=
        :key (lambda (stream) (gethash "subjectKey" stream))))

(defun dmx-workspace-journal-find-stream-by-topic-id (streams topic-id)
  (find topic-id
        streams
        :test #'eql
        :key (lambda (stream)
               (let ((current (dmx-workspace-journal-current-snapshot stream)))
                 (and current
                      (gethash "topicId" current))))))

(defun dmx-workspace-journal-locate-stream
    (client workspace-topicmap-id
     &key subject-key topic-id note-key note-kind reconcile)
  (let* ((resolved-client
           (or client
               (make-default-dmx-import-client :dry-run t :verbose nil)))
         (resolved-topicmap-id
           (normalize-required-workspace-topicmap-id workspace-topicmap-id))
         (resolved-subject-key
           (cond
             (subject-key
              subject-key)
             (note-key
              (dmx-workspace-note-uri
               (normalize-dmx-workspace-note-kind-designator
                note-kind
                'dmx-workspace-journal-locate-stream)
               note-key))
             (t
              nil))))
    (multiple-value-bind (streams _)
        (if reconcile
            (dmx-workspace-journal-reconcile-workspace
             resolved-client
             resolved-topicmap-id
             :persist-events-p nil)
            (dmx-workspace-journal-collect-streams
             resolved-client
             resolved-topicmap-id))
      (declare (ignore _))
      (or (and resolved-subject-key
               (dmx-workspace-journal-find-stream-by-subject-key
                streams
                resolved-subject-key))
          (and topic-id
               (dmx-workspace-journal-find-stream-by-topic-id
                streams
                topic-id))))))

(defun read-dmx-topic-journal
    (&key workspace-topicmap-id client subject-key topic-id note-key note-kind
       (reconcile t))
  (let ((stream (dmx-workspace-journal-locate-stream
                 client
                 workspace-topicmap-id
                 :subject-key subject-key
                 :topic-id topic-id
                 :note-key note-key
                 :note-kind note-kind
                 :reconcile reconcile)))
    (unless stream
      (error 'fedwiki-dmx-import-error
             :message "No workspace journal stream matched the requested subject"))
    (let ((current (or (dmx-workspace-journal-current-snapshot stream)
                       (dmx-workspace-journal-subject-snapshot-from-stream
                        stream))))
      (dmx-workspace-journal-json-object
       "subjectKey" (gethash "subjectKey" stream)
       "subjectUri" (gethash "subjectUri" stream)
       "subjectKind" (gethash "subjectKind" stream)
       "ownershipClass" (gethash "ownershipClass" stream)
       "currentRevision" (gethash "currentRevision" stream)
       "currentState" current
       "revisions" (dmx-workspace-journal-revision-summaries stream)
       "events" (coerce (dmx-workspace-journal-stream-events-list stream) 'vector)))))

(defun list-dmx-workspace-topic-revisions
    (&key workspace-topicmap-id client subject-key topic-id note-key note-kind
       (reconcile t))
  (let ((stream (dmx-workspace-journal-locate-stream
                 client
                 workspace-topicmap-id
                 :subject-key subject-key
                 :topic-id topic-id
                 :note-key note-key
                 :note-kind note-kind
                 :reconcile reconcile)))
    (unless stream
      (error 'fedwiki-dmx-import-error
             :message "No workspace journal stream matched the requested subject"))
    (dmx-workspace-journal-json-object
     "subjectKey" (gethash "subjectKey" stream)
     "subjectKind" (gethash "subjectKind" stream)
     "currentRevision" (gethash "currentRevision" stream)
     "revisions" (dmx-workspace-journal-revision-summaries stream))))

(defun dmx-workspace-journal-owned-subject-p (snapshot)
  (member (gethash "ownershipClass" snapshot)
          '("hyperdoc-workspace-note"
            "hyperdoc-handover"
            "hyperdoc-workspace-annotation"
            "hyperdoc-topic-factory-snippet")
          :test #'string=))

(defun dmx-workspace-journal-latest-restorable-revision (stream)
  (loop for revision in (reverse (coerce (dmx-workspace-journal-revision-summaries stream)
                                         'list))
        when (gethash "topicExists" revision)
          return (gethash "revision" revision)))

(defun dmx-workspace-journal-restore-event-list
    (previous-state next-state)
  (let ((events '()))
    (when (or (not (dmx-workspace-journal-topic-exists-p previous-state))
              (not (dmx-workspace-journal-json-equal-p
                    (gethash "payload" previous-state)
                    (gethash "payload" next-state)))
              (not (equal (gethash "workspaceId" previous-state)
                          (gethash "workspaceId" next-state))))
      (push (dmx-workspace-journal-event
             "restore-topic"
             previous-state
             (let ((snapshot (dmx-workspace-journal-deep-copy next-state)))
               (setf (gethash "inTopicmap" snapshot)
                     (gethash "inTopicmap" previous-state)
                     (gethash "viewProps" snapshot)
                     (dmx-workspace-journal-deep-copy
                      (gethash "viewProps" previous-state)))
               snapshot)
             *dmx-workspace-journal-in-band-observation-kind*
             *dmx-workspace-journal-in-band-actor*)
            events))
    (when (and (not (gethash "inTopicmap" previous-state))
               (gethash "inTopicmap" next-state))
      (push (dmx-workspace-journal-event
             "restore-topicmap-membership"
             previous-state
             next-state
             *dmx-workspace-journal-in-band-observation-kind*
             *dmx-workspace-journal-in-band-actor*)
            events))
    (nreverse events)))

(defun dmx-workspace-journal-restore-summary
    (stream revision target-state current-state status actions
     &key validation-state repair-candidate)
  (dmx-workspace-journal-json-object
   "status" status
   "subjectKey" (gethash "subjectKey" stream)
   "subjectKind" (gethash "subjectKind" stream)
   "ownershipClass" (gethash "ownershipClass" stream)
   "revision" revision
   "actions" (coerce actions 'vector)
   "targetState" target-state
   "currentState" current-state
   "validationState" validation-state
   "repairCandidate" repair-candidate))

(defun restore-dmx-workspace-topic-revision
    (&key workspace-topicmap-id client subject-key topic-id revision dry-run)
  (let* ((resolved-client
           (or client
               (make-default-dmx-import-client :dry-run dry-run :verbose nil)))
         (stream (dmx-workspace-journal-locate-stream
                  resolved-client
                  workspace-topicmap-id
                  :subject-key subject-key
                  :topic-id topic-id
                  :reconcile t)))
    (unless stream
      (error 'fedwiki-dmx-import-error
             :message "No workspace journal stream matched the requested topic"))
    (let* ((resolved-revision
             (or (and revision
                      (parse-positive-integer revision))
                 (dmx-workspace-journal-latest-restorable-revision stream)
                 (error 'fedwiki-dmx-import-error
                        :message "No restorable revision exists for the requested topic")))
           (target-state
             (dmx-workspace-journal-current-snapshot
              stream
              :revision resolved-revision))
           (workspace-topicmap-id*
             (or workspace-topicmap-id
                 (gethash "workspaceTopicmapId" stream)))
           (current-state
             (dmx-workspace-journal-live-snapshot-from-stream
              resolved-client
              stream
              :workspace-topicmap-id workspace-topicmap-id*))
           (actions '()))
      (unless (and target-state
                   (gethash "topicExists" target-state))
        (error 'fedwiki-dmx-import-error
               :message "Requested revision does not reconstruct a restorable topic state"))
      (unless (or (dmx-workspace-journal-owned-subject-p target-state)
                  (gethash "topicExists" current-state))
        (return-from restore-dmx-workspace-topic-revision
          (dmx-workspace-journal-restore-summary
           stream
           resolved-revision
           target-state
           current-state
           "repair_candidate"
           actions
           :repair-candidate
           (dmx-workspace-journal-json-object
            "reason"
            "Foreign or non-owned topic is absent; HyperDoc will not hard-recreate it blindly."
            "subjectKey" (gethash "subjectKey" stream)
            "targetRevision" resolved-revision))))
      (when dry-run
        (unless (dmx-workspace-journal-topic-exists-p current-state)
          (push "create-topic" actions))
        (when (and (dmx-workspace-journal-topic-exists-p current-state)
                   (dmx-workspace-journal-owned-subject-p target-state)
                   (not (dmx-workspace-journal-json-equal-p
                         (gethash "payload" current-state)
                         (gethash "payload" target-state))))
          (push "update-topic" actions))
        (when (and (dmx-workspace-journal-owned-subject-p target-state)
                   (not (equal (gethash "workspaceId" current-state)
                               (gethash "workspaceId" target-state)))
                   (gethash "workspaceId" target-state))
          (push "repair-workspace-assignment" actions))
        (when (and (not (gethash "inTopicmap" current-state))
                   (gethash "inTopicmap" target-state))
          (push "restore-topicmap-membership" actions))
        (return-from restore-dmx-workspace-topic-revision
          (dmx-workspace-journal-restore-summary
           stream
           resolved-revision
           target-state
           current-state
           "dry_run"
           (nreverse actions))))
      (let ((before-state current-state)
            (topic current-state))
        (when (not (dmx-workspace-journal-topic-exists-p current-state))
          (let ((created
                  (dmx-import-create-topic
                   resolved-client
                   (dmx-workspace-journal-payload-json->payload
                    (gethash "payload" target-state)))))
            (setf topic
                  (dmx-workspace-journal-live-snapshot
                   resolved-client
                   created
                   workspace-topicmap-id*))
            (push "create-topic" actions)))
        (when (and (dmx-workspace-journal-owned-subject-p target-state)
                   (dmx-workspace-journal-topic-exists-p topic)
                   (not (dmx-workspace-journal-json-equal-p
                         (gethash "payload" topic)
                         (gethash "payload" target-state))))
          (let* ((existing-topic
                   (dmx-import-read-topic resolved-client
                                          (gethash "topicId" topic)))
                 (updated
                   (dmx-import-update-topic
                    resolved-client
                    existing-topic
                    (dmx-workspace-journal-payload-json->payload
                     (gethash "payload" target-state)))))
            (setf topic
                  (dmx-workspace-journal-live-snapshot
                   resolved-client
                   updated
                   workspace-topicmap-id*))
            (push "update-topic" actions)))
        (when (and (dmx-workspace-journal-owned-subject-p target-state)
                   (gethash "workspaceId" target-state)
                   (not (equal (gethash "workspaceId" topic)
                               (gethash "workspaceId" target-state))))
          (dmx-import-assign-topic-to-workspace
           resolved-client
           (gethash "workspaceId" target-state)
           (gethash "topicId" topic))
          (setf topic
                (dmx-workspace-journal-live-snapshot-from-stream
                 resolved-client
                 stream
                 :workspace-topicmap-id workspace-topicmap-id*))
          (push "repair-workspace-assignment" actions))
        (when (and (gethash "inTopicmap" target-state)
                   (not (gethash "inTopicmap" topic)))
          (dmx-import-add-topic-to-topicmap
           resolved-client
           workspace-topicmap-id*
           (gethash "topicId" topic)
           (or (gethash "viewProps" target-state)
               (dmx-workspace-journal-hidden-view-props)))
          (setf topic
                (dmx-workspace-journal-live-snapshot-from-stream
                 resolved-client
                 stream
                 :workspace-topicmap-id workspace-topicmap-id*))
          (push "restore-topicmap-membership" actions))
        (let ((after-state
                (dmx-workspace-journal-live-snapshot-from-stream
                 resolved-client
                 stream
                 :workspace-topicmap-id workspace-topicmap-id*)))
          (unless (dmx-workspace-journal-snapshot-equivalent-p
                   target-state
                   after-state)
            (return-from restore-dmx-workspace-topic-revision
              (dmx-workspace-journal-restore-summary
               stream
               resolved-revision
               target-state
               before-state
               "validation_failed"
               (nreverse actions)
               :validation-state after-state)))
          (unless *dmx-workspace-journal-suppressed-p*
            (multiple-value-bind (stream* existing-topic)
                (dmx-workspace-journal-read-stream
                 resolved-client
                 (gethash "subjectKey" stream)
                 (dmx-workspace-journal-stream-subject-lookup-kind stream)
                 (dmx-workspace-journal-stream-subject-lookup-value stream)
                 workspace-topicmap-id*
                 :subject-uri (gethash "subjectUri" stream)
                 :subject-kind (gethash "subjectKind" stream)
                 :ownership-class (gethash "ownershipClass" stream)
                 :note-key (gethash "noteKey" stream)
                 :note-kind (gethash "noteKind" stream))
              (dmx-workspace-journal-append-events
               resolved-client
               stream*
               existing-topic
               workspace-topicmap-id*
               (dmx-workspace-journal-restore-event-list
                before-state
                after-state))))
          (dmx-workspace-journal-restore-summary
           stream
           resolved-revision
           target-state
           before-state
           "restored"
           (nreverse actions)
           :validation-state after-state))))))

(defun restore-dmx-workspace-note-revision
    (&key workspace-topicmap-id client subject-key topic-id note-key note-kind
       revision dry-run)
  (restore-dmx-workspace-topic-revision
   :workspace-topicmap-id workspace-topicmap-id
   :client client
   :subject-key (or subject-key
                    (and note-key
                         (dmx-workspace-note-uri
                          (normalize-dmx-workspace-note-kind-designator
                           note-kind
                           'restore-dmx-workspace-note-revision)
                          note-key)))
   :topic-id topic-id
   :revision revision
   :dry-run dry-run))
