;;;; Smoke tests proving that workspace selection uses the live SHOP3 planner.

(in-package #:dreyeck.dmx.workspace-selection/tests)

(defun assert-true (value message)
  (unless value
    (error "~A" message)))

(defun run-workspace-selection-smoke-tests ()
  (let ((find-plans (find-symbol "FIND-PLANS" "SHOP3")))
    (assert-true (find-package "SHOP3")
                 "SHOP3 must be loaded for workspace selection")
    (assert-true (and find-plans (fboundp find-plans))
                 "SHOP3:FIND-PLANS must be fbound"))
  (let ((*shop3-find-plans-call-count* 0))
    (let ((result (select-dmx-sqlite-workspace-with-shop3)))
      (assert-true (getf result :plans)
                   "Live SHOP3 selection must return at least one plan")
      (assert-true (string= "SHOP3:FIND-PLANS" (getf result :find-plans-symbol))
                   "Result must record the exact planner function")
      (assert-true (eq :live (getf result :planner-call))
                   "Result must be marked as a live planner call")
      (assert-true (not (getf result :heuristic-fallback))
                   "Selection must not use a heuristic fallback")
      (assert-true (plusp *shop3-find-plans-call-count*)
                   "Smoke test must observe a real SHOP3:FIND-PLANS call")
      (assert-true (eq :hyperdoc-dreyeck-owner
                       (getf result :selected-workspace))
                   "SHOP3 must select the HyperDoc Dreyeck ASDF owner")
      (assert-true
       (dmx-sqlite-workspace-plan-action-p
        (getf result :selected-plan)
        'dreyeck.dmx.workspace-selection::!select-hyperdoc-dreyeck-owner)
       "Selected SHOP3 plan must contain !SELECT-HYPERDOC-DREYECK-OWNER")))
  (format t "~&Dreyeck DMX SQLite workspace-selection smoke tests passed.~%")
  t)
