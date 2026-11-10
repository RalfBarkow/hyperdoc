# W2 handoff: versioned SHOP3 planning domain for Welcome Development (L3) and transient problems (L1)

**Status:** design only, accepted in architecture, revised with three clarifications (tag retention, private domain lifecycle, replay guarantee).
**Base:** PR #38 accepted at `61cdec068116891d8455cdff9bb7b81ef1df171a` (W1).
**Scope:** Welcome development planning only. No FedWiki planning, authorization or fork-execution change. No S1 acquisition.

**Labels:**
- **[obs]** = read in the pinned sources or observed in the W1 reviews;
- **[exec]** = executed in a disposable SBCL image during design (no repository change; Appendix A);
- **[abg]** = design, to be shown by the acceptance tests.

**Document history:** Claude Code design for Zettel 11569/11570. Architecture accepted; revised for tag retention, private domain lifecycle and the replay guarantee; Eclector API status added (§5.1).

## 0. What W2 guarantees, and what it does not

**Guaranteed.** A recorded assignment, and the submission check that depends on it, is replayed against the **exact SHOP3 planning domain version** that proposed it. That version is identified by content digest and anchored to a dedicated git tag. The replay does not depend on the currently loaded `welcome-development` domain.

**Not guaranteed.** W2 versions the **planning domain only, not the record validator**.
- Historical replay still runs the **current** `project-development-records` and current `development-state` record rules.
- A later, stricter validator can refuse an old journal.
- W2 keeps the validator's source identity as **provenance** (§4, §9), but makes no claim of reproducing the full historical runtime.
- SBCL, SHOP3 and dependency versions are checked against a declared pin, not rebuilt.

## 1. Facts this design relies on [obs]

**Pinned SHOP3 `ce53f9b` (4.3.1):**
- `defdomain` is a macro. It `pushnew`s `(:operator (!!inop) () () () 0)` into the items and expands to `(apply 'make-domain '<name-and-options> '<items>)` (`io/input.lisp:680–695`).
- `make-domain` always calls `install-domain` (`io/input.lisp:735`). This does `(setf (get <name> :domain) domain)` on the **name symbol's plist** (`:742–746`). `:noset t` only prevents setting `*domain*`. `delete-domain` on a domain object sets `(get (domain-name d) :domain)` to NIL (`:748–753`).
- `find-plans` accepts `:domain` as a **domain object** and binds `*domain*` to it while planning (`shop3.lisp:93` ff.; domain resolution `:185–193`, binding `:218`).
- `make-problem` → `initialize-problem` pushes onto `shop3::*all-problems*` and `setf`s `*problem*` (`io/input.lisp:128–176`). `shop3:delete-problem` is exported and removes by object identity (`decls.lisp:713–719`).
- **Domain items are executable.**
  - Method bodies are `eval`ed during reduction (`planning-engine/task-reductions.lisp:335, 348`).
  - Operator costs are `eval`ed (`:156`).
  - The logical keywords `eval`, `call`, `assign`, `assign*`, `enforce`, `setof`, `bagof` and `:external` evaluate Lisp (`theorem-prover/theorem-prover.lisp:378–439`).
  - `:include` loads other files (`io/input.lisp:831–860`).
- `set-variable-property` writes `variable`, `primitive` and `anonymous` properties on symbols. These are derived only from the symbol name (`unification/unify.lisp:455 ff.`).
- `flake.lock` pins `shop3` rev `ce53f9b651acde8c44dc21eddb1a1c5b97f10536`, narHash `sha256-uJ4Fxv82wvZn+tgZjAswcqXxHfNDh2w5kOKrJKVwsRU=`.

