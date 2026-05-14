;;;; Codex collaboration home topic

(in-package :hyperdoc)

(defclass codex-home ()
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (summary :accessor summary-of :initarg :summary)
   (current-slice :accessor codex-home-current-slice-of
                  :initarg :current-slice)
   (primary-review-object :accessor codex-home-primary-review-object-of
                          :initarg :primary-review-object)
   (related-objects :accessor codex-home-related-objects-of
                    :initarg :related-objects)
   (relevant-pages :accessor codex-home-relevant-pages-of
                   :initarg :relevant-pages)
   (validation-commands :accessor codex-home-validation-commands-of
                        :initarg :validation-commands)
   (commit-boundary :accessor codex-home-commit-boundary-of
                    :initarg :commit-boundary
                    :initform nil)))

(defmethod print-object ((object codex-home) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defun codex ()
  (make-instance 'codex-home
                 :id "codex-home"
                 :title "Codex"
                 :summary "Inspectable collaboration home surface for the current HyperDoc review slice."
                 :current-slice "Kioskberrli mobile station-board view"
                 :primary-review-object (kioskberrli-dashboard)
                 :related-objects (list (kioskberrli-dashboard-status)
                                        (kioskberrli-current-blocker)
                                        (kioskberrli-build-evidence-status)
                                        (kioskberrli-dashboard-stations))
                 :relevant-pages '("Kioskberrli"
                                   "Kioskberrli Dashboard"
                                   "Kioskberrli Cross-Host Build Failure")
                 :validation-commands
                 '("nix develop -c sbcl --noinform --disable-debugger --non-interactive --eval '(require :asdf)' --eval '(asdf:load-system :hyperdoc/tests)'"
                   "nix develop -c sbcl --noinform --disable-debugger --non-interactive --eval '(require :asdf)' --eval '(asdf:load-system :hyperdoc/tests)' --eval '(hyperdoc/tests:run-kioskberrli-dashboard-smoke-tests)'"
                   "tools/validate-documentation-slice.sh --page 'hyperdoc/Kioskberrli Dashboard.html'"
                   "git diff --check")
                 :commit-boundary "Codex materializes collaboration/review records and links to the target topic or system. Implementation changes still belong to the relevant target subsystem."))
