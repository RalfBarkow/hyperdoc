;;;; Experimental layout/rendering boundary; no Topicmap model mutation.
(defpackage #:dreyeck/topicmap/tala
  (:use #:cl)
  (:local-nicknames (#:tm #:dreyeck/topicmap))
  (:export #:tala-input #:projection-tala-input #:tala-input-projection
           #:tala-input-source #:tala-input-topics #:tala-input-associations
           #:tala-input-seed #:tala-rendering #:tala-rendering-input
           #:tala-rendering-svg #:tala-rendering-version #:run-tala #:run-d2-tala
           #:validate-tala-svg #:assign-d2-keys #:tala-input-topic-id
           #:tala-input-d2-key #:d2-svg-identity-class
           #:projection-state #:tala-dependency-status #:tala-rendering-evidence))
(in-package #:dreyeck/topicmap/tala)

(defstruct (tala-input (:constructor %make-tala-input))
  projection source topics associations seed)

;; This is a rendering proof, NOT TOPICMAP-LAYOUT. A later geometry exporter
;; belongs between TALA-INPUT and the native sign renderer, returning topic boxes
;; and association routes keyed by the IDs in these maps, never a new Projection.
(defstruct (tala-rendering (:constructor %make-tala-rendering))
  input version svg)

;;;; Keys are not identities
;;
;; A D2 key used to be the Topic ID encoded six hex digits per
;; character. That made the key reversible on its own, and it made the
;; D2 unreadable: a commit topic produced an identifier of over three
;; hundred characters, in a language chosen for being plain to read.
;;
;; The encoding was never needed. Nothing on the path from projection to
;; validated SVG ever decoded a key: VALIDATE-TALA-SVG compares the keys
;; D2 was given against the classes D2 emitted, and TALA-RENDERING-EVIDENCE
;; reports geometry under the Topic ID it already holds in the map. Only
;; the tests decoded, to prove an identity the map states outright.
;;
;; So identity moves from the spelling of the key to a bijection the
;; projection carries and checks. A key is now projection-local: readable,
;; deterministic, unique within one input, and meaningless outside it. The
;; same Topic may appear under different keys in different diagrams and
;; remain the same Topic, which is what it always was.

(defun %d2-key-candidate (topic-id)
  "A readable D2 key for TOPIC-ID, before uniqueness is settled.

Letters, digits and underscore only, because everything else is either
D2 syntax — a dot nests, a dash starts an arrow — or an invitation to
quote. A key must also start with a letter, since one beginning with a
digit reads as a number."
  (let ((sanitized
          (with-output-to-string (s)
            (loop for c across topic-id
                  do (write-char (if (or (alphanumericp c) (char= c #\_)) c #\_)
                                 s)))))
    (cond ((zerop (length sanitized)) "t")
          ((alpha-char-p (char sanitized 0)) sanitized)
          (t (concatenate 'string "t_" sanitized)))))

(defun assign-d2-keys (topic-ids)
  "Map each Topic ID to a distinct readable D2 key, in the order given.

Sanitizing is not injective — two Topic IDs differing only in
punctuation reduce to one candidate — so collisions are possible and are
settled here rather than discovered later as two Topics sharing a node.
The first claimant in the given order keeps the plain key and the next
takes a numbered one, which makes the assignment a function of the
order, and the caller sorts before calling. Nothing is silently
aliased: the result is checked to be as long as its input."
  (let ((taken (make-hash-table :test #'equal))
        (assignment nil))
    (dolist (topic-id topic-ids)
      (let ((candidate (%d2-key-candidate topic-id)))
        (loop with base = candidate
              for index from 2
              while (gethash candidate taken)
              do (setf candidate (format nil "~A__~D" base index)))
        (setf (gethash candidate taken) topic-id)
        (push (cons topic-id candidate) assignment)))
    (setf assignment (nreverse assignment))
    (unless (= (length assignment) (hash-table-count taken))
      (error "Two Topics were assigned the same D2 key."))
    assignment))

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
         ;; Assigned once, from the sorted order, so the same projection
         ;; always yields the same keys and an association can name the
         ;; same key its endpoint topic was given.
         (keys (assign-d2-keys (mapcar #'tm:topicmap-topic-id-of topics)))
         (topic-map nil) (association-map nil))
    (flet ((key-for (topic-id)
             (or (cdr (assoc topic-id keys :test #'string=))
                 (error "No D2 key was assigned to Topic ~S." topic-id))))
    (tm::validate-topicmap-projection topics associations)
    (unless (= (length associations)
               (length (remove-duplicates associations :test #'string=
                             :key #'tm:topicmap-association-id-of)))
      (error "TALA requires unique Association IDs."))
    (dolist (topic topics)
      (unless (getf (tm:topicmap-topic-view-properties-of topic) :visible t)
        (error "TALA proof requires all projected topics to be visible."))
      (push (list :id (copy-seq (tm:topicmap-topic-id-of topic))
                  :d2-id (key-for (tm:topicmap-topic-id-of topic)))
            topic-map))
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
                                   (key-for from) (key-for to) index))
              association-map)))
    (setf topic-map (nreverse topic-map) association-map (nreverse association-map))
    (%make-tala-input
     :projection projection :seed seed :topics topic-map
     :associations association-map
     :source
     (with-output-to-string (s)
       (dolist (topic topics)
         (format s "~A: ~A~%" (key-for (tm:topicmap-topic-id-of topic))
                 (d2-quoted-label (tm:topicmap-topic-label-of topic))))
       (dolist (association associations)
         (format s "~A -> ~A: ~A~%"
                 (key-for (tm:topicmap-association-from-of association))
                 (key-for (tm:topicmap-association-to-of association))
                 (d2-quoted-label
                  (or (tm:topicmap-association-relation-label association)
                      (princ-to-string (tm:topicmap-association-type-of association)))))))))))

(defun tala-input-d2-key (input topic-id)
  "The key this INPUT gave TOPIC-ID, or an error.

Half of the bijection. It is asked of the input and not computed from
the Topic ID, because the key means nothing outside the projection that
assigned it."
  (let ((entry (find topic-id (tala-input-topics input)
                     :key (lambda (e) (getf e :id)) :test #'string=)))
    (unless entry
      (error "Topic ~S is not in this layout input." topic-id))
    (getf entry :d2-id)))

(defun tala-input-topic-id (input d2-key)
  "The Topic this INPUT gave D2-KEY to, or an error.

The other half, and the one that replaces decoding. A key found in the
rendered SVG leads back to a Topic by being looked up here, so the
answer comes from the projection that made the claim rather than from
the spelling of a string."
  (let ((entry (find d2-key (tala-input-topics input)
                     :key (lambda (e) (getf e :d2-id)) :test #'string=)))
    (unless entry
      (error "No Topic in this layout input carries the D2 key ~S." d2-key))
    (getf entry :id)))

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

(defun run-d2-tala (source &key (seed 44) (program "d2"))
  "Lay out D2 SOURCE with TALA and return (values SVG VERSION).

The boundary to the external tool, and nothing else. It knows about D2
text and a layout engine; it knows nothing about projections, topics or
identity, and it validates nothing, because there is nothing here to
validate against — a caller who has expectations is the one who can
check them.

Separated out because two callers want it for different reasons. A
projection renders what it can then hold the result to; an author
renders what they wrote, which answers to nobody. Running the tool twice
in two places would have been the way to let those two drift apart."
  (check-type source string)
  (check-type seed (signed-byte 64))
  (let* ((dependency (tala-dependency-status :program program))
         (version (getf dependency :version)))
    (unless (eq :available (getf dependency :status))
      (error "TALA dependency unavailable/unsupported: ~S. Use nix develop .#tala."
             dependency))
    (values
     (with-input-from-string (s source)
       (uiop:run-program
        (list program "--layout=tala"
              (format nil "--tala-seeds=~D" seed)
              "--theme=0" "--sketch=false" "--animate-interval=0"
              "--timeout=60" "--no-xml-tag" "--stdout-format=svg" "-" "-")
        :input s :output :string :error-output :string
        :external-format :utf-8))
     version)))

(defun run-tala (input &key (program "d2"))
  "Run the pinned external layout capability through streams, without temp files.
An absent/unsupported D2 or invalid result is an error, never a native fallback."
  (check-type input tala-input)
  (multiple-value-bind (svg version)
      (run-d2-tala (tala-input-source input)
                   :seed (tala-input-seed input) :program program)
    (validate-tala-svg input svg)
    (%make-tala-rendering :input input :version version :svg svg)))

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