**HyperDoc:**
- `dreyeck/git:git-commit-refs-containing` searches only `refs/heads/` and `refs/remotes/`, **not** `refs/tags/` (`dreyeck/src/git-commit-inspection.lisp:267–279`). It is **not used** here.
- `git show <sha>:<path>` blob reading already exists (`dreyeck/src/upstream-assessment.lisp:285`).
- `%source-form-digest` / `%form-text` exist (`dreyeck/src/authority-policy.lisp:633–653`). They are internal to that system.
- **Eclector** (pinned `sbcl-eclector-20241012-git`, ASDF version `0.11.0`):
  - It is **not declared** by any HyperDoc `.asd` at `61cdec0`, nor by `dreyeck/work/welcome-development`.
  - `dreyeck/src/git-commit-inspection-views.lisp:86` uses `eclector.reader:quasiquote`.
  - It loads with `(asdf:load-system "eclector")` from the review runtime registry [exec].
  - **W2 must declare it explicitly** (§12).
- W1 git calls carry `--no-lazy-fetch`.
- The W1 binding currently embeds `(shop3::domain-items (find-domain 'welcome-development))` (`welcome-development.lisp:101–109`).
- **R5 probe:** one unused added axiom refuses every stored assignment.

## 2. Domain version identity

```
domain-version-id =
  sha256( development-canonical-string(
    (list "welcome-development-domain-v1"
          :options <historical defdomain options minus the name; only (:noset t) permitted>
          :items   (shop3::domain-items <private domain object built from those items>))))
```

- Lower-case 64-hex. It reuses `development-canonical-string` (`with-standard-io-syntax`, `*package*` = KEYWORD, literal data only).
- It is computed the **same way** for the loaded domain and for a historical one. Both pass through SHOP3's own `defdomain` expansion, so `!!inop` and include handling stay identical.
- The id depends on content only. Different commits with identical items give the same id.

## 3. Git retention: one dedicated tag per version

- **Ref:** `refs/tags/hyperdoc/welcome-development/<domain-version-id>`.
- **Resolution:** `git rev-parse --verify --quiet refs/tags/hyperdoc/welcome-development/<id>^{commit}` must equal the record's `:commit` exactly.
  - Annotated and lightweight tags are both accepted.
  - `git cat-file -t <ref>` (`tag` or `commit`) and the tag object id are kept as provenance.
  - Tag signatures are **not** verified in W2.
- **A branch containing the commit is not sufficient.** No fallback to `git-commit-refs-containing`.
- **Replay never creates, moves or fetches tags or objects.** A missing tag or object refuses with `:domain-version-unavailable`.
- **Creating the tag is a human approval step outside W2,** after the domain change has been reviewed and committed. W2 may print the proposed ref name (§12, `describe-development-domain-version`). It must not run `git tag`.
- **New W1-local helper** `domain-version-tag-commit (repository id)`, using `dreyeck/git:git-run-values` with an explicit `git-repository-checkout` (never the memoized checkout). A shared tag API in `dreyeck/git` is listed as missing, but not required.

## 4. Record `dev-domain-version`

A seventh development record class. It goes through `accepted-records` like the others: trusted producer, revalidated during replay.

| Field | `:observed` | `:fixture` |
|---|---|---|
| `:version-id` | 64-hex | 64-hex |
| `:items-source` | `:git` | `:loaded-image` (explicitly hypothetical) |
| `:repository` | explicit `git-repository-checkout` | — |
| `:tag` | the ref name above | — |
| `:commit` | 40-hex; the tag resolves to it | — |
| `:path` | e.g. `dreyeck/work/welcome-development.lisp` | — |
| `:blob` | `git rev-parse <commit>:<path>` | — |
| `:form-sha256` | SHA-256 of the extracted defdomain form text (`%form-text` rule) | SHA-256 of the canonical items |
| `:reader` | `(:package "DREYECK/WORK/WELCOME-DEVELOPMENT" :read-eval nil :syntax :standard :symbol-policy :w2-v1)` | same |
| `:planner` | `(:shop3-rev "ce53f9b…" :shop3-nar-hash "sha256-uJ4F…" :shop3-asdf-version "4.3.1")` | same |
| `:validator` | provenance only: `(:path "dreyeck/work/welcome-development-records.lisp" :blob <git rev-parse commit:path>)` | `(:path … :sha256 <loaded file digest>)` |

