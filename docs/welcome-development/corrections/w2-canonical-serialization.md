# W2 R1: content-stable canonical string serialization

Reviewed baseline: `9c850a19e660c148ea33c23c48e79f481743fea5`, PR #39.
Date: 2026-11-10. N1 remains fixed; no domain, source screen, record-value
contract, identity scheme, binding format v2 or planner behavior is changed.

## Reproduction and approved P0 digest update

In a detached worktree at the reviewed commit, actual SBCL 2.4.10 produced these
results for EQUAL string contents:

| Storage | Reviewed canonical text | SHA256 |
|---|---|---|
| `simple-base-string` | `#A((4) COMMON-LISP:BASE-CHAR . "same")` | `e349ac574df2ca93152e4233a9bbf0536661a62c853858f260694f242c1d7cad` |
| Character string | `"same"` | `106c4202d3d02a3ff34000f19889ac489e6a40f2ee68ea9e3984633ab059dd4d` |

`with-standard-io-syntax` makes printing readable and independent of caller
settings, but it does not erase array element types. SBCL's readable printer
preserves the base-string representation with `#A`. The old serializer therefore
encoded storage details rather than EQUAL value contents. Nested strings and
canonical strings embedded in v2 inputs are affected too.

The baseline probe copies every string in record IDs and record data to
CHARACTER arrays, creates new record objects, and asserts that the structured
journal data is EQUAL. In this prepared runtime P1, P4, P11 and `:complete` all
refused the normalized copy with `:assignment-plan-binding-mismatch` (at A1 or
the corresponding first complete-scenario assignment). The independent review
reported later failures for P11/complete; this probe normalizes the entire
record ID/data graph and observes the same underlying defect earlier.

[reviewed-baseline.log](w2-canonical-evidence/reviewed-baseline.log) also establishes
an incompatibility between two requested acceptance constraints, without any
correction loaded:

- Original P0 inputs: digest
  `1ebd24a84517314b1087526c13e27518f08f85e0b7e9e67f9185a3e7db3adc61`.
- An **EQUAL copy of those exact inputs containing only character strings**:
  digest `ba9bbb10531faffdc221f1580360382bec2d39ec2fa6a64b83eb9a771ad48ba5`.

The user explicitly chose character-content normalization and approved the full
second digest as the new P0 expectation. The first digest is retained as
historical evidence, not a compatibility requirement. This preserves existing
character-string-only digests and removes representation sensitivity. No hash
alias, P0-specific exception, identity-scheme change or silent pin substitution
is made. The new pin is independently checked against both native binding
construction and the reviewed printer applied to EQUAL all-character inputs.

## Implementation

`development-canonical-string` now copies each permitted cons/string tree into
temporary literal data. Every string becomes a fresh array with element type
CHARACTER before printing. Symbols and integers retain their values. The printed
result is copied to a CHARACTER string too, so `fixture-record-key` inherits a
representation-independent output type through the shared serializer.

No input cons, string, record, planning state or retained Inspector object is
mutated. This is storage normalization only: no Unicode normalization, case
folding, parsing of strings, macro expansion or evaluation occurs. Unsupported
values and uninterned symbols retain their original refusal reasons.

The printer remains under the same `with-standard-io-syntax` / KEYWORD package
contract. SHA256 still hashes its UTF-8 text. Domain-version identity and the
v2 binding schema are unchanged; the domain ID remains exactly
`f342bb4ad3455fac873a56d9a7d817ff35e7ace253527ef7db1068e3759ad315`.

Old digests calculated from representation-sensitive mixed/base-string data
cannot all remain valid while collapsing their EQUAL representations. Already
character-string-only canonical bytes/digests are preserved, including nested
actual plan inputs and Unicode examples. Previously noncanonical mixed-data
bindings may need regeneration from their accepted records. No replay record or
binding digest is automatically rewritten by this correction.

## Executed focused checks

[Probe source](../../../dreyeck/tests/welcome-canonical-replay.lisp) is included in
the optional domain-version test system. [focused.log](w2-canonical-evidence/focused.log)
records:

- EQUAL simple-base, character, adjustable/fill-pointer and displaced strings
  produce identical canonical text and digest; serializer output is CHARACTER.
- Nested strings in lists/dotted pairs and actual v2 plan inputs satisfy the
  same invariant.
- Already-character-only inputs have identical bytes and SHA256 to the reviewed
  printer oracle, including Unicode and escaped quotes/backslashes.
- Caller package, print case/base/escape/readability/circle/pretty settings and
  print length/level do not affect canonical text or digest.
- Nested unsupported objects and uninterned symbols still refuse.
- P1, P4, P11 and `:complete` replay before/after the persistence-style conversion,
  with EQUAL state/plans, respectively 1/2/3/1 alternatives and `:PLAN-ONLY`.
- Assignment references resolve by EQ to their corresponding records in each
  journal. Original IDs/data retain their original EQ identity and contents;
  Inspector and Topicmap link to the exact supplied record objects on both sides.
