# Independent review of A1 — report and reproduction evidence

A review-only record. This branch adds this directory to the reviewed commit
and changes nothing else: no source, test, system definition or existing
evidence file of A1 is modified.

- Reviewed: `c0b5f8328805ebfaa929f4ff4c2e51052dd39511`
  (`codex/lisp-critic-reader-safety`), the A1 handover. The A1 fix is
  `9228ab022e003de815822bdbb1cf4bbd3ba8aba7`; no file under `dreyeck/` and not
  `dreyeck.asd` differs between the two.
- Compared with: `1da262deee28c614ab63c2311f5355de2dfaafc5`, the original
  Slice A.
- Reviewer: Claude Code, 12 November 2026. The reviewer wrote the original
  Slice A and is therefore independent of A1, not of Slice A.
- **This is not an owner acceptance**, and it accepts no correction. Finding 1
  of the report is open.

The report is [A1-review-report.md](A1-review-report.md), as delivered
(SHA-256 `23f52b8c7b8668f0486a1d6a66765d287c5bbd6dadc1f91fcb98482d18fb70e6`).

## Open finding

**A character literal directly followed by `"` or `;` lets a string or a line
comment supply the definition** (`dreyeck/src/lisp-critic-text-passage.lisp:270`
at the reviewed commit). The two inputs and their observed results are in the
report and in `probes2-a1.log` (`char-then-string-2`, `char-then-line-comment`).
It contradicts the sentence "Comments and strings cannot supply candidate
definitions" of the A1 README. Nothing in this branch corrects it.

## Environment

Linux, SBCL 2.4.10, Git 2.43.0. Each run: a fresh SBCL process, no user or
system init file, an explicit source registry (the checkout under test and the
`sbcl-*` packages of a local Nix store), a compilation cache outside the
repository. Two clean detached worktrees, one per commit. The command is in
[run-probes.sh](run-probes.sh), with the reviewer's paths given as variables;
the raw logs still show the reviewer's own paths.

Not available in this environment: `html-inspector-views` and the other systems
HyperDoc needs, Git 2.44 or later, and any source station of the Lisp Critic
engine.

## Files

| File | What it is | SHA-256 |
|---|---|---|
| `probes-prelude.lisp` | definitions shared by the probe scripts | `92634307551e638e331a8298c9e8a09866b4191537933c807efc4c0d8fe996d4` |
| `probes.lisp` | first batch: the three reported failures, the gate, the committed sources, grammar edges | `fb5e19dfc0c568ee5c9b17cef034534d9d31728a1a281f768c77c75060a8a840` |
| `probes2.lisp` | second batch: character-literal boundaries | `6ccaba8c3ab66af579c4a3aa96be5c30fe5c5ae6f7213cd86b7249ad76280cd9` |
| `probes3.lisp` | third batch: two character-literal cases built without source escapes | `32d893a79fa130aa5b6cb6827dc6aeb38ec2a37694b9650fb5b7e4a123c49223` |
| `probes-base.log`, `probes-a1.log` | raw output of the first batch at `1da262d` and `c0b5f83`; 62 `PROBE` lines each | `4a2398492d4f904fe139ae968ae4a115b689e9632bdf48d8a273ea9a96860d60`, `c0f8aa82cf95820a5bcb1acfa7134667688d2c3683e68de634088f095b0bd8b8` |
| `probes2-base.log`, `probes2-a1.log` | raw output of the second batch; 16 `PROBE` lines each | `3892c49c134e8bf708d2b3497a331cd22b448f65c495fb99b5dd855ab88d54c2`, `2abea5e3cc8a710271e864c82b65d3657a9cefde233c2d8bfc38d8d727956f98` |
| `probes3-a1.log` | raw output of the third batch at `c0b5f83` | `73cfa0de3b0b3c917f774786bb9e3ee44f2878efe250ed15c9099b32f112a8fe` |
| `tests-base.log`, `tests-a1.log` | `dreyeck/lisp-critic/text-criticism/tests` at each commit | `acac13ec3856437b94d425cad83a392b9388a5e192e8c16482724ed65a488520`, `21e424481a8b0d6aa5891241f8d1dde03b500d02a43d206b2d17b5a4e6bfaf43` |
| `integration-a1.log` | the attempt at the integration tests at `c0b5f83` | `9432555c5a264c0ef7be14b0cf79394239824301104dad989ee70aacdd2963c2` |

