;;;; Read-only demonstration. Only the original Node server writes the test site.
(defpackage #:dreyeck/fedwiki-original-editor-demo
  (:use #:cl)
  (:local-nicknames (#:lp #:dreyeck/local-fedwiki-page)
                    (#:v #:html-inspector-views))
  (:export #:render-demo #:read-stored-page #:paragraph-reference))
(in-package #:dreyeck/fedwiki-original-editor-demo)

(defparameter +slug+ "original-editor-test")
(defparameter +site+ "fedwiki:original-editor-test.invalid")

(defun test-root ()
  (let ((root (uiop:getenv "HYPERDOC_FEDWIKI_EDITOR_TEST_ROOT")))
    (unless root (error "No isolated original-editor test site configured."))
    (truename (uiop:ensure-directory-pathname root))))

(defclass stored-page ()
  ((source :initarg :source :reader source-of)
   (page :initarg :page :reader page-of)))

(defun read-stored-page ()
  "Read the actual JSON file again; do not reuse a hydrated page cache."
  (let* ((root (test-root))
         (wiki (lp:make-local-fedwiki root +site+)))
    (make-instance 'stored-page
                   :source (lp:observe-local-fedwiki-page-source root +slug+)
                   :page (lp:make-local-fedwiki-page root wiki +slug+))))

(dreyeck/authority-policy:register-reviewed-control
 "fedwiki-original-editor-demo/reread"
 :effect "Read one configured disposable site's original-editor-test JSON page; construct a fresh observation and hydrated page. No writes or network."
 :audit "read-stored-page in dreyeck/src/fedwiki-original-editor-demo.lisp; browser test compares the reread with the original server's persisted bytes")

(defun paragraph-reference (page)
  "Read the explicit coordinate of one P in the real HyperDoc parse tree."
  (let ((node (find "test-paragraph-reference"
                    (plump:get-elements-by-tag-name (hyperdoc::dom-of page) "p")
                    :key (lambda (p) (plump:attribute p "id")) :test #'equal)))
    (unless node (error "The explicitly marked paragraph is absent."))
    (loop for attribute in '("data-fedwiki-site" "data-fedwiki-slug" "data-fedwiki-item-id")
          collect (or (plump:attribute node attribute)
                      (error "Missing coordinate ~A" attribute)))))

(defun render-stored-page (observation)
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
      (v:eval-button "Read stored page again"
        (dreyeck/authority-policy:reviewed-thunk "fedwiki-original-editor-demo/reread"
          (read-stored-page))))))

(v:defview stored-page-view (observation stored-page)
  (v:html-view :title "Stored Wiki page" :priority 1
    (render-stored-page observation)))

(defun render-demo ()
  (let ((origin (uiop:getenv "HYPERDOC_FEDWIKI_EDITOR_TEST_ORIGIN")))
    (unless origin (error "No original Wiki client origin configured."))
    (v:html
      (:p (:a :href (format nil "~A/view/~A" origin +slug+) :target "_blank"
              :rel "noopener" "Open original Wiki client")))
    (render-stored-page (read-stored-page))))

(hyperdoc:defhyperdoc *demo*
  :id "dreyeck/fedwiki-original-editor-demo"
  :title "Original Wiki Editor Test"
  :asdf-system-name "dreyeck/fedwiki-original-editor-demo"
  :subdirectory "dreyeck/pages/fedwiki-original-editor-demo"
  :main-page-id "Editing One Isolated Wiki Page")
