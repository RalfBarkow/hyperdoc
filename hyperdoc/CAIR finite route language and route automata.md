Below is the updated HyperDoc import design for the CAIR paper.

Source paper: **Schlamp et al. 2016, “CAIR: Using Formal Languages to Study Routing, Leaking, and Interception in BGP.”** The paper’s central move is to replace ordinary AS-level graph modeling with a finite route language and minimal deterministic route automata, because graph models falsely imply transitivity and lose policy context. CAIR preserves observed route diversity, supports incremental construction, and gives implementable search patterns for interception attacks and route leaks. 

---

# CAIR as route-language substrate

## 1. Canonical HyperDoc page

Create one durable page:

```text
hyperdoc/CAIR finite route language and route automata.html
```

Working title:

```text
CAIR finite route language and route automata
```

Purpose:

```text
This page imports Schlamp et al.’s CAIR model into HyperDoc as a technical precedent for route language: routes are not reducible to graph edges; route context, policy, observable path diversity, and anomaly patterns must remain inspectable.
```

Why this belongs in HyperDoc:

```text
CAIR is a strong external reference for HyperDoc’s own route-language work. It demonstrates that a “route language” can be formal, operational, and more expressive than a graph. For HyperDoc, the analogy is not BGP itself but the modeling lesson: associations should remain first-class topics with context, not anonymous edges.
```

---

# 2. Main reading result

## 2.1 The paper’s core claim

CAIR argues that BGP routes should not be modeled merely as a graph of AS nodes and links. A graph can represent observed connectivity, but it cannot preserve the policy-specific route context needed to explain leaks, interceptions, or nonuniform redistribution. The paper instead models observed BGP routes as a **finite route language** and builds **minimal deterministic route automata** over that language. 

HyperDoc import:

```text
A route is not just an edge.
A route is an accepted word in a route language.
A route-language view should preserve the context that makes the route valid.
```

HyperDoc translation:

```text
A HyperDoc association is not just a line between topics.
An association is a topic.
When presented in a route-language view, that association topic may play the route role.
```

---

## 2.2 Key diagram to import

The important figure is **Figure 2 on page 3**. It compares:

1. observed BGP routes,
2. a network graph,
3. a deterministic automaton,
4. a minimal automaton.

The figure shows the modeling failure directly: the graph collapses route context and implies paths that were not observed, while the automaton preserves the route language. 

HyperDoc interpretation:

```text
Use this as the visual anchor for the page:
“Graph edges lose route-language context; automata preserve accepted route words.”
```

---

## 2.3 Practical anomaly model

The paper derives an interception pattern using three tests:

1. **Artificiality** — a path segment appears in a single routing context.
2. **Nonuniformity** — that segment contradicts existing route redistribution.
3. **Interception alert** — the suspicious path leads to a subprefix of benign routes.

That pattern is directly expressed over the route automaton. 

HyperDoc import:

```text
A route-language system should support anomaly queries over first-class routes:
- Is this route context unique?
- Does this route contradict neighboring routes?
- Does this route point to a more specific or suspicious target?
```

---

# 3. HyperDoc topic cluster

Add a compact topic cluster. Do not over-import every BGP detail. Keep the cluster centered on route language, inspectable routes, automata, and operational anomaly detection.

## 3.1 Canonical topic

```lisp
(defun cair-finite-route-language-and-route-automata-topic ()
  (make-topic
   :id "cair-finite-route-language-and-route-automata"
   :title "CAIR finite route language and route automata"
   :summary "Schlamp et al.'s CAIR model represents observed BGP paths as a finite route language accepted by minimal deterministic route automata, preserving route diversity that ordinary graph models lose."
   :references '("CAIR finite route language and route automata"
                 "HyperDoc Route Language and Gesture Grammar"
                 "Iconic route language in HyperDoc"
                 "HyperDoc routing and navigation model")))
```

## 3.2 Supporting topics

```lisp
(defun finite-route-language-topic ()
  (make-topic
   :id "finite-route-language"
   :title "Finite route language"
   :summary "A finite route language treats observed routes as accepted words over an alphabet of routing symbols, preserving route context instead of collapsing it into graph connectivity."
   :references '("CAIR finite route language and route automata"
                 "CAIR: Using Formal Languages to Study Routing, Leaking, and Interception in BGP"
                 "HyperDoc Route Language and Gesture Grammar")))
```

```lisp
(defun route-automaton-topic ()
  (make-topic
   :id "route-automaton"
   :title "Route automaton"
   :summary "A route automaton is a minimal deterministic finite-state automaton that accepts the observed finite route language and exposes route diversity, equivalence classes, and anomaly patterns."
   :references '("CAIR finite route language and route automata"
                 "Finite route language"
                 "State machine")))
```

