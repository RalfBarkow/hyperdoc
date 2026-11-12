# Lisp Critic A1: inert claims-source extraction

Base: `1da262deee28c614ab63c2311f5355de2dfaafc5`. This is implementation
verification by Codex, not independent acceptance. No rule, judgement, source
station policy, vendor code or SHOP3 domain is changed.

## Contract

`read-claim-table` returns `(values table nil)` or `(values nil reason)`.
The extractor uses no Common Lisp READ, evaluation, compilation, feature
selection, package lookup or structure constructor. It scans the complete
source before selecting exactly one active top-level, unqualified
`(defun historical-claims () [docstring] (copy-tree 'table))` definition.
Explicit `(quote table)` is also accepted. Comments and strings cannot supply
candidate definitions. Quoted and nested forms cannot supply them either.
Malformed or incomplete source anywhere is refused.

The structural envelope supports balanced lists, whitespace, line comments,
nested block comments, strings with backslash escapes and unescaped token
spellings. Quote, backquote and comma prefixes consume their following form;
only quote is accepted in the candidate definition. `#'`, `#:` and character
literals are inert envelope representations required by ordinary surrounding
source; they are not accepted as table values. No dispatch reader is called.
All other dispatch syntax, including `#S`, `#.`, `#+`, `#-`, vectors, radix
numbers and graph labels, is refused. Escaped symbol spellings are refused.
Package-qualified tokens outside the candidate are inert strings; within the
table they are refused. The envelope is not a validator of arbitrary Common
Lisp programs and makes no claim about execution of the surrounding code.

Table rows are even-length property lists with keyword keys. Values are strings,
keywords with letter/digit/hyphen/underscore/asterisk names, decimal integers,
T, NIL, or proper lists of these. Dotted lists, symbols naming code and computed
tables are refused. Structural nesting is bounded at 128; literal nesting is
bounded at 10 from the table root. Keywords are interned only after the whole
candidate has passed structural and literal validation. Failed extraction does
not create packages or intern source symbols.

`criticise-passage` gates claims parsing on source coherence. A changed or
contradicted source yields `:claims-not-parsed` and discrepancy
`:not-determined`; unavailable text remains `:claims-unreadable`. Existing
source-file statuses retain the detailed reason. `observe-now` delegates to
this boundary. No incompatible observations are compared.

## Executed evidence

`baseline.log` reproduces constructor effects, the changed-source constructor
effect, a block-comment false definition and feature-dependent tables using
the original committed reader. The original 80 checks pass there.
`corrected.log` records zero constructor effects, early source-state gating,
comment refusal and identical conditional refusals under two feature sets.
It also records the 80 checks passing with explicit grammar expectations
updated (no permissive `#.` outside the definition; graph syntax is refused
before a Lisp object exists). Source identity/revision tests are retained.

The probes also cover nested comments, strings, quoted definitions, incomplete
source, unsupported syntax, multiple candidates, source-file/package preservation
and a parser tripwire proving that changed sources never reach parsing.
The authentic committed Fischer source still yields ten primary-paper claims,
five primary-paper observations and five none-observed observations.

Run from this checkout, with the host-specific prepared dependency registry
in `bootstrap.lisp` available:

```sh
export DEFEDERATION_REPO="$PWD"
SBCL=/workspace/scratch/tmdm-mcp-portable/bin/sbcl
git show 1da262deee28c614ab63c2311f5355de2dfaafc5:dreyeck/src/lisp-critic-text-passage.lisp > /tmp/a1-original-passage.lisp
A1_BASELINE_SOURCE=/tmp/a1-original-passage.lisp "$SBCL" --noinform --no-sysinit --no-userinit --non-interactive --load docs/lisp-critic-reader-safety/bootstrap.lisp --load docs/lisp-critic-reader-safety/probes.lisp --eval '(dreyeck/lisp-critic/text-criticism/tests:run-tests)'
"$SBCL" --noinform --no-sysinit --no-userinit --non-interactive --load docs/lisp-critic-reader-safety/bootstrap.lisp --load docs/lisp-critic-reader-safety/probes.lisp --eval '(dreyeck/lisp-critic/text-criticism/tests:run-tests)'
```

For the exact original 80-check baseline, use the original test file as well:
the preserved baseline run preceded changes to its grammar expectations.
The baseline mode deliberately invokes a harmless constructor counter in a
new process; it must not be loaded into a running service.

## Future SHOP3 inputs

- Coherent source state requires matching recorded octet identities; a
  verified-revision fact additionally requires verified Git membership.
- Established discrepancy requires coherent sources, an unambiguous observed
  passage, successfully extracted observations, and the existing comparison.
- Missing, changed, contradicted or refused evidence supports an undetermined
  or unavailable-evidence fact with its reason and provenance.
- Such a gap can justify requesting a further investigation, not a claim that
  a discrepancy is absent. `:not-determined` must never project as false.

Parsing success alone creates no criticism. Observation, derived discrepancy,
reviewer judgement, recommendation, engine Critique and planning remain distinct.
