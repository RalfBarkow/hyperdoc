;;;; dreyeck.ch-owned Lisp image inventory and observations.

(defpackage #:dreyeck/lisp-image
  (:use #:cl)
  (:export
   #:*lisp-image-hyperdoc*
   #:lisp-image-repository-state-example
   #:lisp-image-hauptsache-diff-example
   #:lisp-image-hauptsache-contract-example
   #:lisp-image-page-ownership-example
   
   #:current-lisp-hyperbooks-example
   #:current-lisp-hyperbook-views-example
   
   #:lisp-image-entry
   #:lisp-image-entry-kind
   #:lisp-image-entry-symbol
   #:lisp-image-entry-package-name
   #:lisp-image-entry-symbol-status
   #:lisp-image-entry-page-id

   #:lisp-image-inventory
   #:lisp-image-function-entries
   #:lisp-image-class-entries

   #:package-qualified-symbol-page-id
   #:collect-lisp-function-entries
   #:collect-lisp-class-entries
   #:make-lisp-image-inventory
   #:find-lisp-image-entry

   #:lisp-image-inventory-example
   #:lisp-image-inventory-summary-example
   #:lisp-function-inventory-transfer-example
   #:lisp-image-inventory-transfer-audit-example
   #:lisp-function-page-id-failures-example
   #:reader-safe-lisp-image-page-ids-example

   #:project-lisp-image-entry-to-page
   #:lisp-image-page-projection-example

   #:lisp-image-page-collection
   #:lisp-image-page-collection-kind
   #:lisp-image-page-collection-hyperbook
   #:lisp-image-page-collection-entries
   #:lisp-image-page-collection-pages
   #:project-lisp-image-entries-to-pages
   #:make-lisp-image-page-collection
   #:lisp-image-page-collections-example

   #:lisp-image-loaded-views-example))

(in-package #:dreyeck/lisp-image)
