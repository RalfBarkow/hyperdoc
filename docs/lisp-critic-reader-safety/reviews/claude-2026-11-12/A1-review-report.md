# Independent review of Codex A1 — Lisp Critic source-reader safety

Reviewer: Claude Code, 12 November 2026. I wrote the original Slice A, so I am
independent of A1 and not of Slice A. This is not an owner acceptance.

- Original Slice A: `1da262deee28c614ab63c2311f5355de2dfaafc5`
- A1 fix: `9228ab022e003de815822bdbb1cf4bbd3ba8aba7`; A1 handover, reviewed:
  `c0b5f8328805ebfaa929f4ff4c2e51052dd39511`. Between the two, no file under
  `dreyeck/` and not `dreyeck.asd` changes (checked with `git diff`).
- Reviewed in two clean detached worktrees at the exact commits. Nothing was
  modified, committed or pushed for this review.

## What I executed myself

Environment: Linux, SBCL 2.4.10, Git 2.43.0; a fresh process per run, no init
files, explicit source registry, empty compilation cache. Probe scripts and logs
are beside this report (`probes.lisp`, `probes2.lisp`, `probes3.lisp`,
`probes-*.log`, `tests-*.log`).

| Run | `1da262d` | `c0b5f83` |
|---|---|---|
| `dreyeck/lisp-critic/text-criticism/tests` | PASS, 80 checks, exit 0 | PASS, 80 checks, exit 0 |
| `#S` constructor in the table | **1 effect**; table refused afterwards | 0 effects; `:reader-refused` |
| definition inside `#| … |#`, no real one | **table returned** from the comment | `(:definitions-found 0)` |
| `#+`/`#-` in the table, two feature sets | **`((:subject :a))` vs `((:subject :b))`** | same refusal under both |
| changed claims source carrying `#S` | parser called, **1 effect** | parser not called (0 calls), 0 effects, `:claims-not-parsed`, `:not-determined` |
| changed page only | parser called | parser not called |
| committed sources | 10 claims, 5/5, three discrepancies, `:verified-revision` | identical |
| `…/text-criticism/integration-tests` | not attempted | **NOT RUN**: `html-inspector-views` not found |

So the three reported failures are real in my original code, and A1 removes all
three and adds the gate. I did not use Codex's `probes.lisp` for this; I read it.

Not reproduced by me: the 9 integration checks, and every suite that needs
HyperDoc, a source station or the Catalog. For those I checked only that each
record in the four `*suites.json` files names a log whose SHA-256 matches the
committed log (all 22 match), and that the logs' last lines agree with the
classification. That is consistency of the record, not execution.

## Findings

### 1. Medium — a character literal followed by `"` or `;` lets a string or a line comment supply the definition

`dreyeck/src/lisp-critic-text-passage.lisp:270`. After `#\x` the scanner keeps
consuming until whitespace or a parenthesis. The Lisp reader ends the token at
any terminating macro character, so `"`, `;`, `'`, `` ` `` and `,` are swallowed
into the character token and the text behind them is scanned as code.

Observed at `c0b5f83` (and refused, `(:definitions-found 0)`, at `1da262d`):

```lisp
#\a; (defun historical-claims () (copy-tree '((:subject :in-line-comment))))
```

returns `((:SUBJECT :IN-LINE-COMMENT))`; the standard reader sees one character
and a comment.

```lisp
#\a" (defun historical-claims () (copy-tree '((:subject :in-string)))) #\b" nil
```

returns `((:SUBJECT :IN-STRING))`; the standard reader sees a character, a
string and `NIL`. With a real definition also present, A1 answers
`(:definitions-found 2)` — a refusal of valid source, the safe direction.

This contradicts the README's sentence "Comments and strings cannot supply
candidate definitions" (line 14) and is not among its probes. No effect occurs
and nothing is evaluated. Exposure today is nil: the committed claims source
contains no character literal, and `criticise-passage` parses only content that
matches the recorded digests. It would matter when a state is recorded whose
claims file contains such a sequence, and for direct callers
(`image-agreement`, `lisp-critic-text-criticism.lisp`, calls the reader without
the gate once the reading system is loaded). Likely remedy: end the character
token at the same delimiters as line 276, after the first character.

### 2. Low — "active" is not established; other definitions are not seen

`:310–312`. Only a syntactically top-level, unqualified `(defun
historical-claims …)` is a candidate. A later `(progn (defun historical-claims
…))`, `(cl:defun historical-claims …)` or `(defun pkg::historical-claims …)` is
ignored, and the first table is returned (observed; same at `1da262d`). The
README says this for nested and quoted forms, but calls the selected definition
"active". What the reader establishes is "exactly one unqualified top-level
definition of that spelling". Not a regression; the wording overstates.

### 3. Low — "no package lookup" is not literally true

`:300` interns keywords, after validation only (observed: a refused table leaves
no new keyword; at `1da262d` it did). The README states the ordering correctly
further down; the contract sentence should say "no package lookup except
interning validated keywords".

### 4. Informational — conservative refusals

The whole file is refused for any `#+`, `#-`, `#(`, radix, `#.`, `#S`, graph
label, `|…|` or backslash symbol anywhere, for nesting beyond 128, and for
`(defun historical-claims nil …)` or a body with a declaration. All observed,
all documented or harmless. Results were identical under `*read-base*` 16, a
case-preserving readtable and `*package*` KEYWORD.

