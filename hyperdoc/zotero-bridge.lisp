;;;; Read-only Zotero title resolution bridge for HyperDoc
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defparameter *zotero-default-sqlite-program* "sqlite3")
(defparameter *zotero-note-file-extensions*
  '("md" "markdown" "org" "txt" "text" "rst" "adoc"))

(defclass zotero-library ()
  ((db-path :reader zotero-db-path-of :initarg :db-path)
   (storage-root :reader zotero-storage-root-of :initarg :storage-root)
   (note-roots :reader zotero-note-roots-of :initarg :note-roots :initform nil)
   (sqlite-program :reader zotero-sqlite-program-of
                   :initarg :sqlite-program
                   :initform *zotero-default-sqlite-program*)))

(defclass zotero-library-bridge (zotero-library) ())

(defclass zotero-query-attempt ()
  ((access-mode :reader zotero-query-attempt-access-mode-of
                :initarg :access-mode)
   (command :reader zotero-query-attempt-command-of
            :initarg :command
            :initform nil)
   (status :reader zotero-query-attempt-status-of
           :initarg :status)
   (rows :reader zotero-query-attempt-rows-of
         :initarg :rows
         :initform nil)
   (detail :reader zotero-query-attempt-detail-of
           :initarg :detail
           :initform nil)
   (exit-code :reader zotero-query-attempt-exit-code-of
              :initarg :exit-code
              :initform nil)))

(defclass zotero-query-missing-attempt ()
  ((query :reader zotero-query-missing-attempt-query-of
          :initarg :query
          :initform nil)
   (attempted-operation :reader zotero-query-missing-attempt-operation-of
                        :initarg :attempted-operation
                        :initform nil)
   (receiver :reader zotero-query-missing-attempt-receiver-of
             :initarg :receiver
             :initform nil)
   (arguments :reader zotero-query-missing-attempt-arguments-of
              :initarg :arguments
              :initform nil)
   (higher-level-intent :reader zotero-query-missing-attempt-intent-of
                        :initarg :higher-level-intent
                        :initform nil)
   (status :reader zotero-query-missing-attempt-status-of
           :initarg :status
           :initform :missing)
   (detail :reader zotero-query-missing-attempt-detail-of
           :initarg :detail
           :initform nil)
   (repair-hint :reader zotero-query-missing-attempt-repair-hint-of
                :initarg :repair-hint
                :initform nil)))

(defclass zotero-query-evidence ()
  ((name :reader zotero-query-name-of :initarg :name)
   (sql :reader zotero-query-sql-of :initarg :sql)
   (attempts :reader zotero-query-attempts-of :initarg :attempts :initform nil)
   (selected-attempt :reader zotero-query-selected-attempt-of
                     :initarg :selected-attempt
                     :initform nil)))

(defclass zotero-title-query (zotero-query-evidence)
  ((bridge :reader zotero-title-query-bridge-of :initarg :bridge)
   (query-text :reader zotero-title-query-text-of :initarg :query-text)
   (match-mode :reader zotero-title-query-match-mode-of :initarg :match-mode)
   (matched-items :reader zotero-title-query-matched-items-of
                  :initarg :matched-items
                  :initform nil)))

(defclass zotero-item-id-query (zotero-query-evidence)
  ((bridge :reader zotero-item-id-query-bridge-of :initarg :bridge)
   (item-id :reader zotero-item-id-query-item-id-of :initarg :item-id)
   (matched-item :reader zotero-item-id-query-matched-item-of
                 :initarg :matched-item
                 :initform nil)))

(defclass zotero-recent-changes-query (zotero-query-evidence)
  ((bridge :reader zotero-recent-changes-query-bridge-of :initarg :bridge)
   (limit :reader zotero-recent-changes-query-limit-of :initarg :limit)
   (since :reader zotero-recent-changes-query-since-of
          :initarg :since
          :initform nil)
   (include-attachments-p
    :reader zotero-recent-changes-query-include-attachments-p
    :initarg :include-attachments-p
    :initform nil)
   (change-timestamp-field
    :reader zotero-recent-changes-query-change-timestamp-field-of
    :initarg :change-timestamp-field
    :initform "items.dateModified")
   (recent-items :reader zotero-recent-changes-query-recent-items-of
                 :initarg :recent-items
                 :initform nil)))

(defclass zotero-item-hit ()
  ((item-id :reader zotero-item-id-of :initarg :item-id)
   (item-key :reader zotero-item-key-of :initarg :item-key)
   (item-type :reader zotero-item-type-of :initarg :item-type)
   (title :reader zotero-item-title-of :initarg :title)
   (doi :reader zotero-item-doi-of :initarg :doi :initform nil)
   (citation-key :reader zotero-item-citation-key-of
                 :initarg :citation-key
                 :initform nil)
   (date :reader zotero-item-date-of :initarg :date :initform nil)
   (raw-row :reader zotero-item-raw-row-of :initarg :raw-row)
   (attachments :accessor zotero-item-attachments-of
                :initarg :attachments
                :initform nil)))

(defclass zotero-recent-change-hit (zotero-item-hit)
  ((change-timestamp-field
    :reader zotero-recent-change-hit-change-timestamp-field-of
    :initarg :change-timestamp-field
    :initform "items.dateModified")
   (change-timestamp :reader zotero-recent-change-hit-change-timestamp-of
                     :initarg :change-timestamp
                     :initform nil)
   (evidence-path :reader zotero-recent-change-hit-evidence-path-of
                  :initarg :evidence-path
                  :initform nil)
   (date-added :reader zotero-recent-change-hit-date-added-of
               :initarg :date-added
               :initform nil)
   (item-date-modified
    :reader zotero-recent-change-hit-item-date-modified-of
    :initarg :item-date-modified
    :initform nil)
   (client-date-modified
    :reader zotero-recent-change-hit-client-date-modified-of
    :initarg :client-date-modified
    :initform nil)
   (parent-item-id :reader zotero-recent-change-hit-parent-item-id-of
                   :initarg :parent-item-id
                   :initform nil)
   (attachment-path :reader zotero-recent-change-hit-attachment-path-of
                    :initarg :attachment-path
                    :initform nil)
   (attachment-storage-mod-time
    :reader zotero-recent-change-hit-attachment-storage-mod-time-of
    :initarg :attachment-storage-mod-time
    :initform nil)
   (attachment-last-processed-modification-time
    :reader zotero-recent-change-hit-attachment-last-processed-modification-time-of
    :initarg :attachment-last-processed-modification-time
    :initform nil)))

(defclass zotero-bibliographic-item (zotero-item-hit) ())

(defclass zotero-attachment-hit ()
  ((attachment-item-id :reader zotero-attachment-item-id-of
                       :initarg :attachment-item-id)
   (parent-item-id :reader zotero-attachment-parent-item-id-of
                   :initarg :parent-item-id)
   (attachment-key :reader zotero-attachment-key-of :initarg :attachment-key)
   (attachment-type :reader zotero-attachment-type-of :initarg :attachment-type)
   (link-mode :reader zotero-attachment-link-mode-of :initarg :link-mode)
   (content-type :reader zotero-attachment-content-type-of
                 :initarg :content-type
                 :initform nil)
   (raw-path :reader zotero-attachment-raw-path-of
             :initarg :raw-path
             :initform nil)
   (attachment-title :reader zotero-attachment-title-of
                     :initarg :attachment-title
                     :initform nil)
   (normalized-kind :reader zotero-attachment-normalized-kind-of
                    :initarg :normalized-kind)
   (filename :reader zotero-attachment-filename-of
             :initarg :filename
             :initform nil)
   (raw-row :reader zotero-attachment-raw-row-of :initarg :raw-row)))

(defclass zotero-attachment (zotero-attachment-hit) ())

(defclass zotero-path-resolution-report ()
  ((bridge :reader zotero-path-report-bridge-of
           :reader zotero-attachment-resolution-bridge-of
           :initarg :bridge)
   (item-hit :reader zotero-path-report-item-hit-of
             :initarg :item-hit
             :initform nil)
   (attachment-hit :reader zotero-path-report-attachment-hit-of
                   :reader zotero-attachment-resolution-attachment-of
                   :initarg :attachment-hit
                   :initarg :attachment)
   (attachment-mode :reader zotero-path-report-attachment-mode-of
                    :initarg :attachment-mode
                    :initform nil)
   (attachment-key :reader zotero-path-report-attachment-key-of
                   :initarg :attachment-key
                   :initform nil)
   (storage-relative-path :reader zotero-path-report-storage-relative-path-of
                          :initarg :storage-relative-path
                          :initform nil)
   (resolved-path :reader zotero-path-report-resolved-path-of
                  :reader zotero-attachment-resolution-path-of
                  :initarg :resolved-path
                  :initform nil)
   (exists-p :reader zotero-path-report-exists-p
             :reader zotero-attachment-resolution-exists-p
             :initarg :exists-p
             :initform nil)
   (failure-mode :reader zotero-path-report-failure-mode-of
                 :reader zotero-attachment-resolution-failure-mode-of
                 :initarg :failure-mode
                 :initform nil)
   (detail :reader zotero-path-report-detail-of
           :reader zotero-attachment-resolution-detail-of
           :initarg :detail
           :initform nil)))

(defclass zotero-attachment-path-resolution (zotero-path-resolution-report) ())

(defclass zotero-note-clue-match ()
  ((kind :reader zotero-note-clue-kind-of :initarg :kind)
   (value :reader zotero-note-clue-value-of :initarg :value)
   (line-number :reader zotero-note-clue-line-number-of :initarg :line-number)
   (line-text :reader zotero-note-clue-line-text-of :initarg :line-text)
   (item-id :reader zotero-note-clue-item-id-of
            :initarg :item-id
            :initform nil)
   (attachment-item-id :reader zotero-note-clue-attachment-item-id-of
                       :initarg :attachment-item-id
                       :initform nil)))

(defclass zotero-note-evidence ()
  ((note-path :reader zotero-note-evidence-note-path-of :initarg :note-path)
   (root :reader zotero-note-evidence-root-of :initarg :root :initform nil)
   (matches :reader zotero-note-evidence-matches-of
            :initarg :matches
            :initform nil)))

(defclass zotero-resolution-evidence ()
  ((item-hit :reader zotero-resolution-evidence-item-hit-of
             :initarg :item-hit
             :initform nil)
   (attachment-hit :reader zotero-resolution-evidence-attachment-hit-of
                   :initarg :attachment-hit
                   :initform nil)
   (path-report :reader zotero-resolution-evidence-path-report-of
                :initarg :path-report
                :initform nil)
   (attachment-mode :reader zotero-resolution-evidence-attachment-mode-of
                    :initarg :attachment-mode
                    :initform nil)
   (attachment-key :reader zotero-resolution-evidence-attachment-key-of
                   :initarg :attachment-key
                   :initform nil)
   (storage-relative-path
    :reader zotero-resolution-evidence-storage-relative-path-of
    :initarg :storage-relative-path
    :initform nil)
   (resolved-path :reader zotero-resolution-evidence-resolved-path-of
                  :initarg :resolved-path
                  :initform nil)
   (exists-p :reader zotero-resolution-evidence-exists-p
             :initarg :exists-p
             :initform nil)
   (note-evidence :reader zotero-resolution-evidence-note-evidence-of
                  :initarg :note-evidence
                  :initform nil)
   (failure-mode :reader zotero-resolution-evidence-failure-mode-of
                 :initarg :failure-mode
                 :initform nil)
   (detail :reader zotero-resolution-evidence-detail-of
           :initarg :detail
           :initform nil)))

(defclass zotero-title-resolution-report ()
  ((bridge :reader zotero-report-bridge-of :initarg :bridge)
   (query-title :reader zotero-report-query-title-of :initarg :query-title)
   (item-query :reader zotero-report-item-query-of
               :reader zotero-report-title-query-of
               :initarg :item-query)
   (attachment-query :reader zotero-report-attachment-query-of
                     :initarg :attachment-query
                     :initform nil)
   (item-candidates :reader zotero-report-item-candidates-of
                    :initarg :item-candidates
                    :initform nil)
   (attachment-candidates :reader zotero-report-attachment-candidates-of
                          :initarg :attachment-candidates
                          :initform nil)
   (attachment-resolutions :reader zotero-report-attachment-resolutions-of
                           :initarg :attachment-resolutions
                           :initform nil)
   (candidate-evidence :reader zotero-report-candidate-evidence-of
                       :initarg :candidate-evidence
                       :initform nil)
   (note-evidence :reader zotero-report-note-evidence-of
                  :initarg :note-evidence
                  :initform nil)
   (note-search-status :reader zotero-report-note-search-status-of
                       :initarg :note-search-status
                       :initform :disabled)
   (note-files-searched :reader zotero-report-note-files-searched-of
                        :initarg :note-files-searched
                        :initform 0)
   (selected-item :reader zotero-report-selected-item-of
                  :initarg :selected-item
                  :initform nil)
   (selected-attachment :reader zotero-report-selected-attachment-of
                        :initarg :selected-attachment
                        :initform nil)
   (selected-resolution :reader zotero-report-selected-resolution-of
                        :initarg :selected-resolution
                        :initform nil)
   (selected-evidence :reader zotero-report-selected-evidence-of
                      :initarg :selected-evidence
                      :initform nil)
   (evidence-chain :reader zotero-report-evidence-chain-of
                   :initarg :evidence-chain
                   :initform nil)
   (resolved-path :reader zotero-report-resolved-path-of
                  :initarg :resolved-path
                  :initform nil)
   (exists-p :reader zotero-report-exists-p :initarg :exists-p :initform nil)
   (status :reader zotero-report-status-of :initarg :status)
   (failure-mode :reader zotero-report-failure-mode-of
                 :initarg :failure-mode
                 :initform nil)
   (detail :reader zotero-report-detail-of :initarg :detail :initform nil)))

(defmethod print-object ((object zotero-library) stream)
  (print-unreadable-object (object stream :type t :identity t)
    (format stream "~A -> ~A"
            (or (and (zotero-db-path-of object)
                     (pathname-namestring-or-nil (zotero-db-path-of object)))
                "<no db>")
            (or (and (zotero-storage-root-of object)
                     (pathname-namestring-or-nil
                      (zotero-storage-root-of object)))
                "<no storage>"))))

(defmethod print-object ((object zotero-query-evidence) stream)
  (print-unreadable-object (object stream :type t :identity t)
    (format stream "~A ~A"
            (zotero-query-name-of object)
            (if (zotero-query-selected-attempt-of object)
                (zotero-query-attempt-access-mode-of
                 (zotero-query-selected-attempt-of object))
                :error))))

(defmethod print-object ((object zotero-query-missing-attempt) stream)
  (print-unreadable-object (object stream :type t :identity t)
    (format stream "~A ~A"
            (or (zotero-query-missing-attempt-operation-of object)
                :missing-operation)
            (or (zotero-query-missing-attempt-status-of object)
                :missing))))

(defmethod print-object ((object zotero-title-query) stream)
  (print-unreadable-object (object stream :type t :identity t)
    (format stream "~A ~A (~A)"
            (zotero-title-query-match-mode-of object)
            (zotero-title-query-text-of object)
            (length (zotero-title-query-matched-items-of object)))))

(defmethod print-object ((object zotero-recent-changes-query) stream)
  (print-unreadable-object (object stream :type t :identity t)
    (format stream "~A (~D hits)"
            (zotero-recent-changes-query-change-timestamp-field-of object)
            (length (zotero-recent-changes-query-recent-items-of object)))))

(defmethod print-object ((object zotero-item-hit) stream)
  (print-unreadable-object (object stream :type t :identity t)
    (format stream "~A ~A"
            (zotero-item-id-of object)
            (zotero-item-title-of object))))

(defmethod print-object ((object zotero-recent-change-hit) stream)
  (print-unreadable-object (object stream :type t :identity t)
    (format stream "~A ~A"
            (zotero-item-id-of object)
            (or (zotero-recent-change-hit-change-timestamp-of object)
                "<no timestamp>"))))

(defmethod print-object ((object zotero-attachment-hit) stream)
  (print-unreadable-object (object stream :type t :identity t)
    (format stream "~A ~A"
            (zotero-attachment-item-id-of object)
            (or (zotero-attachment-filename-of object)
                (zotero-attachment-raw-path-of object)
                "<no path>"))))

(defmethod print-object ((object zotero-path-resolution-report) stream)
  (print-unreadable-object (object stream :type t :identity t)
    (format stream "~A ~A"
            (or (zotero-path-report-failure-mode-of object)
                :resolved)
            (or (and (zotero-path-report-resolved-path-of object)
                     (pathname-namestring-or-nil
                      (zotero-path-report-resolved-path-of object)))
                "<no path>"))))

(defmethod print-object ((object zotero-note-evidence) stream)
  (print-unreadable-object (object stream :type t :identity t)
    (format stream "~A (~D matches)"
            (pathname-namestring-or-nil
             (zotero-note-evidence-note-path-of object))
            (length (zotero-note-evidence-matches-of object)))))

(defmethod print-object ((object zotero-resolution-evidence) stream)
  (print-unreadable-object (object stream :type t :identity t)
    (format stream "~A ~A"
            (or (zotero-resolution-evidence-attachment-key-of object)
                "<no attachment key>")
            (or (and (zotero-resolution-evidence-resolved-path-of object)
                     (pathname-namestring-or-nil
                      (zotero-resolution-evidence-resolved-path-of object)))
                "<no path>"))))

(defmethod print-object ((object zotero-title-resolution-report) stream)
  (print-unreadable-object (object stream :type t :identity t)
    (format stream "~A ~A"
            (zotero-report-status-of object)
            (zotero-report-query-title-of object))))

(defun zotero-blank-string-p (value)
  (or (null value)
      (and (stringp value)
           (zerop (length (string-trim '(#\Space #\Tab #\Newline #\Return)
                                       value))))))

(defun zotero-string-value (value)
  (let ((string (and value (format nil "~A" value))))
    (unless (zotero-blank-string-p string)
      string)))

(defun zotero-trimmed-string (value)
  (when-let (string (zotero-string-value value))
    (string-trim '(#\Space #\Tab #\Newline #\Return) string)))

(defun zotero-integer-value (value)
  (cond
    ((integerp value) value)
    ((stringp value)
     (ignore-errors (parse-integer value)))
    (t
     nil)))

(defun zotero-positive-integer-or-default (value default)
  (let ((integer (zotero-integer-value value)))
    (if (and integer (plusp integer))
        integer
        default)))

(defun zotero-normalize-since-value (value)
  (when-let (string (zotero-trimmed-string value))
    string))

(defun expand-home-path-string (string)
  (cond
    ((or (null string) (string= string "")) string)
    ((string= string "~")
     (pathname-namestring-or-nil (user-homedir-pathname)))
    ((uiop:string-prefix-p "~/" string)
     (format nil "~A~A"
             (pathname-namestring-or-nil (user-homedir-pathname))
             (subseq string 2)))
    (t
     string)))

(defun normalize-path-designator (designator &key directoryp)
  (typecase designator
    (null nil)
    (pathname (if directoryp
                  (uiop:ensure-directory-pathname designator)
                  designator))
    (string
     (let ((path (pathname (expand-home-path-string designator))))
       (if directoryp
           (uiop:ensure-directory-pathname path)
           path)))))

(defun normalize-path-list (designators &key directoryp)
  (remove nil
          (mapcar (lambda (designator)
                    (normalize-path-designator designator
                                               :directoryp directoryp))
                  designators)))

(defun default-zotero-db-path ()
  (merge-pathnames "Zotero/zotero.sqlite" (user-homedir-pathname)))

(defun default-zotero-storage-root ()
  (merge-pathnames "Zotero/storage/" (user-homedir-pathname)))

(defun getenv-pathname (name &key directoryp)
  (let ((value (uiop:getenv name)))
    (and (not (zotero-blank-string-p value))
         (normalize-path-designator value :directoryp directoryp))))

(defun getenv-note-roots (name)
  (let ((value (uiop:getenv name)))
    (and (not (zotero-blank-string-p value))
         (normalize-path-list
          (remove-if #'zotero-blank-string-p
                     (uiop:split-string value
                                        :separator '(#\: #\Newline)))
          :directoryp t))))

(defun make-zotero-library-bridge (&key db-path storage-root note-roots
                                     (sqlite-program
                                      *zotero-default-sqlite-program*))
  (make-instance 'zotero-library-bridge
                 :db-path (normalize-path-designator db-path)
                 :storage-root (normalize-path-designator storage-root
                                                          :directoryp t)
                 :note-roots (normalize-path-list note-roots :directoryp t)
                 :sqlite-program sqlite-program))

(defun make-default-zotero-library-bridge ()
  (make-zotero-library-bridge
   :db-path (or (getenv-pathname "HYPERDOC_ZOTERO_DB_PATH")
                (default-zotero-db-path))
   :storage-root (or (getenv-pathname "HYPERDOC_ZOTERO_STORAGE_ROOT"
                                      :directoryp t)
                     (default-zotero-storage-root))
   :note-roots (or (getenv-note-roots "HYPERDOC_ZETTELKASTEN_ROOTS")
                   nil)
   :sqlite-program (or (uiop:getenv "HYPERDOC_SQLITE_PROGRAM")
                       *zotero-default-sqlite-program*)))

(defun zotero-db-exists-p (bridge)
  (and (zotero-db-path-of bridge)
       (uiop:file-exists-p (zotero-db-path-of bridge))))

(defun zotero-storage-root-exists-p (bridge)
  (and (zotero-storage-root-of bridge)
       (uiop:directory-exists-p (zotero-storage-root-of bridge))))

(defun zotero-existing-note-roots (bridge)
  (remove-if-not #'uiop:directory-exists-p (zotero-note-roots-of bridge)))

(defun sql-string-literal (string)
  (format nil "'~A'"
          (with-output-to-string (stream)
            (loop for char across (or string "")
                  do (if (char= char #\')
                         (write-string "''" stream)
                         (write-char char stream))))))

(defun zotero-db-uri (bridge &key immutablep)
  (format nil "file:~A?mode=ro~@[&immutable=1~]"
          (pathname-namestring-or-nil (zotero-db-path-of bridge))
          immutablep))

(defun parse-zotero-json-output (output)
  (if (zotero-blank-string-p output)
      nil
      (with-input-from-string (stream output)
        (let ((data (shasht:read-json stream)))
          (typecase data
            (null nil)
            (vector (coerce data 'list))
            (list data)
            (t (list data)))))))

(defun zotero-query-attempt-status-detail (output exit-code)
  (let ((trimmed (zotero-trimmed-string output)))
    (or trimmed
        (and exit-code
             (format nil "sqlite3 exited with code ~A" exit-code))
        "sqlite3 returned no output")))

(defun run-zotero-sqlite-query (bridge name sql)
  (let* ((sqlite-program (zotero-sqlite-program-of bridge))
         (attempts '())
         (selected nil))
    (cond
      ((null (zotero-db-path-of bridge))
       (push (make-instance 'zotero-query-attempt
                            :access-mode :configuration-error
                            :status :error
                            :detail "No Zotero database path configured.")
             attempts))
      ((not (uiop:file-exists-p (zotero-db-path-of bridge)))
       (push (make-instance 'zotero-query-attempt
                            :access-mode :configuration-error
                            :status :error
                            :detail (format nil "Zotero database not found: ~A"
                                            (pathname-namestring-or-nil
                                             (zotero-db-path-of bridge))))
             attempts))
      ((zotero-blank-string-p sqlite-program)
       (push (make-instance 'zotero-query-attempt
                            :access-mode :runtime-error
                            :status :error
                            :detail "No sqlite3 program configured for the Zotero bridge.")
             attempts))
      (t
       (dolist (spec '((:live-read nil)
                       (:immutable-read t)))
         (destructuring-bind (access-mode immutablep) spec
           (unless selected
             (let* ((uri (zotero-db-uri bridge :immutablep immutablep))
                    (command (list sqlite-program
                                   "-json"
                                   uri
                                   sql)))
               (handler-case
                   (multiple-value-bind (output error-output exit-code)
                       (uiop:run-program command
                                         :output :string
                                         :error-output :output
                                         :ignore-error-status t)
                     (declare (ignore error-output))
                     (let ((detail (zotero-query-attempt-status-detail
                                    output
                                    exit-code)))
                       (if (zerop exit-code)
                           (let ((attempt (make-instance 'zotero-query-attempt
                                                         :access-mode access-mode
                                                         :command command
                                                         :status :ok
                                                         :rows (parse-zotero-json-output
                                                                (or output "[]"))
                                                         :detail detail
                                                         :exit-code exit-code)))
                             (push attempt attempts)
                             (setf selected attempt))
                           (push (make-instance 'zotero-query-attempt
                                                :access-mode access-mode
                                                :command command
                                                :status :error
                                                :detail detail
                                                :exit-code exit-code)
                                 attempts))))
                 (error (condition)
                   (push (make-instance 'zotero-query-attempt
                                        :access-mode access-mode
                                        :command command
                                        :status :error
                                        :detail (princ-to-string condition))
                         attempts)))))))))
    (make-instance 'zotero-query-evidence
                   :name name
                   :sql sql
                   :attempts (nreverse attempts)
                   :selected-attempt selected)))

(defun raw-row-value (row key)
  (and (hash-table-p row)
       (gethash key row)))

(defun zotero-bibliographic-items-query-sql (&key where-clause
                                               (order-by "title, itemID"))
  (format nil
          "SELECT * FROM (~%
             SELECT i.itemID AS itemID,~%
                    i.key AS itemKey,~%
                    it.typeName AS itemType,~%
                    MAX(CASE WHEN f.fieldName='title' THEN v.value END) AS title,~%
                    MAX(CASE WHEN f.fieldName='DOI' THEN v.value END) AS doi,~%
                    MAX(CASE WHEN f.fieldName='citationKey' THEN v.value END) AS citationKey,~%
                    MAX(CASE WHEN f.fieldName='date' THEN v.value END) AS date~%
               FROM items i~%
               JOIN itemTypes it ON it.itemTypeID = i.itemTypeID~%
               LEFT JOIN itemData d ON d.itemID = i.itemID~%
               LEFT JOIN fields f ON f.fieldID = d.fieldID~%
               LEFT JOIN itemDataValues v ON v.valueID = d.valueID~%
              WHERE it.typeName NOT IN ('attachment', 'note', 'annotation')~%
              GROUP BY i.itemID, i.key, it.typeName~%
           ) candidates~%
          ~@[WHERE ~A~%~]\
          ORDER BY ~A;"
          where-clause
          order-by))

(defun title-match-predicate-sql (title match-mode)
  (let ((literal (sql-string-literal title)))
    (ecase match-mode
      (:exact
       (format nil "lower(trim(COALESCE(title, ''))) = lower(trim(~A))"
               literal))
      (:loose
       (format nil "instr(lower(trim(COALESCE(title, ''))), lower(trim(~A))) > 0"
               literal)))))

(defun title-match-query-sql (title &key (match-mode :exact))
  (zotero-bibliographic-items-query-sql
   :where-clause (title-match-predicate-sql title match-mode)))

(defun item-id-query-sql (item-id)
  (zotero-bibliographic-items-query-sql
   :where-clause (format nil "itemID = ~D"
                         (or (zotero-integer-value item-id)
                             -1))
   :order-by "itemID"))

(defun recent-zotero-changes-query-sql (limit since include-attachments-p)
  (let ((type-filter
         (if include-attachments-p
             "it.typeName NOT IN ('note', 'annotation')"
             "it.typeName NOT IN ('attachment', 'note', 'annotation')"))
        (since-clause
         (and since
              (format nil "AND i.dateModified >= ~A"
                      (sql-string-literal since)))))
    (format nil
            "WITH item_fields AS (
               SELECT d.itemID,
                      MAX(CASE WHEN f.fieldName='title' THEN v.value END) AS title
               FROM itemData d
               JOIN fields f ON f.fieldID = d.fieldID
               JOIN itemDataValues v ON v.valueID = d.valueID
               GROUP BY d.itemID
             )
             SELECT i.itemID AS itemID,
                    i.key AS itemKey,
                    it.typeName AS itemType,
                    COALESCE(item_fields.title,
                             CASE
                               WHEN it.typeName = 'attachment'
                               THEN COALESCE(ia.path, '')
                               ELSE ''
                             END) AS title,
                    i.dateAdded AS dateAdded,
                    i.dateModified AS itemDateModified,
                    i.clientDateModified AS clientDateModified,
                    'items.dateModified' AS chosenChangeTimestampField,
                    i.dateModified AS chosenChangeTimestamp,
                    ia.parentItemID AS parentItemID,
                    ia.path AS attachmentPath,
                    ia.storageModTime AS attachmentStorageModTime,
                    ia.lastProcessedModificationTime
                      AS attachmentLastProcessedModificationTime
             FROM items i
             JOIN itemTypes it ON it.itemTypeID = i.itemTypeID
             LEFT JOIN item_fields ON item_fields.itemID = i.itemID
             LEFT JOIN itemAttachments ia ON ia.itemID = i.itemID
             WHERE ~A
             ~@[  ~A~%~]\
             ORDER BY i.dateModified DESC, i.itemID DESC
             LIMIT ~D;"
            type-filter
            since-clause
            limit)))

(defun attachment-query-sql (item-ids)
  (format nil
          "SELECT ia.parentItemID AS parentItemID,~%
                  child.itemID AS attachmentItemID,~%
                  child.key AS attachmentKey,~%
                  it.typeName AS attachmentType,~%
                  ia.linkMode AS linkMode,~%
                  ia.contentType AS contentType,~%
                  ia.path AS attachmentPath,~%
                  MAX(CASE WHEN f.fieldName='title' THEN v.value END) AS attachmentTitle~%
             FROM itemAttachments ia~%
             JOIN items child ON child.itemID = ia.itemID~%
             JOIN itemTypes it ON it.itemTypeID = child.itemTypeID~%
             LEFT JOIN itemData d ON d.itemID = child.itemID~%
             LEFT JOIN fields f ON f.fieldID = d.fieldID~%
             LEFT JOIN itemDataValues v ON v.valueID = d.valueID~%
            WHERE ia.parentItemID IN (~{~A~^, ~})~%
            GROUP BY ia.parentItemID, child.itemID, child.key, it.typeName, ia.linkMode, ia.contentType, ia.path~%
            ORDER BY ia.parentItemID, child.itemID;"
          item-ids))

(defun zotero-query-rows (query)
  (and query
       (zotero-query-selected-attempt-of query)
       (zotero-query-attempt-rows-of
        (zotero-query-selected-attempt-of query))))

(defun zotero-query-failed-p (query)
  (and query
       (null (zotero-query-selected-attempt-of query))
       (find-if (lambda (attempt)
                  (eq (zotero-query-attempt-status-of attempt) :error))
                (zotero-query-attempts-of query))))

(defun zotero-query-primary-attempt (query)
  (or (zotero-query-selected-attempt-of query)
      (first (zotero-query-attempts-of query))))

(defun zotero-query-failure-detail (query)
  (let ((attempt (or (find-if (lambda (candidate)
                                (eq (zotero-query-attempt-status-of candidate)
                                    :error))
                              (zotero-query-attempts-of query))
                     (zotero-query-primary-attempt query))))
    (and attempt
         (zotero-query-attempt-detail-of attempt))))

(defgeneric zotero-query-protocol-status-of (attempt-or-failure))
(defgeneric zotero-query-protocol-rows-of (attempt-or-failure))
(defgeneric zotero-query-protocol-detail-of (attempt-or-failure))
(defgeneric zotero-query-protocol-metadata-of (attempt-or-failure))

(defmethod zotero-query-protocol-status-of ((attempt zotero-query-attempt))
  (zotero-query-attempt-status-of attempt))

(defmethod zotero-query-protocol-rows-of ((attempt zotero-query-attempt))
  (zotero-query-attempt-rows-of attempt))

(defmethod zotero-query-protocol-detail-of ((attempt zotero-query-attempt))
  (zotero-query-attempt-detail-of attempt))

(defmethod zotero-query-protocol-metadata-of ((attempt zotero-query-attempt))
  (list :class 'zotero-query-attempt
        :access-mode (zotero-query-attempt-access-mode-of attempt)
        :command (zotero-query-attempt-command-of attempt)
        :exit-code (zotero-query-attempt-exit-code-of attempt)))

(defmethod zotero-query-protocol-status-of ((attempt zotero-query-missing-attempt))
  (zotero-query-missing-attempt-status-of attempt))

(defmethod zotero-query-protocol-rows-of ((attempt zotero-query-missing-attempt))
  nil)

(defmethod zotero-query-protocol-detail-of ((attempt zotero-query-missing-attempt))
  (zotero-query-missing-attempt-detail-of attempt))

(defmethod zotero-query-protocol-metadata-of ((attempt zotero-query-missing-attempt))
  (let ((query (zotero-query-missing-attempt-query-of attempt)))
    (list :class 'zotero-query-missing-attempt
          :attempted-operation (zotero-query-missing-attempt-operation-of attempt)
          :receiver (zotero-query-missing-attempt-receiver-of attempt)
          :arguments (zotero-query-missing-attempt-arguments-of attempt)
          :higher-level-intent (zotero-query-missing-attempt-intent-of attempt)
          :repair-hint (zotero-query-missing-attempt-repair-hint-of attempt)
          :query-name (and query (zotero-query-name-of query))
          :attempt-count (and query (length (zotero-query-attempts-of query))))))

(defun normalize-zotero-query-attempt
    (query &key attempted-operation receiver arguments higher-level-intent repair-hint)
  (or (and query (zotero-query-selected-attempt-of query))
      (make-instance 'zotero-query-missing-attempt
                     :query query
                     :attempted-operation attempted-operation
                     :receiver receiver
                     :arguments arguments
                     :higher-level-intent higher-level-intent
                     :status (if (zotero-query-failed-p query) :error :missing)
                     :detail (or (zotero-query-failure-detail query)
                                 "No Zotero query attempt was selected.")
                     :repair-hint repair-hint)))

(defun make-zotero-error-query (name detail)
  (make-instance 'zotero-query-evidence
                 :name name
                 :sql ""
                 :attempts (list (make-instance 'zotero-query-attempt
                                                :access-mode :configuration-error
                                                :status :error
                                                :detail detail))
                 :selected-attempt nil))

(defun item-id-designator-value (item-or-id)
  (typecase item-or-id
    (zotero-item-hit (zotero-item-id-of item-or-id))
    (integer item-or-id)
    (string (zotero-integer-value item-or-id))
    (t nil)))

(defun make-zotero-item-from-row (row)
  (make-instance 'zotero-bibliographic-item
                 :item-id (zotero-integer-value (raw-row-value row "itemID"))
                 :item-key (zotero-string-value (raw-row-value row "itemKey"))
                 :item-type (zotero-string-value (raw-row-value row "itemType"))
                 :title (or (zotero-string-value (raw-row-value row "title"))
                            "")
                 :doi (zotero-string-value (raw-row-value row "doi"))
                 :citation-key (zotero-string-value (raw-row-value row "citationKey"))
                 :date (zotero-string-value (raw-row-value row "date"))
                 :raw-row row))

(defun make-zotero-title-query-from-evidence (bridge title match-mode items query)
  (make-instance 'zotero-title-query
                 :bridge bridge
                 :name (zotero-query-name-of query)
                 :sql (zotero-query-sql-of query)
                 :attempts (zotero-query-attempts-of query)
                 :selected-attempt (zotero-query-selected-attempt-of query)
                 :query-text title
                 :match-mode match-mode
                 :matched-items items))

(defun make-zotero-item-id-query-from-evidence (bridge item-id item query)
  (make-instance 'zotero-item-id-query
                 :bridge bridge
                 :name (zotero-query-name-of query)
                 :sql (zotero-query-sql-of query)
                 :attempts (zotero-query-attempts-of query)
                 :selected-attempt (zotero-query-selected-attempt-of query)
                 :item-id item-id
                 :matched-item item))

(defun make-zotero-recent-change-hit-from-row (row row-index)
  (make-instance 'zotero-recent-change-hit
                 :item-id (zotero-integer-value (raw-row-value row "itemID"))
                 :item-key (zotero-string-value (raw-row-value row "itemKey"))
                 :item-type (zotero-string-value (raw-row-value row "itemType"))
                 :title (or (zotero-string-value (raw-row-value row "title"))
                            "")
                 :raw-row row
                 :change-timestamp-field
                 (or (zotero-string-value
                      (raw-row-value row "chosenChangeTimestampField"))
                     "items.dateModified")
                 :change-timestamp
                 (zotero-string-value
                  (raw-row-value row "chosenChangeTimestamp"))
                 :evidence-path
                 (format nil "selected-attempt.rows[~D]" row-index)
                 :date-added
                 (zotero-string-value (raw-row-value row "dateAdded"))
                 :item-date-modified
                 (zotero-string-value (raw-row-value row "itemDateModified"))
                 :client-date-modified
                 (zotero-string-value
                  (raw-row-value row "clientDateModified"))
                 :parent-item-id
                 (zotero-integer-value (raw-row-value row "parentItemID"))
                 :attachment-path
                 (zotero-string-value (raw-row-value row "attachmentPath"))
                 :attachment-storage-mod-time
                 (zotero-integer-value
                  (raw-row-value row "attachmentStorageModTime"))
                 :attachment-last-processed-modification-time
                 (zotero-integer-value
                  (raw-row-value row
                                 "attachmentLastProcessedModificationTime"))))

(defun make-zotero-recent-changes-query-from-evidence
    (bridge limit since include-attachments-p hits query)
  (make-instance 'zotero-recent-changes-query
                 :bridge bridge
                 :name (zotero-query-name-of query)
                 :sql (zotero-query-sql-of query)
                 :attempts (zotero-query-attempts-of query)
                 :selected-attempt (zotero-query-selected-attempt-of query)
                 :limit limit
                 :since since
                 :include-attachments-p include-attachments-p
                 :change-timestamp-field "items.dateModified"
                 :recent-items hits))

(defun lookup-zotero-items-by-title (title &key bridge (match-mode :exact))
  (let* ((bridge (or bridge (make-default-zotero-library-bridge)))
         (query-evidence
          (run-zotero-sqlite-query bridge
                                   (format nil "title lookup (~A)" match-mode)
                                   (title-match-query-sql title
                                                          :match-mode match-mode)))
         (items (mapcar #'make-zotero-item-from-row
                        (zotero-query-rows query-evidence)))
         (title-query (make-zotero-title-query-from-evidence
                       bridge
                       title
                       match-mode
                       items
                       query-evidence)))
    (values items title-query)))

(defun lookup-zotero-item-by-id (item-id &key bridge)
  (let* ((bridge (or bridge (make-default-zotero-library-bridge)))
         (query (run-zotero-sqlite-query bridge
                                         "item id lookup"
                                         (item-id-query-sql item-id)))
         (items (mapcar #'make-zotero-item-from-row
                        (zotero-query-rows query)))
         (item (first items))
         (item-id-query
          (make-zotero-item-id-query-from-evidence bridge
                                                   item-id
                                                   item
                                                   query)))
    (values item
            item-id-query)))

(defun zotero-recent-change-day-key (hit)
  (let ((timestamp (zotero-recent-change-hit-change-timestamp-of hit)))
    (if (and timestamp (>= (length timestamp) 10))
        (subseq timestamp 0 10)
        "No chosen timestamp")))

(defun group-zotero-recent-change-hits-by-day (hits)
  (let ((groups '())
        (current-day nil)
        (current-hits '()))
    (labels ((finish-group ()
               (when current-day
                 (push (list :day current-day
                             :hits (nreverse current-hits))
                       groups))))
      (dolist (hit hits)
        (let ((day (zotero-recent-change-day-key hit)))
          (if (equal day current-day)
              (push hit current-hits)
              (progn
                (finish-group)
                (setf current-day day
                      current-hits (list hit))))))
      (finish-group)
      (nreverse groups))))

(defun recent-zotero-changes (&key bridge (limit 20) since include-attachments?)
  (let* ((bridge (or bridge (make-default-zotero-library-bridge)))
         (limit (zotero-positive-integer-or-default limit 20))
         (since (zotero-normalize-since-value since))
         (query-evidence
          (run-zotero-sqlite-query
           bridge
           (if include-attachments?
               "recent changes (including attachments)"
               "recent changes")
           (recent-zotero-changes-query-sql limit
                                            since
                                            include-attachments?)))
         (hits (loop for row in (zotero-query-rows query-evidence)
                     for row-index from 0
                     collect (make-zotero-recent-change-hit-from-row
                              row
                              row-index))))
    (make-zotero-recent-changes-query-from-evidence bridge
                                                    limit
                                                    since
                                                    include-attachments?
                                                    hits
                                                    query-evidence)))

(defun absolute-path-string-p (string)
  (and (stringp string)
       (or (uiop:string-prefix-p "/" string)
           (uiop:string-prefix-p "~/" string)
           (uiop:string-prefix-p "file://" string)
           (and (> (length string) 2)
                (alpha-char-p (char string 0))
                (char= (char string 1) #\:)))))

(defun zotero-linked-pathname (string)
  (cond
    ((zotero-blank-string-p string) nil)
    ((uiop:string-prefix-p "file://" string)
     (pathname (subseq string 7)))
    ((uiop:string-prefix-p "~/" string)
     (pathname (expand-home-path-string string)))
    (t
     (pathname string))))

(defun zotero-stored-relative-path (string)
  (when (and (stringp string)
             (uiop:string-prefix-p "storage:" string))
    (let ((suffix (string-trim '(#\/ #\\ #\Space)
                               (subseq string (length "storage:")))))
      (unless (zotero-blank-string-p suffix)
        suffix))))

(defun zotero-attachment-kind (raw-path)
  (cond
    ((zotero-blank-string-p raw-path) :missing-path)
    ((uiop:string-prefix-p "storage:" raw-path) :stored)
    ((absolute-path-string-p raw-path) :linked-file)
    (t :unsupported)))

(defun zotero-attachment-filename (raw-path)
  (cond
    ((zotero-blank-string-p raw-path) nil)
    ((uiop:string-prefix-p "storage:" raw-path)
     (let ((relative-path (zotero-stored-relative-path raw-path)))
       (and relative-path (file-namestring (pathname relative-path)))))
    (t
     (file-namestring (zotero-linked-pathname raw-path)))))

(defun make-zotero-attachment-from-row (row)
  (let* ((raw-path (zotero-string-value (raw-row-value row "attachmentPath")))
         (kind (zotero-attachment-kind raw-path)))
    (make-instance 'zotero-attachment
                   :attachment-item-id
                   (zotero-integer-value
                    (raw-row-value row "attachmentItemID"))
                   :parent-item-id
                   (zotero-integer-value (raw-row-value row "parentItemID"))
                   :attachment-key
                   (zotero-string-value (raw-row-value row "attachmentKey"))
                   :attachment-type
                   (zotero-string-value (raw-row-value row "attachmentType"))
                   :link-mode (zotero-integer-value (raw-row-value row "linkMode"))
                   :content-type
                   (zotero-string-value (raw-row-value row "contentType"))
                   :raw-path raw-path
                   :attachment-title
                   (zotero-string-value (raw-row-value row "attachmentTitle"))
                   :normalized-kind kind
                   :filename (zotero-attachment-filename raw-path)
                   :raw-row row)))

(defun list-zotero-attachments-for-item (item-or-id &key bridge)
  (let* ((bridge (or bridge (make-default-zotero-library-bridge)))
         (item-id (item-id-designator-value item-or-id)))
    (if (null item-id)
        (values nil
                (make-zotero-error-query
                 "attachment lookup"
                 "No Zotero item id was provided for attachment lookup."))
        (let* ((query (run-zotero-sqlite-query bridge
                                               "attachment lookup"
                                               (attachment-query-sql
                                                (list item-id))))
               (attachments (mapcar #'make-zotero-attachment-from-row
                                    (zotero-query-rows query))))
          (when (typep item-or-id 'zotero-item-hit)
            (setf (zotero-item-attachments-of item-or-id)
                  attachments))
          (values attachments query)))))

(defun make-zotero-path-report (bridge attachment &key item-hit resolved-path
                                                    exists-p failure-mode detail
                                                    storage-relative-path)
  (make-instance 'zotero-attachment-path-resolution
                 :bridge bridge
                 :item-hit item-hit
                 :attachment attachment
                 :attachment-mode (zotero-attachment-normalized-kind-of attachment)
                 :attachment-key (zotero-attachment-key-of attachment)
                 :storage-relative-path storage-relative-path
                 :resolved-path resolved-path
                 :exists-p exists-p
                 :failure-mode failure-mode
                 :detail detail))

(defun resolve-zotero-stored-attachment-path (attachment &key bridge item-hit)
  (let* ((bridge (or bridge (make-default-zotero-library-bridge)))
         (raw-path (zotero-attachment-raw-path-of attachment))
         (storage-root (zotero-storage-root-of bridge))
         (attachment-key (zotero-attachment-key-of attachment))
         (relative-path (zotero-stored-relative-path raw-path)))
    (cond
      ((not (eq (zotero-attachment-normalized-kind-of attachment) :stored))
       (make-zotero-path-report
        bridge
        attachment
        :item-hit item-hit
        :failure-mode :not-stored-attachment
        :detail "Attachment is not a Zotero stored-file attachment."))
      ((null storage-root)
       (make-zotero-path-report
        bridge
        attachment
        :item-hit item-hit
        :failure-mode :missing-storage-root
        :detail "No Zotero storage root configured."))
      ((null (uiop:directory-exists-p storage-root))
       (make-zotero-path-report
        bridge
        attachment
        :item-hit item-hit
        :failure-mode :storage-root-missing
        :detail (format nil "Configured Zotero storage root not found: ~A"
                        (pathname-namestring-or-nil storage-root))))
      ((zotero-blank-string-p attachment-key)
       (make-zotero-path-report
        bridge
        attachment
        :item-hit item-hit
        :failure-mode :missing-attachment-key
        :detail "Stored attachment lacks a Zotero item key."))
      ((null relative-path)
       (make-zotero-path-report
        bridge
        attachment
        :item-hit item-hit
        :failure-mode :missing-stored-relative-path
        :detail "Stored attachment path metadata is blank after the storage: prefix."))
      (t
       (let* ((key-root (uiop:ensure-directory-pathname
                         (merge-pathnames
                          (format nil "~A/" attachment-key)
                          storage-root)))
              (resolved-path (merge-pathnames (pathname relative-path)
                                              key-root))
              (exists-p (uiop:file-exists-p resolved-path)))
         (make-zotero-path-report
          bridge
          attachment
          :item-hit item-hit
          :storage-relative-path relative-path
          :resolved-path resolved-path
          :exists-p (not (null exists-p))
          :failure-mode (unless exists-p :stored-file-missing)
          :detail (unless exists-p
                    "Stored attachment resolved to a path that does not exist.")))))))

(defun resolve-zotero-linked-attachment-path (attachment &key bridge item-hit)
  (let* ((bridge (or bridge (make-default-zotero-library-bridge)))
         (path (zotero-linked-pathname (zotero-attachment-raw-path-of attachment)))
         (exists-p (and path (uiop:file-exists-p path))))
    (make-zotero-path-report
     bridge
     attachment
     :item-hit item-hit
     :resolved-path path
     :exists-p (not (null exists-p))
     :failure-mode (unless exists-p :linked-file-missing)
     :detail (unless exists-p
               "Linked file path does not exist on disk."))))

(defun resolve-zotero-attachment-path (bridge attachment &key item-hit)
  (let ((kind (zotero-attachment-normalized-kind-of attachment))
        (raw-path (zotero-attachment-raw-path-of attachment)))
    (ecase kind
      (:missing-path
       (make-zotero-path-report
        bridge
        attachment
        :item-hit item-hit
        :failure-mode :missing-attachment-path
        :detail "Attachment metadata does not contain a path."))
      (:unsupported
       (make-zotero-path-report
        bridge
        attachment
        :item-hit item-hit
        :failure-mode :unsupported-attachment-path
        :detail (format nil "Unsupported Zotero attachment path: ~A"
                        raw-path)))
      (:linked-file
       (resolve-zotero-linked-attachment-path attachment
                                              :bridge bridge
                                              :item-hit item-hit))
      (:stored
       (resolve-zotero-stored-attachment-path attachment
                                              :bridge bridge
                                              :item-hit item-hit)))))

(defun pdf-attachment-p (attachment)
  (or (and (zotero-attachment-content-type-of attachment)
           (search "pdf"
                   (string-downcase (zotero-attachment-content-type-of attachment))
                   :test #'char=))
      (and (zotero-attachment-filename-of attachment)
           (string-suffix-p ".pdf"
                            (string-downcase
                             (zotero-attachment-filename-of attachment))))))

(defun item-attachment-map (attachments)
  (let ((table (make-hash-table :test #'eql)))
    (dolist (attachment attachments table)
      (push attachment
            (gethash (zotero-attachment-parent-item-id-of attachment) table)))))

(defun note-file-extension-p (pathname)
  (let ((type (and pathname (pathname-type pathname))))
    (and type
         (member (string-downcase type)
                 *zotero-note-file-extensions*
                 :test #'string=))))

(defun collect-note-files-under (root)
  (labels ((collect (directory)
             (append (remove-if-not #'note-file-extension-p
                                    (ignore-errors
                                      (uiop:directory-files directory)))
                     (loop for subdirectory in (ignore-errors
                                                 (uiop:subdirectories directory))
                           append (collect subdirectory)))))
    (collect (uiop:ensure-directory-pathname root))))

(defun make-note-clue-spec (kind value &key item-id attachment-item-id)
  (list :kind kind
        :value value
        :item-id item-id
        :attachment-item-id attachment-item-id))

(defun unique-note-clue-specs (specs)
  (let ((seen (make-hash-table :test #'equal))
        (result '()))
    (dolist (spec specs (nreverse result))
      (let ((key (list (getf spec :kind)
                       (string-downcase (getf spec :value))
                       (getf spec :item-id)
                       (getf spec :attachment-item-id))))
        (unless (gethash key seen)
          (setf (gethash key seen) t)
          (push spec result))))))

(defun build-note-clue-specs (title items attachments)
  (unique-note-clue-specs
   (append (list (make-note-clue-spec :title title))
           (loop for item in items
                 append (remove nil
                                (list (and (zotero-item-doi-of item)
                                           (make-note-clue-spec
                                            :doi
                                            (zotero-item-doi-of item)
                                            :item-id
                                            (zotero-item-id-of item)))
                                      (and (zotero-item-key-of item)
                                           (make-note-clue-spec
                                            :zotero-item-key
                                            (zotero-item-key-of item)
                                            :item-id
                                            (zotero-item-id-of item)))
                                      (and (zotero-item-citation-key-of item)
                                           (make-note-clue-spec
                                            :citation-key
                                            (zotero-item-citation-key-of item)
                                            :item-id
                                            (zotero-item-id-of item))))))
           (loop for attachment in attachments
                 append (remove nil
                                (list (and (zotero-attachment-filename-of attachment)
                                           (make-note-clue-spec
                                            :attachment-filename
                                            (zotero-attachment-filename-of attachment)
                                            :item-id
                                            (zotero-attachment-parent-item-id-of
                                             attachment)
                                            :attachment-item-id
                                            (zotero-attachment-item-id-of
                                             attachment)))))))))

(defun note-line-match (line needle)
  (search (string-downcase needle)
          (string-downcase line)
          :test #'char=))

(defun read-note-file-lines (path)
  (handler-case
      (uiop:read-file-lines path)
    (error ()
      nil)))

(defun search-note-file-for-clues (note-path root clue-specs)
  (let ((matches '()))
    (loop for line in (read-note-file-lines note-path)
          for line-number from 1
          do (dolist (spec clue-specs)
               (when (note-line-match line (getf spec :value))
                 (push (make-instance 'zotero-note-clue-match
                                      :kind (getf spec :kind)
                                      :value (getf spec :value)
                                      :line-number line-number
                                      :line-text line
                                      :item-id (getf spec :item-id)
                                      :attachment-item-id
                                      (getf spec :attachment-item-id))
                       matches))))
    (when matches
      (make-instance 'zotero-note-evidence
                     :note-path note-path
                     :root root
                     :matches (nreverse matches)))))

(defun collect-note-evidence (bridge title items attachments)
  (let ((roots (zotero-existing-note-roots bridge)))
    (if (null roots)
        (values nil :disabled 0)
        (let* ((clue-specs (build-note-clue-specs title items attachments))
               (files (sort (remove-duplicates
                             (loop for root in roots
                                   append (collect-note-files-under root))
                             :test #'equal)
                            #'string<
                            :key #'pathname-namestring-or-nil))
               (evidence
                (remove nil
                        (loop for file in files
                              for root = (find-if
                                          (lambda (candidate-root)
                                            (uiop:string-prefix-p
                                             (pathname-namestring-or-nil
                                              candidate-root)
                                             (pathname-namestring-or-nil file)))
                                          roots)
                              collect (search-note-file-for-clues
                                       file
                                       root
                                       clue-specs)))))
          (values evidence :searched (length files))))))

(defun note-evidence-for-selection (note-evidence item attachment)
  (remove nil
          (mapcar (lambda (evidence)
                    (when (or (null item)
                              (some (lambda (match)
                                      (or (and (zotero-note-clue-item-id-of match)
                                               (= (zotero-note-clue-item-id-of match)
                                                  (zotero-item-id-of item)))
                                          (and attachment
                                               (zotero-note-clue-attachment-item-id-of match)
                                               (= (zotero-note-clue-attachment-item-id-of match)
                                                  (zotero-attachment-item-id-of
                                                   attachment)))))
                                    (zotero-note-evidence-matches-of evidence)))
                      evidence))
                  note-evidence)))

(defun find-zotero-item-hit-by-id (items item-id)
  (find item-id items :key #'zotero-item-id-of :test #'eql))

(defun make-zotero-resolution-evidence-from-report (report note-evidence)
  (let* ((item-hit (zotero-path-report-item-hit-of report))
         (attachment-hit (zotero-path-report-attachment-hit-of report))
         (supporting-notes (note-evidence-for-selection note-evidence
                                                        item-hit
                                                        attachment-hit)))
    (make-instance 'zotero-resolution-evidence
                   :item-hit item-hit
                   :attachment-hit attachment-hit
                   :path-report report
                   :attachment-mode (zotero-path-report-attachment-mode-of report)
                   :attachment-key (zotero-path-report-attachment-key-of report)
                   :storage-relative-path
                   (zotero-path-report-storage-relative-path-of report)
                   :resolved-path (zotero-path-report-resolved-path-of report)
                   :exists-p (zotero-path-report-exists-p report)
                   :note-evidence supporting-notes
                   :failure-mode (zotero-path-report-failure-mode-of report)
                   :detail (zotero-path-report-detail-of report))))

(defun resolve-zotero-title-to-candidate-pdf-reports (title &key bridge
                                                              (match-mode :exact))
  (let ((bridge (or bridge (make-default-zotero-library-bridge))))
    (multiple-value-bind (items title-query)
        (lookup-zotero-items-by-title title
                                      :bridge bridge
                                      :match-mode match-mode)
      (let* ((attachment-query
              (and items
                   (run-zotero-sqlite-query bridge
                                            "attachment lookup"
                                            (attachment-query-sql
                                             (mapcar #'zotero-item-id-of items)))))
             (attachments (mapcar #'make-zotero-attachment-from-row
                                  (zotero-query-rows attachment-query)))
             (note-evidence nil)
             (note-search-status :disabled)
             (note-files-searched 0))
        (attach-attachments-to-items! items attachments)
        (multiple-value-setq (note-evidence note-search-status note-files-searched)
          (collect-note-evidence bridge title items attachments))
        (let* ((candidate-reports
                (loop for attachment in attachments
                      for item-hit =
                      (find-zotero-item-hit-by-id items
                                                  (zotero-attachment-parent-item-id-of
                                                   attachment))
                      when (pdf-attachment-p attachment)
                      collect (resolve-zotero-attachment-path bridge
                                                              attachment
                                                              :item-hit item-hit)))
               (candidate-evidence
                (mapcar (lambda (report)
                          (make-zotero-resolution-evidence-from-report
                           report
                           note-evidence))
                        candidate-reports)))
          (values candidate-reports
                  title-query
                  attachment-query
                  items
                  attachments
                  note-evidence
                  note-search-status
                  note-files-searched
                  candidate-evidence))))))

(defun select-pdf-resolution (items attachments candidate-reports candidate-evidence)
  (cond
    ((null items)
     (values nil nil nil nil :no-title-match
             "No Zotero bibliographic item matched the requested title."))
    ((> (length items) 1)
     (values nil nil nil nil :ambiguous-title-match
             (format nil "~D Zotero bibliographic items matched the exact title."
                     (length items))))
    (t
     (let* ((item (first items))
            (item-attachments
             (remove-if-not (lambda (attachment)
                              (= (zotero-attachment-parent-item-id-of attachment)
                                 (zotero-item-id-of item)))
                            attachments))
            (item-candidate-reports
             (remove-if-not
              (lambda (report)
                (let ((attachment-hit
                       (zotero-path-report-attachment-hit-of report)))
                  (and attachment-hit
                       (= (zotero-attachment-parent-item-id-of attachment-hit)
                          (zotero-item-id-of item)))))
              candidate-reports))
            (item-candidate-evidence
             (remove-if-not
              (lambda (evidence)
                (eq (zotero-resolution-evidence-item-hit-of evidence)
                    item))
              candidate-evidence)))
       (cond
         ((null item-attachments)
          (values item nil nil nil :no-attachments
                  "The Zotero item has no child attachments."))
         ((null item-candidate-reports)
          (values item nil nil nil :no-pdf-attachment
                  "The Zotero item has attachments, but none are PDFs."))
         ((> (length item-candidate-reports) 1)
          (values item nil nil nil :ambiguous-pdf-attachments
                  (format nil "~D PDF attachments matched the bibliographic item."
                          (length item-candidate-reports))))
         (t
          (let* ((resolution (first item-candidate-reports))
                 (attachment (zotero-path-report-attachment-hit-of resolution))
                 (selected-evidence
                  (or (find resolution
                            item-candidate-evidence
                            :key #'zotero-resolution-evidence-path-report-of
                            :test #'eq)
                      (make-zotero-resolution-evidence-from-report
                       resolution
                       nil))))
            (cond
              ((null resolution)
               (values item attachment nil nil :unresolved-attachment-path
                       "The only PDF attachment could not be matched to a path-resolution report."))
              ((zotero-path-report-exists-p resolution)
               (values item
                       attachment
                       resolution
                       selected-evidence
                       nil
                       nil))
              (t
               (values item
                       attachment
                       resolution
                       selected-evidence
                       :resolved-pdf-missing
                       (or (zotero-path-report-detail-of resolution)
                           "The resolved PDF path does not exist.")))))))))))

(defun attach-attachments-to-items! (items attachments)
  (let ((table (item-attachment-map attachments)))
    (dolist (item items items)
      (setf (zotero-item-attachments-of item)
            (nreverse (copy-list (gethash (zotero-item-id-of item) table)))))))

(defun resolve-zotero-title-to-local-pdf-report (title &key bridge
                                                         (match-mode :exact))
  (let* ((bridge (or bridge (make-default-zotero-library-bridge)))
         (candidate-reports nil)
         (item-query nil)
         (attachment-query nil)
         (items nil)
         (attachments nil)
         (note-evidence nil)
         (note-search-status :disabled)
         (note-files-searched 0)
         (candidate-evidence nil))
    (multiple-value-setq (candidate-reports item-query attachment-query
                                            items attachments note-evidence
                                            note-search-status
                                            note-files-searched
                                            candidate-evidence)
      (resolve-zotero-title-to-candidate-pdf-reports title
                                                     :bridge bridge
                                                     :match-mode match-mode))
    (multiple-value-bind (selected-item selected-attachment selected-resolution
                                        selected-evidence failure-mode detail)
        (select-pdf-resolution items
                               attachments
                               candidate-reports
                               candidate-evidence)
      (let* ((sqlite-failure
              (and (null (zotero-query-selected-attempt-of item-query))
                   :sqlite-query-failed))
             (final-failure-mode
              (or sqlite-failure
                  failure-mode))
             (final-detail
              (or (and sqlite-failure
                       (let ((attempt (car (last (zotero-query-attempts-of item-query)))))
                         (and attempt
                              (zotero-query-attempt-detail-of attempt))))
                  detail))
             (evidence-chain
              (remove nil
                      (append (list selected-item
                                    selected-attachment
                                    selected-resolution
                                    selected-evidence)
                              (and selected-evidence
                                   (zotero-resolution-evidence-note-evidence-of
                                    selected-evidence)))))
             (resolved-path (and selected-resolution
                                 (zotero-path-report-resolved-path-of
                                  selected-resolution)))
             (exists-p (and selected-resolution
                            (zotero-path-report-exists-p selected-resolution))))
        (make-instance 'zotero-title-resolution-report
                       :bridge bridge
                       :query-title title
                       :item-query item-query
                       :attachment-query attachment-query
                       :item-candidates items
                       :attachment-candidates attachments
                       :attachment-resolutions candidate-reports
                       :candidate-evidence candidate-evidence
                       :note-evidence note-evidence
                       :note-search-status note-search-status
                       :note-files-searched note-files-searched
                       :selected-item selected-item
                       :selected-attachment selected-attachment
                       :selected-resolution selected-resolution
                       :selected-evidence selected-evidence
                       :evidence-chain evidence-chain
                       :resolved-path resolved-path
                       :exists-p exists-p
                       :status (if (and selected-resolution exists-p)
                                   :resolved
                                   :unresolved)
                       :failure-mode final-failure-mode
                       :detail final-detail)))))

(defun getenv-integer (name)
  (let ((value (uiop:getenv name)))
    (and (not (zotero-blank-string-p value))
         (ignore-errors (parse-integer value)))))

(defun make-zotero-live-demo-library ()
  (make-zotero-library-bridge
   :db-path (or (getenv-pathname "HYPERDOC_ZOTERO_DEMO_DB_PATH")
                (getenv-pathname "HYPERDOC_ZOTERO_DB_PATH")
                (default-zotero-db-path))
   :storage-root (or (getenv-pathname "HYPERDOC_ZOTERO_DEMO_STORAGE_ROOT"
                                      :directoryp t)
                     (getenv-pathname "HYPERDOC_ZOTERO_STORAGE_ROOT"
                                      :directoryp t)
                     (default-zotero-storage-root))
   :note-roots (or (getenv-note-roots "HYPERDOC_ZOTERO_DEMO_NOTE_ROOTS")
                   (getenv-note-roots "HYPERDOC_ZETTELKASTEN_ROOTS")
                   nil)
   :sqlite-program (or (uiop:getenv "HYPERDOC_ZOTERO_DEMO_SQLITE_PROGRAM")
                       (uiop:getenv "HYPERDOC_SQLITE_PROGRAM")
                       *zotero-default-sqlite-program*)))

(defun mind-and-mechanism-zotero-demo-title ()
  (or (uiop:getenv "HYPERDOC_ZOTERO_DEMO_TITLE")
      "Mind and Mechanism"))

(defun mind-and-mechanism-zotero-demo-item-id ()
  (or (getenv-integer "HYPERDOC_ZOTERO_DEMO_ITEM_ID")
      75704))

(defun mind-and-mechanism-zotero-demo-attachment-key ()
  (or (uiop:getenv "HYPERDOC_ZOTERO_DEMO_ATTACHMENT_KEY")
      "UULEU9Z7"))

(defun mind-and-mechanism-zotero-title-query ()
  (nth-value 1
             (lookup-zotero-items-by-title
              (mind-and-mechanism-zotero-demo-title)
              :bridge (make-zotero-live-demo-library)
              :match-mode :exact)))

(defun mind-and-mechanism-zotero-item-id-query ()
  (nth-value 1
             (lookup-zotero-item-by-id
              (mind-and-mechanism-zotero-demo-item-id)
              :bridge (make-zotero-live-demo-library))))

(defun mind-and-mechanism-zotero-item-hit ()
  (lookup-zotero-item-by-id
   (mind-and-mechanism-zotero-demo-item-id)
   :bridge (make-zotero-live-demo-library)))

(defun mind-and-mechanism-zotero-attachment-hit ()
  (let* ((bridge (make-zotero-live-demo-library))
         (item (mind-and-mechanism-zotero-item-hit))
         (attachments
          (when item
            (multiple-value-bind (hits query)
                (list-zotero-attachments-for-item item :bridge bridge)
              (declare (ignore query))
              hits))))
    (find (mind-and-mechanism-zotero-demo-attachment-key)
          attachments
          :key #'zotero-attachment-key-of
          :test #'string=)))

(defun mind-and-mechanism-zotero-path-resolution-report ()
  (let* ((bridge (make-zotero-live-demo-library))
         (item (mind-and-mechanism-zotero-item-hit))
         (attachment (mind-and-mechanism-zotero-attachment-hit)))
    (and attachment
         (resolve-zotero-stored-attachment-path attachment
                                                :bridge bridge
                                                :item-hit item))))

(defun mind-and-mechanism-zotero-resolution-report ()
  (resolve-zotero-title-to-local-pdf-report
   (mind-and-mechanism-zotero-demo-title)
   :bridge (make-zotero-live-demo-library)
   :match-mode :exact))

(defun martinez-zotero-demo-title ()
  (or (uiop:getenv "HYPERDOC_MARTINEZ_ZOTERO_DEMO_TITLE")
      "A Language Based on Two Relations between Symbols"))

(defun martinez-zotero-demo-item-id ()
  (or (getenv-integer "HYPERDOC_MARTINEZ_ZOTERO_ITEM_ID")
      61122))

(defun martinez-zotero-paper-attachment-key ()
  (or (uiop:getenv "HYPERDOC_MARTINEZ_ZOTERO_PAPER_ATTACHMENT_KEY")
      "8T3KSBAY"))

(defun martinez-zotero-supplement-attachment-key ()
  (or (uiop:getenv "HYPERDOC_MARTINEZ_ZOTERO_SUPPLEMENT_ATTACHMENT_KEY")
      "ZZ59IGHZ"))

(defun martinez-zotero-title-query ()
  (nth-value 1
             (lookup-zotero-items-by-title
              (martinez-zotero-demo-title)
              :bridge (make-zotero-live-demo-library)
              :match-mode :exact)))

(defun martinez-zotero-item-id-query ()
  (nth-value 1
             (lookup-zotero-item-by-id
              (martinez-zotero-demo-item-id)
              :bridge (make-zotero-live-demo-library))))

(defun martinez-zotero-item-hit ()
  (lookup-zotero-item-by-id
   (martinez-zotero-demo-item-id)
   :bridge (make-zotero-live-demo-library)))

(defun martinez-zotero-attachment-hit-by-key (attachment-key)
  (let* ((bridge (make-zotero-live-demo-library))
         (item (martinez-zotero-item-hit))
         (attachments
          (when item
            (multiple-value-bind (hits query)
                (list-zotero-attachments-for-item item :bridge bridge)
              (declare (ignore query))
              hits))))
    (find attachment-key
          attachments
          :key #'zotero-attachment-key-of
          :test #'string=)))

(defun martinez-zotero-paper-attachment-hit ()
  (martinez-zotero-attachment-hit-by-key
   (martinez-zotero-paper-attachment-key)))

(defun martinez-zotero-supplement-attachment-hit ()
  (martinez-zotero-attachment-hit-by-key
   (martinez-zotero-supplement-attachment-key)))

(defun martinez-zotero-path-resolution-report-for-attachment (attachment-key)
  (let* ((bridge (make-zotero-live-demo-library))
         (item (martinez-zotero-item-hit))
         (attachment (martinez-zotero-attachment-hit-by-key attachment-key)))
    (and attachment
         (resolve-zotero-attachment-path bridge
                                         attachment
                                         :item-hit item))))

(defun martinez-zotero-paper-path-resolution-report ()
  (martinez-zotero-path-resolution-report-for-attachment
   (martinez-zotero-paper-attachment-key)))

(defun martinez-zotero-supplement-path-resolution-report ()
  (martinez-zotero-path-resolution-report-for-attachment
   (martinez-zotero-supplement-attachment-key)))

(defun martinez-zotero-resolution-report-for-attachment
    (attachment-key query-title)
  (let* ((bridge (make-zotero-live-demo-library))
         (item-query (martinez-zotero-item-id-query))
         (item (martinez-zotero-item-hit))
         (attachments nil)
         (attachment-query nil))
    (when item
      (multiple-value-setq (attachments attachment-query)
        (list-zotero-attachments-for-item item :bridge bridge)))
    (let* ((attachment
            (find attachment-key
                  attachments
                  :key #'zotero-attachment-key-of
                  :test #'string=))
           (resolution
            (and attachment
                 (resolve-zotero-attachment-path bridge
                                                 attachment
                                                 :item-hit item)))
           (selected-evidence
            (and resolution
                 (make-zotero-resolution-evidence-from-report
                  resolution
                  nil)))
           (failure-mode
            (cond
              ((null item)
               :no-item-id-match)
              ((null attachment)
               :selected-attachment-missing)
              (resolution
               (or (zotero-path-report-failure-mode-of resolution)
                   (unless (zotero-path-report-exists-p resolution)
                     :resolved-pdf-missing)))
              (t
               :unresolved-attachment-path)))
           (detail
            (cond
              ((null item)
               (format nil "No Zotero item matched the configured Martínez item id ~A."
                       (martinez-zotero-demo-item-id)))
              ((null attachment)
               (format nil "No child attachment matched the configured key ~A."
                       attachment-key))
              (resolution
               (or (zotero-path-report-detail-of resolution)
                   (unless (zotero-path-report-exists-p resolution)
                     "The resolved PDF path does not exist.")))
              (t
               "Attachment resolution did not yield a report.")))
           (resolved-path
            (and resolution
                 (zotero-path-report-resolved-path-of resolution)))
           (exists-p
            (and resolution
                 (zotero-path-report-exists-p resolution))))
      (make-instance 'zotero-title-resolution-report
                     :bridge bridge
                     :query-title query-title
                     :item-query item-query
                     :attachment-query attachment-query
                     :item-candidates (and item (list item))
                     :attachment-candidates attachments
                     :attachment-resolutions (and resolution (list resolution))
                     :candidate-evidence (and selected-evidence
                                              (list selected-evidence))
                     :selected-item item
                     :selected-attachment attachment
                     :selected-resolution resolution
                     :selected-evidence selected-evidence
                     :evidence-chain
                     (remove nil (list item
                                       attachment
                                       resolution
                                       selected-evidence))
                     :resolved-path resolved-path
                     :exists-p exists-p
                     :status (or failure-mode :resolved)
                     :failure-mode failure-mode
                     :detail detail))))

(defun martinez-zotero-paper-resolution-report ()
  (martinez-zotero-resolution-report-for-attachment
   (martinez-zotero-paper-attachment-key)
   "A Language Based on Two Relations between Symbols [paper PDF]"))

(defun martinez-zotero-supplement-resolution-report ()
  (martinez-zotero-resolution-report-for-attachment
   (martinez-zotero-supplement-attachment-key)
   "A Language Based on Two Relations between Symbols [supplement PDF]"))
