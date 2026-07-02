;;;; Seed topics, associations, source anchors, and story projection order.

(in-package #:the-1998-ai-planning-systems-competition)

(defparameter *topic-definitions*
  '(("the-1998-ai-planning-systems-competition" "reading-artifact"
     "The 1998 AI Planning Systems Competition"
     "FedWiki/HyperDoc reading artifact projected from a page-attached DMX SQLite topic database."
     "artifact")
    ("mcdermott-2000-planning-competition" "bibliographic-reference"
     "McDermott 2000 Planning Competition"
     "Drew V. McDermott's AI Magazine article on the first automated-planning competition."
     "AI Magazine 21(2), 2000")
    ("planning-competition" "planning-infrastructure"
     "Planning Competition"
     "A shared evaluation setting for planners, benchmark domains, and progress measurement."
     "McDermott 2000")
    ("aips-1998" "event"
     "AIPS 1998"
     "The 1998 AIPS Planning Competition, presented as the first automated-planning competition."
     "McDermott 2000")
    ("pddl" "representation-language"
     "PDDL"
     "Planning Domain Definition Language, used to standardize domain and problem notation for comparison."
     "McDermott 2000")
    ("physics-not-advice" "representational-principle"
     "Physics, Not Advice"
     "The domain description should state action physics and constraints, while planner-specific advice remains separate."
     "McDermott 2000")
    ("domain-physics" "representational-layer"
     "Domain Physics"
     "Actions, preconditions, effects, types, and constraints that define the modeled planning world."
     "McDermott 2000")
    ("planner-advice" "representational-layer"
     "Planner Advice"
     "Search guidance, plan-library commitments, or decomposition strategy that may help one planner but should not be mixed into benchmark physics."
     "McDermott 2000")
    ("benchmark-repository" "planning-infrastructure"
     "Benchmark Repository"
     "A repository of standard planning problems and domains for repeated comparison."
     "McDermott 2000")
    ("syntax-checker" "validation-tool"
     "Syntax Checker"
     "Tooling used to keep competition inputs in the shared notation."
     "McDermott 2000")
    ("solution-checker" "validation-tool"
     "Solution Checker"
     "Tooling used to check whether submitted plans solve benchmark problems."
     "McDermott 2000")
    ("strips-track" "competition-track"
     "STRIPS Track"
     "Classical planning track based on STRIPS-style planning problems."
     "McDermott 2000")
    ("adl-track" "competition-track"
     "ADL Track"
     "Classical planning track using ADL expressivity beyond simple STRIPS operators."
     "McDermott 2000")
    ("classical-planning" "planning-family"
     "Classical Planning"
     "Planning from explicit initial states, goals, and action models, without encoding planner-specific decomposition advice."
     "McDermott 2000")
    ("hierarchical-planning" "planning-family"
     "Hierarchical Planning"
     "Planning through abstract tasks, reductions, and plan-library/domain-rule structure."
     "McDermott 2000")
    ("reactive-planning" "planning-family"
     "Reactive Planning"
     "Planning or acting architectures organized around responsiveness to changing situations."
     "McDermott 2000")
    ("learning-in-planning" "planning-family"
     "Learning in Planning"
     "Planning research direction in which systems improve through experience or learned control knowledge."
     "McDermott 2000")
    ("plan-library" "hierarchical-planning-object"
     "Plan Library"
     "A structured collection of reductions, methods, or domain rules used by hierarchical planners."
     "McDermott 2000")
    ("plan-library-as-advice" "interpretive-claim"
     "Plan Library as Advice"
     "From PDDL's point of view, hierarchical plan libraries may look like advice rather than neutral physics."
     "McDermott 2000")
    ("problematization" "zettel-concept"
     "Problematisierung"
     "The act of making an object contingent by exposing that other possibilities are structurally available."
     "Zettel 6537")
    ("zettel-6537" "zettel"
     "Zettel 6537"
     "Planung als Reduktion und Bestimmung einer strukturell angelegten Offenheit für andere Möglichkeiten."
     "Zettel 6537")
    ("planning-as-contingency-reduction" "interpretive-claim"
     "Planning as Contingency Reduction"
     "Planning begins by opening a field of alternatives and then reduces it by selecting and decomposing a path."
     "Zettel 6537")
    ("shop3-methods-as-explicit-contingency-reduction" "shop3-reading"
     "SHOP3 Methods as Explicit Contingency Reduction"
     "SHOP3 methods make the reduction of alternatives explicit, ordered, inspectable, and locally accountable."
     "SHOP3 reading")
    ("fedwiki-page-projection" "projection-boundary"
     "FedWiki Page Projection"
     "The FedWiki page is a reconstruction from topic and association records, not the source of truth."
     "artifact")
    ("dmx-sqlite-as-reconstruction-basis" "durable-store"
     "DMX SQLite as Reconstruction Basis"
     "The page-attached SQLite database is the durable local basis for reconstructing this reading page."
     "artifact")))

