;;;; Deterministic contracts for read-only Upstream Intake observations.

(defpackage #:dreyeck/upstream-intake/tests
  (:use #:cl)
  (:export #:run-upstream-intake-tests))

(in-package #:dreyeck/upstream-intake/tests)

(defvar *controlled-live-image-probe*)

(defun check (value control &rest arguments)
  (unless value
    (error (apply #'format nil control arguments)))
  value)

(defun make-fixture-directory ()
  (let ((directory
          (merge-pathnames
           (format nil "dreyeck-upstream-intake-~D-~D/"
                   (get-universal-time)
                   (random 1000000))
           (uiop:temporary-directory))))
    (ensure-directories-exist directory)
    directory))

(defun write-fixture-file (directory value)
  (with-open-file
      (stream (merge-pathnames "history.txt" directory)
              :direction :output
              :if-exists :supersede
              :if-does-not-exist :create)
    (format stream "~A~%" value)))

(defun commit-fixture-state (directory value subject)
  (write-fixture-file directory value)
  (dreyeck/git:git-run-string directory "add" "history.txt")
  (dreyeck/git:git-run-string
   directory "commit" "--quiet" "-m" subject)
  (dreyeck/git:trim-git-output
   (dreyeck/git:git-run-string directory "rev-parse" "HEAD")))

(defun initialize-intake-fixture (directory)
  "Create A-B-C on main plus a topic commit D forked from A."
  (dreyeck/git:git-run-string
   directory "init" "--quiet" "--initial-branch=main")
  (dreyeck/git:git-run-string
   directory "config" "user.name" "Upstream Intake fixture")
  (dreyeck/git:git-run-string
   directory "config" "user.email" "intake@dreyeck.invalid")
  (let* ((a (commit-fixture-state directory "A" "Fixture A"))
         (b (commit-fixture-state directory "B" "Fixture B"))
         (c (commit-fixture-state directory "C" "Fixture C")))
    (dreyeck/git:git-run-string directory "branch" "topic" a)
    (dreyeck/git:git-run-string directory "switch" "--quiet" "topic")
    (let ((d (commit-fixture-state directory "D" "Fixture D")))
      (dreyeck/git:git-run-string directory "switch" "--quiet" "main")
      (values a b c d))))

(defun read-file-if-present (pathname)
  (when (probe-file pathname)
    (uiop:read-file-string pathname)))

(defun repository-state (directory)
  "Capture the Git state that a read-only intake must preserve."
  (list
   :head
   (dreyeck/git:git-run-string directory "rev-parse" "HEAD")
   :index
   (dreyeck/git:git-run-string
    directory "diff" "--cached" "--no-ext-diff" "--binary")
   :worktree
   (dreyeck/git:git-run-string
    directory "diff" "--no-ext-diff" "--binary")
   :status
   (dreyeck/git:git-run-string
    directory "status" "--porcelain=v1" "--untracked-files=all")
   :refs
   (dreyeck/git:git-run-string
    directory "for-each-ref" "--format=%(objectname) %(refname)")
   :remotes
   (dreyeck/git:git-run-string directory "remote" "-v")
   :fetch-head
   (read-file-if-present (merge-pathnames ".git/FETCH_HEAD" directory))))

(defun make-fixture-repository (directory)
  (make-instance 'dreyeck/git:git-repository-checkout
                 :root directory
                 :root-source :test-fixture))

(defun check-commit-present-and-ancestor (repository b c)
  (let ((intake
          (dreyeck/upstream-intake:make-upstream-commit-intake
           b :origin "fixture/upstream" :repository repository)))
    (check
     (dreyeck/upstream-intake:git-commit-upstream-object-present-p
      intake)
     "Fixture B was not found as a local commit object.")
    (check
     (dreyeck/upstream-intake:git-commit-upstream-ancestor-of-head-p
      intake)
     "Fixture B was not recognized as an ancestor of C.")
    (check (eq :already-integrated
               (dreyeck/upstream-intake:git-commit-upstream-classification-of
                intake))
           "Ancestor intake received classification ~S."
           (dreyeck/upstream-intake:git-commit-upstream-classification-of
            intake))
    (check
     (member "refs/heads/main"
             (dreyeck/upstream-intake:git-commit-upstream-refs-containing-of
              intake)
             :test #'string=)
     "Refs containing B do not include fixture main.")
    (check
     (string= c
              (dreyeck/git:git-commit-hash-of
               (dreyeck/upstream-intake:upstream-local-context-current-head-of
                (dreyeck/upstream-intake:upstream-reference-local-context-of
                 intake))))
     "Intake did not retain fixture HEAD C.")
    intake))

(defun check-commit-present-and-not-ancestor (repository a d)
  (let ((intake
          (dreyeck/upstream-intake:make-upstream-commit-intake
           d :origin "fixture/topic" :repository repository)))
    (check
     (dreyeck/upstream-intake:git-commit-upstream-object-present-p intake)
     "Fixture topic commit D was not found.")
    (check
     (null
      (dreyeck/upstream-intake:git-commit-upstream-ancestor-of-head-p
       intake))
     "Fixture topic commit D was incorrectly considered integrated.")
    (check (eq :available-not-integrated
               (dreyeck/upstream-intake:git-commit-upstream-classification-of
                intake))
           "Divergent intake received classification ~S."
           (dreyeck/upstream-intake:git-commit-upstream-classification-of
            intake))
    (check
     (member "refs/heads/topic"
             (dreyeck/upstream-intake:git-commit-upstream-refs-containing-of
              intake)
             :test #'string=)
     "Refs containing D do not include fixture topic.")
    (check
     (string= a
              (dreyeck/git:git-commit-hash-of
               (dreyeck/upstream-intake:git-commit-upstream-merge-base-of
                intake)))
     "Divergent intake did not retain merge base A.")
    intake))

(defun check-is-ancestor-exit-one-is-data (repository d c)
  (let ((topic
          (dreyeck/git:make-git-commit
           :repository repository :commit-ish d))
        (head
          (dreyeck/git:make-git-commit
           :repository repository :commit-ish c))
        (result :not-called))
    (handler-case
        (setf result (dreyeck/git:git-commit-ancestor-p topic head))
      (dreyeck/git:git-command-failed (condition)
        (error "merge-base --is-ancestor exit 1 became an error: ~A"
               condition)))
    (check (null result)
           "Expected normal NIL ancestry result, got ~S."
           result)))

(defun check-commit-absent (repository)
  (let ((intake
          (dreyeck/upstream-intake:make-upstream-commit-intake
           "1111111111111111111111111111111111111111"
           :origin "fixture/absent"
           :repository repository)))
    (check
     (null
      (dreyeck/upstream-intake:git-commit-upstream-object-present-p
       intake))
     "Unknown fixture commit was reported as present.")
    (check (eq :not-available-locally
               (dreyeck/upstream-intake:git-commit-upstream-classification-of
                intake))
           "Absent intake received classification ~S."
           (dreyeck/upstream-intake:git-commit-upstream-classification-of
            intake))
    (check
     (null
      (dreyeck/upstream-intake:git-commit-upstream-merge-base-of intake))
     "Absent commit unexpectedly has a merge base.")
    intake))

(defun contract-names (intake)
  (mapcar
   #'dreyeck/upstream-intake:contract-observation-name-of
   (dreyeck/upstream-intake:component-upstream-contracts-of intake)))

(defun check-component-intake (repository)
  (let* ((expected-contracts
           '(:existing-symbol-lookup-preserved
             :local-hyperspec-corpus
             :reproducible-nix-source
             :same-origin-http-serving
             :no-external-runtime-fallback
             :defmethod-resolution
             :runtime-closure-availability))
         (intake
           (dreyeck/upstream-intake:make-component-intake
            :repository repository
            :origin "khinsen/html-inspector-views-hyperspec"
            :component-name "html-inspector-views-hyperspec"
            :reference "khinsen/html-inspector-views-hyperspec"
            :local-subject
            "47e29b3fb89486cc29def9e4c504020d2a714a61"
            :proposed-relation :supersedes
            :status :unverified
            :contracts expected-contracts)))
    (check
     (eq :supersedes
         (dreyeck/upstream-intake:component-upstream-proposed-relation-of
          intake))
     "Component hypothesis lost its proposed SUPERSEDES relation.")
    (check
     (eq :unverified
         (dreyeck/upstream-intake:component-upstream-status-of intake))
     "Component hypothesis was incorrectly verified.")
    (check (equal expected-contracts (contract-names intake))
           "Component contract questions differ: ~S."
           (contract-names intake))
    (check
     (every
      (lambda (contract)
        (eq :unknown
            (dreyeck/upstream-intake:contract-observation-status-of
             contract)))
      (dreyeck/upstream-intake:component-upstream-contracts-of intake))
     "Component contracts must start as UNKNOWN.")
    intake))

(defun check-view (intake &rest expected-texts)
  (let* ((name
           'dreyeck/inspector/upstream-intake::upstream-intake-view)
         (function (symbol-function name)))
    (check (typep function 'generic-function)
           "Upstream Intake view is not a generic function.")
    (check (compute-applicable-methods function (list intake))
           "Upstream Intake view has no method for ~S."
           intake)
    (check
     (find "Upstream Intake"
           (html-inspector-views:all-views intake)
           :key #'html-inspector-views:view-title
           :test #'string=)
     "The Moldable Inspector registry does not expose the Intake view.")
    (let* ((view (funcall function intake))
           (html (html-inspector-views:view-html view)))
      (dolist (expected expected-texts)
        (check (search expected html :test #'char-equal)
               "Upstream Intake view lacks ~S: ~S."
               expected html))
      (check (null (search "<button" html :test #'char-equal))
             "Read-only Intake view unexpectedly renders a button: ~S."
             html)
      (check (null (search "cherry-pick" html :test #'char-equal))
             "Read-only Intake view offers a cherry-pick operation.")))
  t)

(defparameter +upstream-intake-page-specs+
  '(("Upstream Intake as a Read-Only Observation"
     "Upstream Intake as a Read-Only Observation.html")
    ("Observing an Upstream Commit"
     "Observing an Upstream Commit.html")
    ("An Upstream Supersession Hypothesis"
     "An Upstream Supersession Hypothesis.html")))

(defun page-elements (page tag-name)
  (plump:get-elements-by-tag-name (hyperdoc::dom-of page) tag-name))

(defun page-package (page)
  (let* ((tags (page-elements page "in-package"))
         (name (and (= 1 (length tags))
                    (string-trim '(#\Space #\Tab #\Newline #\Return)
                                 (plump:text (first tags))))))
    (check name "Page ~S does not declare exactly one IN-PACKAGE."
           (hyperbook:id-of page))
    (or (find-package (string-upcase name))
        (error "Page ~S names missing package ~S."
               (hyperbook:id-of page) name))))

(defun page-source-function-names (page)
  (mapcar
   (lambda (element)
     (string-trim '(#\Space #\Tab #\Newline #\Return)
                  (plump:text element)))
   (page-elements page "source-of-function")))

(defun page-expressions (page)
  (loop for element in (page-elements page "a")
        for expression = (plump:attribute element "expr")
        when expression collect expression))

(defun page-links (page)
  (loop for element in (page-elements page "a")
        for target = (plump:attribute element "page")
        when target collect target))

(defun page-source-text (page)
  (uiop:read-file-string (hyperdoc:file-of page)))

(defun check-substrings-in-order (text substrings context)
  (loop with position = 0
        for substring in substrings
        for found = (search substring text :start2 position)
        do (check found "~A lacks ~S after character ~D."
                  context substring position)
           (setf position (+ found (length substring))))
  t)

(defun check-example-led-reading-order
    (overview commit-page component-page)
  (let ((overview-source (page-source-text overview))
        (commit-source (page-source-text commit-page))
        (component-source (page-source-text component-page)))
    (check
     (equal
      '("(hyperdoc-host-not-found-upstream-intake-example)"
        "(hyperspec-component-upstream-intake-example)")
      (page-expressions overview))
     "Overview does not directly address both named examples: ~S."
     (page-expressions overview))
    (check (null (search "Executable cases" overview-source
                         :test #'char-equal))
           "Overview still displaces its examples into an appendix.")
    (check-substrings-in-order
     overview-source
     '("(hyperdoc-host-not-found-upstream-intake-example)"
       "What happened in that observation?"
       "Observing an upstream change is a routine"
       "(hyperspec-component-upstream-intake-example)"
       "Compare the two kinds of reference"
       "Implementation and provenance on demand"
       "<source-of-function>observe-upstream-change</source-of-function>")
     "Overview example-led reading path")
    (check-substrings-in-order
     commit-source
     '("(hyperdoc-host-not-found-upstream-intake-example)"
       "What to notice"
       "Interpretation"
       "Historical evidence"
       "Implementation and provenance on demand"
       "<source-of-function>make-hyperdoc-host-not-found-intake</source-of-function>")
     "Commit example-led reading path")
    (check-substrings-in-order
     component-source
     '("(hyperspec-component-upstream-intake-example)"
       "What to notice"
       "Documentation evidence is not capability evidence"
       "Contracts still to compare"
       "Implementation and provenance on demand"
       "<source-of-function>make-hyperspec-component-intake</source-of-function>")
     "Component example-led reading path"))
  t)

(defun resolve-page-source-references (page)
  (let ((*package* (page-package page)))
    (dolist (name (page-source-function-names page))
      (multiple-value-bind (symbol position)
          (read-from-string name)
        (check (= position (length name))
               "Source reference ~S has trailing syntax." name)
        (check (fboundp symbol)
               "Page ~S references missing function ~S."
               (hyperbook:id-of page) symbol))))
  t)

(defun evaluate-page-expressions (page)
  (let ((*package* (page-package page)))
    (mapcar
     (lambda (expression)
       (let ((value (hyperdoc::parse-and-eval expression)))
         (check (not (typep value 'condition))
                "Page ~S expression ~S produced ~A."
                (hyperbook:id-of page) expression value)
         value))
     (page-expressions page))))

(defun view-named (title object)
  (find title
        (html-inspector-views:all-views object)
        :key #'html-inspector-views:view-title
        :test #'string=))

(defun view-reference-values (view)
  (mapcar #'cdr (html-inspector-views:view-references view)))

(defun render-page (page)
  (let ((view (view-named "Content" page)))
    (check view "Page ~S has no Content view." (hyperbook:id-of page))
    (values (html-inspector-views:view-html view) view)))

(defun same-truename-p (first second)
  (string= (namestring (truename first))
           (namestring (truename second))))

(defun pathname-under-directory-p (pathname directory)
  (let ((pathname (namestring (truename pathname)))
        (directory
          (namestring
           (uiop:ensure-directory-pathname (truename directory)))))
    (and (<= (length directory) (length pathname))
         (string= directory pathname :end2 (length directory)))))

(defun run-page-asdf-and-catalog-test ()
  (let* ((system (asdf:find-system :dreyeck/upstream-intake))
         (module
           (asdf:find-component system "dreyeck/pages/upstream-intake"))
         (module-directory (asdf:component-pathname module))
         (book dreyeck/upstream-intake:*upstream-intake-hyperdoc*)
         (catalog-book
           (hyperbook:find-hyperbook
            "dreyeck/upstream-intake" :signal-error? t)))
    (check (typep module 'asdf:module)
           "Upstream Intake pages have no owning ASDF module.")
    (check (same-truename-p module-directory
                            (hyperdoc:directory-of book))
           "ASDF module ~A and HyperDoc directory ~A differ."
           module-directory (hyperdoc:directory-of book))
    (check (eq book catalog-book)
           "The registered Catalog object is not the Intake HyperDoc.")
    (check (string= "Upstream Intake as a Read-Only Observation"
                    (hyperbook:main-page-id-of book))
           "Unexpected Upstream Intake main page ~S."
           (hyperbook:main-page-id-of book))
    (hyperdoc::ensure-pages-loaded book)
    (check (= 3 (hash-table-count (hyperdoc:pages-of book)))
           "Upstream Intake HyperDoc contains ~D pages instead of three."
           (hash-table-count (hyperdoc:pages-of book)))
    (dolist (spec +upstream-intake-page-specs+)
      (destructuring-bind (title filename) spec
        (let* ((page
                 (hyperbook:find-page book title :signal-error? t))
               (expected-file (merge-pathnames filename module-directory)))
          (check (probe-file expected-file)
                 "Page file is absent from the ASDF module: ~A."
                 expected-file)
          (check (same-truename-p expected-file (hyperdoc:file-of page))
                 "Page ~S loaded from ~A instead of ~A."
                 title (hyperdoc:file-of page) expected-file)
          (check (pathname-under-directory-p
                  (hyperdoc:file-of page) module-directory)
                 "Page ~S is outside its ASDF page module."
                 title))))
    book))

(defun check-page-navigation (overview commit-page component-page)
  (check
   (equal
    '("Observing an Upstream Commit"
      "An Upstream Supersession Hypothesis")
    (page-links overview))
   "Overview page navigation differs: ~S." (page-links overview))
  (check
   (member "Upstream Intake as a Read-Only Observation"
           (page-links commit-page) :test #'string=)
   "Commit page has no link back to the overview.")
  (check
   (member "Upstream Intake as a Read-Only Observation"
           (page-links component-page) :test #'string=)
   "Component page has no link back to the overview.")
  t)

(defun check-page-executable-contract
    (page expected-expression expected-type expected-source)
  (check (equal (list expected-expression) (page-expressions page))
         "Page ~S expressions differ: ~S."
         (hyperbook:id-of page) (page-expressions page))
  (check (member expected-source
                 (page-source-function-names page)
                 :test #'string=)
         "Page ~S does not show source for ~A."
         (hyperbook:id-of page) expected-source)
  (resolve-page-source-references page)
  (let ((values (evaluate-page-expressions page)))
    (check (= 1 (length values))
           "Page ~S did not produce one Intake object."
           (hyperbook:id-of page))
    (check (typep (first values) expected-type)
           "Page ~S produced ~S instead of ~S."
           (hyperbook:id-of page) (first values) expected-type)
    (first values)))

(defun check-git-page-inspection (page intake)
  (multiple-value-bind (html page-view)
      (render-page page)
    (declare (ignore html))
    (let ((rendered-intake
            (find-if
             (lambda (value)
               (typep
                value
                'dreyeck/upstream-intake:git-commit-upstream-reference))
             (view-reference-values page-view))))
      (check rendered-intake
             "Commit page did not render an inspectable Git Intake object.")))
  (let ((intake-view (view-named "Upstream Intake" intake)))
    (check intake-view "Commit Intake has no Upstream Intake view.")
    (let ((html (html-inspector-views:view-html intake-view)))
      (dolist (text '("Observed current Lisp image"
                      "HYPERBOOK/FEDWIKI::MAKE-FEDWIKI"
                      "Potential consequences"
                      "POTENTIAL"))
        (check (search text html :test #'char-equal)
               "Commit Intake view lacks ~S." text)))
    (let ((upstream-commit
            (dreyeck/upstream-intake:git-commit-upstream-commit-of intake)))
      (when upstream-commit
        (check (find upstream-commit
                     (view-reference-values intake-view)
                     :test #'eq)
               "Intake view does not link its existing upstream commit."))))
  t)

(defun check-component-page-inspection (page intake)
  (multiple-value-bind (html page-view)
      (render-page page)
    (declare (ignore html))
    (check
     (find-if
      (lambda (value)
        (typep value
               'dreyeck/upstream-intake:component-upstream-reference))
      (view-reference-values page-view))
     "Component page did not render an inspectable Component Intake."))
  (let* ((intake-view (view-named "Upstream Intake" intake))
         (html (and intake-view
                    (html-inspector-views:view-html intake-view))))
    (check intake-view "Component Intake has no Upstream Intake view.")
    (dolist (text '("SUPERSEDES" "UNVERIFIED"
                    "Documentation evidence"
                    "DOCUMENTATION-ONLY"
                    "html-inspector-views-hyperspec"
                    "Candidate system"
                    "not loaded"
                    "HYPERDOC/INSPECTOR::HYPERSPEC-ROOT-PATHNAME"
                    "existing-symbol-lookup-preserved"
                    "local-hyperspec-corpus"
                    "reproducible-nix-source"
                    "same-origin-http-serving"
                    "no-external-runtime-fallback"
                    "defmethod-resolution"
                    "runtime-closure-availability"))
      (check (search text html :test #'char-equal)
             "Component Intake view lacks ~S." text)))
  t)

(defun loaded-system-p (name)
  (member name (asdf:already-loaded-systems) :test #'string-equal))

(defun definition-observation (reference package-name symbol-name)
  (find-if
   (lambda (observation)
     (let ((probe
             (dreyeck/upstream-intake:live-definition-observation-probe
              observation)))
       (and
        (string-equal
         package-name
         (dreyeck/upstream-intake:live-definition-probe-package-name probe))
        (string-equal
         symbol-name
         (dreyeck/upstream-intake:live-definition-probe-symbol-name probe)))))
   (dreyeck/upstream-intake:lisp-image-observation-definitions
    (dreyeck/upstream-intake:upstream-reference-lisp-image-of reference))))

(defun consequence-kinds (reference)
  (mapcar
   #'dreyeck/upstream-intake:potential-live-image-consequence-kind
   (dreyeck/upstream-intake:upstream-reference-potential-consequences-of
    reference)))

(defun run-live-image-observation-tests ()
  (let* ((repository-root
           (dreyeck/git:git-repository-root-of
            (dreyeck/git:current-git-repository-checkout)))
         (repository-before (repository-state repository-root))
         (candidate-system "html-inspector-views-hyperspec")
         (candidate-loaded-before (not (null (loaded-system-p candidate-system))))
         (candidate-package-before
           (find-package "HTML-INSPECTOR-VIEWS-HYPERSPEC"))
         (hyperspec-root-function
           (symbol-function
            'hyperdoc/inspector:hyperspec-root-pathname))
         (hyperspec-page-class
           (find-class 'html-inspector-views/standard::hyperspec-page))
         (content-generic
           (symbol-function 'html-inspector-views/standard:👀content))
         (loaded-before-first-observation
           (copy-list (asdf:already-loaded-systems))))
    (when (boundp '*controlled-live-image-probe*)
      (makunbound '*controlled-live-image-probe*))
    (let* ((probe
             (dreyeck/upstream-intake:make-live-definition-probe
              :package-name "DREYECK/UPSTREAM-INTAKE/TESTS"
              :symbol-name "*CONTROLLED-LIVE-IMAGE-PROBE*"
              :kind :variable
              :change-kind :local-capability
              :evidence "Controlled re-observation fixture."))
           (first
             (dreyeck/upstream-intake:observe-current-lisp-image
              :definition-probes (list probe)))
           (first-definition
             (first
              (dreyeck/upstream-intake:lisp-image-observation-definitions
               first))))
      (check
       (null
        (dreyeck/upstream-intake:live-definition-observation-boundp
         first-definition))
       "Controlled definition was unexpectedly live before the first observation.")
      (unwind-protect
           (progn
             (setf *controlled-live-image-probe* :live-now)
             (let* ((second
                      (dreyeck/upstream-intake:observe-current-lisp-image
                       :definition-probes (list probe)))
                    (second-definition
                      (first
                       (dreyeck/upstream-intake:lisp-image-observation-definitions
                        second))))
               (check
                (dreyeck/upstream-intake:live-definition-observation-boundp
                 second-definition)
                "Re-running did not observe the controlled current binding.")))
        (makunbound '*controlled-live-image-probe*)))
    (check (equal loaded-before-first-observation
                  (asdf:already-loaded-systems))
           "Image observation loaded or unloaded an ASDF system.")

    (let* ((host
             (dreyeck/upstream-intake:make-hyperdoc-host-not-found-intake))
           (host-definition
             (definition-observation
              host "HYPERBOOK/FEDWIKI" "MAKE-FEDWIKI"))
           (component
             (dreyeck/upstream-intake:make-hyperspec-component-intake))
           (local-root
             (definition-observation
              component "HYPERDOC/INSPECTOR" "HYPERSPEC-ROOT-PATHNAME"))
           (local-method
             (definition-observation
              component "HTML-INSPECTOR-VIEWS/STANDARD" "👀CONTENT"))
           (documentation
             (dreyeck/upstream-intake:component-upstream-documentation-observation-of
              component)))
      (check host-definition "Host observation lacks MAKE-FEDWIKI evidence.")
      (check
       (dreyeck/upstream-intake:live-definition-observation-fboundp
        host-definition)
       "Re-running did not observe the now-live MAKE-FEDWIKI definition.")
      (check
       (member :live-function-redefinition (consequence-kinds host))
       "Live modified function produced no potential redefinition evidence.")
      (check
       (null (member :stale-live-definition (consequence-kinds host)))
       "Patch without removed definitions produced stale-definition evidence.")
      (check
       (eq
        (cond
          ((not
            (dreyeck/upstream-intake:git-commit-upstream-object-present-p
             host))
           :not-available-locally)
          ((dreyeck/upstream-intake:git-commit-upstream-ancestor-of-head-p
            host)
           :already-integrated)
          (t :available-not-integrated))
        (dreyeck/upstream-intake:git-commit-upstream-classification-of host))
       "Current host-not-found classification is inconsistent with the freshly observed object/ancestry facts: ~S."
       (dreyeck/upstream-intake:git-commit-upstream-classification-of host))
      (check
       (equal (list (format nil "M~Chyperbook-fedwiki/fedwiki.lisp" #\Tab))
              (dreyeck/git:git-commit-changed-files
               (dreyeck/upstream-intake:git-commit-upstream-commit-of host)))
       "Host-not-found changed-file evidence differs from the actual commit.")
      (check local-root "Component observation lacks local root function.")
      (check
       (dreyeck/upstream-intake:live-definition-observation-fboundp local-root)
       "Known local HyperSpec function was not observed live.")
      (check local-method "Component observation lacks content-method evidence.")
      (check
       (dreyeck/upstream-intake:live-definition-observation-method-present-p
        local-method)
       "Known local HyperSpec content method was not observed live.")
      (check
       (eq :partial
           (dreyeck/upstream-intake:upstream-reference-evidence-status-of
            component))
       "Uninspected candidate runtime evidence did not remain PARTIAL.")
      (check
       (every
        (lambda (contract)
          (eq :unknown
              (dreyeck/upstream-intake:contract-observation-status-of
               contract)))
        (dreyeck/upstream-intake:component-upstream-contracts-of component))
       "Component contracts changed without candidate verification.")
      (check
       (not
        (dreyeck/upstream-intake:lisp-image-observation-candidate-system-loaded-p
         (dreyeck/upstream-intake:upstream-reference-lisp-image-of component)))
       "Component observation reports the forbidden candidate as loaded.")
      (if documentation
          (progn
            (check
             (eq :documentation-only
                 (dreyeck/upstream-intake:component-upstream-documentation-scope-of
                  component))
             "Available documentation commit has the wrong scope.")
            (check
             (equal (list (format nil "M~CREADME.md" #\Tab))
                    (dreyeck/git:git-commit-changed-files
                     (dreyeck/upstream-intake:git-commit-upstream-commit-of
                      documentation)))
             "Documentation commit changes more than README.md."))
          (check
           (eq :not-available-locally
               (dreyeck/upstream-intake:component-upstream-documentation-scope-of
                component))
           "Missing documentation commit was not retained as unavailable.")))

    (check (eq hyperspec-root-function
               (symbol-function
                'hyperdoc/inspector:hyperspec-root-pathname))
           "Observation redefined the local HyperSpec root function.")
    (check (eq hyperspec-page-class
               (find-class
                'html-inspector-views/standard::hyperspec-page))
           "Observation redefined the HyperSpec page class.")
    (check (eq content-generic
               (symbol-function
                'html-inspector-views/standard:👀content))
           "Observation replaced the content generic function.")
    (check (eq candidate-package-before
               (find-package "HTML-INSPECTOR-VIEWS-HYPERSPEC"))
           "Observation created or replaced the candidate package.")
    (check (eql candidate-loaded-before
                (not (null (loaded-system-p candidate-system))))
           "Observation loaded the candidate ASDF system.")
    (check (equal repository-before (repository-state repository-root))
           "Live-image observation changed Git state or FETCH_HEAD."))
  t)

(defun run-hyperdoc-page-tests ()
  (let* ((book (run-page-asdf-and-catalog-test))
         (overview
           (hyperbook:find-page
            book "Upstream Intake as a Read-Only Observation"
            :signal-error? t))
         (commit-page
           (hyperbook:find-page
            book "Observing an Upstream Commit"
            :signal-error? t))
         (component-page
           (hyperbook:find-page
            book "An Upstream Supersession Hypothesis"
            :signal-error? t))
         (repository-root
           (dreyeck/git:git-repository-root-of
            (dreyeck/git:current-git-repository-checkout)))
         (before (repository-state repository-root)))
    (check-page-navigation overview commit-page component-page)
    (check-example-led-reading-order overview commit-page component-page)
    (check
     (equal '("observe-upstream-change"
              "make-upstream-commit-intake"
              "make-component-intake"
              "upstream-reference-summary")
            (page-source-function-names overview))
     "Overview source references differ: ~S."
     (page-source-function-names overview))
    (resolve-page-source-references overview)
    (multiple-value-bind (overview-html overview-view)
        (render-page overview)
      (declare (ignore overview-view))
      (check (search "OBSERVE" overview-html)
             "Overview page did not render its observation process."))
    (let ((commit-intake
            (check-page-executable-contract
             commit-page
             "(hyperdoc-host-not-found-upstream-intake-example)"
             'dreyeck/upstream-intake:git-commit-upstream-reference
             "make-hyperdoc-host-not-found-intake"))
          (component-intake
            (check-page-executable-contract
             component-page
             "(hyperspec-component-upstream-intake-example)"
             'dreyeck/upstream-intake:component-upstream-reference
             "make-hyperspec-component-intake")))
      (check-git-page-inspection commit-page commit-intake)
      (check-component-page-inspection component-page component-intake))
    (check (equal before (repository-state repository-root))
           "Rendering Intake pages changed Git state or FETCH_HEAD."))
  t)

(defun run-fixture-tests ()
  (let ((directory (make-fixture-directory)))
    (unwind-protect
         (multiple-value-bind (a b c d)
             (initialize-intake-fixture directory)
           (let* ((repository (make-fixture-repository directory))
                  (before (repository-state directory))
                  (integrated
                    (check-commit-present-and-ancestor repository b c))
                  (not-integrated
                    (check-commit-present-and-not-ancestor repository a d))
                  (absent (check-commit-absent repository))
                  (component (check-component-intake repository)))
             (check-is-ancestor-exit-one-is-data repository d c)
             (check-view integrated "Upstream Intake" "already-integrated")
             (check-view not-integrated "available-not-integrated")
             (check-view absent "not-available-locally")
             (check-view component "SUPERSEDES" "UNVERIFIED"
                         "defmethod-resolution")
             (check (equal before (repository-state directory))
                    "Intake changed HEAD, index, worktree, refs, remotes, or FETCH_HEAD.")))
      (uiop:delete-directory-tree directory
                                  :validate t
                                  :if-does-not-exist :ignore)))
  t)

(defun run-upstream-intake-tests ()
  (run-live-image-observation-tests)
  (run-fixture-tests)
  (run-hyperdoc-page-tests)
  (check
   (fboundp
    'dreyeck/upstream-intake:hyperdoc-host-not-found-upstream-intake-example)
   "Git-commit Intake example is missing.")
  (check
   (fboundp
    'dreyeck/upstream-intake:hyperspec-component-upstream-intake-example)
   "Component Intake example is missing.")
  (let ((boundary-evidence
          (dreyeck/system-boundaries:check-extension-system-boundaries)))
    (check (every (lambda (record) (getf record :passed))
                  boundary-evidence)
           "Dreyeck system boundary evidence failed: ~S"
           boundary-evidence))
  (format t "Read-only Upstream Intake tests passed.~%")
  t)
