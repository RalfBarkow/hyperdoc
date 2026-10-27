;;; A local, isolated Catalog for the reading "Deploying Topic Maps with HyperDoc". Loopback only; not development mode,
;;; so the served Catalog's authority policy is enforced as in the package. Topic Maps comes from TOPIC_MAPS_ROOT (the
;;; verified store snapshot), HyperDoc from this working tree, so that the reading shows the candidate as it stands.
;;; HYPERDOC_REVIEW_SITE_ROOT must name an empty site root with pages/; HYPERDOC_REVIEW_PORT defaults to 18776.
(require :asdf)
(load (merge-pathnames "topic-maps-project-bootstrap.lisp" (uiop:pathname-directory-pathname *load-truename*)))
(asdf:load-system "topic-maps-deployment-review")
;; The ASDF method collision, added to the reading after the first server (18776) was started.
(when (asdf:find-system "topic-maps-deployment-review-asdf-collision" nil)
  (asdf:load-system "topic-maps-deployment-review-asdf-collision"))
(asdf:load-system "dreyeck/catalog-application")
(let ((site (uiop:getenv "HYPERDOC_REVIEW_SITE_ROOT"))
      (port (parse-integer (or (uiop:getenv "HYPERDOC_REVIEW_PORT") "18776"))))
  (unless (and site (uiop:directory-exists-p (merge-pathnames "pages/" (uiop:ensure-directory-pathname site))))
    (error "Set HYPERDOC_REVIEW_SITE_ROOT to an empty site root with pages/."))
  (dreyeck/catalog-application:start-catalog :port port :host "127.0.0.1" :site-root (uiop:ensure-directory-pathname site))
  (format t "~&DEPLOYMENT-REVIEW-READY http://127.0.0.1:~D/ Topic Maps from ~A~%" port (asdf:system-source-directory "topic-maps"))
  (finish-output)
  (loop (sleep 3600)))