```lisp
(defun graph-transitivity-problem-topic ()
  (make-topic
   :id "graph-transitivity-problem"
   :title "Graph transitivity problem"
   :summary "A graph model can imply transitive reachability that was never observed, losing the route context needed to explain policy-based routing behavior."
   :references '("CAIR finite route language and route automata"
                 "Finite route language"
                 "HyperDoc Route Language and Gesture Grammar")))
```

```lisp
(defun route-diversity-topic ()
  (make-topic
   :id "route-diversity"
   :title "Route diversity"
   :summary "Route diversity is the preservation of distinct observed paths and their contexts, rather than flattening them into a single graph topology."
   :references '("CAIR finite route language and route automata"
                 "Route automaton"
                 "Graph transitivity problem")))
```

```lisp
(defun right-language-topic ()
  (make-topic
   :id "right-language"
   :title "Right language"
   :summary "In a route automaton, the right language of a state is the set of partial routes producible from that state, allowing equivalent routing behavior to be detected and minimized."
   :references '("CAIR finite route language and route automata"
                 "Route automaton"
                 "Finite route language")))
```

```lisp
(defun routing-dominance-topic ()
  (make-topic
   :id "routing-dominance"
   :title "Routing dominance"
   :summary "Routing dominance measures how much routing behavior is reachable through an AS in a route automaton, making sudden route leaks visible as abrupt changes in dominance."
   :references '("CAIR finite route language and route automata"
                 "Route automaton"
                 "Route leak detection")))
```

```lisp
(defun bgp-interception-pattern-topic ()
  (make-topic
   :id "bgp-interception-pattern"
   :title "BGP interception pattern"
   :summary "CAIR detects interception by searching route automata for artificial path segments, nonuniform redistribution, and subprefix hijacking evidence."
   :references '("CAIR finite route language and route automata"
                 "Route automaton"
                 "Route anomaly search pattern")))
```

```lisp
(defun route-leak-detection-topic ()
  (make-topic
   :id "route-leak-detection"
   :title "Route leak detection"
   :summary "Route leak detection in CAIR uses changes in routing dominance to identify originators, propagating upstreams, and affected ASes during abnormal routing shifts."
   :references '("CAIR finite route language and route automata"
                 "Routing dominance"
                 "Route anomaly search pattern")))
```

```lisp
(defun route-anomaly-search-pattern-topic ()
  (make-topic
   :id "route-anomaly-search-pattern"
   :title "Route anomaly search pattern"
   :summary "A route anomaly search pattern is an implementable query over route automata that detects contradictions, artificial path segments, or abnormal dominance changes."
   :references '("CAIR finite route language and route automata"
                 "BGP interception pattern"
                 "Route leak detection")))
```

---

# 4. HyperDoc operational definitions

## 4.1 Finite route language

```text
A finite route language is the set of observed route words accepted by a route model.

In CAIR, a route word is an AS path followed by a prefix.
In HyperDoc, the analogous idea is an accepted association path through topics and association topics.
```

HyperDoc consequence:

```text
Do not flatten route context into anonymous topic links.
Preserve the accepted path and its evidence.
```

---

## 4.2 Route automaton

```text
A route automaton is an inspectable state machine that accepts exactly the route words observed or constructed for a route language.
```

HyperDoc consequence:

```text
A route automaton can become a HyperDoc inspectable object:
- states are inspectable
- transitions are inspectable
- accepted route words are inspectable
- anomaly patterns are inspectable
```

---

## 4.3 Route anomaly search pattern

```text
A route anomaly search pattern is a named operation over a route automaton that detects a structurally meaningful condition.
```

Examples from CAIR:

```text
- artificial path segment
- nonuniform redistribution
- subprefix interception alert
- abrupt routing dominance shift
```

HyperDoc analogue:

```text
- suspicious association path
- conflicting association evidence
- orphaned association topic
- unexpected route dominance
- route-language contradiction
```

---

# 5. Proposed Lisp classes

This is a clean, HyperDoc-native object model. It is not a full implementation yet; it is the class vocabulary that would let the paper become inspectable.

```lisp
(defclass cair-paper ()
  ((title :initarg :title :reader cair-paper-title)
   (authors :initarg :authors :reader cair-paper-authors)
   (year :initarg :year :reader cair-paper-year)
   (doi :initarg :doi :reader cair-paper-doi)
   (source-path :initarg :source-path :reader cair-paper-source-path)))
```

