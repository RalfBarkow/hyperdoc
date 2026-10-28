# Independent review — Task 1E

**GO FOR LOCAL TASK 1E COMMIT.** No semantic or implementation defect was found in the reviewed candidate. This verdict covers the local commit of these exact bytes. It does not certify deployment, a HyperDoc re-pin, Linux, Stage 2, or a 2 GiB host. Nothing was committed, staged, merged, pushed, published or deployed during this review.

Reviewed on 28 October 2026. Original candidate and supplied evidence were read only. Executable work used separate baseline and candidate copies under this report's directory.

## Exact identities and scope

- Baseline and candidate HEAD: `6162ed68c94ea4796b8cf2282edd347d9607b08c`.
- Candidate: `/Users/rgb/workspace/topic-maps-task-1e`, branch `claude/tmdm-association-index-1e`, uncommitted.
- Baseline `src/tmdm/associations.lisp` SHA-256: `cc86f08693a0f4be141757f003f9be476bbb9fe0805484dec8d1692eb7aeef18`.
- Candidate `src/tmdm/associations.lisp` SHA-256: `96d16c7f2754aa13f4b2994b1e9e20b007b16f02ea3a655af53df1c8bd42e708`.
- Exact `git diff HEAD -- src` SHA-256: `a31bdc182eed1da0328c85a9a29b7ae0ffe55c3d8f29497e520dd3868e1d9748`.
- All **33** entries in supplied `candidate/CANDIDATE-FILES.sha256` match the actual candidate. The manifest itself has SHA-256 `90ac1edbfe449242215459cc5027bcf5d827422ec0abf4134f11da4165e68ff9`.
- Modified tracked files: `src/tmdm/associations.lisp` (+41/−1), `topic-maps.asd` (+8), `scripts/fresh-sbcl.lisp` (+1).
- New files: `tests/association-index.lisp` and 29 fixture files (27 CXTM, `api-facts.sexp`, `rejections.sexp`).
- The only production edit extracts the former search as `scan-next-association-merge`, adds `next-association-merge`, and substitutes that call in the existing normalization loop. Equality, merge operations, reification, reader behavior and normalization frequency are unchanged. Test-system wiring is the only other tracked edit. `git diff --check` passes.
- The primary Topic Maps checkout was also observed clean at the same full revision.

| Input | Bytes | SHA-256 |
|---|---:|---|
| Original CTM | 161,228 | `f4f04bb49ce3b762b3e1c0bccf9e177e11785d33db87e8c0d043b04820b540d3` |
| Stage 1 CTM | 220,069 | `fe2955e93239704673a2a38492ea92e57f0d221f14313603dd1dd5f206b340b8` |

The older `203900cb…` / 231,248-byte input is not the measured Stage 1 fixture. Its historical 107–113-second readings must not be attributed to this fixture.

## Algorithm review

The unchanged baseline expression is exactly `(equal-pair (%topic-map-associations map) #'equal-associations-p)`. `equal-pair` searches left endpoints in list order and chooses the first matching later endpoint. `same-scope-p` compares cardinality plus one-direction inclusion; Role equality likewise compares cardinality plus one-direction inclusion of `(type, player)` signatures. Neither uses canonical representatives, item identifiers, reifiers, or Role order as equality components.

On the guarded domain, each Scope and each Role-signature collection is duplicate-free. Equal cardinalities plus inclusion then imply set equality. The key has exactly the three required components: stored Association type identity, sorted stored theme identities, and sorted stored `(Role type, player)` identities. IDs are positive integers assigned injectively through one fresh `eq` table per search. `equal` comparison of the resulting lists is therefore equivalent to baseline equality on that domain. Sorting touches newly allocated lists/conses, not stored model lists.

The duplicate guard is **sufficient, deliberately conservative, and not a minimal necessary condition on every individual map**. Some maps containing duplicates happen to yield the same answer under the key, but removing either guard permits real counterexamples. Duplicate multiplicities are ignored by baseline inclusion, whereas the sorted key retains them; this causes both directional-equality and symmetric-equality counterexamples. No broader equivalence claim outside the guard is justified.

Sharer lists are populated in map order. The second element after the first `member` occurrence is the earliest later sharer. The outer traversal selects the earliest eligible left endpoint, not the earliest completed duplicate. Repeated listing of the same Association does not invalidate this: its first occurrence already has a later sharer and returns before a later occurrence could be examined.