The two first-batch logs are long because each run compiled its dependencies
into an empty cache; the results are the lines beginning `===`, `PROBE`, `GATE`,
`COMMITTED`, `INTERN`, `PACKAGES` and `TOTAL`:

```bash
grep -E '^(===|PROBE|GATE|COMMITTED|INTERN|PACKAGES|TOTAL)' probes-a1.log
```

## Results

| Run | `1da262d` | `c0b5f83` |
|---|---|---|
| `dreyeck/lisp-critic/text-criticism/tests` | PASS, 80 checks, exit 0 | PASS, 80 checks, exit 0 |
| `#S` constructor in the table | 1 effect | 0 effects, refused |
| definition inside a block comment | table returned | `(:definitions-found 0)` |
| `#+` / `#-` in the table under two feature sets | two different tables | the same refusal |
| changed claims source carrying `#S` | parser called, 1 effect | parser not called, `:claims-not-parsed`, `:not-determined` |
| committed sources | 10 claims, 5 and 5, three discrepancies, `:verified-revision` | the same |
| character literal, then `"` or `;` | `(:definitions-found 0)` | **table returned** from the string, and from the comment |
| `dreyeck/lisp-critic/text-criticism/integration-tests` | not attempted | **NOT RUN**: `Component #:HTML-INSPECTOR-VIEWS not found` |

## Limits of this evidence

- Every run here is the reviewer's, in one environment. The 9 integration
  checks, the federated-context, reading, recorded and critique suites, the
  Catalog, and the real-engine and page-station suites were **not run** by the
  reviewer. For those the reviewer checked only that each of the 22 records in
  A1's four `*suites.json` files names a log whose SHA-256 matches the committed
  log, and read the logs' final lines.
- Three probe lines are not evidence of what their names suggest, because the
  input was not what was intended:
  - `char-literal #;` in the second batch: the literal reached the reader as
    `#;`, which is not valid Lisp. The semicolon character literal is tested
    correctly by `char-literal-semicolon` in the third batch.
  - `char-literals-outside` in the first batch: the same mistake, for the same
    reason.
  - `char;hides-real-definition` in the second batch: the input is a reader
    error for the standard reader as well.
- `char-then-string` in the first batch is refused at `c0b5f83` because of how
  that input was built (a backslash inside what the scanner takes for a
  string). The input that shows the finding is `char-then-string-2`.
- `probes3-a1.log` was written by running the third script again after the
  report was finished; the first run's output had only been displayed. Its two
  `PROBE` lines are the ones the report relies on.
- The ground-truth column (`cl-reader=`) is the standard reader's view of the
  same text at top level, with `*read-eval*` false, used only for inputs without
  `#.` and `#S`.
- No browser, Nix build, running image or production service was involved.

## To reproduce

At a clean checkout of each commit, with the variables of `run-probes.sh` set:

```bash
./run-probes.sh '(asdf:test-system "dreyeck/lisp-critic/text-criticism")'
```

```bash
./run-probes.sh '(asdf:load-system "dreyeck/lisp-critic/text-criticism") (load "/path/to/this/directory/probes.lisp")'
```

```bash
./run-probes.sh '(asdf:load-system "dreyeck/lisp-critic/text-criticism") (load "/path/to/this/directory/probes2.lisp")'
```

`probes2.lisp` and `probes3.lisp` load `probes-prelude.lisp` from their own
directory. The probes define a structure whose constructor increments a counter
in the probing process; they should be run only in a fresh process, never in a
running service.
