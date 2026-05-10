;;;; Source-backed Git commit inspection objects.
;;;; Created from SLY MREPL; reload this file instead of redefining ad hoc.


(IN-PACKAGE :HYPERDOC)


(DEFINE-CONDITION GIT-COMMAND-FAILED
    (ERROR)
    ((REPOSITORY-ROOT :READER GIT-COMMAND-FAILED-REPOSITORY-ROOT-OF :INITARG
      :REPOSITORY-ROOT)
     (ARGUMENTS :READER GIT-COMMAND-FAILED-ARGUMENTS-OF :INITARG :ARGUMENTS)
     (EXIT-CODE :READER GIT-COMMAND-FAILED-EXIT-CODE-OF :INITARG :EXIT-CODE)
     (STDOUT :READER GIT-COMMAND-FAILED-STDOUT-OF :INITARG :STDOUT)
     (STDERR :READER GIT-COMMAND-FAILED-STDERR-OF :INITARG :STDERR))
  (:REPORT
   (LAMBDA (CONDITION STREAM)
     (FORMAT STREAM
             "Git command failed in ~A: git ~{~A~^ ~} exited with ~D.~%~A"
             (GIT-COMMAND-FAILED-REPOSITORY-ROOT-OF CONDITION)
             (GIT-COMMAND-FAILED-ARGUMENTS-OF CONDITION)
             (GIT-COMMAND-FAILED-EXIT-CODE-OF CONDITION)
             (GIT-COMMAND-FAILED-STDERR-OF CONDITION)))))


(DEFUN GIT-RUN-STRING (REPOSITORY-ROOT &REST ARGUMENTS)
  "Run git command ARGUMENTS in REPOSITORY-ROOT and return stdout."
  (MULTIPLE-VALUE-BIND (STDOUT STDERR EXIT-CODE)
      (UIOP/RUN-PROGRAM:RUN-PROGRAM (CONS "git" ARGUMENTS) :DIRECTORY
                                    REPOSITORY-ROOT :OUTPUT :STRING
                                    :ERROR-OUTPUT :STRING :IGNORE-ERROR-STATUS
                                    T)
    (UNLESS (ZEROP EXIT-CODE)
      (ERROR 'GIT-COMMAND-FAILED :REPOSITORY-ROOT REPOSITORY-ROOT :ARGUMENTS
             ARGUMENTS :EXIT-CODE EXIT-CODE :STDOUT STDOUT :STDERR STDERR))
    STDOUT))


(DEFUN TRIM-GIT-OUTPUT (STRING)
  (STRING-TRIM '(#\  #\Tab #\Newline #\Return) STRING))


(DEFCLASS GIT-COMMIT NIL
          ((REPOSITORY :READER GIT-COMMIT-REPOSITORY-OF :INITARG :REPOSITORY)
           (COMMIT-ISH :READER GIT-COMMIT-ISH-OF :INITARG :COMMIT-ISH :INITFORM
            "HEAD" :TYPE STRING)
           (HASH :READER GIT-COMMIT-HASH-OF :INITARG :HASH :TYPE STRING))
          (:DOCUMENTATION
           "Source-backed object representing a Git commit in the live HyperDoc checkout."))


(DEFMETHOD PRINT-OBJECT ((COMMIT GIT-COMMIT) STREAM)
  (PRINT-UNREADABLE-OBJECT (COMMIT STREAM :TYPE T :IDENTITY NIL)
    (FORMAT STREAM "~A"
            (SUBSEQ (GIT-COMMIT-HASH-OF COMMIT) 0
                    (MIN 12 (LENGTH (GIT-COMMIT-HASH-OF COMMIT)))))))


(DEFVAR *LAST-INSPECTED-GIT-COMMIT* NIL)


(DEFUN MAKE-GIT-COMMIT
       (
        &KEY (REPOSITORY (CURRENT-GIT-REPOSITORY-CHECKOUT))
        (COMMIT-ISH "HEAD"))
  "Resolve COMMIT-ISH in REPOSITORY and return a GIT-COMMIT object."
  (LET* ((REPO-ROOT (GIT-REPOSITORY-ROOT-OF REPOSITORY))
         (HASH
          (TRIM-GIT-OUTPUT (GIT-RUN-STRING REPO-ROOT "rev-parse" COMMIT-ISH))))
    (MAKE-INSTANCE 'GIT-COMMIT :REPOSITORY REPOSITORY :COMMIT-ISH COMMIT-ISH
                   :HASH HASH)))


(DEFUN CURRENT-HEAD-GIT-COMMIT ()
  "Return an inspectable object for HEAD in the current HyperDoc checkout."
  (SETF *LAST-INSPECTED-GIT-COMMIT* (MAKE-GIT-COMMIT :COMMIT-ISH "HEAD")))


(DEFUN GIT-COMMIT-ONE-LINE (COMMIT)
  (GIT-RUN-STRING (GIT-REPOSITORY-ROOT-OF (GIT-COMMIT-REPOSITORY-OF COMMIT))
   "show" "--no-patch" "--oneline" "--decorate" "--no-color"
   (GIT-COMMIT-HASH-OF COMMIT)))


(DEFUN GIT-COMMIT-METADATA (COMMIT)
  (GIT-RUN-STRING (GIT-REPOSITORY-ROOT-OF (GIT-COMMIT-REPOSITORY-OF COMMIT))
   "show" "--no-patch" "--format=fuller" "--no-color"
   (GIT-COMMIT-HASH-OF COMMIT)))


(DEFUN GIT-COMMIT-STAT (COMMIT)
  (GIT-RUN-STRING (GIT-REPOSITORY-ROOT-OF (GIT-COMMIT-REPOSITORY-OF COMMIT))
   "show" "--stat" "--oneline" "--no-color" (GIT-COMMIT-HASH-OF COMMIT)))


(DEFUN GIT-COMMIT-PATCH (COMMIT)
  (GIT-RUN-STRING (GIT-REPOSITORY-ROOT-OF (GIT-COMMIT-REPOSITORY-OF COMMIT))
   "show" "--stat" "--patch" "--no-color" (GIT-COMMIT-HASH-OF COMMIT)))


(DEFUN GIT-COMMIT-CHANGED-FILES (COMMIT)
  (LET ((OUTPUT
         (GIT-RUN-STRING
          (GIT-REPOSITORY-ROOT-OF (GIT-COMMIT-REPOSITORY-OF COMMIT)) "show"
          "--name-status" "--format=" "--no-color"
          (GIT-COMMIT-HASH-OF COMMIT))))
    (REMOVE "" (UIOP/UTILITY:SPLIT-STRING OUTPUT :SEPARATOR '(#\Newline)) :TEST
            #'STRING=)))



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
