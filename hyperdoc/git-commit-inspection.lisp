;;;; Source-backed Git commit inspection objects.
;;;; Created from SLY MREPL; reload this file instead of redefining ad hoc.

(in-package :hyperdoc)

(define-condition git-command-failed (error)
  ((repository-root
    :reader git-command-failed-repository-root-of
    :initarg :repository-root)
   (arguments
    :reader git-command-failed-arguments-of
    :initarg :arguments)
   (exit-code
    :reader git-command-failed-exit-code-of
    :initarg :exit-code)
   (stdout
    :reader git-command-failed-stdout-of
    :initarg :stdout)
   (stderr
    :reader git-command-failed-stderr-of
    :initarg :stderr))
  (:report
   (lambda (condition stream)
     (format stream
             "Git command failed in ~A: git ~{~A~^ ~} exited with ~D.~%~A"
             (git-command-failed-repository-root-of condition)
             (git-command-failed-arguments-of condition)
             (git-command-failed-exit-code-of condition)
             (git-command-failed-stderr-of condition)))))

(defun git-run-string (repository-root &rest arguments)
  "Run git command ARGUMENTS in REPOSITORY-ROOT and return stdout."
  (multiple-value-bind (stdout stderr exit-code)
      (uiop/run-program:run-program
       (cons "git" arguments)
       :directory repository-root
       :output :string
       :error-output :string
       :ignore-error-status t)
    (unless (zerop exit-code)
      (error 'git-command-failed
             :repository-root repository-root
             :arguments arguments
             :exit-code exit-code
             :stdout stdout
             :stderr stderr))
    stdout))

(defun trim-git-output (string)
  (string-trim '(#\Space #\Tab #\Newline #\Return) string))

(defclass git-commit ()
  ((repository
    :reader git-commit-repository-of
    :initarg :repository)
   (commit-ish
    :reader git-commit-ish-of
    :initarg :commit-ish
    :initform "HEAD"
    :type string)
   (hash
    :reader git-commit-hash-of
    :initarg :hash
    :type string))
  (:documentation
   "Source-backed object representing a Git commit in the live HyperDoc checkout."))

(defmethod print-object ((commit git-commit) stream)
  (print-unreadable-object (commit stream :type t :identity nil)
    (format stream "~A"
            (subseq (git-commit-hash-of commit)
                    0
                    (min 12 (length (git-commit-hash-of commit)))))))

(defvar *last-inspected-git-commit* nil)

(defun make-git-commit
    (&key
       (repository (current-git-repository-checkout))
       (commit-ish "HEAD"))
  "Resolve COMMIT-ISH in REPOSITORY and return a GIT-COMMIT object."
  (let* ((repo-root (git-repository-root-of repository))
         (hash
           (trim-git-output
            (git-run-string repo-root "rev-parse" commit-ish))))
    (make-instance 'git-commit
                   :repository repository
                   :commit-ish commit-ish
                   :hash hash)))

(defun current-head-git-commit ()
  "Return an inspectable object for HEAD in the current HyperDoc checkout."
  (setf *last-inspected-git-commit*
        (make-git-commit :commit-ish "HEAD")))

(defun git-commit-one-line (commit)
  (git-run-string
   (git-repository-root-of (git-commit-repository-of commit))
   "show" "--no-patch" "--oneline" "--decorate" "--no-color"
   (git-commit-hash-of commit)))

(defun git-commit-metadata (commit)
  (git-run-string
   (git-repository-root-of (git-commit-repository-of commit))
   "show" "--no-patch" "--format=fuller" "--no-color"
   (git-commit-hash-of commit)))

(defun git-commit-stat (commit)
  (git-run-string
   (git-repository-root-of (git-commit-repository-of commit))
   "show" "--stat" "--oneline" "--no-color"
   (git-commit-hash-of commit)))

(defun git-commit-patch (commit)
  (git-run-string
   (git-repository-root-of (git-commit-repository-of commit))
   "show" "--stat" "--patch" "--no-color"
   (git-commit-hash-of commit)))

(defun git-commit-changed-files (commit)
  (let ((output
          (git-run-string
           (git-repository-root-of (git-commit-repository-of commit))
           "show" "--name-status" "--format=" "--no-color"
           (git-commit-hash-of commit))))
    (remove ""
            (uiop/utility:split-string output :separator '(#\Newline))
            :test #'string=)))

;;;; Inspectable files changed by a Git commit.

(defclass git-file-at-commit ()
  ((commit
    :reader git-file-commit-of
    :initarg :commit)
   (path
    :reader git-file-path-of
    :initarg :path
    :type string))
  (:documentation
   "A repository file path as seen at a particular Git commit."))

(defmethod print-object ((file git-file-at-commit) stream)
  (print-unreadable-object (file stream :type t :identity nil)
    (format stream "~A @ ~A"
            (git-file-path-of file)
            (subseq (git-commit-hash-of (git-file-commit-of file))
                    0
                    (min 12
                         (length
                          (git-commit-hash-of
                           (git-file-commit-of file))))))))

(defclass git-commit-file-change ()
  ((commit
    :reader git-commit-file-change-commit-of
    :initarg :commit)
   (status
    :reader git-commit-file-change-status-of
    :initarg :status
    :type string)
   (path
    :reader git-commit-file-change-path-of
    :initarg :path
    :type string)
   (old-path
    :reader git-commit-file-change-old-path-of
    :initarg :old-path
    :initform nil
    :type (or null string)))
  (:documentation
   "One file-level name-status row in a Git commit."))

(defmethod print-object ((change git-commit-file-change) stream)
  (print-unreadable-object (change stream :type t :identity nil)
    (format stream "~A ~A"
            (git-commit-file-change-status-of change)
            (git-commit-file-change-path-of change))))

(defun git-status-rename-or-copy-p (status)
  (and (< 0 (length status))
       (find (char status 0) "RC" :test #'char=)))

(defun git-commit-file-change-from-line (commit line)
  "Parse one git show --name-status row into a GIT-COMMIT-FILE-CHANGE."
  (let* ((parts (uiop:split-string line :separator '(#\Tab)))
         (status (or (first parts) ""))
         (rename-or-copy? (git-status-rename-or-copy-p status))
         (old-path (and rename-or-copy? (second parts)))
         (path (if rename-or-copy?
                   (third parts)
                   (second parts))))
    (make-instance 'git-commit-file-change
                   :commit commit
                   :status status
                   :old-path old-path
                   :path (or path ""))))

(defun git-commit-file-changes (commit)
  "Return inspectable file-change objects for COMMIT."
  (mapcar (lambda (line)
            (git-commit-file-change-from-line commit line))
          (git-commit-changed-files commit)))

(defun git-commit-file-change-file (change)
  "Return the changed path as an inspectable file-at-commit object."
  (make-instance 'git-file-at-commit
                 :commit (git-commit-file-change-commit-of change)
                 :path (git-commit-file-change-path-of change)))

(defun git-file-blob-spec (file)
  (format nil "~A:~A"
          (git-commit-hash-of (git-file-commit-of file))
          (git-file-path-of file)))

(defun git-file-contents (file)
  "Return the contents of FILE at its commit.

Deleted paths may not have a blob at the commit itself; callers should handle
GIT-COMMAND-FAILED."
  (git-run-string
   (git-repository-root-of
    (git-commit-repository-of
     (git-file-commit-of file)))
   "show" "--no-color"
   (git-file-blob-spec file)))
