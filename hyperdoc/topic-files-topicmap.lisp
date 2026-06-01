;;;; SQLite-backed topicmap projection over authored topic source files.

(in-package :hyperdoc)

(defclass topic-source-file ()
  ((pathname
    :initarg :pathname
    :reader topic-source-file-pathname-of)
   (status
    :initarg :status
    :initform :unparsed
    :accessor topic-source-file-status-of)
   (form-count
    :initarg :form-count
    :initform 0
    :accessor topic-source-file-form-count-of)
   (in-packages
    :initarg :in-packages
    :initform nil
    :accessor topic-source-file-in-packages-of)
   (factories
    :initarg :factories
    :initform nil
    :accessor topic-source-file-factories-of)
   (parse-failures
    :initarg :parse-failures
    :initform nil
    :accessor topic-source-file-parse-failures-of)))

(defclass topic-factory-source-record ()
  ((source-file
    :initarg :source-file
    :reader topic-factory-source-record-source-file-of)
   (symbol
    :initarg :symbol
    :reader topic-factory-source-record-symbol-of)
   (package-name
    :initarg :package-name
    :initform nil
    :reader topic-factory-source-record-package-name-of)
   (symbol-name
    :initarg :symbol-name
    :reader topic-factory-source-record-symbol-name-of)
   (form-index
    :initarg :form-index
    :reader topic-factory-source-record-form-index-of)
   (status
    :initarg :status
    :initform :partial-topic
    :accessor topic-factory-source-record-status-of)
   (topic-id
    :initarg :topic-id
    :initform nil
    :reader topic-factory-source-record-topic-id-of)
   (topic-title
    :initarg :topic-title
    :initform nil
    :reader topic-factory-source-record-topic-title-of)
   (topic-summary
    :initarg :topic-summary
    :initform nil
    :reader topic-factory-source-record-topic-summary-of)
   (topic-references
    :initarg :topic-references
    :initform nil
    :reader topic-factory-source-record-topic-references-of)
   (make-topic-form
    :initarg :make-topic-form
    :initform nil
    :reader topic-factory-source-record-make-topic-form-of)
   (condition-message
    :initarg :condition-message
    :initform nil
    :reader topic-factory-source-record-condition-message-of)))

(defclass topic-files-topicmap ()
  ((id
    :initarg :id
    :initform "topic-files-topicmap"
    :reader topic-files-topicmap-id-of)
   (title
    :initarg :title
    :initform "Topic Files Topicmap"
    :reader topic-files-topicmap-title-of)
   (db-path
    :initarg :db-path
    :initform (default-topic-files-topicmap-sqlite-path)
    :accessor topic-files-topicmap-db-path-of)
   (sqlite-program
    :initarg :sqlite-program
    :initform "sqlite3"
    :reader topic-files-topicmap-sqlite-program-of)
   (source-files
    :initarg :source-files
    :initform nil
    :accessor topic-files-topicmap-source-files-of)
   (materialized-at
    :initarg :materialized-at
    :initform nil
    :accessor topic-files-topicmap-materialized-at-of)
   (materialization-status
    :initarg :materialization-status
    :initform :not-materialized
    :accessor topic-files-topicmap-materialization-status-of)
   (materialization-detail
    :initarg :materialization-detail
    :initform nil
    :accessor topic-files-topicmap-materialization-detail-of)))

(defmethod print-object ((file topic-source-file) stream)
  (print-unreadable-object (file stream :type t :identity nil)
    (format stream "~A status=~(~A~) factories=~D"
            (namestring (topic-source-file-pathname-of file))
            (topic-source-file-status-of file)
            (length (topic-source-file-factories-of file)))))

(defmethod print-object ((record topic-factory-source-record) stream)
  (print-unreadable-object (record stream :type t :identity nil)
    (format stream "~A status=~(~A~)"
            (topic-factory-source-record-label record)
            (topic-factory-source-record-status-of record))))

(defmethod print-object ((topicmap topic-files-topicmap) stream)
  (print-unreadable-object (topicmap stream :type t :identity nil)
    (format stream "~A files=~D status=~(~A~)"
            (topic-files-topicmap-title-of topicmap)
            (length (topic-files-topicmap-source-files-of topicmap))
            (topic-files-topicmap-materialization-status-of topicmap))))

(defmethod id-of ((topicmap topic-files-topicmap))
  (topic-files-topicmap-id-of topicmap))

(defmethod title-of ((topicmap topic-files-topicmap))
  (topic-files-topicmap-title-of topicmap))

