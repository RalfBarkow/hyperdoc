;;;; Generic DMX topic query layer
;;
;;;; This layer models read-only logical DMX topic queries independently of the
;;;; backend that answers them.  Backend-specific code lives in adjacent adapter
;;;; files; sync remains a dry-run comparison.

(in-package :hyperdoc)

(%defgeneric-unless-present description-of (object))

(defgeneric dmx-run-query (target query &key limit offset include-raw-p)
  (:documentation "Run logical QUERY against TARGET and return a DMX-QUERY-RUN."))

(defgeneric dmx-list-unassigned-topics
    (target &key limit offset type-uri uri-prefix topicmap-id ownership-class
              include-raw-p)
  (:documentation "Return a DMX-QUERY-RUN for topics without workspace assignment."))

(defgeneric dmx-store-topic-row (target raw-row)
  (:documentation "Normalize RAW-ROW from TARGET into a DMX-TOPIC-ROW."))

(defgeneric dmx-persist-query-run (sqlite-store query-run)
  (:documentation "Persist QUERY-RUN evidence into SQLITE-STORE."))

(defgeneric dmx-load-query-runs
    (sqlite-store &key query-id source-target-id limit)
  (:documentation "Load recent query run rows from SQLITE-STORE."))

(defgeneric dmx-compare-topic-stores
    (source-target target-target query &key identity-key)
  (:documentation "Compare QUERY results from two targets without mutating either."))

(defgeneric dmx-plan-topic-sync
    (source-target target-target &key query identity-key)
  (:documentation "Build a read-only DMX-SYNC-PLAN for SOURCE-TARGET and TARGET-TARGET."))

(defgeneric dmx-materialize-query-as-topic
    (sqlite-store query-run &key topic-title topic-uri)
  (:documentation "Create an inspectable dry-run topic materialization payload."))

(defparameter +dmx-query-hyperdoc-workspace-annotation-uri-prefix+
  "hyperdoc:mcp/workspace-annotation/")

(defclass dmx-store-target ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (kind :reader kind-of :initarg :kind)
   (description :reader description-of :initarg :description :initform "")))

(defclass dmx-neo4j-store-target (dmx-store-target)
  ((app-root :reader dmx-neo4j-store-target-app-root-of
             :initarg :app-root)
   (store-path :reader dmx-neo4j-store-target-store-path-of
               :initarg :store-path)
   (java-home :reader dmx-neo4j-store-target-java-home-of
              :initarg :java-home
              :initform nil)
   (helper-source-path :reader dmx-neo4j-store-target-helper-source-path-of
                       :initarg :helper-source-path)
   (helper-build-root :reader dmx-neo4j-store-target-helper-build-root-of
                      :initarg :helper-build-root)
   (helper-classpath-entries
    :reader dmx-neo4j-store-target-helper-classpath-entries-of
    :initarg :helper-classpath-entries
    :initform nil)))

(defclass dmx-http-store-target (dmx-store-target)
  ((base-url :reader dmx-http-store-target-base-url-of
             :initarg :base-url)
   (username :reader dmx-http-store-target-username-of
             :initarg :username
             :initform nil)
   (credential-mode :reader dmx-http-store-target-credential-mode-of
                    :initarg :credential-mode
                    :initform :anonymous)
   (default-topicmap-id :reader dmx-http-store-target-default-topicmap-id-of
                        :initarg :default-topicmap-id
                        :initform nil)
   (default-workspace-id :reader dmx-http-store-target-default-workspace-id-of
                         :initarg :default-workspace-id
                         :initform nil)))

(defclass dmx-sqlite-query-store (dmx-store-target)
  ((db-path :reader dmx-sqlite-query-store-db-path-of
            :initarg :db-path)
   (sqlite-program :reader dmx-sqlite-query-store-sqlite-program-of
                   :initarg :sqlite-program
                   :initform "sqlite3")))

