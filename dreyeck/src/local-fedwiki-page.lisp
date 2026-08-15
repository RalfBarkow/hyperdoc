;;;; Local Federated Wiki pages with explicit local provenance

(in-package #:dreyeck/local-fedwiki-page)

(defun %canonical-site-root (site-root)
  (truename
   (uiop:ensure-directory-pathname
    site-root)))

(defclass local-fedwiki
    (hyperbook/fedwiki::fedwiki)
  ((site-root
    :reader local-fedwiki-site-root-of
    :initarg :site-root
    :type pathname))
  (:documentation
   "A FEDWIKI HyperBook whose pages are resolved exclusively from a local page store."))

(defun make-local-fedwiki (site-root wiki-id)
  "Construct a LOCAL-FEDWIKI backed by SITE-ROOT without network initialization."
  (check-type wiki-id string)
  (make-instance
   'local-fedwiki
   :id wiki-id
   :site-root
   (%canonical-site-root site-root)))

(defun %registered-hyperbook (wiki-id)
  (find
   wiki-id
   (hyperbook:hyperbooks-of hyperbook:*catalog*)
   :key #'hyperbook:id-of
   :test #'equal))

(defun register-local-fedwiki (site-root wiki-id)
  "Register WIKI-ID as a LOCAL-FEDWIKI backed by SITE-ROOT.

If the same LOCAL-FEDWIKI is already registered, return it. Refuse to replace
a different HyperBook that already owns WIKI-ID."
  (check-type wiki-id string)
  (let* ((site-root
           (%canonical-site-root site-root))
         (existing
           (%registered-hyperbook wiki-id)))
    (cond
      ((null existing)
       (let ((wiki
               (make-local-fedwiki
                site-root
                wiki-id)))
         (hyperbook:register wiki)
         wiki))

      ((typep existing 'local-fedwiki)
       (unless
           (equal
            site-root
            (local-fedwiki-site-root-of existing))
         (error
          "LOCAL-FEDWIKI ~S is already registered for ~A, not ~A."
          wiki-id
          (local-fedwiki-site-root-of existing)
          site-root))
       existing)

      (t
       (error
        "HyperBook ~S is already registered as ~S; refusing to replace it with a LOCAL-FEDWIKI."
        wiki-id
        existing)))))

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
           (%canonical-site-root site-root))
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

(defmethod hyperbook:find-page
    ((wiki local-fedwiki)
     slug
     &key
       signal-error?)
  "Resolve SLUG exclusively in the local page store of WIKI."
  (check-type slug string)
  (or
   (gethash
    slug
    (hyperbook/fedwiki::pages-of wiki))

   (let ((pathname
           (dreyeck/fedwiki-assets:local-fedwiki-page-pathname
            (local-fedwiki-site-root-of wiki)
            slug)))
     (cond
       ((probe-file pathname)
        (make-local-fedwiki-page
         (local-fedwiki-site-root-of wiki)
         wiki
         slug))

       (signal-error?
        (error
         'hyperbook:page-lookup-failure
         :hyperbook wiki
         :page-id slug))

       (t
        nil)))))

(defun local-fedwiki-page-asdf-discovery (page)
  "Return the read-only page-attached ASDF observation for PAGE."
  (check-type page local-fedwiki-page)
  (dreyeck/fedwiki-assets:page-attached-asdf-discovery-observation
   (local-fedwiki-page-site-root-of page)
   (hyperbook:id-of page)))
