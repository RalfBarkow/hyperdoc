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

(defparameter +static-route-observability-superseding-local-commit-hash+
  "1f8f2857baf99c623940af7e7acec0393d0ebc83")

(defparameter +graphviz-story-item-original-commit-hash+
  "ceae9d2739c181ce566103e5773e1e08bfdc859b")

(defparameter +graphviz-story-item-proof-source-branch+
  "upstream/main")

(defparameter +graphviz-story-item-proof-target-branch+
  "hauptsache")

(defparameter +graphviz-story-item-proof-shared-base+
  "823bdc2de0f05a549b8a2f7e81c8dcf74db4c32e")

(defparameter +graphviz-story-item-superseding-local-commit-hash+
  "b1e8d4041ab5f584886dfa12e5952b0a6bb6173c")

(defparameter +graphviz-story-item-assimilation-source-page-id+
  "Graphviz story item upstream assimilation example")

(defparameter +graphviz-story-item-corpus-page-id+
  "FedWiki Graphviz story item render trace")

(defparameter +upstream-commit-assimilation-source-page-id+
  "Check upstream commit assimilation equivalence")

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

(defclass git-upstream-commit-assimilation-check ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (equivalence-check :reader equivalence-check-of
                      :initarg :equivalence-check
                      :type git-commit-equivalence-check)
   (payload-paths :reader payload-paths-of
                  :initarg :payload-paths
                  :initform nil)
   (payload-command :reader payload-command-of
                    :initarg :payload-command
                    :type string)
   (corpus-evidence-status :reader corpus-evidence-status-of
                           :initarg :corpus-evidence-status
                           :initform :unavailable)
   (corpus-page-evidence :reader corpus-page-evidence-of
                         :initarg :corpus-page-evidence
                         :initform nil)
   (semantic-evidence-availability :reader semantic-evidence-availability-of
                                   :initarg :semantic-evidence-availability
                                   :initform :unavailable)
   (superseding-local-commit :reader superseding-local-commit-of
                             :initarg :superseding-local-commit
                             :initform nil)
   (semantic-effect-status :reader semantic-effect-status-of
                           :initarg :semantic-effect-status
                           :initform :unknown)
   (semantic-compatibility-status :reader semantic-compatibility-status-of
                                  :initarg :semantic-compatibility-status
                                  :initform :unknown)
   (semantic-compatibility-summary :reader semantic-compatibility-summary-of
                                   :initarg :semantic-compatibility-summary
                                   :type string)
   (semantic-compatibility-notes :reader semantic-compatibility-notes-of
                                 :initarg :semantic-compatibility-notes
                                 :initform nil)
   (validation-status :reader validation-status-of
                      :initarg :validation-status
                      :initform :unknown)
   (validation-summary :reader validation-summary-of
                       :initarg :validation-summary
                       :type string)
   (validation-notes :reader validation-notes-of
                     :initarg :validation-notes
                     :initform nil)
   (final-decision :reader final-decision-of
                   :initarg :final-decision
                   :initform :inconclusive)
   (final-interpretation :reader final-interpretation-of
                         :initarg :final-interpretation
                         :type string)))

(defclass git-upstream-commit-assimilation-surface ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (checks :reader checks-of :initarg :checks :initform nil)
   (notes :reader notes-of :initarg :notes :initform nil)))

(defmethod system-of ((check git-upstream-commit-assimilation-check))
  (system-of (equivalence-check-of check)))

(defmethod repo-root-of ((check git-upstream-commit-assimilation-check))
  (repo-root-of (equivalence-check-of check)))

(defmethod repository-root-source-of ((check git-upstream-commit-assimilation-check))
  (repository-root-source-of (equivalence-check-of check)))

(defmethod source-commit-of ((check git-upstream-commit-assimilation-check))
  (source-commit-of (equivalence-check-of check)))

(defmethod source-branch-of ((check git-upstream-commit-assimilation-check))
  (source-branch-of (equivalence-check-of check)))

(defmethod target-branch-of ((check git-upstream-commit-assimilation-check))
  (target-branch-of (equivalence-check-of check)))

(defmethod shared-base-of ((check git-upstream-commit-assimilation-check))
  (shared-base-of (equivalence-check-of check)))

(defmethod ancestry-present-p ((check git-upstream-commit-assimilation-check))
  (ancestry-present-p (equivalence-check-of check)))

(defmethod patch-equivalent-p ((check git-upstream-commit-assimilation-check))
  (patch-equivalent-p (equivalence-check-of check)))

(defmethod replayed-equivalent-commit-of ((check git-upstream-commit-assimilation-check))
  (replayed-equivalent-commit-of (equivalence-check-of check)))

