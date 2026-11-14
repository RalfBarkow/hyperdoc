# Upstream intake: observe, assess, decide (read-only)

`dreyeck.ch` uses Konrad Hinsen's HyperDoc as a library. When upstream publishes new commits, this workflow answers, for each commit and each changed
definition: what changed, where that definition stands in the fork now, which ASDF system owns it and which should, what it may affect, and what to do. It
reads Git objects and source text. **It loads, compiles and evaluates no library code, fetches nothing, writes nothing in a repository, and executes no
decision.**

It builds on what was there and adds one layer:

| Layer | System | Was there |
|---|---|---|
| Availability, ancestry and classification of a commit (`:not-available-locally`, `:available-not-integrated`, `:already-integrated`) | `dreyeck/workflow/upstream-intake` | yes, used as it is |
| Git objects: commits, parents, files, blobs | `dreyeck/git` | yes, used as it is |
| Lisp and ASDF text as syntax, without `READ` | `dreyeck/asdf-source` | yes, now also used for library `.lisp` files |
| Source forms and the ASDF-owned paths of a system | `dreyeck/workflow` (`OWNED-PATHS`) | yes |
| **Commit evidence, changed definitions, fork situation, ownership, impact, decisions and their ledger, the run** | `dreyeck/workflow/upstream-assessment` | **new** |
| Inspector views and the chain as a Topicmap workspace | `dreyeck/inspector/upstream-assessment` | **new**, on `dreyeck/inspector/topicmap` |
| The page and examples that read it | `dreyeck/upstream-intake` (the existing HyperBook, one page more) | extended |

## Terms

A question about an upstream commit mixes five relations. They are different, and the assessment keeps them apart.

| Term | A relation of | Found from | The assessment says | It does not say |
|---|---|---|---|---|
| **Git fork** | history | the fork's Git: objects present, `merge-base --is-ancestor` | `Git ancestry`: not available, available not integrated, already integrated | whether the commit's definitions stand in the fork's source |
| **Library dependency** | loading | the ASDF definitions as text: `:depends-on`, component paths | which systems list a file and which depend on them | anything that loading would do; nothing is loaded |
| **Local definition** | text | digests of canonical syntax trees, compared | unchanged, adopted, changed, changed-part-elsewhere, moved, absent, ambiguous | why the text differs |
| **Dreyeck extension** | intent | not from source text; from what a document of the checkout states, quoted and checked | the statement, with its source | that a definition is an extension, unless a recorded inventory says so |
| **Code ownership** | maintenance | the ASDF owner (derived), the path default (derived), statements and proposals (observed in their source) | all three side by side, and whether the intended owner is decided | a decision; ownership here is never inferred from where a file came from |

