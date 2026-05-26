;;;; Topics and plan domain for Kioskbeerli Pi simulation.

(in-package :kioskbeerli/pi-simulation)

(defparameter *pi-simulation-fidelity-level-data*
  '((0 "level-0-asdf-plan-only"
     "Level 0: ASDF/plan-only simulation"
     "Construct inspectable Lisp plan, SCXML, topics, and command specs only.")
    (1 "level-1-nix-flake-eval"
     "Level 1: Nix flake evaluation simulation"
     "Evaluate flake and hostname expressions without contacting the Pi.")
    (2 "level-2-vm-derivation-build"
     "Level 2: VM derivation build simulation"
     "Build toplevel or VM derivations for the simulation target without booting by default.")
    (3 "level-3-optional-vm-boot-smoke"
     "Level 3: optional VM/MicroVM boot smoke"
     "Boot smoke is opt-in and skipped unless a Linux virtualization backend is configured.")))

(defparameter *pi-simulation-task-ids*
  '("create-plan"
    "load-den-baseline"
    "draft-sim-flake-shape"
    "plan-flake-evaluation"
    "record-eval-result"
    "plan-vm-derivation-build"
    "record-vm-build"
    "detect-boot-backend"
    "boot-vm-smoke"
    "run-runtime-probes"
    "record-simulation-result"))

(defparameter *pi-simulation-blocked-state-ids*
  '("blocked-no-linux-backend"
    "blocked-no-kvm"
    "blocked-cross-arch"
    "blocked-secret-fixture"
    "blocked-vm-build"
    "blocked-vm-boot"))

(defparameter *pi-simulation-task-data*
  '(("create-plan"
     "Create simulation plan"
     "Construct the ASDF/plan-only simulation object graph."
     0
     nil
     ("Kioskbeerli source tree is loadable")
     ("Inspectable simulation plan exists")
     :complete
     ("kioskbeerli/pi-simulation/")
     "plan-created"
     "PLAN_CREATED")
    ("load-den-baseline"
     "Load Den baseline"
     "Load the documented real Pi baseline without contacting the Pi."
     0
     ("create-plan")
     ("Den base-system milestone is documented")
     ("Simulation starts from runtime hostname myhostname and Den hostname kioskbeerli")
     :planned
     ("kioskbeerli/raspberry-pi-den-base-system.md")
     "den-baseline-loaded"
     "DEN_BASELINE_LOADED")
    ("draft-sim-flake-shape"
     "Draft simulation flake shape"
     "Plan a separate kioskbeerli-pi-sim NixOS configuration and check outputs."
     0
     ("load-den-baseline")
     ("Real target remains kioskbeerli-pi")
     ("Future flake exposes a separate simulation target and checks")
     :planned
     ("missing: documented nixosConfigurations.kioskbeerli-pi-sim design")
     "sim-flake-generated"
     "SIM_FLAKE_GENERATED")
    ("plan-flake-evaluation"
     "Plan flake evaluation"
     "Plan read-only Nix flake evaluations for real and simulated host shape."
     1
     ("draft-sim-flake-shape")
     ("Simulation flake shape is drafted")
     ("Nix evaluation commands are inspectable")
     :planned
     ("missing: nix flake show result")
     "eval-planned"
     "EVAL_PLANNED")
    ("record-eval-result"
     "Record evaluation result"
     "Record that the flake evaluation simulation passed."
     1
     ("plan-flake-evaluation")
     ("Flake evaluation has been run manually outside this subsystem")
     ("Evaluation result is recorded without Pi contact")
     :planned
     ("missing: eval-passed evidence")
     "eval-passed"
     "EVAL_PASSED")
    ("plan-vm-derivation-build"
     "Plan VM derivation build"
     "Plan local or remote derivation builds for the simulation target."
     2
     ("record-eval-result")
     ("Evaluation passed")
     ("Toplevel and VM build command specs are inspectable")
     :planned
     ("missing: vm derivation build plan")
     "vm-build-planned"
     "VM_BUILD_PLANNED")
    ("record-vm-build"
     "Record VM build"
     "Record successful simulation derivation build without booting it by default."
     2
     ("plan-vm-derivation-build")
     ("VM derivation build has been run manually")
     ("VM derivation exists as build evidence")
     :planned
     ("missing: vm-built evidence")
     "vm-built"
     "VM_BUILT")
    ("detect-boot-backend"
     "Detect boot backend"
     "Determine whether Linux virtualization or MicroVM backend support exists."
     3
     ("record-vm-build")
     ("VM derivation exists")
     ("Unsupported hosts skip boot cleanly")
     :planned
     ("missing: backend detection result")
     "boot-backend-detected"
     "BOOT_BACKEND_DETECTED")
    ("boot-vm-smoke"
     "Boot VM smoke"
     "Optionally boot the VM/MicroVM only when a backend is explicitly available."
     3
     ("detect-boot-backend")
     ("Linux virtualization backend is configured")
     ("VM booted for smoke probes")
     :skipped
     ("skipped: VM boot is not part of default make check")
     "vm-booted"
     "VM_BOOTED")
    ("run-runtime-probes"
     "Run runtime probes"
     "Run read-only probes against the simulated machine after an explicit boot."
     3
     ("boot-vm-smoke")
     ("VM booted")
     ("Runtime probes pass in simulation")
     :skipped
     ("skipped: probes require opt-in VM boot")
     "probes-passed"
     "PROBES_PASSED")
    ("record-simulation-result"
     "Record simulation result"
     "Record completed or skipped simulation evidence without mutating the real Pi."
     0
     ("run-runtime-probes")
     ("Simulation evidence is available")
     ("Simulation milestone is reconstructable")
     :planned
     ("missing: simulation result record")
     "complete"
     "SIMULATION_RECORDED")))

