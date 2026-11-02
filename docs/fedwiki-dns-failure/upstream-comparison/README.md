# Upstream commit 58a2b2c "Catch more name service errors" against PR #15

Konrad Hinsen, 2026-11-02, `58a2b2c66f0f5a0900a32910e5991e7d1833d9ed`, <https://codeberg.org/khinsen/hyperdoc/commit/58a2b2c66f0f5a0900a32910e5991e7d1833d9ed>.
Its whole diff is one line in `hyperbook-fedwiki/fedwiki.lisp` ([evidence/upstream-58a2b2c.diff](evidence/upstream-58a2b2c.diff)):

```diff
 ((or stream-error
      usocket:timeout-error
-     usocket:ns-host-not-found-error
+     usocket:ns-error
      shasht:shasht-invalid-char) (c)
```

**Nothing of it was taken over.** `+PREVIOUS+` and the upstream reference of the inventory contract were not moved, the handler of PR #15 was not
changed, and no test of PR #15 was changed. This directory is an analysis with a reproducible test.

## Where the line stands in upstream

Upstream's `make-fedwiki` starts a thread that makes **two separate attempts**, each with its own handler:

1. **The first connection attempt**, the HTTPS probe `(usocket:socket-connect domain 443)`. Its handler-case names only
   `usocket:connection-refused-error` (the site is HTTP) and `usocket:ns-host-not-found-error` (the status becomes the condition).
2. **The fetch of the site map and the plugin data** (`fetch-sitemap`, `fetch-plugin-data`). Its handler-case is the list above.

58a2b2c changes only the **second** list. The handler around the first attempt is untouched
([evidence/provenance.txt](evidence/provenance.txt)).

## The test: does `ns-try-again-error` still end the process in the first attempt?

**Yes.** `scenario.lisp` runs one scenario in a fresh SBCL with the debugger disabled (as `sbcl --script` runs the packaged `hyperdoc-catalog`)
under `unshare -rn` against one checkout of `hyperbook/fedwiki`; `run-matrix.sh` runs thirteen scenarios against four checkouts. The conditions are
injected by encapsulating `usocket:socket-connect` (first attempt) or `fetch-sitemap` (second attempt), so that each checkout's own handlers see
them; `probe-real` injects nothing: the platform's resolver fails in the empty namespace. "S(…)" means the process survived with that condition as the
site's status; "DIED" means the condition escaped the thread and ended the process (exit status 1). Raw data: [evidence/matrix.tsv](evidence/matrix.tsv).

