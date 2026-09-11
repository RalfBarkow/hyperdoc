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

(views:defview 👀tala-result (rendering tala:tala-rendering)
  (views:html-view :title "TALA rendering proof" :priority 1
    (views:html
      (:p "D2 " (views:esc (tala:tala-rendering-version rendering)) " · non-interactive")
      (:p (views:object-ref (tala:tala-rendering-evidence rendering) :display "SVG geometry by original ID"))
      (views:str (rendering-image-html rendering)))))
