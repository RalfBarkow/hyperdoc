;;;; The Task 1E Re-pin Review's Package
(in-package #:cl-user)

(defpackage #:topic-maps-task-1e-review
  (:use #:cl)
  (:local-nicknames (#:v #:html-inspector-views) (#:snap #:dreyeck/source-snapshot) (#:p #:dreyeck/work/project))
  (:export #:+book-id+ #:+commit+ #:+parent-commit+ #:review-page #:record #:records #:record-file #:record-text #:record-intact-p
           #:record-sha256 #:recorded-sha256 #:pins #:the-pins #:pin-rows #:pin-row-pin #:pin-row-where))
