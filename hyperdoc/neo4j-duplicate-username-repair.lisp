;;;; Narrow local Neo4j inspection and repair objects for duplicate DMX usernames
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defparameter +neo4j-duplicate-username-tool-class-name+
  "HyperdocNeo4jDuplicateUsernameTool")

(defparameter +neo4j-duplicate-username-tool-source-relative-path+
  #P"tools/HyperdocNeo4jDuplicateUsernameTool.java")

(defparameter +local-dmx-neo4j-default-app-root+
  #P"/Users/rgb/Applications/dmx-5.3.5/")

(defparameter +local-dmx-neo4j-default-store-relative-path+
  #P"dmx-db/")

(defparameter +local-dmx-neo4j-default-java-home+
  #P"/Library/Java/JavaVirtualMachines/jdk-1.8.jdk/Contents/Home/")

(defparameter +local-dmx-neo4j-default-tool-build-root+
  #P"/tmp/hyperdoc-neo4j-duplicate-username-tool/")

(defparameter +local-dmx-neo4j-default-http-base-url+
  "http://127.0.0.1:8080/")

(defparameter +local-dmx-neo4j-default-http-port+
  8080)

(defparameter +local-dmx-neo4j-default-username+
  "admin")

(defparameter +local-dmx-neo4j-classpath-relative-paths+
  '("bundle-cache/bundle19/version0.0/bundle.jar-embedded/neo4j-kernel-1.8.1.jar"
    "bundle-cache/bundle19/version0.0/bundle.jar-embedded/neo4j-lucene-index-1.8.1.jar"
    "bundle-cache/bundle19/version0.0/bundle.jar-embedded/lucene-core-3.5.0.jar"
    "bundle-cache/bundle19/version0.0/bundle.jar-embedded/geronimo-jta_1.1_spec-1.1.1.jar"))

(defclass neo4j-store-target ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (app-root :reader neo4j-store-target-app-root-of
             :initarg :app-root
             :type pathname)
   (store-path :reader neo4j-store-target-store-path-of
               :initarg :store-path
               :type pathname)
   (java-home :reader neo4j-store-target-java-home-of
              :initarg :java-home
              :type (or null pathname))
   (tool-source-path :reader neo4j-store-target-tool-source-path-of
                     :initarg :tool-source-path
                     :type pathname)
   (tool-build-root :reader neo4j-store-target-tool-build-root-of
                    :initarg :tool-build-root
                    :type pathname)
   (tool-classpath-entries :reader neo4j-store-target-tool-classpath-entries-of
                           :initarg :tool-classpath-entries
                           :type list)))

(defclass dmx-neo4j-instance-target ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (store-target :reader neo4j-instance-target-store-target-of
                 :initarg :store-target
                 :type neo4j-store-target)
   (http-base-url :reader neo4j-instance-target-http-base-url-of
                  :initarg :http-base-url
                  :type string)
   (http-port :reader neo4j-instance-target-http-port-of
              :initarg :http-port
              :type integer)))

(defclass neo4j-read-query-operation ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (instance-target :reader neo4j-read-query-operation-instance-target-of
                    :initarg :instance-target
                    :type dmx-neo4j-instance-target)
   (query-kind :reader neo4j-read-query-operation-kind-of
               :initarg :query-kind)
   (username :reader neo4j-read-query-operation-username-of
             :initarg :username
             :type string)))

(defclass neo4j-username-ambiguity-report ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (read-operation :reader neo4j-username-ambiguity-report-read-operation-of
                   :initarg :read-operation
                   :type neo4j-read-query-operation)
   (status :reader neo4j-username-ambiguity-report-status-of
           :initarg :status)
   (raw-json :reader neo4j-username-ambiguity-report-raw-json-of
             :initarg :raw-json
             :initform nil)
   (raw-payload :reader neo4j-username-ambiguity-report-raw-payload-of
                :initarg :raw-payload
                :initform nil)
   (command-records :reader neo4j-username-ambiguity-report-command-records-of
                    :initarg :command-records
                    :initform nil)
   (matching-topics :reader neo4j-username-ambiguity-report-matching-topics-of
                    :initarg :matching-topics
                    :initform nil)
   (matching-count :reader neo4j-username-ambiguity-report-matching-count-of
                   :initarg :matching-count
                   :initform 0)
   (classification :reader neo4j-username-ambiguity-report-classification-of
                   :initarg :classification)
   (classification-note :reader neo4j-username-ambiguity-report-classification-note-of
                        :initarg :classification-note
                        :initform nil)
   (canonical-topic :reader neo4j-username-ambiguity-report-canonical-topic-of
                    :initarg :canonical-topic
                    :initform nil)
   (stale-topic :reader neo4j-username-ambiguity-report-stale-topic-of
                :initarg :stale-topic
                :initform nil)))

