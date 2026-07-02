;;;; Inspector-oriented entrypoints for the page-attached artifact.

(in-package #:the-1998-ai-planning-systems-competition)

(defun fedwiki-attached-home ()
  (hyperdoc:make-fedwiki-attached-asdf-system
   :slug *reading-slug*
   :site-root #P"/Users/rgb/.wiki/wiki.ralfbarkow.ch/"
   :system *reading-system-name*
   :system-file *reading-system-name*
   :test-system "the-1998-ai-planning-systems-competition/test"
   :package-name *reading-system-name*))

(defun capability-relation ()
  (hyperdoc:make-fedwiki-attached-asdf-capability-relation
   :from-home (fedwiki-attached-home)
   :to-home (fedwiki-attached-home)
   :capability :dmx-sqlite-page-reconstruction
   :entry-package-name "THE-1998-AI-PLANNING-SYSTEMS-COMPETITION"
   :entry-symbol-name "MATERIALIZE-READING-ARTIFACT"
   :reason "The FedWiki page projection is reconstructed from the page-attached DMX SQLite database."
   :load-policy :explicit))

(defun ensure-inspector-views ()
  "Return inspector entrypoints; no live server is required."
  (list :status :available
        :network-required-p *network-required-p*
        :home (fedwiki-attached-home)
        :capability-relation (capability-relation)
        :entry-points
        '("the-1998-ai-planning-systems-competition:inspect-artifact"
          "the-1998-ai-planning-systems-competition:schema-status"
          "the-1998-ai-planning-systems-competition:materialize-reading-artifact"
          "the-1998-ai-planning-systems-competition:validate-reconstruction-idempotence")))

(defun inspect-artifact (&key (db-path (asset-db-pathname)))
  (list :slug *reading-slug*
        :title *reading-title*
        :system *reading-system-name*
        :asset-root (artifact-root)
        :db-path db-path
        :page-json-path (page-json-pathname)
        :schema (schema-status :db-path db-path)
        :required-topic-count (length (required-topic-ids))
        :required-association-count (length (required-association-ids))
        :required-topics-present-p
        (required-topics-present-p :db-path db-path)
        :required-associations-present-p
        (required-associations-present-p :db-path db-path)
        :network-required-p *network-required-p*))
