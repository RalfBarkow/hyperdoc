;;;; Lightweight inspector views for the Kioskbeerli sops-nix secrets objects.

(in-package :kioskbeerli/sops-nix-secrets)

(defmethod html-inspector-views:text-representation
    ((plan sops-nix-secrets-plan))
  (format nil "~A (~D tasks, ~A)"
          (title-of plan)
          (length (tasks-of plan))
          (execution-mode-of plan)))

(defmethod html-inspector-views:text-representation
    ((task sops-nix-secrets-plan-task))
  (format nil "~A: ~A" (id-of task) (status-of task)))

(defmethod html-inspector-views:text-representation
    ((session sops-nix-secrets-session))
  (format nil "~A (~D next actions)"
          (title-of session)
          (length (next-actions-of session))))

(defmethod html-inspector-views:text-representation
    ((spec sops-nix-secrets-command-spec))
  (format nil "~A: ~A" (id-of spec) (execution-mode-of spec)))

(defmethod html-inspector-views:text-representation
    ((topic sops-nix-secrets-topic))
  (format nil "~A: ~A" (category-of topic) (title-of topic)))

(defmethod html-inspector-views:text-representation
    ((bundle sops-nix-secrets-topic-bundle))
  (format nil "~A" (title-of bundle)))

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

(html-inspector-views:defview sops-nix-secrets-plan-overview
    (plan sops-nix-secrets-plan)
  (html-inspector-views:html-view
      :title "Plan"
      :priority 1
    (html-inspector-views:html
      (:h3 (html-inspector-views:esc (title-of plan)))
      (:p (html-inspector-views:esc (summary-of plan)))
      (:table :class "inspector-table"
       (:tr (:td "Execution mode")
            (:td (:tt (html-inspector-views:esc
                       (princ-to-string (execution-mode-of plan))))))
       (:tr (:td "Dry run")
            (:td (:tt (if (dry-run-p plan) "true" "false"))))
       (:tr (:td "Guards")
            (:td (:tt (html-inspector-views:esc
                       (princ-to-string (length (guards-of plan))))))))
      (:h4 "Next actions")
      (%render-object-list (sops-nix-secrets-next-actions :plan plan))
      (:h4 "Tasks")
      (%render-object-list (tasks-of plan))
      (:h4 "Boundary")
      (:p "This subsystem constructs inspectable objects only. It does not ssh, sudo, run sops, run nixos-rebuild, write DMX, or mutate the Pi."))))

(html-inspector-views:defview sops-nix-secrets-task-overview
    (task sops-nix-secrets-plan-task)
  (html-inspector-views:html-view
      :title "Task"
      :priority 1
    (html-inspector-views:html
      (:h3 (html-inspector-views:esc (title-of task)))
      (:p (html-inspector-views:esc (summary-of task)))
      (:table :class "inspector-table"
       (:tr (:td "Task id") (:td (:tt (html-inspector-views:esc (id-of task)))))
       (:tr (:td "Status")
            (:td (:tt (html-inspector-views:esc
                       (princ-to-string (status-of task))))))
       (:tr (:td "SCXML event")
            (:td (:tt (html-inspector-views:esc (scxml-event-of task)))))
       (:tr (:td "SCXML state")
            (:td (:tt (html-inspector-views:esc (state-id-of task))))))
      (:h4 "Dependencies")
      (%render-string-list (dependencies-of task))
      (:h4 "Preconditions")
      (%render-string-list (preconditions-of task))
      (:h4 "Effects")
      (%render-string-list (effects-of task))
      (:h4 "Evidence")
      (%render-string-list (evidence-of task))
      (:h4 "Command specs")
      (%render-object-list (command-specs-of task)))))

(html-inspector-views:defview sops-nix-secrets-command-overview
    (spec sops-nix-secrets-command-spec)
  (html-inspector-views:html-view
      :title "Command Spec"
      :priority 1
    (html-inspector-views:html
      (:h3 (html-inspector-views:esc (title-of spec)))
      (:p (html-inspector-views:esc (summary-of spec)))
      (:table :class "inspector-table"
       (:tr (:td "Task") (:td (:tt (html-inspector-views:esc (task-id-of spec)))))
       (:tr (:td "Execution mode")
            (:td (:tt (html-inspector-views:esc
                       (princ-to-string (execution-mode-of spec))))))
       (:tr (:td "Executed")
            (:td (:tt (if (executed-p spec) "true" "false"))))
       (:tr (:td "Mutates")
            (:td (:tt (if (mutates-p spec) "true" "false")))))
      (:h4 "Command text")
      (:pre (:code (html-inspector-views:esc
                    (or (command-text-of spec) "No runnable command."))))
      (:h4 "Safety boundary")
      (:p (html-inspector-views:esc (safety-boundary-of spec))))))

(html-inspector-views:defview sops-nix-secrets-topic-bundle-overview
    (bundle sops-nix-secrets-topic-bundle)
  (html-inspector-views:html-view
      :title "Topics"
      :priority 1
    (html-inspector-views:html
      (:h3 (html-inspector-views:esc (title-of bundle)))
      (:p (html-inspector-views:esc (summary-of bundle)))
      (:h4 "Task topics")
      (%render-object-list (tasks-of bundle))
      (:h4 "Concept topics")
      (%render-object-list (concepts-of bundle))
      (:h4 "Reference topics")
      (%render-object-list (references-of bundle))
      (:h4 "Guard topics")
      (%render-object-list (guards-of bundle))
      (:h4 "Failure topics")
      (%render-object-list (failures-of bundle))
      (:h4 "Recovery topics")
      (%render-object-list (recoveries-of bundle)))))
