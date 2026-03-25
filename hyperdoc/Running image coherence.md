# Running image coherence

[…]

McDermott’s paper is exactly about keeping a long-lived Lisp image coherent while code and supporting chunks are revised and reloaded, and your repo already contains both the source page **A framework for maintaining the coherence of a running Lisp** and the page **McDermott Running Image Coherence Crosswalk**. That makes **Running image coherence** the right durable topic above those pages, rather than just another Drew-specific leaf.

Your failing trace shows the old boundary: the browser sends a normal association request, then the WebSocket closes before any server acknowledgement, and the JS falls back to the inline message ending with **“See console/server log for request id …”**. That is not just anecdotal; the current client code has an explicit `failPendingRequest(...)` path that emits exactly that feedback when the connection closes before pane-open acknowledgement arrives. 

The important part is that the repo already contains the beginnings of the better thing you want. There is now a separate **connect snapshot** transport (`connect-snapshot-v1`), a server path that opens or reuses a dedicated snapshot pane (`open-dom-connect-snapshot-pane`), and success copy that says **“Connect state opened.”** instead of **“Association pane opened.”** 

On the server side, `handle-inspector-eval-click` already distinguishes ordinary association creation from connect-snapshot submissions: for snapshot submissions it builds a snapshot object, logs request-correlated phases, and opens the snapshot pane rather than a normal association pane.

So the real gap is now very narrow:

**what exists**

* request-id logging
* disconnect-aware client failure path
* connect snapshot pane machinery

**what is still missing**

* a **failure-path materialization** that survives the disconnect boundary

In other words: the request should become a bounded inspectable object **before** success is known, so that “connection closed before pane opened” is itself viewable as first-class state, not only as console/server-log advice. That is a direct **running image coherence** issue in McDermott’s sense: preserve explicit, inspectable coherence/debug state across image and communication boundaries instead of forcing reconstruction from ad hoc logs. 

I would name the slice like this:

* **Topic:** Running image coherence
* **Bridge page:** McDermott Running Image Coherence Crosswalk
* **New inspectable object/page:** Connect request evidence
* **Failure subtype:** WebSocket disconnect before acknowledgement

Codex brief:

```text
Add a durable topic "Running image coherence" and wire it above:
- "A framework for maintaining the coherence of a running Lisp"
- "McDermott Running Image Coherence Crosswalk"

Then implement a first-class inspectable object for request-correlated Connect failures:
- create a bounded "connect request evidence" object at submit boundary
- key it by request id
- persist enough state to inspect after reconnect
- classify "websocket disconnect before acknowledgement" separately from generic pane-open timeout
- make the inline browser error link/open that evidence object when possible, instead of only saying "See console/server log for request id ..."

Preserve the existing connect-snapshot success path and extend it to the failure path.
```
