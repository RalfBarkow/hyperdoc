;;;; Smoke tests for Dock presentation model and pane-state snapshots
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-DOCK-PRESENTATION-SMOKE-TESTS" :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun dock-evidence-path-exists-p (evidence)
  (let ((relative-path (hyperdoc::relative-path-of evidence)))
    (and relative-path
         (probe-file
          (asdf:system-relative-pathname :hyperdoc relative-path)))))

(defun run-dock-presentation-smoke-tests ()
  (let* ((model (hyperdoc::dock-presentation-model))
         (states (hyperdoc::states-of model))
         (transitions (hyperdoc::transitions-of model))
         (claims (hyperdoc::claims-of model))
         (state-titles (mapcar #'hyperdoc::title-of states))
         (claim-titles (mapcar #'hyperdoc::title-of claims))
         (provider-claim
          (find "Provider-specific workflows stay in the pane body"
                claims
                :key #'hyperdoc::title-of
                :test #'string=))
         (mobile-route-claim
          (find "Mobile Dock uses route-first two-tap flow"
                claims
                :key #'hyperdoc::title-of
                :test #'string=))
         (snapshot
          (hyperdoc::make-dom-connect-pane-state-snapshot-from-json
           '(:paneId "pane-1"
             :activeTab "Main page"
             :contextViewTitle "Main page"
             :providerKind "dom-v1"
             :available t
             :enabled t
             :phase "choose-target"
             :helpOpen t
             :presentationState "active"
             :presentationReason "choose-target"
             :introducedCapability "connect"
             :presentationScope "browser-session"
             :coachmarkVisible t
             :selectedSourceLabel "Text pages"
             :selectedSourcePane t
             :pendingRequestId "assoc-123"
             :compactCapabilities ("Connect" "Annotation" "Guide")
             :coachmarkCapabilities ("Touch-Fahrplan")
             :providerHandoffs ("Touch-Fahrplan")))))
    (assert-true (typep model 'hyperdoc::dock-presentation-model)
                 "Dock presentation model entrypoint must materialize an inspectable model object")
    (dolist (title '("latent" "introduction" "active" "degraded" "rediscovery"
                     "idle" "source-latched" "destination-candidate"
                     "confirming" "completed"))
      (assert-true (member title state-titles :test #'string=)
                   (format nil "Dock model must include the ~A state" title)))
    (dolist (state states)
      (assert-true (not (member "Inspect"
                                (hyperdoc::capabilities-of state)
                                :test #'string=))
                   (format nil "Dock state ~A should not enumerate Inspect as a Dock capability"
                           (hyperdoc::title-of state))))
    (assert-equal 13
                  (length transitions)
                  "Dock presentation model should expose desktop coachmark transitions plus mobile route-strip transitions")
    (assert-true (member "Degrade chrome, not capability"
                         claim-titles
                         :test #'string=)
                 "Dock model should keep the core degrade-chrome claim inspectable")
    (assert-true provider-claim
                 "Dock model should keep the provider handoff claim inspectable")
    (assert-true (find "Touch-Fahrplan body workflow"
                       (hyperdoc::evidence-of provider-claim)
                       :key #'hyperdoc::title-of
                       :test #'string=)
                 "Provider claim should include Touch-Fahrplan evidence")
    (assert-true (find "DMX body handoff"
                       (hyperdoc::evidence-of provider-claim)
                       :key #'hyperdoc::title-of
                       :test #'string=)
                 "Provider claim should include DMX evidence")
    (assert-true mobile-route-claim
                 "Dock model should keep the mobile route-strip claim inspectable")
    (assert-true (find "Dock coachmark runtime state"
                       (hyperdoc::evidence-of mobile-route-claim)
                       :key #'hyperdoc::title-of
                       :test #'string=)
                 "Mobile route-strip claim should include JS runtime evidence")
    (dolist (claim claims)
      (assert-true (plusp (length (hyperdoc::evidence-of claim)))
                   (format nil "Dock claim ~A should point to implementation evidence"
                           (hyperdoc::title-of claim)))
      (dolist (evidence (hyperdoc::evidence-of claim))
        (assert-true (dock-evidence-path-exists-p evidence)
                     (format nil "Evidence path should exist for ~A"
                             (hyperdoc::title-of evidence)))))
    (assert-equal "active"
                  (hyperdoc::presentation-state-of snapshot)
                  "Pane snapshot should parse the current Dock presentation state")
    (assert-equal "choose-target"
                  (hyperdoc::presentation-reason-of snapshot)
                  "Pane snapshot should preserve the Dock presentation reason")
    (assert-equal "connect"
                  (hyperdoc::introduced-capability-of snapshot)
                  "Pane snapshot should expose which capability currently owns Dock presentation")
    (assert-equal "browser-session"
                  (hyperdoc::presentation-scope-of snapshot)
                  "Pane snapshot should expose the current Dock presentation memory scope")
    (assert-true (hyperdoc::coachmark-visible-p-of snapshot)
                 "Pane snapshot should preserve whether the expanded coachmark is visible")
    (assert-equal '("Connect" "Annotation" "Guide")
                  (hyperdoc::compact-capabilities-of snapshot)
                  "Pane snapshot should preserve compact capability access after degradation")
    (assert-equal '("Touch-Fahrplan")
                  (hyperdoc::coachmark-capabilities-of snapshot)
                  "Pane snapshot should expose the currently expanded coachmark capabilities")
    (assert-equal '("Touch-Fahrplan")
                  (hyperdoc::provider-handoffs-of snapshot)
                  "Pane snapshot should preserve provider handoff buttons separately from compact Dock identity"))
  (format t "~&Dock presentation smoke tests passed.~%")
  t)
