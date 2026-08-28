(in-package #:dreyeck/git)

(defclass git-source-slice nil
          ((commit :reader git-source-slice-commit-of :initarg :commit)
           (selections :reader git-source-slice-selections-of :initarg
            :selections)
           (sparse-mode :reader git-source-slice-sparse-mode-of :initarg
            :sparse-mode))
          (:documentation
           "A Git source identity together with its sparse materialization policy."))

(defun make-git-source-slice
       (
        &key common-lisp-user::commit common-lisp-user::selections
        common-lisp-user::sparse-mode)
  "Construct a Git source slice for COMMIT and sparse SELECTIONS."
  (check-type common-lisp-user::commit git-commit)
  (unless
      (and (listp common-lisp-user::selections) common-lisp-user::selections)
    (error "Git source slice selections must be a non-empty list: ~S"
           common-lisp-user::selections))
  (unless (member common-lisp-user::sparse-mode '(:cone :no-cone))
    (error "Unsupported Git source slice sparse mode: ~S"
           common-lisp-user::sparse-mode))
  (make-instance 'git-source-slice :commit common-lisp-user::commit :selections
                 common-lisp-user::selections :sparse-mode
                 common-lisp-user::sparse-mode))

(defun materialize-git-source-slice
       (common-lisp-user::slice common-lisp-user::target-root)
  "Materialize SLICE as a sparse checkout rooted at TARGET-ROOT."
  (check-type common-lisp-user::slice git-source-slice)
  (check-type common-lisp-user::target-root pathname)
  (when (probe-file common-lisp-user::target-root)
    (error "Git source slice target already exists: ~S"
           common-lisp-user::target-root))
  (let* ((common-lisp-user::commit
          (git-source-slice-commit-of common-lisp-user::slice))
         (common-lisp-user::repository
          (git-commit-repository-of common-lisp-user::commit))
         (common-lisp-user::source-root
          (git-repository-root-of common-lisp-user::repository))
         (common-lisp-user::commit-hash
          (git-commit-hash-of common-lisp-user::commit))
         (common-lisp-user::selections
          (git-source-slice-selections-of common-lisp-user::slice))
         (common-lisp-user::sparse-mode
          (git-source-slice-sparse-mode-of common-lisp-user::slice)))
    (git-run-string common-lisp-user::source-root "clone" "--quiet"
                    "--no-checkout" "--local"
                    (namestring common-lisp-user::source-root)
                    (namestring common-lisp-user::target-root))
    (git-run-string common-lisp-user::target-root "sparse-checkout" "init"
                    (ecase common-lisp-user::sparse-mode
                      (:cone "--cone")
                      (:no-cone "--no-cone")))
    (apply #'git-run-string common-lisp-user::target-root "sparse-checkout"
           "set" common-lisp-user::selections)
    (git-run-string common-lisp-user::target-root "checkout" "--quiet"
                    common-lisp-user::commit-hash)
    (make-instance 'git-repository-checkout :root common-lisp-user::target-root
                   :root-source common-lisp-user::slice)))
