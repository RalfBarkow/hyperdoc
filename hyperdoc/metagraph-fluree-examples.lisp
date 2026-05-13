;;;; Metagraph JSON-LD and Fluree examples
;;;; Drop into hyperdoc/metagraph-fluree-examples.lisp or another loaded HyperDoc source file.

(in-package :hyperdoc)

(defun metagraph-fluree-layer-boundaries ()
  "Return the multipartite metagraph layer contract as plain inspectable data."
  '((:from :entity-node
     :to :relationship-node
     :predicate "mg:MEMBER_OF"
     :direction "N→E"
     :meaning "An entity participates in a first-class relationship, event, action, or decision.")
    (:from :relationship-node
     :to :entity-node
     :predicate "mg:REFERENCES"
     :direction "E→N"
     :meaning "A relationship node refers back to an entity node.")
    (:from :relationship-node
     :to :subgraph-node
     :predicate "mg:PART_OF"
     :direction "E→S"
     :meaning "A relationship belongs to a context, episode, narrative, or schema.")
    (:from :subgraph-node
     :to :relationship-node
     :predicate "mg:CONTAINS"
     :direction "S→E"
     :meaning "A context contains relationship nodes.")
    (:from :subgraph-node
     :to :subgraph-node
     :predicate "mg:RELATES_TO"
     :direction "S→S"
     :meaning "A meta-context references another context.")))

(defun metagraph-fluree-forbidden-layer-edges ()
  "Return edges that should not appear in the bipartite/multipartite encoding."
  '((:from :entity-node :to :entity-node :reason "Entities should not point directly to entities; promote the relation to an E-node.")
    (:from :relationship-node :to :relationship-node :reason "Relationships about relationships should be mediated by participation or context, not a direct E→E edge.")))

(defun metagraph-fluree-planning-scenario ()
  "Return the compact Q2 planning scenario encoded by the source article."
  '(:entities
    ((:id "mg:person/alice" :kind "Person" :label "Alice")
     (:id "mg:person/bob" :kind "Person" :label "Bob")
     (:id "mg:person/carol" :kind "Person" :label "Carol")
     (:id "mg:project/horizon" :kind "Project" :label "Project Horizon")
     (:id "mg:milestone/q2-launch" :kind "Milestone" :label "Q2 Product Launch")
     (:id "mg:feature/realtime-collab" :kind "Feature" :label "Real-time Collaboration"))
    :relationships
    ((:id "mg:event/planning-meeting-2026-03-24" :kind "Event" :label "Q2 Planning Meeting")
     (:id "mg:decision/accelerate-q2" :kind "Decision" :label "Decision: Accelerate Q2 Deadline")
     (:id "mg:consequence/scope-cut" :kind "Consequence" :label "Scope Reduction: Real-time Collaboration Deferred")
     (:id "mg:causal/meeting-causes-decision" :kind "Causality" :strength 0.92)
     (:id "mg:causal/decision-causes-scope-cut" :kind "Causality" :strength 0.88))
    :subgraphs
    ((:id "mg:episode/q2-planning-session" :kind "episode" :label "Q2 Planning Episode")
     (:id "mg:context/q2-strategic" :kind "context" :label "Q2 Strategic Context"))))

(defun metagraph-fluree-participations ()
  "Return the role-bearing participation nodes for the scenario."
  '((:participant "mg:person/alice" :in "mg:event/planning-meeting-2026-03-24" :role "facilitator" :position 1)
    (:participant "mg:person/bob" :in "mg:event/planning-meeting-2026-03-24" :role "presenter" :position 2)
    (:participant "mg:person/carol" :in "mg:event/planning-meeting-2026-03-24" :role "decision-maker" :position 3)
    (:participant "mg:person/carol" :in "mg:decision/accelerate-q2" :role "authority" :position 1)
    (:participant "mg:person/bob" :in "mg:decision/accelerate-q2" :role "proposer" :position 2)
    (:participant "mg:event/planning-meeting-2026-03-24" :in "mg:causal/meeting-causes-decision" :role "cause" :position 1)
    (:participant "mg:decision/accelerate-q2" :in "mg:causal/meeting-causes-decision" :role "effect" :position 2)
    (:participant "mg:decision/accelerate-q2" :in "mg:causal/decision-causes-scope-cut" :role "cause" :position 1)
    (:participant "mg:consequence/scope-cut" :in "mg:causal/decision-causes-scope-cut" :role "effect" :position 2)))

(defun metagraph-fluree-planning-meeting-participants ()
  "Return the result shape of the article's first SPARQL participant query."
  '((:person-label "Alice" :role "facilitator" :position 1)
    (:person-label "Bob" :role "presenter" :position 2)
    (:person-label "Carol" :role "decision-maker" :position 3)))

(defun metagraph-fluree-causal-chain ()
  "Return the causal chain from the planning meeting to the scope cut."
  '((:cause "Q2 Planning Meeting"
     :effect "Decision: Accelerate Q2 Deadline"
     :strength 0.92
     :link "mg:causal/meeting-causes-decision")
    (:cause "Decision: Accelerate Q2 Deadline"
     :effect "Scope Reduction: Real-time Collaboration Deferred"
     :strength 0.88
     :link "mg:causal/decision-causes-scope-cut")))

