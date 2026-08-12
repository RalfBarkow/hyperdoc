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

(defun run-git-commit-inspection-smoke-tests ()
  (run-git-object-tests)
  (format t "Dreyeck Git commit inspection smoke tests passed.~%")
  t)
