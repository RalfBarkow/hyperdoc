# Federated Wiki without DNS: a first read-only experiment

Reference: Zettel 11483, *Federated Wiki without DNS: Identity, Reachability, and Local Continuity*.

**Question.** Can the same known Federated Wiki page be read under an unchanged site identity although ordinary name resolution fails,
as long as a previously known IP endpoint still answers?

**Answer for this experiment (one site, one page, HTTP, SERVFAIL).** Yes, and the evidence shows where that answer stops. With the name
resolving, the page was read by name (observation A). With resolution failing and the same URL, the ordinary path failed at name
resolution and made no connection (B). With resolution still failing and the address that A's resolution had given, the same URL read
the same JSON (C: HTTP 200, the same SHA-256 as A, equal to the frozen stored page). Three controls were not accepted: an endpoint of a
different, empty wiki (404), an unreachable address (timeout), and a server holding the same slug with one changed sentence (200, other
digest). What the record does **not** support is an authenticated identity: over HTTP without TLS the endpoint's membership of the site is
an inference from equal content, and the record labels it so.

Nothing here is a DNS replacement, a peer discovery, a synchronization or an editor. The endpoint was given, not found.

## What was reused, and what was not touched

| Component | Used for | Changed? |
|---|---|---|
| `hyperbook-fedwiki/utilities.lisp` `wiki-url` | the URL, so the Host header keeps the site name | no |
| `hyperbook-fedwiki/pages.lisp` `fedwiki-page`, `set-page-data` | the JSON of a read page becomes a `fedwiki-page` with story and journal; no new wiki data structure | no |
| drakma (the HTTP client `fetch-json` uses) with its `:real-host` | connect to the given address while URL and Host stay the site's; **no second HTTP client** | no |
| `hyperbook-fedwiki/fedwiki.lisp` | read to see what initialization does; **not used and not changed** (it starts a thread per site, which a one-shot observation does not want) | no |
| `dreyeck/src/local-fedwiki-page*.lisp` | the frozen page file as a `local-fedwiki-page` with its SHA-256 (`observe-local-fedwiki-page-source`), shown by the demo | no |
| `tests/fedwiki-original-editor/node_modules` (`wiki-server` 0.28.1) | the **original** Federated Wiki server serves the frozen page, read-only (`security_legacy=false`) | no |
| `dreyeck/authority-policy` | the Inspector's generic Operations stay gated; the demo depends on it | no |

`hyperbook/fedwiki::fetch-json` was **not** reused: it takes no endpoint and returns only parsed JSON, dropping the status and the octets
whose digest is the evidence. The experiment therefore calls drakma itself, with the same URL builder, and hands the JSON to the library's
own page class. The production client is untouched: `git diff dreyeck.ch -- hyperbook hyperbook-fedwiki hyperdoc` is empty.

New files: `dreyeck/src/fedwiki-without-dns.lisp` (the record), `dreyeck/src/fedwiki-without-dns-demo.lisp` (the Catalog demo and its
Inspector views), `dreyeck/pages/fedwiki-without-dns-demo/…html`, tests, `tests/fedwiki-without-dns/` (harness, observer, original-server
adapter, frozen site, browser walk), this directory (record and evidence), and four ASDF systems in `dreyeck.asd`.

## The experiment

Two Linux network namespaces joined by a `veth` pair (no TUN/TAP), made without root by `unshare -rnm`:

```
 server namespace (10.77.0.1, .3, .4)                       client namespace (10.77.0.2)
 ┌──────────────────────────────────────────┐   veth   ┌────────────────────────────────┐
 │ original wiki-server  10.77.0.1:80  page │◀────────▶│ the observer: SBCL + HyperDoc  │
 │ decoy: empty wiki     10.77.0.3:80  404  │          │ resolv.conf → 10.77.0.1:53     │
 │ decoy: changed page   10.77.0.4:80  200  │          └────────────────────────────────┘
 │ DNS server            10.77.0.1:53       │          nothing at 10.77.0.9
 └──────────────────────────────────────────┘
```

Site identity `wiki.without-dns.test` (RFC 6761 `.test`), page `without-dns-test-page` (title, three story items, four journal entries),
frozen in `tests/fedwiki-without-dns/frozen-site/pages/` (SHA-256 `335357a8…`). The servers run on copies; the frozen file and the served
copy are hashed before and after (unchanged: `evidence/stored-pages.txt`).

