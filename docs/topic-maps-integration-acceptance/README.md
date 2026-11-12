# Executable acceptance: Topic Maps #1, HyperDoc #41 and #42

Recorded on 12 November 2026. Verdict: **the executed component, Nix build and
browser gates pass at the fixed revisions below.** This is not authorization to
merge, activate a new runtime dependency, deploy, or claim complete ISO/IEC
13250 conformance. Existing production startup pins remain unchanged.

Executor: Codex. These are fresh executions independent of the authors' retained
logs, in detached source worktrees and new processes. Codex previously authored
HyperDoc #41/#42; this report does **not** establish implementation-author
separation or replace an independent human review.

## Fixed sources and isolation

GitHub reported all three PRs open and Draft before execution, and their heads
were checked again after execution:

| PR | Executed head | Base |
|---|---|---|
| [Topic Maps #1](https://github.com/RalfBarkow/topic-maps/pull/1) | `c446a8228017f405c3a2650ca893e9450ac7cd7b` | `88994c1b9e1edbf13e665e984a5c9c3b2cdf7575` |
| [HyperDoc #41](https://github.com/RalfBarkow/hyperdoc/pull/41) | `25f83196733a611810da2ea9596af1b4b2d215fb` | `596344ae95d746f436705808462259371f5a593c` |
| [HyperDoc #42](https://github.com/RalfBarkow/hyperdoc/pull/42) | `36c69d3312ae70748ecd40a5452759fcfaad25c4` | `25f83196733a611810da2ea9596af1b4b2d215fb` |

The two HyperDoc worktrees remain at those detached heads and clean. Topic
Maps tests used the candidate archive from #42, whose content was reverified
against the actual Git objects of #1, with all 2390 shipped blobs checked. Only
`reports/` is excluded by the existing snapshot contract. The existing Topic
Maps working tree was not changed. All acceptance artifacts and harnesses live
in this documentation directory; no implementation file or lockfile changed.

The host runs Linux, SBCL 2.4.10, Git 2.52.0, Python 3.12.14 and Chromium
154.0.8037.57. Nix is 2.20.6; its locked nixpkgs revision is
`50ab793786d9de88ee30ec4e4c24fb4236fc2674`. SHOP3 remains locked to
`ce53f9b651acde8c44dc21eddb1a1c5b97f10536`; CLOG Moldable Inspector to
`b369f0a4251c5c96472dc674811fb8f5d0184976`. Host Lisp tests reuse the fixed
PR's prepared dependency source registry but use a new acceptance FASL cache.
The Nix check separately uses the complete locked dependency closure, an empty
HOME and a new compilation cache inside Nix's sandbox.

## Newly executed results

Every PASS below is backed by a new command record with an actual exit code 0.
The records include full argv, environment overrides, working directory, UTC
interval and SHA-256 of the raw output. [COMMANDS.md](COMMANDS.md) collects the
exact shell commands. Inherited proxy/credential values are not copied.

| Check | Observed result | Evidence |
|---|---|---|
| Archive/Git/Nix verification | 19 checks; 2390 files; expected NAR hash | [record](snapshot-reverify.json), [verification](snapshot-reverified.json) |
| PR #1 focused ASDF tests | 21 Default Name Type + 50 relationship checks | [record](pr1-focused.json), [log](pr1-focused.log) |
| PR #1 unchanged full launcher | Lisp and Python checks pass, including eleven-baseline independent relationship count check | [record](pr1-full-launcher.json), [log](pr1-full-launcher.log) |
| PR #41 standalone planning | 195 assertions, real SHOP3 | [record](pr41-planning.json), [log](pr41-planning.log) |
| PR #42 clean isolated runner | 51 exporter checks + 195 unchanged planning assertions; tamper refusal | [record](pr42-exporter-clean.json), [log](pr42-exporter-clean.log) |
| PR #42 old-pin refusal | Optional system loads under verified 88994c1b; export refuses `:relationship-reader-unavailable` | [record](pr42-old-pin.json), [log](pr42-old-pin.log) |
| Full candidate Catalog Nix build | Complete package/dependency closure built; 351 closure paths; candidate present in registry | [record](nix-full-candidate-outer.json), [outputs](nix-build-outputs.json) |
| Separate Nix exporter build check | Unchanged production `/nix/store` verifier accepts 2390 candidate blobs; all 51 exporter checks pass | [record](nix-exporter-check.json), [log](nix-exporter-check.log) |
| Fresh Inspector + Chromium | Ten server-side EQ observations through actual navigation; no browser errors or external requests; child exits 0 | [record](browser.json), [observations](browser-results.json), [Lisp log](inspector.log) |

The new full-launcher outputs match **all 26 hashes** in PR #1's retained after
manifest. [The comparison](pr1-historical-comparison.json) is newly performed;
the historical before run itself was not rerun. The launcher retains four known
DateTime/Include corpus discrepancies and NOT-RUN contracts. A successful
launcher exit is not a claim that every corpus case passed or that XTM was
tested. XTM suites requiring the separate SBCL/CXML environment were not run.

SHOP3 again returns two real methods for Case A, a different method for Case B
and an explicit prerequisite-blocker method. Removing evidence and mutating a
method precondition changes the native alternatives; unknown does not become
negative evidence. All results remain `:PLAN-ONLY`; observed statuses are
preserved. The named source cases remain historical FAIL and NOT-RUN, rather
than being promoted by the successful control or by an investigation plan.

The exported statement is the existing Project assertion:

```lisp
(instance-of
 "tag:dreyeck.ch,2026:hyperdoc/page/dreyeck/work/reading/work-breakdown"
 "tag:dreyeck.ch,2026:hyperdoc/schema/hyperdoc-page")
```

Its observed CTM octet SHA-256 is
`e7c4478cf1cab9e3555efbb359b19818f68ab4a0c51ed8850dd1519e545edd52`;
the map CXTM SHA-256 is
`47a2d02f82960813773d62a16011ac8801cdd1888c94c9308c5b3616f19fa32f`.
Scope is empty. The exporter does not create a TMDM item or conformance Case
Record, infer a supertype consequence, or execute a SHOP3 action. The full
Topic Maps test launcher does create its own disposable test Case Records;
those are separate from the read-only export and from any durable registry.

## Full Nix build: candidate override, no activation

[candidate-build.nix](candidate-build.nix) uses the exact #42 Git revision and
its unchanged flake lock. It overrides only the existing package function's
`topicMaps` argument in an acceptance expression. The fixed-output candidate
requires `sha256-d+qp4MmVOwHnEIRn3zzyIQhR/eUYCBos+XAu7OHs3/I=`.
No PR source expression, runtime pin or verification rule is patched.

The Catalog output is
`/nix/store/4c0bkyyin13xpby4r8cvnxr5w73w662d-hyperdoc-catalog`;
the candidate is
`/nix/store/g72z50szzsc5b5b3id0xyh2cxwd2iyy8-topic-maps-c446a822-acceptance-source`.
The private store root is `/workspace/work/acceptance-nix-root`.
[The built wrapper](nix-catalog-wrapper.txt), [derivations](nix-derivations.json)
and [closure](nix-closure-paths.json) prove the candidate is wired into that
output. Builds used `--no-link`; no profile or production executable changed.

Initial attempts found a read-only `/nix`, an unusable existing portable-store
database and unavailable nested namespace mappings inside the command sandbox.
Those failures are retained, not counted as builds. The successful builds ran
outside that *outer command sandbox* with approval, so Nix could establish its
own sandbox. Both retained `sandbox=true`, `sandbox-fallback=false`, unchanged
hash verification and `--no-write-lock-file`. No `--no-sandbox` fallback was used.

The additional [Nix exporter check](nix-exporter.lisp) loads the actual immutable
candidate store output and the unchanged production `verify-store-snapshot`,
checks one Topic Maps ASDF root and runs #42's original exporter tests. This is
stronger evidence than only hashing a writable extracted test directory.

The full Catalog package was built, **not started**. Its production startup
policy still names 88994c1b, as intended by these PRs. Existing Catalog startup
contracts and activation with a new approved pin were not tested or bypassed.
This report does not claim that the candidate can be activated without the
separate coordinated pin/startup-policy qualification.

## Real Inspector navigation and harness diagnostics

The acceptance-only [Lisp harness](inspector.lisp) starts a fresh loopback CLOG
Inspector on a free port. [Chromium](browser.py) clicks the real object links,
then probes the native Inspector pane's `pane-object` by EQ. It does not
substitute a serialized graph or mock the link handler. The observations cover
the statement, Association, both Topics, map, revision, investigation, native
plan result and both native plan trees. Every probe also asserts the native map
state is unchanged. The owned Lisp process exits 0 and its port is closed
afterwards; no existing image or service is contacted.

[Statement screenshot](inspector-statement.png) ·
[Alternative plans](inspector-plans.png) ·
[Native tree](inspector-native-tree.png).

Three harness issues were diagnosed without implementation changes:

1. The first exporter run shared an extracted tree with the full Python
   launcher. Python added `scripts/__pycache__`; the unchanged verifier correctly
   refused the tree. A separate freshly extracted, verified tree then passed.
   See [initial refusal](pr42-exporter.json) and the clean rerun above.
2. The first browser probe used an incorrect private accessor name. It was
   corrected to the existing `pane-object` accessor. See
   [diagnostic](diagnostics/browser-initial.json).
3. A probe initially ran after the new pane div existed but before native
   `CREATE-PANE` registered it. The harness now waits for an active tab, which
   `SELECT-VIEW` installs after registration. Original object-link clicks are
   made once, after handler binding; they are not retried to hide a navigation
   failure. See [diagnostic](diagnostics/browser-early-probe.json).

The browser and Nix checks required no implementation repair. Existing
dependency/ASDF style warnings remain visible in raw logs. This is a functional
navigation/EQ acceptance, not an exhaustive Inspector layout or editing audit.

## Limits and remaining decisions

- No full ISO/IEC 13250 conformance verdict, new normative disposition or XTM
  acceptance is established. The public-text edition limitations remain.
- The three older HyperDoc planning regression suites were retained evidence
  from #41/#42, not rerun in this acceptance. The existing 195 focused planning
  assertions were actually rerun twice, once at each exact PR head.
- Browser execution used the fixed prepared dependency sources in a new host
  process; it was not a browser test of the built production Catalog executable.
- Nix store integrity is content verification relative to the selected Git
  commit, not authentication of its author.
- Multi-identifier terms, scoped statements, derived closure and snapshot
  lifetime remain outside this first exporter contract. No integration with
  another Topic Maps API, production pin change, merge or deployment follows
  automatically from these results.

Only this new acceptance evidence is committed. [isolation.json](isolation.json),
the source-integrity record and the evidence hash inventory document the final
boundaries. Review and explicit activation authorization remain separate.
