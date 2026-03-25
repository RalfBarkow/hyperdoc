;;;; Pane-local Dock capabilities and generic annotations
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defclass dock-annotation (dom-relation-annotation)
  ((dock-capability :reader dock-capability-of
                    :initarg :dock-capability
                    :initform "Annotation")
   (registry-key :reader registry-key-of
                 :initarg :registry-key
                 :initform nil)))

(defparameter *dock-annotations* (make-hash-table :test #'equal))

(defgeneric dock-primary-object (object)
  (:documentation
   "Return the current inspectable thing that Dock actions should treat as
the primary pane-local object in this slice."))

(defmethod dock-primary-object ((page topic-page))
  (topic-of page))

(defmethod dock-primary-object ((object t))
  object)

(defun dock-object-label (object)
  (or (ignore-errors (title-of object))
      (ignore-errors (id-of object))
      (format nil "~A" object)))

(defun dock-object-stable-id (object)
  (or (ignore-errors (id-of object))
      (ignore-errors (title-of object))
      (format nil "~A" object)))

(defun dock-annotation-topic ()
  (annotation-topic))

(defun make-dock-capability-anchor (capability context-object context-view-title)
  (let ((annotation-topic (dock-annotation-topic)))
    (make-instance 'dom-annotation-anchor
                   :provider-kind "dock-v1"
                   :view-kind "dock"
                   :view-title context-view-title
                   :context-object-id (dock-object-stable-id context-object)
                   :strategy "dock-capability"
                   :value (string-downcase capability)
                   :label capability
                   :durability-tier "strong"
                   :durability-note
                   "Dock capability anchors are synthetic authored anchors for pane-local actions."
                   :object-id (dock-object-stable-id annotation-topic))))

(defun make-dock-object-anchor (object context-object context-view-title)
  (make-instance 'dom-annotation-anchor
                 :provider-kind "dock-v1"
                 :view-kind "dock-target"
                 :view-title context-view-title
                 :context-object-id (dock-object-stable-id context-object)
                 :strategy "current-object"
                 :value (dock-object-stable-id object)
                 :label (dock-object-label object)
                 :durability-tier "medium"
                 :durability-note
                 "This first Dock slice targets the current pane object rather than a specific DOM anchor."
                 :object-id (dock-object-stable-id object)))

(defun dock-annotation-default-note (target-object context-view-title)
  (format nil
          "Draft annotation for ~A.~@[ Captured from the ~A pane view.~] This first Dock slice targets the current pane object rather than a specific DOM anchor."
          (dock-object-label target-object)
          context-view-title))

(defun dock-annotation-title (target-object)
  (format nil "Annotation: ~A" (dock-object-label target-object)))

(defun dock-annotation-summary (target-object context-view-title)
  (format nil
          "Generic Dock annotation for ~A.~@[ The annotation was opened from the ~A pane view.~]"
          (dock-object-label target-object)
          context-view-title))

(defun dock-annotation-key (context-object context-view-title &optional target-anchor)
  (let* ((target-object (dock-primary-object context-object))
         (source-anchor (make-dock-capability-anchor
                         "Annotation"
                         context-object
                         context-view-title))
         (resolved-target-anchor
           (or target-anchor
               (make-dock-object-anchor
                target-object context-object context-view-title))))
    (dom-relation-annotation-id source-anchor resolved-target-anchor)))

(defun make-dock-annotation (&key context-object
                                  context-view-title
                                  target-anchor
                                  target-object
                                  relation-kind
                                  note)
  (let* ((resolved-target-object
           (or target-object
               (dock-primary-object context-object)))
         (source-topic (dock-annotation-topic))
         (source-anchor
           (make-dock-capability-anchor
            "Annotation"
            context-object
            context-view-title))
         (resolved-target-anchor
           (or target-anchor
               (make-dock-object-anchor
                resolved-target-object
                context-object
                context-view-title)))
         (registry-key
           (dom-relation-annotation-id source-anchor resolved-target-anchor)))
    (make-dom-relation-annotation
     :class 'dock-annotation
     :id registry-key
     :title (dock-annotation-title resolved-target-object)
     :summary (dock-annotation-summary
               resolved-target-object
               context-view-title)
     :context-object context-object
     :context-view-title context-view-title
     :source-anchor source-anchor
     :target-anchor resolved-target-anchor
     :source-object source-topic
     :target-object resolved-target-object
     :relation-kind (or relation-kind "annotation")
     :note (or note
               (dock-annotation-default-note
                resolved-target-object
                context-view-title))
     :registry-key registry-key
     :dock-capability "Annotation")))

(defun dock-annotation-for-context (context-object &key context-view-title
                                                   target-anchor
                                                   target-object
                                                   relation-kind
                                                   note)
  (let* ((annotation
           (make-dock-annotation
            :context-object context-object
            :context-view-title context-view-title
            :target-anchor target-anchor
            :target-object target-object
            :relation-kind relation-kind
            :note note))
         (registry-key (id-of annotation)))
    (or (gethash registry-key *dock-annotations*)
        (setf (gethash registry-key *dock-annotations*) annotation))))

(defun dock-inspect-object-for-context (context-object)
  (dock-primary-object context-object))

(defun dock-zotero-capability-available-p (context-object)
  (and (typep (dock-primary-object context-object) 'topic)
       (let ((bridge (ignore-errors (make-default-zotero-library-bridge))))
         (and bridge
              (not (zotero-backend-unavailable-p bridge))))))

(defun chunk-dock-annotation ()
  (dock-annotation-for-context
   (find-page *topics* "Chunk" :signal-error? t)
   :context-view-title "Content"))
