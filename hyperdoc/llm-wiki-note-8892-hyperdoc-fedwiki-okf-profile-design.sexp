(:artifact llm-wiki-note-8892-hyperdoc-fedwiki-okf-profile-design
 :kind profile-design
 :status recorded
 :mode concept-design-only
 :must-not-implement-converter-yet t

 :profile
 (:name :hyperdoc-fedwiki-okf-profile
  :purpose
  "Define how selected HyperDoc/FedWiki knowledge artifacts may be projected
   into OKF-compatible Markdown/YAML concept documents while preserving the
   stronger HyperDoc/FedWiki source, journal, page-asset, and topic identity
   semantics as explicit extensions."

  :not
  (:not-a-converter t
   :not-a-replacement-for-fedwiki t
   :not-a-replacement-for-hyperdoc t
   :not-a-replacement-for-dmx t
   :not-a-runtime-execution-protocol t)

  :is
  (:interchange-profile t
   :reader-surface t
   :export-design-target t
   :import-design-target t
   :loss-model t
   :extension-policy t))

 :source-authorities
 ((:zkn3-zettel
   :number "8892"
   :title "LLM Wiki"
   :zknid "260617160520934rgb27637"
   :role :conceptual-source)

  (:reading-result
   :path "hyperdoc/llm-wiki-note-8892-okf-reading-result.sexp"
   :role :okf-fedwiki-crosswalk-source)

  (:protocol-selection
   :path "hyperdoc/llm-wiki-note-8892-okf-profile-plan-protocol-selection.sexp"
   :role :planner-protocol-source)

  (:design-plan
   :path "hyperdoc/llm-wiki-note-8892-hyperdoc-fedwiki-okf-profile-design-plan.sexp"
   :role :ordered-plan-source)

  (:local-shop3
   :path "/Users/rgb/workspace/shop3/shop3/shop3.asd"
   :role :planner-source-authority)

  (:fedwiki-page-attached-llm-wiki-system
   :path "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/documents-as-a-maintained-wiki/llm-wiki-paper-hyperdoc/llm-wiki-paper-hyperdoc.asd"
   :role :page-attached-asdf-precedent))

 :core-mapping-rules
 ((:okf-bundle
   :maps-to
   (:fedwiki-site
    :fedwiki-neighborhood
    :page-asset-directory
    :git-repository)
   :mapping-quality :partial
   :rule
   "An OKF bundle can represent a selected projection of a FedWiki/HyperDoc
    knowledge neighborhood, but it must not be treated as the authoritative
    federation state.")

  (:okf-concept-document
   :maps-to
   (:fedwiki-page
    :hyperdoc-topic
    :page-attached-asdf-artifact)
   :mapping-quality :good-for-simple-concept-pages
   :rule
   "A simple concept page can project to one OKF concept document. More complex
    pages with executable assets, journals, or story-item structure require
    HyperDoc extension fields.")

  (:okf-frontmatter-type
   :maps-to
   (:topic-kind
    :page-kind
    :artifact-kind
    :task-kind)
   :mapping-quality :good
   :rule
   "The OKF required type field maps to HyperDoc/FedWiki topic or artifact
    kind. HyperDoc should preserve the local kind even if it also emits a
    normalized OKF type.")

  (:okf-frontmatter-title
   :maps-to
   (:fedwiki-title
    :hyperdoc-topic-title)
   :mapping-quality :good)

  (:okf-frontmatter-description
   :maps-to
   (:fedwiki-synopsis
    :summary-story-item
    :topic-shortdesc)
   :mapping-quality :good)

  (:okf-frontmatter-resource
   :maps-to
   (:source-reference
    :asset-reference
    :native-store-locator
    :capability-link)
   :mapping-quality :good
   :rule
   "Resource must identify the source or authority for the concept without
    forcing execution or dereferencing.")

  (:okf-frontmatter-tags
   :maps-to
   (:keywords
    :topic-types
    :categories
    :dmx-type-uris)
   :mapping-quality :partial
   :loss
   (:tag-role-semantics
    :typed-association-semantics))

  (:okf-frontmatter-timestamp
   :maps-to
   (:journal-date
    :story-item-time
    :git-commit-time
    :reading-result-time)
   :mapping-quality :partial
   :rule
   "Timestamp alone is not a substitute for FedWiki journal semantics.")

  (:okf-markdown-links
   :maps-to
   (:wiki-links
    :backlinks
    :story-links
    :dmx-associations)
   :mapping-quality :good-but-untyped
   :loss
   (:association-role-types
    :topicmap-edge-types
    :journal-action-context))

  (:okf-index-md
   :maps-to
   (:site-index
    :topic-arrangement-page
    :neighborhood-routing-page)
   :mapping-quality :partial)

  (:okf-log-md
   :maps-to
   (:fedwiki-journal
    :recent-changes
    :git-history
    :reading-result-log)
   :mapping-quality :partial
   :rule
   "OKF log.md may summarize history, but the original FedWiki journal must be
    preserved as an extension or source artifact."))

 :loss-model
 (:losses-in-plain-okf
  (:fedwiki-journal-action-semantics
   :story-item-type-semantics
   :fork-lineage
   :federation-neighborhood-context
   :page-attached-asdf-executability
   :dmx-topic-identity
   :typed-association-role-semantics
   :lookup-issue-repair-state
   :source-station-boundary)

  :must-preserve-as-extensions
  (:original-fedwiki-page-json
   :original-fedwiki-journal
   :hyperdoc-topic-id
   :hyperdoc-source-authority
   :page-attached-asdf-system
   :dmx-topicmap-reference
   :lookup-issue-state))

 :hyperdoc-extension-fields
 ((:field :hyperdoc_source_authority
   :value-kind :string-or-object
   :purpose "Record the authority boundary for the concept.")

  (:field :hyperdoc_fedwiki_slug
   :value-kind :string
   :purpose "Preserve FedWiki page identity.")

  (:field :hyperdoc_fedwiki_site
   :value-kind :string
   :purpose "Preserve federation/site identity.")

  (:field :hyperdoc_journal_ref
   :value-kind :path-or-object
   :purpose "Refer to the original FedWiki journal instead of flattening it.")

  (:field :hyperdoc_asdf_system
   :value-kind :string
   :purpose "Name a page-attached ASDF system without loading it.")

  (:field :hyperdoc_asset_root
   :value-kind :path
   :purpose "Locate page-attached assets.")

  (:field :hyperdoc_test_system
   :value-kind :string
   :purpose "Name optional validation system.")

  (:field :hyperdoc_dmx_topic_id
   :value-kind :string-or-integer
   :purpose "Preserve DMX topic identity when available.")

  (:field :hyperdoc_dmx_topicmap_id
   :value-kind :string-or-integer
   :purpose "Preserve DMX topicmap projection identity when available.")

  (:field :hyperdoc_lookup_issues
   :value-kind :list
   :purpose "Represent unresolved links as repairable lookup issues."))

 :candidate-okf-types
 ((:type "topic"
   :use-for (:generic-hyperdoc-topic :fedwiki-concept-page))

  (:type "concept"
   :use-for (:stable-explanatory-page :concept-topic))

  (:type "source-artifact"
   :use-for (:zkn3-zettel :pdf :web-clip :repomix-pack))

  (:type "runbook"
   :use-for (:operational-procedure :maintenance-task-sequence))

  (:type "playbook"
   :use-for (:reusable-response-pattern :agent-workflow))

  (:type "executable-task"
   :use-for (:executable-dita-task :pddl-task :shop3-task)
   :extension-required t)

  (:type "page-asset"
   :use-for (:fedwiki-page-attached-asdf-system :sqlite-artifact :static-page-asset)
   :extension-required t)

  (:type "topicmap"
   :use-for (:dmx-topicmap :hyperdoc-topicmap)
   :extension-required t))

 :minimal-okf-frontmatter-template
 (:type "concept"
  :title "<FedWiki or HyperDoc title>"
  :description "<synopsis or shortdesc>"
  :resource "<source authority or page URL/path>"
  :tags ("hyperdoc" "fedwiki")
  :timestamp "<ISO-8601 timestamp>"
  :hyperdoc_source_authority "<source authority>"
  :hyperdoc_fedwiki_slug "<slug>"
  :hyperdoc_asdf_system "<optional page-attached ASDF system>")

 :validation-questions
 ("Can a minimal OKF consumer parse the Markdown/YAML document without knowing HyperDoc?"
  "Does the projection preserve the original FedWiki page and journal as source authority?"
  "Which semantics are lost if HyperDoc extensions are ignored?"
  "Are executable ASDF/page assets described but not executed?"
  "Are unresolved links represented as lookup issues rather than silently dropped?"
  "Can the OKF concept be traced back to the Zettel, page, or source artifact that authorized it?")

 :design-boundary
 (:converter-implemented nil
  :importer-implemented nil
  :exporter-implemented nil
  :zkn3-source-edited nil
  :contact-db-materialization-resumed nil)

 :next
 (!record-okf-profile-as-fedwiki-or-hyperdoc-topic
  :mode :topic-materialization-design-only
  :must-not-implement-converter-yet t
  :source "hyperdoc/llm-wiki-note-8892-hyperdoc-fedwiki-okf-profile-design.sexp"))
