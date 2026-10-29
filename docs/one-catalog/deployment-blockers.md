# One production Catalog: deployment blockers found after the baseline commit

2026-10-29. Findings only; none is fixed in `a9155676`. Each is a separately reviewable follow-up. Evidence: `evidence/blockers/`.
This note also corrects one statement of `security-review.md`: the Workspace is **not** a shared singleton (see 4).

## 1. A disconnected client can terminate the process — **blocker** [obs]
On a warm packaged executable, a client that sends `GET /` and closes the socket immediately made the process exit (status 1) on the first try, with `Unhandled SB-INT:BROKEN-PIPE`
in a `hunchentoot-worker` thread. The **base** package `0c388f95`, which the server runs now, does the same. `--script` disables the debugger, so an unhandled error in any thread is fatal.
Not established: whether nginx in front shields the process (it closes the upstream connection when a client aborts, so a response larger than the socket buffers can still hit it), since nginx was not available here.
A longer timeout is not a fix (the earlier test change only stopped the tests from provoking it). Follow-up: handle stream errors in the worker/acceptor, with `abort.py` as the regression test.

**Cause and fix (branch `fix/catalog-broken-pipe`, not merged):** CLOG starts Clack with `:debug` on, and Hunchentoot's `*catch-errors-p*` is off inside a request, so a write error reaches `hunchentoot:maybe-invoke-debugger`; the executable's debugger is disabled, so invoking it exits the process. `dreyeck/src/catalog-application.lisp` now declines it for `stream-error` only, which lets Hunchentoot's own outer handler end that one request. With the fix `abort.py` leaves the process alive (0 BROKEN-PIPE lines), where the base dies at the first abort; `tests/test_catalog_executable.py::test_aborted_clients_do_not_end_the_process` fails on the old package and passes on the new one.

## 2. CLOG views and the authority boundary [der + obs]
The boundary covers HTML-view controls under `eval-`/`action-` ids. The CLOG handlers a served visitor can reach: *Source* and *Text* are read-only Ace views (`read-only-p t`, no handler); *Playground* has its Eval button disabled and registers no handler when `:playground?` is false (it is, served);
the *Gesture* surface beside the code-page request buttons ends in the same `ensure-operation-request` as the reviewed control `gesture/request-through-binding` (data only); topic-sign gestures are bound only to `topic-action-reference` (reviewed) and offer the Follow operation (navigation).
No handler found that bypasses the boundary. Not covered: other reference prefixes (`input-`, `change-`, `subview-`) are not controlled by the boundary; no `dreyeck` source creates them, and the only `reactive` users are the Project Workspace (refused) and one local-only system. Follow-up: extend `contain-controls` or assert their absence in the walk.

## 3. Trails and TALA [der]
Not part of the six public objects; no Trails object within depth 3 / 500 objects of them. Their controls are reviewed thunks, unchanged in behaviour, **unexercised when served**. Treat them as outside the proposed public surface until a served click test exists (the existing Trails suites exercise them developing only).

## 4. Workspace history [obs]
`work-workspace` returns a new object per call, so history is per Workspace object, not shared between visitors. On one object, 70,000 clicks through the click path grew its history to 70,000 entries: unbounded within that object's life, about one cons per click, reclaimed with the pane. Low severity; bound it in `topicmap-workspace-go-to` if wanted (separate change). `*requests*` (gesture) is bounded by the definitions; the cursors are bounded.
