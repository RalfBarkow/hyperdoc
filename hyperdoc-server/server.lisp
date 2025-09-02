;;;; Web server for HyperDocs
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc/server)

;;
;; Start a server for HyperDocs
;;

(defun serve-hyperdocs (root-object &key (port 8080)
                                      (title "Inspector")
                                      (pane-width "700px")
                                      (development nil))
  "Start a Web server on PORT that serves an inspector on ROOT-OBJECT at path \"/\"
with the given TITLE and PANE-WIDTH. All registered HyperDocs and their
pages are served at the URL defined by their slug. If DEVELOPMENT is non-nil,
enable playgrounds and other development tools. This is not
recommended on public servers because it allows the execution of
arbitrary Lisp code."
  (clog:initialize
   #'(lambda (body)
       (clog-moldable-inspector:on-new-inspector body
                                                 :object root-object
                                                 :pane-width pane-width
                                                 :title title
                                                 :playground? development))
   :port port)
  (dolist (hd (hyperdoc:hyperdocs hyperdoc:*catalog*))
    (clog:set-on-new-window
     #'(lambda (body)
         (clog-moldable-inspector:on-new-inspector body
                                                   :object hd
                                                   :pane-width pane-width
                                                   :title (hyperdoc:title hd)
                                                   :playground? development))
     :path (str:concat "/" (-> hd hyperdoc:title slug)))
    (loop for page-title being the hash-keys in (hyperdoc:all-pages hd)
            using (hash-value object)
          do (let ((page-title* page-title)
                   (object* object))
               (clog:set-on-new-window
                #'(lambda (body)
                    (clog-moldable-inspector:on-new-inspector body
                                                              :object object*
                                                              :pane-width pane-width
                                                              :title page-title*
                                                              :playground? development))
                :path (str:concat "/" (-> hd hyperdoc:title slug)
                                  "/" (-> page-title* slug)))))))

(defun serve-catalog (&key (port 8080) (pane-width "700px") (development nil))
  "Start a Web server on PORT that serves the HyperDoc catalog at path \"/\"
with the given PANE-WIDTH. All registered HyperDocs and their pages are served at
the URL defined by their slug. If DEVELOPMENT is non-nil, enable playgrounds and
other development tools. This is not recommended on public servers because it
allows the execution of arbitrary Lisp code."
  (serve-hyperdocs hyperdoc:*catalog*
                   :port port
                   :title "HyperDoc Catalog"
                   :development development
                   :pane-width pane-width))

;;
;; Compute a slug for a HyperDoc or page from its title.
;;

(defun slug (title)
  "Return a character string derived from the title of HyperDoc HD that is suitable
for use in a URL. It is computed as the first five characters of the title's SHA1
followed by the first 30 characters of the title after removal of characters that
are not allowed in URLs."
  (str:concat
   (str:substring 0 5
                  (sha1:sha1-hex (babel:string-to-octets title)))
   "-"
   (str:substring 0 30
                  (slug:slugify title))))

;;
;; URL view on HyperDocs and their pages
;;

(views:defview 👀url (hd hyperdoc:hyperdoc)
  (url-view-from-slug (-> hd hyperdoc:title slug)))

(views:defview 👀url (hd-page hyperdoc:page)
  (let ((hd (slot-value hd-page 'hyperdoc:hyperdoc)))
    (url-view-from-slug
     (str:concat (-> hd hyperdoc:title slug)
                 "/"
                 (-> hd-page hyperdoc:page-title slug)))))

;; Can't do this for code-file because it doesn't hold a reference to
;; a HyperDoc.

(views:defview 👀url (hd-tool hyperdoc::tool)
  (let ((hd (slot-value hd-tool 'hyperdoc:hyperdoc)))
    (url-view-from-slug
     (str:concat (-> hd hyperdoc:title slug)
                 "/"
                 (-> hd-tool hyperdoc::title-of slug)))))

(defun url-view-from-slug (slug)
  (views:html-view :title "URL" :priority 20
    (views:add-asset-path "/hyperdoc-server/"
                          (asdf:system-relative-pathname
                           :hyperdoc/server
                           "assets/hyperdoc-server"))
    (views:include-js "/hyperdoc-server/js/url.js")
    (views:include-script "makeUrl(window.currentInspectorView)")
    (views:html (:hyperdoc-slug (views:esc slug)))))
