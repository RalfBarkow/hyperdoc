(defpackage #:dreyeck/fedwiki-hyperdoc
  (:use #:cl)
  (:export
   #:page-attached-asdf-under-assets-root-p
   #:direct-hyperdoc-presentation-candidates
   #:hyperdocs-for-asdf-systems
   #:activate-local-fedwiki-page-hyperdoc
   #:activate-page-attached-hyperdoc-from-assets))

(in-package #:dreyeck/fedwiki-hyperdoc)
