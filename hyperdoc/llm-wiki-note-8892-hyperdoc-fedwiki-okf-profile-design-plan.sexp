(:artifact llm-wiki-note-8892-hyperdoc-fedwiki-okf-profile-design-plan
 :kind hyperdoc-native-plan
 :status recorded
 :mode concept-design-only
 :must-not-implement-converter-yet t

 :task
 (!design-hyperdoc-fedwiki-okf-profile
  :mode :concept-design-only
  :inputs
  (:zettel-8892
   :heise-okf-article
   :google-okf-spec
   :llm-wiki-note-8892-okf-reading-result
   :llm-wiki-note-8892-okf-profile-plan-protocol-selection)
  :outputs
  (:mapping-rules
   :loss-model
   :extension-points
   :candidate-frontmatter-fields
   :validation-questions))

 :basis
 (:critical-reading-plan
  (:source *critical-reading-selected-plan*
   :role "Use the already loaded read/identify/rewrite/compare/record cycle as
          the reading discipline for the OKF profile design.")

  :executable-dita-pddl-domain
  (:source *executable-dita-pddl-domain*
   :role "Represent the profile design as executable task-topic material, not
          as free prose only.")

  :fedwiki-attached-asdf-source-authority
  (:source
   (:local-shop3 "/Users/rgb/workspace/shop3/shop3/shop3.asd"
    :hyperdoc-shop3 "/Users/rgb/workspace/hyperdoc/.flake-deps/shop3/shop3.asd"
    :llm-wiki-paper-hyperdoc
    "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/documents-as-a-maintained-wiki/llm-wiki-paper-hyperdoc/llm-wiki-paper-hyperdoc.asd")
   :role "Treat page-attached ASDF systems as durable source authorities and
          profile design precedents."))

 :selected-ordered-plan
 ((!record-plan-artifact
   :artifact "hyperdoc/llm-wiki-note-8892-hyperdoc-fedwiki-okf-profile-design-plan.sexp")

  (!define-profile-scope
   :profile-name :hyperdoc-fedwiki-okf-profile
   :not-a-converter-yet t
   :purpose "Specify how simple HyperDoc/FedWiki knowledge artifacts can be
             represented as conformant or extended OKF concept documents.")

  (!define-source-authorities
   :authorities
   (:zkn3-zettel-8892
    :okf-google-spec
    :okf-google-cloud-article
    :fedwiki-page-attached-asdf-systems
    :hyperdoc-native-plan-protocol
    :shop3-asdf-authority))

  (!map-okf-bundle
   :to (:fedwiki-site
        :fedwiki-neighborhood
        :page-asset-directory
        :git-repository)
   :mapping-quality :partial
   :losses (:federation-neighborhood-semantics
            :git-history-granularity
            :asset-executability))

  (!map-okf-concept-document
   :to (:fedwiki-page
        :hyperdoc-topic
        :page-attached-asdf-artifact)
   :mapping-quality :good-for-simple-concept-pages
   :open-question
   "Should one FedWiki page export as one OKF concept, or should selected
    story items export as separate concepts?")

  (!map-okf-frontmatter
   :fields
   ((:type :to (:topic-kind :page-kind :artifact-kind) :required t)
    (:title :to (:page-title :topic-title) :required nil)
    (:description :to (:synopsis :summary-story-item) :required nil)
    (:resource :to (:source-reference :asset-reference :native-store-locator) :required nil)
    (:tags :to (:keywords :topic-types :categories) :required nil)
    (:timestamp :to (:journal-date :story-item-time :git-commit-time) :required nil))
   :extension-policy
   (:consumers-must-ignore-unknown-fields t
    :hyperdoc-fields-use-prefix "hyperdoc_"))

  (!define-okf-link-model
   :okf-links :markdown-links
   :fedwiki-links (:wiki-links :backlinks :story-links :dmx-associations)
   :losses (:association-role-types
            :typed-topicmap-edges
            :journal-action-context)
   :repair-opportunity (:broken-okf-links-as-hyperdoc-lookup-issues))

  (!define-fedwiki-journal-loss-model
   :okf-log-md :chronological-history
   :fedwiki-journal (:create :edit :add :remove :fork)
   :mapping-quality :partial
   :rule "Do not collapse FedWiki journal semantics into log.md without
          preserving the original journal as a HyperDoc extension.")

  (!define-page-attached-asdf-extension-points
   :fields
   (:hyperdoc_asdf_system
    :hyperdoc_asset_root
    :hyperdoc_test_system
    :hyperdoc_dmx_sqlite
    :hyperdoc_source_authority)
   :rule "These are extensions, not OKF core requirements.")

  (!define-candidate-okf-types
   :types
   (:topic
    :concept
    :source-artifact
    :runbook
    :playbook
    :executable-task
    :page-asset
    :fedwiki-page
    :dmx-topicmap)
   :rule "Only map to OKF core type values once the OKF spec fixes or
          recommends canonical vocabularies.")

  (!define-validation-questions
   :questions
   ("Can this OKF document be consumed by a minimal OKF reader?"
    "What FedWiki semantics are lost by this projection?"
    "Is the original FedWiki page/journal/source authority preserved?"
    "Are executable page assets described but not accidentally executed?"
    "Are broken links represented as repairable lookup issues?"))

  (!record-design-boundary
   :must-not-implement-converter-yet t
   :must-not-edit-zkn3-source t
   :must-not-resume-contact-db-materialization t)

  (!select-next-task
   :task
   (!record-hyperdoc-fedwiki-okf-profile-design
    :mode :concept-design-only
    :from-plan
    "hyperdoc/llm-wiki-note-8892-hyperdoc-fedwiki-okf-profile-design-plan.sexp")))

 :expected-result
 (:plan-artifact-recorded t
  :converter-implemented nil
  :profile-design-ready-to-record t)

 :next
 (!record-hyperdoc-fedwiki-okf-profile-design
  :mode :concept-design-only
  :must-not-implement-converter-yet t
  :from-plan
  "hyperdoc/llm-wiki-note-8892-hyperdoc-fedwiki-okf-profile-design-plan.sexp"))
