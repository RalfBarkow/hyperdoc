;;; A fresh, loopback-only review process. No existing Lisp image is contacted.
(load (merge-pathnames "tmdm-model-bootstrap.lisp" *load-truename*))
(asdf:load-system "dreyeck/catalog-application")
(let* ((site (uiop:getenv "HYPERDOC_TMDM_SITE_ROOT"))
       (port (parse-integer (or (uiop:getenv "HYPERDOC_TMDM_PORT") "18772"))))
  (unless (and site (uiop:directory-exists-p site))
    (error "Set HYPERDOC_TMDM_SITE_ROOT to an empty temporary review site directory."))
  (assert (not (find-package "DREYECK/FEDWIKI-PAGE-AUTHORING")))
  (dreyeck/catalog-application:start-catalog :port port :host "127.0.0.1"
    :site-root (uiop:ensure-directory-pathname site) :development t)
  (format t "~&TMDM review Catalog: http://127.0.0.1:~D/ (development; writer absent)~%" port)
  (finish-output)
  (unwind-protect (loop (sleep 1)) (clog:shutdown)))
