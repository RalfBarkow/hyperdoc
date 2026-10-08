;;;; The public Trails Rendered experiment: observations and their limits.
(defpackage #:dreyeck/work/trails-rendered-reading (:use #:cl)
            (:export #:public-source-boundary #:solo-batch
                     #:solo-batch-provenance #:solo-beam #:public-result
                     #:interpretation-path #:federated-context
                     #:hoverbold-observation #:context-events
                     #:context-state-at #:context-delta "TRAIL-FOLLOWING"
                     "TRAIL-COMPOSITION-WITNESS" "EXECUTE-TRAIL-WITNESS"
                     "TRAIL-WORKSPACE" "ORIGINAL-CODE-BROWSER-CHECK"))
(in-package #:dreyeck/work/trails-rendered-reading)

(hyperdoc:see (hyperdoc:page "Trails Rendered public reproduction"))

;; One shared witness object. Captured payloads remain separate and unmodified.
(defparameter *provenance*
  (alexandria:plist-hash-table
   '(:source-page
    (:url "https://ward.voices.ustawi.wiki/trails-rendered.json"
     :sha256 "5fdba40fd3a68eddee00497af4dadb3847500356a2f131dbc0745afb86de9810"
     :snapshot "/Users/rgb/workspace/wiki-trails-rendered-local/source/trails-rendered.ward.voices.ustawi.wiki.json"
     :local-title-and-story :identical-to-snapshot
     :items (:mech "6405b752d1739af0" :graph-import "17a5b123160ef0d9"
             :trails "cc6a77771de7edbd" :trail-builder "84da00fa76850971"))
    :public-plugins
    (:mech (:repository "https://github.com/WardCunningham/wiki-plugin-mech"
            :revision "a028b4bba04e539dcaa090423d38a00a0050489d" :version "0.1.48-3"
            :entry "src/client/blocks.js: code_emit, solo_emit"
            :served-bundle :identical-to-clean-public-checkout-build
            :sha256 "c72ed0a572469d29c3287dafe8c8770c636d2537dbcfbededdd60a244d1e2384")
     :solo (:repository "https://github.com/WardCunningham/wiki-plugin-solo"
            :revision "17915844349bada64c901bd5ea73472702c446f9" :version "0.1.30-1"
            :entry "client/dialog/index.html"
            :served-dialog :identical-to-public-revision-and-npm-dialog
            :sha256 "5a513f70546ced3e2af7f83c4f14fb73d30e27f22a295558cbff4b078871aed8"))
    :public-code
    (:trails "trails() stores named graphs in this.aspect; trail() creates consecutive Trail relations."
     :mech "solo_emit maps state.aspect to {source: each.source || each.id, aspects: each.result}, then sends {type: 'batch', sources, pageKey} with postMessage."
     :solo-lines (48 52 53 54)
     :solo "beam.splice(0); for each source: source.aspects.forEach(aspect => aspect.label = source.source); beam.push(...source.aspects)."
     :render "Selecting both aspects invokes public Solo composite and dotify, then Graphviz layout.")
    :batch-capture
    (:observed-at "2026-10-04T08:41:15.950Z" :line 47
     :point "Solo MessageEvent.data before the first mutation"
     :method :debugger-breakpoint :serialization "JSON.stringify(event.data) while paused"
     :event-source-is-opener t :page-key "b845228c"
     :file "dreyeck/work/trails-rendered-solo-batch.json"
     :sha256 "ad24ef4944011180134858902e9f8041f501c3896a5cd0d48c33be3f757b5293")
    :beam-capture
    (:observed-at "2026-10-04T09:07:07.794Z" :line 55
     :point "Lexical beam after the source loop, before refreshBeam()"
     :method :paired-debugger-breakpoints-at-47-and-55
     :serialization "JSON.stringify(beam) while paused"
     :page-key "2cd273c5" :input-comparison :same-as-batch-except-page-key
     :input-sha256 "93933158d2a547093644fa5eb078ffd597aa2ec3378f28e34c43cf0d5165e08a"
     :file "dreyeck/work/trails-rendered-solo-beam.json"
     :sha256 "1225c651ef70d2271bbeecc72d41a1b2294846a2e19b3b2b1c06ab31ae33a6b1"
     :runtime-reference-checks
     (:same-beam-array t :same-aspect-objects (t t)
      :same-nested-objects (t t) :references-per-aspect (20 20)
      :graph-values-unchanged (t t)))
    :render-observation
    (:observed-at "2026-10-04T06:43:21.755Z" :chosen-aspects ("0" "1")
     :extraction "Rendered SVG node/edge titles and text labels, in DOM order"
     :witness "/Users/rgb/workspace/wiki-trails-rendered-local/runtime-evidence.json")
    :repeat
    (:wiki-artifact "/nix/store/155fjjd6pv29d8lwpzljmqpv4ifa44bg-wiki-0.39.1"
     :page "http://localhost:3477/view/trails-rendered"
     :dialog "http://localhost:3477/plugins/solo/dialog/"
     :procedure "Serve the saved source page with the identified public assets. Run CODE trails, open the named Solo dialog with the page as opener, and run the MECH SOLO action. Pause at dialog/index.html:47 to serialize event.data; at :55 serialize beam and compare retained references. Remove breakpoints, resume, and select trail 1 then trail 2 to inspect the rendered titles and labels."
     :plugin-source-changes nil
     :limit "graph.js and svg-pan-zoom were fetched unpinned at runtime; plugin revision alone does not freeze those dependencies. pageKey varies by browser load."
     :tests "nix develop .#tala --command sbcl --noinform --no-userinit --non-interactive --eval '(require :asdf)' --eval '(asdf:test-system \"dreyeck/work/reading/tests\")'")
    :hoverbold-capture
    (:file "dreyeck/work/trails-rendered-hoverbold-observation.json"
     :sha256 "888df20c4f6407623fcef06b6b5a7f61ecef4ee62358e12f85fbe52b0b3006e3")
    :boundary-evidence
    (:report (:url "https://ward.voices.ustawi.wiki/increment-of-progress.json"
              :paragraph-date "2026-10-02T18:49:24Z"
              :statement "Ward reports an experimental Solo popup deployed to localhost:3000.")
     :search (:date "2026-10-04" :lineage :public-plugins-above
              :mech (:scope (:all-branches :full-history :pull-1-through-6)
                     :terms ("getBBox" "g.node" "closest('g.node'" "layer" "interpret") :hits 0)
              :solo (:scope (:all-branches :full-history :pull-1 :npm-0.1.30-1)
                     :terms ("getBBox" "g.node" "Trace" "layer" "interpret") :hits 0)
              :served-dialog "next.ward.dojo.fed.wiki matched the public Solo dialog; no Trace/getBBox match.")))))

