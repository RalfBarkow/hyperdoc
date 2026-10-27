;;; The review reading's three suites, run in the runtime of the packaged hyperdoc-catalog-topic-maps on Linux: the source is a
;;; /nix/store path without .git, Topic Maps is the verified snapshot, and there is no Topic Maps repository.
;;; Started by linux-reading-suites.sh with the packaged wrapper's environment. Nothing here is part of the candidate.
(require :asdf)
(asdf:initialize-source-registry
 `(:source-registry
   ,@(loop for path in (uiop:split-string (or (uiop:getenv "CL_SOURCE_REGISTRY") "") :separator ":")
           unless (zerop (length path)) collect `(:tree ,(uiop:ensure-directory-pathname (string-right-trim "/" path))))
   :ignore-inherited-configuration))
(format t "~&RUN-STARTED ~A ~A ~A; source ~A; git: ~A~%" (get-universal-time) (lisp-implementation-type) (lisp-implementation-version)
        (asdf:system-source-directory "dreyeck") (and (probe-file (merge-pathnames ".git" (asdf:system-source-directory "dreyeck"))) t))
(asdf:load-system "topic-maps-deployment-review-asdf-collision/tests")
(progn
  (handler-case
      (progn (uiop:symbol-call :topic-maps-deployment-review/tests :run-tests)
             (uiop:symbol-call :topic-maps-deployment-review/tests :run-proposal-tests)
             (uiop:symbol-call :topic-maps-deployment-review/tests :run-collision-tests)
             (format t "~&Project Workspace loaded: ~A; Topic Maps from ~A~%" (asdf:component-loaded-p "dreyeck/work/project") (asdf:system-source-directory "topic-maps"))
             (format t "~&LINUX-READING-SUITES-PASSED~%"))
    (error (c) (format t "~&LINUX-READING-SUITE-FAILED: ~A~%" c) (uiop:quit 1))))
