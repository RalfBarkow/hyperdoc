;;;; The Integration Review's Package
(in-package #:cl-user)

(defpackage #:topic-maps-integration-review
  (:use #:cl)
  (:local-nicknames (#:v #:html-inspector-views) (#:git #:dreyeck/git) (#:snap #:dreyeck/source-snapshot)
                    (#:c #:dreyeck/catalog-topic-maps) (#:tm #:dreyeck/topicmap) (#:tmi #:dreyeck/inspector/topicmap)
                    (#:p #:dreyeck/work/project))
  (:export #:+book-id+ #:+reviewed-commit+ #:+baseline-commit+ #:+sibling-commit+ #:review-page
           #:record #:records #:record-file #:record-text #:record-outcomes #:record-intact-p #:record-sha256 #:recorded-sha256
           #:review-claim #:claim #:claims #:claim-id #:claim-statement #:claim-class #:claim-evidence #:claim-limit
           #:the-workspace #:subject-object #:integration-association #:association-class #:association-provenance #:association-evidence
           #:performance #:the-performance #:performance-rows #:topic-maps-source #:the-topic-maps-source #:source-facts
           #:identify-topic-maps-source-now #:ask-whether-project-workspace-is-refused #:read-project-ctm-now
           #:source-run #:guard-run #:read-run #:runs
           #:commit-boundary #:boundaries #:boundary #:boundary-id #:boundary-files #:boundary-hunks #:boundary-all-files #:boundary-depends-on #:boundary-file-identity #:boundary-present-p
           #:proposed-object #:file-line #:repository-root))
