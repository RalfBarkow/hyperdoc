;; Local Federated Wiki asset discovery

(defpackage #:dreyeck/fedwiki-assets
  (:use #:cl)
  (:export
   #:local-fedwiki-page-pathname
   #:read-local-fedwiki-page
   #:assets-story-items
   #:assets-reference-of
   #:local-fedwiki-assets-root
   #:resolve-local-assets
   #:discover-asdf-files
   #:discover-page-attached-asdf-files
   #:page-attached-asdf-discovery-observation))

(in-package #:dreyeck/fedwiki-assets)
