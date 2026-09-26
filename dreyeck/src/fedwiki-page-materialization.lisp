;;;; Persist raw Federated Wiki Page JSON in a local site store

(in-package #:dreyeck/fedwiki-page-materialization)

(defun %copy-json-value (value)
  "Return a recursively independent copy of a JSON-compatible Lisp value."
  (typecase value
    (hash-table
     (let ((copy
             (make-hash-table :test #'equal)))
       (maphash
        (lambda (key item)
          (setf
           (gethash key copy)
           (%copy-json-value item)))
        value)
       copy))
    (string
     (copy-seq value))
    (vector
     (map 'vector #'%copy-json-value value))
    (cons
     (mapcar #'%copy-json-value value))
    (t
     value)))

(defun %make-fork-entry (source-site fork-date)
  (check-type source-site string)
  (check-type fork-date integer)
  (let ((entry
          (make-hash-table :test #'equal)))
    (setf
     (gethash "type" entry) "fork"
     (gethash "site" entry) source-site
     (gethash "date" entry) fork-date)
    entry))

(defun page-json-with-fork
    (page-json
     &key
       source-site
       fork-date)
  "Return an independent copy of PAGE-JSON with one fork journal entry appended.

PAGE-JSON itself is not modified. SOURCE-SITE and FORK-DATE describe the
appended Federated Wiki fork relation."
  (check-type page-json hash-table)
  (let* ((copy
           (%copy-json-value page-json))
         (journal
           (multiple-value-bind (value present-p)
               (gethash "journal" copy)
             (if present-p
                 value
                 #()))))
    (check-type journal vector)
    (setf
     (gethash "journal" copy)
     (concatenate
      'vector
      journal
      (vector
       (%make-fork-entry
        source-site
        fork-date))))
    copy))

(defun %temporary-page-pathname (target)
  "Create a new, empty file beside TARGET and return its pathname.

The file is created exclusively: a name another writer already holds, in
this process or another, is passed over and never opened, so concurrent
materializations never share a temporary file. Names are numbered from a
process-wide counter that is incremented atomically; the exclusive creation,
not the number, is what guarantees a file of one's own."
  (loop repeat 1000
        for number = (sb-ext:atomic-incf (car (load-time-value (list 0))))
        for candidate = (make-pathname
                         :name (format nil ".~A.~D.tmp" (or (pathname-name target) "page") number)
                         :type nil
                         :defaults target)
        when (with-open-file (stream candidate :direction :output
                                               :if-exists nil
                                               :if-does-not-exist :create)
               (and stream t))
          return candidate
        finally (error "No free temporary file name beside ~A." target)))

(defun materialize-fedwiki-page-json
    (page-json
     site-root
     slug
     &key
       (if-exists :error))
  "Persist PAGE-JSON as SITE-ROOT/pages/SLUG without changing its semantics.

The input PAGE-JSON is not modified. The JSON is written through a temporary
file in the target directory and then renamed over the target. Existing page
files are rejected by default. IF-EXISTS may be :ERROR or :SUPERSEDE."
  (check-type page-json hash-table)
  (check-type slug string)

  (unless
      (member if-exists
              '(:error :supersede)
              :test #'eq)
    (error
     "Unsupported IF-EXISTS policy: ~S"
     if-exists))

  (let* ((target
           (dreyeck/fedwiki-assets:local-fedwiki-page-pathname
            site-root
            slug))
         (materialized-json
           (%copy-json-value page-json)))

    (when
        (and
         (eq if-exists :error)
         (probe-file target))
      (error
       "Local FedWiki page already exists: ~A"
       target))

    (ensure-directories-exist target)

    (let ((temporary
            (%temporary-page-pathname target)))
      (unwind-protect
           (progn
             (with-open-file
                 (output temporary
                         :direction :output
                         :if-exists :supersede
                         :if-does-not-exist :create
                         :external-format :utf-8)
               (let ((*print-pretty* t)
                     (shasht:*write-indent-string* "  "))
                 (shasht:write-json
                  materialized-json
                  output))
               (terpri output))

             (uiop:rename-file-overwriting-target
              temporary
              target)

             (setf temporary nil)
             target)

        (when
            (and temporary
                 (probe-file temporary))
          (delete-file temporary))))))

(defun materialize-fedwiki-page-fork
    (page-json
     site-root
     slug
     &key
       source-site
       fork-date
       (if-exists :error))
  "Append explicit FedWiki fork provenance and persist the resulting page.

Unlike MATERIALIZE-FEDWIKI-PAGE-JSON, this operation deliberately changes the
page journal by adding one fork entry."
  (materialize-fedwiki-page-json
   (page-json-with-fork
    page-json
    :source-site source-site
    :fork-date fork-date)
   site-root
   slug
   :if-exists if-exists))
