;;;; Git history surfaces and merge-intent relations
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defparameter +hyperdoc-upstream-main-commit-hash+
  "823bdc2de0f05a549b8a2f7e81c8dcf74db4c32e")

(defparameter +hyperdoc-hauptsache-commit-hash+
  "e9257b4d4301b4c4f94c90061ab68659aecad4c6")

(defparameter +hyperdoc-upstream-main-merge-intent-prompt+
  "Merge upstream/main into hauptsache.

Use 823bdc2de0f05a549b8a2f7e81c8dcf74db4c32e and
e9257b4d4301b4c4f94c90061ab68659aecad4c6
as the explicit review anchors for this merge-intent relation.

If merge conflicts arise, do not force a coarse overwrite in either direction.
Instead, refactor the hauptsache-specific local delta into a new ASDF subsystem
named dreyeck so that the upstream HyperDoc core can remain close to upstream/main
while the dreyeck subsystem preserves the local behavior and pages that are specific
to my branch and deployment context.

The outcome must keep overall HyperDoc working:
- asdf:load-system :hyperdoc succeeds
- asdf:load-system :hyperdoc/server succeeds
- the local server still serves the catalog
- existing HyperDoc pages continue to render
- the merge result remains inspectable in the git-history surface")

(defparameter +hyperdoc-upstream-main-conflict-policy+
  "If conflicts arise while merging upstream/main into hauptsache, refactor hauptsache-specific
behavior into a new ASDF subsystem dreyeck instead of forcing a dirty overwrite of upstream core.
The resulting system must continue to load and serve HyperDoc.")

(defparameter +hyperdoc-upstream-main-success-criteria+
  '("asdf:load-system :hyperdoc succeeds"
    "asdf:load-system :hyperdoc/server succeeds"
    "the local server still serves the catalog"
    "existing HyperDoc pages continue to render"
    "the merge result remains inspectable in the git-history surface"))

(defclass git-branch-ref ()
  ((system :reader system-of :initarg :system :type asdf:system)
   (repo-root :reader repo-root-of :initarg :repo-root :type pathname)
   (name :reader branch-name-of :initarg :name :type string)
   (commit-hash :reader commit-hash-of :initarg :commit-hash :type string)
   (role :reader branch-role-of :initarg :role :initform nil)
   (aliases :reader branch-aliases-of :initarg :aliases :initform nil)))

(defclass git-merge-intent ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (relation-type :reader relation-type-of :initarg :relation-type :type string)
   (status :reader status-of :initarg :status :initform "planned" :type string)
   (source-commit :reader source-commit-of :initarg :source-commit :type git-commit-target)
   (target-commit :reader target-commit-of :initarg :target-commit :type git-commit-target)
   (source-branch :reader source-branch-of :initarg :source-branch :type git-branch-ref)
   (target-branch :reader target-branch-of :initarg :target-branch :type git-branch-ref)
   (prompt :reader prompt-of :initarg :prompt :type string)
   (conflict-policy :reader conflict-policy-of :initarg :conflict-policy :type string)
   (success-criteria :reader success-criteria-of :initarg :success-criteria :initform nil)
   (notes :accessor notes-of :initarg :notes :initform nil)))

(defclass git-merge-preparation-note ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (relation :reader relation-of :initarg :relation :type git-merge-intent)
   (note-type :reader note-type-of :initarg :note-type :type string)
   (status :reader status-of :initarg :status :initform "candidate" :type string)
   (paths :reader paths-of :initarg :paths :initform nil)
   (recommendation :reader recommendation-of :initarg :recommendation :type string)))

(defclass git-merge-forecast ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (relation :reader relation-of :initarg :relation :type git-merge-intent)
   (merge-base-commit :reader merge-base-commit-of :initarg :merge-base-commit
                      :type git-commit-target)
   (upstream-only-paths :reader upstream-only-paths-of :initarg :upstream-only-paths
                        :initform nil)
   (hauptsache-only-paths :reader hauptsache-only-paths-of :initarg :hauptsache-only-paths
                          :initform nil)
   (overlapping-paths :reader overlapping-paths-of :initarg :overlapping-paths :initform nil)
   (blocker-summary :reader blocker-summary-of :initarg :blocker-summary :type string)
   (notes :reader notes-of :initarg :notes :initform nil)))

(defclass git-path-decision ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (relation :reader relation-of :initarg :relation :type git-merge-intent)
   (path-set :reader path-set-of :initarg :path-set :type string)
   (path :reader path-of :initarg :path :type string)
   (classification :reader classification-of :initarg :classification :type string)
   (rationale :reader rationale-of :initarg :rationale :type string)
   (linked-note :reader linked-note-of :initarg :linked-note :initform nil)))

(defclass git-path-decision-surface ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (forecast :reader forecast-of :initarg :forecast :type git-merge-forecast)
   (decisions :reader decisions-of :initarg :decisions :initform nil)))

(defclass git-dreyeck-extraction-plan ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (relation :reader relation-of :initarg :relation :type git-merge-intent)
   (forecast :reader forecast-of :initarg :forecast :type git-merge-forecast)
   (buckets :reader buckets-of :initarg :buckets :initform nil)))

(defclass git-dreyeck-extraction-bucket ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (relation :reader relation-of :initarg :relation :type git-merge-intent)
   (forecast :reader forecast-of :initarg :forecast :type git-merge-forecast)
   (bucket-type :reader bucket-type-of :initarg :bucket-type :type string)
   (paths :reader paths-of :initarg :paths :initform nil)
   (why-not-upstream-core :reader why-not-upstream-core-of
                          :initarg :why-not-upstream-core
                          :type string)
   (expected-asdf-placement :reader expected-asdf-placement-of
                            :initarg :expected-asdf-placement
                            :type string)
   (expected-dependency-direction :reader expected-dependency-direction-of
                                  :initarg :expected-dependency-direction
                                  :type string)
   (adaptation-mode :reader adaptation-mode-of :initarg :adaptation-mode :type string)))

(defclass git-dreyeck-transition-plan ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (relation :reader relation-of :initarg :relation :type git-merge-intent)
   (forecast :reader forecast-of :initarg :forecast :type git-merge-forecast)
   (extraction-plan :reader extraction-plan-of :initarg :extraction-plan
                    :type git-dreyeck-extraction-plan)
   (bucket-transitions :reader bucket-transitions-of :initarg :bucket-transitions
                       :initform nil)))

(defclass git-dreyeck-transition-bucket ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (relation :reader relation-of :initarg :relation :type git-merge-intent)
   (forecast :reader forecast-of :initarg :forecast :type git-merge-forecast)
   (extraction-bucket :reader extraction-bucket-of :initarg :extraction-bucket
                      :type git-dreyeck-extraction-bucket)
   (bucket-type :reader bucket-type-of :initarg :bucket-type :type string)
   (paths :reader paths-of :initarg :paths :initform nil)
   (target-destination :reader target-destination-of :initarg :target-destination
                       :type string)
   (dependency-direction :reader dependency-direction-of
                         :initarg :dependency-direction
                         :type string)
   (transition-mode :reader transition-mode-of :initarg :transition-mode :type string)
   (core-continuation :reader core-continuation-of :initarg :core-continuation
                      :type string)
   (validation-proof :reader validation-proof-of :initarg :validation-proof
                     :initform nil)))

(defclass git-manual-conflict ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (relation :reader relation-of :initarg :relation :type git-merge-intent)
   (forecast :reader forecast-of :initarg :forecast :type git-merge-forecast)
   (decision :reader decision-of :initarg :decision :type git-path-decision)
   (path :reader path-of :initarg :path :type string)
   (source-branch :reader source-branch-of :initarg :source-branch :type git-branch-ref)
   (target-branch :reader target-branch-of :initarg :target-branch :type git-branch-ref)
   (reason :reader reason-of :initarg :reason :type string)
   (preferred-resolution :reader preferred-resolution-of
                         :initarg :preferred-resolution
                         :type string)
   (result-placement :reader result-placement-of :initarg :result-placement :type string)))

(defclass git-manual-conflict-dossier ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (relation :reader relation-of :initarg :relation :type git-merge-intent)
   (forecast :reader forecast-of :initarg :forecast :type git-merge-forecast)
   (conflicts :reader conflicts-of :initarg :conflicts :initform nil)))

(defclass git-conflict-resolution-proposal ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (relation :reader relation-of :initarg :relation :type git-merge-intent)
   (forecast :reader forecast-of :initarg :forecast :type git-merge-forecast)
   (conflict :reader conflict-of :initarg :conflict :type git-manual-conflict)
   (path :reader path-of :initarg :path :type string)
   (source-branch :reader source-branch-of :initarg :source-branch :type git-branch-ref)
   (target-branch :reader target-branch-of :initarg :target-branch :type git-branch-ref)
   (conflict-shape :reader conflict-shape-of :initarg :conflict-shape :type string)
   (preferred-merged-form :reader preferred-merged-form-of
                          :initarg :preferred-merged-form
                          :type string)
   (result-placement :reader result-placement-of :initarg :result-placement :type string)
   (patch-sketch :reader patch-sketch-of :initarg :patch-sketch :type string)))

(defclass git-conflict-resolution-proposal-surface ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (relation :reader relation-of :initarg :relation :type git-merge-intent)
   (forecast :reader forecast-of :initarg :forecast :type git-merge-forecast)
   (manual-dossier :reader manual-dossier-of :initarg :manual-dossier
                   :type git-manual-conflict-dossier)
   (proposals :reader proposals-of :initarg :proposals :initform nil)))

(defclass git-dreyeck-executable-scaffold ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (relation :reader relation-of :initarg :relation :type git-merge-intent)
   (forecast :reader forecast-of :initarg :forecast :type git-merge-forecast)
   (transition-plan :reader transition-plan-of :initarg :transition-plan
                    :type git-dreyeck-transition-plan)
   (proposal-surface :reader proposal-surface-of :initarg :proposal-surface
                     :type git-conflict-resolution-proposal-surface)
   (system-names :reader system-names-of :initarg :system-names :initform nil)
   (component-paths :reader component-paths-of :initarg :component-paths
                    :initform nil)
   (package-names :reader package-names-of :initarg :package-names :initform nil)
   (realized-proposals :reader realized-proposals-of :initarg :realized-proposals
                       :initform nil)
   (validation-commands :reader validation-commands-of
                        :initarg :validation-commands
                        :initform nil)))

(defclass git-protocol-seam ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (relation :reader relation-of :initarg :relation :type git-merge-intent)
   (scaffold :reader scaffold-of :initarg :scaffold
             :type git-dreyeck-executable-scaffold)
   (seam-type :reader seam-type-of :initarg :seam-type :type string)
   (core-paths :reader core-paths-of :initarg :core-paths :initform nil)
   (downstream-paths :reader downstream-paths-of :initarg :downstream-paths
                     :initform nil)
   (symbol-names :reader symbol-names-of :initarg :symbol-names :initform nil)
   (consumer-system :reader consumer-system-of :initarg :consumer-system
                    :type string)
   (core-call-surface :reader core-call-surface-of :initarg :core-call-surface
                      :type string)
   (behavior :reader behavior-of :initarg :behavior :type string)
   (realized-proposals :reader realized-proposals-of :initarg :realized-proposals
                       :initform nil)
   (validation-proof :reader validation-proof-of :initarg :validation-proof
                     :initform nil)))

(defclass git-protocol-seam-surface ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (relation :reader relation-of :initarg :relation :type git-merge-intent)
   (scaffold :reader scaffold-of :initarg :scaffold
             :type git-dreyeck-executable-scaffold)
   (seams :reader seams-of :initarg :seams :initform nil)))

