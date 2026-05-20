;;;; Native inspector views for generic topicmap projections.

(in-package :hyperdoc/inspector)

(defun include-topicmap-view-assets ()
  (views:add-asset-path "/dm6-elm/"
                        (asdf:system-relative-pathname
                         :hyperdoc
                         "assets/dm6-elm/"))
  (views:include-css "/dm6-elm/hyperdoc-dm6-inline.css")
  (views:include-js "/dm6-elm/hyperdoc-dm6-inline.js")
  (views:include-script
   "(function mountHyperDocInlineTopicmaps(attempt) {
      if (window.hyperdocDm6Inline &&
          typeof window.hyperdocDm6Inline.mountAll === 'function') {
        window.hyperdocDm6Inline.mountAll(window.currentInspectorView || document);
        return;
      }
      if ((attempt || 0) >= 40) {
        return;
      }
      window.setTimeout(function () {
        mountHyperDocInlineTopicmaps((attempt || 0) + 1);
      }, 50);
    }(0));"))

(defun topicmap-view-html-view (title priority raw-html)
  (when raw-html
    (views:html-view :title title :priority priority
      (include-topicmap-view-assets)
      (views:html
       (views:str raw-html)))))

(defun inspect-object-with-native-inspector (object)
  (let* ((package (find-package "CLOG-MOLDABLE-INSPECTOR"))
         (inspect-symbol (and package
                              (find-symbol "CLOG-INSPECT" package))))
    (unless inspect-symbol
      (error "CLOG-MOLDABLE-INSPECTOR:CLOG-INSPECT is not loaded."))
    (funcall inspect-symbol :object object)))

(defvar *topicmap-inspector-invoker* #'inspect-object-with-native-inspector)

(defun topicmap-inspection-target (object)
  (or (ignore-errors
        (hyperdoc:topicmap-projection-of object))
      object))

(defun inspect-topicmap-view (object)
  "Open the native inspector on OBJECT's topicmap projection.

If OBJECT can be projected with HYPERDOC:TOPICMAP-PROJECTION-OF, inspect
that projection so the primary Content view is the rendered DM6 inline
topicmap island. If projection fails, fall back to OBJECT. Return the inspected
target so noninteractive callers can verify dispatch without depending on a
browser side effect."
  (let ((target (topicmap-inspection-target object)))
    (funcall *topicmap-inspector-invoker* target)
    target))

(defun hyperdoc:inspect-artifact-content (artifact-or-path)
  (let ((target (hyperdoc:content-target-of
                 (hyperdoc:ensure-file-artifact artifact-or-path))))
    (inspect-object-with-native-inspector target)
    target))

(defun hyperdoc:inspect-topicmap-view (object)
  (inspect-topicmap-view object))

(views:defview views:👀content (projection hyperdoc:topicmap-projection)
  (topicmap-view-html-view
   "Content"
   1
   (hyperdoc:render-inline-topicmap-projection-html
    projection
    :asset-prefix "/dm6-elm/"
    :include-assets-p nil
    :title (hyperdoc:topicmap-view-title-of projection))))

(views:defview views:👀content (view hyperdoc:inline-topicmap-view)
  (topicmap-view-html-view
   "Content"
   1
   (hyperdoc:render-inline-topicmap-view-html
    view
    :asset-prefix "/dm6-elm/"
    :include-assets-p nil)))

(views:defview 👀topicmap (object t)
  (unless (or (typep object 'hyperdoc:topicmap-projection)
              (typep object 'hyperdoc:inline-topicmap-view))
    (let ((html (hyperdoc:render-topicmap-view-of-object-html
                 object
                 :asset-prefix "/dm6-elm/"
                 :include-assets-p nil)))
      (topicmap-view-html-view "Topicmap" 2 html))))
