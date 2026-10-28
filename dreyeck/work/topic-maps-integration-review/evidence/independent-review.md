**Independent review — Task 1C: TMDM normalization performance**  
28 October 2026. Read-only review; no candidate or HyperDoc source edits, staging, commits, merges, pushes, pin changes, Catalog changes or deployments.

Evidence labels: **Observed** means independently executed or directly inspected in this review. **Derived** means established by code reasoning under the stated API invariants. **Inferred** means supported by the measurements without claiming a proof outside the measured cases. **Hypothesized** means a possible unmeasured behavior.

1. **Candidate identity.**

   **Observed.** The actual worktree is `/Users/rgb/workspace/topic-maps-task-1c`, branch `claude/tmdm-normalization-perf-1c`, HEAD/base `b2eecffa05de4fce41c10ae1ada9ae11a0c6e7dc`. All three saved candidate diffs equal fresh `git diff HEAD` output for their corresponding scopes. The full patch reconstructs the actual candidate, with no directory differences after excluding `.git` and `reports`. All 29 manifest files match both the worktree and `files-at-review`.

   Manifest SHA-256: `221e51254ed00347904b7b7782a0b204118c8f38272f79dba1d1082df2dc5e88`. Candidate `src/tmdm/merging.lisp` SHA-256: `fc95fff61cb72c4417cac07f4b9b9a510fc3bd19ab3c526bf83c3fac3f961566`.

   **Observed.** Baseline, candidate and experimental trees were reconstructed separately from Git objects plus the preserved patches, using the inspected `build-trees.sh`. The candidate association source equals baseline byte for byte. The experimental association patch exists only in the separate experimental tree. I independently exported sibling reference `5a4a66850403cdfe2755c6c88083a8e31af89628` for the reference benchmark.

2. **Algorithmic correctness and index lifetime.**

   **Derived.** For distinct current Topics in a same-map graph, the key construction matches `equal-topics-p`: II and SI share a namespace; SL has its own namespace; equality is case-sensitive string equality. A single stored reifier slot cannot simultaneously contain two distinct current Topics, so the shared-reified-item clause adds no identity pair on this path. `equal` on these string-valued keys agrees with `string=`.

   **Derived.** Buckets are constructed in map order. For each Topic, `earlier` selects the smallest later position across keys. The first Topic with any nonconflicting partner returns immediately; otherwise the first ordinary pair is retained. This reproduces both nested scan orders and the baseline's nonconflicting-reifier preference, independently of hash traversal order. The conflict predicate agrees with the inverse lookup when each reifier has at most one current item.

   **Derived.** `scan-next-topic-merge` preserves the removed two-search logic, including first-search short circuit and the ready-pair predicate. Multiple items under a reifier or a forwarded listed Topic cause delegation to that scan; the index does not signal the reification error eagerly. The unchanged merge primitive still checks conflicts before replacement.

   **Derived.** The no-invalidation claim holds for this single-threaded API. `map-information-items`, raw identifier/reifier accessors and `canonical-topic` only read the graph; canonical forwarding performs no path compression. No search helper calls a writer, merge, normalization routine or user callback. Local tables and `flet` functions do not escape; the returned value contains only Topic references. `merge-two-topics` runs after the search returns. Its name/occurrence/association and reifier cascades can re-enter normalization, but they start fresh searches after the earlier index has ceased to be used. Import preflight works on a separate copied graph, then repeats on the original, each with separate indexes. Thus mutations between searches cannot leave an index in use. This is not a claim of concurrent mutation support; the existing import API explicitly excludes it.

   **Observed / Derived.** Forwarding and retained-handle code is unchanged. Existing cascade tests and the independent handle check below verify that Topic identity can still merge Associations/Roles while preserving their old handles and identifier unions.

