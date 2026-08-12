;;;; Historical ASDF reference and generic topicmap regression tests.

(defpackage #:dreyeck/git/asdf-reference-tests
  (:use #:cl)
  (:export #:run-git-asdf-reference-smoke-tests))

(in-package #:dreyeck/git/asdf-reference-tests)

(defvar *historical-reader-eval-ran* nil)

(defun check (value control &rest arguments)
  (unless value
    (error (apply #'format nil control arguments)))
  value)

(defun make-fixture-directory ()
  (let ((directory
          (merge-pathnames
           (format nil "dreyeck-asdf-reference-~D-~D/"
                   (get-universal-time)
                   (random 1000000))
           (uiop:temporary-directory))))
    (ensure-directories-exist directory)
    directory))

(defun write-asdf-fixture (pathname)
  (with-open-file (stream pathname
                          :direction :output
                          :if-exists :supersede
                          :if-does-not-exist :create)
    (write-string
     "(asdf:defsystem #:fixture/historical
  :depends-on (#:closer-mop
               \"asdf\"
               #:dreyeck-historical-topicmap-fixture-missing
               (:version #:closer-mop \"1.0\")
               #.(progn
                   (setf *historical-reader-eval-ran* t)
                   #:closer-mop)))
"
     stream)))

(defun initialize-asdf-fixture (directory)
  (dreyeck/git:git-run-string directory "init" "--quiet")
  (dreyeck/git:git-run-string directory "config" "user.name"
                              "Dreyeck ASDF fixture")
  (dreyeck/git:git-run-string directory "config" "user.email"
                              "fixture@dreyeck.invalid")
  (write-asdf-fixture (merge-pathnames "fixture.asd" directory))
  (dreyeck/git:git-run-string directory "add" "fixture.asd")
  (dreyeck/git:git-run-string directory "commit" "--quiet" "-m"
                              "Historical ASDF fixture")
  directory)

(defun make-fixture-file (directory)
  (let* ((repository
           (make-instance 'dreyeck/git:git-repository-checkout
                          :root directory
                          :root-source :test-fixture))
         (commit
           (dreyeck/git:make-git-commit
            :repository repository
            :commit-ish "HEAD")))
    (dreyeck/git:make-git-file-at-commit
     :commit commit
     :path "fixture.asd")))

(defun view-named (title object)
  (find title
        (html-inspector-views:all-views object)
        :key #'html-inspector-views:view-title
        :test #'string=))

(defun view-reference-values (view)
  (mapcar #'cdr (html-inspector-views:view-references view)))

(defun reference-named (name declaration)
  (find name
        (dreyeck/git:historical-asdf-system-declaration-dependencies-of
         declaration)
        :key
        #'dreyeck/git:historical-asdf-dependency-reference-canonical-name-of
        :test #'equal))

(defun association-types (projection)
  (mapcar #'dreyeck/topicmap:topicmap-association-type-of
          (dreyeck/topicmap:topicmap-projection-associations-of projection)))

(defun check-view-order (file)
  (let ((titles
          (mapcar #'html-inspector-views:view-title
                  (html-inspector-views:all-views file))))
    (check (equal '("Overview" "Contents" "ASDF references" "Topicmap")
                  (subseq titles 0 4))
           "Historical ASDF file view order differs: ~S."
           titles)))

(defun check-topicmap-contract (reference expected-target)
  (let* ((projection
           (dreyeck/git:historical-asdf-reference-topicmap reference))
         (topics (dreyeck/topicmap:topicmap-projection-topics-of projection))
         (associations
           (dreyeck/topicmap:topicmap-projection-associations-of projection))
         (topic-ids (mapcar #'dreyeck/topicmap:topicmap-topic-id-of topics))
         (topicmap-view (view-named "Topicmap" reference)))
    (check (= 5 (length topics))
           "Focused ASDF topicmap has ~D topics instead of five."
           (length topics))
    (check (= 4 (length associations))
           "Focused ASDF topicmap has ~D associations instead of four."
           (length associations))
    (check
     (equal '(:has-file-at-commit
              :declares-system
              :depends-on
              :resolves-to-in-current-image)
            (association-types projection))
     "Focused ASDF association types differ: ~S."
     (association-types projection))
    (check (not (member :hierarchy (association-types projection)))
           "Topicmap contains a synthetic hierarchy relation.")
    (dolist (association associations)
      (check
       (member (dreyeck/topicmap:topicmap-association-from-of association)
               topic-ids :test #'string=)
       "Association ~S has a missing source endpoint."
       association)
      (check
       (member (dreyeck/topicmap:topicmap-association-to-of association)
               topic-ids :test #'string=)
       "Association ~S has a missing target endpoint."
       association))
    (dolist (topic topics)
      (let ((properties (dreyeck/topicmap:topicmap-topic-view-properties-of topic)))
        (dolist (key '(:x :y :visible :pinned))
          (check (member key properties)
                 "Topic ~S lacks view property ~S."
                 topic key))))
    (check topicmap-view "Dependency reference has no generic Topicmap view.")
    (let ((html (html-inspector-views:view-html topicmap-view)))
      (dolist (marker '("dreyeck-topicmap-canvas"
                        "data-association-type='DEPENDS-ON'"
                        "data-temporal-scope='HISTORICAL'"
                        "data-pinned='true'"))
        (check (search marker html :test #'char-equal)
               "Native CLOG Topicmap rendering lacks ~S."
               marker)))
    (check (member expected-target
                   (view-reference-values topicmap-view)
                   :test #'eq)
           "Generic Topicmap does not link to the registered ASDF target.")
    projection))

(defun check-fixture-projection (file)
  (let* ((loaded-before
           (sort (copy-list (asdf:already-loaded-systems)) #'string<))
         (projection
           (dreyeck/git:git-file-asdf-reference-projection file))
         (declarations
           (dreyeck/git:historical-asdf-file-projection-declarations-of
            projection))
         (issues
           (dreyeck/git:historical-asdf-file-projection-issues-of projection))
         (declaration (first declarations))
         (dependencies
           (dreyeck/git:historical-asdf-system-declaration-dependencies-of
            declaration))
         (closer-reference (reference-named "closer-mop" declaration))
         (asdf-reference (reference-named "asdf" declaration))
         (missing-reference
           (reference-named
            "dreyeck-historical-topicmap-fixture-missing"
            declaration))
         (unsupported
           (remove :supported dependencies
                   :key
                   #'dreyeck/git:historical-asdf-dependency-reference-support-status-of))
         (unsupported-reference (first unsupported))
         (closer-resolution
           (dreyeck/git:historical-asdf-dependency-resolution
            closer-reference))
         (missing-resolution
           (dreyeck/git:historical-asdf-dependency-resolution
            missing-reference))
         (unsupported-resolution
           (dreyeck/git:historical-asdf-dependency-resolution
            unsupported-reference))
         (target (asdf:registered-system "closer-mop")))
    (check (= 1 (length declarations))
           "Fixture has ~D declarations instead of one."
           (length declarations))
    (check (string= "fixture/historical"
                    (dreyeck/git:historical-asdf-system-declaration-canonical-name-of
                     declaration))
           "Fixture declaration was not canonicalized.")
    (check (string= "#:closer-mop"
                    (dreyeck/git:historical-asdf-dependency-reference-source-designator-of
                     closer-reference))
           "Historical source designator was not preserved.")
    (check (and closer-reference asdf-reference missing-reference)
           "Simple symbol/string ASDF references were not extracted: ~S."
           dependencies)
    (check (= 2 (length unsupported))
           "Expected two unsupported complex references, got ~S."
           unsupported)
    (check (find "(:version" unsupported
                 :key
                 #'dreyeck/git:historical-asdf-dependency-reference-source-designator-of
                 :test #'search)
           "Complex :VERSION dependency was not retained as unsupported.")
    (check (find "#." unsupported
                 :key
                 #'dreyeck/git:historical-asdf-dependency-reference-source-designator-of
                 :test #'search)
           "Reader-evaluation dependency was not retained as unsupported.")
    (check (= 1 (length issues))
           "Reader-evaluation fixture produced unexpected issues: ~S."
           issues)
    (check (search "not evaluated"
                   (dreyeck/git:historical-asdf-parse-issue-message-of
                    (first issues))
                   :test #'char-equal)
           "Reader-evaluation issue does not state its safe handling.")
    (check (null *historical-reader-eval-ran*)
           "Historical #. reader form was evaluated.")
    (check (eq target
               (dreyeck/git:current-asdf-dependency-resolution-target-of
                closer-resolution))
           "CLOSER-MOP did not resolve to ASDF:REGISTERED-SYSTEM.")
    (check (eq :resolved
               (dreyeck/git:current-asdf-dependency-resolution-status-of
                closer-resolution))
           "CLOSER-MOP resolution is not :RESOLVED.")
    (check (eq :unresolved
               (dreyeck/git:current-asdf-dependency-resolution-status-of
                missing-resolution))
           "Missing dependency did not remain unresolved.")
    (check (eq :unsupported
               (dreyeck/git:current-asdf-dependency-resolution-status-of
                unsupported-resolution))
           "Complex dependency did not remain unsupported.")
    (check (null (asdf:registered-system
                  "dreyeck-historical-topicmap-fixture-missing"))
           "Fixture unexpectedly registered its missing dependency.")
    (check (equal loaded-before
                  (sort (copy-list (asdf:already-loaded-systems)) #'string<))
           "Historical parsing or resolution loaded an ASDF system.")
    (check-view-order file)
    (dolist (object (list declaration closer-reference unsupported-reference
                          closer-resolution missing-resolution
                          unsupported-resolution (first issues)))
      (check (view-named "Overview" object)
             "Historical ASDF object ~S lacks an Overview view."
             object))
    (let ((contents-view (view-named "Contents" file))
          (references-view (view-named "ASDF references" file)))
      (check (search "fixture/historical"
                     (html-inspector-views:view-html contents-view)
                     :test #'char-equal)
             "Existing Contents view no longer renders the historical blob.")
      (check (member target
                     (view-reference-values references-view)
                     :test #'eq)
             "ASDF references table does not link to registered target.")
      (check (member closer-reference
                     (view-reference-values references-view)
                     :test #'eq)
             "ASDF references table does not link to the dependency object."))
    (check-topicmap-contract closer-reference target)
    (check (null (asdf:registered-system
                  "dreyeck-historical-topicmap-fixture-missing"))
           "Rendering a view registered the missing dependency.")
    (check (equal loaded-before
                  (sort (copy-list (asdf:already-loaded-systems)) #'string<))
           "Rendering the ASDF references or Topicmap view loaded a system.")
    t))

(defun check-historical-e3-projection ()
  (let* ((repository (dreyeck/git:current-git-repository-checkout))
         (commit
           (dreyeck/git:make-git-commit
            :repository repository
            :commit-ish "e3f69fcf37cca51f32bd55bcf372134e2cdb77a7"))
         (file
           (dreyeck/git:make-git-file-at-commit
            :commit commit
            :path "dreyeck.asd"))
         (projection
           (dreyeck/git:git-file-asdf-reference-projection file))
         (declaration
           (find
            "dreyeck/upstream-intake"
            (dreyeck/git:historical-asdf-file-projection-declarations-of
             projection)
            :key
            #'dreyeck/git:historical-asdf-system-declaration-canonical-name-of
            :test #'string=))
         (reference (reference-named "closer-mop" declaration))
         (resolution
           (dreyeck/git:historical-asdf-dependency-resolution reference))
         (target (asdf:registered-system "closer-mop")))
    (check declaration
           "Historical e3f69 dreyeck.asd lacks DREYECK/UPSTREAM-INTAKE.")
    (check reference
           "Historical DREYECK/UPSTREAM-INTAKE lacks CLOSER-MOP.")
    (check (eq target
               (dreyeck/git:current-asdf-dependency-resolution-target-of
                resolution))
           "Historical CLOSER-MOP did not link to the registered ASDF system.")
    (check-view-order file)
    (check-topicmap-contract reference target)
    t))

(defun check-resolution-source-contract ()
  (let* ((source-pathnames
           (mapcar
            (lambda (filename)
              (asdf:system-relative-pathname "dreyeck/git" filename))
            '("dreyeck/src/git-asdf-references.lisp"
              "dreyeck/src/git-asdf-reference-topicmap.lisp"
              "dreyeck/src/git-asdf-reference-views.lisp")))
         (sources (mapcar #'uiop:read-file-string source-pathnames)))
    (check (search "asdf:registered-system" (first sources)
                   :test #'char-equal)
           "Resolution source does not use ASDF:REGISTERED-SYSTEM.")
    (dolist (forbidden '("asdf:find-system"
                         "asdf:load-system"
                         "asdf:load-asd"
                         "ql:quickload"))
      (loop for source in sources
            for pathname in source-pathnames
            do (check (null (search forbidden source :test #'char-equal))
                      "ASDF model/view source ~A contains forbidden operation ~S."
                      pathname forbidden))))
  t)

(defun run-git-asdf-reference-smoke-tests ()
  (setf *historical-reader-eval-ran* nil)
  (let ((directory (make-fixture-directory)))
    (unwind-protect
         (progn
           (initialize-asdf-fixture directory)
           (check-fixture-projection (make-fixture-file directory)))
      (uiop:delete-directory-tree directory
                                  :validate t
                                  :if-does-not-exist :ignore)))
  (check-historical-e3-projection)
  (check-resolution-source-contract)
  (format t "Historical ASDF reference and generic Topicmap smoke tests passed.~%")
  t)
