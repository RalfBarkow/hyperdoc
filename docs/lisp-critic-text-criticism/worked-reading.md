# Worked reading: one engine Critique, one reviewer judgement

Draft page text for the Lisp Critic book. It is **not registered** in the book:
registering it means listing it in `dreyeck.asd` and adding its expressions to
the reading's tests, which is a separate change. The page text at the end follows
the conventions of "Reading a Recorded Critique".

The reading follows one chain end to end — Source → Critic Target → Rule →
Evaluation Record → Critique → Evidence → Explanation — and then puts a second
chain beside it that looks similar and is not: a criticism no rule produced.

## The engine chain: SETF-PUSH on READING-PLAN

All of it comes from the committed record
`dreyeck/pages/lisp-critic/evaluations/setf-push-reading-plan.json` (SHA-256
`c6bc5ecd4d1218e8ed5bb9849dd224ba3b6888364b2dd804b991a36a2a488b6f`). It is a
**recorded** run of the real engine, made on 29 September 2026 (UTC) in a
trusted development runtime; reading it runs nothing. The live objects are
rebuilt from it by `read-example-evaluation`
(`dreyeck/src/lisp-critic-recorded.lisp:288`).

| Step | Object | What it is here | Who made it |
|---|---|---|---|
| Source | the code page `workflow-reading.lisp` of the book `dreyeck/workflow/reading` | form `(:EXAMPLE READING-PLAN)`, characters 326–1049, source SHA-256 `ae53416a…` | the page's author |
| Critic Target | `example-critic-target` (`lisp-critic-examples.lisp:42`) | the DEFEXAMPLE's form as written, never evaluated; it keeps the source occurrence | `critic-target-for-example`, from the source |
| Rule | `critic-rule` (`lisp-critic-critique.lisp:10`) | `SETF-PUSH`, pattern `(SETF (? X) (CONS (? Y) (? X)))`, response `Instead of (SETF ~S (CONS ...)), use PUSH.`, from `vendor/lisp-critic/lisp-rules.lisp` (20474 bytes; `:236` of the archive) | Riesbeck, in the engine |
| Evaluation Record | `critic-rule-run-record` (`:21`) | status `COMPLETED`, invocation `lisp-critic:apply-critique-rule`, notes `STRUCTURED-ENGINE-FINDINGS`, `TARGET-NOT-EVALUATED`; label `critic-rule-run-366`, meaningful only in the image that made it | `run-critic-rule`, a run of the engine |
| Critique | `critique` (`:26`) | one finding of that run, naming its rule, target and record | the engine's match, kept as an object |
| Evidence | the critique's evidence and the record's match | bindings `X = (CDDDR FORM)`, `Y = "Read-only example …"`; matched subform at path `(2 3)` of the example. Whether a QUOTE encloses it is computed when the record is read (`%quoted-along-p`); the existing page presents it as code | the engine (bindings); the recording and reading code (path, quotation) |
| Explanation | the critique's explanation | `Instead of (SETF (CDDDR …::FORM) (CONS ...)), use PUSH.` | the engine's response template, instantiated |
| Provenance | the record's engine block | Beane's 2004 archive, file digests, recording context | the recording code |

What this chain does **not** contain: no human or model judgement that the
recommendation is right for this example, no response to the Critique, no change
to the example, no acceptance. "A recommendation worth taking" on the existing
page is that page's author's judgement about the Critique, not part of it.

## The second chain: the paragraph on what was read

From the text-criticism records on this branch
(`dreyeck/src/lisp-critic-text-criticism.lisp`). No rule ran.

| Step | Object | What it is here | Who made it |
|---|---|---|---|
| Source | two files at `596344ae`: the page "The Fischer Critic as an Environment" and `lisp-critic-reading.lisp` | recorded by path, SHA-256 and Git blob id | their authors |
| Target | the paragraph, characters 4160–4629; the claim table of `historical-claims` | named by strings, not by an object of the Critic | — |
| Observation | `recorded-observations`, and `observe-now` again | the paragraph stands once; ten claims cite a primary paper, five record a primary paper as read | a probe, run by Claude Code |
| Reading | `passage-reading` | the three things the paragraph is taken to assert; `:interpreted` | Claude Code |
| Derived discrepancy | `passage-discrepancies` | the assertions the table does not bear out | a named comparison, from the two above |
| Judgement | `judgement` | the paragraph and the records disagree; which is wrong is open; basis resolved by `resolve-judgement-basis` | Claude Code |
| Recommendation | `recommendation` | replacement text; `:applied-p nil` | Claude Code |

There is no **Rule**, no **Evaluation Record** and no **Critique** in this chain.
Its nearest equivalent to a rule is the comparison, which is code, but which
decides only that two texts disagree. Its explanation is the judgement's
statement, written by a model, not a rule's response.

## Which objects are which

| | Engine chain | Second chain |
|---|---|---|
| Produced by running a Critic rule | Evaluation Record, Critique, Evidence (bindings), Explanation | — |
| Observed by a probe | the example's source occurrence, re-observed when the page opens | both files and the paragraph |
| Derived by code | the match path and whether it is quoted | the discrepancies |
| Authored by a person or model | "worth taking" on the page | the reading, the judgement, the recommendation |
| Decided by an authority | nothing | nothing |

## Draft page text

```html
<h1>Two Criticisms, Side by Side</h1>

<in-package>dreyeck/lisp-critic/recorded</in-package>

<p>
Two criticisms of material in this repository. The first is a Critique: a run of
the 2004 Riesbeck/Beane engine found it. The second looks similar and is not one:
no rule ran, and a model wrote the judgement. Reading them side by side shows
which parts of a criticism come from where.
</p>

<pre>
Source            the text being criticised
Target            what the criticism is about
Rule              only in the first: the engine's SETF-PUSH
Evaluation Record only in the first: the run, whether or not it found anything
Critique          only in the first: one finding of that run
Evidence          bindings and match | observations and a derived comparison
Explanation       the rule's response | a judgement, with its author
</pre>

<h2>A Critique</h2>

<p>
<code>READING-PLAN</code> adds a documentation string with
<code>(setf (cdddr form) (cons "…" (cdddr form)))</code>. The engine's rule
<code>SETF-PUSH</code> matched it in a recorded run. Everything under the link
was produced by that run or by the code that recorded it.
</p>

<p>
  <a expr="(setf-push-recorded-example)" view="Recorded evaluation">
    Open the recorded SETF-PUSH evaluation
  </a>
</p>

<p>
Nothing in it says whether the recommendation is right for this example. That is
a judgement, and it is not part of the Critique.
</p>

<h2>A judgement about a page</h2>

<p>
A paragraph of <a page="The Fischer Critic as an Environment">The Fischer Critic
as an Environment</a> says that no Fischer paper has been read here. The claim
records the page is about say that five claims rest on primary papers read here.
Two files at one commit were observed, a reading of the paragraph was compared
with the records, and Claude Code judged that the two disagree. It did not judge
which one is wrong.
</p>

<p>
  <a expr="(dreyeck/lisp-critic/text-criticism:observe-now)">
    Observe the two sources again
  </a>
  ·
  <a expr="(dreyeck/lisp-critic/text-criticism:judgement)">
    The judgement and its basis
  </a>
</p>

<p>
No rule ran for this, so there is no Evaluation Record and no Critique. The
recommendation that comes with it has not been applied.
</p>
```

The second pair of links needs `dreyeck/lisp-critic/text-criticism` loaded with
the reading system; that dependency does not exist yet.
