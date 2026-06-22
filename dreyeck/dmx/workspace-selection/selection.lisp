;;;; Result construction for the live SHOP3 workspace-selection run.

(in-package #:dreyeck.dmx.workspace-selection)

(defparameter *shop3-find-plans-call-count* 0
  "Number of real SHOP3:FIND-PLANS calls issued by this selection module.")

(defun %find-plans-symbol ()
  (or (find-symbol "FIND-PLANS" "SHOP3")
      (error "The SHOP3 package does not expose FIND-PLANS.")))

(defun %live-shop3-find-plans (problem)
  "Run the real SHOP3 planner; no heuristic result is available as a fallback."
  (let ((find-plans (%find-plans-symbol)))
    (unless (fboundp find-plans)
      (error "SHOP3 planner entrypoint ~S is not fbound." find-plans))
    (incf *shop3-find-plans-call-count*)
    (shop3:find-plans problem
                      :which :first
                      :verbose 0
                      :plan-tree t)))

(defun %plan->safe-sexp (plan)
  (handler-case
      (shop3:shorter-plan plan)
    (error () plan)))

(defun dmx-sqlite-workspace-plan-action-p (plan action)
  "Return true when PLAN contains ACTION, compared by SHOP3 operator name."
  (let ((expected (string-upcase (symbol-name action))))
    (labels ((walk (form)
               (cond
                 ((atom form) nil)
                 ((and (symbolp (first form))
                       (string= expected (string-upcase (symbol-name (first form)))))
                  t)
                 (t (or (walk (first form))
                        (walk (rest form)))))))
      (walk plan))))

(defun dmx-sqlite-next-task-plan-action-p (plan action)
  "Return true when PLAN contains the specified next-task selection ACTION."
  (dmx-sqlite-workspace-plan-action-p plan action))

(defun %selected-workspace (plan)
  (cond
    ((dmx-sqlite-workspace-plan-action-p
      plan '!select-hyperdoc-dreyeck-owner)
     :hyperdoc-dreyeck-owner)
    ((dmx-sqlite-workspace-plan-action-p
      plan '!select-hauptsache-local-owner)
     :hauptsache-local-owner)
    ((dmx-sqlite-workspace-plan-action-p
      plan '!select-shared-dreyeck-source-tree)
     :shared-dreyeck-source-tree)
    ((dmx-sqlite-workspace-plan-action-p
      plan '!defer-for-more-evidence)
     :deferred-for-more-evidence)
    (t
     (error "Live SHOP3 returned a plan without a workspace-selection action: ~S"
            plan))))

(defun select-dmx-sqlite-workspace-with-shop3 ()
  "Use SHOP3:FIND-PLANS to select the sole valid DMX SQLite ASDF owner.

This function deliberately has no scoring or heuristic fallback.  A planner
load or planning failure is an error rather than an invented decision."
  (multiple-value-bind (raw-plans run-time plan-trees final-states)
      (%live-shop3-find-plans 'dreyeck-dmx-sqlite-workspace-selection-001)
    (unless raw-plans
      (error "SHOP3:FIND-PLANS found no DMX SQLite workspace-selection plan."))
    (let* ((plans (mapcar #'%plan->safe-sexp raw-plans))
           (selected-plan (first plans))
           (selected-workspace (%selected-workspace selected-plan)))
      (list :kind :shop3-dmx-sqlite-workspace-selection
            :planner :shop3
            :find-plans-symbol "SHOP3:FIND-PLANS"
            :planner-call :live
            :heuristic-fallback nil
            :live-planner-call-count *shop3-find-plans-call-count*
            :domain 'dreyeck-dmx-workspace-selection
            :problem 'dreyeck-dmx-sqlite-workspace-selection-001
            :facts *dmx-sqlite-workspace-selection-facts*
            :plans plans
            :raw-plans raw-plans
            :selected-plan selected-plan
            :selected-workspace selected-workspace
            :plan-trees plan-trees
            :final-states final-states
            :run-time run-time
            :next-actions
            '("Port the generic store only after explicit instruction."
              "Keep HyperDoc core ASDF systems unchanged."
              "Do not touch the isolated recorder prototype.")))))

(defun %selected-next-task (plan)
  (cond
    ((dmx-sqlite-next-task-plan-action-p plan '!select-property-journal-sync)
     :property-journal-sync)
    ((dmx-sqlite-next-task-plan-action-p plan '!select-build-graph-recorder-replay)
     :build-graph-recorder-replay)
    ((dmx-sqlite-next-task-plan-action-p plan '!select-fedwiki-artifact-materialization)
     :fedwiki-artifact-materialization)
    ((dmx-sqlite-next-task-plan-action-p plan '!defer-next-task-for-more-evidence)
     :deferred-for-more-evidence)
    (t
     (error "Live SHOP3 returned a plan without a next-task selection action: ~S"
            plan))))

(defun select-dmx-sqlite-next-task-with-shop3 ()
  "Use SHOP3:FIND-PLANS to select the next Dreyeck DMX SQLite task.

The result is a live planning record.  A missing planner or plan is an error;
this function never synthesizes a heuristic fallback."
  (multiple-value-bind (raw-plans run-time plan-trees final-states)
      (%live-shop3-find-plans 'dreyeck-dmx-sqlite-next-task-selection-001)
    (unless raw-plans
      (error "SHOP3:FIND-PLANS found no DMX SQLite next-task selection plan."))
    (let* ((plans (mapcar #'%plan->safe-sexp raw-plans))
           (selected-plan (first plans))
           (selected-task (%selected-next-task selected-plan)))
      (list :kind :shop3-dmx-sqlite-next-task-selection
            :planner :shop3
            :find-plans-symbol "SHOP3:FIND-PLANS"
            :planner-call :live
            :heuristic-fallback nil
            :live-planner-call-count *shop3-find-plans-call-count*
            :domain 'dreyeck-dmx-workspace-selection
            :problem 'dreyeck-dmx-sqlite-next-task-selection-001
            :facts *dmx-sqlite-next-task-selection-facts*
            :plans plans
            :raw-plans raw-plans
            :selected-plan selected-plan
            :selected-task selected-task
            :selected-repo :hyperdoc
            :selected-system :dreyeck/dmx/sqlite
            :plan-trees plan-trees
            :final-states final-states
            :run-time run-time
            :next-actions
            '("Implement generic property values under :dreyeck/dmx/sqlite."
              "Add generic query-run and journal read/value surfaces."
              "Add generic sync workflow read models before recorder replay.")))))
