;;;; Stable local-fixture tests for Git-backed HyperDoc inspection objects.

(defpackage :hyperdoc/git/tests
  (:use :cl)
  (:export :run-git-commit-inspection-smoke-tests))

(in-package :hyperdoc/git/tests)

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
           (format nil "hyperdoc-git-reader-~D-~D/"
                   (get-universal-time)
                   (random 1000000))
           (uiop:temporary-directory))))
    (ensure-directories-exist directory)
    directory))

(defun initialize-git-fixture (directory)
  (hyperdoc::git-run-string directory "init" "--quiet")
  (hyperdoc::git-run-string directory "config" "user.name"
                            "HyperDoc fixture")
  (hyperdoc::git-run-string directory "config" "user.email"
                            "fixture@hyperdoc.invalid")
  (let ((source (merge-pathnames "example.lisp" directory)))
    (write-fixture-source source 1)
    (hyperdoc::git-run-string directory "add" "example.lisp")
    (hyperdoc::git-run-string directory "commit" "--quiet" "-m"
                              "Fixture base")
    (write-fixture-source source 2)
    (hyperdoc::git-run-string directory "add" "example.lisp")
    (hyperdoc::git-run-string directory "commit" "--quiet" "-m"
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

(defun run-git-commit-inspection-smoke-tests ()
  (multiple-value-bind (current-root current-source)
      (hyperdoc::system-repository-root-info :hyperdoc)
    (check (probe-file current-root)
           "The HyperDoc repository root ~S is not accessible."
           current-root)
    (check (eq :system-source-default current-source)
           "Unexpected repository-root source ~S."
           current-source))
  (let ((directory (make-fixture-directory)))
    (unwind-protect
         (progn
           (initialize-git-fixture directory)
           (let* ((repository
                    (make-instance 'hyperdoc::git-repository-checkout
                                   :root directory
                                   :root-source :test-fixture))
                  (commit
                    (hyperdoc::make-git-commit
                     :repository repository
                     :commit-ish "HEAD"))
                  (changes (hyperdoc::git-commit-file-changes commit))
                  (change (first changes))
                  (file (hyperdoc::git-commit-file-change-file change)))
             (check (typep repository 'hyperdoc::git-repository-checkout)
                    "Fixture repository has unexpected type ~S."
                    (type-of repository))
             (check (typep commit 'hyperdoc::git-commit)
                    "Fixture commit has unexpected type ~S."
                    (type-of commit))
             (check (= 40 (length (hyperdoc::git-commit-hash-of commit)))
                    "Resolved hash is not full length: ~S."
                    (hyperdoc::git-commit-hash-of commit))
             (check (search "Inspect fixture change"
                            (hyperdoc::git-commit-metadata commit))
                    "Commit metadata does not contain the fixture subject.")
             (check (= 1 (length changes))
                    "Expected one file change, got ~S."
                    changes)
             (check (string= "M"
                             (hyperdoc::git-commit-file-change-status-of
                              change))
                    "Unexpected change status ~S."
                    (hyperdoc::git-commit-file-change-status-of change))
             (check (string= "example.lisp"
                             (hyperdoc::git-commit-file-change-path-of change))
                    "Unexpected changed path ~S."
                    (hyperdoc::git-commit-file-change-path-of change))
             (check (search "fixture-value () 2"
                            (hyperdoc::git-file-contents file))
                    "Blob reader did not return the committed source.")
             (check (search "+(defun fixture-value () 2)"
                            (hyperdoc::git-commit-patch commit))
                    "Patch reader did not return the expected added line.")
             (dolist (view '(hyperdoc/inspector::👀commit
                             hyperdoc/inspector::👀metadata
                             hyperdoc/inspector::👀stat
                             hyperdoc/inspector::👀changed-files
                             hyperdoc/inspector::👀patch))
               (check-view-method view commit))
             (dolist (view '(hyperdoc/inspector::👀overview
                             hyperdoc/inspector::👀contents))
               (check-view-method view file))))
      (uiop:delete-directory-tree directory
                                  :validate t
                                  :if-does-not-exist :ignore)))
  (format t "Git commit inspection smoke tests passed.~%")
  t)
