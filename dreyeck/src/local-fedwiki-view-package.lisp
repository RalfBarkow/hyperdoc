(defpackage #:dreyeck/local-fedwiki-view
  (:use #:cl)
  (:export
   #:*default-wiki-id*
   #:configured-site-root
   #:view-slug-from-pathname
   #:make-local-fedwiki-view-page
   #:install-local-fedwiki-view-route
   #:serve-catalog-with-local-fedwiki-view))

(in-package #:dreyeck/local-fedwiki-view)
