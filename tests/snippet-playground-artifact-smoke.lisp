;;;; Focused smoke tests for snippet-playground authored/compiled artifacts
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-SNIPPET-PLAYGROUND-ARTIFACT-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun snippet-playground-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun snippet-playground-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun snippet-playground-assert-typep (expected-type object message)
  (unless (typep object expected-type)
    (error "~A -- expected type: ~S actual type: ~S"
           message
           expected-type
           (type-of object))))

(defun snippet-playground-assert-contains (substring string message)
  (unless (search substring string :test #'char=)
    (error "~A -- missing substring: ~S" message substring)))

(defun snippet-playground-assert-not-contains (substring string message)
  (when (search substring string :test #'char=)
    (error "~A -- unexpected substring: ~S" message substring)))

(defun snippet-playground-smoke-find-view-by-title (views title)
  (find title
        views
        :key #'html-inspector-views:view-title
        :test #'string=))

(defun snippet-playground-smoke-load-inspector-views-for-object (object)
  (let ((pane (make-instance 'clog-moldable-inspector::pane
                             :inspector nil
                             :object object)))
    (clog-moldable-inspector::load-views pane)
    (slot-value pane 'clog-moldable-inspector::views)))

(defun snippet-playground-smoke-region-spec (layout-spec placement)
  (find placement
        (getf layout-spec :regions)
        :key #'car
        :test #'eq))

(defun snippet-playground-smoke-region-attribute (region-spec key)
  (getf (rest region-spec) key))

(defun snippet-playground-smoke-make-blocks ()
  (list
   (list :index 1
         :line-number 1
         :location-label "source line 1"
         :open-tag "<pre><code class=\"language-mech\">"
         :source (format nil
                         "CLICK node~%CODE transform~%PREVIEW items"))
   (list :index 2
         :line-number 10
         :location-label "source line 10"
         :open-tag "<pre><code class=\"language-javascript\">"
         :source
         (format nil
                 "export default function(state) {~%  const text = \"Quick Brown Fox\";~%  state.items = text.split(\"\").map((value) => value);~%  return state.items;~%}"))))

(defun make-snippet-playground-artifact-smoke-session ()
  (let* ((blocks (snippet-playground-smoke-make-blocks))
         (source-text (hyperdoc::snippet-playground-source-text-from-blocks
                       blocks)))
    (hyperdoc::make-snippet-playground-result-from-blocks
     :context-object nil
     :context-view-title "Source"
     :source-pathname nil
     :source-text source-text
     :blocks blocks
     :origin-surface-kind "html-source"
     :provider-kind "source-v1"
     :source-label "Snippet playground artifact smoke")))

(defun snippet-playground-smoke-make-bundled-slice-blocks ()
  (list
   (list :index 1
         :line-number 1
         :location-label "source line 1"
         :open-tag "<pre><code class=\"language-mech\">"
         :source (format nil
                         "CLICK station~%CODE report~%PREVIEW items"))
   (list :index 2
         :line-number 10
         :location-label "source line 10"
         :open-tag "<pre><code class=\"language-javascript\">"
         :source
         (format nil
                 "export default function runSlice(state) {~%  state.items = report(desc(links(state)));~%  return state.items;~%}"))
   (list :index 3
         :line-number 20
         :location-label "source line 20"
         :open-tag "<pre><code class=\"language-javascript\">"
         :source
         (format nil
                 "function links(state) {~%  return state.items || [];~%}"))
   (list :index 4
         :line-number 30
         :location-label "source line 30"
         :open-tag "<pre><code class=\"language-javascript\">"
         :source
         (format nil
                 "function desc(items) {~%  return items;~%}"))
   (list :index 5
         :line-number 40
         :location-label "source line 40"
         :open-tag "<pre><code class=\"language-javascript\">"
         :source
         (format nil
                 "function report(items) {~%  return items.map((item) => item);~%}"))))

(defun make-snippet-playground-bundled-slice-smoke-session ()
  (let* ((blocks (snippet-playground-smoke-make-bundled-slice-blocks))
         (source-text (hyperdoc::snippet-playground-source-text-from-blocks
                       blocks)))
    (hyperdoc::make-snippet-playground-result-from-blocks
     :context-object nil
     :context-view-title "Source"
     :source-pathname nil
     :source-text source-text
     :blocks blocks
     :origin-surface-kind "html-source"
     :provider-kind "source-v1"
     :source-label "Snippet playground bundled slice smoke")))

(defun run-snippet-playground-code-slice-bundle-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (let* ((session (make-snippet-playground-bundled-slice-smoke-session))
         (recognized-code-snippets
           (hyperdoc::snippet-playground-session-recognized-code-snippets-of
            session))
         (selected-code
           (hyperdoc::snippet-playground-session-selected-code-of session))
         (selected-source
           (and selected-code
                (hyperdoc::code-snippet-source-of selected-code)))
         (selected-findings
           (and selected-code
                (hyperdoc::code-snippet-findings-of selected-code))))
    (snippet-playground-assert-equal
     :ready
     (hyperdoc::snippet-playground-session-status-of session)
     "Bundled Mech/code slice must build a ready session")
    (snippet-playground-assert-equal
     4
     (length recognized-code-snippets)
     "Recognition must keep all code snippets in the selected Mech slice")
    (snippet-playground-assert-true
     (every (lambda (function-name)
              (some (lambda (snippet)
                      (search function-name
                              (hyperdoc::code-snippet-source-of snippet)
                              :test #'char=))
                    recognized-code-snippets))
            '("runSlice" "links" "desc" "report"))
     "Recognized code snippets must include entry and helper functions")
    (snippet-playground-assert-contains
     "export default function runSlice"
     selected-source
     "Bundled selected code must keep the entry function")
    (snippet-playground-assert-contains
     "function links"
     selected-source
     "Bundled selected code must include links helper")
    (snippet-playground-assert-contains
     "function desc"
     selected-source
     "Bundled selected code must include desc helper")
    (snippet-playground-assert-contains
     "function report"
     selected-source
     "Bundled selected code must include report helper")
    (snippet-playground-assert-true
     (find-if (lambda (finding)
                (search "Bundled 4 code snippets" finding :test #'char=))
              selected-findings)
     "Bundled selected code findings must include the bundle size")))

(defun snippet-playground-smoke-make-elided-html-pre-pollution-blocks ()
  (list
   (list :index 1
         :line-number 1
         :location-label "story item 1 (mech)"
         :open-tag "fedwiki-mech"
         :source (format nil
                         "CLICK station~%CODE popular~%PREVIEW items"))
   (list :index 2
         :line-number 10
         :location-label "story item 2 (html)"
         :open-tag "fedwiki-html"
         :source
         (format nil
                 "<pre>export function popular(count) {~%  let tally = this.neighborhood.reduce( … )~%  let top = tally.sort.slice(0,count)~%  this.items = top.map( … )~%}</pre>"))
   (list :index 3
         :line-number 20
         :location-label "story item 3 (paragraph)"
         :open-tag "fedwiki-paragraph"
         :source "Here I replace some elided code with function names.")
   (list :index 4
         :line-number 30
         :location-label "story item 4 (code)"
         :open-tag "fedwiki-code"
         :source
         (format nil
                 "export function popular(count) {~%  globalThis = this~%  let infos = this.neighborhood~%  let tally = infos.reduce(links, [])~%  let top = tally.sort(desc).slice(0,count)~%  this.items = top.map(report)~%  return `${tally.length} linked pages`~%}"))
   (list :index 5
         :line-number 40
         :location-label "story item 5 (code)"
         :open-tag "fedwiki-code"
         :source
         (format nil
                 "function links(tally, page) {~%  tally.push(page)~%  return tally~%}"))
   (list :index 6
         :line-number 50
         :location-label "story item 6 (code)"
         :open-tag "fedwiki-code"
         :source
         (format nil
                 "function desc(left, right) {~%  return right.count - left.count~%}"))
   (list :index 7
         :line-number 60
         :location-label "story item 7 (code)"
         :open-tag "fedwiki-code"
         :source
         (format nil
                 "function report(item) {~%  return item~%}"))
   (list :index 8
         :line-number 70
         :location-label "story item 8 (code)"
         :open-tag "fedwiki-code"
         :source
         (format nil
                 "class Bag {~%  constructor(items) {~%    this.items = items~%  }~%}"))))

(defun make-snippet-playground-elided-html-pre-pollution-smoke-session ()
  (let* ((blocks (snippet-playground-smoke-make-elided-html-pre-pollution-blocks))
         (source-text (hyperdoc::snippet-playground-source-text-from-blocks
                       blocks)))
    (hyperdoc::make-snippet-playground-result-from-blocks
     :context-object nil
     :context-view-title "Source"
     :source-pathname nil
     :source-text source-text
     :blocks blocks
     :origin-surface-kind "fedwiki-page"
     :provider-kind "fedwiki-v1"
     :source-label "Snippet playground elided html-pre pollution smoke")))

(defun run-snippet-playground-elided-html-pre-pollution-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (let* ((session
           (make-snippet-playground-elided-html-pre-pollution-smoke-session))
         (report
           (hyperdoc::snippet-playground-session-source-expansion-report-of
            session))
         (selected-code
           (hyperdoc::snippet-playground-session-selected-code-of session))
         (selected-source
           (and selected-code
                (hyperdoc::code-snippet-source-of selected-code)))
         (selected-findings
           (and selected-code
                (hyperdoc::code-snippet-findings-of selected-code)))
         (recognized-labels
           (mapcar #'hyperdoc::snippet-location-label-of
                   (hyperdoc::snippet-playground-session-recognized-code-snippets-of
                    session)))
         (candidates
           (and report
                (hyperdoc::snippet-source-expansion-report-candidates report)))
         (preview-candidate
           (find-if (lambda (entry)
                      (string= (getf entry :synthetic_id) "html-pre/2/1"))
                    candidates))
         (preview-source
           (and preview-candidate
                (getf preview-candidate :preview))))
    (snippet-playground-assert-equal
     :ready
     (hyperdoc::snippet-playground-session-status-of session)
     "Elided html-pre fixture must still produce a ready session")
    (snippet-playground-assert-true
     (member "html-pre/2/1 from story item 2 (html)"
             recognized-labels
             :test #'string=)
     "Parser output must retain html-pre candidate provenance in recognized snippets")
    (snippet-playground-assert-true
     preview-candidate
     "Source expansion report must include html-pre/2/1 candidate provenance")
    (snippet-playground-assert-equal
     :accepted
     (getf preview-candidate :status)
     "Elided html-pre preview candidate should still be tracked as accepted exploratory evidence")
    (snippet-playground-assert-contains
     "…"
     (or preview-source "")
     "Candidate preview must preserve the ellipsis marker")
    (snippet-playground-assert-contains
     "export function popular(count)"
     selected-source
     "Selected code must include the explicit code story item entry function")
    (snippet-playground-assert-contains
     "function links"
     selected-source
     "Selected code must include helper links function")
    (snippet-playground-assert-contains
     "function desc"
     selected-source
     "Selected code must include helper desc function")
    (snippet-playground-assert-contains
     "function report"
     selected-source
     "Selected code must include helper report function")
    (snippet-playground-assert-contains
     "class Bag"
     selected-source
     "Selected code must include helper class Bag")
    (snippet-playground-assert-not-contains
     "<pre>"
     selected-source
     "Selected code bundle must exclude HTML wrapper tags")
    (snippet-playground-assert-not-contains
     "</pre>"
     selected-source
     "Selected code bundle must exclude closing HTML wrapper tags")
    (snippet-playground-assert-not-contains
     "Here I replace some elided code with function names."
     selected-source
     "Selected code bundle must exclude paragraph prose")
    (snippet-playground-assert-not-contains
     "…"
     selected-source
     "Selected code bundle must exclude elided html-pre preview text")
    (snippet-playground-assert-not-contains
     "let tally = this.neighborhood.reduce( … )"
     selected-source
     "Selected code bundle must exclude the synthetic html-pre elided preview body")
    (snippet-playground-assert-true
     (find-if (lambda (finding)
                (search "Bundled 5 code snippets" finding :test #'char=))
              selected-findings)
     "Bundle findings must report only the executable snippet count")))

(defun snippet-playground-smoke-make-html-pre-expansion-blocks ()
  (list
   (list :index 1
         :line-number 1
         :location-label "source line 1"
         :open-tag "fedwiki-mech"
         :source (format nil
                         "CLICK station~%CODE transform~%PREVIEW items"))
   (list :index 2
         :line-number 10
         :location-label "story item 2 (html)"
         :open-tag "fedwiki-html"
         :source
         (format nil
                 "<p>HTML wrapper before code.</p>~%<pre class=\"language-javascript\">export default function htmlEntry(state) {~%  state.items = htmlHelper(state.items || []);~%  return state.items;~%}</pre>~%<p>Between blocks.</p>~%<pre data-lang=\"javascript\">function htmlHelper(items) {~%  return items.map((item) => item);~%}</pre>"))))

(defun snippet-playground-smoke-make-html-pre-discrepancy-blocks ()
  (list
   (list :index 1
         :line-number 1
         :location-label "source line 1"
         :open-tag "fedwiki-mech"
         :source (format nil
                         "CLICK station~%CODE transform~%PREVIEW items"))
   (list :index 2
         :line-number 10
         :location-label "story item 2 (html)"
         :open-tag "fedwiki-html"
         :source
         (format nil
                 "<p>HTML wrapper before code.</p>~%<pre class=\"language-javascript\">export default function htmlEntry(state) {~%  state.items = htmlHelper(state.items || []);~%  return state.items;~%}</pre>~%<pre class=\"language-javascript\">  </pre>~%<pre data-lang=\"javascript\">function htmlHelper(items) {~%  return items.map((item) => item);~%}</pre>"))))

(defun snippet-playground-smoke-make-html-pre-malformed-blocks ()
  (list
   (list :index 1
         :line-number 1
         :location-label "source line 1"
         :open-tag "fedwiki-mech"
         :source (format nil
                         "CLICK station~%CODE transform~%PREVIEW items"))
   (list :index 2
         :line-number 10
         :location-label "story item 2 (html)"
         :open-tag "fedwiki-html"
         :source
         (format nil
                 "<p>Before.</p>~%<pre class=\"language-javascript\">export default function htmlEntry(state) {~%  return state.items || [];~%}</pre>~%<pre class=\"language-javascript\">function brokenHelper(items) {~%  return items;~%}"))))

(defun make-snippet-playground-html-pre-expansion-smoke-session
    (&key source-expansion-policy)
  (let* ((blocks (snippet-playground-smoke-make-html-pre-expansion-blocks))
         (source-text (hyperdoc::snippet-playground-source-text-from-blocks
                       blocks)))
    (hyperdoc::make-snippet-playground-result-from-blocks
     :context-object nil
     :context-view-title "Source"
     :source-pathname nil
     :source-text source-text
     :blocks blocks
     :origin-surface-kind "fedwiki-page"
     :provider-kind "fedwiki-v1"
     :source-label "Snippet playground html-pre expansion smoke"
     :source-expansion-policy source-expansion-policy)))

(defun make-snippet-playground-html-pre-discrepancy-smoke-session
    (&key source-expansion-policy)
  (let* ((blocks (snippet-playground-smoke-make-html-pre-discrepancy-blocks))
         (source-text (hyperdoc::snippet-playground-source-text-from-blocks
                       blocks)))
    (hyperdoc::make-snippet-playground-result-from-blocks
     :context-object nil
     :context-view-title "Source"
     :source-pathname nil
     :source-text source-text
     :blocks blocks
     :origin-surface-kind "fedwiki-page"
     :provider-kind "fedwiki-v1"
     :source-label "Snippet playground html-pre discrepancy smoke"
     :source-expansion-policy source-expansion-policy)))

(defun make-snippet-playground-html-pre-malformed-smoke-session
    (&key source-expansion-policy)
  (let* ((blocks (snippet-playground-smoke-make-html-pre-malformed-blocks))
         (source-text (hyperdoc::snippet-playground-source-text-from-blocks
                       blocks)))
    (hyperdoc::make-snippet-playground-result-from-blocks
     :context-object nil
     :context-view-title "Source"
     :source-pathname nil
     :source-text source-text
     :blocks blocks
     :origin-surface-kind "fedwiki-page"
     :provider-kind "fedwiki-v1"
     :source-label "Snippet playground html-pre malformed smoke"
     :source-expansion-policy source-expansion-policy)))

(defun run-snippet-playground-html-pre-expansion-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (let* ((session (make-snippet-playground-html-pre-expansion-smoke-session))
         (recognized-code-snippets
           (hyperdoc::snippet-playground-session-recognized-code-snippets-of
            session))
         (selected-code
           (hyperdoc::snippet-playground-session-selected-code-of session))
         (selected-source
           (and selected-code
                (hyperdoc::code-snippet-source-of selected-code)))
         (entry-position
           (and selected-source
                (search "export default function htmlEntry"
                        selected-source
                        :test #'char=)))
         (helper-position
           (and selected-source
                (search "function htmlHelper"
                        selected-source
                        :test #'char=)))
         (report
           (hyperdoc::snippet-playground-session-source-expansion-report-of
            session))
         (recognized-labels
           (mapcar #'hyperdoc::snippet-location-label-of recognized-code-snippets))
         (candidates
           (and report
                (hyperdoc::snippet-source-expansion-report-candidates
                 report)))
         (first-candidate
           (find-if (lambda (entry)
                      (string= (getf entry :synthetic_id) "html-pre/2/1"))
                    candidates))
         (second-candidate
           (find-if (lambda (entry)
                      (string= (getf entry :synthetic_id) "html-pre/2/2"))
                    candidates))
         (policy-summary
           (and report
                (hyperdoc::snippet-source-expansion-report-policy-summary
                 report))))
    (snippet-playground-assert-equal
     :ready
     (hyperdoc::snippet-playground-session-status-of session)
     "HTML pre expansion must keep the session ready")
    (snippet-playground-assert-true
     (member "html-pre/2/1 from story item 2 (html)"
             recognized-labels
             :test #'string=)
     "Recognized code snippets must include the first extracted html-pre block")
    (snippet-playground-assert-true
     (member "html-pre/2/2 from story item 2 (html)"
             recognized-labels
             :test #'string=)
     "Recognized code snippets must include the second extracted html-pre block")
    (snippet-playground-assert-contains
     "export default function htmlEntry"
     selected-source
     "Bundled selected code must include the extracted html entry function")
    (snippet-playground-assert-contains
     "function htmlHelper"
     selected-source
     "Bundled selected code must include the extracted html helper function")
    (snippet-playground-assert-true
     (and entry-position
          helper-position
          (< entry-position helper-position))
     "Bundled selected code must preserve HTML <pre> source order (entry before helper)")
    (snippet-playground-assert-equal
     2
     (hyperdoc::snippet-source-expansion-report-synthetic-block-count report)
     "Exploratory parser report must record two accepted synthetic candidates")
    (snippet-playground-assert-equal
     1
     (hyperdoc::snippet-source-expansion-report-html-like-block-count report)
     "Exploratory parser report must record one HTML-like source block")
    (snippet-playground-assert-equal
     1
     (hyperdoc::snippet-source-expansion-report-scanned-block-count report)
     "Exploratory parser report must record one scanned block")
    (snippet-playground-assert-equal
     2
     (hyperdoc::snippet-source-expansion-report-accepted-candidate-count report)
     "Exploratory parser report must record two accepted candidates")
    (snippet-playground-assert-equal
     0
     (hyperdoc::snippet-source-expansion-report-rejected-candidate-count report)
     "Exploratory parser report must record zero rejected candidates")
    (snippet-playground-assert-equal
     1
     (hyperdoc::snippet-source-expansion-report-html-like-blocks-scanned report)
     "Exploratory parser report must record one scanned HTML-like block")
    (snippet-playground-assert-equal
     2
     (hyperdoc::snippet-source-expansion-report-pre-regions-found report)
     "Exploratory parser report must record two detected <pre> regions")
    (snippet-playground-assert-equal
     2
     (hyperdoc::snippet-source-expansion-report-pre-regions-accepted report)
     "Exploratory parser report must record two accepted <pre> candidates")
    (snippet-playground-assert-equal
     0
     (hyperdoc::snippet-source-expansion-report-pre-regions-rejected report)
     "Exploratory parser report must record zero rejected <pre> candidates")
    (snippet-playground-assert-true
     (and first-candidate second-candidate)
     "Candidate provenance must include html-pre/2/1 and html-pre/2/2")
    (snippet-playground-assert-equal
     2
     (getf first-candidate :parent_block_index)
     "Candidate provenance must record parent block index")
    (snippet-playground-assert-equal
     1
     (getf first-candidate :pre_ordinal)
     "Candidate provenance must record pre ordinal")
    (snippet-playground-assert-true
     (integerp (or (getf first-candidate :source_line_number) 0))
     "Candidate provenance must record source line number")
    (snippet-playground-assert-true
     (integerp (or (getf first-candidate :character_offset) 0))
     "Candidate provenance must record character offset")
    (snippet-playground-assert-true
     (stringp (getf first-candidate :reason))
     "Candidate provenance must include acceptance/rejection reason")
    (snippet-playground-assert-true
     (and (getf second-candidate :language_hint)
          (search "javascript"
                  (getf second-candidate :language_hint)
                  :test #'char-equal))
     "Language hints from policy-approved attributes must be recorded")
    (snippet-playground-assert-true
     (eq (getf policy-summary :extract_html_pre_p) t)
     "Policy summary must record extract_html_pre_p")
    (snippet-playground-assert-true
     (eq (getf policy-summary :decode_html_entities_p) t)
     "Default policy must decode HTML entities")
    (snippet-playground-assert-true
     (eq (getf policy-summary :include_original_blocks_p) t)
     "Default policy must retain original blocks")
    (snippet-playground-assert-true
     (eq (getf policy-summary :collect_parser_stats_p) t)
     "Policy summary must record collect_parser_stats_p")
    (snippet-playground-assert-true
     (eq (getf policy-summary :record_discrepancies_p) t)
     "Policy summary must record record_discrepancies_p")
    (snippet-playground-assert-true
     (eq (getf policy-summary :collect_incremental_stats_p) nil)
     "Default policy must keep incremental snapshots off")
    (snippet-playground-assert-true
     (eq (getf policy-summary :generate_graphviz_dot_p) nil)
     "Default policy must keep DOT generation off")
    (snippet-playground-assert-true
     (eq (getf policy-summary :parser_engine_kind) :direct)
     "Default policy must keep SCXML controller optional/off")))

(defun run-snippet-playground-html-pre-expansion-disabled-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (let* ((policy
           (hyperdoc::make-snippet-source-expansion-policy
            :extract-html-pre-p nil))
         (session
           (make-snippet-playground-html-pre-expansion-smoke-session
            :source-expansion-policy policy))
         (report
           (hyperdoc::snippet-playground-session-source-expansion-report-of
            session))
         (selected-code
           (hyperdoc::snippet-playground-session-selected-code-of session))
         (recognized-code-snippets
           (hyperdoc::snippet-playground-session-recognized-code-snippets-of
            session))
         (recognized-labels
           (mapcar #'hyperdoc::snippet-location-label-of
                   recognized-code-snippets)))
    (snippet-playground-assert-equal
     0
     (hyperdoc::snippet-source-expansion-report-synthetic-block-count report)
     "Disabled policy must produce zero synthetic html-pre candidates")
    (snippet-playground-assert-equal
     1
     (hyperdoc::snippet-source-expansion-report-html-like-block-count report)
     "Disabled policy must still classify one HTML-like source block")
    (snippet-playground-assert-equal
     0
     (hyperdoc::snippet-source-expansion-report-scanned-block-count report)
     "Disabled policy must keep scanned block count at zero")
    (snippet-playground-assert-true
     (null (hyperdoc::snippet-source-expansion-report-candidates report))
     "Disabled policy must not record extracted html-pre candidates")
    (snippet-playground-assert-true
     (every (lambda (label)
              (or (null label)
                  (not (search "html-pre/" label :test #'char=))))
            recognized-labels)
     "Disabled policy must keep synthetic html-pre labels out of recognized code")
    (snippet-playground-assert-true
     (or (null selected-code)
         (not (search "html-pre/"
                      (or (hyperdoc::snippet-location-label-of selected-code)
                          "")
                      :test #'char=)))
     "Disabled policy must not select a synthetic html-pre code snippet")))

(defun run-snippet-playground-html-pre-expansion-scxml-engine-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (let* ((direct-policy
           (hyperdoc::make-snippet-source-expansion-policy
            :parser-engine-kind :direct))
         (scxml-policy
           (hyperdoc::make-snippet-source-expansion-policy
            :parser-engine-kind :scxml))
         (direct-session
           (make-snippet-playground-html-pre-expansion-smoke-session
            :source-expansion-policy direct-policy))
         (scxml-session
           (make-snippet-playground-html-pre-expansion-smoke-session
            :source-expansion-policy scxml-policy))
         (direct-report
           (hyperdoc::snippet-playground-session-source-expansion-report-of
            direct-session))
         (scxml-report
           (hyperdoc::snippet-playground-session-source-expansion-report-of
            scxml-session))
         (direct-selected
           (hyperdoc::snippet-playground-session-selected-code-of direct-session))
         (scxml-selected
           (hyperdoc::snippet-playground-session-selected-code-of scxml-session)))
    (snippet-playground-assert-equal
     :ready
     (hyperdoc::snippet-playground-session-status-of scxml-session)
     "SCXML exploratory parser orchestration must keep this fixture ready")
    (snippet-playground-assert-equal
     (hyperdoc::code-snippet-source-of direct-selected)
     (hyperdoc::code-snippet-source-of scxml-selected)
     "SCXML and direct exploratory parser engines must produce the same bundled selected code")
    (snippet-playground-assert-equal
     2
     (hyperdoc::snippet-source-expansion-report-synthetic-block-count
      scxml-report)
     "SCXML exploratory parser report must keep the same accepted synthetic count")
    (snippet-playground-assert-equal
     :scxml
     (hyperdoc::snippet-source-expansion-report-parser-engine-kind
      scxml-report)
     "SCXML exploratory parser report must record :scxml engine kind")
    (snippet-playground-assert-equal
     "snippet-source-parser-html-pre-v1"
     (hyperdoc::snippet-source-expansion-report-parser-engine-chart-name
      scxml-report)
     "SCXML exploratory parser report must expose chart identity")
    (snippet-playground-assert-true
     (member "initialize"
             (hyperdoc::snippet-source-expansion-report-parser-engine-states-visited
              scxml-report)
             :test #'string=)
     "SCXML exploratory parser report must include visited parser states")
    (snippet-playground-assert-true
     (member "finalize-report"
             (hyperdoc::snippet-source-expansion-report-parser-engine-states-visited
              scxml-report)
             :test #'string=)
     "SCXML exploratory parser report must include finalize-report state")
    (snippet-playground-assert-equal
     2
     (hyperdoc::snippet-source-expansion-report-synthetic-block-count
      direct-report)
     "Direct exploratory parser baseline must still report two synthetic blocks")))

(defun run-snippet-playground-html-pre-expansion-discrepancy-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (let* ((session (make-snippet-playground-html-pre-discrepancy-smoke-session))
         (report
           (hyperdoc::snippet-playground-session-source-expansion-report-of
            session))
         (selected-code
           (hyperdoc::snippet-playground-session-selected-code-of session))
         (selected-source
           (and selected-code
                (hyperdoc::code-snippet-source-of selected-code)))
         (candidates (hyperdoc::snippet-source-expansion-report-candidates report))
         (rejected-candidate
           (find-if (lambda (entry)
                      (and (eql (getf entry :status) :rejected)
                           (= (getf entry :pre_ordinal) 2)))
                    candidates))
         (empty-pre-discrepancy
           (find-if (lambda (entry)
                      (eql (hyperdoc::snippet-source-parse-discrepancy-kind
                            entry)
                           :empty-pre))
                    (hyperdoc::snippet-source-expansion-report-discrepancies
                     report))))
    (snippet-playground-assert-equal
     :ready
     (hyperdoc::snippet-playground-session-status-of session)
     "Discrepancy fixture must still produce a ready session from accepted snippets")
    (snippet-playground-assert-contains
     "export default function htmlEntry"
     selected-source
     "Discrepancy fixture must still include the entry function")
    (snippet-playground-assert-contains
     "function htmlHelper"
     selected-source
     "Discrepancy fixture must still include the helper function")
    (snippet-playground-assert-equal
     3
     (hyperdoc::snippet-source-expansion-report-pre-regions-found report)
     "Discrepancy fixture must report all discovered <pre> regions")
    (snippet-playground-assert-equal
     1
     (hyperdoc::snippet-source-expansion-report-rejected-candidate-count report)
     "Discrepancy fixture must report one rejected candidate")
    (snippet-playground-assert-true
     rejected-candidate
     "Discrepancy fixture must retain rejected candidate provenance")
    (snippet-playground-assert-true
     empty-pre-discrepancy
     "Discrepancy fixture must record an :empty-pre structured discrepancy")
    (snippet-playground-assert-equal
     2
     (hyperdoc::snippet-source-parse-discrepancy-source-block-index
      empty-pre-discrepancy)
     "Structured discrepancy must identify parent block index")
    (snippet-playground-assert-true
     (integerp
      (or (hyperdoc::snippet-source-parse-discrepancy-source-line-number
           empty-pre-discrepancy)
          0))
     "Structured discrepancy must include source line number")
    (snippet-playground-assert-true
     (integerp
     (or (hyperdoc::snippet-source-parse-discrepancy-character-offset
           empty-pre-discrepancy)
          0))
     "Structured discrepancy must include character offset")))

(defun run-snippet-playground-html-pre-expansion-malformed-pre-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (let* ((session (make-snippet-playground-html-pre-malformed-smoke-session))
         (report
           (hyperdoc::snippet-playground-session-source-expansion-report-of
            session))
         (unterminated-discrepancy
           (find-if
            (lambda (entry)
              (eql (hyperdoc::snippet-source-parse-discrepancy-kind entry)
                   :unterminated-html-region))
            (hyperdoc::snippet-source-expansion-report-discrepancies
             report))))
    (snippet-playground-assert-equal
     :ready
     (hyperdoc::snippet-playground-session-status-of session)
     "Malformed html-pre fixture must still stay ready when at least one candidate is valid")
    (snippet-playground-assert-true
     unterminated-discrepancy
     "Malformed html-pre fixture must record a structured :unterminated-html-region discrepancy")
    (snippet-playground-assert-equal
     2
     (hyperdoc::snippet-source-parse-discrepancy-source-block-index
      unterminated-discrepancy)
     "Unterminated discrepancy must include parent block index provenance")
    (snippet-playground-assert-true
     (integerp
      (or (hyperdoc::snippet-source-parse-discrepancy-character-offset
           unterminated-discrepancy)
          0))
     "Unterminated discrepancy must include character offset provenance")))

(defun run-snippet-playground-html-pre-expansion-graphviz-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (let* ((policy
           (hyperdoc::make-snippet-source-expansion-policy
            :generate-graphviz-dot-p t
            :collect-incremental-stats-p t
            :stats-snapshot-period 1
            :graphviz-dot-snapshot-period 1))
         (session
           (make-snippet-playground-html-pre-expansion-smoke-session
            :source-expansion-policy policy))
         (report
           (hyperdoc::snippet-playground-session-source-expansion-report-of
            session))
         (dot-text
           (hyperdoc::snippet-source-expansion-report-graphviz-dot-text report))
         (snapshots
           (hyperdoc::snippet-source-expansion-report-incremental-stats-snapshots
            report)))
    (snippet-playground-assert-true
     (stringp dot-text)
     "Graphviz smoke test must emit DOT text when enabled")
    (snippet-playground-assert-contains
     "digraph snippet_source_parser"
     dot-text
     "DOT output must contain the graph header")
    (snippet-playground-assert-contains
     "\"source-block-2\""
     dot-text
     "DOT output must include the parent source block node")
    (snippet-playground-assert-contains
     "\"candidate-html-pre-2-1\""
     dot-text
     "DOT output must include the candidate node")
    (snippet-playground-assert-contains
     "\"source-block-2\" -> \"candidate-html-pre-2-1\""
     dot-text
     "DOT output must include a parent-to-candidate edge")
    (snippet-playground-assert-true
     snapshots
     "Incremental stats snapshots must be recorded when enabled")))

(defun run-snippet-playground-artifact-runtime-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (let* ((session (make-snippet-playground-artifact-smoke-session))
         (authored-source
           (hyperdoc::snippet-playground-authored-source-artifact))
         (authored-artifact
           (hyperdoc::snippet-playground-session-authored-artifact-of session))
         (behavior-artifact
           (hyperdoc::snippet-playground-session-behavior-artifact-of session))
         (layout-artifact
           (hyperdoc::snippet-playground-session-layout-artifact-of session))
         (layout-spec
           (hyperdoc::snippet-playground-layout-artifact-comparison-layout-spec-of
            layout-artifact))
         (center-region
           (snippet-playground-smoke-region-spec layout-spec :center))
         (left-region
           (snippet-playground-smoke-region-spec layout-spec :left))
         (right-region
           (snippet-playground-smoke-region-spec layout-spec :right))
         (run-machine
           (hyperdoc::snippet-playground-behavior-artifact-run-machine-of
            behavior-artifact))
         (comparison-machine
           (hyperdoc::snippet-playground-behavior-artifact-comparison-machine-of
            behavior-artifact))
         (run-state-ids
           (mapcar #'hyperdoc::id-of
                   (hyperdoc::state-machine-definition-states-of run-machine)))
         (comparison-state-ids
           (mapcar #'hyperdoc::id-of
                   (hyperdoc::state-machine-definition-states-of
                    comparison-machine)))
         (run-events (hyperdoc::state-machine-definition-events-of run-machine)))
    (snippet-playground-assert-typep
     'hyperdoc::snippet-playground-session
     session
     "Worked example must materialize as a ready snippet-playground session")
    (snippet-playground-assert-typep
     'hyperdoc::authored-relation-artifact-source
     authored-source
     "Snippet-playground must expose a repo-native authored source artifact")
    (snippet-playground-assert-equal
     :repo-native-lisp
     (hyperdoc::authored-relation-artifact-source-kind-of authored-source)
     "Authored source must be repo-native Lisp")
    (snippet-playground-assert-true
     (uiop:file-exists-p
      (merge-pathnames
       (hyperdoc::authored-relation-artifact-source-path-of authored-source)
       (uiop:getcwd)))
     "External authored source file must exist in the repo")
    (snippet-playground-assert-equal
     :ready
     (hyperdoc::snippet-playground-session-status-of session)
     "Worked example must stay in the ready lifecycle state")
    (snippet-playground-assert-typep
     'hyperdoc::snippet-playground-authored-artifact
     authored-artifact
     "Authored artifact must materialize as a first-class object")
    (snippet-playground-assert-equal
     (hyperdoc::authored-relation-artifact-source-artifact-id-of
      authored-source)
     (hyperdoc::id-of authored-artifact)
     "Authored artifact id must be reconstructed from the source artifact")
    (snippet-playground-assert-equal
     (hyperdoc::authored-relation-artifact-source-role-count
      authored-source)
     (length
      (hyperdoc::snippet-playground-authored-artifact-semantic-roles-of
       authored-artifact))
     "Reconstructed authored artifact must preserve source semantic roles")
    (snippet-playground-assert-equal
     (hyperdoc::authored-relation-artifact-source-relation-count
      authored-source)
     (length
      (hyperdoc::snippet-playground-authored-artifact-relations-of
       authored-artifact))
     "Reconstructed authored artifact must preserve source relations")
    (snippet-playground-assert-typep
     'hyperdoc::snippet-playground-behavior-artifact
     behavior-artifact
     "Behavior artifact must materialize as a first-class object")
    (snippet-playground-assert-typep
     'hyperdoc::snippet-playground-layout-artifact
     layout-artifact
     "Layout artifact must materialize as a first-class object")
    (snippet-playground-assert-true
     (eq authored-artifact
         (hyperdoc::snippet-playground-behavior-artifact-authored-artifact-of
          behavior-artifact))
     "Behavior artifact must be compiled from the authored artifact")
    (snippet-playground-assert-true
     (eq authored-artifact
         (hyperdoc::snippet-playground-layout-artifact-authored-artifact-of
          layout-artifact))
     "Layout artifact must be compiled from the authored artifact")
    (snippet-playground-assert-equal
     3
     (length (getf layout-spec :regions))
     "Compiled layout must keep one center, one left, and one right region")
    (snippet-playground-assert-true
     center-region
     "Compiled layout must keep a center region")
    (snippet-playground-assert-true
     left-region
     "Compiled layout must keep a left region")
    (snippet-playground-assert-true
     right-region
     "Compiled layout must keep a right region")
    (snippet-playground-assert-equal
     :shared-mech
     (snippet-playground-smoke-region-attribute center-region :content)
     "Shared Mech must remain bound only to the center region")
    (snippet-playground-assert-equal
     1
     (snippet-playground-smoke-region-attribute center-region :row)
     "Shared Mech must remain in the top row")
    (snippet-playground-assert-equal
     2
     (snippet-playground-smoke-region-attribute center-region :column-span)
     "Shared Mech must continue spanning the comparison split")
    (snippet-playground-assert-equal
     :javascript-code
     (snippet-playground-smoke-region-attribute left-region :content)
     "JavaScript must remain bound only to the left region")
    (snippet-playground-assert-equal
     :lisp-code
     (snippet-playground-smoke-region-attribute right-region :content)
     "Lisp must remain bound only to the right region")
    (dolist (state '(:available :pending :ready :failed))
      (snippet-playground-assert-true
       (member state run-state-ids :test #'eq)
       (format nil "Run machine must keep lifecycle state ~S" state)))
    (dolist (state '(:available :pending :ready :failed))
      (snippet-playground-assert-true
       (member state comparison-state-ids :test #'eq)
       (format nil "Comparison machine must keep lifecycle state ~S" state)))
    (dolist (event '(:snippet-click
                     :open-pending-pane
                     :pair-selected
                     :transformation-unit-built))
      (snippet-playground-assert-true
       (member event run-events :test #'eq)
       (format nil "Run machine must keep lifecycle event ~S" event)))))

(defun run-snippet-playground-artifact-rendering-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (let* ((session (make-snippet-playground-artifact-smoke-session))
         (authored-source
           (hyperdoc::snippet-playground-authored-source-artifact))
         (authored-artifact
           (hyperdoc::snippet-playground-session-authored-artifact-of session))
         (session-views
           (snippet-playground-smoke-load-inspector-views-for-object session))
         (artifact-views
           (snippet-playground-smoke-load-inspector-views-for-object
            authored-artifact))
         (source-views
           (snippet-playground-smoke-load-inspector-views-for-object
            authored-source))
         (summary-view
           (snippet-playground-smoke-find-view-by-title session-views
                                                        "Summary"))
         (authored-view
           (snippet-playground-smoke-find-view-by-title session-views
                                                        "Authored")))
    (dolist (title '("Summary"
                     "Comparison"
                     "Authored"
                     "Behavior"
                     "Layout"))
      (snippet-playground-assert-true
       (snippet-playground-smoke-find-view-by-title session-views title)
       (format nil "Snippet-playground session must expose view ~A" title)))
    (dolist (title '("Summary"
                     "Semantic roles"
                     "Behavior relations"
                     "Layout relations"
                     "Relation graph"))
      (snippet-playground-assert-true
       (snippet-playground-smoke-find-view-by-title artifact-views title)
       (format nil "Authored artifact must expose view ~A" title)))
    (dolist (title '("Summary"
                     "Role definitions"
                     "Relation definitions"))
      (snippet-playground-assert-true
       (snippet-playground-smoke-find-view-by-title source-views title)
       (format nil "Authored source artifact must expose view ~A" title)))
    (snippet-playground-assert-contains
     "Constructed transformation unit"
     (html-inspector-views:view-html summary-view)
     "Summary must stay sparse and keep the short sentence")
    (snippet-playground-assert-contains
     "Interface:"
     (html-inspector-views:view-html summary-view)
     "Summary must keep the explicit interface line")
    (snippet-playground-assert-not-contains
     "Behavior relations"
     (html-inspector-views:view-html summary-view)
     "Summary must not grow into the authored-artifact surface")
    (snippet-playground-assert-contains
     "Selected Mech snippet"
     (html-inspector-views:view-html authored-view)
     "Authored tab must surface semantic roles")
    (snippet-playground-assert-contains
     "comparison-pane contains-center shared-mech"
     (html-inspector-views:view-html authored-view)
     "Authored tab must surface layout relations directly")
    (let ((relation-graph-view
            (snippet-playground-smoke-find-view-by-title
             artifact-views
             "Relation graph")))
      (let ((relation-graph-html
              (html-inspector-views:view-html relation-graph-view)))
      (snippet-playground-assert-contains
       "data-hyperdoc-authored-relation-graph"
       relation-graph-html
       "Authored artifact relation graph view must render with the graph marker")
      (snippet-playground-assert-contains
       "snippet-playground-behavior-artifact"
       relation-graph-html
       "Authored artifact relation graph must mention the compiled behavior artifact target")
      (snippet-playground-assert-contains
       "snippet-playground-layout-artifact"
       relation-graph-html
       "Authored artifact relation graph must mention the compiled layout artifact target")
      (snippet-playground-assert-contains
       "compiled-from"
       relation-graph-html
       "Authored artifact relation graph must expose compiled-from derivation edges")))
    (snippet-playground-assert-contains
     "data-hyperdoc-snippet-authored-artifact"
     (html-inspector-views:view-html
      (snippet-playground-smoke-find-view-by-title artifact-views "Summary"))
     "Authored artifact summary must remain directly inspectable")))

(defun run-snippet-playground-artifact-smoke-tests ()
  (run-snippet-playground-artifact-runtime-smoke-test)
  (run-snippet-playground-code-slice-bundle-smoke-test)
  (run-snippet-playground-elided-html-pre-pollution-smoke-test)
  (run-snippet-playground-html-pre-expansion-smoke-test)
  (run-snippet-playground-html-pre-expansion-disabled-smoke-test)
  (run-snippet-playground-html-pre-expansion-discrepancy-smoke-test)
  (run-snippet-playground-html-pre-expansion-malformed-pre-smoke-test)
  (run-snippet-playground-html-pre-expansion-graphviz-smoke-test)
  (run-snippet-playground-html-pre-expansion-scxml-engine-smoke-test)
  (run-snippet-playground-artifact-rendering-smoke-test)
  (format t "~&Snippet-playground artifact smoke tests passed.~%"))
