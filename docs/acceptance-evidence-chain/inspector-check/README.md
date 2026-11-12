# Isolated CLOG navigation check

This follow-up exercised the acceptance-evidence-chain implementation preserved
in `637970ba79168d97d6d45455b3601cd9f1183ab8`. The checkout HEAD during the run
was `731d62dfe8fc9527399e86d59dbf2212c15c7afa`; the only change from the
implementation commit to that HEAD was the publication-status documentation
correction. The check harness was
uncommitted during execution and is retained here alongside its output.

## Executed command and environment

From `/workspace/work/acceptance-evidence-chain`:

```sh
python docs/acceptance-evidence-chain/inspector-check/browser.py
```

Actual exit code: **0**. Standard output:

```json
{"success": true, "steps": 10, "lispExitCode": 0}
```

The run took place from `2026-11-12T08:18:37.739620+00:00` to
`2026-11-12T08:18:54.781022+00:00`. It used Python 3.12.14, Playwright 1.62.0,
Chromium 154.0.8037.57 and a new SBCL 2.4.10 process. The exact Lisp command,
working directory, source hashes, browser version and individual observations
are retained in [results.json](results.json). This was executed by Codex, the
slice's implementer; no independent-author assessment is claimed.

The harness reuses the existing prepared dependency bootstrap and FASL cache,
with `DEFEDERATION_REPO` selecting this worktree. It does not select or activate
the qualified Topic Maps candidate. The process is new; dependencies are not
rebuilt from scratch. CLOG listens only on an automatically selected loopback
port (`127.0.0.1:59487` in this run). The browser has a fresh context and blocks
external page requests. No existing image or service is attached or modified.

## Observations

All ten actual-pane checks succeeded:

| Navigation or view | Server-side EQ target |
|---|---|
| Initial Evidence chain | Retained chain |
| Retained report text | Same chain |
| Retained log text | Same chain |
| Original execution report link | Original `git-evidence-file` |
| Original retained log link | Original `git-evidence-file` |
| Fixed evidence revision link | Original `git-revision-reference` |
| Parsed report link | Original parsed JSON object |
| Specified tested revision link | Original, separate revision object |
| Retained Nix reference source link | Original descriptor `git-evidence-file` |
| Report link followed again | Same report file object as before |

The probe reads the object from the Inspector's actual final pane and compares
it with the retained source objects using `EQ`. It does not merely check the
HTML link text or a newly reconstructed equivalent object. The retained-text
tabs display the report's `exitCode` field and the log's
`INSTANCE-OF-EXPORT-PASS` text respectively; these remain historical contents.

At every probe, the evaluation status remained `:INSPECTED`, the historical
execution-to-revision binding remained `:NOT-ESTABLISHED`, acceptance remained
`:NONE`, independent-author review remained `:NOT-ASSESSED`, and deployment
authority remained `:NONE`. Retained statement-list identity and cached source
file identity remained unchanged. The original log still had 121067 octets and
SHA-256 `2f9276424cd418cfe55db57a22cbfb542115659d1b98f390a3d0aacd1fa24adf`.

No browser page errors or external page requests were observed. The Lisp
process exited normally with code 0 after the harness signalled shutdown;
its recorded PID no longer existed in the immediate post-run check. The ASDF,
implementation and focused-test file hashes were unchanged before and after.

Retained artifacts:

- [browser.py](browser.py) and [inspector.lisp](inspector.lisp): executable harness.
- [inspector.log](inspector.log): startup and server-side EQ observations;
  SHA-256 `8ea58550870ddcc9c910a1b0146d50aa9fba4882a19874ab73ccd7a4b2976f1d`.
- [results.json](results.json): execution metadata and observations.
- [evidence-chain.png](evidence-chain.png): the actual chain view.
- [report-file.png](report-file.png): the opened native Git evidence object.

## Scope and limits

This is an automated, headless browser check through the native CLOG click
handlers, not a manual Emacs/SLY or production-session observation. Test-only
probes use existing private Inspector pane APIs; no production extension was
introduced. The test exercises the listed links and two text views; it does
not establish every generic Inspector operation or every subordinate Git view.
EQ is demonstrated within this one process, not across processes.

Reproduction requires the host-specific SBCL path and prepared dependency
registry referenced by the inherited bootstrap, Chromium, Playwright, and the
fixed Git objects. `EVIDENCE_SBCL` can select another compatible SBCL executable;
the dependency registry must still be reconstructed on another host. These are
runtime prerequisites, not implicit dependency-pin updates.

The previously retained 101 focused checks and Git/evaluation regressions were
not rerun. Their original records remain unchanged. No historical Nix command,
SHOP3 action, conformance test or deployment was executed. The JSON still has
no tested-revision field: inspecting the descriptor's literal reference does
not establish that the historical execution used that source revision. No
formal acceptance decision follows from this navigation result.
