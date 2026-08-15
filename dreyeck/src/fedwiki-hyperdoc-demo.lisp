;;;; Executable HyperDoc demonstration of local FedWiki HyperDoc activation

(defpackage #:dreyeck/fedwiki-hyperdoc-demo
  (:use #:cl)
  (:export
   #:*fedwiki-hyperdoc-demo*))

(in-package #:dreyeck/fedwiki-hyperdoc-demo)

(hyperdoc:defhyperdoc *fedwiki-hyperdoc-demo*
  :title "From a FedWiki page to an inspectable HyperDoc"
  :id "dreyeck/fedwiki-hyperdoc-demo"
  :asdf-system-name "dreyeck/fedwiki-hyperdoc-demo"
  :subdirectory "dreyeck/pages/fedwiki-hyperdoc-demo"
  :main-page-id "From a FedWiki page to an inspectable HyperDoc")
