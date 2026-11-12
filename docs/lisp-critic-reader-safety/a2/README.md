# A2: character-literal token boundaries

Base: `c0b5f8328805ebfaa929f4ff4c2e51052dd39511`. Implementer: Codex.
These results are implementation evidence, not independent or owner acceptance.

## Correction

Common Lisp character syntax (CLHS 2.4.8.1, Sharpsign Backslash, and 2.1.4,
Character Syntax Types) escapes the first character following `#\`. Subsequent
terminating macro characters terminate the token. The inert extractor now
honours `(`, `)`, `;`, `"`, `'`, backquote and comma at that boundary:

- `#\a;` leaves the semicolon to begin a line comment.
- `#\a"` leaves the quote to begin a string.
- `#\;` consumes the semicolon as the literal character itself.
- `#\"` consumes the double quote as the literal character itself.

Whitespace also terminates subsequent token scanning. The extractor accepts
single characters and the explicit names Space, Newline, Tab, Return, Page,
Rubout and Backspace (case insensitive). Other character names and escaped
multi-character spellings are deliberately refused, rather than resolved
through environment-dependent character naming. Characters remain unsupported
as claim-table values. No standard reader is invoked by the extractor.

"Active definition" means only a recognized direct top-level definition in
the supported grammar. It does not establish execution or which definition
would supersede another at runtime. Keywords are interned after complete
literal validation; extraction is not a claim of zero interning on success.

## Counterexample provenance and outstanding input

The exact two complete examples from Claude's independent A1 review were not
available in the accessible review files or GitHub PR search. They have been
requested from the owner. `probes.lisp` retains explicitly **reconstructed**
complete examples of both reported failure modes; these must not be represented
as the verbatim review script. Running the verbatim examples remains **NOT RUN**
until they are supplied. This is an outstanding acceptance requirement.

The reconstruction sources are printed in `baseline.log`: A1 accepts a direct
apparent definition after an incorrectly swallowed comment delimiter, and
another inside a string whose delimiters are swallowed. Both yield refusal
`:definitions-found 0` on A2. Additional probes cover literal punctuation,
named characters, adjacent comments/strings, incomplete and unsupported syntax,
refusal of character table values and the authentic committed Fischer source.

## Reproduction

Use the existing host-specific A1 bootstrap and verified portable launcher:

```sh
export DEFEDERATION_REPO="$PWD"
git show c0b5f8328805ebfaa929f4ff4c2e51052dd39511:dreyeck/src/lisp-critic-text-passage.lisp > /tmp/a2-original-passage.lisp
A2_BASELINE_SOURCE=/tmp/a2-original-passage.lisp docs/lisp-critic-reader-safety/portable-sbcl --noinform --no-userinit --non-interactive --load docs/lisp-critic-reader-safety/a2/probes.lisp

docs/lisp-critic-reader-safety/portable-sbcl --noinform --no-userinit --non-interactive --load docs/lisp-critic-reader-safety/a2/probes.lisp --load docs/lisp-critic-reader-safety/probes.lisp --eval '(asdf:test-system "dreyeck/lisp-critic/text-criticism")'

A1_SBCL="$PWD/docs/lisp-critic-reader-safety/portable-sbcl" A1_LOG_PREFIX=a2/ python docs/lisp-critic-reader-safety/run-suites.py
```

Baseline reconstruction: exit 0, two expected original failures reproduced.
Corrected run: exit 0, 37 A2 checks, A1 safety probes and 80 source-reader checks.
The initial probe harness had a missing parenthesis and did not execute its
checks; both startup-error logs are retained as `initial-*-harness-error.log`.
No successful test is inferred from those attempts. Existing A1 evidence is
retained unchanged, apart from the explicit terminology clarification in its
README. Regression qualification follows in `suites.json` and the handover.

## Final regression qualification

All runs used isolated SBCL processes and the existing A1 portable launcher.

| Check | Outcome |
|---|---|
| Reconstructed counterexamples against fixed A1 | PASS: both incorrect acceptances reproduced |
| Corrected reader | PASS: 37 A2 checks, existing A1 probes and 80 source-reader checks |
| Trusted character-boundary comparison with standard SBCL reader | PASS: four cases, exit 0 |
| Text-criticism integration | PASS: nine checks, exit 0 |
| Base Lisp Critic, Federated Context, Recorded, Reading | PASS: exit 0 for each |
| Critique, Engine Integration, Page Station | BLOCKED: each exits 1 at its real-engine/source-station prerequisite |
| Catalog | FAIL: exit 1 at `CHECK-PAGE-LOADING-REPOSITORY-CONTEXT`, "Local upstream object is absent." |
| Verbatim Claude review examples | NOT RUN: exact source text requested but not supplied |

The source-station and Catalog outcomes match the retained, paired A1 baseline
findings in the parent directory. Those earlier runs are historical evidence,
not newly executed A2 baseline regression suites. The current terminal
conditions and stack frames were inspected; classification is not inferred
from arbitrary log substrings. The three engine scenarios beyond their missing
prerequisite and the Catalog assertions after its failure were not executed.
No real engine, history dependency or substitute station was acquired.

`character-oracle.lisp` uses READ only on four fixed trusted character tokens,
with `*read-eval*` false. It is a test oracle, not an extractor fallback. Run it
with the same launcher and `--load docs/lisp-critic-reader-safety/a2/character-oracle.lisp`.
The production source, logs and test scripts are hashed in `manifest.json`.
Initial harness syntax errors are retained separately and are not test passes.

Independent review must supply and execute Claude's two exact examples, confirm
that the token boundaries match supported Common Lisp syntax, and review the
unsupported-name refusals. The original A1 history and Claude's branch are
unchanged. This handover does not declare completion of the missing mandatory
review-example check or owner acceptance.
