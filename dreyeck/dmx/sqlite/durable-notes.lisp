;;;; Durable Markdown-note to DMX topic materialization.
;;;;
;;;; Markdown remains a human-readable seed/projection.  The production
;;;; topic memory for this slice is the Dreyeck-owned DMX-shaped SQLite store.

(in-package #:dreyeck.dmx.sqlite)

(defun dreyeck-dmx-sqlite-repo-root ()
  (or (ignore-errors
        (uiop:pathname-directory-pathname
         (asdf:system-source-file :dreyeck/dmx/sqlite)))
      (uiop:getcwd)))

(defparameter *dreyeck-dmx-production-db-path*
  (merge-pathnames #p"var/dmx-associative-mirror.sqlite"
                   (dreyeck-dmx-sqlite-repo-root))
  "Production-path configuration for durable local DMX topic materialization.")

(defparameter *durable-note-materialization-plan-source*
  "hyperdoc/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp")

(defparameter *durable-note-materialization-seed-notes*
  '(("hyperdoc/HyperDoc Core.md" "hyperdoc-core")
    ("hyperdoc/Codex Belongs to Dreyeck.md" "codex-belongs-to-dreyeck")
    ("hyperdoc/Ownership Extraction with Compatibility Shell.md"
     "ownership-extraction-with-compatibility-shell")))

