;;;; Source pane layout evidence
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defclass source-pane-layout-model ()
  ((id :reader id-of :initarg :id)
   (title :reader title-of :initarg :title)
   (summary :reader summary-of :initarg :summary)
   (evidence :reader evidence-of :initarg :evidence :initform nil)
   (runtime-snapshot :reader runtime-snapshot-of
                     :initarg :runtime-snapshot
                     :initform nil)))

(defclass source-pane-layout-evidence ()
  ((id :reader id-of :initarg :id)
   (title :reader title-of :initarg :title)
   (summary :reader summary-of :initarg :summary)
   (layer :reader layer-of :initarg :layer)
   (role :reader role-of :initarg :role)
   (relative-path :reader relative-path-of :initarg :relative-path :initform nil)
   (why-it-matters :reader why-it-matters-of
                   :initarg :why-it-matters
                   :initform nil)
   (detail-columns :reader detail-columns-of
                   :initarg :detail-columns
                   :initform nil)
   (detail-rows :reader detail-rows-of :initarg :detail-rows :initform nil)))

(defclass source-pane-file-target ()
  ((id :reader id-of :initarg :id)
   (title :reader title-of :initarg :title)
   (summary :reader summary-of :initarg :summary)
   (relative-path :reader relative-path-of :initarg :relative-path)))

(defmethod print-object ((object source-pane-layout-model) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object source-pane-layout-evidence) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod print-object ((object source-pane-file-target) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defun make-source-pane-layout-evidence (id title summary layer role relative-path
                                         why-it-matters
                                         &key detail-columns detail-rows)
  (make-instance 'source-pane-layout-evidence
                 :id id
                 :title title
                 :summary summary
                 :layer layer
                 :role role
                 :relative-path relative-path
                 :why-it-matters why-it-matters
                 :detail-columns detail-columns
                 :detail-rows detail-rows))

(defun make-source-pane-file-target (relative-path &key title summary)
  (make-instance 'source-pane-file-target
                 :id (format nil "source-pane-file/~A" relative-path)
                 :title (or title relative-path)
                 :summary
                 (or summary
                     (format nil "Inspectable source-backed target for ~A."
                             relative-path))
                 :relative-path relative-path))

(defun source-pane-layout-dispatch-detail-columns ()
  '(("Page class" . :page-class)
    ("Effective Source method" . :effective-method)
    ("Method source file" . :method-source-file)
    ("Why this path wins" . :reason)))

(defun source-pane-layout-dispatch-detail-rows ()
  (list
   (list :page-class "html-page"
         :effective-method "text-page -> views:👀source -> render-source-connect-surface"
         :method-source-file "hyperdoc-explorer/explorer.lisp"
         :reason
         "hyperdoc::html-page subclasses text-page and does not override Source, so the connectable Source surface stays active.")
   (list :page-class "markdown-page"
         :effective-method "text-page -> views:👀source -> render-source-connect-surface"
         :method-source-file "hyperdoc-explorer/explorer.lisp"
         :reason
         "hyperdoc::markdown-page subclasses html-page, which still inherits the same text-page Source path.")
   (list :page-class "plain HyperBook html-page (contrast path)"
         :effective-method "hyperbook::html-page -> hb:render-file-source-surface"
         :method-source-file "hyperbook-explorer/html-books.lisp"
         :reason
         "This is the shared plain file-source path reused for generic file targets and line rendering, but it is not the active HyperDoc html/markdown Source method.")))

(defun source-pane-layout-pane-shell-detail-columns ()
  '(("Function" . :function)
    ("Source file" . :source-file)
    ("Contribution" . :contribution)))

(defun source-pane-layout-pane-shell-detail-rows ()
  (list
   (list :function "create-tabs"
         :source-file "hyperbook-server/inspector-dom-association.lisp"
         :contribution
         "Creates the pane-local .hyperdoc-dom-connect-pane-chrome and .hyperdoc-dom-connect-pane-slot directly below the inspector tabs.")
   (list :function "pane slot contract"
         :source-file "hyperbook-server/inspector-dom-association.lisp"
         :contribution
         "Keeps the dock-control row separate from the Source body so JS can populate controls without owning the source-pane layout itself.")))

(defun source-pane-layout-server-composition-detail-columns ()
  '(("Function" . :function)
    ("Source file" . :source-file)
    ("Contribution" . :contribution)))

