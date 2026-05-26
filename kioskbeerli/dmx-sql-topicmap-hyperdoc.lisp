(defpackage #:kioskbeerli.dmx-sql-topicmap-hyperdoc
  (:use #:cl)
  (:export
   #:dmx-sql-topicmap-hyperdoc-topics
   #:dmx-sql-topicmap-hyperdoc-assocs
   #:dmx-sql-topicmap-hyperdoc-native-model
   #:dmx-sql-topicmap-hyperdoc-projection
   #:dmx-sql-topicmap-html-fragment))

(in-package #:kioskbeerli.dmx-sql-topicmap-hyperdoc)

(defun plist-value (plist key)
  (getf plist key))

(defun keyword-from-string (string &key (fallback :topic))
  (let ((text (string-trim '(#\Space #\Tab #\Newline #\Return)
                           (or string ""))))
    (if (string= text "")
        fallback
        (intern
         (string-upcase
          (substitute #\- #\_ text))
         "KEYWORD"))))

(defun topic-content-text (node)
  (with-output-to-string (stream)
    (format stream "id: ~A~%" (plist-value node :id))
    (format stream "kind: ~A~%" (plist-value node :kind))
    (format stream "type-uri: ~A~%" (plist-value node :type-uri))
    (format stream "uri: ~A~%" (plist-value node :uri))
    (format stream "value: ~A~%" (plist-value node :value))))

(defun assoc-content-text (edge)
  (with-output-to-string (stream)
    (format stream "id: ~A~%" (plist-value edge :id))
    (format stream "type-uri: ~A~%" (plist-value edge :type-uri))
    (format stream "from: ~A~%" (plist-value edge :from))
    (format stream "from-role: ~A~%" (plist-value edge :from-role))
    (format stream "to: ~A~%" (plist-value edge :to))
    (format stream "to-role: ~A~%" (plist-value edge :to-role))))

(defun dmx-sql-topicmap-hyperdoc-topics (projection)
  "Convert SQL projection payload nodes into HyperDoc-friendly topic plists."
  (let* ((payload
           (kioskbeerli.dmx-sql-topicmap:projection-topicmap-payload
            projection))
         (nodes (getf payload :nodes)))
    (loop for node in nodes
          collect
          (list :id (plist-value node :id)
                :uri (plist-value node :uri)
                :type-uri (plist-value node :type-uri)
                :label (plist-value node :label)
                :value (plist-value node :value)
                :kind (plist-value node :kind)))))

(defun dmx-sql-topicmap-hyperdoc-assocs (projection)
  "Convert SQL projection payload edges into HyperDoc-friendly assoc plists."
  (let* ((payload
           (kioskbeerli.dmx-sql-topicmap:projection-topicmap-payload
            projection))
         (edges (getf payload :edges)))
    (loop for edge in edges
          collect
          (list :id (plist-value edge :id)
                :type-uri (plist-value edge :type-uri)
                :label (plist-value edge :label)
                :from (plist-value edge :from)
                :to (plist-value edge :to)
                :from-role (plist-value edge :from-role)
                :to-role (plist-value edge :to-role)))))

(defun dmx-sql-topicmap-hyperdoc-native-model (projection)
  "Renderer-neutral native model for inspection and tests."
  (let ((summary
          (kioskbeerli.dmx-sql-topicmap:projection-summary projection)))
    (list :kind :dmx-sql-topicmap-native-model
          :title (getf summary :title)
          :db-path (namestring (getf summary :db-path))
          :summary summary
          :topics (dmx-sql-topicmap-hyperdoc-topics projection)
          :assocs (dmx-sql-topicmap-hyperdoc-assocs projection))))

(defun parsed-topic-from-node (node)
  (make-instance
   'hyperdoc:parsed-topic
   :id (plist-value node :id)
   :title (or (plist-value node :label)
              (plist-value node :id))
   :kind (keyword-from-string (plist-value node :kind)
                              :fallback :topic)
   :content (topic-content-text node)
   :source-target (plist-value node :uri)
   :source-index nil))

(defun parsed-relation-from-edge (edge)
  (make-instance
   'hyperdoc:parsed-relation
   :from (plist-value edge :from)
   :to (plist-value edge :to)
   :kind (keyword-from-string (plist-value edge :label)
                              :fallback :association)
   :evidence (assoc-content-text edge)))

(defun projection-layout-for-node-ids (node-ids)
  "Simple deterministic grid layout for the DM6 inline topicmap renderer.

The SQL payload already carries stable node IDs, so the layout can remain
independent of HyperDoc runtime object identity."
  (loop for node-id in node-ids
        for i from 0
        for column = (mod i 4)
        for row = (floor i 4)
        collect
        (cons node-id
              (list :x (+ 120 (* column 300))
                    :y (+ 110 (* row 120))))))

(defun projection-source-text (projection)
  (let* ((summary
           (kioskbeerli.dmx-sql-topicmap:projection-summary projection))
         (payload
           (kioskbeerli.dmx-sql-topicmap:projection-topicmap-payload
            projection)))
    (with-output-to-string (stream)
      (format stream "~A~%~%" (getf summary :title))
      (format stream "DB: ~A~%" (getf summary :db-path))
      (format stream "Nodes: ~D~%" (getf summary :node-count))
      (format stream "Edges: ~D~%" (getf summary :edge-count))
      (format stream "Trace events: ~D~%" (getf summary :trace-event-count))
      (format stream "Provenance edges: ~D~%" (getf summary :provenance-edge-count))
      (format stream "~%Payload keys: ~S~%" (loop for (k v) on payload by #'cddr collect k)))))

(defun dmx-sql-topicmap-hyperdoc-projection (projection)
  "Project the Kioskbeerli SQL mirror projection into HyperDoc's native topicmap IR.

This is the missing dispatch bridge that makes
HYPERDOC:PROJECT-OBJECT-TO-TOPICMAP and
HYPERDOC:RENDER-TOPICMAP-VIEW-OF-OBJECT-HTML return non-NIL."
  (let* ((payload
           (kioskbeerli.dmx-sql-topicmap:projection-topicmap-payload
            projection))
         (nodes (getf payload :nodes))
         (edges (getf payload :edges))
         (topics (mapcar #'parsed-topic-from-node nodes))
         (relations (mapcar #'parsed-relation-from-edge edges))
         (source
           (hyperdoc:source-content-from-object
            projection
            :title (kioskbeerli.dmx-sql-topicmap:projection-title projection)
            :text (projection-source-text projection))))
    (make-instance
     'hyperdoc:topicmap-projection
     :source source
     :topics topics
     :relations relations
     :layout (projection-layout-for-node-ids
         (mapcar (lambda (node)
                   (plist-value node :id))
                 nodes)))))

(defmethod hyperdoc:topicmap-projection-of
    ((projection kioskbeerli.dmx-sql-topicmap:dmx-sql-topicmap-projection))
  (dmx-sql-topicmap-hyperdoc-projection projection))

(defmethod hyperdoc:topicmap-view-title-of
    ((projection kioskbeerli.dmx-sql-topicmap:dmx-sql-topicmap-projection))
  (kioskbeerli.dmx-sql-topicmap:projection-title projection))

(defmethod hyperdoc:topicmap-view-input-owner-of
    ((projection kioskbeerli.dmx-sql-topicmap:dmx-sql-topicmap-projection))
  "kioskbeerli-dmx-sql-topicmap")

(defun html-escape (value)
  (let ((text (format nil "~A" (or value ""))))
    (with-output-to-string (stream)
      (loop for ch across text
            do (case ch
                 (#\< (write-string "&lt;" stream))
                 (#\> (write-string "&gt;" stream))
                 (#\& (write-string "&amp;" stream))
                 (#\" (write-string "&quot;" stream))
                 (otherwise (write-char ch stream)))))))

(defun dmx-sql-topicmap-html-fragment (projection)
  "Fallback HTML proof view.

The real visual path should use HYPERDOC:RENDER-TOPICMAP-VIEW-OF-OBJECT-HTML.
This fallback is kept for debugging when the DM6 island is not mounted."
  (let* ((model (dmx-sql-topicmap-hyperdoc-native-model projection))
         (topics (getf model :topics))
         (assocs (getf model :assocs))
         (summary (getf model :summary)))
    (with-output-to-string (stream)
      (format stream "<section class='kioskbeerli-dmx-sql-topicmap'>~%")
      (format stream "<h2>~A</h2>~%" (html-escape (getf model :title)))
      (format stream "<p><strong>DB:</strong> ~A</p>~%"
              (html-escape (getf model :db-path)))
      (format stream "<p><strong>Nodes:</strong> ~D &nbsp; <strong>Edges:</strong> ~D &nbsp; <strong>Trace events:</strong> ~D &nbsp; <strong>Provenance edges:</strong> ~D</p>~%"
              (getf summary :node-count)
              (getf summary :edge-count)
              (getf summary :trace-event-count)
              (getf summary :provenance-edge-count))
      (format stream "<h3>Trace event topics</h3>~%<ul>~%")
      (dolist (topic topics)
        (when (string= (getf topic :type-uri)
                       "hyperdoc.kioskbeerli.trace_event")
          (format stream "<li><code>~A</code> - ~A</li>~%"
                  (html-escape (getf topic :id))
                  (html-escape (getf topic :label)))))
      (format stream "</ul>~%")
      (format stream "<h3>Associations</h3>~%<ul>~%")
      (dolist (assoc assocs)
        (format stream "<li><code>~A</code>: <code>~A</code> --~A--> <code>~A</code></li>~%"
                (html-escape (getf assoc :id))
                (html-escape (getf assoc :from))
                (html-escape (getf assoc :label))
                (html-escape (getf assoc :to))))
      (format stream "</ul>~%")
      (format stream "</section>~%"))))
