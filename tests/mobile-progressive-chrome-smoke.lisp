;;;; Smoke tests for mobile progressive chrome artifacts.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-MOBILE-PROGRESSIVE-CHROME-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun mobile-progressive-chrome-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun mobile-progressive-chrome-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun mobile-progressive-chrome-state-titles ()
  (mapcar #'hyperdoc::title-of
          (hyperdoc::states-of (hyperdoc::dock-presentation-model))))

(defun run-mobile-progressive-chrome-asdf-system-smoke-test ()
  (let ((system (asdf:find-system :hyperdoc/mobile-progressive-chrome)))
    (mobile-progressive-chrome-assert-true
     system
     "ASDF must resolve :hyperdoc/mobile-progressive-chrome")
    (asdf:load-system :hyperdoc/mobile-progressive-chrome)
    (let ((slice (hyperdoc:mobile-progressive-chrome-system-slice)))
      (mobile-progressive-chrome-assert-equal
       "hyperdoc/mobile-progressive-chrome"
       (hyperdoc::mobile-progressive-chrome-system-name-of slice)
       "Slice object must report the ASDF system name")
      (mobile-progressive-chrome-assert-equal
       "Mobile progressive chrome in HyperDoc"
       (hyperdoc::mobile-progressive-chrome-page-title-of slice)
       "Slice object must report the central page title")
      (dolist (pathname
               (list (hyperdoc::mobile-progressive-chrome-page-pathname-of slice)
                     (hyperdoc::mobile-progressive-chrome-slice-scxml-pathname-of
                      slice)
                     (hyperdoc::mobile-progressive-chrome-playwright-spec-pathname-of
                      slice)))
        (mobile-progressive-chrome-assert-true
         (uiop:file-exists-p pathname)
         (format nil "Slice pathname must exist: ~A" pathname)))
      (mobile-progressive-chrome-assert-true
       (typep (hyperdoc::mobile-progressive-chrome-slice-plan-of slice)
              'hyperdoc::mobile-progressive-chrome-plan)
       "Slice object must expose the plan object")
      (mobile-progressive-chrome-assert-true
       (typep (hyperdoc::mobile-progressive-chrome-slice-state-model-of slice)
              'hyperdoc::dock-presentation-model)
       "Slice object must expose the Dock state model")
      (mobile-progressive-chrome-assert-true
       (typep (hyperdoc:mobile-progressive-chrome-page)
              'hyperdoc::html-page)
       "Slice helper must find the central HTML page")
      (dolist (title '("Mobile progressive chrome ASDF system"
                       "Mobile progressive chrome page"
                       "Mobile progressive chrome boundary layout claim"))
        (mobile-progressive-chrome-assert-true
         (hyperbook:find-page hyperdoc::*topics* title :signal-error? t)
         (format nil "Topic cluster must include ~A" title))))))

(defun run-mobile-progressive-chrome-state-model-smoke-test ()
  (let* ((model (hyperdoc::dock-presentation-model))
         (titles (mobile-progressive-chrome-state-titles))
         (claims (mapcar #'hyperdoc::title-of (hyperdoc::claims-of model)))
         (snapshot
          (hyperdoc::make-dom-connect-pane-state-snapshot-from-json
           '(:paneId "pane-mobile"
             :activeTab "Content"
             :phase "choose-source"
             :presentationState "active"
             :capabilitiesLayerState "capabilities-open"
             :routeCaptureActive t
             :inspectorTabsLayerState "tabs-collapsed"
             :bodyTapDefaultAction "route-laying"
             :routeCaptureStartedBy "CONNECT_CHOSEN"))))
    (dolist (title '("capabilities-collapsed"
                     "capabilities-open"
                     "route-introduction"
                     "source-latched"
                     "route-cancelled"
                     "tabs-collapsed"
                     "tabs-open"
                     "tab-selected"))
      (mobile-progressive-chrome-assert-true
       (member title titles :test #'string=)
       (format nil "Dock model must expose layered state ~A" title)))
    (mobile-progressive-chrome-assert-true
     (member "Mobile Dock gates route capture behind explicit Connect"
             claims
             :test #'string=)
     "Dock model must expose the explicit Connect capture claim")
    (mobile-progressive-chrome-assert-true
     (member "Mobile inspector tabs collapse without losing active tab semantics"
             claims
             :test #'string=)
     "Dock model must expose the inspector-tabs layer claim")
    (mobile-progressive-chrome-assert-equal
     "capabilities-open"
     (hyperdoc::capabilities-layer-state-of snapshot)
     "Pane snapshot must retain capabilities layer state")
    (mobile-progressive-chrome-assert-true
     (hyperdoc::route-capture-active-p-of snapshot)
     "Pane snapshot must retain route capture activity")
    (mobile-progressive-chrome-assert-equal
     "tabs-collapsed"
     (hyperdoc::inspector-tabs-layer-state-of snapshot)
     "Pane snapshot must retain inspector tabs layer state")
    (mobile-progressive-chrome-assert-equal
     "CONNECT_CHOSEN"
     (hyperdoc::route-capture-started-by-of snapshot)
     "Pane snapshot must retain route capture transition cause")))

(defun run-mobile-progressive-chrome-scxml-smoke-test ()
  (let* ((artifact (hyperdoc::mobile-progressive-chrome-scxml-artifact))
         (source (hyperdoc::mobile-progressive-chrome-scxml-source))
         (chart (hyperdoc/scxml:parse-scxml-file
                 (hyperdoc::mobile-progressive-chrome-scxml-pathname)))
         (state-ids (mapcar #'hyperdoc/scxml:scxml-state-id-of
                            (hyperdoc/scxml:scxml-chart-states-of chart))))
    (mobile-progressive-chrome-assert-equal
     "Mobile progressive chrome SCXML"
     (hyperdoc::title-of artifact)
     "SCXML artifact must be inspectable")
    (dolist (needle '("CAPABILITIES_TOGGLE"
                      "CONNECT_CHOSEN"
                      "STATION_TAP"
                      "LINK_CLICK"
                      "INSPECTOR_TABS_TOGGLE"
                      "route-capture-active?"))
      (mobile-progressive-chrome-assert-true
       (search needle source :test #'char=)
       (format nil "SCXML source must mention ~A" needle)))
    (dolist (state-id '("capabilities-collapsed"
                        "capabilities-open"
                        "route-introduction"
                        "route-active-source-latched"
                        "tabs-collapsed"
                        "tabs-open"))
      (mobile-progressive-chrome-assert-true
       (member state-id state-ids :test #'string=)
       (format nil "SCXML parse must include state ~A" state-id)))))

(defun run-mobile-progressive-chrome-plan-smoke-test ()
  (let* ((plan (hyperdoc::mobile-progressive-chrome-plan))
         (tasks (hyperdoc::mobile-progressive-chrome-plan-tasks-of plan))
         (ids (mapcar #'hyperdoc::id-of tasks))
         (statuses (mapcar #'hyperdoc::mobile-progressive-chrome-plan-task-status-of
                           tasks)))
    (dolist (id '("survey-current-dock-runtime"
                  "add-capabilities-layer-state"
                  "add-tabs-layer-state"
                  "gate-route-capture-behind-explicit-connect"
                  "preserve-link-default-action-when-route-inactive"
                  "add-scxml-behavior-model"
                  "add-mobile-regression-tests"
                  "boundary-mounted-toggle-layout"
                  "validate"))
      (mobile-progressive-chrome-assert-true
       (member id ids :test #'string=)
       (format nil "Plan must include task ~A" id)))
    (dolist (status statuses)
      (mobile-progressive-chrome-assert-true
       (member status '("pending" "active" "done" "blocked") :test #'string=)
       (format nil "Task status must be a known plan status: ~A" status)))
    (mobile-progressive-chrome-assert-true
     (every #'hyperdoc::mobile-progressive-chrome-plan-task-implementation-evidence-path-of
            tasks)
     "Each plan task must expose implementation evidence")
    (mobile-progressive-chrome-assert-true
     (every #'hyperdoc::mobile-progressive-chrome-plan-task-validation-evidence-path-of
            tasks)
     "Each plan task must expose validation evidence")))

(defun run-mobile-progressive-chrome-doc-smoke-test ()
  (let ((page (hyperbook:find-page hyperdoc::*hyperdoc*
                                   "Mobile progressive chrome in HyperDoc"
                                   :signal-error? t)))
    (mobile-progressive-chrome-assert-true
     (typep page 'hyperdoc::html-page)
     "Mobile progressive chrome page must materialize as an HTML page")
    (let ((text (plump:text (hyperbook:dom-of page))))
      (dolist (needle '("Capabilities closed"
                        "Route capture"
                        "Ordinary links"
                        "Boundary-mounted handles"
                        "ASDF feature slice"
                        "Mobile progressive chrome SCXML"
                        "mobile-progressive-chrome-plan"))
        (mobile-progressive-chrome-assert-true
         (search needle text :test #'char=)
         (format nil "Documentation page must contain ~S" needle))))))

(defun run-mobile-progressive-chrome-smoke-tests ()
  (run-mobile-progressive-chrome-asdf-system-smoke-test)
  (run-mobile-progressive-chrome-state-model-smoke-test)
  (run-mobile-progressive-chrome-scxml-smoke-test)
  (run-mobile-progressive-chrome-plan-smoke-test)
  (run-mobile-progressive-chrome-doc-smoke-test)
  (format t "~&Mobile progressive chrome smoke tests passed.~%")
  t)
