# Source-backed criticism of a text page

> **The claim-table reader on this branch has known contract violations.** See
> "Reading without running" below before relying on it. The corrected reader is
> Codex's A1, on `codex/lisp-critic-reader-safety`; it is not merged here.

Branch `claude/lisp-critic-text-criticism`, based on `dreyeck.ch` at
`596344ae95d746f436705808462259371f5a593c`. An optional slice: it adds three
ASDF systems and changes no existing source file, page, test or dependency pin.

| Document | Content |
|---|---|
| this file | what the slice is, its behavioural contract, what it is not |
| [review-report.md](review-report.md) | the criticisms of the reviewed pages and code, each with its origin |
| [rule-base.md](rule-base.md) | the Riesbeck/Beane rule base as read from source, its limits, a deferred diagnostic |
| [worked-reading.md](worked-reading.md) | one engine Critique and one reviewer judgement read side by side, as draft page text |
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
`read-claim-table`, as committed here (`1da262deee28c614ab63c2311f5355de2dfaafc5`),
finds the one line that begins `(defun historical-claims`, and reads one form from
there with the standard readtable, `*read-eval*` false and a package made for the
purpose. It accepts only `(defun historical-claims () [docstring] (copy-tree
(quote table)))` with a table of property lists with keyword keys and literal
values.

That contract was claimed too broadly. Codex found three violations, and the
independent review of the correction reproduced all three at `1da262d`
(`docs/lisp-critic-reader-safety/reviews/claude-2026-11-12/` on
`claude/lisp-critic-a1-review`):

- `#S(…)` in the table runs a structure constructor while reading, before the
  table is refused;
- a definition inside `#| … |#` is found by the line search and read;
- `#+`/`#-` select different tables under different `*features*`.

`*read-eval*` false does not stop `#S`, `#+` or `#-`, and a line search does not
know comments. So the reader here is not safe on untrusted text. The one
committed source it is meant for contains none of these constructs, but
`criticise-passage` on this branch reads the table even when that source's
digest does not match the recorded one.

Codex's A1 (`9228ab022e003de815822bdbb1cf4bbd3ba8aba7`, handover
`c0b5f8328805ebfaa929f4ff4c2e51052dd39511`) replaces the Lisp reader with an inert
structural scanner and parses the claims only after the coherence gate. The
review found it removes all three violations, and left one finding open: a
character literal directly followed by `"` or `;` lets a string or a comment
supply the definition. Whether A1 is merged is the owner's decision.

`dreyeck/src/upstream-assessment.lisp` already reads source text as inert tokens
("No package is consulted"). It was not considered when this reader was written;
it should be when the reader is next changed.

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
  not with the `html-inspector-views` parser, whose Eclector client does not
  override read-time evaluation. Both choices are superseded by A1 (above).

## What this slice is not

- No rule of the Riesbeck engine was added or run. No `critique` object, no
  Evaluation Record, no Inspector view and no SHOP3 domain was created.
- The records are plain lists. No Inspector navigation is implemented or
  verified for them.
- Nothing here is an acceptance decision, and the tests were run by the
  implementer only.
- The paragraph on the page is unchanged. Correcting it is a separate decision.