(defmethod summary-of ((topicmap topic-files-topicmap))
  (format nil "~D loaded topic source files parsed into ~A."
          (length (topic-files-topicmap-source-files-of topicmap))
          (namestring (topic-files-topicmap-db-path-of topicmap))))

(defmethod title-of ((file topic-source-file))
  (file-namestring (topic-source-file-pathname-of file)))

(defmethod summary-of ((file topic-source-file))
  (format nil "~A topic source file with ~D top-level forms, ~D factories, and status ~(~A~)."
          (namestring (topic-source-file-pathname-of file))
          (topic-source-file-form-count-of file)
          (length (topic-source-file-factories-of file))
          (topic-source-file-status-of file)))

(defmethod pathname-of ((file topic-source-file))
  (topic-source-file-pathname-of file))

(defmethod content-target-of ((file topic-source-file))
  (topic-source-file-pathname-of file))

(defmethod exists-p ((file topic-source-file))
  (and (uiop:file-exists-p (topic-source-file-pathname-of file)) t))

(defmethod size-of ((file topic-source-file))
  (when (exists-p file)
    (with-open-file (stream (topic-source-file-pathname-of file)
                            :direction :input
                            :element-type '(unsigned-byte 8))
      (file-length stream))))

(defmethod content-of ((file topic-source-file))
  (when (exists-p file)
    (uiop:read-file-string (topic-source-file-pathname-of file))))

(defmethod title-of ((record topic-factory-source-record))
  (topic-factory-source-record-label record))

(defmethod summary-of ((record topic-factory-source-record))
  (format nil "~A in ~A constructs topic ~A."
          (topic-factory-source-record-label record)
          (namestring
           (topic-source-file-pathname-of
            (topic-factory-source-record-source-file-of record)))
          (or (topic-factory-source-record-topic-title-of record)
              (topic-factory-source-record-topic-id-of record)
              "<not statically available>")))

(defun default-topic-files-topicmap-sqlite-path ()
  (handler-case
      (asdf:system-relative-pathname :hyperdoc "var/topics.sqlite")
    (condition ()
      (merge-pathnames #P"var/topics.sqlite"
                       (uiop:ensure-directory-pathname
                        *default-pathname-defaults*)))))

(defun topic-files-topicmap-pathname (path)
  (etypecase path
    (pathname path)
    (string (pathname path))))

(defun make-topic-source-file (path)
  (make-instance 'topic-source-file
                 :pathname (topic-files-topicmap-pathname path)))

(defun ensure-topic-source-file (value)
  (etypecase value
    (topic-source-file value)
    ((or string pathname) (make-topic-source-file value))))

(defun topic-files-topicmap-symbol-name-p (value name)
  (and (symbolp value)
       (string= (symbol-name value) name)))

(defun topic-files-topicmap-defun-form-p (form)
  (and (consp form)
       (topic-files-topicmap-symbol-name-p (first form) "DEFUN")
       (symbolp (second form))))

(defun topic-files-topicmap-in-package-form-p (form)
  (and (consp form)
       (topic-files-topicmap-symbol-name-p (first form) "IN-PACKAGE")
       (second form)))

(defun topic-files-topicmap-package-name (designator)
  (etypecase designator
    (package (package-name designator))
    (string designator)
    (symbol
     (if (keywordp designator)
         (symbol-name designator)
         (string designator)))))

(defun topic-files-topicmap-record-failure (file condition &key form-index)
  (push (list :form-index form-index
              :condition-type (type-of condition)
              :condition-message (princ-to-string condition))
        (topic-source-file-parse-failures-of file)))

(defun topic-files-topicmap-find-make-topic-form (form)
  (labels ((scan-list (items)
             (loop while (consp items)
                   for found = (scan (first items))
                   when found do (return found)
                   do (setf items (rest items))
                   finally (when items
                             (return (scan items)))))
           (scan (node)
             (cond
               ((atom node) nil)
               ((and (consp node)
                     (topic-files-topicmap-symbol-name-p
                      (first node)
                      "MAKE-TOPIC"))
                node)
               (t
                (or (scan (first node))
                    (scan-list (rest node)))))))
    (scan form)))

(defun topic-files-topicmap-static-value (form)
  (cond
    ((or (stringp form) (numberp form) (keywordp form)) form)
    ((and (consp form)
          (topic-files-topicmap-symbol-name-p (first form) "QUOTE"))
     (second form))
    (t nil)))

(defun topic-files-topicmap-keyword-arg (plist key)
  (loop for (argument value) on plist by #'cddr
        when (eq argument key)
          do (return value)))

(defun topic-files-topicmap-static-string (value)
  (let ((static (topic-files-topicmap-static-value value)))
    (and static
         (if (stringp static)
             static
             (format nil "~A" static)))))

(defun topic-files-topicmap-static-references (value)
  (let ((static (topic-files-topicmap-static-value value)))
    (cond
      ((null static) nil)
      ((listp static) (mapcar (lambda (reference)
                                (format nil "~A" reference))
                              static))
      (t (list (format nil "~A" static))))))

(defun topic-files-topicmap-factory-status (topic-id title summary)
  (if (and topic-id title summary)
      :static-topic
      :partial-topic))

(defun topic-files-topicmap-make-factory-record
    (file form form-index make-topic-form)
  (let* ((symbol (second form))
         (arguments (rest make-topic-form))
         (topic-id
           (topic-files-topicmap-static-string
            (topic-files-topicmap-keyword-arg arguments :id)))
         (title
           (topic-files-topicmap-static-string
            (topic-files-topicmap-keyword-arg arguments :title)))
         (summary
           (topic-files-topicmap-static-string
            (topic-files-topicmap-keyword-arg arguments :summary)))
         (references
           (topic-files-topicmap-static-references
            (topic-files-topicmap-keyword-arg arguments :references))))
    (make-instance
     'topic-factory-source-record
     :source-file file
     :symbol symbol
     :package-name (and (symbol-package symbol)
                        (package-name (symbol-package symbol)))
     :symbol-name (symbol-name symbol)
     :form-index form-index
     :status (topic-files-topicmap-factory-status topic-id title summary)
     :topic-id topic-id
     :topic-title title
     :topic-summary summary
     :topic-references references
     :make-topic-form make-topic-form)))

(defun topic-files-topicmap-parse-source-file (file)
  (let ((path (topic-source-file-pathname-of file)))
    (setf (topic-source-file-status-of file) :parsing
          (topic-source-file-form-count-of file) 0
          (topic-source-file-in-packages-of file) nil
          (topic-source-file-factories-of file) nil
          (topic-source-file-parse-failures-of file) nil)
    (cond
      ((not (uiop:file-exists-p path))
       (setf (topic-source-file-status-of file) :missing)
       file)
      (t
       (let ((*read-eval* nil)
             (*package* (or (find-package :hyperdoc)
                            (find-package :cl-user)))
             (eof (gensym "EOF"))
             (form-index 0)
             (factories nil)
             (packages nil))
         (handler-case
             (with-open-file (stream path
                                     :direction :input
                                     :external-format :utf-8)
               (loop
                 for form = (handler-case
                                (read stream nil eof)
                              (error (condition)
                                (topic-files-topicmap-record-failure
                                 file
                                 condition
                                 :form-index (1+ form-index))
                                eof))
                 until (eq form eof)
                 do (incf form-index)
                    (when (topic-files-topicmap-in-package-form-p form)
                      (let* ((package-name
                               (topic-files-topicmap-package-name (second form)))
                             (package (find-package package-name)))
                        (pushnew package-name packages :test #'string=)
                        (if package
                            (setf *package* package)
                            (topic-files-topicmap-record-failure
                             file
                             (make-condition
                              'simple-error
                              :format-control "Package not found while parsing topic source: ~A"
                              :format-arguments (list package-name))
                             :form-index form-index))))
                    (when (topic-files-topicmap-defun-form-p form)
                      (let ((make-topic-form
                              (topic-files-topicmap-find-make-topic-form
                               form)))
                        (when make-topic-form
                          (push
                           (topic-files-topicmap-make-factory-record
                            file
                            form
                            form-index
                            make-topic-form)
                           factories))))))
           (error (condition)
             (topic-files-topicmap-record-failure file condition)))
         (setf (topic-source-file-form-count-of file) form-index
               (topic-source-file-in-packages-of file) (nreverse packages)
               (topic-source-file-factories-of file) (nreverse factories)
               (topic-source-file-status-of file)
               (cond
                 ((topic-source-file-parse-failures-of file)
                  (if factories :partial-error :parse-error))
                 (t :parsed)))
         file)))))

(defun topic-factory-source-record-label (record)
  (if (topic-factory-source-record-package-name-of record)
      (format nil "~A::~A"
              (topic-factory-source-record-package-name-of record)
              (topic-factory-source-record-symbol-name-of record))
      (topic-factory-source-record-symbol-name-of record)))

(defun topic-source-file-factory-records (files)
  (loop for file in files
        append (topic-source-file-factories-of file)))

(defun make-topic-files-topicmap
    (&key source-files
          (db-path (default-topic-files-topicmap-sqlite-path))
          (sqlite-program "sqlite3")
          (title "Topic Files Topicmap"))
  (let ((files (mapcar #'ensure-topic-source-file
                       (or source-files
                           (topic-registry-loaded-topic-files)))))
    (dolist (file files)
      (topic-files-topicmap-parse-source-file file))
    (make-instance 'topic-files-topicmap
                   :title title
                   :db-path (topic-files-topicmap-pathname db-path)
                   :sqlite-program sqlite-program
                   :source-files files)))

(defun topic-registry-diagnostic-topic-files-topicmap
    (diagnostic &key
                  (db-path (default-topic-files-topicmap-sqlite-path))
                  (sqlite-program "sqlite3"))
  (make-topic-files-topicmap
   :source-files (topic-registry-diagnostic-loaded-topic-files-of diagnostic)
   :db-path db-path
   :sqlite-program sqlite-program
   :title (format nil "Topic Files Topicmap for ~A"
                  (topic-registry-diagnostic-id-of diagnostic))))

(defun topic-files-topicmap-now-string ()
  (multiple-value-bind (second minute hour day month year)
      (decode-universal-time (get-universal-time) 0)
    (format nil "~4,'0D-~2,'0D-~2,'0DT~2,'0D:~2,'0D:~2,'0DZ"
            year month day hour minute second)))

(defun topic-files-topicmap-sqlite-available-p (&key (sqlite-program "sqlite3"))
  (and sqlite-program
       (not (string= sqlite-program ""))
       (handler-case
           (multiple-value-bind (output error-output exit-code)
               (uiop:run-program (list sqlite-program "--version")
                                 :output :string
                                 :error-output :string
                                 :ignore-error-status t)
             (declare (ignore output error-output))
             (zerop exit-code))
         (condition ()
           nil))))

(defun topic-files-topicmap-sqlite-run (topicmap sql &key tabs noheader)
  (let* ((db-path (topic-files-topicmap-db-path-of topicmap))
         (parent (uiop:pathname-directory-pathname db-path))
         (program (topic-files-topicmap-sqlite-program-of topicmap)))
    (cond
      ((not (topic-files-topicmap-sqlite-available-p
             :sqlite-program program))
       (values nil :backend-unavailable
               (format nil "sqlite3 is unavailable: ~A" program)))
      (t
       (ensure-directories-exist parent)
       (handler-case
           (multiple-value-bind (output error-output exit-code)
               (uiop:run-program
                (append (list program)
                        (when tabs (list "-tabs"))
                        (when noheader (list "-noheader"))
                        (list (namestring db-path)))
                :input (make-string-input-stream sql)
                :output :string
                :error-output :output
                :ignore-error-status t)
             (declare (ignore error-output))
             (if (zerop exit-code)
                 (values output :ok nil)
                 (values output :error
                         (format nil "sqlite3 exited with code ~D: ~A"
                                 exit-code
                                 output))))
         (condition (condition)
           (values nil :error (princ-to-string condition))))))))

(defun topic-files-topicmap-schema-sql ()
  "CREATE TABLE IF NOT EXISTS topic_source_file(
    path text primary key,
    status text not null,
    form_count integer not null,
    in_packages text,
    parse_failures text,
    parsed_at text not null
  );

  CREATE TABLE IF NOT EXISTS topic_factory(
    factory_key text primary key,
    source_path text not null,
    symbol_package text,
    symbol_name text not null,
    form_index integer not null,
    status text not null,
    topic_id text,
    title text,
    summary text,
    reference_count integer not null,
    condition_message text
  );

  CREATE TABLE IF NOT EXISTS topic_node(
    node_key text primary key,
    factory_key text not null,
    topic_id text,
    title text,
    summary text,
    source_path text not null,
    status text not null
  );

  CREATE TABLE IF NOT EXISTS topic_reference(
    reference_key text primary key,
    node_key text not null,
    factory_key text not null,
    reference_index integer not null,
    reference_text text not null,
    source_path text not null
  );

  CREATE TABLE IF NOT EXISTS topic_file_edge(
    edge_key text primary key,
    edge_type text not null,
    from_key text not null,
    from_label text,
    to_key text not null,
    to_label text,
    source_path text not null
  );

  CREATE INDEX IF NOT EXISTS topic_factory_source_path_idx
    ON topic_factory(source_path);

  CREATE INDEX IF NOT EXISTS topic_node_topic_id_idx
    ON topic_node(topic_id);

  CREATE INDEX IF NOT EXISTS topic_reference_node_key_idx
    ON topic_reference(node_key);

  CREATE INDEX IF NOT EXISTS topic_file_edge_from_to_idx
    ON topic_file_edge(from_key, to_key);")

(defun topic-files-topicmap-sql-label (value)
  (cond
    ((null value) nil)
    ((keywordp value) (string-downcase (symbol-name value)))
    ((symbolp value) (string-downcase (symbol-name value)))
    (t (format nil "~A" value))))

(defun topic-files-topicmap-sql (value)
  (example-source-sqlite-string-literal
   (topic-files-topicmap-sql-label value)))

(defun topic-files-topicmap-print-value (value)
  (when value
    (with-output-to-string (stream)
      (let ((*print-pretty* nil)
            (*print-circle* t)
            (*print-level* 5)
            (*print-length* 50))
        (prin1 value stream)))))

(defun topic-files-topicmap-safe-key-component (value)
  (let ((text (string-downcase (format nil "~A" (or value "value")))))
    (with-output-to-string (stream)
      (loop with wrote-separator = nil
            for char across text
            do (cond
                 ((or (alphanumericp char) (find char "-_./:" :test #'char=))
                  (write-char char stream)
                  (setf wrote-separator nil))
                 ((not wrote-separator)
                  (write-char #\- stream)
                  (setf wrote-separator t)))))))

(defun topic-source-file-key (file)
  (format nil "file:~A"
          (namestring (topic-source-file-pathname-of file))))

(defun topic-factory-source-record-key (record)
  (format nil "factory:~A:~D:~A"
          (namestring
           (topic-source-file-pathname-of
            (topic-factory-source-record-source-file-of record)))
          (topic-factory-source-record-form-index-of record)
          (topic-factory-source-record-label record)))

(defun topic-factory-source-record-node-key (record)
  (format nil "topic:~A"
          (topic-files-topicmap-safe-key-component
           (or (topic-factory-source-record-topic-id-of record)
               (topic-factory-source-record-topic-title-of record)
               (topic-factory-source-record-key record)))))

(defun topic-files-topicmap-edge-key (edge-type from-key to-key)
  (format nil "edge:~A:~A:~A"
          edge-type
          from-key
          to-key))

(defun topic-files-topicmap-insert-sql (table columns values)
  (format nil "INSERT OR REPLACE INTO ~A(~{~A~^, ~}) VALUES(~{~A~^, ~});~%"
          table
          columns
          values))

(defun topic-files-topicmap-materialization-sql (topicmap)
  (let ((parsed-at (topic-files-topicmap-now-string)))
    (with-output-to-string (stream)
      (format stream "BEGIN TRANSACTION;~%")
      (dolist (table '("topic_file_edge"
                       "topic_reference"
                       "topic_node"
                       "topic_factory"
                       "topic_source_file"))
        (format stream "DELETE FROM ~A;~%" table))
      (dolist (file (topic-files-topicmap-source-files-of topicmap))
        (let* ((source-key (topic-source-file-key file))
               (source-path (namestring (topic-source-file-pathname-of file))))
          (write-string
           (topic-files-topicmap-insert-sql
            "topic_source_file"
            '("path" "status" "form_count" "in_packages"
              "parse_failures" "parsed_at")
            (list (topic-files-topicmap-sql source-path)
                  (topic-files-topicmap-sql
                   (topic-source-file-status-of file))
                  (format nil "~D" (topic-source-file-form-count-of file))
                  (topic-files-topicmap-sql
                   (topic-files-topicmap-print-value
                    (topic-source-file-in-packages-of file)))
                  (topic-files-topicmap-sql
                   (topic-files-topicmap-print-value
                    (topic-source-file-parse-failures-of file)))
                  (topic-files-topicmap-sql parsed-at)))
           stream)
          (dolist (record (topic-source-file-factories-of file))
            (let* ((factory-key (topic-factory-source-record-key record))
                   (node-key (topic-factory-source-record-node-key record))
                   (topic-label (or (topic-factory-source-record-topic-title-of
                                     record)
                                    (topic-factory-source-record-topic-id-of
                                     record)
                                    node-key)))
              (write-string
               (topic-files-topicmap-insert-sql
                "topic_factory"
                '("factory_key" "source_path" "symbol_package"
                  "symbol_name" "form_index" "status" "topic_id"
                  "title" "summary" "reference_count"
                  "condition_message")
                (list (topic-files-topicmap-sql factory-key)
                      (topic-files-topicmap-sql source-path)
                      (topic-files-topicmap-sql
                       (topic-factory-source-record-package-name-of record))
                      (topic-files-topicmap-sql
                       (topic-factory-source-record-symbol-name-of record))
                      (format nil "~D"
                              (topic-factory-source-record-form-index-of
                               record))
                      (topic-files-topicmap-sql
                       (topic-factory-source-record-status-of record))
                      (topic-files-topicmap-sql
                       (topic-factory-source-record-topic-id-of record))
                      (topic-files-topicmap-sql
                       (topic-factory-source-record-topic-title-of record))
                      (topic-files-topicmap-sql
                       (topic-factory-source-record-topic-summary-of record))
                      (format nil "~D"
                              (length
                               (topic-factory-source-record-topic-references-of
                                record)))
                      (topic-files-topicmap-sql
                       (topic-factory-source-record-condition-message-of
                        record))))
                stream)
               (write-string
                (topic-files-topicmap-insert-sql
                 "topic_node"
                 '("node_key" "factory_key" "topic_id" "title"
                   "summary" "source_path" "status")
                 (list (topic-files-topicmap-sql node-key)
                       (topic-files-topicmap-sql factory-key)
                       (topic-files-topicmap-sql
                        (topic-factory-source-record-topic-id-of record))
                       (topic-files-topicmap-sql
                        (topic-factory-source-record-topic-title-of record))
                       (topic-files-topicmap-sql
                        (topic-factory-source-record-topic-summary-of record))
                       (topic-files-topicmap-sql source-path)
                       (topic-files-topicmap-sql
                        (topic-factory-source-record-status-of record))))
                 stream)
               (write-string
                (topic-files-topicmap-insert-sql
                 "topic_file_edge"
                 '("edge_key" "edge_type" "from_key" "from_label"
                   "to_key" "to_label" "source_path")
                 (list (topic-files-topicmap-sql
                        (topic-files-topicmap-edge-key
                         "contains-factory"
                         source-key
                         factory-key))
                       (topic-files-topicmap-sql "contains-factory")
                       (topic-files-topicmap-sql source-key)
                       (topic-files-topicmap-sql source-path)
                       (topic-files-topicmap-sql factory-key)
                       (topic-files-topicmap-sql
                        (topic-factory-source-record-label record))
                       (topic-files-topicmap-sql source-path)))
                 stream)
               (write-string
                (topic-files-topicmap-insert-sql
                 "topic_file_edge"
                 '("edge_key" "edge_type" "from_key" "from_label"
                   "to_key" "to_label" "source_path")
                 (list (topic-files-topicmap-sql
                        (topic-files-topicmap-edge-key
                         "constructs-topic"
                         factory-key
                         node-key))
                       (topic-files-topicmap-sql "constructs-topic")
                       (topic-files-topicmap-sql factory-key)
                       (topic-files-topicmap-sql
                        (topic-factory-source-record-label record))
                       (topic-files-topicmap-sql node-key)
                       (topic-files-topicmap-sql topic-label)
                       (topic-files-topicmap-sql source-path)))
                 stream)
               (loop for reference in
                     (topic-factory-source-record-topic-references-of record)
                     for index from 0
                     for reference-key =
                     (format nil "reference:~A:~D" node-key index)
                     do
                        (write-string
                         (topic-files-topicmap-insert-sql
                          "topic_reference"
                          '("reference_key" "node_key" "factory_key"
                            "reference_index" "reference_text" "source_path")
                          (list (topic-files-topicmap-sql reference-key)
                                (topic-files-topicmap-sql node-key)
                                (topic-files-topicmap-sql factory-key)
                                (format nil "~D" index)
                                (topic-files-topicmap-sql reference)
                                (topic-files-topicmap-sql source-path)))
                         stream)
                        (write-string
                         (topic-files-topicmap-insert-sql
                          "topic_file_edge"
                          '("edge_key" "edge_type" "from_key" "from_label"
                            "to_key" "to_label" "source_path")
                          (list (topic-files-topicmap-sql
                                 (topic-files-topicmap-edge-key
                                  "references"
                                  node-key
                                  reference-key))
                                (topic-files-topicmap-sql "references")
                                (topic-files-topicmap-sql node-key)
                                (topic-files-topicmap-sql topic-label)
                                (topic-files-topicmap-sql reference-key)
                                (topic-files-topicmap-sql reference)
                                (topic-files-topicmap-sql source-path)))
                         stream))))))
      (format stream "COMMIT;~%"))))

