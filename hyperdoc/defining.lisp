;;;; Defining HyperDocs
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; This macro is the recommended way to define and register a HyperDoc
;;

(defmacro defhyperdoc (var-symbol
                       &key title asdf-system-name subdirectory entry)
  "Define and register a HyperDoc from TITLE, the HyperDoc's title,
ASDF-SYSTEM-NAME and SUBDIRECTORY to define the HyperDoc's directory,
and optionally ENTRY, the title of the entry page. The HyperDoc
becomes the value bound to VAR-SYMBOL."
  `(progn
     (defvar ,var-symbol
       (make-hyperdoc :title ,title
                      :asdf-system-name ,asdf-system-name
                      :subdirectory ,subdirectory
                      :entry ,entry))
     (eval-when (:load-toplevel)
       (register ,var-symbol))))