The index has no slot, special variable, persistent closure or cache. It returns only a pair of handles. `normalize-associations` still normalizes Roles first, and searches afresh after each merge. Callers in `make-association`, `merge-two-topics`, and `normalize-topic-map` keep their original behavior. Reifier cascades may re-enter normalization and replace types, players, themes, Roles and Associations, but every nested/next search constructs a new index from the current stored graph. Retained-handle forwarding and representative placement remain in unchanged merge code.

The proof assumes finite, structurally valid TMDM storage and ordinary single-threaded mutation. This is not a claim about arbitrary ill-typed/cyclic private-slot corruption or concurrent unsynchronized graph changes. Stale Topic forwarding references and repeated Association listings were nevertheless tested directly because the search can encounter raw storage.

## Independent falsification attempts and results

1. **360,000 ordered raw-map pairs**, generated independently without the supplied random generators. These enumerate 40 Role-player sequences (three symbols, lengths 0–3) × 15 Scope sequences (two themes, lengths 0–3), then every ordered pair of the resulting 600 descriptions. Expected results are computed from cardinality and numeric inclusion, independently of the candidate key. Both the baseline predicate scan and candidate agree on every pair. There are **27,236 asymmetric ordered cases**.
2. This enumeration includes counterexamples to unsafe keying such as Roles `[p,p,q]` versus `[p,q,q]`: baseline equality holds in both directions, although their multisets differ. It also covers directional Scope cases such as `[s,s]` versus `[s,t]`, in both list orders. The candidate correctly falls back.
3. **Ordering counterexample:** on the index path, `[A,B,B,A]` returns the pair at the first and fourth positions, not the second and third. The final named test explicitly asserts distinct one-Role signatures so it cannot accidentally exercise the fallback.
4. **Raw forwarding and freshness:** two players differing only because an old Topic forwards to a live one remain unequal under stored-reference equality. Changing the stored player makes the next search find the pair. A shared Scope list retains its identity and order across the search.
5. **Independent six-level reifier cascade:** three lanes form 18 Associations, plus an unrelated sentinel. Each level uses the previous level's Association and Role reifiers in its type, Role type, player and Scope. Role and Scope orders vary. Two public player merges cause twelve real Association merges, repeated on preflight copies: **24 instrumented merge calls**, normalization depth **7**, and **130 candidate searches**, all agreeing with the unchanged scan. The result has six merged Associations plus the sentinel. All **18 retained Association handles** and **36 retained Role handles** remain usable; identifiers, representative positions, reifier inverses and mutations through obsolete handles are checked. Full CXTM and ordered API facts are byte-identical to the fresh unchanged baseline run.
6. **All 29 supplied fixtures independently reconstructed from unchanged baseline production code.** `next-association-merge` was asserted undefined in that process. Every resulting file matches the supplied fixture byte-for-byte. This includes all 22 document outputs, five API scenarios and three rejection recordings.
7. **Focused suite rerun:** all 97 checks pass, including the supplied random selection, walks and read comparisons. Their zero-difference counts reproduce. The 600-Association scale case took 3.307 seconds against its existing 60-second test budget.

The saved recording provenance says 2026-10-28T14:24:50Z, empty `git diff -- src`, and the exact baseline Association-file hash. Both original recording and pristine re-record logs report `next-association-merge-defined=NIL`. This is consistent with recording before production changes. A saved timestamp is not independently attestable historical proof; the fresh reconstruction establishes the stronger substantive point that these expected results actually come from unchanged `6162ed68`, not the candidate.

Negative fixtures reproduce `TOPIC-MAPS.CTM:CTM-REJECTION` with `:REIFIER-CONFLICT`, `:CORE-SUBJECT-CONFLICT`, and `:REIFIER-CONFLICT` respectively. The API core-subject scenario also checks that rejection leaves the map unchanged. The real corpora raise no read condition; they do not exercise rejection behavior.

## Mutation controls and their limits

All ten supplied mutants were rerun sequentially, one fresh process each. The control survives; each mutation is killed at the same check as in supplied evidence:

| Mutation | Killing check |
|---|---|
| Ignore Scope | `document:scoped-duplicates:cxtm-equals-6162ed68` |
| Ignore Role type | `document:role-type-differs:cxtm-equals-6162ed68` |
| Ignore player | `document:player-differs:cxtm-equals-6162ed68` |
| Order-sensitive Roles | `document:role-order-permutation:cxtm-equals-6162ed68` |
| Last partner | `stale:pair-found-before-the-merge` |
| Swap pair endpoints | `api:api-identifiers-and-handles:facts-equal-6162ed68` |
| Drop Role fallback | `asymmetry:a-first-indexed-agrees` |
| Drop theme fallback | `selection:indexed-equals-oracle-on-every-map` |
| Persistent index | `document:plain-duplicates:cxtm-equals-6162ed68` |
| Canonicalize stored references | `selection:indexed-equals-oracle-on-every-map` |

