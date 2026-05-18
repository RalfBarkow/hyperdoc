;;;; Page-system descriptor for the localhost FedWiki SHOP3 page.

(in-package :hyperdoc)

(eval-when (:load-toplevel :execute)
  (register-page-system (make-fedwiki-shop3-page-system)))
