;;;; Inspector views for Architect-style SCXML sessions
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc/inspector)

(defun scxml-architect-bool-label (value)
  (if value "yes" "no"))

(defun scxml-architect-path-string (path)
  (if path
      (format nil "~{~A~^ \u2192 ~}" path)
      "-"))

(defun scxml-architect-event-list-string (events)
  (if events
      (format nil "~{~A~^, ~}" events)
      "-"))

(defun scxml-architect-event-groups (session)
  (let* ((view-model (hyperdoc::scxml-architect-session-presentation-binding-of
                      session)))
    (or (and view-model
             (hyperdoc::dmx-annotation-workspace-architect-view-model-event-groups-of
              view-model))
        '())))

(defun scxml-architect-scxml-source-text (session)
  (handler-case
      (uiop:read-file-string
       (hyperdoc::scxml-architect-session-scxml-path-of session))
    (condition (condition)
      (format nil "Could not read SCXML source: ~A" condition))))

(views:defview 👀workspace (session hyperdoc::scxml-architect-session)
  (views:html-view :title "Workspace" :priority 1
    (let* ((view-model
             (hyperdoc::scxml-architect-session-presentation-binding-of session))
           (source-run (and view-model
                            (hyperdoc::dmx-annotation-workspace-architect-view-model-source-run-of
                             view-model)))
           (local-lane (and view-model
                            (hyperdoc::dmx-annotation-workspace-architect-view-model-local-lane-of
                             view-model)))
           (dmx-lane (and view-model
                          (hyperdoc::dmx-annotation-workspace-architect-view-model-dmx-lane-of
                           view-model))))
      (views:html
        (:p (views:esc
             "Architect surface for Workspace behavior: local-journal lane, DMX projection lane, active state path, and next legal semantic event."))
        (:table :class "inspector-table"
                (:tr (:td (views:esc "SCXML"))
                     (:td (:tt (views:esc
                                (namestring
                                 (hyperdoc::scxml-architect-session-scxml-path-of
                                  session))))))
                (:tr (:td (views:esc "Active state path"))
                     (:td (:tt (views:esc
                                (scxml-architect-path-string
                                 (hyperdoc::scxml-architect-session-active-state-path-of
                                  session))))))
                (:tr (:td (views:esc "Selected event"))
                     (:td (:tt (views:esc
                                (or (hyperdoc::scxml-architect-session-selected-event-of
                                     session)
                                    "-")))))
                (:tr (:td (views:esc "Preview path"))
                     (:td (:tt (views:esc
                                (scxml-architect-path-string
                                 (hyperdoc::scxml-architect-session-preview-path-of
                                  session))))))
                (:tr (:td (views:esc "Target workspace"))
                     (:td (:tt (views:esc
                                (format nil "~A"
                                        (or (and view-model
                                                 (hyperdoc::dmx-annotation-workspace-architect-view-model-target-workspace-id-of
                                                  view-model))
                                            "-"))))))
                (:tr (:td (views:esc "Target topicmap"))
                     (:td (:tt (views:esc
                                (format nil "~A"
                                        (or (and view-model
                                                 (hyperdoc::dmx-annotation-workspace-architect-view-model-target-topicmap-id-of
                                                  view-model))
                                            "-"))))))
                (:tr (:td (views:esc "Local lane state"))
                     (:td (:tt (views:esc
                                (or (getf local-lane :state) "-")))))
                (:tr (:td (views:esc "Local journal event id"))
                     (:td (:tt (views:esc
                                (format nil "~A"
                                        (or (getf local-lane :event-id) "-"))))))
                (:tr (:td (views:esc "Local save authoritative"))
                     (:td (:tt (views:esc
                                (scxml-architect-bool-label
                                 (getf local-lane :authoritative-p))))))
                (:tr (:td (views:esc "Carrier topic"))
                     (:td (:tt (views:esc
                                (or (getf dmx-lane :carrier-topic) "-")))))
                (:tr (:td (views:esc "Assignment status"))
                     (:td (:tt (views:esc
                                (or (getf dmx-lane :assignment-status) "-")))))
                (:tr (:td (views:esc "Topicmap placement status"))
                     (:td (:tt (views:esc
                                (or (getf dmx-lane :topicmap-placement-status) "-")))))
                (:tr (:td (views:esc "Projection visible after success"))
                     (:td (:tt (views:esc
                                (or (getf dmx-lane :projection-surface) "-"))))))
        (when source-run
          (views:html
            (:p
             (views:object-ref
              source-run
              :display "Open underlying workspace SCXML plan run"))))))))

(views:defview 👀statechart (session hyperdoc::scxml-architect-session)
  (views:html-view :title "Statechart" :priority 2
    (views:html
      (:p (views:esc
           "Large statechart rendering with active and preview path highlighting."))
      (views:graphviz-snippet
       (hyperdoc::scxml-architect-session-graphviz-dot-of session)
       :fallback-title
       "Statechart fallback graph text"))))

(views:defview 👀events (session hyperdoc::scxml-architect-session)
  (views:html-view :title "Events" :priority 3
    (views:html
      (:p (views:esc
           "Enabled semantic events grouped by Workspace hierarchy and advanced diagnostics."))
      (dolist (group (scxml-architect-event-groups session))
        (let ((group-label (getf group :group-label))
              (plans (getf group :plans)))
          (views:html
            (:h4 (views:esc group-label))
            (:table :class "inspector-table"
                    (:tr (:th "Event")
                         (:th "Label")
                         (:th "Function")
                         (:th "Local mutation")
                         (:th "DMX mutation")
                         (:th "Auth required")
                         (:th "TOPIC_UPSERT"))
                    (dolist (plan plans)
                      (views:html
                        (:tr
                         (:td (:tt (views:esc
                                    (hyperdoc::dmx-annotation-workspace-view-action-plan-event
                                     plan))))
                         (:td (views:esc
                               (hyperdoc::dmx-annotation-workspace-view-action-plan-label
                                plan)))
                         (:td (:tt (views:esc
                                    (format nil "~A"
                                            (hyperdoc::dmx-annotation-workspace-view-action-plan-function
                                             plan)))))
                         (:td (:tt (views:esc
                                    (scxml-architect-bool-label
                                     (hyperdoc::dmx-annotation-workspace-view-action-plan-local-mutation-p
                                      plan)))))
                         (:td (:tt (views:esc
                                    (scxml-architect-bool-label
                                     (hyperdoc::dmx-annotation-workspace-view-action-plan-dmx-mutation-p
                                      plan)))))
                         (:td (:tt (views:esc
                                    (scxml-architect-bool-label
                                     (hyperdoc::dmx-annotation-workspace-view-action-plan-auth-required-p
                                      plan)))))
                         (:td (:tt (views:esc
                                    (scxml-architect-bool-label
                                     (hyperdoc::dmx-annotation-workspace-view-action-plan-topic-upsert-p
                                      plan)))))))))))))))

(views:defview 👀differences (session hyperdoc::scxml-architect-session)
  (views:html-view :title "Differences" :priority 4
    (views:html
      (:p (views:esc
           "Programming-by-differences view: inherited parent behavior vs leaf-state differences."))
      (:table :class "inspector-table"
              (:tr (:th "State")
                   (:th "Role")
                   (:th "Inherited events")
                   (:th "Leaf events")
                   (:th "Differences"))
              (dolist (entry (or (hyperdoc::scxml-architect-session-state-metadata-of
                                  session)
                                 '()))
                (views:html
                  (:tr
                   (:td (:tt (views:esc (or (getf entry :state-id) "-"))))
                   (:td (:tt (views:esc (format nil "~A" (getf entry :role)))))
                   (:td (:tt (views:esc
                              (scxml-architect-event-list-string
                               (getf entry :inherited-events)))))
                   (:td (:tt (views:esc
                              (scxml-architect-event-list-string
                               (getf entry :leaf-events)))))
                   (:td (:tt (views:esc
                              (scxml-architect-event-list-string
                               (getf entry :differences))))))))))))

(views:defview 👀plan (session hyperdoc::scxml-architect-session)
  (views:html-view :title "Plan" :priority 5
    (let ((run (hyperdoc::scxml-architect-session-source-object-of session)))
      (views:html
        (:p (views:esc
             "No live mutation is performed in this plan view; it summarizes state/event/preview/effects and typed targets."))
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Current state"))
                     (:td (:tt (views:esc
                                (or (and run
                                         (hyperdoc::dmx-annotation-workspace-view-run-current-state-of
                                          run))
                                    "-")))))
                (:tr (:td (views:esc "Selected event"))
                     (:td (:tt (views:esc
                                (or (hyperdoc::scxml-architect-session-selected-event-of
                                     session)
                                    "-")))))
                (:tr (:td (views:esc "Preview path"))
                     (:td (:tt (views:esc
                                (scxml-architect-path-string
                                 (hyperdoc::scxml-architect-session-preview-path-of
                                  session))))))
                (:tr (:td (views:esc "Transition effects"))
                     (:td (:tt (views:esc
                                (format nil "~D"
                                        (length
                                         (or (hyperdoc::scxml-architect-session-transition-effects-of
                                              session)
                                             '())))))))
                (:tr (:td (views:esc "Target workspace"))
                     (:td (:tt (views:esc
                                (format nil "~A"
                                        (or (and run
                                                 (hyperdoc::dmx-annotation-workspace-view-run-workspace-id-of
                                                  run))
                                            "-"))))))
                (:tr (:td (views:esc "Target topicmap"))
                     (:td (:tt (views:esc
                                (format nil "~A"
                                        (or (and run
                                                 (hyperdoc::dmx-annotation-workspace-view-run-workspace-topicmap-id-of
                                                  run))
                                            "-"))))))
        (when (and run
                   (hyperdoc::dmx-annotation-workspace-view-run-workspace-write-plan-of
                    run))
          (views:html
            (:p (views:object-ref
                 (hyperdoc::dmx-annotation-workspace-view-run-workspace-write-plan-of
                  run)
                 :display "Typed workspace write/projection plan"))))
        (when (and run
                   (hyperdoc::dmx-annotation-workspace-view-run-auth-session-submachine-run-of
                    run))
          (views:html
            (:p (views:object-ref
                 (hyperdoc::dmx-annotation-workspace-view-run-auth-session-submachine-run-of
                  run)
                 :display "Auth/session submachine run")))))))))

(views:defview 👀raw (session hyperdoc::scxml-architect-session)
  (views:html-view :title "Raw" :priority 6
    (views:html
      (:details
       (:summary (views:esc "SCXML source"))
       (:pre :style "white-space: pre-wrap;"
             (views:esc
              (scxml-architect-scxml-source-text session))))
      (:details
       (:summary (views:esc "DOT source"))
       (:pre :style "white-space: pre-wrap;"
             (views:esc
              (or (hyperdoc::scxml-architect-session-graphviz-dot-of session)
                  "")))))))
