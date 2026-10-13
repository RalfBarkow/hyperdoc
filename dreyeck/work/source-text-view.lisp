;;;; Shell source is text, never an execution request.
(in-package #:cl-user)

;; Reuse the existing pathname content dispatch and read-only CLOG Text view.
;; No shell-specific Inspector, process invocation or change to upstream methods.
(defmethod html-inspector-views/standard:file-content-view ((type (eql :sh)) pathname)
  (html-inspector-views/standard:file-content-view :txt pathname))
