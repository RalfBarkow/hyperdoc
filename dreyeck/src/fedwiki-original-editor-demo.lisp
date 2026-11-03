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
(defclass inspector-item (hyperbook/fedwiki::story-item)
  ((source :initarg :source :reader item-source)
   (configuration :initarg :configuration :reader item-configuration))
  (:documentation "A Story Item of the stored page that this demonstration lets the original Wiki editor change. It is the page's own
Item, found by its id; its site, slug and id are those of the stored page and nothing is copied out of it."))
(defclass inspector-code-item (inspector-item) ())
(defclass inspector-paragraph-item (inspector-item) ())

(defclass stored-page ()
  ((source :initarg :source :reader source-of)
   (page :initarg :page :reader page-of)
   (configuration :initarg :configuration :reader observation-configuration)))

(defclass unavailable-page ()
  ((reason :initarg :reason :reader unavailable-reason)
   (configuration :initarg :configuration :reader observation-configuration))
  (:documentation "What a reading of the stored page gives when no page could be read: the configuration and why."))

(defun %declared-items (configuration)
  "The Items of the stored page that become Inspector objects: (id type class), selected by id, never by position."
  (list (list (cfg:configuration-code-item-id configuration) :code 'inspector-code-item)
        (list cfg:+paragraph-item-id+ :paragraph 'inspector-paragraph-item)))

(defun %read-stored-page (configuration)
  (let* ((root (cfg:configuration-root configuration))
         (slug (cfg:configuration-slug configuration))
         (wiki (lp:make-local-fedwiki root (cfg:configuration-site configuration)))
         (source (lp:observe-local-fedwiki-page-source root slug))
         (page (lp:make-local-fedwiki-page root wiki slug))
         (story (coerce (hyperbook/fedwiki::story-of page) 'list)))
    (loop for (id type class) in (%declared-items configuration)
          for items = (remove-if-not (lambda (item) (and (eq type (hyperbook/fedwiki::item-type-of item))
                                                         (equal id (hyperbook/fedwiki::id-of item))))
                                     story)
          do (unless (= 1 (length items)) (error "The isolated ~(~A~) target is not unique." type))
             (change-class (first items) class :source source :configuration configuration))
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

(defun %editor-view-body (item heading frame-class frame-title intro frame-url)
  "The Inspector view of a Story Item with the original Wiki editor of its type in a frame. FRAME-URL, a function of the
configuration, the page slug, the Item id and the observed revision, names the Item by the coordinate it carries."
  (let* ((source (item-source item))
         (configuration (item-configuration item))
         (url (funcall frame-url configuration (lp:page-source-slug source) (hyperbook/fedwiki::id-of item)
                       (lp:page-source-sha256 source))))
    (v:html
      (:h2 (v:esc heading))
      (:p "Target: " (:code (v:esc (cfg:configuration-site configuration))) " / "
          (:code (v:esc (lp:page-source-slug source))) " / "
          (:code (v:esc (hyperbook/fedwiki::id-of item))))
      (:p "Observed JSON SHA-256: " (:code (v:esc (lp:page-source-sha256 source))))
      (cond (url
             (v:html
               (:iframe :class frame-class :title frame-title
                        :src url :sandbox "allow-scripts allow-same-origin"
                        :style "width:100%;height:430px;border:1px solid #aaa;" "")
               (:p (v:esc intro))))
            (t
             (v:html
               (:p :class "original-code-editor-withheld"
                   "The embedded editor is not offered in this Catalog. "
                   (v:esc (cfg:mode-description configuration)))
               (render-configuration configuration))))
      (%reread-button))))

(v:defview original-code-editor-view (item inspector-code-item)
  (v:html-view :title "Original Wiki editor" :priority 5
    (%editor-view-body item "Original Code plugin editor" "original-code-editor" "Original Wiki Code editor"
                       "The frame has its own Wiki origin and the original client runtime. Only the selected Item is exposed. Click outside the Item to save, then verify from disk:"
                       ;; The Code Item keeps its established frame parameter.
                       (lambda (configuration slug id revision)
                         (declare (ignore slug id))
                         (cfg:embedded-editor-url configuration revision)))))

(v:defview original-paragraph-editor-view (item inspector-paragraph-item)
  (v:html-view :title "Original Wiki editor" :priority 5
    (%editor-view-body item "Original Paragraph editor" "original-paragraph-editor" "Original Wiki Paragraph editor"
                       "The frame has its own Wiki origin and the original client runtime; its original text editor changes this Item. Activate Edit with original Wiki plugin, change the text, click the frame's status text outside the Item to save, then read the stored page again:"
                       #'cfg:embedded-item-editor-url)))

;; The existing Story view renders a Paragraph Item as a bare P. For the Item this demonstration lets be edited, the P also
;; carries the Item's coordinate (site, slug, id) and an Inspector reference to the Item itself. The text is still the
;; upstream renderer's: wiki links resolve as before.
(defmethod hyperbook/fedwiki::render-story-item ((type (eql :paragraph)) (item inspector-paragraph-item) page)
  (let ((source (item-source item)))
    (v:html
      (:p :class "story-paragraph"
          :data-fedwiki-site (cfg:configuration-site (item-configuration item))
          :data-fedwiki-slug (lp:page-source-slug source)
          :data-fedwiki-item-id (hyperbook/fedwiki::id-of item)
          (hyperbook/fedwiki::render-wiki-text (hyperbook/fedwiki::text-of item) page)
          " "
          (:small (v:object-ref item :display "paragraph"))))))

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
          ;; The page's existing Story view, transcluded: the Wiki page is shown as every Wiki page is.
          (v:transclusion (find "Story" (v:all-views page) :key #'v:view-title :test #'string=))
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
