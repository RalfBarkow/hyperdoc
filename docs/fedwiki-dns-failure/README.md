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
  way and are **unchanged**: measured with an IP literal and no route, exit 1 before and after
  ([connect-failure-unchanged.txt](evidence/connect-failure-unchanged.txt)). The lookup succeeded there; the connection failed. The
  handler decision is open and tracked in #16.
- **Retry.** A site that failed once keeps its status in `*neighborhood*` for the life of the process, including after a temporary
  failure. The fix only stops the process from ending.
- **The upstream-inventory contract's existing deviations**: tracked in #17 (see *Results*).

## Known finding, kept apart: NODATA

A host name that exists but has **no address record** (the resolver answers NOERROR with an empty answer) arrives as the raw
`sb-bsd-sockets:name-service-error`. `usocket`'s SBCL backend maps only `host-not-found`, `try-again` and `no-recovery`, so this one is
neither a `usocket:ns-error` nor a `usocket:socket-error`. It is **not a connection failure** and **not** what this fix handles. It would
end the process the same way. Measured with the response code 0 and no answer ([resolver-conditions.txt](evidence/resolver-conditions.txt),
the `rcode0` line). Handling it would need an implementation-specific symbol (`sb-bsd-sockets:name-service-error`) in a library file
that otherwise names only `usocket` conditions, or a fix in `usocket`'s mapping. It is a known gap, tracked on its own in #18 (observations, source findings and hypotheses kept apart; no decision yet).

## The regression test

In `dreyeck/tests/catalog-application.lisp`, which the Nix `catalog` check already runs (that check is not changed):

- `check-fedwiki-name-resolution-failure` is **the regression test**. It starts a fresh SBCL with the debugger disabled and looks at its exit
  status. One site per condition the backend raises, the probe signalling it: the process must survive, the condition must be the site's
  status (and an `ns-error`), `wait-for-sitemap` must return, and the site's sitemap snapshot must say `failed`. It asks no resolver and
  opens no connection, so its verdict does not depend on the network or the resolver configuration of the machine it runs on. It is red
  on the unfixed library and green with the fix, it is what establishes this change, and it is called by `run-tests`, hence by the Nix
  check.
- `check-fedwiki-initialization-outcomes` is a table of what `initialize-fedwiki` does with each outcome: both success paths (an
  initial HTTPS stays, `"http"` sets HTTP), the failures kept before, the two new ones, and an error that is none of them (a
  programming error), which still leaves the function. The first rows were already true on the unfixed library.

Red without the fix, green with it ([red](evidence/red-without-fix.txt), [green](evidence/green-with-fix.txt)).

### The integration test with the real resolver, run explicitly

