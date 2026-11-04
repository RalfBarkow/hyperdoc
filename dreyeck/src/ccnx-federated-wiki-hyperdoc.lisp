;;;; HyperDoc registration for the CCNx Federated Wiki reading.

(in-package #:dreyeck/ccnx-federated-wiki)

(dreyeck/hyperdoc:defhyperdoc *ccnx-federated-wiki-hyperdoc*
  :title "The CCNx Federated Wiki"
  :id "dreyeck/ccnx-federated-wiki"
  :asdf-system-name "dreyeck/ccnx-federated-wiki"
  :subdirectory "dreyeck/pages/ccnx-federated-wiki"
  :main-page-id "Reading the CCNx Federated Wiki")

;;; The reading's own style sheet. It is added to the assets that every HyperDoc page gets, for this book's pages only, and every rule in it is
;;; scoped to the .ccnx-reading wrapper of the four pages (dreyeck/ccnx-federated-wiki/assets/ccnx-reading/css/reading.css). The directory is named
;;; like the URL prefix: the Catalog server resolves a plugin path against the parent of the directory it is given.
(defvar *reading-html-page-assets*
  (make-instance 'hyperbook:html-page-assets
                 :inherit hyperdoc::*hyperdoc-html-page-assets*
                 :paths (list (cons "/ccnx-reading/"
                                    (asdf:system-relative-pathname "dreyeck/ccnx-federated-wiki"
                                                                   "dreyeck/ccnx-federated-wiki/assets/ccnx-reading/")))
                 :css '("/ccnx-reading/css/reading.css")))

(defmethod hyperbook:html-page-assets-of ((book (eql *ccnx-federated-wiki-hyperdoc*)))
  *reading-html-page-assets*)
