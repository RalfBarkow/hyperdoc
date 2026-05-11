;;;; Inspectable FedWiki story-item rendering demos
;;
;;;; Demonstrates the Graphviz shape regression and the :HTML trust boundary.

(in-package :hyperdoc/inspector)

(defclass fedwiki-story-item-rendering-demo ()
  ((kind
    :reader fedwiki-story-item-rendering-demo-kind-of
    :initarg :kind)
   (title
    :reader fedwiki-story-item-rendering-demo-title-of
    :initarg :title)
   (item-type
    :reader fedwiki-story-item-rendering-demo-item-type-of
    :initarg :item-type)
   (text
    :reader fedwiki-story-item-rendering-demo-text-of
    :initarg :text)
   (data
    :reader fedwiki-story-item-rendering-demo-data-of
    :initarg :data
    :initform nil)
   (trusted-html-p
    :reader fedwiki-story-item-rendering-demo-trusted-html-p
    :initarg :trusted-html-p
    :initform nil)))

(defmethod views:text-representation
    ((demo fedwiki-story-item-rendering-demo))
  (format nil "~A — ~A"
          (fedwiki-story-item-rendering-demo-title-of demo)
          (fedwiki-story-item-rendering-demo-kind-of demo)))

(defun fedwiki-story-item-demo-hash (&rest pairs)
  (let ((table (make-hash-table :test #'equal)))
    (loop for (key value) on pairs by #'cddr
          do (setf (gethash key table) value))
    table))

(defun make-fedwiki-story-item-rendering-demo-page ()
  (let ((wiki (make-instance 'hyperbook/fedwiki::fedwiki
                             :id "fedwiki:story-item-rendering-demo.example")))
    (hyperbook/fedwiki::make-fedwiki-page
     wiki
     "story-item-rendering-trust-boundary"
     "Story Item Rendering Trust Boundary")))

(defun make-fedwiki-story-item-rendering-demo-item (demo)
  (make-instance 'hyperbook/fedwiki::story-item
                 :item-type
                 (fedwiki-story-item-rendering-demo-item-type-of demo)
                 :id
                 (format nil "demo-~A"
                         (fedwiki-story-item-rendering-demo-kind-of demo))
                 :text
                 (fedwiki-story-item-rendering-demo-text-of demo)
                 :data
                 (fedwiki-story-item-rendering-demo-data-of demo)))

(defun make-fedwiki-html-story-item-blocked-demo ()
  (make-instance
   'fedwiki-story-item-rendering-demo
   :kind :html-blocked
   :title "Blocked :html story item"
   :item-type :html
   :text "<script>alert(1)</script><p>trusted-looking markup</p>"
   :trusted-html-p nil))

(defun make-fedwiki-html-story-item-trusted-demo ()
  (make-instance
   'fedwiki-story-item-rendering-demo
   :kind :html-trusted
   :title "Explicitly trusted :html story item"
   :item-type :html
   :text "<p>trusted html snippet</p>"
   :trusted-html-p t))

(defun make-fedwiki-graphviz-story-item-shape-demo ()
  (make-instance
   'fedwiki-story-item-rendering-demo
   :kind :graphviz-shape
   :title "Graphviz text-backed story item"
   :item-type :graphviz
   :text "digraph { text -> canonical }"
   :data (fedwiki-story-item-demo-hash
          "dot" "digraph { data -> wrong }"
          "engine" "dot")))

(defun make-fedwiki-story-item-rendering-demo-set ()
  (list
   (make-fedwiki-html-story-item-blocked-demo)
   (make-fedwiki-html-story-item-trusted-demo)
   (make-fedwiki-graphviz-story-item-shape-demo)))

(defun render-fedwiki-story-item-demo-to-string-and-assets (demo)
  (let* ((page (make-fedwiki-story-item-rendering-demo-page))
         (item (make-fedwiki-story-item-rendering-demo-item demo))
         (accumulator
           (make-instance 'html-inspector-views::view-accumulator)))
    (let ((hyperbook/fedwiki::*render-unsafe-html-story-items*
            (fedwiki-story-item-rendering-demo-trusted-html-p demo)))
      (values
       (with-output-to-string (stream)
         (let ((html-inspector-views::*html-stream* stream)
               (html-inspector-views::*view-accumulator* accumulator))
           (hyperbook/fedwiki::render-story-item
            (fedwiki-story-item-rendering-demo-item-type-of demo)
            item
            page)))
       (html-inspector-views::accumulator-assets accumulator)))))

(defun fedwiki-story-item-demo-rendered-html (demo)
  (render-fedwiki-story-item-demo-to-string-and-assets demo))

(defun fedwiki-story-item-demo-source-snippet-between-markers
    (pathname start-marker &optional end-marker)
  (when-let (resolved (probe-file pathname))
    (let* ((source (uiop:read-file-string resolved))
           (start (search start-marker source :test #'char=)))
      (when start
        (let ((end (if end-marker
                       (or (search end-marker source
                                   :start2 start
                                   :test #'char=)
                           (length source))
                       (length source))))
          (subseq source start end))))))

(defun fedwiki-story-item-demo-source-pathname ()
  (asdf:system-relative-pathname
   :hyperdoc
   "hyperbook-fedwiki/story-items.lisp"))

(defun fedwiki-story-item-demo-graphviz-source-shape ()
  (let* ((pathname (fedwiki-story-item-demo-source-pathname))
         (snippet
           (fedwiki-story-item-demo-source-snippet-between-markers
            pathname
            "(defmethod render-story-item ((type (eql :graphviz)) item page)"
            ";; Images")))
    (cond
      ((null snippet)
       (list :status :unavailable
             :path (namestring pathname)
             :reason "Could not locate the :graphviz render-story-item source snippet."))
      (t
       (let* ((dot-from-text-p
                (not (null (search "(text-of item)" snippet :test #'char=))))
              (dot-from-data-p
                (not (null (search "(gethash \"dot\"" snippet :test #'char=))))
              (engine-from-data-p
                (not (null (search "(gethash \"engine\"" snippet :test #'char=))))
              (shared-snippet-p
                (not (null (search "views:graphviz-snippet" snippet :test #'char=))))
              (fallback-title-present-p
                (not (null (search ":fallback-title \"Raw DOT source\""
                                   snippet
                                   :test #'char=))))
              (recognized-shape-p
                (and dot-from-text-p
                     (not dot-from-data-p)
                     engine-from-data-p
                     shared-snippet-p)))
         (list :status (if recognized-shape-p :resolved :partial)
               :path (namestring pathname)
               :dot-from-text-p dot-from-text-p
               :dot-from-data-p dot-from-data-p
               :engine-from-data-p engine-from-data-p
               :shared-snippet-p shared-snippet-p
               :fallback-title-present-p fallback-title-present-p
               :recognized-text-backed-shared-shape-p recognized-shape-p
               :snippet snippet))))))

(defun fedwiki-story-item-demo-html-trust-source-shape ()
  (let* ((pathname (fedwiki-story-item-demo-source-pathname))
         (source (and (probe-file pathname)
                      (uiop:read-file-string pathname))))
    (if source
        (list
         :status :resolved
         :path (namestring pathname)
         :has-trust-boundary-marker-p
         (not (null (search "html-story-item-trust-boundary-override"
                            source
                            :test #'char=)))
         :has-default-closed-variable-p
         (not (null (search "*render-unsafe-html-story-items* nil"
                            source
                            :test #'char=)))
         :has-blocked-renderer-p
         (not (null (search "render-blocked-html-story-item"
                            source
                            :test #'char=)))
         :has-explicit-trust-predicate-p
         (not (null (search "trusted-html-story-item-p"
                            source
                            :test #'char=))))
        (list :status :unavailable
              :path (namestring pathname)))))

(defun fedwiki-story-item-demo-observation (demo)
  (multiple-value-bind (html assets)
      (render-fedwiki-story-item-demo-to-string-and-assets demo)
    (list
     :kind (fedwiki-story-item-rendering-demo-kind-of demo)
     :item-type (fedwiki-story-item-rendering-demo-item-type-of demo)
     :trusted-html-p (fedwiki-story-item-rendering-demo-trusted-html-p demo)
     :blocked-message-present-p
     (not (null (search "HTML story item withheld by default"
                        html
                        :test #'char=)))
     :raw-script-present-p
     (not (null (search "<script>" html :test #'char=)))
     :escaped-script-present-p
     (not (null (search "&lt;script&gt;" html :test #'char=)))
     :graphviz-placeholder-present-p
     (not (null (search "data-inspector-graphviz="
                        html
                        :test #'char=)))
     :text-dot-present-p
     (not (null (search "text -&gt; canonical" html :test #'char=)))
     :data-dot-present-p
     (not (null (search "data -&gt; wrong" html :test #'char=)))
     :asset-count (length assets)
     :rendered-html html)))

(defun render-fedwiki-story-item-demo-kv-row (label value)
  (views:html
    (:tr
     (:td (:b (views:esc label)))
     (:td (views:esc (princ-to-string value))))))

(defun render-fedwiki-story-item-demo-code-block (string)
  (views:html
    (:pre :style "white-space: pre-wrap; background-color: #eee; padding: 0.5em;"
          (views:esc string))))

(views:defview 👀overview
    (demo fedwiki-story-item-rendering-demo)
  (views:html-view :title "Overview" :priority 1
    (let ((observation (fedwiki-story-item-demo-observation demo)))
      (views:html
        (:p
         (views:esc
          "Inspectable demonstration of one FedWiki story-item rendering boundary."))

        (:table :class "inspector-table"
                (render-fedwiki-story-item-demo-kv-row
                 "Title"
                 (fedwiki-story-item-rendering-demo-title-of demo))
                (render-fedwiki-story-item-demo-kv-row
                 "Kind"
                 (fedwiki-story-item-rendering-demo-kind-of demo))
                (render-fedwiki-story-item-demo-kv-row
                 "Story item type"
                 (fedwiki-story-item-rendering-demo-item-type-of demo))
                (render-fedwiki-story-item-demo-kv-row
                 "Trusted HTML binding"
                 (fedwiki-story-item-rendering-demo-trusted-html-p demo)))

        (:p
         (views:object-ref observation
                           :display "Inspect observation plist"))))))

(views:defview 👀rendered-html
    (demo fedwiki-story-item-rendering-demo)
  (views:html-view :title "Rendered HTML" :priority 2
    (let ((html (fedwiki-story-item-demo-rendered-html demo)))
      (views:html
        (:p
         (views:esc
          "Escaped rendering output captured from render-story-item."))

        (render-fedwiki-story-item-demo-code-block html)))))

(views:defview 👀source-shape
    (demo fedwiki-story-item-rendering-demo)
  (views:html-view :title "Source shape" :priority 3
    (views:html
      (:p
       (views:esc
        "Source-level contract evidence for the touched story-item renderer."))

      (:ul
       (:li
        (views:object-ref
         (fedwiki-story-item-demo-html-trust-source-shape)
         :display "Inspect :html trust-boundary source shape"))
       (:li
        (views:object-ref
         (fedwiki-story-item-demo-graphviz-source-shape)
         :display "Inspect :graphviz source shape"))))))

(views:defview 👀contract
    (demo fedwiki-story-item-rendering-demo)
  (views:html-view :title "Contract" :priority 4
    (views:html
      (:ul
       (:li
        (views:esc
         ":html story items are blocked and escaped by default."))
       (:li
        (views:esc
         "Raw :html rendering requires an explicit dynamic binding of *render-unsafe-html-story-items*."))

       (:li
        (views:esc
         ":graphviz story items remain text-backed and delegate rendering to views:graphviz-snippet."))

       (:li
        (views:esc
         "data[\"dot\"] must not become canonical DOT source for HyperDoc's editable story-item path."))))))

(views:defview 👀related-examples
    (demo fedwiki-story-item-rendering-demo)
  (views:html-view :title "Related examples" :priority 5
    (views:html
      (:ul
       (:li
        (views:object-ref
         (make-fedwiki-html-story-item-blocked-demo)
         :display "Blocked HTML example"))
       (:li
        (views:object-ref
         (make-fedwiki-html-story-item-trusted-demo)
         :display "Trusted HTML example"))
       (:li
        (views:object-ref
         (make-fedwiki-graphviz-story-item-shape-demo)
         :display "Graphviz shape example"))
       (:li
        (views:object-ref
         (make-fedwiki-story-item-rendering-demo-set)
         :display "All examples as a list"))))))
