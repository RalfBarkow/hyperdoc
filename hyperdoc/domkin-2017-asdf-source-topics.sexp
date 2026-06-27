(:source-reading
 (:id domkin-2017-asdf-source-topics)
 (:title "Domkin 2017 ASDF Source Topics")
 (:type :dmx-source-reading)
 (:source-paper domkin-2017)
 (:paper-title "Loading Multiple Versions of an ASDF System in the Same Lisp Image")
 (:author "Vsevolod Domkin")
 (:venue "European Lisp Symposium 2017")
 (:local-pdf
  "/Users/rgb/Zotero/storage/AYP7XXH7/Domkin - 2017 - Loading Multiple Versions of an ASDF System in the Same Lisp Image..pdf")
 (:article-pages "ELS 2017 pages 10-18")
 (:pdf-pages "local proceedings PDF pages 16-26")

 :reading-notes
 ((:span "ELS 2017 pages 10-11"
   :note "The paper frames Common Lisp dependency hell as build failure or unintended redefinition caused by incompatible artifacts or versions sharing package names.")
  (:span "ELS 2017 pages 11-13"
   :note "The proposed mechanism uses Common Lisp package renaming and an ASDF-compatible dependency traversal to load conflicting versions in a safe order.")
  (:span "ELS 2017 pages 14-16"
   :note "The ASDF critique centers on the unversioned system registry, side-effecting internals, undocumented plan and caching APIs, and missing public middle-level operations.")
  (:span "ELS 2017 pages 16-18"
   :note "The limitations concern nontransactional package capture, interactive session assumptions, monkey-patching, implicit transitive dependencies, duplicate name/version cases, and runtime package lookup through INTERN or EVAL.")
  (:span "ELS 2017 page 18"
   :note "The future-work section asks ASDF to expose better public APIs, documented plan/action APIs, and decoupled middle-level operations."))

 :topics
 ((:topic domkin-2017-loading-multiple-asdf-versions
   :type :source-paper
   :title "Loading Multiple Versions of an ASDF System in the Same Lisp Image"
   :source "Domkin 2017, ELS"
   :span "ELS 2017 pages 10-18"
   :summary "Domkin presents a proof-of-concept for consecutive loading of several versions of the same ASDF system in one Lisp image by renaming packages to avoid package-name conflicts.")
  (:topic common-lisp-dependency-hell
   :type :problem
   :title "Common Lisp Dependency Hell"
   :source "Domkin 2017"
   :span "ELS 2017 page 10"
   :summary "Multiple libraries or versions may require incompatible artifacts with the same names, causing build failure or silent/vocal redefinition of functionality.")
  (:topic package-name-conflict
   :type :problem
   :title "Package Name Conflict"
   :source "Domkin 2017"
   :span "ELS 2017 pages 10-11"
   :summary "Common Lisp packages are globally registered dynamic objects, so loading two artifacts that define packages with the same names or nicknames can redefine or extend an existing package unexpectedly.")
  (:topic global-package-registry
   :type :common-lisp-mechanism
   :title "Global Package Registry"
   :source "Domkin 2017"
   :span "ELS 2017 page 10"
   :summary "The running Lisp image has a centralized registry of known packages; this is the substrate on which package-name conflicts appear.")
  (:topic asdf-unversioned-system-registry
   :type :asdf-limitation
   :title "ASDF Unversioned System Registry"
   :source "Domkin 2017"
   :span "ELS 2017 page 11"
   :summary "ASDF keeps a central registry of known systems keyed by unversioned system names, so at a given moment only one version of a system is accessible to ASDF.")
  (:topic package-renaming-conflict-resolution
   :type :solution-strategy
   :title "Package Renaming Conflict Resolution"
   :source "Domkin 2017"
   :span "ELS 2017 pages 11-13"
   :summary "Rename packages belonging to a loaded version before loading another conflicting version, so package-level names do not collide.")
  (:topic rename-package-as-low-level-mechanism
   :type :common-lisp-mechanism
   :title "RENAME-PACKAGE as Low-Level Conflict Mechanism"
   :source "Domkin 2017"
   :span "ELS 2017 page 11"
   :summary "Common Lisp's RENAME-PACKAGE function is the low-level operation used to avoid package name clashes by changing references before another artifact is initialized.")
  (:topic load-system-with-renamings
   :type :algorithm
   :title "LOAD-SYSTEM-WITH-RENAMINGS"
   :source "Domkin 2017"
   :span "ELS 2017 pages 13-14"
   :summary "Domkin's proof-of-concept loading procedure builds a dependency tree, detects version conflicts, orders dependencies, loads components, records package additions, and performs package renamings at selected points.")
  (:topic dependency-tree-conflict-analysis
   :type :algorithmic-step
   :title "Dependency Tree Conflict Analysis"
   :source "Domkin 2017"
   :span "ELS 2017 pages 12-13"
   :summary "The algorithm traverses ASDF dependency information to discover conflicting systems and locate where renaming must occur in the dependency hierarchy.")
  (:topic topological-load-order-with-load-last-conflict-strategy
   :type :algorithmic-step
   :title "Topological Load Order with Load-Last Conflict Strategy"
   :source "Domkin 2017"
   :span "ELS 2017 page 13"
   :summary "The algorithm uses a topological load order and loads conflict-resolution dependencies last among siblings so renaming happens before a later conflicting load would collide.")
  (:topic post-load-package-capture
   :type :algorithmic-step
   :title "Post-Load Package Capture"
   :source "Domkin 2017"
   :span "ELS 2017 pages 13-14"
   :summary "During loading, newly added packages are recorded after the fact and associated with the system being loaded, allowing later renaming of packages belonging to that system.")
  (:topic asdf-public-api-gap
   :type :asdf-limitation
   :title "ASDF Public API Gap"
   :source "Domkin 2017"
   :span "ELS 2017 pages 14-16"
   :summary "Domkin argues that ASDF lacks public APIs needed for alternative system manipulation strategies such as loading from a specific filesystem location, enumerating candidate locations, selecting a version, or reading an ASD without global state changes.")
  (:topic asdf-plan-api-underdocumented
   :type :asdf-limitation
   :title "ASDF Plan API Underdocumented"
   :source "Domkin 2017"
   :span "ELS 2017 page 14"
   :summary "Domkin notes that ASDF operations are performed according to a plan object, but the plan API is not clearly documented.")
  (:topic asdf-caching-underdocumented
   :type :asdf-limitation
   :title "ASDF Caching Underdocumented"
   :source "Domkin 2017"
   :span "ELS 2017 page 14"
   :summary "Domkin identifies ASDF caching behavior as insufficiently documented for alternative build/loading strategies.")
  (:topic asdf-monolithic-loading-strategy
   :type :asdf-limitation
   :title "ASDF Monolithic Loading Strategy"
   :source "Domkin 2017"
   :span "ELS 2017 page 14"
   :summary "ASDF is described as a tightly-coupled tool tuned toward a particular system-handling strategy, making alternative strategies hard to implement on public APIs alone.")
  (:topic alternative-asdf-system-strategies
   :type :asdf-design-goal
   :title "Alternative ASDF System Strategies"
   :source "Domkin 2017"
   :span "ELS 2017 pages 14-18"
   :summary "Alternative ASDF strategies include non-default system discovery, loading, version selection, and component manipulation workflows that should be expressible through public APIs.")
  (:topic production-build-dependency-immutability
   :type :design-assumption
   :title "Production Build Dependency Immutability"
   :source "Domkin 2017"
   :span "ELS 2017 pages 11 and 16"
   :summary "Domkin's approach targets production-like environments where the whole target system is loaded and dependencies are not later modified in memory.")
  (:topic nontransactional-package-capture-limitation
   :type :limitation
   :title "Nontransactional Package Capture Limitation"
   :source "Domkin 2017"
   :span "ELS 2017 page 16"
   :summary "The package-capture mechanism records global package table changes after the fact and is not transactional; parallel loading can race unless protected.")
  (:topic preexisting-package-discipline-limitation
   :type :limitation
   :title "Preexisting Package Discipline Limitation"
   :source "Domkin 2017"
   :span "ELS 2017 page 17"
   :summary "The approach assumes packages from loaded systems were not previously defined, which is reasonable in a vanilla production environment but can fail in interactive sessions.")
  (:topic monkey-patching-limitation
   :type :limitation
   :title "Monkey-Patching Limitation"
   :source "Domkin 2017"
   :span "ELS 2017 page 17"
   :summary "The procedure does not catch changes to existing packages, a limitation related to interactive monkey-patching or hot-patching.")
  (:topic implicit-transitive-dependency-limitation
   :type :limitation
   :title "Implicit Transitive Dependency Limitation"
   :source "Domkin 2017"
   :span "ELS 2017 page 17"
   :summary "Implicit dependencies can break when a transitive dependency's packages are renamed before a depending system reads references to their old names; explicit dependencies are the straightforward repair.")
  (:topic same-name-same-version-social-limitation
   :type :limitation
   :title "Same Name Same Version Social Limitation"
   :source "Domkin 2017"
   :span "ELS 2017 page 17"
   :summary "Two independent packages with the same name and version are not addressed by the code-level approach and may require social or repository-level resolution.")
  (:topic runtime-intern-eval-renaming-limitation
   :type :limitation
   :title "Runtime INTERN/EVAL Renaming Limitation"
   :source "Domkin 2017"
   :span "ELS 2017 page 17"
   :summary "Code relying on runtime package lookup through INTERN or unevaluated EVAL references can break because renamed packages are no longer available under canonical names.")
  (:topic asdf-api-future-work
   :type :future-work
   :title "ASDF API Future Work"
   :source "Domkin 2017"
   :span "ELS 2017 page 18"
   :summary "Domkin argues ASDF should expose better public APIs, deeper version support, documented plan/action APIs, decoupled internals, and utility wrappers for middle-level operations.")
  (:topic hyperdoc-asdf-session-action-reading
   :type :hyperdoc-reading
   :title "HyperDoc Reading of Domkin's ASDF Session/Action Model"
   :source "Domkin 2017"
   :span "ELS 2017 pages 14 and 18"
   :summary "For HyperDoc, Domkin's critique motivates an explicit, inspectable plan/check/perform/referee layer rather than hiding ASDF-like action selection inside an opaque build tool."))

 :associations
 ((:association domkin-2017 describes domkin-2017-loading-multiple-asdf-versions)
  (:association domkin-2017-loading-multiple-asdf-versions addresses common-lisp-dependency-hell)
  (:association common-lisp-dependency-hell manifests-as package-name-conflict)
  (:association package-name-conflict occurs-in global-package-registry)
  (:association package-renaming-conflict-resolution uses rename-package-as-low-level-mechanism)
  (:association load-system-with-renamings implements package-renaming-conflict-resolution)
  (:association load-system-with-renamings performs dependency-tree-conflict-analysis)
  (:association load-system-with-renamings uses topological-load-order-with-load-last-conflict-strategy)
  (:association load-system-with-renamings records post-load-package-capture)
  (:association load-system-with-renamings assumes production-build-dependency-immutability)
  (:association asdf-unversioned-system-registry contributes-to common-lisp-dependency-hell)
  (:association asdf-public-api-gap limits load-system-with-renamings)
  (:association asdf-plan-api-underdocumented limits alternative-asdf-system-strategies)
  (:association asdf-caching-underdocumented limits alternative-asdf-system-strategies)
  (:association asdf-monolithic-loading-strategy explains asdf-public-api-gap)
  (:association nontransactional-package-capture-limitation constrains load-system-with-renamings)
  (:association preexisting-package-discipline-limitation constrains load-system-with-renamings)
  (:association monkey-patching-limitation constrains load-system-with-renamings)
  (:association implicit-transitive-dependency-limitation constrains load-system-with-renamings)
  (:association runtime-intern-eval-renaming-limitation constrains load-system-with-renamings)
  (:association same-name-same-version-social-limitation constrains package-renaming-conflict-resolution)
  (:association asdf-api-future-work responds-to asdf-public-api-gap)
  (:association asdf-api-future-work responds-to asdf-plan-api-underdocumented)
  (:association asdf-3-3-session-action-model described-by domkin-2017)
  (:association plan-then-perform-build-session inspired-by hyperdoc-asdf-session-action-reading)
  (:association hyperdoc-asdf-session-action-reading derived-from domkin-2017-loading-multiple-asdf-versions)
  (:association build-referee-decision-route responds-to asdf-plan-api-underdocumented)
  (:association lisp-referee-form responds-to asdf-monolithic-loading-strategy)))
