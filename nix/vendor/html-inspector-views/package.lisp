;;;; Package definition
;;
;;;; Copyright (c) 2024-2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(defpackage :html-inspector-views
  (:use :cl)
  (:import-from :cl-who :esc :fmt :htm :str)
  (:export :esc :fmt :htm :str
           #:view
           #:html-view #:make-html-view
           #:html #:html-and-references
           #:view-object #:view-method #:view-title #:view-priority
           #:view-html #:view-references #:view-assets #:view-create-html
           #:all-views #:specific-views
           #:rename #:priority
           #:defview
           #:👀items
           #:👀description
           #:👀representations
           #:👀content
           #:👀source
           #:👀print-string
           #:👀playground
           #:open-package-operations?
           #:text-representation
           #:html-representation
           #:title-bar #:title-bar-representation #:title-bar-action-buttons
           #:gui-class
           #:pane-title
           #:thunk #:eval-thunk
           #:html-id #:inspect-id #:action-id #:eval-id
           #:object-ref #:action-button #:eval-button
           #:add-asset-path #:include-js #:include-css #:include-script
           #:transclusion
           #:html-table
           #:list-view
           #:enumerated-list-view
           #:multi-column-list-view
           #:key-value-table-view
           #:tree-view
           #:lisp-code-view #:html-code-view
           #:include-lisp-highlight-assets #:include-html-beautify-assets
           #:lisp-snippet #:html-snippet
           #:include-graphviz-assets #:graphviz-snippet
           #:graphviz-view #:dot-string
           #:encode-base32 #:decode-base32
           ;; For use by html-inspector-views/reactive
           #:*view-accumulator* #:accumulator-references))
