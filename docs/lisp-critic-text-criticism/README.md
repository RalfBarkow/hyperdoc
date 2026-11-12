# Source-backed criticism of a text page

> **DRAFT — work-in-progress checkpoint, 12 November 2026.** Not reviewed, not accepted.
>
> - Outstanding documents: `worked-reading.md` is not written. `rule-base.md`,
>   `shop3-planning-handover.md` and `terminology-and-sources.md` are drafts.
> - **Unresolved, and not yet reconsidered here:** the section "Reading without
>   running" and the reader contract in the table describe `read-claim-table` as
>   committed at `1da262deee28c614ab63c2311f5355de2dfaafc5`. Codex has since
>   reported three violations of that contract (a `#S` constructor effect, a false
>   definition inside a block comment, a feature-dependent table) and published a
>   correction at `c0b5f8328805ebfaa929f4ff4c2e51052dd39511` on
>   `codex/lisp-critic-reader-safety`. That correction is under independent review.
>   Until this document is revised, do not rely on its statements about what
>   reading the claim table cannot do.
> - Everything else below is as written before that report.

Branch `claude/lisp-critic-text-criticism`, based on `dreyeck.ch` at
`596344ae95d746f436705808462259371f5a593c`. An optional slice: it adds three
ASDF systems and changes no existing source file, page, test or dependency pin.

| Document | Content |
|---|---|
| this file | what the slice is, its behavioural contract, what it is not |
| [review-report.md](review-report.md) | the criticisms of the reviewed pages and code, each with its origin |
| [rule-base.md](rule-base.md) | the Riesbeck/Beane rule base as read from source, its limits, a deferred diagnostic |
| [worked-reading.md](worked-reading.md) | one engine Critique and one reviewer judgement read side by side (draft page text) |
| [shop3-planning-handover.md](shop3-planning-handover.md) | how SHOP3 is meant to use these records; reuse analysis; the next slice |
| [terminology-and-sources.md](terminology-and-sources.md) | the vocabulary, and which sources were read |
| [evidence/](evidence/README.md) | what was executed, what was NOT RUN |

## The case

"The Fischer Critic as an Environment" says, in its paragraph on what has been
read (characters 4160–4629 of the page at the base revision):

> Neither Fischer paper has been read here. Only the first claim on this page is
> currently carried by something observed — a secondary research note … Every
> other Fischer claim cites a paper and reports `:OBSERVED-EVIDENCE-KIND
> :NONE-OBSERVED` …

`historical-claims` in `dreyeck/src/lisp-critic-reading.lisp`, at the same
revision, holds ten claims that cite a primary paper. Five of them, the first
among them, record `:observed-evidence-kind :primary-paper`.

That is a criticism of the second kind HyperDoc already has: not a finding of
the Riesbeck engine, but observations, a judgement resting on them, and a
recommendation, as in `dreyeck/src/lisp-critic-federated-context.lisp`. Until
now that kind existed for code forms of one page. This slice gives it a text
passage as its target.

## What the slice adds

`dreyeck/lisp-critic/text-criticism` (depends on Ironclad only):

**`dreyeck/src/lisp-critic-text-passage.lisp`** — the mechanism.

| Function | Contract |
|---|---|
| `observe-source-state (recorded &key root octets)` | For each recorded file: `:recorded-snapshot` (SHA-256 and Git blob id of the octets equal the recorded ones), `:changed`, `:absent`, `:unreadable` (not valid UTF-8; the condition is reported, not signalled). `:content` is `:matches-recorded` only when every file is `:recorded-snapshot`. Separately, `:revision-binding`: `:verified` when Git, asked now, names each recorded blob at its path in the recorded commit; `:contradicted` when Git knows the commit and names another blob, no such path, or the name is not a commit; `:not-verified` when Git could not be asked, does not have the commit, or the revision is not a full object id. |
| `source-coherence (observation)` | `:verified-revision`, `:recorded-content` (the texts are the recorded ones; commit membership was not verified here), or `:not-determined` with the reason. |
| `observe-passage (passage text)` | `:present-once`, `:absent` or `:ambiguous`, and whether the passage stands at its recorded characters. |
| `read-claim-table (text)` | The quoted table of the one definition of `historical-claims`, as data — or NIL and a reason. See "Reading without running". |
| `observe-claim-evidence (table)` | For each claim that cites a primary paper: subject, id, observed evidence kind; counts. |
| `passage-discrepancies (reading claim-observation)` | The assertions of a reading that the table does not bear out; NIL when it bears out all. An unknown kind of expectation is an error. |
| `criticise-passage (recorded reading &key root octets)` | All of the above. `:discrepancies` is a list, NIL, or `:not-determined`. It is `:not-determined` whenever content does not match, the revision is contradicted, the passage is not present once, or the table is unreadable. `:scope` is `:verified-revision` only when Git confirmed the commit. |

