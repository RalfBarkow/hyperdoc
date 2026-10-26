;;; Explicit, temporary loopback-only review; never reload a running service.
(load (merge-pathnames "topic-maps-project-bootstrap.lisp" *load-truename*))
(asdf:load-system "dreyeck/catalog-application")
(let* ((site (uiop:getenv "HYPERDOC_22U_SITE_ROOT"))
       (port (parse-integer (or (uiop:getenv "HYPERDOC_22U_PORT") "18773"))))
  (unless (and site (uiop:directory-exists-p site))
    (error "Set HYPERDOC_22U_SITE_ROOT to an empty temporary review site with a pages directory."))
  (assert (not (find-package "DREYECK/FEDWIKI-PAGE-AUTHORING")))
  (dreyeck/catalog-application:start-catalog :host "127.0.0.1" :port port
    :site-root (uiop:ensure-directory-pathname site) :development t)
  (format t "~&22U local Inspector Catalog: http://127.0.0.1:~D/ — load optional Reading Slice 22U.~%" port)
  (finish-output)
  (unwind-protect (loop (sleep 1)) (clog:shutdown)))
