;;;; The hyperdoc-catalog-topic-maps executable: the Catalog with the pinned Topic Maps snapshot in its registry.
;;;;
;;;; A separate executable for loopback staging; hyperdoc-catalog and its startup are unchanged and never see topic-maps.
;;;; Before serving it verifies the snapshot and that every Topic Maps system comes from it, and it refuses the Project
;;;; Workspace, whose reader is pinned to another Topic Maps lineage (5a4a668), so that it is never loaded against this one.
;;;; Its plain v:thunk run buttons are not gated by dreyeck/authority-policy, so it serves loopback only.

(defpackage #:dreyeck/catalog-topic-maps
  (:use #:cl)
  (:local-nicknames (#:snap #:dreyeck/source-snapshot))
  (:export #:main #:+topic-maps-commit+ #:loopback-host-p #:topic-maps-origins
           #:install-project-workspace-guard #:project-workspace-refused #:refused-system-p))
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
(defun refused-system-p (name)
  (some (lambda (refused) (or (string= name refused) (uiop:string-prefix-p (concatenate 'string refused "/") name)))
        +refused-systems+))
(defun %refused-dependency (system seen)
  "The first refused system among SYSTEM and its transitive dependencies, found from their definitions alone."
  (let ((name (asdf:component-name system)))
    (cond ((refused-system-p name) name)
          ((gethash name seen) nil)
          (t (setf (gethash name seen) t)
             (loop for spec in (asdf:system-depends-on system)
                   for dependency = (ignore-errors (asdf/find-component:resolve-dependency-spec system spec))
                   thereis (and (typep dependency 'asdf:system) (%refused-dependency dependency seen)))))))

(defvar *guard* nil)
(defun install-project-workspace-guard () (setf *guard* t))
(defmethod asdf:operate :before ((operation t) (component t) &key &allow-other-keys)
  ;; Before any plan is made: the requested system, or anything it depends on, is refused.
  (when *guard*
    (let ((system (typecase component
                    (asdf:component (asdf:component-system component))
                    ((or string symbol) (asdf:find-system component nil)))))
      (let ((refused (and system (%refused-dependency system (make-hash-table :test #'equal)))))
        (when refused (error 'project-workspace-refused :system refused))))))
(defmethod asdf:perform :before ((operation asdf:operation) (component asdf:component))
  ;; The backstop, whatever started the plan.
  (when (and *guard* (refused-system-p (asdf:component-name (asdf:component-system component))))
    (error 'project-workspace-refused :system (asdf:component-name (asdf:component-system component)))))

(defun main (&optional (arguments (uiop:command-line-arguments)))
  "Verify the Topic Maps origins, refuse the Project Workspace, then run the Catalog's own MAIN. The host is checked by
scripts/catalog-topic-maps-main.lisp before anything is loaded."
  (unless (equal arguments '("--help"))
    (handler-case
        (let ((verification (topic-maps-origins)))
          (install-project-workspace-guard)
          (format t "~&Topic Maps ~A: ~A~%" (subseq +topic-maps-commit+ 0 8) (namestring (snap:verification-root verification)))
          (format t "~&Topic Maps snapshot verified without .git (~{~(~A~)~^, ~})~%" (snap:verification-checks verification))
          (finish-output))
      (error (condition)
        (format *error-output* "~&Topic Maps Catalog startup refused: ~A~%" condition)
        (return-from main 2))))
  (dreyeck/catalog-application:main arguments))
