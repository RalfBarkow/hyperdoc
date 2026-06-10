
(in-package :hyperdoc)


(defclass fedwiki-loader-store nil
          ((db-path :reader fedwiki-loader-db-path-of :initarg :db-path)
           (sqlite-program :reader fedwiki-loader-sqlite-program-of :initarg
            :sqlite-program :initform "sqlite3")))


(define-condition fedwiki-loadable-not-found
    (file-error)
    ((logical-path :reader fedwiki-loadable-logical-path-of :initarg
      :logical-path)
     (attempts :reader fedwiki-loadable-attempts-of :initarg :attempts
      :initform nil))
  (:report
   (lambda (condition stream)
     (format stream "Could not resolve loadable ~S. Attempts: ~S"
             (fedwiki-loadable-logical-path-of condition)
             (fedwiki-loadable-attempts-of condition)))))


(defun fedwiki-loader-sql-string (value)
  (if value
      (format nil "'~A'"
              (with-output-to-string (stream)
                (loop for char across (format nil "~A" value)
                      do (if (char= char #\')
                             (write-string "''" stream)
                             (write-char char stream)))))
      "NULL"))


(defun fedwiki-loader-run-sql (store sql &key json-p)
  (let ((command
         (append (list (fedwiki-loader-sqlite-program-of store))
                 (when json-p (list "-json"))
                 (list (namestring (fedwiki-loader-db-path-of store)) sql))))
    (multiple-value-bind (output error-output exit-code)
        (uiop/run-program:run-program command :output :string :error-output
                                      :output :ignore-error-status t)
      (declare (ignore error-output))
      (unless (zerop exit-code)
        (error "sqlite3 failed with exit code ~D: ~A" exit-code output))
      output)))


(defun make-default-fedwiki-loader-store
       (
        &key
        (db-path
         (merge-pathnames #P".cache/hyperdoc/fedwiki-loader.sqlite"
                          (uiop/os:getcwd)))
        (sqlite-program
         (or (uiop/os:getenv "HYPERDOC_SQLITE_PROGRAM") "sqlite3")))
  (ensure-fedwiki-loader-schema
   (make-instance 'fedwiki-loader-store :db-path db-path :sqlite-program
                  sqlite-program)))


(defun fedwiki-register-asset-alias
       (logical-path local-path
        &key system-name asset-kind site-domain page-slug asset-path
        (priority 100) (store (make-default-fedwiki-loader-store)))
  (ensure-fedwiki-loader-schema store)
  (fedwiki-loader-run-sql store
                          (format nil
                                  "INSERT OR REPLACE INTO fedwiki_asset_aliases
            (logical_path, system_name, asset_kind, site_domain, page_slug,
             asset_path, local_path, priority, updated_at)
            VALUES (~A, ~A, ~A, ~A, ~A, ~A, ~A, ~D, current_timestamp);"
                                  (fedwiki-loader-sql-string logical-path)
                                  (fedwiki-loader-sql-string system-name)
                                  (fedwiki-loader-sql-string asset-kind)
                                  (fedwiki-loader-sql-string site-domain)
                                  (fedwiki-loader-sql-string page-slug)
                                  (fedwiki-loader-sql-string asset-path)
                                  (fedwiki-loader-sql-string
                                   (namestring local-path))
                                  priority))
  logical-path)


(defun fedwiki-loader-first-json-row (output)
  (when
      (and output
           (plusp
            (length (string-trim '(#\  #\Tab #\Newline #\Return) output))))
    (let ((data (shasht:read-json output)))
      (typecase data
        (vector (and (plusp (length data)) (aref data 0)))
        (list (first data))
        (t nil)))))


(defvar *original-clog-load-tutorial* nil)


(defvar *default-fedwiki-loader-store* nil)


(defun default-fedwiki-loader-store ()
  (or *default-fedwiki-loader-store*
      (setf *default-fedwiki-loader-store*
              (make-default-fedwiki-loader-store))))


(defun load-fedwiki-resolved-file
       (logical-path &key system-name store verbose print)
  (let* ((effective-store (or store (default-fedwiki-loader-store)))
         (pathname
          (fedwiki-resolve-loadable logical-path :system-name system-name
                                    :store effective-store)))
    (load pathname :verbose verbose :print print)))


(defun install-clog-tutorial-fedwiki-loader (&key store)
  "Patch only CLOG:LOAD-TUTORIAL. Keep original function as fallback target."
  (let* ((effective-store (or store (default-fedwiki-loader-store)))
         (package (find-package :clog))
         (symbol (and package (find-symbol "LOAD-TUTORIAL" package))))
    (unless (and symbol (fboundp symbol))
      (error "CLOG:LOAD-TUTORIAL is not available in this image."))
    (unless *original-clog-load-tutorial*
      (setf *original-clog-load-tutorial* (symbol-function symbol)))
    (setf (symbol-function symbol)
            (lambda (number)
              (handler-case (funcall *original-clog-load-tutorial* number)
                            (file-error nil
                             (let ((logical-path
                                    (format nil
                                            "clog/./tutorial/~2,'0D-tutorial.lisp"
                                            number)))
                               (load-fedwiki-resolved-file logical-path
                                                           :system-name "clog"
                                                           :store
                                                           effective-store)))))))
  :installed)


(defun fedwiki-loader-default-root ()
  (or
   (ignore-errors
    (when (boundp '*hyperdoc-root*)
      (truename (symbol-value '*hyperdoc-root*))))
   (ignore-errors (asdf/system:system-source-directory :hyperdoc))
   (ignore-errors (truename #P"/Users/rgb/workspace/hyperdoc/"))
   (uiop/os:getcwd)))


(defun fedwiki-loader-string-prefix-p (prefix string)
  (let ((prefix (string prefix)) (string (string string)))
    (and (<= (length prefix) (length string))
         (string= prefix string :end2 (length prefix)))))


(defun fedwiki-loader-drop-prefix (prefix string)
  (if (fedwiki-loader-string-prefix-p prefix string)
      (subseq string (length prefix))
      string))


(defun fedwiki-loader-normalize-logical-asset-path
       (logical-path &key system-name)
  (let* ((path (namestring (pathname logical-path)))
         (system-prefix
          (and system-name
               (format nil "~A/" (string-downcase (string system-name)))))
         (without-system
          (if system-prefix
              (fedwiki-loader-drop-prefix system-prefix path)
              path)))
    (fedwiki-loader-drop-prefix "./" without-system)))


(defun fedwiki-loader-slug-character (character)
  (cond ((alphanumericp character) (char-downcase character)) (t #\-)))


(defun fedwiki-loader-collapse-hyphens (string)
  (with-output-to-string (out)
    (let ((previous-hyphen-p nil))
      (loop for character across string
            for hyphen-p = (char= character #\-)
            do (unless (and hyphen-p previous-hyphen-p)
                 (write-char character out)) (setf previous-hyphen-p
                                                     hyphen-p)))))


(defun fedwiki-loader-trim-hyphens (string) (string-trim "-" string))


(defun fedwiki-loader-slugify (value)
  (fedwiki-loader-trim-hyphens
   (fedwiki-loader-collapse-hyphens
    (map 'string #'fedwiki-loader-slug-character (string value)))))


(defun fedwiki-loader-page-slug-for-logical-path
       (logical-path &key system-name page-slug)
  (or page-slug
      (let ((asset-path
             (fedwiki-loader-normalize-logical-asset-path logical-path
                                                          :system-name
                                                          system-name)))
        (cond
         ((and system-name (string-equal (string system-name) "clog")
               (fedwiki-loader-string-prefix-p "tutorial/" asset-path))
          "clog-tutorials")
         (system-name (fedwiki-loader-slugify system-name))
         (t "loadable-assets")))))


(defun fedwiki-loader-page-asset-pathname
       (logical-path &key system-name page-slug root)
  (let* ((root (or root (fedwiki-loader-default-root)))
         (slug
          (fedwiki-loader-page-slug-for-logical-path logical-path :system-name
                                                     system-name :page-slug
                                                     page-slug))
         (asset-path
          (fedwiki-loader-normalize-logical-asset-path logical-path
                                                       :system-name
                                                       system-name))
         (relative (format nil "assets/pages/~A/~A" slug asset-path)))
    (merge-pathnames relative root)))


(defun fedwiki-loader-page-asset-attempt
       (logical-path &key system-name page-slug root)
  (let ((candidate
         (fedwiki-loader-page-asset-pathname logical-path :system-name
                                             system-name :page-slug page-slug
                                             :root root)))
    (if (probe-file candidate)
        (values (truename candidate)
                (list :stage :page-attached-asset :status :hit :detail
                      (namestring candidate)))
        (values nil
                (list :stage :page-attached-asset :status :miss :detail
                      (namestring candidate))))))


(defun fedwiki-loader-sqlite-alias-attempt
       (logical-path &key system-name store)
  (handler-case
   (let* ((store (or store (default-fedwiki-loader-store))))
     (ensure-fedwiki-loader-schema store)
     (let ((row
            (fedwiki-loader-first-json-row
             (fedwiki-loader-run-sql store
                                     (format nil "select resolved_path
                                 from loadable_asset_aliases
                                where logical_path = ~A
                                  and (~A is null or system_name = ~A)
                                order by id desc
                                limit 1;"
                                             (fedwiki-loader-sql-string
                                              logical-path)
                                             (fedwiki-loader-sql-string
                                              system-name)
                                             (fedwiki-loader-sql-string
                                              system-name))
                                     :json-p t))))
       (if row
           (let ((resolved (cdr (assoc :|resolved_path| row))))
             (if (and resolved (probe-file resolved))
                 (values (truename resolved)
                         (list :stage :sqlite-alias :status :hit :detail
                               resolved))
                 (values nil
                         (list :stage :sqlite-alias :status :dangling :detail
                               resolved))))
           (values nil
                   (list :stage :sqlite-alias :status :miss :detail
                         logical-path)))))
   (condition (condition)
    (values nil
            (list :stage :sqlite-alias :status :error :detail
                  (princ-to-string condition))))))


(defun fedwiki-resolve-loadable (logical-path &key system-name page-slug store)
  "Resolve LOGICAL-PATH using:
  1. direct pathname;
  2. FedWiki page-attached asset convention;
  3. SQLite asset alias table.

The page-attached convention is:
  assets/pages/<page-slug>/<asset-path>"
  (let ((attempts nil))
    (labels ((record (attempt)
               (push attempt attempts))
             (finish (pathname)
               (return-from fedwiki-resolve-loadable pathname)))
      (let ((direct (pathname logical-path)))
        (if (probe-file direct)
            (progn
             (record
              (list :stage :exact-path :status :hit :detail
                    (namestring direct)))
             (finish (truename direct)))
            (record
             (list :stage :exact-path :status :miss :detail
                   (namestring direct)))))
      (multiple-value-bind (pathname attempt)
          (fedwiki-loader-page-asset-attempt logical-path :system-name
                                             system-name :page-slug page-slug)
        (record attempt)
        (when pathname (finish pathname)))
      (multiple-value-bind (pathname attempt)
          (fedwiki-loader-sqlite-alias-attempt logical-path :system-name
                                               system-name :store store)
        (record attempt)
        (when pathname (finish pathname)))
      (error 'fedwiki-loadable-not-found :logical-path logical-path :attempts
             (nreverse attempts)))))


(defun ensure-fedwiki-loader-schema (store)
  "Ensure the SQLite objects used by the FedWiki loader exist.

This function is intentionally idempotent: callers may run it before
every alias lookup.  A missing alias table is not an exceptional
repository state; it simply means there are no registered aliases yet."
  (fedwiki-loader-run-sql store
                          "create table if not exists loadable_asset_aliases (
          id integer primary key autoincrement,
          logical_path text not null,
          system_name text,
          resolved_path text not null,
          created_at text not null default (datetime('now'))
        );")
  (fedwiki-loader-run-sql store
                          "create index if not exists loadable_asset_aliases_lookup_idx
          on loadable_asset_aliases(logical_path, system_name, id);")
  store)


(export
 '(make-default-fedwiki-loader-store default-fedwiki-loader-store
                                     ensure-fedwiki-loader-schema
                                     fedwiki-register-asset-alias
                                     fedwiki-resolve-loadable
                                     load-fedwiki-resolved-file
                                     install-clog-tutorial-fedwiki-loader
                                     uninstall-clog-tutorial-fedwiki-loader
                                     fedwiki-loadable-not-found
                                     fedwiki-loadable-logical-path-of
                                     fedwiki-loadable-attempts-of)
 :hyperdoc)

