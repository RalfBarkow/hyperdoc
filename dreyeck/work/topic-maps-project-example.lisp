;;;; Optional local reading: retain actual independent TMDM objects, never project a second graph.
(defpackage #:dreyeck/work/topic-maps-project-example
  (:use #:cl)
  (:local-nicknames (#:m #:topic-maps.tmdm) (#:e #:topic-maps.project-work.example)
                    (#:v #:html-inspector-views) (#:nav #:dreyeck/inspector/tmdm)
                    (#:ev #:dreyeck/evaluation-record) (#:git #:dreyeck/git))
  (:export #:checked-source-path #:run-example #:project-example-run #:run-map
           #:run-source #:run-revision #:run-state #:run-cxtm
           #:inspect-project-example #:exercise-project-example #:+source-revision+))
(in-package #:dreyeck/work/topic-maps-project-example)
(defparameter +source-revision+ "b2eecffa05de4fce41c10ae1ada9ae11a0c6e7dc")
(hyperdoc:see (hyperdoc:page "Reading Slice 22U" :hyperbook "dreyeck/work/topic-maps-project-example"))
(defun checked-source-path ()
  (let* ((root (asdf:system-source-directory "topic-maps/project-work-example"))
         (head (git:trim-git-output (git:git-run-string root "rev-parse" "HEAD"))))
    (unless (and (string= head +source-revision+)
                 (zerop (length (git:git-run-string root "status" "--porcelain"))))
      (error "The 22U reading requires a clean Topic Maps checkout at ~A." +source-revision+))
    (dolist (system '("topic-maps" "topic-maps/tmdm" "topic-maps/ctm" "topic-maps/cxtm"))
      (unless (equal (truename root) (truename (asdf:system-source-directory system)))
        (error "ASDF selected different Topic Maps checkouts: ~A." system)))
    (asdf:system-relative-pathname "topic-maps/project-work-example" "examples/project-work.ctm")))
(defclass project-example-run ()
  ((map :initarg :map :reader run-map) (source :initarg :source :reader run-source)
   (revision :initarg :revision :reader run-revision) (state :initarg :state :reader run-state)
   (cxtm :initarg :cxtm :reader run-cxtm) (digest :initarg :digest :reader run-digest)
   (started :initarg :started :reader run-started) (finished :initarg :finished :reader run-finished)
   (identity :initform (gensym "PROJECT-22U-RUN-") :reader run-identity))
  (:documentation "Execution metadata referring to one actual Map, not a Topic/Association representation."))
(defun snapshot-example-state (map)
  "Copy the example's plain observation data, including mutable strings.
No TMDM object is copied or used as an alternative navigation graph."
  (labels ((snapshot (value)
             (typecase value
               (string (copy-seq value))
               (cons (cons (snapshot (car value)) (snapshot (cdr value))))
               (t value))))
    (snapshot (e:model-view map))))
(defun run-example ()
  (let* ((path (checked-source-path)) (root (asdf:system-source-directory "topic-maps/project-work-example"))
         (repository (make-instance 'git:git-repository-checkout :root root :root-source :asdf-system-source))
         (revision (git:make-git-commit :repository repository :commit-ish +source-revision+))
         (source (git:make-git-file-at-commit :commit revision :path "examples/project-work.ctm"))
         (started (get-universal-time)))
    (multiple-value-bind (map text) (e:load-map path :source-key "HyperDoc explicit 22U execution")
      (unless (and (string= text (git:git-file-contents source)) (e:references-current-p map))
        (error "22U source or native references disagree; no execution is registered."))
      (let ((run (make-instance 'project-example-run :map map :source source :revision revision
                   :state (snapshot-example-state map)
                   :cxtm (topic-maps.cxtm:canonicalize-octets map :base-locator e:*document-iri*)
                   :digest (ironclad:byte-array-to-hex-string (ironclad:digest-file :sha256 path))
                   :started started :finished (get-universal-time))))
        (nav:register-execution map run) run))))
(hyperdoc:defexample inspect-project-example
  "Explicitly read a fresh 22U Map from the pinned independent checkout. No persistence."
  (run-map (run-example)))
(hyperdoc:defexample exercise-project-example
  "Explicit exercise: annotate a newly created in-memory Map only; never the source file."
  (let ((map (run-map (run-example)))) (e:add-exercise-note map) map))
(defmethod ev:evaluation-specification-of ((run project-example-run)) 'inspect-project-example)
(defmethod ev:evaluation-input-of ((run project-example-run)) (run-source run))
(defmethod ev:evaluation-result-of ((run project-example-run)) (run-map run))
(defmethod ev:evaluation-status-of ((run project-example-run)) :completed)
(defmethod ev:evaluation-trace-of ((run project-example-run)) '(:source-checked :ctm-read :native-references-checked :cxtm-produced))
(defmethod ev:evaluation-evidence-of ((run project-example-run)) (list :source (run-source run) :revision (run-revision run) :sha256 (run-digest run)))
(defmethod ev:evaluation-failure-of ((run project-example-run)) nil)
(defmethod ev:evaluation-started-at-of ((run project-example-run)) (run-started run))
(defmethod ev:evaluation-finished-at-of ((run project-example-run)) (run-finished run))
(defmethod ev:evaluation-identity-of ((run project-example-run)) (run-identity run))
(defmethod ev:evaluation-annotation-of ((run project-example-run))
  (list :scope :local-example-not-corpus-registration :stored-12a-evidence :not-reexecuted
        :source-revision +source-revision+ :fresh-process :established-by-launcher-not-library))
(defmethod v:text-representation ((run project-example-run)) "Topic Maps 22U: actual local execution")
(v:defview project-example-execution (run project-example-run)
  (v:html-view :title "22U execution" :priority -10
    (v:html (:h2 "Local execution of Topic Maps Slice 22U")
      (:p "This record contains this execution. Older Slice 12A reports are not new 22U evidence.")
      (:p (v:esc (if (equal (run-state run) (e:model-view (run-map run)))
                     "Native state matches the reading." "Native state changed after the reading; later annotations are not source claims.")))
      (:p (v:object-ref (run-map run) :display "Actual native Topic Map" :select "Topics"))
      (:p (v:object-ref (e:find-topic (run-map run) "urn:topic-maps:question:Q-XTM-LOOP") :display "Q-XTM-LOOP" :select "Topic"))
      (:p (v:object-ref (run-source run) :display "CTM source at the pinned commit" :select "Contents"))
      (:p (v:object-ref (run-revision run) :display "Independent source revision"))
      (:p (v:object-ref (run-cxtm run) :display "CXTM at reading time")))))
(defun role-label (role)
  (flet ((label (topic)
           (let ((name (first (m:topic-names topic))))
             (if name (m:topic-name-value name) (v:text-representation topic)))))
    (format nil "Role ~A in ~A" (label (m:association-role-type role))
            (label (m:association-type (m:association-role-parent role))))))
;; Add semantic Role/Association views; retain all existing TMDM DEFVIEW methods unchanged.
(v:defview project-native-roles (topic m:topic)
  (v:html-view :title "Roles" :priority 5
    (v:html (:h2 "Actual Roles played")
      (:ul (dolist (role (m:topic-roles-played topic))
        (v:html (:li (v:object-ref role :display (role-label role) :select "Role"))))))))
(v:defview project-native-role (role m:association-role)
  (v:html-view :title "Role" :priority -10
    (v:html (:h2 "Native Association Role")
      (:p (v:object-ref (m:association-role-parent role) :display "Parent Association" :select "Association"))
      (:p (v:object-ref (m:association-role-type role) :display "Role Type" :select "Topic"))
      (:p (v:object-ref (m:association-role-player role) :display "Role Player" :select "Topic")))))
(v:defview project-native-association (association m:association)
  (v:html-view :title "Association" :priority -10
    (v:html (:h2 "Native Association")
      (:p (v:object-ref (m:association-parent association) :display "Parent Topic Map" :select "Topics"))
      (:p (v:object-ref (m:association-type association) :display "Association Type" :select "Topic"))
      (:ul (dolist (role (m:association-roles association))
        (v:html (:li (v:object-ref role :display (role-label role) :select "Role"))))))))
(v:defview project-example-entry (page hyperbook:page)
  (when (or (and (equal (hyperbook:id-of (hyperbook:hyperbook-of page)) "dreyeck/work/reading")
                 (equal (hyperbook:id-of page) "Work Breakdown"))
            (and (equal (hyperbook:id-of (hyperbook:hyperbook-of page)) "dreyeck/work/topic-maps-project-example")
                 (equal (hyperbook:id-of page) "Reading Slice 22U")))
    (v:html-view :title "Topic Maps 22U" :priority 140
      (v:html (:h2 "Read the project's native Topic Map")
        (:p "Explicit execution only. Source lookup uses the registered ASDF system; no load runs while a view is rendered.")
        (:p (v:object-ref (hyperdoc:page "Reading Slice 22U" :hyperbook "dreyeck/work/topic-maps-project-example") :display "Reading path"))
        (:p (v:eval-button "Read a fresh 22U Map" (v:thunk (inspect-project-example)) "Run DEFEXAMPLE"))
        (:p (v:object-ref #'inspect-project-example :display "Example definition" :select "Source code"))
        (:p (v:eval-button "Exercise on a separate fresh Map" (v:thunk (exercise-project-example)) "Run isolated exercise"))
        (:p (v:object-ref #'exercise-project-example :display "Exercise definition" :select "Source code"))))))

(hyperdoc:defhyperdoc *project-example-reading*
  :title "Topic Maps Project Example (22U)"
  :id "dreyeck/work/topic-maps-project-example"
  :asdf-system-name "dreyeck/work/topic-maps-project-example"
  :subdirectory "dreyeck/pages/topic-maps-project-example"
  :code-subdirectory "dreyeck/work/topic-maps-project-example"
  :main-page-id "Reading Slice 22U")
