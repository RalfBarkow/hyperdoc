# The public-views test without network (follow-up to RalfBarkow/hyperdoc#12)

Branch `claude/public-views-offline`, stacked on the #12 candidate `5c6a60471237939df89854b7c5effa0a8f3d964f`. It changes one
test file. Nothing here is merged or deployed. Why stacked: the sandboxed check can only pass with #12's own corrections (the
demo in the default membership, the E3 diagnosis observation), so the acceptance criterion needs them.

## The defect

`nix build .#checks.x86_64-linux.catalog` failed in a strict Linux Nix sandbox (`sandbox = true`, no network) in
`dreyeck/topic-maps-public-views/tests`, observed 2026-11-02 at `b989c01`. It predates #12 (the walk visits no object of the
demo; the Original Wiki Editor demo does not use the network).

Mechanism, from the code and the failing log ([before-sandbox-failure.txt](evidence/before-sandbox-failure.txt)):

1. Rendering the public views and walking from them asks `hyperbook/fedwiki::get-fedwiki` for three remote wikis:
   `ward.voices.ustawi.wiki`, `next.ward.dojo.fed.wiki`, `mech.dreyeck.ch`. The sources name them in the Work readings on
   Trails, hub selection and deployment (`dreyeck/work/`); which single visited object asks for which host was not traced.
2. `get-fedwiki` calls `make-fedwiki` with the production operations. `make-fedwiki` starts a thread that runs
   `initialize-fedwiki`: probe port 443 with `usocket`, fetch the sitemap, fetch plugin data.
3. Without network `getaddrinfo` fails with `EAI_AGAIN`, i.e. `usocket:ns-try-again-error`. `initialize-fedwiki` handles only
   stream errors, timeouts, `ns-host-not-found-error` and JSON errors. The condition escapes the thread; under
   `--disable-debugger` SBCL ends the whole process.
4. With live hosts the walk instead read their sitemaps, so what the test met depended on the machine's network.

## The change

