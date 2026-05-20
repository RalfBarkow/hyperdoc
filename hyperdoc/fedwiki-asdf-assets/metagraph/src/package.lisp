;;;; Package definition for the Metagraph JSON-LD + Fluree page asset.

(defpackage #:metagraph-as-bipartite-graph-json-ld--fluree
  (:use #:common-lisp)
  (:nicknames #:mg-jsonld-fluree)
  (:export
   #:*source-topic-id*
   #:*source-title*
   #:mg-topic
   #:mg-assoc
   #:mg-layer-contract-topicmap
   #:mg-layer-contract-topicmap-native
   #:mg-planning-topicmap
   #:mg-planning-topicmap-native
   #:mg-conversation-story-topicmap
   #:mg-conversation-story-topicmap-native
   #:mg-topicmap-projection
   #:mg-topicmap-projection-key
   #:mg-topicmap-projection-title
   #:mg-topicmap-projection-slug
   #:mg-topicmap-projection-description
   #:mg-topicmap-projection-semantic-topicmap
   #:mg-topicmap-projection-native-topicmap
   #:mg-all-topicmaps
   #:mg-all-topicmaps-native
   #:mg-all-topicmap-projections
   #:mg-topics-by-layer
   #:mg-assocs-touching-topic
   #:mg-topic-neighborhood
   #:mg-native-topicmap-p
   #:mg-write-native-topicmap
   #:mg-configure-rendered-topicmap-paths
   #:mg-dm6-asset-url
   #:mg-page-asset-url
   #:mg-topicmap-projection-json
   #:mg-rendered-topicmap-island
   #:mg-rendered-topicmap-html
   #:mg-rendered-topicmap-url
   #:mg-rendered-topicmap-pathname
   #:mg-write-rendered-topicmap
   #:mg-write-all-rendered-topicmaps
   #:mg-open-rendered-topicmap
   #:mg-open-all-rendered-topicmaps
   #:mg-call-clog-inspector
   #:mg-inspect-layer-contract-topicmap
   #:mg-inspect-planning-topicmap
   #:mg-inspect-conversation-story-topicmap
   #:mg-inspect-topicmap-projection
   #:mg-inspect-rendered-topicmap
   #:mg-inspector-views-diagnostic
   #:mg-inspector-views-diagnostic-status
   #:mg-inspector-views-diagnostic-message
   #:mg-inspector-views-diagnostic-action
   #:mg-ensure-inspector-views
   #:mg-install-into-hyperdoc-image
   #:mg-installation-report
   #:mg-installation-steps))

(defpackage #:metagraph-as-bipartite-graph-json-ld--fluree/tests
  (:use #:common-lisp
        #:metagraph-as-bipartite-graph-json-ld--fluree)
  (:export #:run-smoke-tests))