(defparameter *pi-simulation-topic-data*
  '(("simulation-target" "simulation target" :concept
     "Separate NixOS host target used to model Kioskbeerli without mutating the real Pi.")
    ("fidelity-level" "fidelity level" :concept
     "Simulation depth from ASDF-only planning through optional VM boot smoke.")
    ("real-target-boundary" "real target boundary" :guard
     "The real Pi target is never contacted by this subsystem.")
    ("vm-boot-boundary" "VM boot boundary" :guard
     "VM or MicroVM boot is opt-in and skipped by default.")
    ("nixosConfigurations.kioskbeerli-pi" "nixosConfigurations.kioskbeerli-pi" :reference
     "Real target flake output that remains the deployed Pi boundary.")
    ("nixosConfigurations.kioskbeerli-pi-sim" "nixosConfigurations.kioskbeerli-pi-sim" :reference
     "Future simulation target flake output.")
    ("checks-kioskbeerli-pi-sim-eval" "checks.<system>.kioskbeerli-pi-sim-eval" :reference
     "Future flake check for evaluation-only simulation.")
    ("checks-kioskbeerli-pi-sim-build" "checks.<system>.kioskbeerli-pi-sim-build" :reference
     "Future flake check for simulation derivation build.")
    ("blocked-no-linux-backend" "blocked-no-linux-backend" :failure
     "No Linux virtualization backend is configured.")
    ("blocked-no-kvm" "blocked-no-kvm" :failure
     "KVM is unavailable for an optional VM boot smoke.")
    ("blocked-cross-arch" "blocked-cross-arch" :failure
     "Host architecture cannot build or run the requested simulation without remote support.")
    ("blocked-secret-fixture" "blocked-secret-fixture" :failure
     "A simulation fixture would expose real or cleartext secret material.")
    ("blocked-vm-build" "blocked-vm-build" :failure
     "The VM derivation did not build.")
    ("blocked-vm-boot" "blocked-vm-boot" :failure
     "The optional VM/MicroVM did not boot cleanly.")))

(defun pi-simulation-fidelity-levels ()
  (mapcar
   (lambda (spec)
     (destructuring-bind (level id title summary) spec
       (make-instance 'pi-simulation-fidelity-level
                      :level level
                      :id id
                      :title title
                      :summary summary
                      :status (if (zerop level) :available :planned))))
   *pi-simulation-fidelity-level-data*))

(defun pi-simulation-plan-task-ids ()
  (copy-list *pi-simulation-task-ids*))

(defun pi-simulation-blocked-state-ids ()
  (copy-list *pi-simulation-blocked-state-ids*))

(defun %make-pi-simulation-task (spec)
  (destructuring-bind
      (id title summary level dependencies preconditions effects status evidence
          state-id event)
      spec
    (make-instance 'pi-simulation-plan-task
                   :id id
                   :title title
                   :summary summary
                   :level level
                   :dependencies dependencies
                   :preconditions preconditions
                   :effects effects
                   :status status
                   :evidence evidence
                   :state-id state-id
                   :scxml-event event
                   :command-specs (%command-specs-for-task id))))

(defun %pi-simulation-task->shop3-step (task)
  (list '!plan-pi-simulation-task
        (id-of task)
        (level-of task)
        (state-id-of task)))

(defun pi-simulation-shop3-plan-steps (&optional plan)
  "Return the HyperDoc SHOP3 checklist projection for PLAN.

The simulation keeps rich local task objects, but also projects those tasks to
SHOP3-style plan steps so HYPERDOC/SHOP3 checklist helpers can inspect the
simulation through the shared planning layer."
  (mapcar #'%pi-simulation-task->shop3-step
          (if plan
              (tasks-of plan)
              (mapcar #'%make-pi-simulation-task
                      *pi-simulation-task-data*))))