**`dreyeck/src/lisp-critic-text-criticism.lisp`** — the one instance, as records:
`recorded-source-state`, `recorded-observations`, `passage-reading`,
`judgement`, `recommendation`, and `observe-now`, which observes the two files
again. `image-agreement` says whether the claim table an image has loaded is the
one the source declares, and `:reading-system-not-loaded` where it is not.

### Six kinds of thing, kept apart

| Kind | Here | Made by |
|---|---|---|
| Source observation | file states, passage status, claim table; `:evidence-status :observed` | a probe, executed; or recorded at a named state with its method |
| Derived discrepancy | result of `passage-discrepancies`; `:derivation … :status :derived` | comparison, by a named rule, of a reading with the table |
| Reviewer judgement | `judgement`, and `passage-reading` (what the paragraph is taken to assert); `:evidence-status :interpreted` | Claude |
| Recommendation | `recommendation`; no evidence status; `:applied-p nil` | Claude |
| Engine-produced Critique | none in this slice | — |
| SHOP3 planning result | none in this slice | — |

The judgement says that the paragraph and the records disagree. It does not say
which is wrong. The page is not edited.

### Content identity is not revision membership

Equal SHA-256 and equal blob id show that the octets read now are the recorded
octets. They do not show that the recorded commit contains them. That is a
separate question put to Git, with three answers, and it is reported separately.
A result is about a revision only when the answer was `:verified`.

### Reading without running

The claim table is taken from source text, never from a loaded function.
`read-claim-table` finds the one line that begins `(defun historical-claims`,
and reads one form from there with the standard readtable, `*read-eval*` false
and a package made for the purpose and deleted afterwards. `#.` is therefore a
reader error. The form is never evaluated, compiled or loaded. It is accepted
only if it is exactly
`(defun historical-claims () [docstring] (copy-tree (quote table)))` and the
table is a list of property lists with keyword keys and literal values
(keywords, strings, integers, T, NIL, proper lists of these). Everything else is
refused with a reason.

The existing structural reader of `html-inspector-views` was not used: its
client does not override Eclector's read-time evaluation, so by its source it
does not by itself rule out `#.`. That is a reading of its source, not a test
of it.

## Compatibility with the existing judgement-basis resolver

`resolve-judgement-basis` (`lisp-critic-federated-context.lisp`) is reused
unchanged. It reads `:id`, `:state` and `:targets` on observations and `:basis`
and `:targets` on a judgement. The recorded observations carry `:id :passage`
and `:id :claims`, `:state` the full commit id, and string targets; the
judgement's basis names both. The integration tests exercise the resolver
positively and negatively; they were not run by the implementer (see
[evidence/](evidence/README.md)).

## Differences from the approved plan

- Three systems instead of four, and no dependency on the reading system: the
  mechanism and the instance are in one dependency-light system so that its
  tests can run without HyperDoc; only the integration tests need HyperDoc.
- The claim table is read with the standard reader under `*read-eval*` false,
  not with the `html-inspector-views` parser, for the reason given above.

## What this slice is not

- No rule of the Riesbeck engine was added or run. No `critique` object, no
  Evaluation Record, no Inspector view and no SHOP3 domain was created.
- The records are plain lists. No Inspector navigation is implemented or
  verified for them.
- Nothing here is an acceptance decision, and the tests were run by the
  implementer only.
- The paragraph on the page is unchanged. Correcting it is a separate decision.
