;;; Explicit, temporary loopback-only reading of the CTM review; never reload a running service.
(load (merge-pathnames "topic-maps-project-bootstrap.lisp" *load-truename*))
(asdf:load-system "dreyeck/work/topic-maps-ctm-review")
(asdf:load-system "dreyeck/catalog-application")
(let* ((site (uiop:getenv "HYPERDOC_22U_SITE_ROOT"))
       (port (parse-integer (or (uiop:getenv "HYPERDOC_22U_PORT") "18774"))))
  (unless (and site (uiop:directory-exists-p site))
    (error "Set HYPERDOC_22U_SITE_ROOT to an empty temporary review site with a pages directory."))
  (assert (not (find-package "DREYECK/FEDWIKI-PAGE-AUTHORING")))
  (dreyeck/catalog-application:start-catalog :host "127.0.0.1" :port port
    :site-root (uiop:ensure-directory-pathname site) :development t)
  (format t "~&CTM review Catalog: http://127.0.0.1:~D/ — Topic Maps CTM Review (22U) → Reviewing the CTM Reader.~%" port)
  (finish-output)
  (unwind-protect (loop (sleep 1)) (clog:shutdown)))
