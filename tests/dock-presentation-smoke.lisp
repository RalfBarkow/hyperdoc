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
          (find "Mobile Dock gates route capture behind explicit Connect"
                claims
                :key #'hyperdoc::title-of
                :test #'string=))
         (mobile-tabs-claim
          (find "Mobile inspector tabs collapse without losing active tab semantics"
                claims
                :key #'hyperdoc::title-of
                :test #'string=))
         (mobile-boundary-claim
          (find "Mobile chrome toggles remain inside the pane boundary"
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
             :coachmarkVisible nil
             :capabilitiesLayerState "capabilities-open"
             :routeCaptureActive t
             :inspectorTabsLayerState "tabs-collapsed"
             :bodyTapDefaultAction "route-laying"
             :routeCaptureStartedBy "CONNECT_CHOSEN"
             :selectedSourceLabel "Text pages"
             :selectedSourcePane t
             :pendingRequestId "assoc-123"
             :compactCapabilities ("Connect" "Annotation" "Guide")
             :coachmarkCapabilities ()
             :providerHandoffs ("DMX")))))
    (assert-true (typep model 'hyperdoc::dock-presentation-model)
                 "Dock presentation model entrypoint must materialize an inspectable model object")
    (dolist (title '("latent" "introduction" "active" "degraded" "rediscovery"
                     "capabilities-collapsed" "capabilities-open"
                     "route-introduction" "source-latched"
                     "destination-candidate" "confirming" "completed"
                     "route-cancelled" "tabs-collapsed" "tabs-open"
                     "tab-selected"))
      (assert-true (member title state-titles :test #'string=)
                   (format nil "Dock model must include the ~A state" title)))
    (dolist (state states)
      (assert-true (not (member "Inspect"
                                (hyperdoc::capabilities-of state)
                                :test #'string=))
                   (format nil "Dock state ~A should not enumerate Inspect as a Dock capability"
                           (hyperdoc::title-of state))))
    (let ((introduction (find "introduction" states
                              :key #'hyperdoc::title-of :test #'string=))
          (active (find "active" states
                        :key #'hyperdoc::title-of :test #'string=))
          (rediscovery (find "rediscovery" states
                             :key #'hyperdoc::title-of :test #'string=)))
      (assert-true introduction "Dock model must materialize introduction")
      (assert-true active "Dock model must materialize active")
      (assert-true rediscovery "Dock model must materialize rediscovery")
      (assert-true
       (not (hyperdoc::dock-presentation-state-allows-large-coachmark-p
             introduction))
       "Introduction must not allow the large coachmark")
      (assert-true
       (not (hyperdoc::dock-presentation-state-allows-large-coachmark-p active))
       "Active must not allow the large coachmark")
      (assert-true
       (hyperdoc::dock-presentation-state-allows-large-coachmark-p rediscovery)
       "Rediscovery must be the only state that allows the large coachmark")
      (assert-true (search "in-flow"
                           (hyperdoc::compact-representation-of introduction))
                   "Introduction must describe its in-flow representation")
      (assert-true (search "in-flow"
                           (hyperdoc::compact-representation-of active))
                   "Active must describe its in-flow representation"))
    (assert-equal 20
                  (length transitions)
                  "Dock presentation model should expose desktop coachmark transitions plus mobile progressive chrome transitions")
    (assert-true (member "Degrade chrome, not capability"
                         claim-titles
                         :test #'string=)
                 "Dock model should keep the core degrade-chrome claim inspectable")
    (assert-true provider-claim
                 "Dock model should keep the provider handoff claim inspectable")
    (assert-true (find "DMX body handoff"
                       (hyperdoc::evidence-of provider-claim)
                       :key #'hyperdoc::title-of
                       :test #'string=)
                 "Provider claim should include DMX evidence")
    (assert-true mobile-route-claim
                 "Dock model should keep the mobile route-capture claim inspectable")
    (assert-true (find "Dock coachmark runtime state"
                       (hyperdoc::evidence-of mobile-route-claim)
                       :key #'hyperdoc::title-of
                       :test #'string=)
                 "Mobile route-capture claim should include JS runtime evidence")
    (assert-true mobile-tabs-claim
                 "Dock model should keep the mobile inspector-tabs claim inspectable")
    (assert-true mobile-boundary-claim
                 "Dock model should keep the mobile boundary-layout claim inspectable")
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
    (assert-true (not (hyperdoc::coachmark-visible-p-of snapshot))
                 "An active pane snapshot must not claim a visible large coachmark")
    (assert-equal "capabilities-open"
                  (hyperdoc::capabilities-layer-state-of snapshot)
                  "Pane snapshot should expose the capabilities layer state")
    (assert-true (hyperdoc::route-capture-active-p-of snapshot)
                 "Pane snapshot should expose route capture activity")
    (assert-equal "tabs-collapsed"
                  (hyperdoc::inspector-tabs-layer-state-of snapshot)
                  "Pane snapshot should expose the inspector tabs layer state")
    (assert-equal "route-laying"
                  (hyperdoc::body-tap-default-action-of snapshot)
                  "Pane snapshot should say when page-body taps are route-laying taps")
    (assert-equal "CONNECT_CHOSEN"
                  (hyperdoc::route-capture-started-by-of snapshot)
                  "Pane snapshot should preserve the transition that began route capture")
    (assert-equal '("Connect" "Annotation" "Guide")
                  (hyperdoc::compact-capabilities-of snapshot)
                  "Pane snapshot should preserve compact capability access after degradation")
    (assert-equal nil
                  (hyperdoc::coachmark-capabilities-of snapshot)
                  "An active pane snapshot must expose no coachmark-only capabilities")
    (assert-equal '("DMX")
                  (hyperdoc::provider-handoffs-of snapshot)
                  "Pane snapshot should preserve provider handoff buttons separately from compact Dock identity"))
  (format t "~&Dock presentation smoke tests passed.~%")
  t)
