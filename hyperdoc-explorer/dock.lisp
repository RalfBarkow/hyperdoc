;;;; Dock presentation explorer views
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defun dock-evidence-pathname (evidence)
  (let ((relative-path (relative-path-of evidence)))
    (and relative-path
         (ignore-errors
           (asdf:system-relative-pathname :hyperdoc relative-path)))))

(defun dock-evidence-path-status (evidence)
  (if (and (dock-evidence-pathname evidence)
           (probe-file (dock-evidence-pathname evidence)))
      "present"
      "missing"))

(defmethod views:text-representation ((model dock-presentation-model))
  (shorten-dom-association-label (title-of model)))

(defmethod views:text-representation ((state dock-presentation-state))
  (title-of state))

(defmethod views:text-representation ((transition dock-presentation-transition))
  (shorten-dom-association-label (title-of transition)))

(defmethod views:text-representation ((claim dock-claim-code-relation))
  (shorten-dom-association-label (title-of claim)))

(defmethod views:text-representation ((evidence dock-implementation-evidence))
  (shorten-dom-association-label (title-of evidence)))

(defmethod views:text-representation ((artifact mobile-progressive-chrome-scxml-artifact))
  (shorten-dom-association-label (title-of artifact)))

(defmethod views:text-representation ((plan mobile-progressive-chrome-plan))
  (shorten-dom-association-label (title-of plan)))

(defmethod views:text-representation ((task mobile-progressive-chrome-plan-task))
  (shorten-dom-association-label (title-of task)))

(defmethod views:title-bar-action-buttons ((evidence dock-implementation-evidence))
  (let ((pathname (dock-evidence-pathname evidence)))
    (when pathname
      (views:html
       (views:eval-button
        "Open pathname"
        (views:thunk pathname)
        "Open the repo pathname captured as implementation evidence.")))))

(views:defview 👀overview (model dock-presentation-model)
  (views:html-view :title "Overview" :priority 1
                   (views:html
                    (:h3 (views:esc (title-of model)))
                    (:p (views:esc (summary-of model)))
                    (:table :class "inspector-table"
                            (render-connect-field-row "States" (length (states-of model)))
                            (render-connect-field-row "Transitions"
                                                      (length (transitions-of model)))
                            (render-connect-field-row "Claims" (length (claims-of model)))))))

(views:defview 👀states (model dock-presentation-model)
  (views:html-view :title "States" :priority 2
                   (views:html
                    (:table :class "inspector-table"
                            (:tr (:th "State")
                                 (:th "Summary")
                                 (:th "Compact representation")
                                 (:th "Expanded representation")
                                 (:th "Capabilities"))
                            (loop for state in (states-of model)
                                  do (views:html
                                      (:tr (:td (views:object-ref state))
                                           (:td (views:esc (summary-of state)))
                                           (:td (views:esc
                                                 (or (compact-representation-of state)
                                                     "-")))
                                           (:td (views:esc
                                                 (or (expanded-representation-of state)
                                                     "-")))
                                           (:td (render-connect-data-cell
                                                 (capabilities-of state))))))))))

(views:defview 👀transitions (model dock-presentation-model)
  (views:html-view :title "Transitions" :priority 3
                   (views:html
                    (:table :class "inspector-table"
                            (:tr (:th "Transition")
                                 (:th "From")
                                 (:th "To")
                                 (:th "Trigger")
                                 (:th "Exit condition"))
                            (loop for transition in (transitions-of model)
                                  do (views:html
                                      (:tr (:td (views:object-ref transition))
                                           (:td (views:object-ref
                                                 (from-state-of transition)))
                                           (:td (views:object-ref
                                                 (to-state-of transition)))
                                           (:td (views:esc
                                                 (or (trigger-of transition) "-")))
                                           (:td (views:esc
                                                 (or (exit-condition-of transition)
                                                     "-"))))))))))

(views:defview 👀claims (model dock-presentation-model)
  (views:html-view :title "Claims" :priority 4
                   (views:html
                    (:table :class "inspector-table"
                            (:tr (:th "Claim")
                                 (:th "Summary")
                                 (:th "Evidence"))
                            (loop for claim in (claims-of model)
                                  do (views:html
                                      (:tr (:td (views:object-ref claim))
                                           (:td (views:esc (summary-of claim)))
                                           (:td (render-connect-data-cell
                                                 (evidence-of claim))))))))))

