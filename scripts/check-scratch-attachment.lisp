;;;; In the checkout's dev shell, point SCRATCH_TEST_SITE at a freshly unpacked site.
(require :asdf)
(asdf:load-system "dreyeck/fedwiki-hyperdoc")
(asdf:load-system "hyperdoc/explorer")
(asdf:load-system "topic-maps/ctm")

(let* ((root (uiop:ensure-directory-pathname (or (uiop:getenv "SCRATCH_TEST_SITE")
                                                 (error "Set SCRATCH_TEST_SITE to the unpacked site."))))
       (run (dreyeck/fedwiki-hyperdoc:activate-local-fedwiki-page-hyperdoc root "scratch"))
       (book (getf run :runtime-hyperdoc))
       (page (hyperbook:find-page book (hyperbook:main-page-id-of book) :signal-error? t))
       (html (html-inspector-views:view-html (html-inspector-views:👀content page))))
  (assert (equal (getf (getf (getf run :discovery) :asdf-archive) :item-id) "6efc97a9d8dc7bf4"))
  (assert (equal (getf run :selected-presentation-system) "scratch"))
  (assert (equal (getf run :trusted-asd) (truename (asdf:system-source-file "scratch"))))
  (assert (= 3 (length (hyperdoc:data-of book))))
  (assert (search "data:image/png;base64," html))
  (assert (search "data:text/plain;base64," html))
  (assert (search "data:image/png;base64,"
                  (html-inspector-views:view-html (html-inspector-views:👀content page))))
  (format t "~&Activated ~A from ~A~%" (hyperbook:title-of book) (getf run :trusted-asd)))

(let ((sources (mapcar (lambda (source) (getf source :id))
                       (hyperdoc-scratch:sources-for-topic :typed-nodes)))
      (map (topic-maps.ctm:deserialize-file
            (hyperdoc-scratch:topic-map-pathname)
            :document-iri "tag:dreyeck.ch,2026:hyperdoc/scratch/matrix-2026-11-18/map")))
  (assert (equal sources '(:m01 :image :solo)))
  (assert (= 19 (length hyperdoc-scratch:*topics*)))
  (format t "~&~D topic records. Typed nodes: ~S. CTM: ~D topics and ~D associations.~%"
          (length hyperdoc-scratch:*topics*) sources
          (length (topic-maps.tmdm:topic-map-topics map))
          (length (topic-maps.tmdm:topic-map-associations map))))
