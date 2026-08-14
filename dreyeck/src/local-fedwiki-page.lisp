;; Local Federated Wiki pages with explicit local provenance

(in-package #:dreyeck/local-fedwiki-page)

(defclass local-fedwiki-page
    (hyperbook/fedwiki::fedwiki-page)
  ((site-root
    :reader local-fedwiki-page-site-root-of
    :initarg :site-root
    :type pathname))
  (:documentation
   "A FEDWIKI-PAGE whose local page-store root is explicit provenance."))

(defun make-local-fedwiki-page (site-root wiki slug)
  "Read SLUG from SITE-ROOT and return a hydrated LOCAL-FEDWIKI-PAGE in WIKI."
  (check-type slug string)
  (let* ((site-root
           (truename
            (uiop:ensure-directory-pathname
             site-root)))
         (json
           (dreyeck/fedwiki-assets:read-local-fedwiki-page
            site-root
            slug))
         (page
           (make-instance
            'local-fedwiki-page
            :site-root site-root
            :hyperbook wiki
            :id slug
            :title
            (gethash "title" json))))
    (hyperbook/fedwiki::set-page-data
     page
     json)
    (setf
     (gethash
      slug
      (hyperbook/fedwiki::pages-of wiki))
     page)
    page))

(defun local-fedwiki-page-asdf-discovery (page)
  "Return the read-only page-attached ASDF observation for PAGE."
  (check-type page local-fedwiki-page)
  (dreyeck/fedwiki-assets:page-attached-asdf-discovery-observation
   (local-fedwiki-page-site-root-of page)
   (hyperbook:id-of page)))
