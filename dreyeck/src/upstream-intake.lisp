;;;; Inspectable, read-only upstream intake observations.

(in-package #:dreyeck/upstream-intake)

(defparameter +hyperspec-local-subject+
  "47e29b3fb89486cc29def9e4c504020d2a714a61")

(defparameter +hyperdoc-host-not-found-upstream-commit+
  "4a0a9d859148e23b6f1ec8ec106145aa68c79c7c")

(defparameter +html-inspector-views-documentation-commit+
  "db6e40c55a6151164f56689f2034c8d7d9113ff8")

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

(defstruct live-definition-probe
  "One definition identity derived from local patch or component evidence."
  package-name
  symbol-name
  kind
  change-kind
  evidence
  method-specializers)

(defstruct live-definition-observation
  "Read-only facts about one definition in the current Lisp image."
  probe
  package-present-p
  symbol-present-p
  symbol-status
  fboundp
  boundp
  class-present-p
  function-kind
  method-present-p)

(defstruct lisp-image-observation
  "A current, read-only projection of relevant systems and definitions."
  relevant-systems
  candidate-system
  candidate-system-loaded-p
  definitions
  evidence-status)

(defstruct potential-live-image-consequence
  "A possible effect inferred from a live fact and an evidenced change."
  kind
  definition
  basis
  (status :potential))

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
    :type upstream-local-context)
   (lisp-image
    :reader upstream-reference-lisp-image-of
    :initform nil)
   (observed-overlap
    :reader upstream-reference-observed-overlap-of
    :initform nil)
   (potential-consequences
    :reader upstream-reference-potential-consequences-of
    :initform nil)
   (evidence
    :reader upstream-reference-evidence-of
    :initform nil)
   (evidence-status
    :reader upstream-reference-evidence-status-of
    :initform :unknown))
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
    :type list)
   (documentation-commit
    :reader component-upstream-documentation-commit-of
    :initarg :documentation-commit
    :initform nil)
   (documentation-observation
    :reader component-upstream-documentation-observation-of
    :initarg :documentation-observation
    :initform nil)
   (documentation-scope
    :reader component-upstream-documentation-scope-of
    :initarg :documentation-scope
    :initform :not-available-locally))
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

