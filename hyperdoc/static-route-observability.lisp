;;;; Inspectable static route observability skill objects
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defclass static-asset-path-resolution ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (request-path :reader request-path-of :initarg :request-path :type string)
   (owner-kind :reader owner-kind-of :initarg :owner-kind)
   (mount-prefix :reader mount-prefix-of :initarg :mount-prefix :type string)
   (root-path :reader root-path-of :initarg :root-path :type pathname)
   (relative-path :reader relative-path-of :initarg :relative-path :type string)
   (resolved-path :reader resolved-path-of :initarg :resolved-path :type pathname)
   (evidence-mode :reader evidence-mode-of :initarg :evidence-mode)
   (contract :reader contract-of :initarg :contract :type string)
   (implemented-by :reader implemented-by-of
                   :initarg :implemented-by
                   :initform nil)
   (worked-example :reader worked-example-of
                   :initarg :worked-example
                   :initform nil)))

(defclass static-asset-resolution-surface ()
  ((id :reader id-of :initarg :id :type string)
   (title :reader title-of :initarg :title :type string)
   (summary :reader summary-of :initarg :summary :type string)
   (evidence-mode :reader evidence-mode-of :initarg :evidence-mode)
   (resolutions :reader resolutions-of :initarg :resolutions :initform nil)
   (notes :reader notes-of :initarg :notes :initform nil)))

(defun observability-evidence-mode-label (mode)
  (ecase mode
    (:static-computation "static computation")
    (:live-probing "live probing")
    (:static-and-live "static computation plus live probing")))

(defun static-asset-owner-label (owner-kind)
  (ecase owner-kind
    (:clog-static-root "CLOG static root")
    (:views-asset-mount "explicit views:add-asset-path mount")))

(defun server-static-root-pathname ()
  (call-hyperbook-server-helper 'static-root-pathname))

(defun hyperbook-server-assets-root-pathname ()
  (uiop:ensure-directory-pathname
   (asdf:system-relative-pathname :hyperbook/server
                                  "assets/hyperbook-server/")))

(defun make-static-asset-path-resolution (&key id title summary request-path owner-kind
                                               mount-prefix root-path relative-path
                                               evidence-mode contract implemented-by
                                               worked-example)
  (let* ((root (uiop:ensure-directory-pathname root-path))
         (resolved (merge-pathnames (pathname relative-path) root)))
    (make-instance 'static-asset-path-resolution
                   :id id
                   :title title
                   :summary summary
                   :request-path request-path
                   :owner-kind owner-kind
                   :mount-prefix mount-prefix
                   :root-path root
                   :relative-path relative-path
                   :resolved-path resolved
                   :evidence-mode evidence-mode
                   :contract contract
                   :implemented-by implemented-by
                   :worked-example worked-example)))

(defun make-clog-static-root-resolution (&key id title summary request-path relative-path
                                              contract implemented-by worked-example)
  (make-static-asset-path-resolution
   :id id
   :title title
   :summary summary
   :request-path request-path
   :owner-kind :clog-static-root
   :mount-prefix "/"
   :root-path (server-static-root-pathname)
   :relative-path relative-path
   :evidence-mode :static-computation
   :contract contract
   :implemented-by implemented-by
   :worked-example worked-example))

(defun make-mounted-asset-resolution (&key id title summary request-path mount-prefix
                                           root-path relative-path contract
                                           implemented-by worked-example)
  (make-static-asset-path-resolution
   :id id
   :title title
   :summary summary
   :request-path request-path
   :owner-kind :views-asset-mount
   :mount-prefix mount-prefix
   :root-path root-path
   :relative-path relative-path
   :evidence-mode :static-computation
   :contract contract
   :implemented-by implemented-by
   :worked-example worked-example))

(defun hyperdoc-boot-html-static-asset-resolution ()
  (make-clog-static-root-resolution
   :id "boot-html-static-asset-resolution"
   :title "Static asset path resolution for /boot.html"
   :summary "The boot page is served from the active CLOG static root."
   :request-path "/boot.html"
   :relative-path "boot.html"
   :contract "If /boot.html is broken, inspect the effective static root first; this route does not depend on an extra views:add-asset-path mount."
   :implemented-by '("hyperbook/server:static-root-pathname"
                     "hyperbook/server:serve-hyperbooks -> clog:initialize :static-root")
   :worked-example "Static-root triage starts with /boot.html because it proves whether the runtime can serve the top-level CLOG boot file at all."))

(defun hyperdoc-boot-js-static-asset-resolution ()
  (make-clog-static-root-resolution
   :id "boot-js-static-asset-resolution"
   :title "Static asset path resolution for /js/boot.js"
   :summary "boot.js is served from the active CLOG static root in explicit file-backed mode."
   :request-path "/js/boot.js"
   :relative-path "js/boot.js"
   :contract "If /js/boot.js lacks the expected patch markers, the runtime is not serving the intended CLOG static root or is not using file-backed boot.js."
   :implemented-by '("hyperbook/server:static-root-pathname"
                     "hyperbook/server:serve-hyperbooks -> clog:initialize :static-root"
                     "hyperbook/server:serve-hyperbooks -> clog:initialize :static-boot-js t")
   :worked-example "The dreyeck boot.js repair was diagnosed by proving that live /js/boot.js still came from unpatched CLOG output even though the repo already contained the intended patch."))