(defparameter *durable-note-materialization-topic-definitions*
  '((:id "hyperdoc-core"
     :type :project-concept
     :title "HyperDoc Core"
     :source "hyperdoc/HyperDoc Core.md"
     :commit-anchor "1f4e6298"
     :projection-status :seeded-from-markdown
     :summary "HyperDoc core is the upstream-generic substrate boundary, not the local hyperdoc/ path.")
    (:id "ownership-extraction-with-compatibility-shell"
     :type :learned-refactor-pattern
     :title "Ownership Extraction with Compatibility Shell"
     :source "hyperdoc/Ownership Extraction with Compatibility Shell.md"
     :commit-anchor "afa829b9"
     :also-known-as "Substrate / Situated-Surface Split"
     :canonical-example "afa829b9 refactor(codex): move collaboration surface into dreyeck"
     :projection-status :seeded-from-markdown
     :summary "Extract situated project state from a reusable substrate and leave temporary compatibility wrappers.")
    (:id "substrate-situated-surface-split"
     :type :learned-refactor-pattern
     :title "Substrate / Situated-Surface Split"
     :source "hyperdoc/Ownership Extraction with Compatibility Shell.md"
     :commit-anchor "afa829b9"
     :also-known-as "Ownership Extraction with Compatibility Shell"
     :canonical-example "afa829b9 refactor(codex): move collaboration surface into dreyeck"
     :projection-status :derived-from-seed-note
     :summary "A local name for separating upstream-generic substrate from situated collaboration surfaces.")
    (:id "codex-belongs-to-dreyeck"
     :type :architecture-decision
     :title "Codex Belongs to Dreyeck"
     :source "hyperdoc/Codex Belongs to Dreyeck.md"
     :commit-anchor "afa829b9"
     :canonical-example "afa829b9 refactor(codex): move collaboration surface into dreyeck"
     :projection-status :seeded-from-markdown
     :summary "Codex collaboration state belongs to Dreyeck, while HyperDoc supplies reusable substrate.")
    (:id "materialize-durable-notes-into-dreyeck-dmx-sqlite"
     :type :shop3-plan
     :title "Materialize Durable Notes into Dreyeck DMX SQLite"
     :source "hyperdoc/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp"
     :projection-status :seeded-from-shop3-plan
     :summary "SHOP3-shaped plan for materializing durable Markdown-note seeds into the Dreyeck DMX SQLite store.")
    (:id "inspect-dmx-materialized-learning-topics"
     :type :shop3-plan
     :title "Inspect DMX Materialized Learning Topics"
     :source "hyperdoc/inspect-dmx-materialized-learning-topics-plan.sexp"
     :projection-status :seeded-from-shop3-plan
     :summary "SHOP3-shaped plan for exposing materialized DMX learning topics through Codex and inspector surfaces.")
    (:id "add-plan-then-perform-session-state-to-dreyeck-build"
     :type :shop3-plan
     :title "Add Plan-Then-Perform Session State to Dreyeck Build"
     :source "hyperdoc/add-plan-then-perform-session-state-to-dreyeck-build-plan.sexp"
     :projection-status :seeded-from-shop3-plan
     :summary "SHOP3-shaped plan for adding ASDF-inspired session/action state to the Dreyeck build task layer.")
    (:id "render-build-referee-decisions-as-routes"
     :type :shop3-plan
     :title "Render Build Referee Decisions as Routes"
     :source "hyperdoc/render-build-referee-decisions-as-routes-plan.sexp"
     :projection-status :seeded-from-shop3-plan
     :summary "SHOP3-shaped plan for rendering build referee decisions as inspectable route objects.")
    (:id "materialize-build-referee-learning-topics"
     :type :shop3-plan
     :title "Materialize Build Referee Learning Topics"
     :source "hyperdoc/materialize-build-referee-learning-topics-plan.sexp"
     :projection-status :seeded-from-shop3-plan
     :summary "SHOP3-shaped plan for materializing the learned build-session and Lisp referee topics into the Dreyeck DMX SQLite store.")
    (:id "markdown-note-as-seed-or-projection"
     :type :project-concept
     :title "Markdown Note as Seed or Projection"
     :source "hyperdoc/HyperDoc Core.md"
     :commit-anchor "1f4e6298"
     :projection-status :derived-from-seed-note
     :summary "Markdown notes are reviewable seeds, exports, or handover projections, not the final topic store.")
    (:id "hyperdoc-core-vs-local-hyperdoc-path"
     :type :boundary-distinction
     :title "HyperDoc Core vs Local hyperdoc/ Path"
     :source "hyperdoc/HyperDoc Core.md"
     :commit-anchor "1f4e6298"
     :projection-status :derived-from-seed-note
     :summary "A file living under hyperdoc/ is not automatically HyperDoc core.")
    (:id "optional-provider-becomes-inspectable-data"
     :type :learned-problem-solution
     :title "Optional Provider Becomes Inspectable Data"
     :source "hyperdoc/Ownership Extraction with Compatibility Shell.md"
     :commit-anchor "afa829b9"
     :canonical-example "Missing Kioskbeerli providers return structured Codex provider results."
     :projection-status :derived-from-seed-note
     :summary "Missing situated providers should be represented as inspectable data instead of debugger conditions.")
    (:id "codex-is-not-the-build-system"
     :type :learned-boundary-rule
     :title "Codex Is Not the Build System"
     :source "hyperdoc/inspect-dmx-materialized-learning-topics-plan.sexp"
     :projection-status :seeded-from-shop3-plan
     :summary "Codex should invoke reusable deterministic project tasks instead of embedding build, replay, or validation logic.")
    (:id "reusable-common-lisp-build-tasks-for-codex"
     :type :learned-problem-solution
     :title "Reusable Common Lisp Build Tasks for Codex"
     :source "hyperdoc/inspect-dmx-materialized-learning-topics-plan.sexp"
     :projection-status :seeded-from-shop3-plan
     :summary "Common Lisp task functions provide the stable build/check layer Codex and inspectors can call.")
    (:id "dmx-learning-topic-inspection"
     :type :inspection-surface
     :title "DMX Learning Topic Inspection"
     :source "hyperdoc/inspect-dmx-materialized-learning-topics-plan.sexp"
     :projection-status :seeded-from-shop3-plan
     :summary "Inspection of learned DMX topics should show production DB path, required topics, associations, and replay status.")
    (:id "codex-dmx-learning-topics"
     :type :codex-surface
     :title "Codex DMX Learning Topics"
     :source "hyperdoc/inspect-dmx-materialized-learning-topics-plan.sexp"
     :projection-status :seeded-from-shop3-plan
     :summary "Codex-facing surface for materialized DMX learning topics backed by reusable build tasks.")
    (:id "plan-then-perform-build-session"
     :type :learned-build-pattern
     :title "Plan-Then-Perform Build Session"
     :source "hyperdoc/add-plan-then-perform-session-state-to-dreyeck-build-plan.sexp"
     :projection-status :seeded-from-shop3-plan
     :canonical-example "Dreyeck build session tracks up-to-date-before-session, needed-in-session, and done-in-session independently."
     :summary "Separate planning, validity checking, and performing so Codex can inspect deterministic project checks without becoming the build system.")
    (:id "build-referee-decision-route"
     :type :learned-inspector-pattern
     :title "Build Referee Decision Route"
     :source "hyperdoc/render-build-referee-decisions-as-routes-plan.sexp"
     :projection-status :seeded-from-shop3-plan
     :canonical-example "A Dreyeck build referee route shows the requested goal, candidate actions, selected action, decoded operation, status dimensions, reason, and safe-to-perform flag."
     :summary "A Lisp referee result should be rendered as an inspectable route without making Codex the next-move decision owner.")
    (:id "lisp-referee-form"
     :type :architecture-boundary
     :title "Lisp Referee Form"
     :source "hyperdoc/render-build-referee-decisions-as-routes-plan.sexp"
     :projection-status :support-topic
     :summary "An inspectable Common Lisp form or function that owns next admissible action selection.")
    (:id "dreyeck/build:build-session-next-action"
     :type :lisp-referee-form
     :title "dreyeck/build:build-session-next-action"
     :source "dreyeck/build/tasks.lisp"
     :projection-status :support-topic
     :summary "The authoritative Dreyeck build referee function that selects and decodes the next admissible action.")
    (:id "asdf-3-3-session-action-model"
     :type :source-pattern
     :title "ASDF 3.3 Session/Action Model"
     :projection-status :support-topic
     :summary "ASDF-inspired distinction between session planning, action validity, and action performance.")
    (:id "domkin-2017"
     :type :bibliographic-reference
     :title "Domkin 2017"
     :projection-status :support-topic
     :summary "Vsevolod Domkin's ELS 2017 paper on loading multiple versions of an ASDF system in one Lisp image.")
    (:id "dreyeck-dmx-sqlite-production-db"
     :type :production-store
     :title "Dreyeck DMX SQLite Production DB"
     :projection-status :configured-production-store
     :summary "The local DMX-shaped SQLite store for durable Dreyeck project topics.")
    (:id "durable-note-materialization-status"
     :type :build-check
     :title "Durable Note Materialization Status"
     :source "dreyeck/dmx/sqlite/durable-notes.lisp"
     :projection-status :support-topic
     :summary "Structured status report for the durable-note to DMX SQLite materialization.")
    (:id "dmx-topic"
     :type :dmx-object-type
     :title "DMX Topic"
     :projection-status :support-topic
     :summary "The first-class topic object represented in the DMX-shaped SQLite store.")
    (:id "durable-project-topics"
     :type :project-concept
     :title "Durable Project Topics"
     :projection-status :support-topic
     :summary "Project topics that should be persisted in the Dreyeck DMX SQLite production store.")
    (:id "hyperdoc-core-patch"
     :type :classification
     :title "HyperDoc Core Patch"
     :source "hyperdoc/HyperDoc Core.md"
     :commit-anchor "1f4e6298"
     :projection-status :derived-from-seed-note
     :summary "A local generic HyperDoc change that could plausibly remain upstream-generic.")
    (:id "hyperdoc-compatibility-shell"
     :type :classification
     :title "HyperDoc Compatibility Shell"
     :source "hyperdoc/HyperDoc Core.md"
     :commit-anchor "1f4e6298"
     :projection-status :derived-from-seed-note
     :summary "A temporary wrapper preserving old HyperDoc coordinates after ownership moves elsewhere.")
    (:id "project-owned-extension"
     :type :classification
     :title "Project-Owned Extension"
     :source "hyperdoc/HyperDoc Core.md"
     :commit-anchor "1f4e6298"
     :projection-status :derived-from-seed-note
     :summary "Situated code owned by Dreyeck, Kioskbeerli, Hauptsache, DMX integration, Codex, or another project layer.")
    (:id "bounded-convergent-association-edge-reassignment"
     :type :dmx-operation
     :title "Bounded Convergent Association Edge Reassignment"
     :source "dreyeck/dmx/sqlite/edge-reassignment.lisp"
     :projection-status :documented-reader-surface
     :summary "The DMX SQLite operation that moves one bounded association edge to a new target while converging when the target edge is already present.")
    (:id "operation-reader-surface-documentation-pattern"
     :type :documentation-pattern
     :title "Operation Reader Surface Documentation Pattern"
     :source "hyperdoc/document-operation-reader-surface-shop3-plan.sexp"
     :projection-status :seeded-from-shop3-plan
     :summary "A documentation pattern that starts from the reader's operation question, then separates atomic graph change, derivative evidence, and source-of-truth boundaries.")
    (:id "expected-vs-actual-graph-delta"
     :type :reader-surface-concept
     :title "Expected vs Actual Graph Delta"
     :source "dreyeck/dmx/sqlite/edge-reassignment.lisp"
     :projection-status :documented-reader-surface
     :summary "The operation reports the intended association-id delta and the measured association-id delta so unexpected graph changes are explicit.")
    (:id "atomic-vs-derivative-effects"
     :type :reader-surface-concept
     :title "Atomic vs Derivative Effects"
     :source "hyperdoc/document-operation-reader-surface-shop3-plan.sexp"
     :projection-status :documented-reader-surface
     :summary "The reader surface presents the graph edge change as the atomic effect and journals or materializer evidence as derivative effects.")
    (:id "single-source-of-truth-for-maintained-graph"
     :type :architecture-boundary
     :title "Single Source of Truth for Maintained Graph"
     :source "hyperdoc/document-operation-reader-surface-shop3-plan.sexp"
     :projection-status :documented-reader-surface
     :summary "The production DMX SQLite DB remains the source of truth for the maintained graph; documentation and FedWiki pages are reader surfaces, not repairs.")
    (:id "operation-reader-question"
     :type :reader-question
     :title "Operation Reader Question"
     :source "hyperdoc/document-operation-reader-surface-shop3-plan.sexp"
     :projection-status :documented-reader-surface
     :summary "The first question an operation report must answer is what graph fact changed and whether the result is coherent.")
    (:id "bounded-convergent-association-edge-reassignment-fedwiki-page"
     :type :fedwiki-page-artifact
     :title "Bounded Convergent Association Edge Reassignment FedWiki Page"
     :source-reference "fedwiki:wiki.ralfbarkow.ch/bounded-convergent-association-edge-reassignment"
     :projection-status :reader-surface-documentation
     :summary "The localhost FedWiki reader page for bounded convergent association edge reassignment.")))

(defparameter *domkin-2017-source-artifact*
  "hyperdoc/domkin-2017-asdf-source-topics.sexp")

(defparameter *domkin-2017-source-topic-ids*
  '("domkin-2017-loading-multiple-asdf-versions"
    "common-lisp-dependency-hell"
    "package-name-conflict"
    "global-package-registry"
    "asdf-unversioned-system-registry"
    "package-renaming-conflict-resolution"
    "rename-package-as-low-level-mechanism"
    "load-system-with-renamings"
    "dependency-tree-conflict-analysis"
    "topological-load-order-with-load-last-conflict-strategy"
    "post-load-package-capture"
    "asdf-public-api-gap"
    "asdf-plan-api-underdocumented"
    "asdf-caching-underdocumented"
    "asdf-monolithic-loading-strategy"
    "alternative-asdf-system-strategies"
    "production-build-dependency-immutability"
    "nontransactional-package-capture-limitation"
    "preexisting-package-discipline-limitation"
    "monkey-patching-limitation"
    "implicit-transitive-dependency-limitation"
    "same-name-same-version-social-limitation"
    "runtime-intern-eval-renaming-limitation"
    "asdf-api-future-work"
    "hyperdoc-asdf-session-action-reading"))

