;; HYPERDOC_LOCALHOST_FEDWIKI_SOURCE_SNAPSHOT (:SNAPSHOT-KIND "localhost-fedwiki-page-source-snapshot" :SNAPSHOT-FORMAT-VERSION 1 :FINGERPRINT-ALGORITHM "fnv1a-64-over-normalized-raw-page-story-and-journal" :FINGERPRINT "fnv1a64:D3A4A5482E15414D" :SUMMARY "story-items=2; fragments=2; journal=5; last-journal=1762525244000" :SOURCE-PAGE-ID "fedwiki:wiki.ralfbarkow.ch/reproducible-devenv-as-knowledge-artifact" :SOURCE-PAGE-SLUG "reproducible-devenv-as-knowledge-artifact" :SOURCE-PAGE-PATH "pages/reproducible-devenv-as-knowledge-artifact" :SOURCE-PAGE-TITLE "Reproducible DevEnv as Knowledge Artifact" :STORY-ITEM-COUNT 2 :FRAGMENT-COUNT 2 :JOURNAL-ENTRY-COUNT 5 :JOURNAL-LAST-DATE 1762525244000 :PAGE-CREATE-DATE 1762525240000)

(:TOPIC-FACTORY-SNIPPET :ID
                        "reproducible-devenv-as-knowledge-artifact-topic-set" :SOURCE-FILE
                        "assets/reproducible-devenv-as-knowledge-artifact-topic.lisp"
                        :SOURCE-ORIGIN-ID
                        "fedwiki:wiki.ralfbarkow.ch/reproducible-devenv-as-knowledge-artifact"
                        :SOURCE-ORIGIN-PATH "pages/reproducible-devenv-as-knowledge-artifact"
                        :RELATED-HYPERDOC-PAGE-TITLE "Reproducible DevEnv as Knowledge Artifact"
                        :RELATED-TOPIC-ID "reproducible-devenv-as-knowledge-artifact"
                        :RELATED-TOPIC-IDS
                        ("reproducible-devenv-as-knowledge-artifact" "devenv-as-knowledge-artifact"
                                                                     "environment-topic-traceability")
                        :PROVENANCE
                        (:DERIVED-TOPIC-ID "reproducible-devenv-as-knowledge-artifact"
                                           :PROVENANCE-GRANULARITY "multi-item-derived" :PROVENANCE-CLASSIFICATION
                                           "story-item-id-and-journal" :SOURCE-PROVENANCE-CLASSIFICATIONS
                                           ("story-item-id-and-journal") :JOURNAL-ACTION-COUNT 4 :DERIVATION-NOTE
                                           "Dry-run-first DMX snippet twin for authored HyperDoc topic factories derived from two whole localhost FedWiki story items."
                                           :SOURCE-FRAGMENT-SELECTION-KIND "multi-item-fragments"
                                           :SOURCE-STORY-ITEM-SOURCE-IDS
                                           ("fedwiki:wiki.ralfbarkow.ch/reproducible-devenv-as-knowledge-artifact#story-item/fa0fe889c0e5bfc5"
                                            "fedwiki:wiki.ralfbarkow.ch/reproducible-devenv-as-knowledge-artifact#story-item/64855b381af02bb7")
                                           :SOURCE-STORY-ITEM-IDS ("fa0fe889c0e5bfc5" "64855b381af02bb7")
                                           :SOURCE-STORY-ITEM-INDEXES (0 1) :SOURCE-FRAGMENT-ORDINALS (0 0)
                                           :SOURCE-FRAGMENT-ANCHORS ("segment:0" "segment:0")
                                           :SOURCE-FRAGMENT-SECTION-KEYS ("intro" "intro") :SOURCE-FRAGMENT-EXCERPT
                                           "Treat each Nix flake or devShell as a DMX topic: it encapsulates dependencies, platform assumptions, and secrets just..."
                                           :SOURCE-FRAGMENT-EXCERPTS
                                           ("Treat each Nix flake or devShell as a DMX topic: it encapsulates dependencies, platform assumptions, and secrets just..."
                                            "Link these environment topics to projects, FedWiki pages, and Lepiter notebooks so you can query \"which path requires...")
                                           :SOURCE-KIND "localhost-fedwiki-story-item" :SOURCE-PAGE-ID
                                           "fedwiki:wiki.ralfbarkow.ch/reproducible-devenv-as-knowledge-artifact"
                                           :SOURCE-PAGE-SLUG "reproducible-devenv-as-knowledge-artifact"
                                           :SOURCE-PAGE-PATH "pages/reproducible-devenv-as-knowledge-artifact"
                                           :SOURCE-STORY-ITEM-ID "fa0fe889c0e5bfc5" :SOURCE-STORY-ITEM-INDEX 0
                                           :SOURCE-STORY-ITEM-TYPE "paragraph" :JOURNAL-ACTION-TYPES ("add" "edit")
                                           :JOURNAL-LAST-DATE 1762525242000 :PAGE-CREATE-DATE 1762525240000))

;; Topic-factory snippet bundle for Reproducible DevEnv as Knowledge Artifact.

(defun REPRODUCIBLE-DEVENV-AS-KNOWLEDGE-ARTIFACT-TOPIC ()
  (make-topic
   :id "reproducible-devenv-as-knowledge-artifact"
   :title "Reproducible DevEnv as Knowledge Artifact"
   :summary "Reproducible development environments become knowledge artifacts when they stay inspectable as first-class topics and remain linked to the work they support."
   :references '("Reproducible DevEnv as Knowledge Artifact"
                 "The Life Cycle of Collective Knowledge"
                 "fedwiki:wiki.ralfbarkow.ch/reproducible-devenv-as-knowledge-artifact")))

(defun DEVENV-AS-KNOWLEDGE-ARTIFACT-TOPIC ()
  (make-topic
   :id "devenv-as-knowledge-artifact"
   :title "Dev environment as knowledge artifact"
   :summary "A Nix flake or devShell can be treated as a knowledge artifact because it carries dependencies, platform assumptions, and other operational context as one inspectable unit."
   :references '("Reproducible DevEnv as Knowledge Artifact"
                 "The Life Cycle of Collective Knowledge"
                 "fedwiki:wiki.ralfbarkow.ch/reproducible-devenv-as-knowledge-artifact")))

(defun ENVIRONMENT-TOPIC-TRACEABILITY-TOPIC ()
  (make-topic
   :id "environment-topic-traceability"
   :title "Environment topic traceability"
   :summary "Linking environment topics to projects, FedWiki pages, and notebooks keeps shell requirements queryable across onboarding and maintenance work."
   :references '("Reproducible DevEnv as Knowledge Artifact"
                 "The Life Cycle of Collective Knowledge"
                 "fedwiki:wiki.ralfbarkow.ch/reproducible-devenv-as-knowledge-artifact")))
