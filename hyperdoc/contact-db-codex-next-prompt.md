Codex task: materialize the HyperDoc Contact DB topic/page-attached ASDF slice.

Context:
- HyperDoc repo: /Users/rgb/workspace/hyperdoc
- Bootstrap design task already recorded and committed:
  - hyperdoc/design-hyperdoc-contact-db-topic-and-fedwiki-page-plan.sexp
  - commit 769106ae
- The design says the project needs one Lisp-addressable contact point for objects living in different native stores: Zettelkasten/ZKN3, Zotero, DMX remote Neo4j, local DMX mirrors, page-attached ASDF systems, page-local SQLite databases, Git artifacts, and deferred tasks.
- This contact point must be modeled as a topic and materialized as a FedWiki page, not merely as an anonymous SQLite file.

Selected task:
(!materialize-hyperdoc-contact-db-topic
 :from-design-task design-hyperdoc-contact-db-topic-and-fedwiki-page-plan
 :target (:fedwiki-page :page-attached-asdf-system :sqlite-schema)
 :must-preserve-native-authority true)

Required materialization:
1. Create the FedWiki page:
   /Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/hyperdoc-contact-db

2. Create a page-attached ASDF system under:
   /Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/hyperdoc-contact-db/

   Keep the page-attached system flat unless there is already a project convention requiring otherwise.
   Expected files:
   - hyperdoc-contact-db.asd
   - package.lisp
   - model.lisp
   - sqlite.lisp
   - views.lisp
   - tests.lisp
   - README.md
   - MANIFEST.txt

3. Define a first SQLite schema for the local contact registry:
   /Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/hyperdoc-contact-db/contact-db.sqlite

   Minimum conceptual tables:
   - native_stores
   - contacts
   - contact_locators
   - lisp_entry_points
   - deferred_tasks
   - projections
   - sync_states
   - validation_evidence

4. Add one fixture contact only, not a native database mutation:
   contact:zkn3:unresolved-reference:64444

   It should preserve:
   - sourceNoteId: 240611105406688rgb50919
   - sourceField: manlinks
   - rawReference: 64444
   - referenceKind: MANUAL_LINK
   - reason: OUT_OF_RANGE
   - order: 15

5. Provide Lisp entry points for at least:
   - create/open contact DB
   - register contact
   - resolve contact by id
   - list contacts
   - register deferred task
   - inspect fixture contact

6. Add smoke tests that verify:
   - ASDF system loads
   - SQLite schema can be created
   - fixture contact can be registered and resolved
   - no native database is modified
   - no Zkn3LinkRecord or resolved edge is created for 64444

Boundaries:
- Do not edit the ZKN3 source database or rgb.zkn3.
- Do not edit the Zotero database.
- Do not write to remote DMX/Neo4j at dmx.ralfbarkow.ch.
- Do not absorb native databases into the Contact DB.
- Do not create a Zkn3LinkRecord or resolved graph edge for 64444.
- Preserve unowned HyperDoc state, especially:
  /Users/rgb/workspace/hyperdoc/hyperdoc/task-location-problem-determined-htn.sexp

Validation:
- Run the page-attached ASDF smoke tests in the appropriate Nix dev shell.
- Report exact commands and outputs.
- Commit only owned files in the relevant repos.
- Return changed files, validation result, commits, remaining unowned state, and the next recommended task.
