;;;; The Candidate: Its Files and Their Working-Tree Identity
(in-package #:topic-maps-deployment-review)

;;; The candidate is not a commit. Each of its files is identified by what is in the working tree when it is shown: its
;;; SHA-256, its Git blob id, and whether HEAD holds that blob. Only when HEAD does is the file called committed. The
;;; SHA-256 each program or test file had when the tests ran is recorded in the candidate's evidence and compared here.

(defparameter +book-id+ "topic-maps-deployment-review")
(defparameter +base-commit+ "53ee999358f455a2dcb375743072d56d0f4c31cd"
  "The commit the candidate was prepared on: the CTM review, on dreyeck.ch.")
(defparameter +branch+ "dreyeck.ch")

(defparameter +candidate-paths+
  '(;; Program and test files: their SHA-256 at test time is in evidence/tested-files-sha256.txt.
    ("dreyeck.asd" :asdf) ("flake.nix" :nix)
    ("nix/topic-maps-source.nix" :nix) ("nix/topic-maps-b2eecffa.manifest" :snapshot)
    ("nix/catalog-topic-maps.nix" :nix) ("nix/catalog-topic-maps-check.nix" :nix)
    ("scripts/topic-maps-snapshot.py" :snapshot) ("tests/test_topic_maps_snapshot.py" :test)
    ("dreyeck/src/source-snapshot.lisp" :verifier) ("dreyeck/tests/source-snapshot.lisp" :test)
    ("dreyeck/work/topic-maps-project-example.lisp" :provenance) ("dreyeck/work/topic-maps-ctm-review.lisp" :provenance)
    ("dreyeck/tests/topic-maps-project-example.lisp" :test) ("dreyeck/tests/topic-maps-ctm-review.lisp" :test)
    ("dreyeck/src/catalog-topic-maps.lisp" :startup) ("scripts/catalog-topic-maps-main.lisp" :startup)
    ("dreyeck/tests/catalog-topic-maps.lisp" :test) ("scripts/test-catalog-topic-maps.lisp" :test)
    ("tests/test_catalog_topic_maps_executable.py" :test) ("scripts/compare-catalog-derivation.py" :test)
    ("scripts/test-topic-maps-ctm-review-browser.mjs" :test)
    ;; Added with the guard correction (2026-10-27) and the packaging work after it.
    ("scripts/test-asdf-method-preservation.lisp" :test) ("nix/nixos-staging.nix" :nix)
    ;; Documentation and recorded evidence: not test inputs.
    ("docs/topic-maps-deployment/README.md" :documentation) ("docs/topic-maps-deployment/phase-a-design.md" :documentation)
    ("docs/topic-maps-22u-integration/README.md" :documentation) ("docs/topic-maps-deployment/staging.md" :documentation)
    ("docs/topic-maps-deployment/evidence/.gitattributes" :evidence)
    ("docs/topic-maps-deployment/evidence/archive-controls.log" :evidence)
    ("docs/topic-maps-deployment/evidence/archive-verification.json" :evidence)
    ("docs/topic-maps-deployment/evidence/browser-22u-checkout.json" :evidence)
    ("docs/topic-maps-deployment/evidence/browser-review-checkout.json" :evidence)
    ("docs/topic-maps-deployment/evidence/browser-review-snapshot.json" :evidence)
    ("docs/topic-maps-deployment/evidence/catalog-control-changed-wrapper.json" :evidence)
    ("docs/topic-maps-deployment/evidence/catalog-unchanged-x86_64-darwin.json" :evidence)
    ("docs/topic-maps-deployment/evidence/catalog-unchanged-x86_64-linux.json" :evidence)
    ("docs/topic-maps-deployment/evidence/checkout-review-22u.log" :evidence)
    ("docs/topic-maps-deployment/evidence/checkout-source-snapshot.log" :evidence)
    ("docs/topic-maps-deployment/evidence/execution-view-snapshot.png" :evidence)
    ("docs/topic-maps-deployment/evidence/mutants.log" :evidence)
    ("docs/topic-maps-deployment/evidence/package-check/executable.log" :evidence)
    ("docs/topic-maps-deployment/evidence/package-check/lisp.log" :evidence)
    ("docs/topic-maps-deployment/evidence/package-check/nix-build.log" :evidence)
    ("docs/topic-maps-deployment/evidence/package-check/topic-maps-asd" :evidence)
    ("docs/topic-maps-deployment/evidence/production-check.log" :evidence)
    ("docs/topic-maps-deployment/evidence/tested-files-sha256.txt" :evidence)
    ;; Evidence of the corrected candidate. The files above describe the first version of the guard and are unchanged.
    ("docs/topic-maps-deployment/evidence/after-guard-correction/README.md" :evidence)
    ("docs/topic-maps-deployment/evidence/after-guard-correction/tested-files-sha256.txt" :evidence)
    ("docs/topic-maps-deployment/evidence/after-guard-correction/contract-lisp.log" :evidence)
    ("docs/topic-maps-deployment/evidence/after-guard-correction/asdf-methods.log" :evidence)
    ("docs/topic-maps-deployment/evidence/after-guard-correction/executable.log" :evidence)
    ("docs/topic-maps-deployment/evidence/after-guard-correction/derivations-unchanged-x86_64-linux.json" :evidence)
    ("docs/topic-maps-deployment/evidence/after-guard-correction/derivations-unchanged-x86_64-darwin.json" :evidence)
    ("docs/topic-maps-deployment/evidence/after-guard-correction/module-evaluation.json" :evidence)
    ("docs/topic-maps-deployment/evidence/after-guard-correction/nix-darwin-blocker.log" :evidence)
    ("docs/topic-maps-deployment/evidence/after-guard-correction/x86_64-linux/nix-build.log" :evidence)
    ("docs/topic-maps-deployment/evidence/after-guard-correction/x86_64-linux/contract-lisp.log" :evidence)
    ("docs/topic-maps-deployment/evidence/after-guard-correction/x86_64-linux/asdf-methods.log" :evidence)
    ("docs/topic-maps-deployment/evidence/after-guard-correction/x86_64-linux/executable.log" :evidence)
    ("docs/topic-maps-deployment/evidence/after-guard-correction/x86_64-linux/topic-maps-asd" :evidence)
    ("docs/topic-maps-deployment/evidence/after-guard-correction/x86_64-linux/builder-and-snapshot.txt" :evidence)
    ("docs/topic-maps-deployment/evidence/after-guard-correction/x86_64-linux/packaged-reading.log" :evidence)
    ("docs/topic-maps-deployment/evidence/after-guard-correction/x86_64-linux/browser-walk.json" :evidence)
    ("docs/topic-maps-deployment/evidence/after-guard-correction/x86_64-linux/linux-validate.sh" :evidence)
    ("docs/topic-maps-deployment/evidence/after-guard-correction/x86_64-linux/reading-suites.lisp" :evidence)
    ("docs/topic-maps-deployment/evidence/after-guard-correction/x86_64-linux/walk-linux.mjs" :evidence)
    ("docs/topic-maps-deployment/evidence/after-guard-correction/x86_64-linux/of-commit-7080162b/nix-build.log" :evidence)
    ("docs/topic-maps-deployment/evidence/after-guard-correction/x86_64-linux/of-commit-7080162b/contract-lisp.log" :evidence)
    ("docs/topic-maps-deployment/evidence/after-guard-correction/x86_64-linux/of-commit-7080162b/asdf-methods.log" :evidence)
    ("docs/topic-maps-deployment/evidence/after-guard-correction/x86_64-linux/of-commit-7080162b/executable.log" :evidence)
    ("docs/topic-maps-deployment/evidence/after-guard-correction/x86_64-linux/of-commit-7080162b/topic-maps-asd" :evidence)
    ("docs/topic-maps-deployment/evidence/after-guard-correction/x86_64-linux/of-commit-7080162b/packaged-reading.log" :evidence)
    ("docs/topic-maps-deployment/evidence/after-guard-correction/x86_64-linux/of-commit-7080162b/browser-walk.json" :evidence))
  "The paths of the packaging candidate, each with its responsibility: the 43 presented for review on 2026-10-26, and the files the
guard correction of 2026-10-27 and the packaging work after it added. The
Candidate view checks this declaration against Git every time it is shown.")

(defparameter +review-prefixes+
  '("dreyeck/work/topic-maps-deployment-review/" "scripts/serve-topic-maps-deployment-review.lisp"
    "scripts/test-topic-maps-deployment-review-browser.mjs")
  "This reading's own files. They are not part of the candidate.")

