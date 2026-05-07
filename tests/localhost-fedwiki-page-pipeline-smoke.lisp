;;;; Smoke tests for the generic localhost FedWiki page pipeline
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-LOCALHOST-FEDWIKI-PAGE-PIPELINE-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun synthetic-localhost-fedwiki-page-pipeline-fixture ()
  '(:title "Generic localhost FedWiki pipeline fixture"
    :story ((:id "fixture-paragraph"
             :type :paragraph
             :text "This fixture begins with an intro block that should split into a fragment.

Evidence
This evidence block stays in the same paragraph story item and should still be tracked as a fragment.

Claim
This claim block is a later fragment in the same paragraph story item.")
            (:id "fixture-quote"
             :type :quote
             :text "This whole quote item should stay whole when selected as a topic source."))
    :journal ((:type :create :date 1000)
              (:type :add :date 1001 :id "fixture-paragraph"
               :item (:id "fixture-paragraph"))
              (:type :edit :date 1002 :id "fixture-paragraph"
               :item (:id "fixture-paragraph"))
              (:type :add :date 1003 :id "fixture-quote"
               :item (:id "fixture-quote")))))

(defun synthetic-localhost-fedwiki-page-pipeline-spec ()
  (hyperdoc::make-localhost-fedwiki-page-pipeline-spec
   :id "generic-localhost-fedwiki-pipeline-fixture"
   :page-title "Generic localhost FedWiki pipeline fixture"
   :site "wiki.ralfbarkow.ch"
   :slug "generic-localhost-fedwiki-pipeline-fixture"
   :html-url
   "https://example.invalid/generic-localhost-fedwiki-pipeline-fixture"
   :page-reader #'synthetic-localhost-fedwiki-page-pipeline-fixture
   :source-chunk-id "generic-localhost-fedwiki-pipeline-fixture-source"
   :source-chunk-title "Generic localhost FedWiki pipeline fixture source"))

(defparameter *synthetic-localhost-fedwiki-page-topic-specs*
  '((:id "fixture-overview"
     :title "Fixture overview"
     :summary "A small multi-item topic assembled from one fragment and one whole story item."
     :topic-kind :umbrella
     :references ("fedwiki:wiki.ralfbarkow.ch/generic-localhost-fedwiki-pipeline-fixture")
     :fragment-selections ((:use-primary-item t :fragment-ordinals (1))
                           (:item-id "fixture-quote" :whole-item t))
     :derivation-note
     "Derived by grouping one paragraph fragment with one whole quote story item in the synthetic pipeline fixture.")
    (:id "fixture-fragment-topic"
     :title "Fixture fragment topic"
     :summary "A topic derived from two fragments inside one paragraph story item."
     :topic-kind :subtopic
     :references ("fedwiki:wiki.ralfbarkow.ch/generic-localhost-fedwiki-pipeline-fixture")
     :fragment-selections ((:use-primary-item t :fragment-ordinals (0 2))))
    (:id "fixture-whole-item-topic"
     :title "Fixture whole-item topic"
     :summary "A topic derived from one whole non-paragraph story item."
     :topic-kind :subtopic
     :references ("fedwiki:wiki.ralfbarkow.ch/generic-localhost-fedwiki-pipeline-fixture")
     :fragment-selections ((:item-id "fixture-quote" :whole-item t)))))

(defun synthetic-localhost-fedwiki-page-pipeline ()
  (hyperdoc::run-localhost-fedwiki-page-pipeline
   (synthetic-localhost-fedwiki-page-pipeline-spec)
   *synthetic-localhost-fedwiki-page-topic-specs*))

