# W2 trust-screen correction: D1 and D2

Reviewed baseline: `32209c16ce93ddec50e30e820fafa3a6cee54d73`, PR #39.
Date: 2026-11-10. Scope remains planning-domain replay and current validation;
no execution capability, shared SHOP3 change or second planning/domain engine.

## D1: observed failure and correction

The old source-to-domain transition lost the distinction between quoted SHOP3
terms and Lisp expression positions. The recursive name screen allowed `<` as
the function but did not validate its evaluated operands. It also omitted
`:sort-by`. The native engine then evaluated the admitted expressions.

Both independent attacks were reproduced in a detached worktree at the exact
reviewed commit. Tags were created only in an OS-allocated temporary repository.
The retained [baseline log](w2-trust-evidence/reviewed-baseline.log) records:

| Attack | Baseline observation | D1 correction |
|---|---|---|
| D: `(shop3:call < (clear-development-domain-cache) 1)` | Admitted, one private build, two cache-clear calls during native planning, cache 2 → 0, one native plan. | Refused before construction: `:non-plain-call-argument`. |
| E: `(:sort-by (clear-development-domain-cache) ((slice ?s)))` | Admitted, one private build, two cache-clear calls during native planning, cache 2 → 0, one native plan. | Refused before construction: `:sort-by-not-supported`. |

`:PLAN-ONLY` was preserved even in the baseline. This did **not** prevent the
historical Lisp side effect; the unsafe source had already crossed the screen.

The correction routes existing item fields to context checks, without expanding,
converting or executing them. Native SHOP3 remains the only domain constructor
and parser. The supported source subset preserves W1's ordinary methods,
optional branch labels, axioms, SHOP2 operators and integer costs. Predicate,
task and effect terms must be atomic. Unsupported extensions are refused.

Comparison calls are allowed only in logical conditions, with an exact
allowlisted comparison and plain SHOP3 variables or self-evaluating literals
(integer, string, keyword, NIL or T). A variable must be a W1-package variable
under the pinned engine's name rule and have no Lisp binding or special
proclamation. SBCL's non-evaluating variable-kind introspection also rejects an
unbound special with a `?` prefix. Nested operand expressions are refused.

All `:sort-by` source is refused. Task lists remain flat data without CALL or
computed networks. Effects contain flat facts or quantified effects; even the
logical bounds of quantified effects cannot contain CALL. Logical wrappers are
checked recursively. Nested predicate terms are refused so source-supplied
expression lists cannot masquerade as data and later bind a comparison operand.
This is a deliberately restricted source screen, not a general Lisp sandbox.
Current record construction and trusted planner inputs remain separate concerns.

## Evaluation-position audit of the pinned engine

Paths below are under pinned `shop3/shop3/` at `ce53f9b651acde8c44dc21eddb1a1c5b97f10536`.

| Native seam | Evaluated input | W2 boundary |
|---|---|---|
| `theorem-prover/theorem-prover.lisp:176–200` | `:sort-by` key and optional comparison expression | `:sort-by` refused throughout source, including quantified bounds. |
| `theorem-prover/theorem-prover.lisp:545–550` | `standard-satisfiers-for-call` evaluates the complete substituted argument expression | Exact comparison function; plain atomic operands; no nested calls, free symbols or Lisp specials. |
| `theorem-prover/theorem-prover.lisp:378–439,538–591` | `eval`, `assign`, `assign*`, `enforce`, `setof`, `bagof`, `:external` | Existing blanket refusals retained, including under logical wrappers. |
| `io/input.lisp:381–415`; `decls.lisp:204–220`; `planning-engine/task-reductions.lisp:335,348` | A CALL in a task network selects `simple-backquote`; its expressions are evaluated on reduction | Only flat task lists with atomic arguments; CALL and computed/quoted network extensions refused. |
| `planning-engine/task-reductions.lisp:214–246` | Quantified effect bounds invoke `find-satisfiers` | Recursively checked logical bounds with CALL disabled; flat effect facts and recursively checked quantified consequents only. |
| `io/input.lisp:506–538`; `planning-engine/task-reductions.lisp:156` | Operator cost expression | Sixth field must be an integer; fifth must be an effect list, ruling out SHOP1 cost-slot ambiguity. |
| `io/input.lisp:945–974`; native logical satisfiers | Axiom bodies and nested logical conditions | Same recursive logical-context checks as method/operator preconditions; flat ordinary predicate terms. |
| `io/input.lisp:831–860` | `:include` loads external source | Existing item-kind/include refusals retained. |

