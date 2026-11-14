;;;; FedWiki Story integrations for Mech and Solo.

(defpackage #:dreyeck/fedwiki-story
  (:use #:cl)
  (:local-nicknames (#:bt #:bordeaux-threads)
                    (#:fw #:hyperbook/fedwiki)
                    (#:views #:html-inspector-views))
  (:export #:*mech-plugin-host-url*))

(in-package #:dreyeck/fedwiki-story)

(defun story-script (filename)
  (views:add-asset-path "/dreyeck-fedwiki/"
                       (asdf:system-relative-pathname "dreyeck/fedwiki-story"
                                                       "assets/dreyeck-fedwiki/"))
  (concatenate 'string "/dreyeck-fedwiki/" filename))

(defmethod fw::render-story-item :around ((type (eql :html)) item page)
  (let ((text (fw::text-of item)))
    (if (and (search "url(#arrow)" text)
             (cl-ppcre:scan "(?i)^\\s*<svg(?:\\s|>)" text))
        (progn
          (views:include-js (story-script "solo-trail-story.js"))
          (views:include-script "mountFedwikiSoloTrailStory(window.currentInspectorView)")
          (views:html
            (:div :class "fedwiki-inline-svg"
                  :data-site (fw::domain-name-of (fw::origin-of page))
                  :data-slug (fw::origin-id-of page)
                  :data-item (fw::id-of item)
              (:template (views:esc text)))))
        (call-next-method))))

;; Mech runs in an isolated browser Wiki environment. The Lisp side supplies
;; JSON and serves static files.
(defvar *mech-plugin-host-url* nil
  "HTTP(S) URL of a standalone static Wiki plugin host, at an origin distinct
from the Inspector. NIL keeps the original item inspectable without execution.")

(defun sitemap-snapshot (wiki)
  "Copy a coherent read-only snapshot; never fetch or join an initializer."
  (bt:with-lock-held ((slot-value wiki 'fw::sitemap-lock))
    (let* ((state (slot-value wiki 'fw::sitemap-state))
           (initialization (fw::status-of wiki))
           (effective (if (eq state :missing)
                          (cond ((typep initialization 'condition) initialization)
                                ((and (typep initialization 'bt:thread)
                                      (bt:thread-alive-p initialization)) :loading)
                                (t state))
                          state)))
      (alexandria:plist-hash-table
       (list "domain" (fw::domain-name-of wiki)
             "sourceUrl" (or (slot-value wiki 'fw::sitemap-source-url) :null)
             "state" (if (typep effective 'condition) "failed"
                         (string-downcase (symbol-name effective)))
             "message" (if (typep effective 'condition) (princ-to-string effective) :null)
             "sitemap" (if (eq effective :ready) (fw::copy-page-json (fw::sitemap-of wiki)) :null))
       :test 'equal))))

(defun mech-neighborhood-snapshot (page)
  "Snapshot only PAGE's origin and existing context, preserving first occurrence.
This is declared page scope, not a reconstruction of a complete Wiki session."
  (let ((seen (make-hash-table :test #'equal)))
    (alexandria:plist-hash-table
     (list "version" 1 "scope" "page-origin-and-context"
           "page" (alexandria:plist-hash-table
                   (list "site" (fw::domain-name-of (fw::origin-of page))
                         "slug" (fw::origin-id-of page)) :test 'equal)
           "sites" (coerce
                    (loop for wiki in (cons (fw::origin-of page) (fw::context-of page))
                          for domain = (fw::domain-name-of wiki)
                          unless (gethash domain seen)
                            collect (progn (setf (gethash domain seen) t)
                                           (sitemap-snapshot wiki)))
                    'vector))
     :test 'equal)))

(defun mech-json-base64 (value)
  (cl-base64:usb8-array-to-base64-string
   (flexi-streams:string-to-octets (shasht:write-json value nil)
                                 :external-format :utf-8)))

(defmethod fw::render-story-item ((type (eql :mech)) item page)
  (declare (ignore type))
  (let* ((attached-page (dreyeck/fedwiki-story-assets:mastodon-page-p page))
         (attached-url (and attached-page (dreyeck/fedwiki-story-assets:mastodon-host-url page)))
         (host-url (if attached-page attached-url *mech-plugin-host-url*)))
    (views:include-js (story-script "mech-story.js"))
    (views:include-script "mountFedwikiMech(window.currentInspectorView)")
    (views:html
      (:section :class "fedwiki-mech-host"
                :data-host-url (or host-url "")
                :data-host-scope (if attached-url "page-attached" "external")
                :data-item-id (fw::id-of item)
                :data-site (fw::domain-name-of (fw::origin-of page))
                :data-slug (fw::origin-id-of page)
                :data-page-json-base64
                (mech-json-base64 (fw::raw-json-of page))
                :data-neighborhood-json-base64
                (mech-json-base64 (mech-neighborhood-snapshot page))
        (:p :class "mech-host-status"
            (views:esc (cond (host-url "Loading browser Wiki plugin host. No Code item has run.")
                             (attached-page "The page-attached Mech browser assets are unavailable.")
                             (t "Wiki plugin host is not configured. No Code item has run."))))
        (:p (views:object-ref item :display "Inspect original Mech item" :select "Data"))
        (:details (:summary "Original Mech item")
                  (:pre (views:esc (fw::text-of item))))))))