| Scenario | upstream `9f919fc` (parent) | upstream `58a2b2c` (the commit) | ours, `dreyeck.ch` `0a7d4de` | ours with PR #15 |
|---|---|---|---|---|
| **first attempt**, real resolver (`probe-real`) | DIED `ns-try-again-error` | **DIED `ns-try-again-error`** | DIED | S `ns-try-again-error` |
| first attempt, `ns-try-again-error` | DIED | **DIED** | DIED | S |
| first attempt, `ns-no-recovery-error` | DIED | **DIED** | DIED | S |
| first attempt, `ns-host-not-found-error` | S | S | S | S |
| site map, `ns-try-again-error` | DIED | **S** | DIED | S |
| site map, `ns-no-recovery-error` | DIED | **S** | DIED | S |
| site map, `ns-host-not-found-error` | S | S | S | S |
| `ns-unknown-error`, first attempt | DIED | DIED | DIED | DIED |
| `ns-unknown-error`, site map | DIED | **S, status unprintable** | DIED | DIED |
| NODATA `sb-bsd-sockets:name-service-error` (#18), either attempt | DIED | DIED | DIED | DIED |
| `network-unreachable-error` (#16), either attempt | DIED | DIED | DIED | DIED |

Every cell of the table is a measured exit and condition, not a reading of the code. Reproduce, with the two upstream trees checked out
(`git clone https://codeberg.org/khinsen/hyperdoc up && git -C up worktree add ../up-parent 9f919fc…`) and our base as a work tree:

```bash
nix develop .#fedwiki-original-editor -c docs/fedwiki-dns-failure/upstream-comparison/run-matrix.sh \
  "upstream 9f919fc=/path/up-parent" "upstream 58a2b2c=/path/up" "ours 0a7d4de=/path/ours-base" "ours with PR #15=$PWD"
```

(Upstream's `pages.lisp` reads CLOG symbols without its system declaring CLOG; the scenario loads CLOG first. That is a property of the upstream
tree and does not affect the conditions tested.)

## What the upstream commit demonstrably corrects

- **In the second attempt** (site map and plugin data), a lookup that cannot answer (`ns-try-again-error`, e.g. SERVFAIL, no resolver, EAI_AGAIN) and
  `ns-no-recovery-error` no longer end the process: the condition becomes the site's status. At the parent commit they did (rows 5 and 6).
  It also keeps `ns-unknown-error` there, with a status that cannot be printed (below).
- It changes **nothing** for the first attempt: with a resolver that cannot answer, upstream's `make-fedwiki` still ends the process at the HTTPS
  probe, before the second attempt is reached. In practice that is the *common* case: the name is looked up first by the probe, and a failing
  resolver fails there (`probe-real`, reproduced with the real resolver, not only by injection).

So the commit is a real improvement for the case that the probe's lookup succeeded and a later lookup failed, which is a narrow window; it does
not close the defect of #13 in the form that was reported and reproduced.

## What PR #15 corrects beyond it

- **The first attempt.** In our fork the probe is called inside the one handler of `initialize-fedwiki`, so adding `ns-try-again-error` and
  `ns-no-recovery-error` there covers the probe and the second attempt together (rows 1 to 3, 5 and 6, last column).
- It is **tested for the failure that was reported**: a fresh SBCL with the debugger disabled, exit status as the verdict, red without the change, with
  the real resolver in an empty network namespace (the integration test) and injected conditions (the regular test).
- It does **not** correct, as the last rows show, and neither does upstream: NODATA (#18), connection failures (#16), and `ns-unknown-error`.

## Why explicit condition classes and not the parent class `ns-error`

This was decided before the upstream commit appeared and the commit does not change the facts; it does show that the decision is a choice, and
that upstream made the other one.

- **Same reach for what is raised.** The SBCL backend of usocket maps exactly three name-service conditions: `ns-host-not-found-error`,
  `ns-try-again-error`, `ns-no-recovery-error`. The explicit list and `ns-error` behave identically for all of them (table rows 1 to 7).
- **The one difference is `ns-unknown-error`**, which only the parent class keeps. The SBCL backend never raises it, so this is a difference of the
  handlers and not of any observed behaviour. Its report calls `usocket-real-error`, an accessor that exists for `unknown-error` (a `socket-error`)
  and not for `ns-unknown-error`, so **it cannot be printed**: `princ-to-string` signals `no-applicable-method` (measured with usocket alone, with
  drakma, and with the full `hyperbook/fedwiki`). A status of that class makes `sitemap-snapshot`, which formats the status with `princ-to-string`, signal
  as well ([evidence/snapshot-unknown.txt](evidence/snapshot-unknown.txt)): the control `ns-try-again-error` gives `state="failed"` with its message.
  Upstream's handler, widened to `ns-error`, would store exactly such a status; our fork's view of the status would then fail instead of reporting it.
- **The list names specific operational failures** ("retain specific operational failures", the docstring of `initialize-fedwiki`); a parent class
  makes it a catch-all for a family that may grow, including children not yet seen.
- **Our contract encodes the decision.** `check-initialize-fedwiki-dns-change` accepts exactly the two added symbols and rejects an added `ns-error`.

It is reversible and cheap: one list entry, one table row, and the contract's rejection of `ns-error` turned into its acceptance, together with
a view of the status that survives an unprintable condition. Which backends other than SBCL's raise `ns-unknown-error` was not checked.
Where upstream and this fork should agree is a decision for the maintainers, not taken here.

## Effects on the origin and inventory statements

- **The upstream reference is not moved.** The contract compares against `8a1149197` (khinsen); it is an **ancestor** of 58a2b2c, which is the sixth commit
  after it. Of those six, only 58a2b2c touches `hyperbook-fedwiki/`, and it touches only this line. The others change `hyperbook`, `hyperdoc` and the
  explorers. What the contract compares is unchanged. Adopting any of them is a separate, reviewed step; it was not done.
- **`+PREVIOUS+` (`401953522`) is not moved.** The check of PR #15 is relative to it; `initialize-fedwiki` is the same at `+PREVIOUS+` and at the
  base, so its whole difference is still this change. That statement is unaffected.
- **The upstream line does not apply to our file.** `git apply --check` of the upstream diff to `hyperbook-fedwiki/fedwiki.lisp` at `0a7d4de` fails
  (evidence/provenance.txt): our fork replaced upstream's inline `make-fedwiki` thread with `probe-fedwiki-protocol` and `initialize-fedwiki` (the Mech
  changes), so the hunk has no place. The equivalent in our form is the type list in `initialize-fedwiki`, which PR #15 extends. A later adoption of
  the upstream line would be a manual, reviewed edit, not a merge.
- **The "candidate upstream contribution" statement changes.** It said that PR #15 "adds two entries to an existing list". Upstream's list is
  now a different one (`ns-error` in the second handler), and what upstream still lacks is the handler of the **first** attempt. A contribution
  would therefore be: handle `ns-try-again-error` and `ns-no-recovery-error` (or `ns-error`) around the HTTPS probe. It was corrected in the README and in
  `docs/hyperdoc-upstream-boundary.md`. Nothing is offered or sent upstream.
- **The contract's `ns-error` rejection diverges from upstream's choice.** It stays: it encodes our decision above. If the project adopts upstream's
  `ns-error`, that assertion has to be revised on purpose. It is not an upstream conformance check.
- **Origin.** PR #15 was written without having seen 58a2b2c, and nothing in it was taken from it. The upstream commit is dated the same day as
  PR #15 and is, as far as the evidence goes, an independent change of the same family.
