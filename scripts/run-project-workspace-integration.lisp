;;; The Project Workspace against the Topic Maps ASDF finds, with the original retained project CTM. One fresh process.
;;;
;;;   CL_SOURCE_REGISTRY="<runtime sources>:<topic-maps root>//:<this checkout>//" XDG_CACHE_HOME=<empty directory> \
;;;     sbcl --noinform --no-sysinit --no-userinit --non-interactive --load scripts/run-project-workspace-integration.lisp
;;;
;;; The Topic Maps root is a clean Git checkout at the pin or its verified /nix/store snapshot; the identity printed first says
;;; which, and PIN-OK is the pass condition of that line. It reads dreyeck/work/project/hyperdoc-project.ctm and writes nothing:
;;; no Work page, no CTM, no wiki. Every line is an execution in this process.
(require :asdf)
(asdf:initialize-source-registry
 `(:source-registry
   ,@(loop for path in (uiop:split-string (or (uiop:getenv "CL_SOURCE_REGISTRY") "") :separator ":")
           unless (zerop (length path)) collect `(:tree ,(uiop:ensure-directory-pathname (string-right-trim "/" path))))
   :ignore-inherited-configuration))
(defun say (control &rest arguments) (apply #'format t control arguments) (terpri) (finish-output))
(defun seconds-since (start) (/ (- (get-internal-real-time) start) internal-time-units-per-second 1.0d0))
(say "RUN-STARTED ~A ~A ~A" (get-universal-time) (lisp-implementation-type) (lisp-implementation-version))
(dolist (system '("topic-maps" "topic-maps/tmdm" "topic-maps/ctm" "topic-maps/cxtm"))
  (say "ASDF-ORIGIN ~A ~A" system (namestring (asdf:system-source-directory system))))
(asdf:load-system "dreyeck/work/project")
(let* ((identity (uiop:symbol-call :dreyeck/work/project :topic-maps-source-identity))
       (retained (uiop:symbol-call :dreyeck/work/project :project-ctm-pathname))
       (digest-before (ironclad:byte-array-to-hex-string (ironclad:digest-file :sha256 retained))))
  (say "IDENTITY ~S" (loop for (key value) on identity by #'cddr unless (eq key :checks) append (list key value)))
  (say "PIN-~A" (if (getf identity :pinned) "OK" "NOT-OK"))
  (say "CTM-INPUT-SHA256 ~A" digest-before)
  ;; IDENTITY_ONLY=1 stops here: for a root that must be refused as the pin, whose reader would be too slow to wait for.
  (when (uiop:getenv "IDENTITY_ONLY") (say "RUN-STOPPED-AFTER-IDENTITY ~A" (get-universal-time)) (uiop:quit 0))
  (let* ((start (get-internal-real-time))
         (reading (uiop:symbol-call :dreyeck/work/project :project-workspace))
         (elapsed (seconds-since start))
         (model (uiop:symbol-call :dreyeck/work/project :reading-model reading))
         (document (uiop:symbol-call :dreyeck/work/project :reading-document reading))
         (map (uiop:symbol-call :dreyeck/work/project :revision-map document)))
    (say "PROJECT-WORKSPACE wall=~,3F digest=~A refusal=~S" elapsed (uiop:symbol-call :dreyeck/work/project :revision-sha256 document)
         (uiop:symbol-call :dreyeck/work/project :revision-refusal document))
    (say "WITHIN-90-SECONDS ~A" (if (< elapsed 90) "YES" "NO"))
    (say "MODEL declarations=~D statements=~D assignments=~D gaps=~D"
         (length (uiop:symbol-call :dreyeck/work/project :model-declarations model))
         (length (uiop:symbol-call :dreyeck/work/project :model-statements model))
         (length (uiop:symbol-call :dreyeck/work/project :model-assignments model))
         (length (uiop:symbol-call :dreyeck/work/project :model-gaps model)))
    (say "MAP topics=~D associations=~D" (length (uiop:symbol-call :topic-maps.tmdm :topic-map-topics map))
         (length (uiop:symbol-call :topic-maps.tmdm :topic-map-associations map)))
    (say "TRACE-DISCREPANCIES ~S" (uiop:symbol-call :dreyeck/work/project :trace-project-map map model))
    (let* ((cxtm (uiop:symbol-call :topic-maps.cxtm :canonicalize-octets map :base-locator (symbol-value (find-symbol "+DOCUMENT-IRI+" :dreyeck/work/project)))))
      (say "CXTM-BYTES ~D SHA256 ~A" (length cxtm) (ironclad:byte-array-to-hex-string (ironclad:digest-sequence :sha256 cxtm))))
    (let* ((start (get-internal-real-time))
           (projection (uiop:symbol-call :dreyeck/work/project :reading-projection reading))
           (workspace (uiop:symbol-call :dreyeck/work/project :reading-workspace reading)))
      (say "PROJECTION topics=~D edges=~D wall=~,3F"
           (length (uiop:symbol-call :dreyeck/topicmap :topicmap-projection-topics-of projection))
           (length (uiop:symbol-call :dreyeck/topicmap :topicmap-projection-associations-of projection)) (seconds-since start))
      (dolist (key '("hyperbook/dreyeck/work/reading" "page/dreyeck/work/reading/work-breakdown" "ctm-plan-page-authoring"
                     "page/dreyeck/work/reading/authoring-the-ctm-plan-page" "ctm-page-edit" "ctm-wp-2" "ctm-plan-p2" "ctm-pre-content"))
        (unless (uiop:symbol-call :dreyeck/topicmap :topicmap-projection-topic-by-id projection key) (error "No Topic ~A in the projection." key))
        (uiop:symbol-call :dreyeck/topicmap :topicmap-workspace-go-to workspace key))
      (say "NAVIGATION eight keys reached, history ~S" (uiop:symbol-call :dreyeck/topicmap :topicmap-workspace-history-of workspace)))
    (let* ((start (get-internal-real-time))
           (copy (uiop:symbol-call :dreyeck/work/project :ctm-revision-from-octets (uiop:symbol-call :dreyeck/work/project :revision-octets document)))
           (comparison (uiop:symbol-call :dreyeck/work/project :compare-revisions document copy)))
      (say "REVISION-FROM-OCTETS wall=~,3F COMPARE ~S" (seconds-since start) comparison))
    (say "CTM-INPUT-UNCHANGED ~A" (if (equal digest-before (ironclad:byte-array-to-hex-string (ironclad:digest-file :sha256 retained))) "YES" "NO"))))
(say "RUN-FINISHED ~A PROJECT-WORKSPACE-INTEGRATION-PASS" (get-universal-time))