(views:defview 👀overview (state dock-presentation-state)
  (views:html-view :title "Overview" :priority 1
                   (views:html
                    (:h3 (views:esc (title-of state)))
                    (:p (views:esc (summary-of state)))
                    (:table :class "inspector-table"
                            (render-connect-field-row "Compact representation"
                                                      (compact-representation-of state))
                            (render-connect-field-row "Expanded representation"
                                                      (expanded-representation-of state))
                            (render-connect-rich-field-row "Entry triggers"
                                                           (entry-triggers-of state))
                            (render-connect-rich-field-row "Exit conditions"
                                                           (exit-conditions-of state))
                            (render-connect-rich-field-row "Capabilities"
                                                           (capabilities-of state))))))

(views:defview 👀claims (state dock-presentation-state)
  (views:html-view :title "Claims" :priority 2
                   (views:html
                    (:table :class "inspector-table"
                            (:tr (:th "Claim")
                                 (:th "Summary")
                                 (:th "Evidence"))
                            (loop for claim in (claims-of state)
                                  do (views:html
                                      (:tr (:td (views:object-ref claim))
                                           (:td (views:esc (summary-of claim)))
                                           (:td (render-connect-data-cell
                                                 (evidence-of claim))))))))))

(views:defview 👀overview (transition dock-presentation-transition)
  (views:html-view :title "Overview" :priority 1
                   (views:html
                    (:h3 (views:esc (title-of transition)))
                    (:p (views:esc (summary-of transition)))
                    (:table :class "inspector-table"
                            (render-connect-field-row "From state"
                                                      (from-state-of transition))
                            (render-connect-field-row "To state"
                                                      (to-state-of transition))
                            (render-connect-field-row "Trigger"
                                                      (trigger-of transition))
                            (render-connect-field-row "Exit condition"
                                                      (exit-condition-of transition))
                            (render-connect-rich-field-row "Claims"
                                                           (claims-of transition))))))

(views:defview 👀overview (claim dock-claim-code-relation)
  (views:html-view :title "Overview" :priority 1
                   (views:html
                    (:h3 (views:esc (title-of claim)))
                    (:p (views:esc (summary-of claim)))
                    (:h4 "Claim")
                    (:pre :style "white-space: pre-wrap"
                          (views:esc (claim-text-of claim)))
                    (:h4 "Evidence")
                    (render-connect-data-cell (evidence-of claim)))))

(views:defview 👀evidence (claim dock-claim-code-relation)
  (views:html-view :title "Evidence" :priority 2
                   (views:html
                    (:table :class "inspector-table"
                            (:tr (:th "Evidence")
                                 (:th "Surface")
                                 (:th "Path")
                                 (:th "Target"))
                            (loop for evidence in (evidence-of claim)
                                  do (views:html
                                      (:tr (:td (views:object-ref evidence))
                                           (:td (views:esc
                                                 (or (surface-kind-of evidence) "-")))
                                           (:td (:tt (views:esc
                                                      (or (relative-path-of evidence)
                                                          "-"))))
                                           (:td (views:esc
                                                 (or (target-name-of evidence) "-"))))))))))

(views:defview 👀overview (evidence dock-implementation-evidence)
  (views:html-view :title "Overview" :priority 1
                   (views:html
                    (:h3 (views:esc (title-of evidence)))
                    (:p (views:esc (summary-of evidence)))
                    (:table :class "inspector-table"
                            (render-connect-field-row "Surface kind"
                                                      (surface-kind-of evidence))
                            (render-connect-field-row "Relative path"
                                                      (relative-path-of evidence))
                            (render-connect-field-row "Target name"
                                                      (target-name-of evidence))
                            (render-connect-field-row "Path status"
                                                      (dock-evidence-path-status evidence))))))

