;;;; Lightweight inspector views for Kioskbeerli Pi simulation objects.

(in-package :kioskbeerli/pi-simulation)

(defmethod html-inspector-views:text-representation ((plan pi-simulation-plan))
  (format nil "~A (~D tasks, ~D levels)"
          (title-of plan)
          (length (tasks-of plan))
          (length (levels-of plan))))

(defmethod html-inspector-views:text-representation ((task pi-simulation-plan-task))
  (format nil "~A level=~D ~A"
          (id-of task)
          (level-of task)
          (status-of task)))

(defmethod html-inspector-views:text-representation ((level pi-simulation-fidelity-level))
  (format nil "Level ~D: ~A" (level-of level) (title-of level)))

(defmethod html-inspector-views:text-representation ((spec pi-simulation-command-spec))
  (format nil "~A level=~D" (id-of spec) (level-of spec)))

(defmethod html-inspector-views:text-representation ((session pi-simulation-session))
  (format nil "~A boot=~A"
          (title-of session)
          (status-of (boot-status-of session))))

(defmethod html-inspector-views:text-representation ((topic pi-simulation-topic))
  (format nil "~A: ~A" (category-of topic) (title-of topic)))

(defun %render-string-list (items &optional (empty "None."))
  (if items
      (html-inspector-views:html
        (:ul
         (loop for item in items
               do (html-inspector-views:html
                    (:li (:tt (html-inspector-views:esc
                               (princ-to-string item))))))))
      (html-inspector-views:html
        (:p (html-inspector-views:esc empty)))))

(defun %render-object-list (objects &optional (empty "None."))
  (if objects
      (html-inspector-views:html
        (:ul
         (loop for object in objects
               do (html-inspector-views:html
                    (:li (html-inspector-views:object-ref object))))))
      (html-inspector-views:html
        (:p (html-inspector-views:esc empty)))))

(html-inspector-views:defview pi-simulation-plan-overview
    (plan pi-simulation-plan)
  (html-inspector-views:html-view
      :title "Simulation Plan"
      :priority 1
    (html-inspector-views:html
      (:h3 (html-inspector-views:esc (title-of plan)))
      (:p (html-inspector-views:esc (summary-of plan)))
      (:table :class "inspector-table"
       (:tr (:td "Execution mode")
            (:td (:tt (html-inspector-views:esc
                       (princ-to-string (execution-mode-of plan))))))
       (:tr (:td "Dry run") (:td (:tt (if (dry-run-p plan) "true" "false"))))
       (:tr (:td "HyperDoc SHOP3 result")
            (:td (:tt (if (typep plan 'hyperdoc/shop3:hyperdoc-htn-plan-result)
                          "true"
                          "false"))))
       (:tr (:td "SHOP3 checklist steps")
            (:td (:tt (html-inspector-views:esc
                       (princ-to-string
                        (length (hyperdoc/shop3:hyperdoc-plan-checklist
                                 (pi-simulation-shop3-plan-result plan)))))))))
      (:h4 "Fidelity levels")
      (%render-object-list (levels-of plan))
      (:h4 "Next actions")
      (%render-object-list (pi-simulation-next-actions :plan plan))
      (:h4 "Tasks")
      (%render-object-list (tasks-of plan))
      (:h4 "Boundary")
      (:p "This subsystem constructs inspectable objects only. It does not contact the Pi, run nixos-rebuild, boot a VM, create secrets, or write DMX."))))

(html-inspector-views:defview pi-simulation-task-overview
    (task pi-simulation-plan-task)
  (html-inspector-views:html-view
      :title "Simulation Task"
      :priority 1
    (html-inspector-views:html
      (:h3 (html-inspector-views:esc (title-of task)))
      (:p (html-inspector-views:esc (summary-of task)))
      (:table :class "inspector-table"
       (:tr (:td "Task id") (:td (:tt (html-inspector-views:esc (id-of task)))))
       (:tr (:td "Fidelity level")
            (:td (:tt (html-inspector-views:esc
                       (princ-to-string (level-of task))))))
       (:tr (:td "Status")
            (:td (:tt (html-inspector-views:esc
                       (princ-to-string (status-of task))))))
       (:tr (:td "SCXML state")
            (:td (:tt (html-inspector-views:esc (state-id-of task))))))
      (:h4 "Preconditions")
      (%render-string-list (preconditions-of task))
      (:h4 "Effects")
      (%render-string-list (effects-of task))
      (:h4 "Evidence")
      (%render-string-list (evidence-of task))
      (:h4 "Command specs")
      (%render-object-list (command-specs-of task)))))

(html-inspector-views:defview pi-simulation-command-overview
    (spec pi-simulation-command-spec)
  (html-inspector-views:html-view
      :title "Command Spec"
      :priority 1
    (html-inspector-views:html
      (:h3 (html-inspector-views:esc (title-of spec)))
      (:p (html-inspector-views:esc (summary-of spec)))
      (:table :class "inspector-table"
       (:tr (:td "Task") (:td (:tt (html-inspector-views:esc (task-id-of spec)))))
       (:tr (:td "Level")
            (:td (:tt (html-inspector-views:esc
                       (princ-to-string (level-of spec))))))
       (:tr (:td "Executed") (:td (:tt (if (executed-p spec) "true" "false"))))
       (:tr (:td "Mutates") (:td (:tt (if (mutates-p spec) "true" "false")))))
      (:h4 "Command text")
      (:pre (:code (html-inspector-views:esc (command-text-of spec))))
      (:h4 "Safety boundary")
      (:p (html-inspector-views:esc (safety-boundary-of spec))))))

(html-inspector-views:defview pi-simulation-session-overview
    (session pi-simulation-session)
  (html-inspector-views:html-view
      :title "Session"
      :priority 1
    (html-inspector-views:html
      (:h3 (html-inspector-views:esc (title-of session)))
      (:p (html-inspector-views:esc (summary-of session)))
      (:h4 "Plan")
      (:p (html-inspector-views:object-ref (plan-of session)))
      (:h4 "Boot status")
      (:table :class "inspector-table"
       (:tr (:td "Status")
            (:td (:tt (html-inspector-views:esc
                       (princ-to-string (status-of (boot-status-of session)))))))
       (:tr (:td "Reason")
            (:td (html-inspector-views:esc
                  (reason-of (boot-status-of session))))))
      (:h4 "Next actions")
      (%render-object-list (next-actions-of session)))))
