;;;; The Deployment's Subjects and Their Warranted Relations
(in-package #:topic-maps-deployment-review)

;;; A Workspace over HyperDoc's own Topicmap protocol (dreyeck/topicmap), which depends on no Topic Maps revision. Each
;;; Topic stands for one real subject and holds the object it is: a Git revision, the snapshot, the manifest, an ASDF
;;; system, a Nix declaration, a startup function, a recorded run, a decision. Each relation is a warranted association:
;;; its relation type, its provenance (the definition or run that makes it hold), its evidence and how it is known.
;;; The coordinates are authored for this reading; nothing lays them out automatically.

;;; Revisions and the snapshot

(defun topic-maps-repository ()
  "The local Topic Maps repository, the authority for the commit; it is read, never written."
  (let ((root (uiop:ensure-directory-pathname (or (uiop:getenv "TOPIC_MAPS_REPOSITORY") "/Users/rgb/workspace/topic-maps/"))))
    (and (probe-file (merge-pathnames ".git" root)) root)))

(defclass source-revision ()
  ((commit :initarg :commit :reader revision-commit)
   (role :initarg :role :reader revision-role))
  (:documentation "A Topic Maps commit, read from the local repository when it is shown."))
(defmethod v:text-representation ((r source-revision)) (format nil "Topic Maps ~A" (subseq (revision-commit r) 0 8)))
(defun revision-git (revision &rest arguments)
  (let ((root (topic-maps-repository)))
    (and root (multiple-value-bind (out err code) (apply #'git:git-run-values root arguments)
                (declare (ignore err)) (and (zerop code) (string-right-trim '(#\Newline) out))))))

(defclass git-observation ()
  ((question :initarg :question :reader observation-question)
   (command :initarg :command :reader observation-command)
   (exit-code :initarg :exit-code :reader observation-exit-code)
   (answer :initarg :answer :reader observation-answer)
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

(defclass exported-snapshot ()
  ((manifest :initarg :manifest :reader snapshot-manifest)
   (archive :initarg :archive :reader snapshot-archive :documentation "The manifest's :archive plist.")
   (root :initarg :root :reader snapshot-root))
  (:documentation "The runtime snapshot exported from the commit: an archive outside both repositories, unpacked as a store path."))
(defmethod v:text-representation ((s exported-snapshot)) (format nil "Snapshot ~A" (getf (snapshot-archive s) :name)))
(defun manifest-archive (manifest)
  (with-open-file (in (snap:manifest-pathname manifest) :external-format :utf-8)
    (with-standard-io-syntax (let ((*read-eval* nil) (*package* (find-package :keyword))) (getf (read in) :archive)))))

;;; Decisions, runners and warranted associations

(defclass deployment-decision ()
  ((id :initarg :id :reader decision-id) (title :initarg :title :reader decision-title)
   (decision :initarg :decision :reader decision-text) (consequence :initarg :consequence :reader decision-consequence))
  (:documentation "A decision taken on the Phase A design on 2026-10-26, in the reviewer's own message; it is a record, not a claim."))
(defmethod v:text-representation ((d deployment-decision)) (format nil "~A: ~A" (decision-id d) (decision-title d)))

(defclass warranted-association (tm:topicmap-association)
  ((provenance :initarg :provenance :initform nil :reader association-provenance)
   (evidence :initarg :evidence :initform nil :reader association-evidence)
   (class :initarg :class :reader association-class)
   (note :initarg :note :initform nil :reader association-note))
  (:documentation "A Topicmap association that says why it holds."))
(defmethod v:text-representation ((a warranted-association))
  (format nil "~A ~A ~A" (tm:topicmap-association-from-of a) (tm:topicmap-association-type-of a) (tm:topicmap-association-to-of a)))

(defclass review-workspace (tm:topicmap-workspace) ()
  (:documentation "The editing space of this reading's subjects: Point, Go to, and the warrants of the relations at Point."))

(defvar *workspace* nil)
(defvar *subjects* nil)

(defun subject-object (id) (tm:topicmap-topic-object-of (tm:topicmap-projection-topic-by-id (tm:topicmap-workspace-projection-of (the-workspace)) id)))

(defun build-workspace ()
  (let* ((manifest (snap:find-snapshot-manifest c:+topic-maps-commit+))
         (b2eecffa (make-instance 'source-revision :commit c:+topic-maps-commit+ :role "the packaged Topic Maps commit"))
         (pin (make-instance 'source-revision :commit "5a4a66850403cdfe2755c6c88083a8e31af89628"
                                              :role "the Project Workspace's Topic Maps pin"))
         (ancestry (observe-ancestry (revision-commit pin) (revision-commit b2eecffa)))
         (snapshot (make-instance 'exported-snapshot :manifest manifest :archive (manifest-archive manifest)
                                                     :root (asdf:system-source-directory "topic-maps")))
         (decisions
           (list (make-instance 'deployment-decision :id "D1" :title "A separate package"
                                :decision "A separate hyperdoc-catalog-topic-maps package; the production Catalog package stays unchanged."
                                :consequence "nix/catalog.nix and scripts/catalog-main.lisp are untouched; a new flake attribute builds the variant.")
                 (make-instance 'deployment-decision :id "D2" :title "A content-addressed archive"
                                :decision "A small, immutable, content-addressed archive of b2eecffa without reports/, prepared and verified locally; nothing published yet."
                                :consequence "nix/topic-maps-source.nix pins its NAR hash; its release URL does not exist yet.")
                 (make-instance 'deployment-decision :id "D3" :title "An independent Linux builder"
                                :decision "Build on an independent x86_64-linux builder after checking its configuration and capacity; never on the production server while its disk is uncertain."
                                :consequence "Nothing has been built for Linux.")
                 (make-instance 'deployment-decision :id "D4" :title "No push"
                                :decision "Do not push dreyeck.ch; prepare a candidate with exact revisions and evidence."
                                :consequence "The candidate is uncommitted in the working tree.")
                 (make-instance 'deployment-decision :id "D5" :title "Loopback-only staging"
                                :decision "Loopback-only staging; no public plain v:thunk buttons; no change to proxy, service or authority policy."
                                :consequence "The executable refuses any host but 127.0.0.1 and ::1.")))
         (topics nil) (associations nil) (counter 0))
    (labels ((topic (id label kind status object x y)
               (push (tm:make-topicmap-topic :id id :type kind :label label :object object
                                             :view-properties (list :x x :y y :visible t :pinned t :kind kind :status status))
                     topics))
             (relate (from type to class provenance evidence &optional note)
               (push (make-instance 'warranted-association :id (format nil "r~2,'0D" (incf counter)) :type type :from from :to to
                                                           :properties nil :class class :provenance provenance
                                                           :evidence (mapcar #'evidence evidence) :note note)
                     associations)))
      ;; Revisions, snapshot, manifest, verification
      (topic "b2eecffa" "Topic Maps b2eecffa" "source revision" "local repository" b2eecffa 380 40)
      (topic "5a4a668" "Topic Maps 5a4a668" "source revision" "Project Workspace pin" pin 1180 40)
      (topic "snapshot" "Runtime snapshot" "exported snapshot" "1l6im929…-source" snapshot 380 200)
      (topic "manifest" "Snapshot manifest" "verification evidence" "nix/ in the candidate" manifest 700 120)
      (topic "archive-verification" "Archive verification" "verification evidence" "recorded run" (evidence "archive-verification.json") 40 120)
      (topic "lisp-verifier" "Lisp snapshot verifier" "verification evidence" "run on request" (the-verification-runner) 700 280)
      ;; ASDF
      (topic "asdf-ctm" "topic-maps/ctm" "ASDF system" "from the snapshot" (asdf:find-system "topic-maps/ctm") 380 360)
      (topic "asdf-snapshot" "dreyeck/source-snapshot" "ASDF system" "candidate" (asdf:find-system "dreyeck/source-snapshot") 1000 280)
      (topic "asdf-project" "dreyeck/work/project" "ASDF system" "refused, not loaded" (asdf:find-system "dreyeck/work/project") 1180 200)
      (topic "asdf" (format nil "ASDF ~A" (asdf:asdf-version)) "ASDF system" "methods unchanged by the guard" (asdf:find-system "asdf") 1300 360)
      ;; Nix and startup
      (topic "nix-variant" "hyperdoc-catalog-topic-maps" "Nix package" "candidate" (excerpt "flake:variant") 380 520)
      (topic "nix-production" "hyperdoc-catalog" "Nix package" "unchanged" (excerpt "flake:production") 1000 600)
      (topic "candidate" "The candidate (43 files)" "working-tree candidate" "uncommitted" (the-candidate) 700 440)
      (topic "startup" "Catalog startup" "Catalog startup policy" "loopback only" #'c:main 380 680)
      (topic "guard" "Project Workspace guard" "Catalog startup policy" "refuses at startup" (the-guard-trial) 1000 440)
      ;; Test executions
      (topic "test-package" "Package contract" "test execution" "recorded, darwin" (evidence "package-check/lisp.log") 40 600)
      (topic "test-executable" "Executable contract" "test execution" "recorded, darwin" (evidence "package-check/executable.log") 40 760)
      (topic "test-production" "Production startup check" "test execution" "recorded, darwin" (evidence "production-check.log") 1000 760)
      (topic "test-unchanged" "Derivation comparison" "test execution" "evaluated, linux and darwin" (evidence "catalog-unchanged-x86_64-linux.json") 1300 600)
      (topic "test-browser" "Review in a browser (snapshot)" "test execution" "recorded" (evidence "browser-review-snapshot.json") 40 440)
      (topic "test-controls" "Archive verifier controls" "test execution" "recorded" (evidence "archive-controls.log") 40 280)
      (topic "linux" "x86_64-linux build" "test execution" "built and checked in a local builder" (claim "linux-unbuilt") 700 760)
      ;; Decisions
      (loop for decision in decisions for y from 40 by 150
            do (topic (decision-id decision) (format nil "~A ~A" (decision-id decision) (decision-title decision))
                      "deployment decision" "2026-10-26" decision 1540 y))
      ;; Relations
      (relate "snapshot" "exported from" "b2eecffa" :observed (list (excerpt "snapshot:create")) '("archive-verification.json"))
      (relate "manifest" "records the Git objects of" "b2eecffa" :observed (list (file-named "nix/topic-maps-b2eecffa.manifest")) '("archive-verification.json"))
      (relate "manifest" "pins by NAR hash" "snapshot" :observed (list (excerpt "nix:source")) '("archive-verification.json"))
      (relate "archive-verification" "verifies" "snapshot" :observed (list (file-named "scripts/topic-maps-snapshot.py")) '("archive-verification.json"))
      (relate "test-controls" "shows it can fail" "archive-verification" :observed (list (file-named "tests/test_topic_maps_snapshot.py")) '("archive-controls.log"))
      (relate "lisp-verifier" "verifies against the manifest" "snapshot" :observed (list #'snap:verify-snapshot-tree #'snap:verify-store-snapshot)
              '("package-check/lisp.log" "checkout-source-snapshot.log" "mutants.log"))
      (relate "asdf-snapshot" "defines" "lisp-verifier" :derived (list (excerpt "asd:source-snapshot")) nil)
      (relate "asdf-ctm" "is loaded from" "snapshot" :observed (list #'c:topic-maps-origins (excerpt "topic-maps.asd:ctm"))
              '("package-check/lisp.log" "package-check/topic-maps-asd") "This reading's own image loads it from there too: see Where ASDF Finds the Sources.")
      (relate "nix-variant" "puts in its ASDF registry" "snapshot" :observed (list (excerpt "nix:wrapper") (excerpt "nix:source")) '("package-check/topic-maps-asd"))
      (relate "nix-variant" "starts with" "startup" :derived (list (excerpt "nix:wrapper") (excerpt "main:host")) nil)
      (relate "startup" "runs" "guard" :observed (list #'c:main #'c:verify-startup) '("after-guard-correction/contract-lisp.log"))
      (relate "guard" "refuses" "asdf-project" :observed (list #'c:refuse-project-workspace (excerpt "startup:guard") (excerpt "asd:catalog-topic-maps"))
              '("after-guard-correction/executable.log" "after-guard-correction/contract-lisp.log"))
      (relate "asdf-project" "is bound to" "5a4a668" :derived (list (excerpt "workspace:pin")) nil)
      (relate "guard" "once replaced two methods of" "asdf" :observed (list (method-origins) (excerpt "startup:guard-methods")) nil
              "Historical: the first version of the guard, recorded by the collision probe. Asked of this image by the Method origins view, which now says ASDF's own.")
      (relate "guard" "adds no method to" "asdf" :observed (list (method-origins) (excerpt "startup:guard")) '("after-guard-correction/asdf-methods.log")
              "A fresh-process test compares ASDF's method objects before and after loading the corrected guard.")
      (relate "5a4a668" (if (eq :no (observation-answer ancestry)) "is not an ancestor of" "ancestry not established with") "b2eecffa"
              (if (member (observation-answer ancestry) '(:yes :no)) :observed :open) (list ancestry) nil
              "Git's answer when these subjects were projected.")
      (relate "candidate" "declares" "nix-variant" :derived (list (excerpt "flake:variant")) nil)
      (relate "nix-production" "is unchanged, apart from HyperDoc's source, by" "candidate" :observed
              (list (excerpt "flake:production") (excerpt "nix:production-wrapper"))
              '("catalog-unchanged-x86_64-linux.json" "catalog-unchanged-x86_64-darwin.json" "catalog-control-changed-wrapper.json")
              "Evaluated; for Linux nothing was built.")
      (relate "test-production" "exercises" "nix-production" :observed nil '("production-check.log") "x86_64-darwin.")
      (relate "test-unchanged" "compares" "nix-production" :observed (list (file-named "scripts/compare-catalog-derivation.py"))
              '("catalog-unchanged-x86_64-linux.json" "catalog-unchanged-x86_64-darwin.json" "catalog-control-changed-wrapper.json"))
      (relate "test-package" "exercises" "nix-variant" :observed (list (excerpt "nix:check")) '("package-check/lisp.log" "package-check/nix-build.log"))
      (relate "test-executable" "exercises" "startup" :observed (list (file-named "tests/test_catalog_topic_maps_executable.py")) '("package-check/executable.log"))
      (relate "test-browser" "reads the CTM review from" "snapshot" :observed (list (file-named "scripts/test-topic-maps-ctm-review-browser.mjs"))
              '("browser-review-snapshot.json"))
      (relate "nix-variant" "is built and checked for" "linux" :observed (list (excerpt "nix:source") (file-named "nix/catalog-topic-maps-check.nix"))
              '("after-guard-correction/x86_64-linux/nix-build.log" "after-guard-correction/x86_64-linux/contract-lisp.log") "In a local Docker builder with the Nix sandbox off.")
      (relate "D1" "decides" "nix-variant" :observed (list (first decisions)) nil)
      (relate "D2" "decides" "snapshot" :observed (list (second decisions)) nil)
      (relate "D3" "is followed by" "linux" :observed (list (third decisions)) '("after-guard-correction/x86_64-linux/builder-and-snapshot.txt") "An independent builder that is not the production server.")
      (relate "D4" "keeps uncommitted" "candidate" :observed (list (fourth decisions)) nil)
      (relate "D5" "constrains" "startup" :observed (list (fifth decisions)) '("package-check/executable.log")))
    (setf *subjects* (list :revision b2eecffa :pin pin :ancestry ancestry :snapshot snapshot :decisions decisions))
    (make-instance 'review-workspace
                   :projection (tm:make-topicmap-projection :topics (reverse topics) :associations (reverse associations)
                                                            :view-properties '(:width 2000 :height 1000))
                   :point "candidate")))

(defun the-workspace () (or *workspace* (setf *workspace* (build-workspace))))

;;; Views

(defun warrant-rows (associations workspace)
  (v:html
    (:table :class "inspector-table"
     (:tr (:th "From") (:th "Relation") (:th "To") (:th "Known as") (:th "Provenance") (:th "Evidence"))
     (dolist (a associations)
       (flet ((label (id) (tm:topicmap-topic-label-of (tm:topicmap-projection-topic-by-id (tm:topicmap-workspace-projection-of workspace) id))))
         (v:html
           (:tr :class "topic-maps-deployment-review-warrant" :data-association-id (tm:topicmap-association-id-of a)
            (:td (v:esc (label (tm:topicmap-association-from-of a))))
            (:td (v:object-ref a :select "Warrant" :display (tm:topicmap-association-type-of a)))
            (:td (v:esc (label (tm:topicmap-association-to-of a))))
            (:td (v:esc (string-downcase (association-class a))))
            (:td (dolist (p (association-provenance a)) (v:html (v:object-ref p) (:br))))
            (:td (if (association-evidence a)
                     (dolist (e (association-evidence a)) (v:html (v:object-ref e :select "Record") (:br)))
                     (v:esc (if (eq :derived (association-class a)) "none: derived from its provenance" "none")))))))))))

(defmethod tmi::render-workspace-point-editor ((workspace review-workspace) topic)
  ;; At Point: why each of its relations holds. Navigation stays the generic Workspace's.
  (let ((id (tm:topicmap-topic-id-of topic)))
    (v:html
      (:h3 "Why these relations hold")
      (warrant-rows (remove-if-not (lambda (a) (or (string= id (tm:topicmap-association-from-of a)) (string= id (tm:topicmap-association-to-of a))))
                                   (tm:topicmap-projection-associations-of (tm:topicmap-workspace-projection-of workspace)))
                    workspace))))

(v:defview review-workspace-relations (workspace review-workspace)
  (v:html-view :title "Relations" :priority 5
    (v:html
      (:div :style "overflow-wrap:anywhere"
       (:h2 "Every relation and why it holds")
       (warrant-rows (tm:topicmap-projection-associations-of (tm:topicmap-workspace-projection-of workspace)) workspace)
       (reading-links)))))

(v:defview warranted-association-view (a warranted-association)
  (v:html-view :title "Warrant" :priority -10
    (let ((projection (tm:topicmap-workspace-projection-of (the-workspace))))
      (flet ((topic (id) (tm:topicmap-projection-topic-by-id projection id)))
        (v:html
          (:div :style "overflow-wrap:anywhere"
           (:h2 (v:esc (format nil "~A ~A ~A" (tm:topicmap-topic-label-of (topic (tm:topicmap-association-from-of a)))
                               (tm:topicmap-association-type-of a) (tm:topicmap-topic-label-of (topic (tm:topicmap-association-to-of a))))))
           (:p (:strong "Relation type: ") (v:esc (tm:topicmap-association-type-of a)) " · " (:strong "Known as: ")
               (v:esc (string-downcase (association-class a))))
           (:p "From " (v:object-ref (tm:topicmap-topic-object-of (topic (tm:topicmap-association-from-of a)))
                                     :display (tm:topicmap-topic-label-of (topic (tm:topicmap-association-from-of a))))
               " to " (v:object-ref (tm:topicmap-topic-object-of (topic (tm:topicmap-association-to-of a)))
                                    :display (tm:topicmap-topic-label-of (topic (tm:topicmap-association-to-of a)))))
           (when (association-note a) (v:html (:p (v:esc (association-note a)))))
           (:h3 "Provenance")
           (:ul (dolist (p (association-provenance a)) (v:html (:li (v:object-ref p)))))
           (:h3 "Evidence")
           (if (association-evidence a)
               (v:html (:ul (dolist (e (association-evidence a)) (v:html (:li (v:object-ref e :select "Record"))))))
               (v:html (:p (v:esc (if (eq :derived (association-class a)) "No recorded run: it is derived from its provenance." "No recorded run.")))))
           (reading-links)))))))

(v:defview source-revision-view (revision source-revision)
  (v:html-view :title "Revision" :priority -10
    (let ((commit (revision-commit revision)))
      (v:html
        (:div :style "overflow-wrap:anywhere"
         (:h2 (v:esc (format nil "Topic Maps ~A" commit)))
         (:p (v:esc (format nil "~@(~A~). Read from ~A when shown." (revision-role revision) (or (topic-maps-repository) "no local repository"))))
         (:p (v:esc (or (revision-git revision "log" "-1" "--format=%s (%ad, tree %T)" "--date=short" commit) "The commit is not in the local repository.")))
         (:p (v:esc (format nil "Branches holding it: ~A" (or (revision-git revision "branch" "--format=%(refname:short)" "--contains" commit) "none"))))
         (reading-links))))))

(v:defview git-observation-view (o git-observation)
  (v:html-view :title "Git answer" :priority -10
    (v:html
      (:h2 (v:esc (observation-question o)))
      (:p (:code (v:esc (format nil "~{~A~^ ~}" (observation-command o)))) (v:esc (format nil " in ~A" (topic-maps-repository))))
      (:p (v:esc (format nil "Exit status ~A, so: ~(~A~). Asked at ~A (universal time), when the subjects were projected."
                         (observation-exit-code o) (observation-answer o) (observation-at o))))
      (reading-links))))

(v:defview exported-snapshot-view (s exported-snapshot)
  (v:html-view :title "Snapshot" :priority -10
    (let ((archive (snapshot-archive s)) (manifest (snapshot-manifest s)))
      (v:html
        (:div :style "overflow-wrap:anywhere"
         (:h2 "The runtime snapshot of Topic Maps b2eecffa")
         (:p (v:esc (format nil "Archive ~A, ~D octets, SHA-256 ~A. It is in neither repository and is not published."
                            (getf archive :name) (getf archive :octets) (getf archive :sha256))))
         (:p (v:esc (format nil "Unpacked, its NAR hash is ~A, the hash nix/topic-maps-source.nix pins. In this image ASDF loads Topic Maps from ~A, which is ~(~A~)."
                            (snap:manifest-nar-hash manifest) (namestring (snapshot-root s)) (snap:source-kind (snapshot-root s)))))
         (:p (v:esc (format nil "Excluded: ~{~A/~^, ~}, named by its tree id and not shipped." (snap:manifest-excluded manifest))))
         (:p (v:object-ref manifest :display "The manifest") " · " (v:object-ref (the-verification-runner) :display "Verify it now")
             " · " (v:object-ref (evidence "archive-verification.json") :select "Record" :display "How the archive was checked against the commit"))
         (reading-links))))))

(v:defview deployment-decision-view (d deployment-decision)
  (v:html-view :title "Decision" :priority -10
    (v:html
      (:h2 (v:esc (format nil "~A: ~A" (decision-id d) (decision-title d))))
      (:p (v:esc (decision-text d)))
      (:p (:em "In this candidate: ") (v:esc (decision-consequence d)))
      (:p "Taken by the reviewer on 2026-10-26, on the Phase A design.")
      (reading-links))))