A proposal that is not integrated (today: the per-definition inventory of draft #21) is shown as *proposed elsewhere, not in force*. It is recorded as data with
its source, the head commit it was read at and the digest of its file, and it is compared by digest with the text of the fork now. It changes no category, no
proposal and no decision. Integrating #21 would put an inventory in `docs/code-ownership/`, which `default-ownership-policy` already reads; the statements file
would then be superseded by it.

## What is kept apart

| | Where it comes from | Who changes it |
|---|---|---|
| **Last examined upstream state** | `docs/upstream-intake/state.lisp-data` | a person; no run does |
| **Observed upstream state** | the tip of a ref in an upstream repository this run is given to *read* | the world |
| **Objects available** | in the upstream repository given, in the fork's Git, or as recorded evidence; otherwise *missing evidence* | nothing is fetched |
| **Git ancestry** | `merge-base --is-ancestor` in the fork's Git | history |
| **Source adoption** | the fork's source tree compared, definition by definition, with the commit's definitions | the source |
| **Decision** | `docs/upstream-intake/ledger.lisp-data` | a person; a rule only *proposes* |

A commit is never integrated because its definitions *look* adopted: the report keeps `Git ancestry` and `source adoption` as separate columns. In the
worked example the fork's source adopted a definition of `8a1149197` without those commits being in its history, which `docs/hyperdoc-upstream-boundary.md`
already said in prose; here it is a field.

Every claim carries one of the epistemic statuses of the existing workflow reading, with the words of the request in brackets:
`:SOURCE-OBSERVED` (observation), `:MECHANICALLY-DERIVED` (derived evidence), `:DESIGN-INFERENCE` (inference), `:WORKING-HYPOTHESIS` (hypothesis).

## Status: a manual workflow, not yet an automated one

Today a person runs the entry point (below), reads the report and decides. **Nothing triggers it, nothing runs it periodically, and nothing acts on its result.** Three things stay
separate, and none of them is an integration:

| | What it is | What it is not |
|---|---|---|
| **Observation** | which upstream commits exist, and which of them this checkout has objects for | not a fetch, not a merge |
| **Impact assessment** | per changed definition: where it stands in the fork, who owns it, what it may affect, and a *proposal* | not a decision |
| **Decision log** | `ledger.lisp-data`: what a person decided, against which state of the fork, with supersession and history | not an execution; recording `:adopt-upstream-change` changes no source |

An actual integration (taking an upstream change into the fork) is a separate, explicitly authorized operation that this workflow does not contain. Triggering it automatically (a webhook receiver, a mail rule,
a periodic job) is described below as a possibility only; it is not installed, and doing so is a separate decision.

## The entry point

```bash
nix develop .#fedwiki-original-editor -c sbcl --noinform --no-sysinit --no-userinit --script scripts/upstream-intake.lisp \
  --upstream-repository /path/to/hyperdoc-khinsen-upstream
```

It is read-only and repeatable. `--upstream-repository` names a repository that this run may read (a separate checkout of upstream, never this one, never
written, never fetched into). It observes `--ref` (default `main`), takes the range from the recorded last examined commit to that tip, and reports each
commit. `--commit SHA` assesses a commit that a notification names, whatever the range.

| Exit status | Meaning |
|---|---|
| 0 | nothing new since the last examined state |
| 10 | new commits were assessed; decisions are needed |
| 20 | for some commit neither objects nor recorded evidence exist: missing evidence (nothing was fetched) |
| 2 | usage |

`--record-evidence SHA FILE` is the one command that writes, and only the file you name: it saves what a read-only look at that commit in the upstream repository
shows, as plain data. That is how a commit whose objects are not in this checkout (here: `58a2b2c`) enters the workflow without touching this checkout's Git.

**How it would be triggered later.** The same command, with the same arguments, from whatever learns of a new upstream commit: a Codeberg webhook receiver
or a mail rule that calls it with `--commit SHA`, a periodic job that calls it without, or a person. Its exit status says whether anything needs
attention. **Nothing is installed here**: no service, no cron entry, no timer, no scheduler. That is a separate decision.

## Identity of a definition

A definition is followed across versions by a **key**, computed from source text and the file's own package context. Nothing is loaded, so nothing is looked up: whatever
the text and the `in-package` forms do not prove is not assumed.

| | Rule | Consequence |
|---|---|---|
| Package qualifiers | `P:x` and `P::x` read as `x` **only** in a file whose current `in-package` is exactly `P`. No other qualifier is touched; names are never normalized by their symbol name alone | `hyperdoc:hyperdoc` and `hyperdoc` are the same key in a file in package `hyperdoc`, two keys anywhere else (and in a file without `in-package`) |
| Candidates | Where a removed and an added definition (or a commit's definition and a fork definition) differ **only** in package qualification, both are listed as *possible counterparts*, marked `:WORKING-HYPOTHESIS` | the pairing is visible and decides nothing: the relation stays `:absent`, and the change is a removal plus an addition, not a modification |
| Methods | `method:GENERIC:QUALIFIERS:SPECIALIZERS`, as written (`(eql :html)` and all). Parameter names, the body, layout, case and the lambda-list keywords after the specializers are not identity | `render :around`, `render` on another class, `(setf render)` are different definitions |
| Anonymous forms | `form:HEAD:DIGEST` of the form's own text; identical forms in one file are numbered `#2`, `#3`. A form found in the fork counts only in the same file | inserting one does not renumber the others; two different forms never merge; one of two identical forms removed is one removal; a form that is modified is a removal and an addition (no equation without proof) |
| Ambiguity | More than one fork definition with the key → relation `:AMBIGUOUS`, all locations listed, nothing chosen; it is never `:adopted`, and the proposal is `:defer` | the case stays visible in the report, the views and the chain |

## Repeating an intake, and a fork that changes

Intake is idempotent: the same revision assessed twice gives the same report, the same digests, and writes nothing (the ledger is changed only by a person, or by the
command that is told to). Each decision records the **situation digest** of the fork it was taken against (relation, where the definitions stand and with which digests, where each
changed part stands). When the fork changes, a new assessment has a new digest and the older decision is shown **stale** (`STALE` in the report, a note in the view); it is not removed
and not rewritten. A new decision for the same subject is recorded **beside** it and names the one it `:supersedes`; both stay in the ledger (`ledger-history`), only the later is in
force (`ledger-find`). A second decision for a subject without naming what it supersedes, or a second supersession of the same decision, is a conflict.

## Impact assessment

For each changed definition (`defun`, `defmethod` with its qualifiers and specializers, `defclass`, `defpackage`, `defsystem`, ...; forms that define nothing named
are followed by the digest of their text) the assessment gives:

1. **What upstream changed**: the definition before and after, the smallest changed list pairs (`CHANGED-FRAGMENTS`), and the handler forms of the
   definition with what each protects and which clauses it has, so that "which attempt did this change" is a derived fact.
2. **Where the definition stands in the fork**: `:unchanged` (as upstream had it before), `:adopted` (as upstream has it after), `:changed` (a local version),
   `:changed-part-elsewhere` (the text that the commit changed no longer stands in it, and the same text stands, before, after or extended, in other definitions: **a finding about text, not a statement that those definitions replace this one or behave the same**; the relation was called `:replaced` until 2026-11-03, and decisions recorded under that name stay in force, because the situation digest still reads it as `replaced`), `:moved` (the same key at another path), `:absent`.
3. **Which ASDF system owns it now**, from the ASDF definitions of the checkout (component pathnames; nothing is loaded), and **which should**, from the
   ownership policy: the contract's library paths are upstream-owned, everything else dreyeck-owned, and an ownership inventory, when the checkout has one
   (`docs/code-ownership/inventory.lisp-data`), decides case by case.
4. **What may be affected**: the owning and dependent systems, the test systems among them, definitions and HyperDoc pages that mention the name, and the
   contract files that name it. A mention is a lead, not proof of a call.
5. **A proposal**, by rule: `:adopt-upstream-change`, `:already-covered`, or `:defer`; never executed. A person's **recorded decision** stands beside it, from the
   ledger: also `:move-dreyeck-extension`, `:prepare-upstream-contribution`, `:do-not-adopt`.

## Reading it: objects, not a table

The Inspector views are laid out for two kinds of reading, the distinction that Hans Peter Willberg and Friedrich Forssman draw in *Lesetypografie* (informing and consulting reading). *Informing* reading is a glance down a pane that may be narrow: one idea per block, headings that
differ by weight and size, the labels in a column of their own, a measure of about 70 characters, left-aligned and ragged. *Consulting* reading looks something
up and goes on: every definition, ASDF system, claim, decision and ownership judgement that the text names is an Inspector reference, drawn alike (underlined,
one colour), and no identifier is cut off. Identifiers wrap where they must, they are never clipped or hidden, and nothing uses a `nowrap` table cell. (The
Inspector's own title bar clips what does not fit; the views therefore keep the title short and put the full identifier in the first heading.) The commit
view lists each changed definition as a card with its references: the change, the situation in the fork, the definitions that the fork has, the ASDF system, the
ownership judgement and the decisions. `dreyeck/upstream-assessment/tests` checks that those references are there, that there is no table of prose, and that the
style does not clip; `scripts/test-upstream-assessment-browser.mjs` walks the case in a served Catalog with a real browser, from the page to the claim, at 1280 and at 520 pixels.

## Reading a page that links an example, served

`defexample` marks a function of no arguments as an example. In a served Catalog the page shows its source with a marker, `▷`, whose tooltip reads *Not run here:
no operation contract*. That marker is about **execution**: upstream puts a run button before an example's source, and dreyeck offers it only for an example
with a reviewed operation contract. The link `<a expr="(example)">` is **navigation**: the page's own expression is evaluated when the page renders, which a
visitor cannot choose, and the Inspector opens its result. These examples have no contract, deliberately, because nothing needs to run; `check-example-navigation-needs-no-contract`
asserts that a served page leads to the assessment, the chain and the run, offers no thunk, shows the marker, refuses a run obtained anyway, and that a development
server offers the button. If an execution is ever needed, the proposal is a contract for that one example: observational, reading only `docs/upstream-intake/` and
the checkout's source files, opening no Git repository, running no process, fetching and writing nothing, with the tests that show no repository changed. None is
registered.

## The worked example: 58a2b2c "Catch more name service errors"

Konrad Hinsen's commit changes `usocket:ns-host-not-found-error` to `usocket:ns-error` in one handler of `make-fedwiki`. The assessment (evidence recorded from a
read-only look at upstream; the commit's objects are not in this checkout) shows:

- **the changed handler**: the second of the two `handler-case` forms, the one that protects `fetch-sitemap` and `fetch-plugin-data`;
- **the first connection attempt**, the HTTPS probe with `usocket:socket-connect`, as its own handler with clauses `connection-refused-error` and
  `ns-host-not-found-error`: *unchanged* by the commit (derived from the syntax of the two texts);
- **the fork**: `:CHANGED-PART-ELSEWHERE`. `make-fedwiki` is there, but the text of the changed type list stands in `initialize-fedwiki` (`hyperbook-fedwiki/fedwiki.lisp`), which the fork's `make-fedwiki` calls. That `initialize-fedwiki` is the dreyeck counterpart of upstream's second handler is a working hypothesis from reading both; no rule equates them. The upstream
  hunk does not apply to the fork's file; with RalfBarkow/hyperdoc#15 merged the same finding reads "extended" instead of "before";
- **owner**: three things side by side, none of them a decision for this definition: the ASDF system that lists the file now (`hyperbook/fedwiki`, derived), the path default (upstream-owned, derived), what `docs/hyperdoc-upstream-boundary.md` says of the FedWiki initialization deltas (reusable library fixes, candidates for contribution; quoted, and the quotation is checked against the document), and what the draft RalfBarkow/hyperdoc#21 proposes (`:reusable-extension`, target `hyperbook/fedwiki`, `:pending`; **not integrated, not in force**, recorded in `ownership-statements.lisp-data` with the head commit and the file's digest). The intended owner is not decided; the views say so under *Open*. Dependents, tests, the HyperDoc pages and the contract files that may be affected;
- **issue #13 and PR #15**: the analysis of #15 is *reused, not redone*: its measured scenario matrix and the `ns-unknown-error` evidence are imported byte for
  byte (`docs/upstream-intake/evidence/58a2b2c/`, with their digests and their source commit) and the decisions cite them. The matrix shows that upstream
  `58a2b2c` still ends the process in the first connection attempt, with the real resolver, and survives the site-map step;
- **`ns-error` or the explicit classes**: a recorded decision `:DEFER`, *proposed*: for the three conditions the SBCL backend raises the choices behave the same;
  they differ for `ns-unknown-error` only, which is never raised and cannot be printed. It is for the maintainers, with upstream's choice in view;
- **a second decision**, `:PREPARE-UPSTREAM-CONTRIBUTION`, *proposed*: upstream lacks the handling in the first attempt;
- **the ownership and test contract**: `dreyeck/hyperdoc/library-tests` compares the library paths with `8a1149197`; that commit is an ancestor of `58a2b2c`, so the
  reference stays where it is. The check that names the change (`check-initialize-fedwiki-dns-change`) exists only in the draft #15.

Read it in the Catalog: **Upstream Intake → Assessing an Upstream Commit → "Assess 58a2b2c against this checkout's source"** opens the commit assessment; its
changed definition opens the change, with the handler forms, the fork's situation, owners, impact and the decisions; *The chain as a Topicmap* shows commit,
changed definition, current definition, ASDF owner, impact, decision, required migration and verification, each link named by the status of what supports it.

## A real run, and a synthetic one

`evidence/run-2026-11-02.txt` is the report of the entry point against the real fork and the real upstream (`main` at `c165990`, eight commits after the last
examined `8a1149197`). Nothing in it was decided: five commits have proposals by rule, `58a2b2c` has the two recorded decisions, and the two newest ones (`8d1cc1c`
exports one symbol, `c165990` changes CSS only) have a proposal or no code change. The state file recorded `8a1149197` at the time of that run. The later source intake records `bdad8d9b` in the [library boundary](../hyperdoc-upstream-boundary.md).

The tests (`dreyeck/upstream-assessment/tests`) use no real upstream. They build an "upstream" repository with four commits and a "fork" that replaced, adopted and
extended parts of it, with ASDF definitions of their own, and check, among others: that no library source ran (a canary and a package stay untouched),
that no repository changed (refs, `HEAD`, status and object count equal before and after), that a commit that is nowhere is missing evidence and nothing is
fetched, that recorded evidence gives the same assessment as the objects and is refused when its digests do not match, that the identity points above hold (package context, methods, repeated anonymous forms, ambiguity), that several commits are told apart and
observing twice records nothing twice, that a changed fork gives a stale decision and a new one beside it, that adoption without ancestry and ancestry without adoption are different answers, and that a decision for the same
subject cannot be overwritten. The worked example has its own checks against the real source.

## Limits

- **The state is advanced by a person.** After a commit is decided, moving `:last-examined` is a deliberate edit; the run only proposes the range.
- **Fragments are lists, not semantics.** The tool finds that a changed list stands elsewhere in the fork; whether the two versions *behave* the same is a
  decision, which is why such a change is proposed as `:defer`.
- **Package context is the file's `in-package` only.** A `defpackage` with `:use`, shadowing or nicknames is not interpreted; where the spelling differs and the text does not show the packages equal, the two are kept apart and offered as candidates.
- **Reading by scanning.** `#+`/`#-` are not applied and `#.` is not evaluated, so the tree is the same in every image; that is also why what ASDF would see can
  differ from what is scanned.
- **Mentions are leads.** Impact lists are searches over the fork's source, not call graphs.
- **No scheduler, no notification receiver, no automatic adoption.**

## Files

| | |
|---|---|
| `dreyeck/src/upstream-assessment*.lisp` | the model, the syntax layer, the run |
| `dreyeck/src/upstream-assessment-views.lisp` | Inspector views and the chain |
| `dreyeck/src/upstream-assessment-hyperdoc.lisp`, `dreyeck/pages/upstream-intake/Assessing an Upstream Commit.html` | the examples and the page |
| `scripts/upstream-intake.lisp` | the entry point |
| `docs/upstream-intake/state.lisp-data`, `ledger.lisp-data`, `evidence/` | the recorded state, decisions and evidence |
| `docs/upstream-intake/ownership-statements.lisp-data` | what is said about ownership: quotations from this checkout, and the proposal of a draft that is not in force |
| `dreyeck/tests/upstream-assessment*.lisp` | the tests |