(defclass dmx-memory-store-target (dmx-store-target)
  ((raw-rows :reader dmx-memory-store-target-raw-rows-of
             :initarg :raw-rows
             :initform nil)
   (capability-status :reader dmx-memory-store-target-capability-status-of
                      :initarg :capability-status
                      :initform :ok)))

(defclass dmx-topic-row ()
  ((store-id :reader dmx-topic-row-store-id-of :initarg :store-id)
   (backend-kind :reader dmx-topic-row-backend-kind-of :initarg :backend-kind)
   (topic-id :reader dmx-topic-row-topic-id-of :initarg :topic-id :initform nil)
   (uri :reader dmx-topic-row-uri-of :initarg :uri :initform nil)
   (type-uri :reader dmx-topic-row-type-uri-of :initarg :type-uri :initform nil)
   (value :reader dmx-topic-row-value-of :initarg :value :initform nil)
   (workspace-id :reader dmx-topic-row-workspace-id-of
                 :initarg :workspace-id
                 :initform nil)
   (workspace-status :reader dmx-topic-row-workspace-status-of
                     :initarg :workspace-status)
   (topicmap-ids :reader dmx-topic-row-topicmap-ids-of
                 :initarg :topicmap-ids
                 :initform nil)
   (ownership-class :reader dmx-topic-row-ownership-class-of
                    :initarg :ownership-class
                    :initform :foreign-or-unsupported)
   (raw-source :reader dmx-topic-row-raw-source-of
               :initarg :raw-source
               :initform nil)
   (evidence-path :reader dmx-topic-row-evidence-path-of
                  :initarg :evidence-path
                  :initform nil)))

(defclass dmx-query ()
  ((id :reader id-of :initarg :id)
   (title :reader title-of :initarg :title)
   (query-kind :reader dmx-query-kind-of :initarg :query-kind)
   (parameters :reader dmx-query-parameters-of :initarg :parameters :initform nil)
   (created-at :reader dmx-query-created-at-of :initarg :created-at)))

(defclass dmx-query-run ()
  ((id :reader id-of :initarg :id)
   (query :reader dmx-query-run-query-of :initarg :query)
   (source-target :reader dmx-query-run-source-target-of :initarg :source-target)
   (status :reader dmx-query-run-status-of :initarg :status)
   (rows :reader dmx-query-run-rows-of :initarg :rows :initform nil)
   (command-records :reader dmx-query-run-command-records-of
                    :initarg :command-records
                    :initform nil)
   (http-records :reader dmx-query-run-http-records-of
                 :initarg :http-records
                 :initform nil)
   (raw-request :reader dmx-query-run-raw-request-of
                :initarg :raw-request
                :initform nil)
   (raw-response :reader dmx-query-run-raw-response-of
                 :initarg :raw-response
                 :initform nil)
   (executed-at :reader dmx-query-run-executed-at-of :initarg :executed-at)
   (error-detail :reader dmx-query-run-error-detail-of
                 :initarg :error-detail
                 :initform nil)))

(defclass dmx-sync-plan ()
  ((id :reader id-of :initarg :id)
   (source-target :reader dmx-sync-plan-source-target-of :initarg :source-target)
   (target-target :reader dmx-sync-plan-target-target-of :initarg :target-target)
   (query-run-a :reader dmx-sync-plan-query-run-a-of :initarg :query-run-a)
   (query-run-b :reader dmx-sync-plan-query-run-b-of :initarg :query-run-b)
   (items :reader dmx-sync-plan-items-of :initarg :items :initform nil)
   (status :reader dmx-sync-plan-status-of :initarg :status)))

(defclass dmx-sync-plan-item ()
  ((id :reader id-of :initarg :id)
   (uri :reader dmx-sync-plan-item-uri-of :initarg :uri :initform nil)
   (source-row :reader dmx-sync-plan-item-source-row-of
               :initarg :source-row
               :initform nil)
   (target-row :reader dmx-sync-plan-item-target-row-of
               :initarg :target-row
               :initform nil)
   (action :reader dmx-sync-plan-item-action-of :initarg :action)
   (reason :reader dmx-sync-plan-item-reason-of :initarg :reason :initform nil)
   (safe-p :reader dmx-sync-plan-item-safe-p :initarg :safe-p :initform nil)))

