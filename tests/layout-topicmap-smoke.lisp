;;;; Smoke tests for the inspector layout topicmap model.

(in-package :hyperdoc/tests)

(defun layout-topicmap-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun layout-topicmap-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun run-layout-topicmap-snapshot-smoke-test ()
  (asdf:load-system :hyperdoc)
  (let* ((topicmap (hyperdoc:reel-inspector-layout-topicmap))
         (buttons (hyperdoc:layout-topicmap-topic
                   topicmap
                   "hyperdoc-reel__buttons"))
         (pane (hyperdoc:layout-topicmap-topic topicmap "inspector-pane"))
         (scrollable (hyperdoc:layout-topicmap-topic
                      topicmap
                      "hyperdoc-reel__scrollable")))
    (layout-topicmap-assert-true
     (typep topicmap 'hyperdoc:layout-topicmap)
     "Snapshot helper must return a layout-topicmap object")
    (layout-topicmap-assert-equal
     "Inspector Reel layout topicmap"
     (hyperdoc::title-of topicmap)
     "Snapshot must expose the Layout topicmap view title")
    (dolist (topic (list buttons pane scrollable))
      (layout-topicmap-assert-true
       (typep topic 'hyperdoc:layout-topic)
       "Required layout topic must be present")
      (layout-topicmap-assert-true
       (hyperdoc:layout-topic-selector-of topic)
       "Required layout topic must store a DOM selector")
      (layout-topicmap-assert-true
       (hyperdoc:layout-topic-class-list-of topic)
       "Required layout topic must store a class-list evidence basis")
      (layout-topicmap-assert-true
       (hyperdoc:layout-topic-bounding-box-of topic)
       "Required layout topic must expose bounding-box capture status")
      (layout-topicmap-assert-true
       (hyperdoc:evidence-of topic)
       "Required layout topic must expose source evidence")
      (layout-topicmap-assert-true
       (hyperdoc:layout-topic-stability-of topic)
       "Required layout topic must expose stability classification"))
    (layout-topicmap-assert-equal
     "hyperdoc-reel__viewport"
     (hyperdoc:layout-topicmap-parent-of
      topicmap
      "hyperdoc-reel__buttons")
     "Buttons must initially belong to the local Reel viewport")
    (layout-topicmap-assert-equal
     "hyperdoc-reel__scrollable"
     (hyperdoc:layout-topicmap-parent-of topicmap "inspector-pane")
     "Inspector pane must initially belong to the native scroll container")
    (layout-topicmap-assert-true
     (member '("hyperdoc-reel__buttons" "hyperdoc-reel__scrollable")
             (mapcar (lambda (relation)
                       (list (hyperdoc:from-of relation)
                             (hyperdoc:to-of relation)))
                     (hyperdoc:layout-topicmap-relations-of-kind
                      topicmap
                      :controls))
             :test #'equal)
     "Buttons must keep a control relation to the scrollable row")))

(defun run-layout-topicmap-move-patch-smoke-test ()
  (asdf:load-system :hyperdoc)
  (let* ((topicmap (hyperdoc:reel-inspector-layout-topicmap))
         (patch (hyperdoc:make-reel-buttons-into-pane-patch topicmap))
         (before (hyperdoc:layout-patch-before-topicmap-of patch))
         (after (hyperdoc:layout-patch-after-topicmap-of patch)))
    (layout-topicmap-assert-true
     (typep patch 'hyperdoc:move-topic-into-box-patch)
     "Moving buttons into the pane must create a move-topic-into-box-patch")
    (layout-topicmap-assert-equal
     "hyperdoc-reel__buttons"
     (hyperdoc:layout-patch-topic-id-of patch)
     "Patch must target the reel navigation buttons topic")
    (layout-topicmap-assert-equal
     "hyperdoc-reel__viewport"
     (hyperdoc:layout-patch-from-parent-id-of patch)
     "Patch must record the original parent")
    (layout-topicmap-assert-equal
     "inspector-pane"
     (hyperdoc:layout-patch-to-parent-id-of patch)
     "Patch must record the target pane")
    (layout-topicmap-assert-equal
     "hyperdoc-reel__viewport"
     (hyperdoc:layout-topicmap-parent-of before "hyperdoc-reel__buttons")
     "Before topology must keep buttons in the viewport")
    (layout-topicmap-assert-equal
     "inspector-pane"
     (hyperdoc:layout-topicmap-parent-of after "hyperdoc-reel__buttons")
     "After topology must move buttons into the pane")
    (layout-topicmap-assert-true
     (member :native-horizontal-overflow
             (hyperdoc:layout-patch-preserve-of patch))
     "Patch must preserve native horizontal overflow")
    (layout-topicmap-assert-true
     (member :button-labels (hyperdoc:layout-patch-preserve-of patch))
     "Patch must preserve labelled buttons")
    (layout-topicmap-assert-true
     (hyperdoc:layout-patch-source-evidence-of patch)
     "Patch must expose source evidence")
    (layout-topicmap-assert-true
     (hyperdoc:layout-patch-target-evidence-of patch)
     "Patch must expose target evidence")
    (layout-topicmap-assert-true
     (hyperdoc:layout-patch-proposed-implementation-effect-of patch)
     "Patch must expose proposed implementation effect")))

(defun run-layout-repair-plan-smoke-test ()
  (asdf:load-system :hyperdoc)
  (let* ((topicmap (hyperdoc:reel-inspector-layout-topicmap))
         (patch (hyperdoc:make-reel-buttons-into-pane-patch topicmap))
         (plan (hyperdoc:derive-layout-repair-plan patch))
         (results (hyperdoc:layout-repair-plan-rule-results-of plan))
         (effects (hyperdoc:layout-repair-plan-renderer-effects-of plan))
         (statuses (mapcar #'hyperdoc:layout-rule-result-status-of results))
         (preview-effects
           (remove-if-not (lambda (effect)
                            (eq (hyperdoc:layout-renderer-effect-phase-of
                                 effect)
                                :preview))
                          effects))
         (apply-effects
           (remove-if-not (lambda (effect)
                            (eq (hyperdoc:layout-renderer-effect-phase-of
                                 effect)
                                :apply))
                          effects)))
    (layout-topicmap-assert-true
     (typep plan 'hyperdoc:layout-repair-plan)
     "Layout patch must derive a layout-repair-plan object")
    (layout-topicmap-assert-equal
     :previewable
     (hyperdoc:layout-repair-plan-status-of plan)
     "Repair plan must be previewable when hard invariants pass and repairs exist")
    (layout-topicmap-assert-equal
     7
     (length results)
     "Default repair plan must evaluate the first seven layout rules")
    (layout-topicmap-assert-true
     (member :pass statuses)
     "Rule results must expose pass status")
    (layout-topicmap-assert-true
     (member :repair statuses)
     "Rule results must expose repair status")
    (layout-topicmap-assert-true
     (not (member :fail statuses))
     "Valid reel-button patch must not fail default layout rules")
    (layout-topicmap-assert-true
     (find :position-control-rail preview-effects :key #'hyperdoc:kind-of)
     "Preview renderer effects must include local control-rail placement")
    (layout-topicmap-assert-true
     (find :set-style preview-effects :key #'hyperdoc:kind-of)
     "Preview renderer effects must reserve pane bottom clearance")
    (layout-topicmap-assert-true
     (find :durable-override apply-effects :key #'hyperdoc:kind-of)
     "Apply renderer effects must create durable replay metadata")
    (layout-topicmap-assert-true
     (hyperdoc:layout-repair-plan-preview-apply-boundary-of plan)
     "Repair plan must expose the preview/apply boundary")
    (let* ((unknown-rule
             (hyperdoc::make-layout-rule
              "unknown-invariant"
              "Unknown invariant"
              "Unsupported rules fail explicitly."
              :unknown-invariant))
           (failure-result
             (hyperdoc:apply-layout-rule unknown-rule patch)))
      (layout-topicmap-assert-equal
       :fail
       (hyperdoc:layout-rule-result-status-of failure-result)
       "Unsupported rule invariant must fail explicitly")
      (layout-topicmap-assert-true
       (typep (hyperdoc:layout-rule-result-failure-of failure-result)
              'hyperdoc:layout-rule-failure)
       "Unsupported rule invariant must produce a failure object"))))

(defun run-layout-topicmap-topic-cluster-smoke-test ()
  (asdf:load-system :hyperdoc)
  (dolist (title '("Layout as Topicmap"
                   "Inspector Reel layout topicmap"
                   "move-topic-into-box-patch"
                   "layout-repair-plan"))
    (layout-topicmap-assert-true
     (hyperbook:find-page hyperdoc::*topics* title :signal-error? t)
     (format nil "Topic cluster must include ~A" title))))

(defun run-layout-topicmap-smoke-tests ()
  (run-layout-topicmap-snapshot-smoke-test)
  (run-layout-topicmap-move-patch-smoke-test)
  (run-layout-repair-plan-smoke-test)
  (run-layout-topicmap-topic-cluster-smoke-test)
  (format t "~&Layout topicmap smoke tests passed.~%")
  t)