These controls are useful fault sensitivity, not completeness evidence. They do not establish memory bounds, concurrency safety, performance at high Role/Scope arity, every future equality component, or all simultaneous changes to oracle and implementation. There is no explicit ignore-Association-type mutant (although a recorded type-difference test exists), nor a dedicated earliest-completed-pair or destructive-Scope-sort mutant; the independent checks address the latter behaviors directly.

The mutation harness replaces the production function with a handwritten mutant implementation even for `none`, and treats **any error** as a killed mutant. Its process exit code is therefore not a kill/pass verdict. I checked the actual `MUTANT-RESULT` lines and semantic assertion names, and separately ran the real production function through focused and independent tests.

## Real corpora, full outputs and model observations

Fresh unchanged-baseline and candidate processes read both exact CTM fixtures. Complete UTF-8 CXTM files, not just summaries, were retained and byte-compared. All four reads exit 0, with no raised conditions. Model observations also match.

| Corpus | Topics / Associations / Roles | Items / Reifiers | CXTM bytes | CXTM SHA-256 |
|---|---|---|---:|---|
| Original | 327 / 572 / 1,144 | 2,876 / 57 | 392,172 | `6f957018d93e7a4f9b8738042797f60a3d6c094134ef85f6ba40d30bfe03d8b9` |
| Stage 1 | 390 / 768 / 1,536 | 3,735 / 79 | 515,884 | `60c95959833cdf556c0ad432775be761a2b58e7a04b6aa9d8e99926af50820b7` |

Saved HyperDoc observations were inspected and compared: original model declarations/statements/assignments/gaps are **55/57/4/40**, Stage 1 **73/79/8/47**. Baseline and candidate match. Both report no trace discrepancies or revision refusal, matching octet/CXTM roundtrips, and unchanged retained input. Projection counts match (original 148 Topics/286 edges; Stage 1 189/397).

The supplied whole-read harness compares the full CXTM strings, merge counts, fallback counts and shadowed searches. It reports 8,083 original and 10,699 Stage 1 normalization calls, **zero Association merges, zero Topic merges, zero fallbacks and zero shadow mismatches**. These corpora validate unchanged output and the useful fast path; merge semantics, fallback, retained handles and refusals are supported by synthetic/API tests, not by the real corpus.

## Performance and regression evidence

The independent measurements below use SBCL **2.6.4**, fresh processes, existing separate compilation caches, `--dynamic-space-size 4000`, and a **180-second process cap**. There were no concurrent review benchmarks. Timed work is CTM deserialization; file input, compilation, CXTM serialization and observations are outside the timed interval. Allocation counters are sampled immediately around the read; no shadow instrumentation is installed. Host load was substantial (one observed load-average tuple was 18.28/29.38/39.98), so these are single-run observations, not controlled medians.

| Corpus | Baseline wall / CPU s | Candidate wall / CPU s | Wall speedup | Baseline / candidate cumulative allocation |
|---|---:|---:|---:|---:|
| Stage 1 | 82.877 / 77.094 | 16.776 / 15.418 | 4.94× | 8,312,282,304 / 9,522,378,064 bytes |
| Original | 34.418 / 32.119 | 8.487 / 8.128 | 4.06× | 4,968,037,472 / 5,652,309,856 bytes |

Candidate cumulative allocation increases about **14.6%** on Stage 1 and **13.8%** on the original. This is allocation churn, not live heap or peak RSS. It is a concrete cost of the faster index. Peak memory and suitability for a 2 GiB host remain unmeasured.

I inspected the saved benchmark runner, provenance, all 24 run logs, input and output digests, status and summary. Recomputed wall medians agree:

| Runtime / corpus | Baseline median s | Candidate median s |
|---|---:|---:|
| SBCL 2.6.4 / original | 34.52 | 8.58 |
| SBCL 2.6.4 / Stage 1 | 64.48 | 13.27 |
| Nix SBCL 2.4.10 / original | 35.44 | 9.37 |
| Nix SBCL 2.4.10 / Stage 1 | 70.42 | 18.55 |

Saved status records exit 0 for 24 measurements and four warm-ups, with a finished marker. The runner bounds measurements by `timeout 400` and alternates baseline/candidate; warm-ups have a separate 600-second cap. Saved load variation prevents a controlled-machine performance claim. I did not rerun Nix measurements.

