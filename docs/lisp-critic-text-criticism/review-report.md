# Review report: selected Lisp Critic pages and code

> **DRAFT — work-in-progress checkpoint, 12 November 2026.** Not reviewed, not accepted.
>
> - Complete as far as it goes: T1–T8. Not yet written: a severity summary, and the
>   review of "Inspecting One Acceptance Evidence Chain" against the eight criteria
>   (only referred to at the end).
> - Source references still to be checked against a second reading: the section
>   and page numbers of the Fischer 1987 quotations (taken from OCR text of the
>   IJCAI PDF, without page numbers); Fischer & Mastaglio 1991 was not read.
> - T1 cites a probe of the slice whose claim-table reader is the subject of a
>   reported contract violation (see the banner of `README.md`). The observation
>   in T1 was also made by reading the source; it must be reconsidered together
>   with that report.

Reviewer: Claude Code, 12 November 2026. Read-only review, except for the slice
described in [README.md](README.md).

**Origin of every finding below.** None was produced by the Riesbeck engine: no
rule was run for this review, and no finding is a `critique`. Each finding is
marked **S** (observed by reading source at the named revision), **P**
(observed by an executed probe, run by the reviewer), **J** (the reviewer's
judgement about such observations), or **R** (reported to the reviewer by
someone else and not seen). A recommendation is a proposal; none was applied.

Revisions: HyperDoc `596344ae95d746f436705808462259371f5a593c` (`dreyeck.ch`),
at which every Critic source, test and page is byte-identical to PR #43's head
`53928946c650ff2e49441a7c047730c189760999`. Engine source: Zach Beane's archive
of 2004-05-06, whose files have the SHA-256 digests the committed recorded
evaluations name (see [rule-base.md](rule-base.md)). Fischer 1987 was read as
the IJCAI proceedings PDF (see [terminology-and-sources.md](terminology-and-sources.md)).

Criteria, as given in the assignment: (1) source observation kept apart from
interpretation; (2) grounds given for technical claims; (3) execution record,
Critique and acceptance kept apart; (4) identity and provenance of inspected
sources preserved; (5) no unsupported claim about historical software; (6) rule
applicability and limits explained; (7) useful at several levels of expertise;
(8) concrete improvements.

## T1 — A paragraph contradicts the records it summarizes

- **Target:** `dreyeck/pages/lisp-critic/The Fischer Critic as an Environment.html`,
  lines 112–120 (characters 4160–4629).
- **Criteria:** 1, 2.
- **Evidence:** the paragraph says no Fischer paper has been read and all but
  one Fischer claim report `:NONE-OBSERVED` (**S**). Lines 6–9 of the same page
  say the claims "now come from the primary papers". `historical-claims`
  (`dreyeck/src/lisp-critic-reading.lisp`, from line 344) holds ten claims
  citing a primary paper, five with `:observed-evidence-kind :primary-paper`
  (**S**, and **P**: `observe-now` of the slice, 80-check run).
- **Finding (J):** the paragraph and the records disagree. Significance:
  medium — the page's subject is exactly the difference between cited and
  observed evidence, and this paragraph states it wrongly for the current
  records.
- **Which side is wrong** is not settled by the disagreement. Two further
  observations bear on it: the two claims located in the 1987 paper agree with
  that paper as I read it (abstract; acknowledgements) (**S**); whether the
  paper was read *in the workspace the records come from* cannot be observed
  from here.
- **Recommendation:** do not restate counts in prose; point at the records.
  Proposed text is in `recommendation` of the slice. Not applied.

## T2 — "Not a pipeline" goes further than the 1987 paper allows

- **Target:** same page, lines 12–20: "Fischer does not write that ordering
  down, in either direction", and the conclusion that a user model "cannot be
  something the explanation eventually feeds".
- **Criterion:** 5.
- **Evidence (S):** Fischer 1987, section 4, on the system's structure: "The
  user model … obtains information from the rules that have fired, from the
  statistical analyzer and from the knowledge structures that have been
  visited. In return, it determines which rules should fire and what kind of
  explanations should be generated."
- **Finding (J):** the paper does state a direction — both directions. The
  model is fed, among other things, by what the user visits in the explanation
  component, and in return steers rules and explanations. The page is right
  that the system is not a one-way pipeline, and wrong that the paper is silent
  and that explanation cannot feed the model. Significance: medium; it is a
  claim about a historical system that the cited source contradicts in its
  body, while the page argued from the abstract.
- **Recommendation:** describe the relation as the loop the paper states, and
  add the statistical analyzer, which the page's diagram omits.

## T3 — The response step is documented already in 1987

- **Target:** `dreyeck/pages/lisp-critic/Anatomy of a Critique.html`, lines
  105–111, and the claim with subject `:lisp-critic-zmacs` in
  `historical-claims`, which cites Fischer & Mastaglio 1991 and reports
  `:none-observed`.
- **Criterion:** 5.
- **Evidence (S):** Fischer 1987, section 4: "the user can inspect the
  modifications and accept or deny them. On demand, the system explains and
  justifies its suggestions."
- **Finding (J):** accepting or denying a suggestion and asking for an
  explanation are documented for the 1987 system. The page's statement is not
  wrong, but the record places the capability only in a later version and marks
  it unobserved. Significance: low. Fischer & Mastaglio 1991 was not read for
  this review.
