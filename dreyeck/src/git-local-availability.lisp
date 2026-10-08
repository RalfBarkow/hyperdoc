;;;; Local Git Objects as Optional Runtime Resources

(IN-PACKAGE #:DREYECK/GIT)

(DEFUN GIT-RUN-VALUES-WITH-INPUT (REPOSITORY-ROOT INPUT &REST ARGUMENTS)
       "Run exactly the requested Git command, disabling implicit promisor fetching.
Unsupported Git options and other command failures remain Git errors."
       (UIOP/RUN-PROGRAM:RUN-PROGRAM (LIST* "git" "--no-lazy-fetch" ARGUMENTS)
                                     :DIRECTORY REPOSITORY-ROOT :INPUT INPUT
                                     :OUTPUT :STRING :ERROR-OUTPUT :STRING
                                     :IGNORE-ERROR-STATUS T))

(DEFUN GIT-LOCAL-CHECKOUT-AVAILABLE-P (REPOSITORY)
  "Check the optional runtime resource without invoking Git or using an ancestor."
  (AND REPOSITORY
       (LET ((ROOT (GIT-REPOSITORY-ROOT-OF REPOSITORY)))
         (AND (UIOP/FILESYSTEM:DIRECTORY-EXISTS-P ROOT)
              (OR (PROBE-FILE (MERGE-PATHNAMES ".git" ROOT))
                  (AND (PROBE-FILE (MERGE-PATHNAMES "HEAD" ROOT))
                       (UIOP/FILESYSTEM:DIRECTORY-EXISTS-P
                        (MERGE-PATHNAMES "objects/" ROOT))))))))

(DEFUN GIT-LOCAL-OBJECT-KIND (REPOSITORY SPEC)
  "Return an object's kind, or NIL only for Git's successful batch missing response.
A failed Git command remains a GIT-COMMAND-FAILED, including exit 128."
  (WHEN (FIND #\Newline SPEC)
    (ERROR
     "Git batch inspection requires a single-line object specification."))
  (LET ((ROOT (GIT-REPOSITORY-ROOT-OF REPOSITORY))
        (ARGUMENTS '("cat-file" "--batch-check=%(objecttype)")))
    (WITH-INPUT-FROM-STRING (INPUT (FORMAT NIL "~A~%" SPEC))
      (MULTIPLE-VALUE-BIND (STDOUT STDERR EXIT-CODE)
          (APPLY #'GIT-RUN-VALUES-WITH-INPUT ROOT INPUT ARGUMENTS)
        (UNLESS (ZEROP EXIT-CODE)
          (SIGNAL-GIT-COMMAND-FAILED ROOT ARGUMENTS STDOUT STDERR EXIT-CODE))
        (LET ((ANSWER (STRING-RIGHT-TRIM '(#\Newline #\Return) STDOUT)))
          (COND ((EQUAL ANSWER (CONCATENATE 'STRING SPEC " missing")) NIL)
                ((MEMBER ANSWER '("commit" "blob" "tree" "tag") :TEST #'EQUAL)
                 ANSWER)
                (T
                 (ERROR "Unexpected Git object availability response: ~S"
                        STDOUT))))))))

(DEFGENERIC GIT-LOCAL-OBJECT-STATUS
    (OBJECT)
  (:DOCUMENTATION
   "Availability of a runtime checkout, exact commit, or exact file blob.
This does not fetch, clone, substitute a checkout, or alter evidence identity."))

(DEFMETHOD GIT-LOCAL-OBJECT-STATUS ((REPOSITORY GIT-REPOSITORY-CHECKOUT))
  (IF (GIT-LOCAL-CHECKOUT-AVAILABLE-P REPOSITORY)
      :AVAILABLE
      :CHECKOUT-UNAVAILABLE))

(DEFMETHOD GIT-LOCAL-OBJECT-STATUS ((REPOSITORY NULL)) :CHECKOUT-UNAVAILABLE)

(DEFMETHOD GIT-LOCAL-OBJECT-STATUS ((COMMIT GIT-COMMIT))
  (LET ((REPOSITORY (GIT-COMMIT-REPOSITORY-OF COMMIT)))
    (COND
     ((NOT (GIT-LOCAL-CHECKOUT-AVAILABLE-P REPOSITORY)) :CHECKOUT-UNAVAILABLE)
     ((EQUAL "commit"
             (GIT-LOCAL-OBJECT-KIND REPOSITORY (GIT-COMMIT-HASH-OF COMMIT)))
      :AVAILABLE)
     (T :COMMIT-UNAVAILABLE))))

(DEFMETHOD GIT-LOCAL-OBJECT-STATUS ((FILE GIT-FILE-AT-COMMIT))
  (LET* ((COMMIT (GIT-FILE-COMMIT-OF FILE))
         (STATUS (GIT-LOCAL-OBJECT-STATUS COMMIT)))
    (IF (EQ :AVAILABLE STATUS)
        (IF (EQUAL "blob"
                   (GIT-LOCAL-OBJECT-KIND (GIT-COMMIT-REPOSITORY-OF COMMIT)
                    (GIT-FILE-BLOB-SPEC FILE)))
            :AVAILABLE
            :BLOB-UNAVAILABLE)
        STATUS)))
