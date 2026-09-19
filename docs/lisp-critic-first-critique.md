# From an execution record to a Critique

## Observed starting point

This slice started on `dreyeck.ch`, `ac8ac805`, with a clean worktree.
`df774aaf` (State Machine extraction), `c87e7e40` (Lisp Critic extraction), and
`af5c4d31` (SLY mREPL recording) are ancestors of that state. The extraction
is not pending work. `2525b28a` already introduced the Evaluation Record
projection protocol; later adapters include workspace operations and SLY.

`dreyeck/lisp-critic` owns source stations, invocation contracts and run
records. `run-lisp-critic-contract` loads a local wrapper and calls the real
`critique-file` entrypoint, capturing raw output and failures. Its existing
contract deliberately does not normalize findings.
`dreyeck/evaluation-record/lisp-critic` already projects those run records
onto the generic Evaluation Record protocol. That protocol consists of
generic functions, not a common superclass. SLY recording remains unrelated
to the domain assertion that a program deserves a critique.

The missing relation was between an actual structured engine finding and its
rule, observed program form and execution record. A printed warning cannot
supply these object identities.

## One real rule, no new rule language

Load `dreyeck/lisp-critic/critique` for the model and runner. The optional
`dreyeck/inspector/lisp-critic` adds navigable views.

The runner calls the existing Riesbeck/Beane engine's
`apply-critique-rule`, using its existing `CAR-CDR` rule on `(car (cdr items))`.
It does not evaluate the target form, reproduce the matcher, parse printed
warnings or register new rules.

* `critic-rule` snapshots the loaded rule's name, pattern, response template
  and source location. This is domain knowledge, not an invocation contract.
* `critic-rule-run-record` extends the existing `lisp-critic-run-record` for
  this form-based invocation. It retains status, timing, invocation and
  failure evidence. Its Evaluation Record input is the target object and its
  result is the list of Critiques. Existing file-run projections are unchanged.
* `critique` is a separate domain finding. It links the rule, target and run
  record and preserves the engine's structured match as evidence. Its
  explanation/recommendation is instantiated from the engine response.
* `critic-target` retains the program form and its run records, providing the
  initial navigation point. Runs do not rewrite it.

The rule's recommendation is to use `CADR` or `SECOND` instead of the nested
`CAR`/`CDR`. It is not an automatically applied remedy or a user response.
A completed execution can have zero findings. A failed execution has a
condition and no Critique. Thus Evaluation Record and Critique remain distinct.

## Persistent sources and dependency

The external engine is the historical local `a-critic-for-lisp` source
station, not a test double. Pass its directory to `car-cdr-critique-example`,
set `DREYECK_LISP_CRITIC_ROOT`, or use the historical default
`~/.wiki/wiki.ralfbarkow.ch/assets/pages/a-critic-for-lisp/`.
The station must contain the wrapper ASDF system and its vendored
Riesbeck/Beane `lisp-critic` sources. No download or source migration is performed.
The actual rule pathname is retained in `rule-source-of`.

Definitions and the target example are reconstructed from committed source;
the run graph is created anew, not serialized as a historical evaluation.
The real-engine test fails if the local station is unavailable. A fresh
checkout alone does not install that external prerequisite.

## Reproduce and inspect

```lisp
(asdf:load-system "dreyeck/inspector/lisp-critic")
(asdf:load-system "clog-moldable-inspector")
(clog-moldable-inspector:clog-inspect
 :object (dreyeck/lisp-critic:car-cdr-critique-example))
```

The `Critic relations` views expose direct object links from target to run,
run to rule, rule to Critique, and Critique to target, run, evidence and
explanation. No server is started by the example itself.

```sh
nix develop path:. -c sbcl --no-userinit --non-interactive \
  --eval '(require :asdf)' \
  --eval '(asdf:test-system "dreyeck/lisp-critic/critique/tests")'
```

This runs the contract in the loaded parent image and again in a new SBCL
process with no user initialization. It checks the real match, non-match,
unknown-rule failure, Evaluation Record projection, and rendered Inspector
object-reference identities. It does not claim a test in an existing browser
or SLY session.

The immediate remaining question is how an explicit human response to this
particular Critique should be represented without conflating it with either
the explanation or the execution record.
