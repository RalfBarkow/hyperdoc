;;;; Durable example source artifacts.

(in-package :hyperdoc)

(defclass example-source-artifact ()
  ((source-id :initarg :source-id
              :reader example-source-artifact-source-id-of)
   (topic-id :initarg :topic-id :initform nil
             :reader example-source-artifact-topic-id-of)
   (topic-slug :initarg :topic-slug :initform nil
               :reader example-source-artifact-topic-slug-of)
   (topic-title :initarg :topic-title :initform nil
                :reader example-source-artifact-topic-title-of)
   (asdf-system-name :initarg :asdf-system-name :initform nil
                     :reader example-source-artifact-asdf-system-name-of)
   (fedwiki-page-identity :initarg :fedwiki-page-identity :initform nil
                          :reader example-source-artifact-fedwiki-page-identity-of)
   (function-symbol :initarg :function-symbol :initform nil
                    :reader example-source-artifact-function-symbol-of)
   (locator :initarg :locator :initform nil
            :reader example-source-artifact-locator-of)
   (source-language :initarg :source-language :initform :common-lisp
                    :reader example-source-artifact-source-language-of)
   (source-form-kind :initarg :source-form-kind :initform :defexample
                     :reader example-source-artifact-source-form-kind-of)
   (source-text :initarg :source-text :initform nil
                :reader example-source-artifact-source-text-of)
   (created-at :initarg :created-at :initform nil
               :reader example-source-artifact-created-at-of)
   (updated-at :initarg :updated-at :initform nil
               :reader example-source-artifact-updated-at-of)
   (provenance :initarg :provenance :initform :sly-mrepl
               :reader example-source-artifact-provenance-of)))

(defclass example-source-sqlite-store ()
  ((db-path :initarg :db-path
            :reader example-source-sqlite-store-db-path-of)
   (sqlite-program :initarg :sqlite-program :initform "sqlite3"
                   :reader example-source-sqlite-store-program-of)
   (schema-status :initarg :schema-status :initform :unknown
                  :accessor example-source-sqlite-store-schema-status-of)))

(defgeneric ensure-example-source-store-schema (store)
  (:documentation "Ensure STORE can persist example source artifacts."))

(defgeneric find-example-source-artifact (store source-id)
  (:documentation "Return a persisted example source artifact by SOURCE-ID."))

(defgeneric persist-example-source-artifact (store artifact)
  (:documentation "Persist ARTIFACT in STORE and return it."))

