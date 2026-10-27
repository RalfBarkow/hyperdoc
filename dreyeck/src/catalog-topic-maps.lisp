;;;; The hyperdoc-catalog-topic-maps executable: the Catalog with the pinned Topic Maps snapshot in its registry.
;;;;
;;;; A separate executable for loopback staging; hyperdoc-catalog and its startup are unchanged and never see topic-maps.
;;;; Before serving it verifies the snapshot and that every Topic Maps system comes from it, and it refuses the Project
;;;; Workspace, whose reader is pinned to another Topic Maps lineage (5a4a668), so that it is never loaded against this one.
;;;; The refusal is a check of this application's own startup: the Catalog loads exactly one system by choice, the one
;;;; HYPERDOC_CATALOG_SYSTEM names, and MAIN looks at that system's definition, and at its dependencies' definitions, before
;;;; the Catalog starts. It adds no method to ASDF and replaces none: ASDF's own methods stay ASDF's.
;;;; What it protects, and what it does not, is stated in docs/topic-maps-deployment/README.md (The guard's scope). In short: the
;;;; Project Workspace is not loaded at startup, and the one application path that could load a system named by a wiki page
;;;; after startup, dreyeck/page-attached-hyperdoc, is refused the same way, so that it is not in this runtime at all.
;;;; Its plain v:thunk run buttons are not gated by dreyeck/authority-policy, so it serves loopback only.

(defpackage #:dreyeck/catalog-topic-maps
  (:use #:cl)
  (:local-nicknames (#:snap #:dreyeck/source-snapshot))
  (:export #:main #:+topic-maps-commit+ #:loopback-host-p #:topic-maps-origins #:verify-startup
           #:requested-catalog-system #:refuse-project-workspace #:project-workspace-refused #:page-attached-loader-refused
           #:refused-system-p #:loader-system-p))
(in-package #:dreyeck/catalog-topic-maps)

(defparameter +topic-maps-commit+ "b2eecffa05de4fce41c10ae1ada9ae11a0c6e7dc"
  "The commit of the packaged snapshot; the 22U reading and the CTM review pin the same one.")
(defparameter +topic-maps-systems+ '("topic-maps" "topic-maps/tmdm" "topic-maps/ctm" "topic-maps/cxtm" "topic-maps/project-work-example"))

(defun loopback-host-p (host) (member host '("127.0.0.1" "::1") :test #'equal))

(defun topic-maps-origins ()
  "Verify the /nix/store snapshot ASDF loads Topic Maps from, and that every Topic Maps system comes from it."
  (let ((root (truename (asdf:system-source-directory "topic-maps"))))
    (dolist (system +topic-maps-systems+)
      (unless (equal root (truename (asdf:system-source-directory system)))
        (error "ASDF finds ~A in ~A, not in the snapshot ~A." system (asdf:system-source-directory system) root)))
    (snap:verify-store-snapshot root +topic-maps-commit+)))

;;; The Project Workspace guard

(defparameter +refused-systems+ '("dreyeck/work/project")
  "Systems bound to another Topic Maps revision than the snapshot, with their subsystems.")
(define-condition project-workspace-refused (error)
  ((system :initarg :system :reader refused-system))
  (:report (lambda (c s) (format s "~A is bound to Topic Maps 5a4a668, not to the packaged ~A; it is not loaded here."
                                 (refused-system c) (subseq +topic-maps-commit+ 0 8)))))
(defparameter +loader-systems+ '("dreyeck/page-attached-hyperdoc")
  "The system whose function loads, after startup, a system named by a wiki page's attached ASD. The activation button of a
local FedWiki page reaches it through dreyeck/fedwiki-hyperdoc, and that button is a plain v:thunk, which dreyeck/authority-policy
does not gate. dreyeck/fedwiki-hyperdoc and the activation button's system depend on it, so refusing it refuses them as well.")
(define-condition page-attached-loader-refused (project-workspace-refused) ()
  (:report (lambda (c s) (format s "~A would let a wiki page name a system to load after startup, which could introduce the Project Workspace (bound to Topic Maps 5a4a668, not to the packaged ~A); it is not loaded here."
                                 (refused-system c) (subseq +topic-maps-commit+ 0 8)))))
(defun %under-p (name roots)
  (some (lambda (root) (or (string= name root) (uiop:string-prefix-p (concatenate 'string root "/") name))) roots))
(defun refused-system-p (name) (%under-p name +refused-systems+))
(defun loader-system-p (name) (%under-p name +loader-systems+))
(defun %refused-dependency (system seen)
  "The first refused system among SYSTEM and its transitive dependencies, found from their definitions alone."
  (let ((name (asdf:component-name system)))
    (cond ((or (refused-system-p name) (loader-system-p name)) name)
          ((gethash name seen) nil)
          (t (setf (gethash name seen) t)
             (loop for spec in (asdf:system-depends-on system)
                   for dependency = (ignore-errors (asdf/find-component:resolve-dependency-spec system spec))
                   thereis (and (typep dependency 'asdf:system) (%refused-dependency dependency seen)))))))

(defun requested-catalog-system (&optional (getenv #'uiop:getenv))
  "The system the Catalog's own startup loads, chosen as dreyeck/catalog-application's %CONFIGURATION chooses it."
  (or (funcall getenv "HYPERDOC_CATALOG_SYSTEM") "dreyeck/catalog"))

(defun refuse-project-workspace (system-name)
  "Signal PROJECT-WORKSPACE-REFUSED (or PAGE-ATTACHED-LOADER-REFUSED, a kind of it) if the system named SYSTEM-NAME is a refused system or depends on one. It reads system
definitions only: nothing is loaded and no ASDF operation is made, so nothing of a refused system is loaded or run."
  (let* ((system (and (not (refused-system-p system-name)) (asdf:find-system system-name nil)))
         (refused (if system
                      (%refused-dependency system (make-hash-table :test #'equal))
                      (and (or (refused-system-p system-name) (loader-system-p system-name)) system-name))))
    (when refused (error (if (refused-system-p refused) 'project-workspace-refused 'page-attached-loader-refused) :system refused))
    system-name))

(defun verify-startup (&optional (catalog-system (requested-catalog-system)))
  "What MAIN does before the Catalog starts: verify the Topic Maps origins, then refuse the Project Workspace if
CATALOG-SYSTEM is or depends on it. Returns the snapshot verification; starts nothing."
  (let ((verification (topic-maps-origins)))
    (format t "~&Topic Maps ~A: ~A~%" (subseq +topic-maps-commit+ 0 8) (namestring (snap:verification-root verification)))
    (format t "~&Topic Maps snapshot verified without .git (~{~(~A~)~^, ~})~%" (snap:verification-checks verification))
    (finish-output)
    (refuse-project-workspace catalog-system)
    verification))

(defun main (&optional (arguments (uiop:command-line-arguments)))
  "Verify the Topic Maps origins and refuse the Project Workspace (VERIFY-STARTUP), then run the Catalog's own MAIN. The
host is checked by scripts/catalog-topic-maps-main.lisp before anything is loaded."
  (unless (equal arguments '("--help"))
    (handler-case (verify-startup)
      (error (condition)
        (format *error-output* "~&Topic Maps Catalog startup refused: ~A~%" condition)
        (return-from main 2))))
  (dreyeck/catalog-application:main arguments))
