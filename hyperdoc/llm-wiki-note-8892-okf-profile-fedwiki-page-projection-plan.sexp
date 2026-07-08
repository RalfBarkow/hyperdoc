(:artifact llm-wiki-note-8892-okf-profile-fedwiki-page-projection-plan
 :kind fedwiki-page-projection-plan
 :status recorded
 :mode page-projection-plan-only
 :must-not-implement-converter-yet t
 :fedwiki-page-written nil

 :source
 (:topic-materialization-design
  "hyperdoc/llm-wiki-note-8892-okf-profile-topic-materialization-design.sexp"
  :profile-design
  "hyperdoc/llm-wiki-note-8892-hyperdoc-fedwiki-okf-profile-design.sexp"
  :source-zettel "8892"
  :source-zknid "260617160520934rgb27637")

 :page-identity
 (:site "wiki.ralfbarkow.ch"
  :slug "hyperdoc-fedwiki-okf-profile"
  :title "HyperDoc/FedWiki OKF Profile"
  :status :planned-not-written)

 :projection-purpose
 "Project the HyperDoc/FedWiki OKF Profile design into a FedWiki page shape
  so that the profile becomes part of the maintained wiki layer. This plan
  describes the page, story items, journal intent, backlinks, and validation
  checks, but it does not write the page JSON or mutate the FedWiki site."

 :selected-ordered-plan
 ((!record-page-projection-plan
   :artifact
   "hyperdoc/llm-wiki-note-8892-okf-profile-fedwiki-page-projection-plan.sexp")

  (!define-fedwiki-page-identity
   :site "wiki.ralfbarkow.ch"
   :slug "hyperdoc-fedwiki-okf-profile"
   :title "HyperDoc/FedWiki OKF Profile")

  (!define-page-synopsis
   :text
   "A design-only HyperDoc/FedWiki profile for projecting selected knowledge
    artifacts into OKF-compatible Markdown/YAML while preserving source
    authority, journal, page-asset, DMX, lookup-issue, and task boundaries as
    explicit HyperDoc extensions.")

  (!define-story-items
   :items
   ((:id :purpose
     :type :paragraph
     :text
     "OKF is treated here as a portable interchange profile for the LLM Wiki
      pattern, not as a replacement for FedWiki, HyperDoc, DMX, SHOP3, or
      page-attached ASDF systems.")

    (:id :source-authorities
     :type :paragraph
     :text
     "The page is authorized by Zettel 8892, the OKF reading result, the
      HyperDoc-native plan protocol selection, the profile design plan, the
      recorded profile design, and the topic materialization design.")

    (:id :mapping-summary
     :type :paragraph
     :text
     "The profile maps OKF bundles to FedWiki neighborhoods or page asset
      directories, OKF concept documents to FedWiki pages and HyperDoc topics,
      OKF frontmatter to topic/page metadata, Markdown links to wiki links and
      DMX associations, and OKF log.md to a lossy journal summary.")

    (:id :loss-model
     :type :paragraph
     :text
     "Plain OKF loses FedWiki journal action semantics, story-item typing,
      fork lineage, federation-neighborhood context, page-attached ASDF
      executability, DMX identity, typed association roles, lookup issue state,
      and source-station boundaries.")

    (:id :extension-policy
     :type :paragraph
     :text
     "HyperDoc extensions preserve source authority, FedWiki site and slug,
      journal reference, page-attached ASDF system, asset root, optional test
      system, DMX topic/topicmap identity, and lookup issues.")

    (:id :boundary
     :type :paragraph
     :text
     "This page projection remains design-only. It does not implement an OKF
      converter, importer, exporter, or runtime execution protocol, and it does
      not mutate the ZKN3 source or resume Contact DB materialization.")))

  (!define-intended-links
   :links
   ((:from "HyperDoc/FedWiki OKF Profile" :to "LLM Wiki")
    (:from "HyperDoc/FedWiki OKF Profile" :to "Open Knowledge Format")
    (:from "HyperDoc/FedWiki OKF Profile" :to "FedWiki")
    (:from "HyperDoc/FedWiki OKF Profile" :to "page-attached ASDF system")
    (:from "HyperDoc/FedWiki OKF Profile" :to "SHOP3")
    (:from "HyperDoc/FedWiki OKF Profile" :to "DMX")))

  (!define-journal-intent
   :action :create
   :reason
   "Create a durable FedWiki projection of the OKF profile design after the
    projection plan has been recorded and validated.")

  (!define-validation-checks
   :checks
   ((:check :page-identity-stable
     :question "Does the planned page use the stable slug hyperdoc-fedwiki-okf-profile?")

    (:check :design-boundary-preserved
     :question "Does the projection avoid writing the page or implementing converter code?")

    (:check :source-authority-visible
     :question "Does the page identify Zettel 8892 and the recorded design artifacts?")

    (:check :loss-model-visible
     :question "Does the page expose what plain OKF loses?")

    (:check :extension-policy-visible
     :question "Does the page name HyperDoc extension fields and their purpose?")))

  (!record-design-boundary
   :fedwiki-page-written nil
   :okf-converter-implemented nil
   :okf-importer-implemented nil
   :okf-exporter-implemented nil
   :zkn3-source-edited nil
   :contact-db-materialization-resumed nil)

  (!select-next-task
   :task
   (!materialize-fedwiki-page-projection-for-okf-profile
    :mode :page-json-write
    :requires-explicit-operator-approval t
    :source
    "hyperdoc/llm-wiki-note-8892-okf-profile-fedwiki-page-projection-plan.sexp")))

 :fedwiki-page-json-shape
 (:title "HyperDoc/FedWiki OKF Profile"
  :story (:from-selected-story-items true)
  :journal
  ((:type "create"
    :item :page
    :date :future-materialization-time
    :note "planned only; not written by this artifact")))

 :validation-questions
 ("Does this plan remain a page projection plan rather than a page write?"
  "Does it preserve the OKF-as-profile / FedWiki-as-maintained-wiki distinction?"
  "Does it identify all source authorities needed for future page creation?"
  "Does it leave unresolved links as explicit future lookup issues rather than hiding them?"
  "Does it maintain the no-converter/no-importer/no-exporter boundary?")

 :design-boundary
 (:fedwiki-page-written nil
  :hyperdoc-runtime-code-written nil
  :okf-converter-implemented nil
  :okf-importer-implemented nil
  :okf-exporter-implemented nil
  :zkn3-source-edited nil
  :contact-db-materialization-resumed nil)

 :next
 (!materialize-fedwiki-page-projection-for-okf-profile
  :mode :page-json-write
  :requires-explicit-operator-approval t
  :source
  "hyperdoc/llm-wiki-note-8892-okf-profile-fedwiki-page-projection-plan.sexp"))