(defparameter *example-source-store* nil
  "Dynamically bindable example source artifact store.

When NIL, source-reference resolution uses the default SQLite-compatible store
under the user's cache directory.")

(defparameter *default-example-source-store* nil)

(defun example-source-now-string ()
  (multiple-value-bind (second minute hour day month year)
      (decode-universal-time (get-universal-time) 0)
    (format nil "~4,'0D-~2,'0D-~2,'0DT~2,'0D:~2,'0D:~2,'0DZ"
            year month day hour minute second)))

(defun example-source-blank-string-p (value)
  (or (null value)
      (and (stringp value)
           (zerop (length (string-trim '(#\Space #\Tab #\Newline #\Return)
                                       value))))))

(defun example-source-sqlite-string-literal (value)
  (if (null value)
      "NULL"
      (format nil "'~A'"
              (with-output-to-string (stream)
                (loop for char across (format nil "~A" value)
                      do (if (char= char #\')
                             (write-string "''" stream)
                             (write-char char stream)))))))

(defun example-source-keyword-value (value)
  (cond
    ((null value) nil)
    ((keywordp value) value)
    ((symbolp value) (intern (string-upcase (symbol-name value)) :keyword))
    ((stringp value)
     (let ((trimmed (string-trim '(#\Space #\Tab #\Newline #\Return) value)))
       (unless (zerop (length trimmed))
         (intern (substitute #\- #\_ (string-upcase trimmed)) :keyword))))
    (t value)))

(defun example-source-keyword-label (value)
  (cond
    ((null value) nil)
    ((keywordp value) (string-downcase (symbol-name value)))
    ((symbolp value) (string-downcase (symbol-name value)))
    (t (format nil "~A" value))))

(defun example-source-safe-id-component (value)
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

(defun example-source-symbol-label (symbol)
  (when symbol
    (let ((package (symbol-package symbol)))
      (if package
          (format nil "~A::~A" (package-name package) (symbol-name symbol))
          (symbol-name symbol)))))

(defun example-source-print-value (value)
  (when value
    (with-output-to-string (stream)
      (let ((*print-pretty* nil)
            (*print-circle* t))
        (prin1 value stream)))))

(defun example-source-plist-value (plist key)
  (and (listp plist)
       (getf plist key)))

(defun example-entry-source-property (entry key)
  (or (example-source-plist-value (example-entry-locator-of entry) key)
      (example-source-plist-value (example-entry-tags-of entry) key)))

(defun example-entry-source-id (entry)
  (or (example-entry-source-property entry :source-id)
      (format nil "example-source:~A:~A"
              (example-source-safe-id-component
               (example-entry-system-of entry))
              (example-source-safe-id-component
               (example-entry-id-of entry)))))

(defun example-entry-supplied-source-text (entry)
  (example-entry-source-property entry :source-text))

(defun example-entry-topic-id (entry)
  (example-entry-source-property entry :topic-id))

(defun example-entry-topic-slug (entry)
  (example-entry-source-property entry :topic-slug))

(defun example-entry-topic-title (entry)
  (or (example-entry-source-property entry :topic-title)
      (example-entry-source-page-of entry)))

(defun example-entry-fedwiki-page-identity (entry)
  (or (example-entry-source-property entry :fedwiki-page-identity)
      (example-entry-source-property entry :fedwiki-page)))

(defun example-entry-source-language (entry)
  (or (example-source-keyword-value
       (example-entry-source-property entry :source-language))
      :common-lisp))

(defun example-entry-source-form-kind (entry)
  (or (example-source-keyword-value
       (example-entry-source-property entry :source-form-kind))
      :defexample))

(defun example-entry-source-provenance (entry)
  (or (example-source-keyword-value
       (example-entry-source-property entry :provenance))
      :sly-mrepl))

(defun make-example-source-artifact-from-entry
    (entry source-text &key created-at updated-at)
  (make-instance 'example-source-artifact
                 :source-id (example-entry-source-id entry)
                 :topic-id (example-entry-topic-id entry)
                 :topic-slug (example-entry-topic-slug entry)
                 :topic-title (example-entry-topic-title entry)
                 :asdf-system-name (example-entry-system-of entry)
                 :fedwiki-page-identity
                 (example-entry-fedwiki-page-identity entry)
                 :function-symbol
                 (example-source-symbol-label
                  (example-entry-function-of entry))
                 :locator (example-source-print-value
                           (example-entry-locator-of entry))
                 :source-language (example-entry-source-language entry)
                 :source-form-kind (example-entry-source-form-kind entry)
                 :source-text source-text
                 :created-at (or created-at (example-source-now-string))
                 :updated-at (or updated-at (example-source-now-string))
                 :provenance (example-entry-source-provenance entry)))

(defun default-example-source-sqlite-path ()
  (merge-pathnames #P"hyperdoc/example-source-artifacts.sqlite"
                   (merge-pathnames #P".cache/" (user-homedir-pathname))))

(defun make-example-source-sqlite-store
    (&key (db-path (default-example-source-sqlite-path))
       (sqlite-program "sqlite3"))
  (make-instance 'example-source-sqlite-store
                 :db-path (etypecase db-path
                            (pathname db-path)
                            (string (pathname db-path)))
                 :sqlite-program sqlite-program
                 :schema-status :unknown))

(defun default-example-source-store ()
  (or *default-example-source-store*
      (setf *default-example-source-store*
            (make-example-source-sqlite-store))))

(defun current-example-source-store ()
  (or *example-source-store*
      (default-example-source-store)))

(defun example-source-sqlite-available-p (&key (sqlite-program "sqlite3"))
  (and (not (example-source-blank-string-p sqlite-program))
       (handler-case
           (multiple-value-bind (output error-output exit-code)
               (uiop:run-program (list sqlite-program "--version")
                                 :output :string
                                 :error-output :string
                                 :ignore-error-status t)
             (declare (ignore output error-output))
             (zerop exit-code))
         (error () nil))))

(defun example-source-sqlite-run (store sql &key json-p)
  (let* ((sqlite-program (example-source-sqlite-store-program-of store))
         (db-path (example-source-sqlite-store-db-path-of store))
         (parent (and db-path
                      (uiop:pathname-directory-pathname db-path))))
    (cond
      ((null db-path)
       (values nil :configuration-error "No SQLite database path configured."))
      ((not (example-source-sqlite-available-p
             :sqlite-program sqlite-program))
       (values nil :backend-unavailable
               (format nil "The sqlite3 command is unavailable: ~A"
                       sqlite-program)))
      (t
       (when parent
         (ensure-directories-exist parent))
       (handler-case
           (multiple-value-bind (output error-output exit-code)
               (uiop:run-program (append (list sqlite-program)
                                         (when json-p (list "-json"))
                                         (list (namestring db-path) sql))
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
         (error (condition)
           (values nil :error (princ-to-string condition))))))))

(defun example-source-sqlite-schema-sql ()
  "CREATE TABLE IF NOT EXISTS example_source_artifacts(
    source_id text primary key,
    topic_id text,
    topic_slug text,
    topic_title text,
    asdf_system_name text,
    fedwiki_page_identity text,
    function_symbol text,
    locator text,
    source_language text,
    source_form_kind text,
    source_text text not null,
    created_at text not null,
    updated_at text not null,
    provenance text
  );

  CREATE INDEX IF NOT EXISTS example_source_artifacts_topic_slug_idx
    ON example_source_artifacts(topic_slug);

  CREATE INDEX IF NOT EXISTS example_source_artifacts_function_symbol_idx
    ON example_source_artifacts(function_symbol);")

(defmethod ensure-example-source-store-schema
    ((store example-source-sqlite-store))
  (multiple-value-bind (output status detail)
      (example-source-sqlite-run store (example-source-sqlite-schema-sql))
    (declare (ignore output))
    (if (eq status :ok)
        (progn
          (setf (example-source-sqlite-store-schema-status-of store) :ready)
          (values store :ok nil))
        (progn
          (setf (example-source-sqlite-store-schema-status-of store) status)
          (values nil status detail)))))

(defun example-source-seq-list (value)
  (cond
    ((null value) nil)
    ((vectorp value) (coerce value 'list))
    ((listp value) value)
    (t (list value))))

(defun example-source-parse-json-list (string)
  (if (or (null string)
          (zerop (length (string-trim '(#\Space #\Tab #\Newline #\Return)
                                      string))))
      nil
      (example-source-seq-list (shasht:read-json string))))

(defun example-source-row-value (row key)
  (cond
    ((hash-table-p row)
     (multiple-value-bind (value present-p)
         (gethash key row)
       (and present-p value)))
    ((and (listp row) (assoc key row :test #'string=))
     (cdr (assoc key row :test #'string=)))
    ((listp row)
     (getf row (intern (string-upcase key) :keyword)))
    (t nil)))

(defun example-source-artifact-from-row (row)
  (make-instance 'example-source-artifact
                 :source-id (example-source-row-value row "source_id")
                 :topic-id (example-source-row-value row "topic_id")
                 :topic-slug (example-source-row-value row "topic_slug")
                 :topic-title (example-source-row-value row "topic_title")
                 :asdf-system-name
                 (example-source-row-value row "asdf_system_name")
                 :fedwiki-page-identity
                 (example-source-row-value row "fedwiki_page_identity")
                 :function-symbol
                 (example-source-row-value row "function_symbol")
                 :locator (example-source-row-value row "locator")
                 :source-language
                 (example-source-keyword-value
                  (example-source-row-value row "source_language"))
                 :source-form-kind
                 (example-source-keyword-value
                  (example-source-row-value row "source_form_kind"))
                 :source-text (example-source-row-value row "source_text")
                 :created-at (example-source-row-value row "created_at")
                 :updated-at (example-source-row-value row "updated_at")
                 :provenance
                 (example-source-keyword-value
                  (example-source-row-value row "provenance"))))

(defmethod find-example-source-artifact
    ((store example-source-sqlite-store) source-id)
  (multiple-value-bind (schema schema-status schema-detail)
      (ensure-example-source-store-schema store)
    (declare (ignore schema))
    (if (eq schema-status :ok)
        (multiple-value-bind (output status detail)
            (example-source-sqlite-run
             store
             (format nil
                     "SELECT * FROM example_source_artifacts
                      WHERE source_id = ~A
                      LIMIT 1;"
                     (example-source-sqlite-string-literal source-id))
             :json-p t)
          (if (eq status :ok)
              (let ((row (first (example-source-parse-json-list output))))
                (if row
                    (values (example-source-artifact-from-row row) :ok nil)
                    (values nil :not-found nil)))
              (values nil status detail)))
        (values nil schema-status schema-detail))))

(defun example-source-upsert-artifact-sql (artifact)
  (let* ((source-id (example-source-artifact-source-id-of artifact))
         (now (or (example-source-artifact-updated-at-of artifact)
                  (example-source-now-string))))
    (format nil
            "INSERT INTO example_source_artifacts(
               source_id, topic_id, topic_slug, topic_title, asdf_system_name,
               fedwiki_page_identity, function_symbol, locator, source_language,
               source_form_kind, source_text, created_at, updated_at, provenance)
             VALUES(~A, ~A, ~A, ~A, ~A, ~A, ~A, ~A, ~A, ~A, ~A,
                    COALESCE((SELECT created_at FROM example_source_artifacts
                              WHERE source_id = ~A), ~A),
                    ~A, ~A)
             ON CONFLICT(source_id) DO UPDATE SET
               topic_id = excluded.topic_id,
               topic_slug = excluded.topic_slug,
               topic_title = excluded.topic_title,
               asdf_system_name = excluded.asdf_system_name,
               fedwiki_page_identity = excluded.fedwiki_page_identity,
               function_symbol = excluded.function_symbol,
               locator = excluded.locator,
               source_language = excluded.source_language,
               source_form_kind = excluded.source_form_kind,
               source_text = excluded.source_text,
               updated_at = excluded.updated_at,
               provenance = excluded.provenance;"
            (example-source-sqlite-string-literal source-id)
            (example-source-sqlite-string-literal
             (example-source-artifact-topic-id-of artifact))
            (example-source-sqlite-string-literal
             (example-source-artifact-topic-slug-of artifact))
            (example-source-sqlite-string-literal
             (example-source-artifact-topic-title-of artifact))
            (example-source-sqlite-string-literal
             (example-source-artifact-asdf-system-name-of artifact))
            (example-source-sqlite-string-literal
             (example-source-artifact-fedwiki-page-identity-of artifact))
            (example-source-sqlite-string-literal
             (example-source-artifact-function-symbol-of artifact))
            (example-source-sqlite-string-literal
             (example-source-artifact-locator-of artifact))
            (example-source-sqlite-string-literal
             (example-source-keyword-label
              (example-source-artifact-source-language-of artifact)))
            (example-source-sqlite-string-literal
             (example-source-keyword-label
              (example-source-artifact-source-form-kind-of artifact)))
            (example-source-sqlite-string-literal
             (example-source-artifact-source-text-of artifact))
            (example-source-sqlite-string-literal source-id)
            (example-source-sqlite-string-literal
             (or (example-source-artifact-created-at-of artifact) now))
            (example-source-sqlite-string-literal now)
            (example-source-sqlite-string-literal
             (example-source-keyword-label
              (example-source-artifact-provenance-of artifact))))))

(defmethod persist-example-source-artifact
    ((store example-source-sqlite-store) (artifact example-source-artifact))
  (multiple-value-bind (schema schema-status schema-detail)
      (ensure-example-source-store-schema store)
    (declare (ignore schema))
    (if (eq schema-status :ok)
        (multiple-value-bind (output status detail)
            (example-source-sqlite-run
             store
             (example-source-upsert-artifact-sql artifact))
          (declare (ignore output))
          (if (eq status :ok)
              (find-example-source-artifact
               store
               (example-source-artifact-source-id-of artifact))
              (values artifact status detail)))
        (values artifact schema-status schema-detail))))

(defun example-source-file-present-p (source-file)
  (when source-file
    (let ((pathname (pathname source-file)))
      (and (probe-file pathname) pathname))))

(defun resolve-example-source-artifact (entry store)
  (let* ((source-id (example-entry-source-id entry))
         (source-text (example-entry-supplied-source-text entry)))
    (multiple-value-bind (artifact status detail)
        (find-example-source-artifact store source-id)
      (cond
        (artifact
         (values artifact :ok nil))
        ((and (eq status :not-found)
              (not (example-source-blank-string-p source-text)))
         (persist-example-source-artifact
          store
          (make-example-source-artifact-from-entry entry source-text)))
        ((eq status :not-found)
         (values nil :not-found nil))
        (t
         (values nil status detail))))))

(defun resolve-example-source-reference (entry)
  "Resolve ENTRY to :FILE, :TOPIC, or :UNAVAILABLE source metadata.

Resolution order:
1. present source file;
2. persisted topic source artifact;
3. supplied source text, persisted into the source artifact store;
4. explicit unavailable diagnostic."
  (let ((source-file (example-entry-source-file-of entry)))
    (cond
      ((example-source-file-present-p source-file)
       (values :file nil nil))
      (t
       (let ((store (current-example-source-store)))
         (multiple-value-bind (artifact status detail)
             (resolve-example-source-artifact entry store)
             (cond
             (artifact
              (values :topic artifact nil))
             ((eq status :not-found)
              (values :unavailable nil
                      (cond
                        (source-file "source file missing")
                        ((example-entry-function-of entry)
                         "SLY MREPL / source unavailable")
                        (t "source unavailable"))))
             (t
              (values :unavailable nil
                      (or detail
                          (format nil "source store unavailable: ~A"
                                  status)))))))))))

(defun make-example-source-reference (entry)
  (multiple-value-bind (source-kind artifact diagnostic)
      (resolve-example-source-reference entry)
    (make-instance 'example-source-reference
                   :entry entry
                   :function (example-entry-function-of entry)
                   :locator (example-entry-locator-of entry)
                   :source-file (example-entry-source-file-of entry)
                   :source-page (example-entry-source-page-of entry)
                   :tags (example-entry-tags-of entry)
                   :source-kind source-kind
                   :source-artifact artifact
                   :diagnostic diagnostic)))

(defparameter *example-source-artifact-inspector-contract-source-id*
  "example-source:topic-982311:source-artifact-inspector-contract")

(defun example-source-artifact-inspector-contract-source-text ()
  "(hyperdoc:defexample example-source-artifact-inspector-contract-example (:register nil) :topic-backed-ok)")

(defun example-source-artifact-inspector-contract-example ()
  :topic-backed-ok)

(defun make-example-source-artifact-inspector-contract-entry ()
  (let ((source-text (example-source-artifact-inspector-contract-source-text)))
    (make-instance 'example-entry
                   :system "hyperdoc"
                   :id "example:source-artifact-inspector-contract"
                   :title "Example source artifact inspector contract"
                   :function 'example-source-artifact-inspector-contract-example
                   :locator
                   (list
                    :function
                    'example-source-artifact-inspector-contract-example
                    :source-id
                    *example-source-artifact-inspector-contract-source-id*
                    :topic-id "982311"
                    :topic-slug "example-source-artifact-inspector-contract"
                    :topic-title
                    "Example source artifact inspector contract"
                    :fedwiki-page-identity
                    "example-source-artifact-inspector-contract"
                    :source-language :common-lisp
                    :source-form-kind :defexample
                    :provenance :fedwiki-topic
                    :source-text source-text)
                   :package "HYPERDOC"
                   :source-page "Example source artifact inspector contract"
                   :tags (list :topic-id "982311"
                               :source-text source-text)
                   :class-or-group "source artifact")))

(defun make-example-source-artifact-inspector-contract-reference ()
  (make-example-source-reference
   (make-example-source-artifact-inspector-contract-entry)))

(defun make-example-source-artifact-inspector-contract-artifact ()
  (example-source-reference-source-artifact-of
   (make-example-source-artifact-inspector-contract-reference)))

(defun make-example-source-artifact-inspector-contract-result ()
  (run-example-entry
   (make-example-source-artifact-inspector-contract-entry)))

(defmethod title-of ((artifact example-source-artifact))
  (or (example-source-artifact-topic-title-of artifact)
      (example-source-artifact-source-id-of artifact)))

(defmethod summary-of ((artifact example-source-artifact))
  (format nil "~A source artifact for ~A"
          (example-source-keyword-label
           (example-source-artifact-source-language-of artifact))
          (or (example-source-artifact-function-symbol-of artifact)
              (example-source-artifact-topic-slug-of artifact)
              (example-source-artifact-source-id-of artifact))))

(defmethod source-text-of ((artifact example-source-artifact))
  (example-source-artifact-source-text-of artifact))

(defmethod source-title-of ((artifact example-source-artifact))
  (title-of artifact))

(defmethod source-target-of ((artifact example-source-artifact))
  artifact)

(defmethod print-object ((artifact example-source-artifact) stream)
  (print-unreadable-object (artifact stream :type t :identity nil)
    (format stream "~A"
            (example-source-artifact-source-id-of artifact))))

(defmethod print-object ((store example-source-sqlite-store) stream)
  (print-unreadable-object (store stream :type t :identity nil)
    (format stream "~A ~A"
            (example-source-sqlite-store-schema-status-of store)
            (example-source-sqlite-store-db-path-of store))))
