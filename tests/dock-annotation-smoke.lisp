;;;; Smoke tests for pane-local Dock annotations
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-DOCK-ANNOTATION-SMOKE-TESTS" :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun dock-annotation-source-json (context-object-id label value)
  (format nil
          "{\"providerKind\":\"dom-v1\",\"viewKind\":\"content\",\"viewTitle\":\"Main page\",\"contextObjectId\":~S,\"strategy\":\"list-item-anchor\",\"value\":~S,\"label\":~S,\"durabilityTier\":\"medium\",\"durabilityNote\":\"List-item anchors resolve to heading scope plus list and item position.\"}"
          context-object-id
          value
          label))

(defun dock-annotation-target-json (context-object-id)
  (format nil
          "{\"providerKind\":\"dock-v1\",\"viewKind\":\"dock-target\",\"viewTitle\":\"Main page\",\"contextObjectId\":~S,\"strategy\":\"annotation-topic\",\"value\":\"dock-annotation\",\"label\":\"Annotation\",\"durabilityTier\":\"strong\",\"durabilityNote\":\"The generic Annotation target is a synthetic authored anchor that classifies the relation as an annotation.\",\"objectId\":\"dock-annotation\"}"
          context-object-id))

(defun run-dock-annotation-smoke-tests ()
  (clrhash hyperdoc::*dock-annotations*)
  (let* ((hyperdoc-page (hyperdoc::find-page hyperdoc::*hyperdoc* "HyperDoc"
                                             :signal-error? t))
         (chunk-page (hyperdoc::find-page hyperdoc::*topics* "Chunk" :signal-error? t))
         (chunk-topic (hyperdoc::topic-of chunk-page))
         (shortcut-from-page
          (hyperdoc::dock-annotation-for-context
           chunk-page
           :context-view-title "Content"))
         (shortcut-from-page-again
          (hyperdoc::dock-annotation-for-context
           chunk-page
           :context-view-title "Content"))
         (shortcut-from-topic
          (hyperdoc::dock-annotation-for-context
           chunk-topic
           :context-view-title "Topic"))
         (text-pages-source-json
          (dock-annotation-source-json "HYPERDOC"
                                       "Text pages"
                                       "list-item:main-page/text-pages"))
         (text-pages-source-anchor
          (hyperdoc::maybe-dom-connect-anchor-from-json-string
           text-pages-source-json))
         (operation-route-from-helper
          (hyperdoc::create-or-open-operation-route
           text-pages-source-anchor
           (hyperdoc::annotation-topic)
           :context-object hyperdoc-page
           :context-view-title "Main page"))
         (annotation-from-connect
          (hyperdoc::make-association-annotation-from-json
           :context-object hyperdoc-page
           :context-view-title "Main page"
           :source-json text-pages-source-json
           :target-json (dock-annotation-target-json "HYPERDOC")))
         (annotation-from-connect-again
          (hyperdoc::make-association-annotation-from-json
           :context-object hyperdoc-page
           :context-view-title "Main page"
           :source-json text-pages-source-json
           :target-json (dock-annotation-target-json "HYPERDOC"))))
    (assert-true (typep shortcut-from-page 'hyperdoc::dock-annotation)
                 "Dock Annotation should specialize dom-relation-annotation rather than introducing a parallel annotation substrate")
    (assert-true (typep annotation-from-connect 'hyperdoc::dock-annotation)
                 "Connecting a source anchor to Annotation should reify to the same dock-annotation relation object used by the Dock shortcut")
    (assert-true (eq shortcut-from-page shortcut-from-page-again)
                 "Reopening Annotation for the same current pane object should reuse the existing inspectable object")
    (assert-true (eq shortcut-from-page shortcut-from-topic)
                 "Topic pages and their underlying topic objects should reopen the same current-object annotation relation")
    (assert-true (eq annotation-from-connect annotation-from-connect-again)
                 "Connecting the same source anchor to Annotation twice should reopen the existing relation instead of duplicating it")
    (assert-true (hyperdoc::station-p text-pages-source-anchor)
                 "A selected DOM anchor should be accepted as a mobile route station")
    (assert-true (hyperdoc::operation-station-p (hyperdoc::annotation-topic))
                 "Annotation should be accepted as a destination operation station")
    (assert-equal :safe
                  (hyperdoc::route-safety-level
                   text-pages-source-anchor
                   (hyperdoc::annotation-topic)
                   :context-object hyperdoc-page)
                  "Annotation operation routes should be safe direct-open routes")
    (assert-true (eq operation-route-from-helper annotation-from-connect)
                 "The route vocabulary helper should reopen the same source -> Annotation route object")
    (assert-equal "annotation"
                  (hyperdoc::relation-kind-of annotation-from-connect)
                  "Dock annotations should use the generic relation-kind classification slot")
    (assert-equal "Main page"
                  (hyperdoc::context-view-title-of annotation-from-connect)
                  "Source -> Annotation connect should preserve the originating pane view title")
    (assert-true (eq (hyperdoc::target-object-of annotation-from-connect)
                     (hyperdoc::annotation-topic))
                 "Connected annotations should use the generic Annotation topic as their target object")
    (assert-equal "Text pages"
                  (hyperdoc::label-of
                   (hyperdoc::source-anchor-of annotation-from-connect))
                  "The selected source anchor should remain the thing being annotated")
    (assert-true (eq (hyperdoc::source-object-of shortcut-from-page)
                     chunk-topic)
                 "The current-object shortcut should still annotate the current topic object through the same source -> Annotation relation model")
    (assert-true (search "Text pages" (hyperdoc::note-of annotation-from-connect))
                 "Source -> Annotation relations should prefill the note field with source-specific context")
    (hyperdoc::with-zotero-support-mode (:disabled)
      (assert-true (not (hyperdoc::dock-zotero-capability-available-p chunk-page))
                   "The Dock should still exist when Zotero is disabled, but Zotero itself must remain an optional capability")))
  (format t "~&Dock annotation smoke tests passed.~%")
  t)
