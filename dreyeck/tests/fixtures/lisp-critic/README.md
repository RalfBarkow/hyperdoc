# Lisp Critic fixtures and test tiers

`car-cdr-run-snapshot.json` is a **recorded run of the real engine** on `(car (cdr items))`:
rule `CAR-CDR`, pattern `(CAR (CDR (?)))`, recommendation "Use CADR (or CADDR or ...) or SECOND ...".
It was produced by running the 2004 Riesbeck/Beane Lisp Critic
(`https://xach.com/lisp/lisp-critic.tar.gz`, with the one local change `defconstant` → `defparameter`
for `var-prefix`) under SBCL 2.4.10, and serialising the run with `critic-run-snapshot-string`.
Nothing in it was typed in by hand. The integration tier below re-runs the engine and checks that the
committed record is still what the engine says.

## Tiers

| Tier | System | Needs the station? | Fails or skips without it |
|---|---|---|---|
| Regular (part of `dreyeck/catalog`) | `dreyeck/lisp-critic/reading`, `dreyeck/lisp-critic/recorded/tests` | No | Not applicable. It reads recorded critiques, shows an absent engine as absent, and proves page-bound code is not loaded when the policy refuses. |
| Engine integration (strict) | `dreyeck/lisp-critic/engine-integration/tests` | **Yes** | **Fails**, with `ENGINE-INTEGRATION-REQUIRES-A-SOURCE-STATION`. Never skips. |
| Page-station layout | `dreyeck/lisp-critic/page-station/tests` | Yes, the wiki page's own station | Fails. |

## Running the integration tiers

A station is a directory holding `a-critic-for-lisp.asd` and `vendor/lisp-critic/` (the engine files
`lisp-critic.asd`, `tables.lisp`, `write-wrap.lisp`, `extend-match.lisp`, `lisp-critic.lisp`, `lisp-rules.lisp`).
It is the asset directory of the wiki page `a-critic-for-lisp`. Point the test at it:

```bash
DREYECK_LISP_CRITIC_ROOT=/path/to/station/ \
  sbcl --eval '(asdf:test-system "dreyeck/lisp-critic/engine-integration/tests")'
```

An explicit `DREYECK_LISP_CRITIC_ROOT` is exclusive: if it is wrong, nothing else is tried.
`(dreyeck/lisp-critic/engine-integration/tests:run-negative-controls)` shows in fresh images that the strict test
fails with no station, with an empty one, and with an engine that runs and says nothing.