(defun git-upstream-commit-assimilation-check-result-p (object)
  (typep object 'git-upstream-commit-assimilation-check))

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

(defun git-commit-payload-paths (repo-root repository-root-source source-commit-hash)
  (multiple-value-bind (output exit-code command)
      (git-command-result*
       repo-root
       (list "show" "--format=" "--name-only" source-commit-hash)
       :operation "git show --name-only"
       :repository-root-source repository-root-source)
    (declare (ignore exit-code))
    (values (non-empty-output-lines output)
            command)))

(defun semantic-effect-status-label (status)
  (ecase status
    (:present "present")
    (:absent "absent")
    (:unknown "unknown")))

(defun semantic-compatibility-status-label (status)
  (ecase status
    (:compatible "compatible")
    (:diverged "diverged")
    (:unknown "unknown")))

(defun validation-status-label (status)
  (ecase status
    (:passed "passed")
    (:failed "failed")
    (:unknown "unknown")))

(defun corpus-evidence-status-label (status)
  (ecase status
    (:resolved "resolved")
    (:lookup-issue "lookup issue")
    (:unavailable "unavailable")))

(defun semantic-evidence-availability-label (status)
  (ecase status
    (:complete "complete")
    (:partial "partial")
    (:unavailable "unavailable")))

(defun upstream-commit-assimilation-decision-label (decision)
  (ecase decision
    (:needs-cherry-pick ":needs-cherry-pick")
    (:needs-manual-assimilation ":needs-manual-assimilation")
    (:already-assimilated ":already-assimilated")
    (:inconclusive ":inconclusive")))

(defun classify-upstream-commit-assimilation-decision (&key ancestry-present-p
                                                         patch-equivalent-p
                                                         superseding-local-commit
                                                         semantic-effect-status
                                                         semantic-compatibility-status
                                                         validation-status)
  (let ((graph-or-local-evidence-p
         (or ancestry-present-p
             patch-equivalent-p
             superseding-local-commit)))
    (cond
      ((and graph-or-local-evidence-p
            (eq semantic-effect-status :present)
            (eq validation-status :passed))
       :already-assimilated)
      ((and (eq semantic-effect-status :absent)
            (eq semantic-compatibility-status :compatible)
            (eq validation-status :passed))
       :needs-cherry-pick)
      ((and (eq semantic-effect-status :absent)
            (eq semantic-compatibility-status :diverged))
       :needs-manual-assimilation)
      (t
       :inconclusive))))

(defun upstream-commit-assimilation-interpretation (source-commit-hash source-branch
                                                    target-branch final-decision
                                                    &key ancestry-present-p
                                                      replayed-equivalent-commit
                                                      superseding-local-commit)
  (ecase final-decision
    (:already-assimilated
     (cond
       (ancestry-present-p
        (format nil "The original ~A is directly reachable from ~A, and focused semantic validation confirms that its live effect is still present. Treat it as already assimilated."
                source-commit-hash
                target-branch))
       ((and replayed-equivalent-commit
             superseding-local-commit)
        (format nil "The original ~A remains on ~A, while ~A on ~A proves replay-equivalent history and later local ~A preserves the same live effect under the current ownership boundary. Treat it as already assimilated."
                source-commit-hash
                source-branch
                (commit-hash-of replayed-equivalent-commit)
                target-branch
                (commit-hash-of superseding-local-commit)))
       (replayed-equivalent-commit
        (format nil "The original ~A remains on ~A, while ~A on ~A plus the focused semantic proof show that the payload is already present in effect. Treat it as already assimilated."
                source-commit-hash
                source-branch
                (commit-hash-of replayed-equivalent-commit)
                target-branch))
       (superseding-local-commit
        (format nil "No replay-equivalent hash was required: ~A on ~A plus the focused semantic proof show that the payload is already present in effect. Treat it as already assimilated."
                (commit-hash-of superseding-local-commit)
                target-branch))
       (t
        (format nil "Focused graph/history and semantic evidence show that ~A is already present in effect on ~A."
                source-commit-hash
                target-branch))))
    (:needs-cherry-pick
     (format nil "No replay-equivalent or superseding local commit was proven for ~A on ~A, and the focused compatibility checks say the payload remains directly applicable. The narrow action is to cherry-pick from ~A."
             source-commit-hash
             target-branch
             source-branch))
    (:needs-manual-assimilation
     (format nil "The payload for ~A is not already present in effect on ~A, and the focused compatibility checks show target-boundary drift. Manual assimilation is required instead of a straight cherry-pick from ~A."
             source-commit-hash
             target-branch
             source-branch))
    (:inconclusive
     (format nil "The current graph/history and semantic evidence are insufficient to classify ~A safely for ~A."
             source-commit-hash
             target-branch))))

(defun payload-paths-present-in-system-source-p (system-designator payload-paths)
  (every (lambda (path)
           (ignore-errors
             (probe-file
              (asdf:system-relative-pathname system-designator path))))
         payload-paths))

(defun assimilation-source-page-title ()
  +upstream-commit-assimilation-source-page-id+)

(defun call-optional-hyperbook-function (name &rest args)
  (multiple-value-bind (symbol status)
      (find-symbol name :hyperbook)
    (when (and (eq status :external)
               (fboundp symbol))
      (apply (symbol-function symbol) args))))

(defun make-assimilation-page-lookup-issue (condition book page-id
                                            &key
                                              (source-page-id
                                               +upstream-commit-assimilation-source-page-id+)
                                              (source-page-title
                                               (assimilation-source-page-title))
                                              (source-section "Corpus evidence"))
  (let* ((target-hyperbook-id
          (ignore-errors
            (id-of book)))
         (issue
          (call-optional-hyperbook-function
           "MAKE-PAGE-LOOKUP-ISSUE"
           condition
           :source-hyperbook "hyperdoc"
           :source-page-id source-page-id
           :source-page-title source-page-title
           :source-section source-section
           :link-text page-id
           :target-hyperbook-id target-hyperbook-id
           :expected-page-id page-id
           :classification :lookup-failure
           :details (list :lookup-stage :assimilation-corpus
                          :target-hyperbook-id target-hyperbook-id
                          :expected-page-id page-id
                          :condition-type (type-of condition)))))
    (when issue
      (or (ignore-errors
            (call-optional-hyperbook-function
             "ENRICH-LOOKUP-ISSUE"
             issue))
          issue))))

(defun safe-assimilation-page-evidence (book page-id
                                        &key
                                          (source-page-id
                                           +upstream-commit-assimilation-source-page-id+)
                                          (source-page-title
                                           (assimilation-source-page-title))
                                          (source-section "Corpus evidence"))
  (cond
    ((null book)
     (list :status :unavailable
           :page-id page-id
           :reason "Corpus/page lookup not available in the current loaded image."))
    (t
     (handler-case
         (list :status :resolved
               :page-id page-id
               :page (find-page book page-id :signal-error? t))
       (page-lookup-failure (condition)
         (if-let (issue
                  (make-assimilation-page-lookup-issue
                   condition
                   book
                   page-id
                   :source-page-id source-page-id
                   :source-page-title source-page-title
                   :source-section source-section))
             (list :status :lookup-issue
                   :page-id page-id
                   :issue issue)
           (list :status :unavailable
                 :page-id page-id
                 :condition condition
                 :reason
                 "Page lookup failed, but structured lookup-issue construction is not available in the current loaded image.")))
       (hyperbook-lookup-failure (condition)
         (if-let (issue
                  (make-assimilation-page-lookup-issue
                   condition
                   book
                   page-id
                   :source-page-id source-page-id
                   :source-page-title source-page-title
                   :source-section source-section))
             (list :status :lookup-issue
                   :page-id page-id
                   :issue issue)
           (list :status :unavailable
                 :page-id page-id
                 :condition condition
                 :reason
                 "Page lookup failed, but structured lookup-issue construction is not available in the current loaded image.")))
       (error (condition)
         (list :status :unavailable
               :page-id page-id
               :condition condition
               :reason
               "Corpus/page lookup not available in the current loaded image."))))))

(defun page-evidence-status (page-evidence)
  (getf page-evidence :status :unavailable))

(defun corpus-evidence-status (page-evidence)
  (cond
    ((and page-evidence
          (every (lambda (evidence)
                   (eq (page-evidence-status evidence) :resolved))
                 page-evidence))
     :resolved)
    ((some (lambda (evidence)
             (eq (page-evidence-status evidence) :lookup-issue))
           page-evidence)
     :lookup-issue)
    (t
     :unavailable)))

(defun semantic-evidence-availability (runtime-shape corpus-evidence-status)
  (cond
    ((and (recognized-static-route-observability-runtime-shape-p runtime-shape)
          (eq corpus-evidence-status :resolved))
     :complete)
    ((or (recognized-static-route-observability-runtime-shape-p runtime-shape)
         (eq corpus-evidence-status :resolved)
         (eq corpus-evidence-status :lookup-issue))
     :partial)
    (t
     :unavailable)))

(defun find-package-symbol-if-present (package-designator symbol-name)
  (let* ((package (find-package package-designator)))
    (when package
      (multiple-value-bind (symbol status)
          (find-symbol symbol-name package)
        (when status
          symbol)))))

(defun package-function-if-present (package-designator symbol-name)
  (when-let (symbol (find-package-symbol-if-present package-designator
                                                    symbol-name))
    (when (fboundp symbol)
      (symbol-function symbol))))

(defun package-class-if-present (package-designator symbol-name)
  (when-let (symbol (find-package-symbol-if-present package-designator
                                                    symbol-name))
    (find-class symbol nil)))

(defun package-variable-symbol-if-present (package-designator symbol-name)
  (when-let (symbol (find-package-symbol-if-present package-designator
                                                    symbol-name))
    (when (boundp symbol)
      symbol)))

(defun hyperdoc-book-if-available ()
  (when-let (symbol (find-package-symbol-if-present :hyperdoc "*HYPERDOC*"))
    (when (boundp symbol)
      (symbol-value symbol))))

(defun source-snippet-between-markers (pathname start-marker &optional end-marker)
  (when-let (resolved (probe-file pathname))
    (let* ((source (uiop:read-file-string resolved))
           (start (search start-marker source)))
      (when start
        (let ((end (if end-marker
                       (or (search end-marker source :start2 start)
                           (length source))
                       (length source))))
          (subseq source start end))))))

(defun graphviz-story-item-renderer-source-pathname ()
  (asdf:system-relative-pathname :hyperdoc
                                 "hyperbook-fedwiki/story-items.lisp"))

(defun graphviz-story-item-corpus-page-pathname ()
  (asdf:system-relative-pathname :hyperdoc
                                 "hyperdoc/FedWiki Graphviz story item render trace.html"))

(defun inspect-graphviz-story-item-renderer-source-shape ()
  (let* ((pathname (graphviz-story-item-renderer-source-pathname))
         (snippet
          (source-snippet-between-markers
           pathname
           "(defmethod render-story-item ((type (eql :graphviz)) item page)"
           ";; Images")))
    (cond
      ((null (probe-file pathname))
       (list :status :unavailable
             :path (namestring pathname)
             :reason "The current hyperbook-fedwiki/story-items.lisp source file is unavailable."))
      ((null snippet)
       (list :status :unavailable
             :path (namestring pathname)
             :reason "The current image could not locate the :graphviz render-story-item method in hyperbook-fedwiki/story-items.lisp."))
      (t
       (let* ((dot-from-text-p
               (not (null (search "(text-of item)" snippet))))
              (dot-from-data-p
               (not (null (search "(gethash \"dot\"" snippet))))
              (engine-from-data-p
               (not (null (search "(gethash \"engine\"" snippet))))
              (fallback-title-present-p
               (not (null (search ":fallback-title \"Raw DOT source\""
                                  snippet))))
              (recognized-text-backed-shape-p
               (and dot-from-text-p
                    (not dot-from-data-p)
                    engine-from-data-p
                    fallback-title-present-p)))
         (list :status (if recognized-text-backed-shape-p
                           :resolved
                           :partial)
               :path (namestring pathname)
               :snippet snippet
               :dot-from-text-p dot-from-text-p
               :dot-from-data-p dot-from-data-p
               :engine-from-data-p engine-from-data-p
               :fallback-title-present-p fallback-title-present-p
               :recognized-text-backed-shape-p
               recognized-text-backed-shape-p))))))

(defun graphviz-story-item-renderer-shape-label (shape-info)
  (cond
    ((getf shape-info :recognized-text-backed-shape-p)
     "text-backed graphviz renderer using the shared graphviz seam")
    ((eq (getf shape-info :status) :partial)
     "graphviz renderer present, but the current source shape diverges from the text-backed canonical path")
    (t
     "graphviz renderer source shape unavailable")))

(defun inspect-graphviz-story-item-corpus-shape ()
  (let* ((pathname (graphviz-story-item-corpus-page-pathname))
         (resolved (probe-file pathname)))
    (cond
      ((null resolved)
       (list :status :unavailable
             :path (namestring pathname)
             :reason "The FedWiki Graphviz story item render trace page is unavailable in the current checkout."))
      (t
       (let* ((source (uiop:read-file-string resolved))
              (type-present-p
               (not (null (search "\"type\": \"graphviz\"" source))))
              (text-present-p
               (or (search "\"text\": \"digraph { a -&gt; b }\"" source)
                   (search "\"text\": \"digraph { a -> b }\"" source)))
              (shared-helper-present-p
               (not (null (search "views:graphviz-snippet" source))))
              (text-backed-explanation-present-p
               (not (null (search "story item's DOT text" source))))
              (recognized-text-backed-corpus-p
               (and type-present-p
                    text-present-p
                    shared-helper-present-p
                    text-backed-explanation-present-p)))
         (list :status (if recognized-text-backed-corpus-p
                           :resolved
                           :partial)
               :path (namestring resolved)
               :type-present-p type-present-p
               :text-present-p text-present-p
               :shared-helper-present-p shared-helper-present-p
               :text-backed-explanation-present-p
               text-backed-explanation-present-p
               :recognized-text-backed-corpus-p
               recognized-text-backed-corpus-p))))))

(defun graphviz-story-item-semantic-evidence-availability (renderer-shape-info
                                                           corpus-evidence-status
                                                           corpus-shape-info)
  (let ((renderer-resolved-p
         (getf renderer-shape-info :recognized-text-backed-shape-p))
        (corpus-shape-resolved-p
         (getf corpus-shape-info :recognized-text-backed-corpus-p)))
    (cond
      ((and renderer-resolved-p
            corpus-shape-resolved-p
            (eq corpus-evidence-status :resolved))
       :complete)
      ((or renderer-resolved-p
           corpus-shape-resolved-p
           (eq corpus-evidence-status :resolved)
           (eq corpus-evidence-status :lookup-issue))
       :partial)
      (t
       :unavailable))))

(defun inspect-graphviz-story-item-render-validation ()
  (handler-case
      (progn
        (asdf:load-system :hyperbook/fedwiki)
        (let* ((wiki-class
                (package-class-if-present :hyperbook/fedwiki "FEDWIKI"))
               (page-maker
                (package-function-if-present :hyperbook/fedwiki
                                             "MAKE-FEDWIKI-PAGE"))
               (story-item-class
                (package-class-if-present :hyperbook/fedwiki "STORY-ITEM"))
               (render-story-item
                (package-function-if-present :hyperbook/fedwiki
                                             "RENDER-STORY-ITEM"))
               (accumulator-class
                (package-class-if-present :html-inspector-views
                                          "VIEW-ACCUMULATOR"))
               (accumulator-assets
                (package-function-if-present :html-inspector-views
                                             "ACCUMULATOR-ASSETS"))
               (html-stream-symbol
                (or (package-variable-symbol-if-present :html-inspector-views
                                                        "*HTML-STREAM*")
                    (find-package-symbol-if-present :html-inspector-views
                                                    "*HTML-STREAM*")))
               (view-accumulator-symbol
                (or (package-variable-symbol-if-present :html-inspector-views
                                                        "*VIEW-ACCUMULATOR*")
                    (find-package-symbol-if-present :html-inspector-views
                                                    "*VIEW-ACCUMULATOR*"))))
          (unless (and wiki-class
                       page-maker
                       story-item-class
                       render-story-item
                       accumulator-class
                       accumulator-assets
                       html-stream-symbol
                       view-accumulator-symbol)
            (error "Graphviz validation helpers are unavailable in the current image."))
          (let* ((wiki (make-instance wiki-class
                                      :id "fedwiki:graphviz-assimilation.example"))
                 (page (funcall page-maker
                                wiki
                                "graphviz-assimilation-example"
                                "Graphviz Assimilation Example"))
                 (item (make-instance story-item-class
                                      :item-type :graphviz
                                      :id "graphviz-item-1"
                                      :text "digraph { a -> b }"
                                      :data nil))
                 (accumulator (make-instance accumulator-class))
                 (html
                  (with-output-to-string (stream)
                    (progv (list html-stream-symbol
                                 view-accumulator-symbol)
                        (list stream accumulator)
                      (funcall render-story-item :graphviz item page))))
                 (assets (funcall accumulator-assets accumulator))
                 (placeholder-present-p
                  (not (null (search "data-inspector-graphviz=" html))))
                 (dot-transport-present-p
                  (not (null (search "data-inspector-graphviz-dot=" html))))
                 (raw-dot-fallback-present-p
                  (not (null (search "Raw DOT source" html))))
                 (dot-text-present-p
                  (not (null (search "digraph { a -&gt; b }" html))))
                 (generic-raw-text-fallback-present-p
                  (not (null (search "background-color: #eee;" html))))
                 (passed-p
                  (and placeholder-present-p
                       dot-transport-present-p
                       raw-dot-fallback-present-p
                       dot-text-present-p
                       (not generic-raw-text-fallback-present-p))))
            (list :status (if passed-p :passed :failed)
                  :html html
                  :assets assets
                  :placeholder-present-p placeholder-present-p
                  :dot-transport-present-p dot-transport-present-p
                  :raw-dot-fallback-present-p raw-dot-fallback-present-p
                  :dot-text-present-p dot-text-present-p
                  :generic-raw-text-fallback-present-p
                  generic-raw-text-fallback-present-p))))
    (error (condition)
      (list :status :unavailable
            :condition (princ-to-string condition)))))

(defun call-reader-if-supported (reader-name object)
  (when (fboundp reader-name)
    (handler-case
        (values (funcall (fdefinition reader-name) object)
                t)
      (error ()
        (values nil nil)))))

(defun recognized-static-route-observability-runtime-shape-p (shape)
  (member shape '(:static-route-observability :operational-targets)))

(defun static-route-observability-runtime-shape-label (shape)
  (ecase shape
    (:static-route-observability
     "original static-route-observability surface")
    (:operational-targets
     "operational-targets-backed static asset resolution surface")
    (:unknown
     "unknown runtime shape")))

(defun normalize-static-route-observability-owner (owner)
  (case owner
    ((:clog-static-root :default-clog-static-root)
     :clog-static-root)
    ((:views-asset-mount :hyperbook-server-plugin-mount)
     :hyperbook-server-asset-mount)
    (otherwise
     owner)))

(defun static-route-observability-owner-label (owner)
  (ecase owner
    (:clog-static-root
     "CLOG static root")
    (:hyperbook-server-asset-mount
     "hyperbook-server asset mount")))

(defun expected-static-route-observability-runtime-contracts ()
  (sort
   (copy-tree
    '(("/boot.html" :clog-static-root)
      ("/js/boot.js" :clog-static-root)
      ("/js/jquery.min.js" :clog-static-root)
      ("/hyperbook-server/js/url.js" :hyperbook-server-asset-mount)))
   #'string<
   :key #'first))

(defun expected-static-route-observability-request-paths ()
  (mapcar #'first
          (expected-static-route-observability-runtime-contracts)))

(defun static-route-observability-runtime-boundary-constructor-symbols (shape)
  (ecase shape
    (:static-route-observability
     '(hyperdoc-static-asset-resolution-surface
       hyperdoc-boot-html-static-asset-resolution
       hyperdoc-boot-js-static-asset-resolution
       hyperdoc-jquery-min-js-static-asset-resolution
       hyperbook-server-url-js-static-asset-resolution))
    (:operational-targets
     '(hyperdoc-static-asset-resolution-surface
       hyperdoc-boot-html-static-asset-path-resolution
       hyperdoc-boot-js-static-asset-path-resolution
       hyperdoc-jquery-min-js-static-asset-path-resolution
       hyperdoc-url-helper-static-asset-path-resolution))))

(defun static-route-observability-runtime-entry-owner (entry)
  (multiple-value-bind (owner-layer supported-p)
      (call-reader-if-supported 'owner-layer-of entry)
    (cond
      (supported-p
       (normalize-static-route-observability-owner owner-layer))
      (t
       (multiple-value-bind (owner-kind supported-p)
           (call-reader-if-supported 'owner-kind-of entry)
         (when supported-p
           (normalize-static-route-observability-owner owner-kind)))))))

(defun static-route-observability-runtime-contracts (entries)
  (sort
   (loop for entry in entries
         collect (list (request-path-of entry)
                       (static-route-observability-runtime-entry-owner entry)))
   #'string<
   :key #'first))

(defun static-route-observability-runtime-contract-line (contract)
  (destructuring-bind (request-path owner) contract
    (format nil "~A -> ~A"
            request-path
            (static-route-observability-owner-label owner))))

(defun collect-static-route-observability-runtime-shape ()
  (let* ((surface (hyperdoc-static-asset-resolution-surface))
         (entries nil)
         (shape :unknown))
    (multiple-value-bind (value supported-p)
        (call-reader-if-supported 'entries-of surface)
      (when supported-p
        (setf entries value
              shape :operational-targets)))
    (when (eq shape :unknown)
      (multiple-value-bind (value supported-p)
          (call-reader-if-supported 'resolutions-of surface)
        (when supported-p
          (setf entries value
                shape :static-route-observability))))
    (let* ((contracts (and entries
                           (static-route-observability-runtime-contracts entries)))
           (expected-contracts
            (expected-static-route-observability-runtime-contracts)))
      (list :status :constructed
            :surface surface
            :shape shape
            :entries entries
            :contracts contracts
            :expected-contracts expected-contracts
            :matches-expected-p (equal contracts expected-contracts)))))

(defun inspect-static-route-observability-runtime-shape ()
  (handler-case
      (collect-static-route-observability-runtime-shape)
    (error (condition)
      (list :status :unavailable
            :condition (princ-to-string condition)))))

(defun static-route-observability-assimilation-semantic-evidence (equivalence-check
                                                                  payload-paths)
  (declare (ignore equivalence-check))
  (let* ((hyperdoc-book
          (and (boundp '*hyperdoc*)
               (symbol-value '*hyperdoc*)))
         (topics-book
          (and (boundp '*topics*)
               (symbol-value '*topics*)))
         (page-evidence
          (list
           (safe-assimilation-page-evidence
            hyperdoc-book
            "Static route observability")
           (safe-assimilation-page-evidence
            hyperdoc-book
            "Diagnose static asset route ownership")
           (safe-assimilation-page-evidence
            hyperdoc-book
            "Static Asset Path Resolution")
           (safe-assimilation-page-evidence
            topics-book
            "Static route observability")
           (safe-assimilation-page-evidence
            topics-book
            "Static asset path resolution")))
         (corpus-evidence-status
          (corpus-evidence-status page-evidence))
         (runtime-shape-info
          (inspect-static-route-observability-runtime-shape))
         (runtime-shape
          (getf runtime-shape-info :shape :unknown))
         (runtime-status
          (getf runtime-shape-info :status :unavailable))
         (runtime-contracts
          (getf runtime-shape-info :contracts))
         (runtime-matches-expected-p
          (getf runtime-shape-info :matches-expected-p))
         (semantic-evidence-availability
          (semantic-evidence-availability
           runtime-shape
           corpus-evidence-status))
         (constructor-symbols
          (and (recognized-static-route-observability-runtime-shape-p
                runtime-shape)
               (static-route-observability-runtime-boundary-constructor-symbols
                runtime-shape)))
         (constructors-present-p
          (and constructor-symbols
               (every #'fboundp constructor-symbols)))
         (payload-paths-present-p
          (payload-paths-present-in-system-source-p :hyperdoc payload-paths))
         (semantic-effect-status
          (if (and (recognized-static-route-observability-runtime-shape-p
                    runtime-shape)
                   constructors-present-p
                   payload-paths-present-p)
              :present
              :absent))
         (semantic-compatibility-status
          (cond
            (runtime-matches-expected-p
             :compatible)
            ((eq runtime-status :constructed)
             :diverged)
            (t
             :unknown)))
         (superseding-local-commit-hash
          (and (eq runtime-shape :operational-targets)
               runtime-matches-expected-p
               +static-route-observability-superseding-local-commit-hash+)))
    (list :semantic-effect-status semantic-effect-status
          :semantic-compatibility-status semantic-compatibility-status
          :corpus-evidence-status corpus-evidence-status
          :corpus-page-evidence page-evidence
          :semantic-evidence-availability semantic-evidence-availability
          :superseding-local-commit-hash superseding-local-commit-hash
          :summary
          (cond
            ((and (eq semantic-effect-status :present)
                  superseding-local-commit-hash)
             "The static-route-observability payload is already present in effect: the original authored slice remains in the corpus, and later local commit 1f8f2857 preserves the same four-route behavior under the operational-targets-backed surface.")
            ((eq semantic-effect-status :present)
             "The static-route-observability payload is already present in effect: the constructor layer, HyperDoc corpus, and topic surface still match the upstream skill slice.")
            ((eq semantic-compatibility-status :diverged)
             "The current target still constructs a related runtime surface, but its ownership contracts no longer match the upstream static-route-observability payload.")
            (t
             "The static-route-observability payload is not fully present in effect on the current target shape."))
          :notes
          (list
           (format nil "Payload scope stays on the same authored ownership boundary: ~{~A~^, ~}."
                   payload-paths)
           (format nil "Corpus evidence status: ~A."
                   (corpus-evidence-status-label corpus-evidence-status))
           (format nil "Semantic evidence availability: ~A."
                   (semantic-evidence-availability-label
                    semantic-evidence-availability))
           (format nil "Runtime shape: ~A."
                   (static-route-observability-runtime-shape-label runtime-shape))
           (format nil "Constructor layer for the current runtime shape: ~:[missing~;present~] for ~{~A~^, ~}."
                   constructors-present-p
                   constructor-symbols)
           (format nil "Payload paths still exist in the current system source tree: ~:[no~;yes~]."
                   payload-paths-present-p)
           (if runtime-contracts
               (format nil "Observed runtime contracts: ~{~A~^; ~}."
                       (mapcar #'static-route-observability-runtime-contract-line
                               runtime-contracts))
               (format nil "Runtime inspection status: ~A."
                       (or (getf runtime-shape-info :condition)
                           "no contracts recorded")))
           (if superseding-local-commit-hash
               (format nil "Superseding local commit: ~A introduced the operational-targets-backed static asset resolution surface that now carries the live effect."
                       superseding-local-commit-hash)
               "No superseding local commit was needed for the current runtime shape.")))))

(defun static-route-observability-assimilation-validation (equivalence-check
                                                           payload-paths
                                                           semantic-evidence)
  (declare (ignore equivalence-check payload-paths semantic-evidence))
  (let* ((runtime-shape-info
          (inspect-static-route-observability-runtime-shape))
         (runtime-status
          (getf runtime-shape-info :status :unavailable))
         (runtime-shape
          (getf runtime-shape-info :shape :unknown))
         (observed-contracts
          (getf runtime-shape-info :contracts))
         (expected-contracts
          (getf runtime-shape-info
                :expected-contracts
                (expected-static-route-observability-runtime-contracts)))
         (shape-passed-p
          (getf runtime-shape-info :matches-expected-p)))
    (cond
      ((eq runtime-status :constructed)
       (list :validation-status (if shape-passed-p :passed :failed)
             :summary
             (if shape-passed-p
                 (format nil "Focused validation passed: the current ~A materializes the expected four request-path ownership contracts."
                         (static-route-observability-runtime-shape-label
                          runtime-shape))
                 (format nil "Focused validation failed: the current ~A no longer matches the expected four request-path ownership contracts."
                         (static-route-observability-runtime-shape-label
                          runtime-shape)))
             :notes
             (list
              (format nil "Expected contracts: ~{~A~^; ~}."
                      (mapcar #'static-route-observability-runtime-contract-line
                              expected-contracts))
              (format nil "Observed contracts: ~{~A~^; ~}."
                      (mapcar #'static-route-observability-runtime-contract-line
                              observed-contracts)))))
      (t
       (list :validation-status :unknown
             :summary
             "Focused validation could not construct the current static-route-observability runtime shape."
             :notes
             (list (format nil "Validation condition: ~A"
                           (or (getf runtime-shape-info :condition)
                               "unknown runtime shape"))))))))

(defun graphviz-story-item-assimilation-semantic-evidence (equivalence-check
                                                           payload-paths)
  (declare (ignore equivalence-check))
  (let* ((page-evidence
          (list
           (safe-assimilation-page-evidence
            (hyperdoc-book-if-available)
            +graphviz-story-item-corpus-page-id+
            :source-page-id +graphviz-story-item-assimilation-source-page-id+
            :source-page-title +graphviz-story-item-assimilation-source-page-id+
            :source-section "Corpus evidence")))
         (corpus-evidence-status
          (corpus-evidence-status page-evidence))
         (renderer-shape-info
          (inspect-graphviz-story-item-renderer-source-shape))
         (corpus-shape-info
          (inspect-graphviz-story-item-corpus-shape))
         (payload-paths-present-p
          (payload-paths-present-in-system-source-p :hyperdoc payload-paths))
         (renderer-recognized-p
          (getf renderer-shape-info :recognized-text-backed-shape-p))
         (corpus-recognized-p
          (getf corpus-shape-info :recognized-text-backed-corpus-p))
         (semantic-effect-status
          (if (and payload-paths-present-p
                   renderer-recognized-p
                   corpus-recognized-p)
              :present
              :unknown))
         (semantic-compatibility-status
          (cond
            ((and renderer-recognized-p
                  corpus-recognized-p)
             :compatible)
            ((or (eq (getf renderer-shape-info :status) :partial)
                 (eq (getf corpus-shape-info :status) :partial))
             :diverged)
            (t
             :unknown)))
         (semantic-evidence-availability
          (graphviz-story-item-semantic-evidence-availability
           renderer-shape-info
           corpus-evidence-status
           corpus-shape-info))
         (superseding-local-commit-hash
          (and (eq semantic-effect-status :present)
               (eq semantic-compatibility-status :compatible)
               +graphviz-story-item-superseding-local-commit-hash+)))
    (list
     :semantic-effect-status semantic-effect-status
     :semantic-compatibility-status semantic-compatibility-status
     :corpus-evidence-status corpus-evidence-status
     :corpus-page-evidence page-evidence
     :semantic-evidence-availability semantic-evidence-availability
     :superseding-local-commit-hash superseding-local-commit-hash
     :summary
     (cond
       ((and (eq semantic-effect-status :present)
             superseding-local-commit-hash)
        "The graphviz story-item payload is already present in effect: upstream touched only the FedWiki renderer slice, but hauptsache already carries earlier local commit b1e8d404 through the shared graphviz seam, and the current constructor plus corpus still use text-backed graphviz items so no data[\"dot\"] compatibility patch is needed.")
       ((eq semantic-compatibility-status :diverged)
        "The current graphviz story-item slice still looks related, but the constructor or corpus no longer match the text-backed canonical shape used in this repo snapshot.")
       (t
        "The current graphviz story-item constructor and corpus evidence are insufficient to prove the upstream payload already present in effect."))
     :notes
     (list
      (format nil "Payload scope from the upstream commit is limited to ~{~A~^, ~}."
              payload-paths)
      (format nil "Corpus evidence status: ~A."
              (corpus-evidence-status-label corpus-evidence-status))
      (format nil "Semantic evidence availability: ~A."
              (semantic-evidence-availability-label
               semantic-evidence-availability))
      (format nil "Current renderer source shape: ~A."
              (graphviz-story-item-renderer-shape-label
               renderer-shape-info))
      (format nil "Renderer source reads DOT from text-of item: ~:[no~;yes~]."
              (getf renderer-shape-info :dot-from-text-p))
      (format nil "Renderer source reads DOT from data[\"dot\"]: ~:[no~;yes~]."
              (getf renderer-shape-info :dot-from-data-p))
      (format nil "Renderer source keeps engine lookup in item data: ~:[no~;yes~]."
              (getf renderer-shape-info :engine-from-data-p))
      (format nil "Corpus trace still records a real localhost graphviz story item as text-backed DOT plus the shared graphviz helper path: ~:[no~;yes~]."
              (getf corpus-shape-info :recognized-text-backed-corpus-p))
      (format nil "The earlier local commit ~A already introduced the shared graphviz seam on hauptsache."
              +graphviz-story-item-superseding-local-commit-hash+)))))

(defun graphviz-story-item-assimilation-validation (equivalence-check
                                                    payload-paths
                                                    semantic-evidence)
  (declare (ignore equivalence-check payload-paths semantic-evidence))
  (let ((validation-info
         (inspect-graphviz-story-item-render-validation)))
    (case (getf validation-info :status :unknown)
      (:passed
       (list :validation-status :passed
             :summary
             "Focused validation passed: a text-backed :graphviz story item with nil data still renders through the shared graphviz placeholder, DOT transport attribute, and raw DOT fallback."
             :notes
             (list
              "The focused runtime check constructs a FedWiki :graphviz story item with text \"digraph { a -> b }\" and data NIL."
              "The rendered HTML still contains the shared graphviz placeholder and DOT transport attribute."
              "The shared raw DOT fallback remains present, which shows no data[\"dot\"] compatibility patch is needed for the current canonical shape.")))
      (:failed
       (list :validation-status :failed
             :summary
             "Focused validation failed: the current graphviz story-item path no longer renders the shared placeholder from a text-backed item."
             :notes
             (list
              (format nil "Placeholder present: ~:[no~;yes~]."
                      (getf validation-info :placeholder-present-p))
              (format nil "DOT transport present: ~:[no~;yes~]."
                      (getf validation-info :dot-transport-present-p))
              (format nil "Raw DOT fallback present: ~:[no~;yes~]."
                      (getf validation-info :raw-dot-fallback-present-p))
              (format nil "DOT text preserved: ~:[no~;yes~]."
                      (getf validation-info :dot-text-present-p))
              (format nil "Generic raw-text fallback leaked through: ~:[no~;yes~]."
                      (getf validation-info :generic-raw-text-fallback-present-p)))))
      (otherwise
       (list :validation-status :unknown
             :summary
             "Focused validation could not run the current text-backed graphviz story-item check."
             :notes
             (list (format nil "Validation condition: ~A"
                           (or (getf validation-info :condition)
                               "graphviz validation helpers unavailable"))))))))

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

(defun %system-git-upstream-commit-assimilation-check
    (system-designator source-commit-hash
     &key source-branch target-branch shared-base-hash
       id title summary
       semantic-evidence-function
       focused-validation-function)
  (let* ((equivalence-check
          (%system-git-commit-equivalence-check
           system-designator
           source-commit-hash
           :source-branch source-branch
           :target-branch target-branch
           :shared-base-hash shared-base-hash
           :id (or id "git-commit-equivalence-check")
           :title (or title
                      (format nil "Commit equivalence proof for ~A"
                              (short-git-commit-hash source-commit-hash)))
           :summary
           "Read-only graph/history proof that distinguishes original commit ancestry from replay-equivalent content on a target branch."))
         (repo-root (repo-root-of equivalence-check))
         (repository-root-source
          (repository-root-source-of equivalence-check))
         (payload-paths nil)
         (payload-command nil))
    (multiple-value-setq (payload-paths payload-command)
      (git-commit-payload-paths repo-root repository-root-source
                                source-commit-hash))
    (let* ((semantic-evidence
            (if semantic-evidence-function
                (funcall semantic-evidence-function
                         equivalence-check
                         payload-paths)
                nil))
           (superseding-local-commit-hash
            (getf semantic-evidence :superseding-local-commit-hash))
           (superseding-local-commit
            (and superseding-local-commit-hash
                 (%system-git-commit-target
                  (system-of equivalence-check)
                  superseding-local-commit-hash)))
           (validation-evidence
            (if focused-validation-function
                (funcall focused-validation-function
                         equivalence-check
                         payload-paths
                         semantic-evidence)
                nil))
           (semantic-effect-status
            (getf semantic-evidence :semantic-effect-status :unknown))
           (semantic-compatibility-status
            (getf semantic-evidence :semantic-compatibility-status :unknown))
           (corpus-evidence-status
            (getf semantic-evidence :corpus-evidence-status :unavailable))
           (corpus-page-evidence
            (getf semantic-evidence :corpus-page-evidence))
           (semantic-evidence-availability
            (getf semantic-evidence
                  :semantic-evidence-availability
                  :unavailable))
           (semantic-compatibility-summary
            (or (getf semantic-evidence :summary)
                "No semantic compatibility summary recorded."))
           (semantic-compatibility-notes
            (getf semantic-evidence :notes))
           (validation-status
            (getf validation-evidence :validation-status :unknown))
           (validation-summary
            (or (getf validation-evidence :summary)
                "No focused validation summary recorded."))
           (validation-notes
            (getf validation-evidence :notes))
           (final-decision
            (classify-upstream-commit-assimilation-decision
             :ancestry-present-p (ancestry-present-p equivalence-check)
             :patch-equivalent-p (patch-equivalent-p equivalence-check)
             :superseding-local-commit superseding-local-commit
             :semantic-effect-status semantic-effect-status
             :semantic-compatibility-status semantic-compatibility-status
             :validation-status validation-status)))
      (make-instance
       'git-upstream-commit-assimilation-check
       :id (or id "git-upstream-commit-assimilation-check")
       :title (or title
                  (format nil "Upstream commit assimilation check for ~A"
                          (short-git-commit-hash source-commit-hash)))
       :summary (or summary
                    "Read-only assimilation check that combines graph/history proof with payload scope, semantic compatibility, and focused validation before classifying the next action for an upstream commit.")
       :equivalence-check equivalence-check
       :payload-paths payload-paths
       :payload-command payload-command
       :corpus-evidence-status corpus-evidence-status
       :corpus-page-evidence corpus-page-evidence
       :semantic-evidence-availability semantic-evidence-availability
       :superseding-local-commit superseding-local-commit
       :semantic-effect-status semantic-effect-status
       :semantic-compatibility-status semantic-compatibility-status
       :semantic-compatibility-summary semantic-compatibility-summary
       :semantic-compatibility-notes semantic-compatibility-notes
       :validation-status validation-status
       :validation-summary validation-summary
       :validation-notes validation-notes
       :final-decision final-decision
       :final-interpretation
       (upstream-commit-assimilation-interpretation
        source-commit-hash
        source-branch
        target-branch
        final-decision
        :ancestry-present-p (ancestry-present-p equivalence-check)
        :replayed-equivalent-commit
        (replayed-equivalent-commit-of equivalence-check)
        :superseding-local-commit superseding-local-commit)))))

(defun system-git-upstream-commit-assimilation-check
    (system-designator source-commit-hash
     &key source-branch target-branch shared-base-hash
       id title summary
       semantic-evidence-function
       focused-validation-function)
  (call-with-git-runtime-boundary
   (lambda ()
     (%system-git-upstream-commit-assimilation-check
      system-designator
      source-commit-hash
      :source-branch source-branch
      :target-branch target-branch
      :shared-base-hash shared-base-hash
      :id id
      :title title
      :summary summary
      :semantic-evidence-function semantic-evidence-function
      :focused-validation-function focused-validation-function))))

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

(defun %hyperdoc-static-route-observability-commit-assimilation-check ()
  (%system-git-upstream-commit-assimilation-check
   :hyperdoc
   +static-route-observability-original-commit-hash+
   :source-branch +static-route-observability-proof-source-branch+
   :target-branch +static-route-observability-proof-target-branch+
   :shared-base-hash +static-route-observability-proof-shared-base+
   :id "static-route-observability-commit-assimilation-check"
   :title "Upstream commit assimilation check for the static-route-observability skill commit"
   :summary "Worked example classifying the static-route-observability upstream skill commit as already assimilated by combining replay-equivalence proof with constructor/corpus/runtime checks."
   :semantic-evidence-function
   #'static-route-observability-assimilation-semantic-evidence
   :focused-validation-function
   #'static-route-observability-assimilation-validation))

(defun hyperdoc-static-route-observability-commit-assimilation-check ()
  (call-with-git-runtime-boundary
   (lambda ()
     (%hyperdoc-static-route-observability-commit-assimilation-check))))

(defun %hyperdoc-graphviz-story-item-commit-assimilation-check ()
  (%system-git-upstream-commit-assimilation-check
   :hyperdoc
   +graphviz-story-item-original-commit-hash+
   :source-branch +graphviz-story-item-proof-source-branch+
   :target-branch +graphviz-story-item-proof-target-branch+
   :shared-base-hash +graphviz-story-item-proof-shared-base+
   :id "graphviz-story-item-commit-assimilation-check"
   :title "Upstream commit assimilation check for the graphviz story-item renderer commit"
   :summary "Worked example classifying upstream graphviz story-item commit ceae9d as already assimilated in effect even though graph/history proof alone does not show a replay-equivalent commit on hauptsache."
   :semantic-evidence-function
   #'graphviz-story-item-assimilation-semantic-evidence
   :focused-validation-function
   #'graphviz-story-item-assimilation-validation))

(defun hyperdoc-graphviz-story-item-commit-assimilation-check ()
  (call-with-git-runtime-boundary
   (lambda ()
     (%hyperdoc-graphviz-story-item-commit-assimilation-check))))

(defexample graphviz-story-item-upstream-assimilation-example
    (:register nil)
  "Run the ceae9d graphviz upstream assimilation check and return the inspectable result."
  (let ((check (hyperdoc-graphviz-story-item-commit-assimilation-check)))
    (typecase check
      (git-upstream-commit-assimilation-check
       (-> check
           (assert-equal +graphviz-story-item-original-commit-hash+
                         :key (lambda (object)
                                (commit-hash-of (source-commit-of object))))
           (assert-equal +graphviz-story-item-proof-target-branch+
                         :key #'target-branch-of)
           (assert-eql :already-assimilated
                       :key #'final-decision-of)))
      (git-runtime-unavailable
       check)
      (t
       (error "Unexpected graphviz assimilation example result: ~S" check)))))

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

(defun %hyperdoc-upstream-commit-assimilation-surface ()
  (make-instance
   'git-upstream-commit-assimilation-surface
   :id "hyperdoc-upstream-commit-assimilation-surface"
   :title "Upstream commit assimilation surface"
   :summary "Inspect read-only assimilation checks that combine graph/history proof with payload scope, semantic compatibility, and focused validation before deciding whether an upstream commit should be cherry-picked, manually assimilated, or treated as already present in effect."
   :checks (list (hyperdoc-static-route-observability-commit-assimilation-check)
                 (hyperdoc-graphviz-story-item-commit-assimilation-check))
   :notes '("Graph/history proof remains necessary but not sufficient: replay equivalence and ancestry are kept distinct from semantic assimilation proof."
            "Payload scope is made explicit from the source commit before semantic notes are interpreted."
            "This skill stays read-only by default; it classifies assimilation state but does not mutate refs or execute merges.")))

(defun hyperdoc-upstream-commit-assimilation-surface ()
  (call-with-git-runtime-boundary
   (lambda ()
     (%hyperdoc-upstream-commit-assimilation-surface))))
