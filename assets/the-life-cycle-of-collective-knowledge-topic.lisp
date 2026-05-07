;; HYPERDOC_LOCALHOST_FEDWIKI_SOURCE_SNAPSHOT (:SNAPSHOT-KIND "localhost-fedwiki-page-source-snapshot" :SNAPSHOT-FORMAT-VERSION 1 :FINGERPRINT-ALGORITHM "fnv1a-64-over-normalized-raw-page-story-and-journal" :FINGERPRINT "fnv1a64:168557695B6C63A3" :SUMMARY "story-items=2; fragments=7; journal=6; last-journal=1774540104897" :SOURCE-PAGE-ID "fedwiki:wiki.ralfbarkow.ch/the-life-cycle-of-collective-knowledge" :SOURCE-PAGE-SLUG "the-life-cycle-of-collective-knowledge" :SOURCE-PAGE-PATH "pages/the-life-cycle-of-collective-knowledge" :SOURCE-PAGE-TITLE "The Life Cycle of Collective Knowledge" :STORY-ITEM-COUNT 2 :FRAGMENT-COUNT 7 :JOURNAL-ENTRY-COUNT 6 :JOURNAL-LAST-DATE 1774540104897 :PAGE-CREATE-DATE 1774540076497)

(:TOPIC-FACTORY-SNIPPET :ID "the-life-cycle-of-collective-knowledge-topic-set"
                        :SOURCE-FILE "assets/the-life-cycle-of-collective-knowledge-topic.lisp"
                        :SOURCE-ORIGIN-ID
                        "fedwiki:wiki.ralfbarkow.ch/the-life-cycle-of-collective-knowledge"
                        :SOURCE-ORIGIN-PATH "pages/the-life-cycle-of-collective-knowledge"
                        :RELATED-HYPERDOC-PAGE-TITLE "The Life Cycle of Collective Knowledge"
                        :RELATED-TOPIC-ID "the-life-cycle-of-collective-knowledge" :RELATED-TOPIC-IDS
                        ("the-life-cycle-of-collective-knowledge" "collective-knowledge"
                                                                  "refinement-of-information-into-knowledge"
                                                                  "digital-fragility-of-software-source-code"
                                                                  "computational-reproducibility-is-not-enough"
                                                                  "software-interoperability-across-time" "stable-software-environments")
                        :PROVENANCE
                        (:SOURCE-KIND "localhost-fedwiki-topic-factory-snippet" :SOURCE-PAGE-ID
                                      "fedwiki:wiki.ralfbarkow.ch/the-life-cycle-of-collective-knowledge"
                                      :SOURCE-PAGE-PATH "pages/the-life-cycle-of-collective-knowledge"
                                      :PROVENANCE-GRANULARITY "story-item-fragment" :SOURCE-STORY-ITEM-SOURCE-ID
                                      "fedwiki:wiki.ralfbarkow.ch/the-life-cycle-of-collective-knowledge#story-item/3cf5038a96d6b6ee"
                                      :SOURCE-FRAGMENT-ORDINALS (0 6 3 4 5) :SOURCE-FRAGMENT-ANCHORS
                                      ("segment:0" "segment:6" "segment:3" "segment:4" "segment:5")
                                      :SOURCE-FRAGMENT-SECTION-KEYS
                                      ("intro" "claim-carried-by-this-page" "why-this-matters-for-hyperdoc"
                                               "why-this-matters-for-hyperdoc" "why-this-matters-for-hyperdoc")
                                      :SOURCE-FRAGMENT-EXCERPT
                                      "This page anchors Konrad Hinsen's FedWiki note on how collective knowledge is published, reviewed, cited, combined, a..."
                                      :SOURCE-FRAGMENT-EXCERPTS
                                      ("This page anchors Konrad Hinsen's FedWiki note on how collective knowledge is published, reviewed, cited, combined, a..."
                                       "The life cycle of collective knowledge does not stop at preservation. It also requires forms of software publication ..."
                                       "The central claim is that collective knowledge depends on representations that stay usable long enough to be reviewed..."
                                       "Archiving old environments improves reproducibility, but the stronger demand for collective knowledge is interoperabi..."
                                       "This is the point at which the FedWiki note connects directly to HyperDoc's long-term interest in Common Lisp. The no...")
                                      :DERIVATION-NOTE
                                      "Dry-run-first DMX snippet twin for authored HyperDoc topic factories derived from paragraph fragments in one localhost FedWiki story item."
                                      :SOURCE-PAGE-SLUG "the-life-cycle-of-collective-knowledge"
                                      :SOURCE-STORY-ITEM-ID "3cf5038a96d6b6ee" :SOURCE-STORY-ITEM-INDEX 0
                                      :SOURCE-STORY-ITEM-TYPE "paragraph" :JOURNAL-ACTION-COUNT 2
                                      :JOURNAL-ACTION-TYPES ("add" "edit") :JOURNAL-LAST-DATE 1774540081043
                                      :PAGE-CREATE-DATE 1774540076497 :PROVENANCE-CLASSIFICATION
                                      "story-item-id-and-journal"))