(defun ensure-topic-files-topicmap-sqlite-schema (topicmap)
  (topic-files-topicmap-sqlite-run
   topicmap
   (topic-files-topicmap-schema-sql)))

(defun materialize-topic-files-topicmap (topicmap)
  (dolist (file (topic-files-topicmap-source-files-of topicmap))
    (topic-files-topicmap-parse-source-file file))
  (multiple-value-bind (schema-output schema-status schema-detail)
      (ensure-topic-files-topicmap-sqlite-schema topicmap)
    (declare (ignore schema-output))
    (if (not (eq schema-status :ok))
        (setf (topic-files-topicmap-materialization-status-of topicmap)
              schema-status
              (topic-files-topicmap-materialization-detail-of topicmap)
              schema-detail)
        (multiple-value-bind (output status detail)
            (topic-files-topicmap-sqlite-run
             topicmap
             (topic-files-topicmap-materialization-sql topicmap))
          (declare (ignore output))
          (setf (topic-files-topicmap-materialization-status-of topicmap)
                status
                (topic-files-topicmap-materialization-detail-of topicmap)
                detail
                (topic-files-topicmap-materialized-at-of topicmap)
                (and (eq status :ok)
                     (topic-files-topicmap-now-string))))))
  topicmap)

(defun topic-files-topicmap-sqlite-lines (topicmap sql)
  (multiple-value-bind (output status detail)
      (topic-files-topicmap-sqlite-run topicmap sql :tabs t :noheader t)
    (unless (eq status :ok)
      (error "Could not query topic files topicmap SQLite store: ~A" detail))
    (remove "" (uiop:split-string (or output "") :separator '(#\Newline))
            :test #'string=)))

(defun topic-files-topicmap-split-row (line)
  (uiop:split-string line :separator '(#\Tab)))

(defun topic-files-topicmap-table-count (topicmap table)
  (let* ((line (first
                (topic-files-topicmap-sqlite-lines
                 topicmap
                 (format nil "SELECT count(*) FROM ~A;" table))))
         (trimmed (and line
                       (string-trim '(#\Space #\Tab #\Newline #\Return)
                                    line))))
    (and trimmed
         (parse-integer trimmed :junk-allowed t))))

(defun topic-files-topicmap-sqlite-table-counts (topicmap)
  (loop for table in '("topic_source_file"
                       "topic_factory"
                       "topic_node"
                       "topic_reference"
                       "topic_file_edge")
        collect (list :table table
                      :count (topic-files-topicmap-table-count
                              topicmap
                              table))))

(defun topic-files-topicmap-db-ready-p (topicmap)
  (and (uiop:file-exists-p (topic-files-topicmap-db-path-of topicmap))
       (eq (topic-files-topicmap-materialization-status-of topicmap) :ok)))

(defun topic-files-topicmap-ensure-payload-db (topicmap)
  (unless (topic-files-topicmap-db-ready-p topicmap)
    (materialize-topic-files-topicmap topicmap))
  (topic-files-topicmap-db-ready-p topicmap))

(defun topic-files-topicmap-payload-nodes-from-db (topicmap)
  (loop for line in
        (topic-files-topicmap-sqlite-lines
         topicmap
         "SELECT 'file:' || path,
                 path,
                 'file',
                 status,
                 path,
                 printf('%d top-level forms', form_count)
            FROM topic_source_file
           UNION ALL
          SELECT factory_key,
                 coalesce(symbol_package || '::', '') || symbol_name,
                 'factory',
                 status,
                 source_path,
                 coalesce(title, topic_id, '')
            FROM topic_factory
           UNION ALL
          SELECT node_key,
                 coalesce(title, topic_id, node_key),
                 'topic',
                 status,
                 source_path,
                 replace(replace(coalesce(summary, ''), char(10), ' '), char(9), ' ')
            FROM topic_node
           UNION ALL
          SELECT reference_key,
                 reference_text,
                 'reference',
                 'reference',
                 source_path,
                 ''
            FROM topic_reference
           ORDER BY 3, 2;")
        for row = (topic-files-topicmap-split-row line)
        collect (list :id (or (first row) "")
                      :label (or (second row) "")
                      :kind (or (third row) "")
                      :status (or (fourth row) "")
                      :source-path (or (fifth row) "")
                      :value (or (sixth row) ""))))

(defun topic-files-topicmap-payload-edges-from-db (topicmap)
  (loop for line in
        (topic-files-topicmap-sqlite-lines
         topicmap
         "SELECT edge_key,
                 edge_type,
                 from_key,
                 coalesce(from_label, ''),
                 to_key,
                 coalesce(to_label, ''),
                 source_path
            FROM topic_file_edge
           ORDER BY edge_type, from_label, to_label;")
        for row = (topic-files-topicmap-split-row line)
        collect (list :id (or (first row) "")
                      :label (or (second row) "")
                      :type-uri (or (second row) "")
                      :from (or (third row) "")
                      :from-label (or (fourth row) "")
                      :to (or (fifth row) "")
                      :to-label (or (sixth row) "")
                      :source-path (or (seventh row) ""))))

(defun topic-files-topicmap-payload (topicmap)
  (topic-files-topicmap-ensure-payload-db topicmap)
  (let ((nodes (topic-files-topicmap-payload-nodes-from-db topicmap))
        (edges (topic-files-topicmap-payload-edges-from-db topicmap)))
    (list :kind :topic-files-topicmap
          :title (topic-files-topicmap-title-of topicmap)
          :db-path (namestring (topic-files-topicmap-db-path-of topicmap))
          :summary (list :source-file-count
                         (length (topic-files-topicmap-source-files-of
                                  topicmap))
                         :node-count (length nodes)
                         :edge-count (length edges)
                         :materialization-status
                         (topic-files-topicmap-materialization-status-of
                          topicmap))
          :nodes nodes
          :edges edges)))

(defun topic-files-topicmap-keyword-from-kind (kind)
  (let ((text (string-trim '(#\Space #\Tab #\Newline #\Return)
                           (or kind ""))))
    (if (string= text "")
        :topic
        (intern (substitute #\- #\_ (string-upcase text)) :keyword))))

(defun topic-files-topicmap-projection-source-text (topicmap payload)
  (with-output-to-string (stream)
    (format stream "~A~%~%" (topic-files-topicmap-title-of topicmap))
    (format stream "DB: ~A~%" (getf payload :db-path))
    (format stream "Source files: ~D~%"
            (getf (getf payload :summary) :source-file-count))
    (format stream "Nodes: ~D~%" (length (getf payload :nodes)))
    (format stream "Edges: ~D~%" (length (getf payload :edges)))))

(defun topic-files-topicmap-projection-layout (nodes)
  (loop for node in nodes
        for index from 0
        for column = (mod index 4)
        for row = (floor index 4)
        collect (cons (getf node :id)
                      (list :x (+ 120 (* column 300))
                            :y (+ 110 (* row 120))))))

(defun topic-files-topicmap-projection (topicmap)
  (let* ((payload (topic-files-topicmap-payload topicmap))
         (nodes (getf payload :nodes))
         (edges (getf payload :edges))
         (source (source-content-from-object
                  topicmap
                  :title (topic-files-topicmap-title-of topicmap)
                  :text (topic-files-topicmap-projection-source-text
                         topicmap
                         payload))))
    (make-instance
     'topicmap-projection
     :source source
     :topics (loop for node in nodes
                   collect
                   (make-instance
                    'parsed-topic
                    :id (getf node :id)
                    :title (getf node :label)
                    :kind (topic-files-topicmap-keyword-from-kind
                           (getf node :kind))
                    :content (format nil "~A~%~A"
                                     (getf node :status)
                                     (getf node :value))
                    :source-target (getf node :source-path)
                    :source-index nil))
     :relations (loop for edge in edges
                      collect
                      (make-instance
                       'parsed-relation
                       :from (getf edge :from)
                       :to (getf edge :to)
                       :kind (topic-files-topicmap-keyword-from-kind
                              (getf edge :label))
                       :evidence (getf edge :source-path)))
     :layout (topic-files-topicmap-projection-layout nodes))))

(defmethod topicmap-projection-of ((topicmap topic-files-topicmap))
  (topic-files-topicmap-projection topicmap))

(defmethod topicmap-view-title-of ((topicmap topic-files-topicmap))
  (topic-files-topicmap-title-of topicmap))

(defmethod topicmap-view-input-owner-of ((topicmap topic-files-topicmap))
  (topic-files-topicmap-id-of topicmap))