```lisp
(defclass finite-route-language ()
  ((alphabet :initarg :alphabet :accessor route-language-alphabet)
   (routes :initarg :routes :accessor route-language-routes)
   (observation-points :initarg :observation-points
                       :accessor route-language-observation-points)
   (source :initarg :source :accessor route-language-source)))
```

```lisp
(defclass route-word ()
  ((path :initarg :path :accessor route-word-path)
   (target :initarg :target :accessor route-word-target)
   (source :initarg :source :accessor route-word-source)
   (metadata :initarg :metadata :initform nil :accessor route-word-metadata)))
```

```lisp
(defclass bgp-route-word (route-word)
  ((as-path :initarg :as-path :accessor bgp-route-as-path)
   (prefix :initarg :prefix :accessor bgp-route-prefix)))
```

```lisp
(defclass route-automaton ()
  ((states :initarg :states :accessor automaton-states)
   (transitions :initarg :transitions :accessor automaton-transitions)
   (start-state :initarg :start-state :accessor automaton-start-state)
   (accepting-states :initarg :accepting-states
                     :accessor automaton-accepting-states)
   (language :initarg :language :accessor automaton-language)))
```

```lisp
(defclass route-state ()
  ((id :initarg :id :reader route-state-id)
   (right-language :initarg :right-language
                   :accessor route-state-right-language)
   (metadata :initarg :metadata :initform nil :accessor route-state-metadata)))
```

```lisp
(defclass route-transition ()
  ((from :initarg :from :reader transition-from)
   (label :initarg :label :reader transition-label)
   (to :initarg :to :reader transition-to)
   (count :initarg :count :initform 1 :accessor transition-count)
   (metadata :initarg :metadata :initform nil :accessor transition-metadata)))
```

```lisp
(defclass route-automaton-construction-run ()
  ((input-routes :initarg :input-routes :accessor construction-input-routes)
   (automaton :initarg :automaton :accessor construction-automaton)
   (created-states :initarg :created-states :accessor construction-created-states)
   (created-transitions :initarg :created-transitions
                        :accessor construction-created-transitions)
   (minimized-p :initarg :minimized-p :accessor construction-minimized-p)
   (evidence :initarg :evidence :initform nil :accessor construction-evidence)))
```

```lisp
(defclass route-anomaly-pattern ()
  ((name :initarg :name :reader anomaly-pattern-name)
   (description :initarg :description :reader anomaly-pattern-description)
   (predicate :initarg :predicate :reader anomaly-pattern-predicate)))
```

```lisp
(defclass interception-pattern (route-anomaly-pattern)
  ((artificiality-test :initarg :artificiality-test
                       :accessor interception-artificiality-test)
   (nonuniformity-test :initarg :nonuniformity-test
                       :accessor interception-nonuniformity-test)
   (subprefix-test :initarg :subprefix-test
                   :accessor interception-subprefix-test)))
```

```lisp
(defclass route-leak-pattern (route-anomaly-pattern)
  ((dominance-metric :initarg :dominance-metric
                     :accessor route-leak-dominance-metric)
   (threshold :initarg :threshold :accessor route-leak-threshold)))
```

```lisp
(defclass route-anomaly-alert ()
  ((pattern :initarg :pattern :reader alert-pattern)
   (route-segment :initarg :route-segment :reader alert-route-segment)
   (evidence :initarg :evidence :reader alert-evidence)
   (status :initarg :status :initform :candidate :accessor alert-status)))
```

---

# 6. Proposed generic functions and operations

## 6.1 Language construction

```lisp
(defgeneric make-route-language (routes &key observation-points source))
```

Purpose:

```text
Construct a finite route language object from route words.
```

---

```lisp
(defgeneric route-language-routes-to-target (language target))
```

Purpose:

```text
Return all route words in a language that reach a given target.
```

---

```lisp
(defgeneric route-language-subset (language predicate))
```

Purpose:

```text
Produce a smaller route language by selecting accepted route words.
```

---

## 6.2 Automaton construction

```lisp
(defgeneric build-route-automaton (route-language &key minimize))
```

Purpose:

```text
Build a route automaton accepting the supplied finite route language.
```

---

```lisp
(defgeneric add-route-word (automaton route-word))
```

Purpose:

```text
Incrementally add a route word while preserving accepted-route semantics.
```

---

```lisp
(defgeneric remove-route-word (automaton route-word))
```

Purpose:

```text
Remove a route word from an automaton.
```

---

```lisp
(defgeneric minimize-route-automaton (automaton))
```

Purpose:

```text
Merge equivalent states by right-language equivalence.
```

---

```lisp
(defgeneric accepts-route-p (automaton route-word))
```

