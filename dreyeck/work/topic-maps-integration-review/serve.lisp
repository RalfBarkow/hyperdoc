;;; Operator entry, run by serve.sh: load the reading "Integrating Topic Maps 6162ed68", then hand over to the Catalog's own foreground MAIN, the one the packaged executables use: it serves on
;;; HYPERDOC_CATALOG_HOST, is not in development mode, stops on SIGINT or SIGTERM and returns an exit status.
;;; Loading compiles and loads code only. No review experiment, verification or guard trial runs until its button is
;;; pressed in the reading.
(require :asdf)
(load (merge-pathnames "../../../scripts/topic-maps-project-bootstrap.lisp" (uiop:pathname-directory-pathname *load-truename*)))
(format t "~&Loading the reading (code only; no experiment runs) ...~%") (finish-output)
(asdf:load-system "topic-maps-integration-review")
(asdf:load-system "dreyeck/catalog-application")
(format t "~&Loaded. Topic Maps from ~A; HyperDoc from ~A.~%Starting the Catalog ...~%"
        (asdf:system-source-directory "topic-maps") (asdf:system-source-directory "dreyeck"))
(finish-output)
(uiop:quit (dreyeck/catalog-application:main (uiop:command-line-arguments)))