(defparameter *domkin-2017-source-topic-definitions*
  `((:id "domkin-2017-loading-multiple-asdf-versions"
     :type :source-paper
     :title "Loading Multiple Versions of an ASDF System in the Same Lisp Image"
     :source ,*domkin-2017-source-artifact*
     :source-reference "Domkin 2017, ELS"
     :page-hint "ELS 2017 pages 10-18; local PDF pages 16-26"
     :projection-status :seeded-from-source-reading
     :summary "Domkin presents a proof-of-concept for consecutive loading of several versions of the same ASDF system in one Lisp image by renaming packages to avoid package-name conflicts.")
    (:id "common-lisp-dependency-hell"
     :type :problem
     :title "Common Lisp Dependency Hell"
     :source ,*domkin-2017-source-artifact*
     :source-reference "Domkin 2017"
     :page-hint "ELS 2017 page 10"
     :projection-status :seeded-from-source-reading
     :summary "Multiple libraries or versions may require incompatible artifacts with the same names, causing build failure or silent/vocal redefinition of functionality.")
    (:id "package-name-conflict"
     :type :problem
     :title "Package Name Conflict"
     :source ,*domkin-2017-source-artifact*
     :source-reference "Domkin 2017"
     :page-hint "ELS 2017 pages 10-11"
     :projection-status :seeded-from-source-reading
     :summary "Common Lisp packages are globally registered dynamic objects, so loading two artifacts that define packages with the same names or nicknames can redefine or extend an existing package unexpectedly.")
    (:id "global-package-registry"
     :type :common-lisp-mechanism
     :title "Global Package Registry"
     :source ,*domkin-2017-source-artifact*
     :source-reference "Domkin 2017"
     :page-hint "ELS 2017 page 10"
     :projection-status :seeded-from-source-reading
     :summary "The running Lisp image has a centralized registry of known packages; this is the substrate on which package-name conflicts appear.")
    (:id "asdf-unversioned-system-registry"
     :type :asdf-limitation
     :title "ASDF Unversioned System Registry"
     :source ,*domkin-2017-source-artifact*
     :source-reference "Domkin 2017"
     :page-hint "ELS 2017 page 11"
     :projection-status :seeded-from-source-reading
     :summary "ASDF keeps a central registry of known systems keyed by unversioned system names, so at a given moment only one version of a system is accessible to ASDF.")
    (:id "package-renaming-conflict-resolution"
     :type :solution-strategy
     :title "Package Renaming Conflict Resolution"
     :source ,*domkin-2017-source-artifact*
     :source-reference "Domkin 2017"
     :page-hint "ELS 2017 pages 11-13"
     :projection-status :seeded-from-source-reading
     :summary "Rename packages belonging to a loaded version before loading another conflicting version, so package-level names do not collide.")
    (:id "rename-package-as-low-level-mechanism"
     :type :common-lisp-mechanism
     :title "RENAME-PACKAGE as Low-Level Conflict Mechanism"
     :source ,*domkin-2017-source-artifact*
     :source-reference "Domkin 2017"
     :page-hint "ELS 2017 page 11"
     :projection-status :seeded-from-source-reading
     :summary "Common Lisp's RENAME-PACKAGE function is the low-level operation used to avoid package name clashes by changing references before another artifact is initialized.")
    (:id "load-system-with-renamings"
     :type :algorithm
     :title "LOAD-SYSTEM-WITH-RENAMINGS"
     :source ,*domkin-2017-source-artifact*
     :source-reference "Domkin 2017"
     :page-hint "ELS 2017 pages 13-14"
     :projection-status :seeded-from-source-reading
     :summary "Domkin's proof-of-concept loading procedure builds a dependency tree, detects version conflicts, orders dependencies, loads components, records package additions, and performs package renamings at selected points.")
    (:id "dependency-tree-conflict-analysis"
     :type :algorithmic-step
     :title "Dependency Tree Conflict Analysis"
     :source ,*domkin-2017-source-artifact*
     :source-reference "Domkin 2017"
     :page-hint "ELS 2017 pages 12-13"
     :projection-status :seeded-from-source-reading
     :summary "The algorithm traverses ASDF dependency information to discover conflicting systems and locate where renaming must occur in the dependency hierarchy.")
    (:id "topological-load-order-with-load-last-conflict-strategy"
     :type :algorithmic-step
     :title "Topological Load Order with Load-Last Conflict Strategy"
     :source ,*domkin-2017-source-artifact*
     :source-reference "Domkin 2017"
     :page-hint "ELS 2017 page 13"
     :projection-status :seeded-from-source-reading
     :summary "The algorithm uses a topological load order and loads conflict-resolution dependencies last among siblings so renaming happens before a later conflicting load would collide.")
    (:id "post-load-package-capture"
     :type :algorithmic-step
     :title "Post-Load Package Capture"
     :source ,*domkin-2017-source-artifact*
     :source-reference "Domkin 2017"
     :page-hint "ELS 2017 pages 13-14"
     :projection-status :seeded-from-source-reading
     :summary "During loading, newly added packages are recorded after the fact and associated with the system being loaded, allowing later renaming of packages belonging to that system.")
    (:id "asdf-public-api-gap"
     :type :asdf-limitation
     :title "ASDF Public API Gap"
     :source ,*domkin-2017-source-artifact*
     :source-reference "Domkin 2017"
     :page-hint "ELS 2017 pages 14-16"
     :projection-status :seeded-from-source-reading
     :summary "Domkin argues that ASDF lacks public APIs needed for alternative system manipulation strategies such as loading from a specific filesystem location, enumerating candidate locations, selecting a version, or reading an ASD without global state changes.")
    (:id "asdf-plan-api-underdocumented"
     :type :asdf-limitation
     :title "ASDF Plan API Underdocumented"
     :source ,*domkin-2017-source-artifact*
     :source-reference "Domkin 2017"
     :page-hint "ELS 2017 page 14"
     :projection-status :seeded-from-source-reading
     :summary "Domkin notes that ASDF operations are performed according to a plan object, but the plan API is not clearly documented.")
    (:id "asdf-caching-underdocumented"
     :type :asdf-limitation
     :title "ASDF Caching Underdocumented"
     :source ,*domkin-2017-source-artifact*
     :source-reference "Domkin 2017"
     :page-hint "ELS 2017 page 14"
     :projection-status :seeded-from-source-reading
     :summary "Domkin identifies ASDF caching behavior as insufficiently documented for alternative build/loading strategies.")
    (:id "asdf-monolithic-loading-strategy"
     :type :asdf-limitation
     :title "ASDF Monolithic Loading Strategy"
     :source ,*domkin-2017-source-artifact*
     :source-reference "Domkin 2017"
     :page-hint "ELS 2017 page 14"
     :projection-status :seeded-from-source-reading
     :summary "ASDF is described as a tightly-coupled tool tuned toward a particular system-handling strategy, making alternative strategies hard to implement on public APIs alone.")
    (:id "alternative-asdf-system-strategies"
     :type :asdf-design-goal
     :title "Alternative ASDF System Strategies"
     :source ,*domkin-2017-source-artifact*
     :source-reference "Domkin 2017"
     :page-hint "ELS 2017 pages 14-18"
     :projection-status :seeded-from-source-reading
     :summary "Alternative ASDF strategies include non-default system discovery, loading, version selection, and component manipulation workflows that should be expressible through public APIs.")
    (:id "production-build-dependency-immutability"
     :type :design-assumption
     :title "Production Build Dependency Immutability"
     :source ,*domkin-2017-source-artifact*
     :source-reference "Domkin 2017"
     :page-hint "ELS 2017 pages 11 and 16"
     :projection-status :seeded-from-source-reading
     :summary "Domkin's approach targets production-like environments where the whole target system is loaded and dependencies are not later modified in memory.")
    (:id "nontransactional-package-capture-limitation"
     :type :limitation
     :title "Nontransactional Package Capture Limitation"
     :source ,*domkin-2017-source-artifact*
     :source-reference "Domkin 2017"
     :page-hint "ELS 2017 page 16"
     :projection-status :seeded-from-source-reading
     :summary "The package-capture mechanism records global package table changes after the fact and is not transactional; parallel loading can race unless protected.")
    (:id "preexisting-package-discipline-limitation"
     :type :limitation
     :title "Preexisting Package Discipline Limitation"
     :source ,*domkin-2017-source-artifact*
     :source-reference "Domkin 2017"
     :page-hint "ELS 2017 page 17"
     :projection-status :seeded-from-source-reading
     :summary "The approach assumes packages from loaded systems were not previously defined, which is reasonable in a vanilla production environment but can fail in interactive sessions.")
    (:id "monkey-patching-limitation"
     :type :limitation
     :title "Monkey-Patching Limitation"
     :source ,*domkin-2017-source-artifact*
     :source-reference "Domkin 2017"
     :page-hint "ELS 2017 page 17"
     :projection-status :seeded-from-source-reading
     :summary "The procedure does not catch changes to existing packages, a limitation related to interactive monkey-patching or hot-patching.")
    (:id "implicit-transitive-dependency-limitation"
     :type :limitation
     :title "Implicit Transitive Dependency Limitation"
     :source ,*domkin-2017-source-artifact*
     :source-reference "Domkin 2017"
     :page-hint "ELS 2017 page 17"
     :projection-status :seeded-from-source-reading
     :summary "Implicit dependencies can break when a transitive dependency's packages are renamed before a depending system reads references to their old names; explicit dependencies are the straightforward repair.")
    (:id "same-name-same-version-social-limitation"
     :type :limitation
     :title "Same Name Same Version Social Limitation"
     :source ,*domkin-2017-source-artifact*
     :source-reference "Domkin 2017"
     :page-hint "ELS 2017 page 17"
     :projection-status :seeded-from-source-reading
     :summary "Two independent packages with the same name and version are not addressed by the code-level approach and may require social or repository-level resolution.")
    (:id "runtime-intern-eval-renaming-limitation"
     :type :limitation
     :title "Runtime INTERN/EVAL Renaming Limitation"
     :source ,*domkin-2017-source-artifact*
     :source-reference "Domkin 2017"
     :page-hint "ELS 2017 page 17"
     :projection-status :seeded-from-source-reading
     :summary "Code relying on runtime package lookup through INTERN or unevaluated EVAL references can break because renamed packages are no longer available under canonical names.")
    (:id "asdf-api-future-work"
     :type :future-work
     :title "ASDF API Future Work"
     :source ,*domkin-2017-source-artifact*
     :source-reference "Domkin 2017"
     :page-hint "ELS 2017 page 18"
     :projection-status :seeded-from-source-reading
     :summary "Domkin argues ASDF should expose better public APIs, deeper version support, documented plan/action APIs, decoupled internals, and utility wrappers for middle-level operations.")
    (:id "hyperdoc-asdf-session-action-reading"
     :type :hyperdoc-reading
     :title "HyperDoc Reading of Domkin's ASDF Session/Action Model"
     :source ,*domkin-2017-source-artifact*
     :source-reference "Domkin 2017"
     :page-hint "ELS 2017 pages 14 and 18"
     :projection-status :seeded-from-source-reading
     :summary "For HyperDoc, Domkin's critique motivates an explicit, inspectable plan/check/perform/referee layer rather than hiding ASDF-like action selection inside an opaque build tool.")))

(defparameter *durable-note-materialization-association-definitions*
  '((:source "hyperdoc-core"
     :predicate "supplies-boundary-for"
     :target "ownership-extraction-with-compatibility-shell")
    (:source "ownership-extraction-with-compatibility-shell"
     :predicate "applied-in"
     :target "codex-belongs-to-dreyeck")
    (:source "hyperdoc-core"
     :predicate "distinguishes"
     :target "hyperdoc-core-patch")
    (:source "hyperdoc-core"
     :predicate "distinguishes"
     :target "hyperdoc-compatibility-shell")
    (:source "hyperdoc-core"
     :predicate "excludes"
     :target "project-owned-extension")
    (:source "markdown-note-as-seed-or-projection"
     :predicate "materializes-to"
     :target "dmx-topic")
    (:source "dreyeck-dmx-sqlite-production-db"
     :predicate "stores"
     :target "durable-project-topics")
    (:source "codex-is-not-the-build-system"
     :predicate "recommends"
     :target "reusable-common-lisp-build-tasks-for-codex")
    (:source "reusable-common-lisp-build-tasks-for-codex"
     :predicate "supports"
     :target "codex-dmx-learning-topics")
    (:source "codex-dmx-learning-topics"
     :predicate "inspects"
     :target "dreyeck-dmx-sqlite-production-db")
    (:source "dmx-learning-topic-inspection"
     :predicate "depends-on"
     :target "durable-note-materialization-status")
    (:source "plan-then-perform-build-session"
     :predicate "refines"
     :target "codex-is-not-the-build-system")
    (:source "plan-then-perform-build-session"
     :predicate "supports"
     :target "reusable-common-lisp-build-tasks-for-codex")
    (:source "plan-then-perform-build-session"
     :predicate "inspired-by"
     :target "asdf-3-3-session-action-model")
    (:source "asdf-3-3-session-action-model"
     :predicate "described-by"
     :target "domkin-2017")
    (:source "build-referee-decision-route"
     :predicate "renders"
     :target "lisp-referee-form")
    (:source "build-referee-decision-route"
     :predicate "explains"
     :target "plan-then-perform-build-session")
    (:source "build-referee-decision-route"
     :predicate "supports"
     :target "codex-is-not-the-build-system")
    (:source "build-referee-decision-route"
     :predicate "inspects"
     :target "dreyeck/build:build-session-next-action")
    (:source "bounded-convergent-association-edge-reassignment"
     :predicate "instantiates"
     :target "operation-reader-surface-documentation-pattern")
    (:source "bounded-convergent-association-edge-reassignment"
     :predicate "uses"
     :target "expected-vs-actual-graph-delta")
    (:source "bounded-convergent-association-edge-reassignment"
     :predicate "separates"
     :target "atomic-vs-derivative-effects")
    (:source "bounded-convergent-association-edge-reassignment"
     :predicate "respects"
     :target "single-source-of-truth-for-maintained-graph")
    (:source "operation-reader-surface-documentation-pattern"
     :predicate "answers"
     :target "operation-reader-question")
    (:source "bounded-convergent-association-edge-reassignment-fedwiki-page"
     :predicate "documents"
     :target "bounded-convergent-association-edge-reassignment")))

(defparameter *domkin-2017-source-association-keys*
  '(("domkin-2017" "describes" "domkin-2017-loading-multiple-asdf-versions")
    ("domkin-2017-loading-multiple-asdf-versions" "addresses" "common-lisp-dependency-hell")
    ("common-lisp-dependency-hell" "manifests-as" "package-name-conflict")
    ("package-name-conflict" "occurs-in" "global-package-registry")
    ("package-renaming-conflict-resolution" "uses" "rename-package-as-low-level-mechanism")
    ("load-system-with-renamings" "implements" "package-renaming-conflict-resolution")
    ("load-system-with-renamings" "performs" "dependency-tree-conflict-analysis")
    ("load-system-with-renamings" "uses" "topological-load-order-with-load-last-conflict-strategy")
    ("load-system-with-renamings" "records" "post-load-package-capture")
    ("load-system-with-renamings" "assumes" "production-build-dependency-immutability")
    ("asdf-unversioned-system-registry" "contributes-to" "common-lisp-dependency-hell")
    ("asdf-public-api-gap" "limits" "load-system-with-renamings")
    ("asdf-plan-api-underdocumented" "limits" "alternative-asdf-system-strategies")
    ("asdf-caching-underdocumented" "limits" "alternative-asdf-system-strategies")
    ("asdf-monolithic-loading-strategy" "explains" "asdf-public-api-gap")
    ("nontransactional-package-capture-limitation" "constrains" "load-system-with-renamings")
    ("preexisting-package-discipline-limitation" "constrains" "load-system-with-renamings")
    ("monkey-patching-limitation" "constrains" "load-system-with-renamings")
    ("implicit-transitive-dependency-limitation" "constrains" "load-system-with-renamings")
    ("runtime-intern-eval-renaming-limitation" "constrains" "load-system-with-renamings")
    ("same-name-same-version-social-limitation" "constrains" "package-renaming-conflict-resolution")
    ("asdf-api-future-work" "responds-to" "asdf-public-api-gap")
    ("asdf-api-future-work" "responds-to" "asdf-plan-api-underdocumented")
    ("asdf-3-3-session-action-model" "described-by" "domkin-2017")
    ("plan-then-perform-build-session" "inspired-by" "hyperdoc-asdf-session-action-reading")
    ("hyperdoc-asdf-session-action-reading" "derived-from" "domkin-2017-loading-multiple-asdf-versions")
    ("build-referee-decision-route" "responds-to" "asdf-plan-api-underdocumented")
    ("lisp-referee-form" "responds-to" "asdf-monolithic-loading-strategy")))

(defparameter *domkin-2017-source-association-definitions*
  '((:source "domkin-2017"
     :predicate "describes"
     :target "domkin-2017-loading-multiple-asdf-versions"
     :source-artifact "hyperdoc/domkin-2017-asdf-source-topics.sexp"
     :projection-status :seeded-from-source-reading)
    (:source "domkin-2017-loading-multiple-asdf-versions"
     :predicate "addresses"
     :target "common-lisp-dependency-hell"
     :source-artifact "hyperdoc/domkin-2017-asdf-source-topics.sexp"
     :projection-status :seeded-from-source-reading)
    (:source "common-lisp-dependency-hell"
     :predicate "manifests-as"
     :target "package-name-conflict"
     :source-artifact "hyperdoc/domkin-2017-asdf-source-topics.sexp"
     :projection-status :seeded-from-source-reading)
    (:source "package-name-conflict"
     :predicate "occurs-in"
     :target "global-package-registry"
     :source-artifact "hyperdoc/domkin-2017-asdf-source-topics.sexp"
     :projection-status :seeded-from-source-reading)
    (:source "package-renaming-conflict-resolution"
     :predicate "uses"
     :target "rename-package-as-low-level-mechanism"
     :source-artifact "hyperdoc/domkin-2017-asdf-source-topics.sexp"
     :projection-status :seeded-from-source-reading)
    (:source "load-system-with-renamings"
     :predicate "implements"
     :target "package-renaming-conflict-resolution"
     :source-artifact "hyperdoc/domkin-2017-asdf-source-topics.sexp"
     :projection-status :seeded-from-source-reading)
    (:source "load-system-with-renamings"
     :predicate "performs"
     :target "dependency-tree-conflict-analysis"
     :source-artifact "hyperdoc/domkin-2017-asdf-source-topics.sexp"
     :projection-status :seeded-from-source-reading)
    (:source "load-system-with-renamings"
     :predicate "uses"
     :target "topological-load-order-with-load-last-conflict-strategy"
     :source-artifact "hyperdoc/domkin-2017-asdf-source-topics.sexp"
     :projection-status :seeded-from-source-reading)
    (:source "load-system-with-renamings"
     :predicate "records"
     :target "post-load-package-capture"
     :source-artifact "hyperdoc/domkin-2017-asdf-source-topics.sexp"
     :projection-status :seeded-from-source-reading)
    (:source "load-system-with-renamings"
     :predicate "assumes"
     :target "production-build-dependency-immutability"
     :source-artifact "hyperdoc/domkin-2017-asdf-source-topics.sexp"
     :projection-status :seeded-from-source-reading)
    (:source "asdf-unversioned-system-registry"
     :predicate "contributes-to"
     :target "common-lisp-dependency-hell"
     :source-artifact "hyperdoc/domkin-2017-asdf-source-topics.sexp"
     :projection-status :seeded-from-source-reading)
    (:source "asdf-public-api-gap"
     :predicate "limits"
     :target "load-system-with-renamings"
     :source-artifact "hyperdoc/domkin-2017-asdf-source-topics.sexp"
     :projection-status :seeded-from-source-reading)
    (:source "asdf-plan-api-underdocumented"
     :predicate "limits"
     :target "alternative-asdf-system-strategies"
     :source-artifact "hyperdoc/domkin-2017-asdf-source-topics.sexp"
     :projection-status :seeded-from-source-reading)
    (:source "asdf-caching-underdocumented"
     :predicate "limits"
     :target "alternative-asdf-system-strategies"
     :source-artifact "hyperdoc/domkin-2017-asdf-source-topics.sexp"
     :projection-status :seeded-from-source-reading)
    (:source "asdf-monolithic-loading-strategy"
     :predicate "explains"
     :target "asdf-public-api-gap"
     :source-artifact "hyperdoc/domkin-2017-asdf-source-topics.sexp"
     :projection-status :seeded-from-source-reading)
    (:source "nontransactional-package-capture-limitation"
     :predicate "constrains"
     :target "load-system-with-renamings"
     :source-artifact "hyperdoc/domkin-2017-asdf-source-topics.sexp"
     :projection-status :seeded-from-source-reading)
    (:source "preexisting-package-discipline-limitation"
     :predicate "constrains"
     :target "load-system-with-renamings"
     :source-artifact "hyperdoc/domkin-2017-asdf-source-topics.sexp"
     :projection-status :seeded-from-source-reading)
    (:source "monkey-patching-limitation"
     :predicate "constrains"
     :target "load-system-with-renamings"
     :source-artifact "hyperdoc/domkin-2017-asdf-source-topics.sexp"
     :projection-status :seeded-from-source-reading)
    (:source "implicit-transitive-dependency-limitation"
     :predicate "constrains"
     :target "load-system-with-renamings"
     :source-artifact "hyperdoc/domkin-2017-asdf-source-topics.sexp"
     :projection-status :seeded-from-source-reading)
    (:source "runtime-intern-eval-renaming-limitation"
     :predicate "constrains"
     :target "load-system-with-renamings"
     :source-artifact "hyperdoc/domkin-2017-asdf-source-topics.sexp"
     :projection-status :seeded-from-source-reading)
    (:source "same-name-same-version-social-limitation"
     :predicate "constrains"
     :target "package-renaming-conflict-resolution"
     :source-artifact "hyperdoc/domkin-2017-asdf-source-topics.sexp"
     :projection-status :seeded-from-source-reading)
    (:source "asdf-api-future-work"
     :predicate "responds-to"
     :target "asdf-public-api-gap"
     :source-artifact "hyperdoc/domkin-2017-asdf-source-topics.sexp"
     :projection-status :seeded-from-source-reading)
    (:source "asdf-api-future-work"
     :predicate "responds-to"
     :target "asdf-plan-api-underdocumented"
     :source-artifact "hyperdoc/domkin-2017-asdf-source-topics.sexp"
     :projection-status :seeded-from-source-reading)
    (:source "plan-then-perform-build-session"
     :predicate "inspired-by"
     :target "hyperdoc-asdf-session-action-reading"
     :source-artifact "hyperdoc/domkin-2017-asdf-source-topics.sexp"
     :projection-status :seeded-from-source-reading)
    (:source "hyperdoc-asdf-session-action-reading"
     :predicate "derived-from"
     :target "domkin-2017-loading-multiple-asdf-versions"
     :source-artifact "hyperdoc/domkin-2017-asdf-source-topics.sexp"
     :projection-status :seeded-from-source-reading)
    (:source "build-referee-decision-route"
     :predicate "responds-to"
     :target "asdf-plan-api-underdocumented"
     :source-artifact "hyperdoc/domkin-2017-asdf-source-topics.sexp"
     :projection-status :seeded-from-source-reading)
    (:source "lisp-referee-form"
     :predicate "responds-to"
     :target "asdf-monolithic-loading-strategy"
     :source-artifact "hyperdoc/domkin-2017-asdf-source-topics.sexp"
     :projection-status :seeded-from-source-reading)))

(defparameter *durable-note-materialization-required-topic-ids*
  '("hyperdoc-core"
    "ownership-extraction-with-compatibility-shell"
    "substrate-situated-surface-split"
    "codex-belongs-to-dreyeck"
    "materialize-durable-notes-into-dreyeck-dmx-sqlite"
    "markdown-note-as-seed-or-projection"
    "hyperdoc-core-vs-local-hyperdoc-path"
    "optional-provider-becomes-inspectable-data"
    "inspect-dmx-materialized-learning-topics"
    "add-plan-then-perform-session-state-to-dreyeck-build"
    "render-build-referee-decisions-as-routes"
    "materialize-build-referee-learning-topics"
    "codex-is-not-the-build-system"
    "reusable-common-lisp-build-tasks-for-codex"
    "dmx-learning-topic-inspection"
    "codex-dmx-learning-topics"
    "plan-then-perform-build-session"
    "build-referee-decision-route"
    "lisp-referee-form"
    "dreyeck/build:build-session-next-action"
    "asdf-3-3-session-action-model"
    "domkin-2017"
    "durable-note-materialization-status"
    "bounded-convergent-association-edge-reassignment"
    "operation-reader-surface-documentation-pattern"
    "expected-vs-actual-graph-delta"
    "atomic-vs-derivative-effects"
    "single-source-of-truth-for-maintained-graph"
    "operation-reader-question"
    "bounded-convergent-association-edge-reassignment-fedwiki-page"))

(defparameter *dmx-learning-topic-ids*
  '("codex-is-not-the-build-system"
    "reusable-common-lisp-build-tasks-for-codex"
    "dmx-learning-topic-inspection"
    "codex-dmx-learning-topics"
    "plan-then-perform-build-session"
    "build-referee-decision-route"))

(defparameter *dmx-learning-support-topic-ids*
  '("inspect-dmx-materialized-learning-topics"
    "add-plan-then-perform-session-state-to-dreyeck-build"
    "render-build-referee-decisions-as-routes"
    "materialize-build-referee-learning-topics"
    "durable-note-materialization-status"
    "dreyeck-dmx-sqlite-production-db"
    "lisp-referee-form"
    "dreyeck/build:build-session-next-action"
    "asdf-3-3-session-action-model"
    "domkin-2017"))

(defparameter *dmx-learning-association-keys*
  '(("codex-is-not-the-build-system"
     "recommends"
     "reusable-common-lisp-build-tasks-for-codex")
    ("reusable-common-lisp-build-tasks-for-codex"
     "supports"
     "codex-dmx-learning-topics")
    ("codex-dmx-learning-topics"
     "inspects"
     "dreyeck-dmx-sqlite-production-db")
    ("dmx-learning-topic-inspection"
     "depends-on"
     "durable-note-materialization-status")
    ("plan-then-perform-build-session"
     "refines"
     "codex-is-not-the-build-system")
    ("plan-then-perform-build-session"
     "supports"
     "reusable-common-lisp-build-tasks-for-codex")
    ("plan-then-perform-build-session"
     "inspired-by"
     "asdf-3-3-session-action-model")
    ("asdf-3-3-session-action-model"
     "described-by"
     "domkin-2017")
    ("build-referee-decision-route"
     "renders"
     "lisp-referee-form")
    ("build-referee-decision-route"
     "explains"
     "plan-then-perform-build-session")
    ("build-referee-decision-route"
     "supports"
     "codex-is-not-the-build-system")
    ("build-referee-decision-route"
     "inspects"
     "dreyeck/build:build-session-next-action")))

(defparameter *dmx-operation-reader-surface-topic-ids*
  '("bounded-convergent-association-edge-reassignment"
    "operation-reader-surface-documentation-pattern"
    "expected-vs-actual-graph-delta"
    "atomic-vs-derivative-effects"
    "single-source-of-truth-for-maintained-graph"
    "operation-reader-question"
    "bounded-convergent-association-edge-reassignment-fedwiki-page"))

(defparameter *dmx-operation-reader-surface-association-keys*
  '(("bounded-convergent-association-edge-reassignment"
     "instantiates"
     "operation-reader-surface-documentation-pattern")
    ("bounded-convergent-association-edge-reassignment"
     "uses"
     "expected-vs-actual-graph-delta")
    ("bounded-convergent-association-edge-reassignment"
     "separates"
     "atomic-vs-derivative-effects")
    ("bounded-convergent-association-edge-reassignment"
     "respects"
     "single-source-of-truth-for-maintained-graph")
    ("operation-reader-surface-documentation-pattern"
     "answers"
     "operation-reader-question")
    ("bounded-convergent-association-edge-reassignment-fedwiki-page"
     "documents"
     "bounded-convergent-association-edge-reassignment")))

(defun durable-note-all-topic-definitions ()
  (append *durable-note-materialization-topic-definitions*
          *domkin-2017-source-topic-definitions*))

(defun durable-note-all-association-definitions ()
  (append *durable-note-materialization-association-definitions*
          *domkin-2017-source-association-definitions*))

(defun durable-note-required-topic-ids ()
  (append *durable-note-materialization-required-topic-ids*
          *domkin-2017-source-topic-ids*))

(defun durable-note-source-pathname (source)
  (when source
    (merge-pathnames source (dreyeck-dmx-sqlite-repo-root))))

(defun durable-note-title-from-markdown (content)
  (loop for line in (uiop:split-string content :separator '(#\Newline))
        thereis
        (when (and (> (length line) 2)
                   (string= "# " line :end2 2))
          (string-trim '(#\Space #\Tab) (subseq line 2)))))

(defun durable-note-source-info (source)
  (let ((pathname (durable-note-source-pathname source)))
    (cond
      ((null source)
       (list :source nil :exists-p nil))
      ((probe-file pathname)
       (let ((content (uiop:read-file-string pathname)))
         (list :source source
               :pathname (namestring pathname)
               :exists-p t
               :source-title (durable-note-title-from-markdown content)
               :source-bytes (length content))))
      (t
       (list :source source
             :pathname (namestring pathname)
             :exists-p nil)))))

(defun dmx-token-string (value)
  (cond
    ((null value)
     "")
    ((keywordp value)
     (string-downcase (symbol-name value)))
    ((symbolp value)
     (string-downcase (symbol-name value)))
    (t
     (format nil "~A" value))))

(defun durable-note-topic-type-uri (type)
  (format nil "dreyeck.dmx.topic.~A" (dmx-token-string type)))

(defun durable-note-association-type-uri (predicate)
  (format nil "dreyeck.dmx.association.~A" (dmx-token-string predicate)))

(defun durable-note-topic-uri (topic-id)
  (format nil "dmx://dreyeck/local-topic/~A" topic-id))

(defun durable-note-association-id (definition)
  (format nil "assoc:~A:~A:~A"
          (getf definition :source)
          (getf definition :predicate)
          (getf definition :target)))

(defun durable-note-topic-definition (topic-id)
  (find topic-id
        (durable-note-all-topic-definitions)
        :key (lambda (definition) (getf definition :id))
        :test #'equal))

(defun durable-note-association-key (definition)
  (list (getf definition :source)
        (getf definition :predicate)
        (getf definition :target)))

(defun dmx-learning-association-definitions ()
  (remove-if-not
   (lambda (definition)
     (member (durable-note-association-key definition)
             *dmx-learning-association-keys*
             :test #'equal))
   (durable-note-all-association-definitions)))

(defun dmx-operation-reader-surface-association-definitions ()
  (durable-note-association-definitions-for-keys
   *dmx-operation-reader-surface-association-keys*))

(defun durable-note-topic-payload-json (definition source-info)
  (let ((title (or (getf definition :title)
                   (getf source-info :source-title)
                   (getf definition :id))))
    (json-object
     :id (getf definition :id)
     :type (dmx-token-string (getf definition :type))
     :title title
     :source (getf definition :source)
     :source-reference (getf definition :source-reference)
     :source-title (getf source-info :source-title)
     :source-bytes (getf source-info :source-bytes)
     :page-hint (getf definition :page-hint)
     :commit-anchor (getf definition :commit-anchor)
     :projection-status (dmx-token-string (getf definition :projection-status))
     :also-known-as (getf definition :also-known-as)
     :canonical-example (getf definition :canonical-example)
     :summary (getf definition :summary))))

(defun durable-note-association-payload-json (definition)
  (json-object
   :source (getf definition :source)
   :predicate (getf definition :predicate)
   :target (getf definition :target)
   :source-artifact (getf definition :source-artifact)
   :projection-status
   (dmx-token-string
    (or (getf definition :projection-status)
        :seeded-from-shop3-plan))))

(defun materialize-durable-note-topic
    (db-path definition &key (replace-existing? t))
  (let* ((source-info (durable-note-source-info (getf definition :source)))
         (missing-source? (and (getf definition :source)
                               (not (getf source-info :exists-p))))
         (topic-id (getf definition :id))
         (title (or (getf definition :title)
                    (getf source-info :source-title)
                    topic-id)))
    (if missing-source?
        (list :id topic-id
              :state :missing-source
              :source (getf definition :source))
        (let* ((state
                 (record-dmx-topic-value
                  db-path
                  topic-id
                  (durable-note-topic-type-uri (getf definition :type))
                  title
                  :uri (durable-note-topic-uri topic-id)
                  :payload-json
                  (durable-note-topic-payload-json definition source-info)
                  :sync-state "local"
                  :replace-existing? replace-existing?)))
          (list :id topic-id
                :state state
                :source (getf definition :source))))))

(defun durable-note-association-players-present-p (db-path definition)
  (and (dmx-sql-object-exists-p db-path (getf definition :source))
       (dmx-sql-object-exists-p db-path (getf definition :target))))

(defun materialize-durable-note-association
    (db-path definition &key (replace-existing? t))
  (let ((assoc-id (durable-note-association-id definition)))
    (if (not (durable-note-association-players-present-p db-path definition))
        (list :id assoc-id
              :state :missing-player
              :source (getf definition :source)
              :target (getf definition :target))
        (list :id assoc-id
              :state
              (record-dmx-association-value
               db-path
               assoc-id
               (durable-note-association-type-uri
                (getf definition :predicate))
               :players
               (topic-association-players
                (getf definition :source)
                "dmx.role.player1"
                (getf definition :target)
                "dmx.role.player2")
               :value (getf definition :predicate)
               :payload-json (durable-note-association-payload-json definition)
               :replace-existing? replace-existing?)
              :source (getf definition :source)
              :predicate (getf definition :predicate)
              :target (getf definition :target)))))

(defun durable-note-known-seed-notes ()
  (loop for (source topic-id) in *durable-note-materialization-seed-notes*
        for info = (durable-note-source-info source)
        collect (list :source source
                      :topic-id topic-id
                      :exists-p (getf info :exists-p)
                      :source-title (getf info :source-title)
                      :pathname (getf info :pathname))))

(defun durable-note-missing-seed-notes ()
  (remove-if (lambda (note) (getf note :exists-p))
             (durable-note-known-seed-notes)))

(defun durable-note-present-topic-ids (db-path topic-ids)
  (when topic-ids
    (mapcar
     #'first
     (dmx-sqlite-query-rows
      db-path
      (format nil
            "select local_id from dmx_sql_object where object_kind = 'topic' and ~A order by local_id;"
            (dmx-sqlite-string-in-clause "local_id" topic-ids))))))

(defun durable-note-association-definitions-for-keys (keys)
  (remove-if-not
   (lambda (definition)
     (member (durable-note-association-key definition) keys :test #'equal))
   (durable-note-all-association-definitions)))

(defun durable-note-object-rows-by-id (db-path object-kind local-ids)
  (when local-ids
    (dmx-sqlite-object-rows
     db-path
     :where (format nil "~A and ~A"
                    (sql-is-clause "object_kind" object-kind)
                    (dmx-sqlite-string-in-clause "local_id" local-ids))
     :order-by "local_id")))

(defun durable-note-row-for-id (rows local-id)
  (find local-id rows
        :key (lambda (row) (getf row :local-id))
        :test #'equal))

(defun durable-note-association-ids (definitions)
  (mapcar #'durable-note-association-id definitions))

(defun durable-note-present-association-ids (db-path definitions)
  (mapcar (lambda (row) (getf row :local-id))
          (durable-note-object-rows-by-id
           db-path
           "assoc"
           (durable-note-association-ids definitions))))

(defun durable-note-materialized-topic-count (db-path)
  (length
    (durable-note-present-topic-ids
    db-path
    (mapcar (lambda (definition) (getf definition :id))
            (durable-note-all-topic-definitions)))))

(defun durable-note-materialized-association-count (db-path)
  (length
   (durable-note-present-association-ids
    db-path
    (durable-note-all-association-definitions))))

(defun durable-note-missing-topic-ids (db-path topic-ids)
  (let ((present-topic-ids (durable-note-present-topic-ids db-path topic-ids)))
    (remove-if (lambda (topic-id)
                 (member topic-id present-topic-ids :test #'equal))
               topic-ids)))

(defun durable-note-missing-association-ids (db-path definitions)
  (let ((present-association-ids
          (durable-note-present-association-ids db-path definitions)))
    (remove-if (lambda (assoc-id)
                 (member assoc-id present-association-ids :test #'equal))
               (durable-note-association-ids definitions))))

(defun durable-note-materialization-validation (db-path)
  (let* ((db-exists? (probe-file db-path))
         (missing-notes (durable-note-missing-seed-notes))
         (missing-topics
           (if db-exists?
               (durable-note-missing-topic-ids
                db-path
                (durable-note-required-topic-ids))
               (durable-note-required-topic-ids)))
         (missing-associations
           (if db-exists?
               (durable-note-missing-association-ids
                db-path
                (durable-note-all-association-definitions))
               (mapcar #'durable-note-association-id
                       (durable-note-all-association-definitions))))
         (passed? (and db-exists?
                       (null missing-notes)
                       (null missing-topics)
                       (null missing-associations))))
    (list :status (if passed? :passed :failed)
          :db-exists-p (and db-exists? t)
          :missing-notes missing-notes
          :missing-required-topics missing-topics
          :missing-required-associations missing-associations)))

(defun durable-note-materialization-status
    (&key (db-path *dreyeck-dmx-production-db-path*))
  "Return a structured, inspectable status object for this materialization."
  (let* ((db-exists? (probe-file db-path))
         (validation (durable-note-materialization-validation db-path)))
    (list :kind :durable-note-materialization-status
          :production-db-path (namestring db-path)
          :production-db-exists-p (and db-exists? t)
          :known-seed-notes (durable-note-known-seed-notes)
          :materialized-topic-count
          (if db-exists?
              (durable-note-materialized-topic-count db-path)
              0)
          :materialized-association-count
          (if db-exists?
              (durable-note-materialized-association-count db-path)
              0)
          :missing-notes (getf validation :missing-notes)
          :last-validation-status (getf validation :status)
          :validation validation)))

(defun dmx-materialized-learning-topic-entry (topic-id row)
  (let* ((definition (durable-note-topic-definition topic-id))
         (source-info (durable-note-source-info (getf definition :source))))
    (list :id topic-id
          :present-p (and row t)
          :title (or (getf row :value)
                     (getf definition :title)
                     topic-id)
          :topic-type (getf definition :type)
          :type-uri (getf row :type-uri)
          :source (getf definition :source)
          :source-reference (getf definition :source-reference)
          :source-exists-p (getf source-info :exists-p)
          :page-hint (getf definition :page-hint)
          :projection-status (getf definition :projection-status)
          :summary (getf definition :summary)
          :db-object row)))

(defun dmx-materialized-learning-association-entry (definition row)
  (let ((association-id (durable-note-association-id definition)))
    (list :id association-id
          :present-p (and row t)
          :source (getf definition :source)
          :predicate (getf definition :predicate)
          :target (getf definition :target)
          :type-uri (getf row :type-uri)
          :db-object row)))

(defun dmx-materialized-learning-topics
    (&key (db-path *dreyeck-dmx-production-db-path*))
  "Return the materialized learning-topic subset from the DMX production store.

This is a read-only inspection query. Materialization and replay checks stay in
the build task layer that calls the existing materializer."
  (let* ((db-exists? (probe-file db-path))
         (status (durable-note-materialization-status :db-path db-path))
         (learning-topic-ids *dmx-learning-topic-ids*)
         (support-topic-ids *dmx-learning-support-topic-ids*)
         (all-topic-ids (append learning-topic-ids support-topic-ids))
         (topic-rows
           (and db-exists?
                (durable-note-object-rows-by-id db-path "topic" all-topic-ids)))
         (learning-association-definitions
           (dmx-learning-association-definitions))
         (association-rows
           (and db-exists?
                (durable-note-object-rows-by-id
                 db-path
                 "assoc"
                 (durable-note-association-ids
                  learning-association-definitions))))
         (learning-topics
           (loop for topic-id in learning-topic-ids
                 collect
                 (dmx-materialized-learning-topic-entry
                  topic-id
                  (durable-note-row-for-id topic-rows topic-id))))
         (support-topics
           (loop for topic-id in support-topic-ids
                 collect
                 (dmx-materialized-learning-topic-entry
                  topic-id
                  (durable-note-row-for-id topic-rows topic-id))))
         (learning-associations
           (loop for definition in learning-association-definitions
                 for association-id = (durable-note-association-id definition)
                 collect
                 (dmx-materialized-learning-association-entry
                  definition
                  (durable-note-row-for-id association-rows association-id))))
         (missing-learning-topic-ids
           (loop for topic in learning-topics
                 unless (getf topic :present-p)
                   collect (getf topic :id)))
         (missing-learning-association-ids
           (loop for association in learning-associations
                 unless (getf association :present-p)
                   collect (getf association :id)))
         (passed? (and (eq :passed (getf status :last-validation-status))
                       (null missing-learning-topic-ids)
                       (null missing-learning-association-ids))))
    (list :kind :dmx-materialized-learning-topics
          :status (if passed? :passed :failed)
          :production-db-path (namestring db-path)
          :production-db-exists-p (and db-exists? t)
          :materialization-status status
          :last-validation-status (getf status :last-validation-status)
          :last-replay-status :not-run
          :learning-topic-ids learning-topic-ids
          :support-topic-ids support-topic-ids
          :topics learning-topics
          :support-topics support-topics
          :associations learning-associations
          :missing-learning-topic-ids missing-learning-topic-ids
          :missing-learning-association-ids
          missing-learning-association-ids)))

(defun dmx-materialized-operation-reader-surface-topics
    (&key (db-path *dreyeck-dmx-production-db-path*))
  "Return the materialized operation-reader-surface topic cluster."
  (let* ((db-exists? (probe-file db-path))
         (status (durable-note-materialization-status :db-path db-path))
         (topic-ids *dmx-operation-reader-surface-topic-ids*)
         (topic-rows
           (and db-exists?
                (durable-note-object-rows-by-id db-path "topic" topic-ids)))
         (association-definitions
           (dmx-operation-reader-surface-association-definitions))
         (association-rows
           (and db-exists?
                (durable-note-object-rows-by-id
                 db-path
                 "assoc"
                 (durable-note-association-ids association-definitions))))
         (topics
           (loop for topic-id in topic-ids
                 collect
                 (dmx-materialized-learning-topic-entry
                  topic-id
                  (durable-note-row-for-id topic-rows topic-id))))
         (associations
           (loop for definition in association-definitions
                 for association-id = (durable-note-association-id definition)
                 collect
                 (dmx-materialized-learning-association-entry
                  definition
                  (durable-note-row-for-id association-rows association-id))))
         (missing-topic-ids
           (loop for topic in topics
                 unless (getf topic :present-p)
                   collect (getf topic :id)))
         (missing-association-ids
           (loop for association in associations
                 unless (getf association :present-p)
                   collect (getf association :id)))
         (passed? (and (eq :passed (getf status :last-validation-status))
                       (null missing-topic-ids)
                       (null missing-association-ids))))
    (list :kind :dmx-materialized-operation-reader-surface-topics
          :status (if passed? :passed :failed)
          :production-db-path (namestring db-path)
          :production-db-exists-p (and db-exists? t)
          :materialization-status status
          :last-validation-status (getf status :last-validation-status)
          :topic-ids topic-ids
          :association-keys *dmx-operation-reader-surface-association-keys*
          :topics topics
          :associations associations
          :missing-topic-ids missing-topic-ids
          :missing-association-ids missing-association-ids)))

(defun dmx-materialized-domkin-2017-source-topics
    (&key (db-path *dreyeck-dmx-production-db-path*))
  "Return the materialized Domkin 2017 ASDF source-topic subgraph."
  (let* ((db-exists? (probe-file db-path))
         (status (durable-note-materialization-status :db-path db-path))
         (source-topic-ids *domkin-2017-source-topic-ids*)
         (source-association-definitions
           (durable-note-association-definitions-for-keys
            *domkin-2017-source-association-keys*))
         (topic-rows
           (and db-exists?
                (durable-note-object-rows-by-id
                 db-path
                 "topic"
                 source-topic-ids)))
         (association-rows
           (and db-exists?
                (durable-note-object-rows-by-id
                 db-path
                 "assoc"
                 (durable-note-association-ids
                  source-association-definitions))))
         (topics
           (loop for topic-id in source-topic-ids
                 collect
                 (dmx-materialized-learning-topic-entry
                  topic-id
                  (durable-note-row-for-id topic-rows topic-id))))
         (associations
           (loop for definition in source-association-definitions
                 for association-id = (durable-note-association-id definition)
                 collect
                 (dmx-materialized-learning-association-entry
                  definition
                  (durable-note-row-for-id association-rows association-id))))
         (missing-topic-ids
           (loop for topic in topics
                 unless (getf topic :present-p)
                   collect (getf topic :id)))
         (missing-association-ids
           (loop for association in associations
                 unless (getf association :present-p)
                   collect (getf association :id)))
         (topic-count (count-if (lambda (topic)
                                  (getf topic :present-p))
                                topics))
         (association-count
           (count-if (lambda (association)
                       (getf association :present-p))
                     associations))
         (passed? (and (eq :passed (getf status :last-validation-status))
                       (null missing-topic-ids)
                       (null missing-association-ids))))
    (list :kind :dmx-materialized-domkin-2017-source-topics
          :source "domkin-2017"
          :title
          "Loading Multiple Versions of an ASDF System in the Same Lisp Image"
          :production-db-path (namestring db-path)
          :production-db-exists-p (and db-exists? t)
          :status (if passed? :passed :failed)
          :materialization-status status
          :topic-count topic-count
          :expected-topic-count (length source-topic-ids)
          :association-count association-count
          :expected-association-count
          (length *domkin-2017-source-association-keys*)
          :missing-topic-ids missing-topic-ids
          :missing-association-ids missing-association-ids
          :topics topics
          :associations associations
          :source-artifact *domkin-2017-source-artifact*)))

(defun materialize-durable-notes-into-production-db
    (&key (db-path *dreyeck-dmx-production-db-path*) (replace-existing? t))
  "Materialize the canonical durable Markdown-note seed set into the DMX store.

The operation is idempotent: replaying it returns :UNCHANGED for topic and
association rows whose content already matches the seed definitions."
  (initialize-dmx-associative-mirror :db-path db-path)
  (let ((topic-results
          (loop for definition in (durable-note-all-topic-definitions)
                collect
                (materialize-durable-note-topic
                 db-path definition
                 :replace-existing? replace-existing?)))
        (association-results
          (loop for definition in (durable-note-all-association-definitions)
                collect
                (materialize-durable-note-association
                 db-path definition
                 :replace-existing? replace-existing?))))
    (list :kind :durable-note-materialization
          :production-db-path (namestring db-path)
          :topic-results topic-results
          :association-results association-results
          :status (durable-note-materialization-status :db-path db-path))))
