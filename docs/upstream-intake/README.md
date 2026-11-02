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

## Impact assessment

For each changed definition (`defun`, `defmethod` with its qualifiers and specializers, `defclass`, `defpackage`, `defsystem`, ...; forms that define nothing named
are followed by the digest of their text) the assessment gives:

1. **What upstream changed**: the definition before and after, the smallest changed list pairs (`CHANGED-FRAGMENTS`), and the handler forms of the
   definition with what each protects and which clauses it has, so that "which attempt did this change" is a derived fact.
2. **Where the definition stands in the fork**: `:unchanged` (as upstream had it before), `:adopted` (as upstream has it after), `:changed` (a local version),
   `:replaced` (its changed part stands in other definitions, before, after or extended), `:moved` (the same key at another path), `:absent`.
3. **Which ASDF system owns it now**, from the ASDF definitions of the checkout (component pathnames; nothing is loaded), and **which should**, from the
   ownership policy: the contract's library paths are upstream-owned, everything else dreyeck-owned, and an ownership inventory, when the checkout has one
   (`docs/code-ownership/inventory.lisp-data`), decides case by case.
4. **What may be affected**: the owning and dependent systems, the test systems among them, definitions and HyperDoc pages that mention the name, and the
   contract files that name it. A mention is a lead, not proof of a call.
5. **A proposal**, by rule: `:adopt-upstream-change`, `:already-covered`, or `:defer`; never executed. A person's **recorded decision** stands beside it, from the
   ledger: also `:move-dreyeck-extension`, `:prepare-upstream-contribution`, `:do-not-adopt`.

## The worked example: 58a2b2c "Catch more name service errors"

Konrad Hinsen's commit changes `usocket:ns-host-not-found-error` to `usocket:ns-error` in one handler of `make-fedwiki`. The assessment (evidence recorded from a
read-only look at upstream; the commit's objects are not in this checkout) shows:

- **the changed handler**: the second of the two `handler-case` forms, the one that protects `fetch-sitemap` and `fetch-plugin-data`;
- **the first connection attempt**, the HTTPS probe with `usocket:socket-connect`, as its own handler with clauses `connection-refused-error` and
  `ns-host-not-found-error`: *unchanged* by the commit (derived from the syntax of the two texts);
- **the fork**: `:REPLACED`. `make-fedwiki` is there, but the changed type list stands in `initialize-fedwiki` (`hyperbook-fedwiki/fedwiki.lisp`). The upstream
  hunk does not apply to the fork's file; with RalfBarkow/hyperdoc#15 merged the same finding reads "extended" instead of "before";
- **owner**: `hyperbook/fedwiki`, upstream-owned; dependents, tests, the HyperDoc pages and the contract files that may be affected;
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
exports one symbol, `c165990` changes CSS only) have a proposal or no code change. The state file still says `8a1149197`.

The tests (`dreyeck/upstream-assessment/tests`) use no real upstream. They build an "upstream" repository with four commits and a "fork" that replaced, adopted and
extended parts of it, with ASDF definitions of their own, and check, among others: that no library source ran (a canary and a package stay untouched),
that no repository changed (refs, `HEAD`, status and object count equal before and after), that a commit that is nowhere is missing evidence and nothing is
fetched, that recorded evidence gives the same assessment as the objects and is refused when its digests do not match, that several commits are told apart and
observing twice records nothing twice, that adoption without ancestry and ancestry without adoption are different answers, and that a decision for the same
subject cannot be overwritten. The worked example has its own checks against the real source.

## Limits

- **The state is advanced by a person.** After a commit is decided, moving `:last-examined` is a deliberate edit; the run only proposes the range.
- **Fragments are lists, not semantics.** The tool finds that a changed list stands elsewhere in the fork; whether the two versions *behave* the same is a
  decision, which is why such a change is proposed as `:defer`.
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
| `dreyeck/tests/upstream-assessment*.lisp` | the tests |
