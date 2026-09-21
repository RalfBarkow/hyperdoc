;;;; Server-independent rendering of locally persisted Federated Wiki pages

(in-package #:dreyeck/local-fedwiki-view)

(defparameter *default-wiki-id*
  "fedwiki:dreyeck.ch")

(defun configured-site-root ()
  "Return the local FedWiki page-store root used by the /view route.

The answer now comes from DREYECK/FEDWIKI-ASSETS, so that anything else
needing this runtime's site root asks the same question rather than
rebuilding the default. HYPERDOC_FEDWIKI_SITE_ROOT still overrides it."
  (dreyeck/fedwiki-assets:configured-local-site-root))

(defun view-slug-from-pathname (pathname)
  "Return the single page slug encoded by /view/<slug>, or NIL."
  (let ((prefix "/view/"))
    (when
        (and
         (stringp pathname)
         (> (length pathname)
            (length prefix))
         (string=
          prefix
          pathname
          :end2
          (length prefix)))
      (let ((encoded
              (subseq pathname
                      (length prefix))))
        (when
            (not
             (find #\/ encoded))
          (tbnl:url-decode encoded))))))

(defun make-local-fedwiki-view-page
    (site-root
     slug
     &key
       (wiki-id *default-wiki-id*))
  "Resolve SLUG through the registered LOCAL-FEDWIKI for SITE-ROOT."
  (let ((wiki
          (dreyeck/local-fedwiki-page:register-local-fedwiki
           site-root
           wiki-id)))
    (hyperbook:find-page
     wiki
     slug
     :signal-error? t)))

(defun ensure-page-attached-workspace-offer (page)
  "Ensure the Catalog offer for PAGE's uniquely matching page-attached ASDF system.

Return NIL when PAGE has no matching attached system.  Repeated calls
return the existing offer.  Ambiguous matches fail closed.

Offered without being evaluated. This used to call REGISTER-ASD-SYSTEMS
on every .asd the page carries, whose own docstring begins \"Evaluate
trusted ASD-PATHNAME\": ASDF:LOAD-ASD runs the file as Lisp. Since this
function runs on every /view/<slug> request, visiting a page ran the
code attached to it, before anything was clicked and whatever the
development flag said.

Nothing is lost by not evaluating, because only a system whose name
equals the page slug was ever admitted. That condition is decidable
from the filename: the .asd a page offers is the one named after the
page. The offer therefore says a page-attached ASDF artifact is here;
whether a system can be built from it is a later question, asked in a
runtime that is allowed to ask it."
  (let* ((discovery
          (dreyeck/local-fedwiki-page:local-fedwiki-page-asdf-discovery page))
         (page-slug (getf discovery :slug))
         (matches
          (remove-if-not
           (lambda (asd) (equal page-slug (pathname-name asd)))
           (getf discovery :asdf-files))))
    (cond ((null matches) nil)
          ((= 1 (length matches))
           (dreyeck/catalog::admit :catalog page-slug))
          (t
           (error "Page slug ~S matches ~D page-attached ASDF artifacts: ~S"
                  page-slug (length matches) matches)))))

(defun install-local-fedwiki-view-route
       (site-root
        &key (path "/view") (pane-width "700px") (development nil)
        (wiki-id *default-wiki-id*))
  "Install PATH/<slug> as a local FedWiki JSON route in the running CLOG server."
  (let ((site-root (uiop/pathname:ensure-directory-pathname site-root)))
    (clog:set-on-new-window
     (lambda (body)
       (let* ((pathname (clog:property (clog:location body) "pathname"))
              (slug (view-slug-from-pathname pathname)))
         (unless slug (error "Expected /view/<slug>, got ~S." pathname))
         (let ((page
                (make-local-fedwiki-view-page site-root slug :wiki-id wiki-id)))
           (ensure-page-attached-workspace-offer page)
           (clog-moldable-inspector:on-new-inspector body :object page
                                                     :pane-width pane-width
                                                     :title
                                                     (hyperbook:title-of page)
                                                     :playground?
                                                     development))))
     :path path)))

(defun serve-catalog-with-local-fedwiki-view
    (&key
       (site-root
         (configured-site-root))
       (port 8080)
       (host "0.0.0.0")
       (pane-width "700px")
       (development nil)
       (wiki-id *default-wiki-id*))
  "Serve the HyperBook catalog plus server-independent /view/<slug> FedWiki pages."

  ;; Register the local FedWiki before SERVE-CATALOG installs the
  ;; routes for all currently registered HyperBooks.
  (dreyeck/local-fedwiki-page:register-local-fedwiki
   site-root
   wiki-id)

  (hyperbook/server:serve-catalog
   :port port
   :host host
   :pane-width pane-width
   :development development)

  (install-local-fedwiki-view-route
   site-root
   :pane-width pane-width
   :development development
   :wiki-id wiki-id))

(html-inspector-views:defview
    hyperbook/server::👀url
    (page dreyeck/local-fedwiki-page:local-fedwiki-page)
  (hyperbook/server::url-view-from-slug
   (concatenate
    'string
    "view/"
    (hyperbook:path-item-of page))))
