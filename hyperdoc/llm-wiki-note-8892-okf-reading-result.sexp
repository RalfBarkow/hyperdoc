(:artifact llm-wiki-note-8892-okf-reading-result
 :kind reading-result
 :status recorded
 :mode concept-crosswalk-only

 :workflow-discipline
 (:task-location-before-implementation true
  :task-location-search-performed true
  :implementation-performed false
  :reason "This slice records a reading result and a conceptual crosswalk only.")

 :source-identity
 (:zkn3
  (:zettel-number "8892"
   :locator :xpath
   :zknid "260617160520934rgb27637"
   :title "LLM Wiki"
   :source "/Users/rgb/rgb~Zettelkasten/Zettelkasten-Dateien/rgb.zkn3"))

 :source-claims
 (:llm-wiki
  (:problem "RAG/file-upload systems rediscover knowledge from raw documents at query time."
   :solution "Maintain a persistent, interlinked Markdown wiki between raw sources and answers."
   :key-distinction "The wiki is not merely context; it is the maintained, compounding artifact."
   :layers
   ((:raw-sources :authority :human-curated :mutation-policy :immutable)
    (:wiki :authority :llm-maintained :medium :markdown)
    (:schema :authority :human-and-llm-coevolved :examples ("AGENTS.md" "CLAUDE.md")))
   :operations (:ingest :query :lint)
   :navigation-files ("index.md" "log.md")))

 :okf-source
 (:heise-url "https://heise.de/-11332215"
  :google-cloud-url "https://cloud.google.com/blog/products/data-analytics/how-the-open-knowledge-format-can-improve-data-sharing"
  :spec-url "https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md"
  :reading-summary
  "OKF v0.1 formalizes the LLM-wiki pattern as a portable, interoperable,
   vendor-neutral Markdown/YAML-frontmatter bundle format. It standardizes
   the minimum structural surface needed for producers and consumers to
   exchange maintained knowledge without requiring a proprietary platform,
   SDK, runtime, schema registry, or central authority.")

 :okf-model
 (:bundle "directory tree of Markdown files"
  :concept "one Markdown document"
  :concept-id "file path within bundle without .md suffix"
  :frontmatter (:required (type)
                :recommended (title description resource tags timestamp)
                :producer-extensions-allowed true)
  :body "standard Markdown, preferably structurally marked up"
  :links "standard Markdown links; graph edges are directed but semantically untyped"
  :reserved-files
  (("index.md" :directory-listing :progressive-disclosure)
   ("log.md" :chronological-history))
  :conformance
  (:all-non-reserved-md-files-have-parseable-yaml-frontmatter true
   :frontmatter-has-non-empty-type true
   :reserved-files-follow-index-log-structure-when-present true
   :consumers-tolerate-unknown-fields true
   :consumers-tolerate-broken-links true))

 :crosswalk
 (:karpathy-to-hyperdoc-fedwiki
  ((:raw-sources
    :karpathy "raw source documents"
    :hyperdoc (:source-artifacts :zkn3-source :zotero-attachments :pdfs :repomix-packs :web-clips)
    :boundary :read-only-source-of-truth)

   (:wiki
    :karpathy "LLM-maintained Markdown wiki"
    :hyperdoc (:fedwiki-pages :story-items :journals :backlinks :hyperdoc-topic-pages :page-assets)
    :boundary :maintained-synthesis-layer)

   (:schema
    :karpathy ("AGENTS.md" "CLAUDE.md")
    :hyperdoc (:htn-plans :shop3-plans :executable-dita-task-topics :scxml-workflows :page-attached-asdf-contracts)
    :boundary :agent-discipline-and-workflow-contract)

   (:ingest
    :karpathy "read source and update wiki"
    :hyperdoc (:source-station-assimilation :fedwiki-materialization :topic-factory :page-attached-asdf-materialization))

   (:query
    :karpathy "answer from maintained wiki and file valuable answers back"
    :hyperdoc (:moldable-inspector :topicmap-query :dmx-projection :answers-filed-as-pages))

   (:lint
    :karpathy "health-check contradictions, stale claims, orphan pages, missing links"
    :hyperdoc (:journal-checker :lookup-issue-repair :orphan-topic-detection :stale-claim-review :cross-reference-repair))))

 :okf-to-fedwiki-crosswalk
 ((:okf-bundle
   :fedwiki (:site-or-page-neighborhood :page-asset-directory :git-repository)
   :mapping-quality :partial)

  (:okf-concept-document
   :fedwiki (:page :story :page-attached-asset)
   :mapping-quality :good-for-simple-concepts)

  (:okf-frontmatter/type
   :fedwiki (:page-type :topic-kind :story-item-kind :page-attached-asdf-system-kind)
   :mapping-quality :good)

  (:okf-frontmatter/title
   :fedwiki (:page-title)
   :mapping-quality :good)

  (:okf-frontmatter/description
   :fedwiki (:synopsis :first-paragraph :summary-story-item)
   :mapping-quality :good)

  (:okf-frontmatter/resource
   :fedwiki (:source-reference :asset-reference :external-link :native-store-locator)
   :mapping-quality :good)

  (:okf-frontmatter/tags
   :fedwiki (:keywords :categories :topic-types)
   :mapping-quality :partial)

  (:okf-frontmatter/timestamp
   :fedwiki (:journal-date :story-item-metadata :git-commit-time)
   :mapping-quality :partial)

  (:okf-markdown-links
   :fedwiki (:wiki-links :backlinks :story-link-items)
   :mapping-quality :good-but-link-semantics-are-untyped-in-okf)

  (:okf-index-md
   :fedwiki (:sitemap :recent-neighborhood-index :topic-arrangement-page)
   :mapping-quality :partial)

  (:okf-log-md
   :fedwiki (:journal :recent-changes :git-history)
   :mapping-quality :partial)

  (:okf-citations
   :fedwiki (:source-citations :bibliography-items :zotero-bridge :source-artifacts)
   :mapping-quality :good)

  (:okf-broken-links-tolerated
   :fedwiki (:lookup-issues :unresolved-topic-links :repairable-routes)
   :mapping-quality :strong-hyperdoc-advantage))

 :main-reading-result
 (:okf-is-not
  (:replacement-for-fedwiki true
   :replacement-for-hyperdoc true
   :replacement-for-dmx true)

  :okf-is
  (:portable-interchange-profile true
   :structural-subset-of-fedwiki-hyperdoc-knowledge-artifacts true
   :possible-export-target true
   :possible-import-source true
   :possible-agent-consumption-profile true)

  :losses-if-exporting-fedwiki-to-plain-okf
  (:journal-action-semantics :story-item-types :fork-history :federation-neighborhood :page-attached-asdf-executability :dmx-topic-identity)

  :hyperdoc-opportunity
  "Define an OKF profile for HyperDoc/FedWiki that preserves simple concept
   pages as conformant OKF while declaring HyperDoc/FedWiki extensions for
   journal semantics, story item types, executable page assets, and DMX topic identity.")

 :open-questions
 ((:q1 "Should a FedWiki page export as one OKF concept document, or should selected story items export as concepts?")
  (:q2 "How should FedWiki journal actions map to OKF log.md without losing fork/edit/remove semantics?")
  (:q3 "Should page-attached ASDF systems be represented as OKF resources, extensions, or separate concept documents?")
  (:q4 "Can HyperDoc lookup issues become OKF-tolerated broken links plus repair metadata?")
  (:q5 "Should HyperDoc define okf_type values for topic, runbook, playbook, page-asset, source-artifact, and executable-task?"))

 :next
 (!design-hyperdoc-fedwiki-okf-profile
  :mode :concept-design-only
  :must-not-implement-converter-yet true
  :inputs (:zettel-8892 :heise-okf-article :google-okf-spec)
  :outputs (:mapping-rules :loss-model :extension-points :candidate-okf-frontmatter-fields)))
