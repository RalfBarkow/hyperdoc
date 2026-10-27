(defpackage #:topic-maps-deployment-review/tests
  (:use #:cl)
  (:local-nicknames (#:r #:topic-maps-deployment-review) (#:v #:html-inspector-views) (#:tm #:dreyeck/topicmap)
                    (#:snap #:dreyeck/source-snapshot) (#:c #:dreyeck/catalog-topic-maps))
  (:export #:run-tests))
(in-package #:topic-maps-deployment-review/tests)

(defvar *checks* nil)
(defmacro check (label form)
  `(progn (unless ,form (error "Deployment review check failed: ~A" ,label)) (push ,label *checks*)))

(defun html-views (object) (remove-if-not (lambda (view) (typep view 'v::html-view)) (v:all-views object)))
(defun view (object title)
  (or (find title (html-views object) :key #'v:view-title :test #'equal) (error "No view ~S on ~S" title object)))
(defun html (object title) (v:view-html (view object title)))
(defun refs (object title) (let ((view (view object title))) (v:view-html view) (mapcar #'cdr (v:view-references view))))
(defun render-all (object) (dolist (view (html-views object)) (v:view-html view)))

(defun page-titles ()
  "The titles of the pages the system declares, from its own definition."
  (mapcar (lambda (c) (pathname-name (asdf:component-pathname c)))
          (asdf:component-children (asdf:find-component "topic-maps-deployment-review" "pages"))))
(defun pages () (mapcar #'r:review-page (page-titles)))
(defun page-links (page-title)
  "Every expr link of a page as (expression view-title-or-nil), and every page link's title."
  (let ((text (uiop:read-file-string (asdf:system-relative-pathname "topic-maps-deployment-review" (format nil "pages/~A.html" page-title))))
        (exprs nil) (page-refs nil))
    (loop for start = (search "expr=\"" text) then (search "expr=\"" text :start2 (1+ start)) while start
          do (let* ((from (+ start 6)) (to (position #\" text :start from))
                    (tag-end (position #\> text :start to))
                    (view-at (search "view=\"" text :start2 to :end2 tag-end)))
               (push (list (plump:decode-entities (subseq text from to))
                           (and view-at (subseq text (+ view-at 6) (position #\" text :start (+ view-at 6)))))
                     exprs)))
    (loop for start = (search "page=\"" text) then (search "page=\"" text :start2 (1+ start)) while start
          do (push (subseq text (+ start 6) (position #\" text :start (+ start 6))) page-refs))
    (values (reverse exprs) (reverse page-refs))))
(defun evaluate (expression)
  (let ((*package* (find-package :topic-maps-deployment-review))) (eval (read-from-string expression))))

(defun git-state ()
  "What would show the working tree or the index changed."
  (list (r::git-values "status" "--porcelain") (r::sha256-hex (sb-ext:string-to-octets (values (r::git-values "diff" "--binary")) :external-format :utf-8))))
(defun project-packages () (remove-if-not (lambda (p) (uiop:string-prefix-p "DREYECK/WORK/PROJECT" (package-name p))) (list-all-packages)))

(defparameter +kinds+ '("source revision" "exported snapshot" "verification evidence" "ASDF system" "Nix package"
                        "Catalog startup policy" "test execution" "deployment decision"))

(defun run-tests ()
  (let* ((*checks* nil) (workspace (r:the-workspace)) (projection (tm:topicmap-workspace-projection-of workspace))
         (topics (tm:topicmap-projection-topics-of projection)) (associations (tm:topicmap-projection-associations-of projection)))
    (flet ((topic-object (id) (tm:topicmap-topic-object-of (tm:topicmap-projection-topic-by-id projection id))))
      ;; The candidate: Git agrees with the declaration, every tested file is as tested, and nothing is called committed
      ;; that HEAD does not hold.
      (check :declared-paths-agree (if (r::git-available-p) (eq t (r:declared-paths-agree-p)) (eq :unknown (r:declared-paths-agree-p))))
      (check :tested-files-as-tested
             (every #'r:file-matches-tested-p (remove-if-not #'r:file-tested-sha256 (r:candidate-files (r:the-candidate)))))
      (check :every-tested-digest-is-a-candidate-file (= (length (r::tested-digests)) (count-if #'r:file-tested-sha256 (r:candidate-files (r:the-candidate)))))
      (check :states-are-what-git-says
             (every (lambda (f) (member (r:file-state f) (cond ((not (r::git-available-p)) '(:no-git))
                                                               ((equal (r::git-line "rev-parse" "HEAD") r:+base-commit+) '(:uncommitted-new :uncommitted-modified))
                                                               (t '(:uncommitted-new :uncommitted-modified :committed)))))
                    (r:candidate-files (r:the-candidate))))
      (let ((altered (make-instance 'r:candidate-file :path "dreyeck.asd" :kind :asdf :tested-sha256 (make-string 64 :initial-element #\0))))
        (check :changed-since-tested-is-detected
               (and (not (r:file-matches-tested-p altered)) (search "Changed since the tests ran" (html altered "Candidate file")))))
      ;; Rendering every page and every view of every object of the reading runs, loads and writes nothing.
      (let* ((watched (list 'snap:verify-store-snapshot 'snap:verify-snapshot-tree 'r:verify-snapshot-now 'r:try-project-workspace-under-guard
                            'dreyeck/work/topic-maps-ctm-review:run-claim-experiment 'dreyeck/work/topic-maps-project-example:run-example))
             (saved (mapcar #'symbol-function watched)) (calls 0)
             (git-before (git-state)) (loaded-before (asdf:already-loaded-systems)) (packages-before (project-packages)))
        (unwind-protect
             (progn
               (loop for name in watched for fn in saved
                     do (let ((fn fn)) (setf (symbol-function name) (lambda (&rest arguments) (incf calls) (apply fn arguments)))))
               (dolist (page (pages)) (render-all page))
               (dolist (object (append (list (r:the-candidate) workspace (r:the-verification-runner) (r:the-guard-trial)
                                             (r::method-origins) (r:topic-maps-origins-now)
                                             (snap:find-snapshot-manifest c:+topic-maps-commit+))
                                       (r:candidate-files (r:the-candidate)) (r:all-evidence) (r:claims) (r:excerpts)
                                       associations (mapcar #'tm:topicmap-topic-object-of topics)))
                 (render-all object)))
          (loop for name in watched for fn in saved do (setf (symbol-function name) fn)))
        (check :rendering-runs-nothing (zerop calls))
        (let ((git-after (git-state)))
          (unless (equal git-before git-after) (format t "~&GIT-BEFORE ~S~%GIT-AFTER ~S~%" git-before git-after))
          (check :rendering-writes-nothing (equal git-before git-after)))
        (check :rendering-loads-nothing (and (equal loaded-before (asdf:already-loaded-systems)) (equal packages-before (project-packages))
                                             (not (asdf:component-loaded-p "dreyeck/work/project")))))
      ;; Every page the system declares is a page of the book; every link of every page reaches its object and the view it
      ;; names; every claim is linked from a page.
      (check :declared-pages-present (and (= 8 (length (page-titles))) (every #'hyperbook:title-of (pages))))
      (let ((linked nil))
        (dolist (page (pages))
          (multiple-value-bind (exprs page-refs) (page-links (hyperbook:title-of page))
            (dolist (link exprs)
              (destructuring-bind (expression title) link
                (let ((object (evaluate expression)))
                  (push object linked)
                  (check :link-reaches-an-object object)
                  (when title (check :link-reaches-its-view (view object title))))))
            (dolist (title page-refs) (check :page-link-resolves (r:review-page title)))))
        (check :every-claim-linked (every (lambda (claim) (member claim linked :test #'eq)) (r:claims))))
      ;; The subjects: every kind present, each Topic holding the real object, each relation warranted.
      (check :every-subject-kind (every (lambda (kind) (find kind topics :key #'tm:topicmap-topic-type-of :test #'equal)) +kinds+))
      (check :topics-hold-real-objects
             (and (eq (topic-object "asdf-ctm") (asdf:find-system "topic-maps/ctm"))
                  (eq (topic-object "asdf-project") (asdf:find-system "dreyeck/work/project"))
                  (eq (topic-object "startup") #'c:main) (eq (topic-object "candidate") (r:the-candidate))
                  (eq (topic-object "lisp-verifier") (r:the-verification-runner)) (eq (topic-object "guard") (r:the-guard-trial))
                  (eq (topic-object "test-package") (r:evidence "package-check/lisp.log"))
                  (string= c:+topic-maps-commit+ (snap:manifest-commit (topic-object "manifest")))))
      (check :every-relation-warranted
             (every (lambda (a)
                      (and (typep a 'r:warranted-association) (stringp (tm:topicmap-association-type-of a))
                           (member (r:association-class a) '(:observed :derived :inferred :open))
                           (or (r:association-provenance a) (r:association-evidence a))
                           (or (not (eq :observed (r:association-class a))) (r:association-evidence a)
                               (some (lambda (p) (typep p '(or r::git-observation r::method-origins r::deployment-decision)))
                                     (r:association-provenance a)))))
                    associations))
      (check :lineages-observed (or (null (r::topic-maps-repository)) (eq :no (r::observation-answer (getf r::*subjects* :ancestry)))))
      ;; Point: Go to moves it, and the Topicmap at Point says why each of its relations holds.
      (tm:topicmap-workspace-go-to workspace "guard")
      (let ((text (html workspace "Topicmap")) (references (refs workspace "Topicmap"))
            (at-guard (remove-if-not (lambda (a) (or (string= "guard" (tm:topicmap-association-from-of a)) (string= "guard" (tm:topicmap-association-to-of a))))
                                     associations)))
        (check :point-moved (string= "guard" (tm:topicmap-workspace-point-of workspace)))
        (check :warrants-at-point (and (search "Why these relations hold" text)
                                       (every (lambda (a) (member a references :test #'eq)) at-guard)
                                       (member (r:evidence "package-check/executable.log") references :test #'eq))))
      (tm:topicmap-workspace-go-to workspace "candidate")
      ;; Claims: each says how it is known; observed ones have evidence or a live check.
      (check :claims-classified (every (lambda (c) (member (r:claim-class c) '(:observed :derived :inferred :open))) (r:claims)))
      (check :observed-claims-supported
             (every (lambda (c) (or (not (eq :observed (r:claim-class c))) (r:claim-evidence c)
                                    (some (lambda (s) (typep s '(or r::method-origins r:source-excerpt))) (r:claim-sources c))))
                    (r:claims)))
      (check :defect-corrected (not (r::guard-replaced-asdf-methods-p)))
      ;; The way back: every view this reading defines leads to its pages.
      (check :views-lead-back
             (every (lambda (object) (every (lambda (view) (or (not (eq (symbol-package (class-name (class-of object))) (find-package :topic-maps-deployment-review)))
                                                                (search "Back to the reading" (v:view-html view))
                                                                (member (v:view-title view) '("Guard result") :test #'string=)))
                                            (remove-if-not (lambda (view) (member (v:view-title view) '("Candidate" "Candidate file" "Record" "Claim" "Warrant" "Source excerpt" "Verify now" "Guard" "Method origins" "ASDF origins") :test #'string=))
                                                           (html-views object))))
                    (append (list (r:the-candidate) (r:the-verification-runner) (r:the-guard-trial) (r::method-origins) (r:topic-maps-origins-now))
                            (r:all-evidence) (r:claims) (r:excerpts) associations)))
      ;; Only an explicit run runs: the verification and the guard trial.
      (when (equal "nix-store-snapshot" (uiop:getenv "HYPERDOC_EXPECTED_TOPIC_MAPS_SOURCE"))
        (let ((verification (r:verify-snapshot-now)))
          (check :explicit-verification (and (typep verification 'snap:snapshot-verification)
                                             (eq verification (first (first (r:runner-runs (r:the-verification-runner)))))))))
      (let ((result (r:try-project-workspace-under-guard)))
        (check :explicit-guard-trial-refuses (typep (r::result-condition result) 'c:project-workspace-refused))
        (check :guard-trial-loads-nothing (and (r::result-packages-unchanged result) (not (r::result-loaded result)) (null (project-packages))))
        (check :guard-trial-names-the-refused-system (search "dreyeck/work/project" (princ-to-string (r::result-condition result))))))
    (format t "~&TOPIC-MAPS-DEPLOYMENT-REVIEW-PASS: ~D assertions; ~D pages, ~D subjects, ~D warranted relations, ~D claims.~%"
            (length *checks*) (length (pages)) (length (tm:topicmap-projection-topics-of (tm:topicmap-workspace-projection-of (r:the-workspace))))
            (length (tm:topicmap-projection-associations-of (tm:topicmap-workspace-projection-of (r:the-workspace)))) (length (r:claims)))
    t))
