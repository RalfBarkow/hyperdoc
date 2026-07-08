(:artifact design-hyperdoc-contact-db-topic-and-fedwiki-page-plan
 :kind deferred-plan-task
 :status :recorded

 :task
 (!design-hyperdoc-contact-db-topic-and-fedwiki-page
  :title "HyperDoc Contact DB"
  :slug "hyperdoc-contact-db"
  :kind (:topic :fedwiki-page :page-attached-asdf-system)
  :backing-store :sqlite
  :dmx-projection true
  :stores (:contact-records
           :native-store-locators
           :lisp-entry-points
           :deferred-tasks
           :projection-entry-points
           :sync-state
           :validation-evidence)
  :must-not-absorb-native-databases true
  :must-preserve-native-authority true)

 :why
 "The project needs one Lisp-addressable contact point for objects that live
  in different native stores: Zettelkasten/ZKN3, Zotero, DMX remote Neo4j,
  local DMX mirrors, page-attached ASDF systems, page-local SQLite databases,
  Git artifacts, and deferred tasks. This contact point must be modeled as a
  topic and materialized as a FedWiki page, not merely as an anonymous SQLite file."

 :bootstrap-location
 (:repo "/Users/rgb/workspace/hyperdoc"
  :artifact "hyperdoc/design-hyperdoc-contact-db-topic-and-fedwiki-page-plan.sexp")

 :future-materialization
 (:fedwiki-page
  "/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/hyperdoc-contact-db"
  :page-attached-asdf
  "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/hyperdoc-contact-db/hyperdoc-contact-db.asd"
  :sqlite
  "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/hyperdoc-contact-db/contact-db.sqlite")

 :initial-contact-example
 (:id "contact:zkn3:unresolved-reference:64444"
  :native-store :zettelkasten-zkn3
  :native-locator
  (:sourceNoteId "240611105406688rgb50919"
   :sourceField "manlinks"
   :rawReference "64444"
   :referenceKind "MANUAL_LINK"
   :reason "OUT_OF_RANGE"
   :order 15)
  :decision
  (:preserve-source-token true
   :create-Zkn3LinkRecord false
   :create-resolved-edge false))

 :done-when
 (:fedwiki-page-designed true
  :page-attached-asdf-contract-designed true
  :sqlite-schema-designed true
  :lisp-entry-points-designed true
  :dmx-projection-boundary-designed true
  :native-authority-boundaries-preserved true)

 :next
 (!materialize-hyperdoc-contact-db-topic
  :from-design-task design-hyperdoc-contact-db-topic-and-fedwiki-page-plan
  :target (:fedwiki-page :page-attached-asdf-system :sqlite-schema)
  :must-preserve-native-authority true))