Purpose:

```text
Test whether the automaton accepts a route word.
```

---

## 6.3 State and transition inspection

```lisp
(defgeneric right-language-of (automaton state))
```

Purpose:

```text
Return the partial routes accepted from a state.
```

---

```lisp
(defgeneric outgoing-transitions (automaton state))
```

```lisp
(defgeneric incoming-transitions (automaton state))
```

```lisp
(defgeneric transition-labels (automaton state))
```

---

## 6.4 CAIR construction operations

The paper’s implementation algorithm has three operational steps: common path traversal, remaining route insertion, and on-the-fly minimization. 

```lisp
(defgeneric longest-common-path-segment (automaton route-word))
```

```lisp
(defgeneric clone-confluence-state (automaton state))
```

```lisp
(defgeneric insert-remaining-route-segment (automaton state route-suffix))
```

```lisp
(defgeneric minimize-backwards-from-route (automaton route-word))
```

```lisp
(defgeneric equivalent-route-state (automaton state))
```

---

## 6.5 Interception detection

```lisp
(defgeneric artificial-path-segment-p (automaton segment))
```

```lisp
(defgeneric nonuniform-redistribution-p (automaton segment))
```

```lisp
(defgeneric subprefix-interception-p (automaton victim-prefix candidate-prefix))
```

```lisp
(defgeneric detect-interception-alerts (automaton))
```

```lisp
(defgeneric locate-attacker-candidates (automaton alert))
```

Purpose:

```text
Represent the CAIR search pattern for interception attacks as named inspectable operations.
```

The paper’s detection pattern identifies candidate interception by combining artificiality, nonuniformity, and subprefix evidence. 

---

## 6.6 Route leak analysis

```lisp
(defgeneric routing-dominance (automaton symbol))
```

```lisp
(defgeneric routing-dominance-delta (before after symbol))
```

```lisp
(defgeneric detect-route-leak-alerts (before-automaton after-automaton &key threshold))
```

```lisp
(defgeneric route-leak-originator-candidates (alert))
```

```lisp
(defgeneric route-leak-propagator-candidates (alert))
```

Purpose:

```text
Expose CAIR’s route-leak analysis as HyperDoc operations over automaton snapshots.
```

The paper models routing dominance as reachability through automaton states and uses abrupt changes to analyze the Telekom Malaysia 2015 route leak. 

---

## 6.7 HyperDoc rendering operations

```lisp
(defgeneric render-route-language-summary (language stream))
```

```lisp
(defgeneric render-route-automaton-view (automaton stream &key focus-state))
```

```lisp
(defgeneric render-route-word-table (language stream))
```

```lisp
(defgeneric render-route-anomaly-alert (alert stream))
```

```lisp
(defgeneric render-cair-paper-crosswalk (paper stream))
```

---

# 7. HyperDoc page structure

Use this page outline.

```html
<h1>CAIR finite route language and route automata</h1>

<in-package>hyperdoc</in-package>

<h2>Why this paper matters for HyperDoc route language</h2>

<p>
  Schlamp et al. show that graph models lose route context: observed links do
  not imply all transitive paths. Their CAIR framework represents BGP paths as a
  finite route language accepted by minimal route automata. HyperDoc imports
  this as a route-language precedent: association topics should remain
  first-class, inspectable route objects rather than anonymous edges.
</p>

<h2>Inspectable objects</h2>

<ul>
  <li><a hyperbook="topics" page="CAIR finite route language and route automata"><tt>CAIR finite route language and route automata</tt></a></li>
  <li><a hyperbook="topics" page="Finite route language"><tt>Finite route language</tt></a></li>
  <li><a hyperbook="topics" page="Route automaton"><tt>Route automaton</tt></a></li>
  <li><a hyperbook="topics" page="Graph transitivity problem"><tt>Graph transitivity problem</tt></a></li>
  <li><a hyperbook="topics" page="Route diversity"><tt>Route diversity</tt></a></li>
  <li><a hyperbook="topics" page="Right language"><tt>Right language</tt></a></li>
  <li><a hyperbook="topics" page="BGP interception pattern"><tt>BGP interception pattern</tt></a></li>
  <li><a hyperbook="topics" page="Route leak detection"><tt>Route leak detection</tt></a></li>
</ul>

<h2>Core import</h2>

<p>
  CAIR treats observed routes as words in a finite route language. A route
  automaton accepts exactly those route words and preserves policy-relevant
  route diversity that ordinary graphs erase.
</p>

<h2>HyperDoc crosswalk</h2>

<table>
  <tr>
    <th>CAIR term</th>
    <th>HyperDoc import</th>
  </tr>
  <tr>
    <td>AS path</td>
    <td>Accepted route word</td>
  </tr>
  <tr>
    <td>Prefix</td>
    <td>Route target</td>
  </tr>
  <tr>
    <td>Finite route language</td>
    <td>Set of accepted route expressions</td>
  </tr>
  <tr>
    <td>Route automaton</td>
    <td>Inspectable state-machine representation of route context</td>
  </tr>
  <tr>
    <td>Route diversity</td>
    <td>Preserved distinction between association contexts</td>
  </tr>
  <tr>
    <td>Interception pattern</td>
    <td>Inspectable anomaly query over route objects</td>
  </tr>
</table>

<h2>Design consequence</h2>

<p>
  HyperDoc should not model routes as anonymous graph edges. Associations are
  topics. A route-language view may present association topics as routes, but
  the association itself remains first-class and inspectable.
</p>

<h2>Related pages</h2>

<ul>
  <li><a page="HyperDoc Route Language and Gesture Grammar">HyperDoc Route Language and Gesture Grammar</a></li>
  <li><a page="Iconic route language in HyperDoc">Iconic route language in HyperDoc</a></li>
  <li><a page="HyperDoc routing and navigation model">HyperDoc routing and navigation model</a></li>
  <li><a page="State machine">State machine</a></li>
  <li><a page="Inspectable iconic retrieval objects">Inspectable iconic retrieval objects</a></li>
</ul>
```

