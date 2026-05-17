;;;; Page-system descriptor for the localhost FedWiki mobile chrome twin.

(in-package :hyperdoc)

(eval-when (:load-toplevel :execute)
  (register-page-system (make-fedwiki-mobile-progressive-chrome-page-system)))
