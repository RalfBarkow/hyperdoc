;;;; Repo-native authored source for the snippet-playground relation artifact
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defun snippet-playground-authored-source-role
    (&key id title summary kind binding participants findings)
  (list :id id
        :title title
        :summary summary
        :kind kind
        :binding binding
        :participants participants
        :findings findings))

(defun snippet-playground-authored-source-relation
    (&key id title summary layer subject predicate object attributes)
  (list :id id
        :title title
        :summary summary
        :layer layer
        :subject subject
        :predicate predicate
        :object object
        :attributes attributes))

(defun snippet-playground-authored-source-role-definitions ()
  (list
   (snippet-playground-authored-source-role
    :id "role/selected-mech-snippet"
    :title "Selected Mech snippet"
    :summary "Evidence input chosen from the origin surface."
    :kind :evidence-input
    :binding :selected-mech-snippet)
   (snippet-playground-authored-source-role
    :id "role/selected-javascript-snippet"
    :title "Selected JavaScript snippet"
    :summary "Executable evidence input chosen from the origin surface."
    :kind :evidence-input
    :binding :selected-javascript-snippet)
   (snippet-playground-authored-source-role
    :id "role/derived-lisp-snippet"
    :title "Derived Lisp snippet"
    :summary "Rita-side scaffold derived from the selected evidence and interface."
    :kind :derived-output
    :binding :derived-lisp-snippet)
   (snippet-playground-authored-source-role
    :id "role/transformation-unit"
    :title "Transformation unit"
    :summary "Primary semantic artifact that binds evidence to the execution interface."
    :kind :semantic-artifact
    :binding :transformation-unit)
   (snippet-playground-authored-source-role
    :id "role/execution-interface"
    :title "Execution interface"
    :summary "Operational handoff such as state.items."
    :kind :semantic-artifact
    :binding :execution-interface)
   (snippet-playground-authored-source-role
    :id "role/lefty-pair"
    :title "Lefty pair"
    :summary "Representational pair combining Mech with JavaScript."
    :kind :comparison-pair
    :binding :lefty-pair
    :participants '(:selected-mech-snippet :selected-javascript-snippet))
   (snippet-playground-authored-source-role
    :id "role/rita-pair"
    :title "Rita pair"
    :summary "Representational pair combining Mech with Lisp."
    :kind :comparison-pair
    :binding :rita-pair
    :participants '(:selected-mech-snippet :derived-lisp-snippet))))

(defun snippet-playground-authored-source-relation-definitions ()
  (list
   (snippet-playground-authored-source-relation
    :id "semantic/evidence/mech"
    :title "Snippet evidence -> Mech"
    :summary "Snippet-playground gathers Mech evidence."
    :layer :semantic
    :subject :snippet-playground
    :predicate :uses-evidence
    :object :mech-snippet)
   (snippet-playground-authored-source-relation
    :id "semantic/evidence/code"
    :title "Snippet evidence -> Code"
    :summary "Snippet-playground gathers code evidence."
    :layer :semantic
    :subject :snippet-playground
    :predicate :uses-evidence
    :object :code-snippet)
   (snippet-playground-authored-source-relation
    :id "semantic/interface"
    :title "Snippet infers execution interface"
    :summary "Execution interface is inferred from Mech + code evidence."
    :layer :semantic
    :subject :snippet-playground
    :predicate :infers
    :object :snippet-execution-interface)
   (snippet-playground-authored-source-relation
    :id "semantic/transformation-unit"
    :title "Snippet constructs transformation unit"
    :summary "Transformation unit is the primary semantic artifact."
    :layer :semantic
    :subject :snippet-playground
    :predicate :constructs
    :object :snippet-transformation-unit)
   (snippet-playground-authored-source-relation
    :id "semantic/transformation-unit/lefty"
    :title "Transformation unit -> Lefty"
    :summary "Transformation unit exposes the Lefty projection."
    :layer :semantic
    :subject :snippet-transformation-unit
    :predicate :projects-to
    :object :lefty)
   (snippet-playground-authored-source-relation
    :id "semantic/transformation-unit/rita"
    :title "Transformation unit -> Rita"
    :summary "Transformation unit exposes the Rita projection."
    :layer :semantic
    :subject :snippet-transformation-unit
    :predicate :projects-to
    :object :rita)
   (snippet-playground-authored-source-relation
    :id "projection/behavior"
    :title "Compiled behavior projection"
    :summary "Authored snippet relations compile into a lifecycle machine."
    :layer :projection
    :subject :snippet-playground
    :predicate :projects-to
    :object :snippet_playground_run)
   (snippet-playground-authored-source-relation
    :id "projection/layout"
    :title "Compiled layout projection"
    :summary "Authored layout relations compile into a comparison layout spec."
    :layer :projection
    :subject :snippet-playground
    :predicate :projects-to
    :object :snippet-comparison-layout)
   (snippet-playground-authored-source-relation
    :id "behavior/run/state/unavailable"
    :title "State unavailable"
    :summary "Snippet capability is hidden."
    :layer :behavior
    :subject :snippet-playground-run
    :predicate :has-state
    :object :unavailable
    :attributes
    '(:title "unavailable"
      :summary "Snippet capability is hidden because the current pane does not expose a snippet provider."))
   (snippet-playground-authored-source-relation
    :id "behavior/run/state/available"
    :title "State available"
    :summary "Snippet capability is visible."
    :layer :behavior
    :subject :snippet-playground-run
    :predicate :has-state
    :object :available
    :attributes
    '(:title "available"
      :summary "Snippet capability is visible on the origin pane."))
   (snippet-playground-authored-source-relation
    :id "behavior/run/state/invoked"
    :title "State invoked"
    :summary "Snippet was clicked."
    :layer :behavior
    :subject :snippet-playground-run
    :predicate :has-state
    :object :invoked
    :attributes
    '(:title "invoked"
      :summary "The user clicked Snippet on the origin pane."))
   (snippet-playground-authored-source-relation
    :id "behavior/run/state/pending"
    :title "State pending"
    :summary "Pending pane is visible."
    :layer :behavior
    :subject :snippet-playground-run
    :predicate :has-state
    :object :pending
    :attributes
    '(:title "pending"
      :summary "A pending pane has opened to the right of the origin pane."))
   (snippet-playground-authored-source-relation
    :id "behavior/run/state/collecting-input"
    :title "State collecting_input"
    :summary "Collecting provider input."
    :layer :behavior
    :subject :snippet-playground-run
    :predicate :has-state
    :object :collecting-input
    :attributes
    '(:title "collecting_input"
      :summary "Provider-specific snippet input is being collected."))
   (snippet-playground-authored-source-relation
    :id "behavior/run/state/recognizing"
    :title "State recognizing"
    :summary "Recognizing snippets."
    :layer :behavior
    :subject :snippet-playground-run
    :predicate :has-state
    :object :recognizing
    :attributes
    '(:title "recognizing"
      :summary "Mech and code snippets are being recognized."))
   (snippet-playground-authored-source-relation
    :id "behavior/run/state/pairing"
    :title "State pairing"
    :summary "Selecting evidential inputs."
    :layer :behavior
    :subject :snippet-playground-run
    :predicate :has-state
    :object :pairing
    :attributes
    '(:title "pairing"
      :summary "Recognized Mech/code evidence is being selected before semantic binding."))
   (snippet-playground-authored-source-relation
    :id "behavior/run/state/building-session"
    :title "State building_session"
    :summary "Building the session."
    :layer :behavior
    :subject :snippet-playground-run
    :predicate :has-state
    :object :building-session
    :attributes
    '(:title "building_session"
      :summary "The inspectable snippet-playground session is being built."))
   (snippet-playground-authored-source-relation
    :id "behavior/run/state/ready"
    :title "State ready"
    :summary "Ready pane replaced pending."
    :layer :behavior
    :subject :snippet-playground-run
    :predicate :has-state
    :object :ready
    :attributes
    '(:title "ready"
      :summary "Pending pane has been replaced in place by a ready snippet session."))
   (snippet-playground-authored-source-relation
    :id "behavior/run/state/failed"
    :title "State failed"
    :summary "Failure replaced pending."
    :layer :behavior
    :subject :snippet-playground-run
    :predicate :has-state
    :object :failed
    :attributes
    '(:title "failed"
      :summary "Pending pane has been replaced by an inspectable failure object."))
   (snippet-playground-authored-source-relation
    :id "behavior/run/initial"
    :title "Initial run state"
    :summary "State machine initial state."
    :layer :behavior
    :subject :snippet-playground-run
    :predicate :initial-state
    :object :unavailable)
   (snippet-playground-authored-source-relation
    :id "behavior/run/terminal/ready"
    :title "Terminal ready"
    :summary "Ready is terminal."
    :layer :behavior
    :subject :snippet-playground-run
    :predicate :terminal-state
    :object :ready)
   (snippet-playground-authored-source-relation
    :id "behavior/run/terminal/failed"
    :title "Terminal failed"
    :summary "Failed is terminal."
    :layer :behavior
    :subject :snippet-playground-run
    :predicate :terminal-state
    :object :failed)
   (snippet-playground-authored-source-relation
    :id "behavior/run/failure/failed"
    :title "Failure failed"
    :summary "Failed is a failure state."
    :layer :behavior
    :subject :snippet-playground-run
    :predicate :failure-state
    :object :failed)
   (snippet-playground-authored-source-relation
    :id "behavior/run/guard/provider"
    :title "Guard pane-supports-snippet-provider"
    :summary "Origin pane supports a snippet provider."
    :layer :behavior
    :subject :snippet-playground-run
    :predicate :has-guard
    :object :pane-supports-snippet-provider)
   (snippet-playground-authored-source-relation
    :id "behavior/run/guard/input"
    :title "Guard input-extracted"
    :summary "Input was extracted."
    :layer :behavior
    :subject :snippet-playground-run
    :predicate :has-guard
    :object :input-extracted)
   (snippet-playground-authored-source-relation
    :id "behavior/run/guard/candidates"
    :title "Guard candidates-found"
    :summary "Snippet candidates were recognized."
    :layer :behavior
    :subject :snippet-playground-run
    :predicate :has-guard
    :object :candidates-found)
   (snippet-playground-authored-source-relation
    :id "behavior/run/guard/valid-pair"
    :title "Guard valid-pair"
    :summary "Evidential Mech + code pair is valid."
    :layer :behavior
    :subject :snippet-playground-run
    :predicate :has-guard
    :object :valid-pair)
   (snippet-playground-authored-source-relation
    :id "behavior/run/event/snippet-click"
    :title "Event snippet-click"
    :summary "User clicked Snippet."
    :layer :behavior
    :subject :snippet-playground-run
    :predicate :has-event
    :object :snippet-click)
   (snippet-playground-authored-source-relation
    :id "behavior/run/event/open-pending-pane"
    :title "Event open-pending-pane"
    :summary "Pending pane was opened."
    :layer :behavior
    :subject :snippet-playground-run
    :predicate :has-event
    :object :open-pending-pane)
   (snippet-playground-authored-source-relation
    :id "behavior/run/event/pending-pane-opened"
    :title "Event pending-pane-opened"
    :summary "Pending pane is visible."
    :layer :behavior
    :subject :snippet-playground-run
    :predicate :has-event
    :object :pending-pane-opened)
   (snippet-playground-authored-source-relation
    :id "behavior/run/event/input-collected"
    :title "Event input-collected"
    :summary "Provider input was collected."
    :layer :behavior
    :subject :snippet-playground-run
    :predicate :has-event
    :object :input-collected)
   (snippet-playground-authored-source-relation
    :id "behavior/run/event/snippets-recognized"
    :title "Event snippets-recognized"
    :summary "Snippet candidates were recognized."
    :layer :behavior
    :subject :snippet-playground-run
    :predicate :has-event
    :object :snippets-recognized)
   (snippet-playground-authored-source-relation
    :id "behavior/run/event/pair-selected"
    :title "Event pair-selected"
    :summary "Mech + code evidence pair was selected."
    :layer :behavior
    :subject :snippet-playground-run
    :predicate :has-event
    :object :pair-selected)
   (snippet-playground-authored-source-relation
    :id "behavior/run/event/transformation-unit-built"
    :title "Event transformation-unit-built"
    :summary "Transformation unit was built into a session."
    :layer :behavior
    :subject :snippet-playground-run
    :predicate :has-event
    :object :transformation-unit-built)
   (snippet-playground-authored-source-relation
    :id "behavior/run/event/input-collection-failed"
    :title "Event input-collection-failed"
    :summary "Input collection failed."
    :layer :behavior
    :subject :snippet-playground-run
    :predicate :has-event
    :object :input-collection-failed)
   (snippet-playground-authored-source-relation
    :id "behavior/run/event/recognition-failed"
    :title "Event recognition-failed"
    :summary "Recognition failed."
    :layer :behavior
    :subject :snippet-playground-run
    :predicate :has-event
    :object :recognition-failed)
   (snippet-playground-authored-source-relation
    :id "behavior/run/event/pairing-failed"
    :title "Event pairing-failed"
    :summary "Pairing failed."
    :layer :behavior
    :subject :snippet-playground-run
    :predicate :has-event
    :object :pairing-failed)
   (snippet-playground-authored-source-relation
    :id "behavior/run/event/session-build-failed"
    :title "Event session-build-failed"
    :summary "Session build failed."
    :layer :behavior
    :subject :snippet-playground-run
    :predicate :has-event
    :object :session-build-failed)
   (snippet-playground-authored-source-relation
    :id "behavior/run/transition/unavailable-available"
    :title "Transition unavailable -> available"
    :summary "Snippet capability becomes visible."
    :layer :behavior
    :subject :unavailable
    :predicate :transition-to
    :object :available
    :attributes
    '(:machine :snippet-playground-run
      :id "snippet/unavailable->available"
      :guard :pane-supports-snippet-provider
      :side-effects
      "Show Snippet in the capability row for html-source and fedwiki-page surfaces."))
   (snippet-playground-authored-source-relation
    :id "behavior/run/transition/available-invoked"
    :title "Transition available -> invoked"
    :summary "Snippet is clicked."
    :layer :behavior
    :subject :available
    :predicate :transition-to
    :object :invoked
    :attributes
    '(:machine :snippet-playground-run
      :id "snippet/available->invoked"
      :trigger :snippet-click))
   (snippet-playground-authored-source-relation
    :id "behavior/run/transition/invoked-pending"
    :title "Transition invoked -> pending"
    :summary "Pending pane opens."
    :layer :behavior
    :subject :invoked
    :predicate :transition-to
    :object :pending
    :attributes
    '(:machine :snippet-playground-run
      :id "snippet/invoked->pending"
      :trigger :open-pending-pane
      :side-effects
      "Open a pending pane to the right of the origin pane and retain the origin-pane placement invariant."))
   (snippet-playground-authored-source-relation
    :id "behavior/run/transition/pending-collecting"
    :title "Transition pending -> collecting-input"
    :summary "Pending pane is ready for collection."
    :layer :behavior
    :subject :pending
    :predicate :transition-to
    :object :collecting-input
    :attributes
    '(:machine :snippet-playground-run
      :id "snippet/pending->collecting-input"
      :trigger :pending-pane-opened))
   (snippet-playground-authored-source-relation
    :id "behavior/run/transition/collecting-recognizing"
    :title "Transition collecting-input -> recognizing"
    :summary "Collected input moves into recognition."
    :layer :behavior
    :subject :collecting-input
    :predicate :transition-to
    :object :recognizing
    :attributes
    '(:machine :snippet-playground-run
      :id "snippet/collecting-input->recognizing"
      :trigger :input-collected
      :guard :input-extracted))
   (snippet-playground-authored-source-relation
    :id "behavior/run/transition/recognizing-pairing"
    :title "Transition recognizing -> pairing"
    :summary "Recognized snippets move into pairing."
    :layer :behavior
    :subject :recognizing
    :predicate :transition-to
    :object :pairing
    :attributes
    '(:machine :snippet-playground-run
      :id "snippet/recognizing->pairing"
      :trigger :snippets-recognized
      :guard :candidates-found))
   (snippet-playground-authored-source-relation
    :id "behavior/run/transition/pairing-building"
    :title "Transition pairing -> building-session"
    :summary "Selected evidence builds a session."
    :layer :behavior
    :subject :pairing
    :predicate :transition-to
    :object :building-session
    :attributes
    '(:machine :snippet-playground-run
      :id "snippet/pairing->building-session"
      :trigger :pair-selected
      :guard :valid-pair))
   (snippet-playground-authored-source-relation
    :id "behavior/run/transition/building-ready"
    :title "Transition building-session -> ready"
    :summary "Transformation unit becomes a ready session."
    :layer :behavior
    :subject :building-session
    :predicate :transition-to
    :object :ready
    :attributes
    '(:machine :snippet-playground-run
      :id "snippet/building-session->ready"
      :trigger :transformation-unit-built))
   (snippet-playground-authored-source-relation
    :id "behavior/run/transition/collecting-failed"
    :title "Transition collecting-input -> failed"
    :summary "Collection failure."
    :layer :behavior
    :subject :collecting-input
    :predicate :transition-to
    :object :failed
    :attributes
    '(:machine :snippet-playground-run
      :id "snippet/collecting-input->failed"
      :trigger :input-collection-failed))
   (snippet-playground-authored-source-relation
    :id "behavior/run/transition/recognizing-failed"
    :title "Transition recognizing -> failed"
    :summary "Recognition failure."
    :layer :behavior
    :subject :recognizing
    :predicate :transition-to
    :object :failed
    :attributes
    '(:machine :snippet-playground-run
      :id "snippet/recognizing->failed"
      :trigger :recognition-failed))
   (snippet-playground-authored-source-relation
    :id "behavior/run/transition/pairing-failed"
    :title "Transition pairing -> failed"
    :summary "Pairing failure."
    :layer :behavior
    :subject :pairing
    :predicate :transition-to
    :object :failed
    :attributes
    '(:machine :snippet-playground-run
      :id "snippet/pairing->failed"
      :trigger :pairing-failed))
   (snippet-playground-authored-source-relation
    :id "behavior/run/transition/building-failed"
    :title "Transition building-session -> failed"
    :summary "Session build failure."
    :layer :behavior
    :subject :building-session
    :predicate :transition-to
    :object :failed
    :attributes
    '(:machine :snippet-playground-run
      :id "snippet/building-session->failed"
      :trigger :session-build-failed))
   (snippet-playground-authored-source-relation
    :id "behavior/run/invariant/placement"
    :title "Invariant result pane placement"
    :summary "Result pane opens right-of the origin."
    :layer :behavior
    :subject :snippet-playground-run
    :predicate :has-invariant
    :object "Result pane placement"
    :attributes
    '(:detail "The result pane is always created to the right of the pane that initiated Snippet."))
   (snippet-playground-authored-source-relation
    :id "behavior/run/invariant/shared-lifecycle"
    :title "Invariant shared lifecycle"
    :summary "Source and FedWiki share the same machine."
    :layer :behavior
    :subject :snippet-playground-run
    :predicate :has-invariant
    :object "Shared lifecycle"
    :attributes
    '(:detail "The same run states apply to html-source and fedwiki-page providers."))
   (snippet-playground-authored-source-relation
    :id "behavior/run/invariant/failure"
    :title "Invariant inspectable failure"
    :summary "Failures are inspectable."
    :layer :behavior
    :subject :snippet-playground-run
    :predicate :has-invariant
    :object "Inspectable failure"
    :attributes
    '(:detail "Malformed or unsupported input resolves to an inspectable failure object rather than a silent failure."))
   (snippet-playground-authored-source-relation
    :id "behavior/run/source-evidence/browser"
    :title "Browser source evidence"
    :summary "Browser capability wiring."
    :layer :behavior
    :subject :snippet-playground-run
    :predicate :source-evidence
    :object "assets/hyperdoc/js/dom-annotation-connect.js"
    :attributes
    '(:layer "browser"
      :detail "Capability visibility and invocation reuse the existing pane-shell submit bridge."))
   (snippet-playground-authored-source-relation
    :id "behavior/run/source-evidence/server"
    :title "Server source evidence"
    :summary "Pending-pane replacement wiring."
    :layer :behavior
    :subject :snippet-playground-run
    :predicate :source-evidence
    :object "hyperbook-server/inspector-wiring.lisp"
    :attributes
    '(:layer "server"
      :detail "Pending panes open to the right of the origin pane and are replaced in place."))
   (snippet-playground-authored-source-relation
    :id "behavior/run/source-evidence/provider"
    :title "Provider source evidence"
    :summary "Provider-aware target dispatch."
    :layer :behavior
    :subject :snippet-playground-run
    :predicate :source-evidence
    :object "hyperdoc-explorer/dom-annotations.lisp"
    :attributes
    '(:layer "provider"
      :detail "html-source and fedwiki-page surfaces both dispatch through provider-aware snippet targets."))
   (snippet-playground-authored-source-relation
    :id "behavior/run/source-evidence/session"
    :title "Session source evidence"
    :summary "Session construction logic."
    :layer :behavior
    :subject :snippet-playground-run
    :predicate :source-evidence
    :object "hyperdoc-inspector/snippet-playground.lisp"
    :attributes
    '(:layer "session"
      :detail "Recognition, evidence selection, session construction, and failure objects all share the same run definition."))
   (snippet-playground-authored-source-relation
    :id "behavior/comparison/state/available"
    :title "Comparison state available"
    :summary "Comparison surface can be built."
    :layer :behavior
    :subject :snippet-comparison-surface
    :predicate :has-state
    :object :available
    :attributes
    '(:title "available"
      :summary "Comparison surface can be built from the selected snippet evidence."))
   (snippet-playground-authored-source-relation
    :id "behavior/comparison/state/pending"
    :title "Comparison state pending"
    :summary "Comparison surface is pending."
    :layer :behavior
    :subject :snippet-comparison-surface
    :predicate :has-state
    :object :pending
    :attributes
    '(:title "pending"
      :summary "Pending pane is visible to the right of the origin pane."))
   (snippet-playground-authored-source-relation
    :id "behavior/comparison/state/ready"
    :title "Comparison state ready"
    :summary "Comparison surface is ready."
    :layer :behavior
    :subject :snippet-comparison-surface
    :predicate :has-state
    :object :ready
    :attributes
    '(:title "ready"
      :summary "Pending pane was replaced in place by a ready comparison surface."))
   (snippet-playground-authored-source-relation
    :id "behavior/comparison/state/failed"
    :title "Comparison state failed"
    :summary "Comparison surface failed."
    :layer :behavior
    :subject :snippet-comparison-surface
    :predicate :has-state
    :object :failed
    :attributes
    '(:title "failed"
      :summary "Pending pane was replaced in place by an inspectable failed comparison surface."))
   (snippet-playground-authored-source-relation
    :id "behavior/comparison/initial"
    :title "Comparison initial state"
    :summary "Comparison machine initial state."
    :layer :behavior
    :subject :snippet-comparison-surface
    :predicate :initial-state
    :object :available)
   (snippet-playground-authored-source-relation
    :id "behavior/comparison/terminal/ready"
    :title "Comparison terminal ready"
    :summary "Ready is terminal."
    :layer :behavior
    :subject :snippet-comparison-surface
    :predicate :terminal-state
    :object :ready)
   (snippet-playground-authored-source-relation
    :id "behavior/comparison/terminal/failed"
    :title "Comparison terminal failed"
    :summary "Failed is terminal."
    :layer :behavior
    :subject :snippet-comparison-surface
    :predicate :terminal-state
    :object :failed)
   (snippet-playground-authored-source-relation
    :id "behavior/comparison/failure/failed"
    :title "Comparison failure state"
    :summary "Failed is a failure state."
    :layer :behavior
    :subject :snippet-comparison-surface
    :predicate :failure-state
    :object :failed)
   (snippet-playground-authored-source-relation
    :id "behavior/comparison/event/open-pending-pane"
    :title "Comparison event open-pending-pane"
    :summary "Comparison pending pane opens."
    :layer :behavior
    :subject :snippet-comparison-surface
    :predicate :has-event
    :object :open-pending-pane)
   (snippet-playground-authored-source-relation
    :id "behavior/comparison/event/comparison-built"
    :title "Comparison event comparison-built"
    :summary "Comparison was built."
    :layer :behavior
    :subject :snippet-comparison-surface
    :predicate :has-event
    :object :comparison-built)
   (snippet-playground-authored-source-relation
    :id "behavior/comparison/event/comparison-failed"
    :title "Comparison event comparison-failed"
    :summary "Comparison failed."
    :layer :behavior
    :subject :snippet-comparison-surface
    :predicate :has-event
    :object :comparison-failed)
   (snippet-playground-authored-source-relation
    :id "behavior/comparison/transition/available-pending"
    :title "Comparison transition available -> pending"
    :summary "Comparison pending opens."
    :layer :behavior
    :subject :available
    :predicate :transition-to
    :object :pending
    :attributes
    '(:machine :snippet-comparison-surface
      :id "comparison/available->pending"
      :trigger :open-pending-pane
      :side-effects
      "Open a pending pane to the right of the origin pane."))
   (snippet-playground-authored-source-relation
    :id "behavior/comparison/transition/pending-ready"
    :title "Comparison transition pending -> ready"
    :summary "Comparison replaces pending."
    :layer :behavior
    :subject :pending
    :predicate :transition-to
    :object :ready
    :attributes
    '(:machine :snippet-comparison-surface
      :id "comparison/pending->ready"
      :trigger :comparison-built
      :side-effects
      "Replace the pending pane in place with the ready comparison surface."))
   (snippet-playground-authored-source-relation
    :id "behavior/comparison/transition/pending-failed"
    :title "Comparison transition pending -> failed"
    :summary "Failed comparison replaces pending."
    :layer :behavior
    :subject :pending
    :predicate :transition-to
    :object :failed
    :attributes
    '(:machine :snippet-comparison-surface
      :id "comparison/pending->failed"
      :trigger :comparison-failed
      :side-effects
      "Replace the pending pane in place with an inspectable failure surface."))
   (snippet-playground-authored-source-relation
    :id "behavior/comparison/invariant/placement"
    :title "Comparison invariant placement"
    :summary "Comparison result remains right-of origin."
    :layer :behavior
    :subject :snippet-comparison-surface
    :predicate :has-invariant
    :object "Placement invariant"
    :attributes
    '(:detail "Result pane remains to the right of the pane that initiated Snippet."))
   (snippet-playground-authored-source-relation
    :id "behavior/comparison/invariant/pending"
    :title "Comparison invariant pending replacement"
    :summary "Pending is replaced in place."
    :layer :behavior
    :subject :snippet-comparison-surface
    :predicate :has-invariant
    :object "Pending replacement"
    :attributes
    '(:detail "Ready and failed surfaces both replace the pending pane in place."))
   (snippet-playground-authored-source-relation
    :id "behavior/comparison/source-evidence/session"
    :title "Comparison source evidence"
    :summary "Comparison layout and lifecycle are session-backed."
    :layer :behavior
    :subject :snippet-comparison-surface
    :predicate :source-evidence
    :object "hyperdoc-inspector/snippet-playground.lisp"
    :attributes
    '(:layer "session"
      :detail "Comparison surface layout and lifecycle are carried separately from the primary snippet run state machine."))
   (snippet-playground-authored-source-relation
    :id "layout/result/right-of"
    :title "Result pane right-of origin pane"
    :summary "Result pane opens right-of the origin pane."
    :layer :layout
    :subject :result-pane
    :predicate :right-of
    :object :origin-pane)
   (snippet-playground-authored-source-relation
    :id "layout/ready/replaces"
    :title "Ready pane replaces pending pane"
    :summary "Ready pane replaces pending in place."
    :layer :layout
    :subject :ready-pane
    :predicate :replaces
    :object :pending-pane)
   (snippet-playground-authored-source-relation
    :id "layout/failed/replaces"
    :title "Failed pane replaces pending pane"
    :summary "Failed pane replaces pending in place."
    :layer :layout
    :subject :failed-pane
    :predicate :replaces
    :object :pending-pane)
   (snippet-playground-authored-source-relation
    :id "layout/comparison/left"
    :title "Comparison contains Lefty JavaScript"
    :summary "Comparison pane contains JavaScript on the left."
    :layer :layout
    :subject :comparison-pane
    :predicate :contains-left
    :object :lefty-javascript)
   (snippet-playground-authored-source-relation
    :id "layout/comparison/center"
    :title "Comparison contains shared Mech"
    :summary "Comparison pane contains shared Mech in the center."
    :layer :layout
    :subject :comparison-pane
    :predicate :contains-center
    :object :shared-mech)
   (snippet-playground-authored-source-relation
    :id "layout/comparison/right"
    :title "Comparison contains Rita Lisp"
    :summary "Comparison pane contains Lisp on the right."
    :layer :layout
    :subject :comparison-pane
    :predicate :contains-right
    :object :rita-lisp)
   (snippet-playground-authored-source-relation
    :id "layout/comparison/shared-mech-above-left"
    :title "Shared Mech above JavaScript"
    :summary "Shared Mech appears above the JavaScript region."
    :layer :layout
    :subject :shared-mech
    :predicate :above
    :object :lefty-javascript)
   (snippet-playground-authored-source-relation
    :id "layout/comparison/shared-mech-above-right"
    :title "Shared Mech above Lisp"
    :summary "Shared Mech appears above the Lisp region."
    :layer :layout
    :subject :shared-mech
    :predicate :above
    :object :rita-lisp)
   (snippet-playground-authored-source-relation
    :id "layout/comparison/show-once"
    :title "Comparison shows shared Mech once"
    :summary "Shared Mech renders once above the code comparison."
    :layer :layout
    :subject :comparison-pane
    :predicate :show-once
    :object :shared-mech)
   (snippet-playground-authored-source-relation
    :id "layout/projection/lefty"
    :title "Lefty renders JavaScript"
    :summary "Lefty projection renders JavaScript on the left."
    :layer :layout
    :subject :lefty-javascript
    :predicate :renders
    :object :javascript-code
    :attributes '(:title "JavaScript"
                  :region left-code-region
                  :placement :left))
   (snippet-playground-authored-source-relation
    :id "layout/projection/shared-mech"
    :title "Shared Mech renders once above the split"
    :summary "Shared Mech renders once above JavaScript and Lisp."
    :layer :layout
    :subject :shared-mech
    :predicate :renders
    :object :shared-mech
    :attributes '(:title "Mech"
                  :region shared-mech-region
                  :placement :center))
   (snippet-playground-authored-source-relation
    :id "layout/projection/rita"
    :title "Rita renders Lisp"
    :summary "Rita projection renders Lisp on the right."
    :layer :layout
    :subject :rita-lisp
    :predicate :renders
    :object :lisp-code
    :attributes '(:title "Lisp"
                  :region right-code-region
                  :placement :right))))

