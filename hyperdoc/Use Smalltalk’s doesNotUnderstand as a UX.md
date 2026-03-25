# Use Smalltalk’s `doesNotUnderstand:` as a UX and debugging model

[…], but I would not do it as a global, magical fallback.

Smalltalk’s `doesNotUnderstand:` is a good model for the **user-facing behavior** you want:

* the system does not crash immediately
* the failed message send becomes an inspectable object
* you can see selector, receiver, arguments, and context
* the failure can be routed into tooling instead of killing the session

That is very close to what HyperDoc should do at the Zotero boundary.

In Common Lisp/CLOS, the nearest analogue is not `doesNotUnderstand:` itself, but the protocol around:

* `no-applicable-method`
* `no-next-method`
* `slot-missing`
* ordinary condition handling

For your current case, the relevant one is `no-applicable-method`: a generic function was called, but there was no method for the actual arguments. That is exactly the shape of:

* `ZOTERO-QUERY-ATTEMPT-ROWS-OF`
* called with `NIL`

So yes: **you could adopt a DNU-like policy here**.

But I would structure it like this:

## What to adopt

Adopt the **semantics** of DNU:

* convert a protocol failure into a first-class inspectable failure object
* preserve the attempted operation
* preserve receiver and arguments
* preserve source context
* keep the server alive

## What not to adopt

Do **not** make the whole Lisp image behave like Smalltalk DNU for everything.

That would be too broad and too dangerous, because:

* it can hide real programming errors
* it can make debugging harder
* `NIL` is an ordinary Lisp object, not a special “unknown receiver”
* a global fallback would blur real bugs and expected unavailable-capability boundaries

## Best fit here

For the Zotero seam, the best pattern is:

### 1. Treat the Zotero query protocol as a boundary protocol

Examples:

* `zotero-query-attempt-rows-of`
* `zotero-query-attempt-error-of`
* `zotero-query-attempt-metadata-of`

### 2. Never let that protocol operate on raw `NIL`

Instead, normalize lookup results into one of:

* a real query-attempt object
* a `zotero-query-unavailable`
* a `zotero-query-failure`
* a `zotero-query-missing`
* or similar Null Object / issue object

### 3. Make those objects implement the same protocol

So callers can ask for rows/errors/status without exploding.

That is actually better than classic `doesNotUnderstand:` because it is explicit and typed.

## Strong recommendation

I would prefer a **Null Object / failure-object protocol** over a literal DNU emulation.

So instead of:

* call `zotero-query-attempt-rows-of`
* get `no-applicable-method`
* trap that and synthesize a fallback

prefer:

* `lookup-zotero-collection` returns a real attempt object **or** a failure/unavailable object
* both satisfy the protocol
* inspectors know how to render both

That gives you:

* explicit semantics
* better testability
* fewer hidden control-flow surprises
* clearer domain boundaries

## Where DNU still helps conceptually

You can still use the Smalltalk idea for the **failure object shape**.

A good HyperDoc failure object here could contain:

* requested operation: `zotero-query-attempt-rows-of`
* receiver: `NIL`
* arguments
* higher-level intent: `lookup-zotero-collection "coachmark"`
* source page/hyperbook
* underlying condition
* repair hints
* degraded result status

That is basically a HyperDoc-flavored `MessageNotUnderstood`.

## So the answer is

**Yes, but locally and explicitly.**

Not:

* “teach the whole server to ignore missing methods”

But:

* “at the Zotero boundary, convert no-applicable-method / missing-attempt cases into inspectable protocol objects instead of fatal crashes”

If you want the shortest design rule:

**Use Smalltalk’s `doesNotUnderstand:` as a UX and debugging model, but implement it in HyperDoc as typed boundary failure objects, not as a global language-level fallback.**
