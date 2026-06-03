;;;; HyperDoc authored topic family for layout-as-topicmap editing.

(in-package :hyperdoc)

(defun layout-as-topicmap-topic ()
  (make-topic
   :id "layout-as-topicmap"
   :title "Layout as Topicmap"
   :summary "Inspector layout can be represented as first-class layout topics and relations so visible chrome moves create inspectable patches before renderer mutation."
   :references '("Layout as Topicmap"
                 "hyperdoc/layout-topicmap.lisp"
                 "hyperdoc-explorer/layout-topicmap.lisp"
                 "tests/layout-topicmap-smoke.lisp"
                 "tests/playwright/layout-topicmap.spec.js")))

(defun inspector-reel-layout-topicmap-topic ()
  (make-topic
   :id "inspector-reel-layout-topicmap"
   :title "Inspector Reel layout topicmap"
   :summary "Static first-slice layout snapshot for the HyperDoc Reel subset: reel, viewport, controls, native scroll container, and inspector pane."
   :references '("Layout as Topicmap"
                 "The Reel as Accessible Carousel"
                 "hyperdoc/layout-topicmap.lisp"
                 "assets/hyperdoc/js/layout-topicmap.js")))

(defun move-topic-into-box-patch-topic ()
  (make-topic
   :id "move-topic-into-box-patch"
   :title "move-topic-into-box-patch"
   :summary "Inspectable layout patch that moves a topic from one containment parent to another while preserving before topology, after topology, evidence, and preview/apply policy."
   :references '("Layout as Topicmap"
                 "hyperdoc/layout-topicmap.lisp"
                 "hyperdoc-explorer/layout-topicmap.lisp"
                 "tests/layout-topicmap-smoke.lisp")))