(defun read-observation (file)
  (with-open-file (stream (asdf:system-relative-pathname
                          "dreyeck/work/reading" file)
                         :external-format :utf-8)
    (shasht:read-json* :stream stream :single-value t
                      :object-format :hash-table :hash-table-test 'equal
                      :array-format :vector
                      :true-value :true :false-value :false :null-value :null)))

(defun read-capture (key)
  (read-observation (getf (gethash key *provenance*) :file)))

(hyperdoc:defexample solo-batch
  "Observed MessageEvent.data before Solo mutates it. Read the saved JSON,
not a reconstruction: fresh hash tables and vectors preserve every value."
  (read-capture :batch-capture))

(hyperdoc:defexample solo-beam
  "The already captured lexical beam, after the public source loop.
These independent JSON snapshots preserve values, not JavaScript aliases;
the runtime reference checks are in SOLO-BATCH-PROVENANCE."
  (read-capture :beam-capture))

(hyperdoc:defexample solo-batch-provenance
  "The shared provenance of this experiment: source and public assets,
capture points, runtime reference checks, repeat entry point and search scope."
  *provenance*)

(hyperdoc:defexample public-result
  "Observed rendered node/edge titles and labels when both trails were selected.
This is the recorded output, not a graph regenerated from the captured batch."
  (list :status :observed
        :nodes (copy-tree '(("2" "Reflective Practice") ("0" "Susan Kare")
                            ("1" "John Dewey") ("3" "Jean Lave") ("4" "Dorothy Smith")))
        :edges (copy-tree '(("0->1" "Trail") ("1->2" "Trail")
                            ("3->4" "Trail") ("4->2" "Trail")))
        :provenance (solo-batch-provenance)))

