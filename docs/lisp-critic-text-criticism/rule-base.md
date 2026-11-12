# The Riesbeck/Beane rule base, as read from source

> **DRAFT — work-in-progress checkpoint, 12 November 2026.** Not reviewed.
>
> Complete: identification of the engine source, the inventory count, the engine
> properties and the deferred diagnostic. Outstanding: the per-rule table
> (target type, trigger, evidence, false positives and negatives) for the rules
> named below, and line references into the engine files. **No rule was run for
> this document.** Everything here was read from source; statements about what
> the engine does on a given input are derived from that reading and were not
> observed in a run.

## Which source

There is no source station in the environment this was written in, and no
engine file in the repository. The engine was read from Zach Beane's archive,
`https://xach.com/lisp/lisp-critic.tar.gz` (16619 octets, SHA-256
`0ea7923082c134480edb7c52aaea9e3209695a3b5c2482d6934a9921533bfde7`), which the
committed recorded evaluations name as the edition they were made with.

| File | SHA-256 in the archive equals the digest in `pages/lisp-critic/evaluations/*.json`? |
|---|---|
| `README`, `lisp-critic.asd`, `tables.lisp`, `write-wrap.lisp`, `lisp-critic.lisp`, `lisp-rules.lisp` | yes, all six |
| `extend-match.lisp` | no as archived; yes (`5072e904…`) after the one documented change, `(defconstant var-prefix "?")` → `(defparameter var-prefix "?")` |

So the text read is the text of the recorded engine. That is content identity
with the recorded digests; it is not the wiki page's source station.

## Inventory

- `lisp-rules.lisp` has 79 `define-lisp-pattern` forms and defines 78 rules:
  `NTH-FOR-CDR` is defined twice, and `add-lisp-pattern` stores the second
  pattern and response under the same name, so `(nth 1 (?))` is not a rule at
  run time.
- HyperDoc defines no rule. It has exercised three: `CAR-CDR` (live example and
  committed fixture), `SETF-PUSH` and `X-PLUS-1` (committed recorded
  evaluations on two DEFEXAMPLEs).

## Properties of the engine that bound what a run shows

1. **First match only.** `find-critiques` returns the findings for the first
   matching subform, searching a form before its elements and the CAR before
   the CDR, joined by `OR`. One Critique does not mean one occurrence.
2. **Position-blind.** The search descends every cons, quoted data and list
   tails included. A match need not be code that is evaluated where it stands.
   The recorded `X-PLUS-1` case is one; `lisp-critic-recorded.lisp` reports it
   as inside a QUOTE, but only for recorded evaluations.
3. **Symbol identity.** `pat-match` matches a non-variable atom by `EQL`. A
   pattern literal that is not a `COMMON-LISP` symbol was read in
   `LISP-CRITIC-USER`, and cannot match the same-named symbol of another
   package. Patterns with such literals: `VERBOSE-GENERIC-VAR-NAME`
   (`input-list`, `output-list`, `data`; `number` is `CL:NUMBER`),
   `QUOTE-FALSE` (`false`), `RETURN-DONE` (`done`), `MISSPELLED-OCCURRENCE`
   (six spellings), `NTH-FOR-CDR` (`lst`).
4. **Definition-shaped patterns.** `?TOP-LEVEL` and `(defun …)` patterns do not
   match a DEFEXAMPLE as written; `lisp-critic-examples.lisp` says so.
5. **Probable defects in the vendor file** (not to be changed here): `and`
   where `?and` is meant, in `DO-WITH-BODY` and `DOLIST-SETF`; the literal `lst`
   in `NTH-FOR-CDR`.

## Classification

| Class | Rules or cases |
|---|---|
| A — adequate | `CAR-CDR`, `SETF-PUSH` |
| B — inadequate applicability, evidence or explanation | `X-PLUS-1` (property 2); the five rules of property 3; `NTH-FOR-CDR`, `DO-WITH-BODY`, `DOLIST-SETF` (property 5) |
| C — missing executable rule | none proposed |
| D — judgement needing context the engine does not have | the criticisms in [review-report.md](review-report.md), F1 of PR #43 among them |

## A deferred diagnostic (specified, not implemented)

For one rule applied to one target, observe the pattern's literals whose home
package is neither `COMMON-LISP` nor `KEYWORD`, whether a symbol `EQ` to one of
them occurs in the target, and same-named symbols of other packages there.

- Absence of an `EQ` symbol is sufficient for the failure of that literal
  sub-pattern. It is sufficient for the failure of the rule only where the
  literal lies on every matching path (list positions, `?and`, `?contains`,
  `?top-level`, `?repeat`). It is never necessary. Under `?or` or `?optional` it
  removes an alternative; under `?not` or `?match` nothing follows.
- Results are per literal `:required`, `:alternative` or `:undetermined`; an
  unknown `?` operator makes the whole result `:undetermined`.
- It belongs in a separate record referenced from the run record, not on the
  rule, the target or a Critique, and should be called a literal-identity
  observation, not "applicability".
- For recorded and reconstituted runs the pattern is text and packages are gone;
  the diagnostic is then unavailable and is never computed from text.
