;;;; Inspectable, read-only upstream intake observations.

(in-package #:dreyeck/upstream-intake)

(defparameter +hyperspec-local-subject+
  "47e29b3fb89486cc29def9e4c504020d2a714a61")

(defparameter +hyperdoc-host-not-found-upstream-commit+
  "4a0a9d859148e23b6f1ec8ec106145aa68c79c7c")

(defparameter +hyperspec-contract-names+
  '(:existing-symbol-lookup-preserved
    :local-hyperspec-corpus
    :reproducible-nix-source
    :same-origin-http-serving
    :no-external-runtime-fallback
    :defmethod-resolution
    :runtime-closure-availability))

(defparameter +contract-observation-statuses+
  '(:unknown :confirmed :not-confirmed :not-applicable))

(defclass upstream-local-context ()
  ((repository
    :reader upstream-local-context-repository-of
    :initarg :repository)
   (branch
    :reader upstream-local-context-branch-of
    :initarg :branch
    :type (or null string))
   (current-head
    :reader upstream-local-context-current-head-of
    :initarg :current-head
    :type dreyeck/git:git-commit))
  (:documentation
   "Observed checkout, branch, and HEAD for one upstream intake."))

(defclass upstream-reference ()
  ((kind
    :reader upstream-reference-kind-of
    :initarg :kind
    :type (member :git-commit :component))
   (origin
    :reader upstream-reference-origin-of
    :initarg :origin
    :type string)
   (reference
    :reader upstream-reference-reference-of
    :initarg :reference
    :type string)
   (local-context
    :reader upstream-reference-local-context-of
    :initarg :local-context
    :type upstream-local-context))
  (:documentation
   "An observed upstream hint, without an integration decision."))

(defclass git-commit-upstream-reference (upstream-reference)
  ((commit
    :reader git-commit-upstream-commit-of
    :initarg :commit
    :type (or null dreyeck/git:git-commit))
   (object-present-p
    :reader git-commit-upstream-object-present-p
    :initarg :object-present-p
    :type boolean)
   (ancestor-of-head-p
    :reader git-commit-upstream-ancestor-of-head-p
    :initarg :ancestor-of-head-p
    :type boolean)
   (merge-base
    :reader git-commit-upstream-merge-base-of
    :initarg :merge-base
    :type (or null dreyeck/git:git-commit))
   (refs-containing
    :reader git-commit-upstream-refs-containing-of
    :initarg :refs-containing
    :type list)
   (classification
    :reader git-commit-upstream-classification-of
    :initarg :classification
    :type (member :already-integrated
                  :available-not-integrated
                  :not-available-locally)))
  (:documentation
   "Facts derived from local Git object and ancestry readers only."))

(defstruct (contract-observation
            (:constructor %make-contract-observation (name status))
            (:conc-name contract-observation-))
  "One explicit contract question and its current evidence status."
  (name nil :type symbol)
  (status :unknown
          :type (member :unknown
                        :confirmed
                        :not-confirmed
                        :not-applicable)))

(defun contract-observation-name-of (observation)
  (contract-observation-name observation))

(defun contract-observation-status-of (observation)
  (contract-observation-status observation))

(defun make-contract-observation (name &optional (status :unknown))
  (check-type name symbol)
  (unless (member status +contract-observation-statuses+)
    (error 'type-error
           :datum status
           :expected-type
           '(member :unknown :confirmed :not-confirmed :not-applicable)))
  (%make-contract-observation name status))

(defclass component-upstream-reference (upstream-reference)
  ((component-name
    :reader component-upstream-component-name-of
    :initarg :component-name
    :type string)
   (upstream-url
    :reader component-upstream-url-of
    :initarg :upstream-url
    :initform nil
    :type (or null string))
   (local-subject
    :reader component-upstream-local-subject-of
    :initarg :local-subject)
   (proposed-relation
    :reader component-upstream-proposed-relation-of
    :initarg :proposed-relation
    :type symbol)
   (status
    :reader component-upstream-status-of
    :initarg :status
    :type symbol)
   (contracts
    :reader component-upstream-contracts-of
    :initarg :contracts
    :type list))
  (:documentation
   "A capability relation hypothesis whose contracts remain explicit data."))

(defmethod print-object ((reference upstream-reference) stream)
  (print-unreadable-object (reference stream :type t :identity nil)
    (format stream "~A ~A"
            (upstream-reference-origin-of reference)
            (upstream-reference-reference-of reference))))

(defun make-upstream-local-context (repository)
  (make-instance
   'upstream-local-context
   :repository repository
   :branch (dreyeck/git:git-current-branch repository)
   :current-head
   (dreyeck/git:make-git-commit
    :repository repository
    :commit-ish "HEAD")))

(defun make-upstream-commit-intake
    (commit-ish
     &key
       origin
       (repository (dreyeck/git:current-git-repository-checkout)))
  "Observe COMMIT-ISH against REPOSITORY without modifying or fetching it."
  (check-type commit-ish string)
  (check-type origin string)
  (let* ((local-context (make-upstream-local-context repository))
         (current-head
           (upstream-local-context-current-head-of local-context))
         (object-present-p
           (dreyeck/git:git-commit-object-present-p repository commit-ish))
         (upstream-commit
           (and object-present-p
                (dreyeck/git:make-git-commit
                 :repository repository
                 :commit-ish commit-ish)))
         (ancestor-of-head-p
           (and upstream-commit
                (dreyeck/git:git-commit-ancestor-p
                 upstream-commit current-head)))
         (merge-base
           (and upstream-commit
                (dreyeck/git:git-commit-merge-base
                 upstream-commit current-head)))
         (refs-containing
           (if upstream-commit
               (dreyeck/git:git-commit-refs-containing upstream-commit)
               nil))
         (classification
           (cond
             ((not object-present-p) :not-available-locally)
             (ancestor-of-head-p :already-integrated)
             (t :available-not-integrated))))
    (make-instance
     'git-commit-upstream-reference
     :kind :git-commit
     :origin origin
     :reference commit-ish
     :local-context local-context
     :commit upstream-commit
     :object-present-p object-present-p
     :ancestor-of-head-p (not (null ancestor-of-head-p))
     :merge-base merge-base
     :refs-containing refs-containing
     :classification classification)))

(defun normalize-contract-observation (contract)
  (etypecase contract
    (contract-observation contract)
    (symbol (make-contract-observation contract))))

(defun make-component-intake
    (&key
       origin
       component-name
       reference
       upstream-url
       local-subject
       (proposed-relation :supersedes)
       (status :unverified)
       contracts
       (repository (dreyeck/git:current-git-repository-checkout)))
  "Record a component relation hypothesis without evaluating or applying it."
  (check-type origin string)
  (check-type component-name string)
  (check-type reference string)
  (make-instance
   'component-upstream-reference
   :kind :component
   :origin origin
   :reference reference
   :local-context (make-upstream-local-context repository)
   :component-name component-name
   :upstream-url upstream-url
   :local-subject local-subject
   :proposed-relation proposed-relation
   :status status
   :contracts (mapcar #'normalize-contract-observation contracts)))

(defun make-hyperdoc-host-not-found-intake ()
  "Observe Konrad Hinsen's host-not-found HyperDoc commit locally."
  (make-upstream-commit-intake
   +hyperdoc-host-not-found-upstream-commit+
   :origin "khinsen/hyperdoc"))

(defun make-hyperspec-component-intake ()
  "Record the unverified HyperSpec supersession hypothesis."
  (let* ((repository (dreyeck/git:current-git-repository-checkout))
         (local-subject
           (if (dreyeck/git:git-commit-object-present-p
                repository +hyperspec-local-subject+)
               (dreyeck/git:make-git-commit
                :repository repository
                :commit-ish +hyperspec-local-subject+)
               +hyperspec-local-subject+)))
    (make-component-intake
     :repository repository
     :origin "khinsen/html-inspector-views-hyperspec"
     :component-name "html-inspector-views-hyperspec"
     :reference "khinsen/html-inspector-views-hyperspec"
     :local-subject local-subject
     :proposed-relation :supersedes
     :status :unverified
     :contracts +hyperspec-contract-names+)))

(defgeneric upstream-reference-observations (reference)
  (:documentation "Return only observed facts or explicit review hypotheses."))

(defmethod upstream-reference-observations
    ((reference git-commit-upstream-reference))
  (list
   :object-present-p (git-commit-upstream-object-present-p reference)
   :ancestor-of-head-p
   (git-commit-upstream-ancestor-of-head-p reference)
   :merge-base (git-commit-upstream-merge-base-of reference)
   :refs-containing (git-commit-upstream-refs-containing-of reference)
   :classification (git-commit-upstream-classification-of reference)))

(defmethod upstream-reference-observations
    ((reference component-upstream-reference))
  (list
   :local-subject (component-upstream-local-subject-of reference)
   :upstream-candidate (upstream-reference-reference-of reference)
   :proposed-relation
   (component-upstream-proposed-relation-of reference)
   :status (component-upstream-status-of reference)
   :contracts (component-upstream-contracts-of reference)))

(defun commit-hash-or-value (value)
  (if (typep value 'dreyeck/git:git-commit)
      (dreyeck/git:git-commit-hash-of value)
      value))

(defun local-context-summary (context)
  (list
   :repository
   (namestring
    (dreyeck/git:git-repository-root-of
     (upstream-local-context-repository-of context)))
   :branch (upstream-local-context-branch-of context)
   :head
   (dreyeck/git:git-commit-hash-of
    (upstream-local-context-current-head-of context))))

(defgeneric upstream-reference-summary (reference)
  (:documentation "Return a copy-pasteable plist summary of REFERENCE."))

(defmethod upstream-reference-summary
    ((reference git-commit-upstream-reference))
  (let ((context (upstream-reference-local-context-of reference)))
    (list
     :kind :git-commit
     :origin (upstream-reference-origin-of reference)
     :reference (upstream-reference-reference-of reference)
     :local-context (local-context-summary context)
     :object-present-p
     (git-commit-upstream-object-present-p reference)
     :current-head
     (dreyeck/git:git-commit-hash-of
      (upstream-local-context-current-head-of context))
     :ancestor-of-head-p
     (git-commit-upstream-ancestor-of-head-p reference)
     :merge-base
     (commit-hash-or-value
      (git-commit-upstream-merge-base-of reference))
     :refs-containing
     (copy-list (git-commit-upstream-refs-containing-of reference))
     :classification
     (git-commit-upstream-classification-of reference))))

(defmethod upstream-reference-summary
    ((reference component-upstream-reference))
  (list
   :kind :component
   :origin (upstream-reference-origin-of reference)
   :reference (upstream-reference-reference-of reference)
   :local-context
   (local-context-summary
    (upstream-reference-local-context-of reference))
   :local-subject
   (commit-hash-or-value
    (component-upstream-local-subject-of reference))
   :upstream-candidate
   (upstream-reference-reference-of reference)
   :proposed-relation
   (component-upstream-proposed-relation-of reference)
   :status (component-upstream-status-of reference)
   :contracts
   (mapcar
    (lambda (contract)
      (list (contract-observation-name-of contract)
            (contract-observation-status-of contract)))
    (component-upstream-contracts-of reference))))

(hyperdoc:defexample hyperdoc-host-not-found-upstream-intake-example
  "Observe the upstream host-not-found commit without integrating it."
  (make-hyperdoc-host-not-found-intake))

(hyperdoc:defexample hyperspec-component-upstream-intake-example
  "Inspect the still-unverified HyperSpec supersession hypothesis."
  (make-hyperspec-component-intake))
