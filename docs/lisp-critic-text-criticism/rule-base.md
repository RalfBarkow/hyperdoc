# The Riesbeck/Beane rule base, as read from source

**No rule was run for this report.** Everything here was read from the engine's
source. Statements about what the engine does on a given input are derived from
that reading; none was observed in a run. Line numbers refer to the files of the
archive identified below.

## Which source

There is no source station in the environment this was written in, and no engine
file in the repository. The engine was read from Zach Beane's archive,
`https://xach.com/lisp/lisp-critic.tar.gz` (16619 octets, SHA-256
`0ea7923082c134480edb7c52aaea9e3209695a3b5c2482d6934a9921533bfde7`), which the
committed recorded evaluations name as the edition they were made with.

| File | SHA-256 in the archive equals the digest in `pages/lisp-critic/evaluations/*.json`? |
|---|---|
| `README`, `lisp-critic.asd`, `tables.lisp`, `write-wrap.lisp`, `lisp-critic.lisp` (`2fe59ca5…`), `lisp-rules.lisp` (`ca19b512…`) | yes, all six |
| `extend-match.lisp` | no as archived (`b0e8ba39…`); yes (`5072e904…`) after the one documented change, `(defconstant var-prefix "?")` → `(defparameter var-prefix "?")` |

So the text read is the text of the recorded engine: content identity with the
recorded digests. It is not the wiki page's source station.

## How a rule is applied

- `define-lisp-pattern` (`lisp-critic.lisp:148`) calls `add-lisp-pattern`
  (`:153–159`), which stores pattern and response under the rule's name; a second
  definition with the same name replaces the first.
- `apply-critique-rule` (`:210`) calls `find-critiques` (`:225–233`). At each
  node it tries the pattern; on a match it returns the findings *for that node*
  and stops. Otherwise it descends into the CAR, and only if that finds nothing,
  into the CDR, joined by `OR`. A `?top-level` pattern is tried at the root only.
- `pat-match` (`extend-match.lisp:131–142`) matches a non-variable atom by
  `(eql pat form)` (`:135`).
- `lisp-rules.lisp` is read in the package `LISP-CRITIC-USER` (`:65`, `:68`), so
  every pattern literal that is not a `COMMON-LISP` symbol is a
  `LISP-CRITIC-USER` symbol.

## Inventory

- `lisp-rules.lisp` has 79 `define-lisp-pattern` forms and defines 78 rules:
  `NTH-FOR-CDR` is defined twice (`:301`, `:305`), and the second replaces the
  first, so `(nth 1 (?))` is not a rule at run time.
- HyperDoc defines no rule. It has exercised three: `CAR-CDR` (live example and
  committed fixture), `SETF-PUSH` and `X-PLUS-1` (committed recorded evaluations
  on two DEFEXAMPLEs).

## Five properties that bound what a run shows

1. **First match only** (`find-critiques`, `:225–233`). One Critique does not mean
   one occurrence; a second `(car (cdr …))` elsewhere in the form is not reported.
2. **Position-blind.** The search descends every cons, quoted data and list
   tails included. A match need not be code that is evaluated where it stands.
   The recorded `X-PLUS-1` case is one; `lisp-critic-recorded.lisp` reports that it
   lies inside a QUOTE, but only for recorded evaluations.
3. **Symbol identity** (`extend-match.lisp:135`). A pattern literal that is a
   `LISP-CRITIC-USER` symbol is never `EQL` to the same-named symbol of the
   package a target was read in. A completed run with no Critique is then no
   evidence that the construct is absent.
4. **Definition-shaped patterns.** `?top-level` and `(defun …)` patterns do not
   match a DEFEXAMPLE as written; `lisp-critic-examples.lisp` says so.
5. **Probable defects in the vendor file** (not changed here): `and` where `?and`
   is meant in `DO-WITH-BODY` (`:266`) and `DOLIST-SETF` (`:316`), which makes
   that branch require a literal `AND`; the literal `lst` in the second
   `NTH-FOR-CDR` (`:305`), which limits it to a variable of that name in
   `LISP-CRITIC-USER`.

## The rules relevant to this study

