;;;; Read-only Git commit equivalence proofs from graph/history evidence
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defparameter +static-route-observability-original-commit-hash+
  "4fd5e78c0e3afd9f14a0fda4f9d379b2ecc4286c")

(defparameter +static-route-observability-proof-source-branch+
  "backup/hauptsache-before-remote-sync-4fd5e78")

(defparameter +static-route-observability-proof-target-branch+
  "backup/hauptsache-before-merging-original-4fd5e78-d969ef5")

(defparameter +static-route-observability-proof-shared-base+
  "d6ff2f4881533dbc26510d47bd085bb4c9a4b1bc")

(defclass git-commit-equivalence-check ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (system :reader system-of :initarg :system :type asdf:system)
   (repo-root :reader repo-root-of :initarg :repo-root :type pathname)
   (repository-root-source :reader repository-root-source-of
                           :initarg :repository-root-source
                           :initform :system-source-default)
   (source-commit :reader source-commit-of
                  :initarg :source-commit
                  :type git-commit-target)
   (source-branch :reader source-branch-of :initarg :source-branch :type string)
   (target-branch :reader target-branch-of :initarg :target-branch :type string)
   (shared-base :reader shared-base-of
                :initarg :shared-base
                :type git-commit-target)
   (ancestry-present-p :reader ancestry-present-p
                       :initarg :ancestry-present-p
                       :initform nil)
   (patch-equivalent-p :reader patch-equivalent-p
                       :initarg :patch-equivalent-p
                       :initform nil)
   (replayed-equivalent-commit :reader replayed-equivalent-commit-of
                               :initarg :replayed-equivalent-commit
                               :initform nil)
   (ancestry-command :reader ancestry-command-of
                     :initarg :ancestry-command
                     :type string)
   (cherry-command :reader cherry-command-of
                   :initarg :cherry-command
                   :type string)
   (history-command :reader history-command-of
                    :initarg :history-command
                    :type string)
   (range-diff-command :reader range-diff-command-of
                       :initarg :range-diff-command
                       :type string)
   (ancestry-exit-code :reader ancestry-exit-code-of
                       :initarg :ancestry-exit-code
                       :type integer)
   (cherry-output :reader cherry-output-of
                  :initarg :cherry-output
                  :initform nil)
   (left-right-history :reader left-right-history-of
                       :initarg :left-right-history
                       :initform nil)
   (range-diff-summary :reader range-diff-summary-of
                       :initarg :range-diff-summary
                       :initform nil)
   (status-summary :reader status-summary-of
                   :initarg :status-summary
                   :type string)
   (merge-intent-interpretation :reader merge-intent-interpretation-of
                                :initarg :merge-intent-interpretation
                                :type string)))

(defclass git-commit-equivalence-surface ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (checks :reader checks-of :initarg :checks :initform nil)
   (notes :reader notes-of :initarg :notes :initform nil)))