(defparameter *association-definitions*
  '(("assoc-paper-describes-competition" "describes"
     "the paper describes the 1998 AIPS Planning Competition"
     "mcdermott-2000-planning-competition" "aips-1998")
    ("assoc-competition-produced-pddl" "produced-or-used"
     "the competition produced/used PDDL"
     "aips-1998" "pddl")
    ("assoc-pddl-supports-comparison" "supports"
     "PDDL supports comparison by standardizing domain/problem notation"
     "pddl" "planning-competition")
    ("assoc-physics-not-advice-distinguishes" "distinguishes"
     "physics, not advice distinguishes domain physics from planner advice"
     "physics-not-advice" "domain-physics")
    ("assoc-physics-not-advice-separates-advice" "separates"
     "physics, not advice keeps planner advice separate"
     "physics-not-advice" "planner-advice")
    ("assoc-classical-contrasts-hierarchical" "contrasts"
     "classical planning contrasts with hierarchical planning"
     "classical-planning" "hierarchical-planning")
    ("assoc-hierarchical-uses-plan-library" "uses"
     "hierarchical planning uses abstract actions and plan-library reductions"
     "hierarchical-planning" "plan-library")
    ("assoc-plan-library-read-as-advice" "can-be-read-as"
     "plan libraries can be read as advice"
     "plan-library" "plan-library-as-advice")
    ("assoc-hierarchical-track-failed-advice-separation" "failed-because"
     "hierarchical-planning participation failed because PDDL/advice separation was too difficult"
     "hierarchical-planning" "physics-not-advice")
    ("assoc-zettel-interprets-planning" "interprets"
     "Zettel 6537 interprets planning as contingency reduction"
     "zettel-6537" "planning-as-contingency-reduction")
    ("assoc-problematization-opens-contingency" "opens"
     "Problematisierung exposes other possibilities before reduction"
     "problematization" "planning-as-contingency-reduction")
    ("assoc-shop3-methods-explicit-reduction" "makes-explicit"
     "SHOP3 methods make contingency reduction explicit and inspectable"
     "shop3-methods-as-explicit-contingency-reduction" "planning-as-contingency-reduction")
    ("assoc-fedwiki-page-reconstructed-from-sqlite" "reconstructed-from"
     "the FedWiki page is reconstructed from the DMX SQLite asset"
     "fedwiki-page-projection" "dmx-sqlite-as-reconstruction-basis")
    ("assoc-sqlite-durable-topic-basis" "stores"
     "the SQLite asset is the durable topic basis for the page projection"
     "dmx-sqlite-as-reconstruction-basis" "the-1998-ai-planning-systems-competition")
    ("assoc-benchmark-repository-supports-competition" "supports"
     "the benchmark repository supports repeated competition comparison"
     "benchmark-repository" "planning-competition")
    ("assoc-checkers-support-benchmarks" "validates"
     "syntax and solution checkers support benchmark use"
     "syntax-checker" "solution-checker")
    ("assoc-tracks-distinguish-classical" "organizes"
     "STRIPS and ADL tracks organize classical planning comparison"
     "strips-track" "adl-track")
    ("assoc-reading-artifact-projects-paper" "projects"
     "the reading artifact projects McDermott 2000 through HyperDoc"
     "the-1998-ai-planning-systems-competition"
     "mcdermott-2000-planning-competition")))

