;;;; Installation and inspector helpers for the HyperDoc image.

(in-package #:metagraph-as-bipartite-graph-json-ld--fluree)

(defparameter *installed-topicmaps* nil)
(defvar *mg-inspector-views-installed-p* nil)

(defclass mg-inspector-views-diagnostic ()
  ((status :reader mg-inspector-views-diagnostic-status :initarg :status)
   (message :reader mg-inspector-views-diagnostic-message :initarg :message)
   (action :reader mg-inspector-views-diagnostic-action :initarg :action)))

(defmethod print-object ((diagnostic mg-inspector-views-diagnostic) stream)
  (print-unreadable-object (diagnostic stream :type t :identity nil)
    (format stream "~A" (mg-inspector-views-diagnostic-status diagnostic))))

(defun mg-inspector-diagnostic (status message action)
  (make-instance 'mg-inspector-views-diagnostic
                 :status status
                 :message message
                 :action action))

(defun mg-call-clog-inspector (object)
  (let* ((pkg (find-package "CLOG-MOLDABLE-INSPECTOR"))
         (sym (and pkg (find-symbol "CLOG-INSPECT" pkg))))
    (if (and sym (fboundp sym))
        (funcall sym :object object)
        object)))

(defun mg-inspect-layer-contract-topicmap (&key (native t))
  (mg-call-clog-inspector
   (if native
       (mg-layer-contract-topicmap-native)
       (mg-layer-contract-topicmap))))

(defun mg-inspect-planning-topicmap (&key (native t))
  (mg-call-clog-inspector
   (if native
       (mg-planning-topicmap-native)
       (mg-planning-topicmap))))

(defun mg-inspect-conversation-story-topicmap (&key (native t))
  (mg-call-clog-inspector
   (if native
       (mg-conversation-story-topicmap-native)
       (mg-conversation-story-topicmap))))

(defun mg-views-ready-p ()
  (let ((pkg (find-package "HTML-INSPECTOR-VIEWS")))
    (and pkg
         (find-symbol "DEFVIEW" pkg)
         (find-symbol "HTML-VIEW" pkg)
         (find-symbol "INCLUDE-CSS" pkg)
         (find-symbol "INCLUDE-JS" pkg)
         (find-symbol "INCLUDE-SCRIPT" pkg)
         (find-symbol "HTML" pkg)
         (find-symbol "STR" pkg))))

(defun mg-ensure-inspector-views (&key force)
  (cond
    ((and *mg-inspector-views-installed-p* (not force))
     :already-installed)
    ((not (mg-views-ready-p))
     (mg-inspector-diagnostic
      :inspector-not-loaded
      "HyperDoc inspector views are not loaded in this image."
      "(asdf:load-system :hyperdoc/server), then call MG-ENSURE-INSPECTOR-VIEWS again."))
    (t
     (eval
      (let ((*package*
              (find-package
               "METAGRAPH-AS-BIPARTITE-GRAPH-JSON-LD--FLUREE")))
        (read-from-string
         "(progn
          (in-package #:metagraph-as-bipartite-graph-json-ld--fluree)

          (defun mg-include-dm6-inspector-assets ()
            (html-inspector-views:include-css
             \"/assets/dm6-elm/hyperdoc-dm6-inline.css\")
            (html-inspector-views:include-js
             \"/assets/dm6-elm/hyperdoc-dm6-inline.js\")
            (html-inspector-views:include-script
             \"(function mountMetagraphDm6Topicmaps(attempt) {
                var scope = window.currentInspectorView || document;
                if (window.hyperdocDm6Inline &&
                    typeof window.hyperdocDm6Inline.mountAll === 'function') {
                  window.hyperdocDm6Inline.mountAll(scope);
                  return;
                }
                if ((attempt || 0) >= 80) {
                  return;
                }
                window.setTimeout(function () {
                  mountMetagraphDm6Topicmaps((attempt || 0) + 1);
                }, 50);
              }(0));\"))

          (html-inspector-views:defview mg-topic-map-view
              (projection mg-topicmap-projection)
            (html-inspector-views:html-view
             :title \"Topic Map\"
             :priority 1
             (mg-include-dm6-inspector-assets)
             (html-inspector-views:html
              (html-inspector-views:str
               (mg-rendered-topicmap-island projection)))))

          (html-inspector-views:defview mg-native-model-view
              (projection mg-topicmap-projection)
            (html-inspector-views:html-view
             :title \"Native Model\"
             :priority 2
             (html-inspector-views:html
              (:p \"The JSON-ish native DM6/AppEmbed model supplied to script.dm6-stored.\")
              (html-inspector-views:object-ref
               (mg-topicmap-projection-native-topicmap projection)))))

          (html-inspector-views:defview mg-semantic-model-view
              (projection mg-topicmap-projection)
            (html-inspector-views:html-view
             :title \"Semantic Model\"
             :priority 3
             (html-inspector-views:html
              (:p \"The N/E/S semantic topicmap before DM6-native projection.\")
              (html-inspector-views:object-ref
               (mg-topicmap-projection-semantic-topicmap projection)))))

          (html-inspector-views:defview mg-rendered-html-view
              (projection mg-topicmap-projection)
            (html-inspector-views:html-code-view
             (mg-rendered-topicmap-html projection)
             :title \"Rendered HTML\"
             :priority 4)))")))
     (setf *mg-inspector-views-installed-p* t)
     :installed)))

(defun mg-inspect-rendered-topicmap (&optional (which :conversation-story))
  (let ((ensure-result (mg-ensure-inspector-views)))
    (if (typep ensure-result 'mg-inspector-views-diagnostic)
        ensure-result
        (mg-call-clog-inspector
         (if (typep which 'mg-topicmap-projection)
             which
             (mg-topicmap-projection which))))))

(defun mg-installation-steps ()
  '((:step 1
     :title "Materialize assets from HyperDoc"
     :action "(write-page-asdf-system *metagraph-spec* :clean t)")
    (:step 2
     :title "Load exact ASDF pathname"
     :action "(load-page-asdf-system *metagraph-spec* :force t)")
    (:step 3
     :title "Run smoke tests"
     :action "(test-page-asdf-system *metagraph-spec*)")
    (:step 4
     :title "Inspect projection objects"
     :action "(inspect-page-asdf-system *metagraph-spec*)")
    (:step 5
     :title "Render pages and create deployable ZIP"
     :action "(page-asdf-asset-workflow *metagraph-spec* :clean t :force t :test t :inspect t :zip t)")))

(defun mg-installation-report ()
  (let ((story (mg-conversation-story-topicmap-native))
        (planning (mg-planning-topicmap-native))
        (contract (mg-layer-contract-topicmap-native)))
    (list :system :metagraph-as-bipartite-graph-json-ld--fluree
          :source-topic-id *source-topic-id*
          :source-title *source-title*
          :native-topicmaps
          (list :conversation-story (mg-native-topicmap-p story)
                :planning-example (mg-native-topicmap-p planning)
                :layer-contract (mg-native-topicmap-p contract))
          :topicmap-projections
          (mapcar #'mg-topicmap-projection-key
                  (mg-all-topicmap-projections)))))

(defun mg-install-into-hyperdoc-image ()
  (setf *installed-topicmaps* (mg-all-topicmaps-native))
  (mg-write-all-rendered-topicmaps)
  (when (mg-views-ready-p)
    (mg-ensure-inspector-views))
  (mg-installation-report))
