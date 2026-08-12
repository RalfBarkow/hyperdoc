;;;; Package for Dreyeck's renderer-independent Topicmap protocol.

(defpackage #:dreyeck/topicmap
  (:use #:cl)
  (:export
   #:topicmap-projection
   #:make-topicmap-projection
   #:topicmap-projection-source-of
   #:topicmap-projection-topics-of
   #:topicmap-projection-associations-of
   #:topicmap-projection-view-properties-of
   #:topicmap-topic
   #:make-topicmap-topic
   #:topicmap-topic-id-of
   #:topicmap-topic-type-of
   #:topicmap-topic-label-of
   #:topicmap-topic-object-of
   #:topicmap-topic-temporal-scope-of
   #:topicmap-topic-view-properties-of
   #:topicmap-association
   #:make-topicmap-association
   #:topicmap-association-id-of
   #:topicmap-association-type-of
   #:topicmap-association-from-of
   #:topicmap-association-to-of
   #:topicmap-association-properties-of
   #:topicmap-projection-of))
