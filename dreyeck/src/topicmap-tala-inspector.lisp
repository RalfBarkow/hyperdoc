;;;; Explicit comparison of one projection; native navigation stays authoritative.
(defpackage #:dreyeck/inspector/topicmap/tala
  (:use #:cl)
  (:local-nicknames (#:tm #:dreyeck/topicmap)
                    (#:tala #:dreyeck/topicmap/tala)
                    (#:native #:dreyeck/inspector/topicmap)
                    (#:views #:html-inspector-views))
  (:export #:tala-comparison #:compare-workspace-layouts
           #:repository-layout-comparison #:comparison-workspace
           #:comparison-projection #:comparison-rendering #:comparison-invariants))
(in-package #:dreyeck/inspector/topicmap/tala)

(defclass tala-comparison ()
  ((workspace :reader comparison-workspace :initarg :workspace)
   (projection :reader comparison-projection :initarg :projection)
   (rendering :reader comparison-rendering :initarg :rendering)
   (invariants :reader comparison-invariants :initarg :invariants)))

(defun compare-workspace-layouts (workspace &key (program "d2") (seed 44))
  "Lay out one existing workspace projection once, explicitly on request.
Viewing the result or invoking existing navigation actions does not run TALA."
  (check-type workspace tm:topicmap-workspace)
  (let* ((base (tm:topicmap-workspace-projection-of workspace))
         (base-before (tala:projection-state base))
         (point-before (copy-seq (tm:topicmap-workspace-point-of workspace)))
         (history-before (copy-list (tm:topicmap-workspace-history-of workspace)))
         (projection (tm:topicmap-projection-of workspace))
         (projection-before (tala:projection-state projection))
         (input (tala:projection-tala-input projection :seed seed))
         (rendering (tala:run-tala input :program program))
         (evidence (tala:tala-rendering-evidence rendering))
         (ids (mapcar #'tm:topicmap-topic-id-of (tm:topicmap-projection-topics-of projection)))
         (output-ids (mapcar (lambda (e) (getf e :id)) (getf evidence :topics)))
         (endpoints (mapcar (lambda (a) (list (tm:topicmap-association-id-of a)
                                             (tm:topicmap-association-from-of a)
                                             (tm:topicmap-association-to-of a)))
                            (tm:topicmap-projection-associations-of projection)))
         (output-endpoints (mapcar (lambda (e) (list (getf e :id) (getf e :from) (getf e :to)))
                                   (getf evidence :associations)))
         (checks
           (list :topic-ids-preserved (and (= (length ids) (length output-ids))
                                           (null (set-exclusive-or ids output-ids :test #'equal)))
                 :association-endpoints-preserved
                 (and (= (length endpoints) (length output-endpoints))
                      (null (set-exclusive-or endpoints output-endpoints :test #'equal)))
                 :no-foreign-topic-ids (null (set-difference output-ids ids :test #'equal))
                 :point-unchanged (equal point-before (tm:topicmap-workspace-point-of workspace))
                 :history-unchanged (equal history-before (tm:topicmap-workspace-history-of workspace))
                 :projection-unchanged (and (equal base-before (tala:projection-state base))
                                             (equal projection-before (tala:projection-state projection)))
                 :same-projection (eq projection (tala:tala-input-projection input)))))
    (unless (loop for (key value) on checks by #'cddr always value)
      (error "TALA comparison invariant failed: ~S" checks))
    (make-instance 'tala-comparison :workspace workspace :projection projection
                   :rendering rendering
                   :invariants (list :status :passed :checks checks
                                     :point-before point-before
                                     :point-after (tm:topicmap-workspace-point-of workspace)
                                     :projected-topic-ids ids :rendered-topic-ids output-ids
                                     :association-endpoints-before endpoints
                                     :association-endpoints-after output-endpoints))))

(defun repository-layout-comparison (&key (program "d2") (seed 44))
  "Compare the existing real Git repository/HEAD projection of this ASDF checkout."
  (compare-workspace-layouts
   (tm::make-topicmap-workspace-for-object
    (dreyeck/git:make-current-git-repository-checkout))
   :program program :seed seed))

(defun rendering-image-html (rendering)
  ;; Image context isolates SVG styles/IDs and intentionally has no Inspector
  ;; actions. Native signs below remain the interactive presentation.
  (format nil "<img alt='TALA layout proof (non-interactive)' style='max-width:100%' src='data:image/svg+xml;base64,~A'>"
          (cl-base64:usb8-array-to-base64-string
           (babel:string-to-octets (tala:tala-rendering-svg rendering)
                                   :encoding :utf-8))))

(defmethod native:render-topicmap-html
    ((rendering tala:tala-rendering) (projection tm:topicmap-projection))
  (unless (eq projection (tala:tala-input-projection (tala:tala-rendering-input rendering)))
    (error "TALA rendering belongs to a different Projection."))
  (rendering-image-html rendering))

(views:defview 👀layout-comparison (comparison tala-comparison)
  (views:html-view :title "Native / TALA" :priority 1
    (views:html
      (:p "TALA derives presentation from a Projection. It does not modify Topicmap semantics.")
      (:p (views:object-ref (comparison-projection comparison) :display "Projection")
          " · " (views:object-ref (comparison-workspace comparison) :display "Workspace")
          " · " (views:object-ref (tala:tala-rendering-input (comparison-rendering comparison))
                                  :display "TALA input and identity maps")
          " · " (views:object-ref (comparison-rendering comparison) :display "TALA result"))
      (:p (views:object-ref (comparison-invariants comparison) :display "Invariant report"))
      (:h3 "Native (existing Workspace navigation)")
      (views:str (native:render-topicmap-html :native-svg (comparison-projection comparison)))
      (:h3 "TALA (non-interactive layout proof)")
      (:p "Use the native Topic signs or inspect Workspace to navigate. This image has no navigation actions. The comparison retains the point at layout time; inspect Workspace for the current point.")
      (views:str (native:render-topicmap-html (comparison-rendering comparison)
                                            (comparison-projection comparison))))))

(views:defview 👀tala-input (input tala:tala-input)
  (views:html-view :title "D2 input" :priority 1
    (views:html
      (:p "Seed: " (views:esc (princ-to-string (tala:tala-input-seed input))))
      (:pre (views:esc (tala:tala-input-source input)))
      (:p (views:object-ref (tala:tala-input-topics input) :display "Topic ID map")
          " · " (views:object-ref (tala:tala-input-associations input) :display "Association ID / endpoint map")))) )

;;;; Inline, with Inspector references
;;
;; The same SVG, placed in the page instead of an image, so that each D2
;; group can carry an ordinary Inspector reference. A group is found by the
;; class D2 derives from the key this rendering's input gave it, the class
;; VALIDATE-TALA-SVG already checks; labels, geometry and DOM nodes identify
;; nothing. An edge's path and label sit in one group and so reach one
;; Association. Shape and edge groups are siblings, so neither contains the
;; other's reference.
;;
;; D2 names its marker, mask, style scope and fonts after a hash of the
;; diagram. Two copies of one diagram in a page would share those IDs, and
;; hidden Inspector views stay in the page, so each rendering of this view
;; gets its own suffix on that hash.

(defun %d2-scope (dom)
  "The diagram hash D2 scoped this SVG with, e.g. \"d2-37195573\"."
  (let ((svg (find-if (lambda (node)
                        (member "d2-svg" (uiop:split-string (or (plump:attribute node "class") "") :separator " ")
                                :test #'string=))
                      (plump:get-elements-by-tag-name dom "svg"))))
    (or (and svg
             (find-if (lambda (class)
                        (and (> (length class) 3) (string= "d2-" class :end2 3)
                             (every #'digit-char-p (subseq class 3))))
                      (uiop:split-string (plump:attribute svg "class") :separator " ")))
        (error "TALA SVG has no D2 scope class."))))

(defun %rescope (string scope new-scope)
  "STRING with each SCOPE that is not followed by another digit renamed."
  (with-output-to-string (out)
    (loop with start = 0
          for position = (search scope string :start2 start)
          do (write-string string out :start start :end (or position (length string)))
          while position
          do (let ((end (+ position (length scope))))
               (write-string (if (and (< end (length string))
                                      (digit-char-p (char string end)))
                                 scope new-scope)
                             out)
               (setf start end)))))

(defun %rescope-dom (dom scope new-scope)
  "Rename SCOPE in IDs, references and the style sheet. A class token is
renamed only when it is SCOPE, so D2's identity classes are never touched."
  (plump:traverse
   dom
   (lambda (node)
     (let ((attributes (plump:attributes node)))
       (loop for name being the hash-keys of attributes using (hash-value value)
             do (setf (gethash name attributes)
                      (if (string-equal name "class")
                          (format nil "~{~A~^ ~}"
                                  (mapcar (lambda (class)
                                            (if (string= class scope) new-scope class))
                                          (uiop:split-string value :separator " ")))
                          (%rescope value scope new-scope))))
       (when (string-equal "style" (plump:tag-name node))
         (loop for child across (plump:children node)
               when (typep child 'plump:textual-node)
                 do (setf (plump:text child)
                          (%rescope (plump:text child) scope new-scope))))))
   :test #'plump:element-p)
  dom)

(defun %identity-group (groups entry)
  "The one top-level group D2 made for ENTRY's key."
  (let* ((class (tala:d2-svg-identity-class (getf entry :d2-id)))
         (matches (remove class groups :key (lambda (g) (plump:attribute g "class"))
                                       :test-not #'equal)))
    (unless (= 1 (length matches))
      (error "~D SVG groups carry the D2 identity of ~S." (length matches)
             (getf entry :id)))
    (first matches)))

(defun interactive-tala-svg (rendering)
  "RENDERING's SVG with an Inspector reference on each Topic and Association
group. Call it while a view is being built: the references belong to it."
  (let* ((input (tala:tala-rendering-input rendering))
         (projection (tala:tala-input-projection input))
         (dom (let ((plump:*tag-dispatchers* plump:*xml-tags*))
                (plump:parse (tala:tala-rendering-svg rendering))))
         (groups (remove-if-not
                  (lambda (g) (let ((parent (plump:parent g)))
                                (and (plump:element-p parent)
                                     (string= "svg" (plump:tag-name parent)))))
                  (plump:get-elements-by-tag-name dom "g")))
         (scope (%d2-scope dom)))
    (%rescope-dom dom scope
                  (format nil "~A-~(~A~)" scope (symbol-name (gensym "V"))))
    (dolist (entry (tala:tala-input-topics input))
      (let ((group (%identity-group groups entry))
            (topic (tm:topicmap-projection-topic-by-id projection (getf entry :id))))
        (setf (plump:attribute group "id") (views:inspect-id topic)
              (plump:attribute group "data-topic-id") (getf entry :id)
              (plump:attribute group "style") "cursor:pointer")))
    (dolist (entry (tala:tala-input-associations input))
      (let ((group (%identity-group groups entry))
            (association (find (getf entry :id)
                               (tm:topicmap-projection-associations-of projection)
                               :key #'tm:topicmap-association-id-of :test #'equal)))
        ;; The same reference is the Association's sign: PRIMARY inspects it,
        ;; SECONDARY offers what an Association offers.
        (setf (plump:attribute group "id")
              (native:register-association-sign (views:inspect-id association))
              (plump:attribute group "data-association-id") (getf entry :id)
              (plump:attribute group "style") "cursor:pointer")))
    (let ((outer (first (plump:get-elements-by-tag-name dom "svg"))))
      (setf (plump:attribute outer "style") "max-width:100%;height:auto"))
    (plump:serialize dom nil)))

(views:defview 👀tala-interactive (rendering tala:tala-rendering)
  (views:html-view :title "TALA (interactive)" :priority 2
    (views:html
      (:p "The same TALA layout, inline. Click an edge or its label to inspect that Association; click a shape to inspect its Topic. Right-click an edge to inspect its relation contract: hold for the menu, or move right at once to mark. Inspecting changes nothing.")
      (views:str (interactive-tala-svg rendering)))))

(views:defview 👀tala-result (rendering tala:tala-rendering)
  (views:html-view :title "TALA rendering proof" :priority 1
    (views:html
      (:p "D2 " (views:esc (tala:tala-rendering-version rendering))
          " · image, non-interactive; the TALA (interactive) view inlines it")
      (:p (views:object-ref (tala:tala-rendering-evidence rendering) :display "SVG geometry by original ID"))
      (views:str (rendering-image-html rendering)))))
