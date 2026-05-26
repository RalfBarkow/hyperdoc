;;;; Non-executing Nix command specifications for Kioskbeerli Pi simulation.

(in-package :kioskbeerli/pi-simulation)

(defparameter *pi-simulation-command-spec-data*
  '(("nix-flake-show"
     "nix flake show"
     "Inspect flake outputs before evaluating or building the simulation target."
     "plan-flake-evaluation"
     1
     "nix flake show"
     ("nix" "flake" "show"))
    ("nix-eval-real-hostname"
     "Evaluate real target hostname"
     "Evaluate the current real target hostname without contacting the Pi."
     "plan-flake-evaluation"
     1
     "nix eval .#nixosConfigurations.kioskbeerli-pi.config.networking.hostName"
     ("nix" "eval" ".#nixosConfigurations.kioskbeerli-pi.config.networking.hostName"))
    ("nix-eval-den-hostname"
     "Evaluate Den hostname"
     "Evaluate the Den hostName field for the kioskbeerli-pi entity."
     "plan-flake-evaluation"
     1
     "nix eval --raw --expr '(import ./nix/den/kioskbeerli.nix).\"kioskbeerli-pi\".hostName'"
     ("nix" "eval" "--raw" "--expr" "(import ./nix/den/kioskbeerli.nix).\"kioskbeerli-pi\".hostName"))
    ("nix-build-sim-toplevel"
     "Build simulation toplevel"
     "Build the planned simulation target toplevel derivation."
     "plan-vm-derivation-build"
     2
     "nix build .#nixosConfigurations.kioskbeerli-pi-sim.config.system.build.toplevel"
     ("nix" "build" ".#nixosConfigurations.kioskbeerli-pi-sim.config.system.build.toplevel"))
    ("nix-build-sim-vm"
     "Build simulation VM"
     "Build the planned simulation VM derivation without booting it by default."
     "plan-vm-derivation-build"
     2
     "nix build .#nixosConfigurations.kioskbeerli-pi-sim.config.system.build.vm"
     ("nix" "build" ".#nixosConfigurations.kioskbeerli-pi-sim.config.system.build.vm"))))

(defun %make-command-spec (spec)
  (destructuring-bind (id title summary task-id level command-text argv) spec
    (make-instance 'pi-simulation-command-spec
                   :id id
                   :title title
                   :summary summary
                   :task-id task-id
                   :level level
                   :command-text command-text
                   :argv argv
                   :mutates-p nil
                   :execution-mode :manual-only
                   :executed-p nil)))

(defun pi-simulation-command-specs ()
  "Return inspectable Nix command specs. They are never executed here."
  (mapcar #'%make-command-spec *pi-simulation-command-spec-data*))

(defun %command-specs-for-task (task-id)
  (remove-if-not
   (lambda (spec)
     (string= task-id (task-id-of spec)))
   (pi-simulation-command-specs)))

(defun pi-simulation-vm-boot-status (&key backend)
  "Return the opt-in VM boot status without starting a VM."
  (if backend
      (make-instance 'pi-simulation-boot-status
                     :status :planned
                     :backend backend
                     :reason "A backend was named, but boot remains an explicit future/manual action.")
      (make-instance 'pi-simulation-boot-status
                     :status :skipped
                     :backend nil
                     :reason "VM/MicroVM boot smoke is skipped by default; no Linux virtualization backend is configured."
                     :evidence '("blocked-no-linux-backend"))))