(defun source-pane-layout-server-composition-detail-rows ()
  (list
   (list :function "render-source-connect-surface"
         :source-file "hyperdoc-explorer/dom-annotations.lisp"
         :contribution
         "Builds the source-v1 provider for Source tabs and threads optional focused-line landing into the provider.")
   (list :function "render-anchor-provider-surface"
         :source-file "hyperdoc-explorer/dom-annotations.lisp"
         :contribution
         "Emits the connectable surface shell, hidden submit bridge, overlay, and provider root that browser JS binds.")
   (list :function "render-anchor-provider-body"
         :source-file "hyperdoc-explorer/dom-annotations.lisp"
         :contribution
         "Owns the Source body composition: .hyperdoc-source-pane outside, .hyperdoc-source-connect-view inside, and shared source lines in the middle.")))

(defun source-pane-layout-shared-rendering-detail-columns ()
  '(("Helper" . :helper)
    ("Source file" . :source-file)
    ("Responsibility" . :responsibility)))

(defun source-pane-layout-shared-rendering-detail-rows ()
  (list
   (list :helper "hb:render-source-surface-lines"
         :source-file "hyperbook-explorer/html-books.lisp"
         :responsibility
         "Shared line-numbered escaped source-line renderer reused by both the plain file surface and the connectable source body.")
   (list :helper "hb:render-file-source-surface"
         :source-file "hyperbook-explorer/html-books.lisp"
         :responsibility
         "Plain non-connect source pane used when a file should be inspectable without source-anchor controls.")
   (list :helper "hyperbook::html-page -> views:👀source"
         :source-file "hyperbook-explorer/html-books.lisp"
         :responsibility
         "Contrast path showing the plain html-page Source implementation that HyperDoc html/markdown pages do not dispatch through.")))

(defun source-pane-layout-css-detail-columns ()
  '(("Selector" . :selector)
    ("Role" . :role)
    ("Layout relationship" . :layout-relationship)))

(defun source-pane-layout-css-detail-rows ()
  (list
   (list :selector ".hyperdoc-dom-connect-pane-chrome"
         :role "Pane chrome wrapper"
         :layout-relationship
         "Holds the dedicated chrome region beneath the tab strip.")
   (list :selector ".hyperdoc-dom-connect-pane-slot"
         :role "Dock control slot"
         :layout-relationship
         "Reserves the full-width row where JS injects the dock control.")
   (list :selector ".hyperdoc-dom-connect-control"
         :role "Dock control shell"
         :layout-relationship
         "Stacks compact capability chrome above coachmark and feedback content.")
   (list :selector ".hyperdoc-source-pane"
         :role "Source body wrapper"
         :layout-relationship
         "Takes the remaining inspector body width below the pane chrome and constrains flex overflow.")
   (list :selector ".hyperdoc-source-connect-view"
         :role "Connectable source surface"
         :layout-relationship
         "Provides the bordered scrolling source-reading surface used for connectable Source tabs.")
   (list :selector ".hyperdoc-source-pane-view"
         :role "Plain source surface"
         :layout-relationship
         "Provides the bordered scrolling source-reading surface for non-connect file targets.")))

(defun source-pane-layout-js-detail-columns ()
  '(("Function" . :function)
    ("Responsibility" . :responsibility)))

(defun source-pane-layout-js-detail-rows ()
  (list
   (list :function "ensurePaneState"
         :responsibility
         "Finds the nearest inspector pane and .hyperdoc-dom-connect-pane-slot, initializes pane-local state, and calls ensurePaneControlMarkup(slot).")
   (list :function "ensurePaneControlMarkup"
         :responsibility
         "Injects .hyperdoc-dom-connect-control.hyperdoc-dock-control into the pane slot and owns the pane-slot/control handshake.")
   (list :function "syncPaneSurface"
         :responsibility
         "Rebinds the active connect surface when tabs or panes change so Source panes stay available and controls stay in sync.")
   (list :function "initSurface"
         :responsibility
         "Bootstraps root listeners, schedules pane-surface sync, and applies focused-line auto-scroll on source surfaces.")))

(defun source-pane-dispatch-evidence ()
  (make-source-pane-layout-evidence
   "source-pane-layout/dispatch"
   "HTML/Markdown Source dispatch"
   "The current effective Source path for HyperDoc html-page and markdown-page stays connectable because both classes inherit the text-page Source method."
   "Dispatch"
   "Shows which Source method actually wins for HyperDoc html and markdown pages."
   "hyperdoc-explorer/html-pages.lisp"
   "This is the dispatch seam that explains why html/markdown Source remains connectable and why the plain HyperBook html-page Source path is only a contrast path here."
   :detail-columns (source-pane-layout-dispatch-detail-columns)
   :detail-rows (source-pane-layout-dispatch-detail-rows)))