| Rule (line) | Target it can examine | Trigger | Evidence of a Critique | Explanation and recommendation | False positives | False negatives |
|---|---|---|---|---|---|---|
| `CAR-CDR` (`:297`) | any form | `(car (cdr ?))` anywhere | bindings and matched subform | use `CADR` or `SECOND` | inside quoted data (property 2) | second occurrence (1) |
| `SETF-PUSH` (`:236`) | any form | `(setf ?x (cons ?y ?x))` | the same | use `PUSH` | quoted data (2) | second occurrence (1) |
| `X-PLUS-1` (`:377`) | any form | `(+ ?var 1)` or `(+ 1 ?var)`, `?var` not a number | the same | `1+` for the value or `INCF` to change the place | quoted data — the recorded case (2) | second occurrence (1) |
| `VERBOSE-GENERIC-VAR-NAME` (`:586`) | any symbol | `number`, `input-list`, `output-list`, `data` | the symbol | shorter generic names | none known | all but `CL:NUMBER` in a target read outside `LISP-CRITIC-USER` (3) |
| `QUOTE-FALSE` (`:393`) | any form | `'false` | — | `NIL` | none known | always, outside `LISP-CRITIC-USER` (3) |
| `RETURN-DONE` (`:397`) | any form | `'done` | — | return `T` or `NIL` | none known | always, outside `LISP-CRITIC-USER` (3) |
| `MISSPELLED-OCCURRENCE` (`:330`) | any symbol | six misspellings | — | spelling | none known | always, outside `LISP-CRITIC-USER` (3) |
| `NTH-FOR-CDR` (`:305`; `:301` replaced) | any form | `(nth <non-number> lst)` | — | lists are not arrays | none known | any other variable name (5); `(nth 1 …)` never (inventory) |
| `DO-WITH-BODY` (`:258`), `DOLIST-SETF` (`:310`) | `DO`, `DOLIST` forms | assignment in the body; second branch needs a literal `AND` | — | update in the DO step | none known | `PUSH` accumulation (5) |

## Classification

| Class | Rules or cases |
|---|---|
| A — adequate | `CAR-CDR`, `SETF-PUSH` — each property-1 and property-2 limit is shared by every rule and belongs in the explanation, not in the rule |
| B — inadequate applicability, evidence or explanation | `X-PLUS-1` (2); `VERBOSE-GENERIC-VAR-NAME`, `QUOTE-FALSE`, `RETURN-DONE`, `MISSPELLED-OCCURRENCE`, `NTH-FOR-CDR` (3); `DO-WITH-BODY`, `DOLIST-SETF` (5) |
| C — missing executable rule | none proposed |
| D — judgement needing context the engine does not have | the criticisms in [review-report.md](review-report.md), F1 of PR #43 among them |

No new rule is proposed. A rule made to recognize F1 would recognize a case
already known from the review, which the assignment excludes.

## A deferred diagnostic (specified, not implemented)

For one rule applied to one target, observe the pattern's literals whose home
package is neither `COMMON-LISP` nor `KEYWORD`, whether a symbol `EQ` to one of
them occurs in the target, and same-named symbols of other packages there.

- Absence of an `EQ` symbol is sufficient for the failure of that literal
  sub-pattern. It is sufficient for the failure of the rule only where the literal
  lies on every matching path (list positions, `?and`, `?contains`, `?top-level`,
  `?repeat`). It is never necessary. Under `?or` or `?optional` it removes an
  alternative; under `?not` or `?match` nothing follows.
- Results are per literal `:required`, `:alternative` or `:undetermined`; an
  unknown `?` operator makes the whole result `:undetermined`.
- It belongs in a separate record referenced from the run record, not on the
  rule, the target or a Critique, and should be called a literal-identity
  observation, not "applicability".
- For recorded and reconstituted runs the pattern is text and packages are gone;
  the diagnostic is then unavailable and is never computed from text.
- Its tests need a real engine. A station rebuilt from the digest-verified files
  would satisfy the digest prerequisite of the engine-integration tier, not the
  page-station tier.

## What HyperDoc could take from Fischer's critic

From Fischer 1987 (pp. 177, 181–183): advice depends on a user model that is fed
by the rules that fired, the statistical analyzer and the knowledge structures
visited, and in turn decides which rules fire and which explanations are given;
the user accepts or denies each suggestion; explanation is on demand; KAESTLE
illustrates why a rule is valid. HyperDoc has the Critique, its rule, its
evidence and its explanation as navigable objects. It has no user model, no
response step and no explanation beyond the rule's response string. The smallest
step towards Fischer's design would be a recorded response to one Critique —
accepted, rejected, explanation requested — kept as its own record, as
`docs/lisp-critic-first-critique.md` already asks. That is a proposal, not
implemented.