(defparameter *source-fragment-definitions*
  '(("source-mcdermott-biblio"
     "mcdermott-2000-planning-competition"
     "AI Magazine 21(2), 2000"
     "bibliography"
     "Drew V. McDermott, The 1998 AI Planning Systems Competition, AI Magazine 21(2), 2000.")
    ("source-mcdermott-physics-not-advice"
     "mcdermott-2000-planning-competition"
     "representational issue"
     "short-excerpt"
     "physics, not advice")
    ("source-zettel-6537-planung"
     "zettel-6537"
     "reading bridge"
     "short-excerpt"
     "Planung als Reduktion und Bestimmung einer strukturell angelegten Offenheit für andere Möglichkeiten.")))

(defparameter *story-item-definitions*
  '(("synopsis" "paragraph"
     "Synopsis: McDermott 2000 is read here as an infrastructure paper about making automated-planning comparison possible. The local source of truth for this page is the attached DMX-shaped SQLite topic database.")
    ("bibliographic-card" "paragraph"
     "Bibliographic card: Drew V. McDermott, The 1998 AI Planning Systems Competition, AI Magazine 21(2), 2000. This artifact stores bibliography, source anchors, short excerpts, and paraphrased topic summaries rather than a copy of the PDF.")
    ("reading-thesis" "paragraph"
     "Reading thesis: the 1998 AIPS Planning Competition matters because it created shared domains, made planner comparison meaningful, measured field progress, and began a benchmark repository in standard notation.")
    ("physics-not-advice" "paragraph"
     "physics, not advice: PDDL should describe actions, preconditions, effects, and constraints as domain physics. Planner-specific hints, decompositions, and control knowledge belong outside the benchmark description.")
    ("planning-families" "paragraph"
     "Planning distinctions: the paper separates classical planning, hierarchical planning, reactive planning, and learning in planning. The distinction is not merely taxonomic; it exposes what must be standardized before planners can be compared.")
    ("hierarchical-shop3" "paragraph"
     "Why the hierarchical-planning track matters for SHOP3: hierarchical planners bring abstract actions, methods, and plan libraries. From PDDL's standpoint those plan-library rules can look like advice, which is why McDermott reports that hierarchical-planning researchers dropped out when the physics/advice separation proved too hard under the competition constraints.")
    ("zettel-6537-bridge" "paragraph"
     "Zettel 6537 bridge: Planung als Reduktion und Bestimmung einer strukturell angelegten Offenheit für andere Möglichkeiten. Planning begins with Problematisierung, opening the object as contingent, then reduces this openness by selecting and decomposing a path.")
    ("shop3-hyperdoc-consequence" "paragraph"
     "SHOP3/HyperDoc consequence: methods and plans should be inspectable contingency reductions. A method does not merely solve; it records how a space of other possibilities was reduced into a committed decomposition.")
    ("reconstruction-note" "paragraph"
     "Reconstruction note: this FedWiki page is projected from the attached DMX SQLite topic database. The SQLite asset is the durable topic basis; the page JSON is a reproducible projection.")))

(defun topic-definitions ()
  *topic-definitions*)

(defun association-definitions ()
  *association-definitions*)

(defun source-fragment-definitions ()
  *source-fragment-definitions*)

(defun story-item-definitions ()
  *story-item-definitions*)

(defun required-topic-ids ()
  (mapcar #'first *topic-definitions*))

(defun required-association-ids ()
  (mapcar #'first *association-definitions*))