(views:defview 👀path (evidence dock-implementation-evidence)
  (views:html-view :title "Path" :priority 2
                   (let ((pathname (dock-evidence-pathname evidence)))
                     (views:html
                      (:table :class "inspector-table"
                              (render-connect-field-row "Relative path"
                                                        (relative-path-of evidence))
                              (render-connect-field-row "Absolute pathname"
                                                        (and pathname
                                                             (namestring pathname)))
                              (render-connect-field-row "Exists"
                                                        (dom-connect-bool-label
                                                         (and pathname
                                                              (probe-file pathname)))))))))

(views:defview 👀overview (artifact mobile-progressive-chrome-scxml-artifact)
  (views:html-view :title "Overview" :priority 1
                   (views:html
                    (:h3 (views:esc (title-of artifact)))
                    (:p (views:esc (summary-of artifact)))
                    (:table :class "inspector-table"
                            (render-connect-field-row "Relative path"
                                                      (relative-path-of artifact))
                            (render-connect-rich-field-row
                             "Events"
                             (mobile-progressive-chrome-scxml-events-of artifact))
                            (render-connect-rich-field-row
                             "Guards"
                             (mobile-progressive-chrome-scxml-guards-of artifact))
                            (render-connect-rich-field-row
                             "Invariants"
                             (mobile-progressive-chrome-scxml-invariants-of artifact))))))

(views:defview 👀source (artifact mobile-progressive-chrome-scxml-artifact)
  (views:html-view :title "SCXML" :priority 2
                   (views:html
                    (:pre :style "white-space: pre-wrap"
                          (views:esc
                           (mobile-progressive-chrome-scxml-source))))))

(views:defview 👀overview (plan mobile-progressive-chrome-plan)
  (views:html-view :title "Overview" :priority 1
                   (views:html
                    (:h3 (views:esc (title-of plan)))
                    (:p (views:esc (summary-of plan)))
                    (:table :class "inspector-table"
                            (render-connect-field-row
                             "Tasks"
                             (length (mobile-progressive-chrome-plan-tasks-of plan)))
                            (render-connect-rich-field-row
                             "Done"
                             (mapcar #'title-of
                                     (remove-if-not
                                      (lambda (task)
                                        (string= "done"
                                                 (mobile-progressive-chrome-plan-task-status-of
                                                  task)))
                                      (mobile-progressive-chrome-plan-tasks-of
                                       plan))))))))

(views:defview 👀tasks (plan mobile-progressive-chrome-plan)
  (views:html-view :title "Tasks" :priority 2
                   (views:html
                    (:table :class "inspector-table"
                            (:tr (:th "Task")
                                 (:th "Status")
                                 (:th "Implementation evidence")
                                 (:th "Validation evidence")
                                 (:th "Dependencies"))
                            (loop for task in (mobile-progressive-chrome-plan-tasks-of plan)
                                  do (views:html
                                      (:tr
                                       (:td (views:object-ref task))
                                       (:td (views:esc
                                             (mobile-progressive-chrome-plan-task-status-of
                                              task)))
                                       (:td (:tt
                                             (views:esc
                                              (or (mobile-progressive-chrome-plan-task-implementation-evidence-path-of
                                                   task)
                                                  "-"))))
                                       (:td (:tt
                                             (views:esc
                                              (or (mobile-progressive-chrome-plan-task-validation-evidence-path-of
                                                   task)
                                                  "-"))))
                                       (:td
                                        (render-connect-data-cell
                                         (mobile-progressive-chrome-plan-task-dependency-ids-of
                                          task))))))))))

(views:defview 👀overview (task mobile-progressive-chrome-plan-task)
  (views:html-view :title "Overview" :priority 1
                   (views:html
                    (:h3 (views:esc (title-of task)))
                    (:p (views:esc (summary-of task)))
                    (:table :class "inspector-table"
                            (render-connect-field-row
                             "Status"
                             (mobile-progressive-chrome-plan-task-status-of task))
                            (render-connect-field-row
                             "Implementation evidence"
                             (mobile-progressive-chrome-plan-task-implementation-evidence-path-of
                              task))
                            (render-connect-field-row
                             "Validation evidence"
                             (mobile-progressive-chrome-plan-task-validation-evidence-path-of
                              task))
                            (render-connect-rich-field-row
                             "Dependencies"
                             (mobile-progressive-chrome-plan-task-dependency-ids-of
                              task))))))
