# Prepared Draft PR: Add read-only TMDM relationship readers and retained qualification evidence

Repository: `RalfBarkow/topic-maps`.
Base: `dreyeck.ch` at `88994c1b9e1edbf13e665e984a5c9c3b2cdf7575`.
Head: published branch `claude/tmdm-core-relationship-readers` at `c446a8228017f405c3a2650ca893e9450ac7cd7b`.
Creation is left to the operator: connector and CLI PR writes were refused by GitHub's integration permissions.

## Prepared description

This proposes the independently completed readers at c446a8228017f405c3a2650ca893e9450ac7cd7b against dreyeck.ch at 88994c1b9e1edbf13e665e984a5c9c3b2cdf7575.

Six public TMDM 7.2/7.3 readers recognize stored Associations and return native players or source Associations. They do not create items, infer relationships or interpret Scope. The adapter document remains a design proposal; no HyperDoc or SHOP3 dependency is introduced.

Retained evidence: reports/core-relationship-readers/README.md, before/after logs, exit codes and SHA-256 manifests. Recorded runs report 50 relationship checks, 21 default-name checks and the independent eleven-baseline count comparison. All 25 existing report hashes are unchanged. Known corpus FAILs remain; XTM suites were NOT-RUN. These are retained execution results, not new runs performed while opening this PR.

Cross-review verified source structure, read-only canonical traversal and the explicit evidence limits. HyperDoc integration and replacement runtime snapshot qualification are separate work. No merge or deployment is authorized.
