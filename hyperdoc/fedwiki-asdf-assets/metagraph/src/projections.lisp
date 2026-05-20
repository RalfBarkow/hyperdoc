;;;; Topicmap projection and rendered DM6/AppEmbed Topic Map helpers.

(in-package #:metagraph-as-bipartite-graph-json-ld--fluree)

(defparameter *mg-dm6-bundle-path* "/assets/dm6-elm/app.js")
(defparameter *mg-dm6-css-path* "/assets/dm6-elm/hyperdoc-dm6-inline.css")
(defparameter *mg-dm6-inline-js-path* "/assets/dm6-elm/hyperdoc-dm6-inline.js")
(defparameter *mg-page-asset-path-prefix*
  "/assets/pages/metagraph-as-bipartite-graph-json-ld--fluree/")

(defun mg-configure-rendered-topicmap-paths
    (&key dm6-bundle css inline-js page-asset-prefix)
  (when dm6-bundle
    (setf *mg-dm6-bundle-path* dm6-bundle))
  (when css
    (setf *mg-dm6-css-path* css))
  (when inline-js
    (setf *mg-dm6-inline-js-path* inline-js))
  (when page-asset-prefix
    (setf *mg-page-asset-path-prefix* page-asset-prefix))
  (list :dm6-bundle *mg-dm6-bundle-path*
        :dm6-css *mg-dm6-css-path*
        :dm6-inline-js *mg-dm6-inline-js-path*
        :page-asset-prefix *mg-page-asset-path-prefix*))

(defun mg-dm6-asset-url (path)
  path)

(defun mg-page-asset-url (path)
  path)

(defclass mg-topicmap-projection ()
  ((key :reader mg-topicmap-projection-key :initarg :key)
   (title :reader mg-topicmap-projection-title :initarg :title)
   (slug :reader mg-topicmap-projection-slug :initarg :slug)
   (description :reader mg-topicmap-projection-description :initarg :description)
   (semantic-topicmap :reader mg-topicmap-projection-semantic-topicmap
                      :initarg :semantic-topicmap)
   (native-topicmap :reader mg-topicmap-projection-native-topicmap
                    :initarg :native-topicmap)))

(defmethod print-object ((projection mg-topicmap-projection) stream)
  (print-unreadable-object (projection stream :type t :identity nil)
    (format stream "~A, ~D native topics"
            (mg-topicmap-projection-title projection)
            (length (cdr (assoc "topics"
                                (mg-topicmap-projection-native-topicmap projection)
                                :test #'string=))))))

(defun mg-topicmap-projection-spec (which)
  (ecase which
    (:conversation-story
     (list :key :conversation-story
           :title "Conversation Story: Metagraph ASDF Asset Workflow"
           :slug "metagraph-conversation-story-topicmap"
           :description "The repaired workflow from source topic to tested page-local ASDF asset."
           :semantic (mg-conversation-story-topicmap)
           :native (mg-conversation-story-topicmap-native)))
    (:layer-contract
     (list :key :layer-contract
           :title "Metagraph N/E/S Layer Contract"
           :slug "metagraph-layer-contract-topicmap"
           :description "Allowed and disallowed layer transitions for N, E, and S nodes."
           :semantic (mg-layer-contract-topicmap)
           :native (mg-layer-contract-topicmap-native)))
    (:planning-example
     (list :key :planning-example
           :title "Metagraph N/E/S Planning Example"
           :slug "metagraph-planning-example-topicmap"
           :description "Concrete Q2 planning example with entity, relationship, and context nodes."
           :semantic (mg-planning-topicmap)
           :native (mg-planning-topicmap-native)))))

(defun mg-topicmap-projection (&optional (which :conversation-story))
  (let ((spec (mg-topicmap-projection-spec which)))
    (make-instance 'mg-topicmap-projection
                   :key (getf spec :key)
                   :title (getf spec :title)
                   :slug (getf spec :slug)
                   :description (getf spec :description)
                   :semantic-topicmap (getf spec :semantic)
                   :native-topicmap (getf spec :native))))

(defun mg-all-topicmap-projections ()
  (mapcar #'mg-topicmap-projection
          '(:conversation-story :layer-contract :planning-example)))

(defun mg-native-topicmap-json (native-topicmap)
  (with-output-to-string (stream)
    (let ((shasht:*write-alist-as-object* t))
      (shasht:write-json native-topicmap stream))))

(defun mg-topicmap-projection-json (projection)
  (mg-native-topicmap-json (mg-topicmap-projection-native-topicmap projection)))

(defun mg-html-escape (value)
  (with-output-to-string (stream)
    (loop for ch across (format nil "~A" value)
          do (case ch
               (#\& (write-string "&amp;" stream))
               (#\< (write-string "&lt;" stream))
               (#\> (write-string "&gt;" stream))
               (#\" (write-string "&quot;" stream))
               (#\' (write-string "&#39;" stream))
               (t (write-char ch stream))))))

(defun mg-rendered-topicmap-island (projection)
  (let ((json (mg-topicmap-projection-json projection))
        (slug (mg-html-escape (mg-topicmap-projection-slug projection)))
        (title (mg-html-escape (mg-topicmap-projection-title projection)))
        (description (mg-html-escape
                      (mg-topicmap-projection-description projection)))
        (bundle (mg-html-escape (mg-dm6-asset-url *mg-dm6-bundle-path*))))
    (format nil
            "<section class=\"dm6-hyperdoc-map dm6-island\" data-dm6-slug=\"~A\" data-dm6-bundle=\"~A\">~%~
  <header class=\"dm6-island-header\">~%~
    <div class=\"dm6-island-title\">~%~
      <h2>DM6 Topic Map</h2>~%~
      <span class=\"dm6-island-subtitle\">~A</span>~%~
    </div>~%~
    <nav class=\"dm6-toolbar\" aria-label=\"dm6 controls\">~%~
      <button type=\"button\" data-dm6-action=\"select\">Select</button>~%~
      <button type=\"button\" data-dm6-action=\"move\">Move</button>~%~
      <button type=\"button\" data-dm6-action=\"cross\">Cross</button>~%~
      <button type=\"button\" data-dm6-action=\"fit\">Fit</button>~%~
      <button type=\"button\" data-dm6-action=\"reset\">Reset</button>~%~
      <button type=\"button\" data-dm6-action=\"evidence\">Evidence</button>~%~
    </nav>~%~
  </header>~%~
  <div class=\"dm6-mode-banner\">~%~
    <span><b>Input owner:</b> <span class=\"dm6-input-owner\">page</span></span>~%~
    <span><b>Mode:</b> <span class=\"dm6-mode\">select</span></span>~%~
    <span><b>HyperDoc:</b> <span class=\"dm6-hyperdoc-state\">projection rendered from Lisp asset</span></span>~%~
  </div>~%~
  <div class=\"dm6-canvas\"><div class=\"dm6-stage\">dm6 AppEmbed mount pending...</div></div>~%~
  <div class=\"dm6-success-card\">~%~
    <div><strong class=\"dm6-mount-summary\">dm6 mounting...</strong><br>Projection: ~A</div>~%~
    <div><b>Status:</b> <span class=\"dm6-status\">not mounted</span></div>~%~
  </div>~%~
  <details class=\"dm6-evidence-drawer\">~%~
    <summary>Evidence timeline: <span class=\"dm6-evidence-count\">0</span> events - last: <span class=\"dm6-evidence-last\">none</span></summary>~%~
    <div class=\"dm6-evidence-panel\">~%~
      <div class=\"dm6-evidence-actions\">~%~
        <button type=\"button\" data-dm6-evidence-copy>Copy JSON</button>~%~
        <button type=\"button\" data-dm6-evidence-clear>Clear</button>~%~
        <button type=\"button\" data-dm6-evidence-download>Download</button>~%~
      </div>~%~
      <h3>Evidence summary</h3><pre class=\"dm6-evidence-summary\">{}</pre>~%~
      <h3>Raw events</h3><pre class=\"dm6-evidence\"></pre>~%~
      <h3>Stored model supplied to AppEmbed</h3><pre class=\"dm6-stored-visible\">{}</pre>~%~
    </div>~%~
  </details>~%~
  <script type=\"application/json\" class=\"dm6-stored\" data-dm6-generated=\"metagraph-projection-v4\">~%~A~%</script>~%~
</section>~%"
            slug
            bundle
            title
            description
            json)))

(defun mg-rendered-topicmap-html (projection)
  (let ((title (mg-html-escape (mg-topicmap-projection-title projection)))
        (description (mg-html-escape
                      (mg-topicmap-projection-description projection)))
        (css-path (mg-html-escape (mg-dm6-asset-url *mg-dm6-css-path*)))
        (inline-js-path
          (mg-html-escape (mg-dm6-asset-url *mg-dm6-inline-js-path*))))
    (format nil
            "<!doctype html>~%~
<meta charset=\"utf-8\">~%~
<title>~A</title>~%~
<link rel=\"stylesheet\" href=\"~A\">~%~
<style>body{margin:0;font:14px system-ui,sans-serif;background:#eef4f8}.page{padding:12px}.intro{margin:0 0 12px;padding:10px 12px;background:#f8fbfd;border:1px solid #dbe5ee;border-radius:8px}.intro h1{margin:0 0 4px;font-size:18px}.intro p{margin:0;color:#435466}</style>~%~
<div class=\"page\">~%~
  <section class=\"intro\"><h1>~A</h1><p>~A</p></section>~%~
  ~A~%~
</div>~%~
<script src=\"~A\"></script>~%~
<script>~%~
(function () {~%~
  function boot() {~%~
    if (window.hyperdocDm6Inline) {~%~
      window.hyperdocDm6Inline.mountAll(document);~%~
    }~%~
  }~%~
  if (document.readyState === \"loading\") {~%~
    document.addEventListener(\"DOMContentLoaded\", boot);~%~
  } else {~%~
    boot();~%~
  }~%~
}());~%~
</script>~%"
            title
            css-path
            title
            description
            (mg-rendered-topicmap-island projection)
            inline-js-path)))

(defun mg-projection-output-directory ()
  (merge-pathnames
   "pages/"
   (asdf:system-source-directory
    :metagraph-as-bipartite-graph-json-ld--fluree)))

(defun mg-rendered-topicmap-pathname (projection)
  (merge-pathnames
   (format nil "~A.html" (mg-topicmap-projection-slug projection))
   (mg-projection-output-directory)))

(defun mg-write-rendered-topicmap (which &key pathname)
  (let* ((projection (if (typep which 'mg-topicmap-projection)
                         which
                         (mg-topicmap-projection which)))
         (target (or pathname (mg-rendered-topicmap-pathname projection))))
    (ensure-directories-exist target)
    (with-open-file (stream target
                            :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create
                            :external-format :utf-8)
      (write-string (mg-rendered-topicmap-html projection) stream))
    target))

(defun mg-write-all-rendered-topicmaps ()
  (mapcar #'mg-write-rendered-topicmap
          (mg-all-topicmap-projections)))

(defun mg-rendered-topicmap-url (projection)
  (format nil "~Apages/~A.html"
          *mg-page-asset-path-prefix*
          (mg-topicmap-projection-slug projection)))

(defun mg-hyperdoc-open-browser (url)
  (let* ((clog-package (find-package "CLOG"))
         (open-browser (and clog-package
                            (find-symbol "OPEN-BROWSER" clog-package))))
    (cond
      ((and open-browser (fboundp open-browser))
       (funcall (symbol-function open-browser) :url url))
      ((and (> (length url) 0)
            (char= (char url 0) #\/))
       (format t "~&Open in the HyperDoc browser: ~A~%" url))
      (t
       (format t "~&Open in browser: ~A~%" url))))
  url)

(defun mg-open-rendered-topicmap (&optional (which :conversation-story))
  (let ((projection (if (typep which 'mg-topicmap-projection)
                        which
                        (mg-topicmap-projection which))))
    (mg-write-rendered-topicmap projection)
    (mg-hyperdoc-open-browser (mg-rendered-topicmap-url projection))))

(defun mg-open-all-rendered-topicmaps ()
  (mapcar #'mg-open-rendered-topicmap
          '(:conversation-story :layer-contract :planning-example)))

(defun mg-inspect-topicmap-projection (&optional (which :conversation-story))
  (mg-inspect-rendered-topicmap which))