(defun run-localhost-fedwiki-page-pipeline-parse-smoke-test ()
  (let* ((pipeline (synthetic-localhost-fedwiki-page-pipeline))
         (source (hyperdoc::localhost-fedwiki-page-pipeline-result-source pipeline))
         (story-items (hyperdoc::localhost-fedwiki-source-data-story-items source))
         (primary-item (hyperdoc::localhost-fedwiki-page-pipeline-result-primary-item
                        pipeline))
         (first-fragment (first (hyperdoc::localhost-fedwiki-item-data-fragments
                                 primary-item)))
         (topic-chunks (hyperdoc::localhost-fedwiki-page-pipeline-result-topic-chunks
                        pipeline))
         (fragment-topic
          (find "fixture-fragment-topic"
                topic-chunks
                :key #'hyperdoc::localhost-fedwiki-promoted-topic-data-id
                :test #'equal))
         (whole-item-topic
          (find "fixture-whole-item-topic"
                topic-chunks
                :key #'hyperdoc::localhost-fedwiki-promoted-topic-data-id
                :test #'equal))
         (overview
          (hyperdoc::localhost-fedwiki-page-pipeline-result-umbrella-topic pipeline)))
    (assert-true (typep pipeline 'hyperdoc::localhost-fedwiki-page-pipeline-result)
                 "Synthetic fixture must run through the generic localhost FedWiki page pipeline")
    (assert-equal 2
                  (length story-items)
                  "Synthetic fixture must normalize two story items")
    (assert-equal "story-item"
                  (getf (hyperdoc::localhost-fedwiki-item-data-provenance primary-item)
                        :provenance-granularity)
                  "Normalized story items must keep story-item provenance")
    (assert-equal "story-item-fragment"
                  (getf (hyperdoc::localhost-fedwiki-fragment-data-provenance first-fragment)
                        :provenance-granularity)
                  "Normalized fragments must keep story-item-fragment provenance")
    (assert-equal "story-item-fragment"
                  (getf (hyperdoc::localhost-fedwiki-promoted-topic-data-provenance
                         fragment-topic)
                        :provenance-granularity)
                  "Generic pipeline must preserve fragment-derived topic provenance")
    (assert-equal '(0 2)
                  (getf (hyperdoc::localhost-fedwiki-promoted-topic-data-provenance
                         fragment-topic)
                        :source-fragment-ordinals)
                  "Fragment-derived topics must preserve fragment ordinals")
    (assert-equal "story-item"
                  (getf (hyperdoc::localhost-fedwiki-promoted-topic-data-provenance
                         whole-item-topic)
                        :provenance-granularity)
                  "Whole-item-derived topics must stay distinguishable from fragment-derived topics")
    (assert-equal "This whole quote item should stay whole when selected as a topic source."
                  (hyperdoc::localhost-fedwiki-promoted-topic-data-body whole-item-topic)
                  "Whole-item topic body must preserve the whole source item text")
    (assert-equal "multi-item-derived"
                  (getf (hyperdoc::localhost-fedwiki-promoted-topic-data-provenance
                         overview)
                        :provenance-granularity)
                  "Cross-item topics must be classified as multi-item-derived")
    (assert-equal '(0 1)
                  (getf (hyperdoc::localhost-fedwiki-promoted-topic-data-provenance
                         overview)
                        :source-story-item-indexes)
                  "Multi-item topics must preserve both contributing story item indexes")))

(defun run-localhost-fedwiki-page-pipeline-render-smoke-test ()
  (let* ((pipeline (synthetic-localhost-fedwiki-page-pipeline))
         (topic-entries
          (loop for topic in (hyperdoc::localhost-fedwiki-page-pipeline-result-topic-chunks
                              pipeline)
                collect (list :title (hyperdoc::localhost-fedwiki-promoted-topic-data-title
                                      topic)
                              :summary
                              (hyperdoc::localhost-fedwiki-promoted-topic-data-summary
                               topic))))
         (rendered
          (hyperdoc::render-hyperdoc-page-shell
           "Generic localhost FedWiki pipeline fixture"
           (list "<p>This synthetic page proves the generic localhost FedWiki page pipeline without promoting a second durable HyperDoc page.</p>")
           (list
            (list :title "Reusable topic chunks"
                  :body-html (hyperdoc::render-topic-list-html topic-entries)))))
         (metadata
          (hyperdoc::make-localhost-fedwiki-topic-factory-metadata-from-pipeline
           pipeline
           :id "fixture-fragment-topic-set"
           :source-file "assets/fixture-fragment-topic-set.lisp"
           :related-hyperdoc-page-title
           "Generic localhost FedWiki pipeline fixture"
           :related-topic-id "fixture-fragment-topic"
           :fragment-selections
           '((:use-primary-item t :fragment-ordinals (0 2)))
           :note
           "Synthetic fragment-scoped metadata for the generic localhost FedWiki page pipeline smoke test."))
         (provenance (getf metadata :provenance)))
    (assert-true (search "<h1>Generic localhost FedWiki pipeline fixture</h1>"
                         rendered)
                 "Generic page shell must render a page title")
    (assert-true (search "Fixture whole-item topic" rendered)
                 "Generic page shell must render topic entries")
    (assert-equal "pages/generic-localhost-fedwiki-pipeline-fixture"
                  (getf metadata :source-origin-path)
                  "Generic topic-factory metadata must preserve canonical repo-relative FedWiki paths")
    (assert-equal "story-item-fragment"
                  (getf provenance :provenance-granularity)
                  "Generic fragment-scoped metadata must preserve fragment provenance granularity")
    (assert-equal '(0 2)
                  (getf provenance :source-fragment-ordinals)
                  "Generic fragment-scoped metadata must preserve fragment ordinals")
    (assert-true (not (search "/Users/" (prin1-to-string metadata)))
                 "Generic fragment-scoped metadata must not contain machine-local absolute paths")))

(defun run-localhost-fedwiki-page-pipeline-smoke-tests ()
  (run-localhost-fedwiki-page-pipeline-parse-smoke-test)
  (run-localhost-fedwiki-page-pipeline-render-smoke-test)
  (format t "~&Localhost FedWiki page pipeline smoke tests passed.~%")
  t)
