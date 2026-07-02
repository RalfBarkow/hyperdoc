;;;; FedWiki page projection from the asset-local DMX SQLite database.

(in-package #:the-1998-ai-planning-systems-competition)

(defun split-lines (string)
  (loop with start = 0
        for position = (position #\Newline string :start start)
        collect (subseq string start position)
        while position
        do (setf start (1+ position))))

(defun split-tabs (string)
  (loop with start = 0
        for position = (position #\Tab string :start start)
        collect (subseq string start position)
        while position
        do (setf start (1+ position))))

(defun json-string (value)
  (with-output-to-string (stream)
    (write-char #\" stream)
    (loop for ch across (format nil "~A" (or value ""))
          do (case ch
               (#\" (write-string "\\\"" stream))
               (#\\ (write-string "\\\\" stream))
               (#\Newline (write-string "\\n" stream))
               (#\Return (write-string "\\r" stream))
               (#\Tab (write-string "\\t" stream))
               (otherwise (write-char ch stream))))
    (write-char #\" stream)))

(defun story-rows (db-path)
  (let* ((stdout
           (sqlite-exec
            db-path
            (format nil
                    "SELECT item_id, item_type, text FROM fedwiki_story_items WHERE page_slug = ~A ORDER BY item_order;"
                    (sql-literal *reading-slug*))
            :separator (string #\Tab)))
         (lines (remove "" (split-lines stdout) :test #'string=)))
    (mapcar #'split-tabs lines)))

(defun page-title-from-db (db-path)
  (sqlite-scalar
   db-path
   (format nil "SELECT title FROM fedwiki_pages WHERE slug = ~A;"
           (sql-literal *reading-slug*))))

(defun journal-date-from-db (db-path)
  (sqlite-scalar
   db-path
   (format nil
           "SELECT date_epoch_ms FROM fedwiki_journal_actions WHERE page_slug = ~A ORDER BY action_order LIMIT 1;"
           (sql-literal *reading-slug*))))

(defun story-item-json (row)
  (destructuring-bind (id type text) row
    (format nil
            "    {~%      \"type\": ~A,~%      \"id\": ~A,~%      \"text\": ~A~%    }"
            (json-string type)
            (json-string id)
            (json-string text))))

(defun reconstruct-fedwiki-page-json-string
    (&key (db-path (asset-db-pathname)))
  "Return the FedWiki page JSON projection reconstructed from DB-PATH."
  (let ((title (page-title-from-db db-path))
        (story (story-rows db-path))
        (journal-date (journal-date-from-db db-path)))
    (with-output-to-string (stream)
      (format stream "{~%  \"title\": ~A,~%  \"story\": [~%"
              (json-string title))
      (loop for row in story
            for firstp = t then nil
            unless firstp do (format stream ",~%")
            do (write-string (story-item-json row) stream))
      (format stream "~%  ],~%  \"journal\": [~%")
      (format stream
              "    {~%      \"type\": \"create\",~%      \"date\": ~A,~%      \"item\": {~%        \"title\": ~A~%      }~%    }~%"
              journal-date
              (json-string title))
      (format stream "  ]~%}~%"))))

(defun file-string (pathname)
  (when (probe-file pathname)
    (with-open-file (stream pathname :direction :input :external-format :utf-8)
      (let ((string (make-string (file-length stream))))
        (read-sequence string stream)
        string))))

(defun write-string-file-if-changed (pathname string)
  (ensure-directories-exist pathname)
  (let ((existing (file-string pathname)))
    (if (and existing (string= existing string))
        :unchanged
        (progn
          (with-open-file (stream pathname
                                  :direction :output
                                  :if-exists :supersede
                                  :if-does-not-exist :create
                                  :external-format :utf-8)
            (write-string string stream))
          (if existing :updated :created)))))

(defun materialize-fedwiki-page-from-dmx
    (&key (db-path (asset-db-pathname))
       (page-path (page-json-pathname)))
  "Write the FedWiki page JSON projection from DB-PATH to PAGE-PATH."
  (let* ((json (reconstruct-fedwiki-page-json-string :db-path db-path))
         (state (write-string-file-if-changed page-path json)))
    (list :page-path page-path
          :relative-page-path (relative-artifact-path page-path)
          :state state
          :bytes (length json))))
