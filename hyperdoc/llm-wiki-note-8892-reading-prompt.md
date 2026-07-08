Reading task: LLM Wiki / Zettel 8892 / Open Knowledge Format.

We are pausing Contact DB materialization and opening a reading episode.

Operational definition:
Reading is an ordered, inspectable transformation of source objects into durable topic work:
acquire source, preserve provenance, segment claims, locate existing task/topic context, compare with existing topics, formulate questions, record distinctions, update HTN/topic map, and produce a reusable reading result.

Sources:
- Zettel 8892, topic: LLM Wiki
- heise link: https://heise.de/-11332215
- article title: Open Knowledge Format: KI-Wissen als Markdown-Dateien
- official OKF context: Google Cloud's Open Knowledge Format announcement

Reuse existing reading task families:
- read-through-zkn3-zettel
- critical-reading
- Goldberg reader operations
- Knuth / How to Read a Web reader operations

Selected task:
(!read-llm-wiki-note-8892-with-okf-article
 :zettel-id "8892"
 :topic "LLM Wiki"
 :article-url "https://heise.de/-11332215"
 :must-update-htn true
 :must-preserve-source-provenance true)

Reading questions:
1. What does Note 8892 already say about LLM Wiki?
2. What does OKF add to our existing FedWiki-as-LLM-Wiki pattern?
3. Is OKF a competing format, an export target, or a profile of page-attached knowledge artifacts?
4. Which fields in OKF correspond to FedWiki page title, story, journal, backlinks, assets, and page-attached ASDF systems?
5. What would an OKF producer/consumer look like in HyperDoc?

Boundary:
- Do not implement an OKF converter yet.
- Do not resume Contact DB materialization in this slice.
- Do not edit the ZKN3 source.
- Do not write to remote DMX/Neo4j.
- Produce a reading result and a next task candidate.
