(:artifact llm-wiki-note-8892-reading-htn
 :kind htn-continuation
 :status active-reading-root

 :pause
 (:suspended-root-task
  (!materialize-hyperdoc-contact-db-topic
   :from-design-task design-hyperdoc-contact-db-topic-and-fedwiki-page-plan
   :target (:fedwiki-page :page-attached-asdf-system :sqlite-schema)
   :must-preserve-native-authority true)
  :reason "Return to LLM Wiki / Note 8892 reading episode.")

 :root-task
 (!read-llm-wiki-note-8892-with-okf-article
  :zettel-id "8892"
  :topic "LLM Wiki"
  :article-url "https://heise.de/-11332215"
  :article-title "Open Knowledge Format: KI-Wissen als Markdown-Dateien"
  :must-update-htn true
  :must-preserve-source-provenance true)

 :operational-definition
 (:reading
  "Reading is an ordered, inspectable transformation of source objects into durable topic work:
   acquire source, preserve provenance, segment claims, locate existing task/topic context,
   compare with existing topics, formulate questions, record distinctions, update HTN/topic map,
   and produce a reusable reading result.")

 :existing-reading-task-families
 ((:family read-through-zkn3-zettel
   :reused-operators
   (!classify-zkn3-container
    !extract-zkn3-member
    !parse-zkn-file-xml
    !locate-zkn3-zettel-entry
    !extract-zkn3-zettel-text
    !inspect-zettel-source-result
    !read-zettel-text
    !record-reading-result))

  (:family critical-reading
   :reused-operators
   (!read-program-critically
    !identify-obscure-expressions
    !identify-confusing-control-flow
    !compare-original-and-rewrite
    !derive-style-rule-from-rewrite))

  (:family goldberg-reader-operations
   :role "Programmer-as-reader operations: read to learn, find, rewrite, maintain, and derive reusable operations.")

  (:family knuth-web-reader-operations
   :role "Distinguish reader order, machine order, and projection order."))

 :method
 (:name read-zettel-and-okf-as-llm-wiki-topic
  :subtasks
  ((!record-reading-plan)
   (!check-existing-reading-task-families)
   (!locate-zkn3-zettel-entry :zettel-id "8892")
   (!extract-zkn3-zettel-text :zettel-id "8892")
   (!acquire-web-source :url "https://heise.de/-11332215")
   (!preserve-source-provenance)
   (!segment-source-claims)
   (!identify-okf-format-claims)
   (!map-claims-to-llm-wiki-pattern)
   (!compare-okf-to-fedwiki-as-llm-wiki)
   (!formulate-reading-questions)
   (!record-reading-result)
   (!update-topic-map)
   (!close-reading-plan)))

 :initial-reading-questions
 ((:q1 "What does Note 8892 already say about LLM Wiki?")
  (:q2 "What does OKF add to our existing FedWiki-as-LLM-Wiki pattern?")
  (:q3 "Is OKF a competing format, an export target, or a profile of page-attached knowledge artifacts?")
  (:q4 "Which fields in OKF correspond to FedWiki page title, story, journal, backlinks, assets, and page-attached ASDF systems?")
  (:q5 "What would an OKF producer/consumer look like in HyperDoc?"))

 :next
 (!read-zkn3-zettel-8892
  :mode :source-reading-only
  :then-read-url "https://heise.de/-11332215"
  :then-record-llm-wiki-okf-crosswalk true))
