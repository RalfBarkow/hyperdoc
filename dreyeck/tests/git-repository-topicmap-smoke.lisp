(in-package #:dreyeck/git/tests)

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
  (format t "Dreyeck Git repository Topicmap smoke tests passed.~%")
  t)
