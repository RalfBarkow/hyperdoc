;;;; Inspector views for Shared Projection IR and Behavior IR
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc/inspector)

(defun shared-projection-label (value)
  (cond
    ((null value) "n/a")
    ((stringp value) value)
    ((keywordp value) (string-downcase (string value)))
    ((symbolp value) (string-downcase (string value)))
    ((hash-table-p value)
     (with-output-to-string (stream)
       (let ((pairs '()))
         (maphash (lambda (key child)
                    (push (format nil "~A=~A" key child) pairs))
                  value)
         (write-string (format nil "{~{~A~^, ~}}" (nreverse pairs))
                       stream))))
    ((vectorp value)
     (format nil "~{~A~^, ~}" (coerce value 'list)))
    ((listp value)
     (format nil "~{~A~^, ~}" value))
    (t
     (format nil "~A" value))))

(defun shared-projection-lines-html (lines)
  (views:html
    (:pre (views:esc (format nil "~{~A~%~}" lines)))))

(defun shared-projection-primary-machine (window)
  (hyperdoc::shared-projection-context-window-primary-machine window))

(defun shared-projection-primary-run (window)
  (hyperdoc::shared-projection-context-window-primary-run window))

(defun shared-projection-primary-trace (window)
  (hyperdoc::shared-projection-context-window-primary-trace window))

(defun shared-projection-render-object-ref (object &key display select)
  (if object
      (views:object-ref object :display display :select select)
      (views:html (:span :style "opacity: 0.55;" "n/a"))))

(defun shared-projection-render-memberships (memberships)
  (if memberships
      (format nil
              "~:{topicmap ~A (assoc ~A)~^; ~}"
              (mapcar
               (lambda (membership)
                 (list
                  (hyperdoc::shared-projection-topicmap-membership-topicmap-id-of
                   membership)
                  (or (hyperdoc::shared-projection-topicmap-membership-assoc-id-of
                       membership)
                      "n/a")))
               memberships))
      "none"))

(defun shared-projection-render-provenance-label (provenance)
  (if provenance
      (format nil "~A / ~A / ~A"
              (shared-projection-label
               (hyperdoc::shared-projection-provenance-source-kind-of provenance))
              (shared-projection-label
               (hyperdoc::shared-projection-provenance-source-id-of provenance))
              (shared-projection-label
               (hyperdoc::shared-projection-provenance-derivation-kind-of provenance)))
      "n/a"))

(defun shared-projection-role-lines (relation)
  (mapcar
   (lambda (binding)
     (format nil "~A -> ~A"
             (hyperdoc::shared-projection-role-binding-role-of binding)
             (hyperdoc::shared-projection-role-binding-entity-id-of binding)))
   (hyperdoc::shared-projection-relation-roles-of relation)))

(defun shared-projection-context-window-summary-lines (window)
  (list
   (format nil "Workspace: ~A"
           (hyperdoc::shared-projection-context-window-workspace-name-of window))
   (format nil "Topicmap: ~A"
           (hyperdoc::shared-projection-context-window-topicmap-id-of window))
   (format nil "Projection status: ~A"
           (shared-projection-label
            (hyperdoc::shared-projection-context-window-projection-status-of window)))
   (format nil "Focus entities: ~{~A~^, ~}"
           (hyperdoc::shared-projection-context-window-focus-entity-ids-of window))
   (format nil "Entity count: ~D"
           (length (hyperdoc::shared-projection-context-window-entities-of window)))
   (format nil "Relation count: ~D"
           (length (hyperdoc::shared-projection-context-window-relations-of window)))
   (format nil "Active behavior machine ids: ~{~A~^, ~}"
           (hyperdoc::shared-projection-context-window-active-behavior-machine-ids-of
            window))
   (format nil "Source endpoints: ~{~A~^, ~}"
           (hyperdoc::shared-projection-context-window-source-endpoints-of window))))

(defun shared-projection-provenance-lines (provenance)
  (list
   (format nil "Source kind: ~A"
           (shared-projection-label
            (hyperdoc::shared-projection-provenance-source-kind-of provenance)))
   (format nil "Source id: ~A"
           (shared-projection-label
            (hyperdoc::shared-projection-provenance-source-id-of provenance)))
   (format nil "Derivation kind: ~A"
           (shared-projection-label
            (hyperdoc::shared-projection-provenance-derivation-kind-of provenance)))
   (format nil "Confidence: ~A"
           (shared-projection-label
            (hyperdoc::shared-projection-provenance-confidence-of provenance)))
   (format nil "Replay hash: ~A"
           (shared-projection-label
            (hyperdoc::shared-projection-provenance-replay-hash-of provenance)))))

(defun shared-projection-journal-event-lines (event)
  (list
   (format nil "Subject key: ~A"
           (hyperdoc::shared-projection-journal-event-subject-key-of event))
   (format nil "Timestamp: ~A"
           (hyperdoc::shared-projection-journal-event-timestamp-of event))
   (format nil "Operation: ~A"
           (hyperdoc::shared-projection-journal-event-operation-of event))
   (format nil "Target id: ~A"
           (shared-projection-label
            (hyperdoc::shared-projection-journal-event-target-id-of event)))
   (format nil "Derivation kind: ~A"
           (shared-projection-label
            (hyperdoc::shared-projection-journal-event-derivation-kind-of event)))
   (format nil "Replay status: ~A"
           (shared-projection-label
            (hyperdoc::shared-projection-journal-event-replay-status-of event)))))

(defmethod views:text-representation
    ((window hyperdoc::shared-projection-context-window))
  (format nil "~A" (hyperdoc::title-of window)))

(defmethod views:text-representation
    ((entity hyperdoc::shared-projection-entity))
  (format nil "~A" (hyperdoc::title-of entity)))

(defmethod views:text-representation
    ((relation hyperdoc::shared-projection-relation))
  (format nil "~A" (or (hyperdoc::title-of relation)
                       (hyperdoc::shared-projection-relation-type-of relation))))

(defmethod views:text-representation
    ((trace hyperdoc::behavior-trace))
  (format nil "~A" (hyperdoc::title-of trace)))

(defmethod views:text-representation
    ((provenance hyperdoc::shared-projection-provenance))
  (format nil "~A" (shared-projection-render-provenance-label provenance)))

(views:defview 👀summary (window hyperdoc::shared-projection-context-window)
  (views:html-view :title "Summary" :priority 1
    (views:html
      (:div
       (:p (views:esc (or (hyperdoc::summary-of window) "")))
       (shared-projection-lines-html
        (shared-projection-context-window-summary-lines window))
       (:h4 "Primary behavior machine")
       (shared-projection-render-object-ref
        (shared-projection-primary-machine window)
        :display
        (and (shared-projection-primary-machine window)
             (hyperdoc::title-of (shared-projection-primary-machine window))))
       (:h4 "Current run")
       (shared-projection-render-object-ref
        (shared-projection-primary-run window)
        :display
        (and (shared-projection-primary-run window)
             (hyperdoc::title-of (shared-projection-primary-run window))))
       (:h4 "Current trace")
       (shared-projection-render-object-ref
        (shared-projection-primary-trace window)
        :display
        (and (shared-projection-primary-trace window)
             (hyperdoc::title-of (shared-projection-primary-trace window))))))))

(views:defview 👀graph/relations (window hyperdoc::shared-projection-context-window)
  (views:html-view :title "Graph / relations" :priority 2
    (views:html
      (:div
       (:h4 "Entities")
       (:table :class "inspector-table"
               (:tr (:th "Entity")
                    (:th "Type")
                    (:th "Owner class")
                    (:th "Workspace assignment")
                    (:th "Topicmap memberships"))
               (dolist (entity (hyperdoc::shared-projection-context-window-entities-of
                                window))
                 (let ((assignment
                         (hyperdoc::shared-projection-entity-workspace-assignment-of
                          entity)))
                   (views:html
                     (:tr
                      (:td (views:object-ref entity :display (hyperdoc::id-of entity)))
                      (:td (:code (views:esc
                                   (shared-projection-label
                                    (hyperdoc::shared-projection-entity-type-of entity)))))
                      (:td (:code (views:esc
                                   (shared-projection-label
                                    (hyperdoc::shared-projection-entity-owner-class-of
                                     entity)))))
                      (:td (:code
                            (views:esc
                             (if assignment
                                 (format nil "~A (~A)"
                                         (hyperdoc::shared-projection-workspace-assignment-workspace-id-of
                                          assignment)
                                         (hyperdoc::shared-projection-workspace-assignment-status-of
                                          assignment))
                                 "none"))))
                      (:td (:code (views:esc
                                   (shared-projection-render-memberships
                                    (hyperdoc::shared-projection-entity-topicmap-memberships-of
                                     entity))))))))))
       (:h4 "Relations")
       (:table :class "inspector-table"
               (:tr (:th "Relation")
                    (:th "Type")
                    (:th "Roles")
                    (:th "Provenance"))
               (dolist (relation
                        (hyperdoc::shared-projection-context-window-relations-of
                         window))
                 (views:html
                   (:tr
                    (:td (views:object-ref relation :display (hyperdoc::id-of relation)))
                    (:td (:code (views:esc
                                 (shared-projection-label
                                  (hyperdoc::shared-projection-relation-type-of
                                   relation)))))
                    (:td (:pre (views:esc
                                (format nil "~{~A~%~}"
                                        (shared-projection-role-lines relation)))))
                    (:td (:code
                          (views:esc
                           (shared-projection-render-provenance-label
                            (hyperdoc::shared-projection-relation-provenance-of
                             relation)))))))))))))

(views:defview 👀behavior-machine (window hyperdoc::shared-projection-context-window)
  (let ((machine (shared-projection-primary-machine window)))
    (views:html-view :title "Behavior machine" :priority 3
      (views:html
        (:div
         (shared-projection-render-object-ref
          machine
          :display (and machine (hyperdoc::title-of machine))
          :select "Overview")
         (when machine
           (views:html
             (:h4 "Machine summary")
             (shared-projection-lines-html
              (state-machine-definition-overview-lines machine)))))))))

(views:defview 👀current-run/trace (window hyperdoc::shared-projection-context-window)
  (let ((run (shared-projection-primary-run window))
        (trace (shared-projection-primary-trace window)))
    (views:html-view :title "Current run / trace" :priority 4
      (views:html
        (:div
         (:h4 "Run")
         (shared-projection-render-object-ref
          run
          :display (and run (hyperdoc::title-of run))
          :select "Overview")
         (when run
           (views:html
             (shared-projection-lines-html
              (state-machine-run-overview-lines run))))
         (:h4 "Trace")
         (shared-projection-render-object-ref
          trace
          :display (and trace (hyperdoc::title-of trace))
          :select "Summary")
         (when trace
           (views:html
             (:pre
              (views:esc
               (format nil
                       "~{~A~%~}"
                       (cons "timestamp | transition | from | to | note | evidence"
                             (mapcar
                              (lambda (entry)
                                (format nil "~A | ~A | ~A | ~A | ~A | ~A"
                                        (shared-projection-label
                                         (hyperdoc::behavior-trace-entry-timestamp-of
                                          entry))
                                        (shared-projection-label
                                         (hyperdoc::behavior-trace-entry-transition-id-of
                                          entry))
                                        (shared-projection-label
                                         (hyperdoc::behavior-trace-entry-from-state-of
                                          entry))
                                        (shared-projection-label
                                         (hyperdoc::behavior-trace-entry-to-state-of
                                          entry))
                                        (shared-projection-label
                                         (hyperdoc::behavior-trace-entry-note-of entry))
                                        (shared-projection-label
                                         (hyperdoc::behavior-trace-entry-evidence-of
                                          entry))))
                              (hyperdoc::behavior-trace-entries-of trace)))))))))))))

(views:defview 👀provenance/source-evidence
    (window hyperdoc::shared-projection-context-window)
  (views:html-view :title "Provenance / source evidence" :priority 5
    (views:html
      (:div
       (:h4 "Source endpoints")
       (:pre (views:esc
              (format nil "~{~A~%~}"
                      (hyperdoc::shared-projection-context-window-source-endpoints-of
                       window))))
       (:h4 "Entity and relation provenance")
       (:table :class "inspector-table"
               (:tr (:th "Object")
                    (:th "Provenance")
                    (:th "Journal subject"))
               (dolist (entity (hyperdoc::shared-projection-context-window-entities-of
                                window))
                 (views:html
                   (:tr
                    (:td (views:object-ref entity :display (hyperdoc::id-of entity)))
                    (:td (views:esc
                          (shared-projection-render-provenance-label
                           (hyperdoc::shared-projection-entity-provenance-of entity))))
                    (:td (:code (views:esc
                                 (shared-projection-label
                                  (hyperdoc::shared-projection-entity-journal-subject-key-of
                                   entity))))))))
               (dolist (relation
                        (hyperdoc::shared-projection-context-window-relations-of
                         window))
                 (views:html
                   (:tr
                    (:td (views:object-ref relation :display (hyperdoc::id-of relation)))
                    (:td (views:esc
                          (shared-projection-render-provenance-label
                           (hyperdoc::shared-projection-relation-provenance-of
                            relation))))
                    (:td (:span :style "opacity: 0.55;" "n/a"))))))
       (:h4 "Journal events")
       (:table :class "inspector-table"
               (:tr (:th "Event")
                    (:th "Operation")
                    (:th "Replay status")
                    (:th "Subject"))
               (dolist (event
                        (hyperdoc::shared-projection-context-window-journal-events-of
                         window))
                 (views:html
                   (:tr
                    (:td (views:object-ref event :display (hyperdoc::id-of event)))
                    (:td (:code (views:esc
                                 (shared-projection-label
                                  (hyperdoc::shared-projection-journal-event-operation-of
                                   event)))))
                    (:td (:code (views:esc
                                 (shared-projection-label
                                  (hyperdoc::shared-projection-journal-event-replay-status-of
                                   event)))))
                    (:td (:code (views:esc
                                 (shared-projection-label
                                  (hyperdoc::shared-projection-journal-event-subject-key-of
                                   event)))))))))))))

(views:defview 👀scxml (window hyperdoc::shared-projection-context-window)
  (let ((machine (shared-projection-primary-machine window)))
    (views:html-view :title "SCXML" :priority 6
      (views:html
        (:div
         (if machine
             (views:html
               (:pre :data-shared-projection-scxml "true"
                     (views:esc (hyperdoc::behavior-machine-definition->scxml
                                 machine))))
             (views:html
               (:p "No active behavior machine."))))))))

(views:defview 👀javascript/json (window hyperdoc::shared-projection-context-window)
  (views:html-view :title "JavaScript / JSON" :priority 7
    (views:html
      (:div
       (:h4 "JavaScript plain-object form")
       (:pre :data-shared-projection-javascript "true"
             (views:esc
              (hyperdoc::shared-projection-context-window-javascript-source window)))
       (:h4 "JSON payload")
       (:pre :data-shared-projection-json "true"
             (views:esc
              (hyperdoc::shared-projection-context-window-json-string window)))))))

(views:defview 👀summary (entity hyperdoc::shared-projection-entity)
  (views:html-view :title "Summary" :priority 1
    (shared-projection-lines-html
     (list
      (format nil "Type: ~A"
              (shared-projection-label
               (hyperdoc::shared-projection-entity-type-of entity)))
      (format nil "Owner class: ~A"
              (shared-projection-label
               (hyperdoc::shared-projection-entity-owner-class-of entity)))
      (format nil "Workspace assignment: ~A"
              (if-let ((assignment
                        (hyperdoc::shared-projection-entity-workspace-assignment-of
                         entity)))
                (format nil "~A (~A)"
                        (hyperdoc::shared-projection-workspace-assignment-workspace-id-of
                         assignment)
                        (hyperdoc::shared-projection-workspace-assignment-status-of
                         assignment))
                "none"))
      (format nil "Topicmap memberships: ~A"
              (shared-projection-render-memberships
               (hyperdoc::shared-projection-entity-topicmap-memberships-of entity)))
      (format nil "Journal subject key: ~A"
              (shared-projection-label
               (hyperdoc::shared-projection-entity-journal-subject-key-of entity)))
      (format nil "Provenance: ~A"
              (shared-projection-render-provenance-label
               (hyperdoc::shared-projection-entity-provenance-of entity)))))))

(views:defview 👀summary (relation hyperdoc::shared-projection-relation)
  (views:html-view :title "Summary" :priority 1
    (shared-projection-lines-html
     (append
      (list
       (format nil "Type: ~A"
               (shared-projection-label
                (hyperdoc::shared-projection-relation-type-of relation)))
       (format nil "Provenance: ~A"
               (shared-projection-render-provenance-label
                (hyperdoc::shared-projection-relation-provenance-of relation)))
       "Roles:")
      (mapcar (lambda (line) (format nil "  ~A" line))
              (shared-projection-role-lines relation))))))

(views:defview 👀summary (trace hyperdoc::behavior-trace)
  (views:html-view :title "Summary" :priority 1
    (shared-projection-lines-html
     (list
      (format nil "Run id: ~A" (hyperdoc::behavior-trace-run-id-of trace))
      (format nil "Entry count: ~D"
              (length (hyperdoc::behavior-trace-entries-of trace)))))))

(views:defview 👀trace (trace hyperdoc::behavior-trace)
  (views:html-view :title "Trace" :priority 2
    (views:html
      (:pre
       (views:esc
        (format nil
                "~{~A~%~}"
                (cons
                 "timestamp | transition | from | to | note | evidence"
                 (mapcar
                  (lambda (entry)
                    (format nil "~A | ~A | ~A | ~A | ~A | ~A"
                            (shared-projection-label
                             (hyperdoc::behavior-trace-entry-timestamp-of entry))
                            (shared-projection-label
                             (hyperdoc::behavior-trace-entry-transition-id-of entry))
                            (shared-projection-label
                             (hyperdoc::behavior-trace-entry-from-state-of entry))
                            (shared-projection-label
                             (hyperdoc::behavior-trace-entry-to-state-of entry))
                            (shared-projection-label
                             (hyperdoc::behavior-trace-entry-note-of entry))
                            (shared-projection-label
                             (hyperdoc::behavior-trace-entry-evidence-of entry))))
                  (hyperdoc::behavior-trace-entries-of trace)))))))))

(views:defview 👀summary (provenance hyperdoc::shared-projection-provenance)
  (views:html-view :title "Summary" :priority 1
    (shared-projection-lines-html
     (shared-projection-provenance-lines provenance))))

(views:defview 👀summary (event hyperdoc::shared-projection-journal-event)
  (views:html-view :title "Summary" :priority 1
    (shared-projection-lines-html
     (shared-projection-journal-event-lines event))))

(views:defview 👀scxml (machine hyperdoc::behavior-machine-definition)
  (views:html-view :title "SCXML" :priority 1
    (views:html
      (:pre :data-behavior-machine-scxml "true"
            (views:esc (hyperdoc::behavior-machine-definition->scxml machine))))))
