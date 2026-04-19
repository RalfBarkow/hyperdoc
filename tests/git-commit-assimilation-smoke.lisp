;;;; Smoke tests for upstream commit assimilation checks
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-GIT-COMMIT-ASSIMILATION-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun assimilation-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun assimilation-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun assimilation-assert-typep (expected-type object message)
  (unless (typep object expected-type)
    (error "~A -- expected type: ~S actual type: ~S"
           message
           expected-type
           (type-of object))))

(defun assimilation-find-view-by-title (views title)
  (find title
        views
        :key #'html-inspector-views:view-title
        :test #'string=))

(defun assimilation-load-inspector-views-for-object (object)
  (let ((pane (make-instance 'clog-moldable-inspector::pane
                             :inspector nil
                             :object object)))
    (clog-moldable-inspector::load-views pane)
    (slot-value pane 'clog-moldable-inspector::views)))

(defun sorted-copy-of-strings (strings)
  (sort (copy-seq strings) #'string<))

(defun run-upstream-commit-assimilation-classification-smoke-test ()
  (assimilation-assert-equal
   :already-assimilated
   (hyperdoc::classify-upstream-commit-assimilation-decision
    :patch-equivalent-p t
    :semantic-effect-status :present
    :semantic-compatibility-status :compatible
    :validation-status :passed)
   "Patch-equivalent content with present effect and passing validation must classify as already assimilated")
  (assimilation-assert-equal
   :already-assimilated
   (hyperdoc::classify-upstream-commit-assimilation-decision
    :superseding-local-commit t
    :semantic-effect-status :present
    :semantic-compatibility-status :compatible
    :validation-status :passed)
   "A proven superseding local commit with present effect and passing validation must classify as already assimilated")
  (assimilation-assert-equal
   :needs-cherry-pick
   (hyperdoc::classify-upstream-commit-assimilation-decision
    :semantic-effect-status :absent
    :semantic-compatibility-status :compatible
    :validation-status :passed)
   "Absent effect plus compatible payload and passing validation must classify as needs-cherry-pick")
  (assimilation-assert-equal
   :needs-manual-assimilation
   (hyperdoc::classify-upstream-commit-assimilation-decision
    :semantic-effect-status :absent
    :semantic-compatibility-status :diverged
    :validation-status :failed)
   "Absent effect plus diverged compatibility must classify as manual assimilation")
  (assimilation-assert-equal
   :inconclusive
   (hyperdoc::classify-upstream-commit-assimilation-decision
    :patch-equivalent-p t
    :semantic-effect-status :unknown
    :semantic-compatibility-status :unknown
   :validation-status :unknown)
   "Missing semantic and validation evidence must remain inconclusive"))

(defun run-upstream-commit-assimilation-page-evidence-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((resolved
           (hyperdoc::safe-assimilation-page-evidence
            hyperdoc::*hyperdoc*
            "Static route observability"))
         (missing
           (hyperdoc::safe-assimilation-page-evidence
            hyperdoc::*topics*
            "Assimilation lookup issue smoke missing page"))
         (unavailable
           (hyperdoc::safe-assimilation-page-evidence
            nil
            "Assimilation unavailable corpus page")))
    (assimilation-assert-equal
     :resolved
     (getf resolved :status)
     "A resolvable assimilation corpus page must surface as :resolved")
    (assimilation-assert-true
     (equal "Static route observability"
            (hyperbook:title-of (getf resolved :page)))
     "Resolved assimilation corpus evidence must preserve the page object")
    (assimilation-assert-equal
     :lookup-issue
     (getf missing :status)
     "A missing assimilation corpus page must surface as :lookup-issue")
    (assimilation-assert-true
     (typep (getf missing :issue) 'hyperbook:page-lookup-issue)
     "A missing assimilation corpus page must preserve a bounded page-lookup-issue")
    (assimilation-assert-equal
     :unavailable
     (getf unavailable :status)
     "A missing corpus lookup path must surface as :unavailable")))

(defun run-upstream-commit-assimilation-worked-example-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((check
           (hyperdoc::hyperdoc-static-route-observability-commit-assimilation-check))
         (graphviz-check
           (hyperdoc::hyperdoc-graphviz-story-item-commit-assimilation-check))
         (graphviz-example
           (hyperdoc::graphviz-story-item-upstream-assimilation-example))
         (surface
           (hyperdoc::hyperdoc-upstream-commit-assimilation-surface))
         (check-views
           (assimilation-load-inspector-views-for-object check))
         (graphviz-check-views
           (assimilation-load-inspector-views-for-object graphviz-check))
         (surface-views
           (assimilation-load-inspector-views-for-object surface))
         (payload-paths
           (sorted-copy-of-strings
            (hyperdoc::payload-paths-of check)))
         (graphviz-payload-paths
           (sorted-copy-of-strings
            (hyperdoc::payload-paths-of graphviz-check))))
    (assimilation-assert-typep
     'hyperdoc::git-upstream-commit-assimilation-check
     check
     "Worked example entry point must materialize as a git-upstream-commit-assimilation-check")
    (assimilation-assert-typep
     'hyperdoc::git-upstream-commit-assimilation-check
     graphviz-check
     "Graphviz worked example constructor must materialize as a git-upstream-commit-assimilation-check")
    (assimilation-assert-typep
     'hyperdoc::git-upstream-commit-assimilation-check
     graphviz-example
     "Graphviz defexample must evaluate to the inspectable assimilation object")
    (assimilation-assert-typep
     'hyperdoc::git-upstream-commit-assimilation-surface
     surface
     "Surface entry point must materialize as a git-upstream-commit-assimilation-surface")
    (assimilation-assert-typep
     'hyperdoc::git-commit-equivalence-check
     (hyperdoc::equivalence-check-of check)
     "Assimilation check must wrap the existing commit-equivalence proof object")
    (assimilation-assert-equal
     :already-assimilated
     (hyperdoc::final-decision-of check)
     "Static-route worked example must classify as already assimilated")
    (assimilation-assert-true
     (hyperdoc::patch-equivalent-p check)
     "Graph/history evidence must still prove replay equivalence separately")
    (assimilation-assert-equal
     "f7dd5540d3f7497a4d76f2b75db6f15d65485c0b"
     (hyperdoc::commit-hash-of
      (hyperdoc::replayed-equivalent-commit-of check))
     "Worked example must expose the replayed equivalent commit")
    (assimilation-assert-equal
     "1f8f2857baf99c623940af7e7acec0393d0ebc83"
     (hyperdoc::commit-hash-of
      (hyperdoc::superseding-local-commit-of check))
     "Worked example must expose the later local superseding commit")
    (assimilation-assert-equal
     :present
     (hyperdoc::semantic-effect-status-of check)
     "Semantic evidence must separately say that the skill effect is present")
    (assimilation-assert-equal
     :compatible
     (hyperdoc::semantic-compatibility-status-of check)
     "Semantic evidence must separately say that the payload remains compatible")
    (assimilation-assert-equal
     :resolved
     (hyperdoc::corpus-evidence-status-of check)
     "Worked example corpus evidence must stay resolved in the loaded explorer image")
    (assimilation-assert-equal
     :complete
     (hyperdoc::semantic-evidence-availability-of check)
     "Worked example semantic evidence must stay complete in the loaded explorer image")
    (assimilation-assert-equal
     :passed
     (hyperdoc::validation-status-of check)
     "Focused validation must pass for the worked example")
    (assimilation-assert-equal
     (sorted-copy-of-strings
      '("hyperdoc-explorer/static-route-observability.lisp"
        "hyperdoc.asd"
        "hyperdoc/Diagnose static asset route ownership.html"
        "hyperdoc/Static route observability.html"
        "hyperdoc/static-route-observability.lisp"
        "hyperdoc/topics.lisp"))
     payload-paths
     "Payload scope must expose the exact upstream file set for the worked example")
    (assimilation-assert-true
     (fboundp 'hyperdoc::graphviz-story-item-upstream-assimilation-example)
     "Graphviz worked example must be registered as a top-level defexample function")
    (assimilation-assert-equal
     "ceae9d2739c181ce566103e5773e1e08bfdc859b"
     (hyperdoc::commit-hash-of
      (hyperdoc::source-commit-of graphviz-check))
     "Graphviz worked example must expose the upstream source commit")
    (assimilation-assert-equal
     "hauptsache"
     (hyperdoc::target-branch-of graphviz-check)
     "Graphviz worked example must target hauptsache")
    (assimilation-assert-true
     (not (hyperdoc::ancestry-present-p graphviz-check))
     "Graphviz worked example must keep graph/history ancestry separate from semantic assimilation")
    (assimilation-assert-true
     (not (hyperdoc::patch-equivalent-p graphviz-check))
     "Graphviz worked example must not claim replay-equivalent content from graph/history proof alone")
    (assimilation-assert-equal
     nil
     (hyperdoc::replayed-equivalent-commit-of graphviz-check)
     "Graphviz worked example must keep the replay-equivalent commit absent")
    (assimilation-assert-equal
     "b1e8d4041ab5f584886dfa12e5952b0a6bb6173c"
     (hyperdoc::commit-hash-of
      (hyperdoc::superseding-local-commit-of graphviz-check))
     "Graphviz worked example must expose the earlier local superseding commit")
    (assimilation-assert-equal
     :present
     (hyperdoc::semantic-effect-status-of graphviz-check)
     "Graphviz semantic evidence must separately say that the live effect is already present")
    (assimilation-assert-equal
     :compatible
     (hyperdoc::semantic-compatibility-status-of graphviz-check)
     "Graphviz semantic evidence must separately say that the current constructor/corpus shape remains compatible")
    (assimilation-assert-equal
     :resolved
     (hyperdoc::corpus-evidence-status-of graphviz-check)
     "Graphviz worked example corpus evidence must resolve in the loaded explorer image")
    (assimilation-assert-equal
     :complete
     (hyperdoc::semantic-evidence-availability-of graphviz-check)
     "Graphviz worked example semantic evidence must stay complete in the loaded explorer image")
    (assimilation-assert-equal
     :passed
     (hyperdoc::validation-status-of graphviz-check)
     "Graphviz worked example focused validation must pass")
    (assimilation-assert-equal
     :already-assimilated
     (hyperdoc::final-decision-of graphviz-check)
     "Graphviz worked example must classify as already assimilated")
    (assimilation-assert-equal
     (sorted-copy-of-strings
      '("hyperbook-fedwiki/story-items.lisp"))
     graphviz-payload-paths
     "Graphviz worked example payload scope must stay on the single upstream renderer file")
    (dolist (title '("Summary"
                     "Graph/History proof"
                     "Payload scope"
                     "Semantic evidence"
                     "Validation"
                     "Decision rationale"))
      (assimilation-assert-true
       (assimilation-find-view-by-title check-views title)
       (format nil "Assimilation check must expose view ~A" title)))
    (dolist (title '("Summary"
                     "Graph/History proof"
                     "Payload scope"
                     "Semantic evidence"
                     "Validation"
                     "Decision rationale"))
      (assimilation-assert-true
       (assimilation-find-view-by-title graphviz-check-views title)
       (format nil "Graphviz assimilation check must expose view ~A" title)))
    (dolist (title '("Summary"
                     "Comparison"
                     "Worked example"))
      (assimilation-assert-true
       (assimilation-find-view-by-title surface-views title)
       (format nil "Assimilation surface must expose view ~A" title)))
    (assimilation-assert-equal
     2
     (length (hyperdoc::checks-of surface))
     "Assimilation surface must now expose both the static-route and graphviz worked examples")))

(defun run-upstream-commit-assimilation-page-render-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((page
           (hyperbook:find-page hyperdoc::*hyperdoc*
                                "Graphviz story item upstream assimilation example"
                                :signal-error? t))
         (views
           (assimilation-load-inspector-views-for-object page))
         (content-view
           (assimilation-find-view-by-title views "Content"))
         (content-html
           (and content-view
                (html-inspector-views:view-html content-view))))
    (assimilation-assert-true
     content-view
     "Graphviz assimilation example page must expose a Content view")
    (assimilation-assert-true
     (search "defexample" content-html :test #'char-equal)
     "Graphviz assimilation example page must inline-render the top-level defexample form")
    (assimilation-assert-true
     (search "graphviz-story-item-upstream-assimilation-example"
             content-html :test #'char-equal)
     "Graphviz assimilation example page must inline-render the worked-example defexample source")
    (assimilation-assert-true
     (search "Run example" content-html :test #'char-equal)
     "Inline-rendered defexample source must expose the runnable play-button affordance")
    (assimilation-assert-equal
     nil
     (search "source-of-function" content-html :test #'char-equal)
     "Graphviz assimilation example page must show rendered source, not a source-of-function placeholder label")))

(defun run-upstream-commit-assimilation-documentation-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let ((topic (hyperdoc::check-upstream-commit-assimilation-equivalence-topic))
        (example-topic
          (hyperdoc::graphviz-story-item-upstream-assimilation-example-topic)))
    (assimilation-assert-true
     (fboundp 'hyperdoc::check-upstream-commit-assimilation-equivalence-topic)
     "Assimilation topic function must be present")
    (assimilation-assert-true
     (fboundp 'hyperdoc::graphviz-story-item-upstream-assimilation-example-topic)
     "Graphviz assimilation example topic function must be present")
    (assimilation-assert-equal
     "Check upstream commit assimilation equivalence"
     (hyperbook:title-of topic)
     "Assimilation topic title")
    (assimilation-assert-equal
     "Graphviz story item upstream assimilation example"
     (hyperbook:title-of example-topic)
     "Graphviz assimilation example topic title")
    (assimilation-assert-true
     (hyperbook:find-page hyperdoc::*topics*
                          "Check upstream commit assimilation equivalence"
                          :signal-error? t)
     "Assimilation topic page must exist")
    (assimilation-assert-true
     (hyperbook:find-page hyperdoc::*hyperdoc*
                          "Check upstream commit assimilation equivalence"
                          :signal-error? t)
     "Assimilation HyperDoc page must exist")
    (assimilation-assert-true
     (hyperbook:find-page hyperdoc::*topics*
                          "Graphviz story item upstream assimilation example"
                          :signal-error? t)
     "Graphviz assimilation example topic page must exist")
    (assimilation-assert-true
     (hyperbook:find-page hyperdoc::*hyperdoc*
                          "Graphviz story item upstream assimilation example"
                          :signal-error? t)
     "Graphviz assimilation example HyperDoc page must exist")))

(defun run-git-commit-assimilation-smoke-tests ()
  (run-upstream-commit-assimilation-classification-smoke-test)
  (run-upstream-commit-assimilation-page-evidence-smoke-test)
  (run-upstream-commit-assimilation-worked-example-smoke-test)
  (run-upstream-commit-assimilation-page-render-smoke-test)
  (run-upstream-commit-assimilation-documentation-smoke-test)
  t)
