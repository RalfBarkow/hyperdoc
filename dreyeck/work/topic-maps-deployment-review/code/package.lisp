;;;; The Review's Package
(in-package #:cl-user)

(defpackage #:topic-maps-deployment-review
  (:use #:cl)
  (:local-nicknames (#:v #:html-inspector-views) (#:git #:dreyeck/git) (#:snap #:dreyeck/source-snapshot)
                    (#:c #:dreyeck/catalog-topic-maps) (#:tm #:dreyeck/topicmap) (#:tmi #:dreyeck/inspector/topicmap)
                    (#:ap #:dreyeck/authority-policy) (#:ex #:dreyeck/work/topic-maps-project-example))
  (:export #:+book-id+ #:+base-commit+ #:+candidate-paths+ #:review-page
           #:candidate #:the-candidate #:candidate-files #:candidate-file #:file-named #:file-path #:file-kind
           #:file-sha256-now #:file-tested-sha256 #:file-state #:file-matches-tested-p #:declared-paths-agree-p #:+reviewed-head+
           #:review-reading-paths
           #:source-excerpt #:excerpt #:excerpt-key #:excerpt-text #:excerpts
           #:recorded-evidence #:evidence #:evidence-file #:evidence-kind #:evidence-outcomes #:all-evidence
           #:review-claim #:claim #:claim-id #:claim-statement #:claim-class #:claim-evidence #:claim-sources #:claims
           #:review-workspace #:the-workspace #:warranted-association #:association-provenance #:association-evidence
           #:association-class #:subject-object
           #:verification-runner #:the-verification-runner #:guard-trial #:the-guard-trial #:runner-runs
           #:verify-snapshot-now #:try-project-workspace-under-guard #:topic-maps-origins-now))
