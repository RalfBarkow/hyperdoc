(:artifact llm-wiki-note-8892-okf-profile-topic-materialization-design
 :kind topic-materialization-design
 :status recorded
 :mode topic-materialization-design-only
 :must-not-implement-converter-yet t

 :source
 (:profile-design
  "hyperdoc/llm-wiki-note-8892-hyperdoc-fedwiki-okf-profile-design.sexp"
  :profile-name :hyperdoc-fedwiki-okf-profile
  :source-zettel "8892"
  :source-zknid "260617160520934rgb27637")

 :topic-identity
 (:topic-id "hyperdoc-fedwiki-okf-profile"
  :title "HyperDoc/FedWiki OKF Profile"
  :slug "hyperdoc-fedwiki-okf-profile"
  :topic-kind :architectural-profile
  :status :design-only)

 :concept-definition
 "The HyperDoc/FedWiki OKF Profile specifies how selected HyperDoc and
  FedWiki knowledge artifacts can be projected into OKF-compatible
  Markdown/YAML concept documents while preserving stronger HyperDoc/FedWiki
  semantics as explicit extensions: source authority, journal history,
  page-attached ASDF systems, DMX identity, lookup issues, and executable
  task boundaries."

 :materialization-targets
 ((:hyperdoc-topic
   :role :canonical-design-topic
   :artifact-kind :sexp-topic
   :path
   "hyperdoc/llm-wiki-note-8892-okf-profile-topic-materialization-design.sexp")

  (:fedwiki-page
   :role :page-projection
   :site "wiki.ralfbarkow.ch"
   :slug "hyperdoc-fedwiki-okf-profile"
   :status :design-only-not-written-yet)

  (:executable-dita-concept
   :role :concept-topic-projection
   :status :candidate)

  (:executable-dita-task
   :role :future-task-contract
   :status :candidate)

  (:shop3-plan-topic
   :role :future-planner-projection
   :status :candidate))

 :fedwiki-page-projection
 (:title "HyperDoc/FedWiki OKF Profile"
  :slug "hyperdoc-fedwiki-okf-profile"
  :synopsis
  "A design-only profile for projecting selected HyperDoc/FedWiki knowledge
   artifacts into OKF-compatible Markdown/YAML while preserving FedWiki and
   HyperDoc semantics as extensions."

  :story
  ((:item-id :purpose
    :type :paragraph
    :text
    "This page records the HyperDoc/FedWiki OKF Profile as a topic. OKF is
     treated as a portable interchange profile, not as a replacement for
     FedWiki, HyperDoc, DMX, page-attached ASDF systems, or SHOP3/HTN plans.")

   (:item-id :source-authorities
    :type :paragraph
    :text
    "The profile is authorized by Zettel 8892 'LLM Wiki', the OKF reading
     result, the protocol-selection artifact, the profile design plan, the
     recorded profile design, local SHOP3 ASDF authority, and the
     page-attached LLM Wiki ASDF system.")

   (:item-id :core-mapping
    :type :paragraph
    :text
    "The core mapping relates OKF bundles to FedWiki sites or neighborhoods,
     OKF concept documents to FedWiki pages and HyperDoc topics, OKF
     frontmatter to topic/page/artifact metadata, Markdown links to wiki links
     and DMX associations, and OKF log.md to a lossy journal summary.")

   (:item-id :loss-model
    :type :paragraph
    :text
    "Plain OKF loses FedWiki journal action semantics, story-item typing,
     fork lineage, federation-neighborhood context, page-attached ASDF
     executability, DMX topic identity, typed association roles, lookup issue
     state, and source-station boundaries.")

   (:item-id :extension-policy
    :type :paragraph
    :text
    "HyperDoc extensions must preserve source authority, FedWiki slug and
     site, journal reference, page-attached ASDF system, asset root, optional
     test system, DMX topic and topicmap identity, and lookup issues.")

   (:item-id :boundary
    :type :paragraph
    :text
    "This is still design-only. No OKF converter, importer, exporter, ZKN3
     mutation, or Contact DB materialization is performed by this topic.")))

 :topic-associations
 ((:association :specializes
   :from "hyperdoc-fedwiki-okf-profile"
   :to "llm-wiki"
   :reason "OKF is read as a portable profile of the LLM Wiki pattern.")

  (:association :projects-to
   :from "fedwiki-page"
   :to "okf-concept-document"
   :mapping-quality :good-for-simple-concept-pages)

  (:association :preserves-as-extension
   :from "fedwiki-journal"
   :to "hyperdoc_journal_ref"
   :reason "OKF log.md is insufficient to preserve journal semantics.")

  (:association :preserves-as-extension
   :from "page-attached-asdf-system"
   :to "hyperdoc_asdf_system"
   :reason "Executable assets must be described without accidental execution.")

  (:association :records-loss
   :from "dmx-association"
   :to "okf-markdown-link"
   :loss (:role-type :association-type :topicmap-context)))

 :executable-dita-concept-candidate
 (:concept-id "hyperdoc-fedwiki-okf-profile"
  :title "HyperDoc/FedWiki OKF Profile"
  :shortdesc
  "Design-only profile for OKF projection of HyperDoc/FedWiki knowledge artifacts."
  :conbody
  (:purpose :mapping-rules :loss-model :extension-policy :validation-questions))

 :executable-task-topic-candidate
 (:task-id "record-okf-profile-as-fedwiki-or-hyperdoc-topic"
  :task
  (!record-okf-profile-as-fedwiki-or-hyperdoc-topic
   :mode :topic-materialization-design-only
   :must-not-implement-converter-yet t)
  :steps
  ((!record-topic-identity)
   (!record-page-projection)
   (!record-topic-associations)
   (!record-validation-questions)
   (!record-design-boundary))
  :expected-result
  (:topic-materialization-design-recorded t
   :fedwiki-page-written nil
   :converter-implemented nil))

 :validation-questions
 ("Does the topic preserve the distinction between OKF as interchange profile and FedWiki as maintained wiki?"
  "Does the page projection preserve source authority and journal semantics as extensions?"
  "Does the design avoid implementing converter/importer/exporter code?"
  "Does the topic expose the loss model explicitly?"
  "Can this topic later be promoted to a FedWiki page or DITA concept without changing the profile semantics?")

 :design-boundary
 (:fedwiki-page-written nil
  :hyperdoc-runtime-code-written nil
  :okf-converter-implemented nil
  :okf-importer-implemented nil
  :okf-exporter-implemented nil
  :zkn3-source-edited nil
  :contact-db-materialization-resumed nil)

 :next
 (!record-fedwiki-page-projection-plan-for-okf-profile
  :mode :page-projection-plan-only
  :source "hyperdoc/llm-wiki-note-8892-okf-profile-topic-materialization-design.sexp"
  :must-not-implement-converter-yet t))
