;;;; Smoke tests for The Life Cycle of Collective Knowledge slice
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-COLLECTIVE-KNOWLEDGE-SLICE-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun collective-knowledge-relative-path (relative-path)
  (asdf:system-relative-pathname :hyperdoc relative-path))

(defun run-collective-knowledge-chunk-parse-smoke-test ()
  (let* ((parsed (hyperdoc::parse-the-life-cycle-of-collective-knowledge-chunks))
         (pipeline (hyperdoc::the-life-cycle-of-collective-knowledge-page-pipeline))
         (source (getf parsed :source-fedwiki-page))
         (definition (getf parsed :topic-definition))
         (umbrella (getf parsed :umbrella-topic))
         (subtopics (getf parsed :subtopics))
         (page (getf parsed :topic-page))
         (dmx (getf parsed :dmx-snippet))
         (first-item (first (hyperdoc::story-items-of source)))
         (second-item (second (hyperdoc::story-items-of source)))
         (first-fragment (first (hyperdoc::fragments-of first-item)))
         (definition-provenance (hyperdoc::provenance-of definition))
         (first-provenance (hyperdoc::provenance-of (first subtopics))))
    (assert-true
     (typep pipeline 'hyperdoc::localhost-fedwiki-page-pipeline-result)
     "Collective knowledge must now run through the generic localhost FedWiki page pipeline")
    (assert-equal
     "the-life-cycle-of-collective-knowledge"
     (hyperdoc::localhost-fedwiki-page-pipeline-spec-id
      (hyperdoc::localhost-fedwiki-page-pipeline-result-spec pipeline))
     "Collective knowledge must configure the generic pipeline through a page-specific spec")
    (assert-true (typep source 'hyperdoc::localhost-fedwiki-source-chunk)
                 "Source parse must read the localhost FedWiki page into a source chunk")
    (assert-equal "pages/the-life-cycle-of-collective-knowledge"
                  (hyperdoc::source-path-of source)
                  "Source chunk must keep the repo-relative localhost FedWiki page path")
    (assert-equal 2
                  (length (hyperdoc::story-items-of source))
                  "Source parse must preserve the real localhost FedWiki story item structure")
    (assert-equal "paragraph"
                  (hyperdoc::item-type-of first-item)
                  "First normalized story item type")
    (assert-equal "assets"
                  (hyperdoc::item-type-of second-item)
                  "Second normalized story item type")
    (assert-equal "story-item"
                  (getf (hyperdoc::provenance-of first-item) :provenance-granularity)
                  "Whole normalized story items must keep story-item provenance granularity")
    (assert-true (typep first-fragment 'hyperdoc::localhost-fedwiki-fragment-record)
                 "Paragraph story items must expose normalized fragment records")
    (assert-equal "story-item-fragment"
                  (getf (hyperdoc::provenance-of first-fragment) :provenance-granularity)
                  "Normalized fragments must keep story-item-fragment provenance granularity")
    (assert-equal "segment:0"
                  (hyperdoc::fragment-anchor-of first-fragment)
                  "Normalized fragments must expose stable fragment anchors")
    (assert-equal "intro"
                  (hyperdoc::section-key-of first-fragment)
                  "Normalized fragments must expose section keys")
    (assert-true (typep definition 'hyperdoc::topic-definition-chunk)
                 "Topic asset must parse into a topic-definition chunk")
    (assert-true (typep umbrella 'hyperdoc::subtopic-chunk)
                 "Umbrella topic must parse into a topic-shaped chunk")
    (assert-equal 6 (length subtopics)
                  "FedWiki-derived source must yield the six requested reusable subtopics")
    (assert-equal "collective-knowledge"
                  (hyperbook:id-of (first subtopics))
                  "First derived subtopic id")
    (assert-equal "The Life Cycle of Collective Knowledge"
                  (hyperbook:title-of umbrella)
                  "Umbrella topic title")
    (assert-equal "the-life-cycle-of-collective-knowledge"
                  (getf first-provenance :source-page-slug)
                  "Derived topic chunks must preserve FedWiki page provenance")
    (assert-true
     (or (getf first-provenance :source-story-item-id)
         (integerp (getf first-provenance :source-story-item-index)))
     "Derived topic chunks must preserve item identity or item index provenance")
    (assert-true (plusp (getf first-provenance :journal-action-count))
                 "Derived topic chunks must preserve journal provenance when available")
    (assert-true (string= "story-item-id-and-journal"
                          (getf first-provenance :provenance-classification))
                 "Derived topic chunks must classify provenance completeness")
    (assert-equal "story-item-fragment"
                  (getf first-provenance :provenance-granularity)
                  "Derived topic chunks must classify fragment-level provenance explicitly")
    (assert-equal '(0 3 6)
                  (getf first-provenance :source-fragment-ordinals)
                  "Derived topic chunks must preserve fragment ordinals inside the source story item")
    (assert-equal '("segment:0" "segment:3" "segment:6")
                  (getf first-provenance :source-fragment-anchors)
                  "Derived topic chunks must preserve fragment anchors")
    (assert-true (search "paragraph fragments within one localhost FedWiki story item"
                         (getf first-provenance :derivation-note))
                 "Derived topic chunks must describe the fragment split rule")
    (assert-equal "fedwiki:wiki.ralfbarkow.ch/the-life-cycle-of-collective-knowledge"
                  (hyperdoc::source-origin-id-of definition)
                  "Topic definition must point back to the canonical FedWiki page id")
    (assert-equal "assets/the-life-cycle-of-collective-knowledge-topic.lisp"
                  (hyperdoc::source-path-of definition)
                  "Topic definition must keep repo-relative snippet source paths")
    (assert-equal "story-item-fragment"
                  (getf definition-provenance :provenance-granularity)
                  "Topic-definition metadata must preserve fragment-based provenance granularity")
    (assert-true (search "hyperdoc:topic-factory-snippet/the-life-cycle-of-collective-knowledge-topic-set"
                         (hyperdoc::snippet-uri-of dmx))
                 "DMX snippet chunk must keep the stable snippet URI")
    (assert-equal "hyperdoc/The Life Cycle of Collective Knowledge.html"
                  (hyperdoc::page-path-of page)
                  "Page chunk must point at the authored HyperDoc page path")))

(defun run-collective-knowledge-render-smoke-test ()
  (let ((expected-page (uiop:read-file-string
                        (collective-knowledge-relative-path
                         "hyperdoc/The Life Cycle of Collective Knowledge.html")))
        (expected-topic-snippet (uiop:read-file-string
                                 (collective-knowledge-relative-path
                                  "assets/the-life-cycle-of-collective-knowledge-topic.lisp")))
        (source
          (hyperdoc::the-life-cycle-of-collective-knowledge-localhost-fedwiki-source-chunk))
        (rendered-page
          (hyperdoc::render-the-life-cycle-of-collective-knowledge-page))
        (rendered-topic-snippet
          (hyperdoc::render-the-life-cycle-of-collective-knowledge-topic-factory-snippet)))
    (assert-true
     (search "preserve fragment-level provenance within that item instead of claiming"
             rendered-page)
     "Rendered page wording must state fragment-level provenance instead of overclaiming item-level provenance")
    (assert-true
     (search "fragment-level rather than whole-item-level" rendered-page)
     "Rendered page must explicitly distinguish fragment-level derivation from whole-item provenance")
    (assert-true
     (hyperdoc::localhost-fedwiki-page-artifact-reflected-source-snapshot
      expected-page)
     "Committed page artifact must embed a source snapshot comment")
    (assert-true
     (hyperdoc::localhost-fedwiki-topic-snippet-artifact-reflected-source-snapshot
      expected-topic-snippet)
     "Committed topic snippet must embed a source snapshot comment")
    (multiple-value-bind (page-first-line page-body)
        (hyperdoc::split-string-first-line expected-page)
      (assert-true
       (hyperdoc::string-prefix-p*
        hyperdoc::+localhost-fedwiki-page-source-snapshot-page-prefix+
        page-first-line)
       "Committed page artifact must keep the source snapshot in an inert HTML comment")
      (assert-true
       (search "<h1>The Life Cycle of Collective Knowledge</h1>"
               page-body
               :test #'char=)
       "Committed page artifact body must still start with rendered HTML content after the inert comment")
      (assert-true
       (not (search hyperdoc::+localhost-fedwiki-page-source-snapshot-envelope-tag+
                    page-body
                    :test #'char=))
       "Committed page artifact must not leak the snapshot tag into visible page body content"))
    (multiple-value-bind (snippet-first-line snippet-rest)
        (hyperdoc::split-string-first-line expected-topic-snippet)
      (declare (ignore snippet-rest))
      (assert-true
       (hyperdoc::string-prefix-p*
        hyperdoc::+localhost-fedwiki-page-source-snapshot-snippet-prefix+
        snippet-first-line)
       "Committed topic snippet must keep the source snapshot in a reader-safe Lisp comment")
      (assert-equal
       :topic-factory-snippet
       (with-input-from-string (stream expected-topic-snippet)
         (let ((*read-eval* nil))
           (first (read stream nil :eof))))
       "Committed topic snippet must remain reader-safe because the envelope comment is skipped before the snippet form")
      (let* ((temp-path
               (merge-pathnames
                (format nil "hyperdoc-snippet-envelope-load-smoke-~D.lisp"
                        (get-universal-time))
                (uiop:temporary-directory))))
        (unwind-protect
             (progn
               (setf (symbol-value 'cl-user::*hyperdoc-snippet-envelope-load-smoke*)
                     :unset)
               (with-open-file (stream temp-path
                                       :direction :output
                                       :if-exists :supersede
                                       :if-does-not-exist :create
                                       :external-format :utf-8)
                 (write-line snippet-first-line stream)
                 (write-line "(in-package :cl-user)" stream)
                 (write-line "(defparameter *hyperdoc-snippet-envelope-load-smoke* :loaded)" stream))
               (load temp-path)
               (assert-equal
                :loaded
                (symbol-value 'cl-user::*hyperdoc-snippet-envelope-load-smoke*)
                "The Lisp snapshot envelope comment must stay load-safe when it prefixes a loadable file"))
          (when (uiop:file-exists-p temp-path)
            (delete-file temp-path)))))
    (let ((page-reflection
            (hyperdoc::localhost-fedwiki-page-artifact-reflected-source-snapshot-reflection
             expected-page))
          (snippet-reflection
            (hyperdoc::localhost-fedwiki-topic-snippet-artifact-reflected-source-snapshot-reflection
             expected-topic-snippet)))
      (assert-equal
       :present
       (hyperdoc::localhost-fedwiki-source-snapshot-envelope-reflection-status
        page-reflection)
       "Committed page artifact must reflect a valid source snapshot envelope")
      (assert-equal
       :present
       (hyperdoc::localhost-fedwiki-source-snapshot-envelope-reflection-status
        snippet-reflection)
       "Committed topic snippet must reflect a valid source snapshot envelope")
      (assert-true
       (null
        (hyperdoc::localhost-fedwiki-source-snapshot-envelope-reflection-error-message
         page-reflection))
       "Valid page envelopes must not report parse errors")
      (assert-true
       (null
        (hyperdoc::localhost-fedwiki-source-snapshot-envelope-reflection-error-message
         snippet-reflection))
       "Valid snippet envelopes must not report parse errors"))
    (assert-equal
     expected-page
     (hyperdoc::render-localhost-fedwiki-page-artifact-with-source-snapshot
      rendered-page
      source)
     "Committed HyperDoc page must stay in sync with the rendered page plus the source snapshot envelope")
    (assert-equal
     expected-topic-snippet
     (hyperdoc::render-localhost-fedwiki-topic-snippet-artifact-with-source-snapshot
      rendered-topic-snippet
      source)
     "Committed topic-factory snippet must stay in sync with the rendered snippet plus the source snapshot envelope")))

(defun run-collective-knowledge-generated-output-idempotence-smoke-test ()
  (let ((page-path
          (collective-knowledge-relative-path
           "hyperdoc/The Life Cycle of Collective Knowledge.html"))
        (snippet-path
          (collective-knowledge-relative-path
           "assets/the-life-cycle-of-collective-knowledge-topic.lisp")))
    (hyperdoc::write-the-life-cycle-of-collective-knowledge-artifacts)
    (let ((first-page (uiop:read-file-string page-path))
          (first-snippet (uiop:read-file-string snippet-path)))
      (hyperdoc::write-the-life-cycle-of-collective-knowledge-artifacts)
      (assert-equal first-page
                    (uiop:read-file-string page-path)
                    "Repeated page generation must be idempotent")
      (assert-equal first-snippet
                    (uiop:read-file-string snippet-path)
                    "Repeated topic snippet generation must be idempotent"))))

(defun run-collective-knowledge-topic-presence-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (dolist (entry '((hyperdoc::the-life-cycle-of-collective-knowledge-topic
                    "The Life Cycle of Collective Knowledge")
                   (hyperdoc::collective-knowledge-topic
                    "Collective knowledge")
                   (hyperdoc::refinement-of-information-into-knowledge-topic
                    "Refinement of information into knowledge")
                   (hyperdoc::digital-fragility-of-software-source-code-topic
                    "Digital fragility of software source code")
                   (hyperdoc::computational-reproducibility-is-not-enough-topic
                    "Computational reproducibility is not enough")
                   (hyperdoc::software-interoperability-across-time-topic
                    "Software interoperability across time")
                   (hyperdoc::stable-software-environments-topic
                    "Stable software environments")))
    (destructuring-bind (symbol title) entry
      (assert-true (fboundp symbol)
                   (format nil "Missing topic function ~A" symbol))
      (assert-true (hyperbook:find-page hyperdoc::*topics* title :signal-error? t)
                   (format nil "Missing Topics HyperBook page ~A" title))))
  (assert-true (hyperbook:find-page hyperdoc::*hyperdoc*
                                    "The Life Cycle of Collective Knowledge"
                                    :signal-error? t)
               "The composed HyperDoc page must be browseable"))

(defun run-collective-knowledge-slice-smoke-tests ()
  (run-collective-knowledge-chunk-parse-smoke-test)
  (run-collective-knowledge-render-smoke-test)
  (run-collective-knowledge-generated-output-idempotence-smoke-test)
  (run-collective-knowledge-topic-presence-smoke-test)
  (format t "~&Collective knowledge slice smoke tests passed.~%")
  t)
