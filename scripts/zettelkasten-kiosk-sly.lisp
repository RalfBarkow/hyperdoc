;;; The development image of «nix run …#zettelkasten-kiosk -- --sly»: Slynk for Emacs, the page-attached system
;;; activated from the wiki page's assets (so that what Emacs edits there is what this image loaded), and the Catalog.
;;; Like hyperdoc-sly, and unlike the packaged Catalog, this image may load a page's system after a person asked for it;
;;; the person asked by passing --sly. Listens on 127.0.0.1 only.
(require :asdf)
(require :sb-posix)
(sb-posix:unsetenv "DYLD_LIBRARY_PATH")
(asdf:initialize-source-registry
 `(:source-registry
   ;; The store copy of the page's system would shadow the page's own assets; only the assets copy is to be found.
   ;; An exclusion applies to the :tree entries after it, so it comes first.
   (:also-exclude ,(uiop:getenv "HYPERDOC_PAGE_SLUG"))
   ,@(loop for path in (uiop:split-string (or (uiop:getenv "CL_SOURCE_REGISTRY") "") :separator ":")
           unless (zerop (length path))
             collect `(:tree ,(uiop:ensure-directory-pathname (string-right-trim "/" path))))
   :ignore-inherited-configuration))

;; Slynk first, so that Emacs can attach while the systems compile.
(load (uiop:getenv "HYPERDOC_SLYNK_LOADER"))
(uiop:symbol-call :slynk-loader :init :setup nil)
(pushnew :slynk *features*)
(uiop:symbol-call :slynk :run-hook (symbol-value (uiop:find-symbol* "*AFTER-INIT-HOOK*" :slynk)))
(let ((port (uiop:symbol-call :slynk :create-server :interface "127.0.0.1" :port 0 :dont-close t :style :spawn)))
  (with-open-file (s (uiop:getenv "HYPERDOC_SLYNK_PORT_FILE") :direction :output :if-exists :supersede)
    (format s "~D~%" port)))

(asdf:load-system "dreyeck/catalog-topic-maps")
(uiop:symbol-call :dreyeck/catalog-topic-maps :verify-startup "dreyeck/catalog")
(asdf:load-system "dreyeck/catalog-application")
(asdf:load-system "dreyeck/fedwiki-hyperdoc")
(let ((site-root (uiop:getenv "HYPERDOC_FEDWIKI_SITE_ROOT"))
      (slug (uiop:getenv "HYPERDOC_PAGE_SLUG")))
  (format t "~&Activating the page-attached HyperDoc ~A from ~A~%" slug site-root)
  (finish-output)
  (uiop:symbol-call :dreyeck/fedwiki-hyperdoc :activate-local-fedwiki-page-hyperdoc
                    (uiop:ensure-directory-pathname site-root) slug)
  (format t "~&System ~A loaded from ~A~%" slug (asdf:system-source-file slug))
  (finish-output))
(let ((configuration (uiop:symbol-call :dreyeck/catalog-application "%CONFIGURATION" nil)))
  (apply (uiop:find-symbol* "START-CATALOG" :dreyeck/catalog-application) configuration)
  (format t "~&HyperBook Catalog listening on ~A:~D (development image with Slynk)~%"
          (getf configuration :host) (getf configuration :port))
  (finish-output))
;; The bootstrap owns this image's lifetime; Emacs connections do not.
(sb-thread:wait-on-semaphore (sb-thread:make-semaphore))
