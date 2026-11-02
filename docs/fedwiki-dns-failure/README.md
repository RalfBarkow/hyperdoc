# A name-resolution failure of a remote wiki ended the process (RalfBarkow/hyperdoc#13)

Branch `claude/fedwiki-dns-try-again`, from `dreyeck.ch` at `0a7d4deec1e930ab2da3510a2547967b80347918`. Nothing here is merged or deployed.

## The defect, and the change

`hyperbook/fedwiki::initialize-fedwiki` runs in a thread that `make-fedwiki` starts for every remote wiki. It keeps, as the site's
status, the failures that belong to that one site: stream errors, timeouts, `usocket:ns-host-not-found-error`, invalid JSON. A resolver
that answers "try again later" (`EAI_AGAIN`: no network, or failing name servers) raised `usocket:ns-try-again-error`, which was not
among them. It left the thread, and in a process without a debugger, as the packaged `hyperdoc-catalog` is (`sbcl --script`), SBCL ends
the whole process. Reproduction and acceptance criteria are in #13.

The change adds two entries to the handler's list of conditions, in `hyperbook-fedwiki/fedwiki.lisp` (+4 lines with a comment):
`usocket:ns-try-again-error` and `usocket:ns-no-recovery-error`.

## The handler: which condition class

`usocket` names the failures of a host-name lookup with one parent and four children:

```text
usocket:ns-error                  "Parent error for all name resolution errors"
  ├─ ns-host-not-found-error      already handled
  ├─ ns-try-again-error           the reported defect
  ├─ ns-no-recovery-error
  └─ ns-unknown-error             "when there's no other, more applicable, error available"
```

What the SBCL backend (`usocket/backend/sbcl.lisp`) raises, and what a real resolver does. The resolver column was measured, with SBCL
2.4.10 on glibc, in an empty network namespace with a small DNS server answering with a chosen response code
([resolver-conditions.txt](evidence/resolver-conditions.txt)):

| Resolver behaviour | Condition |
|---|---|
| no server listening, server silent, SERVFAIL, NOTIMP, REFUSED | `ns-try-again-error` (5 of 5) |
| NXDOMAIN, FORMERR, and the response codes 6, 9, 10, 15 | `ns-host-not-found-error` |
| NOERROR without an address (NODATA) | the **raw** `sb-bsd-sockets:name-service-error`, no `ns-error` at all |
| no response code gave `ns-no-recovery-error` or `ns-unknown-error` | |

The backend maps exactly three conditions of the family: `host-not-found`, `try-again` and `no-recovery`. `ns-unknown-error` is **never
raised** by it, and it cannot even be printed: its report calls `usocket-real-error`, an accessor that exists only for a different
class (`princ` signals `no-applicable-method`; `sitemap-snapshot` formats the status that way).

Decision: **the two missing conditions the backend raises, not `ns-error` and not `ns-try-again-error` alone.**

- `ns-try-again-error` alone fixes everything that was observed, and would leave `ns-no-recovery-error` (EAI_FAIL, a lookup that cannot
  recover, which other libcs return where glibc does not) ending the process by the same mechanism. It has the same cause and the
  same remedy. I could not make glibc produce it, so that part rests on the backend's mapping, not on an observation.
- `ns-error` is shorter and survives new children in `usocket`, but it also retains `ns-unknown-error`, which the backend never raises
  and which cannot be printed: a status that breaks the view that shows it. The existing list names specific failures ("retain specific
  operational failures"); a parent class would turn it into a catch-all for the lookup.
- The contract test (below) rejects an added `usocket:ns-error`.

## Not in this change

- **Connect failures** (`usocket:socket-error`: `network-unreachable-error`, `host-unreachable-error`, ...) end the process in the same
  way and are **unchanged**. Measured with an IP literal and no route: exit 1 before and after
  ([connect-failure-unchanged.txt](evidence/connect-failure-unchanged.txt)). It is a different failure (the lookup succeeded), and the
  right outcome is a decision of its own: the probe returns `"http"` for a refused connection, and what an unreachable one should
  mean is not obvious. It should become its own issue.
- **NODATA**, the raw `sb-bsd-sockets:name-service-error` above, is not handled either: a host whose name has no address record. It
  is a gap in `usocket`'s SBCL mapping and would need an implementation-specific symbol in this library file.
- **Retry.** A site that failed once keeps its status in `*neighborhood*` for the life of the process, including after a temporary
  failure. The fix only stops the process from ending.

## The regression test

In `dreyeck/tests/catalog-application.lisp`, which the Nix `catalog` check already runs (that check is not changed):

- `check-fedwiki-name-resolution-failure` starts a fresh SBCL with the debugger disabled and looks at its exit status.
  1. One site per condition the backend raises, the probe signalling it: the process must survive, the condition must be the site's
     status (and an `ns-error`), `wait-for-sitemap` must return, and the site's sitemap snapshot must say `failed`. Deterministic
     everywhere.
  2. The platform's resolver itself, **only where it cannot reach a network**: in a process with no route to any network (the Nix build
     sandbox), or in an empty network namespace (`unshare -rn`). A machine with a network that cannot make a namespace is never asked:
     the test then says so and runs only the first part. In the Nix sandbox no DNS query can leave.
