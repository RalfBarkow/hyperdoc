;;;; Smoke tests for Reproducible DevEnv as Knowledge Artifact slice
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-REPRODUCIBLE-DEVENV-AS-KNOWLEDGE-ARTIFACT-SLICE-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defparameter *reproducible-devenv-topic-factory-snippet-dmx-workspace-topicmap-id*
  919822)

(defun reproducible-devenv-relative-path (relative-path)
  (asdf:system-relative-pathname :hyperdoc relative-path))

(defun run-reproducible-devenv-as-knowledge-artifact-chunk-parse-smoke-test ()
  (let* ((parsed
           (hyperdoc::parse-reproducible-devenv-as-knowledge-artifact-chunks))
         (pipeline
           (hyperdoc::reproducible-devenv-as-knowledge-artifact-page-pipeline))
         (source (getf parsed :source-fedwiki-page))
         (definition (getf parsed :topic-definition))
         (umbrella (getf parsed :umbrella-topic))
         (subtopics (getf parsed :subtopics))
         (page (getf parsed :topic-page))
         (dmx (getf parsed :dmx-snippet))
         (first-item (first (hyperdoc::story-items-of source)))
         (second-item (second (hyperdoc::story-items-of source)))
         (first-fragment (first (hyperdoc::fragments-of first-item)))
         (first-subtopic (first subtopics))
         (second-subtopic (second subtopics))
         (umbrella-provenance (hyperdoc::provenance-of umbrella))
         (first-provenance (hyperdoc::provenance-of first-subtopic))
         (second-provenance (hyperdoc::provenance-of second-subtopic))
         (definition-provenance (hyperdoc::provenance-of definition)))
    (assert-true
     (typep pipeline 'hyperdoc::localhost-fedwiki-page-pipeline-result)
     "Second real page must run through the generic localhost FedWiki page pipeline")
    (assert-equal
     "reproducible-devenv-as-knowledge-artifact"
     (hyperdoc::localhost-fedwiki-page-pipeline-spec-id
      (hyperdoc::localhost-fedwiki-page-pipeline-result-spec pipeline))
     "Second real page must configure the generic pipeline through a page-specific spec")
    (assert-true (typep source 'hyperdoc::localhost-fedwiki-source-chunk)
                 "Source parse must return a localhost FedWiki source chunk")
    (assert-equal "pages/reproducible-devenv-as-knowledge-artifact"
                  (hyperdoc::source-path-of source)
                  "Second real page must preserve repo-relative FedWiki provenance")
    (assert-equal 2
                  (length (hyperdoc::story-items-of source))
                  "Second real page must preserve its two paragraph story items")
    (assert-equal "paragraph"
                  (hyperdoc::item-type-of first-item)
                  "First normalized story item type")
    (assert-equal "paragraph"
                  (hyperdoc::item-type-of second-item)
                  "Second normalized story item type")
    (assert-equal "story-item"
                  (getf (hyperdoc::provenance-of first-item)
                        :provenance-granularity)
                  "Whole normalized story items must keep story-item provenance granularity")
    (assert-equal "story-item-fragment"
                  (getf (hyperdoc::provenance-of first-fragment)
                        :provenance-granularity)
                  "Normalized paragraph fragments must remain available after the refactor")
    (assert-equal "story-item"
                  (getf first-provenance :provenance-granularity)
                  "First promoted subtopic must be whole-item-derived")
    (assert-equal "story-item"
                  (getf second-provenance :provenance-granularity)
                  "Second promoted subtopic must be whole-item-derived")
    (assert-equal "multi-item-derived"
                  (getf umbrella-provenance :provenance-granularity)
                  "Umbrella topic must explicitly record multi-item-derived provenance")
    (assert-equal "fa0fe889c0e5bfc5"
                  (getf first-provenance :source-story-item-id)
                  "First promoted subtopic must keep its source story item id")
    (assert-equal 1
                  (getf second-provenance :source-story-item-index)
                  "Second promoted subtopic must keep its source story item index")
    (assert-equal '(0 1)
                  (getf umbrella-provenance :source-story-item-indexes)
                  "Umbrella topic must preserve both source story item indexes")
    (assert-true
     (search "two whole localhost FedWiki story items"
             (getf umbrella-provenance :derivation-note))
     "Umbrella topic must describe the multi-item derivation rule")
    (assert-equal "assets/reproducible-devenv-as-knowledge-artifact-topic.lisp"
                  (hyperdoc::source-path-of definition)
                  "Topic definition must keep repo-relative snippet source paths")
    (assert-equal "multi-item-derived"
                  (getf definition-provenance :provenance-granularity)
                  "Topic-definition metadata must keep multi-item-derived provenance")
    (assert-true
     (search "hyperdoc:topic-factory-snippet/reproducible-devenv-as-knowledge-artifact-topic-set"
             (hyperdoc::snippet-uri-of dmx))
     "DMX snippet chunk must keep the stable snippet URI")
    (assert-equal "hyperdoc/Reproducible DevEnv as Knowledge Artifact.html"
                  (hyperdoc::page-path-of page)
                  "Page chunk must point at the authored HyperDoc page path")))

(defun run-reproducible-devenv-as-knowledge-artifact-render-smoke-test ()
  (let ((expected-page
          (uiop:read-file-string
           (reproducible-devenv-relative-path
            "hyperdoc/Reproducible DevEnv as Knowledge Artifact.html")))
        (expected-topic-snippet
          (uiop:read-file-string
           (reproducible-devenv-relative-path
            "assets/reproducible-devenv-as-knowledge-artifact-topic.lisp")))
        (rendered-page
          (hyperdoc::render-reproducible-devenv-as-knowledge-artifact-page))
        (rendered-topic-snippet
          (hyperdoc::render-reproducible-devenv-as-knowledge-artifact-topic-factory-snippet)))
    (assert-true
     (search "<tt>story-item</tt> provenance" rendered-page)
     "Rendered page wording must state whole-item provenance for the individual subtopics")
    (assert-true
     (search "<tt>multi-item-derived</tt> provenance" rendered-page)
     "Rendered page wording must state multi-item-derived provenance for the umbrella topic")
    (assert-equal expected-page
                  rendered-page
                  "Rendered HyperDoc page must stay in sync with the committed page")
    (assert-equal expected-topic-snippet
                  rendered-topic-snippet
                  "Rendered topic-factory snippet must stay in sync with the committed asset")))

(defun run-reproducible-devenv-as-knowledge-artifact-generated-output-idempotence-smoke-test ()
  (let ((page-path
          (reproducible-devenv-relative-path
           "hyperdoc/Reproducible DevEnv as Knowledge Artifact.html"))
        (snippet-path
          (reproducible-devenv-relative-path
           "assets/reproducible-devenv-as-knowledge-artifact-topic.lisp")))
    (hyperdoc::write-reproducible-devenv-as-knowledge-artifact-artifacts)
    (let ((first-page (uiop:read-file-string page-path))
          (first-snippet (uiop:read-file-string snippet-path)))
      (hyperdoc::write-reproducible-devenv-as-knowledge-artifact-artifacts)
      (assert-equal first-page
                    (uiop:read-file-string page-path)
                    "Repeated page generation must be idempotent")
      (assert-equal first-snippet
                    (uiop:read-file-string snippet-path)
                    "Repeated topic snippet generation must be idempotent"))))

(defun run-reproducible-devenv-as-knowledge-artifact-topic-presence-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (dolist (entry '((hyperdoc::reproducible-devenv-as-knowledge-artifact-topic
                    "Reproducible DevEnv as Knowledge Artifact")
                   (hyperdoc::devenv-as-knowledge-artifact-topic
                    "Dev environment as knowledge artifact")
                   (hyperdoc::environment-topic-traceability-topic
                    "Environment topic traceability")))
    (destructuring-bind (symbol title) entry
      (assert-true (fboundp symbol)
                   (format nil "Missing topic function ~A" symbol))
      (assert-true (hyperbook:find-page hyperdoc::*topics* title :signal-error? t)
                   (format nil "Missing Topics HyperBook page ~A" title))))
  (assert-true
   (hyperbook:find-page hyperdoc::*hyperdoc*
                        "Reproducible DevEnv as Knowledge Artifact"
                        :signal-error? t)
   "The composed HyperDoc page must be browseable"))

