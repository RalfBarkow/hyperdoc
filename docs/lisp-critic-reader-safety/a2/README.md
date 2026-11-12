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