The W1 domain has no implication or arbitrary task-network extensions; local
symbols spelling such logical names do not gain native executable semantics.
No trust-screen check invokes `eval`, a historical form, a recovery restart or a
record-supplied function. Only already screened items reach native construction.

## Executed focused probes

[Probe source](../../../dreyeck/tests/welcome-domain-trust.lisp) retains the D/E
labels. Twenty tagged negatives pass in [d1-focused.log](w2-trust-evidence/d1-focused.log).
Every negative asserts zero `make-domain` calls, zero cache-clear calls, unchanged
cache entry EQ identities, public object/plist/dynamic domain, and problem
registry/current-problem pointer.

| Required path | Probe label | Result |
|---|---|---|
| Nested executable CALL operand | D | Refused; no construction or mutation. |
| Lisp special-variable operand | SPECIAL-VARIABLE | Refused; no construction or mutation. |
| `:sort-by` key expression | E | Refused; no construction or mutation. |
| `:sort-by` comparison expression | SORT-COMPARISON | Refused; no construction or mutation. |
| CALL in method task list | METHOD-TASK, METHOD-TASK-FLAT-CALL | Refused even when the comparison itself has only literal operands. |

Other cases cover a special with a SHOP3-looking name, an unbound special,
a keyword with a variable-looking name, nested CALL, free symbol, NOT/OR/FORALL
wrappers, nested predicate terms, direct/quantified effects, sorting in effect
bounds, operator preconditions and axiom bodies. The exact source from W1 commit
`61cdec068116891d8455cdff9bb7b81ef1df171a` is read locally, copied into the temporary
tag fixture, admitted, and produces both expected P0 S1 assignments with native
plan trees/final states and `:PLAN-ONLY`.

## Reproduction

Using the already prepared dependency registry and SBCL 2.4.10:

```sh
git worktree add --detach /workspace/work/w2-trust-baseline \
  32209c16ce93ddec50e30e820fafa3a6cee54d73
DEFEDERATION_REPO=/workspace/work/w2-trust-baseline \
/workspace/scratch/tmdm-mcp-portable/bin/sbcl \
  --noinform --no-sysinit --no-userinit --non-interactive \
  --load /workspace/work/defederation-bootstrap.lisp \
  --eval '(asdf:load-system "dreyeck/work/welcome-development/domain-version-tests")' \
  --load /workspace/work/welcome-w2/dreyeck/tests/welcome-domain-trust.lisp \
  --eval '(dreyeck/work/welcome-development::run-domain-trust-probes t)'
```

Corrected focused command:

```sh
DEFEDERATION_REPO=/workspace/work/welcome-w2 \
/workspace/scratch/tmdm-mcp-portable/bin/sbcl \
  --noinform --no-sysinit --no-userinit --non-interactive \
  --load /workspace/work/defederation-bootstrap.lisp \
  --eval '(asdf:load-system "dreyeck/work/welcome-development/domain-version-tests")' \
  --eval '(dreyeck/work/welcome-development::run-domain-trust-probes)'
```

The fixture strings and native item expectations are separately retained; no
host reader is used on historical text to create attack tags. OS `mktemp`
allocates a fresh repository, and `unwind-protect` removes it. Native admission
recomputes each baseline/positive version ID after actual SHOP3 expansion.
