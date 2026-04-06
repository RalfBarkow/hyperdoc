;;;; Shared Graphviz rendering helpers for HyperDoc inspector views
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc/inspector)

(defun include-graphviz-assets ()
  (views:add-asset-path "/hyperdoc/"
                        (asdf:system-relative-pathname
                         :hyperdoc
                         "assets/hyperdoc/"))
  (views:include-css "/hyperdoc/css/graphviz.css")
  (views:include-js "/hyperdoc/js/viz@3.22.0/viz-global.js")
  (views:include-js "/hyperdoc/js/graphviz.js")
  (views:include-script
   "(function initHyperdocGraphviz(attempt) {
      if (window.hyperdocGraphviz &&
          typeof window.hyperdocGraphviz.initCurrentView === 'function') {
        window.hyperdocGraphviz.initCurrentView();
        return;
      }
      if ((attempt || 0) >= 40) {
        return;
      }
      window.setTimeout(function () {
        initHyperdocGraphviz((attempt || 0) + 1);
      }, 50);
    }(0));"))

(defun render-graphviz-dot (dot-text &key (fallback-title "Derived DOT source"))
  (let ((dot (or dot-text "")))
    (views:html
      (:div :class "hyperdoc-graphviz"
            :data-hyperdoc-graphviz "true"
            :data-hyperdoc-graphviz-state "pending"
            ;; Keep DOT in an HTML-decoded attribute instead of script raw text,
            ;; so entity escaping is reversed by the parser before JS reads it.
            :data-hyperdoc-graphviz-dot dot
            (:div :class "hyperdoc-graphviz-canvas"
                  (:p :class "hyperdoc-graphviz-pending"
                      (views:esc "Rendering Graphviz diagram...")))
            (:details :class "hyperdoc-graphviz-dot-fallback"
                      (:summary (views:esc fallback-title))
                      (:pre (views:esc dot)))))))