`dreyeck/tests/topic-maps-public-views.lisp`: `call-with-offline-fedwiki` wraps `run-tests`. For the duration it replaces
the visited-site table (`*neighborhood*`) and passes `make-fedwiki` its **own keyword operations** (`:protocol-probe`,
`:sitemap-fetcher`, `:plugin-data-fetcher`, the seam the upstream inventory documents as there "to inject operations while
preserving production behavior"), each signalling `usocket:ns-host-not-found-error`. That condition is handled by
`initialize-fedwiki`, which retains it as the site's status. So the test exercises production's own failure path, no socket is
opened, and the outcome is the same on every machine. Afterwards the harness asserts that every site finished by retaining
exactly that condition and that every site in the table was made offline; the test prints the hosts
(`TOPIC-MAPS-PUBLIC-VIEWS-OFFLINE: 3 remote FedWiki sites …`). A caller that names its own operation keeps it.

The replacement is a temporary global `(setf fdefinition)`, so it is confined as described under *Review* below: it acts only
in the thread that called the harness, and the sites' threads are finished and the original function is restored on every exit.

Not changed: any library or application source (`hyperbook-fedwiki` is under the source-inventory test), `nix/`, `flake.*`,
`scripts/`, the other tests. No assertion was removed, weakened or reordered: `run-tests` runs the former body, wrapped, and
now runs one more check first, `check-offline-harness`.

## Review of the temporary replacement (2026-11-02, before merge)

Asked: is the function restored, are the started threads finished, and can it interact with other tests?
Experiments against the first version of the harness ([harness-review.txt](evidence/harness-review.txt)):

| Question | Finding on the first version | Now |
|---|---|---|
| Restored by `unwind-protect`? | **Yes**: function and table, after a normal exit and after an error (E1, E2). | unchanged; checked by `check-offline-harness` |
| Sites' threads finished? | **Only on a normal exit.** After an error the status was still a thread object (E3). | finished on every exit, before the function is restored; status is the retained condition |
| Other threads? | **Affected.** The replacement is global: a site made by any other thread during the harness was made offline, counted as asked for by the views and broke the harness's own check (E4). In an image that also serves a Catalog, its request threads would have created offline sites in the real, global table. | acts only where `*offline-fedwiki-p*` is bound (thread-local); other threads get the original function and table |
| Other tests? | In the Nix check every test system runs in its own `sbcl` process (`nix/catalog-check.nix`), so none shares this process. Tests elsewhere also rebind `*neighborhood*` (thread-locally) and some call `make-fedwiki` themselves (`tests/fedwiki-mech-sitemaps.lisp`, `dreyeck/tests/fedwiki-journal-context-debugger-smoke.lisp`); they are not run by this system. | a test that runs in another thread of the same image is unaffected; one that runs inside the harness's thread keeps the operations it names |

Limits, not addressed: two harnesses running at the same time in different threads would restore the function out of order
(the test system does not do that); and a test inside the harness that creates a site by `make-fedwiki` with its own
operations is accepted (its host is recorded) but is not required to be in the table.

`check-offline-harness` runs first in `run-tests`, outside the harness, and checks: restoration after a normal exit and after an
error, finished threads after an error, that another thread is not affected, and that a named operation is the caller's. Two
mutants of the harness (threads not finished; the guard global) are killed ([harness-review.txt](evidence/harness-review.txt)).

## Evidence (x86_64-linux cloud container, 2026-11-02)

| Criterion | Result |
|---|---|
| **Unchanged** `nix build .#checks.x86_64-linux.catalog`, `sandbox = true`, at **`7fba558`** (clean tree; the last commit that changes code) | **exit 0**, 5 min 29 s. The check, flake and lock are byte-identical to the #12 candidate (`git diff 5c6a604 7fba558` outside `docs/` touches only the test file); the package sources include `docs/`, so the commit that records this evidence cannot be the one tested. Markers: [after-sandbox-markers.txt](evidence/after-sandbox-markers.txt): application suite, demo tests, membership (24, each once, with and without an extra system), Topic Maps, `TOPIC-MAPS-PUBLIC-VIEWS-PASS`, ASDF methods (183), executable tests 6/6. Earlier runs of the first version of the harness at `4435a3e` and `1465c17` also exited 0. |
| Same check before the change (`b989c01`) | failed at the step above [obs] |
| Walk coverage preserved | The walk's summary with the harness is **identical** to that of the unmodified test on a machine with network, except for the label ([before](evidence/walk-with-network-before.sexp), [after](evidence/walk-offline-harness-after.sexp); again with the hardened harness: [hardened](evidence/walk-offline-harness-hardened.sexp)): 300 objects (bounded), 9 538 controls (inert 8 478, slot-reader 993, reviewed 11, reviewed-class 56, refused 0), the same views, errors (6 × `code-page/no-applicable-method-error`, as before) and visited-type histogram. |
| Authority-policy assertions preserved | Three mutants are killed by the complete `run-tests` under the harness ([mutants.txt](evidence/mutants.txt)): no containment, every control permitted, and a walk that sees no references. |

The walk alone does not kill the first two mutants, and did not before: no plain thunk is reachable in its 300 objects, because
the readings use `run-button` and `reviewed-thunk`. The containment is proven by `check-an-extra-button-is-refused` and the gate
checks, which `run-tests` runs.

## A production finding, not changed here

The packaged executable also starts with `--script` (no debugger) and the same `initialize-fedwiki`. A transient resolver
failure (`EAI_AGAIN`) while a visitor opens a page that reaches a not-yet-visited remote wiki therefore ends the Catalog
process, the way a broken pipe did before `573fe37`. The fix belongs to the FedWiki client (handle the condition, or all
`usocket` name-service errors) and to its upstream-inventory test; it is out of scope for this test-only change and is proposed
as its own task. Since verified and fixed: [../fedwiki-name-service-failures.md](../fedwiki-name-service-failures.md).

## Reproduce

```bash
nix build .#checks.x86_64-linux.catalog -L --out-link result-offline
```

Source acquisition in the cloud container needed the two controlled paths recorded in
[`../fedwiki-original-editor-farm/verification.md`](../fedwiki-original-editor-farm/verification.md#how-the-sources-were-obtained);
on a machine with ordinary network access the command above is enough.