`check-fedwiki-real-resolver-integration`, in the same file, is **not called by `run-tests`** and so not by the Nix `catalog` check. It
asks the platform's own resolver for a name that cannot exist (`wiki.test-host.invalid`) and requires that the process survives with an
`ns-error` as the site's status. It was part of the regular test in the first versions of this change (`369c745d` to `209f25b`). It was
moved out because its outcome depends on the resolver configuration of the environment (a loopback resolver that answers differently, for
example NODATA, #18, would make the Nix check fail for a reason that is not the code under test), and a build should not need a real name
resolution.

- Run it with `scripts/check-fedwiki-real-resolver.sh` (Linux, `nix develop`, `unshare`). It runs the child SBCL **under `unshare -rn`**, an
  empty network namespace whose loopback is empty. Where `unshare` cannot make one it runs only if the process sees nothing but `lo`
  already (a resolver on that loopback is then not excluded, see *Review of the two guards*), and otherwise it **signals an error** instead
  of passing silently.
- Result at `0d89285`: **pass** with the fix, `OUTCOME REAL-RESOLVER NS-TRY-AGAIN-ERROR ns-error=T snapshot=failed`; **fails** (exit 1,
  the child process ended) with `hyperbook-fedwiki/fedwiki.lisp` as at the base `0a7d4de`
  ([real-resolver-integration.txt](evidence/real-resolver-integration.txt)).
- The regular test asks no resolver any more. Measured by running `dreyeck/catalog-application` in `unshare -rnm` with a counting DNS stub
  on the loopback that `resolv.conf` names: the test file at `209f25b` made **2** queries (`wiki.test-host.invalid`), the test file at
  `0d89285` made **0** ([regular-test-dns-queries.txt](evidence/regular-test-dns-queries.txt)).

## Results, kept apart

**New, from this change.**

| Check | Result |
|---|---|
| Regression test (injected), unfixed library | **fails**: exit 1; the control `host-not-found` finishes, then `try-again` ends the process. The integration test with the real resolver in `unshare -rn` fails the same way ([real-resolver-integration.txt](evidence/real-resolver-integration.txt)) |
| The same, with the fix | **passes**; the integration test: the real resolver in the namespace answers `ns-try-again-error`, the status is kept |
| Reproduction of #13 (`sbcl --script`, `unshare -rn`), modes `real`, `try-again`, `not-found` | before: exit 1, 1, 0. **After: 0, 0, 0** ([reproduction.txt](evidence/reproduction.txt)) |
| **Unchanged** `nix build .#checks.x86_64-linux.catalog`, `sandbox = true`, at **`0d89285`** (clean tree; the last commit that changes code) | **exit 0**, 6 min 31 s. `git diff 0a7d4de 0d89285` touches `hyperbook-fedwiki/fedwiki.lisp`, two test files and the new `scripts/check-fedwiki-real-resolver.sh`; `nix/` and `flake.*` are unchanged, and the check is the same command. The regular test now asks no resolver (0 queries, see above), so the check needs no real name resolution: its `application.log` holds no real-resolver marker ([nix-check-at-0d89285.txt](evidence/nix-check-at-0d89285.txt)). Earlier runs, when the real-resolver part was still in the regular test, also exited 0: `09f0768` (isolation path, `OUTCOME REAL-RESOLVER NS-TRY-AGAIN-ERROR`, [after-sandbox-markers.txt](evidence/after-sandbox-markers.txt)) and `a449731` |
| Related test systems at the base and with the change: `hyperbook/fedwiki/tests`, `dreyeck/wiki-link/tests`, `dreyeck/local-fedwiki-view/tests`, `dreyeck/catalog-application` | **pass at both**: no regression ([related-test-systems.txt](evidence/related-test-systems.txt)) |
| Inventory contract of this change (`check-initialize-fedwiki-dns-change`) | holds; rejects an added `usocket:ns-error`, a missing or doubled entry, the two symbols **moved** out of the handler's type list (into the `progn`, a quoted list, a clause of their own), and any other change to the form ([mutants](evidence/contract-after-hardening.txt)) |

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
same at `+PREVIOUS+` and at the base, so its whole difference from `+PREVIOUS+` is this change. **Repair needed, separately, tracked in #17:** review the
Mech, POPUP and WALK deltas of the four files and of `hyperbook.asd`, and enumerate them with their sources or take them out of
the library paths. The deviations were reconstructed path by path with their origin commits
([inventory-reconstruction.txt](evidence/inventory-reconstruction.txt)): of the 15 paths the test walks, 10 hold and 5 fail.

## Review of the two guards (2026-11-02)

**1. Does the real-resolver test keep a DNS server out of reach?** The first guard, "no route to `192.0.2.1`", did not. It says there is no
default route, not that no resolver is reachable: a resolver on loopback (a local stub), an internal DNS server, an IPv6-only network
answer without one. Measured, in a namespace with a loopback DNS server and no default route: the guard said "no network" and the real
resolver sent the server 2 queries ([no-route-guard-hole.txt](evidence/no-route-guard-hole.txt)). With a non-loopback interface (a TUN
device, `10.7.7.1/24`), the DNS server on it and no default route: the old guard said "no network" (`T`) and the server received
**1 query**; the new guard saw the interface (`isolated-p` = `NIL`), ran the resolver in a nested empty namespace, and the server received
**no further query** ([non-loopback-interface-comparison.txt](evidence/non-loopback-interface-comparison.txt)).

The guard is now isolation. It applies to the explicit integration test only, since the regular test no longer asks a resolver (see *The
integration test with the real resolver*): an empty namespace by `unshare -rn`, which is isolated by construction; failing that, the process
sees no interface but loopback (`%isolated-p`, read from `/proc/net/dev`); failing that, the integration test signals an error. A Nix build sandbox on Linux
shows only `lo` in `/proc/net/dev` ([nix-sandbox-network-view.txt](evidence/nix-sandbox-network-view.txt)); `/sys/class/net` is not
there, which is why `/proc` is read. On macOS neither holds (no `/proc/net/dev`, no `unshare`): the integration test cannot run there; the
regular test, which is injected, does. Not run on macOS.

**What the isolation guard does and does not exclude.** Seeing only `lo` in `/proc/net/dev`, or running under `unshare -rn`, means that the
process has **no route to a host outside its network namespace**, so no connection to an external DNS server (or any other external
host) can be made. It does **not** mean that no resolver is reachable: a resolver that listens on the loopback of that namespace is
reachable, and `lo` alone cannot tell it from none. Measured: in `unshare -rnm` with only `lo`, a UDP stub on `127.0.0.1:53` named in
`/etc/resolv.conf` received the real resolver's queries, and the outcome followed the stub's answer
([resolver-conditions.txt](evidence/resolver-conditions.txt), [no-route-guard-hole.txt](evidence/no-route-guard-hole.txt)). The two paths
differ in what they promise (the first is the one the integration test takes by preference; the second was the only one used in the sandbox
while the real-resolver part was still in the regular test, at `09f0768`):

| Path | Loopback resolver | Established |
|---|---|---|
| `unshare -rn` (an empty namespace is made by the test) | none: the new loopback is empty, nothing listens on it | measured: no further query reached a server on the outer interface |
| the process already sees only `lo` (a Nix build sandbox) | **not excluded**: whatever listens on that loopback is asked | measured for the sandbox: `lo` only; whether anything listens on its `127.0.0.1:53` was not recorded. The outcome there, `ns-try-again-error`, is what a missing server gives (`noserver` in the table), so it is consistent with no listener, but it is not proof of one |

Two consequences. (1) The expected `ns-error` of the integration test holds where nothing answers on loopback (or something answers
SERVFAIL, NXDOMAIN and the like); a loopback resolver that answers differently, for example NODATA (#18), gives another outcome and the
integration test fails there, with the condition printed. Because it is no longer part of the regular test, that cannot fail the Nix check. That is a finding about the environment or the library, not a regression of
this change. (2) A path that does not go through a UDP port on the loopback, such as the `nscd` socket or a resolver reached through a
Unix-domain socket, is a **hypothesis, not a measurement**: a Unix-domain socket is not confined by the network namespace, so it could answer
from outside it. No such path was looked for or found in the build sandbox, and none is excluded by the guard.

**2. Does the inventory contract see the two conditions moved out of the type list?** It did not. Moved as bare elements into the `progn`,
the check still held (`MOVED-TO-PROGN: CONTRACT-HOLDS`): a count and a difference to `+PREVIOUS+` cannot tell where the symbols stand
([contract-before-hardening.txt](evidence/contract-before-hardening.txt)). Only that assertion was hardened: both symbols must be members
of the `or` type list of a `handler-case` clause that already names `usocket:ns-host-not-found-error`. The move is now rejected, as are
the other mutants ([contract-after-hardening.txt](evidence/contract-after-hardening.txt)).

## Candidate upstream contribution

The change to `initialize-fedwiki` alters nothing for a reachable host and adds two entries to an existing list. It is recorded as such in
`docs/hyperdoc-upstream-boundary.md` and in the contract (`dreyeck/tests/hyperdoc-library-delta.lisp`).

## Reproduce

```bash
nix build .#checks.x86_64-linux.catalog -L --out-link result-dns
```

The check runs the regression test with injected conditions and asks no resolver. The real resolver is a separate, explicit run
(Linux with `unshare`; it signals an error where it cannot run):

```bash
scripts/check-fedwiki-real-resolver.sh
```

The package sources include `docs/`, so the commit that records this evidence cannot be the one that was tested.