| Id | Role | DNS server | Request | Result (recorded) |
|---|---|---|---|---|
| A | baseline | resolves the site to 10.77.0.1 | by name | HTTP 200, page read |
| B | DNS failure | answers **SERVFAIL** to everything | by name | `USOCKET:NS-TRY-AGAIN-ERROR`, no connection, nothing read |
| C | given endpoint | still SERVFAIL | same URL, connect to **10.77.0.1** (taken from A's resolution) | HTTP 200, same SHA-256 as A, JSON equals the stored page |
| D | control: wrong endpoint | SERVFAIL | endpoint 10.77.0.3 (another, empty wiki) | HTTP 404, no page |
| E | control: unreachable | SERVFAIL | endpoint 10.77.0.9 (nobody) | no connection (timeout) |
| F | control: other content | SERVFAIL | endpoint 10.77.0.4 (same slug, one sentence changed) | HTTP 200, **different** digest |

Independent of the Lisp code, the harness also asks `getent hosts` and makes a raw TCP connection from the client namespace
(`evidence/run.txt`): before the failure `getent` resolves and TCP connects; under the failure `getent` fails (exit 2) and **TCP to
10.77.0.1:80 still connects**. That is the "IP connectivity remains while DNS fails" condition, observed by tools that do not share code with
the observer. The DNS server's own log is `evidence/dns-queries.txt` (it also shows that the wiki server's start-up looks up
`raw.githubusercontent.com`, which the namespace answers with NXDOMAIN; nothing leaves the namespaces).

The DNS failure is `servfail` by default. `--dns-failure nxdomain` and `silent` give other conditions of the same resolver family; their runs
are summarized in [evidence/variants.txt](evidence/variants.txt).

The served octets (1260) differ from the stored file (1712): the original server serializes the page itself. "Unchanged JSON" is therefore
tested as structural equality of the parsed JSON (`equivalent-json`) in addition to equal digests between the two retrieval paths (A and C
have the same served bytes). A byte-identical match (`identical-bytes`) is what the loopback test uses.

## The observation object

`dreyeck/src/fedwiki-without-dns.lisp`: `access-observation` and `experiment-record` (CLOS, with `print-object`), `claim`, `observe-access`.
An observation holds: the **site identity** as named (the host name of the URL; never derived from an address), the **page slug**, the URL, the
**endpoint** and the **origin of the endpoint mapping** (`(:earlier-resolution "A")` or `(:declared "…")`), the **access** (`:ordinary-resolution`
or `:explicit-endpoint`), the **DNS result** at that moment (resolved addresses, or the condition type and message), the **connection and
HTTP** result, the **TLS status** (`:not-performed`, with the reason), the **JSON SHA-256** of the served octets, the content relation to the
stored page, the **observation time**, and the **warrant**. Records are plain data (keywords, strings, integers): `read-record` uses the
standard reader with `*read-eval*` off and refuses anything else.

Warrants: `observed` is what the observer measured (a condition signalled, a status received, octets hashed); `derived` is computed from
observed values (digests compared; the outcome of an observation); `inferred` goes beyond what was measured and states its assumption
(the endpoint belongs to the site); `hypothesized` was not tested (a certificate check; other failures; other sites). `derive-findings`
computes the claims from the record alone, so a record that shows less supports fewer claims.

## Reading it: Catalog → demo HyperBook → page → Inspector observation

The demo is **not** a member of the default Catalog (`scripts/check-without-dns-demo-membership.lisp`: the default Catalog stays the 24
HyperBooks of `dreyeck.ch`; naming the demo adds exactly its id). Start a local Catalog that names it, as `HYPERDOC_CATALOG_SYSTEM` does:

```bash
nix develop .#fedwiki-original-editor -c sh -c 'HYPERDOC_WITHOUT_DNS_PORT=8099 "$HYPERDOC_FEDWIKI_SBCL" --noinform --no-sysinit --no-userinit --script tests/fedwiki-without-dns/serve.lisp'
```

Then, at <http://127.0.0.1:8099/> (loopback only):

1. **Catalog**: click *Reading a Wiki Page Without DNS*.
2. **Demo HyperBook**: click *Text pages*, then *Reading One Wiki Page Without DNS*.
3. **The page**: it shows the stored page that was read (its story, the digest of the frozen file) and the six observations in one table.
4. **Inspector observation**: click *Experiment record* for the comparison of the access paths (the tabs *Claims by warrant*, *Setup* and
   *Record as data* follow), or *B* and *C* for the two observations: B failed at name resolution, C read the page.

