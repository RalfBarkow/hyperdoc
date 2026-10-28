;;;; Recorded Evidence and Claims: what ran, when, and how each statement is known
(in-package #:topic-maps-integration-review)

(defparameter +book-id+ "topic-maps-integration-review")
(defparameter +reviewed-commit+ "6162ed68c94ea4796b8cf2282edd347d9607b08c"
  "Task 1C: b2eecffa plus the indexed search for the next Topic merge, independently reviewed and committed locally on 2026-10-28.")
(defparameter +baseline-commit+ "b2eecffa05de4fce41c10ae1ada9ae11a0c6e7dc" "The Topic Maps commit HyperDoc packaged until this integration.")
(defparameter +sibling-commit+ "5a4a66850403cdfe2755c6c88083a8e31af89628" "The Project Workspace's earlier pin: a sibling of b2eecffa on 963f2a0, not an ancestor.")

(defun review-page (title) (hyperbook:find-page +book-id+ title :signal-error? t))
(defun reading-root () (asdf:system-source-directory "topic-maps-integration-review"))
(defun evidence-pathname (file) (merge-pathnames (concatenate 'string "evidence/" file) (reading-root)))

;;; A record is one file of this reading's evidence/ directory: a run's log, a review, a summary. Showing it reads the file and
;;; checks it against evidence/SHA256SUMS; it runs nothing.

(defclass record ()
  ((file :initarg :file :reader record-file)
   (title :initarg :title :reader record-title)
   (kind :initarg :kind :reader record-kind :documentation ":independent (the 2026-10-28 review), :task1c (the committed change's own evidence) or :integration (this step).")
   (when :initarg :when :reader record-when)
   (procedure :initarg :procedure :reader record-procedure :documentation "Objects: functions and text saying what produced the file.")
   (patterns :initarg :patterns :reader record-patterns :documentation "Substrings that mark the lines stating an outcome.")))
(defmethod v:text-representation ((r record)) (record-title r))

(defun record-text (record) (uiop:read-file-string (evidence-pathname (record-file record)) :external-format :utf-8))
(defun record-sha256 (record)
  (ironclad:byte-array-to-hex-string (ironclad:digest-file :sha256 (evidence-pathname (record-file record)))))
(defun recorded-sha256 (file)
  "The digest evidence/SHA256SUMS states for FILE, or NIL."
  (with-open-file (in (evidence-pathname "SHA256SUMS") :external-format :utf-8)
    (loop for line = (read-line in nil) while line
          when (and (> (length line) 66) (string= file (string-left-trim "* " (subseq line 64)))) return (subseq line 0 64))))
(defun record-intact-p (record) (equal (record-sha256 record) (recorded-sha256 (record-file record))))
(defun record-outcomes (record)
  (remove-if-not (lambda (line) (some (lambda (pattern) (search pattern line)) (record-patterns record)))
                 (uiop:split-string (record-text record) :separator '(#\Newline))))

(defvar *records* nil)
(defun records ()
  (or *records*
      (setf *records*
            (flet ((rec (file title kind when procedure patterns)
                     (make-instance 'record :file file :title title :kind kind :when when :procedure procedure :patterns patterns)))
              (list
               (rec "independent-review.md" "The independent review (GO)" :independent "2026-10-28"
                    '("A separate reviewer's reconstruction of baseline, candidate and experimental trees, fresh processes, own checks.")
                    '("GO for" "Observed." "Derived."))
               (rec "independent-suite-and-mutation-results.json" "Independent suite and mutation results" :independent "2026-10-28"
                    '("Full suite on baseline and candidate; focused suite; mutants M0-M8, rerun by the reviewer.") '("KILLED" "SURVIVED" "suite"))
               (rec "independent-semantic-checks.log" "Independent semantic supplement (77 checks)" :independent "2026-10-28"
                    '("The reviewer's own tests: the nine identifier-kind combinations, case, first partner, six reifiable kinds, retained handles.") '("PASS" "FAIL" "CHECKS"))
               (rec "independent-shadow-reproduction.log" "Independent shadow reproduction" :independent "2026-10-28"
                    '("The whole corpus read with the old pairwise search shadowing the index at 18 sampled searches.") '("SHADOW" "mismatch"))
               (rec "independent-bench-baseline-timeout.json" "Independent benchmark: b2eecffa times out" :independent "2026-10-28"
                    '("Unmodified b2eecffa, SBCL 2.6.4, 120-second limit.") '("returncode" "read_wall"))
               (rec "independent-bench-candidate.json" "Independent benchmark: Task 1C, SBCL 2.6.4" :independent "2026-10-28"
                    '("Three fresh processes on the unchanged project CTM.") '("read_wall" "equals_5a"))
               (rec "independent-bench-candidate-nix.json" "Independent benchmark: Task 1C, packaged SBCL 2.4.10" :independent "2026-10-28"
                    '("One fresh process.") '("read_wall" "equals_5a"))
               (rec "independent-bench-reference.json" "Independent benchmark: 5a4a668 reference" :independent "2026-10-28"
                    '("The sibling lineage, exported by the reviewer.") '("read_wall" "equals_5a"))
               (rec "independent-bench-experimental.json" "EXPERIMENTAL, not Task 1C: candidate + association index" :independent "2026-10-28"
                    '("Measured by the reviewer; not committed and not part of this integration.") '("read_wall" "equals_5a"))
               (rec "task1c-commit-record.md" "The Task 1C commit record" :task1c "2026-10-28"
                    '("The commit 6162ed68, its tree and parent, and the checks made before and after committing.") '("Commit:" "Tree:" "Parent:" "Verified"))
               (rec "task1c-evidence-correspondence.txt" "Evidence matches the candidate bytes" :task1c "2026-10-27"
                    '("shasum -c against the manifest, git diff against the saved patches, file times, the suite re-run.") '("OK" "identical" "PASS"))
               (rec "task1c-mutation-results.txt" "Mutation controls" :task1c "2026-10-27"
                    '("Eight mutants of next-topic-merge in a throwaway image, each of which the new suite must kill.") '("KILLED" "SURVIVED"))
               (rec "task1c-corpus-search-counts.txt" "The corpus never merges two Topics" :task1c "2026-10-27"
                    '("7,511 searches while reading the project CTM; none finds a pair.") '("SHADOW-RESULT"))
               (rec "phase-a-integration.txt" "Phase A: fast-forward of the Topic Maps branch" :integration "2026-10-28"
                    '("git merge --ff-only in /Users/rgb/workspace/topic-maps, then the full suite with report files.") '("HEAD" "tree" "PASS" "identical" "exit"))
               (rec "snapshot-archive-verification.json" "The 6162ed68 archive verified against the commit" :integration "2026-10-28"
                    (list "scripts/topic-maps-snapshot.py verify: Git and Nix, independent of the Lisp verifier.") '("\"success\"" "\"files\"" "\"narHash\"" "\"commit\"" "\"excluded\""))
               (rec "phase-b-snapshot-suites.log" "Snapshot verifier, 22U reading and CTM review on the 6162ed68 snapshot" :integration "2026-10-28"
                    (list #'snap:verify-store-snapshot) '("PASS" "ASDF-ORIGIN"))
               (rec "phase-b-project-suite.log" "The Project Workspace suite on the integrated Git checkout" :integration "2026-10-28"
                    (list #'p::topic-maps-source-identity #'p:project-workspace) '("PASS" "ASDF-ORIGIN"))
               (rec "phase-b-workspace-git-checkout.log" "Project Workspace and original CTM: clean Git checkout of 6162ed68" :integration "2026-10-28"
                    (list #'p::topic-maps-source-identity) '("PIN-" "PROJECT-WORKSPACE" "WITHIN" "MODEL" "MAP" "TRACE" "CXTM" "PROJECTION" "NAVIGATION" "REVISION-FROM" "UNCHANGED" "PASS"))
               (rec "phase-b-workspace-git-checkout-under-load.log" "The same run while the machine was overloaded (161 s)" :integration "2026-10-28"
                    (list #'p::topic-maps-source-identity) '("PIN-" "PROJECT-WORKSPACE" "WITHIN" "REVISION-FROM" "load"))
               (rec "phase-b-workspace-verified-snapshot.log" "Project Workspace and original CTM: verified Git-free snapshot" :integration "2026-10-28"
                    (list #'p::topic-maps-source-identity #'snap:verify-store-snapshot) '("PIN-" "PROJECT-WORKSPACE" "WITHIN" "MODEL" "MAP" "TRACE" "CXTM" "PROJECTION" "NAVIGATION" "REVISION-FROM" "UNCHANGED" "PASS"))
               (rec "phase-b-negative-5a4a668.log" "Negative: the 5a4a668 checkout is not the pin" :integration "2026-10-28"
                    (list #'p::topic-maps-source-identity) '("PIN-" "IDENTITY"))
               (rec "phase-b-negative-old-b2eecffa-snapshot.log" "Negative: the b2eecffa snapshot does not verify as 6162ed68" :integration "2026-10-28"
                    (list #'p::topic-maps-source-identity #'snap:verify-store-snapshot) '("PIN-" "IDENTITY" ":REASON"))
               (rec "phase-b-negative-unverifiable.log" "Negative: a directory without .git outside /nix/store" :integration "2026-10-28"
                    (list #'p::topic-maps-source-identity) '("PIN-" "IDENTITY"))
               (rec "phase-b-benchmark-integrated.json" "CTM read on the integrated primary checkout (three fresh processes)" :integration "2026-10-28"
                    '("tools/bench.py of the Task 1C evidence; the unmodified Task 1B probe.") '("read_wall" "equals_5a4a668" "returncode"))
               (rec "phase-b-browser-reading.txt" "This reading served and navigated in a browser" :integration "2026-10-28"
                    '("An interactive check in the Claude desktop app's in-app browser; not a scripted test.") '("OBSERVED" "NOT DONE"))
               (rec "phase-c-declared-paths-agree.txt" "DECLARED-PATHS-AGREE: what it protects, why it failed, how it is bound now" :integration "2026-10-28"
                    (list #'topic-maps-deployment-review::declared-paths-agree-p #'topic-maps-deployment-review::tested-files-match-at-p #'topic-maps-deployment-review::unexpected-drift)
                    '("INTERPRETATION" "equal to the declaration" "differing from" "BEFORE" "AFTER" "PASS" "MUTANT" "KILLED"))
               (rec "phase-c-project-workspace-browser.log" "The Project Workspace in a browser: log of scripts/test-project-workspace.mjs" :integration "2026-10-28"
                    '("Fresh process; headless Chrome; the trusted review runtime scripts/serve-project-workspace.lisp; the original CTM; Topic Maps 6162ed68 as a clean Git checkout.") '("PASS" "object" "absent" "nothing written" "git status" "Runtime"))
               (rec "phase-c-project-workspace-browser.json" "The Project Workspace in a browser: result.json" :integration "2026-10-28"
                    '("Written by the same test on success.") '("status" "topicMaps" "runtime" "workBreakdownPageObject"))
               (rec "zettel-11359-excerpt.md" "Zettel 11359: the proposed navigation from a Work Item to its implementation" :integration "2026-10-28"
                    '("An excerpt (sections 1, 3 and 5) of the project owner's note, with the SHA-256 of the whole note. Intent, not a declaration.") '("Work Item" "Source Change" "Evidence" "Project Workspace" "Deployment Evidence"))
               (rec "phase-d-boundary-rehearsal.txt" "The four commit boundaries, rehearsed" :integration "2026-10-28"
                    '("Boundaries 1 and 2 committed in a scratch clone of the repository (not this worktree) and tested at each commit.") '("B1" "B2" "tree" "PASS" "exit"))
               (rec "phase-b-nix-package-check.log" "The Nix package check for the retargeted pins" :integration "2026-10-28"
                    '("nix build of checks.x86_64-darwin.catalog-topic-maps with the snapshot in the local store.") '("PASS" "error" "built" "ASDF-ORIGIN"))))))) 
(defun record (file) (or (find file (records) :key #'record-file :test #'string=) (error "No record ~S." file)))

;;; Claims

(defclass review-claim ()
  ((id :initarg :id :reader claim-id) (statement :initarg :statement :reader claim-statement)
   (class :initarg :class :reader claim-class :documentation ":observed, :derived, :inferred or :open.")
   (evidence :initarg :evidence :initform nil :reader claim-evidence) (sources :initarg :sources :initform nil :reader claim-sources)
   (limit :initarg :limit :initform nil :reader claim-limit :documentation "What the evidence does not show.")))
(defmethod v:text-representation ((c review-claim)) (format nil "~A (~(~A~))" (claim-statement c) (claim-class c)))

(defvar *claims* nil)
(defun claims ()
  (or *claims*
      (setf *claims*
            (flet ((claim (id class statement evidence sources &optional limit)
                     (make-instance 'review-claim :id id :class class :statement statement :evidence (mapcar #'record evidence)
                                                  :sources sources :limit limit)))
              (list
               (claim "fast-forward" :observed
                      "The primary Topic Maps branch codex/project-work-slice-22u moved from b2eecffa to 6162ed68 by a fast-forward; its tree equals the reviewed commit's tree; b2eecffa and every other branch are untouched."
                      '("phase-a-integration.txt" "task1c-commit-record.md") nil
                      "Local only. The branch is not pushed; its gitweb remote still names b2eecffa.")
               (claim "one-bounded-change" :observed
                      "The reviewed commit changes 29 paths: one production file (src/tmdm/merging.lisp), the test runner wiring, the ASDF declaration, one test file and 25 fixtures. The experimental association index is not in it."
                      '("task1c-commit-record.md" "independent-review.md") (list #'topic-maps.tmdm::next-topic-merge #'topic-maps.tmdm::scan-next-topic-merge))
               (claim "same-pair" :derived
                      "next-topic-merge returns the pair scan-next-topic-merge (the b2eecffa search, moved verbatim) returns: same identity rule, same order, same preference for a nonconflicting pair."
                      '("independent-review.md") (list #'topic-maps.tmdm::next-topic-merge #'topic-maps.tmdm::scan-next-topic-merge #'topic-maps.tmdm::equal-topics-p)
                      "The proof rests on equal-topics-p and the conflict test having no side effects and on identifiers being strings; arbitrarily malformed raw slots are not covered.")
               (claim "tests-agree" :observed
                      "4,000 generated maps, 800 merge walks and 400 CTM documents give identical outcomes with the index and with the old search (including the number of merges); 177 maps exercise the preference, 63 the fallback."
                      '("independent-review.md" "independent-semantic-checks.log")
                      nil "The old search shares equal-topics-p, topic-reified, the merge primitives and the serializer with the new one; a defect in those would survive.")
               (claim "mutants-killed" :observed
                      "The unmutated implementation passes; eight mutants (conflict ignored, stale reification table, no two-item fallback, no representative guard, II and SI separated, locator in the identifier namespace, last instead of first partner, preference dropped) are each killed. The stale table is killed by the invalidation tests alone."
                      '("independent-suite-and-mutation-results.json" "task1c-mutation-results.txt") nil
                      "Eight specific perturbations, not a proof against every wrong implementation.")
               (claim "fixtures-from-baseline" :observed
                      "The expected CXTM of 21 documents and 3 staged imports and the class and code of 7 rejections were produced by the unchanged b2eecffa source; the reviewer re-recorded them there and they are identical."
                      '("independent-review.md" "task1c-evidence-correspondence.txt") nil)
               (claim "suite-preserved" :observed
                      "The full Topic Maps suite runs with fresh caches on baseline and candidate: exit 0, 25 report files byte-identical, one added PASS line. The integrated primary checkout repeats it."
                      '("phase-a-integration.txt" "independent-suite-and-mutation-results.json") nil
                      "The suites keep their known baseline FAIL and NOT-RUN cases: preservation, not standards conformance.")
               (claim "corpus-identical" :observed
                      "On the unchanged HyperDoc project CTM the semantic signature (4e8a07ba…) and the CXTM (6f957018…) are byte-identical to the 5a4a668 reference, under SBCL 2.6.4 and 2.4.10 and in the Project Workspace."
                      '("independent-bench-candidate.json" "independent-bench-reference.json" "phase-b-workspace-verified-snapshot.log") nil
                      "The corpus never merges two Topics, so it cannot show the preference path.")
               (claim "corpus-never-merges" :observed
                      "Reading the project CTM performs 7,511 Topic-merge searches and none finds a pair; no Topic and no Association is merged."
                      '("task1c-corpus-search-counts.txt" "independent-shadow-reproduction.log") (list #'topic-maps.tmdm::next-topic-merge))
               (claim "slices-against-baseline" :observed
                      "On two corpus slices that b2eecffa can finish, it needs 111 s and 152 s; the candidate 0.5 s and 0.5 s; signatures and CXTM are byte-identical."
                      '("independent-review.md") nil "The whole corpus cannot be run on b2eecffa.")
               (claim "within-90-seconds" :observed
                      "The unchanged project CTM reads in a median of 29 s (independent reproduction, three runs) and 34 s (this integration's benchmark of the primary checkout, three runs from 28.7 s to 34.5 s): below the 90-second operational limit."
                      '("independent-bench-candidate.json" "independent-bench-baseline-timeout.json" "phase-b-benchmark-integrated.json") nil
                      "Timings are from one Intel Mac. They vary with load: one Project Workspace run took 161 s on an overloaded machine (load average above 100) and 35 s when repeated alone.")
               (claim "target-20s-unmet" :observed
                      "The approximately 20-second aspiration is not met: the remaining time is the Association pair search, which this change leaves alone."
                      '("independent-review.md" "independent-bench-experimental.json") nil
                      "The experimental combination with an association index reads in about 8 s; it is not part of this integration.")
               (claim "snapshot-of-6162ed68" :observed
                      "The runtime snapshot of 6162ed68 (every root entry but reports/, 2,354 files) equals the commit's tree: 19 independent Git and Nix checks pass, and the archive and manifest are reproducible byte for byte."
                      '("snapshot-archive-verification.json") (list (snap:find-snapshot-manifest +reviewed-commit+)))
               (claim "pins-retargeted" :observed
                      "With the Catalog, the 22U reading and the Project Workspace pinned to 6162ed68, the snapshot verifier (34 assertions), the 22U reading (41) and the CTM review (58) pass on the Git-free snapshot."
                      '("phase-b-snapshot-suites.log") (list #'c:topic-maps-origins #'snap:verify-store-snapshot))
               (claim "project-suite-passes" :observed
                      "The Project Workspace suite passes on the integrated Git checkout: 265 source checks, 186 read-back checks with the 90-second bound, and 125 acceptance checks."
                      '("phase-b-project-suite.log") (list #'p::topic-maps-source-identity))
               (claim "workspace-on-both-roots" :observed
                      "The Project Workspace reads the original CTM, traces every statement, builds 148 signs and 286 edges, navigates its eight keys and reproduces the CTM by octets and CXTM, both from a clean Git checkout and from the verified Git-free snapshot; the CTM bytes stay unchanged."
                      '("phase-b-workspace-git-checkout.log" "phase-b-workspace-verified-snapshot.log") (list #'p::topic-maps-source-identity)
                      "Lisp API navigation, not a browser flow.")
               (claim "pin-can-fail" :observed
                      "The pin check fails for the 5a4a668 checkout, for the b2eecffa snapshot (which does not verify as 6162ed68) and for a directory that Git cannot identify; the last two report no commit and not clean."
                      '("phase-b-negative-5a4a668.log" "phase-b-negative-old-b2eecffa-snapshot.log" "phase-b-negative-unverifiable.log") (list #'p::pinned-state-p #'p::topic-maps-source-identity))
               (claim "guard-remains" :observed
                      "The Catalog's startup guard still refuses dreyeck/work/project and everything that depends on it; only its wording changed, because the Workspace is no longer bound to another lineage. Admission to the served runtime is a separate decision."
                      '("phase-b-snapshot-suites.log") (list #'c:refuse-project-workspace #'c:verify-startup)
                      "Asked of definitions only; a load made later by other means is not stopped (see the deployment review).")
               (claim "nix-contract-darwin" :observed
                      "The packaged contract for the retargeted pins passes in the Nix build sandbox on x86_64-darwin: every Topic Maps system comes from the one verified snapshot of 6162ed68 (the only topic-maps.asd in the registry), the Catalog, verifier, 22U and CTM-review suites pass, ASDF's own methods are unchanged, and the built executable refuses public hosts and the Project Workspace."
                      '("phase-b-nix-package-check.log") (list #'c:topic-maps-origins #'c:main)
                      "The snapshot was added to the local store from the verified archive; the unpublished release URL was not contacted. The sandbox build also fetched public inputs (curl and others from cache.nixos.org, the d2 release archive) that the store no longer held. hyperdoc-catalog, the production package, was not rebuilt or compared in this step.")
               (claim "reading-navigated-in-a-browser" :observed
                      "This reading, served on loopback from the Git-free snapshot, was opened in a browser: its pages, a claim, a function's source code, the Workspace and its relations render, rendering ran nothing, and the guard button answered."
                      '("phase-b-browser-reading.txt") nil
                      "Interactive and single-browser. The HyperDoc Project Workspace's own pages were not navigated in a browser.")
               (claim "linux-nix-unbuilt" :open
                      "Nothing was built or checked for x86_64-linux."
                      nil nil)
               (claim "declared-paths-bound" :observed
                      "DECLARED-PATHS-AGREE protects one historical change set, the earlier review's candidate at its completion commit 8e64e718 (73 declared paths, 23 tested files). It failed because it compared the working tree; the integration changes seven protected files on purpose. Its contract is now bound to 8e64e718, names those seven changes as successor changes with reasons, and still detects an extra path, an altered file and an unlisted modification."
                      '("phase-c-declared-paths-agree.txt") (list #'topic-maps-deployment-review::declared-paths-agree-p #'topic-maps-deployment-review::tested-files-match-at-p #'topic-maps-deployment-review::unexpected-drift)
                      "The earlier review's second test procedure (the proposals') already fails at 8e64e718 and was not touched.")
               (claim "project-workspace-browser" :observed
                      "In a fresh process and a headless browser, with the original project CTM and Topic Maps 6162ed68 as a clean Git checkout, the walk from the Catalog through a declared Work Item, its source page, its plan relationship, an Implementation Assignment and its evidence file passes; the Work Breakdown page is the same Lisp object from two routes (and another page is not); the absent acceptance record is named; the Work pages and the CTM keep their digests."
                      '("phase-c-project-workspace-browser.log" "phase-c-project-workspace-browser.json") (list #'p::topic-maps-source-identity)
                      "One browser, headless; object identity is read from the printed address under each pane's Print tab. The Git-free snapshot as the Topic Maps root was not used in the browser.")
               (claim "trusted-runtime-not-the-guarded-catalog" :observed
                      "The browser walk ran in a separate trusted review runtime, scripts/serve-project-workspace.lisp (a fresh loopback Catalog over an empty test-copy site root), not in the packaged executable: that executable still refuses dreyeck/work/project at startup. The guard was neither bypassed nor weakened."
                      '("phase-c-project-workspace-browser.log" "phase-b-nix-package-check.log") (list #'c:refuse-project-workspace #'c:main)
                      "Serving the Project Workspace from the packaged staging service would need an explicit admission decision.")
               (claim "zettel-navigation-is-proposed" :observed
                      "Zettel 11359's wished-for navigation (Work Item, Source Change, Evidence, Project Workspace, Deployment Evidence) exists only in this reading's Topicmap as relations of class proposed. No Work page, WBS declaration, acceptance record or CTM source was changed or written, and the proposals of the earlier review were not promoted."
                      '("zettel-11359-excerpt.md" "phase-c-project-workspace-browser.log") nil
                      "A statement about what was not done: the browser test checks the Work pages and the CTM by digest; Git shows them unchanged.")
               (claim "boundaries-coherent" :observed
                      "Boundaries 1 and 2 were committed in a scratch clone and tested at each commit; their file sets are disjoint apart from two files split by hunk, and together with the reading and the documentation they are exactly the candidate's changed paths."
                      '("phase-d-boundary-rehearsal.txt") nil
                      "Boundaries 3 and 4 (the reading and this documentation) are tested by the reading's own suite in the final tree, reported in docs/topic-maps-6162ed68-integration.")
               (claim "browser-from-snapshot-open" :open
                      "The browser walk was not run with the Git-free snapshot as the Topic Maps root."
                      nil nil)
               (claim "staging-not-started" :open
                      "No server was touched; the staging service still runs the b2eecffa package."
                      nil nil)))))) 
(defun claim (id) (or (find id (claims) :key #'claim-id :test #'string=) (error "No claim ~S." id)))
