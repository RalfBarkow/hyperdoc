;;;; Experimental layout/rendering boundary; no Topicmap model mutation.
(defpackage #:dreyeck/topicmap/tala
  (:use #:cl)
  (:local-nicknames (#:tm #:dreyeck/topicmap))
  (:export #:tala-input #:projection-tala-input #:tala-input-projection
           #:tala-input-source #:tala-input-topics #:tala-input-associations
           #:tala-input-seed #:tala-rendering #:tala-rendering-input
           #:tala-rendering-svg #:tala-rendering-version #:run-tala
           #:validate-tala-svg #:tala-id #:topic-id-from-tala-id
           #:projection-state #:tala-dependency-status #:tala-rendering-evidence))
(in-package #:dreyeck/topicmap/tala)

(defstruct (tala-input (:constructor %make-tala-input))
  projection source topics associations seed)

;; This is a rendering proof, NOT TOPICMAP-LAYOUT. A later geometry exporter
;; belongs between TALA-INPUT and the native sign renderer, returning topic boxes
;; and association routes keyed by the IDs in these maps, never a new Projection.
(defstruct (tala-rendering (:constructor %make-tala-rendering))
  input version svg)

(defun tala-id (topic-id)
  "Encode a stable Topic ID as a D2-safe identifier, independently of labels."
  (check-type topic-id string)
  (with-output-to-string (s)
    (write-char #\n s)
    (loop for c across topic-id do (format s "~6,'0X" (char-code c)))))

(defun topic-id-from-tala-id (id)
  (unless (and (plusp (length id)) (char= #\n (char id 0))
               (zerop (mod (1- (length id)) 6)))
    (error "Invalid TALA Topic ID: ~S" id))
  (with-output-to-string (s)
    (loop for i from 1 below (length id) by 6
          do (write-char (or (code-char (parse-integer id :start i :end (+ i 6)
                                                         :radix 16))
                             (error "Invalid character in TALA ID: ~S" id)) s))))

(defun d2-quoted-label (label)
  (with-output-to-string (s)
    (write-char #\" s)
    (loop for c across label do
      (write-string (case c
                      (#\\ "\\\\") (#\" "\\\"") (#\$ "\\$")
                      (#\Newline "\\n") (#\Return "\\r") (#\Tab "\\t")
                      (otherwise (string c))) s))
    (write-char #\" s)))

(defun projection-tala-input (projection &key (seed 44))
  "Snapshot layout input from PROJECTION. Exclude point, positions and history.
The first slice supports flat, entirely visible projections only. Maps retain
Topic/Association IDs and endpoints; D2 labels never supply identity."
  (check-type projection tm:topicmap-projection)
  (check-type seed (signed-byte 64))
  (let* ((topics (sort (copy-list (tm:topicmap-projection-topics-of projection))
                       #'string< :key #'tm:topicmap-topic-id-of))
         (associations
           (sort (copy-list (tm:topicmap-projection-associations-of projection))
                 #'string< :key #'tm:topicmap-association-id-of))
         (counts (make-hash-table :test #'equal))
         (topic-map nil) (association-map nil))
    (tm::validate-topicmap-projection topics associations)
    (unless (= (length associations)
               (length (remove-duplicates associations :test #'string=
                             :key #'tm:topicmap-association-id-of)))
      (error "TALA requires unique Association IDs."))
    (dolist (topic topics)
      (unless (getf (tm:topicmap-topic-view-properties-of topic) :visible t)
        (error "TALA proof requires all projected topics to be visible."))
      (push (list :id (copy-seq (tm:topicmap-topic-id-of topic))
                  :d2-id (tala-id (tm:topicmap-topic-id-of topic))) topic-map))
    (dolist (association associations)
      (unless (eq :relation
                  (getf (tm:topicmap-association-properties-of association)
                        :presentation :relation))
        (error "TALA proof supports relation signs, not containment presentations."))
      (let* ((from (tm:topicmap-association-from-of association))
             (to (tm:topicmap-association-to-of association))
             (pair (list from to))
             (index (gethash pair counts 0)))
        (incf (gethash pair counts 0))
        (push (list :id (copy-seq (tm:topicmap-association-id-of association))
                    :from (copy-seq from) :to (copy-seq to)
                    :d2-id (format nil "(~A -> ~A)[~D]"
                                   (tala-id from) (tala-id to) index))
              association-map)))
    (setf topic-map (nreverse topic-map) association-map (nreverse association-map))
    (%make-tala-input
     :projection projection :seed seed :topics topic-map
     :associations association-map
     :source
     (with-output-to-string (s)
       (dolist (topic topics)
         (format s "~A: ~A~%" (tala-id (tm:topicmap-topic-id-of topic))
                 (d2-quoted-label (tm:topicmap-topic-label-of topic))))
       (dolist (association associations)
         (format s "~A -> ~A: ~A~%"
                 (tala-id (tm:topicmap-association-from-of association))
                 (tala-id (tm:topicmap-association-to-of association))
                 (d2-quoted-label
                  (princ-to-string (tm:topicmap-association-type-of association)))))))))

(defun d2-svg-identity-class (id)
  ;; D2 v0.9.0: base64.URLEncoding(svg.EscapeText(ID)). Our generated IDs
  ;; contain only hex node names and the fixed connection punctuation.
  (let ((escaped (with-output-to-string (s)
                   (loop for c across id do
                     (write-string (if (char= c #\>) "&gt;" (string c)) s)))))
    (substitute #\_ #\/ (substitute #\- #\+
                                   (cl-base64:string-to-base64-string escaped)))))

(defun validate-tala-svg (input svg)
  "Check exact topic/edge identity coverage using D2's SVG group markers only.
No coordinates or labels are parsed; SVG remains derived presentation data."
  (let* ((dom (plump:parse svg))
         (groups
           (loop for g in (plump:get-elements-by-tag-name dom "g")
                 when (and (plump:element-p (plump:parent g))
                           (string= "svg" (plump:tag-name (plump:parent g))))
                   collect (plump:attribute g "class")))
         (expected
           (mapcar (lambda (entry) (d2-svg-identity-class (getf entry :d2-id)))
                   (append (tala-input-topics input) (tala-input-associations input)))))
    (unless (and (plusp (length (plump:get-elements-by-tag-name dom "svg")))
                 (equal (sort groups #'string<) (sort expected #'string<)))
      (error "TALA SVG identity coverage differs from the input projection."))
    t))

(defun run-tala (input &key (program "d2"))
  "Run the pinned external layout capability through streams, without temp files.
An absent/unsupported D2 or invalid result is an error, never a native fallback."
  (check-type input tala-input)
  (let* ((dependency (tala-dependency-status :program program))
         (version (getf dependency :version)))
    (unless (eq :available (getf dependency :status))
      (error "TALA dependency unavailable/unsupported: ~S. Use nix develop .#tala." dependency))
    (let ((svg
            (with-input-from-string (s (tala-input-source input))
              (uiop:run-program
               (list program "--layout=tala"
                     (format nil "--tala-seeds=~D" (tala-input-seed input))
                     "--theme=0" "--sketch=false" "--animate-interval=0"
                     "--timeout=60" "--no-xml-tag" "--stdout-format=svg" "-" "-")
               :input s :output :string :error-output :string
               :external-format :utf-8))))
      (validate-tala-svg input svg)
      (%make-tala-rendering :input input :version version :svg svg))))

(defun projection-state (projection)
  (list (dreyeck/topicmap:topicmap-projection-source-of projection)
        (copy-tree (dreyeck/topicmap:topicmap-projection-view-properties-of projection))
        (mapcar (lambda (topic)
                  (list topic
                        (copy-seq (dreyeck/topicmap:topicmap-topic-id-of topic))
                        (copy-seq (dreyeck/topicmap:topicmap-topic-label-of topic))
                        (dreyeck/topicmap:topicmap-topic-type-of topic)
                        (dreyeck/topicmap:topicmap-topic-object-of topic)
                        (dreyeck/topicmap:topicmap-topic-temporal-scope-of topic)
                        (copy-tree (dreyeck/topicmap:topicmap-topic-view-properties-of topic))))
                (dreyeck/topicmap:topicmap-projection-topics-of projection))
        (mapcar (lambda (association)
                  (list association
                        (copy-seq (dreyeck/topicmap:topicmap-association-id-of association))
                        (copy-seq (dreyeck/topicmap:topicmap-association-from-of association))
                        (copy-seq (dreyeck/topicmap:topicmap-association-to-of association))
                        (dreyeck/topicmap:topicmap-association-type-of association)
                        (copy-tree (dreyeck/topicmap:topicmap-association-properties-of association))))
                (dreyeck/topicmap:topicmap-projection-associations-of projection))))


(defun tala-dependency-status (&key (program "d2"))
  "Return inspectable dependency evidence; never substitute a different engine."
  (handler-case
      (let ((version (string-trim '(#\Space #\Newline #\Return)
                                 (uiop:run-program (list program "--version")
                                                   :output :string :error-output :string)))
            (engine (uiop:run-program (list program "layout" "tala")
                                      :output :string :error-output :string)))
        (list :status (if (and (string= version "v0.9.0") (search "tala (bundled)" engine))
                          :available :unsupported)
              :program program :version version :engine engine))
    (error (condition)
      (list :status :unavailable :program program :condition condition
            :remedy "Run in nix develop .#tala (pinned D2 v0.9.0)."))))

(defun tala-rendering-evidence (rendering)
  "Inspect the SVG geometry matched to original IDs, without interpreting paths.
Coordinates remain SVG attribute strings in its nested viewBox coordinate system.
This is evidence for the rendering proof, not a numeric TOPICMAP-LAYOUT API."
  (let* ((input (tala-rendering-input rendering))
         (svg (tala-rendering-svg rendering))
         (dom (plump:parse svg))
         (groups (plump:get-elements-by-tag-name dom "g")))
    (validate-tala-svg input svg)
    (labels ((group-for (entry)
               (find (d2-svg-identity-class (getf entry :d2-id)) groups
                     :key (lambda (g) (plump:attribute g "class")) :test #'equal))
             (attributes (node names)
               (mapcar (lambda (name) (cons name (plump:attribute node name))) names)))
      (list :representation :svg-geometry
            :viewboxes (mapcar (lambda (node) (plump:attribute node "viewBox"))
                               (plump:get-elements-by-tag-name dom "svg"))
            :topics
            (mapcar (lambda (entry)
                      (list :id (getf entry :id)
                            :rectangles (mapcar (lambda (node)
                                                  (attributes node '("x" "y" "width" "height")))
                                                (plump:get-elements-by-tag-name (group-for entry) "rect"))
                            :svg-group (group-for entry)))
                    (tala-input-topics input))
            :associations
            (mapcar (lambda (entry)
                      (list :id (getf entry :id) :from (getf entry :from) :to (getf entry :to)
                            :paths (mapcar (lambda (node) (plump:attribute node "d"))
                                           (plump:get-elements-by-tag-name (group-for entry) "path"))
                            :svg-group (group-for entry)))
                    (tala-input-associations input))))))
