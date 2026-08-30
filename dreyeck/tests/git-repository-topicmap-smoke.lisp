(in-package #:dreyeck/git/tests)


(defun run-git-source-slice-topicmap-test ()
  (let ((directory (make-fixture-directory)))
    (unwind-protect
        (progn
         (initialize-git-fixture directory)
         (let* ((common-lisp-user::repository
                 (make-instance 'dreyeck/git:git-repository-checkout :root directory :root-source
                                :git-source-slice-topicmap-test))
                (common-lisp-user::commit
                 (dreyeck/git:make-git-commit :repository common-lisp-user::repository :commit-ish
                                              "HEAD~1"))
                (common-lisp-user::slice
                 (dreyeck/git:make-git-source-slice :commit common-lisp-user::commit :selections
                                                    '("/example.lisp") :sparse-mode :no-cone))
                (common-lisp-user::projection
                 (dreyeck/topicmap:topicmap-projection-of common-lisp-user::slice))
                (common-lisp-user::topics
                 (dreyeck/topicmap:topicmap-projection-topics-of common-lisp-user::projection))
                (common-lisp-user::associations
                 (dreyeck/topicmap:topicmap-projection-associations-of
                  common-lisp-user::projection))
                (common-lisp-user::slice-topic
                 (find common-lisp-user::slice common-lisp-user::topics :key
                       #'dreyeck/topicmap:topicmap-topic-object-of :test #'eq))
                (common-lisp-user::commit-topic
                 (find common-lisp-user::commit common-lisp-user::topics :key
                       #'dreyeck/topicmap:topicmap-topic-object-of :test #'eq))
                (common-lisp-user::association (first common-lisp-user::associations))
                (common-lisp-user::view-properties
                 (dreyeck/topicmap:topicmap-projection-view-properties-of
                  common-lisp-user::projection)))
           (check
            (eq common-lisp-user::slice
                (dreyeck/topicmap:topicmap-projection-source-of common-lisp-user::projection))
            "Projection source is not the Git source slice.")
           (check (= 2 (length common-lisp-user::topics))
                  "Expected exactly two source-slice topics, got ~S." common-lisp-user::topics)
           (check common-lisp-user::slice-topic "No topic refers to the Git source slice.")
           (check
            (eq :git-source-slice
                (dreyeck/topicmap:topicmap-topic-type-of common-lisp-user::slice-topic))
            "Unexpected source-slice topic type ~S."
            (dreyeck/topicmap:topicmap-topic-type-of common-lisp-user::slice-topic))
           (check common-lisp-user::commit-topic "No topic refers to the source-slice commit.")
           (check
            (eq :git-commit
                (dreyeck/topicmap:topicmap-topic-type-of common-lisp-user::commit-topic))
            "Unexpected commit topic type ~S."
            (dreyeck/topicmap:topicmap-topic-type-of common-lisp-user::commit-topic))
           (check (= 1 (length common-lisp-user::associations))
                  "Expected exactly one source-slice association, got ~S."
                  common-lisp-user::associations)
           (check
            (eq 'dreyeck/git:git-source-slice-commit-of
                (dreyeck/topicmap:topicmap-association-type-of common-lisp-user::association))
            "Unexpected source-slice association type ~S."
            (dreyeck/topicmap:topicmap-association-type-of common-lisp-user::association))
           (check
            (string= (dreyeck/topicmap:topicmap-topic-id-of common-lisp-user::slice-topic)
                     (dreyeck/topicmap:topicmap-association-from-of common-lisp-user::association))
            "Source-slice association does not start at the slice topic.")
           (check
            (string= (dreyeck/topicmap:topicmap-topic-id-of common-lisp-user::commit-topic)
                     (dreyeck/topicmap:topicmap-association-to-of common-lisp-user::association))
            "Source-slice association does not end at the commit topic.")
           (check
            (string= (dreyeck/topicmap:topicmap-topic-id-of common-lisp-user::slice-topic)
                     (getf common-lisp-user::view-properties :point))
            "Source-slice topic is not the projection point.")))
      (uiop/filesystem:delete-directory-tree directory :validate t :if-does-not-exist :ignore)))
  (format t "Dreyeck Git source-slice Topicmap test passed.~%")
  t)


(defun run-git-repository-topicmap-smoke-tests ()
  (let ((directory (make-fixture-directory)))
    (unwind-protect
        (progn
         (initialize-git-fixture directory)
         (let* ((repository
                 (make-instance 'dreyeck/git:git-repository-checkout :root
                                directory :root-source :test-fixture))
                (projection
                 (dreyeck/topicmap:topicmap-projection-of repository))
                (topics
                 (dreyeck/topicmap:topicmap-projection-topics-of projection))
                (associations
                 (dreyeck/topicmap:topicmap-projection-associations-of
                  projection))
                (repository-topic
                 (find repository topics :key
                       #'dreyeck/topicmap:topicmap-topic-object-of :test #'eq))
                (head-topic
                 (find-if
                  (lambda (topic)
                    (typep (dreyeck/topicmap:topicmap-topic-object-of topic)
                           'dreyeck/git:git-commit))
                  topics))
                (head
                 (and head-topic
                      (dreyeck/topicmap:topicmap-topic-object-of head-topic)))
                (association (first associations))
                (view-properties
                 (dreyeck/topicmap:topicmap-projection-view-properties-of
                  projection))
                (html
                 (dreyeck/inspector/topicmap:render-topicmap-html :native-svg
                                                                  projection))
                (views (html-inspector-views:all-views repository)))
           (check (typep projection 'dreyeck/topicmap:topicmap-projection)
                  "Expected a Topicmap projection, got ~S." projection)
           (check
            (eq repository
                (dreyeck/topicmap:topicmap-projection-source-of projection))
            "Projection source is not the fixture repository.")
           (check (= 2 (length topics))
                  "Expected exactly two repository topics, got ~S." topics)
           (check repository-topic
                  "No topic refers to the fixture repository object.")
           (check
            (eq repository
                (dreyeck/topicmap:topicmap-topic-object-of repository-topic))
            "Repository topic does not preserve repository identity.")
           (check head-topic "No Git commit topic was projected for HEAD.")
           (check (typep head 'dreyeck/git:git-commit)
                  "HEAD topic contains unexpected object ~S." head)
           (check (eq repository (dreyeck/git:git-commit-repository-of head))
                  "Projected HEAD commit does not refer to the fixture repository.")
           (check (= 40 (length (dreyeck/git:git-commit-hash-of head)))
                  "Projected HEAD does not have a full Git hash: ~S."
                  (dreyeck/git:git-commit-hash-of head))
           (check (= 1 (length associations))
                  "Expected exactly one repository association, got ~S."
                  associations)
           (check
            (eq :current-head
                (dreyeck/topicmap:topicmap-association-type-of association))
            "Unexpected repository association type ~S."
            (dreyeck/topicmap:topicmap-association-type-of association))
           (check
            (string= (dreyeck/topicmap:topicmap-topic-id-of repository-topic)
                     (dreyeck/topicmap:topicmap-association-from-of
                      association))
            "CURRENT-HEAD does not start at the repository topic.")
           (check
            (string= (dreyeck/topicmap:topicmap-topic-id-of head-topic)
                     (dreyeck/topicmap:topicmap-association-to-of association))
            "CURRENT-HEAD does not end at the HEAD commit topic.")
           (check
            (string= (dreyeck/topicmap:topicmap-topic-id-of repository-topic)
                     (getf view-properties :point))
            "Repository topic is not the projection point.")
           (check (string= (namestring directory) (getf view-properties :root))
                  "Projection root ~S does not match fixture root ~S."
                  (getf view-properties :root) directory)
           (check
            (let ((branch (getf view-properties :branch)))
              (and (stringp branch) (plusp (length branch))))
            "Projection does not expose the fixture branch: ~S."
            (getf view-properties :branch))
           (check
            (search (dreyeck/topicmap:topicmap-topic-id-of repository-topic)
                    html :test #'char-equal)
            "Native SVG does not contain the repository topic.")
           (check
            (search (dreyeck/topicmap:topicmap-topic-id-of head-topic) html
                    :test #'char-equal)
            "Native SVG does not contain the HEAD topic.")
           (check (search "CURRENT-HEAD" html :test #'char-equal)
                  "Native SVG does not render the CURRENT-HEAD relation.")
           (check
            (search "dreyeck-topicmap-point-sign" html :test #'char-equal)
            "Native SVG does not render the repository point sign.")
           (check
            (some
             (lambda (view)
               (string= "Topicmap" (html-inspector-views:view-title view)))
             views)
            "Repository Inspector does not expose the Topicmap view.")))
      (uiop/filesystem:delete-directory-tree directory :validate t
                                             :if-does-not-exist :ignore)))
  (run-git-source-slice-topicmap-test)
  (format t "Dreyeck Git repository Topicmap smoke tests passed.~%")
  t)