(defun hyperdoc-jquery-min-js-static-asset-resolution ()
  (make-clog-static-root-resolution
   :id "jquery-min-js-static-asset-resolution"
   :title "Static asset path resolution for /js/jquery.min.js"
   :summary "jquery.min.js is another CLOG static-root asset and should resolve beside boot.js."
   :request-path "/js/jquery.min.js"
   :relative-path "js/jquery.min.js"
   :contract "When /js/jquery.min.js fails together with /boot.html or /js/boot.js, treat the failure as a static-root problem before chasing page-specific JavaScript bugs."
   :implemented-by '("hyperbook/server:static-root-pathname"
                     "hyperbook/server:serve-hyperbooks -> clog:initialize :static-root")
   :worked-example "Static-root regression triage uses jquery.min.js as a second /js/ probe to distinguish single-file problems from broken CLOG static-root serving."))

(defun hyperbook-server-url-js-static-asset-resolution ()
  (make-mounted-asset-resolution
   :id "hyperbook-server-url-js-static-asset-resolution"
   :title "Static asset path resolution for /hyperbook-server/js/url.js"
   :summary "url.js is served through an explicit HyperBook-server asset mount, not through the CLOG static root."
   :request-path "/hyperbook-server/js/url.js"
   :mount-prefix "/hyperbook-server/"
   :root-path (hyperbook-server-assets-root-pathname)
   :relative-path "js/url.js"
   :contract "If /hyperbook-server/js/url.js is broken while /js/boot.js is healthy, inspect the route's explicit views:add-asset-path mount and helper-loading contract instead of the global static root."
   :implemented-by '("hyperbook/server:url-view-from-slug -> views:add-asset-path \"/hyperbook-server/\""
                     "hyperbook/server:url-view-from-slug -> views:include-js \"/hyperbook-server/js/url.js\"")
   :worked-example "The URL-tab regression was not a boot.js/static-root problem; it depended on making the helper route explicit and versioned where add-asset-path alone was not enough."))

(defun hyperdoc-static-asset-resolution-surface ()
  (make-instance 'static-asset-resolution-surface
                 :id "hyperdoc-static-asset-resolution-surface"
                 :title "Static asset resolution surface"
                 :summary "Compare which static asset routes belong to the CLOG static root and which are owned by explicit runtime asset mounts."
                 :evidence-mode :static-computation
                 :resolutions (list (hyperdoc-boot-html-static-asset-resolution)
                                    (hyperdoc-boot-js-static-asset-resolution)
                                    (hyperdoc-jquery-min-js-static-asset-resolution)
                                    (hyperbook-server-url-js-static-asset-resolution))
                 :notes '("The current skill computes ownership from server wiring; it does not probe HTTP routes by itself."
                          "/boot.html, /js/boot.js, and /js/jquery.min.js belong to the active CLOG static root."
                          "/hyperbook-server/js/url.js belongs to an explicit HyperBook-server asset mount.")))