(defun loaded-system-names ()
  (mapcar #'string-downcase (asdf:already-loaded-systems)))

(defun system-loaded-p (name loaded-systems)
  (and name
       (member (string-downcase name) loaded-systems :test #'string=)))

(defun probe-symbol (probe)
  (let ((package
          (find-package (live-definition-probe-package-name probe))))
    (if package
        (multiple-value-bind (symbol status)
            (find-symbol (live-definition-probe-symbol-name probe) package)
          (values package symbol status))
        (values nil nil nil))))

(defun specializer-names (method)
  (mapcar
   (lambda (specializer)
     (ignore-errors (class-name specializer)))
   (closer-mop:method-specializers method)))

(defun method-present-p (function probe)
  (let ((expected
          (loop for (package-name symbol-name)
                  in (live-definition-probe-method-specializers probe)
                for package = (find-package package-name)
                for symbol = (and package (find-symbol symbol-name package))
                collect symbol)))
    (and (typep function 'generic-function)
         (notany #'null expected)
         (find expected
               (closer-mop:generic-function-methods function)
               :key #'specializer-names
               :test #'equal))))

(defun observe-live-definition (probe)
  (multiple-value-bind (package symbol status)
      (probe-symbol probe)
    (let* ((fboundp (and symbol (fboundp symbol)))
           (function (and fboundp (symbol-function symbol)))
           (class (and symbol (find-class symbol nil))))
      (make-live-definition-observation
       :probe probe
       :package-present-p (not (null package))
       :symbol-present-p (not (null symbol))
       :symbol-status status
       :fboundp (not (null fboundp))
       :boundp (not (null (and symbol (boundp symbol))))
       :class-present-p (not (null class))
       :function-kind
       (cond
         ((null function) nil)
         ((typep function 'generic-function) :generic-function)
         (t :function))
       :method-present-p
       (not
        (null
         (and function
              (live-definition-probe-method-specializers probe)
              (method-present-p function probe))))))))

(defun live-definition-overlap-p (observation)
  (case
      (live-definition-probe-kind
       (live-definition-observation-probe observation))
    (:class (live-definition-observation-class-present-p observation))
    (:variable (live-definition-observation-boundp observation))
    (:method (live-definition-observation-method-present-p observation))
    (otherwise (live-definition-observation-fboundp observation))))

(defun consequence-kind (observation)
  (let* ((probe (live-definition-observation-probe observation))
         (change-kind (live-definition-probe-change-kind probe))
         (definition-kind (live-definition-probe-kind probe)))
    (cond
      ((member change-kind '(:removed :renamed))
       :stale-live-definition)
      ((eq change-kind :added)
       :live-definition-collision)
      ((eq change-kind :modified)
       (ecase definition-kind
         (:function :live-function-redefinition)
         (:generic-function :live-generic-function-redefinition)
         (:method :live-method-redefinition)
         (:class :live-class-redefinition)
         (:variable :live-variable-rebinding)))
      (t nil))))

(defun potential-consequence-for (observation)
  (let ((kind (and (live-definition-overlap-p observation)
                   (consequence-kind observation))))
    (when kind
      (make-potential-live-image-consequence
       :kind kind
       :definition observation
       :basis
       (format nil "Observed live definition plus evidenced ~A upstream change."
               (live-definition-probe-change-kind
                (live-definition-observation-probe observation)))))))

(defun observe-current-lisp-image
    (&key relevant-systems candidate-system definition-probes
          (evidence-status :observed))
  "Observe only named systems and definitions in the current Lisp image.

This function performs no ASDF lookup or load and creates no packages,
symbols, functions, methods, or classes."
  (let* ((loaded-systems (loaded-system-names))
         (definitions
           (mapcar #'observe-live-definition definition-probes)))
    (make-lisp-image-observation
     :relevant-systems
     (mapcar
      (lambda (name)
        (cons name (not (null (system-loaded-p name loaded-systems)))))
      relevant-systems)
     :candidate-system candidate-system
     :candidate-system-loaded-p
     (not (null (system-loaded-p candidate-system loaded-systems)))
     :definitions definitions
     :evidence-status evidence-status)))

(defun observe-upstream-change
    (reference &key relevant-systems candidate-system definition-probes
                    evidence (evidence-status :observed))
  "Attach a new read-only current-image observation to REFERENCE.

The caller supplies definition identities derived from patch or component
evidence. Potential consequences remain separate objects with :POTENTIAL
status; this routine never loads or changes the observed definitions."
  (let* ((image
           (observe-current-lisp-image
            :relevant-systems relevant-systems
            :candidate-system candidate-system
            :definition-probes definition-probes
            :evidence-status evidence-status))
         (overlap
           (remove-if-not
            #'live-definition-overlap-p
            (lisp-image-observation-definitions image)))
         (consequences
           (remove nil
                   (mapcar #'potential-consequence-for overlap))))
    (setf (slot-value reference 'lisp-image) image
          (slot-value reference 'observed-overlap) overlap
          (slot-value reference 'potential-consequences) consequences
          (slot-value reference 'evidence) evidence
          (slot-value reference 'evidence-status) evidence-status)
    reference))

(defun make-upstream-commit-intake
    (commit-ish
     &key
       origin
       (repository (dreyeck/git:current-git-repository-checkout))
       relevant-systems
       candidate-system
       definition-probes
       evidence
       (evidence-status :observed))
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
    (observe-upstream-change
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
      :classification classification)
     :relevant-systems relevant-systems
     :candidate-system candidate-system
     :definition-probes definition-probes
     :evidence evidence
     :evidence-status evidence-status)))

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
       documentation-commit
       documentation-observation
       (documentation-scope :not-available-locally)
       relevant-systems
       candidate-system
       definition-probes
       evidence
       (evidence-status :partial)
       (repository (dreyeck/git:current-git-repository-checkout)))
  "Record a component relation hypothesis without evaluating or applying it."
  (check-type origin string)
  (check-type component-name string)
  (check-type reference string)
  (observe-upstream-change
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
    :contracts (mapcar #'normalize-contract-observation contracts)
    :documentation-commit documentation-commit
    :documentation-observation documentation-observation
    :documentation-scope documentation-scope)
   :relevant-systems relevant-systems
   :candidate-system candidate-system
   :definition-probes definition-probes
   :evidence evidence
   :evidence-status evidence-status))

(defun host-not-found-definition-probes ()
  (list
   (make-live-definition-probe
    :package-name "HYPERBOOK/FEDWIKI"
    :symbol-name "MAKE-FEDWIKI"
    :kind :function
    :change-kind :modified
    :evidence
    "Commit 4a0a9d modifies the MAKE-FEDWIKI DEFUN in hyperbook-fedwiki/fedwiki.lisp.")))

(defun hyperspec-local-definition-probes ()
  (list
   (make-live-definition-probe
    :package-name "HYPERDOC/INSPECTOR"
    :symbol-name "HYPERSPEC-HTTP-ROOT"
    :kind :function
    :change-kind :local-capability
    :evidence "Local subject 47e29b3 provides the same-origin HTTP root.")
   (make-live-definition-probe
    :package-name "HYPERDOC/INSPECTOR"
    :symbol-name "HYPERSPEC-ROOT-PATHNAME"
    :kind :function
    :change-kind :local-capability
    :evidence "Local subject 47e29b3 validates the local HyperSpec corpus.")
   (make-live-definition-probe
    :package-name "HTML-INSPECTOR-VIEWS/STANDARD"
    :symbol-name "HYPERSPEC-URL"
    :kind :function
    :change-kind :local-capability
    :evidence "The existing symbol lookup and URL formatter are live dependencies.")
   (make-live-definition-probe
    :package-name "HTML-INSPECTOR-VIEWS/STANDARD"
    :symbol-name "*HYPERSPEC-URL-TEMPLATE*"
    :kind :variable
    :change-kind :local-capability
    :evidence "The local subject configures the existing URL template.")
   (make-live-definition-probe
    :package-name "HTML-INSPECTOR-VIEWS/STANDARD"
    :symbol-name "HYPERSPEC-PAGE"
    :kind :class
    :change-kind :local-capability
    :evidence "The local inspector method specializes the existing HyperSpec page class.")
   (make-live-definition-probe
    :package-name "HTML-INSPECTOR-VIEWS/STANDARD"
    :symbol-name "👀CONTENT"
    :kind :method
    :change-kind :local-capability
    :method-specializers
    '(("HTML-INSPECTOR-VIEWS/STANDARD" "HYPERSPEC-PAGE"))
    :evidence "Local subject 47e29b3 installs a content view for HyperSpec pages.")))

(defun candidate-documentation-repository-directories (repository)
  (let* ((root
           (dreyeck/git:git-repository-root-of repository))
         (parent
           (uiop:pathname-parent-directory-pathname
            (uiop:ensure-directory-pathname root)))
         (configured
           (uiop:getenv "HYPERDOC_HTML_INSPECTOR_VIEWS_CHECKOUT")))
    (remove-duplicates
     (remove nil
             (list
              (and configured
                   (uiop:ensure-directory-pathname configured))
              (merge-pathnames #P"html-inspector-views/" parent)))
     :test #'equal)))

(defun documentation-repository-containing (repository commit-ish)
  (loop for directory
          in (candidate-documentation-repository-directories repository)
        when (uiop:directory-exists-p directory)
          do (let ((checkout
                     (make-instance
                      'dreyeck/git:git-repository-checkout
                      :root directory
                      :root-source :local-sibling-candidate)))
               (when (ignore-errors
                       (dreyeck/git:git-commit-object-present-p
                        checkout commit-ish))
                 (return checkout)))))

(defun make-hyperdoc-host-not-found-intake ()
  "Observe Konrad Hinsen's host-not-found HyperDoc commit locally."
  (make-upstream-commit-intake
   +hyperdoc-host-not-found-upstream-commit+
   :origin "khinsen/hyperdoc"
   :relevant-systems '("hyperbook/fedwiki")
   :definition-probes (host-not-found-definition-probes)
   :evidence
   '(:changed-files ("M" "hyperbook-fedwiki/fedwiki.lisp")
     :patch-scope :runtime-code
     :definition-change
     (:modified-function "HYPERBOOK/FEDWIKI::MAKE-FEDWIKI"))))

(defun make-hyperspec-component-intake ()
  "Record the unverified HyperSpec supersession hypothesis."
  (let* ((repository (dreyeck/git:current-git-repository-checkout))
         (local-subject
           (if (dreyeck/git:git-commit-object-present-p
                repository +hyperspec-local-subject+)
               (dreyeck/git:make-git-commit
                :repository repository
                :commit-ish +hyperspec-local-subject+)
               +hyperspec-local-subject+))
         (documentation-repository
           (documentation-repository-containing
            repository +html-inspector-views-documentation-commit+))
         (documentation-observation
           (and documentation-repository
                (make-upstream-commit-intake
                 +html-inspector-views-documentation-commit+
                 :origin "khinsen/html-inspector-views"
                 :repository documentation-repository
                 :evidence
                 '(:changed-files ("M" "README.md")
                   :patch-scope :documentation-only))))
         (documentation-scope
           (if documentation-observation
               :documentation-only
               :not-available-locally)))
    (make-component-intake
     :repository repository
     :origin "khinsen/html-inspector-views-hyperspec"
     :component-name "html-inspector-views-hyperspec"
     :reference "khinsen/html-inspector-views-hyperspec"
     :local-subject local-subject
     :proposed-relation :supersedes
     :status :unverified
     :contracts +hyperspec-contract-names+
     :documentation-commit +html-inspector-views-documentation-commit+
     :documentation-observation documentation-observation
     :documentation-scope documentation-scope
     :relevant-systems
     '("hyperdoc/inspector" "html-inspector-views/standard")
     :candidate-system "html-inspector-views-hyperspec"
     :definition-probes (hyperspec-local-definition-probes)
     :evidence
     '(:candidate-runtime-source :not-inspected
       :candidate-contract-equivalence :unknown
       :documentation-commit-does-not-implement-capability)
     :evidence-status :partial)))

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
   :classification (git-commit-upstream-classification-of reference)
   :current-lisp-image (upstream-reference-lisp-image-of reference)
   :observed-overlap (upstream-reference-observed-overlap-of reference)
   :potential-consequences
   (upstream-reference-potential-consequences-of reference)))

(defmethod upstream-reference-observations
    ((reference component-upstream-reference))
  (list
   :local-subject (component-upstream-local-subject-of reference)
   :upstream-candidate (upstream-reference-reference-of reference)
   :proposed-relation
   (component-upstream-proposed-relation-of reference)
   :status (component-upstream-status-of reference)
   :contracts (component-upstream-contracts-of reference)
   :documentation-commit
   (component-upstream-documentation-commit-of reference)
   :documentation-scope
   (component-upstream-documentation-scope-of reference)
   :current-lisp-image (upstream-reference-lisp-image-of reference)
   :observed-overlap (upstream-reference-observed-overlap-of reference)
   :potential-consequences
   (upstream-reference-potential-consequences-of reference)))

(defun definition-observation-summary (observation)
  (let ((probe (live-definition-observation-probe observation)))
    (list
     :identity
     (format nil "~A::~A"
             (live-definition-probe-package-name probe)
             (live-definition-probe-symbol-name probe))
     :kind (live-definition-probe-kind probe)
     :change-kind (live-definition-probe-change-kind probe)
     :package-present-p
     (live-definition-observation-package-present-p observation)
     :symbol-present-p
     (live-definition-observation-symbol-present-p observation)
     :symbol-status
     (live-definition-observation-symbol-status observation)
     :fboundp (live-definition-observation-fboundp observation)
     :boundp (live-definition-observation-boundp observation)
     :class-present-p
     (live-definition-observation-class-present-p observation)
     :function-kind
     (live-definition-observation-function-kind observation)
     :method-present-p
     (live-definition-observation-method-present-p observation))))

(defun lisp-image-summary (reference)
  (let ((image (upstream-reference-lisp-image-of reference)))
    (when image
      (list
       :relevant-systems
       (copy-tree (lisp-image-observation-relevant-systems image))
       :candidate-system
       (lisp-image-observation-candidate-system image)
       :candidate-system-loaded-p
       (lisp-image-observation-candidate-system-loaded-p image)
       :definitions
       (mapcar #'definition-observation-summary
               (lisp-image-observation-definitions image))
       :evidence-status
       (lisp-image-observation-evidence-status image)
       :potential-consequences
       (mapcar
        (lambda (consequence)
          (list
           :kind
           (potential-live-image-consequence-kind consequence)
           :status
           (potential-live-image-consequence-status consequence)
           :basis
           (potential-live-image-consequence-basis consequence)))
        (upstream-reference-potential-consequences-of reference))))))

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
     (git-commit-upstream-classification-of reference)
     :current-lisp-image (lisp-image-summary reference)
     :evidence (copy-tree (upstream-reference-evidence-of reference))
     :evidence-status
     (upstream-reference-evidence-status-of reference))))

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
   :documentation-commit
   (component-upstream-documentation-commit-of reference)
   :documentation-scope
   (component-upstream-documentation-scope-of reference)
   :contracts
   (mapcar
    (lambda (contract)
      (list (contract-observation-name-of contract)
            (contract-observation-status-of contract)))
    (component-upstream-contracts-of reference))
   :current-lisp-image (lisp-image-summary reference)
   :evidence (copy-tree (upstream-reference-evidence-of reference))
   :evidence-status
   (upstream-reference-evidence-status-of reference)))

(hyperdoc:defexample hyperdoc-host-not-found-upstream-intake-example
  "Observe the upstream host-not-found commit without integrating it."
  (make-hyperdoc-host-not-found-intake))

(hyperdoc:defexample hyperspec-component-upstream-intake-example
  "Inspect the still-unverified HyperSpec supersession hypothesis."
  (make-hyperspec-component-intake))