**Admission rules during replay:**
1. The record must precede every assignment that names its id.
2. Duplicate version ids in one journal are refused.
3. Fixture and observed records cannot be mixed (existing rule).
4. **`:observed`:**
   - commit and blob are present locally (`git-commit-object-present-p`);
   - the tag resolves to `:commit`;
   - `<commit>:<path>` resolves to `:blob`;
   - the form digest matches;
   - the trust screen passes (§5);
   - the private domain is built (§6) and its recomputed id equals `:version-id`.
5. **`:fixture`:** the id is computed from the loaded domain (`shop3::domain-items (find-domain 'welcome-development)`). It is shown as `:hypothesized`, never `:observed`.
6. `:planner` must equal the running image's pin. The running pin is read from `flake.lock` of the loaded checkout and `(asdf:component-version (asdf:find-system "shop3"))`; a mismatch refuses with `:planner-version-mismatch`. This checks the **declared** pin; the SHOP3 store-path basename is kept as provenance only.

**Refusals:** `:domain-version-unavailable`, `:domain-version-mismatch`, `:domain-version-untrusted` (with the screen reason), `:planner-version-mismatch`, `:duplicate-domain-version`.

## 5. Trust boundary: historical domain source is code

Building and planning with a historical domain **executes code**. Method bodies, operator costs and the evaluating logical keywords run `eval` in the replaying process.

**The trust anchor is the dedicated tag (§3):** someone with write access deliberately approved that domain version of this repository. W2 does not make untrusted domain code safe. The screen below is defence in depth, against accidents and silent drift.

