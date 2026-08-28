;;;; Stable local-fixture tests for Dreyeck Git inspection.

(defpackage #:dreyeck/git/tests
  (:use #:cl)
  (:export #:run-git-commit-inspection-smoke-tests))

(in-package #:dreyeck/git/tests)

(defun check (value control &rest arguments)
  (unless value
    (error (apply #'format nil control arguments)))
  value)

(defun write-fixture-source (pathname value)
  (with-open-file (stream pathname
                          :direction :output
                          :if-exists :supersede
                          :if-does-not-exist :create)
    (format stream "(defun fixture-value () ~D)~%" value)))

(defun make-fixture-directory ()
  (let ((directory
          (merge-pathnames
           (format nil "dreyeck-git-reader-~D-~D/"
                   (get-universal-time)
                   (random 1000000))
           (uiop:temporary-directory))))
    (ensure-directories-exist directory)
    directory))

(defun initialize-git-fixture (directory)
  (dreyeck/git:git-run-string directory "init" "--quiet")
  (dreyeck/git:git-run-string directory "config" "user.name"
                              "Dreyeck fixture")
  (dreyeck/git:git-run-string directory "config" "user.email"
                              "fixture@dreyeck.invalid")
  (let ((source (merge-pathnames "example.lisp" directory)))
    (write-fixture-source source 1)
    (dreyeck/git:git-run-string directory "add" "example.lisp")
    (dreyeck/git:git-run-string directory "commit" "--quiet" "-m"
                                "Fixture base")
    (write-fixture-source source 2)
    (dreyeck/git:git-run-string directory "add" "example.lisp")
    (dreyeck/git:git-run-string directory "commit" "--quiet" "-m"
                                "Inspect fixture change"))
  directory)

(defun check-view-method (name object)
  (let ((function (symbol-function name)))
    (check (typep function 'generic-function)
           "Inspector view ~S is not a generic function."
           name)
    (check (compute-applicable-methods function (list object))
           "Inspector view ~S has no applicable method for ~S."
           name object)))

(defun run-git-object-tests ()
  (multiple-value-bind (current-root current-source)
      (dreyeck/git::system-repository-root-info :dreyeck/git)
    (check (probe-file current-root)
           "The Dreyeck repository root ~S is not accessible."
           current-root)
    (check (eq :system-source-default current-source)
           "Unexpected repository-root source ~S."
           current-source))
  (let ((directory (make-fixture-directory)))
    (unwind-protect
         (progn
           (initialize-git-fixture directory)
           (let* ((repository
                    (make-instance 'dreyeck/git:git-repository-checkout
                                   :root directory
                                   :root-source :test-fixture))
                  (commit
                    (dreyeck/git:make-git-commit
                     :repository repository
                     :commit-ish "HEAD"))
                  (changes (dreyeck/git:git-commit-file-changes commit))
                  (change (first changes))
                  (file (dreyeck/git:git-commit-file-change-file change)))
             (check (typep repository
                           'dreyeck/git:git-repository-checkout)
                    "Fixture repository has unexpected type ~S."
                    (type-of repository))
             (check (typep commit 'dreyeck/git:git-commit)
                    "Fixture commit has unexpected type ~S."
                    (type-of commit))
             (check (= 40 (length (dreyeck/git:git-commit-hash-of commit)))
                    "Resolved hash is not full length: ~S."
                    (dreyeck/git:git-commit-hash-of commit))
             (check (search "Inspect fixture change"
                            (dreyeck/git:git-commit-metadata commit))
                    "Commit metadata does not contain the fixture subject.")
             (check (= 1 (length changes))
                    "Expected one file change, got ~S."
                    changes)
             (check (string= "M"
                             (dreyeck/git:git-commit-file-change-status-of
                              change))
                    "Unexpected change status ~S."
                    (dreyeck/git:git-commit-file-change-status-of change))
             (check (string=
                     "example.lisp"
                     (dreyeck/git:git-commit-file-change-path-of change))
                    "Unexpected changed path ~S."
                    (dreyeck/git:git-commit-file-change-path-of change))
             (check (search "fixture-value () 2"
                            (dreyeck/git:git-file-contents file))
                    "Blob reader did not return the committed source.")
             (check (search "+(defun fixture-value () 2)"
                            (dreyeck/git:git-commit-patch commit))
                    "Patch reader did not return the expected added line.")
             (dolist (view '(dreyeck/inspector/git::👀commit
                             dreyeck/inspector/git::👀metadata
                             dreyeck/inspector/git::👀stat
                             dreyeck/inspector/git::👀changed-files
                             dreyeck/inspector/git::👀patch))
               (check-view-method view commit))
             (dolist (view '(dreyeck/inspector/git::👀overview
                             dreyeck/inspector/git::👀contents))
               (check-view-method view file))))
      (uiop:delete-directory-tree directory
                                  :validate t
                                  :if-does-not-exist :ignore)))
  t)

(defun run-repository-slice-commit-test ()
  (let ((directory (make-fixture-directory)))
    (unwind-protect
        (progn
         (initialize-git-fixture directory)
         (let ((common-lisp-user::repository
                (make-instance 'dreyeck/git:git-repository-checkout :root
                               directory :root-source :repository-slice-test)))
           (write-fixture-source (merge-pathnames "example.lisp" directory) 3)
           (let ((common-lisp-user::observation
                  (dreyeck/git:commit-repository-slice
                   common-lisp-user::repository '("example.lisp")
                   "Fixture slice")))
             (check
              (eq :committed (getf common-lisp-user::observation :status))
              "Repository slice did not commit: ~S"
              common-lisp-user::observation))
           (let ((common-lisp-user::observation
                  (dreyeck/git:commit-repository-slice
                   common-lisp-user::repository '("example.lisp")
                   "Nothing to commit")))
             (check
              (eq :nothing-to-commit
                  (getf common-lisp-user::observation :status))
              "Expected :NOTHING-TO-COMMIT, got ~S."
              common-lisp-user::observation))
           (check
            (string= ""
                     (dreyeck/git:git-run-string directory "status" "--short"))
            "Fixture is not clean after repository-slice test.")))
      (uiop/filesystem:delete-directory-tree directory :validate t
                                             :if-does-not-exist :ignore)))
  t)

(defun run-repository-slice-index-guard-test ()
  (let ((directory (make-fixture-directory)))
    (unwind-protect
        (progn
         (initialize-git-fixture directory)
         (let ((common-lisp-user::repository
                (make-instance 'dreyeck/git:git-repository-checkout :root
                               directory :root-source
                               :repository-slice-guard-test)))
           (write-fixture-source (merge-pathnames "foreign.lisp" directory) 9)
           (dreyeck/git:git-run-string directory "add" "--" "foreign.lisp")
           (write-fixture-source (merge-pathnames "example.lisp" directory) 4)
           (let ((common-lisp-user::head-before
                  (dreyeck/git:git-run-string directory "rev-parse" "HEAD"))
                 (common-lisp-user::refused-p nil))
             (handler-case
              (dreyeck/git:commit-repository-slice common-lisp-user::repository
                                                   '("example.lisp")
                                                   "Must not commit")
              (error nil (setf common-lisp-user::refused-p t)))
             (check common-lisp-user::refused-p
                    "Repository slice accepted a nonempty index.")
             (check
              (string= "foreign.lisp"
                       (dreyeck/git:trim-git-output
                        (dreyeck/git:git-run-string directory "diff" "--cached"
                                                    "--name-only")))
              "Foreign staged path changed.")
             (check
              (string= "example.lisp"
                       (dreyeck/git:trim-git-output
                        (dreyeck/git:git-run-string directory "diff"
                                                    "--name-only")))
              "Selected path was staged despite refusal.")
             (check
              (string= common-lisp-user::head-before
                       (dreyeck/git:git-run-string directory "rev-parse"
                                                   "HEAD"))
              "HEAD changed despite repository-slice refusal."))))
      (uiop/filesystem:delete-directory-tree directory :validate t
                                             :if-does-not-exist :ignore)))
  t)

(defun run-git-commit-inspection-smoke-tests ()
  (run-git-object-tests)
  (run-repository-slice-commit-test)
  (run-repository-slice-index-guard-test)
  (format t "Dreyeck Git commit inspection smoke tests passed.~%")
  t)