(defun non-empty-output-lines (string)
  (remove-if #'uiop:emptyp
             (uiop:split-string (or string "")
                                :separator '(#\Newline))))

(defun whitespace-trim (string)
  (string-trim '(#\Space #\Tab) string))

(defun first-whitespace-token (string)
  (first (remove-if #'uiop:emptyp
                    (uiop:split-string (whitespace-trim string)
                                       :separator '(#\Space #\Tab)))))

(defun git-hash-fragment-p (string)
  (and (stringp string)
       (<= 7 (length string) 40)
       (every (lambda (char)
                (not (null (digit-char-p char 16))))
              string)))

(defun hash-fragment-matches-commit-p (fragment full-commit-hash)
  (or (string= fragment full-commit-hash)
      (and (< (length fragment) (length full-commit-hash))
           (uiop:string-prefix-p fragment full-commit-hash))))

(defun git-command-result* (directory args &key operation repository-root-source
                                      (acceptable-exit-codes '(0)))
  (multiple-value-bind (resolved-program requested-program configuration-source)
      (resolve-git-program)
    (let* ((resolved-program-string
             (and resolved-program
                  (git-command-program-string resolved-program)))
           (command
             (and resolved-program
                  (append (list resolved-program-string
                                "-C"
                                (pathname-namestring-or-nil directory))
                          args)))
           (command-display
             (and command
                  (format nil "~{~A~^ ~}" command))))
      (unless resolved-program
        (signal-git-runtime-unavailable
         :classification :git-executable-unavailable
         :operation (or operation "git command")
         :repository-root directory
         :working-directory directory
         :reason "Git proof unavailable: no usable Git executable is configured for this runtime."
         :detail "Configure HYPERDOC_GIT_PROGRAM or hyperdoc::*git-program* if Git is not on PATH."
         :repository-root-source repository-root-source
         :requested-program requested-program
         :configuration-source configuration-source
         :command (git-command-display-string
                   (or requested-program "git")
                   directory
                   args)))
      (handler-case
          (multiple-value-bind (output error-output exit-code)
              (uiop:run-program command
                                :output :string
                                :error-output :output
                                :ignore-error-status t)
            (declare (ignore error-output))
            (let ((output (trim-line-endings (or output ""))))
              (if (member exit-code acceptable-exit-codes)
                  (values output exit-code command-display)
                  (let ((classification
                          (classify-git-runtime-failure
                           :operation (or operation "git command")
                           :detail output
                           :exit-code exit-code)))
                    (signal-git-runtime-unavailable
                     :classification classification
                     :operation (or operation "git command")
                     :repository-root directory
                     :working-directory directory
                     :detail output
                     :repository-root-source repository-root-source
                     :requested-program requested-program
                     :resolved-program resolved-program-string
                     :configuration-source configuration-source
                     :command command-display
                     :exit-code exit-code)))))
        (git-runtime-unavailable (condition)
          (error condition))
        (error (condition)
          (let ((detail (princ-to-string condition)))
            (signal-git-runtime-unavailable
             :classification (classify-git-runtime-failure
                              :operation (or operation "git command")
                              :detail detail)
             :operation (or operation "git command")
             :repository-root directory
             :working-directory directory
             :detail detail
             :repository-root-source repository-root-source
             :requested-program requested-program
             :resolved-program resolved-program-string
             :configuration-source configuration-source
             :command command-display)))))))

(defun git-resolve-commitish (repo-root repository-root-source commitish)
  (let ((hash (nth-value
               0
               (git-command-result*
                repo-root
                (list "rev-parse" "--verify"
                      (format nil "~A^{commit}" commitish))
                :operation "git rev-parse --verify"
                :repository-root-source repository-root-source))))
    (unless (full-git-commit-hash-p hash)
      (signal-git-runtime-unavailable
       :operation "git rev-parse --verify"
       :repository-root repo-root
       :repository-root-source repository-root-source
       :reason (format nil "Expected a full commit hash for ~A." commitish)
       :detail hash))
    hash))

(defun parse-git-cherry-line (line)
  (let* ((trimmed (whitespace-trim line))
         (marker (and (> (length trimmed) 0)
                      (char trimmed 0)))
         (remainder (if marker
                        (whitespace-trim (subseq trimmed 1))
                        ""))
         (hash (first-whitespace-token remainder)))
    (when (and marker
               hash
               (member marker '(#\- #\+)))
      (values marker hash))))

(defun cherry-marker-for-commit (lines commit-hash)
  (loop for line in lines
        do (multiple-value-bind (marker hash)
               (parse-git-cherry-line line)
             (when (and marker
                        hash
                        (hash-fragment-matches-commit-p hash commit-hash))
               (return marker)))))

(defun parse-range-diff-equivalence-line (line)
  (let ((equals-position (position #\= line)))
    (when equals-position
      (let* ((left (subseq line 0 equals-position))
             (right (subseq line (1+ equals-position)))
             (left-colon (position #\: left))
             (right-colon (position #\: right))
             (source-short
               (and left-colon
                    (first-whitespace-token
                     (subseq left (1+ left-colon)))))
             (target-short
               (and right-colon
                    (first-whitespace-token
                     (subseq right (1+ right-colon))))))
        (when (and (git-hash-fragment-p source-short)
                   (git-hash-fragment-p target-short))
          (list :source-short source-short
                :target-short target-short
                :line line))))))

(defun range-diff-equivalence-info (lines source-commit-hash)
  (loop for line in lines
        for parsed = (parse-range-diff-equivalence-line line)
        when (and parsed
                  (hash-fragment-matches-commit-p
                   (getf parsed :source-short)
                   source-commit-hash))
          do (return parsed)))

(defun commit-equivalence-status-summary (ancestry-present-p patch-equivalent-p)
  (cond
    (ancestry-present-p
     "The source commit is directly reachable from the target branch ancestry.")
    (patch-equivalent-p
     "The source commit hash is outside the target ancestry, but an equivalent replay is present on the target branch.")
    (t
     "The source commit is neither directly reachable from the target ancestry nor proven replay-equivalent by the current graph/history checks.")))

(defun commit-equivalence-interpretation (source-commit-hash source-branch target-branch
                                           ancestry-present-p replayed-equivalent-commit)
  (cond
    (ancestry-present-p
     (format nil "The original ~A is directly reachable from ~A ancestry."
             source-commit-hash
             target-branch))
    (replayed-equivalent-commit
     (format nil "The original ~A remains on the ~A branch, while ~A on ~A is its replayed equivalent."
             source-commit-hash
             source-branch
             (commit-hash-of replayed-equivalent-commit)
             target-branch))
    (t
     (format nil "The original ~A is not reachable from ~A ancestry, and no replay-equivalent commit was proven from the current graph/history evidence."
             source-commit-hash
             target-branch))))

(defun %system-git-commit-equivalence-check (system-designator source-commit-hash
                                              &key source-branch target-branch
                                                shared-base-hash id title summary)
  (let* ((system (etypecase system-designator
                   (asdf:system
                    system-designator)
                   ((or string symbol)
                    (asdf:find-system system-designator)))))
    (unless (full-git-commit-hash-p source-commit-hash)
      (error "Expected a full source commit hash, got ~S." source-commit-hash))
    (unless (full-git-commit-hash-p shared-base-hash)
      (error "Expected a full shared-base hash, got ~S." shared-base-hash))
    (multiple-value-bind (repo-root repository-root-source)
        (system-repository-root-info system)
      (multiple-value-bind (ancestry-output ancestry-exit-code ancestry-command)
          (git-command-result*
           repo-root
           (list "merge-base" "--is-ancestor" source-commit-hash target-branch)
           :operation "git merge-base --is-ancestor"
           :repository-root-source repository-root-source
           :acceptable-exit-codes '(0 1))
        (declare (ignore ancestry-output))
        (multiple-value-bind (cherry-output cherry-exit-code cherry-command)
            (git-command-result*
             repo-root
             (list "cherry" target-branch source-branch)
             :operation "git cherry"
             :repository-root-source repository-root-source)
          (declare (ignore cherry-exit-code))
          (multiple-value-bind (history-output history-exit-code history-command)
              (git-command-result*
               repo-root
               (list "log" "--left-right" "--cherry-pick" "--oneline"
                     (format nil "~A...~A" source-branch target-branch))
               :operation "git log --left-right --cherry-pick --oneline"
               :repository-root-source repository-root-source)
            (declare (ignore history-exit-code))
            (multiple-value-bind (range-diff-output range-diff-exit-code range-diff-command)
                (git-command-result*
                 repo-root
                 (list "range-diff"
                       (format nil "~A..~A" shared-base-hash source-branch)
                       (format nil "~A..~A" shared-base-hash target-branch))
                 :operation "git range-diff"
                 :repository-root-source repository-root-source)
              (declare (ignore range-diff-exit-code))
              (let* ((ancestry-present-p (zerop ancestry-exit-code))
                     (cherry-lines (non-empty-output-lines cherry-output))
                     (history-lines (non-empty-output-lines history-output))
                     (range-diff-lines (non-empty-output-lines range-diff-output))
                     (cherry-marker (cherry-marker-for-commit cherry-lines
                                                             source-commit-hash))
                     (range-diff-info (range-diff-equivalence-info range-diff-lines
                                                                   source-commit-hash))
                     (patch-equivalent-p
                       (or ancestry-present-p
                           (char= #\- (or cherry-marker #\+))
                           (not (null range-diff-info))))
                     (source-commit (%system-git-commit-target system
                                                              source-commit-hash))
                     (shared-base (%system-git-commit-target system
                                                            shared-base-hash))
                     (replayed-equivalent-commit
                       (cond
                         (ancestry-present-p
                          source-commit)
                         (range-diff-info
                          (%system-git-commit-target
                           system
                           (git-resolve-commitish
                            repo-root
                            repository-root-source
                            (getf range-diff-info :target-short))))
                         (t
                          nil))))
                (make-instance
                 'git-commit-equivalence-check
                 :id (or id "git-commit-equivalence-check")
                 :title (or title
                            (format nil "Commit equivalence proof for ~A"
                                    (short-git-commit-hash source-commit-hash)))
                 :summary (or summary
                              "Read-only graph/history proof that distinguishes original commit ancestry from replay-equivalent content on a target branch.")
                 :system system
                 :repo-root repo-root
                 :repository-root-source repository-root-source
                 :source-commit source-commit
                 :source-branch source-branch
                 :target-branch target-branch
                 :shared-base shared-base
                 :ancestry-present-p ancestry-present-p
                 :patch-equivalent-p patch-equivalent-p
                 :replayed-equivalent-commit replayed-equivalent-commit
                 :ancestry-command ancestry-command
                 :cherry-command cherry-command
                 :history-command history-command
                 :range-diff-command range-diff-command
                 :ancestry-exit-code ancestry-exit-code
                 :cherry-output cherry-lines
                 :left-right-history history-lines
                 :range-diff-summary range-diff-lines
                 :status-summary
                 (commit-equivalence-status-summary ancestry-present-p
                                                    patch-equivalent-p)
                 :merge-intent-interpretation
                 (commit-equivalence-interpretation
                  source-commit-hash
                  source-branch
                  target-branch
                  ancestry-present-p
                  replayed-equivalent-commit))))))))))

(defun system-git-commit-equivalence-check (system-designator source-commit-hash
                                             &key source-branch target-branch
                                               shared-base-hash id title summary)
  (call-with-git-runtime-boundary
   (lambda ()
     (%system-git-commit-equivalence-check
      system-designator
      source-commit-hash
      :source-branch source-branch
      :target-branch target-branch
      :shared-base-hash shared-base-hash
      :id id
      :title title
      :summary summary))))

(defun %hyperdoc-static-route-observability-commit-equivalence-check ()
  (%system-git-commit-equivalence-check
   :hyperdoc
   +static-route-observability-original-commit-hash+
   :source-branch +static-route-observability-proof-source-branch+
   :target-branch +static-route-observability-proof-target-branch+
   :shared-base-hash +static-route-observability-proof-shared-base+
   :id "static-route-observability-commit-equivalence-check"
   :title "Commit equivalence proof for the static-route-observability skill commit"
   :summary "Worked example proving that the original static-route-observability skill commit remains on a preserved source branch while an equivalent replay exists on the preserved pre-merge hauptsache target branch."))

(defun hyperdoc-static-route-observability-commit-equivalence-check ()
  (call-with-git-runtime-boundary
   (lambda ()
     (%hyperdoc-static-route-observability-commit-equivalence-check))))

(defun %hyperdoc-commit-equivalence-proof-surface ()
  (make-instance
   'git-commit-equivalence-surface
   :id "hyperdoc-commit-equivalence-proof-surface"
   :title "Commit equivalence proof surface"
   :summary "Inspect read-only proof objects that distinguish original commit ancestry from replay-equivalent content on target branches."
   :checks (list (%hyperdoc-static-route-observability-commit-equivalence-check))
   :notes '("Use an explicit shared base commit for range-diff; do not rely on a floating remote ref once the target branch has moved."
            "This worked example pins the target to the preserved pre-merge hauptsache branch so the replay-equivalent state remains inspectable after the original lineage was later merged."
            "This skill proves graph/history equivalence only; it does not repair branches or mutate refs.")))

(defun hyperdoc-commit-equivalence-proof-surface ()
  (call-with-git-runtime-boundary
   (lambda ()
     (%hyperdoc-commit-equivalence-proof-surface))))
