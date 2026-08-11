;;;; Deterministic contracts for read-only Upstream Intake observations.

(defpackage #:dreyeck/upstream-intake/tests
  (:use #:cl)
  (:export #:run-upstream-intake-tests))

(in-package #:dreyeck/upstream-intake/tests)

(defun check (value control &rest arguments)
  (unless value
    (error (apply #'format nil control arguments)))
  value)

(defun make-fixture-directory ()
  (let ((directory
          (merge-pathnames
           (format nil "dreyeck-upstream-intake-~D-~D/"
                   (get-universal-time)
                   (random 1000000))
           (uiop:temporary-directory))))
    (ensure-directories-exist directory)
    directory))

(defun write-fixture-file (directory value)
  (with-open-file
      (stream (merge-pathnames "history.txt" directory)
              :direction :output
              :if-exists :supersede
              :if-does-not-exist :create)
    (format stream "~A~%" value)))

(defun commit-fixture-state (directory value subject)
  (write-fixture-file directory value)
  (dreyeck/git:git-run-string directory "add" "history.txt")
  (dreyeck/git:git-run-string
   directory "commit" "--quiet" "-m" subject)
  (dreyeck/git:trim-git-output
   (dreyeck/git:git-run-string directory "rev-parse" "HEAD")))

(defun initialize-intake-fixture (directory)
  "Create A-B-C on main plus a topic commit D forked from A."
  (dreyeck/git:git-run-string
   directory "init" "--quiet" "--initial-branch=main")
  (dreyeck/git:git-run-string
   directory "config" "user.name" "Upstream Intake fixture")
  (dreyeck/git:git-run-string
   directory "config" "user.email" "intake@dreyeck.invalid")
  (let* ((a (commit-fixture-state directory "A" "Fixture A"))
         (b (commit-fixture-state directory "B" "Fixture B"))
         (c (commit-fixture-state directory "C" "Fixture C")))
    (dreyeck/git:git-run-string directory "branch" "topic" a)
    (dreyeck/git:git-run-string directory "switch" "--quiet" "topic")
    (let ((d (commit-fixture-state directory "D" "Fixture D")))
      (dreyeck/git:git-run-string directory "switch" "--quiet" "main")
      (values a b c d))))

(defun read-file-if-present (pathname)
  (when (probe-file pathname)
    (uiop:read-file-string pathname)))

(defun repository-state (directory)
  "Capture the Git state that a read-only intake must preserve."
  (list
   :head
   (dreyeck/git:git-run-string directory "rev-parse" "HEAD")
   :index
   (dreyeck/git:git-run-string
    directory "diff" "--cached" "--no-ext-diff" "--binary")
   :worktree
   (dreyeck/git:git-run-string
    directory "diff" "--no-ext-diff" "--binary")
   :status
   (dreyeck/git:git-run-string
    directory "status" "--porcelain=v1" "--untracked-files=all")
   :refs
   (dreyeck/git:git-run-string
    directory "for-each-ref" "--format=%(objectname) %(refname)")
   :remotes
   (dreyeck/git:git-run-string directory "remote" "-v")
   :fetch-head
   (read-file-if-present (merge-pathnames ".git/FETCH_HEAD" directory))))

(defun make-fixture-repository (directory)
  (make-instance 'dreyeck/git:git-repository-checkout
                 :root directory
                 :root-source :test-fixture))

(defun check-commit-present-and-ancestor (repository b c)
  (let ((intake
          (dreyeck/upstream-intake:make-upstream-commit-intake
           b :origin "fixture/upstream" :repository repository)))
    (check
     (dreyeck/upstream-intake:git-commit-upstream-object-present-p
      intake)
     "Fixture B was not found as a local commit object.")
    (check
     (dreyeck/upstream-intake:git-commit-upstream-ancestor-of-head-p
      intake)
     "Fixture B was not recognized as an ancestor of C.")
    (check (eq :already-integrated
               (dreyeck/upstream-intake:git-commit-upstream-classification-of
                intake))
           "Ancestor intake received classification ~S."
           (dreyeck/upstream-intake:git-commit-upstream-classification-of
            intake))
    (check
     (member "refs/heads/main"
             (dreyeck/upstream-intake:git-commit-upstream-refs-containing-of
              intake)
             :test #'string=)
     "Refs containing B do not include fixture main.")
    (check
     (string= c
              (dreyeck/git:git-commit-hash-of
               (dreyeck/upstream-intake:upstream-local-context-current-head-of
                (dreyeck/upstream-intake:upstream-reference-local-context-of
                 intake))))
     "Intake did not retain fixture HEAD C.")
    intake))

(defun check-commit-present-and-not-ancestor (repository a d)
  (let ((intake
          (dreyeck/upstream-intake:make-upstream-commit-intake
           d :origin "fixture/topic" :repository repository)))
    (check
     (dreyeck/upstream-intake:git-commit-upstream-object-present-p intake)
     "Fixture topic commit D was not found.")
    (check
     (null
      (dreyeck/upstream-intake:git-commit-upstream-ancestor-of-head-p
       intake))
     "Fixture topic commit D was incorrectly considered integrated.")
    (check (eq :available-not-integrated
               (dreyeck/upstream-intake:git-commit-upstream-classification-of
                intake))
           "Divergent intake received classification ~S."
           (dreyeck/upstream-intake:git-commit-upstream-classification-of
            intake))
    (check
     (member "refs/heads/topic"
             (dreyeck/upstream-intake:git-commit-upstream-refs-containing-of
              intake)
             :test #'string=)
     "Refs containing D do not include fixture topic.")
    (check
     (string= a
              (dreyeck/git:git-commit-hash-of
               (dreyeck/upstream-intake:git-commit-upstream-merge-base-of
                intake)))
     "Divergent intake did not retain merge base A.")
    intake))

(defun check-is-ancestor-exit-one-is-data (repository d c)
  (let ((topic
          (dreyeck/git:make-git-commit
           :repository repository :commit-ish d))
        (head
          (dreyeck/git:make-git-commit
           :repository repository :commit-ish c))
        (result :not-called))
    (handler-case
        (setf result (dreyeck/git:git-commit-ancestor-p topic head))
      (dreyeck/git:git-command-failed (condition)
        (error "merge-base --is-ancestor exit 1 became an error: ~A"
               condition)))
    (check (null result)
           "Expected normal NIL ancestry result, got ~S."
           result)))

(defun check-commit-absent (repository)
  (let ((intake
          (dreyeck/upstream-intake:make-upstream-commit-intake
           "1111111111111111111111111111111111111111"
           :origin "fixture/absent"
           :repository repository)))
    (check
     (null
      (dreyeck/upstream-intake:git-commit-upstream-object-present-p
       intake))
     "Unknown fixture commit was reported as present.")
    (check (eq :not-available-locally
               (dreyeck/upstream-intake:git-commit-upstream-classification-of
                intake))
           "Absent intake received classification ~S."
           (dreyeck/upstream-intake:git-commit-upstream-classification-of
            intake))
    (check
     (null
      (dreyeck/upstream-intake:git-commit-upstream-merge-base-of intake))
     "Absent commit unexpectedly has a merge base.")
    intake))

(defun contract-names (intake)
  (mapcar
   #'dreyeck/upstream-intake:contract-observation-name-of
   (dreyeck/upstream-intake:component-upstream-contracts-of intake)))

(defun check-component-intake (repository)
  (let* ((expected-contracts
           '(:existing-symbol-lookup-preserved
             :local-hyperspec-corpus
             :reproducible-nix-source
             :same-origin-http-serving
             :no-external-runtime-fallback
             :defmethod-resolution
             :runtime-closure-availability))
         (intake
           (dreyeck/upstream-intake:make-component-intake
            :repository repository
            :origin "khinsen/html-inspector-views-hyperspec"
            :component-name "html-inspector-views-hyperspec"
            :reference "khinsen/html-inspector-views-hyperspec"
            :local-subject
            "47e29b3fb89486cc29def9e4c504020d2a714a61"
            :proposed-relation :supersedes
            :status :unverified
            :contracts expected-contracts)))
    (check
     (eq :supersedes
         (dreyeck/upstream-intake:component-upstream-proposed-relation-of
          intake))
     "Component hypothesis lost its proposed SUPERSEDES relation.")
    (check
     (eq :unverified
         (dreyeck/upstream-intake:component-upstream-status-of intake))
     "Component hypothesis was incorrectly verified.")
    (check (equal expected-contracts (contract-names intake))
           "Component contract questions differ: ~S."
           (contract-names intake))
    (check
     (every
      (lambda (contract)
        (eq :unknown
            (dreyeck/upstream-intake:contract-observation-status-of
             contract)))
      (dreyeck/upstream-intake:component-upstream-contracts-of intake))
     "Component contracts must start as UNKNOWN.")
    intake))

(defun check-view (intake &rest expected-texts)
  (let* ((name
           'dreyeck/inspector/upstream-intake::upstream-intake-view)
         (function (symbol-function name)))
    (check (typep function 'generic-function)
           "Upstream Intake view is not a generic function.")
    (check (compute-applicable-methods function (list intake))
           "Upstream Intake view has no method for ~S."
           intake)
    (check
     (find "Upstream Intake"
           (html-inspector-views:all-views intake)
           :key #'html-inspector-views:view-title
           :test #'string=)
     "The Moldable Inspector registry does not expose the Intake view.")
    (let* ((view (funcall function intake))
           (html (html-inspector-views:view-html view)))
      (dolist (expected expected-texts)
        (check (search expected html :test #'char-equal)
               "Upstream Intake view lacks ~S: ~S."
               expected html))
      (check (null (search "<button" html :test #'char-equal))
             "Read-only Intake view unexpectedly renders a button: ~S."
             html)
      (check (null (search "cherry-pick" html :test #'char-equal))
             "Read-only Intake view offers a cherry-pick operation.")))
  t)

(defun run-fixture-tests ()
  (let ((directory (make-fixture-directory)))
    (unwind-protect
         (multiple-value-bind (a b c d)
             (initialize-intake-fixture directory)
           (let* ((repository (make-fixture-repository directory))
                  (before (repository-state directory))
                  (integrated
                    (check-commit-present-and-ancestor repository b c))
                  (not-integrated
                    (check-commit-present-and-not-ancestor repository a d))
                  (absent (check-commit-absent repository))
                  (component (check-component-intake repository)))
             (check-is-ancestor-exit-one-is-data repository d c)
             (check-view integrated "Upstream Intake" "already-integrated")
             (check-view not-integrated "available-not-integrated")
             (check-view absent "not-available-locally")
             (check-view component "SUPERSEDES" "UNVERIFIED"
                         "defmethod-resolution")
             (check (equal before (repository-state directory))
                    "Intake changed HEAD, index, worktree, refs, remotes, or FETCH_HEAD.")))
      (uiop:delete-directory-tree directory
                                  :validate t
                                  :if-does-not-exist :ignore)))
  t)

(defun run-upstream-intake-tests ()
  (run-fixture-tests)
  (check
   (fboundp
    'dreyeck/upstream-intake:hyperdoc-host-not-found-upstream-intake-example)
   "Git-commit Intake example is missing.")
  (check
   (fboundp
    'dreyeck/upstream-intake:hyperspec-component-upstream-intake-example)
   "Component Intake example is missing.")
  (let ((boundary-evidence
          (dreyeck/system-boundaries:check-extension-system-boundaries)))
    (check (every (lambda (record) (getf record :passed))
                  boundary-evidence)
           "Dreyeck system boundary evidence failed: ~S"
           boundary-evidence))
  (format t "Read-only Upstream Intake tests passed.~%")
  t)
