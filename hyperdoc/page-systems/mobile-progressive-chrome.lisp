;;;; Page-system descriptor for Mobile progressive chrome in HyperDoc.

(in-package :hyperdoc)

(eval-when (:load-toplevel :execute)
  (register-page-system (make-mobile-progressive-chrome-page-system)))