(defun make-pi-simulation-plan (&key (execution-mode :plan-only))
  "Return the inspectable Kioskbeerli Pi simulation plan.

The default and only supported execution mode is :PLAN-ONLY. This function does
not contact the Pi, run nixos-rebuild, boot a VM, create secrets, or write DMX."
  (unless (eq execution-mode :plan-only)
    (error "Kioskbeerli Pi simulation only supports :PLAN-ONLY, not ~S."
           execution-mode))
  (let* ((tasks (mapcar #'%make-pi-simulation-task
                        *pi-simulation-task-data*))
         (shop3-steps (mapcar #'%pi-simulation-task->shop3-step tasks)))
    (make-instance 'pi-simulation-plan
                   :id "kioskbeerli-pi-simulation-plan"
                   :title "Kioskbeerli Pi simulation plan"
                   :summary "Plan-first simulation model for the Kioskbeerli Pi NixOS state across ASDF, Nix evaluation, VM derivation build, and optional VM boot smoke fidelity levels."
                   :problem-name 'kioskbeerli-pi-simulation
                   :plans (list shop3-steps)
                   :raw-plans (list shop3-steps)
                   :plan-trees nil
                   :final-states nil
                   :time 0
                   :execution-mode execution-mode
                   :dry-run-p t
                   :levels (pi-simulation-fidelity-levels)
                   :tasks tasks
                   :command-specs (pi-simulation-command-specs))))

(defun pi-simulation-shop3-plan-result (&optional (plan (make-pi-simulation-plan)))
  "Return PLAN as a HyperDoc SHOP3 plan result.

PI-SIMULATION-PLAN subclasses HYPERDOC/SHOP3:HYPERDOC-HTN-PLAN-RESULT. This
adapter makes the relationship explicit at call sites that want the shared
SHOP3 planning protocol rather than the domain-specific simulation task graph."
  (unless (typep plan 'hyperdoc/shop3:hyperdoc-htn-plan-result)
    (error "Not a HyperDoc SHOP3 plan result: ~S" plan))
  plan)

(defun pi-simulation-lookup-plan-task
    (task-or-id &key (plan (make-pi-simulation-plan)))
  (if (typep task-or-id 'pi-simulation-plan-task)
      task-or-id
      (let ((task-id (normalize-pi-simulation-id task-or-id)))
        (find task-id (tasks-of plan) :key #'id-of :test #'string=))))

(defun %completed-task-p (task)
  (member (status-of task) '(:complete :passed :available) :test #'eq))

(defun %task-dependencies-satisfied-p (task plan)
  (every (lambda (dependency-id)
           (let ((dependency
                   (pi-simulation-lookup-plan-task dependency-id :plan plan)))
             (and dependency (%completed-task-p dependency))))
         (dependencies-of task)))

(defun pi-simulation-next-actions
    (&key (plan (make-pi-simulation-plan)))
  "Return currently available simulation actions without executing them."
  (remove-if-not
   (lambda (task)
     (and (not (%completed-task-p task))
          (%task-dependencies-satisfied-p task plan)))
   (tasks-of plan)))

(defun %make-topic (spec)
  (destructuring-bind (id title category summary) spec
    (make-instance 'pi-simulation-topic
                   :id id
                   :title title
                   :category category
                   :summary summary)))

(defun pi-simulation-topic-bundle ()
  (make-instance
   'pi-simulation-topic-bundle
   :id "kioskbeerli-pi-simulation-topic-bundle"
   :title "Kioskbeerli Pi simulation topic bundle"
   :summary "Inspectable concept, reference, guard, and failure topics for the plan-first Pi simulation milestone."
   :topics (mapcar #'%make-topic *pi-simulation-topic-data*)))

(defun make-pi-simulation-session
    (&key (plan (make-pi-simulation-plan)))
  (make-instance
   'pi-simulation-session
   :id "kioskbeerli-pi-simulation-session"
   :title "Kioskbeerli Pi simulation session"
   :summary "Inspectable plan-only session for simulating the Kioskbeerli Pi state without mutating the real target."
   :execution-mode (execution-mode-of plan)
   :plan plan
   :chart (pi-simulation-scxml-chart)
   :topic-bundle (pi-simulation-topic-bundle)
   :next-actions (pi-simulation-next-actions :plan plan)
   :boot-status (pi-simulation-vm-boot-status)))

(defun inspect-pi-simulation-plan (&optional (plan (make-pi-simulation-plan)))
  "Open PLAN in the CLOG inspector when available."
  (%clog-inspect plan))
