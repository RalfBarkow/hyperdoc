;;;; Package for Dreyeck's generic Topicmap Inspector extension.

(defpackage #:dreyeck/inspector/topicmap
  (:use #:cl)
  (:export
   #:*topicmap-renderer*
   #:render-topicmap-html
   #:render-native-topicmap-html))

(trivial-package-local-nicknames:add-package-local-nickname
 :views :html-inspector-views :dreyeck/inspector/topicmap)
