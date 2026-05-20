;;;; DMX query operation constructors and backend adapters

(in-package :hyperdoc)

(defparameter +dmx-unassigned-topics-tool-class-name+
  "HyperdocNeo4jUnassignedTopicsTool")

(defparameter +dmx-unassigned-topics-tool-source-relative-path+
  #P"tools/HyperdocNeo4jUnassignedTopicsTool.java")

(defparameter +local-dmx-query-default-sqlite-path+
  #P"var/dmx-query-journal.sqlite")

(defparameter +local-dmx-neo4j-query-default-tool-build-root+
  #P"/tmp/hyperdoc-neo4j-unassigned-topics-tool/")

(defun dmx-query-normalize-pathname (value &key directoryp)
  (typecase value
    (null nil)
    (pathname (if directoryp
                  (uiop:ensure-directory-pathname value)
                  value))
    (string
     (let ((path (pathname value)))
       (if directoryp
           (uiop:ensure-directory-pathname path)
           path)))))

(defun dmx-query-tool-path (relative-path)
  (asdf:system-relative-pathname :hyperdoc relative-path))

(defun make-local-dmx-neo4j-query-target
    (&key
       (app-root +local-dmx-neo4j-default-app-root+)
       (store-path nil)
       (java-home +local-dmx-neo4j-default-java-home+)
       (helper-build-root +local-dmx-neo4j-query-default-tool-build-root+))
  (let* ((app-root (dmx-query-normalize-pathname app-root :directoryp t))
         (store-path (or (dmx-query-normalize-pathname store-path :directoryp t)
                         (merge-pathnames
                          +local-dmx-neo4j-default-store-relative-path+
                          app-root))))
    (make-instance
     'dmx-neo4j-store-target
     :id "local-dmx-neo4j"
     :title "Local offline DMX Neo4j store"
     :kind :neo4j
     :description "Read-only embedded Neo4j target for local DMX topic inventory."
     :app-root app-root
     :store-path store-path
     :java-home (dmx-query-normalize-pathname java-home :directoryp t)
     :helper-source-path
     (dmx-query-tool-path +dmx-unassigned-topics-tool-source-relative-path+)
     :helper-build-root
     (dmx-query-normalize-pathname helper-build-root :directoryp t)
     :helper-classpath-entries (neo4j-helper-classpath-entries app-root))))

(defun make-local-dmx-http-query-target
    (&key (base-url +local-dmx-neo4j-default-http-base-url+)
       username
       (credential-mode :anonymous)
       default-topicmap-id
       default-workspace-id)
  (make-instance
   'dmx-http-store-target
   :id "local-dmx-http"
   :title "Local DMX HTTP endpoint"
   :kind :http
   :description "Capability-limited read-only HTTP target for local live DMX."
   :base-url base-url
   :username username
   :credential-mode credential-mode
   :default-topicmap-id default-topicmap-id
   :default-workspace-id default-workspace-id))

(defun make-remote-dmx-http-query-target
    (&key (base-url "https://dmx.ralfbarkow.ch")
       username
       (credential-mode :anonymous)
       default-topicmap-id
       default-workspace-id)
  (make-instance
   'dmx-http-store-target
   :id "remote-dmx-http"
   :title "Remote DMX HTTP endpoint"
   :kind :http
   :description "Capability-limited read-only HTTP target for remote DMX."
   :base-url base-url
   :username username
   :credential-mode credential-mode
   :default-topicmap-id default-topicmap-id
   :default-workspace-id default-workspace-id))

(defun make-dmx-query-sqlite-store
    (&key
       (db-path +local-dmx-query-default-sqlite-path+)
       (sqlite-program "sqlite3"))
  (make-instance
   'dmx-sqlite-query-store
   :id "local-dmx-query-sqlite"
   :title "Local DMX query SQLite journal"
   :kind :sqlite
   :description "Durable local journal for DMX query definitions, runs, rows, and dry-run sync plans."
   :db-path (dmx-query-normalize-pathname db-path)
   :sqlite-program sqlite-program))

(defun dmx-neo4j-query-classpath-string (target &key include-build-root-p)
  (neo4j-string-join
   (mapcar #'namestring
           (append
            (when include-build-root-p
              (list (dmx-neo4j-store-target-helper-build-root-of target)))
            (dmx-neo4j-store-target-helper-classpath-entries-of target)))
   ":"))

(defun dmx-neo4j-query-java-program (target program-name)
  (if-let (java-home (dmx-neo4j-store-target-java-home-of target))
    (namestring (merge-pathnames (format nil "bin/~A" program-name)
                                 java-home))
    program-name))

(defun dmx-neo4j-query-build-dir-command (target)
  (list "mkdir" "-p"
        (namestring (dmx-neo4j-store-target-helper-build-root-of target))))

(defun dmx-neo4j-query-compile-command (target)
  (list (dmx-neo4j-query-java-program target "javac")
        "-cp" (dmx-neo4j-query-classpath-string target)
        "-d" (namestring (dmx-neo4j-store-target-helper-build-root-of target))
        (namestring (dmx-neo4j-store-target-helper-source-path-of target))))

(defun dmx-neo4j-query-report-command
    (target &key limit offset topicmap-id uri-prefix type-uri)
  (append
   (list (dmx-neo4j-query-java-program target "java")
         "-cp" (dmx-neo4j-query-classpath-string target
                                                 :include-build-root-p t)
         +dmx-unassigned-topics-tool-class-name+
         "report-unassigned-topics"
         (namestring (dmx-neo4j-store-target-store-path-of target)))
   (when limit
     (list "--limit" (format nil "~D" limit)))
   (when offset
     (list "--offset" (format nil "~D" offset)))
   (when topicmap-id
     (list "--topicmap-id" (format nil "~A" topicmap-id)))
   (when uri-prefix
     (list "--uri-prefix" uri-prefix))
   (when type-uri
     (list "--type-uri" type-uri))))

(defun dmx-query-command-record-success-p (record)
  (and record (neo4j-command-record-success-p record)))

(defun dmx-query-json-field (object key &optional default)
  (if (hash-table-p object)
      (multiple-value-bind (value present-p)
          (gethash key object)
        (if present-p value default))
      default))

(defun dmx-query-payload-rows (payload)
  (dmx-query-seq-list
   (or (dmx-query-json-field payload "rows")
       (dmx-query-json-field payload "topics")
       (dmx-query-json-field payload "matchingTopics"))))

(defun dmx-neo4j-query-store-available-p (target)
  (and (dmx-neo4j-store-target-store-path-of target)
       (uiop:directory-exists-p
        (dmx-neo4j-store-target-store-path-of target))))

(defmethod dmx-run-query
    ((target dmx-neo4j-store-target) (query dmx-query)
     &key limit offset include-raw-p)
  (declare (ignore include-raw-p))
  (let ((parameters (dmx-query-parameters-of query)))
    (cond
      ((not (eq (dmx-query-kind-of query) :unassigned-topics))
       (make-dmx-query-run
        query
        target
        :backend-capability-missing
        :error-detail (format nil "Neo4j adapter does not implement query kind ~A"
                              (dmx-query-kind-of query))))
      ((not (dmx-neo4j-query-store-available-p target))
       (make-dmx-query-run
        query
        target
        :backend-unavailable
        :raw-request (namestring (dmx-neo4j-store-target-store-path-of target))
        :error-detail
        (format nil "Local DMX Neo4j store not found: ~A"
                (namestring (dmx-neo4j-store-target-store-path-of target)))))
      (t
       (let* ((build-record
                (neo4j-run-command-record
                 :prepare-build
                 (dmx-neo4j-query-build-dir-command target)))
              (compile-record
                (neo4j-run-command-record
                 :compile-helper
                 (dmx-neo4j-query-compile-command target)))
              (records (list build-record compile-record)))
         (cond
           ((not (dmx-query-command-record-success-p build-record))
            (make-dmx-query-run
             query target :backend-unavailable
             :command-records records
             :error-detail "Preparing the Neo4j query helper build directory failed."))
           ((not (dmx-query-command-record-success-p compile-record))
            (make-dmx-query-run
             query target :backend-unavailable
             :command-records records
             :error-detail "Compiling the read-only Neo4j query helper failed."))
           (t
            (let* ((report-command
                     (dmx-neo4j-query-report-command
                      target
                      :limit limit
                      :offset offset
                      :topicmap-id (getf parameters :topicmap-id)
                      :uri-prefix (getf parameters :uri-prefix)
                      :type-uri (getf parameters :type-uri)))
                   (report-record
                     (neo4j-run-command-record :read-report report-command))
                   (records (append records (list report-record))))
              (if (not (dmx-query-command-record-success-p report-record))
                  (make-dmx-query-run
                   query target :backend-unavailable
                   :command-records records
                   :raw-request (neo4j-command-display-string report-command)
                   :raw-response (getf report-record :output)
                   :error-detail "Running the read-only Neo4j unassigned-topic report failed.")
                  (handler-case
                      (let* ((payload (shasht:read-json
                                       (getf report-record :output)))
                             (rows (mapcar
                                    (lambda (raw-row)
                                      (dmx-store-topic-row target raw-row))
                                    (dmx-query-payload-rows payload))))
                        (make-dmx-query-run
                         query target :ok
                         :rows rows
                         :command-records records
                         :raw-request (neo4j-command-display-string
                                       report-command)
                         :raw-response (getf report-record :output)))
                    (error (condition)
                      (make-dmx-query-run
                       query target :error
                       :command-records records
                       :raw-request (neo4j-command-display-string
                                     report-command)
                       :raw-response (getf report-record :output)
                       :error-detail (princ-to-string condition)))))))))))))

(defun list-local-dmx-unassigned-topics (&key limit)
  (dmx-list-unassigned-topics
   (make-local-dmx-neo4j-query-target)
   :limit limit
   :include-raw-p t))

(defun record-local-dmx-unassigned-topic-query
    (&key limit (sqlite-store (make-dmx-query-sqlite-store)))
  (let ((run (list-local-dmx-unassigned-topics :limit limit)))
    (dmx-persist-query-run sqlite-store run)
    run))

(defun plan-local-to-remote-dmx-unassigned-topic-sync
    (&key limit
       (sqlite-store (make-dmx-query-sqlite-store))
       (source-target (make-local-dmx-neo4j-query-target))
       (target-target (make-remote-dmx-http-query-target)))
  (let* ((query (make-dmx-unassigned-topics-query :limit limit))
         (plan (dmx-plan-topic-sync source-target
                                    target-target
                                    :query query
                                    :identity-key :uri)))
    (when sqlite-store
      (dmx-persist-query-run sqlite-store
                             (dmx-sync-plan-query-run-a-of plan))
      (dmx-persist-query-run sqlite-store
                             (dmx-sync-plan-query-run-b-of plan))
      (when (fboundp 'dmx-persist-sync-plan)
        (funcall 'dmx-persist-sync-plan sqlite-store plan)))
    plan))
