(:artifact contact-db-codex-next-htn
 :kind htn-continuation
 :status selected-for-next-codex-availability

 :context
 (:bootstrap-task-artifact
  "hyperdoc/design-hyperdoc-contact-db-topic-and-fedwiki-page-plan.sexp"
  :bootstrap-task-commit "769106ae"
  :reason
  "The HyperDoc Contact DB does not exist yet. The next Codex move should materialize it as a topic, FedWiki page, page-attached ASDF system, and SQLite-backed contact registry.")

 :root-task
 (!continue-contact-db-work-when-codex-available
  :project hyperdoc
  :topic-title "HyperDoc Contact DB"
  :slug "hyperdoc-contact-db")

 :method
 (:name materialize-contact-db-topic-first
  :preconditions
  (:bootstrap-task-recorded true
   :contact-db-topic-materialized false
   :native-authority-boundaries-known true)
  :subtasks
  ((!record-plan-artifact
    :artifact "hyperdoc/contact-db-codex-next-htn.sexp")
   (!record-shop3-selected-plan
    :artifact "hyperdoc/contact-db-codex-next-shop3-plan.sexp")
   (!record-codex-prompt
    :artifact "hyperdoc/contact-db-codex-next-prompt.md")
   (!handoff-to-codex
    :prompt "hyperdoc/contact-db-codex-next-prompt.md")))

 :selected-next-primitive
 (!materialize-hyperdoc-contact-db-topic
  :from-design-task design-hyperdoc-contact-db-topic-and-fedwiki-page-plan
  :target (:fedwiki-page :page-attached-asdf-system :sqlite-schema)
  :must-preserve-native-authority true)

 :deferred-non-selected-tasks
 ((!investigate-unresolved-zkn3-reference
   :source-note-id "240611105406688rgb50919"
   :source-field "manlinks"
   :raw-reference "64444"
   :mode :source-curation-report-only
   :reason "Wait until the Contact DB exists, then register this as a contact/deferred source-curation task."))

 :boundary
 (:must-not-modify-zkn3-source true
  :must-not-modify-zotero-db true
  :must-not-write-dmx-remote-neo4j true
  :must-not-absorb-native-databases true
  :must-not-create-zkn3linkrecord true
  :must-not-create-resolved-edge-for-64444 true))
