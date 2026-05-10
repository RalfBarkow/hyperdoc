;;;; Inspector views for the Git comparison plan.
;;;; Created from SLY MREPL; reload this file instead of redefining ad hoc.

(in-package :hyperdoc/inspector)

(defun render-plan-row (label value)
  (html-inspector-views:html
    (:tr
     (:td (:b (html-inspector-views:esc label)))
     (:td (html-inspector-views:esc value)))))

(defun render-plan-list (&rest lines)
  (html-inspector-views:html
    (:ul
     (dolist (line lines)
       (html-inspector-views:html
         (:li (html-inspector-views:esc line)))))))

(defmethod html-inspector-views:text-representation
    ((plan hyperdoc::git-comparison-plan))
  (hyperdoc::git-comparison-plan-title-of plan))

(html-inspector-views:defview 👀situation
    (plan hyperdoc::git-comparison-plan)
  (html-inspector-views:html-view :title "Situation" :priority 1
    (html-inspector-views:html
      (:h2 (html-inspector-views:esc "Konrad upstream/main → hauptsache"))

      (:table :class "inspector-table"
              (render-plan-row
               "Konrad is working on"
               "shared HyperBook/HyperDoc core: link routing, explorer rendering, FedWiki, Wikipedia, server/runtime correctness")
              (render-plan-row
               "This affects us in"
               "shared core files that hauptsache also extended")
              (render-plan-row
               "Our codebase adds"
               "dreyeck deployment, local documentation, inspector/debugging surfaces, DMX/Zotero/SCXML/topic tooling")
              (render-plan-row
               "Comparison basis"
               (hyperdoc::git-comparison-plan-comparison-command plan)))

      (:p
       (html-inspector-views:esc
        "The question is not 'merge everything'. The question is which upstream core changes should become the new baseline, and which hauptsache behavior must remain local or be replayed on top.")))))

(html-inspector-views:defview 👀impact
    (plan hyperdoc::git-comparison-plan)
  (html-inspector-views:html-view :title "Impact" :priority 2
    (declare (ignore plan))
    (html-inspector-views:html
      (:h3 (html-inspector-views:esc "Expected impact on hauptsache"))

      (:table :class "inspector-table"
              (render-plan-row
               "Low risk"
               "upstream-only helper files and generated/support files; accept or keep outside runtime load path")
              (render-plan-row
               "Needs review"
               "shared core files touched by both sides: package definitions, explorer rendering, FedWiki pages, Wikipedia integration")
              (render-plan-row
               "Keep local"
               "dreyeck, local HyperDoc pages, DMX workspace/topic tooling, Zotero/topic enrichment, SCXML/state-machine surfaces")
              (render-plan-row
               "Merge rule"
               "upstream core first; replay hauptsache inspectors or UI affordances only where they are still useful"))

      (:h3 (html-inspector-views:esc "Concrete known examples"))
      (render-plan-list
       "hyperbook-wikipedia/list-wikipedia-editions.lisp: take upstream helper verbatim; it stays outside the runtime path."
       "hyperbook-wikipedia/wikipedia.lisp: upstream correctness baseline; replay hauptsache languages inspector if still needed."
       "hyperbook-fedwiki/pages.lisp: upstream transport/context baseline; replay hauptsache UI affordance if still needed."
       "hyperbook-explorer/rendering.lisp and package.lisp: inspect carefully; likely real splice points."))))

(html-inspector-views:defview 👀next
    (plan hyperdoc::git-comparison-plan)
  (html-inspector-views:html-view :title "Next" :priority 3
    (html-inspector-views:html
      (:h3 (html-inspector-views:esc "Next object to build"))

      (:table :class "inspector-table"
              (render-plan-row
               "Object"
               "git-tree-comparison")
              (render-plan-row
               "Command"
               (hyperdoc::git-comparison-plan-comparison-command plan))
              (render-plan-row
               "Views"
               "Overview, Upstream changes, Hauptsache changes, Overlap")
              (render-plan-row
               "Row behavior"
               "each path row opens an inspectable path-delta object"))

      (:h3 (html-inspector-views:esc "Do not do yet"))
      (render-plan-list
       "Do not run the merge yet."
       "Do not classify files from raw Git output alone."
       "Do not let Repomix be the primary comparison substrate."))))

(html-inspector-views:defview 👀evidence
    (plan hyperdoc::git-comparison-plan)
  (html-inspector-views:html-view :title "Evidence" :priority 4
    (let ((preflight
            (hyperdoc::git-comparison-plan-preflight-of plan)))
      (html-inspector-views:html
        (:p
         (html-inspector-views:esc
          "Supporting evidence. Use this only when the refs or merge base look suspicious."))

        (if preflight
            (html-inspector-views:object-ref preflight)
            (html-inspector-views:esc
             "No preflight object is available in this image."))))))
