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
         (source (getf parsed :source-asset))
         (definition (getf parsed :topic-definition))
         (umbrella (getf parsed :umbrella-topic))
         (subtopics (getf parsed :subtopics))
         (page (getf parsed :topic-page))
         (dmx (getf parsed :dmx-snippet)))
    (assert-true (typep source 'hyperdoc::source-asset-chunk)
                 "Source asset must parse into a source-asset chunk")
    (assert-true (typep definition 'hyperdoc::topic-definition-chunk)
                 "Topic asset must parse into a topic-definition chunk")
    (assert-true (typep umbrella 'hyperdoc::subtopic-chunk)
                 "Umbrella topic must parse into a topic-shaped chunk")
    (assert-equal 6 (length subtopics)
                  "Source asset must yield the six requested reusable subtopics")
    (assert-equal "collective-knowledge"
                  (hyperbook:id-of (first subtopics))
                  "First derived subtopic id")
    (assert-equal "The Life Cycle of Collective Knowledge"
                  (hyperbook:title-of umbrella)
                  "Umbrella topic title")
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
        (rendered-page
          (hyperdoc::render-the-life-cycle-of-collective-knowledge-page))
        (rendered-topic-snippet
          (hyperdoc::render-the-life-cycle-of-collective-knowledge-topic-factory-snippet)))
    (assert-equal expected-page
                  rendered-page
                  "Rendered HyperDoc page must stay in sync with the committed page")
    (assert-equal expected-topic-snippet
                  rendered-topic-snippet
                  "Rendered topic-factory snippet must stay in sync with the committed asset")))

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
  (run-collective-knowledge-topic-presence-smoke-test)
  (format t "~&Collective knowledge slice smoke tests passed.~%")
  t)
