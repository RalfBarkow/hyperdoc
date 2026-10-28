Commit: 88994c1b9e1edbf13e665e984a5c9c3b2cdf7575
Tree: b0835676837d6a53457a87880d64046035140bb7
Parent: 6162ed68c94ea4796b8cf2282edd347d9607b08c
Author: rgb <ralf.barkow@me.com> 2026-10-28T16:42:36+01:00
Committer: rgb <ralf.barkow@me.com> 2026-10-28T16:42:36+01:00
Subject: perf(tmdm): index association normalization merge candidates

perf(tmdm): index association normalization merge candidates

Replace the quadratic cross-Association scan in normalize-associations with
an indexed search for the next merge candidate. Pair selection order and
merge semantics are unchanged relative to 6162ed68.

Adds tests/association-index.lisp with 29 fixtures. Independently reviewed.

Not verified: Linux execution, the Stage 2 CTM, peak RSS and suitability
for the constrained NixOS host, high-arity performance, and the historical
Python Unicode/NFC checker mismatch (pre-existing, Python 3.14 / Unicode 16).

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>


 .../scope-collapses-after-theme-merge.cxtm         |   34 +
 .../association-index/scoped-duplicates.cxtm       |   69 +
 tests/fixtures/association-index/type-differs.cxtm |   38 +
 topic-maps.asd                                     |    8 +
 33 files changed, 3229 insertions(+), 1 deletion(-)

Primary checkout: codex/project-work-slice-22u at 88994c1b9e1edbf13e665e984a5c9c3b2cdf7575, status lines:        0
