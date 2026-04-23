;;;; Focused smoke tests for Shared Projection IR and Behavior IR
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-SHARED-PROJECTION-IR-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun shared-projection-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun shared-projection-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun shared-projection-assert-typep (expected-type object message)
  (unless (typep object expected-type)
    (error "~A -- expected type: ~S actual type: ~S"
           message
           expected-type
           (type-of object))))

(defun shared-projection-assert-contains (substring string message)
  (unless (search substring string :test #'char=)
    (error "~A -- missing substring: ~S" message substring)))

(defun shared-projection-smoke-find-view-by-title (views title)
  (find title
        views
        :key #'html-inspector-views:view-title
        :test #'string=))

(defun shared-projection-smoke-load-inspector-views-for-object (object)
  (let ((pane (make-instance 'clog-moldable-inspector::pane
                             :inspector nil
                             :object object)))
    (clog-moldable-inspector::load-views pane)
    (slot-value pane 'clog-moldable-inspector::views)))

(defun shared-projection-smoke-state-ids (machine)
  (sort (mapcar #'hyperdoc::id-of
                (hyperdoc::state-machine-definition-states-of machine))
        #'string<))

(defun shared-projection-smoke-transition-signatures (machine)
  (sort (mapcar
         (lambda (transition)
           (list (hyperdoc::id-of transition)
                 (hyperdoc::state-machine-transition-from-state-of transition)
                 (hyperdoc::state-machine-transition-to-state-of transition)
                 (hyperdoc::state-machine-transition-trigger-of transition)
                 (hyperdoc::state-machine-transition-guard-of transition)))
         (hyperdoc::state-machine-definition-transitions-of machine))
        #'string<
        :key #'car))

(defun shared-projection-make-visible-topicmap-json ()
  (let ((topicmap (make-hash-table :test #'equal))
        (topic (make-hash-table :test #'equal))
        (entry (make-hash-table :test #'equal))
        (view-props (make-hash-table :test #'equal)))
    (setf (gethash "id" topic) 919822
          (gethash "value" topic) "context-window"
          (gethash "typeUri" topic) "dmx.topicmaps.topicmap"
          (gethash "children" topic) (make-hash-table :test #'equal))
    (setf (gethash "id" entry) 123
          (gethash "value" entry) "Visible topic"
          (gethash "typeUri" entry) "dmx.notes.note"
          (gethash "children" entry) (make-hash-table :test #'equal))
    (setf (gethash "dmx.topicmaps.x" view-props) 10
          (gethash "dmx.topicmaps.y" view-props) 20
          (gethash "dmx.topicmaps.visibility" view-props) t
          (gethash "dmx.topicmaps.pinned" view-props) nil)
    (setf (gethash "viewProps" entry) view-props)
    (setf (gethash "topic" topicmap) topic
          (gethash "topics" topicmap) (vector entry))
    topicmap))

(defun shared-projection-make-visible-topic-json ()
  (let ((topic (make-hash-table :test #'equal))
        (children (make-hash-table :test #'equal))
        (title-child (make-hash-table :test #'equal)))
    (setf (gethash "id" topic) 123
          (gethash "uri" topic) "dmx://topic/123"
          (gethash "typeUri" topic) "dmx.notes.note"
          (gethash "value" topic) "Visible topic"
          (gethash "children" topic) children)
    (setf (gethash "value" title-child) "Visible topic"
          (gethash "typeUri" title-child) "dmx.notes.title")
    (setf (gethash "dmx.notes.title" children) title-child)
    topic))

(defun run-shared-projection-runtime-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (let* ((window (hyperdoc::make-workspace-annotation-shared-projection-example))
         (machine (hyperdoc::shared-projection-context-window-primary-machine
                   window))
         (run (hyperdoc::shared-projection-context-window-primary-run window))
         (trace (hyperdoc::shared-projection-context-window-primary-trace
                 window)))
    (shared-projection-assert-typep
     'hyperdoc::shared-projection-context-window
     window
     "Worked example must materialize as a shared-projection-context-window")
    (shared-projection-assert-typep
     'hyperdoc::behavior-machine-definition
     machine
     "Worked example must materialize a behavior-machine-definition")
    (shared-projection-assert-typep
     'hyperdoc::behavior-run
     run
     "Worked example must materialize a behavior-run")
    (shared-projection-assert-typep
     'hyperdoc::behavior-trace
     trace
     "Worked example must materialize a behavior-trace")
    (shared-projection-assert-equal
     '("annotation/123")
     (hyperdoc::shared-projection-context-window-focus-entity-ids-of window)
     "Worked example must keep stable focus ids")
    (shared-projection-assert-equal
     '("workspace_annotation_lifecycle")
     (hyperdoc::shared-projection-context-window-active-behavior-machine-ids-of
      window)
     "Worked example must keep stable active behavior machine ids")))

(defun run-shared-projection-json-roundtrip-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (let* ((window (hyperdoc::make-workspace-annotation-shared-projection-example))
         (json-text (hyperdoc::shared-projection-context-window-json-string
                     window))
         (json-object (shasht:read-json json-text))
         (roundtrip
           (hyperdoc::shared-projection-context-window-from-json-string
            json-text))
         (first-entity
           (first (hyperdoc::shared-projection-context-window-entities-of
                   roundtrip)))
         (first-relation
           (first (hyperdoc::shared-projection-context-window-relations-of
                   roundtrip)))
         (first-event
           (first (hyperdoc::shared-projection-context-window-journal-events-of
                   roundtrip))))
    (shared-projection-assert-equal
     1
     (gethash "schemaVersion" json-object)
     "Top-level JSON form must be versioned")
    (shared-projection-assert-equal
     (hyperdoc::id-of window)
     (hyperdoc::id-of roundtrip)
     "Context-window id must survive JSON round-trip")
    (shared-projection-assert-equal
     (hyperdoc::shared-projection-context-window-entity-ids-of window)
     (hyperdoc::shared-projection-context-window-entity-ids-of roundtrip)
     "Entity ids must survive JSON round-trip")
    (shared-projection-assert-equal
     (hyperdoc::shared-projection-context-window-relation-ids-of window)
     (hyperdoc::shared-projection-context-window-relation-ids-of roundtrip)
     "Relation ids must survive JSON round-trip")
    (shared-projection-assert-equal
     "annotation/123"
     (hyperdoc::shared-projection-entity-journal-subject-key-of first-entity)
     "Journal linkage must survive JSON round-trip")
    (shared-projection-assert-equal
     "hyperdoc-journal"
     (hyperdoc::shared-projection-provenance-source-kind-of
      (hyperdoc::shared-projection-entity-provenance-of first-entity))
     "Provenance source-kind must survive JSON round-trip")
    (shared-projection-assert-equal
     "annotation-has-machine"
     (hyperdoc::shared-projection-relation-type-of first-relation)
     "Typed relation must survive JSON round-trip")
    (shared-projection-assert-equal
     "replayable"
     (hyperdoc::shared-projection-journal-event-replay-status-of first-event)
     "Journal replay status must survive JSON round-trip")
    (shared-projection-assert-equal
     "rebuildable-shared-projection"
     (hyperdoc::shared-projection-context-window-projection-status-of roundtrip)
     "Projection status must survive JSON round-trip")))

(defun run-shared-projection-behavior-roundtrip-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (let* ((generic-machine (hyperdoc::make-example-state-machine-definition))
         (behavior-machine
           (hyperdoc::state-machine-definition->behavior-machine-definition
            generic-machine))
         (machine (hyperdoc::make-workspace-annotation-behavior-machine-definition))
         (scxml (hyperdoc::behavior-machine-definition->scxml machine))
         (roundtrip (hyperdoc::scxml->behavior-machine-definition scxml)))
    (shared-projection-assert-typep
     'hyperdoc::behavior-machine-definition
     behavior-machine
     "Generic HyperDoc state-machine definitions must normalize into Behavior IR")
    (shared-projection-assert-equal
     (hyperdoc::id-of machine)
     (hyperdoc::id-of roundtrip)
     "SCXML round-trip must preserve machine id semantically")
    (shared-projection-assert-equal
     (hyperdoc::state-machine-definition-initial-state-of machine)
     (hyperdoc::state-machine-definition-initial-state-of roundtrip)
     "SCXML round-trip must preserve initial state semantically")
    (shared-projection-assert-equal
     (shared-projection-smoke-state-ids machine)
     (shared-projection-smoke-state-ids roundtrip)
     "SCXML round-trip must preserve the state set semantically")
    (shared-projection-assert-equal
     (shared-projection-smoke-transition-signatures machine)
     (shared-projection-smoke-transition-signatures roundtrip)
     "SCXML round-trip must preserve transition semantics")
    (shared-projection-assert-equal
     (sort (copy-list
            (hyperdoc::state-machine-definition-terminal-states-of machine))
           #'string<)
     (sort (copy-list
            (hyperdoc::state-machine-definition-terminal-states-of roundtrip))
           #'string<)
     "SCXML round-trip must preserve final states semantically")
    (shared-projection-assert-contains
     "<scxml"
     scxml
     "Behavior IR must export SCXML text")
    (shared-projection-assert-contains
     "workspace_annotation_lifecycle"
     scxml
     "Exported SCXML must name the stable example machine id")))

(defun run-shared-projection-rendering-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (let* ((window (hyperdoc::make-workspace-annotation-shared-projection-example))
         (views (shared-projection-smoke-load-inspector-views-for-object
                 window)))
    (dolist (title '("Summary"
                     "Graph / relations"
                     "Behavior machine"
                     "Current run / trace"
                     "Provenance / source evidence"
                     "SCXML"
                     "JavaScript / JSON"))
      (shared-projection-assert-true
       (shared-projection-smoke-find-view-by-title views title)
       (format nil "Shared projection context window must expose view ~A"
               title)))
    (shared-projection-assert-contains
     "rebuildable-shared-projection"
     (html-inspector-views:view-html
      (shared-projection-smoke-find-view-by-title views "Summary"))
     "Summary view must surface projection status")
    (shared-projection-assert-contains
     "rel/annotation-has-machine"
     (html-inspector-views:view-html
      (shared-projection-smoke-find-view-by-title views "Graph / relations"))
     "Graph / relations view must surface the worked example relation")
    (shared-projection-assert-contains
     "annotation/123"
     (html-inspector-views:view-html
      (shared-projection-smoke-find-view-by-title views
                                                  "Provenance / source evidence"))
     "Provenance view must surface the journal-linked subject key")
    (shared-projection-assert-contains
     "data-shared-projection-scxml"
     (html-inspector-views:view-html
      (shared-projection-smoke-find-view-by-title views "SCXML"))
     "SCXML view must surface a dedicated SCXML payload region")
    (shared-projection-assert-contains
     "&lt;scxml"
     (html-inspector-views:view-html
      (shared-projection-smoke-find-view-by-title views "SCXML"))
     "SCXML view must surface behavior SCXML text as escaped inspector HTML")))

(defun run-shared-projection-negative-distinction-smoke-test ()
  (asdf:load-system :hyperdoc)
  (let* ((window
           (hyperdoc::dmx-topicmap-json->shared-projection-context-window
            (shared-projection-make-visible-topicmap-json)
            :topic-jsons (list (shared-projection-make-visible-topic-json))
            :workspace-json nil
            :active-behavior-machine-ids nil))
         (entity
           (first (hyperdoc::shared-projection-context-window-entities-of
                   window))))
    (shared-projection-assert-true
     (hyperdoc::shared-projection-entity-topicmap-memberships-of entity)
     "Visible topicmap membership must be reconstructed")
    (shared-projection-assert-true
     (null (hyperdoc::shared-projection-entity-workspace-assignment-of entity))
     "Topicmap visibility must not imply workspace assignment")
    (shared-projection-assert-true
     (null (hyperdoc::shared-projection-entity-owner-class-of entity))
     "Topicmap visibility must not imply ownership")
    (shared-projection-assert-equal
     t
     (gethash "dmx.topicmaps.visibility"
              (hyperdoc::shared-projection-topicmap-membership-view-props-of
               (first (hyperdoc::shared-projection-entity-topicmap-memberships-of
                       entity))))
     "Visibility must stay a projection property rather than an ownership fact")))

(defun run-shared-projection-ir-smoke-tests ()
  (run-shared-projection-runtime-smoke-test)
  (run-shared-projection-json-roundtrip-smoke-test)
  (run-shared-projection-behavior-roundtrip-smoke-test)
  (run-shared-projection-rendering-smoke-test)
  (run-shared-projection-negative-distinction-smoke-test)
  (format t "~&Shared Projection IR smoke tests passed.~%"))