(defun hyperdoc-root () (asdf:system-source-directory "dreyeck"))
(defun root-path (path) (merge-pathnames path (hyperdoc-root)))
(defun git-values (&rest arguments) (apply #'git:git-run-values (hyperdoc-root) arguments))
(defun git-lines (&rest arguments)
  (multiple-value-bind (out err code) (apply #'git-values arguments)
    (declare (ignore err))
    (and (zerop code) (remove "" (uiop:split-string out :separator '(#\Newline)) :test #'string=))))
(defun git-line (&rest arguments) (first (apply #'git-lines arguments)))
(defvar *git-available* :unknown)
(defun git-available-p ()
  "Whether HyperDoc's source is a Git working tree. The packaged Catalog's source is a /nix/store path with no .git; there the
reading says so and shows what it can: the SHA-256 of each file."
  (when (eq *git-available* :unknown)
    (setf *git-available* (and (git-line "rev-parse" "--git-dir") t)))
  *git-available*)

(defun octets-of (pathname)
  (with-open-file (in pathname :element-type '(unsigned-byte 8))
    (let ((data (make-array (file-length in) :element-type '(unsigned-byte 8)))) (read-sequence data in) data)))
(defun sha256-hex (octets) (ironclad:byte-array-to-hex-string (ironclad:digest-sequence :sha256 octets)))

(defun review-reading-path-p (path) (some (lambda (prefix) (uiop:string-prefix-p prefix path)) +review-prefixes+))

;;; Files

(defclass candidate-file ()
  ((path :initarg :path :reader file-path)
   (kind :initarg :kind :reader file-kind)
   (tested-sha256 :initarg :tested-sha256 :initform nil :reader file-tested-sha256
                  :documentation "The SHA-256 recorded when the tests ran, for program and test files; NIL otherwise."))
  (:documentation "One file of the candidate, identified by what the working tree holds when it is asked."))
(defmethod v:text-representation ((f candidate-file)) (file-path f))

(defun file-octets-now (file)
  (let ((pathname (root-path (file-path file)))) (and (probe-file pathname) (octets-of pathname))))
(defun file-sha256-now (file) (let ((octets (file-octets-now file))) (and octets (sha256-hex octets))))
(defun file-blob-now (file) (let ((octets (file-octets-now file))) (and octets (snap:git-object-id "blob" octets))))
(defvar *git-cache* nil
  "While one view renders: a table of what Git said, so that a view over many files asks Git for each tree once, not for each file.")
(defun tree-blobs (revision)
  "The blob id of every file of REVISION's tree, by path, from one `git ls-tree -r`."
  (let ((table (make-hash-table :test #'equal)))
    (dolist (line (git-lines "ls-tree" "-r" revision) table)
      (let ((tab (position #\Tab line)))
        (when tab
          (setf (gethash (subseq line (1+ tab)) table) (subseq line (1+ (position #\Space line :from-end t :end tab)) tab)))))))
(defun cached-git (key thunk)
  (if *git-cache* (multiple-value-bind (value found) (gethash key *git-cache*) (if found value (setf (gethash key *git-cache*) (funcall thunk)))) (funcall thunk)))
(defun head-commit () (cached-git :head (lambda () (git-line "rev-parse" "HEAD"))))
(defun file-blob-at (file revision)
  (if *git-cache*
      (gethash (file-path file) (cached-git (list :tree revision) (lambda () (tree-blobs revision))))
      (git-line "rev-parse" "--verify" "--quiet" (format nil "~A:~A" revision (file-path file)))))
(defun file-matches-tested-p (file) (and (file-tested-sha256 file) (equal (file-tested-sha256 file) (file-sha256-now file))))

(defun file-state (file)
  "Where the working-tree bytes of FILE stand now: :COMMITTED if HEAD holds exactly them and HEAD is not the base,
:UNCOMMITTED-NEW if the base has no such file, :UNCOMMITTED-MODIFIED otherwise, :AS-IN-BASE if they equal the base's
blob (the candidate's change is gone), or :MISSING."
  (let ((now (file-blob-now file)) (head (file-blob-at file "HEAD")) (base (file-blob-at file +base-commit+)))
    (cond ((null now) :missing)
          ((not (git-available-p)) :no-git)
          ((equal now base) :as-in-base)
          ((and (equal now head) (not (equal (head-commit) +base-commit+))) :committed)
          ((null base) :uncommitted-new)
          (t :uncommitted-modified))))

(defun state-text (state)
  (ecase state
    (:committed (format nil "committed in ~A" (subseq (head-commit) 0 12)))
    (:uncommitted-new "uncommitted, new (no such file at the base)")
    (:uncommitted-modified "uncommitted, modified against the base")
    (:as-in-base "equal to the base: the candidate's change is not there")
    (:missing "missing from the working tree")
    (:no-git "Git state not available: this source has no .git")))

;;; The candidate

(defclass candidate ()
  ((files :initarg :files :reader candidate-files))
  (:documentation "The packaging candidate: its declared files, with the tested SHA-256 of each program and test file."))
(defmethod v:text-representation ((c candidate)) "The Topic Maps packaging candidate")

(defparameter +tested-digests-records+
  '("docs/topic-maps-deployment/evidence/after-guard-correction/tested-files-sha256.txt"
    "docs/topic-maps-deployment/evidence/tested-files-sha256.txt")
  "The record of the corrected candidate's tested files, then the first one's (2026-10-26, before the guard was corrected). The
first that exists is read; the other stays as the historical record of what the first runs tested.")
(defun tested-digests ()
  "The SHA-256 of each program and test file when the tests ran, read from the candidate's own record."
  (with-open-file (in (root-path (find-if (lambda (path) (probe-file (root-path path))) +tested-digests-records+)))
    (loop for line = (read-line in nil) while line
          collect (cons (subseq line 66) (subseq line 0 64)))))

(defvar *candidate* nil)
(defun the-candidate ()
  (or *candidate*
      (setf *candidate*
            (let ((tested (tested-digests)))
              (make-instance 'candidate
                             :files (loop for (path kind) in +candidate-paths+
                                          collect (make-instance 'candidate-file :path path :kind kind
                                                                 :tested-sha256 (cdr (assoc path tested :test #'string=)))))))))
(defun file-named (path)
  (or (find path (candidate-files (the-candidate)) :key #'file-path :test #'string=) (error "~A is not a candidate file." path)))

(defparameter +reviewed-head+ "8e64e7189daf1c5615cbc8bbe40cff3bf2bcd1aa"
  "The commit at which the candidate is complete: between the base and it Git changes exactly the declared paths, and every tested file
has the bytes the tests ran on. The contract below is bound to this commit, not to the working tree. Later work cannot change what
this reading reviewed, and cannot pass as it: a protected file changed since then is reported, and unless a named successor changed
it (+SUCCESSOR-CHANGES+) the contract fails.")

(defparameter +successor-changes+
  '(("dreyeck.asd" . "Topic Maps 6162ed68 integration: the 6162ed68 manifest as a static file and the Project Workspace's dependency on the verifier; one production Catalog (docs/one-catalog): the readings depend on the authority policy, and the guard's tests include the served views")
    ("nix/topic-maps-source.nix" . "Topic Maps 6162ed68 integration: the pinned archive is now 6162ed68's; one production Catalog (docs/one-catalog): the 88994c1b archive is in the repository and unpacked by a fixed-output derivation")
    ("flake.nix" . "One production Catalog (docs/one-catalog): hyperdoc-catalog carries the snapshot and the verified startup; this variant stays only as the record this reading reviews")
    ("dreyeck/work/topic-maps-ctm-review.lisp" . "One production Catalog (docs/one-catalog): the run button goes through the authority policy, so a served Catalog does not offer it")
    ("dreyeck/src/catalog-topic-maps.lisp" . "Topic Maps 6162ed68 integration: the packaged commit, and the guard's message")
    ("dreyeck/work/topic-maps-project-example.lisp" . "Topic Maps 6162ed68 integration: the pinned revision; one production Catalog (docs/one-catalog): the run buttons go through the authority policy")
    ("dreyeck/tests/source-snapshot.lisp" . "Topic Maps 6162ed68 integration: the commit and the file count of the snapshot")
    ("dreyeck/tests/catalog-topic-maps.lisp" . "Topic Maps 6162ed68 integration: the guard's new wording")
    ("tests/test_catalog_topic_maps_executable.py" . "Topic Maps 6162ed68 integration: the guard's new wording"))
  "The protected paths changed after +REVIEWED-HEAD+ by a named successor, each with its reason. A protected path changed for any other
reason is unexpected drift. The list is not a way to accept arbitrary files: it names paths of the declaration only, and each entry
is a decision of a later, documented change (docs/topic-maps-6162ed68-integration).")

(defun git-changed-paths (&optional (revision +reviewed-head+))
  "The paths Git changes between the base and REVISION, less this reading's own files; then, from the working tree, the untracked ones."
  (values (sort (remove-if #'review-reading-path-p (git-lines "diff" "--name-only" +base-commit+ revision)) #'string<)
          (sort (git-lines "ls-files" "--others" "--exclude-standard") #'string<)))
(defun review-reading-paths () (remove-if-not #'review-reading-path-p (nth-value 1 (git-changed-paths))))
(defun declared-paths-agree-p (&key (revision +reviewed-head+) (changed nil changed-p) (declared (mapcar #'first +candidate-paths+)))
  "Whether the paths Git changes between the base and REVISION (the reviewed head) are exactly the declared candidate; :UNKNOWN
without Git. CHANGED and DECLARED stand in for Git's answer and the declaration, so that a test can show an extra, or a missing,
path is detected."
  (if (git-available-p)
      (equal (sort (copy-list (if changed-p changed (git-changed-paths revision))) #'string<) (sort (copy-list declared) #'string<))
      :unknown))

(defun blob-sha256-at (revision path)
  "The SHA-256 of PATH's bytes at REVISION, from Git's object, or NIL."
  (multiple-value-bind (out err code)
      (uiop:run-program (list "git" "-C" (sb-ext:native-namestring (hyperdoc-root)) "cat-file" "blob" (format nil "~A:~A" revision path))
                        :output :string :external-format :latin-1 :ignore-error-status t :error-output nil)
    (declare (ignore err))
    (and out (eql code 0) (sha256-hex (map '(vector (unsigned-byte 8)) #'char-code out)))))
(defun tested-files-match-at-p (&key (revision +reviewed-head+) (blob-sha256 #'blob-sha256-at))
  "Whether every program and test file of the candidate has, at REVISION, the SHA-256 recorded when the tests ran. BLOB-SHA256 stands
in for Git's answer so that a test can show an altered file is detected."
  (every (lambda (entry) (equal (cdr entry) (funcall blob-sha256 revision (car entry)))) (tested-digests)))
(defun protected-paths-drift (&optional (revision +reviewed-head+))
  "The declared paths whose bytes in the working tree are not those of REVISION (or that are missing from either)."
  (let ((table (cached-git (list :tree revision) (lambda () (tree-blobs revision)))))
    (sort (loop for (path) in +candidate-paths+
                for pathname = (root-path path)
                for now = (and (probe-file pathname) (snap:git-object-id "blob" (octets-of pathname)))
                unless (equal now (gethash path table)) collect path)
          #'string<)))
(defun unexpected-drift (&key (drift (protected-paths-drift)) (allowed (mapcar #'car +successor-changes+)))
  "The drifted protected paths no named successor accounts for."
  (set-difference drift allowed :test #'string=))
(defun reviewed-head-reachable-p ()
  (multiple-value-bind (out err code) (git-values "merge-base" "--is-ancestor" +reviewed-head+ "HEAD") (declare (ignore out err)) (eql code 0)))

;;; Excerpts: a definition as it stands in a file now

(defclass source-excerpt ()
  ((key :initarg :key :reader excerpt-key)
   (title :initarg :title :reader excerpt-title)
   (root :initarg :root :reader excerpt-root :documentation "Directory of the file: HyperDoc's checkout or a store path.")
   (path :initarg :path :reader excerpt-path)
   (start :initarg :start :reader excerpt-start :documentation "The text the excerpt begins with.")
   (end :initarg :end :initform nil :reader excerpt-end :documentation "The text it ends with, first found after START; NIL for the whole file."))
  (:documentation "A definition located by its own text, so that it is found again after the file changes elsewhere."))
(defmethod v:text-representation ((e source-excerpt)) (excerpt-title e))

(defun excerpt-text (excerpt)
  "The excerpt's text as the file holds it now, with its character positions; an error if it is not found."
  (let* ((text (uiop:read-file-string (merge-pathnames (excerpt-path excerpt) (excerpt-root excerpt))))
         (start (if (excerpt-start excerpt) (search (excerpt-start excerpt) text) 0)))
    (unless start (error "~A no longer contains ~S." (excerpt-path excerpt) (excerpt-start excerpt)))
    (let* ((end-at (and (excerpt-end excerpt) (search (excerpt-end excerpt) text :start2 start)))
           (end (cond ((null (excerpt-end excerpt)) (length text))
                      (end-at (+ end-at (length (excerpt-end excerpt))))
                      (t (error "~A has no ~S after its start." (excerpt-path excerpt) (excerpt-end excerpt))))))
      (values (subseq text start end) start end))))

(defun excerpt-file (excerpt)
  "The candidate file the excerpt is in, or NIL for a file outside the candidate."
  (and (equal (excerpt-root excerpt) (hyperdoc-root))
       (find (excerpt-path excerpt) (candidate-files (the-candidate)) :key #'file-path :test #'string=)))

(defclass historical-excerpt (source-excerpt) ()
  (:documentation "A file kept verbatim by this reading as it was before a correction. It is no file of the candidate."))
(defun historical-excerpt (key title file start &optional end)
  (make-instance 'historical-excerpt :key key :title title :root (root-path "dreyeck/work/topic-maps-deployment-review/asdf-collision/evidence/")
                                     :path file :start start :end end))

(defun hyperdoc-excerpt (key title path start &optional end)
  (make-instance 'source-excerpt :key key :title title :root (hyperdoc-root) :path path :start start :end end))
(defun topic-maps-excerpt (key title path start &optional end)
  "An excerpt of the Topic Maps source ASDF loaded, which in this reading is the verified store snapshot."
  (make-instance 'source-excerpt :key key :title title :root (asdf:system-source-directory "topic-maps") :path path
                                 :start start :end end))

(defvar *excerpts* nil)
(defun excerpts ()
  (or *excerpts*
      (setf *excerpts*
            (list
             (hyperdoc-excerpt "flake:variant" "flake.nix: the hyperdoc-catalog-topic-maps package" "flake.nix"
                               "          # Separate from hyperdoc-catalog" "revision = self.rev or self.dirtyRev or \"\";
          };")
             (hyperdoc-excerpt "flake:production" "flake.nix: the hyperdoc-catalog package, as at the base" "flake.nix"
                               "          hyperdoc-catalog = pkgs.callPackage ./nix/catalog.nix {" "          };")
             (hyperdoc-excerpt "flake:check" "flake.nix: the catalog-topic-maps check" "flake.nix"
                               "        catalog-topic-maps = let pkgs" "revision = self.rev or self.dirtyRev or \"\";
          };")
             (hyperdoc-excerpt "nix:source" "nix/topic-maps-source.nix: the pinned snapshot" "nix/topic-maps-source.nix" nil)
             (hyperdoc-excerpt "nix:wrapper" "nix/catalog-topic-maps.nix: registry, revision and startup"
                               "nix/catalog-topic-maps.nix" "  text = ''" "  '';")
             (hyperdoc-excerpt "nix:check" "nix/catalog-topic-maps-check.nix: the sandboxed contract"
                               "nix/catalog-topic-maps-check.nix" nil)
             (hyperdoc-excerpt "nix:production-wrapper" "nix/catalog.nix: the production wrapper, outside the candidate"
                               "nix/catalog.nix" nil)
             (hyperdoc-excerpt "asd:source-snapshot" "dreyeck.asd: the dreyeck/source-snapshot systems" "dreyeck.asd"
                               ";; The pinned Topic Maps commit as a Nix store snapshot" "(uiop:symbol-call :dreyeck/source-snapshot/tests :run-tests)))")
             (hyperdoc-excerpt "asd:catalog-topic-maps" "dreyeck.asd: the dreyeck/catalog-topic-maps systems" "dreyeck.asd"
                               ";; The separate hyperdoc-catalog-topic-maps executable" "(uiop:symbol-call :dreyeck/catalog-topic-maps/tests :run-tests)))")
             (hyperdoc-excerpt "asd:project-example" "dreyeck.asd: the 22U reading's dependencies" "dreyeck.asd"
                               "(defsystem \"dreyeck/work/topic-maps-project-example\"" ":serial t")
             (topic-maps-excerpt "topic-maps.asd:ctm" "topic-maps.asd (from the snapshot): topic-maps/ctm" "topic-maps.asd"
                                 "(asdf:defsystem \"topic-maps/ctm\"" "(:file \"src/ctm/resources\")))")
             (hyperdoc-excerpt "main:host" "scripts/catalog-topic-maps-main.lisp: loopback before loading"
                               "scripts/catalog-topic-maps-main.lisp" ";; Loopback only" "(uiop:quit 2))))")
             ;; Historical: the reviewed candidate bound the Workspace to 5a4a668. Since the Topic Maps 6162ed68 integration the file binds it
             ;; to 6162ed68 (docs/topic-maps-6162ed68-integration); this reading keeps the lines it reviewed, extracted from commit 8e64e718.
             (historical-excerpt "workspace:pin" "The Project Workspace's pin as the reviewed candidate held it (commit 8e64e718; historical)"
                                 "project-workspace-pin-at-8e64e718.lisp" "(defparameter +topic-maps-revision+"
                                 "not in practical time.\")")
             (historical-excerpt "startup:guard-methods" "The first guard's two ASDF methods, as the candidate's file held them (historical)"
                                 "catalog-topic-maps-before-correction.lisp" "(defvar *guard* nil)"
                                 "(error 'project-workspace-refused :system (asdf:component-name (asdf:component-system component)))))")
             (hyperdoc-excerpt "startup:guard" "dreyeck/src/catalog-topic-maps.lisp: the startup check of the corrected guard"
                               "dreyeck/src/catalog-topic-maps.lisp" "(defparameter +refused-systems+" "    verification))")
             (hyperdoc-excerpt "snapshot:create" "scripts/topic-maps-snapshot.py: create" "scripts/topic-maps-snapshot.py"
                               "def create(repo, commit, outdir):" "    print(json.dumps({\"archive\"")
             (hyperdoc-excerpt "snapshot:attributes" "scripts/topic-maps-snapshot.py: attributes and hermetic Git"
                               "scripts/topic-maps-snapshot.py" "# Attributes under which" "env=GIT_ENV).stdout")))))
(defun excerpt (key) (or (find key (excerpts) :key #'excerpt-key :test #'string=) (error "No excerpt ~S." key)))

;;; Views

(defun reading-links ()
  "The way back from any object of this reading to its pages."
  (v:html
    (:p :class "topic-maps-deployment-review-links"
        "Back to the reading: "
        (v:object-ref (review-page "Deploying Topic Maps with HyperDoc") :select "Content" :display "Overview")
        " · " (v:object-ref (the-candidate) :select "Candidate" :display "Candidate")
        " · " (v:object-ref (the-workspace) :select "Topicmap" :display "Subjects")
        " · " (v:object-ref (review-page "Tested and Unverified") :select "Content" :display "Tested and unverified")
        " · " (v:object-ref (review-page "The Proposed Deployment WBS") :select "Content" :display "Proposed project work"))))

(v:defview candidate-view (candidate candidate)
  (v:html-view :title "Candidate" :priority -10
    (let ((*git-cache* (make-hash-table :test #'equal)))
     (multiple-value-bind (changed untracked) (git-changed-paths)
      (declare (ignore changed))
      (v:html
        (:div :style "overflow-wrap:anywhere"
         (:h2 "The Topic Maps packaging candidate")
         (:p (v:esc (format nil "~A on ~A, base ~A. HEAD is ~A now. Topic Maps ~A." (namestring (hyperdoc-root)) +branch+
                            +base-commit+ (or (git-line "rev-parse" "HEAD") "not available without .git") c:+topic-maps-commit+)))
         (:p (:strong (v:esc (case (declared-paths-agree-p)
                                (:unknown (format nil "This source has no .git, so Git cannot say which paths differ from the base. The declaration names ~D paths." (length +candidate-paths+)))
                                ((nil) (format nil "Git disagrees with the declaration: the paths that differ from the base at the reviewed head ~A are not these ~D." (subseq +reviewed-head+ 0 8) (length +candidate-paths+)))
                                (t (format nil "Git agrees with the declaration at the reviewed head ~A: these ~D paths, and no others, differ from the base." (subseq +reviewed-head+ 0 8) (length +candidate-paths+)))))))
         (when (git-available-p)
           (let ((drift (protected-paths-drift)))
             (v:html (:p (v:esc (format nil "Protected files whose working-tree bytes are no longer the reviewed head's: ~D~@[ (~{~A~^, ~})~]. Each is accounted for by a named successor change (Topic Maps 6162ed68 integration) unless it is listed here as unexpected: ~:[none~;~:*~{~A~^, ~}~]."
                                              (length drift) drift (unexpected-drift :drift drift)))))))
         (:p (v:esc "Observed when this view is shown: each file's SHA-256 now, whether HEAD holds those bytes, and, for program and test files, whether they are the bytes the tests ran on."))
         (:table :class "inspector-table"
          (:tr (:th "File") (:th "Responsibility") (:th "State now") (:th "As tested"))
          (dolist (file (candidate-files candidate))
            (v:html (:tr (:td (v:object-ref file :select "Candidate file"))
                         (:td (v:esc (string-downcase (file-kind file))))
                         (:td (v:esc (state-text (file-state file))))
                         (:td (v:esc (cond ((null (file-tested-sha256 file)) "not a test input")
                                           ((file-matches-tested-p file) "same bytes as tested")
                                           (t "changed since the tests ran"))))))))
         (:h3 "Untracked files, outside the candidate")
         (:p "This reading's own files:")
         (:ul (dolist (path (remove-if-not #'review-reading-path-p untracked)) (v:html (:li (:code (v:esc path))))))
         (let ((others (remove-if #'review-reading-path-p untracked)))
           (when others
             (v:html (:p "Neither the candidate nor this reading:")
                     (:ul (dolist (path others) (v:html (:li (:code (v:esc path)))))))))
         (reading-links)))))))

(v:defview candidate-file-view (file candidate-file)
  (v:html-view :title "Candidate file" :priority -10
    (let ((octets (file-octets-now file)))
      (v:html
        (:div :style "overflow-wrap:anywhere"
         (:h2 (:code (v:esc (file-path file))))
         (:p (v:esc (format nil "~A. Responsibility: ~(~A~)." (state-text (file-state file)) (file-kind file))))
         (:p (v:esc (format nil "SHA-256 now ~A." (or (file-sha256-now file) "—"))))
         (:p (v:esc (cond ((null (file-tested-sha256 file)) "Not an input of the tests: documentation or recorded evidence.")
                          ((file-matches-tested-p file) (format nil "The tests ran on these bytes (recorded SHA-256 ~A)." (file-tested-sha256 file)))
                          (t (format nil "Changed since the tests ran: they ran on SHA-256 ~A." (file-tested-sha256 file))))))
         (:p (v:esc (format nil "Git blob now ~A; at HEAD ~A; at the base ~A." (or (file-blob-now file) "—")
                            (or (file-blob-at file "HEAD") "none") (or (file-blob-at file +base-commit+) "none"))))
         (:p (v:object-ref file :select "Against the base" :display "What changed against the base"))
         (if (and octets (every (lambda (b) (or (<= 9 b 13) (<= 32 b))) octets))
             (v:html (:pre :style "white-space:pre-wrap;overflow-wrap:anywhere;max-height:40em;overflow:auto"
                           (v:esc (sb-ext:octets-to-string octets :external-format :utf-8))))
             (v:html (:p (v:esc (format nil "~:[Missing~;Binary, ~:*~D octets~]." (and octets (length octets)))))))
         (reading-links))))))

(v:defview candidate-file-change-view (file candidate-file)
  (v:html-view :title "Against the base" :priority -9
    (v:html
      (:h2 (:code (v:esc (file-path file))) " against " (:code (v:esc (subseq +base-commit+ 0 12))))
      (:pre :style "white-space:pre-wrap;overflow-wrap:anywhere;max-height:40em;overflow:auto"
            (v:esc (or (values (git-values "diff" "--no-color" "--no-ext-diff" +base-commit+ "--" (file-path file))) "")))
      (reading-links))))

(v:defview source-excerpt-view (excerpt source-excerpt)
  (v:html-view :title "Source excerpt" :priority -10
    (multiple-value-bind (text start end) (excerpt-text excerpt)
      (let ((file (excerpt-file excerpt)))
        (v:html
          (:div :style "overflow-wrap:anywhere"
           (:h2 (v:esc (excerpt-title excerpt)))
           (:p (v:esc (format nil "~A, characters ~D–~D, as the file holds it now (excerpt SHA-256 ~A)."
                              (namestring (merge-pathnames (excerpt-path excerpt) (excerpt-root excerpt))) start end
                              (sha256-hex (sb-ext:string-to-octets text :external-format :utf-8)))))
           (:p (if file
                   (v:html "In the candidate: " (v:object-ref file :select "Candidate file") (v:esc (format nil " (~A)." (state-text (file-state file)))))
                   (v:esc (if (uiop:string-prefix-p "/nix/store/" (namestring (excerpt-root excerpt)))
                              "Read from the verified /nix/store snapshot that ASDF loads Topic Maps from."
                              "Not a candidate file: unchanged by the candidate."))))
           (:pre :style "white-space:pre-wrap;overflow-wrap:anywhere" (v:esc text))
           (reading-links)))))))

;;; The first version of the guard, kept as it was

(defun collision-finding-if-loaded ()
  "The collision probe's record object, if the collision extension of this reading is loaded."
  (let ((symbol (find-symbol "ASDF-COLLISION-FINDING" :topic-maps-deployment-review)))
    (and symbol (fboundp symbol) (funcall symbol))))
(v:defview source-excerpt-view (excerpt historical-excerpt) (declare (ignore excerpt)) nil)
(v:defview historical-excerpt-view (excerpt historical-excerpt)
  (v:html-view :title "Historical source" :priority -11
    (multiple-value-bind (text start end) (excerpt-text excerpt)
      (let ((file (merge-pathnames (excerpt-path excerpt) (excerpt-root excerpt))))
        (v:html
          (:div :style "overflow-wrap:anywhere"
           (:h2 (v:esc (excerpt-title excerpt)))
           (:p (v:esc (format nil "~A, characters ~D–~D. This reading keeps the file verbatim (SHA-256 ~A): the bytes of dreyeck/src/catalog-topic-maps.lisp that the candidate's tests ran on on 2026-10-26 and that the collision probe loaded."
                              (namestring file) start end (sha256-hex (octets-of file)))))
           (:p "The candidate's file now holds the corrected guard: " (v:object-ref (excerpt "startup:guard") :select "Source excerpt" :display "its startup check") ". "
               "The records of the collision, which describe this version, are unchanged"
               (let ((finding (collision-finding-if-loaded)))
                 (if finding (v:html ": " (v:object-ref finding :select "Record" :display "the probe's record") ".") (v:html "."))))
           (:pre :style "white-space:pre-wrap;overflow-wrap:anywhere" (v:esc text))
           (reading-links)))))))
