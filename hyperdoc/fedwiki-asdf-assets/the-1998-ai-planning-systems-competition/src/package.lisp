;;;; Package definitions for the McDermott 2000 page-attached artifact.

(defpackage #:the-1998-ai-planning-systems-competition
  (:use #:cl)
  (:export
   #:*reading-slug*
   #:*reading-title*
   #:*network-required-p*
   #:artifact-root
   #:asset-db-pathname
   #:page-json-pathname
   #:required-topic-ids
   #:required-association-ids
   #:topic-definitions
   #:association-definitions
   #:source-fragment-definitions
   #:story-item-definitions
   #:sqlite-run
   #:initialize-dmx-sqlite-asset
   #:seed-reading-topics
   #:schema-status
   #:topic-exists-p
   #:association-exists-p
   #:required-topics-present-p
   #:required-associations-present-p
   #:reconstruct-fedwiki-page-json-string
   #:materialize-fedwiki-page-from-dmx
   #:materialize-reading-artifact
   #:validate-reconstruction-idempotence
   #:fedwiki-attached-home
   #:capability-relation
   #:ensure-inspector-views
   #:inspect-artifact))

(defpackage #:the-1998-ai-planning-systems-competition/tests
  (:use #:cl #:the-1998-ai-planning-systems-competition)
  (:export #:run-smoke-tests))
