;;;; Metagraph JSON-LD and Fluree topic factories
;;;; Drop into hyperdoc/topics/metagraph-fluree.lisp, or merge selected functions into hyperdoc/topics.lisp.

(in-package :hyperdoc)

(defun make-metagraph-fluree-topic (id title summary &optional extra-references)
  (make-topic
   :id id
   :title title
   :summary summary
   :references (append '("Metagraph as Bipartite Graph: JSON-LD + Fluree"
                         "Metagraph as Bipartite Graph: Implementing Higher-Order Knowledge with JSON-LD and Fluree")
                       extra-references)))

(defun bipartite-metagraph-topic ()
  (make-metagraph-fluree-topic
   "bipartite-metagraph"
   "Bipartite metagraph"
   "A metagraph implementation pattern that promotes relationships to first-class nodes while constraining edges to cross declared layer boundaries."))

(defun entity-node-topic ()
  (make-metagraph-fluree-topic
   "entity-node"
   "Entity node"
   "Layer-N node for primitive things such as people, projects, features, concepts, places, and objects."))

(defun relationship-node-topic ()
  (make-metagraph-fluree-topic
   "relationship-node"
   "Relationship node"
   "Layer-E node that represents an event, action, decision, consequence, or causal link as a first-class inspectable entity."))

(defun subgraph-node-topic ()
  (make-metagraph-fluree-topic
   "subgraph-node"
   "Subgraph node"
   "Layer-S node that represents a context, episode, narrative, named graph, or schema grouping relationship nodes."))

(defun reified-participation-topic ()
  (make-metagraph-fluree-topic
   "reified-participation"
   "Reified participation"
   "A role-bearing intermediate assertion that says which participant belongs to which relationship node, with metadata such as role and position."))

(defun causal-e-node-topic ()
  (make-metagraph-fluree-topic
   "causal-e-node"
   "Causal E-node"
   "A relationship node whose participants are themselves events, decisions, or consequences, making causality queryable rather than procedural."))

(defun json-ld-vocabulary-topic ()
  (make-metagraph-fluree-topic
   "json-ld-vocabulary"
   "JSON-LD vocabulary"
   "A URI-addressed semantic vocabulary that gives metagraph node and edge types portable meanings across agents and systems."))

(defun shacl-write-constraint-topic ()
  (make-metagraph-fluree-topic
   "shacl-write-constraint"
   "SHACL write constraint"
   "A shape-level guard that rejects writes violating the metagraph layer contract, such as entity-to-entity or relationship-to-relationship edges."))

(defun temporal-ledger-topic ()
  (make-metagraph-fluree-topic
   "temporal-ledger"
   "Temporal ledger"
   "An immutable append-only transaction history in which each knowledge state remains queryable after later revisions."))

(defun as-of-query-topic ()
  (make-metagraph-fluree-topic
   "as-of-query"
   "As-of query"
   "A query evaluated against the graph as it existed at a specific block or timestamp rather than only against the present state."))

(defun valid-time-topic ()
  (make-metagraph-fluree-topic
   "valid-time"
   "Valid time"
   "Domain time indicating when a claim was true in the modeled world, distinct from transaction time indicating when it was recorded."))

(defun named-graph-provenance-topic ()
  (make-metagraph-fluree-topic
   "named-graph-provenance"
   "Named-graph provenance"
   "A JSON-LD and RDF pattern for treating a whole subgraph, including its author, confidence, and perspective, as a first-class object."))

(defun agent-memory-topic ()
  (make-metagraph-fluree-topic
   "agent-memory"
   "Agent memory"
   "A knowledge substrate for agents that remembers facts together with context, provenance, revision history, and causal chains."))

(defun first-class-relationship-topic ()
  (make-metagraph-fluree-topic
   "first-class-relationship"
   "First-class relationship"
   "A relationship represented as an addressable object that can itself participate in other relationships, contexts, and provenance structures."))

(defun fluree-metagraph-topic ()
  (make-metagraph-fluree-topic
   "fluree-metagraph"
   "Fluree metagraph"
   "A JSON-LD-native, SHACL-constrained, temporal-ledger implementation of the bipartite metagraph pattern."))

(defun metagraph-fluree-topic-suite ()
  "Return all proposed topic objects for the Metagraph/Fluree slice."
  (list (bipartite-metagraph-topic)
        (entity-node-topic)
        (relationship-node-topic)
        (subgraph-node-topic)
        (reified-participation-topic)
        (causal-e-node-topic)
        (json-ld-vocabulary-topic)
        (shacl-write-constraint-topic)
        (temporal-ledger-topic)
        (as-of-query-topic)
        (valid-time-topic)
        (named-graph-provenance-topic)
        (agent-memory-topic)
        (first-class-relationship-topic)
        (fluree-metagraph-topic)))
