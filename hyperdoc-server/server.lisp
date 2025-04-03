;;;; Web server for HyperDocs
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc/server)

(defun serve-catalog (&key (port 8080) (development nil) (pane-width "700px"))
  (serve-hyperdocs hyperdoc:*catalog*
                   :port port
                   :development development
                   :pane-width pane-width))

(defun serve-hyperdocs (root-object &key (port 8080) (development nil) (pane-width "700px"))
  (setf hyperdoc:*development-features* development)
  (clog-moldable-inspector:clog-serve-inspector root-object
                                                :pane-width pane-width
                                                :port port
                                                :playground? development)
  (dolist (hd (hyperdoc:hyperdocs hyperdoc:*catalog*))
    (clog:set-on-new-window
     #'(lambda (body)
         (clog-moldable-inspector:on-new-inspector body
                                                   :object hd
                                                   :pane-width pane-width
                                                   :title (hyperdoc:title hd)
                                                   :playground? development))
     :path (str:concat "/" (slug hd)))))


(defun slug (hd)
  (let ((title (hyperdoc:title hd)))
    (str:concat
     (str:substring 0 5
                    (sha1:sha1-hex (babel:string-to-octets title)))
     "-"
     (str:substring 0 30
                    (slug:slugify title)))))

(views:defview 👀url (hd hyperdoc:hyperdoc)
  (views:html-view :title "URL" :priority 7
    (views:add-asset-path "/hyperdoc-server/"
                          (asdf:system-relative-pathname
                           :hyperdoc/server
                           "assets/hyperdoc-server"))
  (views:include-js "/hyperdoc-server/js/url.js")
  (views:include-script "makeUrl(window.currentInspectorView)")
  (views:html (:hyperdoc-slug (views:esc (slug hd))))))
