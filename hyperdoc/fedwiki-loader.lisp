
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


(defun ensure-fedwiki-loader-schema (store)
  (ensure-directories-exist
   (uiop/pathname:pathname-directory-pathname
    (fedwiki-loader-db-path-of store)))
  (fedwiki-loader-run-sql store
                          "CREATE TABLE IF NOT EXISTS fedwiki_asset_aliases (
      logical_path text primary key,
      system_name text,
      asset_kind text,
      site_domain text,
      page_slug text,
      asset_path text,
      local_path text,
      priority integer default 100,
      updated_at text default current_timestamp
    );

    CREATE TABLE IF NOT EXISTS fedwiki_resolution_attempts (
      id text primary key,
      logical_path text,
      stage text,
      status text,
      detail text,
      created_at text default current_timestamp
    );")
  store)


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


(defun fedwiki-resolve-loadable
       (logical-path
        &key (store (make-default-fedwiki-loader-store)) system-name)
  (let ((attempts nil))
    (labels ((note (stage status detail)
               (push (list :stage stage :status status :detail detail)
                     attempts)))
      (let ((p (ignore-errors (pathname logical-path))))
        (when (and p (probe-file p))
          (note :exact-path :ok (namestring p))
          (return-from fedwiki-resolve-loadable (truename p)))
        (note :exact-path :miss logical-path))
      (let* ((sql
              (format nil "SELECT local_path FROM fedwiki_asset_aliases
                           WHERE logical_path = ~A
                           ~@[AND system_name = ~A~]
                           ORDER BY priority ASC
                           LIMIT 1;"
                      (fedwiki-loader-sql-string logical-path)
                      (and system-name
                           (fedwiki-loader-sql-string system-name))))
             (row
              (fedwiki-loader-first-json-row
               (fedwiki-loader-run-sql store sql :json-p t)))
             (local-path (and row (gethash "local_path" row))))
        (cond
         ((and local-path (probe-file local-path))
          (note :sqlite-alias :ok local-path)
          (return-from fedwiki-resolve-loadable (truename local-path)))
         (local-path (note :sqlite-alias :stale local-path))
         (t (note :sqlite-alias :miss logical-path))))
      (restart-case (error 'fedwiki-loadable-not-found :logical-path
                           logical-path :attempts (nreverse attempts) :pathname
                           logical-path)
        (use-value (pathname) :report "Use a pathname for this loadable."
                   pathname)))))


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

