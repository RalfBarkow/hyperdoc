;;;; MREPL recipe for the HyperDoc-native metagraph asset workflow.

(asdf:load-system :hyperdoc/fedwiki-asdf-assets)

(in-package :hyperdoc)

(defparameter *metagraph-spec*
  (make-metagraph-jsonld-fluree-asset-spec
   :asset-root #P"/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/"))

(page-asdf-asset-workflow
 *metagraph-spec*
 :clean t
 :force t
 :test t
 :inspect t
 :zip t)

;;;; After the generated system is loaded:

(in-package :mg-jsonld-fluree)

(mg-topicmap-projection :planning-example)
(mg-inspect-rendered-topicmap :planning-example)
(mg-write-all-rendered-topicmaps)
