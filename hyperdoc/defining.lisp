;;;; Defining HyperDocs
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; This macro is the recommended way to define and register a HyperDoc
;;

(defmacro defhyperdoc (var-symbol
                       &key title asdf-system-name subdirectory entry)
  `(progn
     (defvar ,var-symbol
       (make-hyperdoc :title ,title
                      :asdf-system-name ,asdf-system-name
                      :subdirectory ,subdirectory
                      :entry ,entry))
     (eval-when (:load-toplevel)
       (register ,var-symbol))))