(defclass git-merge-rehearsal ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (relation :reader relation-of :initarg :relation :type git-merge-intent)
   (forecast :reader forecast-of :initarg :forecast :type git-merge-forecast)
   (scaffold :reader scaffold-of :initarg :scaffold
             :type git-dreyeck-executable-scaffold)
   (proposal-surface :reader proposal-surface-of :initarg :proposal-surface
                     :type git-conflict-resolution-proposal-surface)
   (merge-base-commit :reader merge-base-commit-of :initarg :merge-base-commit
                      :type git-commit-target)
   (mechanism :reader mechanism-of :initarg :mechanism :type string)
   (virtual-merge-tree-hash :reader virtual-merge-tree-hash-of
                            :initarg :virtual-merge-tree-hash
                            :type string)
   (raw-conflict-paths :reader raw-conflict-paths-of :initarg :raw-conflict-paths
                       :initform nil)
   (additional-conflict-paths :reader additional-conflict-paths-of
                              :initarg :additional-conflict-paths
                              :initform nil)
   (message-lines :reader message-lines-of :initarg :message-lines :initform nil)
   (scaffold-sufficient-p :reader scaffold-sufficient-p-of
                          :initarg :scaffold-sufficient-p
                          :initform nil)
   (scaffold-direction-status :reader scaffold-direction-status-of
                              :initarg :scaffold-direction-status
                              :type string)
   (scaffold-evidence :reader scaffold-evidence-of :initarg :scaffold-evidence
                      :initform nil)
   (rehearsal-results :accessor rehearsal-results-of :initarg :rehearsal-results
                      :initform nil)))

(defclass git-rehearsal-result ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (rehearsal :reader rehearsal-of :initarg :rehearsal :type git-merge-rehearsal)
   (conflict :reader conflict-of :initarg :conflict :type git-manual-conflict)
   (proposal :reader proposal-of :initarg :proposal
             :type git-conflict-resolution-proposal)
   (path :reader path-of :initarg :path :type string)
   (merge-tree-status :reader merge-tree-status-of :initarg :merge-tree-status
                      :type string)
   (conflict-kind :reader conflict-kind-of :initarg :conflict-kind :initform nil)
   (clean-in-principle-p :reader clean-in-principle-p-of
                         :initarg :clean-in-principle-p
                         :initform nil)
   (proposal-readiness :reader proposal-readiness-of
                       :initarg :proposal-readiness
                       :type string)
   (scaffold-sufficiency :reader scaffold-sufficiency-of
                         :initarg :scaffold-sufficiency
                         :type string)
   (rationale :reader rationale-of :initarg :rationale :type string)
   (evidence :reader evidence-of :initarg :evidence :initform nil)))

(defclass git-extra-raw-conflict ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (rehearsal :reader rehearsal-of :initarg :rehearsal :type git-merge-rehearsal)
   (path :reader path-of :initarg :path :type string)
   (conflict-kind :reader conflict-kind-of :initarg :conflict-kind :initform nil)
   (looks-like :reader looks-like-of :initarg :looks-like :type string)
   (promote-to-manual-dossier-p :reader promote-to-manual-dossier-p-of
                                :initarg :promote-to-manual-dossier-p
                                :initform nil)
   (preliminary-preferred-handling :reader preliminary-preferred-handling-of
                                   :initarg :preliminary-preferred-handling
                                   :type string)))

(defclass git-raw-conflict-surface ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (rehearsal :reader rehearsal-of :initarg :rehearsal :type git-merge-rehearsal)
   (typed-manual-results :reader typed-manual-results-of :initarg :typed-manual-results
                         :initform nil)
   (extra-conflicts :reader extra-conflicts-of :initarg :extra-conflicts :initform nil)
   (remainder-paths :reader remainder-paths-of :initarg :remainder-paths :initform nil)))

(defclass git-history-surface ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (system :reader system-of :initarg :system :type asdf:system)
   (repo-root :reader repo-root-of :initarg :repo-root :type pathname)
   (local-branch :reader local-branch-of :initarg :local-branch :type git-branch-ref)
   (upstream-branch :reader upstream-branch-of :initarg :upstream-branch :type git-branch-ref)
   (relations :reader relations-of :initarg :relations :initform nil)
   (commit-window :reader commit-window-of :initarg :commit-window :initform 8 :type integer)))

(defun short-git-commit-hash (hash &optional (length 7))
  (subseq hash 0 (min length (length hash))))