1. **Source.** Only the blob at the tagged commit of the explicitly supplied repository. Never record-carried items, never the network.
2. **Locating the form (text, no reader).** The blob is a whole Lisp file whose other forms (`in-package`, `defclass`, `defun` …) would fail the restrictive reader. So the defdomain form is first located **textually**:
   - exactly one occurrence of `(shop3:defdomain` outside strings and comments;
   - its balanced extent is found with the `%form-text` rules (strings, `;` comments, `#\` characters);
   - `:form-sha256` is the SHA-256 of that substring.

   W2 uses a W1-local copy of that algorithm, so it does not depend on the authority system's internal function. Only this substring is read.
3. **Reading.** Use the Eclector client in §5.1, with `*read-eval*` NIL, `*read-base*` 10, the standard Eclector readtable, and the W1 package as the current package.
   - New symbols may be interned **only** in `DREYECK/WORK/WELCOME-DEVELOPMENT` and `KEYWORD`.
   - `SHOP3` (`SHOP3:DEFDOMAIN`, `SHOP3:CALL`, `SHOP3:FORALL`) and `COMMON-LISP` symbols must already exist and be on the allowlist: `< <= > >= = /= NOT AND OR NIL T`, plus any further CL symbol the W1 form needs, enumerated by test A7.
   - Uninterned `#:` symbols, other package prefixes, `#.`, `#+`/`#-` and `#S` refuse.
   - **Any Eclector reader condition is a refusal.** The client never invokes Eclector's `recover`, `use-value` or `intern` restarts.
4. **Selection.** The read form must be exactly `(shop3:defdomain (welcome-development . options) items)`. Options other than `:noset t` refuse, including `:type` and `:redefine-ok`.
5. **Structural screen**, before `make-domain`:
   - **only literal data**: conses, symbols, strings and integers. A `#P` pathname, vector, character, float or any other object refuses; `development-canonical-string` enforces the same rule;
   - no `:include` item;
   - item kinds limited to `:-`, `:operator`, `:method`;
   - the logical keywords `eval`, `assign`, `assign*`, `enforce`, `setof`, `bagof` and `:external` are refused;
   - `shop3:call` only with a function in `{<, <=, >, >=, =, /=}`;
   - `shop3:forall`, `not`, `and`, `or`, `imply` allowed;
   - operator cost absent or a literal number.

   The W1 domain at `61cdec0` passes this screen (acceptance A7).
6. **Execution context.** The replaying process. For independent historical validation, the documented mode is a **separate disposable SBCL process** with an empty HOME and private FASL cache, plus a network namespace where available, as in the W1 reviews. The function itself is in-image.
7. **The historical defdomain form itself is never `eval`ed.** Replay constructs a new form `(shop3:defdomain (<private-symbol> :noset t :silently t) <screened items>)` and evaluates that (§6). This keeps the public name out of the expansion.

### 5.1 Eclector API status (pinned 0.11.0)

**Confirmed: exported, found in the pinned source, and exercised in a disposable image [exec]:**

| API | Use in W2 | Probe result (Appendix A) |
|---|---|---|
| `eclector.reader:*client*`, `eclector.reader:read-from-string` (also `read`) | read the extracted form with the W2 client | domain-shaped form read with the expected symbols |
| `eclector.reader:interpret-symbol (client stream package-indicator symbol-name internp)`; indicator is `NIL` (`#:`), `:keyword`, `:current` or a package-name string (`code/reader/generic-functions.lisp:119`; default methods `code/reader/tokens.lisp:510, 603`) | symbol policy | refused: `#:x`, `other::new` (internp T), `other:missing`, non-allowlisted CL symbols (`DELETE-FILE`, `CAR` via `#'car`). **No symbol was added to the foreign package.** |
| `eclector.reader:evaluate-expression (client expression)` (`generic-functions.lisp:137`, called from `#.` in `macro-functions.lisp:470–492`) | refuse `#.` even if the caller's `*read-eval*` is T | the client's refusal surfaces as `ECLECTOR.READER:READ-TIME-EVALUATION-ERROR`; with `*read-eval*` NIL, Eclector signals `READ-TIME-EVALUATION-INHIBITED` first |
| `eclector.reader:evaluate-feature-expression (client feature-expression)` (`generic-functions.lisp:147`) | refuse `#+`/`#-` | refused |
| `eclector.reader:make-structure-instance (client name initargs)` (`generic-functions.lisp:135`) | refuse `#S` | refused |

**Probe findings the implementation must respect [exec]:**
1. **Eclector wraps client errors** raised inside `evaluate-expression` into a **recoverable** reader error (`READ-TIME-EVALUATION-ERROR`). If anyone invokes the `recover` restart, it would inject NIL and continue. W2 treats every Eclector reader condition as a refusal and never invokes those restarts (A7).
2. **`#P"…"` is read successfully** as a pathname object; no reader hook refuses it. Pathnames are refused by the literal-data screen in §5 step 5 (A7).
3. **Feature expressions:** the probe client interned the feature symbol (`SBCL`) into the *current* package. It ignored Eclector's package state, which Eclector sets to `KEYWORD` while reading feature expressions.
   - The W2 client must resolve `:current` with `(eclector.reader:state-value client '*package*)`, not a fixed package.
   - It must refuse `#+`/`#-` without any interning outside `KEYWORD` and the W1 package (A7).

**Exported but not yet exercised; requires an implementation-time probe:**
- `eclector.reader:state-value` / `call-with-state-value` for `*package*`, `*read-eval*` and `*read-base*`. Default methods are in `generic-functions.lisp:26–80`. The W2 client's use of them is unverified.
- `eclector.reader:call-reader-macro`, and `eclector.readtable` functions for a restricted readtable, in case the screen needs to refuse further dispatch macros (`#'`, `#(`, `#*`, `#C`, `#A`, `#=`/`##`) at read time rather than through the literal-data screen. Only `#'` is probed so far, and it was refused through the symbol policy.
- Behaviour when the extracted substring holds more than one form or trailing input (must refuse).
- That reading the actual W1 defdomain substring at `61cdec0` with the final client gives items EQUAL to the loaded domain's source items.

**Not assumed:** any Eclector API for "read without interning". W2 relies only on `interpret-symbol`, plus the guarantee in §5 step 3 that new symbols go only into the W1 package and `KEYWORD`.

## 6. Private SHOP3 domain: creation, isolation, removal

**Creation:** `development-domain-object (version-id items)`.
1. Look up the per-image cache `*development-domain-cache*`, an EQUAL hash table: version-id → `(private-symbol . domain)`. On a hit, return the domain.
2. Otherwise `(make-symbol (format nil "WELCOME-DEVELOPMENT@~A" version-id))`: an **uninterned** symbol, created per cache entry.
3. Evaluate `(shop3:defdomain (<private-symbol> :noset t :silently t) <items>)` inside `unwind-protect`.
   - `install-domain` writes only `(get <private-symbol> :domain)`, which no other code can name.
   - `:noset t` leaves `shop3:*domain*` unchanged.
4. Recompute the id from `(shop3::domain-items domain)`; it must equal the expected id.
5. Only then store the entry in the cache. If any step fails after install, the cleanup form runs `(shop3:delete-domain domain)` on the **object** and nothing is cached.

**Isolation invariants**, checked in tests and before/after each replay in debug mode:
- `(get 'welcome-development :domain)` is EQ to its value before; `(symbol-plist 'welcome-development)` is EQUAL to its value before.
- `shop3:*domain*` is EQ to its value before.
- No interned symbol named `WELCOME-DEVELOPMENT@…` exists in any package.
- Replay never calls `find-domain`, `delete-domain`, `set-domain` or `defdomain` with the public name.
- The only remaining global side effects are SHOP3's name-derived symbol properties (`variable`, `primitive`, `anonymous`). Their values depend only on the symbol name, so they are identical for any domain. Tests snapshot them for the current domain's symbols.

**Removal:** `clear-development-domain-cache ()`. For each entry, `(shop3:delete-domain domain)` (the object method, which sets the private symbol's `:domain` to NIL), then `remhash`. It returns the number of entries removed. It never touches the public registration; this holds on non-local exit too (`unwind-protect` per entry).

**Planning with it:** `find-plans problem :domain <object>` (§8). SHOP3 binds `*domain*` dynamically for the call and restores it on unwind.

## 7. Binding format v2

- `:format "welcome-development-plan-v2"`.
- `:inputs` = `(:format … :source … :domain-version <id> :planner <pin> :state <sorted canonical strings> :tasks ((advance-welcome)) :which :all :alternatives <sorted canonical strings>)`. The full domain items are **removed**.
- `:digest` = SHA-256 of the canonical inputs. `:step` and `:alternative-id` are unchanged.
- v1 bindings refuse with `:unsupported-binding-format`. Only fixtures exist, so no migration is needed.
- `assignment-proposal-binding (records step &key domain-version)`:
  - `:domain-version` is required, and its `dev-domain-version` record must already be in `records`;
  - fixture helpers pass the fixture version.

## 8. Replay algorithm (`development-state`)

The current ordered loop is kept. A per-replay version table is added.

| Record | Check |
|---|---|
| `dev-domain-version` | §4 admission, then add to the table |
| `dev-assignment` | the version named in its binding must be in the table → plan the prefix state with **that** private domain → existing proposal and binding checks |
| `dev-submission` | plan the prefix state with the **domain version of its assignment** → require the exact `(!await-submission s a e)` (the existing check, now version-aware) |
| others | unchanged (current validator, §0) |

The final next-action cycle in `development-workflow` plans with the **currently loaded** public domain. The run reports `:current-domain-version` (id) and `:current-version-tagged` (T or NIL).

Producing a new **observed** assignment requires a tagged version and its `dev-domain-version` record. Uncommitted or untagged domain code can only produce fixture assignments.

## 9. Validator provenance (not replayed)

- `dev-domain-version :validator` holds the records-file blob at the tagged commit.
- `development-run` gains `:validator-source` = `(:path … :sha256 <digest of the loaded records source file>)`.
- The Inspector view states verbatim: "Planning domain replayed by version; record validation uses the current validator."

## 10. L1: transient SHOP3 problems

```lisp
(defun plan-development-state (state domain)
  (let ((shop3::*problem* shop3::*problem*))          ; make-problem SETFs it; keep that local
    (let* ((name (gensym "WELCOME-DEVELOPMENT-"))
           (problem (shop3:make-problem (list name :domain (shop3::domain-name domain) :silently t)
                                        (copy-tree state) '((advance-welcome)))))
      (unwind-protect
           (multiple-value-bind (raw seconds trees states)
               (shop3:find-plans problem :domain domain :which :all :verbose 0 :plan-tree t :collect-state t)
             (make-instance 'dreyeck/shop3:hyperdoc-htn-plan-result ...))   ; as today
        (shop3:delete-problem problem)))))
```

- The result object keeps only the name, plans, trees and states, so nothing depends on the registered problem.
- Same pattern as `docs/defederation-consolidation/review/probes/harness.lisp:41`.
- Applying it to defederation and local-only planning is out of scope.

## 11. Inspector and Topicmap

- A `development-domain-version` object holds:
  - the record;
  - an EQ link to the `dreyeck/git` commit object (existing commit views);
  - tag kind and object id;
  - blob and form digest;
  - screen result;
  - the private domain object;
  - the planner pin.
- Topicmap:
  - a `:domain-version` topic, `:observed` for git and `:hypothesized` for fixtures;
  - a `:derived` association from every assignment validation, and every submission check, to the version used;
  - `:current-domain-version` on the run topic.
- No buttons, no execution controls.

## 12. Implementation map (W1 files only)

| File | Change |
|---|---|
| `dreyeck/work/welcome-development-domain-versions.lisp` (new, after the package file) | version id, Eclector reading client and screen, `domain-version-tag-commit`, blob and form reading, private domain cache (`development-domain-object`, `clear-development-domain-cache`), `describe-development-domain-version` (read-only; prints id, blob and proposed tag ref) |
| `welcome-development-records.lisp` | `dev-domain-version` class, admission, version-aware replay, `:validator` provenance |
| `welcome-development.lisp` | `plan-development-state (state domain)` with transient problems; binding v2; `assignment-proposal-binding … :domain-version`; current-version reporting |
| `welcome-development-views.lisp` | §11 topics, Inspector line from §9 |
| `welcome-development-examples.lisp` | fixture journals: policy, `dev-domain-version :fixture`, … |
| `welcome-development-package.lisp`, `dreyeck.asd` | exports, new component; **add `"eclector"` to `dreyeck/work/welcome-development` `:depends-on`**. It is not declared anywhere today (§1) |
| `dreyeck/tests/welcome-development.lisp` + `scripts/test-welcome-domain-versions.lisp` (new, separate disposable image) | §13 |

**Unchanged:** `dreyeck/shop3/**`, `dreyeck/src/**` (including `git-commit-refs-containing`), defederation, local-only, authority and fork execution.

**Missing APIs, marked and not invented:**
- a shared `refs/tags` lookup in `dreyeck/git`;
- the W2 Eclector client itself (the hooks exist, §5.1);
- a shared balanced-form extractor (only the internal `%form-text` exists);
- tag signature verification.

## 13. Acceptance criteria (executable)

**Tests that need tags use a temporary git repository created by the test in its own temp directory.** It contains two commits of the domain file and tags created by the test fixture, and is deleted afterwards. The project repository is never tagged, written or fetched.

**A1 Identity.**
- Loaded domain id = id rebuilt from the git blob of the same source.
- The same id from two separate processes.
- Identical items at two commits give the same id; one changed item gives a different id.

**A2 R5 reversed** (disposable image):
- record a journal under version A;
- load A plus one unused axiom (B) as the public domain;
- the journal replays and is accepted;
- a new assignment binds to B only after B's `dev-domain-version`.

**A3 Public registration untouched.** Snapshot `(get 'welcome-development :domain)`, `(symbol-plist 'welcome-development)` and `shop3:*domain*`, then check EQ/EQUAL after each of:
- successful replay;
- cache clear;
- injected failure during reading;
- injected failure during the screen;
- injected failure during `make-domain` (error after install, via `sb-int:encapsulate` on `shop3::install-domain`);
- injected failure during the id check;
- injected failure during `find-plans`.

Also: replay succeeds after `(shop3:delete-domain 'welcome-development)` in a disposable image.

**A4 Private isolation.**
- `(symbol-package (shop3::domain-name d))` is NIL.
- No interned `WELCOME-DEVELOPMENT@…` symbol exists.
- After `clear-development-domain-cache`, the private symbol's `:domain` is NIL, the cache is empty, and the return value equals the entry count.
- On a failed creation, nothing is cached and the private registration is NIL.

**A5 Tags.** Each of these is refused:
- tag missing;
- tag pointing at another commit;
- commit only on a branch, with no tag.

Each of these is accepted:
- annotated tag;
- lightweight tag.

Before and after replay, `for-each-ref refs/tags` output is identical (no tag created). Strace shows only read-only git subcommands (`cat-file`, `rev-parse`, `show`) and 0 network system calls.

**A6 Forgery and staleness.** Each of these is refused for the stated reason:
- blob or form digest mismatch;
- unknown version id in a binding;
- binding version swapped for another valid version;
- domain items supplied only in a record;
- planner pin mismatch;
- duplicate version record;
- version record after its first use;
- v1 binding;
- mixed fixture and observed versions.

**A7 Trust screen.** Each of these is refused **before** `make-domain` is called (counter via `sb-int:encapsulate`) and before any symbol is interned outside the W1 package and `KEYWORD` (symbol counts of the probe packages, before and after):
- `:include`;
- `#.`, both with the caller's `*read-eval*` NIL and with it T;
- a reader error wrapped as recoverable, without any restart being invoked;
- `#+`/`#-`, with the feature symbol not interned in the W1 package;
- `#S(…)`;
- `#P"…"` (refused by the literal-data screen);
- uninterned `#:x`;
- a foreign package prefix, both `pkg:sym` and `pkg::sym`;
- a second `(shop3:defdomain` occurrence in the file, and trailing input after the extracted form;
- `shop3:call` with a non-allowlisted function (e.g. `cl:delete-file`);
- each of `eval`, `assign`, `assign*`, `enforce`, `setof`, `bagof`, `:external`;
- a non-literal operator cost;
- `:type` / `:redefine-ok` options;
- two defdomain forms.

The W1 domain at `61cdec0` passes.

**A8 Submission follows its assignment's version.** Assign under A; switch the public domain to B; the first claim is admitted through A's `!await-submission`. C1–C3 are still refused.

**A9 Regressions.** All of the following still pass:
- P0–P11, P4b/P10 refusals, `:complete`;
- F1–F5 and C1–C3 negatives, the first-submission positives;
- `:PLAN-ONLY`;
- Inspector/Topicmap EQ;
- binding determinism (new v2 digest, stable across processes);
- the Defederation and Local-only suites, unchanged.

**A10 L1.**
- After 100 `development-workflow` runs of `:complete` and 20 `fixture-records` builds, `(length shop3::*all-problems*)` and `shop3::*problem*` are unchanged.
- The same holds when `find-plans` signals (injected).
- The cache size equals the number of distinct versions used.

**A11 Provenance views.**
- Every validation and submission check links EQ to its version object, which links EQ to the git commit object.
- Fixture versions are only ever `:hypothesized`.
- The run shows `:current-domain-version` and `:current-version-tagged`.

**A12 Validator non-claim.** `:validator` provenance is present on versions and runs. The Inspector shows the §9 sentence. No test asserts historical validator behaviour.

**A13 Separation.**
- No change under FedWiki, authority or fork-execution paths.
- No executor capability, Catalog member or button is added.
- The fixture part makes 0 network system calls and runs 0 git commands.

## 14. Decisions recorded

| Decision | Choice |
|---|---|
| Retention | dedicated tag `refs/tags/hyperdoc/welcome-development/<id>`; branches insufficient |
| Tag creation | human, outside W2; never during replay |
| Historical domain | trusted code; the tag is the approval; screen = defence in depth |
| Version scope | planning domain only; validator recorded as provenance, not replayed |
| Problem registry | transient per planner call; private domain cache explicitly clearable |

## Appendix A: Eclector design probe (executed, not committed)

**Setup:**
- one disposable SBCL 2.4.10 process;
- empty `HOME`, private FASL cache, `unshare --net`;
- `CL_SOURCE_REGISTRY` = the runtime registry used for the W1 reviews;
- `(asdf:load-system "eclector")` → version `0.11.0` from `/nix/store/0k97waw59qnfwdx11l5jpmy502b7s3q0-sbcl-eclector-20241012-git/`.

**Not used:** the HyperDoc tree and SHOP3. A stand-in package `SHOP3` exporting `DEFDOMAIN`, `CALL` and `FORALL` was defined in the probe image only.

**The probe client** is a stand-in for the W2 client, not its implementation:

```lisp
(defclass screen-client () ())
(defmethod eclector.reader:interpret-symbol ((client screen-client) stream indicator name internp)
  ;; NIL → refuse; :keyword → intern in KEYWORD; :current → existing allowlisted CL/SHOP3 symbol
  ;; or intern in the stand-in W1 package; string → only existing allowlisted symbols, else refuse.
  ...)
(defmethod eclector.reader:evaluate-expression ((client screen-client) expression) (error 'refused ...))
(defmethod eclector.reader:evaluate-feature-expression ((client screen-client) fe) (error 'refused ...))
(defmethod eclector.reader:make-structure-instance ((client screen-client) name initargs) (error 'refused ...))
;; (let ((eclector.reader:*client* (make-instance 'screen-client)) (*package* <W1 stand-in>))
;;   (eclector.reader:read-from-string text))
```

**Observed results:**

| Input | Result |
|---|---|
| domain-shaped `(shop3:defdomain (welcome-development :noset t) (… (shop3:call < ?n ?max) …))` | read; symbols in the stand-in W1 package, `SHOP3:CALL`, `CL:<` |
| `(a #.(< 1 2))`, `*read-eval*` T | `ECLECTOR.READER:READ-TIME-EVALUATION-ERROR` wrapping the client refusal |
| `(a #.(< 1 2))`, `*read-eval*` NIL | `ECLECTOR.READER:READ-TIME-EVALUATION-INHIBITED` |
| `(a #.(delete-file "x"))` | refused by the symbol policy (`DELETE-FILE`) before evaluation |
| `(a #+sbcl b)` | refused; the feature symbol was interned in the stand-in current package (finding 3 in §5.1) |
| `(w2probe-other::newsym)`, `(w2probe-other:missing)` | refused; the foreign package's symbol count was unchanged |
| `(#:x)` | refused |
| `#S(foo :a 1)` | refused |
| `#P"/etc/passwd"` | **read as a pathname** (finding 2 in §5.1) |
| `(#'car)` | refused by the symbol policy (`CAR`) |

The probe does not establish the full W2 client. The open items in §5.1 remain implementation-time probes and are covered by A7.
