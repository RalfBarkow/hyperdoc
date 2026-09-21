(defpackage #:dreyeck/asdf-source
  (:use #:cl)
  (:documentation "ASDF definition source, read as syntax rather than run.")
  ;; Only what both consumers need. Not the scanner's internals: this is
  ;; a way to ask what a .asd says, not a general Lisp parser.
  (:export #:asdf-source-node
           #:asdf-source-node-kind
           #:asdf-source-node-raw
           #:asdf-source-node-value
           #:asdf-source-node-children
           #:asdf-source-node-start
           #:asdf-source-node-end
           #:scan-asdf-source
           #:simple-asdf-designator-name
           #:asdf-defsystem-form-p
           #:depends-on-node))