- The domain identity is unchanged; P0 equals the approved full new pin and
  independently agrees with the reviewed character-only oracle.
- A retained v2 assignment carrying the historical P0 digest visibly refuses
  with `:assignment-plan-binding-mismatch`. Its binding object, digest and
  contents remain unchanged after refusal: there is no accepted legacy alias or
  automatic rewrite.

The identity runner now prints `R1-IDENTITY` alongside `W2-IDENTITY`; the audit
script compares both outputs across two fresh SBCL processes. That checks both
composite-key text and its digests, with base/character input variants.

## Commands

Baseline, with the existing prepared dependency registry:

```sh
git worktree add --detach /workspace/work/w2-r1-baseline \
  9c850a19e660c148ea33c23c48e79f481743fea5
DEFEDERATION_REPO=/workspace/work/w2-r1-baseline \
/workspace/scratch/tmdm-mcp-portable/bin/sbcl \
  --noinform --no-sysinit --no-userinit --non-interactive \
  --load /workspace/work/defederation-bootstrap.lisp \
  --eval '(asdf:load-system "dreyeck/work/welcome-development/domain-version-tests")' \
  --load /workspace/work/welcome-w2/dreyeck/tests/welcome-canonical-replay.lisp \
  --eval '(dreyeck/work/welcome-development::run-canonical-replay-baseline)'
```

Corrected focused checks:

```sh
DEFEDERATION_REPO=/workspace/work/welcome-w2 \
/workspace/scratch/tmdm-mcp-portable/bin/sbcl \
  --noinform --no-sysinit --no-userinit --non-interactive \
  --load /workspace/work/defederation-bootstrap.lisp \
  --eval '(asdf:load-system "dreyeck/work/welcome-development/domain-version-tests")' \
  --eval '(dreyeck/work/welcome-development::run-canonical-replay-tests)'
```

Complete regression and syscall audit:

```sh
DEFEDERATION_REPO=/workspace/work/welcome-w2 \
W2_SBCL=/workspace/scratch/tmdm-mcp-portable/bin/sbcl \
W2_BOOTSTRAP=/workspace/work/defederation-bootstrap.lisp \
W2_LOGS=/workspace/work/w2-r1-final-evidence \
scripts/audit-welcome-domain-versions.sh
```

This retains the existing empty-child-HOME/private-FASL-cache setup and pinned
SHOP3 4.3.1, Eclector 0.11.0 and SBCL 2.4.10 runtime. No dependency acquisition,
project tag creation, merge, deployment, S1 acquisition or agent execution.

## Full run results

The complete audit exited **0**, with the approved full P0 pin and visible
legacy-binding refusal enabled. It compares both content-stable P0 results and
composite fixture keys across fresh processes. All current acceptance criteria
pass; the old representation-dependent digest remains historical evidence.

| Executed check | Result / evidence |
|---|---|
| R1 strings / nested plan inputs / legacy character-only bytes | PASS in acceptance.log and focused.log. |
| P1/P4/P11/complete persistence-style round-trip | PASS, with 1/2/3/1 native alternatives, EQUAL values/state/plans and EQ record/reference links. |
| Domain ID | Exact `f342bb4a…` preserved. |
| P0 digest | Exact approved `ba9bbb10531faffdc221f1580360382bec2d39ec2fa6a64b83eb9a771ad48ba5`, checked against an independent character-only oracle and across fresh processes. |
| Historical stored digest | `1ebd24a8…` refuses visibly; the retained binding is not rewritten and no substituted digest is accepted. |
| Composite keys | Both processes print identical `R1-IDENTITY` text/digests and assert CHARACTER output. |
| A1–A13 / D1/D2 / N1 | PASS in acceptance.log; all trust/value/lifecycle assertions remain active. |
| P0–P11 / completion / F1–F5 / C1–C3 | PASS in regressions.log; all original scenario behavior and refusal checks retained. |
| Inspector / Topicmap / lifecycle / L1 | PASS, including original object EQ links and 100 complete runs + 20 journal builds with unchanged problem registry/current pointer. |
| Defederation / Local-only | Both unchanged regression suites PASS. |
| Syscalls and tags | Fixture: zero Git/network calls. Replay: only cat-file/rev-parse/show and zero network calls. Socket positive control detected. Temporary and project tag snapshots unchanged. |

[All raw logs/traces and checksum manifest](w2-canonical-evidence/) are retained.
Network namespace creation remains unavailable on this host: strace observes
zero network calls rather than enforcing network isolation. Temporary tag
fixtures are deleted by the audit; no project tag is created. Only disposable
SBCL images were used; no live SLY image or production system was modified.

Changed source paths are `welcome-development.lisp` (the shared serializer),
`welcome-development-examples.lisp` (return-contract docstring only), optional
ASDF/test registration, new `welcome-canonical-replay.lisp`, and the existing
identity/audit runners. Documentation and evidence accompany the patch. No
source acquisition, merge, deployment, project tags, S1 acquisition or agent
execution is included. Stop for independent Claude Code re-review of draft PR #39.
