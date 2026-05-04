;;;; Smoke tests for the post-partial repair state of annotation topic 936040
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc/tests)

(defun annotation-936040-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun annotation-936040-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected ~S but got ~S" message expected actual)))

(defun make-annotation-936040-regression-client ()
  (let* ((client (make-instance 'hyperdoc::memory-dmx-import-client
                                :next-topic-id 936041))
         (annotation (make-test-dock-annotation
                      :note "Preserved compatibility carrier topic"))
         (plan (hyperdoc::plan-dmx-workspace-annotation-write-from-object
                annotation
                :workspace-id *dmx-annotations-smoke-workspace-id*
                :workspace-topicmap-id
                *dmx-annotations-smoke-workspace-topicmap-id*
                :client client
                :storage-mode
                hyperdoc::*dmx-workspace-annotation-compatibility-storage-mode*))
         (payload (copy-tree
                   (hyperdoc::dmx-workspace-annotation-write-plan-payload
                    plan)))
         (view-props
           (hyperdoc::dmx-workspace-annotation-write-plan-view-props plan)))
    (setf (getf payload :id) 936040)
    (hyperdoc::dmx-import-create-topic client payload)
    (setf (gethash
           (hyperdoc::memory-topicmap-membership-key
            *dmx-annotations-smoke-workspace-topicmap-id*
            936040)
           (hyperdoc::topicmap-memberships-of client))
          view-props)
    (values client annotation)))

(defun run-dmx-annotation-936040-regression-smoke-test ()
  (multiple-value-bind (client annotation)
      (make-annotation-936040-regression-client)
    (let* ((plan (hyperdoc::plan-dmx-workspace-annotation-write-from-object
                  annotation
                  :workspace-id *dmx-annotations-smoke-workspace-id*
                  :workspace-topicmap-id
                  *dmx-annotations-smoke-workspace-topicmap-id*
                  :client client
                  :storage-mode
                  hyperdoc::*dmx-workspace-annotation-compatibility-storage-mode*))
           (state
             (list :topic-id
                   (hyperdoc::dmx-workspace-annotation-write-plan-existing-topic-id
                    plan)
                   :topic-action
                   (hyperdoc::dmx-workspace-annotation-write-plan-topic-action
                    plan)
                   :topicmap-id
                   (hyperdoc::dmx-workspace-annotation-write-plan-workspace-topicmap-id
                    plan)
                   :topicmap-present-p
                   (hyperdoc::dmx-import-topic-in-topicmap-p
                    client
                    *dmx-annotations-smoke-workspace-topicmap-id*
                    936040)
                   :workspace-id
                   (hyperdoc::dmx-workspace-annotation-write-plan-current-workspace-id
                    plan)
                   :remaining-action
                   (and (eq (hyperdoc::dmx-workspace-annotation-write-plan-workspace-action
                             plan)
                            :assign)
                        :assign-workspace))))
      (annotation-936040-assert-equal
       936040
       (getf state :topic-id)
       "Annotation 936040 fixture must resolve the existing carrier topic")
      (annotation-936040-assert-equal
       :update
       (getf state :topic-action)
       "Annotation 936040 must replan as UPDATE, not CREATE")
      (annotation-936040-assert-equal
       *dmx-annotations-smoke-workspace-topicmap-id*
       (getf state :topicmap-id)
       "Annotation 936040 target topicmap must remain 919822")
      (annotation-936040-assert-true
       (getf state :topicmap-present-p)
       "Annotation 936040 fixture must represent present topicmap placement")
      (annotation-936040-assert-equal
       nil
       (getf state :workspace-id)
       "Annotation 936040 fixture must represent missing workspace assignment")
      (annotation-936040-assert-equal
       :assign-workspace
       (getf state :remaining-action)
       "Annotation 936040 remaining action must be only workspace assignment"))))

(defun run-dmx-annotation-936040-regression-smoke-tests ()
  (run-dmx-annotation-936040-regression-smoke-test)
  t)
