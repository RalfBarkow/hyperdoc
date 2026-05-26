;;;; Smoke tests for the Kioskbeerli Pi simulation planning subsystem.

(in-package :kioskbeerli/pi-simulation/tests)

(defun assert-true (condition message)
  (unless condition
    (error "Pi simulation smoke test failed: ~A" message))
  condition)

(defun assert-false (condition message)
  (when condition
    (error "Pi simulation smoke test failed: ~A" message))
  t)

(defun assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "Pi simulation smoke test failed: ~A -- expected ~S, got ~S"
           message
           expected
           actual))
  actual)

(defun assert-contains (needle haystack message)
  (assert-true (and haystack (find needle haystack :test #'equal))
               (format nil "~A -- missing ~S" message needle)))

(defun collect-plan-strings (plan)
  (let ((strings nil))
    (labels ((collect (value)
               (cond
                 ((stringp value) (push value strings))
                 ((symbolp value) (push (symbol-name value) strings))
                 ((listp value) (mapc #'collect value))
                 ((typep value 'pi-simulation-plan)
                  (mapc #'collect
                        (list (id-of value)
                              (title-of value)
                              (summary-of value)
                              (execution-mode-of value)
                              (levels-of value)
                              (tasks-of value)
                              (command-specs-of value))))
                 ((typep value 'pi-simulation-fidelity-level)
                  (mapc #'collect
                        (list (id-of value)
                              (title-of value)
                              (summary-of value)
                              (status-of value))))
                 ((typep value 'pi-simulation-plan-task)
                  (mapc #'collect
                        (list (id-of value)
                              (title-of value)
                              (summary-of value)
                              (dependencies-of value)
                              (preconditions-of value)
                              (effects-of value)
                              (status-of value)
                              (evidence-of value)
                              (state-id-of value)
                              (scxml-event-of value)
                              (command-specs-of value))))
                 ((typep value 'pi-simulation-command-spec)
                  (mapc #'collect
                        (list (id-of value)
                              (title-of value)
                              (summary-of value)
                              (task-id-of value)
                              (command-text-of value)
                              (argv-of value)
                              (safety-boundary-of value)))))))
      (collect plan))
    strings))

(defun run-asdf-load-smoke-test ()
  (assert-true (asdf:find-system :kioskbeerli/pi-simulation nil)
               "ASDF must know :KIOSKBEERLI/PI-SIMULATION")
  (asdf:load-system :kioskbeerli/pi-simulation)
  (assert-true (find-package :kioskbeerli/pi-simulation)
               "Package :KIOSKBEERLI/PI-SIMULATION must exist"))

(defun run-fidelity-level-smoke-test ()
  (let* ((plan (make-pi-simulation-plan))
         (levels (levels-of plan)))
    (assert-equal '(0 1 2 3)
                  (mapcar #'level-of levels)
                  "Plan must expose fidelity levels 0-3")
    (assert-equal :plan-only
                  (execution-mode-of plan)
                  "Default execution mode must be plan-only")
    (assert-true (dry-run-p plan)
                 "Plan must be dry-run by default")))

(defun run-command-spec-smoke-test ()
  (let ((specs (pi-simulation-command-specs)))
    (assert-true specs
                 "Simulation command specs must exist")
    (dolist (spec specs)
      (assert-equal :manual-only
                    (execution-mode-of spec)
                    "Command specs must be manual-only")
      (assert-false (executed-p spec)
                    "Command specs must not execute in smoke tests")
      (assert-false (mutates-p spec)
                    "Simulation command specs must be non-mutating"))))

(defun run-scxml-smoke-test ()
  (let* ((path (pi-simulation-scxml-pathname))
         (chart (pi-simulation-scxml-chart))
         (state-ids (pi-simulation-scxml-state-ids chart)))
    (assert-true (probe-file path)
                 "SCXML file must exist")
    (assert-true (typep chart 'hyperdoc/scxml:scxml-chart)
                 "SCXML file must parse")
    (dolist (state '("plan-created"
                     "den-baseline-loaded"
                     "sim-flake-generated"
                     "eval-planned"
                     "eval-passed"
                     "vm-build-planned"
                     "vm-built"
                     "boot-backend-detected"
                     "vm-booted"
                     "probes-passed"
                     "complete"))
      (assert-contains state state-ids
                       "SCXML chart must include required state"))
    (dolist (state (pi-simulation-blocked-state-ids))
      (assert-contains state state-ids
                       "SCXML chart must include required blocked state"))))

(defun run-boot-skip-smoke-test ()
  (let ((status (pi-simulation-vm-boot-status)))
    (assert-equal :skipped
                  (status-of status)
                  "VM boot must be skipped by default")
    (assert-false (backend-of status)
                  "Default smoke path must not configure a backend")))

(defun run-no-pi-contact-smoke-test ()
  (let ((strings (collect-plan-strings (make-pi-simulation-plan))))
    (dolist (forbidden '("guest@192.168.178.34"
                         "ssh "
                         "sudo"
                         "nixos-rebuild"
                         "sops "
                         "dmx.ralfbarkow.ch"
                         "drakma"))
      (assert-false
       (some (lambda (string)
               (search forbidden string :test #'char-equal))
             strings)
       (format nil "Plan fixtures must not contain forbidden execution/contact marker ~S"
               forbidden)))))

(defun run-task-state-link-smoke-test ()
  (let ((links (pi-simulation-task-state-links)))
    (assert-equal (pi-simulation-plan-task-ids)
                  (mapcar #'task-id-of links)
                  "Every task must have a state link")
    (dolist (link links)
      (assert-true (scxml-event-of link)
                   "Every task link must have an event")
      (assert-true (scxml-state-of link)
                   "Every task link must have a state"))))

(defun run-session-smoke-test ()
  (let ((session (make-pi-simulation-session)))
    (assert-true (typep session 'pi-simulation-session)
                 "Session constructor must return a session")
    (assert-true (plan-of session)
                 "Session must expose its plan")
    (assert-true (chart-of session)
                 "Session must expose its SCXML chart")
    (assert-true (topic-bundle-of session)
                 "Session must expose its topic bundle")
    (assert-equal :skipped
                  (status-of (boot-status-of session))
                  "Session boot status must be skipped by default")))

(defun run-pi-simulation-smoke-tests ()
  (run-asdf-load-smoke-test)
  (run-fidelity-level-smoke-test)
  (run-command-spec-smoke-test)
  (run-scxml-smoke-test)
  (run-boot-skip-smoke-test)
  (run-no-pi-contact-smoke-test)
  (run-task-state-link-smoke-test)
  (run-session-smoke-test)
  (format t "~&Kioskbeerli Pi simulation smoke tests passed.~%")
  t)
