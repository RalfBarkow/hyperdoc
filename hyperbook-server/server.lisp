;;;; Web server for HyperBooks
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook/server)

;;
;; Start a server for HyperBooks
;;

(defvar *server-parameters* nil)

(defun known-wikis-pathname ()
  (merge-pathnames #P"hyperbook/known-wikis.sexp"
                   (uiop:xdg-config-home)))

(defun load-known-wikis ()
  (let ((pathname (known-wikis-pathname)))
    (if (probe-file pathname)
        (values
         (with-open-file (stream pathname :direction :input)
           (read stream nil nil))
         t)
        (values nil nil))))

(defun static-root-pathname ()
  (let ((root (uiop:ensure-directory-pathname
               (asdf:system-relative-pathname :clog "static-files/"))))
    (assert (typep root 'pathname) (root)
            "Static root must be a pathname, got ~S" root)
    root))

(defun register-known-hyperbooks ()
  (let ((path (known-wikis-pathname)))
    (multiple-value-bind (entries exists?)
        (load-known-wikis)
      (unless exists?
        (format t "~&[HYPERBOOK] no known-wikis config found at ~A~%" path)
        (return-from register-known-hyperbooks nil))

      (labels
          ((ensure-scheme-loaded (id)
             (let* ((uri (handler-case (puri:parse-uri id) (error () nil)))
                    (scheme (and uri (puri:uri-scheme uri))))
               (when scheme
                 (case (intern (string-upcase scheme) :keyword)
                   (:FEDWIKI (asdf:load-system :hyperbook/fedwiki))
                   (otherwise nil)))))

           (entry->id (entry)
             (cond
               ((stringp entry)
                entry)
               ((and (consp entry) (stringp (first entry)))
                (first entry))
               ((and (consp entry) (keywordp (first entry)))
                (destructuring-bind (kind host &key plugmatic &allow-other-keys) entry
                  (when plugmatic
                    (format t "~&[HYPERBOOK] note: ignoring :plugmatic in ~S (use id-only entry)~%"
                            entry))
                  (case kind
                    (:fedwiki (format nil "fedwiki:~A" host))
                    (otherwise
                     (format t "~&[HYPERBOOK] ignoring unsupported known wiki entry ~S~%"
                             entry)
                     nil))))
               (t
                (format t "~&[HYPERBOOK] ignoring malformed known wiki entry ~S~%" entry)
                nil)))

           (register-id (id)
             (ensure-scheme-loaded id)
             (let ((hb (hyperbook:find-hyperbook id)))
               (unless hb
                 (format t "~&[HYPERBOOK] failed to resolve ~A (find-hyperbook returned NIL)~%"
                         id))
               hb)))

        (dolist (entry entries)
          (handler-case
              (let ((id (entry->id entry)))
                (when id
                  (unless (hyperbook:find-hyperbook id)
                    (format t "~&[HYPERBOOK] ensuring ~A~%" id))
                  (register-id id)))
            (error (c)
              (format t "~&[HYPERBOOK] failed to process ~S: ~A~%" entry c))))))))

(defun ensure-startup-hyperbooks ()
  (let ((ids '("hyperdoc/explorer"
               "moldable-inspector"
               "wikipedia:en")))
    (asdf:load-system :hyperdoc/explorer)
    (dolist (id ids)
      (unless (hyperbook:find-hyperbook id)
        (format t "~&[HYPERBOOK] ensuring ~A~%" id)
        (unless (hyperbook:find-hyperbook id)
          (format t "~&[HYPERBOOK] failed to resolve ~A (find-hyperbook returned NIL)~%"
                  id))))))

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
    (when development*
      (ignore-errors (clog-moldable-inspector::enable-web-debugger)))
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
                (object (or (and (or (equal '() rel-path)
                                     (equal '("") rel-path))
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
    (views:include-css "/hyperbook/css/hyperbook.css")
    (views:html
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
    (register-known-hyperbooks)
    (ensure-startup-hyperbooks)
    (serve-hyperbooks hyperbook:*catalog*
                      :port port
                      :title "HyperBook Catalog"
                      :development development*
                      :pane-width pane-width)))

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

(defclass slug-wrapper () (slug))

(defmethod views:html-representation ((w slug-wrapper) &optional id)
  (declare (ignore id))
  (views:html (:hyperbook-slug (views:esc (slot-value w 'slug)))))

(views:defview 👀url (w slug-wrapper)
  (url-view-from-slug (slot-value w 'slug)))