- **Recommendation:** add a claim located in the 1987 paper, or widen the
  existing one, once someone has read the passage in the project's own copy.

## T4 — An unconditional sentence over a conditional example

- **Target:** `Anatomy of a Critique.html`, lines 5–9: "Every part below is a
  real object produced by a real run of the Riesbeck engine".
- **Criteria:** 3, 6.
- **Evidence (S):** `critique-anatomy-example`
  (`lisp-critic-reading.lisp:1885`) returns the rule, Critique, evidence and
  explanation as NIL, with the failure, when no run completes — which is the
  case wherever the source station is absent or page-attached code may not run.
- **Finding (J):** the code distinguishes the two cases; the prose does not.
  Where the engine cannot run, the page asserts objects that do not exist.
  Significance: low to medium.
- **Recommendation:** say "where the engine can run"; point to the recorded
  Critiques for the other case.

## T5 — "Riesbeck's engine prints findings"

- **Target:** `Reading the Lisp Critic Genealogy.html`, lines 78–84.
- **Criteria:** 1, 5.
- **Evidence (S):** the engine exports `apply-critique-rule`, which returns a
  list of findings, each a list of rule name, bindings and matched code
  (`lisp-critic.lisp`, `defstruct (critique (:type list) …)`); `run-critic-rule`
  consumes exactly these (`lisp-critic-critique.lisp:95–106`).
- **Finding (J):** the engine both returns structured findings and prints.
  What HyperDoc adds is the run record that exists without a finding, object
  identity and relations — not the structure of a finding. Significance: low.
- **Recommendation:** "returns findings as lists and prints them".

## T6 — A subject wider than its locator

- **Target:** `historical-claims`, subject `:riesbeck-engine`
  (`lisp-critic-reading.lisp:499–502`): "The engine carries a dated update
  history running from 1997 to 2003", locator `lisp-critic.lisp`.
- **Criterion:** 5.
- **Evidence (S):** true of `lisp-critic.lisp` (10/2/97 to 1/3/03). The rule
  file `lisp-rules.lisp` of the same engine has an entry "2/3/04 removed ENDP
  recommendation [CKR]".
- **Finding (J):** correct for the file cited, too wide for "the engine".
  Significance: low.
- **Recommendation:** name the file in the assertion, or add the rule file's
  range.

## T7 — Code: what a live Critique does not say about itself

- **Target:** `dreyeck/src/lisp-critic-critique.lisp` and
  `lisp-critic-critique-views.lisp`.
- **Criteria:** 4, 6.
- **Evidence (S):**
  1. `run-critic-rule` (69–120) does not test for the station before loading;
     an absent station gives `:failed` with a load condition, where
     `run-lisp-critic-contract` gives `:asset-missing`.
  2. `critique-view` shows "Match evidence" without where in the target the
     match stands or whether a QUOTE encloses it. That exists only for recorded
     evaluations (`%path-to`, `%quoted-along-p` in `lisp-critic-recorded.lisp`).
  3. The six policy slots of `lisp-critic-contract` are read by no code under
     `dreyeck/`; only `source-station` has an effect.
- **Finding (J):** (1) two words for one situation; (2) a live Critique cannot
  show the property that made the recorded `X-PLUS-1` case a false positive;
  (3) the class describes an invocation, it does not enforce one — it is not a
  contract in Meyer's sense. Significance: low each; (2) matters most to a
  reader.
- **Recommendation:** none applied. (2) is a candidate for a later slice.

## T8 — PR #43, finding F1: what kind of thing it is

- **Target:** `dreyeck/work/acceptance-evidence-chain.lisp` at `53928946`,
  `read-git-blob`.
- **Criteria:** 3, 6.
- **What exists, by kind:**

  | Kind | Content | Standing |
  |---|---|---|
  | Source observation (**S**) | only `git-command-failed` is turned into a typed refusal; the text is decoded by `uiop:run-program … :output :string` | read at `53928946` |
  | Diagnostic observation (**P**) | in SBCL 2.4.10 that decoding signals `STREAM-DECODING-ERROR` on invalid UTF-8 | my own experiment, on other code than the PR's |
  | Diagnostic observation (**R**) | Codex's probes on the PR's code in temporary repositories: the condition escapes unwrapped | reported to me; no log seen |
  | Reviewer judgement (**J**) | the implementation does not keep its documented promise that a lossy round-trip is refused | mine; independent of the implementer |
  | Proposed remedy | catch the condition in `read-git-blob`, refuse with `:invalid-utf-8` | Codex's proposal; not implemented at the reviewed head |
  | Engine Critique | none | no rule of the engine concerns this |
  | Acceptance assessment | none | F1 is not a failed historical test and not a decision |

- **Recommendation:** keep F1 in this form. Recording it as records of the kind
  this slice uses would need a target that is a blob at a revision rather than
  two working-tree files; the source-state part of the slice already identifies
  such a target.

## Pages and code reviewed without a finding worth recording

`dreyeck/src/lisp-critic-examples.lisp` and `lisp-critic-snapshot.lisp` keep
their stated distinctions (occurrence, execution, evaluation, critique; record,
snapshot, presentation) and say what they do not do. "Reading a Recorded
Critique" and "Lisp Critic on the Federated Context" were read as models for
the slice. "Inspecting One Acceptance Evidence Chain" was reviewed with PR #43
earlier; its findings are in that review and are not repeated here.
