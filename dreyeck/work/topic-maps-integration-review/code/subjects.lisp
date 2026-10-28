;;;; The Integration's Subjects and Their Warranted Relations
(in-package #:topic-maps-integration-review)

;;; A Workspace over HyperDoc's own Topicmap protocol (dreyeck/topicmap). Each Topic stands for one subject and holds the object it is:
;;; a Topic Maps revision, a function, a recorded run, a claim. Each relation says why it holds: its type, its provenance (the
;;; definition or file that makes it hold), its evidence (recorded runs) and how it is known. The coordinates are authored for this
;;; reading; nothing lays them out automatically.

(defun topic-maps-repository ()
  (let ((root (uiop:ensure-directory-pathname (or (uiop:getenv "TOPIC_MAPS_REPOSITORY") "/Users/rgb/workspace/topic-maps/"))))
    (and (probe-file (merge-pathnames ".git" root)) root)))

(defclass source-revision ()
  ((commit :initarg :commit :reader revision-commit) (role :initarg :role :reader revision-role))
  (:documentation "A Topic Maps commit, read from the local repository when it is shown."))
(defmethod v:text-representation ((r source-revision)) (format nil "Topic Maps ~A" (subseq (revision-commit r) 0 8)))
(defun revision-git (revision &rest arguments)
  (let ((root (topic-maps-repository)))
    (and root (multiple-value-bind (out err code) (apply #'git:git-run-values root arguments)
                (declare (ignore err)) (and (zerop code) (string-right-trim '(#\Newline) out))))))

(defclass git-observation ()
  ((question :initarg :question :reader observation-question) (command :initarg :command :reader observation-command)
   (exit-code :initarg :exit-code :reader observation-exit-code) (answer :initarg :answer :reader observation-answer)
   (at :initarg :at :reader observation-at))
  (:documentation "One read-only question put to the Topic Maps repository, with Git's own answer."))
(defmethod v:text-representation ((o git-observation)) (observation-question o))
(defun observe-ancestry (ancestor descendant)
  (let ((root (topic-maps-repository)) (command (list "git" "merge-base" "--is-ancestor" ancestor descendant)))
    (multiple-value-bind (out err code) (if root (apply #'git:git-run-values root (rest command)) (values "" "no repository" nil))
      (declare (ignore out err))
      (make-instance 'git-observation :question (format nil "Is ~A an ancestor of ~A?" (subseq ancestor 0 8) (subseq descendant 0 8))
                                      :command command :exit-code code :at (get-universal-time)
                                      :answer (case code (0 :yes) (1 :no) (t :unknown))))))

(defclass integration-association (tm:topicmap-association)
  ((provenance :initarg :provenance :initform nil :reader association-provenance)
   (evidence :initarg :evidence :initform nil :reader association-evidence)
   (class :initarg :class :reader association-class)
   (note :initarg :note :initform nil :reader association-note))
  (:documentation "A Topicmap association that says why it holds."))
(defmethod v:text-representation ((a integration-association))
  (format nil "~A ~A ~A" (tm:topicmap-association-from-of a) (tm:topicmap-association-type-of a) (tm:topicmap-association-to-of a)))
(defclass proposed-object ()
  ((title :initarg :title :reader proposed-title) (kind :initarg :kind :reader proposed-kind) (statement :initarg :statement :reader proposed-statement))
  (:documentation "A project object that a note proposes and no Work page, WBS dictionary or CTM declares. It exists only in this reading."))
(defmethod v:text-representation ((o proposed-object)) (format nil "~A (proposed)" (proposed-title o)))
(v:defview proposed-object-view (object proposed-object)
  (v:html-view :title "Proposed" :priority -10
    (v:html
      (:div :style "overflow-wrap:anywhere"
       (:h2 (v:esc (proposed-title object)))
       (:p (:strong "Proposed, not declared. ") (v:esc (format nil "A ~A that Zettel 11359 wishes to navigate from. It is not a Work Item of any Work page, not an entry of a WBS dictionary and not in the project CTM; this reading does not make it one." (proposed-kind object))))
       (:p (v:esc (proposed-statement object)))
       (:p "The note: " (v:object-ref (record "zettel-11359-excerpt.md") :select "Record" :display "Zettel 11359, excerpt"))
       (:p "Its proposed relations to the real subjects are the relations of class " (:em "proposed") " in the " (v:object-ref (the-workspace) :select "Relations" :display "Relations view") ".")
       (reading-links)))))

(defclass integration-workspace (tm:topicmap-workspace) ()
  (:documentation "The editing space of this reading's subjects: Point, Go to, and the warrants of the relations at Point."))

(defvar *workspace* nil)
(defvar *subjects* nil)
(defun the-workspace () (or *workspace* (setf *workspace* (build-workspace))))
(defun subject-object (id) (tm:topicmap-topic-object-of (tm:topicmap-projection-topic-by-id (tm:topicmap-workspace-projection-of (the-workspace)) id)))

(defun build-workspace ()
  (let* ((baseline (make-instance 'source-revision :commit +baseline-commit+ :role "the previously packaged Topic Maps commit"))
         (reviewed (make-instance 'source-revision :commit +reviewed-commit+ :role "Task 1C: b2eecffa plus the indexed Topic merge search"))
         (sibling (make-instance 'source-revision :commit +sibling-commit+ :role "the Project Workspace's former pin"))
         (ancestry (observe-ancestry +baseline-commit+ +reviewed-commit+))
         (lineage (observe-ancestry +sibling-commit+ +reviewed-commit+))
         (manifest (snap:find-snapshot-manifest +reviewed-commit+))
         (topics nil) (associations nil) (counter 0))
    (labels ((topic (id label kind status object x y)
               (push (tm:make-topicmap-topic :id id :type kind :label label :object object
                                             :view-properties (list :x x :y y :visible t :pinned t :kind kind :status status))
                     topics))
             (relate (from type to class provenance evidence &optional note)
               (push (make-instance 'integration-association :id (format nil "r~2,'0D" (incf counter)) :type type :from from :to to
                                                             :properties nil :class class :provenance provenance
                                                             :evidence (mapcar #'record evidence) :note note)
                     associations)))
      ;; Revisions and the reviewed change
      (topic "b2eecffa" "Topic Maps b2eecffa" "source revision" "previous pin" baseline 40 60)
      (topic "6162ed68" "Topic Maps 6162ed68" "source revision" "Task 1C, integrated locally" reviewed 420 60)
      (topic "5a4a668" "Topic Maps 5a4a668" "source revision" "sibling lineage, former Workspace pin" sibling 40 260)
      (topic "change" "next-topic-merge" "reviewed change" "the one production change" #'topic-maps.tmdm::next-topic-merge 800 60)
      (topic "oracle" "scan-next-topic-merge" "reviewed change" "the b2eecffa search, kept as fallback and oracle" #'topic-maps.tmdm::scan-next-topic-merge 800 240)
      (topic "review" "Independent review (GO)" "test execution" "2026-10-28" (record "independent-review.md") 1180 60)
      (topic "mutants" "Mutation controls" "test execution" "8 of 8 killed" (record "independent-suite-and-mutation-results.json") 1180 240)
      (topic "semantic" "Independent semantic checks (77)" "test execution" "pass" (record "independent-semantic-checks.log") 1180 420)
      ;; Measurements
      (topic "performance" "Performance difference" "measurement" "observed" (the-performance) 800 420)
      (topic "slices" "Corpus slices against b2eecffa" "measurement" "observed" (claim "slices-against-baseline") 420 420)
      (topic "corpus" "Project CTM, unchanged bytes" "measurement" "signature and CXTM equal 5a4a668" (claim "corpus-identical") 40 420)
      ;; The source of the integration
      (topic "snapshot" "Snapshot manifest of 6162ed68" "verification evidence" "2,354 files, no reports/" manifest 420 600)
      (topic "archive" "Archive verification" "verification evidence" "19 checks" (record "snapshot-archive-verification.json") 40 600)
      (topic "source-now" "Topic Maps source of this image" "source of this image" "asked on request" (the-topic-maps-source) 800 600)
      ;; HyperDoc
      (topic "identity" "topic-maps-source-identity" "HyperDoc function" "pin check, snapshot-aware" #'p::topic-maps-source-identity 1180 600)
      (topic "project" "dreyeck/work/project" "ASDF system" "bound to 6162ed68" (asdf:find-system "dreyeck/work/project") 1180 780)
      (topic "guard" "Catalog startup guard" "HyperDoc function" "still refuses the Workspace" #'c:refuse-project-workspace 800 780)
      (topic "run-git" "Workspace run, Git checkout" "test execution" "pass" (record "phase-b-workspace-git-checkout.log") 420 780)
      (topic "run-snapshot" "Workspace run, verified snapshot" "test execution" "pass" (record "phase-b-workspace-verified-snapshot.log") 40 780)
      (topic "nix" "Nix package contract (darwin)" "test execution" "pass" (record "phase-b-nix-package-check.log") 420 940)
      (topic "negatives" "Pin negatives" "test execution" "refused as expected" (record "phase-b-negative-5a4a668.log") 40 940)
      (topic "open" "Remaining work" "open claim" "not done" (claim "staging-not-started") 800 940)
      ;; The note, the proposed object and the earlier proposals
      (topic "zettel" "Zettel 11359" "coordination note" "the owner's note" (record "zettel-11359-excerpt.md") 1560 60)
      (topic "p-work-item" "Work Item: Topic Maps in HyperDoc integrieren" "proposed project object" "proposed, not declared"
             (make-instance 'proposed-object :title "Work Item: Topic Maps in HyperDoc integrieren" :kind "Work Item"
                            :statement "Zettel 11359 names it as the start of a navigation: its Source Change, its Evidence, the Project Workspace that reads it and the Deployment Evidence.") 1560 240)
      (topic "p-packages" "Proposed Work Packages of the earlier review" "proposals" "proposed, not declared"
             (hyperbook:find-page "topic-maps-deployment-review" "The Proposed Deployment WBS" :signal-error? t) 1560 420)
      ;; The earlier review's contract and the browser run
      (topic "contract" "DECLARED-PATHS-AGREE (version-bound)" "HyperDoc function" "bound to 8e64e718" #'topic-maps-deployment-review::declared-paths-agree-p 1560 600)
      (topic "contract-run" "The contract: results and controls" "test execution" "pass" (record "phase-c-declared-paths-agree.txt") 1940 600)
      (topic "browser-pw" "Project Workspace in a browser" "test execution" "pass" (record "phase-c-project-workspace-browser.log") 1940 780)
      (topic "trusted" "serve-project-workspace.lisp" "runtime" "trusted review runtime, not the packaged Catalog" (file-line "scripts/serve-project-workspace.lisp") 1940 960)
      ;; The four boundaries
      (topic "b1" "Boundary 1: pins and snapshot" "commit boundary" "proposed" (boundary "1") 2320 60)
      (topic "b2" "Boundary 2: Project Workspace" "commit boundary" "proposed" (boundary "2") 2320 240)
      (topic "b3" "Boundary 3: this reading" "commit boundary" "proposed" (boundary "3") 2320 420)
      (topic "b4" "Boundary 4: record and procedure" "commit boundary" "proposed" (boundary "4") 2320 600)
      (relate "6162ed68" "descends from" "b2eecffa" (if (eq :yes (observation-answer ancestry)) :observed :open) (list ancestry) '("phase-a-integration.txt")
              "Git's answer when these subjects were projected.")
      (relate "5a4a668" (if (eq :no (observation-answer lineage)) "is not an ancestor of" "ancestry not established with") "6162ed68"
              (if (member (observation-answer lineage) '(:yes :no)) :observed :open) (list lineage) nil "A sibling lineage on 963f2a0.")
      (relate "change" "is the one production change of" "6162ed68" :observed (list #'topic-maps.tmdm::next-topic-merge #'topic-maps.tmdm::normalize-topic-map)
              '("task1c-commit-record.md" "independent-review.md"))
      (relate "oracle" "defines the choice that" "change" :derived (list #'topic-maps.tmdm::scan-next-topic-merge #'topic-maps.tmdm::next-topic-merge) nil
              "The index returns the pair the scan returns; the scan is also the fallback.")
      (relate "review" "judges" "change" :observed (list (record "independent-review.md")) '("independent-review.md"))
      (relate "mutants" "shows the tests can fail on" "change" :observed (list #'topic-maps.tmdm::next-topic-merge) '("independent-suite-and-mutation-results.json" "task1c-mutation-results.txt"))
      (relate "semantic" "checks independently" "change" :observed (list #'topic-maps.tmdm::equal-topics-p) '("independent-semantic-checks.log"))
      (relate "performance" "measures" "change" :observed (list (the-performance)) '("independent-bench-baseline-timeout.json" "independent-bench-candidate.json" "phase-b-benchmark-integrated.json"))
      (relate "slices" "compares b2eecffa with" "6162ed68" :observed nil '("independent-review.md"))
      (relate "corpus" "reads equal under" "6162ed68" :observed nil '("independent-bench-candidate.json" "phase-b-workspace-verified-snapshot.log"))
      (relate "snapshot" "records the Git objects of" "6162ed68" :observed (list manifest) '("snapshot-archive-verification.json"))
      (relate "archive" "verifies" "snapshot" :observed (list (file-line "scripts/topic-maps-snapshot.py")) '("snapshot-archive-verification.json"))
      (relate "source-now" "is verified against" "snapshot" :derived (list #'snap:verify-store-snapshot) nil "On request; see The Topic Maps Source Revision.")
      (relate "identity" "checks the pin of" "source-now" :observed (list #'p::topic-maps-source-identity #'p::pinned-state-p) '("phase-b-project-suite.log"))
      (relate "project" "is bound to" "6162ed68" :observed (list (symbol-value 'p::+topic-maps-revision+)) '("phase-b-project-suite.log"))
      (relate "project" "asks" "identity" :derived (list #'p::topic-maps-source-identity) nil)
      (relate "run-git" "exercises" "project" :observed nil '("phase-b-workspace-git-checkout.log"))
      (relate "run-snapshot" "exercises" "project" :observed nil '("phase-b-workspace-verified-snapshot.log"))
      (relate "negatives" "shows the pin can fail for" "identity" :observed nil '("phase-b-negative-5a4a668.log" "phase-b-negative-old-b2eecffa-snapshot.log" "phase-b-negative-unverifiable.log"))
      (relate "nix" "exercises" "snapshot" :observed (list (claim "nix-contract-darwin")) '("phase-b-nix-package-check.log")
              "x86_64-darwin only; the same check on Linux is open.")
      (relate "guard" "still refuses" "project" :observed (list #'c:refuse-project-workspace #'c:verify-startup) '("phase-b-snapshot-suites.log")
              "Its wording changed with the pin; its behaviour did not.")
      (relate "zettel" "wishes for" "p-work-item" :observed (list (record "zettel-11359-excerpt.md")) '("zettel-11359-excerpt.md") "The note says it; it declares nothing.")
      (relate "p-work-item" "would be implemented by (proposed)" "6162ed68" :proposed (list (claim "zettel-navigation-is-proposed")) '("zettel-11359-excerpt.md")
              "The Zettel's Source Change. No Work page or CTM declares this relation.")
      (relate "p-work-item" "would be evidenced by (proposed)" "review" :proposed (list (claim "zettel-navigation-is-proposed")) '("zettel-11359-excerpt.md")
              "The Zettel's Evidence: the independent review of Task 1C.")
      (relate "p-work-item" "would be read in the Project Workspace (proposed)" "project" :proposed (list (claim "zettel-navigation-is-proposed")) '("zettel-11359-excerpt.md")
              "The Zettel's CTM, TMDM, CXTM, Inspector chain: the Workspace reads the CTM as TMDM objects; this relation is the wish, not a declaration.")
      (relate "p-work-item" "would be shown deployable by (proposed)" "nix" :proposed (list (claim "zettel-navigation-is-proposed")) '("zettel-11359-excerpt.md")
              "The Zettel's Deployment Evidence: the Nix snapshot and runtime tests; the systemd and Linux parts are open.")
      (relate "p-packages" "is a separate proposal from" "p-work-item" :open nil nil
              "Whether the Zettel's steps become additions to the proposals of the earlier review, or declarations, is not decided here. Nothing was promoted.")
      (relate "b1" "changes the pins to" "6162ed68" :derived (list (boundary "1")) nil)
      (relate "b1" "makes version-bound" "contract" :derived (list (boundary "1") #'topic-maps-deployment-review::declared-paths-agree-p) nil)
      (relate "contract-run" "checks" "contract" :observed (list #'topic-maps-deployment-review::tested-files-match-at-p) '("phase-c-declared-paths-agree.txt"))
      (relate "b2" "depends on" "b1" :derived (list (boundary "2")) nil)
      (relate "b2" "binds the Workspace and changes" "identity" :derived (list (boundary "2") #'p::pinned-state-p) nil)
      (relate "b2" "keeps" "guard" :derived (list (boundary "2") #'c:refuse-project-workspace) nil "Only the guard's message changes.")
      (relate "b3" "depends on" "b2" :derived (list (boundary "3")) nil)
      (relate "b4" "depends on" "b3" :derived (list (boundary "4")) nil)
      (relate "browser-pw" "exercises" "project" :observed nil '("phase-c-project-workspace-browser.log" "phase-c-project-workspace-browser.json"))
      (relate "browser-pw" "runs in" "trusted" :observed (list (file-line "scripts/serve-project-workspace.lisp")) '("phase-c-project-workspace-browser.log"))
      (relate "trusted" "is not behind" "guard" :observed (list #'c:refuse-project-workspace #'c:main) '("phase-c-project-workspace-browser.log" "phase-b-nix-package-check.log")
              "The packaged executable still refuses dreyeck/work/project; the browser walk used a separate, trusted, loopback runtime.")
      (relate "open" "waits on" "guard" :derived nil nil "Admitting the Workspace to the served runtime is a separate decision."))
    (setf *subjects* (list :baseline baseline :reviewed reviewed :sibling sibling :ancestry ancestry :lineage lineage :manifest manifest))
    (make-instance 'integration-workspace
                   :projection (tm:make-topicmap-projection :topics (reverse topics) :associations (reverse associations)
                                                            :view-properties '(:width 2700 :height 1100))
                   :point "6162ed68")))

;;; Views

(defun warrant-rows (associations workspace)
  (v:html
    (:table :class "inspector-table"
     (:tr (:th "From") (:th "Relation") (:th "To") (:th "Known as") (:th "Provenance") (:th "Evidence"))
     (dolist (a associations)
       (flet ((label (id) (tm:topicmap-topic-label-of (tm:topicmap-projection-topic-by-id (tm:topicmap-workspace-projection-of workspace) id))))
         (v:html
           (:tr :class "topic-maps-integration-review-warrant" :data-association-id (tm:topicmap-association-id-of a)
            (:td (v:esc (label (tm:topicmap-association-from-of a))))
            (:td (v:object-ref a :select "Warrant" :display (tm:topicmap-association-type-of a)))
            (:td (v:esc (label (tm:topicmap-association-to-of a))))
            (:td (v:esc (string-downcase (association-class a))))
            (:td (dolist (p (association-provenance a)) (v:html (v:object-ref p) (:br))))
            (:td (if (association-evidence a)
                     (dolist (e (association-evidence a)) (v:html (v:object-ref e :select "Record") (:br)))
                     (v:esc (if (eq :derived (association-class a)) "none: derived from its provenance" "none")))))))))))

(defmethod tmi::render-workspace-point-editor ((workspace integration-workspace) topic)
  (let ((id (tm:topicmap-topic-id-of topic)))
    (v:html
      (:h3 "Why these relations hold")
      (warrant-rows (remove-if-not (lambda (a) (or (string= id (tm:topicmap-association-from-of a)) (string= id (tm:topicmap-association-to-of a))))
                                   (tm:topicmap-projection-associations-of (tm:topicmap-workspace-projection-of workspace)))
                    workspace))))

(v:defview integration-workspace-relations (workspace integration-workspace)
  (v:html-view :title "Relations" :priority 5
    (v:html
      (:div :style "overflow-wrap:anywhere"
       (:h2 "Every relation and why it holds")
       (warrant-rows (tm:topicmap-projection-associations-of (tm:topicmap-workspace-projection-of workspace)) workspace)
       (reading-links)))))

(v:defview integration-association-view (a integration-association)
  (v:html-view :title "Warrant" :priority -10
    (let ((projection (tm:topicmap-workspace-projection-of (the-workspace))))
      (flet ((topic (id) (tm:topicmap-projection-topic-by-id projection id)))
        (v:html
          (:div :style "overflow-wrap:anywhere"
           (:h2 (v:esc (format nil "~A ~A ~A" (tm:topicmap-topic-label-of (topic (tm:topicmap-association-from-of a)))
                               (tm:topicmap-association-type-of a) (tm:topicmap-topic-label-of (topic (tm:topicmap-association-to-of a))))))
           (:p (:strong "Relation type: ") (v:esc (tm:topicmap-association-type-of a)) " · " (:strong "Known as: ") (v:esc (string-downcase (association-class a))))
           (:p "From " (v:object-ref (tm:topicmap-topic-object-of (topic (tm:topicmap-association-from-of a))) :display (tm:topicmap-topic-label-of (topic (tm:topicmap-association-from-of a))))
               " to " (v:object-ref (tm:topicmap-topic-object-of (topic (tm:topicmap-association-to-of a))) :display (tm:topicmap-topic-label-of (topic (tm:topicmap-association-to-of a)))))
           (when (association-note a) (v:html (:p (v:esc (association-note a)))))
           (:h3 "Provenance")
           (:ul (dolist (p (association-provenance a)) (v:html (:li (v:object-ref p)))))
           (:h3 "Evidence")
           (if (association-evidence a)
               (v:html (:ul (dolist (e (association-evidence a)) (v:html (:li (v:object-ref e :select "Record"))))))
               (v:html (:p (v:esc (if (eq :derived (association-class a)) "No recorded run: it is derived from its provenance." "No recorded run.")))))
           (reading-links)))))))
