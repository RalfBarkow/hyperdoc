(in-package #:topic-maps-deployment-review/tests)

;;; The proposed project work: read from its two files only, read as the emitter reads it, kept apart in its four questions,
;;; covering the candidate's files, rendered without effect, and navigable from its pages to the objects.

(defparameter +proposal-pages+ '("The Proposed Deployment WBS" "The Six Open Decisions" "Promoting the Proposals"))
(defparameter +declaration-files+ '("dreyeck.asd" "flake.nix")
  "The candidate files that declare parts of two work packages: one system or package each.")

(defun %replace (text old new)
  (let ((at (search old text))) (assert at () "~S not in the text" old) (concatenate 'string (subseq text 0 at) new (subseq text (+ at (length old))))))

(defun proposal-page-links (title)
  "Like PAGE-LINKS, but a page link is (title hyperbook-or-nil)."
  (let ((text (uiop:read-file-string (asdf:system-relative-pathname "topic-maps-deployment-review" (format nil "pages/~A.html" title))))
        (page-refs nil))
    (loop for start = (search "<a page=\"" text) then (search "<a page=\"" text :start2 (1+ start)) while start
          do (let* ((from (+ start 9)) (to (position #\" text :start from)) (tag-end (position #\> text :start to))
                    (book-at (search "hyperbook=\"" text :start2 to :end2 tag-end)))
               (push (list (subseq text from to) (and book-at (subseq text (+ book-at 11) (position #\" text :start (+ book-at 11))))) page-refs)))
    (values (page-links title) (reverse page-refs))))

(defun run-proposal-tests ()
  (let* ((*checks* nil) (p (r::the-proposals)) (topics (r::proposals-topics p)) (statements (r::proposals-statements p))
         (record (r::crosscheck-record)) (emitter (getf record :with-proposals))
         (workspace (r::the-proposal-workspace)) (projection (tm:topicmap-workspace-projection-of workspace)))
    (flet ((ids (kind) (mapcar #'r::proposal-id (remove kind topics :key #'r::proposal-kind :test-not #'equal)))
           (of (relation) (remove relation statements :key (lambda (s) (r::relation-name (r::statement-relation s))) :test-not #'string=)))
      ;; Read from the proposal files only; the Work reader reads no declaration from them, though it reads the plan page's.
      (check :sources-are-the-proposal-files
             (every (lambda (s) (and (r::review-reading-path-p (r::proposal-source-path s)) (equal (r::proposal-source-sha256 s) (r::proposal-source-sha256-now s))))
                    (r::proposal-sources)))
      (check :work-reader-reads-no-declaration (null (r::work-topics-read (r::proposal-source-text (r::proposal-source :addition)))))
      (check :work-reader-positive-control (< 10 (length (r::work-topics-read (r::plan-page-text)))))
      ;; As the emitter reads them: its record is of these files, made with the pinned revision, refused nothing, changed nothing.
      (check :crosscheck-of-these-files (r::crosscheck-of-these-files-p record))
      (check :crosscheck-with-the-pinned-revision
             (and (getf (getf record :topic-maps) :pinned) (equal "5a4a66850403cdfe2755c6c88083a8e31af89628" (getf (getf record :topic-maps) :commit))))
      (check :crosscheck-not-refused (null (getf emitter :refused)))
      (check :crosscheck-changed-nothing (every (lambda (k) (getf (getf record :unchanged) k)) '(:tree :retained-ctm :source-pages)))
      (check :crosscheck-baseline-is-the-retained-ctm (getf (getf record :baseline) :ctm-equals-retained))
      (check :crosscheck-retained-ctm-is-the-file (equal (getf (getf record :inputs) :retained-ctm-sha256)
                                                         (r::sha256-hex (r::octets-of (r::root-path "dreyeck/work/project/hyperdoc-project.ctm")))))
      (check :appending-would-change-the-ctm (not (getf emitter :ctm-equals-retained)))
      (check :nothing-declared-by-the-emitter (null (getf emitter :declared-tmd)))
      (dolist (row (r::reader-agreement record)) (check (intern (format nil "READERS-AGREE-ON-~A" (first row)) :keyword) (second row)))
      ;; Positive controls: one changed statement disagrees with the record, and a record of other files is recognized as such.
      (let* ((source (r::proposal-source :addition))
             (altered (make-instance 'r::proposal-source :key :addition :title "altered" :path (r::proposal-source-path source) :promotion ""
                                                         :sha256 "0" :text (%replace (r::proposal-source-text source)
                                                                                     "data-proposed-from=\"tmd-p2\" data-proposed-relation=\"work:relation/depends-on\" data-proposed-to=\"tmd-p1\""
                                                                                     "data-proposed-from=\"tmd-p2\" data-proposed-relation=\"work:relation/depends-on\" data-proposed-to=\"tmd-p3\""))))
        (multiple-value-bind (topics* statements* assignments*) (r::read-addition altered)
          (let ((r::*proposals* (make-instance 'r::deployment-proposals :topics topics* :statements statements* :assignments assignments*
                                                                        :entries (r::proposals-entries p) :evidence (r::proposals-evidence p))))
            (check :control-changed-statement-disagrees
                   (equal '((:proposals t) (:proposed-statements nil)) (mapcar (lambda (row) (list (first row) (second row))) (subseq (r::reader-agreement record) 0 2))))))
        (let ((other (copy-list record)))
          (setf (getf other :inputs) (list* :addition-sha256 (make-string 64 :initial-element #\0) (getf record :inputs)))
          (check :control-record-of-other-files (not (r::crosscheck-of-these-files-p other)))))
      ;; The page's two quantitative statements about the cross-check hold.
      (let* ((retained (uiop:read-file-string (r::root-path "dreyeck/work/project/hyperdoc-project.ctm") :external-format :utf-8))
             (ratio (/ (getf emitter :ctm-characters) (length retained))))
        (check :ctm-nearly-twice (< 3/2 ratio 2)))
      (check :thirteen-gaps (= 13 (length (getf emitter :gaps))))
      (check :every-proposed-package-gets-acceptance-requires-declaration
             (equal (sort (ids "work package") #'string<)
                    (sort (mapcar #'second (remove "acceptance-requires-declaration" (getf emitter :gaps) :key #'first :test-not #'equal)) #'string<)))
      ;; Four questions kept apart: each relation connects only what its contract allows.
      (flet ((kind (id) (r::proposal-kind (r::proposed-topic id))))
        (check :decomposition-within-the-wbs
               (every (lambda (s) (and (equal "deliverable" (kind (r::statement-from s))) (member (kind (r::statement-to s)) '("deliverable" "work package") :test #'equal)))
                      (of "decomposes into")))
        (check :production-from-steps-to-packages
               (every (lambda (s) (and (equal "plan step" (kind (r::statement-from s))) (equal "work package" (kind (r::statement-to s))))) (of "produces")))
        (check :dependency-among-steps-and-preconditions
               (every (lambda (s) (and (equal "plan step" (kind (r::statement-from s))) (member (kind (r::statement-to s)) '("plan step" "precondition") :test #'equal)))
                      (of "depends on"))))
      (check :only-three-relation-types (= (length statements) (+ (length (of "decomposes into")) (length (of "produces")) (length (of "depends on")))))
      ;; The breakdown: one root, every package reached from it, packages are the leaves, every leaf has one draft entry.
      (let ((root (r::proposed-topic "tmd-deployment")))
        (labels ((leaves (topic) (let ((children (r::wbs-children (r::proposal-id topic)))) (if children (mapcan #'leaves children) (list topic)))))
          (check :one-root (equal (list root) (remove-if (lambda (d) (r::wbs-parent (r::proposal-id d))) (remove "deliverable" topics :key #'r::proposal-kind :test-not #'equal))))
          (check :hundred-percent (equal (sort (mapcar #'r::proposal-id (leaves root)) #'string<) (sort (ids "work package") #'string<)))))
      (check :one-entry-per-package (equal (sort (mapcar #'r::entry-id (r::proposals-entries p)) #'string<) (sort (ids "work package") #'string<)))
      (check :no-entry-for-summary-elements (notany #'r::proposed-entry (ids "deliverable")))
      (check :exclusions-in-every-scope (every (lambda (e) (search "Excluded:" (r::entry-field e "scope"))) (r::proposals-entries p)))
      ;; The plan: every step produces one package, every package is produced, every precondition is waited on, no cycle.
      (check :each-step-produces-one (every (lambda (id) (= 1 (length (r::step-products id)))) (ids "plan step")))
      (check :each-package-produced (every #'r::produced-by (ids "work package")))
      (check :each-precondition-waited-on (every #'r::step-dependents (ids "precondition")))
      (check :plan-acyclic
             (let ((state (make-hash-table :test #'equal)))
               (labels ((visit (id) (case (gethash id state) (:active nil) (:done t)
                                      (t (setf (gethash id state) :active)
                                         (prog1 (every #'visit (mapcar #'r::proposal-id (r::step-dependencies id))) (setf (gethash id state) :done))))))
                 (every #'visit (ids "plan step")))))
      ;; Implementation objects: every program and test file of the candidate is named by a package's effect, the shared ones
      ;; are exactly the two declaration files; every named path exists.
      (let* ((programs
               ;; The proposals were written against the candidate of 2026-10-26: the files its first tested-files record lists. The
               ;; files added since (the ASDF preservation test, the staging module) are not in the proposals, which are not edited here.
               (with-open-file (in (r::root-path "docs/topic-maps-deployment/evidence/tested-files-sha256.txt"))
                 (loop for line = (read-line in nil) while line collect (subseq line 66))))
             (named (loop for e in (r::proposals-entries p) append (r::entry-effect-paths e))))
        (check :every-program-file-in-a-package (every (lambda (f) (member f named :test #'string=)) programs))
        (check :shared-files-are-the-declaration-files
               (equal (sort (remove-duplicates (remove-if-not (lambda (f) (< 1 (count f named :test #'string=))) named) :test #'string=) #'string<)
                      (sort (copy-list +declaration-files+) #'string<)))
        (check :every-named-path-exists (every (lambda (f) (probe-file (r::root-path f))) named)))
      ;; Controls: an existing control's marker is in its test now; a planned one names no test.
      (dolist (e (r::proposals-entries p))
        (dolist (c (r::entry-controls e))
          (if (equal "planned" (r::control-coverage c))
              (check :planned-control-names-no-test (null (r::control-test c)))
              (check :existing-control-marker-present (r::control-marker-present-p c)))))
      (check :asdf-preservation-is-planned
             (equal "planned" (r::control-coverage (find "tmd-asdf-methods-preserved" (r::entry-controls (r::proposed-entry "tmd-wp-2-3")) :key #'r::control-id :test #'equal))))
      ;; Evidence: execution reports carry every run fact; each names its record; none is an acceptance.
      (dolist (e (r::proposals-evidence p))
        (when (r::execution-report-p e)
          (check :execution-report-complete
                 (every (lambda (k) (r::evidence-fact e k)) '(:data-test :data-repository :data-revision :data-tree :data-content :data-observation :data-observed-at)))
          (check :execution-report-test-exists (probe-file (r::root-path (r::evidence-fact e :data-test)))))
        (when (or (r::execution-report-p e) (search "record " (r::proposal-text e)))
          (check :evidence-names-its-record (r::evidence-records e))))
      (let ((probe (r::assignment-evidence "tmd-run-asdf-collision-probe")) (entry (r::proposed-entry "tmd-wp-2-3")))
        (check :probe-report-derived-for-2-3-by-its-content (and (member probe (r::content-naming-runs entry)) (not (member probe (r::reported-runs entry)))))
        (check :probe-report-is-evidence-of-the-review (member probe (r::delivering-evidence "tmd-wp-3"))))
      (check :package-contract-run-derived-for-2-1 (member (r::assignment-evidence "tmd-run-package-contract") (r::reported-runs (r::proposed-entry "tmd-wp-2-1"))))
      (check :no-acceptance-anywhere
             (every (lambda (a) (search "No acceptance by the user is recorded" (r::assignment-field a "acceptance"))) (r::proposals-assignments p)))
      ;; Rendering the pages and every view of every proposal object runs, writes and loads nothing.
      (let ((git-before (git-state)) (loaded-before (asdf:already-loaded-systems)) (point (tm:topicmap-workspace-point-of workspace)))
        (dolist (title +proposal-pages+) (render-all (r:review-page title)))
        (render-all (r:review-page "Deploying Topic Maps with HyperDoc"))
        (dolist (object (append (list p workspace (r::the-emitter-crosscheck) (r::work-reader-check)) (r::proposal-sources)
                                topics statements (r::proposals-assignments p) (r::proposals-entries p) (r::proposals-evidence p)
                                (r::model-excerpts) (tm:topicmap-projection-associations-of projection)))
          (render-all object))
        (check :proposal-rendering-writes-nothing (equal git-before (git-state)))
        (check :proposal-rendering-loads-nothing (and (equal loaded-before (asdf:already-loaded-systems)) (null (project-packages))
                                                      (not (asdf:component-loaded-p "dreyeck/work/project"))))
        (check :rendering-leaves-point (equal point (tm:topicmap-workspace-point-of workspace))))
      (check :every-acceptance-section-says-none
             (every (lambda (x) (search "No acceptance record." (html x "Proposal"))) topics))
      (check :model-excerpts-found (every #'r:excerpt-text (r::model-excerpts)))
      ;; Every link of the three pages reaches its object and view; page links reach their pages, here or in their HyperBook.
      (let ((linked nil))
        (dolist (title +proposal-pages+)
          (multiple-value-bind (exprs page-refs) (proposal-page-links title)
            (dolist (link exprs)
              (destructuring-bind (expression view-title) link
                (let ((object (evaluate expression)))
                  (push object linked)
                  (check :proposal-link-object object)
                  (when view-title (check :proposal-link-view (view object view-title))))))
            (dolist (ref page-refs)
              (destructuring-bind (page book) ref
                (check :proposal-page-link (if book
                                               (hyperbook:find-page (hyperbook:find-hyperbook book :signal-error? t) page :signal-error? nil)
                                               (r:review-page page)))))))
        (check :decisions-reach-the-constraints
               (every (lambda (key) (member (r::model-excerpt key) linked :test #'eq))
                      '("ia:proposal-rule" "emitter:sources" "tests:determinism" "emitter:texts-extra" "acceptance:d5")))
        (check :pages-reach-native-readers (and (member #'dreyeck/work/ctm-page-authoring::read-wbs-dictionary linked :test #'eq)
                                                (member #'r::read-addition linked :test #'eq))))
      ;; The Workspace: every proposal and assignment a Topic holding its object, at an authored position; every relation stated.
      (check :workspace-topics-hold-the-objects
             (every (lambda (x) (eq x (tm:topicmap-topic-object-of (tm:topicmap-projection-topic-by-id projection (r::proposal-id x))))) topics))
      (check :workspace-relations-are-statements-or-references
             (every (lambda (a) (and (typep a 'r::proposal-association)
                                     (tm:topicmap-projection-topic-by-id projection (tm:topicmap-association-from-of a))
                                     (tm:topicmap-projection-topic-by-id projection (tm:topicmap-association-to-of a))
                                     (if (eq :proposed (r::association-standing a))
                                         (member (r::association-statement a) statements :test #'eq)
                                         (typep (r::association-statement a) 'r::proposal-assignment))))
                    (tm:topicmap-projection-associations-of projection)))
      (tm:topicmap-workspace-go-to workspace "tmd-wp-2-3")
      (let ((text (html workspace "Topicmap")) (references (refs workspace "Topicmap")))
        (check :point-at-2-3-keeps-the-questions-apart
               (every (lambda (heading) (search heading text)) '("WBS decomposition" "Plan" "Evidence reported by assignments" "Acceptance")))
        (check :point-at-2-3-reaches-entry-and-steps
               (and (member (r::proposed-entry "tmd-wp-2-3") references :test #'eq) (member (r::proposed-topic "tmd-p5") references :test #'eq)
                    (member (r:file-named "dreyeck/src/catalog-topic-maps.lisp") references :test #'eq))))
      (tm:topicmap-workspace-go-to workspace "tmd-deployment"))
    (format t "~&TOPIC-MAPS-DEPLOYMENT-REVIEW-PROPOSALS-PASS: ~D assertions; ~D proposed Topics, ~D proposed statements, ~D assignments, ~D evidence entries, ~D draft entries, the emitter's reading agreed.~%"
            (length *checks*) (length (r::proposals-topics (r::the-proposals))) (length (r::proposals-statements (r::the-proposals)))
            (length (r::proposals-assignments (r::the-proposals))) (length (r::proposals-evidence (r::the-proposals))) (length (r::proposals-entries (r::the-proposals))))
    t))