(defun snippet-playground-authored-source-findings ()
  '("Authored source lives in a repo-native reconstruction file, outside feature-local runtime construction."
    "Runtime rebuilds the authored artifact before compiling behavior and layout."
    "Lefty/Rita remain representational pairs; transformation unit remains the primary semantic artifact."))

(defun make-snippet-playground-authored-source-artifact ()
  (make-authored-relation-artifact-source
   :id "source/snippet-playground-authored-artifact"
   :title "Snippet playground authored source artifact"
   :summary "Repo-native authored source for the snippet-playground relation artifact."
   :source-kind :repo-native-lisp
   :source-path "hyperdoc-inspector/snippet-playground-authored-source.lisp"
   :schema-version 1
   :artifact-id "snippet-playground-authored-artifact"
   :artifact-title "Snippet playground authored relation artifact"
   :artifact-summary
   "Authored relation artifact that compiles into snippet-playground behavior and layout artifacts."
   :workflow-role
   "Graph-authored reconstruction surface for snippet-playground."
   :compiler-pipeline
   "repo-native authored source -> authored relation artifact -> compiled behavior artifact + compiled layout artifact -> runtime snippet-playground UI"
   :semantic-role-definitions
   (snippet-playground-authored-source-role-definitions)
   :relation-definitions
   (snippet-playground-authored-source-relation-definitions)
   :compiled-targets
   '("snippet-playground-behavior-artifact"
     "snippet-playground-layout-artifact")
   :findings (snippet-playground-authored-source-findings)))

(defparameter *snippet-playground-authored-source-artifact*
  (make-snippet-playground-authored-source-artifact))

(defun snippet-playground-authored-source-artifact ()
  *snippet-playground-authored-source-artifact*)
