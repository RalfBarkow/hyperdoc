;;;; Two Projections of the Companion

(in-package #:dreyeck/traverse)

(hyperdoc:see
  (hyperdoc:page "From Git Revision to Nix Package" :hyperbook "dreyeck/traverse/reading"))
(hyperdoc:see
  (hyperdoc:page "How TRAVERSE Enters Mech" :hyperbook "dreyeck/traverse/reading"))
(hyperdoc:see
  (hyperdoc:page "From PageFold to Discourse Graph" :hyperbook "dreyeck/traverse/reading"))
(hyperdoc:see
  (hyperdoc:page "What the Deployment Proves" :hyperbook "dreyeck/traverse/reading"))

(defparameter +statuses+ '(:observed :derived :recorded :handed-over :not-established)
  "Warrant statuses. :observed — read in a retained source or record; :derived — computed by a named
source from observed input; :recorded — stated by a record that was not re-checked here; :handed-over —
captured at an interface; :not-established — explicitly not shown by anything retained.")

(defun projection (source topics relations)
  "TOPICS: (id label object status). RELATIONS: (from to type status basis evidence).
Topics carry the represented objects; every relation needs a basis and an evidence object.
Association identities derive from endpoints and type, never from positions."
  (let ((ids (mapcar #'first topics)))
    (tm:make-topicmap-projection
     :source source
     :topics (loop for (id label object status) in topics
                   for i from 0
                   do (unless object (error "Missing represented object: ~A" id))
                      (unless (member status +statuses+) (error "Unknown status ~S for ~A" status id))
                   collect (tm:make-topicmap-topic
                            :id id :type :traverse-companion :label label :object object
                            :view-properties (list :x (+ 30 (* 270 (mod i 4))) :y (+ 30 (* 130 (floor i 4)))
                                                   :visible t :evidence-status status)))
     :associations (loop for (from to type status basis evidence) in relations
                         do (unless (and (member from ids :test #'equal) (member to ids :test #'equal))
                              (error "Relation ~A refers to a missing topic" type))
                            (unless (and basis evidence) (error "Unwarranted relation: ~A ~A ~A" from type to))
                            (unless (member status +statuses+) (error "Unknown status ~S for ~A" status type))
                         collect (tm:make-topicmap-association
                                  :id (format nil "~A/~A/~A" from type to) :type type :from from :to to
                                  :properties (list :evidence-status status :basis basis
                                                    :warrant (list :status status :source evidence :basis basis))))
     :view-properties '(:width 1150 :height 900))))

(defun source-projection (reading)
  (let* ((s (lambda (key) (source-by-key reading key)))
         (acceptance (record-of reading "dreyeck/mech-profile-consumer-acceptance-traverse.json"))
         (http (record-of reading "postdeployment/http-observation.json")))
    (projection
     reading
     (list (list "rev:dreyeck" "dreyeck.ch 916ea5bf" (revision-of reading "dreyeck") :observed)
           (list "src:flake-input" "flake input mech-composition" (funcall s "dreyeck:mech-composition-input") :observed)
           (list "src:lock-node" "flake.lock node" (funcall s "dreyeck:lock-node") :observed)
           (list "src:profile-packages" "profilePackages" (funcall s "dreyeck:profile-packages") :observed)
           (list "src:with-mech" "withMech" (funcall s "dreyeck:with-mech") :observed)
           (list "rev:composition" "composition a83c3e0d" (revision-of reading "composition") :observed)
           (list "src:wiki-profile" "wiki-profile.nix" (funcall s "composition:wiki-profile") :observed)
           (list "src:mech-nix" "mech.nix" (funcall s "composition:mech-nix") :observed)
           (list "src:digest-checks" "mech-build.mjs checks" (funcall s "composition:mech-build-checks") :observed)
           (list "src:module-pin" "mech-pins.json module" (funcall s "composition:pins-module") :observed)
           (list "src:module-identity" "moduleIdentity" (funcall s "composition:moduleIdentity") :observed)
           (list "rev:module" "module 1dbedae7" (revision-of reading "module") :observed)
           (list "src:entry" "discourse-entry.mjs" (funcall s "composition:discourse-entry") :observed)
           (list "src:install-traverse" "installDiscourseTraverse" (funcall s "composition:installDiscourseTraverse") :observed)
           (list "rev:upstream" "Ward Mech a028b4b" (revision-of reading "upstream") :observed)
           (list "src:catalog" "upstream blocks catalog" (funcall s "upstream:blocks") :observed)
           (list "rec:acceptance" "consumer acceptance (before deployment)" acceptance :recorded)
           (list "rec:served" "served bundle (after deployment)" http :observed))
     (list (list "rev:dreyeck" "src:flake-input" "contains" :observed "flake.nix at 916ea5bf" (funcall s "dreyeck:mech-composition-input"))
           (list "rev:dreyeck" "src:lock-node" "contains" :observed "flake.lock at 916ea5bf" (funcall s "dreyeck:lock-node"))
           (list "src:flake-input" "rev:composition" "names" :observed "the input URL carries the full OID" (funcall s "dreyeck:mech-composition-input"))
           (list "src:lock-node" "rev:composition" "locks" :observed "rev and narHash of the locked node" (funcall s "dreyeck:lock-node"))
           (list "src:profile-packages" "src:with-mech" "wiki-discourse = withMech" :observed "profilePackages definition" (funcall s "dreyeck:profile-packages"))
           (list "src:with-mech" "src:wiki-profile" "imports from the composition" :observed "withMech imports nix/wiki-profile.nix of the input" (funcall s "dreyeck:with-mech"))
           (list "rev:composition" "src:mech-nix" "contains" :observed "nix/mech.nix at a83c3e0d" (funcall s "composition:mech-nix"))
           (list "src:mech-nix" "src:digest-checks" "runs" :observed "buildPhase runs nix/mech-build.mjs" (funcall s "composition:mech-nix"))
           (list "src:digest-checks" "src:module-pin" "requires equal digest" :observed "assert moduleIdentity().sourceContentSha256 equals the pin" (funcall s "composition:mech-build-checks"))
           (list "src:digest-checks" "src:module-identity" "computes with" :observed "mech-build.mjs imports moduleIdentity" (funcall s "composition:mech-build-checks"))
           (list "src:module-pin" "rev:module" "names" :observed "module.oid in mech-pins.json" (funcall s "composition:pins-module"))
           (list "rev:composition" "src:entry" "contains" :observed "integrations/mech/src/discourse-entry.mjs at a83c3e0d" (funcall s "composition:discourse-entry"))
           (list "src:entry" "src:install-traverse" "calls" :observed "installDiscourseTraverse(blocks) in the entry" (funcall s "composition:discourse-entry"))
           (list "src:install-traverse" "src:catalog" "adds TRAVERSE to" :observed "catalog.TRAVERSE = { emit: traverse_emit }" (funcall s "composition:installDiscourseTraverse"))
           (list "rev:upstream" "src:catalog" "contains" :observed "src/client/blocks.js at a028b4b" (funcall s "upstream:blocks"))
           (list "src:wiki-profile" "rec:acceptance" "evaluated package recorded" :recorded "x86_64-linux evaluated, not built, before deployment" acceptance)
           (list "rec:acceptance" "rec:served" "same bundle later served" :observed "recorded bundle SHA-256 equals the served one; compared on load" http)))))

(defun dataflow-projection (run)
  (let* ((reading (run-reading run))
         (s (lambda (key) (source-by-key reading key)))
         (st (lambda (name) (stage-of run name)))
         (observed (stage-value (stage-of run "observed link")))
         (fixture (gethash "fixture" (record-value (run-record run))))
         (pages (gethash "pages" fixture)))
    (projection
     run
     (list (list "page:question" "page Question" (gethash "question" pages) :observed)
           (list "item:fold" "pagefold Claims" (gethash "fold" observed) :observed)
           (list "item:link" "paragraph [[Claim A]]" (gethash "item" observed) :observed)
           (list "page:claim-a" "page Claim A" (gethash "claim-a" pages) :observed)
           (list "stage:extract" "EXTRACT edge" (funcall st "EXTRACT") :derived)
           (list "stage:resolve" "resolveEdges" (funcall st "resolveEdges") :derived)
           (list "stage:traverse" "traverse" (funcall st "traverse") :derived)
           (list "stage:present" "presentGraph" (funcall st "presentGraph") :derived)
           (list "stage:solo" "SOLO batch" (funcall st "SOLO") :handed-over)
           (list "assertion" "asserted relation (not established)" (funcall st "asserted relation") :not-established)
           (list "src:extract" "extract_edges_from_story" (funcall s "composition:extract_edges_from_story") :observed)
           (list "src:fold" "canonicalize_fold" (funcall s "composition:canonicalize_fold") :observed)
           (list "src:resolve" "resolveEdges source" (funcall s "composition:resolveEdges") :observed)
           (list "src:traverse" "traverse source" (funcall s "composition:traverse") :observed)
           (list "src:present" "presentGraph source" (funcall s "composition:presentGraph") :observed)
           (list "src:solo" "solo_emit" (funcall s "upstream:solo_emit") :observed))
     (list (list "page:question" "item:fold" "contains" :observed "story item f000000000000001 of the fixture" (run-record run))
           (list "page:question" "item:link" "contains" :observed "story item p000000000000002 of the fixture" (run-record run))
           (list "item:link" "page:claim-a" "links to" :observed "[[Claim A]] names the slug claim-a listed in the sitemap" (run-record run))
           (list "item:link" "stage:extract" "read by" :observed "the recorded EXTRACT edge has toId companion.example+claim-a" (run-record run))
           (list "item:fold" "stage:extract" "role from fold label" :derived "Claims canonicalized to claim" (funcall s "composition:canonicalize_fold"))
           (list "src:extract" "stage:extract" "defines" :observed "extract_edges_from_story" (funcall s "composition:extract_edges_from_story"))
           (list "src:fold" "stage:extract" "defines role names" :observed "canonicalize_fold" (funcall s "composition:canonicalize_fold"))
           (list "stage:extract" "stage:resolve" "input to" :observed "recorded resolveEdges output carries the EXTRACT edge" (run-record run))
           (list "src:resolve" "stage:resolve" "defines" :observed "resolveEdges" (funcall s "composition:resolveEdges"))
           (list "stage:resolve" "stage:traverse" "input to" :observed "recorded traverse output" (run-record run))
           (list "src:traverse" "stage:traverse" "defines" :observed "traverse" (funcall s "composition:traverse"))
           (list "stage:traverse" "stage:present" "input to" :observed "recorded presentGraph output" (run-record run))
           (list "src:present" "stage:present" "defines" :observed "presentGraph" (funcall s "composition:presentGraph"))
           (list "stage:present" "stage:solo" "handed over as aspect" :observed "the batch graph equals presentGraph's; compared on load" (run-record run))
           (list "src:solo" "stage:solo" "defines" :observed "solo_emit posts the batch" (funcall s "upstream:solo_emit"))
           (list "stage:extract" "assertion" "is not" :not-established "a fold-derived page relation is not the author's domain assertion" (funcall s "composition:traverse-header"))))))

(defun companion-workspace (&optional (mode :source))
  (let ((reading (retained-reading)))
    (ecase mode
      (:source (tm:make-topicmap-workspace (source-projection reading) "rev:dreyeck"))
      (:dataflow (tm:make-topicmap-workspace (dataflow-projection (two-page-example)) "item:link")))))

(defun switch-projection (workspace mode)
  "Reproject the same Workspace; Point and history are kept, including a Point absent from the other projection."
  (tm:topicmap-workspace-reproject
   workspace
   (ecase mode
     (:source (source-projection (retained-reading)))
     (:dataflow (dataflow-projection (two-page-example)))))
  workspace)

(hyperdoc:defexample source-workspace
  "Source/Composition: from the deployment branch to the evaluated package and the served bundle."
  (companion-workspace :source))

(hyperdoc:defexample dataflow-workspace
  "Execution/Dataflow: from the story item through the five stages to the SOLO batch."
  (companion-workspace :dataflow))

(dreyeck/hyperdoc:defhyperdoc *companion*
  :title "TRAVERSE Reading Companion"
  :id "dreyeck/traverse/reading"
  :asdf-system-name "dreyeck/traverse/reading"
  :subdirectory "dreyeck/pages/traverse"
  :code-subdirectory "dreyeck/traverse"
  :main-page-id "What Did Ward Propose?")

(dolist (name '(retained-reading package-chain traverse-entry two-page-example deployment-evidence
                source-workspace dataflow-workspace))
  (dreyeck/authority-policy:register-operation-contract
   :identity (format nil "traverse/~(~A~)" name)
   :operation (format nil "DREYECK/TRAVERSE::~A" name)
   :applicability :example
   :status :contracted
   :effect-classes '(:observational)
   :effect-extent "Read hash-verified retained files; allocate source, record, stage and Workspace objects."
   :authority "Retained sources at fixed revisions; records marked before or after the deployment"
   :preconditions "dreyeck/traverse/reading loaded"
   :postconditions "No process, network request, Wiki or server is touched"
   :verification-evidence "dreyeck/traverse/reading/tests"
   :replay-semantics "Fresh Lisp inspection; no Mech execution or rebuild"
   :audit-provenance "TRAVERSE reading companion, 2026-10-21"))