;; Topic-factory snippet bundle for The Life Cycle of Collective Knowledge.

(defun THE-LIFE-CYCLE-OF-COLLECTIVE-KNOWLEDGE-TOPIC ()
  (make-topic
   :id "the-life-cycle-of-collective-knowledge"
   :title "The Life Cycle of Collective Knowledge"
   :summary "Collective knowledge remains alive only when its representations stay usable long enough to be reviewed, recombined, and reused across time."
   :references '("Source-oriented and image-oriented development in Common Lisp"
                 "Opening external FedWiki sites"
                 "fedwiki:wiki.ralfbarkow.ch/the-life-cycle-of-collective-knowledge")))

(defun COLLECTIVE-KNOWLEDGE-TOPIC ()
  (make-topic
   :id "collective-knowledge"
   :title "Collective knowledge"
   :summary "Collective knowledge is information that has been published, reviewed, cited, recombined, and carried forward beyond any single contributor or file format."
   :references '("The Life Cycle of Collective Knowledge"
                 "Source-oriented and image-oriented development in Common Lisp"
                 "fedwiki:wiki.ralfbarkow.ch/the-life-cycle-of-collective-knowledge")))

(defun REFINEMENT-OF-INFORMATION-INTO-KNOWLEDGE-TOPIC ()
  (make-topic
   :id "refinement-of-information-into-knowledge"
   :title "Refinement of information into knowledge"
   :summary "Information becomes knowledge when communities can inspect, cite, compare, refine, and recombine it through durable representations."
   :references '("The Life Cycle of Collective Knowledge"
                 "fedwiki:wiki.ralfbarkow.ch/the-life-cycle-of-collective-knowledge")))

(defun DIGITAL-FRAGILITY-OF-SOFTWARE-SOURCE-CODE-TOPIC ()
  (make-topic
   :id "digital-fragility-of-software-source-code"
   :title "Digital fragility of software source code"
   :summary "Software source code is digitally fragile because its intelligibility and execution depend on machines, runtimes, toolchains, and surrounding environments."
   :references '("The Life Cycle of Collective Knowledge"
                 "Source-oriented and image-oriented development in Common Lisp"
                 "fedwiki:wiki.ralfbarkow.ch/the-life-cycle-of-collective-knowledge")))

(defun COMPUTATIONAL-REPRODUCIBILITY-IS-NOT-ENOUGH-TOPIC ()
  (make-topic
   :id "computational-reproducibility-is-not-enough"
   :title "Computational reproducibility is not enough"
   :summary "Archiving old environments preserves rerun capability, but collective knowledge needs more than frozen reproducibility snapshots."
   :references '("The Life Cycle of Collective Knowledge"
                 "Source-oriented and image-oriented development in Common Lisp"
                 "A framework for maintaining the coherence of a running Lisp"
                 "fedwiki:wiki.ralfbarkow.ch/the-life-cycle-of-collective-knowledge")))

(defun SOFTWARE-INTEROPERABILITY-ACROSS-TIME-TOPIC ()
  (make-topic
   :id "software-interoperability-across-time"
   :title "Software interoperability across time"
   :summary "Long-lived software knowledge requires later systems to inspect, compare, and reuse earlier components across time instead of only preserving them as inert artifacts."
   :references '("The Life Cycle of Collective Knowledge"
                 "Source-oriented and image-oriented development in Common Lisp"
                 "fedwiki:wiki.ralfbarkow.ch/the-life-cycle-of-collective-knowledge")))

(defun STABLE-SOFTWARE-ENVIRONMENTS-TOPIC ()
  (make-topic
   :id "stable-software-environments"
   :title "Stable software environments"
   :summary "Stable software environments provide the language, standards, and implementation continuity that let software remain usable across long spans of time."
   :references '("The Life Cycle of Collective Knowledge"
                 "Source-oriented and image-oriented development in Common Lisp"
                 "fedwiki:wiki.ralfbarkow.ch/the-life-cycle-of-collective-knowledge")))
