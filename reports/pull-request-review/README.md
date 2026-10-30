# Focused local Reading evidence

Baseline: `573fe37611a61d984260ebf43c797f7534211bdd`.

- `lisp-checks.log`: 141 checks, fresh SBCL 2.4.10, exit 0; actual HTML Inspector
  views/references and native Topicmap workspace navigation were exercised.
- `capture-checks.log`: six Python unittest cases, exit 0; API failures,
  pagination and head/state races use mocked responses and never contact GitHub.
- `source-identities.json`: exact source/data hashes, observed PR heads,
  observation UTC and unchanged reused framework/policy/pin files.
- `runtime-sources.txt`: the actual ASDF dependency versions/source roots used.

Commands and the reader-safe local SLY entrypoint are in
`docs/pull-request-review.md`. The validation environment used cached declared
Nix dependencies with explicit ASDF registry/cache paths outside the repository;
no such workspace-specific launcher paths enter the Reading. No new Nix build,
whole project suite, manual SLY/browser acceptance, live MCP or production check
is claimed. Existing framework compatibility warnings are not new test failures.

The retained GitHub snapshot is a GET-only observation of six open PRs before
this Reading's own Draft PR is created. Re-import/compare is explicit; rendering
never polls GitHub. Curated quotes and reported PASS results are not human
acceptance. Actual human review notes remain separate objects, not source edits.
