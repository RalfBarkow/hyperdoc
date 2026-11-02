;;;; Read-only demonstration. Only the original Node server writes the test site.
;;;; Configuration, and what each mode offers: dreyeck/src/fedwiki-original-editor-configuration.lisp.
(defpackage #:dreyeck/fedwiki-original-editor-demo
  (:use #:cl)
  (:local-nicknames (#:lp #:dreyeck/local-fedwiki-page)
                    (#:cfg #:dreyeck/fedwiki-original-editor-configuration)
                    (#:v #:html-inspector-views))
  (:export #:render-demo #:read-stored-page #:paragraph-reference
           #:stored-page #:unavailable-page #:unavailable-reason #:observation-configuration))
(in-package #:dreyeck/fedwiki-original-editor-demo)

;; Only this demo's hydrated code object gains a view. Its inherited id, text
;; and data remain those of the real page; no upstream renderer is replaced.
(defclass inspector-code-item (hyperbook/fedwiki::story-item)
  ((source :initarg :source :reader item-source)
   (configuration :initarg :configuration :reader item-configuration)))

(defclass stored-page ()
  ((source :initarg :source :reader source-of)
   (page :initarg :page :reader page-of)
   (configuration :initarg :configuration :reader observation-configuration)))

(defclass unavailable-page ()
  ((reason :initarg :reason :reader unavailable-reason)
   (configuration :initarg :configuration :reader observation-configuration))
  (:documentation "What a reading of the stored page gives when no page could be read: the configuration and why."))

(defun %read-stored-page (configuration)
  (let* ((root (cfg:configuration-root configuration))
         (slug (cfg:configuration-slug configuration))
         (wiki (lp:make-local-fedwiki root (cfg:configuration-site configuration)))
         (source (lp:observe-local-fedwiki-page-source root slug))
         (page (lp:make-local-fedwiki-page root wiki slug))
         (items (remove-if-not
                 (lambda (item) (and (eq :code (hyperbook/fedwiki::item-type-of item))
                                     (equal (cfg:configuration-code-item-id configuration)
                                            (hyperbook/fedwiki::id-of item))))
                 (coerce (hyperbook/fedwiki::story-of page) 'list))))
    (unless (= 1 (length items)) (error "The isolated Code target is not unique."))
    (change-class (first items) 'inspector-code-item :source source :configuration configuration)
    (make-instance 'stored-page :source source :page page :configuration configuration)))

(defun read-stored-page (&optional (configuration (cfg:editor-configuration)))
  "Read the actual JSON file again; do not reuse a hydrated page cache. Without a configured site, or when the page
cannot be read as the one isolated target, return an UNAVAILABLE-PAGE that says why, instead of signalling."
  (if (null (cfg:configuration-root configuration))
      (make-instance 'unavailable-page :configuration configuration
                                       :reason (cfg:mode-description configuration))
      (handler-case (%read-stored-page configuration)
        (error (condition)
          (make-instance 'unavailable-page :configuration configuration
                                           :reason (format nil "The configured site gives no readable target page: ~A" condition))))))

(defun %reread-button ()
  (v:eval-button "Read stored page again"
    (dreyeck/authority-policy:reviewed-thunk "fedwiki-original-editor-demo/reread"
      (read-stored-page))))

(defun render-configuration (configuration)
  (v:html
    (:h3 "Configuration")
    (:p (v:esc (cfg:mode-description configuration)))
    (:table :class "inspector-table"
      (:tr (:th "Target") (:td (:code (v:esc (cfg:configuration-site configuration))) " / "
                               (:code (v:esc (cfg:configuration-slug configuration))) " / "
                               (:code (v:esc (cfg:configuration-code-item-id configuration)))))
      (:tr (:th (:code (v:esc cfg:+root-variable+)))
           (:td (v:esc (if (cfg:configuration-root configuration) "set, directory found" "not used"))))
      (:tr (:th (:code (v:esc cfg:+origin-variable+)))
           (:td (v:esc (or (cfg:configuration-origin configuration) "not used"))))
      (:tr (:th (:code (v:esc cfg:+mode-variable+)))
           (:td (v:esc (or (cfg:configuration-requested-mode configuration) "not set (read-only)"))))
      (:tr (:th "Mode") (:td (:code (v:esc (string-downcase (cfg:configuration-mode configuration)))))))
    (when (cfg:configuration-problems configuration)
      (v:html (:ul :class "editor-configuration-problems"
                (dolist (problem (cfg:configuration-problems configuration))
                  (v:html (:li (v:esc problem)))))))
    (:p (v:object-ref configuration :display "Inspect this configuration"))))

(v:defview configuration-view (configuration cfg:editor-configuration)
  (v:html-view :title "Editor configuration" :priority 1
    (render-configuration configuration)))

(v:defview original-code-editor-view (item inspector-code-item)
  (v:html-view :title "Original Wiki editor" :priority 5
    (let* ((source (item-source item))
           (configuration (item-configuration item))
           (url (cfg:embedded-editor-url configuration (lp:page-source-sha256 source))))
      (v:html
        (:h2 "Original Code plugin editor")
        (:p "Target: " (:code (v:esc (cfg:configuration-site configuration))) " / "
            (:code (v:esc (lp:page-source-slug source))) " / "
            (:code (v:esc (hyperbook/fedwiki::id-of item))))
        (:p "Observed JSON SHA-256: " (:code (v:esc (lp:page-source-sha256 source))))
        (cond (url
               (v:html
                 (:iframe :class "original-code-editor" :title "Original Wiki Code editor"
                          :src url :sandbox "allow-scripts allow-same-origin"
                          :style "width:100%;height:430px;border:1px solid #aaa;" "")
                 (:p "The frame has its own Wiki origin and the original client runtime. Only the selected Item is exposed. Click outside the Item to save, then verify from disk:")))
              (t
               (v:html
                 (:p :class "original-code-editor-withheld"
                     "The embedded editor is not offered in this Catalog. "
                     (v:esc (cfg:mode-description configuration)))
                 (render-configuration configuration))))
        (%reread-button)))))

(dreyeck/authority-policy:register-reviewed-control
 "fedwiki-original-editor-demo/reread"
 :effect "Read one configured disposable site's original-editor-test JSON page; construct a fresh observation and hydrated page, or say why none could be read. No writes or network."
 :audit "read-stored-page in dreyeck/src/fedwiki-original-editor-demo.lisp; browser test compares the reread with the original server's persisted bytes; dreyeck/tests/fedwiki-original-editor-demo.lisp checks the unconfigured and unreadable cases")

(defun paragraph-reference (page)
  "Read the explicit coordinate of one P in the real HyperDoc parse tree."
  (let ((node (find "test-paragraph-reference"
                    (plump:get-elements-by-tag-name (hyperdoc::dom-of page) "p")
                    :key (lambda (p) (plump:attribute p "id")) :test #'equal)))
    (unless node (error "The explicitly marked paragraph is absent."))
    (loop for attribute in '("data-fedwiki-site" "data-fedwiki-slug" "data-fedwiki-item-id")
          collect (or (plump:attribute node attribute)
                      (error "Missing coordinate ~A" attribute)))))

(defun render-unavailable (observation)
  (v:html
    (:h2 "Stored Wiki page")
    (:p :class "stored-page-unavailable" (v:esc (unavailable-reason observation)))
    (:p "Nothing was written. HyperDoc never writes this site.")
    (render-configuration (observation-configuration observation))
    (when (cfg:configuration-root (observation-configuration observation))
      (%reread-button))))

(defun render-stored-page (observation)
  (if (typep observation 'unavailable-page)
      (render-unavailable observation)
      (let ((source (source-of observation)) (page (page-of observation)))
        (v:html
          (:h2 "Stored Wiki page")
          (:p "JSON file: " (:code (v:esc (namestring (lp:page-source-pathname source)))))
          (:p "SHA-256: " (:code (v:esc (lp:page-source-sha256 source))))
          ;; Invoke the existing generic renderer, without loading Verified Examples.
          (loop for item across (hyperbook/fedwiki::story-of page)
                do (hyperbook/fedwiki::render-story-item
                    (hyperbook/fedwiki::item-type-of item) item page))
          (:h3 "JSON read from disk (including journal)")
          (:pre :class "persisted-json" (v:esc (shasht:write-json (lp:page-source-json source) nil)))
          (%reread-button)))))

(v:defview stored-page-view (observation stored-page)
  (v:html-view :title "Stored Wiki page" :priority 1
    (render-stored-page observation)))

(v:defview unavailable-page-view (observation unavailable-page)
  (v:html-view :title "Stored Wiki page" :priority 1
    (render-unavailable observation)))

(defun render-demo (&optional (configuration (cfg:editor-configuration)))
  "The page's generated part. It never signals for a missing or unusable configuration: it says what is not configured."
  (let ((client (cfg:client-url configuration)))
    (cond ((eq :unconfigured (cfg:configuration-mode configuration))
           (v:html
             (:p :class "editor-demo-unconfigured"
                 "This Catalog has no isolated test site configured. The demonstration is shown read-only: "
                 "no Wiki page is read or written here, no Wiki client is linked and no editor is embedded.")
             (render-configuration configuration)))
          (t
           (when client
             (v:html
               (:p (:a :href client :target "_blank" :rel "noopener" "Open original Wiki client"))))
           (render-stored-page (read-stored-page configuration))))))

(hyperdoc:defhyperdoc *demo*
  :id "dreyeck/fedwiki-original-editor-demo"
  :title "Original Wiki Editor Test"
  :asdf-system-name "dreyeck/fedwiki-original-editor-demo"
  :subdirectory "dreyeck/pages/fedwiki-original-editor-demo"
  :main-page-id "Editing One Isolated Wiki Page")
