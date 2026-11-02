;;;; Package for the Inspector views of the upstream assessment.

(defpackage #:dreyeck/inspector/upstream-assessment
  (:use #:cl)
  (:local-nicknames (#:ua #:dreyeck/upstream-assessment) (#:v #:html-inspector-views) (#:tm #:dreyeck/topicmap))
  (:export #:change-chain-workspace #:chain-step #:chain-step-label #:chain-step-object #:chain-steps #:claim-status-label))