**HyperDoc's requirement remains the complete read-and-model operation in under 90 seconds.** I inspected the unchanged script's literal `(< elapsed 90)` test. The raw-read timeout above does not replace or relax that requirement. Saved Stage 1 full-operation results are candidate **18.536, 18.248, 21.554 seconds**, baseline **76.126 seconds**, with `WITHIN-90-SECONDS YES` and no refusal. Original results are candidate 11.641 and baseline 32.144 seconds. Candidate `PIN-NOT-OK` is expected for an uncommitted tree; it is not a semantic failure or permission to re-pin. I inspected, but did not independently rerun, HyperDoc integration.

All **25 archived baseline/candidate regression report files are byte-identical**. The **33 existing PASS lines** agree after excluding the new Association-index line. All **24 report checkers** were independently run against the saved reports and passed. The full historical suite was not independently rerun; its saved outputs and complete report archive were audited. Saved corpus-verification/unit-test logs are additional supplied evidence.

The historical `check-nfc.py` failure is reproduced separately using the same installed **Python 3.14.4 / Unicode 16.0.0** on both unchanged baseline and candidate. Both exit 1 at the identical version assertion requiring Unicode 15.0/15.1, before any NFC comparison or SBCL invocation. The checker source is unchanged. System Python 3.9.6 / Unicode 13.0 also fails that guard. This is a pre-existing environment mismatch, not a Task 1E regression; successful NFC verification itself remains unavailable in these interpreter configurations.

The fast path still performs pairwise duplicate checks within each Association (quadratic in Role count, and duplicate-theme detection may also be quadratic), then sorts Role/Scope keys. It is intended to remove the costly cross-Association scan on the actual corpus; it is not an unconditional speedup on every graph shape. High arity and merge-heavy performance were not benchmarked. Reader normalization frequency and preflight copying were deliberately untouched.

## Reproduction, limitations and recommendations

All independent runnable code and outputs are beside this report:

- `setup.lisp`, `run-check.py`, `reconstruct.lisp`, `selection.lisp`, `cascade.lisp`, `corpus.lisp`.
- `runs.jsonl`: exact commands, roots, per-process bounds, relevant environment and exit codes.
- `reconstructed-fixtures/`, `selection-final.log`, `cascade-base.*`, `cascade-candidate.*`, `stage1-{base,candidate}.*`, `original-{base,candidate}.*`.
- `focused.log`, `mutant-*.log`, `independent-checkers.json`, `nfc314-{base,candidate}.log`.
- `initial-snapshot.json`, `candidate.diff`, `verification.json`, `report-archive-hashes.json`, `saved-evidence-checks.json`.

For example, from this review directory, run these **sequentially**:

```sh
python3 run-check.py selection-recheck candidate selection.lisp 90
python3 run-check.py cascade-recheck-base base cascade.lisp 90
python3 run-check.py cascade-recheck-candidate candidate cascade.lisp 90
CTM_INPUT=/Users/rgb/workspace/topic-maps-task-1e-evidence/fixtures/stage1-hyperdoc-project.ctm python3 run-check.py stage1-recheck-base base corpus.lisp 180
CTM_INPUT=/Users/rgb/workspace/topic-maps-task-1e-evidence/fixtures/stage1-hyperdoc-project.ctm python3 run-check.py stage1-recheck-candidate candidate corpus.lisp 180
```

Initial review-harness errors (flat ASDF cache collisions and a missing parenthesis) are retained in the logs. They were corrected only in the review harness; the final runs succeed without candidate edits. The final ordering test was also tightened to prove it exercises the index path. No expectation was updated from candidate behavior.

Nonblocking recommendations: retain the independent six-level cascade and explicit Scope/ordering counterexamples as future regression tests; add a mutation for earliest-completed rather than earliest-left-endpoint selection; keep production function execution separate from the handwritten mutation control; and measure peak RSS on the actual production host before any deployment decision. Run the NFC checker in its supported Unicode environment as a separate existing maintenance issue. Preserve the equality/key correspondence if future TMDM equality changes.

No blocking correctness gap remains for this local commit. Unmeasured Stage 2, Linux, production peak memory, high-arity performance and a controlled idle-machine benchmark limit broader claims.

Preservation check completed: all **12,284 snapshotted candidate files** and all **122 supplied evidence files** retain their initial SHA-256 hashes. Candidate Git status is identical, and the evidence file set is unchanged. Results are recorded in `verification.json`.
