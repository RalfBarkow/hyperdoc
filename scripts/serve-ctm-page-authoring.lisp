;;; A fresh, loopback-only review Catalog with the Item edit path: Edit proposal, Preview, Action context,
;;; Execution (no request is attached, so nothing can be written) and the TMDM readings.
;;; No existing Lisp image is contacted. Environment:
;;;   TOPIC_MAPS_ROOT           a CLEAN topic-maps checkout (required): the commit 788899ae or a descendant whose reading inputs are
;;;                             unchanged since (tested with 963f2a0). Not a working repository that is being developed.
;;;   HYPERDOC_FEDWIKI_SITE_ROOT the FedWiki site directory to read, e.g. ~/.wiki/localhost/ (required)
;;;   HYPERDOC_CTM_PORT         default 18773
(load (merge-pathnames "tmdm-model-bootstrap.lisp" *load-truename*))
(asdf:load-system "dreyeck/catalog-application")
(let* ((site (uiop:getenv "HYPERDOC_FEDWIKI_SITE_ROOT"))
       (port (parse-integer (or (uiop:getenv "HYPERDOC_CTM_PORT") "18773"))))
  (unless (and site (uiop:directory-exists-p site))
    (error "Set HYPERDOC_FEDWIKI_SITE_ROOT to the FedWiki site directory to read."))
  (dreyeck/catalog-application:start-catalog
   :port port :host "127.0.0.1" :site-root (uiop:ensure-directory-pathname site)
   :development nil :catalog-system "dreyeck/ctm-page-authoring/local")
  (format t "~&CTM page authoring review Catalog: http://127.0.0.1:~D/ (nothing is written to ~A)~%" port site)
  (finish-output)
  (unwind-protect (loop (sleep 1)) (clog:shutdown)))
