;;;; Browser assets for the page-attached Mech of Mastodon reading.

(defpackage #:dreyeck/fedwiki-story-assets
  (:use #:cl)
  (:local-nicknames (#:assets #:dreyeck/fedwiki-assets))
  (:export #:mastodon-page-p #:mastodon-host-url #:wrap-mastodon-assets))

(in-package #:dreyeck/fedwiki-story-assets)

(defconstant +max-browser-file-size+ (* 1024 1024))

(defparameter *slug* "mech-of-mastodon")
(defparameter *url-prefix* "/assets/pages/mech-of-mastodon/host/")
(defparameter *asd-name* "mech-of-mastodon-reading.asd")

(defparameter *browser-files*
  '(("page-attached.html" "host/page-attached.html" "text/html; charset=utf-8")
    ("host.css" "host/host.css" "text/css; charset=utf-8")
    ("host.js" "host/host.js" "text/javascript; charset=utf-8")
    ("jquery-3.7.1.min.js" "host/jquery-3.7.1.min.js" "text/javascript; charset=utf-8")
    ("neighborhood.js" "host/neighborhood.js" "text/javascript; charset=utf-8")
    ("mastodon-preview.js" "host/mastodon-preview.js" "text/javascript; charset=utf-8")
    ("plugins/mech/mech.js" "host/plugins/mech/mech.js" "text/javascript; charset=utf-8")
    ("plugins/mech/blocks.js" "host/plugins/mech/blocks.js" "text/javascript; charset=utf-8")
    ("plugins/mech/library.js" "host/plugins/mech/library.js" "text/javascript; charset=utf-8")
    ("plugins/mech/interpreter.js" "host/plugins/mech/interpreter.js" "text/javascript; charset=utf-8")
    ("mech-of-mastodon.json" "evidence/mech-of-mastodon.json" "application/json; charset=utf-8")))

(defun mastodon-page-p (page)
  (and (typep page 'dreyeck/local-fedwiki-page:local-fedwiki-page)
       (string= (hyperbook:id-of page) *slug*)))

(defun attachment-declared-p (page-json)
  (find "pages/mech-of-mastodon" (assets:assets-story-items page-json)
        :test #'equal :key #'assets:assets-reference-of))

(defun asset-file (directory name)
  ;; The site root is canonical. Keep each served file at its declared path.
  (let ((path (merge-pathnames name directory)))
    (when (equal path (probe-file path)) path)))

(defun attachment-source (site-root page-json)
  (when (attachment-declared-p page-json)
    (let ((directory (assets:page-assets-directory
                      (truename (uiop:ensure-directory-pathname site-root)) *slug*)))
      (cond ((and (asset-file directory *asd-name*)
                  (asset-file directory "host/page-attached.html"))
             directory)
            (t (asset-file directory "mech-of-mastodon.zip"))))))

(defun browser-file-bytes (source name)
  (when source
    (if (uiop:directory-pathname-p source)
        (let ((file (asset-file source name)))
          (when file
            (with-open-file (stream file :element-type '(unsigned-byte 8))
              (let ((size (file-length stream)))
                (when (<= size +max-browser-file-size+)
                  (let ((bytes (make-array size :element-type '(unsigned-byte 8))))
                    (when (= size (read-sequence bytes stream)) bytes)))))))
        (zip:with-zipfile (archive source)
          (let* ((prefix "mech-of-mastodon/")
                 (asd (zip:get-zipfile-entry (concatenate 'string prefix *asd-name*) archive))
                 (entry (zip:get-zipfile-entry (concatenate 'string prefix name) archive)))
            (when (and asd entry (<= (zip:zipfile-entry-size entry) +max-browser-file-size+))
              (zip:zipfile-entry-contents entry)))))))

(defun mastodon-host-url (page)
  (when (mastodon-page-p page)
    (when (ignore-errors
            (browser-file-bytes
             (attachment-source
              (dreyeck/local-fedwiki-page:local-fedwiki-page-site-root-of page)
              (hyperbook/fedwiki::raw-json-of page))
             "host/page-attached.html"))
      (concatenate 'string *url-prefix* "page-attached.html"))))

(defun response-for-file (site-root request entry)
  (destructuring-bind (url name mime) entry
    (let* ((source (attachment-source site-root (assets:read-local-fedwiki-page site-root *slug*)))
           (bytes (browser-file-bytes source name)))
      (when bytes
        (list 200
              (append
               (list :content-type mime :content-length (length bytes)
                     :cache-control "no-store" :x-content-type-options "nosniff"
                     :referrer-policy "no-referrer" :access-control-allow-origin "*")
               (when (equal url "page-attached.html")
                 (list :content-security-policy
                       "sandbox allow-scripts; default-src 'none'; script-src 'self' data:; connect-src 'self' https://journa.host; style-src 'self' 'unsafe-inline'; frame-ancestors 'self'; base-uri 'none'; form-action 'none'")))
              (if (eq (getf request :request-method) :head) (list "") bytes))))))

(defun wrap-mastodon-assets (app site-root)
  "Serve just the reading's browser files from the configured FedWiki page store."
  (lambda (request)
    (let ((path (getf request :path-info)))
      (if (and (stringp path) (alexandria:starts-with-subseq *url-prefix* path))
          (or (when (member (getf request :request-method) '(:get :head))
                (let ((entry (assoc (subseq path (length *url-prefix*)) *browser-files* :test #'equal)))
                  (when entry
                    (ignore-errors (response-for-file site-root request entry)))))
              '(404 (:content-type "text/plain") ("Not found")))
          (funcall app request)))))
