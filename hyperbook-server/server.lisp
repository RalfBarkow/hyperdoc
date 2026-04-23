;;;; Web server for HyperBooks
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook/server)

;;
;; Start a server for HyperBooks
;;

(defvar *server-parameters* nil)
(defvar *server-startup-hooks* nil)

(defun register-server-startup-hook (hook)
  "Register HOOK to run during SERVE-CATALOG startup.
HOOK may be a function or a symbol naming a function."
  (pushnew hook *server-startup-hooks* :test #'equal))

(defun run-server-startup-hooks ()
  (dolist (hook (reverse *server-startup-hooks*))
    (funcall hook)))

(defun maybe-enable-web-debugger ()
  "Optional seam into CLOG-MOLDABLE-INSPECTOR.
Enable web debugger only when that extension is loaded."
  (let ((sym (find-symbol "ENABLE-WEB-DEBUGGER" :clog-moldable-inspector)))
    (when (and sym (fboundp sym))
      (funcall sym))))

(defun known-wikis-pathname ()
  (merge-pathnames #P"hyperbook/known-wikis.sexp"
                   (uiop:xdg-config-home)))

(defun known-wikis-pathnames ()
  (list (known-wikis-pathname)))

(defun resolve-known-wikis-pathname ()
  (or (find-if #'probe-file (known-wikis-pathnames))
      (known-wikis-pathname)))

(defun load-known-wikis ()
  (let* ((candidates (known-wikis-pathnames))
         (pathname (resolve-known-wikis-pathname))
         (exists? (and pathname (probe-file pathname))))
    (if exists?
        (handler-case
            (values
             (with-open-file (stream pathname :direction :input)
               (read stream nil nil))
             t
             pathname
             candidates
             nil)
          (error (c)
            (values nil t pathname candidates c)))
        (values nil nil pathname candidates nil))))

(defun static-root-pathname ()
  (let* ((env-root (when-let (clog-src (uiop:getenv "CLOG_SRC"))
                     (let ((candidate (uiop:ensure-directory-pathname
                                       (merge-pathnames #P"static-files/"
                                                        (uiop:ensure-directory-pathname
                                                         (pathname clog-src))))))
                       (when (probe-file candidate)
                         candidate))))
         (root (or env-root
                   (uiop:ensure-directory-pathname
                    (asdf:system-relative-pathname :clog "static-files/")))))
    (assert (typep root 'pathname) (root)
            "Static root must be a pathname, got ~S" root)
    root))

(defun required-static-asset-pathnames (&optional (root (static-root-pathname)))
  (list (merge-pathnames #P"boot.html" root)
        (merge-pathnames #P"js/boot.js" root)
        (merge-pathnames #P"js/jquery.min.js" root)))

(defun validate-static-root-pathname (&optional (root (static-root-pathname)))
  (dolist (path (required-static-asset-pathnames root))
    (unless (probe-file path)
      (error
       (format nil
               "Missing required CLOG static asset ~A.~%~
                Active static root: ~A~%~
                CLOG_SRC: ~S~%~
                Start HyperDoc via the repo-managed environment so the patched CLOG static-files tree is active."
               path
               root
               (uiop:getenv "CLOG_SRC")))))
  root)

(defun valid-clog-static-root-p (root)
  (and root
       (typep root '(or pathname string))))

(defun make-static-root-lifecycle-guard-middleware (fallback-root)
  (assert (typep fallback-root 'pathname) (fallback-root)
          "Fallback static root must be a pathname, got ~S" fallback-root)
  (lambda (app)
    (lambda (env)
      (unless (valid-clog-static-root-p clog-connection:*static-root*)
        (format t "~&[HYPERBOOK] restoring CLOG static root for request ~A from ~S to ~A~%"
                (getf env :path-info)
                clog-connection:*static-root*
                fallback-root)
        (setf clog-connection:*static-root* fallback-root))
      (funcall app env))))

(defun register-runtime-asset-paths ()
  (clog-connection:add-plugin-path
   "^/hyperbook-server/"
   (uiop:ensure-directory-pathname
    (asdf:system-relative-pathname :hyperbook/server
                                   "assets/"))))

(defun register-known-hyperbooks ()
  (multiple-value-bind (entries exists? path candidates load-error)
      (load-known-wikis)
    (format t "~&[HYPERBOOK] known-wikis candidate paths: ~S~%" candidates)
    (format t "~&[HYPERBOOK] known-wikis path: ~A~%" path)
    (format t "~&[HYPERBOOK] known-wikis exists: ~S~%" exists?)
    (when load-error
      (format t "~&[HYPERBOOK] failed to read known-wikis from ~A: ~A~%"
              path
              load-error)
      (return-from register-known-hyperbooks nil))
    (unless exists?
      (format t "~&[HYPERBOOK] no known-wikis config found at ~A~%" path)
      (return-from register-known-hyperbooks nil))
    (unless (listp entries)
      (format t "~&[HYPERBOOK] malformed known-wikis root form in ~A: expected a list, got ~S~%"
              path
              entries)
      (return-from register-known-hyperbooks nil))
    (format t "~&[HYPERBOOK] known-wikis entry count: ~D~%" (length entries))
    (format t "~&[HYPERBOOK] loaded known-wikis entries: ~S~%" entries)

    (labels
        ((ensure-fedwiki-system-loaded ()
           (asdf:load-system :hyperbook/fedwiki))

         (id-like-string-p (string)
           (and (stringp string)
                (find #\: string)))

         (fedwiki-constructor ()
           (or (find-symbol "GET-FEDWIKI" :hyperbook/fedwiki)
               (error "GET-FEDWIKI not found after loading :hyperbook/fedwiki")))

         (entry->registration (entry)
           (cond
             ((stringp entry)
              (if (str:starts-with? "fedwiki:" entry)
                  (list :kind :fedwiki
                        :id entry
                        :domain (str:substring (length "fedwiki:") nil entry))
                  (list :kind :raw-id
                        :id entry)))
             ((and (consp entry)
                   (null (rest entry))
                   (stringp (first entry))
                   (id-like-string-p (first entry)))
              (entry->registration (first entry)))
             ((and (consp entry) (stringp (first entry)))
              (destructuring-bind (host &key https &allow-other-keys) entry
                (list :kind :fedwiki
                      :id (format nil "fedwiki:~A" host)
                      :domain host
                      :https https)))
             ((and (consp entry) (keywordp (first entry)))
              (destructuring-bind (kind host &key plugmatic https &allow-other-keys) entry
                (when plugmatic
                  (format t "~&[HYPERBOOK] note: ignoring :plugmatic in ~S (use id-only entry)~%"
                          entry))
                (case kind
                  (:fedwiki (list :kind :fedwiki
                                  :id (format nil "fedwiki:~A" host)
                                  :domain host
                                  :https https))
                  (otherwise
                   (format t "~&[HYPERBOOK] ignoring unsupported known wiki entry ~S~%"
                           entry)
                   nil))))
             (t
              (format t "~&[HYPERBOOK] ignoring malformed known wiki entry ~S~%" entry)
              nil)))

         (register-entry (registration)
           (destructuring-bind (&key kind id domain https &allow-other-keys) registration
             (case kind
               (:fedwiki
                (ensure-fedwiki-system-loaded)
                (format t "~&[HYPERBOOK] registering normalized id ~A~%" id)
                (let ((hb (funcall (fedwiki-constructor)
                                   domain
                                   nil
                                   nil
                                   :https https)))
                  (hyperbook:register hb)
                  (format t "~&[HYPERBOOK] registered HyperBook ID: ~A~%"
                          (hyperbook:id-of hb))
                  hb))
               (:raw-id
                (format t "~&[HYPERBOOK] registering normalized id ~A~%" id)
                (let ((hb (hyperbook:find-hyperbook id)))
                  (unless hb
                    (format t "~&[HYPERBOOK] failed to resolve ~A (find-hyperbook returned NIL)~%"
                            id))
                  (when hb
                    (format t "~&[HYPERBOOK] registered HyperBook ID: ~A~%"
                            (hyperbook:id-of hb)))
                  hb))
               (otherwise nil)))))

      (dolist (entry entries)
        (handler-case
            (when-let (registration (entry->registration entry))
              (format t "~&[HYPERBOOK] processing known wiki entry ~S~%" entry)
              (format t "~&[HYPERBOOK] normalized registration: ~S~%" registration)
              (register-entry registration))
          (error (c)
            (format t "~&[HYPERBOOK] failed to process ~S: ~A~%" entry c)))))))

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

(defun development-mode-p ()
  "Return the active server development policy.
This is the same runtime switch used for Playground evaluation."
  (if *server-parameters*
      (second *server-parameters*)
      (env-truthy-p "HYPERDOC_DEVELOPMENT" nil)))

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
        (static-root (validate-static-root-pathname)))
    (format t "~&[HYPERBOOK] static root: ~A~%" static-root)
    (when development*
      (ignore-errors (maybe-enable-web-debugger)))
    (register-runtime-asset-paths)
    (clog:initialize
     #'(lambda (body)
         (clog-moldable-inspector:on-new-inspector body
                                                   :object root-object
                                                   :pane-width pane-width
                                                   :title title
                                                   :playground? development*))
     :port port
     :static-root static-root
     :static-boot-js t
     :lack-middleware-list
     (list (make-static-root-lifecycle-guard-middleware static-root))
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
                (suffix (str:substring (length path) nil full-path))
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
    (run-server-startup-hooks)
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

(defun trim-trailing-slash (string)
  (string-right-trim "/" string))

(defun local-route-host ()
  (let ((bind-address (or (uiop:getenv "HYPERDOC_BIND_ADDRESS")
                          "127.0.0.1")))
    (if (member bind-address '("0.0.0.0" "::" "*") :test #'string=)
        "127.0.0.1"
        bind-address)))

(defun canonical-route-origin ()
  (if-let (public-base-url (uiop:getenv "HYPERDOC_PUBLIC_BASE_URL"))
      (trim-trailing-slash public-base-url)
      (format nil "http://~A:~A"
              (local-route-host)
              (or (uiop:getenv "HYPERDOC_PORT")
                  "8080"))))

(defun canonical-inspector-path (object)
  (typecase object
    (hyperbook:hyperbook
     (str:concat "/" (slug object)))
    (hyperbook:page
     (str:concat "/"
                 (slug (hyperbook:hyperbook-of object))
                 "/"
                 (tbnl:url-encode (hyperbook:path-item-of object))))
    (t
     nil)))

(defun canonical-page-path (page)
  (canonical-inspector-path page))

(defun canonical-inspector-url (object &key (origin (canonical-route-origin)))
  (when-let (path (canonical-inspector-path object))
    (str:concat (trim-trailing-slash origin)
                path)))

(defun canonical-page-url (page &key (origin (canonical-route-origin)))
  (canonical-inspector-url page :origin origin))

(defun versioned-hyperbook-server-asset-url (asset-url asset-relative-path)
  (let* ((asset-file (asdf:system-relative-pathname
                      :hyperbook/server
                      asset-relative-path))
         (date (ignore-errors (file-write-date asset-file))))
    (if date
        (format nil "~A?date=~A" asset-url date)
        asset-url)))

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
    ;; Runtime mounting and cache-busting need different filesystem roots here:
    ;; the server route is mounted at startup, while the file lives under
    ;; assets/hyperbook-server/js/url.js for version lookup.
    (views:include-js
     (versioned-hyperbook-server-asset-url
      "/hyperbook-server/js/url.js"
      "assets/hyperbook-server/js/url.js"))
    (views:include-script "makeUrl(window.currentInspectorView)")
    (views:html (:hyperbook-slug (views:esc slug)))))

(defclass slug-wrapper () (slug))

(defmethod views:html-representation ((w slug-wrapper) &optional id)
  (declare (ignore id))
  (views:html (:hyperbook-slug (views:esc (slot-value w 'slug)))))

(views:defview 👀url (w slug-wrapper)
  (url-view-from-slug (slot-value w 'slug)))