(defclass dmx-query-topic-materialization ()
  ((sqlite-store :reader dmx-query-topic-materialization-sqlite-store-of
                 :initarg :sqlite-store)
   (query-run :reader dmx-query-topic-materialization-query-run-of
              :initarg :query-run)
   (topic-title :reader dmx-query-topic-materialization-topic-title-of
                :initarg :topic-title)
   (topic-uri :reader dmx-query-topic-materialization-topic-uri-of
              :initarg :topic-uri)
   (payload :reader dmx-query-topic-materialization-payload-of
            :initarg :payload)
   (status :reader dmx-query-topic-materialization-status-of
           :initarg :status
           :initform :dry-run)))

(defun dmx-query-now-string ()
  (multiple-value-bind (second minute hour day month year)
      (decode-universal-time (get-universal-time) 0)
    (format nil "~4,'0D-~2,'0D-~2,'0DT~2,'0D:~2,'0D:~2,'0DZ"
            year month day hour minute second)))

(defun dmx-query-safe-id-component (value)
  (let ((string (string-downcase (format nil "~A" (or value "value")))))
    (with-output-to-string (stream)
      (loop with wrote-separator = nil
            for char across string
            do (cond
                 ((or (alphanumericp char) (char= char #\-) (char= char #\_))
                  (write-char char stream)
                  (setf wrote-separator nil))
                 ((not wrote-separator)
                  (write-char #\- stream)
                  (setf wrote-separator t)))))))

(defun dmx-query-make-id (prefix &rest parts)
  (format nil "~A:~A:~36R"
          prefix
          (dmx-query-safe-id-component (format nil "~{~A~^-~}" parts))
          (get-universal-time)))

(defun dmx-query-string-prefix-p (prefix string)
  (and (stringp prefix)
       (stringp string)
       (<= (length prefix) (length string))
       (string= prefix string :end2 (length prefix))))

(defun dmx-query-keyword-value (value)
  (cond
    ((null value) nil)
    ((keywordp value) value)
    ((symbolp value) (intern (string-upcase (symbol-name value)) :keyword))
    ((stringp value)
     (intern (substitute #\- #\_ (string-upcase value)) :keyword))
    (t value)))

(defun dmx-query-keyword-label (value)
  (cond
    ((null value) "")
    ((keywordp value) (string-downcase (symbol-name value)))
    ((symbolp value) (string-downcase (symbol-name value)))
    (t (format nil "~A" value))))

(defun dmx-query-seq-list (value)
  (cond
    ((null value) nil)
    ((vectorp value) (coerce value 'list))
    ((listp value) value)
    (t (list value))))

(defun dmx-query-keyword-key (key)
  (intern (substitute #\- #\_ (string-upcase key)) :keyword))

(defun dmx-query-camel-keyword-key (key)
  (with-output-to-string (stream)
    (loop for char across key
          for index from 0
          do (cond
               ((and (upper-case-p char) (plusp index))
                (write-char #\- stream)
                (write-char char stream))
               (t
                (write-char (char-upcase char) stream))))))

(defun dmx-query-raw-plist-value (raw-row key default)
  (if (and (consp raw-row) (consp (first raw-row)))
      (or (cdr (assoc key raw-row :test #'string=))
          default)
      (or (getf raw-row (dmx-query-keyword-key key))
          (getf raw-row (intern (dmx-query-camel-keyword-key key) :keyword))
          default)))

(defun dmx-query-raw-value (raw-row key &optional default)
  (cond
    ((hash-table-p raw-row)
     (multiple-value-bind (value present-p)
        (gethash key raw-row)
       (if present-p value default)))
    ((listp raw-row)
     (dmx-query-raw-plist-value raw-row key default))
    (t default)))

(defun dmx-query-json-string (value)
  (with-output-to-string (stream)
    (let ((shasht:*write-alist-as-object* t))
      (shasht:write-json value stream))))

(defun dmx-query-parse-json-list (string)
  (if (or (null string)
          (zerop (length (string-trim '(#\Space #\Tab #\Newline #\Return)
                                      string))))
      nil
      (let ((data (shasht:read-json string)))
        (dmx-query-seq-list data))))

(defun dmx-query-raw-bool (raw-row key)
  (let ((value (dmx-query-raw-value raw-row key nil)))
    (cond
      ((eq value t) t)
      ((eq value nil) nil)
      ((stringp value) (member (string-downcase value) '("true" "yes" "1")
                               :test #'string=))
      (t value))))

(defun dmx-query-raw-topicmap-ids (raw-row)
  (or (dmx-query-seq-list (dmx-query-raw-value raw-row "topicmapIds"))
      (loop for membership in
            (dmx-query-seq-list
             (dmx-query-raw-value raw-row "topicmapMemberships"))
            for id = (dmx-query-raw-value membership "topicmapId")
            when id
              collect id)))

(defun dmx-query-raw-workspace-assignment (raw-row)
  (or (dmx-query-raw-value raw-row "workspaceAssignment")
      (dmx-query-raw-value raw-row "workspaceAssignmentEvidence")))

(defun dmx-query-raw-workspace-id (raw-row)
  (or (dmx-query-raw-value raw-row "workspaceId")
      (dmx-query-raw-value raw-row "workspaceIdProperty")
      (dmx-query-raw-value raw-row "workspacePropertyValue")))

(defun dmx-query-assignment-workspace-id (assignment)
  (and assignment
       (dmx-query-raw-value assignment "workspaceId")))

(defun dmx-query-workspace-status (raw-row)
  (or (let ((explicit (dmx-query-raw-value raw-row "workspaceStatus")))
        (and explicit (dmx-query-keyword-value explicit)))
      (let* ((workspace-id (dmx-query-raw-workspace-id raw-row))
             (property-exists
               (or (dmx-query-raw-bool raw-row "workspacePropertyExists")
                   workspace-id))
             (assignment (dmx-query-raw-workspace-assignment raw-row))
             (assignment-id (dmx-query-assignment-workspace-id assignment))
             (assignment-exists
               (or (dmx-query-raw-bool raw-row "workspaceAssignmentExists")
                   assignment)))
        (cond
          ((and property-exists assignment-exists workspace-id assignment-id
                (not (equal (format nil "~A" workspace-id)
                            (format nil "~A" assignment-id))))
           :inconsistent)
          (property-exists :assigned-by-property)
          (assignment-exists :assigned-by-association)
          (t :unassigned)))))

(defun dmx-query-row-workspace-id (raw-row status)
  (case status
    (:assigned-by-association
     (dmx-query-assignment-workspace-id
      (dmx-query-raw-workspace-assignment raw-row)))
    (otherwise
     (or (dmx-query-raw-workspace-id raw-row)
         (dmx-query-assignment-workspace-id
          (dmx-query-raw-workspace-assignment raw-row))))))

(defun dmx-query-ownership-class (raw-row)
  (or (let ((explicit (dmx-query-raw-value raw-row "ownershipClass")))
        (and explicit (dmx-query-keyword-value explicit)))
      (let ((uri (dmx-query-raw-value raw-row "uri")))
        (if (dmx-query-string-prefix-p
             +dmx-query-hyperdoc-workspace-annotation-uri-prefix+
             uri)
            :hyperdoc-workspace-annotation
            :foreign-or-unsupported))))

(defun dmx-query-row-matches-parameters-p
    (row &key type-uri uri-prefix topicmap-id ownership-class)
  (and (eq (dmx-topic-row-workspace-status-of row) :unassigned)
       (or (null type-uri)
           (equal type-uri (dmx-topic-row-type-uri-of row)))
       (or (null uri-prefix)
           (dmx-query-string-prefix-p uri-prefix (dmx-topic-row-uri-of row)))
       (or (null topicmap-id)
           (member topicmap-id
                   (dmx-topic-row-topicmap-ids-of row)
                   :test (lambda (a b)
                           (equal (format nil "~A" a) (format nil "~A" b)))))
       (or (null ownership-class)
           (eq (dmx-query-keyword-value ownership-class)
               (dmx-topic-row-ownership-class-of row)))))

(defun dmx-query-apply-limit-offset (rows limit offset)
  (let* ((offset (or offset 0))
         (tail (nthcdr offset rows)))
    (if (and limit (integerp limit) (not (minusp limit)))
        (subseq tail 0 (min limit (length tail)))
        tail)))

(defmethod dmx-store-topic-row ((target dmx-store-target) raw-row)
  (let* ((status (dmx-query-workspace-status raw-row))
         (raw-topic-id (or (dmx-query-raw-value raw-row "topicId")
                           (dmx-query-raw-value raw-row "nodeId"))))
    (make-instance 'dmx-topic-row
                   :store-id (id-of target)
                   :backend-kind (kind-of target)
                   :topic-id (and raw-topic-id (format nil "~A" raw-topic-id))
                   :uri (dmx-query-raw-value raw-row "uri")
                   :type-uri (dmx-query-raw-value raw-row "typeUri")
                   :value (dmx-query-raw-value raw-row "value")
                   :workspace-id (dmx-query-row-workspace-id raw-row status)
                   :workspace-status status
                   :topicmap-ids (dmx-query-raw-topicmap-ids raw-row)
                   :ownership-class (dmx-query-ownership-class raw-row)
                   :raw-source raw-row
                   :evidence-path (dmx-query-raw-value raw-row "evidencePath"))))

(defun make-dmx-unassigned-topics-query
    (&key limit offset type-uri uri-prefix topicmap-id ownership-class)
  (make-instance 'dmx-query
                 :id "dmx-query:unassigned-topics"
                 :title "List topics not assigned to any workspace"
                 :query-kind :unassigned-topics
                 :parameters (list :limit limit
                                   :offset offset
                                   :type-uri type-uri
                                   :uri-prefix uri-prefix
                                   :topicmap-id topicmap-id
                                   :ownership-class ownership-class)
                 :created-at (dmx-query-now-string)))

(defun make-dmx-query-run
    (query target status &key rows command-records http-records raw-request
                  raw-response error-detail)
  (make-instance 'dmx-query-run
                 :id (dmx-query-make-id "dmx-query-run"
                                        (id-of target)
                                        (dmx-query-kind-of query))
                 :query query
                 :source-target target
                 :status status
                 :rows rows
                 :command-records command-records
                 :http-records http-records
                 :raw-request raw-request
                 :raw-response raw-response
                 :executed-at (dmx-query-now-string)
                 :error-detail error-detail))

(defmethod dmx-list-unassigned-topics
    ((target dmx-store-target)
     &key limit offset type-uri uri-prefix topicmap-id ownership-class
       include-raw-p)
  (dmx-run-query
   target
   (make-dmx-unassigned-topics-query
    :limit limit
    :offset offset
    :type-uri type-uri
    :uri-prefix uri-prefix
    :topicmap-id topicmap-id
    :ownership-class ownership-class)
   :limit limit
   :offset offset
   :include-raw-p include-raw-p))

(defmethod dmx-run-query
    ((target dmx-memory-store-target) (query dmx-query)
     &key limit offset include-raw-p)
  (declare (ignore include-raw-p))
  (if (not (eq (dmx-memory-store-target-capability-status-of target) :ok))
      (make-dmx-query-run query target
                          (dmx-memory-store-target-capability-status-of target)
                          :error-detail "Memory fixture target configured as unavailable.")
      (let* ((parameters (dmx-query-parameters-of query))
             (normalized
               (mapcar (lambda (raw-row)
                         (dmx-store-topic-row target raw-row))
                       (dmx-memory-store-target-raw-rows-of target)))
             (rows
               (remove-if-not
                (lambda (row)
                  (dmx-query-row-matches-parameters-p
                   row
                   :type-uri (getf parameters :type-uri)
                   :uri-prefix (getf parameters :uri-prefix)
                   :topicmap-id (getf parameters :topicmap-id)
                   :ownership-class (getf parameters :ownership-class)))
                normalized)))
        (make-dmx-query-run
         query
         target
         :ok
         :rows (dmx-query-apply-limit-offset rows limit offset)
         :raw-request (prin1-to-string (dmx-query-parameters-of query))))))

(defun make-dmx-memory-query-target (&key (id "memory-dmx-query-target")
                                       (title "Memory DMX query target")
                                       (raw-rows nil)
                                       (capability-status :ok))
  (make-instance 'dmx-memory-store-target
                 :id id
                 :title title
                 :kind :memory
                 :description "Fixture-backed DMX query target for tests."
                 :raw-rows raw-rows
                 :capability-status capability-status))

(defmethod dmx-run-query
    ((target dmx-http-store-target) (query dmx-query)
     &key limit offset include-raw-p)
  (declare (ignore limit offset include-raw-p))
  (let ((status
          (if (eq (dmx-http-store-target-credential-mode-of target)
                  :credentials-required)
              :credentials-pending
              :backend-capability-missing)))
    (make-dmx-query-run
     query
     target
     status
     :raw-request
     (format nil "~A full-store query ~A"
             (dmx-http-store-target-base-url-of target)
             (dmx-query-kind-of query))
     :error-detail
     (case status
       (:credentials-pending
        "HTTP DMX target needs credentials; credentials are not persisted in HyperDoc's SQLite query journal.")
       (otherwise
        "HTTP DMX adapter cannot perform full-store unassigned-topic inventory through the current public read API.")))))

(defun dmx-query-run-ok-p (run)
  (and run (eq (dmx-query-run-status-of run) :ok)))

(defun dmx-topic-row-identity-value (row identity-key)
  (ecase identity-key
    (:uri (dmx-topic-row-uri-of row))
    (:topic-id (dmx-topic-row-topic-id-of row))))

(defun dmx-index-topic-rows (rows identity-key)
  (let ((table (make-hash-table :test #'equal))
        (ambiguous nil))
    (dolist (row rows)
      (let ((key (dmx-topic-row-identity-value row identity-key)))
        (if (or (null key) (gethash key table))
            (push row ambiguous)
            (setf (gethash key table) row))))
    (values table ambiguous)))

(defun make-dmx-sync-plan-item (&key uri source-row target-row action reason safe-p)
  (make-instance 'dmx-sync-plan-item
                 :id (dmx-query-make-id "dmx-sync-plan-item" uri action)
                 :uri uri
                 :source-row source-row
                 :target-row target-row
                 :action action
                 :reason reason
                 :safe-p safe-p))

(defun dmx-topic-row-diff-action (source-row target-row)
  (cond
    ((not (equal (dmx-topic-row-value-of source-row)
                 (dmx-topic-row-value-of target-row)))
     :different-value)
    ((not (equal (dmx-topic-row-type-uri-of source-row)
                 (dmx-topic-row-type-uri-of target-row)))
     :different-type-uri)
    ((not (eq (dmx-topic-row-workspace-status-of source-row)
              (dmx-topic-row-workspace-status-of target-row)))
     :workspace-status-differs)
    (t :same)))

(defmethod dmx-compare-topic-stores
    ((source-target dmx-store-target) (target-target dmx-store-target)
     (query dmx-query)
     &key (identity-key :uri))
  (let ((source-run (dmx-run-query source-target query
                                   :limit (getf (dmx-query-parameters-of query)
                                                :limit)))
        (target-run (dmx-run-query target-target query
                                   :limit (getf (dmx-query-parameters-of query)
                                                :limit))))
    (if (not (and (dmx-query-run-ok-p source-run)
                  (dmx-query-run-ok-p target-run)))
        (make-instance
         'dmx-sync-plan
         :id (dmx-query-make-id "dmx-sync-plan"
                                (id-of source-target)
                                (id-of target-target))
         :source-target source-target
         :target-target target-target
         :query-run-a source-run
         :query-run-b target-run
         :status :unsupported
         :items (list
                 (make-dmx-sync-plan-item
                  :action :unsupported
                  :reason (format nil
                                  "Comparison requires two successful read-only query runs; source=~A target=~A"
                                  (dmx-query-run-status-of source-run)
                                  (dmx-query-run-status-of target-run))
                  :safe-p nil)))
        (multiple-value-bind (source-index source-ambiguous)
            (dmx-index-topic-rows (dmx-query-run-rows-of source-run) identity-key)
          (multiple-value-bind (target-index target-ambiguous)
              (dmx-index-topic-rows (dmx-query-run-rows-of target-run) identity-key)
            (let ((items nil))
              (maphash
               (lambda (uri source-row)
                 (let ((target-row (gethash uri target-index)))
                   (if target-row
                       (let ((action (dmx-topic-row-diff-action source-row
                                                                target-row)))
                         (push
                          (make-dmx-sync-plan-item
                           :uri uri
                           :source-row source-row
                           :target-row target-row
                           :action action
                           :reason (if (eq action :same)
                                       "Rows match by URI."
                                       "Rows differ by normalized fields.")
                           :safe-p (eq action :same))
                          items))
                       (push
                        (make-dmx-sync-plan-item
                         :uri uri
                         :source-row source-row
                         :action :missing-in-target
                         :reason "URI is present in source query result but absent in target."
                         :safe-p nil)
                        items))))
               source-index)
              (maphash
               (lambda (uri target-row)
                 (unless (gethash uri source-index)
                   (push
                    (make-dmx-sync-plan-item
                     :uri uri
                     :target-row target-row
                     :action :missing-in-source
                     :reason "URI is present in target query result but absent in source."
                     :safe-p nil)
                    items)))
               target-index)
              (dolist (row (append source-ambiguous target-ambiguous))
                (push
                 (make-dmx-sync-plan-item
                  :uri (dmx-topic-row-uri-of row)
                  :source-row (and (member row source-ambiguous) row)
                  :target-row (and (member row target-ambiguous) row)
                  :action :ambiguous-identity
                  :reason "URI identity is missing or duplicated in one result set."
                  :safe-p nil)
                 items))
              (make-instance
               'dmx-sync-plan
               :id (dmx-query-make-id "dmx-sync-plan"
                                      (id-of source-target)
                                      (id-of target-target))
               :source-target source-target
               :target-target target-target
               :query-run-a source-run
               :query-run-b target-run
               :status :dry-run
               :items (nreverse items))))))))

(defmethod dmx-plan-topic-sync
    ((source-target dmx-store-target) (target-target dmx-store-target)
     &key query (identity-key :uri))
  (dmx-compare-topic-stores
   source-target
   target-target
   (or query (make-dmx-unassigned-topics-query))
   :identity-key identity-key))

(defun dmx-topic-row-json-object (row)
  `(("storeId" . ,(dmx-topic-row-store-id-of row))
    ("backendKind" . ,(dmx-query-keyword-label
                       (dmx-topic-row-backend-kind-of row)))
    ("topicId" . ,(dmx-topic-row-topic-id-of row))
    ("uri" . ,(dmx-topic-row-uri-of row))
    ("typeUri" . ,(dmx-topic-row-type-uri-of row))
    ("value" . ,(dmx-topic-row-value-of row))
    ("workspaceId" . ,(and (dmx-topic-row-workspace-id-of row)
                           (format nil "~A"
                                   (dmx-topic-row-workspace-id-of row))))
    ("workspaceStatus" . ,(dmx-query-keyword-label
                           (dmx-topic-row-workspace-status-of row)))
    ("topicmapIds" . ,(coerce (dmx-topic-row-topicmap-ids-of row) 'vector))
    ("ownershipClass" . ,(dmx-query-keyword-label
                          (dmx-topic-row-ownership-class-of row)))
    ("evidencePath" . ,(dmx-topic-row-evidence-path-of row))))

(defun dmx-sync-plan-item-json-object (item)
  `(("uri" . ,(dmx-sync-plan-item-uri-of item))
    ("action" . ,(dmx-query-keyword-label
                  (dmx-sync-plan-item-action-of item)))
    ("reason" . ,(dmx-sync-plan-item-reason-of item))
    ("safe" . ,(and (dmx-sync-plan-item-safe-p item) t))
    ("source" . ,(and (dmx-sync-plan-item-source-row-of item)
                      (dmx-topic-row-json-object
                       (dmx-sync-plan-item-source-row-of item))))
    ("target" . ,(and (dmx-sync-plan-item-target-row-of item)
                      (dmx-topic-row-json-object
                       (dmx-sync-plan-item-target-row-of item))))))

(defmethod dmx-materialize-query-as-topic
    ((sqlite-store dmx-sqlite-query-store) (query-run dmx-query-run)
     &key topic-title topic-uri)
  (let* ((title (or topic-title
                    (format nil "DMX query run ~A" (id-of query-run))))
         (uri (or topic-uri
                  (format nil "hyperdoc:dmx-query-run/~A"
                          (dmx-query-safe-id-component (id-of query-run)))))
         (payload
           `(("title" . ,title)
             ("uri" . ,uri)
             ("queryRunId" . ,(id-of query-run))
             ("status" . ,(dmx-query-keyword-label
                           (dmx-query-run-status-of query-run)))
             ("rowCount" . ,(length (dmx-query-run-rows-of query-run)))
             ("rows" . ,(coerce
                          (mapcar #'dmx-topic-row-json-object
                                  (dmx-query-run-rows-of query-run))
                          'vector)))))
    (make-instance 'dmx-query-topic-materialization
                   :sqlite-store sqlite-store
                   :query-run query-run
                   :topic-title title
                   :topic-uri uri
                   :payload payload
                   :status :dry-run)))

(defmethod print-object ((object dmx-store-target) stream)
  (print-unreadable-object (object stream :type t :identity nil)
    (format stream "~A (~(~A~))" (title-of object) (kind-of object))))

(defmethod print-object ((object dmx-topic-row) stream)
  (print-unreadable-object (object stream :type t :identity nil)
    (format stream "~A ~A ~A"
            (dmx-topic-row-topic-id-of object)
            (or (dmx-topic-row-uri-of object) "<no uri>")
            (dmx-topic-row-workspace-status-of object))))

(defmethod print-object ((object dmx-query) stream)
  (print-unreadable-object (object stream :type t :identity nil)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object dmx-query-run) stream)
  (print-unreadable-object (object stream :type t :identity nil)
    (format stream "~A ~A rows=~D"
            (title-of (dmx-query-run-query-of object))
            (dmx-query-run-status-of object)
            (length (dmx-query-run-rows-of object)))))

(defmethod print-object ((object dmx-sync-plan) stream)
  (print-unreadable-object (object stream :type t :identity nil)
    (format stream "~A -> ~A ~A items=~D"
            (id-of (dmx-sync-plan-source-target-of object))
            (id-of (dmx-sync-plan-target-target-of object))
            (dmx-sync-plan-status-of object)
            (length (dmx-sync-plan-items-of object)))))
