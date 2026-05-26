(defpackage #:kioskberrli.dmx-sql-topicmap
  (:use #:cl)
  (:export
   #:dmx-sql-topicmap-node
   #:dmx-sql-topicmap-edge
   #:dmx-sql-topicmap-projection
   #:make-dmx-sql-topicmap-projection
   #:projection-nodes
   #:projection-edges
   #:projection-summary
   #:print-dmx-sql-topicmap-projection))

(in-package #:kioskberrli.dmx-sql-topicmap)

(defstruct dmx-sql-topicmap-node
  id
  label
  kind
  type-uri
  uri
  value)

(defstruct dmx-sql-topicmap-edge
  id
  label
  type-uri
  from
  to
  from-role
  to-role)

(defclass dmx-sql-topicmap-projection ()
  ((db-path
    :initarg :db-path
    :reader projection-db-path)
   (title
    :initarg :title
    :initform "DMX SQL Topicmap Projection"
    :reader projection-title)
   (nodes
    :initarg :nodes
    :initform nil
    :reader projection-nodes)
   (edges
    :initarg :edges
    :initform nil
    :reader projection-edges)
   (source-sql
    :initarg :source-sql
    :initform nil
    :reader projection-source-sql)))

(defun sqlite-lines (db-path sql)
  (multiple-value-bind (stdout stderr exit-code)
      (uiop:run-program
       (list "sqlite3" "-tabs" "-noheader" (namestring db-path) sql)
       :output :string
       :error-output :string
       :ignore-error-status t)
    (unless (zerop exit-code)
      (error "sqlite3 failed with exit code ~A: ~A" exit-code stderr))
    (remove "" (uiop:split-string stdout :separator '(#\Newline))
            :test #'string=)))

(defun split-tab-row (line)
  (uiop:split-string line :separator '(#\Tab)))

(defun short-label (string)
  (let ((text (or string "")))
    (cond
      ((search ":" text :from-end t)
       (subseq text (1+ (position #\: text :from-end t))))
      ((search "." text :from-end t)
       (subseq text (1+ (position #\. text :from-end t))))
      (t text))))

(defun read-dmx-sql-topicmap-nodes (db-path)
  (loop for line in
        (sqlite-lines
         db-path
         "select local_id,
                 object_kind,
                 coalesce(uri, ''),
                 type_uri,
                 coalesce(value, '')
            from dmx_sql_object
           where object_kind = 'topic'
              or type_uri in (
                'hyperdoc.kioskberrli.trace_event',
                'hyperdoc.kioskberrli.task',
                'hyperdoc.kioskberrli.state',
                'hyperdoc.kioskberrli.status',
                'dmx.notes.note'
              )
           order by object_kind, type_uri, local_id;")
        for row = (split-tab-row line)
        for local-id = (first row)
        for kind = (second row)
        for uri = (third row)
        for type-uri = (fourth row)
        for value = (fifth row)
        collect
        (make-dmx-sql-topicmap-node
         :id local-id
         :label (or (and value (plusp (length value)) value)
                    (short-label local-id))
         :kind kind
         :type-uri type-uri
         :uri uri
         :value value)))

(defun read-dmx-sql-topicmap-edges (db-path)
  (loop for line in
        (sqlite-lines
         db-path
         "select a.local_id,
                 a.type_uri,
                 p1.player_local_id,
                 p1.role_type_uri,
                 p2.player_local_id,
                 p2.role_type_uri
            from dmx_sql_object a
            join dmx_sql_assoc_player p1
              on p1.assoc_id = a.local_id
             and p1.player_no = 1
            join dmx_sql_assoc_player p2
              on p2.assoc_id = a.local_id
             and p2.player_no = 2
           where a.object_kind = 'assoc'
           order by a.local_id;")
        for row = (split-tab-row line)
        for assoc-id = (first row)
        for assoc-type = (second row)
        for from = (third row)
        for from-role = (fourth row)
        for to = (fifth row)
        for to-role = (sixth row)
        collect
        (make-dmx-sql-topicmap-edge
         :id assoc-id
         :label (short-label assoc-type)
         :type-uri assoc-type
         :from from
         :to to
         :from-role from-role
         :to-role to-role)))

(defun make-dmx-sql-topicmap-projection
    (&key
       db-path
       (title "Kioskberrli DMX associative SQL mirror"))
  (unless db-path
    (error "DB-PATH is required."))
  (unless (probe-file db-path)
    (error "Database not found: ~A" db-path))
  (make-instance
   'dmx-sql-topicmap-projection
   :db-path db-path
   :title title
   :nodes (read-dmx-sql-topicmap-nodes db-path)
   :edges (read-dmx-sql-topicmap-edges db-path)
   :source-sql
   '("dmx_sql_object"
     "dmx_sql_assoc"
     "dmx_sql_assoc_player"
     "dmx_sql_sync_identity"
     "dmx_sql_sync_journal")))

(defun projection-summary (projection)
  (list
   :title (projection-title projection)
   :db-path (projection-db-path projection)
   :node-count (length (projection-nodes projection))
   :edge-count (length (projection-edges projection))
   :trace-event-count
   (count "hyperdoc.kioskberrli.trace_event"
          (projection-nodes projection)
          :key #'dmx-sql-topicmap-node-type-uri
          :test #'string=)
   :provenance-edge-count
   (count "hyperdoc.assoc.has_provenance"
          (projection-edges projection)
          :key #'dmx-sql-topicmap-edge-type-uri
          :test #'string=)))

(defun print-dmx-sql-topicmap-projection
    (projection &optional (stream *standard-output*))
  (format stream "~&~A~%" (projection-title projection))
  (format stream "DB: ~A~%" (projection-db-path projection))
  (format stream "Nodes: ~D~%" (length (projection-nodes projection)))
  (format stream "Edges: ~D~%" (length (projection-edges projection)))
  (format stream "~%Trace event nodes:~%")
  (dolist (node (projection-nodes projection))
    (when (string= (dmx-sql-topicmap-node-type-uri node)
                   "hyperdoc.kioskberrli.trace_event")
      (format stream "  ~A  ~A~%"
              (dmx-sql-topicmap-node-id node)
              (dmx-sql-topicmap-node-label node))))
  (format stream "~%Edges:~%")
  (dolist (edge (projection-edges projection))
    (format stream "  ~A --~A--> ~A~%"
            (dmx-sql-topicmap-edge-from edge)
            (dmx-sql-topicmap-edge-label edge)
            (dmx-sql-topicmap-edge-to edge)))
  projection)
