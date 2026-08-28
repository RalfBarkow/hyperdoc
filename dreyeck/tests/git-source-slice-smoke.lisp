(in-package #:dreyeck/git/tests)

(defun run-git-source-slice-no-cone-test ()
  (let* ((directory (make-fixture-directory))
         (common-lisp-user::target-root
          (merge-pathnames
           (format nil "dreyeck-git-materialized-~D-~D/" (get-universal-time)
                   (random 1000000))
           (uiop/stream:temporary-directory))))
    (unwind-protect
        (progn
         (initialize-git-fixture directory)
         (check (not (probe-file common-lisp-user::target-root))
                "Materialization target already exists: ~S"
                common-lisp-user::target-root)
         (let* ((common-lisp-user::repository
                 (make-instance 'dreyeck/git:git-repository-checkout :root
                                directory :root-source :git-source-slice-test))
                (common-lisp-user::source-head
                 (dreyeck/git:trim-git-output
                  (dreyeck/git:git-run-string directory "rev-parse" "HEAD")))
                (common-lisp-user::commit
                 (dreyeck/git:make-git-commit :repository
                                              common-lisp-user::repository
                                              :commit-ish "HEAD~1"))
                (common-lisp-user::slice
                 (dreyeck/git:make-git-source-slice :commit
                                                    common-lisp-user::commit
                                                    :selections
                                                    '("/example.lisp")
                                                    :sparse-mode :no-cone))
                (common-lisp-user::materialized
                 (dreyeck/git:materialize-git-source-slice
                  common-lisp-user::slice common-lisp-user::target-root))
                (common-lisp-user::materialized-root
                 (dreyeck/git:git-repository-root-of
                  common-lisp-user::materialized)))
           (check
            (string= (dreyeck/git:git-commit-hash-of common-lisp-user::commit)
                     (dreyeck/git:trim-git-output
                      (dreyeck/git:git-run-string
                       common-lisp-user::materialized-root "rev-parse"
                       "HEAD")))
            "Materialized checkout is not at the requested commit.")
           (check
            (eq common-lisp-user::slice
                (dreyeck/git:git-repository-root-source-of
                 common-lisp-user::materialized))
            "Materialized checkout does not retain its source slice.")
           (check
            (probe-file
             (merge-pathnames "example.lisp"
                              common-lisp-user::materialized-root))
            "Selected root file was not materialized.")
           (check
            (string= common-lisp-user::source-head
                     (dreyeck/git:trim-git-output
                      (dreyeck/git:git-run-string directory "rev-parse"
                                                  "HEAD")))
            "Source checkout HEAD changed during materialization.")))
      (when (probe-file common-lisp-user::target-root)
        (uiop/filesystem:delete-directory-tree common-lisp-user::target-root
                                               :validate t :if-does-not-exist
                                               :ignore))
      (uiop/filesystem:delete-directory-tree directory :validate t
                                             :if-does-not-exist :ignore)))
  t)

(defun run-git-source-slice-cone-test ()
  (let* ((directory (make-fixture-directory))
         (common-lisp-user::target-root
          (merge-pathnames
           (format nil "dreyeck-git-cone-materialized-~D-~D/"
                   (get-universal-time) (random 1000000))
           (uiop/stream:temporary-directory))))
    (unwind-protect
        (progn
         (initialize-git-fixture directory)
         (let ((common-lisp-user::selected
                (merge-pathnames "nested/inside.lisp" directory))
               (common-lisp-user::outside
                (merge-pathnames "other/outside.lisp" directory)))
           (ensure-directories-exist common-lisp-user::selected)
           (ensure-directories-exist common-lisp-user::outside)
           (write-fixture-source common-lisp-user::selected 10)
           (write-fixture-source common-lisp-user::outside 20)
           (dreyeck/git:git-run-string directory "add" "nested/inside.lisp"
                                       "other/outside.lisp")
           (dreyeck/git:git-run-string directory "commit" "--quiet" "-m"
                                       "Add cone fixture"))
         (let* ((common-lisp-user::repository
                 (make-instance 'dreyeck/git:git-repository-checkout :root
                                directory :root-source
                                :git-source-slice-cone-test))
                (common-lisp-user::source-head
                 (dreyeck/git:trim-git-output
                  (dreyeck/git:git-run-string directory "rev-parse" "HEAD")))
                (common-lisp-user::commit
                 (dreyeck/git:make-git-commit :repository
                                              common-lisp-user::repository
                                              :commit-ish "HEAD"))
                (common-lisp-user::slice
                 (dreyeck/git:make-git-source-slice :commit
                                                    common-lisp-user::commit
                                                    :selections '("nested")
                                                    :sparse-mode :cone))
                (common-lisp-user::materialized
                 (dreyeck/git:materialize-git-source-slice
                  common-lisp-user::slice common-lisp-user::target-root))
                (common-lisp-user::materialized-root
                 (dreyeck/git:git-repository-root-of
                  common-lisp-user::materialized)))
           (check
            (string= (dreyeck/git:git-commit-hash-of common-lisp-user::commit)
                     (dreyeck/git:trim-git-output
                      (dreyeck/git:git-run-string
                       common-lisp-user::materialized-root "rev-parse"
                       "HEAD")))
            "Cone materialization is not at the requested commit.")
           (check
            (probe-file
             (merge-pathnames "nested/inside.lisp"
                              common-lisp-user::materialized-root))
            "Selected cone subtree was not materialized.")
           (check
            (not
             (probe-file
              (merge-pathnames "other/outside.lisp"
                               common-lisp-user::materialized-root)))
            "Unselected sibling subtree was materialized.")
           (check
            (eq common-lisp-user::slice
                (dreyeck/git:git-repository-root-source-of
                 common-lisp-user::materialized))
            "Materialized checkout does not retain its source slice.")
           (check
            (string= common-lisp-user::source-head
                     (dreyeck/git:trim-git-output
                      (dreyeck/git:git-run-string directory "rev-parse"
                                                  "HEAD")))
            "Source checkout HEAD changed during cone materialization.")))
      (when (probe-file common-lisp-user::target-root)
        (uiop/filesystem:delete-directory-tree common-lisp-user::target-root
                                               :validate t :if-does-not-exist
                                               :ignore))
      (uiop/filesystem:delete-directory-tree directory :validate t
                                             :if-does-not-exist :ignore)))
  t)

(defun run-git-source-slice-existing-target-test ()
  (let* ((directory (make-fixture-directory))
         (common-lisp-user::target-root
          (merge-pathnames
           (format nil "dreyeck-git-existing-target-~D-~D/"
                   (get-universal-time) (random 1000000))
           (uiop/stream:temporary-directory)))
         (common-lisp-user::marker
          (merge-pathnames "marker.txt" common-lisp-user::target-root)))
    (unwind-protect
        (progn
         (initialize-git-fixture directory)
         (ensure-directories-exist common-lisp-user::marker)
         (with-open-file
             (stream common-lisp-user::marker :direction :output
              :if-does-not-exist :create :if-exists :error)
           (write-string "preserve" stream))
         (let* ((common-lisp-user::repository
                 (make-instance 'dreyeck/git:git-repository-checkout :root
                                directory :root-source
                                :git-source-slice-existing-target-test))
                (common-lisp-user::source-head
                 (dreyeck/git:trim-git-output
                  (dreyeck/git:git-run-string directory "rev-parse" "HEAD")))
                (common-lisp-user::commit
                 (dreyeck/git:make-git-commit :repository
                                              common-lisp-user::repository
                                              :commit-ish "HEAD~1"))
                (common-lisp-user::slice
                 (dreyeck/git:make-git-source-slice :commit
                                                    common-lisp-user::commit
                                                    :selections
                                                    '("/example.lisp")
                                                    :sparse-mode :no-cone))
                (common-lisp-user::rejected-p nil))
           (handler-case
            (dreyeck/git:materialize-git-source-slice common-lisp-user::slice
                                                      common-lisp-user::target-root)
            (error nil (setf common-lisp-user::rejected-p t)))
           (check common-lisp-user::rejected-p
                  "Existing target was accepted: ~S"
                  common-lisp-user::target-root)
           (check (probe-file common-lisp-user::marker)
                  "Existing target marker disappeared.")
           (check
            (with-open-file (stream common-lisp-user::marker :direction :input)
              (string= "preserve" (read-line stream nil "")))
            "Existing target marker was modified.")
           (check
            (not
             (probe-file
              (merge-pathnames ".git/" common-lisp-user::target-root)))
            "Materializer initialized Git in the existing target.")
           (check
            (string= common-lisp-user::source-head
                     (dreyeck/git:trim-git-output
                      (dreyeck/git:git-run-string directory "rev-parse"
                                                  "HEAD")))
            "Source checkout HEAD changed after target rejection.")))
      (when (probe-file common-lisp-user::target-root)
        (uiop/filesystem:delete-directory-tree common-lisp-user::target-root
                                               :validate t :if-does-not-exist
                                               :ignore))
      (uiop/filesystem:delete-directory-tree directory :validate t
                                             :if-does-not-exist :ignore)))
  t)

(defun run-git-source-slice-smoke-tests ()
  (run-git-source-slice-no-cone-test)
  (run-git-source-slice-cone-test)
  (run-git-source-slice-existing-target-test)
  (format t "Dreyeck Git source slice smoke tests passed.~%")
  t)
