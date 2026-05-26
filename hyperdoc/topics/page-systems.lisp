;;;; Page-system topic cluster.

(in-package :hyperdoc)

(defun page-system-topic ()
  (make-topic
   :id "page-system"
   :title "Page system"
   :summary "A reloadable presentation boundary that connects one page to the ASDF systems, runtime providers, inspection targets, and validation checks needed to display it."
   :references '("Page systems as ASDF reload boundaries"
                 "Mobile progressive chrome in HyperDoc")))

(defun page-system-asdf-boundary-topic ()
  (make-topic
   :id "page-system-asdf-boundary"
   :title "Page system ASDF boundary"
   :summary "ASDF load boundary that re-provides display and inspection runtime for a page without making the page system an implementation ownership boundary."
   :references '("Page systems as ASDF reload boundaries"
                 "ASDF system"
                 "hyperdoc.asd")))

(defun page-runtime-provider-topic ()
  (make-topic
   :id "page-runtime-provider"
   :title "Page runtime provider"
   :summary "Inspectable provider object describing the ASDF system, ensure operation, readiness condition, and display notes for one runtime layer used by page systems."
   :references '("Page systems as ASDF reload boundaries"
                 "hyperdoc/page-systems.lisp")))

(defun hyperdoc-page-system-topic ()
  (make-topic
   :id "hyperdoc-page-system"
   :title "HyperDoc page system"
   :summary "Page-system specialization for authored HyperDoc pages whose ASDF boundary reloads the HyperDoc and inspector runtime needed to inspect the page."
   :references '("Page systems as ASDF reload boundaries"
                 "Mobile progressive chrome in HyperDoc"
                 "DM6 AppEmbed HyperDoc Inline Proof")))

(defun fedwiki-page-system-topic ()
  (make-topic
   :id "fedwiki-page-system"
   :title "FedWiki page system"
   :summary "Page-system specialization for FedWiki pages whose ASDF boundary reloads FedWiki rendering and local materialization helpers without requiring live network access."
   :references '("Page systems as ASDF reload boundaries"
                 "fedwiki:wiki.ralfbarkow.ch/mobile-progressive-chrome-in-hyperdoc")))

(defun fedwiki-attached-asdf-system-topic ()
  (make-topic
   :id "fedwiki-attached-asdf-system"
   :title "FedWiki-attached ASDF system"
   :summary "Inspectable system-home object that resolves a FedWiki page identity to local page assets, an exact ASDF entrypoint, ASDF system state, actions, tests, an Examples view, and lookup recovery routes."
   :references '("FedWiki-attached ASDF system"
                 "Running HyperDoc Examples"
                 "Kioskbeerli"
                 "hyperdoc/fedwiki-attached-asdf-system.lisp"
                 "hyperdoc-inspector/fedwiki-attached-asdf-system.lisp")))

(defun page-display-contract-topic ()
  (make-topic
   :id "page-display-contract"
   :title "Page display contract"
   :summary "Inspectable set of display expectations that a page-system reload report checks after ASDF reloads the page runtime."
   :references '("Page systems as ASDF reload boundaries"
                 "hyperdoc/page-systems.lisp"
                 "tests/page-system-smoke.lisp")))

(defun page-reload-report-topic ()
  (make-topic
   :id "page-reload-report"
   :title "Page reload report"
   :summary "Inspectable result object returned by page-system-reload, recording the ASDF system loaded, readiness status, and display-contract warnings."
   :references '("Page systems as ASDF reload boundaries"
                 "hyperdoc/page-systems.lisp"
                 "tests/page-system-smoke.lisp")))

(defun shop3-page-as-asdf-system-topic ()
  (make-topic
   :id "shop3-page-as-asdf-system"
   :title "SHOP3 page as ASDF system"
   :summary "FedWiki SHOP3 page represented as an ASDF-backed page system that reloads both the FedWiki display runtime and the external SHOP3 HTN planner runtime."
   :references '("SHOP3 page as ASDF system"
                 "Page systems as ASDF reload boundaries"
                 "fedwiki:wiki.ralfbarkow.ch/shop3")))

(defun shop3-runtime-provider-topic ()
  (make-topic
   :id "shop3-runtime-provider"
   :title "SHOP3 runtime provider"
   :summary "External runtime provider that makes the open-source SHOP3 Common Lisp HTN planner available to page-system reloads through ASDF."
   :references '("SHOP3 page as ASDF system"
                 "https://github.com/shop-planner/shop3"
                 "hyperdoc/page-systems.lisp")))

(defun shop3-fedwiki-page-system-topic ()
  (make-topic
   :id "shop3-fedwiki-page-system"
   :title "SHOP3 FedWiki page system"
   :summary "The page-system instance named fedwiki/page/wiki.ralfbarkow.ch/shop3 for the localhost FedWiki SHOP3 page."
   :references '("SHOP3 page as ASDF system"
                 "fedwiki.asd"
                 "hyperdoc/page-systems/fedwiki-shop3.lisp")))

(defun external-runtime-provider-topic ()
  (make-topic
   :id "external-runtime-provider"
   :title "External runtime provider"
   :summary "Page-runtime provider whose ASDF system and source provenance come from an external open-source project rather than HyperDoc-owned runtime code."
   :references '("Page systems as ASDF reload boundaries"
                 "SHOP3 page as ASDF system"
                 "hyperdoc/page-systems.lisp")))

(defun htn-planner-runtime-topic ()
  (make-topic
   :id "htn-planner-runtime"
   :title "HTN planner runtime"
   :summary "Common Lisp runtime for Hierarchical Task Network planning, loaded explicitly for page systems that need planner objects inspectable in HyperDoc."
   :references '("SHOP3 page as ASDF system"
                 "SHOP3 Planning Layer for HyperDoc"
                 "https://github.com/shop-planner/shop3")))

(defun page-system-with-external-lisp-dependency-topic ()
  (make-topic
   :id "page-system-with-external-lisp-dependency"
   :title "Page system with external Lisp dependency"
   :summary "Page-system pattern where ASDF reload re-provides a page plus a non-HyperDoc Common Lisp system required to inspect the page's domain runtime."
   :references '("SHOP3 page as ASDF system"
                 "Page systems as ASDF reload boundaries"
                 "hyperdoc/page-systems.lisp")))