(defun metagraph-fluree-scope-cut-responsibility ()
  "Return the humans found by walking backward from the scope-cut consequence."
  '((:person-label "Carol" :role "decision-maker" :via "via origin (meeting)")
    (:person-label "Carol" :role "authority" :via "via intermediary (decision)")
    (:person-label "Bob" :role "presenter" :via "via origin (meeting)")
    (:person-label "Bob" :role "proposer" :via "via intermediary (decision)")
    (:person-label "Alice" :role "facilitator" :via "via origin (meeting)")))

(defun metagraph-fluree-as-of-query-model ()
  "Return a FlureeQL-style as-of query and the expected pre-scope-cut result."
  '(:query
    (:ledger "metagraph/planning"
     :select (("?event" ("*")))
     :where (("?event" "@type" "mg:RelationshipNode")
             ("?event" "mg:relationKind" "?kind"))
     :opts (:as-of "2026-03-24T17:00:00Z"))
    :expected-result
    ((:id "mg:event/planning-meeting-2026-03-24" :kind "Event" :label "Q2 Planning Meeting")
     (:id "mg:decision/accelerate-q2" :kind "Decision" :label "Decision: Accelerate Q2 Deadline"))
    :excluded-at-this-time
    ("mg:consequence/scope-cut")))

(defun metagraph-fluree-history-model ()
  "Return the history record used to explain causal-strength revision."
  '((:block 4
     :time "2026-03-24T16:05:00Z"
     :author "bob@example.com"
     :assert ((:id "mg:causal/meeting-causes-decision" :strength 0.92)))
    (:block 7
     :time "2026-03-28T11:00:00Z"
     :author "alice@example.com"
     :assert ((:id "mg:causal/meeting-causes-decision" :strength 0.78))
     :retract ((:id "mg:causal/meeting-causes-decision" :strength 0.92)))))

(defun metagraph-fluree-named-graph-comparison ()
  "Return the multi-perspective named-graph comparison from the article."
  '((:graph-label "Bob's Meeting Notes" :observer "Bob" :mood "tense" :confidence 0.85)
    (:graph-label "Official Minutes" :observer "Carol" :mood "contentious" :confidence 0.98)))

(defun metagraph-fluree-curl-commands ()
  "Return a dry-run Fluree command sequence without executing it."
  '((:step :start-server
     :command "docker run -d --name fluree-metagraph -p 58090:58090 -v fluree-data:/var/lib/fluree fluree/server:latest")
    (:step :health-check
     :command "curl http://localhost:58090/fdb/health")
    (:step :create-ledger
     :command "curl -X POST http://localhost:58090/fdb/create-ledger -H 'Content-Type: application/json' -d @ledger.json")
    (:step :load-schema
     :command "curl -X POST http://localhost:58090/fdb/metagraph/planning/transact -H 'Content-Type: application/json' -d @schema.jsonld")
    (:step :load-data
     :command "curl -X POST http://localhost:58090/fdb/metagraph/planning/transact -H 'Content-Type: application/json' -d @planning-chain.jsonld")))

(defexample metagraph-fluree-layer-summary-example
    "Inspect the N/E/S layer contract and the forbidden edge classes."
  (let ((boundaries (metagraph-fluree-layer-boundaries))
        (forbidden (metagraph-fluree-forbidden-layer-edges)))
    (assert (= 5 (length boundaries)))
    (assert (= 2 (length forbidden)))
    (list :layers '(:entity-node :relationship-node :subgraph-node)
          :allowed-boundaries boundaries
          :forbidden-boundaries forbidden)))

(defexample metagraph-fluree-planning-scenario-example
    "Inspect the compact strategic-planning metagraph scenario."
  (let ((scenario (metagraph-fluree-planning-scenario))
        (participations (metagraph-fluree-participations)))
    (assert (= 9 (length participations)))
    (list :scenario scenario
          :participations participations)))

(defexample metagraph-fluree-participants-query-example
    "Return the result of querying participants in the Q2 planning meeting."
  (let ((rows (metagraph-fluree-planning-meeting-participants)))
    (assert (equal '(:person-label "Alice" :role "facilitator" :position 1)
                   (first rows)))
    rows))

(defexample metagraph-fluree-causal-chain-example
    "Inspect the first-class causal E-nodes and the responsibility trace."
  (let ((chain (metagraph-fluree-causal-chain))
        (responsibility (metagraph-fluree-scope-cut-responsibility)))
    (assert (= 2 (length chain)))
    (assert (= 5 (length responsibility)))
    (list :causal-chain chain
          :responsibility responsibility)))

(defexample metagraph-fluree-time-travel-example
    "Inspect transaction-time and history examples without requiring a Fluree server."
  (let ((as-of (metagraph-fluree-as-of-query-model))
        (history (metagraph-fluree-history-model)))
    (assert (= 2 (length history)))
    (list :as-of-query as-of
          :history history)))

(defexample metagraph-fluree-named-graph-provenance-example
    "Compare two named graphs that preserve different perspectives on the same meeting."
  (let ((rows (metagraph-fluree-named-graph-comparison)))
    (assert (= 2 (length rows)))
    rows))

(defexample metagraph-fluree-curl-sequence-example
    "Inspect the Fluree setup and transaction command sequence as a safe dry run."
  (metagraph-fluree-curl-commands))
