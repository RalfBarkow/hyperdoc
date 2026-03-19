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
   (success-criteria :reader success-criteria-of :initarg :success-criteria :initform nil)))

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

(defmethod print-object ((object git-branch-ref) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A@~A"
            (branch-name-of object)
            (short-git-commit-hash (commit-hash-of object)))))

(defmethod print-object ((object git-merge-intent) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object git-history-surface) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defun system-git-branch-ref (system-designator branch-name
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

(defun git-branch-target (branch-ref)
  (system-git-commit-target (system-of branch-ref)
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
    (system-git-commit-target (system-of branch-ref)
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
            collect (system-git-commit-target (system-of branch-ref) line))))

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

(defun hyperdoc-upstream-main-branch-ref ()
  (system-git-branch-ref :hyperdoc
                         "upstream/main"
                         :full-commit-hash +hyperdoc-upstream-main-commit-hash+
                         :role :upstream
                         :aliases '("khinsen/main")))

(defun hyperdoc-hauptsache-branch-ref ()
  (system-git-branch-ref :hyperdoc
                         "hauptsache"
                         :full-commit-hash +hyperdoc-hauptsache-commit-hash+
                         :role :local))

(defun hyperdoc-upstream-main-into-hauptsache-merge-intent ()
  (let* ((source-branch (hyperdoc-upstream-main-branch-ref))
         (target-branch (hyperdoc-hauptsache-branch-ref))
         (source-commit (git-branch-target source-branch))
         (target-commit (git-branch-target target-branch)))
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

(defun hyperdoc-git-history-surface ()
  (let* ((local-branch (hyperdoc-hauptsache-branch-ref))
         (upstream-branch (hyperdoc-upstream-main-branch-ref))
         (system (system-of local-branch)))
    (make-instance 'git-history-surface
                   :id "hyperdoc-git-history-surface"
                   :title "HyperDoc Git history surface"
                   :summary "Lane-based history and merge-worklist surface for the HyperDoc repository, centered on explicit merge-intent relations."
                   :system system
                   :repo-root (repo-root-of local-branch)
                   :local-branch local-branch
                   :upstream-branch upstream-branch
                   :relations (list (hyperdoc-upstream-main-into-hauptsache-merge-intent))
                   :commit-window 8)))
