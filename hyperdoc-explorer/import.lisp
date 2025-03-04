;;;; Import additional symbols into package hyperdoc
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; The symbols imported in the following are from packages that are
;; dependencies of system "hyperdoc/explorer", but not of system
;; "hyperdoc". Therefore they could not be imported at package
;; creation time.
;;

(import '(html-inspector-views:defview
          html-inspector-views:text-representation
          html-inspector-views:html-representation
          html-inspector-views:title-bar-action-buttons
          html-inspector-views:html
          html-inspector-views:html-view
          html-inspector-views:action-button
          html-inspector-views:eval-button
          html-inspector-views:object-ref
          html-inspector-views:transclusion
          html-inspector-views:thunk
          html-inspector-views:rename
          html-inspector-views:add-asset-path
          html-inspector-views:include-css
          html-inspector-views:list-view
          html-inspector-views:enumerated-list-view
          html-inspector-views:👀content
          html-inspector-views:👀items
          html-inspector-views/standard:var-definition))