- `check-fedwiki-initialization-outcomes` is a table of what `initialize-fedwiki` does with each outcome: both success paths (an
  initial HTTPS stays, `"http"` sets HTTP), the failures kept before, the two new ones, and an error that is none of them (a
  programming error), which still leaves the function. The first rows were already true on the unfixed library.

Red without the fix, green with it ([red](evidence/red-without-fix.txt), [green](evidence/green-with-fix.txt)).

## Results, kept apart

**New, from this change.**

| Check | Result |
|---|---|
| New regression check, unfixed library | **fails**: exit 1; the control `host-not-found` finishes, then `try-again` ends the process; both with an injected probe and with the real resolver in `unshare -rn` |
| The same, with the fix | **passes**; the real resolver in the namespace answers `ns-try-again-error`, the status is kept |
| Reproduction of #13 (`sbcl --script`, `unshare -rn`), modes `real`, `try-again`, `not-found` | before: exit 1, 1, 0. **After: 0, 0, 0** ([reproduction.txt](evidence/reproduction.txt)) |
| **Unchanged** `nix build .#checks.x86_64-linux.catalog`, `sandbox = true`, at **`a449731`** (clean tree; the last commit that changes code) | **exit 0**, 5 min 44 s. `git diff 0a7d4de a449731` touches `hyperbook-fedwiki/fedwiki.lisp` and two test files only; `nix/`, `flake.*` and `scripts/` are unchanged. In the sandbox the real resolver was exercised (no route): `FEDWIKI-NAME-RESOLUTION-FAILURE: … OUTCOME REAL-RESOLVER NS-TRY-AGAIN-ERROR` ([after-sandbox-markers.txt](evidence/after-sandbox-markers.txt)) |
| Related test systems at the base and with the change: `hyperbook/fedwiki/tests`, `dreyeck/wiki-link/tests`, `dreyeck/local-fedwiki-view/tests`, `dreyeck/catalog-application` | **pass at both**: no regression ([related-test-systems.txt](evidence/related-test-systems.txt)) |
| Inventory contract of this change (`check-initialize-fedwiki-dns-change`) | holds; rejects an added `usocket:ns-error`, a missing or doubled entry, and any other change to the form ([mutants](evidence/dns-contract-mutants.txt)) |

**Pre-existing at the base `0a7d4de`, not caused and not accepted here.** The whole upstream-inventory test
(`dreyeck/hyperdoc/library-tests`) is red at the base. Only the manual matrix `scripts/check-upstream-boundary.sh` runs it (it needs `.git`); no CI, hook or Nix check does. It
has failed since the Mech changes of 2026-10-10 (`e903974`, `99521dc`) and the later POPUP and WALK commits. None of them touched the
contract, whose test file was last changed on 2026-10-01
([inventory-preexisting-vs-new.txt](evidence/inventory-preexisting-vs-new.txt)):

| Assertion | At the base | With this change |
|---|---|---|
| the four FedWiki files equal `+PREVIOUS+` (`401953522`) | **fails**: `fedwiki.lisp` (`defclass fedwiki`, `fetch-sitemap`, `sitemap-snapshot`), `pages.lisp` (`defclass fedwiki-page`, `copy-page-json`, `set-page-data`), `story-items.lisp` (four Mech forms), `wiki-links.lisp` (`make-remote`) | **fails on the same assertion**; `fedwiki.lisp` differs in those three forms and additionally in `initialize-fedwiki`, which is this change |
| `hyperbook.asd` against upstream | would fail next (`defsystem hyperbook/fedwiki` and its tests differ); hidden behind the first | still hidden behind the first |

So the contract was **not** brought up to date: `+PREVIOUS+` was not moved, which would have accepted those deviations unreviewed. The
new check is relative to `+PREVIOUS+` and runs first, so it reports even though the later assertions fail. `initialize-fedwiki` is the
same at `+PREVIOUS+` and at the base, so its whole difference from `+PREVIOUS+` is this change. **Repair needed, separately:** review the
Mech, POPUP and WALK deltas of the four files and of `hyperbook.asd`, and either enumerate them with their sources or take them out of
the library paths.

## Candidate upstream contribution

The change to `initialize-fedwiki` alters nothing for a reachable host and adds two entries to an existing list. It is recorded as such in
`docs/hyperdoc-upstream-boundary.md` and in the contract (`dreyeck/tests/hyperdoc-library-delta.lisp`).

## Reproduce

```bash
nix build .#checks.x86_64-linux.catalog -L --out-link result-dns
```

A dev machine with `unshare` also runs the real-resolver part of the check; one without it runs only the injected part and prints that.
The package sources include `docs/`, so the commit that records this evidence cannot be the one that was tested.
