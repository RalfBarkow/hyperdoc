(defpackage #:dreyeck/issue/tests
  (:use #:cl)
  (:export #:run-issue-work-context-topicmap-smoke-tests))

(in-package #:dreyeck/issue/tests)

(defun dreyeck/issue/tests:run-issue-work-context-topicmap-smoke-tests ()
  (let ((directory (dreyeck/git/tests::make-fixture-directory)))
    (unwind-protect
        (progn
         (dreyeck/git/tests::initialize-git-fixture directory)
         (let* ((dreyeck/issue/tests::repository
                 (make-instance 'dreyeck/git:git-repository-checkout :root
                                directory :root-source :test-fixture))
                (dreyeck/issue/tests::issue
                 (make-instance 'dreyeck/issue:issue-reference :forge
                                "github.com" :owner "Zettelkasten-Team"
                                :repository "Zettelkasten" :number 541))
                (dreyeck/issue/tests::context
                 (dreyeck/issue:make-issue-work-context
                  dreyeck/issue/tests::repository dreyeck/issue/tests::issue))
                (dreyeck/issue/tests::projection
                 (dreyeck/topicmap:topicmap-projection-of
                  dreyeck/issue/tests::context))
                (dreyeck/issue/tests::topics
                 (dreyeck/topicmap:topicmap-projection-topics-of
                  dreyeck/issue/tests::projection))
                (dreyeck/issue/tests::associations
                 (dreyeck/topicmap:topicmap-projection-associations-of
                  dreyeck/issue/tests::projection))
                (dreyeck/issue/tests::repository-topic
                 (find dreyeck/issue/tests::repository
                       dreyeck/issue/tests::topics :key
                       #'dreyeck/topicmap:topicmap-topic-object-of :test #'eq))
                (dreyeck/issue/tests::head-topic
                 (find-if
                  (lambda (dreyeck/issue/tests::topic)
                    (typep
                     (dreyeck/topicmap:topicmap-topic-object-of
                      dreyeck/issue/tests::topic)
                     'dreyeck/git:git-commit))
                  dreyeck/issue/tests::topics))
                (dreyeck/issue/tests::head
                 (and dreyeck/issue/tests::head-topic
                      (dreyeck/topicmap:topicmap-topic-object-of
                       dreyeck/issue/tests::head-topic)))
                (dreyeck/issue/tests::association
                 (first dreyeck/issue/tests::associations))
                (dreyeck/issue/tests::view-properties
                 (dreyeck/topicmap:topicmap-projection-view-properties-of
                  dreyeck/issue/tests::projection))
                (dreyeck/issue/tests::html
                 (dreyeck/inspector/topicmap:render-topicmap-html :native-svg
                                                                  dreyeck/issue/tests::projection))
                (dreyeck/issue/tests::views
                 (html-inspector-views:all-views dreyeck/issue/tests::context))
                (dreyeck/issue/tests::issue-topic
                 (find dreyeck/issue/tests::issue dreyeck/issue/tests::topics
                       :key #'dreyeck/topicmap:topicmap-topic-object-of :test
                       #'eq))
                (dreyeck/issue/tests::tracks-association
                 (find :tracks dreyeck/issue/tests::associations :key
                       #'dreyeck/topicmap:topicmap-association-type-of :test
                       #'eq)))
           (dreyeck/git/tests::check
            (typep dreyeck/issue/tests::projection
                   'dreyeck/topicmap:topicmap-projection)
            "Expected a Topicmap projection, got ~S."
            dreyeck/issue/tests::projection)
           (dreyeck/git/tests::check
            (eq dreyeck/issue/tests::context
                (dreyeck/topicmap:topicmap-projection-source-of
                 dreyeck/issue/tests::projection))
            "Projection source is not the issue work context.")
           (dreyeck/git/tests::check (= 3 (length dreyeck/issue/tests::topics))
                                     "Expected repository, HEAD, and issue topics, got ~S."
                                     dreyeck/issue/tests::topics)
           (dreyeck/git/tests::check dreyeck/issue/tests::repository-topic
                                     "No topic refers to the fixture repository object.")
           (dreyeck/git/tests::check
            (eq dreyeck/issue/tests::repository
                (dreyeck/topicmap:topicmap-topic-object-of
                 dreyeck/issue/tests::repository-topic))
            "Repository topic does not preserve repository identity.")
           (dreyeck/git/tests::check dreyeck/issue/tests::head-topic
                                     "No Git commit topic was projected for HEAD.")
           (dreyeck/git/tests::check
            (typep dreyeck/issue/tests::head 'dreyeck/git:git-commit)
            "HEAD topic contains unexpected object ~S."
            dreyeck/issue/tests::head)
           (dreyeck/git/tests::check
            (eq dreyeck/issue/tests::repository
                (dreyeck/git:git-commit-repository-of
                 dreyeck/issue/tests::head))
            "Projected HEAD commit does not refer to the fixture repository.")
           (dreyeck/git/tests::check
            (= 40
               (length
                (dreyeck/git:git-commit-hash-of dreyeck/issue/tests::head)))
            "Projected HEAD does not have a full Git hash: ~S."
            (dreyeck/git:git-commit-hash-of dreyeck/issue/tests::head))
           (dreyeck/git/tests::check
            (= 2 (length dreyeck/issue/tests::associations))
            "Expected CURRENT-HEAD and TRACKS associations, got ~S."
            dreyeck/issue/tests::associations)
           (dreyeck/git/tests::check
            (eq :current-head
                (dreyeck/topicmap:topicmap-association-type-of
                 dreyeck/issue/tests::association))
            "Unexpected repository association type ~S."
            (dreyeck/topicmap:topicmap-association-type-of
             dreyeck/issue/tests::association))
           (dreyeck/git/tests::check
            (string=
             (dreyeck/topicmap:topicmap-topic-id-of
              dreyeck/issue/tests::repository-topic)
             (dreyeck/topicmap:topicmap-association-from-of
              dreyeck/issue/tests::association))
            "CURRENT-HEAD does not start at the repository topic.")
           (dreyeck/git/tests::check
            (string=
             (dreyeck/topicmap:topicmap-topic-id-of
              dreyeck/issue/tests::head-topic)
             (dreyeck/topicmap:topicmap-association-to-of
              dreyeck/issue/tests::association))
            "CURRENT-HEAD does not end at the HEAD commit topic.")
           (dreyeck/git/tests::check
            (string=
             (dreyeck/topicmap:topicmap-topic-id-of
              dreyeck/issue/tests::repository-topic)
             (getf dreyeck/issue/tests::view-properties :point))
            "Repository topic is not the projection point.")
           (dreyeck/git/tests::check
            (string= (namestring directory)
                     (getf dreyeck/issue/tests::view-properties :root))
            "Projection root ~S does not match fixture root ~S."
            (getf dreyeck/issue/tests::view-properties :root) directory)
           (dreyeck/git/tests::check
            (let ((dreyeck/issue/tests::branch
                   (getf dreyeck/issue/tests::view-properties :branch)))
              (and (stringp dreyeck/issue/tests::branch)
                   (plusp (length dreyeck/issue/tests::branch))))
            "Projection does not expose the fixture branch: ~S."
            (getf dreyeck/issue/tests::view-properties :branch))
           (dreyeck/git/tests::check
            (search
             (dreyeck/topicmap:topicmap-topic-id-of
              dreyeck/issue/tests::repository-topic)
             dreyeck/issue/tests::html :test #'char-equal)
            "Native SVG does not contain the repository topic.")
           (dreyeck/git/tests::check
            (search
             (dreyeck/topicmap:topicmap-topic-id-of
              dreyeck/issue/tests::head-topic)
             dreyeck/issue/tests::html :test #'char-equal)
            "Native SVG does not contain the HEAD topic.")
           (dreyeck/git/tests::check
            (search "CURRENT-HEAD" dreyeck/issue/tests::html :test
                    #'char-equal)
            "Native SVG does not render the CURRENT-HEAD relation.")
           (dreyeck/git/tests::check
            (search "dreyeck-topicmap-point-sign" dreyeck/issue/tests::html
                    :test #'char-equal)
            "Native SVG does not render the repository point sign.")
           (dreyeck/git/tests::check
            (some
             (lambda (dreyeck/issue/tests::view)
               (string= "Topicmap"
                        (html-inspector-views:view-title
                         dreyeck/issue/tests::view)))
             dreyeck/issue/tests::views)
            "Repository Inspector does not expose the Topicmap view.")
           (dreyeck/git/tests::check dreyeck/issue/tests::issue-topic
                                     "No topic refers to the issue reference object.")
           (dreyeck/git/tests::check
            (eq :tracks
                (dreyeck/topicmap:topicmap-association-type-of
                 dreyeck/issue/tests::tracks-association))
            "TRACKS association was not projected for the issue."
            (dreyeck/topicmap:topicmap-association-type-of
             dreyeck/issue/tests::tracks-association))
           (dreyeck/git/tests::check
            (string= "Zettelkasten-Team/Zettelkasten#541"
                     (dreyeck/issue:issue-reference-coordinate
                      dreyeck/issue/tests::issue))
            "Unexpected issue coordinate.")))
      (uiop/filesystem:delete-directory-tree directory :validate t
                                             :if-does-not-exist :ignore)))
  (format t "Dreyeck issue work context Topicmap smoke tests passed.~%")
  t)