The comparison names the site, the failure condition, the given endpoint and where its mapping came from, whether the page was read, whether
the digest equals the stored one, and marks every claim *observed*, *derived*, *inferred* or *hypothesized*. The views offer no control of their
own: no fetch, no write. (The Inspector's generic *Operations* tab, which every object has, stays under `dreyeck/authority-policy`.)

`scripts/check-fedwiki-without-dns.sh` does steps 1 to 4 in a browser (Chromium) and checks them; its screenshots are in
[evidence/browser/](evidence/browser/).

## Acceptance

| # | Required | Shown by |
|---|---|---|
| 1 | Ordinary retrieval succeeds with working resolution | observation A: DNS resolved to 10.77.0.1, HTTP 200, `read; the same page`; `getent` resolves (`evidence/run.txt`); test `check-record-is-consistent` |
| 2 | DNS fails under the controlled condition | observation B: `USOCKET:NS-TRY-AGAIN-ERROR` for SERVFAIL, stage `name-resolution`, no HTTP; `getent` exit 2; DNS log shows the SERVFAIL answers |
| 3 | The given IP endpoint stays reachable | raw TCP to 10.77.0.1:80 connects under the failure (`evidence/run.txt`); observation C connects |
| 4 | The same unchanged wiki JSON is read again | C has the same SHA-256 as A, `equivalent-json` to the frozen stored page; frozen and served files unchanged (`evidence/stored-pages.txt`) |
| 5 | The Inspector view distinguishes the observed states | `Comparison of the access paths`, `Claims by warrant`, and one view per observation and claim; tests and browser walk assert the distinct outcomes and the four warrants |
| 6 | No production wiki data read or changed | only the frozen test site and two files of the checkout are read; a test forbids network calls while the demo renders and compares the bytes of the record and the frozen page before and after |
| 7 | Existing FedWiki and Catalog tests stay green | [evidence/existing-tests.txt](evidence/existing-tests.txt); the unchanged Nix `catalog` check (below) |

Negative controls D, E, F are in the record and the tests. The tests are themselves checked by mutants
([evidence/mutants.txt](evidence/mutants.txt)): a view with a control, a different-content answer counted as the same page, the endpoint
ignored, the site identity taken from the address, an inferred claim labelled observed, three corruptions of the committed record, and a
demo that resolves a name are each detected.

## Limits

- **HTTP without TLS.** No authenticated site identity is claimed. "The endpoint holds the same site's page" is *inferred* from equal content; a
  certificate check against the site name is the separate acceptance stage (`tls` is recorded as `not-performed`). Not tested.
- **One site, one page, one resolver failure per run, a read-only original server.** A production farm, other pages and other failure modes
  are untested. The failure modes `nxdomain` and `silent` were run once each ([evidence/variants.txt](evidence/variants.txt)).
- **The endpoint is given.** Its origin is either the resolution of an earlier observation of the same run or declared by the experimenter. Nothing finds endpoints,
  keeps them, refreshes them or decides between them.
- **No change to the production FedWiki client**, which still fails the way it does when its resolution fails (see #13, #15, #18); the
  experiment does not fix or depend on any of that: its observer records the condition and goes on.
- **Linux with user and network namespaces.** `veth` pairs worked in the Claude Code cloud container used here. Where they do not
  (`unshare -rn` fails), `scripts/check-fedwiki-without-dns.sh` says so and points to the process-local test
  `asdf:test-system "dreyeck/fedwiki-without-dns"`: a loopback server, the resolver *injected* to fail, a request with `:real-host 127.0.0.1`.
  Its force is limited: it shows that the code path reads the page by a given address while the name stays unresolved, not that the real
  stack's resolution failed, and not that anything was reached over a network.
- The browser walk was made with Chromium on Linux only. The packaged `hyperdoc-catalog` with `HYPERDOC_CATALOG_SYSTEM` naming the demo
  was **not** run; the local launcher above calls the same `start-catalog` with the same `catalog-system` argument. Nothing is added to the
  default Catalog, to `nix/` or to any service configuration.

## Reproduce

```bash
scripts/check-fedwiki-without-dns.sh            # tests, the experiment in two namespaces, comparison with the committed record, the browser walk
scripts/check-fedwiki-without-dns.sh --record   # the same, and replace this directory's record and evidence with the new run
```

Needs `unshare` with user namespaces, `ip` (iproute2; from `PATH`, `$IP`, or nixpkgs through this flake), `nix develop .#fedwiki-original-editor`
and `npm ci --prefix tests/fedwiki-original-editor --ignore-scripts`. Chromium comes from `$CHROMIUM` or `/opt/pw-browsers`. No network is
needed once the Nix inputs are in the store. Two runs differ in times, ports and versions, and agree in the outcomes, statuses and
digests (`tests/fedwiki-without-dns/compare-records.lisp`).