---

# 8. Crosswalk into HyperDoc route language

## CAIR route language → HyperDoc route language

```text
CAIR:
A route is a word accepted by a finite language.

HyperDoc:
A route presentation is an association topic viewed in a route role.
```

## CAIR route automaton → HyperDoc inspectable route object

```text
CAIR:
A route automaton preserves route diversity and policy context.

HyperDoc:
A route inspector should preserve association context, participant roles, evidence, and traversal behavior.
```

## CAIR graph critique → HyperDoc graph critique

```text
CAIR:
Graphs falsely imply transitivity and create nonexistent paths.

HyperDoc:
Naive topic graphs may falsely imply semantic equivalence or valid traversal where no authored association topic exists.
```

## CAIR anomaly search → HyperDoc anomaly search

```text
CAIR:
Interception and route leaks are detected as route-language anomalies.

HyperDoc:
Conflicting, orphaned, over-dominant, or provenance-poor associations can be detected as route-language anomalies.
```

---

# 9. Operations to add as HyperDoc concepts

These should become operational topics or examples, not necessarily implemented immediately.

```text
construct finite route language
build route automaton
minimize route automaton
inspect right language
detect artificial path segment
detect nonuniform redistribution
detect subprefix interception
compute routing dominance
detect route leak
render route automaton
compare graph model with route automaton
```

Each can become a small inspectable operation page later.

---

# 10. Minimal runtime seed, if implemented later

A very small executable slice could start with generic route words, independent of BGP:

```lisp
(defclass hyperdoc-route-word ()
  ((participants :initarg :participants :accessor route-word-participants)
   (target :initarg :target :accessor route-word-target)
   (association-topic :initarg :association-topic
                      :accessor route-word-association-topic)))
```

```lisp
(defclass hyperdoc-route-language ()
  ((route-words :initarg :route-words :accessor hyperdoc-route-words)))
```

```lisp
(defgeneric route-word->labels (route-word))
(defgeneric accepted-route-word-p (route-language route-word))
(defgeneric association-topic->route-word (association-topic))
```

This would let HyperDoc test the CAIR idea without importing BGP mechanics.

---

# 11. Recommended file changes for the actual HyperDoc slice

For a documentation-only slice:

```text
hyperdoc/CAIR finite route language and route automata.html
hyperdoc/topics.lisp
```

Optional if adding executable model vocabulary:

```text
hyperdoc/route-languages.lisp
tests/route-languages-smoke.lisp
hyperdoc.asd
```

Optional if adding inspector views:

```text
hyperdoc-inspector/route-languages.lisp
```

---

# 12. Commit shape

Suggested commit:

```text
docs(hyperdoc): import CAIR as route-language precedent
```

Scope:

```text
- add CAIR finite route language page
- add topic factories for CAIR route-language concepts
- cross-link to HyperDoc route-language documentation
- no runtime implementation unless explicitly chosen
```

---

The clean HyperDoc reading is:

> CAIR gives us a rigorous precedent for saying that routes are language objects, not just graph edges. For HyperDoc, this reinforces the rule that associations are topics, and that route views should preserve the semantics, evidence, and context of those association topics rather than flattening them into anonymous links.