(defun source-pane-pane-shell-evidence ()
  (make-source-pane-layout-evidence
   "source-pane-layout/pane-shell"
   "Pane chrome and slot shell"
   "The dock-control row lives in a dedicated pane-slot shell below the inspector tabs, not inside the Source body itself."
   "Pane shell"
   "Shows where the pane chrome and pane slot come from before JS populates them."
   "hyperbook-server/inspector-dom-association.lisp"
   "The Source pane layout only makes sense once the pane-chrome shell and slot are visible as a separate layer in the chain."
   :detail-columns (source-pane-layout-pane-shell-detail-columns)
   :detail-rows (source-pane-layout-pane-shell-detail-rows)))

(defun source-pane-server-composition-evidence ()
  (make-source-pane-layout-evidence
   "source-pane-layout/server-composition"
   "Server-side source/connect composition"
   "Server-side wrappers compose the connectable source surface, the hidden bridge controls, and the Source body wrapper beneath the pane chrome."
   "Server composition"
   "Shows which wrapper owns the connectable Source surface and which one owns the Source body layout."
   "hyperdoc-explorer/dom-annotations.lisp"
   "This is the inner server-side composition layer between the inherited Source method and the browser-side pane-slot handshake."
   :detail-columns (source-pane-layout-server-composition-detail-columns)
   :detail-rows (source-pane-layout-server-composition-detail-rows)))

(defun source-pane-shared-rendering-evidence ()
  (make-source-pane-layout-evidence
   "source-pane-layout/shared-rendering"
   "Shared and plain file-source rendering"
   "HyperBook provides the shared line renderer and the plain non-connect file-source pane; HyperDoc reuses the line renderer inside its connectable Source body."
   "Shared rendering"
   "Separates plain file-source responsibilities from connectable source-surface responsibilities."
   "hyperbook-explorer/html-books.lisp"
   "This layer is the contrast point that makes it inspectable why plain file rendering and connectable Source rendering share lines but not the same outer surface contract."
   :detail-columns (source-pane-layout-shared-rendering-detail-columns)
   :detail-rows (source-pane-layout-shared-rendering-detail-rows)))

(defun source-pane-css-layout-evidence ()
  (make-source-pane-layout-evidence
   "source-pane-layout/css"
   "Source-pane layout CSS"
   "The pane chrome, pane slot, dock control, source-pane wrapper, and source-reading surfaces are all sized and related in the DOM-annotation connect stylesheet."
   "CSS"
   "Shows which selectors own the Source body width and its relationship to the dock-control row."
   "assets/hyperdoc/css/dom-annotation-connect.css"
   "This is the layout layer that keeps the dock chrome visible while letting the Source body fill the inspector beneath it."
   :detail-columns (source-pane-layout-css-detail-columns)
   :detail-rows (source-pane-layout-css-detail-rows)))

(defun source-pane-js-handshake-evidence ()
  (make-source-pane-layout-evidence
   "source-pane-layout/js"
   "Pane-slot and source-surface runtime handshake"
   "Browser-side initialization discovers the active connect surface, populates the pane slot with dock controls, and keeps pane state synchronized when tabs switch."
   "JS"
   "Shows which runtime functions populate the pane slot and bind the connectable Source surface."
   "assets/hyperdoc/js/dom-annotation-connect.js"
   "This is the runtime layer that turns the pane slot into a live dock-control row and binds the source surface beneath it."
   :detail-columns (source-pane-layout-js-detail-columns)
   :detail-rows (source-pane-layout-js-detail-rows)))

(defun source-pane-layout-runtime-snapshot ()
  (make-dom-connect-pane-state-snapshot-from-json
   '(:paneId "source-pane-layout"
     :activeTab "Source"
     :contextViewTitle "Source"
     :providerKind "source-v1"
     :available t
     :enabled t
     :phase "dormant"
     :helpOpen nil
     :presentationState "latent"
     :presentationReason "connectable-source-pane"
     :coachmarkVisible nil
     :selectedSourceLabel nil
     :selectedSourcePane nil
     :pendingRequestId nil
     :compactCapabilities ("Connect" "Annotation" "Guide")
     :coachmarkCapabilities ()
     :providerHandoffs ())))

(defun source-pane-layout-model ()
  (make-instance 'source-pane-layout-model
                 :id "source-pane-layout-evidence"
                 :title "Source pane layout evidence"
                 :summary
                 "Inspectable evidence chain for the current html/markdown Source path: inherited dispatch, pane-slot shell, connectable source composition, shared line rendering, layout CSS, browser-side pane-slot handshake, and representative runtime state."
                 :evidence
                 (list (source-pane-dispatch-evidence)
                       (source-pane-pane-shell-evidence)
                       (source-pane-server-composition-evidence)
                       (source-pane-shared-rendering-evidence)
                       (source-pane-css-layout-evidence)
                       (source-pane-js-handshake-evidence))
                 :runtime-snapshot
                 (source-pane-layout-runtime-snapshot)))

(defun chunk-source-pane-layout-evidence ()
  (source-pane-layout-model))
