(:artifact llm-wiki-note-8892-reading-shop3-plan
 :kind shop3-selected-plan
 :status ready-to-execute-in-sly

 :problem
 (:name read-llm-wiki-note-8892-with-okf-article-problem
  :objects
  (:zettel-id "8892"
   :zkn3-source "/Users/rgb/rgb~Zettelkasten/Zettelkasten-Dateien/rgb.zkn3"
   :article-url "https://heise.de/-11332215"
   :topic-title "LLM Wiki")
  :initial-state
  (:contact-db-work-paused true
   :existing-reading-families-known true
   :zettel-8892-not-yet-read-in-this-episode true
   :okf-article-not-yet-read-in-this-episode true)
  :goal
  (:zettel-8892-read true
   :okf-article-read true
   :operational-reading-definition-recorded true
   :llm-wiki-okf-crosswalk-recorded true
   :next-topic-task-selected true))

 :selected-ordered-plan
 ((!record-reading-plan
   :artifact "hyperdoc/llm-wiki-note-8892-reading-htn.sexp")

  (!check-existing-reading-task-families
   :families (:read-through-zkn3-zettel
              :critical-reading
              :goldberg-reader-operations
              :knuth-web-reader-operations))

  (!read-zkn3-zettel
   :zettel-id "8892"
   :source "/Users/rgb/rgb~Zettelkasten/Zettelkasten-Dateien/rgb.zkn3")

  (!read-web-article
   :url "https://heise.de/-11332215"
   :title "Open Knowledge Format: KI-Wissen als Markdown-Dateien")

  (!segment-claims
   :sources (:zettel-8892 :heise-okf-article :google-cloud-okf-announcement))

  (!construct-crosswalk
   :from (:okf-bundle :markdown-file :yaml-frontmatter :markdown-link :static-viewer)
   :to (:fedwiki-page :story-item :journal :backlink :page-asset :page-attached-asdf-system))

  (!formulate-reading-questions
   :topic "LLM Wiki")

  (!record-reading-result
   :artifact "hyperdoc/llm-wiki-note-8892-okf-reading-result.sexp")

  (!select-next-reading-task
   :candidate
   (!design-okf-fedwiki-crosswalk
    :mode :concept-design-only
    :must-not-implement-converter-yet true)))

 :non-goals
 (:do-not-materialize-contact-db-now true
  :do-not-implement-okf-converter-now true
  :do-not-edit-zkn3-source true
  :do-not-write-dmx-remote-neo4j true))
