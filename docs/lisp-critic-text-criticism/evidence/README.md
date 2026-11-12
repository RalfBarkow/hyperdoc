# Test evidence for the text-criticism slice

Recorded on 12 November 2026 by the implementer (Claude Code). Every run below
is the implementer's own. None is an independent acceptance, and none was run
in a complete HyperDoc environment.

## Environment

- Base revision: `596344ae95d746f436705808462259371f5a593c` (`dreyeck.ch`).
- Linux, SBCL 2.4.10, ASDF as shipped with it, Git 2.43.0.
- A fresh SBCL process per run, no user or system init file, an explicit source
  registry (this checkout and the `sbcl-*` packages of the local Nix store), and
  an empty compilation cache outside the repository. See
  [run-tests.sh](run-tests.sh).
- Not resolvable in this environment: `html-inspector-views`,
  `clog-moldable-inspector`, `plump-inspector-views`, `lwcells`, `njson/jzon`,
  `iolib`, `threads`. The project's Git layer needs Git 2.44 or later.
- No source station of the Lisp Critic engine. No engine was loaded.

## Executed

| System | Outcome | Raw output | SHA-256 of the raw output |
|---|---|---|---|
| `dreyeck/lisp-critic/text-criticism/tests` | **PASS**, 80 checks, exit 0 | [text-criticism-tests.log](text-criticism-tests.log) | `3e052d9bdc1b27de4a52ed89d3c2128d5b7b75bcdd203e76401d51b12ca3780b` |
| `dreyeck/lisp-critic/tests` (existing, unchanged) | exit 0 | not retained | — |

In the passing run the two source files had the recorded content, and Git named
the recorded blobs in the recorded commit (`revision membership verified`).

## NOT RUN

Each of these was started and stopped before any test executed, because a
dependency could not be found. They are not failures of the tests and not
passes.

| System | Why it did not run |
|---|---|
| `dreyeck/lisp-critic/text-criticism/integration-tests` | `Component #:HTML-INSPECTOR-VIEWS not found` ([log](integration-tests-NOT-RUN.log), SHA-256 `9432555c5a264c0ef7be14b0cf79394239824301104dad989ee70aacdd2963c2`) |
| `dreyeck/lisp-critic/federated-context/tests` | `html-inspector-views` not found |
| `dreyeck/lisp-critic/reading/tests` | `html-inspector-views` not found |
| `dreyeck/lisp-critic/recorded/tests` | `html-inspector-views` not found |
| `dreyeck/lisp-critic/critique/tests` | `html-inspector-views` not found |
| `dreyeck/lisp-critic/engine-integration/tests`, `…/page-station/tests` | not attempted: they need the reading system and a source station |
| `dreyeck/catalog/tests` | not attempted |

So, in particular, **the judgement-basis resolver of the federated context was
not exercised through its own system here**, and the comparison of the loaded
claim table with the source text was not made.

## A supplementary check, and what it is not

[resolver-standalone.lisp](resolver-standalone.lisp) reads the one committed
definition of `resolve-judgement-basis` from
`dreyeck/src/lisp-critic-federated-context.lisp` (file SHA-256
`eb6797fa1c07b6355bc1448c3a4592a08ec9bc62babbae45f7a5aaede4dbff9d`), evaluates
that definition on its own in a scratch package, and applies it to the new
records: the basis resolves to the two recorded observations, and is refused
for an unrecorded observation, another state, an unobserved target and an empty
list of observations. 5 checks, exit 0
([log](resolver-standalone.log), SHA-256
`5d7f6ddb1bc3a02b91ffa263a5bfdff16d5caa822b37a7e04779cc5b53fd7f5f`).

This shows that the committed function text accepts and refuses these records.
It is not a load of `dreyeck/lisp-critic/federated-context`, it does not
replace the integration tests, and it is not part of any test system.

## To be run elsewhere, by someone other than the implementer

In an environment that loads HyperDoc, at this branch's commit:

```bash
sbcl --non-interactive --eval '(asdf:test-system "dreyeck/lisp-critic/text-criticism")'
```

```bash
sbcl --non-interactive --eval '(asdf:test-system "dreyeck/lisp-critic/text-criticism/integration-tests")'
```

```bash
sbcl --non-interactive --eval '(asdf:test-system "dreyeck/lisp-critic/federated-context/tests")'
```

```bash
sbcl --non-interactive --eval '(asdf:test-system "dreyeck/lisp-critic/reading/tests")'
```

The first must print `TEXT-CRITICISM-PASS: 80 checks`; the second
`TEXT-CRITICISM-INTEGRATION-PASS`. The last two are regressions: the slice adds
optional systems and changes no existing file except `dreyeck.asd`, to which it
only adds three system definitions.