(defclass neo4j-duplicate-username-repair-plan ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (instance-target :reader neo4j-duplicate-username-repair-plan-instance-target-of
                    :initarg :instance-target
                    :type dmx-neo4j-instance-target)
   (report :reader neo4j-duplicate-username-repair-plan-report-of
           :initarg :report
           :type neo4j-username-ambiguity-report)
   (status :reader neo4j-duplicate-username-repair-plan-status-of
           :initarg :status)
   (approval-status :accessor neo4j-duplicate-username-repair-plan-approval-status-of
                    :initarg :approval-status
                    :initform :pending)
   (offline-confirmation-status :accessor neo4j-duplicate-username-repair-plan-offline-confirmation-status-of
                                :initarg :offline-confirmation-status
                                :initform :pending)
   (offline-confirmation-note :accessor neo4j-duplicate-username-repair-plan-offline-confirmation-note-of
                              :initarg :offline-confirmation-note
                              :initform nil)
   (review-note :accessor neo4j-duplicate-username-repair-plan-review-note-of
                :initarg :review-note
                :initform nil)
   (refusal-reason :reader neo4j-duplicate-username-repair-plan-refusal-reason-of
                   :initarg :refusal-reason
                   :initform nil)
   (replacement-value :reader neo4j-duplicate-username-repair-plan-replacement-value-of
                      :initarg :replacement-value
                      :type string)
   (backup-path :reader neo4j-duplicate-username-repair-plan-backup-path-of
                :initarg :backup-path
                :type pathname)
   (expected-canonical-topic-id :reader neo4j-duplicate-username-repair-plan-expected-canonical-topic-id-of
                                :initarg :expected-canonical-topic-id
                                :initform nil)
   (expected-stale-topic-id :reader neo4j-duplicate-username-repair-plan-expected-stale-topic-id-of
                            :initarg :expected-stale-topic-id
                            :initform nil)
   (verification-operation :reader neo4j-duplicate-username-repair-plan-verification-operation-of
                           :initarg :verification-operation
                           :type neo4j-read-query-operation)))

(defclass neo4j-repair-operation ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (plan :reader neo4j-repair-operation-plan-of
         :initarg :plan
         :type neo4j-duplicate-username-repair-plan)
   (status :reader neo4j-repair-operation-status-of
           :initarg :status)
   (refusal-reason :reader neo4j-repair-operation-refusal-reason-of
                   :initarg :refusal-reason
                   :initform nil)
   (preflight-report :reader neo4j-repair-operation-preflight-report-of
                     :initarg :preflight-report
                     :initform nil)
   (execution-records :reader neo4j-repair-operation-execution-records-of
                      :initarg :execution-records
                      :initform nil)
   (post-repair-report :reader neo4j-repair-operation-post-repair-report-of
                       :initarg :post-repair-report
                       :initform nil)
   (verification-operation :reader neo4j-repair-operation-verification-operation-of
                           :initarg :verification-operation
                           :initform nil)
   (verification-record :accessor neo4j-repair-operation-verification-record-of
                        :initarg :verification-record
                        :initform nil)))

(defun neo4j-command-kind-label (kind)
  (ecase kind
    (:duplicate-username-report "Duplicate username report")
    (:live-username-probe "Live username probe")))

(defun neo4j-username-ambiguity-classification-label (classification)
  (ecase classification
    (:no-match "No username topic matches")
    (:unique "Unique username topic")
    (:canonical-vs-stale-duplicate "Canonical account plus stale duplicate")
    (:unresolved "Unresolved ambiguity")
    (:inspection-failed "Inspection failed")))

(defun neo4j-repair-plan-status-label (status)
  (ecase status
    (:review-pending "Review pending")
    (:unsupported "Unsupported plan")))

(defun neo4j-repair-operation-status-label (status)
  (ecase status
    (:refused "Refused")
    (:failed "Failed")
    (:executed "Executed")))

(defun neo4j-repair-approval-status-label (status)
  (ecase status
    (:pending "Pending")
    (:approved "Approved")))

(defun neo4j-offline-confirmation-status-label (status)
  (ecase status
    (:pending "Pending")
    (:confirmed-stopped "Confirmed stopped")))