(defun git-output-lines (repo-root &rest args)
  (sort (remove-duplicates
         (remove-if #'uiop:emptyp
                    (uiop:split-string
                     (apply #'git-command-output repo-root args)
                     :separator '(#\Newline)))
         :test #'string=)
        #'string<))

(defun string-list-difference (left right)
  (loop for item in left
        unless (member item right :test #'string=)
          collect item))

(defun string-list-intersection (left right)
  (loop for item in left
        when (member item right :test #'string=)
          collect item))

(defun git-merge-base-hash (repo-root source-hash target-hash)
  (let ((hash (git-command-output repo-root "merge-base" source-hash target-hash)))
    (unless (full-git-commit-hash-p hash)
      (signal-git-runtime-unavailable
       :operation "git merge-base"
       :repository-root repo-root
       :reason (format nil "Expected a merge-base hash for ~A and ~A."
                       source-hash
                       target-hash)
       :detail hash))
    hash))

(defun git-changed-paths-between (repo-root from-hash to-hash)
  (git-output-lines repo-root
                    "-c"
                    "core.quotePath=false"
                    "diff"
                    "--name-only"
                    (format nil "~A..~A" from-hash to-hash)))

(defun string-contains-ci-p (needle haystack)
  (not (null (search needle haystack :test #'char-equal))))

(defun note-applies-to-path-p (note path)
  (or (member path (paths-of note) :test #'string=)
      (and (string= (id-of note) "dreyeck-runtime-catalog-seam")
           (or (uiop:string-prefix-p "hyperbook-server/" path)
               (uiop:string-prefix-p "assets/hyperbook-server/" path)
               (uiop:string-prefix-p "nix/" path)))
      (and (string= (id-of note) "dreyeck-link-and-page-resolution-seam")
           (or (uiop:string-prefix-p "hyperbook-explorer/" path)
               (string= path "hyperdoc-explorer/html-pages.lisp")
               (string= path "hyperdoc/tools.lisp")))))

(defun relation-note-for-path (relation path)
  (find-if (lambda (note)
             (note-applies-to-path-p note path))
           (notes-of relation)))

(defun merge-tree-message-line-p (line)
  (or (uiop:string-prefix-p "Auto-merging " line)
      (uiop:string-prefix-p "CONFLICT (" line)))

(defun parse-merge-tree-conflict-line (line)
  (when (uiop:string-prefix-p "CONFLICT (" line)
    (let* ((kind-start (1+ (position #\( line)))
           (kind-end (and kind-start
                          (position #\) line :start kind-start)))
           (path-marker "Merge conflict in ")
           (path-start (search path-marker line :test #'char=)))
      (when (and kind-start kind-end path-start)
        (cons (subseq line (+ path-start (length path-marker)))
              (subseq line kind-start kind-end))))))

(defun merge-tree-conflict-kind-for-path (path message-lines)
  (loop for line in message-lines
        for parsed = (parse-merge-tree-conflict-line line)
        when (and parsed
                  (string= path (car parsed)))
          do (return (cdr parsed))))

(defun git-merge-tree-rehearsal-report (repo-root source-hash target-hash)
  (let* ((output (git-command-output-ignore-status repo-root
                                                   "merge-tree"
                                                   "--write-tree"
                                                   "--name-only"
                                                   source-hash
                                                   target-hash))
         (lines (uiop:split-string output :separator '(#\Newline)))
         (virtual-tree-hash (or (first lines) ""))
         (state :paths)
         (raw-conflict-paths nil)
         (message-lines nil))
    (unless (full-git-commit-hash-p virtual-tree-hash)
      (signal-git-runtime-unavailable
       :operation "git merge-tree --write-tree --name-only"
       :repository-root repo-root
       :reason "Expected git merge-tree to yield a virtual tree hash."
       :detail output))
    (loop for line in (rest lines)
          do (cond
               ((and (eq state :paths)
                     (uiop:emptyp line))
                (setf state :messages))
               ((eq state :paths)
                (push line raw-conflict-paths))
               ((merge-tree-message-line-p line)
                (push line message-lines))))
    (list :virtual-merge-tree-hash virtual-tree-hash
          :raw-conflict-paths (nreverse raw-conflict-paths)
          :message-lines (nreverse message-lines))))

(defun external-symbol-named-p (symbol-designator)
  (let ((separator (position #\: symbol-designator)))
    (when separator
      (let* ((package-name (subseq symbol-designator 0 separator))
             (symbol-name (subseq symbol-designator (1+ separator)))
             (package (find-package package-name)))
        (when package
          (multiple-value-bind (symbol status)
              (find-symbol symbol-name package)
            (and symbol
                 (eq status :external))))))))

(defun fbound-symbol-named-p (symbol-designator)
  (let ((separator (position #\: symbol-designator)))
    (when separator
      (let* ((package-name (subseq symbol-designator 0 separator))
             (symbol-name (subseq symbol-designator (1+ separator)))
             (package (find-package package-name)))
        (when package
          (multiple-value-bind (symbol status)
              (find-symbol symbol-name package)
            (and symbol
                 status
                 (fboundp symbol))))))))

(defun dreyeck-server-dependency-direction-ready-p ()
  (when-let (system (ignore-errors
                      (asdf:find-system :dreyeck/server)))
    (member "hyperdoc/server"
            (asdf:system-depends-on system)
            :test #'string=)))

(defun dreyeck-scaffold-rehearsal-assessment ()
  (handler-case
      (progn
        (asdf:load-system :dreyeck/server)
        (let* ((checks (list
                        (cons "ASDF graph keeps :dreyeck/server downstream of :hyperdoc/server."
                              (dreyeck-server-dependency-direction-ready-p))
                        (cons "HyperBook core exports register-link-redirection."
                              (external-symbol-named-p
                               "hyperbook:register-link-redirection"))
                        (cons "HyperBook core exports register-link-target-rewriter."
                              (external-symbol-named-p
                               "hyperbook:register-link-target-rewriter"))
                        (cons "HyperBook server exports register-server-startup-hook."
                              (external-symbol-named-p
                               "hyperbook/server:register-server-startup-hook"))
                        (cons "Dreyeck scaffold installs its downstream entrypoint."
                              (fbound-symbol-named-p
                               "dreyeck/server:install-dreyeck-server-scaffold"))))
               (ok (every #'cdr checks)))
          (list :ok ok
                :status (if ok
                            "sufficient-for-current-asdf-and-package-direction"
                            "incomplete-for-current-asdf-and-package-direction")
                :evidence
                (loop for (message . passedp) in checks
                      collect (format nil "~:[missing~;ok~]: ~A"
                                      passedp
                                      message)))))
    (error (condition)
      (list :ok nil
            :status "failed-to-load-dreyeck-scaffold"
            :evidence (list (princ-to-string condition))))))

(defmethod print-object ((object git-branch-ref) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A@~A"
            (branch-name-of object)
            (short-git-commit-hash (commit-hash-of object)))))

(defmethod print-object ((object git-merge-intent) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object git-merge-preparation-note) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object git-merge-forecast) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object git-path-decision) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object git-path-decision-surface) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object git-dreyeck-extraction-plan) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object git-dreyeck-extraction-bucket) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object git-dreyeck-transition-plan) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object git-dreyeck-transition-bucket) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object git-manual-conflict) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object git-manual-conflict-dossier) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object git-conflict-resolution-proposal) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object git-conflict-resolution-proposal-surface) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object git-dreyeck-executable-scaffold) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object git-protocol-seam) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object git-protocol-seam-surface) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object git-merge-rehearsal) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object git-rehearsal-result) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object git-extra-raw-conflict) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object git-raw-conflict-surface) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object git-history-surface) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmacro def-git-runtime-entrypoint (name lambda-list &body body)
  `(defun ,name ,lambda-list
     (call-with-git-runtime-boundary
      (lambda ()
        ,@body))))

(defun %system-git-branch-ref (system-designator branch-name
                                &key
                                  full-commit-hash
                                  role
                                  aliases)
  (let ((system (etypecase system-designator
                  (asdf:system
                   system-designator)
                  ((or string symbol)
                   (asdf:find-system system-designator)))))
    (unless (full-git-commit-hash-p full-commit-hash)
      (error "Expected a full 40-character Git commit hash for ~A, got ~S."
             branch-name
             full-commit-hash))
    (make-instance 'git-branch-ref
                   :system system
                   :repo-root (system-repository-root system)
                   :name branch-name
                   :commit-hash (string-downcase full-commit-hash)
                   :role role
                   :aliases aliases)))

(def-git-runtime-entrypoint system-git-branch-ref
    (system-designator branch-name &key full-commit-hash role aliases)
  (%system-git-branch-ref system-designator
                          branch-name
                          :full-commit-hash full-commit-hash
                          :role role
                          :aliases aliases))

(defun git-branch-target (branch-ref)
  (%system-git-commit-target (system-of branch-ref)
                             (commit-hash-of branch-ref)))

(defun git-branch-current-commit-hash (branch-ref)
  (let ((output (ignore-errors
                  (git-command-output
                   (repo-root-of branch-ref)
                   "rev-parse"
                   (branch-name-of branch-ref)))))
    (and (full-git-commit-hash-p output)
         output)))

(defun git-branch-resolution-status (branch-ref)
  (let ((current-hash (git-branch-current-commit-hash branch-ref)))
    (cond ((null current-hash)
           :missing)
          ((string= current-hash (commit-hash-of branch-ref))
           :matches)
          (t
           :drifted))))

(defun git-branch-current-target (branch-ref)
  (when-let (current-hash (git-branch-current-commit-hash branch-ref))
    (%system-git-commit-target (system-of branch-ref)
                               current-hash)))

(defun git-commit-metadata-field (target label)
  (cdr (assoc label (git-commit-metadata target) :test #'string=)))

(defun git-branch-history-targets (branch-ref &key (limit 8) exclude-refs)
  (let* ((args (append (list "rev-list"
                             (format nil "--max-count=~D" limit)
                             (branch-name-of branch-ref))
                       (loop for excluded-branch in exclude-refs
                             collect (format nil "^~A"
                                             (branch-name-of excluded-branch)))))
         (lines (uiop:split-string
                 (apply #'git-command-output (repo-root-of branch-ref) args)
                 :separator '(#\Newline))))
    (loop for line in lines
          when (full-git-commit-hash-p line)
            collect (%system-git-commit-target (system-of branch-ref) line))))

(defun git-history-local-commits (surface)
  (git-branch-history-targets (local-branch-of surface)
                              :limit (commit-window-of surface)
                              :exclude-refs (list (upstream-branch-of surface))))

(defun git-history-upstream-commits (surface)
  (git-branch-history-targets (upstream-branch-of surface)
                              :limit (commit-window-of surface)
                              :exclude-refs (list (local-branch-of surface))))

(defun git-history-merge-worklist (surface &key (target-branch (local-branch-of surface)))
  (loop for relation in (relations-of surface)
        when (string= (branch-name-of (target-branch-of relation))
                      (branch-name-of target-branch))
          collect relation))

(defun make-git-path-decision (relation path-set path classification rationale
                               &key linked-note)
  (make-instance
   'git-path-decision
   :id (format nil "~A/~A/~A"
               (id-of relation)
               path-set
               path)
   :title (format nil "~A -> ~A"
                  classification
                  path)
   :summary rationale
   :relation relation
   :path-set path-set
   :path path
   :classification classification
   :rationale rationale
   :linked-note linked-note))

(defun overlapping-path-decision (relation path)
  (let ((note (relation-note-for-path relation path)))
    (cond
      ((member path '("hyperbook-fedwiki/fedwiki.lisp"
                      "hyperbook-fedwiki/pages.lisp"
                      "hyperbook-fedwiki/plugins.lisp"
                      "hyperbook-fedwiki/story-items.lisp"
                      "hyperbook-fedwiki/utilities.lisp"
                      "hyperbook-fedwiki/views.lisp"
                      "hyperbook-fedwiki/wiki-links.lisp"
                      "hyperbook-wikipedia/list-wikipedia-editions.lisp"
                      "hyperbook-wikipedia/wikipedia-editions.lisp"
                      "hyperbook-wikipedia/wikipedia.lisp")
               :test #'string=)
       (make-git-path-decision
        relation
        "overlapping"
        path
        "adopt-upstream"
        "Upstream owns the generic integration logic here; local behavior should not keep diverging in this shared support layer."
        :linked-note note))
      ((member path '("hyperbook/catalog.lisp"
                      "hyperbook/hyperbooks.lisp")
               :test #'string=)
       (make-git-path-decision
        relation
        "overlapping"
        path
        "keep-hauptsache"
        "The local catalog wiring must survive the merge for now; keep the branch behavior visible until its downstream seam is extracted cleanly."
        :linked-note note))
      ((member path '("hyperbook-explorer/package.lisp"
                      "hyperbook.asd"
                      "hyperbook/package.lisp")
               :test #'string=)
       (make-git-path-decision
        relation
        "overlapping"
        path
        "manual-merge-needed"
        "Package and system definitions need a deliberate union of exports, dependencies, and load order rather than a one-sided choice."
        :linked-note note))
      (t
       (make-git-path-decision
        relation
        "overlapping"
        path
        "extract-to-dreyeck"
        "This shared path looks like a branch-specific policy seam; move the local delta behind dreyeck instead of preserving a long-lived patch in upstream-touched code."
        :linked-note note)))))

(defun clearly-dreyeck-candidate-path-p (path)
  (or (member path '(".envrc"
                     "dev.sh"
                     "start.sh"
                     "flake.nix"
                     "flake.lock"
                     "assets/hyperbook-server/js/url.js")
              :test #'string=)
      (uiop:string-prefix-p "hyperbook-server/" path)
      (uiop:string-prefix-p "nix/" path)
      (string-contains-ci-p "dreyeck" path)
      (string-contains-ci-p "deploy" path)
      (string-contains-ci-p "restart" path)
      (string-contains-ci-p "legacy hyperdoc.service" path)
      (string-contains-ci-p "verify hyperdoc on dreyeck.ch" path)
      (string-contains-ci-p "probe dreyeck" path)
      (string-contains-ci-p "live parity" path)
      (string-contains-ci-p "local boot" path)))

(defun likely-keep-in-hyperdoc-core-path-p (path)
  (or (string= path "hyperdoc.asd")
      (uiop:string-prefix-p "hyperbook/" path)
      (uiop:string-prefix-p "hyperbook-explorer/" path)
      (uiop:string-prefix-p "hyperbook-wikipedia/" path)
      (uiop:string-prefix-p "hyperdoc/" path)
      (uiop:string-prefix-p "hyperdoc-explorer/" path)
      (uiop:string-prefix-p "hyperdoc-inspector/" path)
      (uiop:string-prefix-p "njson/" path)
      (uiop:string-prefix-p "tests/" path)
      (uiop:string-prefix-p "tools/" path)))

(defun hauptsache-only-path-decision (relation path)
  (let ((note (relation-note-for-path relation path)))
    (cond
      ((clearly-dreyeck-candidate-path-p path)
       (make-git-path-decision
        relation
        "hauptsache-only"
        path
        "clearly-dreyeck-candidate"
        "This path looks tied to local runtime, deployment, or dreyeck-specific behavior rather than something upstream HyperDoc core should absorb unchanged."
        :linked-note note))
      ((likely-keep-in-hyperdoc-core-path-p path)
       (make-git-path-decision
        relation
        "hauptsache-only"
        path
        "likely-keep-in-hyperdoc-core"
        "This path reads like general HyperDoc or HyperBook implementation or durable documentation and is a better candidate for core retention than downstream extraction."
        :linked-note note))
      (t
       (make-git-path-decision
        relation
        "hauptsache-only"
        path
        "unknown-needs-review"
        "The pathname alone does not settle whether this belongs in dreyeck or in shared HyperDoc core; review it explicitly before merge execution."
        :linked-note note)))))

(defun git-overlapping-path-decisions (forecast)
  (let ((relation (relation-of forecast)))
    (loop for path in (overlapping-paths-of forecast)
          collect (overlapping-path-decision relation path))))

(defun git-hauptsache-only-path-decisions (forecast)
  (let ((relation (relation-of forecast)))
    (loop for path in (hauptsache-only-paths-of forecast)
          collect (hauptsache-only-path-decision relation path))))

(defun git-path-decisions-with-classification (decisions classification)
  (loop for decision in decisions
        when (string= (classification-of decision) classification)
          collect decision))

(defun git-manual-overlapping-path-decisions (forecast)
  (git-path-decisions-with-classification
   (git-overlapping-path-decisions forecast)
   "manual-merge-needed"))

(defun git-hauptsache-dreyeck-candidate-decisions (forecast)
  (git-path-decisions-with-classification
   (git-hauptsache-only-path-decisions forecast)
   "clearly-dreyeck-candidate"))

(defun git-hauptsache-unknown-path-decisions (forecast)
  (git-path-decisions-with-classification
   (git-hauptsache-only-path-decisions forecast)
   "unknown-needs-review"))

(defun make-git-path-decision-surface (forecast id title summary decisions)
  (make-instance 'git-path-decision-surface
                 :id id
                 :title title
                 :summary summary
                 :forecast forecast
                 :decisions decisions))

(defun git-overlapping-path-decision-surface (forecast)
  (make-git-path-decision-surface
   forecast
   (format nil "~A-overlapping-decisions" (id-of forecast))
   "Overlapping path decisions"
   "Inspectable per-path decisions for the overlapping paths between upstream/main and hauptsache."
   (git-overlapping-path-decisions forecast)))

(defun git-hauptsache-path-decision-surface (forecast)
  (make-git-path-decision-surface
   forecast
   (format nil "~A-hauptsache-decisions" (id-of forecast))
   "Hauptsache-only path classifications"
   "Bucketed classification pass for hauptsache-only paths."
   (git-hauptsache-only-path-decisions forecast)))

(defun git-dreyeck-candidate-path-surface (forecast)
  (make-git-path-decision-surface
   forecast
   (format nil "~A-dreyeck-candidates" (id-of forecast))
   "Dreyeck candidate paths"
   "Filtered hauptsache-only paths that already look like downstream dreyeck candidates."
   (git-hauptsache-dreyeck-candidate-decisions forecast)))

(defun git-unresolved-manual-path-surface (forecast)
  (make-git-path-decision-surface
   forecast
   (format nil "~A-manual-overlap" (id-of forecast))
   "Unresolved manual overlapping paths"
   "Filtered overlapping paths that still need explicit hand-merge decisions."
   (git-manual-overlapping-path-decisions forecast)))

(defun duplicate-strings (strings)
  (let ((seen nil)
        (duplicates nil))
    (dolist (string strings (nreverse duplicates))
      (if (member string seen :test #'string=)
          (pushnew string duplicates :test #'string=)
          (push string seen)))))

(defun dreyeck-extraction-bucket-specs ()
  (list
   (list
    :bucket-type "runtime-hooks"
    :title "Runtime hooks"
    :summary "Local server startup, inspector tuning, and runtime URL behavior should become a dreyeck-owned runtime layer instead of a long-lived patch stack in shared server code."
    :paths '("assets/hyperbook-server/js/url.js"
             "hyperbook-server/assets/hyperbook-server/js/url.js"
             "hyperbook-server/inspector-performance.lisp"
             "hyperbook-server/inspector-wiring.lisp"
             "hyperbook-server/playground-bindings.lisp"
             "hyperbook-server/playground-package.lisp"
             "hyperbook-server/playground-stepper.lisp"
             "hyperbook-server/server.lisp")
    :why-not-upstream-core
    "These paths encode local runtime behavior, startup wiring, and inspector/playground policy that exists to support the dreyeck deployment context rather than generic HyperDoc server semantics."
    :expected-asdf-placement ":dreyeck/server"
    :expected-dependency-direction ":dreyeck/server -> :hyperdoc/server"
    :adaptation-mode "replace-with-hook/protocol-seam")
   (list
    :bucket-type "local-deployment"
    :title "Local deployment"
    :summary "Host-specific flake, host module, and release packaging paths belong to the dreyeck deployment layer, not in upstream HyperDoc core."
    :paths '(".envrc"
             "flake.lock"
             "flake.nix"
             "nix/hosts/dreyeck-ch-fallback-hardware.nix"
             "nix/hosts/dreyeck-ch.nix"
             "nix/hosts/dreyeck-ch/hardware-configuration.nix"
             "nix/modules/hyperdoc-release.nix"
             "nix/release/package.nix"
             "start.sh")
    :why-not-upstream-core
    "These files describe machine-specific deployment state, release packaging, and local bootstrap behavior that should stay downstream even after the merge."
    :expected-asdf-placement "outside ASDF; dreyeck release and host layer"
    :expected-dependency-direction "dreyeck deployment layer -> built :hyperdoc and future :dreyeck systems"
    :adaptation-mode "move")
   (list
    :bucket-type "page-content-overlays"
    :title "Page and content overlays"
    :summary "Operational pages about dreyeck deployment, parity, rollback, and local boot should live as downstream overlays instead of upstream reference content."
    :paths '("hyperdoc-inspector/playground-restarts.html"
             "hyperdoc/Back up dreyeck.ch before deployment.html"
             "hyperdoc/Confirm scoped example parity on dreyeck.html"
             "hyperdoc/Deploy dreyeck.ch from the local flake.html"
             "hyperdoc/Deploy or restart dreyeck and confirm live parity.html"
             "hyperdoc/Detect legacy workspace-checkout hyperdoc.service on dreyeck.ch.html"
             "hyperdoc/Diagnose sbcl command-not-found in the legacy hyperdoc.service.html"
             "hyperdoc/Get hauptsache working on dreyeck.ch.html"
             "hyperdoc/Landing Page Redirect to Local Boot.html"
             "hyperdoc/Live parity evidence.html"
             "hyperdoc/New team member onboarding for dreyeck operations.html"
             "hyperdoc/Onboarding dreyeck deployment and restart.html"
             "hyperdoc/Probe dreyeck runtime load set.html"
             "hyperdoc/Record dreyeck.ch generation before rebuild.html"
             "hyperdoc/Rehearse dreyeck.ch deployment with runner.html"
             "hyperdoc/Restart dreyeck release service.html"
             "hyperdoc/Roll back HyperDoc on dreyeck.ch.html"
             "hyperdoc/Training arc: deploy and restart dreyeck safely.html"
             "hyperdoc/Training arc: verify scoped examples after deployment.html"
             "hyperdoc/Verify HyperDoc locally before deployment.html"
             "hyperdoc/Verify HyperDoc on dreyeck.ch.html")
    :why-not-upstream-core
    "These pages describe dreyeck-specific operational workflows, deployment evidence, and local boot behavior; upstream HyperDoc documentation should remain host-agnostic."
    :expected-asdf-placement ":dreyeck/content"
    :expected-dependency-direction ":dreyeck/content -> :hyperdoc"
    :adaptation-mode "move")
   (list
    :bucket-type "glue-code"
    :title "Glue code"
    :summary "Local wrappers, dependency shims, and vendor patches should stay as dreyeck-owned glue around the core systems until cleaner extension seams replace them."
    :paths '("dev.sh"
             "nix/patches/clog-boot-ignore-empty-ids.patch"
             "nix/patches/clog-moldable-inspector-playground-eval.patch"
             "nix/sbcl-named-closure.nix"
             "nix/vendor/named-closure/named-closure.asd"
             "nix/vendor/named-closure/named-closure.lisp")
    :why-not-upstream-core
    "These paths bridge local development and release behavior into the current tree through wrappers, patches, and vendored glue that upstream should not absorb unchanged."
    :expected-asdf-placement ":dreyeck/dev plus dreyeck release support"
    :expected-dependency-direction "dreyeck glue -> core systems and release tooling"
    :adaptation-mode "wrap")))

(defun ensure-dreyeck-bucket-specs-cover-candidates (candidate-paths specs)
  (let* ((bucket-paths (loop for spec in specs
                             append (copy-list (getf spec :paths))))
         (duplicates (duplicate-strings bucket-paths))
         (missing (string-list-difference candidate-paths bucket-paths))
         (extra (string-list-difference bucket-paths candidate-paths)))
    (when duplicates
      (error "Dreyeck extraction bucket specs contain duplicate path~:P: ~{~A~^, ~}."
             duplicates))
    (when missing
      (error "Dreyeck extraction bucket specs are missing candidate path~:P: ~{~A~^, ~}."
             missing))
    (when extra
      (error "Dreyeck extraction bucket specs include non-candidate path~:P: ~{~A~^, ~}."
             extra))))

(defun make-git-dreyeck-extraction-bucket (forecast spec candidate-paths)
  (make-instance
   'git-dreyeck-extraction-bucket
   :id (format nil "~A/~A" (id-of forecast) (getf spec :bucket-type))
   :title (getf spec :title)
   :summary (getf spec :summary)
   :relation (relation-of forecast)
   :forecast forecast
   :bucket-type (getf spec :bucket-type)
   :paths (loop for path in candidate-paths
                when (member path (getf spec :paths) :test #'string=)
                  collect path)
   :why-not-upstream-core (getf spec :why-not-upstream-core)
   :expected-asdf-placement (getf spec :expected-asdf-placement)
   :expected-dependency-direction (getf spec :expected-dependency-direction)
   :adaptation-mode (getf spec :adaptation-mode)))

(defun git-dreyeck-extraction-buckets (forecast)
  (let* ((candidate-paths (loop for decision in (git-hauptsache-dreyeck-candidate-decisions forecast)
                                collect (path-of decision)))
         (specs (dreyeck-extraction-bucket-specs)))
    (ensure-dreyeck-bucket-specs-cover-candidates candidate-paths specs)
    (loop for spec in specs
          collect (make-git-dreyeck-extraction-bucket forecast spec candidate-paths))))

(defun git-dreyeck-extraction-plan-from-forecast (forecast)
  (make-instance
   'git-dreyeck-extraction-plan
   :id (format nil "~A-dreyeck-plan" (id-of forecast))
   :title "Dreyeck extraction plan"
   :summary "Concrete plan for extracting the currently identified dreyeck candidate paths into downstream buckets before any merge execution."
   :relation (relation-of forecast)
   :forecast forecast
   :buckets (git-dreyeck-extraction-buckets forecast)))

(defun dreyeck-transition-bucket-specs ()
  (list
   (list
    :bucket-type "runtime-hooks"
    :title "Transition runtime hooks into :dreyeck/server"
    :summary "Split the runtime/startup hook paths into a downstream server system while leaving HyperDoc core with a narrow startup protocol."
    :target-destination
    ":dreyeck/server components dreyeck-server/package.lisp, runtime-hooks.lisp, inspector-hooks.lisp, playground-hooks.lisp, and a downstream URL asset overlay."
    :dependency-direction
    ":dreyeck/server depends on :hyperdoc/server; :hyperdoc/server must not depend on dreyeck."
    :transition-mode "split"
    :core-continuation
    "HyperDoc core must keep exporting hyperbook/server:serve-catalog and invoke small startup, inspector, and asset hook seams without importing dreyeck packages directly."
    :validation-proof
    '("asdf:load-system :hyperdoc"
      "asdf:load-system :hyperdoc/server"
      "nix run . starts the server"
      "GET /boot.html still returns 200"
      "existing HyperDoc pages still render"))
   (list
    :bucket-type "local-deployment"
    :title "Move deployment files into the dreyeck release tree"
    :summary "Keep host-specific Nix, flake, and launcher files outside HyperDoc core and let them consume built core artifacts as a downstream deployment layer."
    :target-destination
    "Outside ASDF in a dreyeck deployment tree: dreyeck/flake.nix, dreyeck/nix/{hosts,modules,release}, and dreyeck/start.sh."
    :dependency-direction
    "dreyeck deployment layer depends on built :hyperdoc and :dreyeck/server artifacts; HyperDoc core has no reverse dependency."
    :transition-mode "move"
    :core-continuation
    "HyperDoc core must continue to build and load via ASDF without importing host-specific Nix modules, flake entrypoints, or release scripts."
    :validation-proof
    '("asdf:load-system :hyperdoc"
      "asdf:load-system :hyperdoc/server"
      "nix run . still builds the staged release"
      "the served catalog still comes up after the downstream launcher consumes the built artifacts"))
   (list
    :bucket-type "page-content-overlays"
    :title "Move dreyeck pages into :dreyeck/content overlays"
    :summary "Downstream operational pages should load as additive dreyeck overlay content instead of remaining mixed into upstream reference pages."
    :target-destination
    ":dreyeck/content modules for dreyeck/hyperdoc/*.html and dreyeck/hyperdoc-inspector/*.html overlay pages."
    :dependency-direction
    ":dreyeck/content depends on :hyperdoc and adds overlay pages without creating a reverse dependency."
    :transition-mode "move"
    :core-continuation
    "HyperDoc core must continue to resolve shared catalog pages and inspector surfaces; downstream dreyeck pages should load as additive overlays rather than edits to upstream core content."
    :validation-proof
    '("asdf:load-system :hyperdoc"
      "existing HyperDoc pages still render"
      "tools/check-topic-coverage.lisp stays green for moved or remaining pages"
      "dreyeck overlay pages resolve after downstream content loads"))
   (list
    :bucket-type "glue-code"
    :title "Wrap local glue around stable core entrypoints"
    :summary "Keep local dev wrappers, vendor shims, and release patches in a downstream support layer that wraps official HyperDoc entrypoints instead of redefining them in core."
    :target-destination
    ":dreyeck/dev support plus dreyeck/nix/patches and dreyeck/vendor/named-closure."
    :dependency-direction
    "dreyeck dev/release glue depends on :hyperdoc/server and external tooling; HyperDoc core must not depend on the wrappers."
    :transition-mode "wrap"
    :core-continuation
    "HyperDoc core must continue to expose stable ASDF and server entrypoints; downstream wrappers provide patched named-closure and developer-launch behavior around those entrypoints."
    :validation-proof
    '("asdf:load-system :hyperdoc"
      "asdf:load-system :hyperdoc/server"
      "nix run . still succeeds"
      "downstream dev launchers can wrap the core server without patching the core load graph"))))

(defun ensure-dreyeck-transition-specs-cover-buckets (buckets specs)
  (let* ((bucket-types (mapcar #'bucket-type-of buckets))
         (spec-types (mapcar (lambda (spec)
                               (getf spec :bucket-type))
                             specs))
         (duplicates (duplicate-strings spec-types))
         (missing (string-list-difference bucket-types spec-types))
         (extra (string-list-difference spec-types bucket-types)))
    (when duplicates
      (error "Dreyeck transition specs contain duplicate bucket type~:P: ~{~A~^, ~}."
             duplicates))
    (when missing
      (error "Dreyeck transition specs are missing bucket type~:P: ~{~A~^, ~}."
             missing))
    (when extra
      (error "Dreyeck transition specs include unknown bucket type~:P: ~{~A~^, ~}."
             extra))))

(defun make-git-dreyeck-transition-bucket (forecast extraction-bucket spec)
  (make-instance
   'git-dreyeck-transition-bucket
   :id (format nil "~A/transition/~A"
               (id-of forecast)
               (bucket-type-of extraction-bucket))
   :title (getf spec :title)
   :summary (getf spec :summary)
   :relation (relation-of forecast)
   :forecast forecast
   :extraction-bucket extraction-bucket
   :bucket-type (bucket-type-of extraction-bucket)
   :paths (copy-list (paths-of extraction-bucket))
   :target-destination (getf spec :target-destination)
   :dependency-direction (getf spec :dependency-direction)
   :transition-mode (getf spec :transition-mode)
   :core-continuation (getf spec :core-continuation)
   :validation-proof (copy-list (getf spec :validation-proof))))

(defun git-dreyeck-transition-buckets (forecast)
  (let* ((extraction-plan (git-dreyeck-extraction-plan-from-forecast forecast))
         (buckets (buckets-of extraction-plan))
         (specs (dreyeck-transition-bucket-specs)))
    (ensure-dreyeck-transition-specs-cover-buckets buckets specs)
    (loop for bucket in buckets
          for spec = (find (bucket-type-of bucket)
                           specs
                           :key (lambda (entry)
                                  (getf entry :bucket-type))
                           :test #'string=)
          collect (make-git-dreyeck-transition-bucket forecast bucket spec))))

(defun git-dreyeck-transition-plan-from-forecast (forecast)
  (let ((extraction-plan (git-dreyeck-extraction-plan-from-forecast forecast)))
    (make-instance
     'git-dreyeck-transition-plan
     :id (format nil "~A-dreyeck-transition" (id-of forecast))
     :title "Dreyeck transition plan"
     :summary "Implementation-ready downstream transition plan for the current dreyeck extraction buckets, including target destinations, dependency direction, core call surfaces, and validation proofs."
     :relation (relation-of forecast)
     :forecast forecast
     :extraction-plan extraction-plan
     :bucket-transitions (git-dreyeck-transition-buckets forecast))))

(defun manual-conflict-spec (path)
  (cond
    ((string= path "hyperbook.asd")
     (list
      :title "Manual conflict: hyperbook.asd"
      :summary "ASDF system composition still needs a deliberate merge."
      :reason
      "Both branches changed system composition and load order here; the merged file must keep upstream system structure intact while making space for a later dreyeck subsystem instead of burying branch-specific release wiring in core."
      :preferred-resolution
      "Start from upstream's system graph, manually union only the shared dependencies and load order that still belong in HyperDoc core, and reserve dreyeck-specific code for a separate downstream system."
      :result-placement "hyperdoc core"))
    ((string= path "hyperbook/package.lisp")
     (list
      :title "Manual conflict: hyperbook/package.lisp"
      :summary "Package exports and imports still need a deliberate merge."
      :reason
      "Package exports define the public protocol surface, so this file cannot be merged mechanically without risking accidental export drift or leaking dreyeck-only names into shared HyperBook core."
      :preferred-resolution
      "Keep upstream's package definition as the base, manually add only the hook or protocol exports that core truly needs, and move branch-specific exports into a later dreyeck package."
      :result-placement "hyperdoc core"))
    ((string= path "hyperbook-explorer/package.lisp")
     (list
      :title "Manual conflict: hyperbook-explorer/package.lisp"
      :summary "Explorer package surface still needs a deliberate merge."
      :reason
      "The explorer package straddles shared UI and branch-specific lookup behavior, so the merged export surface must be curated instead of keeping a one-sided package definition."
      :preferred-resolution
      "Use upstream's explorer package as the base, add only the shared extension-hook names required by core, and keep dreyeck-specific explorer bindings in a downstream package."
      :result-placement "hyperdoc core"))
    (t
     (error "No manual conflict spec for path ~S." path))))

(defun make-git-manual-conflict (forecast decision)
  (let* ((relation (relation-of forecast))
         (path (path-of decision))
         (spec (manual-conflict-spec path)))
    (make-instance
     'git-manual-conflict
     :id (format nil "~A/manual/~A" (id-of forecast) path)
     :title (getf spec :title)
     :summary (getf spec :summary)
     :relation relation
     :forecast forecast
     :decision decision
     :path path
     :source-branch (source-branch-of relation)
     :target-branch (target-branch-of relation)
     :reason (getf spec :reason)
     :preferred-resolution (getf spec :preferred-resolution)
     :result-placement (getf spec :result-placement))))

(defun git-manual-conflicts (forecast)
  (loop for decision in (git-manual-overlapping-path-decisions forecast)
        collect (make-git-manual-conflict forecast decision)))

(defun git-manual-conflict-for-path (forecast path)
  (find path
        (git-manual-conflicts forecast)
        :key #'path-of
        :test #'string=))

(defun git-manual-conflict-dossier-from-forecast (forecast)
  (make-instance
   'git-manual-conflict-dossier
   :id (format nil "~A-manual-conflicts" (id-of forecast))
   :title "Manual merge dossier"
   :summary "Typed dossier for the remaining manual overlapping paths that still require curated merge decisions."
   :relation (relation-of forecast)
   :forecast forecast
   :conflicts (git-manual-conflicts forecast)))

(defun conflict-resolution-proposal-spec (path)
  (cond
    ((string= path "hyperbook.asd")
     (list
      :title "Resolution proposal: hyperbook.asd"
      :summary "Keep the shared ASDF graph in HyperDoc core, but peel runtime-specific server files into future dreyeck systems."
      :conflict-shape
      "Both branches extend the same system definitions. Upstream adds link-redirection in hyperbook/explorer plus wikipedia-editions and the supporting hunchentoot dependency. Hauptsache adds those shared updates and also inserts lookup-failures, asdf-plan-view, html-inspector-views/standard, clog, and the inspector/playground server files."
      :preferred-merged-form
      "Use upstream's system graph as the baseline, keep the shared explorer diagnostics that are now used generically by HyperDoc core, and move the inspector/performance/playground server files into future :dreyeck/server components so :hyperbook/server stays close to upstream."
      :result-placement "hyperdoc core"
      :patch-sketch
      "hyperbook/explorer: keep shared additions like lookup-failures, link-redirection, and asdf-plan-view in the core system list if their callers stay in core.
hyperbook/server: keep (:file \"package\") and (:file \"server\") in :hyperbook/server, but move inspector-wiring, inspector-performance, playground-stepper, playground-package, and playground-bindings into future :dreyeck/server.
Keep the future dependency direction one-way: :dreyeck/server -> :hyperdoc/server."))
    ((string= path "hyperbook/package.lisp")
     (list
      :title "Resolution proposal: hyperbook/package.lisp"
      :summary "The package conflict collapses to a shared hook export; keep that hook in HyperBook core and stop there."
      :conflict-shape
      "Both branches add the same catalog API export, #:register-link-redirection, in the same export block. The anchored file tips already agree textually, so the remaining work is to confirm that this hook stays in HyperBook core and that no dreyeck-only exports piggyback onto :hyperbook."
      :preferred-merged-form
      "Keep a single core export for #:register-link-redirection in :hyperbook. Do not move this export to dreyeck, because generic core catalog code and shared link-redirection support already call it."
      :result-placement "hyperdoc core"
      :patch-sketch
      ";; The catalog API
-#:register #:register-scheme
+#:register #:register-scheme #:register-link-redirection"))
    ((string= path "hyperbook-explorer/package.lisp")
     (list
      :title "Resolution proposal: hyperbook-explorer/package.lisp"
      :summary "Union the shared upstream link exports with the current lookup-diagnostics exports, while keeping the package itself in HyperBook core."
      :conflict-shape
      "Both branches edit the same export form. Upstream adds generic page-link, hyperbook-link, no-links?, replace-by-hyperbook-link, and render-hyperbook-or-page-link exports. Hauptsache adds those shared names and also extends the package with source metadata and lookup-issue diagnostic exports that are now consumed by HyperDoc core explorer files."
      :preferred-merged-form
      "Start from upstream's export block, then merge in the lookup-issue and source metadata exports that HyperDoc core now uses. Keep the package definition in HyperBook core, but resist adding any future dreyeck-only explorer helpers here; those should live in a downstream package or hook layer."
      :result-placement "hyperdoc core"
      :patch-sketch
      "(export '(link source-page-of source-hyperbook-of key-of
          link-text-of source-section-of
          target-hyperbook-of target-page-of
          object-link thunk-of view-of
          page-link hyperbook-link web-link url-of
          make-page-link make-hyperbook-link make-web-link
          links web-links-of page-links-of hyperbook-links-of
          no-links? extract-links
          lookup-issue page-lookup-issue target-grouping-issue
          make-page-lookup-issue make-target-grouping-issue
          lookup-issue-* mark-lookup-issue! enrich-lookup-issue lookup-issues-of
          replace-by-hyperbook-link render-hyperbook-or-page-link
          👀links 👀backlinks 👀lookup-issues ...))"))
    (t
     (error "No conflict resolution proposal spec for path ~S." path))))

(defun make-git-conflict-resolution-proposal (forecast conflict)
  (let* ((path (path-of conflict))
         (spec (conflict-resolution-proposal-spec path)))
    (make-instance
     'git-conflict-resolution-proposal
     :id (format nil "~A/proposal/~A" (id-of forecast) path)
     :title (getf spec :title)
     :summary (getf spec :summary)
     :relation (relation-of forecast)
     :forecast forecast
     :conflict conflict
     :path path
     :source-branch (source-branch-of conflict)
     :target-branch (target-branch-of conflict)
     :conflict-shape (getf spec :conflict-shape)
     :preferred-merged-form (getf spec :preferred-merged-form)
     :result-placement (getf spec :result-placement)
     :patch-sketch (getf spec :patch-sketch))))

(defun git-conflict-resolution-proposals (forecast)
  (loop for conflict in (git-manual-conflicts forecast)
        collect (make-git-conflict-resolution-proposal forecast conflict)))

(defun git-conflict-resolution-proposal-for-path (forecast path)
  (find path
        (git-conflict-resolution-proposals forecast)
        :key #'path-of
        :test #'string=))

(defun git-conflict-resolution-proposal-surface-from-forecast (forecast)
  (let ((manual-dossier (git-manual-conflict-dossier-from-forecast forecast)))
    (make-instance
     'git-conflict-resolution-proposal-surface
     :id (format nil "~A-resolution-proposals" (id-of forecast))
     :title "Manual conflict resolution proposals"
     :summary "Explicit proposed merged forms for the remaining manual overlap paths, with path-level conflict shape and pseudo-diff sketches."
     :relation (relation-of forecast)
     :forecast forecast
     :manual-dossier manual-dossier
     :proposals (git-conflict-resolution-proposals forecast))))

(defun git-realized-resolution-proposals (forecast)
  (remove nil
          (list (git-conflict-resolution-proposal-for-path forecast "hyperbook.asd")
                (git-conflict-resolution-proposal-for-path forecast "hyperbook/package.lisp")
                (git-conflict-resolution-proposal-for-path forecast "hyperbook-explorer/package.lisp"))))

(defun git-dreyeck-executable-scaffold-from-forecast (forecast)
  (let ((transition-plan (git-dreyeck-transition-plan-from-forecast forecast))
        (proposal-surface (git-conflict-resolution-proposal-surface-from-forecast forecast)))
    (make-instance
     'git-dreyeck-executable-scaffold
     :id (format nil "~A-dreyeck-scaffold" (id-of forecast))
     :title "Dreyeck executable scaffold"
     :summary "Minimal executable downstream boundary that proves the dreyeck transition plan can become a real loadable subsystem without moving the larger bucket sets yet."
     :relation (relation-of forecast)
     :forecast forecast
     :transition-plan transition-plan
     :proposal-surface proposal-surface
     :system-names '(":dreyeck" ":dreyeck/server")
     :component-paths '("dreyeck.asd"
                        "dreyeck/package.lisp"
                        "dreyeck/server.lisp")
     :package-names '(":dreyeck" ":dreyeck/server")
     :realized-proposals (git-realized-resolution-proposals forecast)
     :validation-commands
     '("asdf:load-system :hyperdoc :force t"
       "asdf:load-system :hyperdoc/server :force t"
       "asdf:load-system :dreyeck/server :force t"
       "nix run ."))))

(defun protocol-seam-specs ()
  (list
   (list
    :seam-type "server-startup-hook"
    :title "Protocol seam: server startup hook"
    :summary "HyperDoc core now exposes a small startup hook seam so downstream dreyeck wiring can install itself after core server startup setup, without reversing the ASDF dependency direction."
    :core-paths '("hyperbook-server/package.lisp"
                  "hyperbook-server/server.lisp")
    :downstream-paths '("dreyeck/server.lisp")
    :symbol-names '("hyperbook/server:register-server-startup-hook"
                    "hyperbook/server:serve-catalog"
                    "dreyeck/server:install-dreyeck-server-scaffold")
    :consumer-system ":dreyeck/server"
    :core-call-surface
    "HyperDoc core continues to call hyperbook/server:serve-catalog. The core server now runs its startup hook list after registering the standard startup HyperBooks, and dreyeck installs its downstream behavior through that seam."
    :behavior
    "The downstream scaffold registers INSTALL-DREYECK-SERVER-SCAFFOLD as a startup hook, so the local redirection and rewrite behavior is layered on top of the core server instead of forcing :hyperdoc/server to import dreyeck."
    :proposal-paths '("hyperbook.asd")
    :validation-proof
    '("asdf:load-system :hyperdoc/server :force t"
      "asdf:load-system :dreyeck/server :force t"
      "nix run . starts the core server without a reverse dependency on dreyeck"))
   (list
    :seam-type "link-redirection-and-target-rewrite"
    :title "Protocol seam: link redirection and target rewrite"
    :summary "HyperBook core and explorer rendering now expose explicit link-redirection and link-target rewrite seams so dreyeck-specific routing can stay downstream."
    :core-paths '("hyperbook/package.lisp"
                  "hyperbook-explorer/package.lisp"
                  "hyperbook-explorer/rendering.lisp")
    :downstream-paths '("dreyeck/server.lisp")
    :symbol-names '("hyperbook:register-link-redirection"
                    "hyperbook:register-link-target-rewriter"
                    "hyperbook:render-hyperbook-or-page-link"
                    "dreyeck/server:dreyeck-local-boot-link-redirection"
                    "dreyeck/server:dreyeck-link-target-rewriter")
    :consumer-system ":dreyeck/server"
    :core-call-surface
    "HyperDoc core continues to render links through hyperbook:render-hyperbook-or-page-link. The renderer now consults registered target rewriters before resolving the final HyperBook/page target."
    :behavior
    "The downstream scaffold keeps #\\:REGISTER-LINK-REDIRECTION in HyperBook core and adds REGISTER-LINK-TARGET-REWRITER in the shared explorer surface. Dreyeck consumes both hooks to redirect local boot URLs and alias local target ids without leaking dreyeck-only helpers into core packages."
    :proposal-paths '("hyperbook/package.lisp"
                      "hyperbook-explorer/package.lisp")
    :validation-proof
    '("asdf:load-system :hyperdoc :force t"
      "asdf:load-system :hyperdoc/server :force t"
      "asdf:load-system :dreyeck/server :force t"
      "The explorer still resolves shared links after the rewrite seam is loaded"))))

(defun make-git-protocol-seam (forecast scaffold spec)
  (make-instance
   'git-protocol-seam
   :id (format nil "~A/seam/~A"
               (id-of forecast)
               (getf spec :seam-type))
   :title (getf spec :title)
   :summary (getf spec :summary)
   :relation (relation-of forecast)
   :scaffold scaffold
   :seam-type (getf spec :seam-type)
   :core-paths (copy-list (getf spec :core-paths))
   :downstream-paths (copy-list (getf spec :downstream-paths))
   :symbol-names (copy-list (getf spec :symbol-names))
   :consumer-system (getf spec :consumer-system)
   :core-call-surface (getf spec :core-call-surface)
   :behavior (getf spec :behavior)
   :realized-proposals
   (loop for path in (getf spec :proposal-paths)
         for proposal = (git-conflict-resolution-proposal-for-path forecast path)
         when proposal
           collect proposal)
   :validation-proof (copy-list (getf spec :validation-proof))))

(defun git-protocol-seams-from-forecast (forecast &key scaffold)
  (let ((scaffold* (or scaffold
                       (git-dreyeck-executable-scaffold-from-forecast forecast))))
    (loop for spec in (protocol-seam-specs)
          collect (make-git-protocol-seam forecast scaffold* spec))))

(defun git-protocol-seam-for-type (forecast seam-type)
  (find seam-type
        (git-protocol-seams-from-forecast forecast)
        :key #'seam-type-of
        :test #'string=))

(defun git-protocol-seam-surface-from-forecast (forecast)
  (let ((scaffold (git-dreyeck-executable-scaffold-from-forecast forecast)))
    (make-instance
     'git-protocol-seam-surface
     :id (format nil "~A-protocol-seams" (id-of forecast))
     :title "First protocol seams for dreyeck extraction"
     :summary "Inspectable surface for the first concrete runtime and link-rendering seams that let dreyeck stay downstream while HyperDoc core remains close to upstream."
     :relation (relation-of forecast)
     :scaffold scaffold
     :seams (git-protocol-seams-from-forecast forecast :scaffold scaffold))))

(defun manual-proposal-rehearsal-assessment (conflict proposal raw-conflict-paths
                                             message-lines scaffold-assessment)
  (declare (ignore proposal))
  (let* ((path (path-of conflict))
         (raw-conflict-p (member path raw-conflict-paths :test #'string=))
         (conflict-kind (merge-tree-conflict-kind-for-path path message-lines))
         (direction-ready (dreyeck-server-dependency-direction-ready-p))
         (core-link-redirection-export-p
           (external-symbol-named-p "hyperbook:register-link-redirection"))
         (core-target-rewriter-export-p
           (external-symbol-named-p "hyperbook:register-link-target-rewriter"))
         (base-evidence (copy-list (getf scaffold-assessment :evidence))))
    (cond
      ((string= path "hyperbook.asd")
       (list
        :summary
        "The ASDF proposal now rehearses as a direction check more than a raw text conflict."
        :merge-tree-status (if raw-conflict-p
                               "merge-tree-conflict"
                               "no-raw-conflict")
        :conflict-kind conflict-kind
        :clean-in-principle-p (and (not raw-conflict-p)
                                   direction-ready)
        :proposal-readiness
        (if (and (not raw-conflict-p) direction-ready)
            "ready-in-principle-via-current-downstream-asdf-direction"
            "blocked-by-missing-downstream-asdf-direction")
        :scaffold-sufficiency
        (if direction-ready
            "current-dreyeck-scaffold-realizes-the-downstream-asdf-direction"
            (getf scaffold-assessment :status))
        :rationale
        "git merge-tree no longer reports hyperbook.asd as a raw conflict at the anchored tips. The remaining rehearsal question is whether the current code already proves the intended one-way dependency direction, and the live scaffold does: :dreyeck/server depends on :hyperdoc/server instead of reversing that edge."
        :evidence
        (append
         (list (if raw-conflict-p
                   "merge-tree still reports hyperbook.asd as a raw conflict."
                   "merge-tree does not report hyperbook.asd as a raw conflict.")
               (if direction-ready
                   "The current ASDF graph keeps :dreyeck/server downstream of :hyperdoc/server."
                   "The current ASDF graph does not yet prove :dreyeck/server downstream of :hyperdoc/server."))
         base-evidence)))
      ((string= path "hyperbook/package.lisp")
       (list
        :summary
        "The HyperBook package proposal now rehearses as a core-hook verification."
        :merge-tree-status (if raw-conflict-p
                               "merge-tree-conflict"
                               "no-raw-conflict")
        :conflict-kind conflict-kind
        :clean-in-principle-p (not raw-conflict-p)
        :proposal-readiness
        (if (and (not raw-conflict-p) core-link-redirection-export-p)
            "ready-in-principle-via-shared-core-hook-export"
            "auto-merges-but-core-hook-availability-still-needs-verification")
        :scaffold-sufficiency
        (if core-link-redirection-export-p
            "current-core-package-already-exposes-register-link-redirection"
            (getf scaffold-assessment :status))
        :rationale
        "git merge-tree no longer reports hyperbook/package.lisp as a raw conflict at the anchored tips. The proposal survives as a boundary check: REGISTER-LINK-REDIRECTION should remain a shared HyperBook core export, and the current scaffold already consumes that hook from downstream instead of moving it into dreyeck."
        :evidence
        (append
         (list (if raw-conflict-p
                   "merge-tree still reports hyperbook/package.lisp as a raw conflict."
                   "merge-tree does not report hyperbook/package.lisp as a raw conflict.")
               (if core-link-redirection-export-p
                   "The current core package exports HYPERBOOK:REGISTER-LINK-REDIRECTION."
                   "The current core package does not export HYPERBOOK:REGISTER-LINK-REDIRECTION."))
         base-evidence)))
      ((string= path "hyperbook-explorer/package.lisp")
       (list
        :summary
        "The explorer package proposal still needs a curated manual export-block merge."
        :merge-tree-status (if raw-conflict-p
                               "merge-tree-conflict"
                               "no-raw-conflict")
        :conflict-kind conflict-kind
        :clean-in-principle-p nil
        :proposal-readiness
        (if core-target-rewriter-export-p
            "manual-patch-still-needed-but-current-scaffold-supports-it"
            "manual-patch-still-needed-and-current-scaffold-is-incomplete")
        :scaffold-sufficiency
        (if core-target-rewriter-export-p
            "current-scaffold-provides-the-first-shared-explorer-rewrite-seam"
            (getf scaffold-assessment :status))
        :rationale
        "git merge-tree still reports hyperbook-explorer/package.lisp as a raw content conflict, so this proposal cannot yet be called clean in principle. The scaffold is still useful here because it already proves the intended shared seam: HyperBook core exports REGISTER-LINK-TARGET-REWRITER, which means the remaining work is a curated export-block merge rather than a missing architectural boundary."
        :evidence
        (append
         (list (if raw-conflict-p
                   "merge-tree still reports hyperbook-explorer/package.lisp as a raw conflict."
                   "merge-tree does not report hyperbook-explorer/package.lisp as a raw conflict.")
               (if core-target-rewriter-export-p
                   "The current core explorer surface exports HYPERBOOK:REGISTER-LINK-TARGET-REWRITER."
                   "The current core explorer surface does not export HYPERBOOK:REGISTER-LINK-TARGET-REWRITER."))
         base-evidence)))
      (t
       (error "No rehearsal assessment for manual path ~S." path)))))

(defun make-git-rehearsal-result (forecast rehearsal conflict proposal report
                                  scaffold-assessment)
  (let* ((assessment
           (manual-proposal-rehearsal-assessment
            conflict
            proposal
            (getf report :raw-conflict-paths)
            (getf report :message-lines)
            scaffold-assessment))
         (path (path-of conflict)))
    (make-instance
     'git-rehearsal-result
     :id (format nil "~A/rehearsal/~A" (id-of forecast) path)
     :title (format nil "Rehearsal result: ~A" path)
     :summary (getf assessment :summary)
     :rehearsal rehearsal
     :conflict conflict
     :proposal proposal
     :path path
     :merge-tree-status (getf assessment :merge-tree-status)
     :conflict-kind (getf assessment :conflict-kind)
     :clean-in-principle-p (getf assessment :clean-in-principle-p)
     :proposal-readiness (getf assessment :proposal-readiness)
     :scaffold-sufficiency (getf assessment :scaffold-sufficiency)
     :rationale (getf assessment :rationale)
     :evidence (copy-list (getf assessment :evidence)))))

(defun git-manual-conflict-rehearsal-results (forecast rehearsal report
                                              scaffold-assessment)
  (loop for conflict in (git-manual-conflicts forecast)
        for proposal = (git-conflict-resolution-proposal-for-path
                        forecast
                        (path-of conflict))
        collect (make-git-rehearsal-result forecast
                                           rehearsal
                                           conflict
                                           proposal
                                           report
                                           scaffold-assessment)))

(defun rehearsal-result-on-raw-conflict-frontier-p (result)
  (string= (merge-tree-status-of result) "merge-tree-conflict"))

(defun git-typed-manual-raw-conflict-results (rehearsal)
  (loop for result in (rehearsal-results-of rehearsal)
        when (rehearsal-result-on-raw-conflict-frontier-p result)
          collect result))

(defun extra-raw-conflict-spec (path)
  (cond
    ((string= path "hyperbook-explorer/rendering.lisp")
     (list
      :title "Extra raw conflict: hyperbook-explorer/rendering.lisp"
      :summary "The explorer renderer still has a raw content conflict beyond the current manual package dossier."
      :looks-like "dreyeck-candidate spillover"
      :promote-to-manual-dossier-p t
      :preliminary-preferred-handling
      "Keep the shared renderer in HyperBook core, converge both sides on the shared render-hyperbook-or-page-link path, and move only the branch-specific target rewriting behavior behind REGISTER-LINK-TARGET-REWRITER in dreyeck."))
    ((string= path "hyperbook-fedwiki/fedwiki.lisp")
     (list
      :title "Extra raw conflict: hyperbook-fedwiki/fedwiki.lisp"
      :summary "The fedwiki hyperbook root still has a raw content conflict that the earlier overlapping-path pass under-classified."
      :looks-like "upstream/core boundary issue"
      :promote-to-manual-dossier-p t
      :preliminary-preferred-handling
      "Keep the fedwiki hyperbook object and network/protocol initialization in HyperBook core, manually union the HTTPS probing and network-failure handling, and do not treat this as dreyeck extraction work."))
    ((string= path "hyperbook-fedwiki/pages.lisp")
     (list
      :title "Extra raw conflict: hyperbook-fedwiki/pages.lisp"
      :summary "The fedwiki page loader/view layer still has a raw content conflict outside the current manual dossier."
      :looks-like "missing earlier classification"
      :promote-to-manual-dossier-p t
      :preliminary-preferred-handling
      "Promote this path into the curated conflict set, keep remote-page loading and page-action behavior in HyperBook core, and merge the protocol-aware fetching plus context-ordering updates without moving the file into dreyeck."))
    ((string= path "hyperbook-wikipedia/list-wikipedia-editions.lisp")
     (list
      :title "Extra raw conflict: hyperbook-wikipedia/list-wikipedia-editions.lisp"
      :summary "The new wikipedia edition-list helper lands as an add/add conflict and needs an explicit typed resolution."
      :looks-like "missing earlier classification"
      :promote-to-manual-dossier-p t
      :preliminary-preferred-handling
      "Keep one shared upstream-core helper file, manually reconcile the generated edition-list workflow and any local annotations, and avoid treating the helper as dreyeck-specific."))
    ((string= path "hyperbook-wikipedia/wikipedia.lisp")
     (list
      :title "Extra raw conflict: hyperbook-wikipedia/wikipedia.lisp"
      :summary "The shared wikipedia HyperBook implementation still has a raw content conflict beyond the current manual dossier."
      :looks-like "upstream/core boundary issue"
      :promote-to-manual-dossier-p t
      :preliminary-preferred-handling
      "Keep the wikipedia integration in HyperBook core, manually union the main-page fallback, UTF-8 request settings, and link-redirection changes, and leave dreyeck out of this file unless a later downstream seam proves necessary."))
    (t
     (error "No extra raw conflict spec for path ~S." path))))

(defun make-git-extra-raw-conflict (rehearsal path)
  (let* ((spec (extra-raw-conflict-spec path))
         (conflict-kind
           (merge-tree-conflict-kind-for-path path (message-lines-of rehearsal))))
    (make-instance
     'git-extra-raw-conflict
     :id (format nil "~A/extra-raw-conflict/~A"
                 (id-of rehearsal)
                 path)
     :title (getf spec :title)
     :summary (getf spec :summary)
     :rehearsal rehearsal
     :path path
     :conflict-kind conflict-kind
     :looks-like (getf spec :looks-like)
     :promote-to-manual-dossier-p (getf spec :promote-to-manual-dossier-p)
     :preliminary-preferred-handling
     (getf spec :preliminary-preferred-handling))))

(defun git-extra-raw-conflicts (rehearsal)
  (loop for path in (additional-conflict-paths-of rehearsal)
        collect (make-git-extra-raw-conflict rehearsal path)))

(defun git-extra-raw-conflict-for-path (forecast path)
  (find path
        (extra-conflicts-of
         (git-raw-conflict-surface-from-forecast forecast))
        :key #'path-of
        :test #'string=))

(defun git-rehearsal-untyped-raw-conflict-paths (rehearsal)
  (let ((typed-paths (append (mapcar #'path-of
                                     (git-typed-manual-raw-conflict-results rehearsal))
                             (mapcar #'path-of
                                     (git-extra-raw-conflicts rehearsal)))))
    (string-list-difference (raw-conflict-paths-of rehearsal)
                            typed-paths)))

(defun git-typed-raw-conflict-frontier-count (rehearsal)
  (+ (length (git-typed-manual-raw-conflict-results rehearsal))
     (length (git-extra-raw-conflicts rehearsal))))

(defun git-raw-conflict-surface-from-forecast (forecast)
  (let* ((rehearsal (git-merge-rehearsal-from-forecast forecast))
         (typed-manual-results
           (git-typed-manual-raw-conflict-results rehearsal))
         (extra-conflicts (git-extra-raw-conflicts rehearsal)))
    (make-instance
     'git-raw-conflict-surface
     :id (format nil "~A-extra-raw-conflicts" (id-of forecast))
     :title "Extra raw merge conflicts"
     :summary "Typed surface for the raw merge-tree conflicts outside the current manual dossier, plus explicit frontier accounting against the anchored dry-run rehearsal."
     :rehearsal rehearsal
     :typed-manual-results typed-manual-results
     :extra-conflicts extra-conflicts
     :remainder-paths (git-rehearsal-untyped-raw-conflict-paths rehearsal))))

(defun git-rehearsal-result-for-path (forecast path)
  (find path
        (rehearsal-results-of (git-merge-rehearsal-from-forecast forecast))
        :key #'path-of
        :test #'string=))

(defun git-merge-rehearsal-from-forecast (forecast)
  (let* ((relation (relation-of forecast))
         (repo-root (repo-root-of (source-branch-of relation)))
         (source-hash (commit-hash-of (source-commit-of relation)))
         (target-hash (commit-hash-of (target-commit-of relation)))
         (report (git-merge-tree-rehearsal-report repo-root source-hash target-hash))
         (scaffold (git-dreyeck-executable-scaffold-from-forecast forecast))
         (proposal-surface
           (git-conflict-resolution-proposal-surface-from-forecast forecast))
         (scaffold-assessment (dreyeck-scaffold-rehearsal-assessment))
         (manual-paths (mapcar #'path-of (git-manual-conflicts forecast)))
         (rehearsal
           (make-instance
            'git-merge-rehearsal
            :id (format nil "~A-merge-rehearsal" (id-of forecast))
            :title "Dry-run merge rehearsal"
            :summary "Non-destructive merge rehearsal object that records the current virtual merge-tree result, the manual proposal viability for the named paths, and whether the current dreyeck scaffold is sufficient for the planned downstream direction."
            :relation relation
            :forecast forecast
            :scaffold scaffold
            :proposal-surface proposal-surface
            :merge-base-commit (merge-base-commit-of forecast)
            :mechanism
            "git merge-tree --write-tree --name-only against the explicit source and target anchors"
            :virtual-merge-tree-hash
            (getf report :virtual-merge-tree-hash)
            :raw-conflict-paths (copy-list (getf report :raw-conflict-paths))
            :additional-conflict-paths
            (string-list-difference (getf report :raw-conflict-paths)
                                    manual-paths)
            :message-lines (copy-list (getf report :message-lines))
            :scaffold-sufficient-p (getf scaffold-assessment :ok)
            :scaffold-direction-status (getf scaffold-assessment :status)
            :scaffold-evidence (copy-list (getf scaffold-assessment :evidence))
            :rehearsal-results nil)))
    (setf (rehearsal-results-of rehearsal)
          (git-manual-conflict-rehearsal-results forecast
                                                 rehearsal
                                                 report
                                                 scaffold-assessment))
    rehearsal))

(defun git-merge-forecast-blocker-summary (overlapping-paths notes)
  (if overlapping-paths
      (format nil "~D overlapping path~:P need review before any merge execution; ~D dreyeck extraction candidate note~:P attached."
              (length overlapping-paths)
              (length notes))
      (format nil "No overlapping paths at the anchored commits; ~D dreyeck extraction candidate note~:P still document branch-specific extraction seams."
              (length notes))))

(defun make-hyperdoc-upstream-main-dreyeck-notes (relation)
  (list
   (make-instance
    'git-merge-preparation-note
    :id "dreyeck-runtime-catalog-seam"
    :title "Extract runtime and catalog wiring behind a dreyeck seam"
    :summary "Local startup and HyperBook registration code looks like a cleaner dreyeck extension seam than a long-lived patch stack against upstream core."
    :relation relation
    :note-type "dreyeck-extraction-candidate"
    :status "candidate"
    :paths '("hyperbook-server/server.lisp"
             "hyperbook/catalog.lisp"
             "hyperbook/hyperbooks.lisp")
    :recommendation
    "If merge prep shows pressure on startup and catalog code, move branch-specific registrations and local runtime behavior into a dreyeck subsystem that loads after hyperdoc/server.")
   (make-instance
    'git-merge-preparation-note
    :id "dreyeck-link-and-page-resolution-seam"
    :title "Isolate link and page-resolution overrides from shared explorer files"
    :summary "Shared explorer and HyperDoc rendering files are likely conflict points; branch-specific lookup or page policy should move behind dreyeck hooks instead of staying as deep edits in upstream-touched code."
    :relation relation
    :note-type "dreyeck-extraction-candidate"
    :status "candidate"
    :paths '("hyperbook-explorer/link-redirection.lisp"
             "hyperbook-explorer/link-views.lisp"
             "hyperbook-explorer/links.lisp"
             "hyperbook-explorer/rendering.lisp"
             "hyperdoc-explorer/html-pages.lisp"
             "hyperdoc/tools.lisp")
    :recommendation
    "Prefer small dreyeck-owned extension hooks for lookup, link rewriting, and page-resolution policy over carrying direct edits in shared explorer and HyperDoc core files.")))

(defun git-merge-forecast-from-relation (relation)
  (let* ((repo-root (repo-root-of (source-branch-of relation)))
         (system (system-of (source-branch-of relation)))
         (source-hash (commit-hash-of (source-commit-of relation)))
         (target-hash (commit-hash-of (target-commit-of relation)))
         (merge-base-hash (git-merge-base-hash repo-root source-hash target-hash))
         (upstream-paths (git-changed-paths-between repo-root merge-base-hash source-hash))
         (hauptsache-paths (git-changed-paths-between repo-root merge-base-hash target-hash))
         (overlap (string-list-intersection upstream-paths hauptsache-paths))
         (upstream-only (string-list-difference upstream-paths hauptsache-paths))
         (hauptsache-only (string-list-difference hauptsache-paths upstream-paths))
         (notes (notes-of relation)))
    (make-instance
     'git-merge-forecast
     :id (format nil "~A-forecast" (id-of relation))
     :title (format nil "Merge forecast for ~A -> ~A"
                    (branch-name-of (source-branch-of relation))
                    (branch-name-of (target-branch-of relation)))
     :summary "Computed merge-preparation object anchored to the explicit merge-intent commits; classifies changed paths into upstream-only, hauptsache-only, and overlapping sets without executing the merge."
     :relation relation
     :merge-base-commit (%system-git-commit-target system merge-base-hash)
     :upstream-only-paths upstream-only
     :hauptsache-only-paths hauptsache-only
     :overlapping-paths overlap
     :blocker-summary (git-merge-forecast-blocker-summary overlap notes)
     :notes notes)))

(defun git-history-merge-forecasts (surface)
  (loop for relation in (relations-of surface)
        collect (git-merge-forecast-from-relation relation)))

(defun %hyperdoc-upstream-main-branch-ref ()
  (%system-git-branch-ref :hyperdoc
                          "upstream/main"
                          :full-commit-hash +hyperdoc-upstream-main-commit-hash+
                          :role :upstream
                          :aliases '("khinsen/main")))

(def-git-runtime-entrypoint hyperdoc-upstream-main-branch-ref ()
  (%hyperdoc-upstream-main-branch-ref))

(defun %hyperdoc-hauptsache-branch-ref ()
  (%system-git-branch-ref :hyperdoc
                          "hauptsache"
                          :full-commit-hash +hyperdoc-hauptsache-commit-hash+
                          :role :local))

(def-git-runtime-entrypoint hyperdoc-hauptsache-branch-ref ()
  (%hyperdoc-hauptsache-branch-ref))

(defun %hyperdoc-upstream-main-into-hauptsache-merge-intent ()
  (let* ((source-branch (%hyperdoc-upstream-main-branch-ref))
         (target-branch (%hyperdoc-hauptsache-branch-ref))
         (source-commit (git-branch-target source-branch))
         (target-commit (git-branch-target target-branch))
         (relation
           (make-instance 'git-merge-intent
                          :id "merge-upstream-main-into-hauptsache-via-dreyeck-fallback"
                          :title "Merge upstream/main into hauptsache via dreyeck fallback"
                          :summary "Typed merge-intent relation between explicit upstream/main and hauptsache commit anchors for the HyperDoc repo."
                          :relation-type "merge-intent"
                          :status "planned"
                          :source-commit source-commit
                          :target-commit target-commit
                          :source-branch source-branch
                          :target-branch target-branch
                          :prompt +hyperdoc-upstream-main-merge-intent-prompt+
                          :conflict-policy +hyperdoc-upstream-main-conflict-policy+
                          :success-criteria +hyperdoc-upstream-main-success-criteria+)))
    (setf (notes-of relation)
          (make-hyperdoc-upstream-main-dreyeck-notes relation))
    relation))

(def-git-runtime-entrypoint hyperdoc-upstream-main-into-hauptsache-merge-intent ()
  (%hyperdoc-upstream-main-into-hauptsache-merge-intent))

(def-git-runtime-entrypoint hyperdoc-dreyeck-runtime-seam-note ()
  (first (notes-of (%hyperdoc-upstream-main-into-hauptsache-merge-intent))))

(def-git-runtime-entrypoint hyperdoc-dreyeck-link-resolution-note ()
  (second (notes-of (%hyperdoc-upstream-main-into-hauptsache-merge-intent))))

(defun %hyperdoc-upstream-main-into-hauptsache-merge-forecast ()
  (git-merge-forecast-from-relation
   (%hyperdoc-upstream-main-into-hauptsache-merge-intent)))

(def-git-runtime-entrypoint hyperdoc-upstream-main-into-hauptsache-merge-forecast ()
  (%hyperdoc-upstream-main-into-hauptsache-merge-forecast))

(def-git-runtime-entrypoint hyperdoc-upstream-main-into-hauptsache-overlapping-path-decision-surface ()
  (git-overlapping-path-decision-surface
   (%hyperdoc-upstream-main-into-hauptsache-merge-forecast)))

(def-git-runtime-entrypoint hyperdoc-upstream-main-into-hauptsache-hauptsache-path-decision-surface ()
  (git-hauptsache-path-decision-surface
   (%hyperdoc-upstream-main-into-hauptsache-merge-forecast)))

(def-git-runtime-entrypoint hyperdoc-upstream-main-into-hauptsache-dreyeck-candidate-path-surface ()
  (git-dreyeck-candidate-path-surface
   (%hyperdoc-upstream-main-into-hauptsache-merge-forecast)))

(def-git-runtime-entrypoint hyperdoc-upstream-main-into-hauptsache-unresolved-manual-path-surface ()
  (git-unresolved-manual-path-surface
   (%hyperdoc-upstream-main-into-hauptsache-merge-forecast)))

(def-git-runtime-entrypoint hyperdoc-upstream-main-into-hauptsache-dreyeck-extraction-plan ()
  (git-dreyeck-extraction-plan-from-forecast
   (%hyperdoc-upstream-main-into-hauptsache-merge-forecast)))

(def-git-runtime-entrypoint hyperdoc-upstream-main-into-hauptsache-dreyeck-transition-plan ()
  (git-dreyeck-transition-plan-from-forecast
   (%hyperdoc-upstream-main-into-hauptsache-merge-forecast)))

(def-git-runtime-entrypoint hyperdoc-upstream-main-into-hauptsache-manual-conflict-dossier ()
  (git-manual-conflict-dossier-from-forecast
   (%hyperdoc-upstream-main-into-hauptsache-merge-forecast)))

(def-git-runtime-entrypoint hyperdoc-upstream-main-into-hauptsache-conflict-resolution-proposal-surface ()
  (git-conflict-resolution-proposal-surface-from-forecast
   (%hyperdoc-upstream-main-into-hauptsache-merge-forecast)))

(def-git-runtime-entrypoint hyperdoc-upstream-main-into-hauptsache-dreyeck-executable-scaffold ()
  (git-dreyeck-executable-scaffold-from-forecast
   (%hyperdoc-upstream-main-into-hauptsache-merge-forecast)))

(def-git-runtime-entrypoint hyperdoc-upstream-main-into-hauptsache-protocol-seam-surface ()
  (git-protocol-seam-surface-from-forecast
   (%hyperdoc-upstream-main-into-hauptsache-merge-forecast)))

(def-git-runtime-entrypoint hyperdoc-upstream-main-into-hauptsache-merge-rehearsal ()
  (git-merge-rehearsal-from-forecast
   (%hyperdoc-upstream-main-into-hauptsache-merge-forecast)))

(def-git-runtime-entrypoint hyperdoc-upstream-main-into-hauptsache-extra-raw-conflict-surface ()
  (git-raw-conflict-surface-from-forecast
   (%hyperdoc-upstream-main-into-hauptsache-merge-forecast)))

(def-git-runtime-entrypoint hyperdoc-upstream-main-into-hauptsache-server-startup-hook-seam ()
  (git-protocol-seam-for-type
   (%hyperdoc-upstream-main-into-hauptsache-merge-forecast)
   "server-startup-hook"))

(def-git-runtime-entrypoint hyperdoc-upstream-main-into-hauptsache-link-redirection-seam ()
  (git-protocol-seam-for-type
   (%hyperdoc-upstream-main-into-hauptsache-merge-forecast)
   "link-redirection-and-target-rewrite"))

(def-git-runtime-entrypoint hyperdoc-upstream-main-into-hauptsache-hyperbook-asd-manual-conflict ()
  (git-manual-conflict-for-path
   (%hyperdoc-upstream-main-into-hauptsache-merge-forecast)
   "hyperbook.asd"))

(def-git-runtime-entrypoint hyperdoc-upstream-main-into-hauptsache-hyperbook-package-manual-conflict ()
  (git-manual-conflict-for-path
   (%hyperdoc-upstream-main-into-hauptsache-merge-forecast)
   "hyperbook/package.lisp"))

(def-git-runtime-entrypoint hyperdoc-upstream-main-into-hauptsache-hyperbook-explorer-package-manual-conflict ()
  (git-manual-conflict-for-path
   (%hyperdoc-upstream-main-into-hauptsache-merge-forecast)
   "hyperbook-explorer/package.lisp"))

(def-git-runtime-entrypoint hyperdoc-upstream-main-into-hauptsache-hyperbook-asd-resolution-proposal ()
  (git-conflict-resolution-proposal-for-path
   (%hyperdoc-upstream-main-into-hauptsache-merge-forecast)
   "hyperbook.asd"))

(def-git-runtime-entrypoint hyperdoc-upstream-main-into-hauptsache-hyperbook-package-resolution-proposal ()
  (git-conflict-resolution-proposal-for-path
   (%hyperdoc-upstream-main-into-hauptsache-merge-forecast)
   "hyperbook/package.lisp"))

(def-git-runtime-entrypoint hyperdoc-upstream-main-into-hauptsache-hyperbook-explorer-package-resolution-proposal ()
  (git-conflict-resolution-proposal-for-path
   (%hyperdoc-upstream-main-into-hauptsache-merge-forecast)
   "hyperbook-explorer/package.lisp"))

(def-git-runtime-entrypoint hyperdoc-upstream-main-into-hauptsache-hyperbook-asd-rehearsal-result ()
  (git-rehearsal-result-for-path
   (%hyperdoc-upstream-main-into-hauptsache-merge-forecast)
   "hyperbook.asd"))

(def-git-runtime-entrypoint hyperdoc-upstream-main-into-hauptsache-hyperbook-package-rehearsal-result ()
  (git-rehearsal-result-for-path
   (%hyperdoc-upstream-main-into-hauptsache-merge-forecast)
   "hyperbook/package.lisp"))

(def-git-runtime-entrypoint hyperdoc-upstream-main-into-hauptsache-hyperbook-explorer-package-rehearsal-result ()
  (git-rehearsal-result-for-path
   (%hyperdoc-upstream-main-into-hauptsache-merge-forecast)
   "hyperbook-explorer/package.lisp"))

(def-git-runtime-entrypoint hyperdoc-upstream-main-into-hauptsache-hyperbook-explorer-rendering-extra-raw-conflict ()
  (git-extra-raw-conflict-for-path
   (%hyperdoc-upstream-main-into-hauptsache-merge-forecast)
   "hyperbook-explorer/rendering.lisp"))

(def-git-runtime-entrypoint hyperdoc-upstream-main-into-hauptsache-hyperbook-fedwiki-fedwiki-extra-raw-conflict ()
  (git-extra-raw-conflict-for-path
   (%hyperdoc-upstream-main-into-hauptsache-merge-forecast)
   "hyperbook-fedwiki/fedwiki.lisp"))

(def-git-runtime-entrypoint hyperdoc-upstream-main-into-hauptsache-hyperbook-fedwiki-pages-extra-raw-conflict ()
  (git-extra-raw-conflict-for-path
   (%hyperdoc-upstream-main-into-hauptsache-merge-forecast)
   "hyperbook-fedwiki/pages.lisp"))

(def-git-runtime-entrypoint hyperdoc-upstream-main-into-hauptsache-hyperbook-wikipedia-list-editions-extra-raw-conflict ()
  (git-extra-raw-conflict-for-path
   (%hyperdoc-upstream-main-into-hauptsache-merge-forecast)
   "hyperbook-wikipedia/list-wikipedia-editions.lisp"))

(def-git-runtime-entrypoint hyperdoc-upstream-main-into-hauptsache-hyperbook-wikipedia-wikipedia-extra-raw-conflict ()
  (git-extra-raw-conflict-for-path
   (%hyperdoc-upstream-main-into-hauptsache-merge-forecast)
   "hyperbook-wikipedia/wikipedia.lisp"))

(defun %hyperdoc-git-history-surface ()
  (let* ((local-branch (%hyperdoc-hauptsache-branch-ref))
         (upstream-branch (%hyperdoc-upstream-main-branch-ref))
         (system (system-of local-branch)))
    (make-instance 'git-history-surface
                   :id "hyperdoc-git-history-surface"
                   :title "HyperDoc Git history surface"
                   :summary "Lane-based history and merge-worklist surface for the HyperDoc repository, centered on explicit merge-intent relations."
                   :system system
                   :repo-root (repo-root-of local-branch)
                   :local-branch local-branch
                   :upstream-branch upstream-branch
                   :relations (list (%hyperdoc-upstream-main-into-hauptsache-merge-intent))
                   :commit-window 8)))

(def-git-runtime-entrypoint hyperdoc-git-history-surface ()
  (%hyperdoc-git-history-surface))

(defun hyperdoc-git-history-route-discovery ()
  (make-instance 'canonical-route-discovery
                 :id "canonical-route-discovery-for-git-history-surface"
                 :title "Canonical route discovery for Git history surface"
                 :summary "Shows the canonical page URL for the Git history page and the direct-addressability status of the anchored merge-intent object."
                 :page (find-page (symbol-value '*hyperdoc*)
                                  "Git History Surface for HyperDoc"
                                  :signal-error? t)
                 :inspectable-object
                 (hyperdoc-upstream-main-into-hauptsache-merge-intent)
                 :inspectable-object-label
                 "Anchored merge-intent relation"
                 :notes
                 (list
                  "Use the canonical page URL for HTTP smoke tests instead of guessing the router slug."
                  "Pages and hyperbooks are directly addressable inspector roots today; nested relation objects are inspectable in-process but do not yet have dedicated canonical URLs.")))
