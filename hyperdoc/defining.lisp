;;;; Defining HyperDocs
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; This macro is the recommended way to define and register a HyperDoc
;;

(defmacro defhyperdoc (var-symbol
                       &key id title asdf-system-name subdirectory
                         main-page-id tools data)
  "Define and register a HyperDoc from TITLE, the HyperDoc's title,
ASDF-SYSTEM-NAME and SUBDIRECTORY to define the HyperDoc's directory.
Optional data are MAIN-PAGE-ID, the id of the main page, TOOLS, a list
of packages defining HyperDoc tools, and DATA, a list of (SYMBOL . STRING)
cons pairs in which SYMBOL names a global variable and STRING is the
title under which the variable's data is listed in the HyperDoc's
list of datasets. The HyperDoc becomes the value bound to VAR-SYMBOL."
  `(progn
     (defvar ,var-symbol
       (make-hyperdoc :id ,id
                      :title ,title
                      :asdf-system-name ,asdf-system-name
                      :subdirectory ,subdirectory
                      :main-page-id ,main-page-id
                      :tools ,tools
                      :data ,data))
     (eval-when (:load-toplevel)
       (register ,var-symbol))))
