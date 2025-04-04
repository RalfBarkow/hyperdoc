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
with the given TITLE and PANE-WIDTH. All registered HyperDocs are
served at the URL defined by their slug. If DEVELOPMENT is non-nil,
enable playgrounds and other development tools. This is not
recommended on public servers because it allows the execution of
arbitrary Lisp code."
  (setf hyperdoc:*development-features* development)
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
     :path (str:concat "/" (slug hd)))))

(defun serve-catalog (&key (port 8080) (pane-width "700px") (development nil))
  "Start a Web server on PORT that serves the HyperDoc catalog at path \"/\"
with the given PANE-WIDTH. All registered HyperDocs are served at the URL defined
by their slug. If DEVELOPMENT is non-nil, enable playgrounds and other development
tools. This is not recommended on public servers because it allows the execution
of arbitrary Lisp code."
  (serve-hyperdocs hyperdoc:*catalog*
                   :port port
                   :title "HyperDoc Catalog"
                   :development development
                   :pane-width pane-width))

;;
;; Compute a slug for a HyperDoc from its title.
;;

(defun slug (hd)
  "Return a character string derived from the title of HyperDoc HD that is suitable
for use in a URL. It is computed as the first five characters of the title's SHA1
followed by the first 30 characters of the title after removal of characters that
are not allowed in URLs."
  (let ((title (hyperdoc:title hd)))
    (str:concat
     (str:substring 0 5
                    (sha1:sha1-hex (babel:string-to-octets title)))
     "-"
     (str:substring 0 30
                    (slug:slugify title)))))

;;
;; URL view on HyperDocs
;;

(views:defview 👀url (hd hyperdoc:hyperdoc)
  (views:html-view :title "URL" :priority 7
    (views:add-asset-path "/hyperdoc-server/"
                          (asdf:system-relative-pathname
                           :hyperdoc/server
                           "assets/hyperdoc-server"))
  (views:include-js "/hyperdoc-server/js/url.js")
  (views:include-script "makeUrl(window.currentInspectorView)")
  (views:html (:hyperdoc-slug (views:esc (slug hd))))))
