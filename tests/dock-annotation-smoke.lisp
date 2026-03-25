;;;; Smoke tests for pane-local Dock annotations
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-DOCK-ANNOTATION-SMOKE-TESTS" :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun run-dock-annotation-smoke-tests ()
  (clrhash hyperdoc::*dock-annotations*)
  (let* ((chunk-page (hyperdoc::find-page hyperdoc::*topics* "Chunk" :signal-error? t))
         (chunk-topic (hyperdoc::topic-of chunk-page))
         (annotation-from-page
           (hyperdoc::dock-annotation-for-context
            chunk-page
            :context-view-title "Content"))
         (annotation-from-page-again
           (hyperdoc::dock-annotation-for-context
            chunk-page
            :context-view-title "Content"))
         (annotation-from-topic
           (hyperdoc::dock-annotation-for-context
            chunk-topic
            :context-view-title "Topic")))
    (assert-true (typep annotation-from-page 'hyperdoc::dock-annotation)
                 "Dock Annotation should specialize dom-relation-annotation rather than introducing a parallel annotation substrate")
    (assert-true (eq annotation-from-page annotation-from-page-again)
                 "Reopening Annotation for the same current pane object should reuse the existing inspectable object")
    (assert-true (eq annotation-from-page annotation-from-topic)
                 "Topic pages and their underlying topic objects should reopen the same generic annotation target in this slice")
    (assert-equal "annotation"
                  (hyperdoc::relation-kind-of annotation-from-page)
                  "Dock annotations should use the generic relation-kind classification slot")
    (assert-equal "Content"
                  (hyperdoc::context-view-title-of annotation-from-page)
                  "The first opened Dock annotation should preserve the originating pane view title")
    (assert-true (eq (hyperdoc::target-object-of annotation-from-page)
                     chunk-topic)
                 "The generic Annotation target should be the current topic object for a topic page context")
    (assert-true (eq (hyperdoc::source-object-of annotation-from-page)
                     (hyperdoc::annotation-topic))
                 "Dock annotations should point back to the generic Annotation topic object")
    (assert-true (search "Chunk" (hyperdoc::note-of annotation-from-page))
                 "Dock annotations should prefill the note field with target-specific context")
    (hyperdoc::with-zotero-support-mode (:disabled)
      (assert-true (not (hyperdoc::dock-zotero-capability-available-p chunk-page))
                   "The Dock should still exist when Zotero is disabled, but Zotero itself must remain an optional capability")))
  (format t "~&Dock annotation smoke tests passed.~%")
  t)
