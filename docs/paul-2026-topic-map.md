# Paul (2026): source-backed Topic Map merge with HyperDoc

## Scope and authority

Taylor H. Paul, *A Network Model for the Automated Planning and Scheduling of Pipelined Workflows*, University of Maryland, College Park, PhD dissertation (2026). The supplied 259-page PDF is the evidence for the manually curated claims below; its printed page numbers differ from PDF page indices. [Publisher record](https://search.proquest.com/openview/04c374e7775805391be20977693d1056/1). The dissertation points to [taylorpaul/WORKSWORLD](https://github.com/taylorpaul/WORKSWORLD) in its Contributions (p. 9). That source code is **not** part of this change.

This small reading adds no planner domain, PDDL translation, Kubernetes controller, remote protocol, runtime executor, or repository-to-repository synchronization. The goal is to inspect the native TMDM representation of selected source claims beside the existing HyperDoc *Planning with SHOP3* subject.

## Authored sources and identities

- `dreyeck/work/paul-2026/hyperdoc-context.ctm`: a **new** small crosswalk over the existing HyperDoc file `dreyeck/pages/work/Planning with SHOP3.html` and `dreyeck/shop3/manual-topics.lisp`. It does **not** serialize an existing HyperDoc Work Topic.
- `dreyeck/work/paul-2026/paul-2026.ctm`: a manually extracted conceptual map of the dissertation. Every scholarly concept carries a printed-page Occurrence.
- Both independently declare SHOP3 with Subject Identifier `urn:hyperdoc:subject:shop3`. This is an intentionally shared, locally authored **subject identity**, not a published PSI or a claim that a HyperDoc page and a TMDM Topic are the same object.
- All dissertation-specific concepts use `urn:hyperdoc:paul-2026:...` Subject Identifiers. Their local item identifiers and any Type/Role Topics remain distinct from the HyperDoc source unless actual identity evidence is provided. Titles/names alone are not merge keys.

The `hyperdoc-context.ctm` record is an authored **derived crosswalk** to existing HyperDoc code and its *Planning with SHOP3* page. The quoted title and path are source-observed in that repository. The crosswalk's shared Subject Identifier is our explicit modeling decision.

## Dissertation warrants

| Concept or association | Printed pages | Evidence |
| --- | --- | --- |
| Resource graph: sites as vertices, intra-/intersite links | 66–67 | Definition 3.4.4; Eq. 3.5; Fig. 3.7 |
| Workflow request graph: DAG of data and processing components | 68–70 | Definitions 3.4.5–3.4.6; Eq. 3.6 |
| Interfaces DSI/DPI | 51–55, 63–64 | §§3.1.3–3.1.4, 3.4.2 |
| WORKSWORLD / WORKSWORLD-2 numeric domains | 78–90 | §§4.1–4.2 |
| WORKSWORLD-2H uses SHOP3 | 90–94 | §4.3, especially §4.3.1 and Tables 4.9–4.10 |
| `achieve-all-goals` and its method-level control flow | 91–95 | Fig. 4.2; Table 4.9; Algorithm 1 |
| `plan-source-delivery`: reuse / replicate / transform | 95–97 | §4.3.3; Table 4.11; Algorithm 1 |
| Topology phase and `commit-rate-flow` phase | 92–97 | Fig. 4.2; Algorithm 1 |
| Numeric versus hierarchical planner tradeoff | 159–175, 202–206 | §6.2, §8.1; performance is reported by Paul, **not remeasured here** |

All named concept and relation assertions in `paul-2026.ctm` are **source-observed manual selections** against these pages. The CTM abstraction is a **derived representation**, not Paul's own Topic Map. For example, `has-entry-method` identifies the top-level method and `calls` abstracts the Figure 4.2 control flow; `may-call` distinguishes the conditional `plan-source-delivery` → `commit-rate-flow` rate flush in recursive Transform cases. These relations are readings of Paul's algorithm, **not** a claim that every step is an immediate SHOP3 method-body subtask.

No inferred equivalence between a HyperDoc planning *task* and a WORKSWORLD *task* is asserted. New research connections can be added later with an explicit `inferred` or `hypothesized` warrant, while retaining the source-claim distinction.

## Native merge contract (not a diagram)

`dreyeck/work/paul-2026/merged-reading.lisp` uses the independent library directly:

1. `topic-maps.ctm:deserialize-file` reads two different CTM sources with distinct Document IRIs into two Maps.
2. `topic-maps.tmdm:import-map-content` transfers source content into the target Map and returns its native source-object resolver.
3. The pre-import target SHOP3 Topic stays `EQ` to the post-import target Topic. Resolving the independent source SHOP3 Topic returns that **same target object**.
4. A distinct WORKSWORLD-2H Topic is present; source Map remains a separate native Map. Native Association Roles can be followed in the existing `dreyeck/inspector/tmdm` views.

The original TMDM source and target are in-memory objects; the two CTM files are **not changed** and no second Topic/Association graph is constructed. The source/target object resolver is only meaningful during the same Lisp process. `topic-maps.tmdm:import-map-content` specifically excludes a source Map's own item identifiers; it is not a merge of two root Map items. See the independent [Map Content Import contract](https://github.com/RalfBarkow/topic-maps/blob/dreyeck.ch/docs/reading-map-content-import.md).

## Reproduce and verify

With the independent `topic-maps` ASDF source available from the pinned project environment:

```lisp
(asdf:load-system "dreyeck/work/paul-2026")
(multiple-value-bind (map source resolve)
    (dreyeck/work/paul-2026:read-merged-map)
  (declare (ignore resolve))
  (describe map)
  (describe source))
(asdf:test-system "dreyeck/work/paul-2026/tests")
```

Use the optional HyperDoc reading `Reading Paul 2026 with Topic Maps` and the existing native TMDM Inspector to navigate. Loading and tests do not run from the normal Catalog startup. No external services or download are implied by the CTM identifiers or URLs.

**Acceptance boundary:** validate actual parsing, native `EQ` identity, source nonmutation and resolvable WORKSWORLD-2H/SHOP3 Role players in a fresh Lisp. Static checks of the Lisp syntax or CTM text are **not** substitutes for this execution. If a test has not been run, record it as NOT-RUN, not PASS.
