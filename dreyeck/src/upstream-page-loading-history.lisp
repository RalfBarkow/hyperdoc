;;;; How upstream HyperDoc page loading became a public protocol.
;;;;
;;;; Two layers are kept apart on purpose.
;;;;
;;;; An observation is a frozen Git fact. It is re-checkable against the
;;;; object database this repository already carries, so a reader never has
;;;; to trust the prose. Observations never refresh themselves implicitly.
;;;;
;;;; An attribution is an interpretation. Saying that a commit "establishes
;;;; capability D" is a judgement about observed warrants, not a Git fact,
;;;; and carries :EVIDENCE-STATUS :INTERPRETED.
;;;;
;;;; A warrant identifies source evidence by pathname and by form text, not
;;;; by line number, so it survives reformatting above and below it.

(in-package #:dreyeck/upstream-intake)

(hyperdoc:see
  (hyperdoc:page "How Page Loading Became a Protocol")
  (hyperdoc:page "Specialization Without Integration")
  (hyperdoc:page "What Upstream History Warrants"))

;;
;; Reaching the upstream objects
;;
;; Resolve the loaded reading system's checkout before querying any objects.
;; Object availability is observed, never assumed; no fetch is attempted.

(defun page-loading-history-repository ()
  "Resolve the checkout of the actually loaded Intake system, without a cached default."
  (multiple-value-bind (root source)
      (dreyeck/git::system-repository-root-info "dreyeck/upstream-intake")
    (make-instance 'dreyeck/git:git-repository-checkout
                   :root root :root-source source)))

(defun page-loading-history-commit (reference &optional repository)
  "Resolve REFERENCE in the explicit history context; diagnose absent objects before SHOW."
  (let ((repository (or repository (page-loading-history-repository))))
    (unless (dreyeck/git:git-commit-object-present-p repository reference)
      (error "History commit ~A is absent from the object database queried via ~A."
             reference (dreyeck/git:git-repository-root-of repository)))
    (dreyeck/git:make-git-commit :repository repository :commit-ish reference)))

(defun page-loading-repository-context
    (&optional (reference "8a1149197fabcb1ab5622316f09c5a60c2d3f1f8"))
  "Observe checkout, shared object database and branch ancestry independently."
  (let* ((repository (page-loading-history-repository))
         (root (dreyeck/git:git-repository-root-of repository))
         (present (dreyeck/git:git-commit-object-present-p repository reference))
         (branch "refs/heads/dreyeck.ch")
         (branch-present (dreyeck/git:git-commit-object-present-p repository branch)))
    (flet ((git-path (option)
             (uiop:ensure-directory-pathname
              (dreyeck/git:trim-git-output
               (dreyeck/git:git-run-string
                root "rev-parse" "--path-format=absolute" option)))))
      (list :kind :repository-context
            :source-system "dreyeck/upstream-intake"
            :repository-root root :worktree-root root
            :git-directory (git-path "--git-dir")
            :git-common-directory (git-path "--git-common-dir")
            :reference reference :object-present-p present
            :ancestry-reference branch :ancestry-reference-present-p branch-present
            :ancestry-observed-p (and present branch-present)
            :ancestor-of-dreyeck.ch-p
            (and present branch-present
                 (dreyeck/git:git-commit-ancestor-p
                  (page-loading-history-commit reference repository)
                  (page-loading-history-commit branch repository)))
            :evidence-status :observed))))

(defun page-loading-blob-text (commit pathname)
  "Return the text of PATHNAME at COMMIT, or NIL when the file is absent.

An absent file is ordinary negative evidence for an added or removed path."
  (handler-case
      (dreyeck/git:git-file-contents
       (dreyeck/git:make-git-file-at-commit :commit commit :path pathname))
    (error () nil)))

(defun page-loading-changed-paths (commit)
  "The paths COMMIT changed, sorted, using the typed Git change objects."
  (sort (mapcar #'dreyeck/git:git-commit-file-change-path-of
                (dreyeck/git:git-commit-file-changes commit))
        #'string<))

;;
;; The observation layer
;;
;; Each record is a frozen Git fact plus the warrants that make its claim
;; checkable. A warrant's :AFTER text must occur in the commit's own blob and
;; must be absent from the parent's blob; a :BEFORE text, when the form
;; already existed, must occur in the parent's blob. That triple is what
;; distinguishes "this commit introduced the form" from "the form was already
;; there".
;;

(defun page-loading-history-observations ()
  "Frozen Git observations of the commits that turned page loading into a
protocol, oldest first. Returns a fresh copy; nothing is refreshed here."
  (copy-tree
   '((:kind :git-commit
      :layer :mechanism
      :reference "a8683fb4b43d19e2eb85601e77431f682a80ad89"
      :authored-at "2025-02-21T19:53:37+01:00"
      :parent "25c8ba374e5ecacfe3834b81791c48f41cae8dfe"
      :subject "Prepare for HTML pages"
      :changed-files ("hyperdoc.asd"
                      "hyperdoc/commondoc-pages.lisp"
                      "hyperdoc/html-pages.lisp"
                      "hyperdoc/hyperdoc.lisp")
      :warrants ((:id :load-page-becomes-generic
                  :pathname "hyperdoc/hyperdoc.lisp"
                  :before "(defun load-page (page)"
                  :after "(defgeneric load-page (page))")
                 (:id :page-class-appears
                  :pathname "hyperdoc/hyperdoc.lisp"
                  :after "(defgeneric page-class (filetype))")
                 (:id :construction-selects-by-filetype
                  :pathname "hyperdoc/hyperdoc.lisp"
                  :before "(make-instance 'page :hyperdoc hdoc :file file)"
                  :after "(make-instance (page-class type-as-kw)"))
      :evidence-status :observed)

     (:kind :git-commit
      :layer :contract
      :reference "b3e732232e51ccbcd0de479ae51b776955aa01e4"
      :authored-at "2026-08-17T14:40:00+02:00"
      :parent "44ed77e9b1d8c4707c86479826e9f0df5cd88684"
      :subject "Make CL the default for *current-package*; export it"
      :changed-files ("hyperdoc-explorer/html-pages.lisp"
                      "hyperdoc-explorer/package.lisp")
      :warrants ((:id :renderer-default-package
                  :pathname "hyperdoc-explorer/html-pages.lisp"
                  :before "(let ((*current-package* (find-package \"CL-USER\")))"
                  :after "(let ((*current-package* (find-package \"CL\")))")
                 (:id :current-package-exported
                  :pathname "hyperdoc-explorer/package.lisp"
                  :after "(export '(*current-package*))"))
      :evidence-status :observed)

     (:kind :git-commit
      :layer :contract
      :reference "a15bb5445e31a19c9b4e41a465f87b19764f0e00"
      :authored-at "2026-08-17T14:40:25+02:00"
      :parent "b3e732232e51ccbcd0de479ae51b776955aa01e4"
      :subject "Export *current-hyperbook* and *current-page*"
      :changed-files ("hyperbook-explorer/package.lisp")
      :warrants ((:id :dynamic-context-exported
                  :pathname "hyperbook-explorer/package.lisp"
                  :before "serialize-page-dom))"
                  :after "*current-hyperbook*))"))
      :evidence-status :observed)

     (:kind :git-commit
      :layer :contract
      :reference "beb1689a742f99f75b9255488bd4473ba67f3306"
      :authored-at "2026-08-17T14:57:39+02:00"
      :parent "a15bb5445e31a19c9b4e41a465f87b19764f0e00"
      :subject "Allow hyperdoc subclasses to define page subclasses as well"
      :changed-files ("hyperdoc-explorer/html-pages.lisp"
                      "hyperdoc-explorer/markdown-pages.lisp"
                      "hyperdoc-explorer/package.lisp"
                      "hyperdoc/core.lisp"
                      "hyperdoc/package.lisp")
      :warrants ((:id :page-class-arity
                  :pathname "hyperdoc/core.lisp"
                  :before "(defgeneric page-class (filetype))"
                  :after "(defgeneric page-class (hdoc filetype))")
                 (:id :make-text-page-passes-hdoc
                  :pathname "hyperdoc/core.lisp"
                  :before "(page-class type-as-kw)"
                  :after "(page-class hdoc type-as-kw)")
                 (:id :default-method-stays-general
                  :pathname "hyperdoc-explorer/html-pages.lisp"
                  :before "(defmethod page-class ((filetype (eql :html)))"
                  :after "(defmethod page-class ((hd hyperdoc) (filetype (eql :html)))")
                 (:id :page-class-exported
                  :pathname "hyperdoc/package.lisp"
                  :after ";; Defining page classes for file types")
                 (:id :concrete-page-classes-exported
                  :pathname "hyperdoc-explorer/package.lisp"
                  :before "(export '(*current-package*))"
                  :after "(export '(html-page"))
      :evidence-status :observed)

     (:kind :git-commit
      :layer :contract
      :reference "8a1149197fabcb1ab5622316f09c5a60c2d3f1f8"
      :authored-at "2026-08-18T11:22:11+02:00"
      :parent "beb1689a742f99f75b9255488bd4473ba67f3306"
      :subject "Allow hyperdoc subclasses to specialized load-page"
      :changed-files ("hyperdoc/package.lisp")
      :warrants ((:id :load-page-exported
                  :pathname "hyperdoc/package.lisp"
                  :after ";; Load a page"))
      :evidence-status :observed))))

(defun page-loading-history-observation (reference)
  "The frozen observation whose :REFERENCE is REFERENCE."
  (or (find reference (page-loading-history-observations)
            :key (lambda (record) (getf record :reference))
            :test #'string=)
      (error "No page-loading observation for reference ~S." reference)))

;;
;; Re-checking an observation against the object database
;;

(defun verify-page-loading-warrant (warrant commit parent)
  "Check one warrant's form text in the blobs of COMMIT and its PARENT."
  (let* ((pathname (getf warrant :pathname))
         (before (getf warrant :before))
         (after (getf warrant :after))
         (after-text (page-loading-blob-text commit pathname))
         (before-text (page-loading-blob-text parent pathname)))
    (list :id (getf warrant :id)
          :pathname pathname
          ;; The new form is really in this commit.
          :after-present-p (and after-text (search after after-text) t)
          ;; ... and was not already there in the parent.
          :introduced-here-p (if before-text
                                 (not (search after before-text))
                                 t)
          ;; When a form was replaced rather than added, the old text must
          ;; still be findable in the parent.
          :before-present-p (cond ((null before) :not-applicable)
                                  ((null before-text) nil)
                                  (t (and (search before before-text) t))))))

(defun verify-page-loading-observation (record)
  "Re-derive RECORD's Git facts from the object database and report agreement.

This reads only. It never rewrites the frozen record."
  (let* ((reference (getf record :reference))
         (commit (page-loading-history-commit reference))
         (parents (dreyeck/git:git-commit-parents commit))
         (parent (page-loading-history-commit (getf record :parent)))
         (observed-subject (dreyeck/git:git-commit-subject commit))
         (observed-date (dreyeck/git:git-commit-authored-at commit))
         (observed-paths (page-loading-changed-paths commit))
         (recorded-paths (sort (copy-list (getf record :changed-files))
                               #'string<))
         (warrants (mapcar (lambda (warrant)
                             (verify-page-loading-warrant warrant commit parent))
                           (getf record :warrants))))
    (let ((agreements
            (list :object-present-p
                  (dreyeck/git:git-commit-object-present-p
                   (page-loading-history-repository) reference)
                  :parent-agrees-p (equal (list (getf record :parent)) parents)
                  :subject-agrees-p (string= (getf record :subject)
                                             observed-subject)
                  ;; A date is a Git fact and belongs with the others,
                  ;; re-checkable rather than trusted. It earns its place
                  ;; because sequence alone hides what the dates show:
                  ;; eighteen months separate the mechanism from the
                  ;; contract that publishes it.
                  :authored-at-agrees-p (equal (getf record :authored-at)
                                               observed-date)
                  :changed-files-agree-p (equal recorded-paths observed-paths)
                  :warrants-agree-p
                  (every (lambda (warrant)
                           (and (getf warrant :after-present-p)
                                (getf warrant :introduced-here-p)
                                (not (null (getf warrant :before-present-p)))))
                         warrants))))
      (append (list :kind :observation-verification
                    :reference reference
                    :observed-parents parents
                    :observed-subject observed-subject
                    :observed-authored-at observed-date
                    :observed-changed-files observed-paths
                    :warrants warrants)
              agreements
              (list :agrees-p
                    (and (getf agreements :object-present-p)
                         (getf agreements :parent-agrees-p)
                         (getf agreements :subject-agrees-p)
                         (getf agreements :authored-at-agrees-p)
                         (getf agreements :changed-files-agree-p)
                         (getf agreements :warrants-agree-p))
                    :evidence-status :observed)))))

(defun verify-page-loading-history ()
  "Re-check every frozen observation. The reader can run this at any time."
  (mapcar #'verify-page-loading-observation
          (page-loading-history-observations)))

;;
;; Relocation: the commits that moved the code without reshaping the protocol
;;

(defun page-loading-relocation-observations ()
  "Commits that moved page loading between files and systems.

They are listed so the reader can see that the range was not idle, without
reading every relocation patch. The claim that they leave the protocol shape
alone is checked separately by PAGE-LOADING-PROTOCOL-SHAPE-ACROSS-RELOCATION."
  (copy-tree
   '((:reference "6ef01b73" :subject "Major cleanup")
     (:reference "0de5c65" :subject "Move loading text pages to the explorer system")
     (:reference "c141852" :subject "Transfer code from hyperdoc/explorer to hyperbook/explorer (WIP)")
     (:reference "4a8e9e0" :subject "Don't use distinct packages for the explorer code")
     (:reference "1b6a79d" :subject "Move most HTML rendering to HyperBook explorer"))))

(defun page-loading-protocol-shape-across-relocation ()
  "Compare the two generics at the ends of the relocation range.

The file that holds them changes; their arity does not. That is the whole
claim, and it is checked rather than asserted."
  (flet ((shape (reference pathname)
           (let ((text (page-loading-blob-text
                        (page-loading-history-commit reference) pathname)))
             (list :reference reference
                   :pathname pathname
                   :page-class-one-argument-p
                   (and text (search "(defgeneric page-class (filetype))" text) t)
                   :load-page-one-argument-p
                   (and text (search "(defgeneric load-page (page))" text) t)))))
    (let ((start (shape "a8683fb4b43d19e2eb85601e77431f682a80ad89"
                        "hyperdoc/hyperdoc.lisp"))
          (end (shape "44ed77e9b1d8c4707c86479826e9f0df5cd88684"
                      "hyperdoc/core.lisp")))
      (list :kind :protocol-shape-comparison
            :start start
            :end end
            :file-moved-p (not (string= (getf start :pathname)
                                        (getf end :pathname)))
            :shape-unchanged-p
            (and (getf start :page-class-one-argument-p)
                 (getf end :page-class-one-argument-p)
                 (getf start :load-page-one-argument-p)
                 (getf end :load-page-one-argument-p)
                 t)
            :evidence-status :observed))))

;;
;; The interpretation layer
;;
;; Every attribution names the observed warrants it rests on. RESOLVE makes
;; that reference real: an attribution cannot cite a warrant the observation
;; layer does not contain.
;;

(defun page-loading-capability-attributions ()
  "Which commit first makes each capability true, and on what observed basis.

These are interpretations of the observations, not additional Git facts."
  (copy-tree
   '((:kind :capability-attribution
      :label "A"
      :capability :page-class-depends-on-the-hyperdoc
      :statement "Page class selection can depend on the HyperDoc instance, not only on the filetype."
      :established-by "beb1689a742f99f75b9255488bd4473ba67f3306"
      :basis ((:commit "beb1689a742f99f75b9255488bd4473ba67f3306"
               :warrant :page-class-arity)
              (:commit "beb1689a742f99f75b9255488bd4473ba67f3306"
               :warrant :make-text-page-passes-hdoc))
      :evidence-status :interpreted)

     (:kind :capability-attribution
      :label "B"
      :capability :load-page-is-a-generic-operation
      :statement "LOAD-PAGE exists as a distinct generic operation rather than one concrete function."
      :established-by "a8683fb4b43d19e2eb85601e77431f682a80ad89"
      :basis ((:commit "a8683fb4b43d19e2eb85601e77431f682a80ad89"
               :warrant :load-page-becomes-generic))
      :evidence-status :interpreted)

     (:kind :capability-attribution
      :label "C"
      :capability :load-page-is-a-public-extension-point
      :statement "LOAD-PAGE is reachable as a supported export rather than through the internal symbol."
      :established-by "8a1149197fabcb1ab5622316f09c5a60c2d3f1f8"
      :basis ((:commit "8a1149197fabcb1ab5622316f09c5a60c2d3f1f8"
               :warrant :load-page-exported))
      :evidence-status :interpreted)

     (:kind :capability-attribution
      :label "D"
      :capability :page-subclass-selection
      :statement "A HyperDoc subclass can select its own page subclass: the dispatch admits the book, the generic is exported, and the concrete page classes can be subclassed."
      :established-by "beb1689a742f99f75b9255488bd4473ba67f3306"
      :basis ((:commit "beb1689a742f99f75b9255488bd4473ba67f3306"
               :warrant :page-class-arity)
              (:commit "beb1689a742f99f75b9255488bd4473ba67f3306"
               :warrant :page-class-exported)
              (:commit "beb1689a742f99f75b9255488bd4473ba67f3306"
               :warrant :concrete-page-classes-exported))
      :evidence-status :interpreted)

     (:kind :capability-attribution
      :label "E"
      :capability :loading-behavior-composes
      :statement "A page subclass can add behavior around loading without replacing the ordinary loader: the primary methods are untouched, so a supported qualifier composes with them."
      :established-by "8a1149197fabcb1ab5622316f09c5a60c2d3f1f8"
      :basis ((:commit "8a1149197fabcb1ab5622316f09c5a60c2d3f1f8"
               :warrant :load-page-exported)
              (:commit "a8683fb4b43d19e2eb85601e77431f682a80ad89"
               :warrant :load-page-becomes-generic))
      :evidence-status :interpreted)

     (:kind :capability-attribution
      :label "F"
      :capability :upstream-default-stays-general
      :statement "The upstream default stays deliberately unspecific, so downstream policy is a specialization rather than a global override."
      :established-by "beb1689a742f99f75b9255488bd4473ba67f3306"
      :basis ((:commit "beb1689a742f99f75b9255488bd4473ba67f3306"
               :warrant :default-method-stays-general)
              (:commit "b3e732232e51ccbcd0de479ae51b776955aa01e4"
               :warrant :renderer-default-package))
      :evidence-status :interpreted))))

(defun resolve-capability-basis (attribution)
  "Return the observed warrants ATTRIBUTION rests on.

Signals when an attribution cites a warrant the observation layer does not
contain, so an interpretation cannot drift away from its evidence."
  (mapcar
   (lambda (entry)
     (let* ((reference (getf entry :commit))
            (identifier (getf entry :warrant))
            (record (page-loading-history-observation reference))
            (warrant (find identifier (getf record :warrants)
                           :key (lambda (w) (getf w :id)))))
       (unless warrant
         (error "Capability ~S cites warrant ~S, absent from observation ~S."
                (getf attribution :capability) identifier reference))
       (list :commit reference
             :warrant identifier
             :pathname (getf warrant :pathname)
             :before (getf warrant :before)
             :after (getf warrant :after))))
   (getf attribution :basis)))

(defun page-loading-capability-table ()
  "The A-F table with every row resolved back to its observed warrants."
  (mapcar (lambda (attribution)
            (list :label (getf attribution :label)
                  :capability (getf attribution :capability)
                  :statement (getf attribution :statement)
                  :established-by (getf attribution :established-by)
                  :resolved-basis (resolve-capability-basis attribution)
                  :evidence-status (getf attribution :evidence-status)))
          (page-loading-capability-attributions)))

;;
;; The same history read across states rather than commit by commit
;;

(defun page-loading-authored-universal-time (iso-8601)
  "Parse an author date as Git prints it with %aI.

Fixed width by construction — 2026-08-17T14:40:00+02:00 — so this reads
positions rather than pattern-matching, and a string of another shape
fails loudly instead of yielding a plausible wrong instant. Written here
rather than pulled from a date library because one arithmetic question
is not worth a dependency."
  (unless (and (stringp iso-8601) (= 25 (length iso-8601)))
    (error "Not an ISO 8601 author date of the expected shape: ~S" iso-8601))
  (flet ((number-at (start end) (parse-integer iso-8601 :start start :end end)))
    (let* ((offset-sign (if (char= #\- (char iso-8601 19)) -1 1))
           (offset-hours (number-at 20 22))
           (offset-minutes (number-at 23 25))
           ;; ENCODE-UNIVERSAL-TIME wants hours *west* of GMT, so an
           ;; eastern offset is negative and the sign flips here.
           (zone (- (* offset-sign (+ offset-hours (/ offset-minutes 60))))))
      (encode-universal-time (number-at 17 19) (number-at 14 16)
                             (number-at 11 13) (number-at 8 10)
                             (number-at 5 7) (number-at 0 4)
                             zone))))

(defun page-loading-history-states ()
  "The observed commits as an ordered run of states, with the gaps between.

Ordered by observed ancestry, not by position in the frozen list: the two
layers are not one parent chain — the mechanism commit's parent is not in
the set — so list order would be an assumption where ancestry is a fact.

The elapsed time is carried because the states are not evenly spaced and
the spacing is itself the finding. Between two of them lie twenty-five
seconds; between two others, eighteen months."
  (let* ((records (page-loading-history-observations))
         (ordered
           (sort (copy-list records)
                 (lambda (earlier later)
                   (and (not (string= (getf earlier :reference)
                                      (getf later :reference)))
                        (dreyeck/git:git-commit-ancestor-p
                         (page-loading-history-commit (getf earlier :reference))
                         (page-loading-history-commit
                          (getf later :reference))))))))
    (loop for (record next) on ordered
          for at = (page-loading-authored-universal-time
                    (getf record :authored-at))
          collect (list :reference (getf record :reference)
                        :layer (getf record :layer)
                        :subject (getf record :subject)
                        :authored-at (getf record :authored-at)
                        :seconds-to-next
                        (when next
                          (- (page-loading-authored-universal-time
                              (getf next :authored-at))
                             at))))))

(defun page-loading-states-in-date-order-p ()
  "Does ancestry order agree with author-date order?

Asked rather than assumed. They can disagree — a rebase or a cherry-pick
rewrites one and not the other — and a disagreement would be a finding
about this history, not a defect in the ordering."
  (let ((seconds (mapcar (lambda (state) (getf state :seconds-to-next))
                         (page-loading-history-states))))
    (every (lambda (gap) (or (null gap) (plusp gap))) seconds)))

(defun page-loading-capability-matrix ()
  "Every attributed capability against every observed state.

The transpose of the A-F table. That table answers \"which commit first
made this true\"; this one answers \"what was true here\", which is the
question a reader has when looking at one commit and wondering what it
had to work with.

A capability holds at a state when the commit that established it is an
ancestor of that state, or is that state. So the row reads \"established
at or before this point\". It does not observe removal: nothing here
would notice a capability being taken away again, and claiming otherwise
would be reading more out of ancestry than ancestry says."
  (let ((states (page-loading-history-states)))
    (list
     :states states
     :rows
     (mapcar
      (lambda (attribution)
        (let ((established-by (getf attribution :established-by)))
          (list :label (getf attribution :label)
                :capability (getf attribution :capability)
                :statement (getf attribution :statement)
                :established-by established-by
                :holds
                (mapcar
                 (lambda (state)
                   (list :reference (getf state :reference)
                         :holds-p
                         (dreyeck/git:git-commit-ancestor-p
                          (page-loading-history-commit established-by)
                          (page-loading-history-commit
                           (getf state :reference)))))
                 states))))
      (page-loading-capability-attributions)))))

;;
;; Ancestry is not adoption
;;

(defun page-loading-ancestry-observation (reference)
  "Observe one upstream reference against the current branch of this checkout."
  (let* ((repository (page-loading-history-repository))
         (commit (page-loading-history-commit reference repository))
         (head (page-loading-history-commit "HEAD" repository)))
    (list :reference reference
          :subject (dreyeck/git:git-commit-subject commit)
          :object-present-p (dreyeck/git:git-commit-object-present-p
                             repository reference)
          :ancestor-of-head-p (dreyeck/git:git-commit-ancestor-p commit head)
          :merge-base (dreyeck/git:git-commit-hash-of
                       (dreyeck/git:git-commit-merge-base commit head)))))

(defun page-loading-transition-references ()
  "The four contract commits, oldest first."
  (mapcar (lambda (record) (getf record :reference))
          (remove-if-not (lambda (record) (eq :contract (getf record :layer)))
                         (page-loading-history-observations))))

;;
;; Source adoption, semantic equivalence and text similarity
;;

(defun page-loading-local-source-line (relative-path prefix)
  "The first line of a tracked local file containing PREFIX, trimmed."
  (let ((pathname (asdf/system:system-relative-pathname "dreyeck"
                                                        relative-path)))
    (when (probe-file pathname)
      (with-open-file (stream pathname)
        (loop for line = (read-line stream nil nil)
              while line
              when (search prefix line)
                return (string-trim '(#\Space #\Tab #\Return) line))))))

(defun page-loading-upstream-source-line (reference relative-path prefix)
  "The first line containing PREFIX in RELATIVE-PATH at upstream REFERENCE."
  (let ((text (page-loading-blob-text (page-loading-history-commit reference)
                                      relative-path)))
    (when text
      (loop for line in (uiop:split-string text :separator '(#\Newline))
            when (search prefix line)
              return (string-trim '(#\Space #\Tab #\Return) line)))))

(defun page-loading-same-reading-p (first second &optional (package :hyperdoc))
  "Whether two spellings read to the same s-expression in one package.

Uses the project's own structural reader, so the answer is the reader's, not
a string comparison's."
  (let ((one (html-inspector-views/standard:parse-lisp-code
              first (find-package package)))
        (other (html-inspector-views/standard:parse-lisp-code
                second (find-package package))))
    (equal (mapcar #'html-inspector-views/standard:s-exp
                   (html-inspector-views/standard:top-level-forms-of one))
           (mapcar #'html-inspector-views/standard:s-exp
                   (html-inspector-views/standard:top-level-forms-of other)))))

;;
;; Page 1: How Page Loading Became a Protocol
;;

(hyperdoc:defexample page-loading-repository-context-example
  "First establish which worktree and shared Git repository this reading can observe."
  (page-loading-repository-context))

(hyperdoc:defexample page-loading-mechanism-example
  "The commit that turns one concrete loader into two generic operations.

Read the warrants: LOAD-PAGE stops being a DEFUN, PAGE-CLASS appears, and
construction starts selecting a class by filetype. A mechanism now exists.
Nothing here is exported, so no downstream contract exists yet."
  (let ((record (page-loading-history-observation
                 "a8683fb4b43d19e2eb85601e77431f682a80ad89")))
    (list :kind :mechanism-origin
          :observation record
          :verification (verify-page-loading-observation record)
          :public-contract-yet-p nil
          :evidence-status :observed)))

(hyperdoc:defexample page-loading-relocation-example
  "The long middle of the history, where the code moves and the shape does not.

The generics travel from hyperdoc/hyperdoc.lisp to hyperdoc/core.lisp. Both
stay one-argument. The reader can skip the relocation patches on that basis
rather than on trust."
  (list :kind :relocation-summary
        :commits (page-loading-relocation-observations)
        :comparison (page-loading-protocol-shape-across-relocation)
        :evidence-status :observed))

(hyperdoc:defexample page-loading-contract-sequence-example
  "The four commits that turn the mechanism into a public protocol.

Each record is re-checked against the object database, and each parent link
is verified, so the chain is observed rather than narrated."
  (let ((records (remove-if-not
                  (lambda (record) (eq :contract (getf record :layer)))
                  (page-loading-history-observations))))
    (list :kind :contract-sequence
          :count (length records)
          :steps (mapcar (lambda (record)
                           (list :reference (getf record :reference)
                                 :subject (getf record :subject)
                                 :changed-files (getf record :changed-files)
                                 :verification
                                 (verify-page-loading-observation record)))
                         records)
          :chain-intact-p
          (loop for (earlier later) on records
                while later
                always (string= (getf earlier :reference)
                                (getf later :parent)))
          :evidence-status :observed)))

(hyperdoc:defexample page-loading-structural-center-example
  "Why beb1689 is the structural centre rather than one export among others.

It is the only commit in the transition that changes behavior, and it needs
three things at once: the dispatch must admit the book, PAGE-CLASS must be
exported, and the concrete page classes must be exported so a downstream book
has something to subclass."
  (let ((record (page-loading-history-observation
                 "beb1689a742f99f75b9255488bd4473ba67f3306")))
    (list :kind :structural-centre
          :observation record
          :verification (verify-page-loading-observation record)
          :warrant-count (length (getf record :warrants))
          :evidence-status :observed)))

(hyperdoc:defexample page-loading-publication-only-example
  "The target commit publishes an existing seam; it does not implement one.

Only the package definition changes, so every other file is byte-identical to
the parent. The LOAD-PAGE methods are compared directly to make that concrete."
  (let* ((reference "8a1149197fabcb1ab5622316f09c5a60c2d3f1f8")
         (parent "beb1689a742f99f75b9255488bd4473ba67f3306")
         (commit (page-loading-history-commit reference))
         (before (page-loading-history-commit parent))
         (implementation "hyperdoc-explorer/html-pages.lisp"))
    (list :kind :publication-commit
          :observation (page-loading-history-observation reference)
          :verification (verify-page-loading-observation
                         (page-loading-history-observation reference))
          :changed-paths (page-loading-changed-paths commit)
          :implementation-file implementation
          :implementation-unchanged-p
          (equal (page-loading-blob-text commit implementation)
                 (page-loading-blob-text before implementation))
          :evidence-status :observed)))

(hyperdoc:defexample page-loading-capability-matrix-example
  "What was already true at each step, and how far apart the steps are.

Reading the transition commit by commit makes it look like five moves of
similar weight. Read across states it is one mechanism, a long silence,
three contract commits inside twenty minutes, and a publication the next
morning. 8a11491 builds almost nothing because almost everything it
publishes was already there.

The ordering is observed ancestry; that it agrees with the author dates
is checked rather than assumed."
  (let ((matrix (page-loading-capability-matrix)))
    (list :kind :capability-matrix
          :states (getf matrix :states)
          :rows (getf matrix :rows)
          :ancestry-agrees-with-dates-p (page-loading-states-in-date-order-p)
          :evidence-status :interpreted)))

(hyperdoc:defexample page-loading-capability-table-example
  "Capabilities A to F, each resolved back to the warrants it rests on.

This is the interpretation layer. Every row carries :INTERPRETED, and every
basis entry is looked up in the observation layer, so a row cannot cite
evidence that is not there."
  (list :kind :capability-table
        :rows (page-loading-capability-table)
        :evidence-status :interpreted))

;;
;; Page 2: Specialization Without Integration
;;

(hyperdoc:defexample page-loading-ancestry-example
  "Where the fork actually stands relative to the upstream history.

The mechanism commit is a genuine ancestor. The four contract commits are
not, and they all share the same merge base. Adoption happened in the source
tree, not in the commit graph."
  (list :kind :ancestry-observation
        :mechanism (page-loading-ancestry-observation
                    "a8683fb4b43d19e2eb85601e77431f682a80ad89")
        :fork-point (page-loading-ancestry-observation
                     "44ed77e9b1d8c4707c86479826e9f0df5cd88684")
        :contract (mapcar #'page-loading-ancestry-observation
                          (page-loading-transition-references))
        :evidence-status :observed))

(hyperdoc:defexample page-loading-four-relations-example
  "Four relations that are easy to collapse into one word, kept apart.

Each question gets its own observed answer. Two are true and two are false,
which is exactly why \"integrated\" is not a usable single relation."
  (let ((upstream (page-loading-upstream-source-line
                   "8a1149197fabcb1ab5622316f09c5a60c2d3f1f8"
                   "hyperdoc/core.lisp" "(defgeneric page-class"))
        (local (page-loading-local-source-line
                "hyperdoc/core.lisp" "(defgeneric page-class")))
    (list :kind :relation-comparison
          :upstream-spelling upstream
          :local-spelling local
          :git-ancestry
          (list :question "Is the upstream commit an ancestor of this branch?"
                :value (getf (page-loading-ancestry-observation
                              "8a1149197fabcb1ab5622316f09c5a60c2d3f1f8")
                             :ancestor-of-head-p))
          :source-adoption
          (list :question "Does the local tree carry the adopted call site?"
                :value (and (page-loading-local-source-line
                             "hyperdoc/core.lisp"
                             "(page-class hdoc type-as-kw)")
                            t))
          :semantic-equivalence
          (list :question "Do the two spellings read to the same form?"
                :value (and upstream local
                            (page-loading-same-reading-p upstream local)))
          :text-similarity
          (list :question "Are the two spellings the same text?"
                :value (equal upstream local))
          :evidence-status :observed)))

(hyperdoc:defexample page-loading-dreyeck-specialization-example
  "What Dreyeck actually added on top of the published protocol.

A book subclass, a page subclass, one PAGE-CLASS method and one LOAD-PAGE
:AFTER method. Observed in the running image through the metaobject
protocol, not read out of a document."
  (flet ((methods (name)
           (let ((function (and (fboundp name) (fdefinition name))))
             (and function
                  (typep function 'generic-function)
                  (mapcar
                   (lambda (method)
                     (list :qualifiers (method-qualifiers method)
                           :specializers
                           (mapcar #'princ-to-string
                                   (sb-mop:method-specializers method))))
                   (sb-mop:generic-function-methods function))))))
    (list :kind :dreyeck-specialization
          :book-subclass
          (list :class (find-class 'dreyeck/hyperdoc:hyperdoc nil)
                :upstream-superclass (find-class 'hyperdoc:hyperdoc nil))
          :page-subclass
          (list :class (find-class 'dreyeck/hyperdoc:html-page nil)
                :upstream-superclass (find-class 'hyperdoc:html-page nil))
          :page-class-methods (methods 'hyperdoc:page-class)
          :load-page-methods (methods 'hyperdoc:load-page)
          :evidence-status :observed)))

(hyperdoc:defexample page-loading-reader-package-history-example
  "The reader package was never CL upstream until b3e7322 made it so.

CL-USER is upstream's own long-standing default. Konrad changed the general
default to CL; Dreyeck then re-established CL-USER for Dreyeck pages only.
Calling that a return to an older CL default would invert the direction of
the history, so the three sample points are observed here."
  (flet ((sample (reference pathname)
           (let ((text (page-loading-blob-text
                        (page-loading-history-commit reference) pathname)))
             (list :reference reference
                   :pathname pathname
                   :cl-user-present-p
                   (and text (search "(find-package \"CL-USER\")" text) t)
                   :cl-present-p
                   (and text (search "(find-package \"CL\")" text) t)))))
    (list :kind :reader-package-history
          :samples
          (list (sample "a8683fb4b43d19e2eb85601e77431f682a80ad89"
                        "hyperdoc/commondoc-pages.lisp")
                (sample "2cfd48dd8c6586ecc532d289d5f9265311948d5f"
                        "hyperdoc-explorer/html-pages.lisp")
                (sample "b3e732232e51ccbcd0de479ae51b776955aa01e4"
                        "hyperdoc-explorer/html-pages.lisp"))
          :earlier-cl-default-p nil
          :dreyeck-policy :cl-user-restored-for-dreyeck-pages-only
          :evidence-status :observed)))

;;
;; Page 3: What Upstream History Warrants
;;

(hyperdoc:defexample page-loading-ownership-example
  "Which part of today's Dreyeck each upstream commit does and does not warrant.

A row is :UPSTREAM-NOW-PROVIDES only when a frozen warrant backs it. The
categories are an interpretation; the warrants they cite are observed."
  (flet ((row (category subject reference warrant local-path local-probe)
           (list :category category
                 :subject subject
                 :upstream-warrant
                 (first (resolve-capability-basis
                         (list :capability subject
                               :basis (list (list :commit reference
                                                  :warrant warrant)))))
                 :local-evidence
                 (page-loading-local-source-line local-path local-probe))))
    (list :kind :ownership-table
          :rows
          (list (row :upstream-now-provides :two-argument-page-class
                     "beb1689a742f99f75b9255488bd4473ba67f3306"
                     :page-class-arity
                     "hyperdoc/core.lisp" "(page-class hdoc type-as-kw)")
                (row :upstream-now-provides :public-page-class
                     "beb1689a742f99f75b9255488bd4473ba67f3306"
                     :page-class-exported
                     "hyperdoc/package.lisp" "#:page-class")
                (row :upstream-now-provides :public-load-page
                     "8a1149197fabcb1ab5622316f09c5a60c2d3f1f8"
                     :load-page-exported
                     "hyperdoc/package.lisp" "#:load-page")
                (row :upstream-now-provides :general-renderer-package
                     "b3e732232e51ccbcd0de479ae51b776955aa01e4"
                     :renderer-default-package
                     "hyperdoc-explorer/html-pages.lisp"
                     "(find-package \"CL\")"))
          :dreyeck-specialization
          (list :subject :dreyeck-page-policy
                :uses (list :public-page-class :public-load-page)
                :detail (page-loading-dreyeck-specialization-example)
                :evidence-status :interpreted)
          :evidence-status :interpreted)))

(hyperdoc:defexample page-loading-local-delta-example
  "What upstream history through 8a1149 does not warrant at all.

The code-subdirectory extension has no upstream counterpart in this range.
The LOAD-PAGE :AFTER method sits on a public seam but reaches the DOM through
an internal slot, because this history establishes no public parse-tree
accessor."
  (let* ((reference "8a1149197fabcb1ab5622316f09c5a60c2d3f1f8")
         (upstream-core (page-loading-blob-text
                         (page-loading-history-commit reference)
                         "hyperdoc/core.lisp"))
         (policy (asdf/system:system-relative-pathname
                  "dreyeck" "dreyeck/src/hyperdoc-pages.lisp"))
         (policy-text (and (probe-file policy)
                           (uiop:read-file-string policy))))
    (list :kind :local-delta
          :code-subdirectory
          (list :category :remaining-local-library-delta
                :upstream-present-p
                (and upstream-core
                     (search "code-subdirectory" upstream-core) t)
                :local-present-p
                (and (page-loading-local-source-line
                      "hyperdoc/core.lisp" "code-subdirectory")
                     t))
          :parse-tree-coupling
          (list :category :residual-unsupported-coupling
                :upstream-public-accessor-p
                (and upstream-core
                     (search "(defgeneric parse-tree" upstream-core) t)
                :local-slot-access-p
                (and policy-text
                     (search "PARSE-TREE" policy-text :test #'char-equal) t))
          :evidence-status :observed)))

(hyperdoc:defexample page-loading-serialized-spelling-example
  "One spelling difference that upstream history does not warrant.

The binding is the same symbol either way, which the project's own reader
confirms. What has no warrant is the package prefix on a lambda-list
parameter: no upstream commit in this history produces it, so it is
representation, not semantics. Knowing that is a reason to leave it alone
unless a separate decision says otherwise, not a reason to rewrite source
to look like upstream."
  (let ((upstream (page-loading-upstream-source-line
                   "8a1149197fabcb1ab5622316f09c5a60c2d3f1f8"
                   "hyperdoc/core.lisp" "(defgeneric page-class"))
        (local (page-loading-local-source-line
                "hyperdoc/core.lisp" "(defgeneric page-class")))
    (list :kind :source-hygiene-comparison
          :upstream-spelling upstream
          :local-spelling local
          :warranted-by (getf (first (resolve-capability-basis
                                      (list :capability :page-class-arity
                                            :basis
                                            (list (list :commit "beb1689a742f99f75b9255488bd4473ba67f3306"
                                                        :warrant :page-class-arity)))))
                              :after)
          :same-text-p (equal upstream local)
          :same-reading-p (and upstream local
                               (page-loading-same-reading-p upstream local))
          :difference :representation-without-upstream-warrant
          :evidence-status :observed)))