3. **Tests, independent semantics and remaining gaps.**

   **Observed.** The focused system passed 120 checks on both reconstructed candidate and experimental trees. Candidate coverage reached 4,000 generated maps: 3,563 pairs, 374 no-pair states, 177 preference cases and 63 reification refusals, with zero differences. The 800 walks performed 2,433 merges, with 568 multi-merge walks and 610 fixed points. The 400 whole reads produced 233 successes and 167 refusals, 465 Topic merges and zero outcome/merge-count differences. M0 survived; all M1–M8 failed at the intended semantic assertions. The isolated M2 results are recorded separately below.

   **Observed.** I regenerated all 24 CXTM fixtures and the seven class/code rejection outcomes using unchanged baseline production source in a disposable tree, adding only the candidate test file and its ASDF declaration. Every expected fixture matched. This establishes baseline provenance independently of the original timestamps.

   **Observed.** The full existing suite exited zero on both baseline and candidate, without compiler warnings in these full-suite runs. All 25 report files are byte-identical; the only added PASS summary is the new 120-check suite. These suites retain their known baseline FAIL/NOT-RUN cases; success here establishes preservation, not complete standards conformance.

   **Derived.** Fixture replay proves baseline compatibility, not independent correctness of the baseline. The scan oracle shares `equal-topics-p`, `topic-reified`, mutation primitives, preflight copying and the serializer with the candidate. A defect in those shared components could survive all differential tests. The generator uses a fixed seed and mostly Names/Associations/map reification; it is not exhaustive over every item kind or graph. An arbitrary error terminating `merge-walk` is classified as merge refusal, so zero differences alone would be weak without the path floors and other tests. The killed mutants are eight specific perturbations, not proof against all incorrect implementations.

   **Derived / Observed.** Identity namespace rules, replacement/union behavior and distinct-reified-item conflict have independent support in the [public TMDM text, clauses 5.3.5 and 6.2](https://isotopicmaps.org/sam/sam-model/). Exact list-order selection and the ready-pair scheduling are baseline implementation policies; retained handle forwarding and atomic rejection are API policies. I added direct expected-pair tests for all nine identifier-kind combinations, string case/representation, first partner within a bucket and across key order; all six reifiable kinds in conflict/clear combinations; and retained Association/Role handles with identifier unions. Their final results appear below.

   **Observed / Inferred.** The real corpus exercises the no-pair path. Its output agreement cannot validate preference, refusal or cascading merge behavior; those rely on the separate source proof, semantic tests, fixtures, controls and existing suites.

4. **Independent reproduction.**

   All final results below come from reconstructed trees, fresh Lisp processes and isolated caches. Supplied scripts were inspected first. Copies of runner scripts were adapted only to keep generated files and caches in disposable paths. The original probe and benchmark code were preserved unchanged. My first temporary cache adaptation flattened source paths and caused a package-FASL collision; those startup runs were discarded. The final full-suite/focused/fixture runs use path-preserving caches, with separate logs.

   **Observed.** Host: Intel i5-8279U, 8 logical CPUs, 16 GiB RAM, macOS 15.8.1 (24H32). Default Lisp: SBCL 2.6.4, `/usr/local/bin/sbcl`; comparison Lisp: packaged SBCL 2.4.10. The probe uses document IRI `tag:dreyeck.ch,2026:hyperdoc/project.ctm`. Input SHA-256 was verified before and after the runs and again at review completion: `f4f04bb49ce3b762b3e1c0bccf9e177e11785d33db87e8c0d043b04820b540d3`.

   | Implementation | Read wall seconds | Read allocation, decimal GB | Whole-process peak RSS, decimal MB |
   |---|---:|---:|---:|
   | Unmodified b2eecffa, SBCL 2.6.4 | timeout at 120, exit 124 | unavailable | 128.3 |
   | Task 1C, SBCL 2.6.4, three runs | 31.413 / 28.990 / 27.665; median 28.990 | 4.966 per run | 102.47–102.51 |
   | Task 1C, SBCL 2.4.10, one run | 33.248 | 5.253 | 294.4 |
   | Experimental Task 1C + association index, one run | 8.907 | 5.650 | 107.6 |
   | Independently exported 5a4a668, one run | 7.579 | 4.878 | 117.8 |

   **Observed.** All six successful full-corpus reads have byte-identical semantic signatures and CXTM, compared directly with the newly run 5a4a668 and with the saved reference. Signature: 567,386 bytes, SHA-256 `4e8a07ba210faa368e7339e1666b3e534cbcf3461b277c22186b5afe75c1a02d`. CXTM: 392,172 bytes, SHA-256 `6f957018d93e7a4f9b8738042797f60a3d6c094134ef85f6ba40d30bfe03d8b9`. Every signature before CXTM equals its after-CXTM signature. Counts are 327 Topics, 572 Associations, 323 Names, 509 Occurrences, 1,144 Roles and 57 reifying Topics; counts are corroboration, not the equivalence criterion.

   **Observed / Derived.** A separate graph audit found zero Variants, 327 uniquely identified Topics and valid import/reference/reification invariants. The signature records the complete direct graph represented in this corpus, including identifiers, values, datatypes, scopes, role types/players and reifier relationships; Topic references have unambiguous identifier anchors, parent relationships are implicit in containment, and inverse reification was checked. The supplied probe's `item-ref` has no Variant branch, so its explicit inverse description is not generally complete for reified Variants. This omission is inactive in this corpus; my separate six-kind selection tests cover Variant reifiers. Do not generalize this probe into a universal graph-isomorphism proof.

   | Real corpus slice | Unmodified baseline read | Candidate read | Complete signature and CXTM |
   |---|---:|---:|---|
   | R3 | 111.475 s | 0.492 s | byte-identical |
   | R8 | 152.317 s | 0.510 s | byte-identical |

   **Observed.** The independent semantic supplement passed 77 explicit checks. The isolated stale-reification-cache mutant M2 fails both random invalidation walks and direct reifier-mutation assertions; the stale-Topic-handle assertions alone survive M2, as expected for their narrower purpose. The bounded shadow reproduction read the entire corpus, observed 7,511 searches and zero pairs, and compared 18 evenly sampled no-pair searches with the old scan: zero mismatches, 58.8 seconds of oracle work, 85.6 seconds total including shadow work. This does not reproduce the historical 187 sampled comparisons.

   Reproduction details: [suite results](/private/tmp/task1c-independent-review-96ln4s4u/suite-results-correct.json), [candidate benchmark](/private/tmp/task1c-independent-review-96ln4s4u/bench/candidate/summary.json), [independent checks and microbenchmarks](/private/tmp/task1c-independent-review-96ln4s4u/independent-checks.log), [shadow log](/private/tmp/task1c-independent-review-96ln4s4u/shadow-reduced.log), [final integrity](/private/tmp/task1c-independent-review-96ln4s4u/final-integrity.json).

5. **Performance assessment.**

   **Observed.** The fresh baseline profile timed out after 45 seconds and attributed 98.5% inclusive samples to `equal-topics-p` (56.1% to `map-information-items`). The fresh candidate profile completed its read in 26.014 seconds: association normalization 72.7% inclusive, `next-topic-merge` 6.2%, `copy-map-graph` 8.6%, `map-information-items` 6.8% (inclusive costs overlap). It recorded 7,511 searches, zero Topic pairs, zero Topic merges and zero Association merges. This independently reproduces the reported bottleneck shift. Profile timings are instrumented and are not included in the three-run benchmark median.

   **Observed.** Synthetic small-map tests expose a constant-factor tradeoff. These are single repeated batches, using the same candidate merge code with only the old search substituted for the comparison:

   | Synthetic workload | Old scan | Index | Interpretation |
   |---|---:|---:|---|
   | Two Topics, no pair, per search | 0.420 µs | 1.424 µs | index ~3.4× slower, +1.0 µs |
   | Eight Topics, immediate pair, per search | 1.898 µs | 4.074 µs | index ~2.1× slower |
   | 32 Topics, no pair, per search | 951.857 µs | 20.827 µs | index ~45.7× faster |
   | Normalize 16 equal Topics, per map | 0.096 ms | 0.149 ms | index ~1.54× slower |
   | Normalize 64 equal Topics, per map | 1.104 ms | 1.740 ms | index ~1.58× slower |
   | Normalize 256 equal Topics, per map | 15.402 ms | 25.557 ms | index ~1.66× slower |

   **Observed / Inferred.** These raw, all-duplicate stress maps do not represent ordinary already-normalized public input. They nevertheless refute a universal speedup claim. The 256-Topic normalization batch also allocated about 14.09 MB per map with the index versus 9.03 MB with the scan. The extra work is measurable but small in these absolute cases, while the target corpus and both corpus slices improve dramatically. I do not consider it disproportionate enough to block this bounded Task 1C commit. No small-map fast path was implemented.


   **Derived.** The optimization removes the repeated O(Topics² × information-items) inverse lookups on the common no-equal-pair path. Expected hash lookup cost is constant; enumerating items and building keys still happens on every call. Bucket scans can be quadratic when many Topics share a key or many candidates conflict. The report's blanket linear build-cost description should be read with qualifications: per-Topic `remove-duplicates` and string hashing/comparison have their own costs; ANSI Common Lisp does not promise linear duplicate elimination. No persistent-memory growth from a retained index was introduced.

   **Inferred / Hypothesized.** The measured corpus meets the 90-second read requirement and misses the approximately 20-second aspiration. This does not establish universal speedup, Linux/production timing, behavior with very large identifier sets, or a general low overhead bound on early-pair-heavy inputs. The small-map measurements below make the observed tradeoff explicit; no additional optimization is proposed.

6. **Evidence integrity and integration boundary.**

   **Observed.** The supplied evidence directory has 251 files. All checked README/handoff/guide evidence paths and all 29 files in its candidate manifest exist. There is no checksum manifest for the entire evidence directory; the supplied SHA-256 manifest covers the candidate only. I saved a separate full content-hash inventory and source manifests in this review directory. Acceptance depends on exact patch/file comparison, independently exported sources, fresh results and byte comparisons, not timestamps or check counts alone.

   **Observed.** The benchmark script reports child return codes/equality booleans but does not fail solely because the reader timed out or equality was false. I inspected the individual results and output bytes rather than using the Python process exit code as the acceptance signal. A baseline timeout has no complete output and establishes no full-corpus semantic comparison against b2eecffa. The slice comparisons below provide direct baseline checks; the full corpus has the separately reproduced 5a4a668 comparison.

   **Observed, historical evidence only.** I inspected `1b-inputs/workspace.lisp` and `logs/workspace/workspace-candidate.log`. The harness loads Project Workspace under SBCL 2.4.10, records the actual dirty/unpinned candidate source identity, reads the original digest without refusal in 32.653 seconds, checks model counts 55 declarations / 57 statements / 4 assignments / 40 gaps / 4 sources and source text equality, builds 148 projection Topics / 286 edges, navigates eight known keys through workspace APIs, and compares a second in-memory octet read by bytes and CXTM. This supports source-level parser/model/projection/navigation/revision compatibility on that Mac.

   **Derived.** The snapshot-verification branch of that harness executes only for a Nix-store source; it was not executed for this dirty worktree. The run does not validate a packaged Git-free candidate snapshot, pin verification, Linux runtime, the production host, HTTP/browser Inspector navigation, browser rendering, or every navigation path. Eight Lisp API navigations cannot establish a complete Inspector browser flow.

   **Observed.** I did not repeat that Project Workspace execution, the original full 187-sample shadow run, or the exact historical timing repetitions. New measurements are distinguished above. Optional XTM integration, a packaged Git-free snapshot, Linux/production and browser Inspector navigation remain unrun. The experimental tree received focused tests and a corpus benchmark only, not a Task 1E correctness/integration review. No Task 1E implementation or integration was performed.

7. **Defects and counterexamples.**

   **Observed / Derived.** No semantic defect or reproducible semantic counterexample was found for valid same-map graphs and the staged normalization states supported by the existing single-threaded API. Identifier strings, finite collections, unique Topic membership and same-map parent/reference invariants remain the domain of the argument. Arbitrarily malformed raw slots are not covered by a universal equivalence claim.

   **Observed.** There is a concrete performance counterexample to universal speedup: tiny/first-pair-heavy synthetic maps are slower, as quantified above. This is a nonblocking tradeoff, not evidence of changed normalization semantics. Nonblocking evidence/documentation qualifications are the candidate-only scope of the supplied manifest, the benchmark's reporting-only exit behavior, the probe's omitted explicit Variant inverse and the qualified complexity bound. None requires changing candidate production code for the stated local-commit goal.

8. **Recommendation and exact commit boundary.**

   **GO for a local Task 1C commit.**

   **Derived / Inferred.** The selection proof and mutation boundaries support semantic preservation; independently regenerated baseline expectations, existing reports, direct semantic checks, killed controls and complete corpus bytes agree. The fresh median read is 28.990 seconds, below the 90-second operational limit by about 3.1×; the approximately 20-second aspiration remains unmet. The small-map tradeoff and untested packaging/Linux/browser integration remain explicit limitations. There is no required source correction for this local commit recommendation.

   The intended local commit consists of exactly the 29 paths in [commit-files.txt](/private/tmp/task1c-independent-review-96ln4s4u/commit-files.txt): `src/tmdm/merging.lisp`, `scripts/fresh-sbcl.lisp`, `topic-maps.asd`, `tests/normalization-index.lisp`, and the 25 named fixture files under `tests/fixtures/normalization-index/`. This is three modified existing files plus 26 new files. The proposed file list is copied from the verified manifest, not inferred from a directory wildcard. Keep the association experiment, supplied external evidence and this independent review outside that commit. This recommendation does not authorize or perform a commit, pin change or deployment.

Evidence and independently produced logs remain in `/private/tmp/task1c-independent-review-96ln4s4u`. The supplied evidence and actual candidate were unchanged at the final content-hash check.
