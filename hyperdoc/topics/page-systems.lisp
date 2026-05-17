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
