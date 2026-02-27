;;;; Web server for HyperBooks
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook/server)

;;
;; Start a server for HyperBooks
;;

(defvar *server-parameters* nil)

(defun static-root-pathname ()
  (let ((root (uiop:ensure-directory-pathname
               (asdf:system-relative-pathname :clog "static-files/"))))
    (assert (typep root 'pathname) (root)
            "Static root must be a pathname, got ~S" root)
    root))

(defun env-truthy-p (name &optional (default nil))
  (let ((v (uiop:getenv name)))
    (cond
      ((null v) default)
      ((member (string-downcase v)
               '("1" "true" "yes" "on")
               :test #'string=)
       t)
      (t nil))))

(defun serve-hyperbooks (root-object &key (port 8080)
                                       (title "Inspector")
                                       (pane-width "700px")
                                       (development :auto))
  "Start a Web server on PORT that serves an inspector on ROOT-OBJECT at path \"/\"
with the given TITLE and PANE-WIDTH. All registered HyperBooks are
served at the URL defined by their slug. If DEVELOPMENT is non-nil,
enable playgrounds and other development tools. This is not
recommended on public servers because it allows the execution of
  arbitrary Lisp code."
  (let ((development* (if (eq development :auto)
                          (env-truthy-p "HYPERDOC_DEVELOPMENT" nil)
                          development))
        (static-root (static-root-pathname)))
    (clog:initialize
     #'(lambda (body)
         (clog-moldable-inspector:on-new-inspector body
                                                   :object root-object
                                                   :pane-width pane-width
                                                   :title title
                                                   :playground? development*))
     :port port
     :static-root static-root
     :extended-routing t)
    (dolist (hb (hyperbook:hyperbooks-of hyperbook:*catalog*))
      (add-path-to-hyperbook hb pane-width development*))
    (setf *server-parameters* (list pane-width development*))))

(defun add-path-to-hyperbook (hb pane-width development)
  (let ((path (str:concat "/" (-> hb slug)))
        (hb* hb))
    (clog:set-on-new-window
     #'(lambda (body)
         (let* ((full-path (clog:property (clog:location body) "pathname"))
                (_ (assert (str:starts-with? path full-path)))
                (suffix (str:substring (length path)  nil full-path))
                (rel-path (mapcar #'tbnl:url-decode (rest (str:split "/" suffix))))
                (object (or (and (or (equal '() rel-path) ;; example.org/hyperbook
                                     (equal '("") rel-path)) ;; example.org/hyperbook/
                                 hb)
                            (hyperbook:lookup-path hb rel-path)
                            (make-instance 'notfound :hyperbook hb*
                                                     :path rel-path))))
           (declare (ignore _))
           (clog-moldable-inspector:on-new-inspector body
                                                     :object object
                                                     :pane-width pane-width
                                                     :title (hyperbook:title-of hb)
                                                     :playground? development)))
     :path path)))

(defmethod hyperbook:register :after ((hb hyperbook:hyperbook))
  (when *server-parameters*
    (apply #'add-path-to-hyperbook (cons hb *server-parameters*))))

(defclass notfound ()
  ((hyperbook :reader hyperbook-of :initarg :hyperbook)
   (path :reader path-of :initarg :path)))

(views:defview views:👀content (notfound notfound)
  (views:html-view :title "Not found" :priority 1
    (views:add-asset-path "/hyperbook/"
                          (asdf:system-relative-pathname
                           :hyperbook
                           "assets/hyperbook/"))
    (views:include-css "/hyperbook/css/hyperbook.css")    (views:html
      (:div :class "hyperbook-page"
            (:h1 "Not found")
            (:p (views:esc (str:join "/" (path-of notfound))))))))

(defun serve-catalog (&key (port 8080) (pane-width "700px") (development :auto))
  "Start a Web server on PORT that serves the HyperBook catalog at path \"/\"
with the given PANE-WIDTH. All registered HyperBooks are served at the
URL defined by their slug. If DEVELOPMENT is non-nil, enable
playgrounds and other development tools. This is not recommended on
public servers because it allows the execution of arbitrary Lisp code."
  (let ((development* (if (eq development :auto)
                          (env-truthy-p "HYPERDOC_DEVELOPMENT" nil)
                          development)))
    (serve-hyperbooks hyperbook:*catalog*
                     :port port
                     :title "HyperBook Catalog"
                     :development development*
                     :pane-width pane-width)))

;;
;; Compute a slug for a HyperBook from its title and id
;;

(defun slug (hyperbook)
  "Return a character string derived from HYPERBOOK that is suitable
for use in a URL. It is computed as the first five characters of the
id's SHA1 followed by the first 30 characters of the title after
removal of characters that are not allowed in URLs."
  (str:concat
   (str:substring 0 5
                  (-> hyperbook hyperbook:id-of sha1:sha1-hex))
   "-"
   (str:substring 0 30
                  (-> hyperbook hyperbook:title-of slug:slugify))))

;;
;; URL view on HyperBooks and their pages
;;

(views:defview 👀url (hb hyperbook:hyperbook)
  (url-view-from-slug (-> hb slug)))

(views:defview 👀url (hb-page hyperbook:page)
  (let ((hb (slot-value hb-page 'hyperbook:hyperbook)))
    (url-view-from-slug
     (str:concat (-> hb slug)
                 "/"
                 (-> hb-page hyperbook:path-item-of tbnl:url-encode)))))

(defun url-view-from-slug (slug)
  (views:html-view :title "URL" :priority 20
    (views:add-asset-path "/hyperbook-server/"
                          (asdf:system-relative-pathname
                           :hyperbook/server
                           "assets/hyperbook-server/"))
    (views:include-js "/hyperbook-server/js/url.js")
    (views:include-script "makeUrl(window.currentInspectorView)")
    (views:html (:hyperbook-slug (views:esc slug)))))

;;
;; Extended dataset view with URLs
;;

(defclass slug-wrapper () (slug))

(defmethod views:html-representation ((w slug-wrapper) &optional id)
  (declare (ignore id))
  (views:html (:hyperbook-slug (views:esc (slot-value w 'slug)))))

(views:defview 👀url (w slug-wrapper)
  (url-view-from-slug (slot-value w 'slug)))