(hyperdoc:defexample interpretation-path
  "Derived structural summaries of the captured batch and recorded result.
No Solo transformation or renderer is reimplemented here."
  (let* ((batch (solo-batch))
         (trails (loop for source across (gethash "sources" batch)
                       append (loop for aspect across (gethash "aspects" source)
                                    for graph = (gethash "graph" aspect)
                                    collect (list :name (gethash "name" aspect)
                                                  :nodes (map 'list
                                                              (lambda (node)
                                                                (substitute #\Space #\Newline
                                                                            (gethash "name" (gethash "props" node))))
                                                              (gethash "nodes" graph))
                                                  :trail-relations (count "Trail" (gethash "rels" graph)
                                                                          :key (lambda (rel) (gethash "type" rel))
                                                                          :test #'equal)))))
         (names (mapcan (lambda (trail) (copy-list (getf trail :nodes))) trails))
         (result (public-result)))
    (list :status :derived :aspects (length trails) :trails trails
          :shared-node-names (remove-duplicates
                              (remove-if-not (lambda (name)
                                               (> (count-if (lambda (trail)
                                                              (member name (getf trail :nodes) :test #'equal))
                                                            trails) 1))
                                             names)
                              :test #'equal)
          :rendered-nodes (length (getf result :nodes))
          :rendered-trail-relations (count "Trail" (getf result :edges) :key #'second :test #'equal)
          :provenance (solo-batch-provenance))))

(hyperdoc:defexample public-source-boundary
  "Observed report and scoped negative search; the local unpublished change
is an inference. Its implementation was not observed or reconstructed."
  (let ((evidence (gethash :boundary-evidence (solo-batch-provenance))))
    (list :label "PUBLIC REPRODUCTION ENDS HERE."
          :report (getf evidence :report) :searched-public-sources (getf evidence :search)
          :finding "Trace/getBBox behaviour was not found in the searched public sources."
          :status :inferred
          :inference "Ward's reported later experiment appears to be a local Solo change; its precise source and behaviour remain unobserved."
          :falsified-by "A public revision in the identified lineage containing that operation."
          :provenance (solo-batch-provenance))))

(defun read-federated-context ()
  "Selected page contents and journal actions from the recovered Jan/Thompson JSON.
The page/link/fork/trail graph records observations; ordering and shared concept
names are derived below. Each inspection opens fresh objects. Causal influence
on Ward's Trail relation change is not established."
  (let* ((context (derive-federated-data
                   (read-observation "dreyeck/work/trails-rendered-federated-context.json")))
         (observed (gethash "observed" context))
         (links (gethash "links" observed))
         (forks (gethash "forks" observed))
         (change (gethash "relation-type-change" observed))
         (attribution (find "jan-dewey" links :key (lambda (link) (gethash "from" link))
                            :test #'equal))
         (names (loop for trail across (gethash "trails" observed)
                      append (coerce (gethash "nodes" trail) 'list)))
         (events (append (remove-if-not (lambda (link) (gethash "date" link))
                                       (coerce links 'list))
                         (coerce forks 'list) (list change))))
    (setf (gethash "derived" context)
          (alexandria:plist-hash-table
           (list "scope" "Temporal ordering and shared concepts."
                 "temporal-order" (coerce (sort events #'< :key (lambda (event) (gethash "date" event)))
                                          'vector)
                 "shared-concepts"
                 (coerce (remove-duplicates
                          (remove-if-not (lambda (name)
                                           (find name links :key (lambda (link) (gethash "target" link))
                                                            :test #'equal))
                                         names)
                          :test #'equal :from-end t)
                         'vector)
                 "jan-fork-after-ward-trail-change"
                 (if (> (gethash "date" (aref forks 0)) (gethash "date" change)) :true :false)
                 "jan-attribution-after-ward-trail-change"
                 (if (> (gethash "date" attribution) (gethash "date" change)) :true :false))
           :test 'equal))
    context))

(hyperdoc:see (hyperdoc:page "Solo hoverbold"))

(hyperdoc:defexample hoverbold-observation
  "Observed public Solo installation and trusted mouseenter/mouseleave execution.
The JSON contains actual node/edge DOM snapshots before, during and after hover,
computed stroke widths, source-function text and debugger-observed writes.
Edge grouping is derived from the observed title table. No SVG or hover effect
is reconstructed; each call reads fresh objects and arrays."
  (read-capture :hoverbold-capture))