### No finding

Unclosed list, string or block comment, stray `)`, `#` or `'` at end of input:
all refused. Dotted, circular, quoted, backquoted, non-keyword-keyed and
too-deep tables: refused. Mixed case, explicit `(quote …)`, `+5`, non-ASCII
keyword letters and string escapes: accepted with the value the standard reader
would give. No package is left behind.

## Coverage, qualified

| Scope | Standing |
|---|---|
| Parser contract | Reproduced by me, with finding 1 open |
| Judgement-basis resolver integration | Codex: 9 checks PASS on both revisions; **not reproduced by me** |
| Catalog regression | Codex: FAIL on both, at `dreyeck/tests/upstream-intake-smoke.lisp:1404`; later assertions not reached |
| Real Riesbeck/Beane engine | NOT RUN anywhere: no source station |
| Page-attached source station | NOT RUN anywhere: same prerequisite |

The Catalog failure does not block the bounded A1 review. The failing check asks
whether commit `8a1149197fabcb1ab5622316f09c5a60c2d3f1f8` is in the local
object store of the checkout that loaded the Intake system. In my clone that
object is present (`git cat-file -t` → `commit`); in Codex's it was not. The
check concerns `dreyeck/upstream-intake`, no Catalog system depends on the
optional text-criticism systems, and it fails identically on the unchanged
base. It is a repository-history prerequisite to be tracked separately. It also
means there is no Catalog evidence for A1 beyond that assertion, in either
direction.

## SHOP3 handover

The four rules under "Future SHOP3 inputs" are right and I found nothing in the
code that contradicts them:

- Content identity and revision membership stay separate fields
  (`:content`, `:revision-binding`); `:scope` is `:verified-revision` only on a
  `:verified` answer (unchanged from Slice A, exercised by the 80 checks).
- `:not-determined` is a distinct value on every refusing path, including the
  new `:claims-not-parsed`.

What the handover does not yet state, and the next slice needs:

- A fact for `:claims-not-parsed` distinct from `:claims-unreadable` (not
  attempted versus attempted and refused).
- That `planned-*` effects are refused as input, and that no operator may add an
  accepted-judgement or applied-correction fact; both can only come from a
  record made by a named reviewer or executor.
- That a successful table extraction is evidence about the recorded text only,
  and — until finding 1 is closed — only for sources without a character literal
  directly followed by a terminating macro character.

## Conclusions

1. **Does A1 satisfy its bounded source-reader safety contract?** For effects,
   feature independence, reader-state independence, block comments, incomplete
   source and the coherence gate: yes, as far as I could test. For "comments and
   strings cannot supply candidate definitions": no, in the case of finding 1.
2. **Independently reproduced:** the three original failures on `1da262d`; their
   absence on `c0b5f83`; the gate (zero parser calls for changed sources); the
   80 checks on both commits; the committed table (10 claims, 5/5).
3. **Remaining limitations:** finding 1; findings 2 and 3 as wording; the 9
   integration checks not reproduced by a second party; Catalog incomplete;
   real-engine and page-station suites not run; no browser or Nix evidence.
4. **Can A1 be submitted for owner acceptance?** It can be submitted, with
   finding 1 disclosed. I would not describe it as meeting its contract as
   worded until line 270 is corrected and the two inputs above are added to the
   probes, or the contract sentence is narrowed. That choice is the owner's.
5. **Evidence contract for the next SHOP3 slice:** per criticism, positive
   status facts only — content identity (matches / differs, with per-file
   status), revision membership (verified / not-verified / contradicted, with
   reason), passage status, claims status (read / not-parsed / unreadable, with
   reason), and either discrepancy atoms with their scope, or
   `reading-borne-out` with its scope, or `discrepancy-status :not-determined`
   and neither of the other two. Each fact carries the observation it came from.
   Judgement and recommendation enter as "recorded, by whom", never as true or
   applied. Planned effects and absent records produce no fact.
