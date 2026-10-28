(defpackage #:topic-maps-task-1e-review/tests
  (:use #:cl)
  (:local-nicknames (#:r #:topic-maps-task-1e-review) (#:v #:html-inspector-views) (#:snap #:dreyeck/source-snapshot) (#:p #:dreyeck/work/project))
  (:export #:run-tests))
(in-package #:topic-maps-task-1e-review/tests)

(defvar *checks* nil)
(defmacro check (label form)
  `(progn (unless ,form (error "Task 1E re-pin review check failed: ~A" ,label)) (push ,label *checks*)))

(defun root () (asdf:system-source-directory "topic-maps-task-1e-review"))
(defun hyperdoc-root () (asdf:system-source-directory "dreyeck"))
(defun page-titles ()
  (mapcar #'pathname-name (remove-if-not (lambda (path) (equal "html" (pathname-type path))) (uiop:directory-files (merge-pathnames "pages/" (root))))))
(defun page-text (title) (uiop:read-file-string (merge-pathnames (format nil "pages/~A.html" title) (root))))
(defun occurrences (needle text) (loop for start = (search needle text) then (search needle text :start2 (1+ start)) while start count t))
(defun links (title)
  (let ((text (page-text title)) (out nil))
    (loop for start = (search "expr=\"" text) then (search "expr=\"" text :start2 (1+ start)) while start
          do (let* ((from (+ start 6)) (to (position #\" text :start from)) (tag-end (position #\> text :start to))
                    (at (search "view=\"" text :start2 to :end2 tag-end)))
               (push (list (plump:decode-entities (subseq text from to)) (and at (subseq text (+ at 6) (position #\" text :start (+ at 6))))) out)))
    (nreverse out)))
(defun pages-linked (title)
  (let ((text (page-text title)) (out nil))
    (loop for start = (search "page=\"" text) then (search "page=\"" text :start2 (1+ start)) while start
          do (push (subseq text (+ start 6) (position #\" text :start (+ start 6))) out))
    out))
(defun evaluate (expression) (let ((*package* (find-package :topic-maps-task-1e-review))) (eval (read-from-string expression))))
(defun html (object title)
  (v:view-html (or (find title (remove-if-not (lambda (view) (typep view 'v::html-view)) (v:all-views object)) :key #'v:view-title :test #'equal)
                   (error "No view ~S" title))))
(defun git (&rest args)
  (string-trim '(#\Newline) (uiop:run-program (list* "git" "-C" (namestring (hyperdoc-root)) args) :output :string)))

(defun page-tests ()
  (let ((titles (page-titles)))
    (check "pages:six" (= 6 (length titles)))
    (check "pages:main" (member "Re-pinning Topic Maps to 88994c1b" titles :test #'string=))
    (dolist (title titles)
      (check (format nil "page:~A:found" title) (r:review-page title))
      (dolist (target (pages-linked title)) (check (format nil "page:~A:links:~A" title target) (member target titles :test #'string=)))
      (dolist (entry (links title))
        (let ((object (evaluate (first entry))))
          (check (format nil "page:~A:~A:evaluates" title (first entry)) object)
          (when (second entry) (check (format nil "page:~A:~A:view-exists" title (first entry)) (let ((view (find (second entry) (v:all-views object) :key (function v:view-title) :test (function equal)))) (and view (or (not (typep view (quote v::html-view))) (v:view-html view)))))))))
    ;; A page that is not in the book is refused: the check can fail.
    (check "pages:negative:unknown-page-is-refused" (handler-case (progn (r:review-page "No Such Page") nil) (error () t)))))

(defun evidence-tests ()
  (let* ((records (r:records))
         (files (mapcar #'file-namestring (remove "SHA256SUMS" (uiop:directory-files (merge-pathnames "evidence/" (root))) :key #'file-namestring :test #'string=))))
    (check "evidence:every-record-has-a-file-and-every-file-a-record"
           (and (null (set-difference files (mapcar #'r:record-file records) :test #'string=))
                (null (set-difference (mapcar #'r:record-file records) files :test #'string=))))
    (check "evidence:every-record-matches-SHA256SUMS" (every #'r:record-intact-p records))
    (check "evidence:negative:altered-bytes-do-not-match"
           (let* ((rec (first records)) (octets (copy-seq (alexandria:read-file-into-byte-vector (r::evidence-pathname (r:record-file rec))))))
             (setf (aref octets 0) (logxor 1 (aref octets 0)))
             (not (equal (ironclad:byte-array-to-hex-string (ironclad:digest-sequence :sha256 octets)) (r:recorded-sha256 (r:record-file rec))))))))

(defvar *skipped* nil "Checks that could not be made in this image, said aloud and not counted as passes.")
(defun skip (label reason) (push (format nil "~A: ~A" label reason) *skipped*))

(defun repository ()
  (let ((path (uiop:getenv "TOPIC_MAPS_REPOSITORY")))
    (and path (plusp (length path)) (probe-file (merge-pathnames ".git" (uiop:ensure-directory-pathname path))) (uiop:ensure-directory-pathname path))))
(defun topic-maps-git (&rest args)
  (string-trim '(#\Newline) (uiop:run-program (list* "git" "-C" (namestring (repository)) args) :output :string)))
(defun commit-object-line (object prefix)
  (let ((line (find-if (lambda (l) (uiop:string-prefix-p prefix l)) (uiop:split-string object :separator '(#\Newline)))))
    (and line (subseq line (length prefix)))))

(defun pin-tests ()
  (let* ((manifest (snap:find-snapshot-manifest r:+commit+)) (object (snap:manifest-commit-object manifest)))
    ;; Git-free: the manifest's raw commit object hashes, as Git hashes a commit, to the commit the reading names.
    (check "pins:the-manifest-commit-object-hashes-to-the-commit"
           (and (string= r:+commit+ (snap:manifest-commit manifest))
                (string= r:+commit+ (snap:git-object-id "commit" (sb-ext:string-to-octets object :external-format :utf-8)))))
    (check "pins:the-commit-object-names-the-previous-pin-as-its-parent" (equal r:+parent-commit+ (commit-object-line object "parent ")))
    (check "pins:the-commit-object-names-its-root-tree-as-the-manifest-does" (equal (snap:manifest-root-tree manifest) (commit-object-line object "tree ")))
    (check "pins:the-manifest-excludes-only-reports" (equal '("reports") (snap:manifest-excluded manifest)))
    ;; Against the actual repository, when this image has one.
    (if (repository)
        (progn
          (check "pins:git-says-the-commit-is-a-commit" (string= "commit" (topic-maps-git "cat-file" "-t" r:+commit+)))
          (check "pins:git-says-the-parent-is-the-previous-pin" (string= r:+parent-commit+ (topic-maps-git "rev-parse" (format nil "~A^" r:+commit+))))
          (check "pins:git-says-the-tree-is-the-manifest-root-tree" (string= (snap:manifest-root-tree manifest) (topic-maps-git "rev-parse" (format nil "~A^{tree}" r:+commit+))))
          (check "pins:git-says-the-raw-commit-object-is-the-manifest-one"
                 (string= (string-right-trim '(#\Newline) object) (string-right-trim '(#\Newline) (topic-maps-git "cat-file" "commit" r:+commit+)))))
        (skip "pins:git-oracle" "TOPIC_MAPS_REPOSITORY is not a Git repository in this image")))
  ;; What this image loaded is the pin: a clean checkout at it or a verified snapshot of it, by HyperDoc's own check.
  (let ((identity (p::topic-maps-source-identity)))
    (check "pins:this-image-loaded-the-pinned-source" (and (getf identity :pinned) (member (getf identity :kind) '(:git-checkout :verified-nix-store-snapshot))))
    (check "pins:the-source-identity-names-the-commit" (equal r:+commit+ (getf identity :commit)))
    (check "pins:negative:an-unidentified-directory-is-not-pinned"
           (let ((other (p::topic-maps-source-identity (uiop:temporary-directory))))
             (and (eq :unverifiable (getf other :kind)) (null (getf other :commit)) (null (getf other :pinned))))))
  (check "pins:all-four-name-the-commit" (every (lambda (row) (equal r:+commit+ (r:pin-row-pin row))) (r:pin-rows)))
  (check "pins:negative:the-previous-commit-is-not-the-workspace-pin" (not (equal r:+parent-commit+ p::+topic-maps-revision+)))
  (check "pins:pinned-state-p-positive-control" (p::pinned-state-p r:+commit+ "" t))
  (check "pins:negative:the-previous-commit-is-not-pinned" (not (p::pinned-state-p r:+parent-commit+ "" t)))
  (check "pins:negative:a-changed-tree-is-not-pinned" (not (p::pinned-state-p r:+commit+ " M src/tmdm/associations.lisp" t)))
  (check "pins:negative:two-roots-are-not-pinned" (not (p::pinned-state-p r:+commit+ "" nil)))
  (check "pins:the-previous-manifests-are-kept-as-history"
         (and (probe-file (merge-pathnames "nix/topic-maps-6162ed68.manifest" (hyperdoc-root))) (probe-file (merge-pathnames "nix/topic-maps-b2eecffa.manifest" (hyperdoc-root)))))
  (check "pins:the-nix-source-names-the-archive-and-the-nar-hash-of-the-manifest"
         (let ((text (uiop:read-file-string (merge-pathnames "nix/topic-maps-source.nix" (hyperdoc-root)))))
           (and (search "topic-maps-88994c1b-runtime.tar.gz" text)
                (search (format nil "hash = \"~A\"" (snap:manifest-nar-hash (snap:find-snapshot-manifest r:+commit+))) text))))
  (check "pins:pins-view-renders-and-says-yes" (let ((h (html (r:the-pins) "Pins"))) (and (search "yes" h) (not (search ">NO<" h))))))

(defun file-digests (directory)
  (sort (mapcar (lambda (path) (cons (file-namestring path) (ironclad:byte-array-to-hex-string (ironclad:digest-file :sha256 path))))
                (uiop:directory-files directory))
        #'string< :key #'car))
(defun wall-of (file)
  "The first PROJECT-WORKSPACE wall= seconds in an evidence log."
  (let* ((text (r:record-text (r:record file))) (at (search "PROJECT-WORKSPACE wall=" text)))
    (and at (let ((start (+ at (length "PROJECT-WORKSPACE wall="))))
              (/ (round (* 10 (let ((*read-default-float-format* 'double-float)) (read-from-string text t nil :start start)))) 10.0d0)))))

(defun claim-tests ()
  ;; Rendering reads files and nothing else: no evidence or page byte changes, no system gets loaded, no record is replaced.
  (let ((evidence-before (file-digests (merge-pathnames "evidence/" (root)))) (pages-before (file-digests (merge-pathnames "pages/" (root))))
        (systems-before (sort (copy-list (asdf:already-loaded-systems)) #'string<)) (records-before (r:records)) (pin-before (mapcar #'r:pin-row-pin (r:pin-rows))))
    (dolist (rec (r:records)) (html rec "Record"))
    (html (r:the-pins) "Pins")
    (check "rendering:changes-no-evidence-or-page-byte" (and (equal evidence-before (file-digests (merge-pathnames "evidence/" (root)))) (equal pages-before (file-digests (merge-pathnames "pages/" (root))))))
    (check "rendering:loads-no-system" (equal systems-before (sort (copy-list (asdf:already-loaded-systems)) #'string<)))
    (check "rendering:replaces-no-record-and-moves-no-pin" (and (eq records-before (r:records)) (equal pin-before (mapcar #'r:pin-row-pin (r:pin-rows))))))
  (let ((code (uiop:read-file-string (merge-pathnames "code/review.lisp" (root)))))
    (check "code:defines-no-button-example-or-subprocess"
           (notany (lambda (needle) (search needle code)) '("eval-button" "v:thunk" "defexample" "run-program" "run-tests" "asdf:load-system" "asdf:test-system"))))
  ;; Numbers on the Project Workspace page are the walls in its records.
  (let ((page (page-text "Project Workspace on 88994c1b")))
    (dolist (entry '(("workspace-original-ctm-git-checkout.log" 21.9) ("workspace-original-ctm-verified-snapshot.log" 11.6)
                     ("workspace-stage1-ctm-git-checkout-run1.log" 20.9) ("workspace-stage1-ctm-git-checkout-run2.log" 23.8)
                     ("workspace-stage1-ctm-verified-snapshot.log" 32.3)))
      (check (format nil "numbers:~A:page-states-the-recorded-wall" (first entry))
             (and (< (abs (- (wall-of (first entry)) (second entry))) 0.051) (search (format nil ">~,1F" (second entry)) page))))
    (check "numbers:the-original-and-stage-1-digests-are-the-ones-the-logs-read"
           (and (search "f4f04bb49ce3b762b3e1c0bccf9e177e11785d33db87e8c0d043b04820b540d3" (r:record-text (r:record "workspace-original-ctm-git-checkout.log")))
                (search "fe2955e93239704673a2a38492ea92e57f0d221f14313603dd1dd5f206b340b8" (r:record-text (r:record "workspace-stage1-ctm-git-checkout-run1.log")))
                (search "fe2955e93239704673a2a38492ea92e57f0d221f14313603dd1dd5f206b340b8" (r:record-text (r:record "control-stage1-ctm-at-6162ed68.log")))
                (search "fe2955e9" (page-text "The Stage 1 CTM and the Proposed Work Packages")))))
  ;; The original CTM in this tree is the one the original rows used.
  (check "numbers:the-original-ctm-in-this-tree-has-the-recorded-digest"
         (string= "f4f04bb49ce3b762b3e1c0bccf9e177e11785d33db87e8c0d043b04820b540d3"
                  (ironclad:byte-array-to-hex-string (ironclad:digest-file :sha256 (p::project-ctm-pathname)))))
  ;; The control and the new-pin run have the same CTM bytes and differ in the pin.
  (check "control:same-bytes-different-pin"
         (let ((old (r:record-text (r:record "control-stage1-ctm-at-6162ed68.log"))) (new (r:record-text (r:record "control-stage1-ctm-at-88994c1b.log"))))
           (and (search "PIN-NOT-OK" old) (search "PIN-OK" new) (not (search "PIN-NOT-OK" new))
                (search "CTM-INPUT-SHA256 fe2955e9" old) (search "CTM-INPUT-SHA256 fe2955e9" new))))
  ;; What the pages must say, stated as contracts of their text.
  (let ((remaining (page-text "Remaining Requirements")))
    (dolist (needle '("Linux" "resident set size" "Stage 2" "High-arity" "Unicode" "Deployment" "Catalog test suite" "uncommitted"))
      (check (format nil "remaining:names:~A" needle) (search needle remaining))))
  (let ((stage1 (page-text "The Stage 1 CTM and the Proposed Work Packages")))
    (check "stage1-page:says-the-final-bytes-were-compared-and-the-older-readings-were-another-state" (and (search "same bytes" stage1) (search "203900cb" stage1)))
    (check "stage1-page:says-the-proposal-is-not-promoted" (and (search "does not promote" stage1) (search "stay proposed" stage1)))))

(defun run-tests ()
  (let ((*checks* nil) (*skipped* nil))
    (page-tests) (evidence-tests) (pin-tests) (claim-tests)
    (format t "~&TOPIC-MAPS-TASK-1E-REVIEW-PASS: ~D checks: pages and links, evidence digests, the pins read from the loaded source, the manifest, and the stated limits.~%" (length *checks*))
    (dolist (s (reverse *skipped*)) (format t "~&SKIPPED (not a pass): ~A~%" s))
    (finish-output)
    t))