(defun run-reproducible-devenv-as-knowledge-artifact-dmx-smoke-test ()
  (let* ((definition
           (hyperdoc::reproducible-devenv-as-knowledge-artifact-topic-definition-chunk))
         (client (make-instance 'hyperdoc::memory-dmx-import-client
                                :next-topic-id 7100))
         (plan
           (hyperdoc::plan-topic-factory-snippet-dmx-write
            definition
            :workspace-topicmap-id
            *reproducible-devenv-topic-factory-snippet-dmx-workspace-topicmap-id*
            :client client))
         (payload (hyperdoc::topic-factory-snippet-dmx-write-plan-payload plan))
         (children (getf payload :children))
         (provenance-json
           (gethash hyperdoc::*dmx-topic-factory-snippet-provenance-type-uri*
                    children))
         (provenance-object (shasht:read-json provenance-json))
         (story-item-indexes
           (sort (coerce (gethash "source_story_item_indexes" provenance-object)
                         'list)
                 #'<))
         (output
           (with-output-to-string (stream)
             (hyperdoc::execute-topic-factory-snippet-dmx-write
              definition
              :workspace-topicmap-id
              *reproducible-devenv-topic-factory-snippet-dmx-workspace-topicmap-id*
              :client client
              :dry-run t
              :stream stream))))
    (assert-equal :create
                  (hyperdoc::topic-factory-snippet-dmx-write-plan-topic-action plan)
                  "Fresh second-page snippet plan must start with CREATE")
    (assert-equal "hyperdoc:topic-factory-snippet/reproducible-devenv-as-knowledge-artifact-topic-set"
                  (hyperdoc::topic-factory-snippet-dmx-write-plan-uri plan)
                  "Second-page snippet plan must keep the stable snippet URI")
    (assert-equal "assets/reproducible-devenv-as-knowledge-artifact-topic.lisp"
                  (gethash hyperdoc::*dmx-topic-factory-snippet-source-file-type-uri*
                           children)
                  "Second-page snippet payload must use the repo-relative snippet source path")
    (assert-true
     (search "fedwiki:wiki.ralfbarkow.ch/reproducible-devenv-as-knowledge-artifact"
             provenance-json)
     "Second-page snippet provenance must preserve the canonical FedWiki page id")
    (assert-true
     (search "pages/reproducible-devenv-as-knowledge-artifact"
             provenance-json)
     "Second-page snippet provenance must preserve the repo-relative FedWiki page path")
    (assert-equal "multi-item-derived"
                  (gethash "provenance_granularity" provenance-object)
                  "Second-page snippet provenance JSON must preserve multi-item-derived granularity")
    (assert-equal '(0 1)
                  story-item-indexes
                  "Second-page snippet provenance JSON must preserve both whole-item indexes")
    (assert-true
     (not (search "/Users/" provenance-json))
     "Second-page snippet provenance must not preserve machine-local absolute paths")
    (assert-true (search "topic-action=CREATE" output)
                 "Second-page dry-run output must expose CREATE")
    (assert-true
     (search "source=assets/reproducible-devenv-as-knowledge-artifact-topic.lisp"
             output)
     "Second-page dry-run output must expose the canonical repo-relative snippet path")))

(defun run-reproducible-devenv-as-knowledge-artifact-slice-smoke-tests ()
  (run-reproducible-devenv-as-knowledge-artifact-chunk-parse-smoke-test)
  (run-reproducible-devenv-as-knowledge-artifact-render-smoke-test)
  (run-reproducible-devenv-as-knowledge-artifact-generated-output-idempotence-smoke-test)
  (run-reproducible-devenv-as-knowledge-artifact-topic-presence-smoke-test)
  (run-reproducible-devenv-as-knowledge-artifact-dmx-smoke-test)
  (format t "~&Reproducible DevEnv as Knowledge Artifact slice smoke tests passed.~%")
  t)
