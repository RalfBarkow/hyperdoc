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

(defun layout-repair-plan-topic ()
  (make-topic
   :id "layout-repair-plan"
   :title "layout-repair-plan"
   :summary "Inspectable rule-derived plan that records layout rule results, preview renderer effects, apply-phase durable override effects, evidence, and failure modes for a layout patch."
   :references '("Layout as Topicmap"
                 "hyperdoc/layout-topicmap.lisp"
                 "hyperdoc-explorer/layout-topicmap.lisp"
                 "assets/hyperdoc/js/layout-topicmap.js"
                 "tests/layout-topicmap-smoke.lisp"
                 "tests/playwright/layout-topicmap.spec.js")))

(defun layout-override-topic ()
  (make-topic
   :id "layout-override"
   :title "layout-override"
   :summary "Durable replay artifact created from an applied layout-repair-plan; it records the source patch, before/after topology, rule summaries, renderer effects, evidence, timestamp, and revert data."
   :references '("Layout as Topicmap"
                 "hyperdoc/layout-topicmap.lisp"
                 "hyperdoc-explorer/layout-topicmap.lisp"
                 "assets/hyperdoc/js/layout-topicmap.js"
                 "tests/layout-topicmap-smoke.lisp"
                 "tests/playwright/layout-topicmap.spec.js")))

(defun layout-override-store-topic ()
  (make-topic
   :id "layout-override-store"
   :title "layout-override-store"
   :summary "Explicit session replay boundary for persisted layout overrides; the browser inspector uses a small localStorage store keyed by hyperdoc.layout.overrides.v1."
   :references '("Layout as Topicmap"
                 "hyperdoc/layout-topicmap.lisp"
                 "assets/hyperdoc/js/layout-topicmap.js"
                 "tests/layout-topicmap-smoke.lisp"
                 "tests/playwright/layout-topicmap.spec.js")))
