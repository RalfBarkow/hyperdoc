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
              (quote
                     (("Upstream Intake as a Read-Only Observation"
                       "Upstream Intake as a Read-Only Observation.html")
                      ("Observing an Upstream Commit"
                       "Observing an Upstream Commit.html")
                      ("An Upstream Supersession Hypothesis"
                       "An Upstream Supersession Hypothesis.html")
                      ("Historical ASDF Dependencies as a Topicmap"
                       "Historical ASDF Dependencies as a Topicmap.html")
                      ("HyperDoc Page Loading: Source Ahead of the Running Image"
                       "HyperDoc Page Loading - Source Ahead of the Running Image.html")
                      ("How Page Loading Became a Protocol"
                       "How Page Loading Became a Protocol.html")
                      ("Specialization Without Integration"
                       "Specialization Without Integration.html")
                      ("What Upstream History Warrants"
                       "What Upstream History Warrants.html"))))

(defun page-elements (page tag-name)
  (plump:get-elements-by-tag-name (hyperdoc::dom-of page) tag-name))

(defun page-package (page)
       (let*
             ((tags
                    (plump-dom:get-elements-by-tag-name
                                                        (plump-parser:parse
                                                                            (hyperdoc:file-of
                                                                                              page))
                                                        "in-package"))
              (name
                    (and (= 1 (length tags))
                         (string-trim
                                      (quote
                                             (#\Space
                                              #\Tab
                                              #\Newline
                                              #\Return))
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

(defun check-example-led-reading-order (overview commit-page component-page)
       (let
            ((overview-source (page-source-text overview))
             (commit-source (page-source-text commit-page))
             (component-source (page-source-text component-page)))
            (check
                   (equal
                          (quote
                                 ("(hyperdoc-host-not-found-upstream-intake-example)"
                                  "(hyperspec-component-upstream-intake-example)"
                                  "(upstream-intake-removal-workspace-example)"))
                          (page-expressions overview))
                   "Overview does not directly address both named examples: ~S."
                   (page-expressions overview))
            (check
                   (null
                         (search "Executable cases" overview-source :test
                                 (function char-equal)))
                   "Overview still displaces its examples into an appendix.")
            (check-substrings-in-order overview-source
                                       (quote
                                              ("(hyperdoc-host-not-found-upstream-intake-example)"
                                               "What happened in that observation?"
                                               "Observing an upstream change is a routine"
                                               "(hyperspec-component-upstream-intake-example)"
                                               "Compare the two kinds of reference"
                                               "Implementation and provenance on demand"
                                               "<source-of-function>observe-upstream-change</source-of-function>"))
                                       "Overview example-led reading path")
            (check-substrings-in-order commit-source
                                       (quote
                                              ("(hyperdoc-host-not-found-upstream-intake-example)"
                                               "What to notice"
                                               "Interpretation"
                                               "Historical evidence"
                                               "Implementation and provenance on demand"
                                               "<source-of-function>make-hyperdoc-host-not-found-intake</source-of-function>"))
                                       "Commit example-led reading path")
            (check-substrings-in-order component-source
                                       (quote
                                              ("(hyperspec-component-upstream-intake-example)"
                                               "What to notice"
                                               "Documentation evidence is not capability evidence"
                                               "Contracts still to compare"
                                               "Implementation and provenance on demand"
                                               "<source-of-function>make-hyperspec-component-intake</source-of-function>"))
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

(defun run-page-asdf-and-catalog-test nil
       (let*
             ((system (asdf:find-system :dreyeck/upstream-intake))
              (module
                      (asdf:find-component system
                                           "dreyeck/pages/upstream-intake"))
              (module-directory (asdf:component-pathname module))
              (book dreyeck/upstream-intake:*upstream-intake-hyperdoc*)
              (catalog-book
                            (hyperbook:find-hyperbook "dreyeck/upstream-intake"
                                                      :signal-error? t)))
             (check (typep module (quote asdf:module))
                    "Upstream Intake pages have no owning ASDF module.")
             (check
                    (same-truename-p module-directory
                                     (hyperdoc:directory-of book))
                    "ASDF module ~A and HyperDoc directory ~A differ."
                    module-directory (hyperdoc:directory-of book))
             (check (eq book catalog-book)
                    "The registered Catalog object is not the Intake HyperDoc.")
             (check
                    (string= "Upstream Intake as a Read-Only Observation"
                             (hyperbook:main-page-id-of book))
                    "Unexpected Upstream Intake main page ~S."
                    (hyperbook:main-page-id-of book))
             (hyperdoc::ensure-pages-loaded book)
             (check (zerop (length (hyperdoc::code-pages-of book)))
                    "Upstream Intake unexpectedly constructed ~D code pages; its complete inventory is currently the reader HTML inventory."
                    (length (hyperdoc::code-pages-of book)))
             (check
                    (= (length +upstream-intake-page-specs+)
                       (hash-table-count (hyperdoc:pages-of book)))
                    "Upstream Intake HyperDoc contains ~D pages instead of ~D."
                    (hash-table-count (hyperdoc:pages-of book))
                    (length +upstream-intake-page-specs+))
             (dolist (spec +upstream-intake-page-specs+)
                     (destructuring-bind (title filename) spec
                                         (let*
                                               ((page
                                                      (hyperbook:find-page book
                                                                           title
                                                                           :signal-error?
                                                                           t))
                                                (expected-file
                                                               (merge-pathnames
                                                                                filename
                                                                                module-directory)))
                                               (check
                                                      (probe-file
                                                                  expected-file)
                                                      "Page file is absent from the ASDF module: ~A."
                                                      expected-file)
                                               (check
                                                      (same-truename-p
                                                                       expected-file
                                                                       (hyperdoc:file-of
                                                                                         page))
                                                      "Page ~S loaded from ~A instead of ~A."
                                                      title
                                                      (hyperdoc:file-of page)
                                                      expected-file)
                                               (check
                                                      (pathname-under-directory-p
                                                                                  (hyperdoc:file-of
                                                                                                    page)
                                                                                  module-directory)
                                                      "Page ~S is outside its ASDF page module."
                                                      title))))
             book))

(defun check-page-navigation (overview commit-page component-page)
       (check
              (equal
                     (quote
                            ("Observing an Upstream Commit"
                             "An Upstream Supersession Hypothesis"
                             "HyperDoc Page Loading: Source Ahead of the Running Image"
                             "How Page Loading Became a Protocol"))
                     (page-links overview))
              "Overview page navigation differs: ~S." (page-links overview))
       (check
              (member "Upstream Intake as a Read-Only Observation"
                      (page-links commit-page) :test (function string=))
              "Commit page has no link back to the overview.")
       (check
              (member "Upstream Intake as a Read-Only Observation"
                      (page-links component-page) :test (function string=))
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
       (multiple-value-bind (html page-view) (render-page page)
                            (declare (ignore html))
                            (check
                                   (find-if
                                            (lambda (value)
                                                    (typep value
                                                           (quote
                                                                  dreyeck/upstream-intake:component-upstream-reference)))
                                            (view-reference-values page-view))
                                   "Component page did not render an inspectable Component Intake."))
       (let*
             ((intake-view (view-named "Upstream Intake" intake))
              (html
                    (and intake-view
                         (html-inspector-views:view-html intake-view))))
             (check intake-view
                    "Component Intake has no Upstream Intake view.")
             (dolist
                     (text
                           (quote
                                  ("SUPERSEDES"
                                   "UNVERIFIED"
                                   "Documentation evidence"
                                   "DOCUMENTATION-ONLY"
                                   "html-inspector-views-hyperspec"
                                   "Candidate system"
                                   "not loaded"
                                   "DREYECK/HYPERSPEC::HYPERSPEC-ROOT-PATHNAME"
                                   "existing-symbol-lookup-preserved"
                                   "local-hyperspec-corpus"
                                   "reproducible-nix-source"
                                   "same-origin-http-serving"
                                   "no-external-runtime-fallback"
                                   "defmethod-resolution"
                                   "runtime-closure-availability")))
                     (check (search text html :test (function char-equal))
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

(defun run-live-image-observation-tests nil
       (let*
             ((repository-root
                               (dreyeck/git:git-repository-root-of
                                                                   (dreyeck/git:current-git-repository-checkout)))
              (repository-before (repository-state repository-root))
              (candidate-system "html-inspector-views-hyperspec")
              (candidate-loaded-before
                                       (not
                                            (null
                                                  (loaded-system-p
                                                                   candidate-system))))
              (candidate-package-before
                                        (find-package
                                                      "HTML-INSPECTOR-VIEWS-HYPERSPEC"))
              (hyperspec-root-function
                                       (symbol-function
                                                        (quote
                                                               dreyeck/hyperspec:hyperspec-root-pathname)))
              (hyperspec-page-class
                                    (find-class
                                                (quote
                                                       html-inspector-views/standard::hyperspec-page)))
              (content-generic
                               (symbol-function
                                                (quote
                                                       html-inspector-views/standard:👀content)))
              (loaded-before-first-observation
                                               (copy-list
                                                          (asdf:already-loaded-systems))))
             (when (boundp (quote *controlled-live-image-probe*))
                   (makunbound (quote *controlled-live-image-probe*)))
             (let*
                   ((probe
                           (dreyeck/upstream-intake:make-live-definition-probe
                                                                               :package-name
                                                                               "DREYECK/UPSTREAM-INTAKE/TESTS"
                                                                               :symbol-name
                                                                               "*CONTROLLED-LIVE-IMAGE-PROBE*"
                                                                               :kind
                                                                               :variable
                                                                               :change-kind
                                                                               :local-capability
                                                                               :evidence
                                                                               "Controlled re-observation fixture."))
                    (first
                           (dreyeck/upstream-intake:observe-current-lisp-image
                                                                               :definition-probes
                                                                               (list
                                                                                     probe)))
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
                                          (setf *controlled-live-image-probe*
                                                :live-now)
                                          (let*
                                                ((second
                                                         (dreyeck/upstream-intake:observe-current-lisp-image
                                                                                                             :definition-probes
                                                                                                             (list
                                                                                                                   probe)))
                                                 (second-definition
                                                                    (first
                                                                           (dreyeck/upstream-intake:lisp-image-observation-definitions
                                                                                                                                       second))))
                                                (check
                                                       (dreyeck/upstream-intake:live-definition-observation-boundp
                                                                                                                   second-definition)
                                                       "Re-running did not observe the controlled current binding.")))
                                   (makunbound
                                               (quote
                                                      *controlled-live-image-probe*))))
             (check
                    (equal loaded-before-first-observation
                           (asdf:already-loaded-systems))
                    "Image observation loaded or unloaded an ASDF system.")
             (let*
                   ((host
                          (dreyeck/upstream-intake:make-hyperdoc-host-not-found-intake))
                    (host-definition
                                     (definition-observation host
                                                             "HYPERBOOK/FEDWIKI"
                                                             "MAKE-FEDWIKI"))
                    (component
                               (dreyeck/upstream-intake:make-hyperspec-component-intake))
                    (local-root
                                (definition-observation component
                                                        "DREYECK/HYPERSPEC"
                                                        "HYPERSPEC-ROOT-PATHNAME"))
                    (local-method
                                  (definition-observation component
                                                          "HTML-INSPECTOR-VIEWS/STANDARD"
                                                          "👀CONTENT"))
                    (documentation
                                   (dreyeck/upstream-intake:component-upstream-documentation-observation-of
                                                                                                            component)))
                   (check host-definition
                          "Host observation lacks MAKE-FEDWIKI evidence.")
                   (check
                          (dreyeck/upstream-intake:live-definition-observation-fboundp
                                                                                       host-definition)
                          "Re-running did not observe the now-live MAKE-FEDWIKI definition.")
                   (check
                          (member :live-function-redefinition
                                  (consequence-kinds host))
                          "Live modified function produced no potential redefinition evidence.")
                   (check
                          (null
                                (member :stale-live-definition
                                        (consequence-kinds host)))
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
                              (dreyeck/upstream-intake:git-commit-upstream-classification-of
                                                                                             host))
                          "Current host-not-found classification is inconsistent with the freshly observed object/ancestry facts: ~S."
                          (dreyeck/upstream-intake:git-commit-upstream-classification-of
                                                                                         host))
                   (check
                          (equal
                                 (list
                                       (format nil
                                               "M~Chyperbook-fedwiki/fedwiki.lisp"
                                               #\Tab))
                                 (dreyeck/git:git-commit-changed-files
                                                                       (dreyeck/upstream-intake:git-commit-upstream-commit-of
                                                                                                                              host)))
                          "Host-not-found changed-file evidence differs from the actual commit.")
                   (check local-root
                          "Component observation lacks local root function.")
                   (check
                          (dreyeck/upstream-intake:live-definition-observation-fboundp
                                                                                       local-root)
                          "Known local HyperSpec function was not observed live.")
                   (check local-method
                          "Component observation lacks content-method evidence.")
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
                                 (dreyeck/upstream-intake:component-upstream-contracts-of
                                                                                          component))
                          "Component contracts changed without candidate verification.")
                   (check
                          (not
                               (dreyeck/upstream-intake:lisp-image-observation-candidate-system-loaded-p
                                                                                                         (dreyeck/upstream-intake:upstream-reference-lisp-image-of
                                                                                                                                                                   component)))
                          "Component observation reports the forbidden candidate as loaded.")
                   (if documentation
                       (progn
                              (check
                                     (eq :documentation-only
                                         (dreyeck/upstream-intake:component-upstream-documentation-scope-of
                                                                                                            component))
                                     "Available documentation commit has the wrong scope.")
                              (check
                                     (equal
                                            (list
                                                  (format nil "M~CREADME.md"
                                                          #\Tab))
                                            (dreyeck/git:git-commit-changed-files
                                                                                  (dreyeck/upstream-intake:git-commit-upstream-commit-of
                                                                                                                                         documentation)))
                                     "Documentation commit changes more than README.md."))
                       (check
                              (eq :not-available-locally
                                  (dreyeck/upstream-intake:component-upstream-documentation-scope-of
                                                                                                     component))
                              "Missing documentation commit was not retained as unavailable.")))
             (check
                    (eq hyperspec-root-function
                        (symbol-function
                                         (quote
                                                dreyeck/hyperspec:hyperspec-root-pathname)))
                    "Observation redefined the local HyperSpec root function.")
             (check
                    (eq hyperspec-page-class
                        (find-class
                                    (quote
                                           html-inspector-views/standard::hyperspec-page)))
                    "Observation redefined the HyperSpec page class.")
             (check
                    (eq content-generic
                        (symbol-function
                                         (quote
                                                html-inspector-views/standard:👀content)))
                    "Observation replaced the content generic function.")
             (check
                    (eq candidate-package-before
                        (find-package "HTML-INSPECTOR-VIEWS-HYPERSPEC"))
                    "Observation created or replaced the candidate package.")
             (check
                    (eql candidate-loaded-before
                         (not (null (loaded-system-p candidate-system))))
                    "Observation loaded the candidate ASDF system.")
             (check
                    (equal repository-before
                           (repository-state repository-root))
                    "Live-image observation changed Git state or FETCH_HEAD."))
       t)

(defun run-hyperdoc-page-tests nil
       (let*
             ((book (run-page-asdf-and-catalog-test))
              (overview
                        (hyperbook:find-page book
                                             "Upstream Intake as a Read-Only Observation"
                                             :signal-error? t))
              (commit-page
                           (hyperbook:find-page book
                                                "Observing an Upstream Commit"
                                                :signal-error? t))
              (component-page
                              (hyperbook:find-page book
                                                   "An Upstream Supersession Hypothesis"
                                                   :signal-error? t))
              (asdf-page
                         (hyperbook:find-page book
                                              "Historical ASDF Dependencies as a Topicmap"
                                              :signal-error? t))
              (page-loading-page
                                 (hyperbook:find-page book
                                                      "HyperDoc Page Loading: Source Ahead of the Running Image"
                                                      :signal-error? t))
              (repository-root
                               (dreyeck/git:git-repository-root-of
                                                                   (dreyeck/git:current-git-repository-checkout)))
              (before (repository-state repository-root)))
             (check
                    (equal
                           (quote
                                  ("hyperdoc-page-loading-image-state-example"
                                   "hyperdoc-page-loading-source-state-example"
                                   "hyperdoc-page-loading-checkpoint-example"))
                           (page-source-function-names page-loading-page))
                    "Page Loading source references differ: ~S."
                    (page-source-function-names page-loading-page))
             (check
                    (equal
                           (quote
                                  ("Upstream Intake as a Read-Only Observation"))
                           (page-links page-loading-page))
                    "Page Loading backlink differs: ~S."
                    (page-links page-loading-page))
             (check-page-executable-contract page-loading-page
                                             "(hyperdoc-page-loading-comparison-example)"
                                             (quote list)
                                             "hyperdoc-page-loading-image-state-example")
             (render-page page-loading-page)
             (check-page-navigation overview commit-page component-page)
             (check-example-led-reading-order overview commit-page
                                              component-page)
             (check
                    (equal
                           (quote
                                  ("upstream-intake-removal-workspace-example"
                                   "observe-upstream-change"
                                   "make-upstream-commit-intake"
                                   "make-component-intake"
                                   "upstream-reference-summary"))
                           (page-source-function-names overview))
                    "Overview source references differ: ~S."
                    (page-source-function-names overview))
             (resolve-page-source-references overview)
             (check
                    (equal
                           (quote
                                  ("git-file-asdf-reference-projection"
                                   "historical-asdf-dependency-resolution"
                                   "historical-asdf-reference-topicmap"))
                           (page-source-function-names asdf-page))
                    "Historical ASDF page source references differ: ~S."
                    (page-source-function-names asdf-page))
             (check (null (page-expressions asdf-page))
                    "Historical ASDF page unexpectedly evaluates expressions.")
             (resolve-page-source-references asdf-page)
             (multiple-value-bind (asdf-html asdf-view) (render-page asdf-page)
                                  (declare (ignore asdf-view))
                                  (dolist
                                          (expected
                                                    (quote
                                                           ("renderer-independent"
                                                            "ASDF:REGISTERED-SYSTEM"
                                                            "general Dreyeck Topicmap contract"
                                                            "unchanged library"
                                                            "native CLOG/SVG"
                                                            "neither a core dependency")))
                                          (check
                                                 (search expected asdf-html
                                                         :test
                                                         (function char-equal))
                                                 "Historical ASDF page lacks ~S."
                                                 expected)))
             (multiple-value-bind (overview-html overview-view)
                                  (render-page overview)
                                  (declare (ignore overview-view))
                                  (check (search "OBSERVE" overview-html)
                                         "Overview page did not render its observation process."))
             (let
                  ((commit-intake
                                  (check-page-executable-contract commit-page
                                                                  "(hyperdoc-host-not-found-upstream-intake-example)"
                                                                  (quote
                                                                         dreyeck/upstream-intake:git-commit-upstream-reference)
                                                                  "make-hyperdoc-host-not-found-intake"))
                   (component-intake
                                     (check-page-executable-contract
                                                                     component-page
                                                                     "(hyperspec-component-upstream-intake-example)"
                                                                     (quote
                                                                            dreyeck/upstream-intake:component-upstream-reference)
                                                                     "make-hyperspec-component-intake")))
                  (check-git-page-inspection commit-page commit-intake)
                  (check-component-page-inspection component-page
                                                   component-intake))
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

(defun check-page-loading-intake nil
       (let*
             ((dreyeck/upstream-intake/tests::records
                                                      (dreyeck/workflow:outstanding-changes))
              (root
                    (dreyeck/git:git-repository-root-of
                                                        (dreyeck/git:current-git-repository-checkout)))
              (state (repository-state root))
              (loaded (asdf/operate:already-loaded-systems))
              (loader (function hyperdoc:load-page))
              (selector (function hyperdoc:page-class))
              (methods (copy-list (sb-mop:generic-function-methods loader)))
              (historical
                          (dreyeck/upstream-intake:hyperdoc-page-loading-before)))
             (assert
                     (eq :available-not-integrated
                         (getf historical :classification)))
             (assert
                     (eq :internal
                         (getf
                               (first
                                      (getf
                                            (getf historical
                                                  :current-lisp-image)
                                            :definitions))
                               :symbol-status)))
             (dotimes (i 2)
                      (let*
                            ((now
                                  (dreyeck/upstream-intake:make-hyperdoc-page-loading-intake))
                             (definition
                                         (definition-observation now "HYPERDOC"
                                                                 "LOAD-PAGE")))
                            (assert (not (eq historical now)))
                            (assert
                                    (dreyeck/upstream-intake:git-commit-upstream-object-present-p
                                                                                                  now))
                            (assert
                                    (eq :external
                                        (dreyeck/upstream-intake:live-definition-observation-symbol-status
                                                                                                           definition)))
                            (assert
                                    (eq
                                        (if
                                            (dreyeck/upstream-intake:git-commit-upstream-ancestor-of-head-p
                                                                                                            now)
                                            :already-integrated
                                            :available-not-integrated)
                                        (dreyeck/upstream-intake:git-commit-upstream-classification-of
                                                                                                       now)))
                            (assert
                                    (every
                                           (lambda (c)
                                                   (eq :potential
                                                       (dreyeck/upstream-intake:potential-live-image-consequence-status
                                                                                                                        c)))
                                           (dreyeck/upstream-intake:upstream-reference-potential-consequences-of
                                                                                                                 now)))
                            (format t
                                    "PAGE-LOADING-INTAKE: before internal; now external; Git ~S~%"
                                    (dreyeck/upstream-intake:git-commit-upstream-classification-of
                                                                                                   now))))
             (assert
                     (equal historical
                            (dreyeck/upstream-intake:hyperdoc-page-loading-before)))
             (assert (eq loader (function hyperdoc:load-page)))
             (assert (eq selector (function hyperdoc:page-class)))
             (assert (equal methods (sb-mop:generic-function-methods loader)))
             (assert (equal loaded (asdf/operate:already-loaded-systems)))
             (assert (equal state (repository-state root)))
             (assert (not (loaded-system-p "dreyeck/workflow/authoring")))
             (assert
                     (equal dreyeck/upstream-intake/tests::records
                            (dreyeck/workflow:outstanding-changes))))
       t)

;;
;; The page-loading history reading sequence
;;

(defparameter +page-loading-history-reading-sequence+
  '(("How Page Loading Became a Protocol"
     ("page-loading-repository-context-example"
      "page-loading-mechanism-example"
      "page-loading-relocation-example"
      "page-loading-contract-sequence-example"
      "page-loading-structural-center-example"
      "page-loading-publication-only-example"
      "page-loading-capability-table-example")
     ("Specialization Without Integration"
      "Upstream Intake as a Read-Only Observation"))
    ("Specialization Without Integration"
     ("page-loading-ancestry-example"
      "page-loading-four-relations-example"
      "page-loading-dreyeck-specialization-example"
      "page-loading-reader-package-history-example")
     ("HyperDoc Page Loading: Source Ahead of the Running Image"
      "What Upstream History Warrants"
      "Upstream Intake as a Read-Only Observation"))
    ("What Upstream History Warrants"
     ("page-loading-ownership-example"
      "page-loading-local-delta-example"
      "page-loading-serialized-spelling-example")
     ("How Page Loading Became a Protocol"
      "Upstream Intake as a Read-Only Observation"))))

(defparameter +page-loading-frozen-identities+
  '(("a8683fb4b43d19e2eb85601e77431f682a80ad89"
     "25c8ba374e5ecacfe3834b81791c48f41cae8dfe"
     "Prepare for HTML pages")
    ("b3e732232e51ccbcd0de479ae51b776955aa01e4"
     "44ed77e9b1d8c4707c86479826e9f0df5cd88684"
     "Make CL the default for *current-package*; export it")
    ("a15bb5445e31a19c9b4e41a465f87b19764f0e00"
     "b3e732232e51ccbcd0de479ae51b776955aa01e4"
     "Export *current-hyperbook* and *current-page*")
    ("beb1689a742f99f75b9255488bd4473ba67f3306"
     "a15bb5445e31a19c9b4e41a465f87b19764f0e00"
     "Allow hyperdoc subclasses to define page subclasses as well")
    ("8a1149197fabcb1ab5622316f09c5a60c2d3f1f8"
     "beb1689a742f99f75b9255488bd4473ba67f3306"
     "Allow hyperdoc subclasses to specialized load-page")))

(defun check-frozen-history-identities ()
  "The frozen records must name exactly these full hashes, parents and
subjects. Abbreviated or drifting identities are a defect, not a detail."
  (let ((records (dreyeck/upstream-intake:page-loading-history-observations)))
    (check (= (length +page-loading-frozen-identities+) (length records))
           "Expected ~D frozen observations, found ~D."
           (length +page-loading-frozen-identities+) (length records))
    (loop for (reference parent subject) in +page-loading-frozen-identities+
          for record in records
          do (check (string= reference (getf record :reference))
                    "Frozen reference ~S differs from ~S."
                    (getf record :reference) reference)
             (check (= 40 (length (getf record :reference)))
                    "Frozen reference ~S is not a full hash."
                    (getf record :reference))
             (check (string= parent (getf record :parent))
                    "Frozen parent of ~S differs: ~S."
                    reference (getf record :parent))
             (check (= 40 (length (getf record :parent)))
                    "Frozen parent ~S is not a full hash."
                    (getf record :parent))
             (check (string= subject (getf record :subject))
                    "Frozen subject of ~S differs: ~S."
                    reference (getf record :subject))
             (check (eq :observed (getf record :evidence-status))
                    "Frozen record ~S is not marked :OBSERVED." reference)
             (check (getf record :warrants)
                    "Frozen record ~S carries no warrant." reference)))
  t)

(defun check-live-history-verification ()
  "Every frozen record must still agree with the object database."
  (dolist (verification
           (dreyeck/upstream-intake:verify-page-loading-history))
    (let ((reference (getf verification :reference)))
      (check (getf verification :object-present-p)
             "Observed commit ~S is absent from this repository." reference)
      (check (getf verification :parent-agrees-p)
             "Parent of ~S disagrees with Git: ~S."
             reference (getf verification :observed-parents))
      (check (getf verification :subject-agrees-p)
             "Subject of ~S disagrees with Git: ~S."
             reference (getf verification :observed-subject))
      (check (getf verification :changed-files-agree-p)
             "Changed files of ~S disagree with Git: ~S."
             reference (getf verification :observed-changed-files))
      (check (getf verification :warrants-agree-p)
             "A warrant of ~S is not confirmed by the blobs: ~S."
             reference (getf verification :warrants))
      (check (getf verification :agrees-p)
             "Verification of ~S did not agree overall." reference)))
  t)

(defun check-history-ancestry-observation ()
  "Adoption is not ancestry: the target is not an ancestor, the fork point is."
  (let ((target (dreyeck/upstream-intake:page-loading-ancestry-observation
                 "8a1149197fabcb1ab5622316f09c5a60c2d3f1f8"))
        (fork (dreyeck/upstream-intake:page-loading-ancestry-observation
               "44ed77e9b1d8c4707c86479826e9f0df5cd88684")))
    (check (getf target :object-present-p)
           "The upstream target object is not present locally.")
    (check (null (getf target :ancestor-of-head-p))
           "8a1149 is reported as an ancestor of this branch.")
    (check (eq t (getf fork :ancestor-of-head-p))
           "The fork point 44ed77e is not reported as an ancestor.")
    (check (string= "44ed77e9b1d8c4707c86479826e9f0df5cd88684"
                    (getf target :merge-base))
           "Unexpected merge base ~S." (getf target :merge-base)))
  t)

(defun check-capability-attributions-are-derived ()
  "An attribution must resolve to warrants that the observation layer holds,
and must fail when it cites one that does not exist."
  (dolist (attribution
           (dreyeck/upstream-intake:page-loading-capability-attributions))
    (check (eq :interpreted (getf attribution :evidence-status))
           "Capability ~S is not marked :INTERPRETED."
           (getf attribution :capability))
    (let ((resolved
            (dreyeck/upstream-intake:resolve-capability-basis attribution)))
      (check resolved "Capability ~S resolved to no warrant at all."
             (getf attribution :capability))
      (dolist (entry resolved)
        (let* ((record (dreyeck/upstream-intake:page-loading-history-observation
                        (getf entry :commit)))
               (warrant (find (getf entry :warrant) (getf record :warrants)
                              :key (lambda (w) (getf w :id)))))
          (check warrant
                 "Capability ~S cites warrant ~S absent from observation ~S."
                 (getf attribution :capability) (getf entry :warrant)
                 (getf entry :commit))
          (check (equal (getf warrant :after) (getf entry :after))
                 "Resolved warrant ~S does not carry the observed form."
                 (getf entry :warrant))))))
  (check (nth-value 1
                    (ignore-errors
                     (dreyeck/upstream-intake:resolve-capability-basis
                      (list :capability :fabricated-for-this-test
                            :basis
                            (list (list :commit
                                        "8a1149197fabcb1ab5622316f09c5a60c2d3f1f8"
                                        :warrant :no-such-warrant))))))
         "A fabricated capability basis resolved instead of signalling.")
  t)

(defun check-page-loading-history-reading (book)
  "Each reading page must exist, address its examples in order, transclude
their persisted source, link onward as intended, and evaluate."
  (dolist (spec +page-loading-history-reading-sequence+)
    (destructuring-bind (title example-names links) spec
      (let ((page (hyperbook:find-page book title :signal-error? t)))
        (check (equal (mapcar (lambda (name) (format nil "(~A)" name))
                              example-names)
                      (page-expressions page))
               "Page ~S does not address its examples in order: ~S."
               title (page-expressions page))
        (check (equal example-names (page-source-function-names page))
               "Page ~S does not transclude its examples in order: ~S."
               title (page-source-function-names page))
        (check (equal links (page-links page))
               "Page ~S navigation differs: ~S." title (page-links page))
        (resolve-page-source-references page)
        (dolist (name example-names)
          (let ((symbol (find-symbol (string-upcase name)
                                     :dreyeck/upstream-intake)))
            (check (and symbol (fboundp symbol))
                   "Page ~S names example ~S, which is not callable."
                   title name)))
        (let ((values (evaluate-page-expressions page)))
          (check (= (length example-names) (length values))
                 "Page ~S produced ~D values for ~D examples."
                 title (length values) (length example-names))
          (dolist (value values)
            (check (getf value :evidence-status)
                   "Page ~S produced a result without an evidence status."
                   title)))
        ;; The page must actually render, with each example's persisted
        ;; source transcluded rather than copied into the HTML.
        (let ((html (render-page page)))
          (check (plusp (length html))
                 "Page ~S rendered no content." title)
          (dolist (name example-names)
            (check (search name html :test #'char-equal)
                   "Page ~S did not transclude the source of ~S."
                   title name))))))
  t)

(defun check-page-loading-repository-context ()
  "History ignores an unrelated cached checkout and records every Git query's root."
  (let* ((directory (make-fixture-directory))
         (dreyeck/git::*git-repository-checkout*
           (make-instance 'dreyeck/git:git-repository-checkout
                          :root directory :root-source :decoy))
         (original (symbol-function 'dreyeck/git:git-run-values))
         (calls nil))
    (unwind-protect
         (progn
           (setf (symbol-function 'dreyeck/git:git-run-values)
                 (lambda (root &rest arguments)
                   (push (cons root arguments) calls)
                   (apply original root arguments)))
           (uiop:with-current-directory (directory)
             (let* ((context (dreyeck/upstream-intake:page-loading-repository-context-example))
                    (root (getf context :repository-root))
                    (expected
                      (dreyeck/git::system-repository-root-info "dreyeck/upstream-intake")))
               (check (equal (truename expected) (truename root))
                      "History did not derive its checkout from the loaded Intake system.")
               (check (eq :repository-context (getf context :kind)) "Wrong context kind.")
               (check (eq :observed (getf context :evidence-status)) "Context is not observed.")
               (check (getf context :object-present-p) "Local upstream object is absent.")
               (check (getf context :ancestry-observed-p) "Local branch ancestry was not observed.")
               (check (probe-file (getf context :git-common-directory)) "Shared Git directory absent.")
               (setf calls nil)
               (let ((missing (dreyeck/upstream-intake::page-loading-repository-context
                               "0000000000000000000000000000000000000000")))
                 (check (null (getf missing :object-present-p)) "Missing object reported present.")
                 (check (null (getf missing :ancestry-observed-p)) "Absent object ancestry queried.")
                 (check (notany (lambda (call) (member "show" (cdr call) :test #'equal)) calls)
                        "Absent object triggered git show."))
               (setf calls nil)
               (let ((publication (dreyeck/upstream-intake:page-loading-publication-only-example)))
                 (check (eq :publication-commit (getf publication :kind)) "Publication example failed.")
                 (check (getf publication :implementation-unchanged-p) "Historical implementation changed.")
                 (check (some (lambda (call) (member "show" (cdr call) :test #'equal)) calls)
                        "Publication did not query historical blobs.")
                 (check (every (lambda (call) (equal (truename root) (truename (car call)))) calls)
                        "Publication queried a different repository: ~S." calls))
               (format t "~&PAGE-LOADING-REPOSITORY-CONTEXT=~S~%" context))))
      (setf (symbol-function 'dreyeck/git:git-run-values) original)
      (uiop:delete-directory-tree directory :validate t :if-does-not-exist :ignore)))
  t)

(defun run-page-loading-history-tests ()
  "The reading sequence, its frozen identities, and its live agreement."
  (let* ((book dreyeck/upstream-intake:*upstream-intake-hyperdoc*)
         (root (dreyeck/git:git-repository-root-of
                (dreyeck/git:current-git-repository-checkout)))
         (before (repository-state root)))
    (hyperdoc::ensure-pages-loaded book)
    (check-page-loading-repository-context)
    (check-frozen-history-identities)
    (check-live-history-verification)
    (check-history-ancestry-observation)
    (check-capability-attributions-are-derived)
    (check-page-loading-history-reading book)
    (let ((shape
            (dreyeck/upstream-intake:page-loading-protocol-shape-across-relocation)))
      (check (getf shape :file-moved-p)
             "The relocation comparison no longer shows a moved file.")
      (check (getf shape :shape-unchanged-p)
             "The relocation range changed the protocol shape: ~S." shape))
    (check (equal before (repository-state root))
           "Reading the page-loading history mutated the repository state."))
  (format t "Page-loading history reading tests passed.~%")
  t)

(defun run-upstream-intake-tests nil
       (dreyeck/upstream-intake/tests::check-page-loading-intake)
       (run-page-loading-history-tests)
       (run-live-image-observation-tests) (run-fixture-tests)
       (run-hyperdoc-page-tests)
       (check
              (fboundp
                       (quote
                              dreyeck/upstream-intake:hyperdoc-host-not-found-upstream-intake-example))
              "Git-commit Intake example is missing.")
       (check
              (fboundp
                       (quote
                              dreyeck/upstream-intake:hyperspec-component-upstream-intake-example))
              "Component Intake example is missing.")
       (format t "Read-only Upstream Intake tests passed.~%") t)