(defun neo4j-seq->list (value)
  (cond
    ((null value) '())
    ((listp value) value)
    ((vectorp value) (coerce value 'list))
    (t (list value))))

(defun neo4j-payload-field (table key &optional default)
  (if (hash-table-p table)
      (multiple-value-bind (value present-p)
          (gethash key table)
        (if present-p value default))
      default))

(defun neo4j-user-accounts-for-topic (topic)
  (neo4j-seq->list
   (neo4j-payload-field topic "userAccounts")))

(defun neo4j-topic-account-backed-p (topic)
  (plusp (length (neo4j-user-accounts-for-topic topic))))

(defun neo4j-topic-node-id (topic)
  (neo4j-payload-field topic "nodeId"))

(defun neo4j-topic-workspace-assignment (topic)
  (neo4j-payload-field topic "workspaceAssignment"))

(defun neo4j-topic-workspace-title (topic)
  (neo4j-payload-field
   (neo4j-topic-workspace-assignment topic)
   "workspaceTitle"))

(defun neo4j-topic-primary-user-account (topic)
  (first (neo4j-user-accounts-for-topic topic)))

(defun neo4j-topic-password-topic (topic)
  (neo4j-payload-field
   (neo4j-topic-primary-user-account topic)
   "passwordTopic"))

(defun neo4j-string-join (strings separator)
  (with-output-to-string (stream)
    (loop for string in strings
          for firstp = t then nil
          do (unless firstp
               (write-string separator stream))
          (write-string string stream))))

(defun neo4j-command-display-string (command)
  (neo4j-string-join
   (mapcar (lambda (token)
             (shell-quote
              (etypecase token
                (pathname (namestring token))
                (string token)
                (symbol (symbol-name token))
                (integer (princ-to-string token)))))
           command)
   " "))

(defun neo4j-trim-output (string)
  (string-right-trim '(#\Newline #\Return)
                     (or string "")))

(defun neo4j-run-command-record (kind command)
  (handler-case
      (multiple-value-bind (output error-output exit-code)
          (uiop:run-program command
                            :output :string
                            :error-output :output
                            :ignore-error-status t)
        (declare (ignore error-output))
        (list :kind kind
              :command command
              :command-string (neo4j-command-display-string command)
              :exit-code exit-code
              :output (neo4j-trim-output output)))
    (error (condition)
      (list :kind kind
            :command command
            :command-string (neo4j-command-display-string command)
            :exit-code nil
            :output (princ-to-string condition)))))

(defun neo4j-command-record-success-p (record)
  (let ((exit-code (getf record :exit-code)))
    (and (integerp exit-code)
         (zerop exit-code))))

(defun neo4j-helper-classpath-entries (app-root)
  (mapcar (lambda (relative-path)
            (merge-pathnames relative-path app-root))
          +local-dmx-neo4j-classpath-relative-paths+))

(defun neo4j-helper-classpath-string (store-target &key include-build-root-p)
  (let ((entries
         (append
          (when include-build-root-p
            (list (neo4j-store-target-tool-build-root-of store-target)))
          (neo4j-store-target-tool-classpath-entries-of store-target))))
    (neo4j-string-join (mapcar #'namestring entries) ":")))

(defun neo4j-java-program (store-target program-name)
  (if-let (java-home (neo4j-store-target-java-home-of store-target))
      (namestring
       (merge-pathnames (format nil "bin/~A" program-name)
                        java-home))
    program-name))

(defun neo4j-helper-compile-command (store-target)
  (list (neo4j-java-program store-target "javac")
        "-cp" (neo4j-helper-classpath-string store-target)
        "-d" (namestring (neo4j-store-target-tool-build-root-of store-target))
        (namestring (neo4j-store-target-tool-source-path-of store-target))))

(defun neo4j-helper-report-command (store-target username)
  (list (neo4j-java-program store-target "java")
        "-cp" (neo4j-helper-classpath-string store-target :include-build-root-p t)
        +neo4j-duplicate-username-tool-class-name+
        "report"
        (namestring (neo4j-store-target-store-path-of store-target))
        username))

(defun neo4j-helper-rename-command (store-target node-id new-value)
  (list (neo4j-java-program store-target "java")
        "-cp" (neo4j-helper-classpath-string store-target :include-build-root-p t)
        +neo4j-duplicate-username-tool-class-name+
        "rename-stale-username"
        (namestring (neo4j-store-target-store-path-of store-target))
        (princ-to-string node-id)
        new-value))

(defun neo4j-tool-build-dir-command (store-target)
  (list "mkdir" "-p"
        (namestring (neo4j-store-target-tool-build-root-of store-target))))

(defun neo4j-store-backup-command (store-target backup-path)
  (list "cp" "-Rp"
        (namestring (neo4j-store-target-store-path-of store-target))
        (namestring backup-path)))

(defun neo4j-live-username-probe-command (instance-target username)
  (list "curl" "-sS" "-i" "--max-time" "5"
        (format nil "~Aaccess-control/username/~A?children=true&assocChildren=true"
                (neo4j-instance-target-http-base-url-of instance-target)
                username)))

(defun neo4j-port-listener-command (port)
  (list "lsof" "-nP"
        (format nil "-iTCP:~D" port)
        "-sTCP:LISTEN"))

(defun neo4j-store-tool-path (relative-path)
  (asdf:system-relative-pathname :hyperdoc relative-path))

(defgeneric neo4j-duplicate-username-adapter-prepare-commands (store-target)
  (:documentation "Return the fixed helper-setup command list for STORE-TARGET."))

(defgeneric neo4j-duplicate-username-adapter-report-command (store-target username)
  (:documentation "Return the fixed read-only report command for USERNAME on STORE-TARGET."))

(defgeneric neo4j-duplicate-username-adapter-rename-command (store-target node-id new-value)
  (:documentation "Return the fixed narrow rename command for NODE-ID on STORE-TARGET."))

(defmethod neo4j-duplicate-username-adapter-prepare-commands ((store-target neo4j-store-target))
  (list (neo4j-tool-build-dir-command store-target)
        (neo4j-helper-compile-command store-target)))

(defmethod neo4j-duplicate-username-adapter-report-command
    ((store-target neo4j-store-target) username)
  (neo4j-helper-report-command store-target username))

(defmethod neo4j-duplicate-username-adapter-rename-command
    ((store-target neo4j-store-target) node-id new-value)
  (neo4j-helper-rename-command store-target node-id new-value))

(defun neo4j-path-safe-component (string)
  (let* ((raw
          (with-output-to-string (stream)
            (loop with wrote-separator = nil
                  for char across (string-downcase string)
                  do (cond
                       ((or (alphanumericp char)
                            (char= char #\-)
                            (char= char #\_))
                        (write-char char stream)
                        (setf wrote-separator nil))
                       ((not wrote-separator)
                        (write-char #\- stream)
                        (setf wrote-separator t))))))
         (candidate (string-trim "-" raw)))
    (if (> (length candidate) 0)
        candidate
        "username")))

(defun deterministic-neo4j-backup-path (store-target username stale-topic-id)
  (merge-pathnames
   (format nil "dmx-db.pre-repair-~A-stale-~D/"
           (neo4j-path-safe-component username)
           stale-topic-id)
   (neo4j-store-target-app-root-of store-target)))

(defun make-local-neo4j-store-target
    (&key
       (app-root +local-dmx-neo4j-default-app-root+)
       (java-home +local-dmx-neo4j-default-java-home+)
       (tool-build-root +local-dmx-neo4j-default-tool-build-root+))
  (let* ((app-root (uiop:ensure-directory-pathname app-root))
         (store-path (merge-pathnames +local-dmx-neo4j-default-store-relative-path+
                                      app-root))
         (tool-source-path
          (neo4j-store-tool-path +neo4j-duplicate-username-tool-source-relative-path+)))
    (make-instance 'neo4j-store-target
                   :id "local-neo4j-store-target"
                   :title "Local Neo4j store target"
                   :summary "Local-first target object for the DMX 5.3.5 Neo4j store and the narrow duplicate-username helper tool."
                   :app-root app-root
                   :store-path store-path
                   :java-home java-home
                   :tool-source-path tool-source-path
                   :tool-build-root (uiop:ensure-directory-pathname tool-build-root)
                   :tool-classpath-entries (neo4j-helper-classpath-entries app-root))))

(defun make-local-dmx-neo4j-instance-target
    (&key
       (store-target (make-local-neo4j-store-target))
       (http-base-url +local-dmx-neo4j-default-http-base-url+)
       (http-port +local-dmx-neo4j-default-http-port+))
  (make-instance 'dmx-neo4j-instance-target
                 :id "local-dmx-neo4j-instance-target"
                 :title "Local DMX Neo4j instance target"
                 :summary "Local DMX target object that keeps the Neo4j store path and the live HTTP verification endpoint together for the duplicate-admin workflow."
                 :store-target store-target
                 :http-base-url http-base-url
                 :http-port http-port))

(defun make-local-admin-username-ambiguity-read-operation
    (&key
       (instance-target (make-local-dmx-neo4j-instance-target))
       (username +local-dmx-neo4j-default-username+))
  (make-instance 'neo4j-read-query-operation
                 :id "neo4j-read-query-operation:duplicate-admin-username-report"
                 :title "Read duplicate DMX username report"
                 :summary "Read-only report operation for one DMX username value. It compiles the narrow helper and asks only for the duplicate-username shape."
                 :instance-target instance-target
                 :query-kind :duplicate-username-report
                 :username username))

(defun make-local-admin-live-username-verification-operation
    (&key
       (instance-target (make-local-dmx-neo4j-instance-target))
       (username +local-dmx-neo4j-default-username+))
  (make-instance 'neo4j-read-query-operation
                 :id "neo4j-read-query-operation:live-admin-username-probe"
                 :title "Verify duplicate-admin ambiguity over HTTP"
                 :summary "Read-only live probe for the public username endpoint after the store-level repair and server restart."
                 :instance-target instance-target
                 :query-kind :live-username-probe
                 :username username))

(defun example-admin-username-ambiguity-payload ()
  (shasht:read-json
   "{\"tool\":\"HyperdocNeo4jDuplicateUsernameTool\",\"command\":\"report\",\"dbPath\":\"/Users/rgb/Applications/dmx-5.3.5/dmx-db\",\"username\":\"admin\",\"matchingCount\":2,\"matchingTopics\":[{\"nodeId\":2827,\"typeUri\":\"dmx.accesscontrol.username\",\"value\":\"admin\",\"workspaceId\":2790,\"created\":1311111111111,\"modified\":1311111112222,\"workspaceAssignment\":{\"assignmentAssocId\":2895,\"workspaceId\":2790,\"workspaceTitle\":\"System\",\"workspaceUri\":\"dmx://workspace/system\"},\"userAccounts\":[],\"configDefaults\":[{\"configurationId\":2872,\"defaultTopicId\":2869,\"defaultTypeUri\":\"dmx.accesscontrol.login_enabled\",\"defaultValue\":true}]},{\"nodeId\":906722,\"typeUri\":\"dmx.accesscontrol.username\",\"value\":\"admin\",\"workspaceId\":2879,\"created\":1773393295339,\"modified\":1773393295444,\"workspaceAssignment\":{\"assignmentAssocId\":906936,\"workspaceId\":2879,\"workspaceTitle\":\"/admin\",\"workspaceUri\":\"dmx://workspace/admin\"},\"userAccounts\":[{\"userAccountId\":2900,\"workspaceId\":2879,\"value\":\"admin\",\"created\":1311111113333,\"modified\":1773393295444,\"passwordTopic\":{\"passwordTopicId\":906938,\"hasSalt\":true,\"created\":1773393295440,\"modified\":1773393295444}}],\"configDefaults\":[{\"configurationId\":906808,\"defaultTopicId\":906729,\"defaultTypeUri\":\"dmx.accesscontrol.login_enabled\",\"defaultValue\":true}]}]}"))

(defun example-admin-username-read-operation ()
  (make-local-admin-username-ambiguity-read-operation))

(defun classify-neo4j-username-ambiguity-topics (topics)
  (let* ((matching-topics (neo4j-seq->list topics))
         (account-backed
          (remove-if-not #'neo4j-topic-account-backed-p matching-topics))
         (standalone
          (remove-if #'neo4j-topic-account-backed-p matching-topics)))
    (cond
      ((null matching-topics)
       (list :classification :no-match
             :note "No username topic matches the requested value."))
      ((= 1 (length matching-topics))
       (list :classification :unique
             :canonical-topic (first matching-topics)
             :note "The username is unique in the store; there is no duplicate repair to plan."))
      ((and (= 2 (length matching-topics))
            (= 1 (length account-backed))
            (= 1 (length standalone)))
       (list :classification :canonical-vs-stale-duplicate
             :canonical-topic (first account-backed)
             :stale-topic (first standalone)
             :note "Exactly one username topic is attached to a user_account and exactly one is standalone, so the standalone duplicate is the only supported rename target."))
      (t
       (list :classification :unresolved
             :note "The matching topics do not reduce to one account-backed canonical identity plus one standalone stale duplicate."
             :canonical-topic (when (= 1 (length account-backed))
                                (first account-backed)))))))

(defun make-neo4j-username-ambiguity-report
    (read-operation &key status raw-json raw-payload command-records)
  (let* ((matching-topics
          (neo4j-seq->list
           (neo4j-payload-field raw-payload "matchingTopics")))
         (matching-count
          (or (neo4j-payload-field raw-payload "matchingCount")
              (length matching-topics)))
         (classification-data
          (if (eq status :ok)
              (classify-neo4j-username-ambiguity-topics matching-topics)
              (list :classification :inspection-failed
                    :note "The read-only duplicate-username inspection did not complete successfully."))))
    (make-instance 'neo4j-username-ambiguity-report
                   :id (format nil "neo4j-username-ambiguity-report:~A"
                               (neo4j-read-query-operation-username-of read-operation))
                   :title "Neo4j username ambiguity report"
                   :summary "Inspectable report for one username value, including the matched username topics, canonical/stale classification, and the exact commands used to obtain the evidence."
                   :read-operation read-operation
                   :status status
                   :raw-json raw-json
                   :raw-payload raw-payload
                   :command-records command-records
                   :matching-topics matching-topics
                   :matching-count matching-count
                   :classification (getf classification-data :classification)
                   :classification-note (getf classification-data :note)
                   :canonical-topic (getf classification-data :canonical-topic)
                   :stale-topic (getf classification-data :stale-topic))))

(defun inspect-neo4j-duplicate-username-report (read-operation)
  (let* ((store-target
          (neo4j-instance-target-store-target-of
           (neo4j-read-query-operation-instance-target-of read-operation)))
         (prepare-commands
          (neo4j-duplicate-username-adapter-prepare-commands store-target))
         (records '())
         (build-record (neo4j-run-command-record
                        :prepare-build
                        (first prepare-commands)))
         (compile-record (neo4j-run-command-record
                          :compile-helper
                          (second prepare-commands))))
    (setf records (list build-record compile-record))
    (cond
      ((not (neo4j-command-record-success-p build-record))
       (make-neo4j-username-ambiguity-report
        read-operation
        :status :inspection-failed
        :command-records records))
      ((not (neo4j-command-record-success-p compile-record))
       (make-neo4j-username-ambiguity-report
        read-operation
        :status :inspection-failed
        :command-records records))
      (t
       (let* ((report-record
               (neo4j-run-command-record
                :read-report
                (neo4j-duplicate-username-adapter-report-command
                 store-target
                 (neo4j-read-query-operation-username-of read-operation))))
              (records (append records (list report-record))))
         (if (neo4j-command-record-success-p report-record)
             (make-neo4j-username-ambiguity-report
              read-operation
              :status :ok
              :raw-json (getf report-record :output)
              :raw-payload (shasht:read-json (getf report-record :output))
              :command-records records)
             (make-neo4j-username-ambiguity-report
              read-operation
              :status :inspection-failed
              :command-records records)))))))

(defun inspect-local-admin-username-ambiguity
    (&key
       (instance-target (make-local-dmx-neo4j-instance-target))
       (username +local-dmx-neo4j-default-username+))
  (inspect-neo4j-duplicate-username-report
   (make-instance 'neo4j-read-query-operation
                  :id "neo4j-read-query-operation:duplicate-admin-username-report"
                  :title "Read duplicate DMX username report"
                  :summary "Read-only report operation for one DMX username value. It compiles the narrow helper and asks only for the duplicate-username shape."
                  :instance-target instance-target
                  :query-kind :duplicate-username-report
                  :username username)))

(defun make-example-admin-username-ambiguity-report ()
  (make-neo4j-username-ambiguity-report
   (example-admin-username-read-operation)
   :status :ok
   :raw-payload (example-admin-username-ambiguity-payload)
   :raw-json nil
   :command-records
   (list (list :kind :read-report
               :command '("java" "-cp" "/tmp/example-classpath"
                          "HyperdocNeo4jDuplicateUsernameTool"
                          "report"
                          "/Users/rgb/Applications/dmx-5.3.5/dmx-db"
                          "admin")
               :command-string
               "'java' '-cp' '/tmp/example-classpath' 'HyperdocNeo4jDuplicateUsernameTool' 'report' '/Users/rgb/Applications/dmx-5.3.5/dmx-db' 'admin'"
               :exit-code 0
               :output "{...example report elided...}"))))

(defun neo4j-supported-duplicate-repair-p (report)
  (eq (neo4j-username-ambiguity-report-classification-of report)
      :canonical-vs-stale-duplicate))

(defun plan-neo4j-duplicate-username-repair
    (report &key replacement-value backup-path)
  (let* ((read-operation
          (neo4j-username-ambiguity-report-read-operation-of report))
         (instance-target
          (neo4j-read-query-operation-instance-target-of read-operation))
         (stale-topic (neo4j-username-ambiguity-report-stale-topic-of report))
         (canonical-topic (neo4j-username-ambiguity-report-canonical-topic-of report))
         (stale-topic-id (neo4j-topic-node-id stale-topic))
         (canonical-topic-id (neo4j-topic-node-id canonical-topic))
         (username (neo4j-read-query-operation-username-of read-operation))
         (replacement-value
          (or replacement-value
              (if stale-topic-id
                  (format nil "~A__stale_~D" username stale-topic-id)
                  (format nil "~A__stale_duplicate" username))))
         (backup-path
          (or backup-path
              (and stale-topic-id
                   (deterministic-neo4j-backup-path
                    (neo4j-instance-target-store-target-of instance-target)
                    username
                    stale-topic-id))))
         (supported-p (neo4j-supported-duplicate-repair-p report)))
    (make-instance 'neo4j-duplicate-username-repair-plan
                   :id (format nil "neo4j-duplicate-username-repair-plan:~A"
                               username)
                   :title "Neo4j duplicate-username repair plan"
                   :summary "Reviewed plan object for the single supported write: rename one stale standalone duplicate username topic off the login value, preserving the canonical user_account-backed identity."
                   :instance-target instance-target
                   :report report
                   :status (if supported-p :review-pending :unsupported)
                   :approval-status :pending
                   :offline-confirmation-status :pending
                   :refusal-reason (unless supported-p
                                     (or (neo4j-username-ambiguity-report-classification-note-of report)
                                         "This ambiguity shape is outside the single supported rename repair."))
                   :replacement-value replacement-value
                   :backup-path backup-path
                   :expected-canonical-topic-id canonical-topic-id
                   :expected-stale-topic-id stale-topic-id
                   :verification-operation
                   (make-instance 'neo4j-read-query-operation
                                  :id "neo4j-read-query-operation:live-admin-username-probe"
                                  :title "Verify duplicate-admin ambiguity over HTTP"
                                  :summary "Read-only live probe for the public username endpoint after the store-level repair and server restart."
                                  :instance-target instance-target
                                  :query-kind :live-username-probe
                                  :username username))))

(defun plan-local-admin-duplicate-username-repair
    (&key
       (instance-target (make-local-dmx-neo4j-instance-target))
       (username +local-dmx-neo4j-default-username+))
  (plan-neo4j-duplicate-username-repair
   (inspect-local-admin-username-ambiguity
    :instance-target instance-target
    :username username)))

(defun make-example-admin-duplicate-username-repair-plan ()
  (plan-neo4j-duplicate-username-repair
   (make-example-admin-username-ambiguity-report)
   :backup-path #P"/Users/rgb/Applications/dmx-5.3.5/dmx-db.pre-repair-example/"))

(defun approve-neo4j-duplicate-username-repair-plan (plan &key review-note)
  (when (eq (neo4j-duplicate-username-repair-plan-status-of plan)
            :review-pending)
    (setf (neo4j-duplicate-username-repair-plan-approval-status-of plan)
          :approved
          (neo4j-duplicate-username-repair-plan-review-note-of plan)
          (or review-note
              "Reviewed in HyperDoc before local execution.")))
  plan)

(defun confirm-neo4j-duplicate-username-repair-plan-offline (plan &key note)
  (when (eq (neo4j-duplicate-username-repair-plan-status-of plan)
            :review-pending)
    (setf (neo4j-duplicate-username-repair-plan-offline-confirmation-status-of plan)
          :confirmed-stopped
          (neo4j-duplicate-username-repair-plan-offline-confirmation-note-of plan)
          (or note
              "Operator explicitly confirmed that the local DMX/Neo4j instance is stopped before repair.")))
  plan)

(defun make-refused-neo4j-repair-operation
    (plan refusal-reason &key preflight-report verification-record)
  (make-instance 'neo4j-repair-operation
                 :id "neo4j-repair-operation:duplicate-username-repair"
                 :title "Neo4j duplicate-username repair operation"
                 :summary "Execution record for the single supported duplicate-username rename repair."
                 :plan plan
                 :status :refused
                 :refusal-reason refusal-reason
                 :preflight-report preflight-report
                 :verification-operation
                 (neo4j-duplicate-username-repair-plan-verification-operation-of plan)
                 :verification-record verification-record))

(defun make-failed-neo4j-repair-operation
    (plan execution-records &key preflight-report post-repair-report refusal-reason)
  (make-instance 'neo4j-repair-operation
                 :id "neo4j-repair-operation:duplicate-username-repair"
                 :title "Neo4j duplicate-username repair operation"
                 :summary "Execution record for the single supported duplicate-username rename repair."
                 :plan plan
                 :status :failed
                 :refusal-reason refusal-reason
                 :preflight-report preflight-report
                 :execution-records execution-records
                 :post-repair-report post-repair-report
                 :verification-operation
                 (neo4j-duplicate-username-repair-plan-verification-operation-of plan)))

(defun make-successful-neo4j-repair-operation
    (plan execution-records &key preflight-report post-repair-report)
  (make-instance 'neo4j-repair-operation
                 :id "neo4j-repair-operation:duplicate-username-repair"
                 :title "Neo4j duplicate-username repair operation"
                 :summary "Execution record for the single supported duplicate-username rename repair."
                 :plan plan
                 :status :executed
                 :preflight-report preflight-report
                 :execution-records execution-records
                 :post-repair-report post-repair-report
                 :verification-operation
                 (neo4j-duplicate-username-repair-plan-verification-operation-of plan)))

(defun neo4j-port-listener-state (instance-target)
  (let ((record
         (neo4j-run-command-record
          :port-listener-check
          (neo4j-port-listener-command
           (neo4j-instance-target-http-port-of instance-target)))))
    (cond
      ((and (integerp (getf record :exit-code))
            (zerop (getf record :exit-code))
            (> (length (getf record :output)) 0))
       (values :running record))
      ((and (integerp (getf record :exit-code))
            (= 1 (getf record :exit-code)))
       (values :stopped record))
      (t
       (values :unknown record)))))

(defun neo4j-report-matches-plan-p (report plan)
  (and (eq (neo4j-username-ambiguity-report-classification-of report)
           :canonical-vs-stale-duplicate)
       (eql (neo4j-topic-node-id
             (neo4j-username-ambiguity-report-canonical-topic-of report))
            (neo4j-duplicate-username-repair-plan-expected-canonical-topic-id-of plan))
       (eql (neo4j-topic-node-id
             (neo4j-username-ambiguity-report-stale-topic-of report))
            (neo4j-duplicate-username-repair-plan-expected-stale-topic-id-of plan))))

(defun neo4j-repair-plan-deterministic-targets-p (plan)
  (and (integerp (neo4j-duplicate-username-repair-plan-expected-stale-topic-id-of plan))
       (integerp (neo4j-duplicate-username-repair-plan-expected-canonical-topic-id-of plan))
       (stringp (neo4j-duplicate-username-repair-plan-replacement-value-of plan))
       (> (length (neo4j-duplicate-username-repair-plan-replacement-value-of plan)) 0)
       (pathnamep (neo4j-duplicate-username-repair-plan-backup-path-of plan))))

(defun execute-approved-neo4j-duplicate-username-repair (plan)
  (cond
    ((not (typep plan 'neo4j-duplicate-username-repair-plan))
     (error "Expected a neo4j-duplicate-username-repair-plan, got ~S" plan))
    ((not (eq (neo4j-duplicate-username-repair-plan-status-of plan)
              :review-pending))
     (make-refused-neo4j-repair-operation
      plan
      (or (neo4j-duplicate-username-repair-plan-refusal-reason-of plan)
          "This plan is not in a supported review-pending state.")))
    ((not (eq (neo4j-duplicate-username-repair-plan-approval-status-of plan)
              :approved))
     (make-refused-neo4j-repair-operation
      plan
      "Refusing mutation: the plan is still pending review and has not been explicitly approved."))
    ((not (eq (neo4j-duplicate-username-repair-plan-offline-confirmation-status-of plan)
              :confirmed-stopped))
     (make-refused-neo4j-repair-operation
      plan
      "Refusing mutation: the plan does not yet carry an explicit offline confirmation for the local DMX/Neo4j instance."))
    ((not (neo4j-repair-plan-deterministic-targets-p plan))
     (make-refused-neo4j-repair-operation
      plan
      "Refusing mutation: the plan does not yet contain a deterministic stale node id, canonical node id, replacement value, and backup path."))
    (t
     (let* ((instance-target
             (neo4j-duplicate-username-repair-plan-instance-target-of plan))
            (preflight-report
             (inspect-local-admin-username-ambiguity
              :instance-target instance-target
              :username
              (neo4j-read-query-operation-username-of
               (neo4j-username-ambiguity-report-read-operation-of
                (neo4j-duplicate-username-repair-plan-report-of plan))))))
       (cond
         ((not (eq (neo4j-username-ambiguity-report-status-of preflight-report)
                   :ok))
          (make-refused-neo4j-repair-operation
           plan
           "Refusing mutation: the preflight inspection did not complete successfully."
           :preflight-report preflight-report))
         ((not (neo4j-report-matches-plan-p preflight-report plan))
          (make-refused-neo4j-repair-operation
           plan
           "Refusing mutation: the live store no longer matches the reviewed canonical/stale duplicate shape."
           :preflight-report preflight-report))
         (t
          (multiple-value-bind (listener-state listener-record)
              (neo4j-port-listener-state instance-target)
            (cond
              ((eq listener-state :running)
               (make-refused-neo4j-repair-operation
                plan
                "Refusing mutation: the local DMX server is still listening on the instance port. Stop the service before opening the embedded store for rename."
                :preflight-report preflight-report
                :verification-record listener-record))
              ((eq listener-state :unknown)
               (make-refused-neo4j-repair-operation
                plan
                "Refusing mutation: HyperDoc could not verify whether the local DMX server is stopped."
                :preflight-report preflight-report
                :verification-record listener-record))
              (t
               (let* ((store-target
                       (neo4j-instance-target-store-target-of instance-target))
                      (records
                       (list listener-record
                             (neo4j-run-command-record
                              :prepare-build
                              (first
                               (neo4j-duplicate-username-adapter-prepare-commands
                                store-target)))
                             (neo4j-run-command-record
                              :compile-helper
                              (second
                               (neo4j-duplicate-username-adapter-prepare-commands
                                store-target)))
                             (neo4j-run-command-record
                              :backup-store
                              (neo4j-store-backup-command
                               store-target
                               (neo4j-duplicate-username-repair-plan-backup-path-of plan))))))
                 (labels ((record-at (index) (nth index records))
                          (rename-record ()
                            (neo4j-run-command-record
                             :rename-stale-username
                             (neo4j-duplicate-username-adapter-rename-command
                              store-target
                              (neo4j-duplicate-username-repair-plan-expected-stale-topic-id-of plan)
                              (neo4j-duplicate-username-repair-plan-replacement-value-of plan)))))
                   (cond
                     ((not (neo4j-command-record-success-p (record-at 1)))
                      (make-failed-neo4j-repair-operation
                       plan records
                       :preflight-report preflight-report
                       :refusal-reason "Preparing the helper build directory failed."))
                     ((not (neo4j-command-record-success-p (record-at 2)))
                      (make-failed-neo4j-repair-operation
                       plan records
                       :preflight-report preflight-report
                       :refusal-reason "Compiling the narrow Neo4j helper failed."))
                     ((not (neo4j-command-record-success-p (record-at 3)))
                      (make-failed-neo4j-repair-operation
                       plan records
                       :preflight-report preflight-report
                       :refusal-reason "The required store backup step failed; no rename was attempted."))
                     (t
                      (let* ((rename-record (rename-record))
                             (records (append records (list rename-record))))
                        (if (not (neo4j-command-record-success-p rename-record))
                            (make-failed-neo4j-repair-operation
                             plan records
                             :preflight-report preflight-report
                             :refusal-reason "The stale duplicate rename failed.")
                            (let ((post-repair-report
                                   (inspect-local-admin-username-ambiguity
                                    :instance-target instance-target
                                    :username
                                    (neo4j-read-query-operation-username-of
                                     (neo4j-username-ambiguity-report-read-operation-of
                                      preflight-report)))))
                              (if (member (neo4j-username-ambiguity-report-classification-of
                                           post-repair-report)
                                          '(:unique :no-match)
                                          :test #'eq)
                                  (make-successful-neo4j-repair-operation
                                   plan
                                   records
                                   :preflight-report preflight-report
                                   :post-repair-report post-repair-report)
                                  (make-failed-neo4j-repair-operation
                                   plan
                                   records
                                   :preflight-report preflight-report
                                   :post-repair-report post-repair-report
                                   :refusal-reason
                                   "The rename executed, but the post-repair store report still does not show a unique username topic."))))))))))))))))))

(defun verify-neo4j-duplicate-username-repair-operation (operation)
  (unless (typep operation 'neo4j-repair-operation)
    (error "Expected a neo4j-repair-operation, got ~S" operation))
  (let* ((verification-operation
          (neo4j-repair-operation-verification-operation-of operation))
         (instance-target
          (and verification-operation
               (neo4j-read-query-operation-instance-target-of verification-operation))))
    (if (null verification-operation)
        operation
        (multiple-value-bind (listener-state listener-record)
            (neo4j-port-listener-state instance-target)
          (setf (neo4j-repair-operation-verification-record-of operation)
                (if (eq listener-state :running)
                    (neo4j-run-command-record
                     :live-username-probe
                     (neo4j-live-username-probe-command
                      instance-target
                      (neo4j-read-query-operation-username-of verification-operation)))
                    listener-record))
          operation))))

(defun make-example-refused-admin-duplicate-username-repair-operation ()
  (execute-approved-neo4j-duplicate-username-repair
   (make-example-admin-duplicate-username-repair-plan)))

(defmethod print-object ((object neo4j-store-target) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object dmx-neo4j-instance-target) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object neo4j-read-query-operation) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object neo4j-username-ambiguity-report) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A (~A)"
            (title-of object)
            (neo4j-username-ambiguity-classification-label
             (neo4j-username-ambiguity-report-classification-of object)))))

(defmethod print-object ((object neo4j-duplicate-username-repair-plan) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A (~A / ~A / ~A)"
            (title-of object)
            (neo4j-repair-plan-status-label
             (neo4j-duplicate-username-repair-plan-status-of object))
            (neo4j-repair-approval-status-label
             (neo4j-duplicate-username-repair-plan-approval-status-of object))
            (neo4j-offline-confirmation-status-label
             (neo4j-duplicate-username-repair-plan-offline-confirmation-status-of object)))))

(defmethod print-object ((object neo4j-repair-operation) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A (~A)"
            (title-of object)
            (neo4j-repair-operation-status-label
             (neo4j-repair-operation-status-of object)))))

(defmethod materialization-shell-block ((operation neo4j-read-query-operation))
  (let* ((store-target
          (neo4j-instance-target-store-target-of
           (neo4j-read-query-operation-instance-target-of operation)))
         (prepare-commands
          (neo4j-duplicate-username-adapter-prepare-commands store-target))
         (commands
          (case (neo4j-read-query-operation-kind-of operation)
            (:duplicate-username-report
             (list (first prepare-commands)
                   (second prepare-commands)
                   (neo4j-duplicate-username-adapter-report-command
                    store-target
                    (neo4j-read-query-operation-username-of operation))))
            (:live-username-probe
             (list (neo4j-live-username-probe-command
                    (neo4j-read-query-operation-instance-target-of operation)
                    (neo4j-read-query-operation-username-of operation)))))))
    (shell-block
     (mapcar #'neo4j-command-display-string commands))))

(defmethod materialization-shell-block ((plan neo4j-duplicate-username-repair-plan))
  (if (not (eq (neo4j-duplicate-username-repair-plan-status-of plan)
               :review-pending))
      (shell-block
       (list "# Unsupported repair plan"
             (format nil "# Reason: ~A"
                     (or (neo4j-duplicate-username-repair-plan-refusal-reason-of plan)
                         "This ambiguity shape is not supported by the narrow rename repair."))))
      (let* ((instance-target
              (neo4j-duplicate-username-repair-plan-instance-target-of plan))
             (store-target
              (neo4j-instance-target-store-target-of instance-target))
             (prepare-commands
              (neo4j-duplicate-username-adapter-prepare-commands store-target))
             (commands
              (list (neo4j-port-listener-command
                     (neo4j-instance-target-http-port-of instance-target))
                    (first prepare-commands)
                    (second prepare-commands)
                    (neo4j-store-backup-command
                     store-target
                     (neo4j-duplicate-username-repair-plan-backup-path-of plan))
                    (neo4j-duplicate-username-adapter-rename-command
                     store-target
                     (neo4j-duplicate-username-repair-plan-expected-stale-topic-id-of plan)
                     (neo4j-duplicate-username-repair-plan-replacement-value-of plan))
                    (neo4j-duplicate-username-adapter-report-command
                     store-target
                     (neo4j-read-query-operation-username-of
                      (neo4j-duplicate-username-repair-plan-verification-operation-of plan)))
                    (neo4j-live-username-probe-command
                     instance-target
                     (neo4j-read-query-operation-username-of
                      (neo4j-duplicate-username-repair-plan-verification-operation-of plan))))))
        (shell-block
         (append
          '("# Stop the DMX server before running the store mutation."
            "# Review the report object first. Approve the plan explicitly and record offline confirmation before executing the guarded verb.")
          (mapcar #'neo4j-command-display-string commands))))))

(defmethod materialization-shell-block ((operation neo4j-repair-operation))
  (materialization-shell-block
   (neo4j-repair-operation-plan-of operation)))
