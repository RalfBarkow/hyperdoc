(:artifact contact-db-codex-next-shop3-plan
 :kind shop3-selected-plan
 :status ready-for-codex

 :problem
 (:name materialize-hyperdoc-contact-db-topic-problem
  :objects
  (:hyperdoc-repo "/Users/rgb/workspace/hyperdoc"
   :fedwiki-pages-repo "/Users/rgb/.wiki/wiki.ralfbarkow.ch"
   :fedwiki-assets-repo "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets"
   :topic-title "HyperDoc Contact DB"
   :slug "hyperdoc-contact-db")
  :initial-state
  (:bootstrap-task-recorded true
   :bootstrap-task-commit "769106ae"
   :contact-db-fedwiki-page-exists false
   :contact-db-page-attached-asdf-exists false
   :contact-db-sqlite-schema-exists false
   :native-authority-preserved true)
  :goal
  (:contact-db-fedwiki-page-designed true
   :contact-db-page-attached-asdf-contract-designed true
   :contact-db-sqlite-schema-designed true
   :lisp-entry-points-designed true
   :smoke-tests-pass true
   :native-authority-preserved true))

 :selected-ordered-plan
 ((!inspect-bootstrap-design
   :artifact "hyperdoc/design-hyperdoc-contact-db-topic-and-fedwiki-page-plan.sexp")

  (!materialize-fedwiki-page
   :path "/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/hyperdoc-contact-db"
   :title "HyperDoc Contact DB"
   :role "Human-readable and forkable coordination surface for the Lisp-addressable contact registry.")

  (!materialize-page-attached-asdf-system
   :path "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/hyperdoc-contact-db"
   :system hyperdoc-contact-db
   :flat-assets true
   :files ("hyperdoc-contact-db.asd"
           "package.lisp"
           "model.lisp"
           "sqlite.lisp"
           "views.lisp"
           "tests.lisp"
           "README.md"
           "MANIFEST.txt"))

  (!define-contact-db-sqlite-schema
   :sqlite "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/hyperdoc-contact-db/contact-db.sqlite"
   :tables (:native_stores
            :contacts
            :contact_locators
            :lisp_entry_points
            :deferred_tasks
            :projections
            :sync_states
            :validation_evidence)
   :must-not-copy-native-databases true)

  (!add-initial-contact-fixture
   :id "contact:zkn3:unresolved-reference:64444"
   :native-store zettelkasten-zkn3
   :raw-reference "64444"
   :fixture-only true
   :must-not-create-resolved-edge true)

  (!write-smoke-tests
   :assertions
   (:can-load-page-attached-asdf-system true
    :can-create-empty-contact-db true
    :can-register-fixture-contact true
    :can-resolve-fixture-contact true
    :does-not-touch-native-databases true))

  (!validate-materialization
   :commands
   ("nix develop -c sbcl --no-userinit --non-interactive --eval '(require :asdf)' --eval '(asdf:load-system :hyperdoc-contact-db)' --eval '(asdf:load-system :hyperdoc-contact-db/tests)' --eval '(uiop:quit 0)'"))

  (!commit-fedwiki-assets
   :repo "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets"
   :message "feat(contact-db): add HyperDoc Contact DB page-attached system")

  (!commit-fedwiki-page
   :repo "/Users/rgb/.wiki/wiki.ralfbarkow.ch"
   :message "docs(contact-db): add HyperDoc Contact DB page")

  (!record-result-or-blocker
   :where "Codex handoff response"
   :include (:commits :validation-output :unowned-state :next-task)))

 :non-goals
 (:do-not-edit-zkn3-source true
  :do-not-edit-zotero-db true
  :do-not-write-dmx-remote-neo4j true
  :do-not-create-zkn3linkrecord-for-64444 true
  :do-not-turn-contact-db-into-data-warehouse true))
