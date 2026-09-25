;;;; Package for Dreyeck's generic Topicmap Inspector extension.

(defpackage #:dreyeck/inspector/topicmap
  (:use #:cl)
  (:export
   #:*topicmap-renderer*
   #:render-topicmap-html
   #:render-native-topicmap-html
   #:workspace-action-sign-occurrence
   #:open-workspace-action-sign-occurrences
   #:workspace-action-sign-occurrence-current-p
   #:invalidate-workspace-action-sign-occurrence
   #:*workspace-action-sign-bindings*
   #:occurrence-reference #:occurrence-element #:occurrence-pane
   #:occurrence-view #:occurrence-token #:occurrence-inputs
   #:occurrence-topic #:occurrence-topic-id #:occurrence-projection
   #:occurrence-workspace #:occurrence-gesture-window
   #:occurrence-inspectable-object))

(trivial-package-local-nicknames:add-package-local-nickname
 :views :html-inspector-views :dreyeck/inspector/topicmap)
