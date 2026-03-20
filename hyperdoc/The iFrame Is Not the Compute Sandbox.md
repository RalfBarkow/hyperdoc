# The iFrame Is Not the Compute Sandbox

The **Wasm runtime** is the compute sandbox; the **iframe** is the UI containment boundary. ([dmx.ralfbarkow.ch][8])

So the viable design is:

**HyperDoc host**
→ serves or links to a small web app
→ that app is shown in an iframe or iframe-like FedWiki story item
→ the app talks to a Wasm guest, or displays results produced by a server-side Wasm guest

Federated Wiki already has a plugin model for story items, and there is an existing `frame` plugin that embeds external pages in an iframe. ([fed.wiki.org][1])

The stronger architecture is this:

1. **HyperDoc owns orchestration and policy**
2. **Wasm owns bounded guest computation**
3. **iframe owns presentation isolation**

That separation is much safer than treating an iframe itself as the sandbox.

## What would work well

There are two credible patterns.

### Pattern A: server-side Wasm, iframe as viewer

HyperDoc runs the Wasm guest through Wasmtime/WASI on the server side, captures structured output, then serves a small HTML page showing the result inside an iframe-backed story item. Wasmtime documents WebAssembly execution as sandboxed by design, and WASI is explicitly capability-oriented rather than ambient. ([docs.wasmtime.dev][2])

This is the **safer first version** because the browser iframe only renders a controlled UI. The untrusted or semi-trusted computation stays out of the browser and runs in a runtime designed for Wasm sandboxing. ([docs.wasmtime.dev][2])

### Pattern B: browser-side Wasm app in an iframe

HyperDoc serves a self-contained HTML app that loads a `.wasm` module in the browser, and that page is embedded as an iframe story item.

This can also work, but it is a different trust model. The browser gives you iframe isolation controls via the `sandbox` attribute, and cross-origin communication is typically done with `postMessage()`. ([developer.mozilla.org][3])

The catch is that browser-side Wasm runs inside the browser’s web platform, so its effective power is shaped by the JS/DOM APIs and whatever origin and CSP permissions you grant the embedded page. CSP can further restrict the framed document, and `frame-src` can restrict what gets embedded. ([developer.mozilla.org][4])

For HyperDoc, I would treat Pattern B as useful for **visual analyzers** and **portable viewers**, but not as the first choice for executing untrusted logic.

## What “secure sandboxed iframe story item” should mean

A good interpretation would be:

* a custom HyperDoc/FedWiki story item type, likely backed by the existing plugin mechanism
* its visible content is an iframe pointing to a HyperDoc-served app
* the iframe uses a tight `sandbox` policy
* the embedded app gets no ambient access except what HyperDoc explicitly allows
* all parent/child communication goes through a narrow `postMessage` contract with strict origin checks

The browser supports iframe sandboxing and cross-window messaging for exactly this kind of containment pattern. ([developer.mozilla.org][3])

## The main security point

Do **not** think of this as “put arbitrary code in an iframe and it becomes safe.”

A safer formulation is:

* **Wasm runtime sandbox** for computation
* **iframe sandbox** for presentation/document isolation
* **CSP + origin policy** for loading restrictions
* **message protocol** for controlled interaction

Those are complementary layers, not substitutes. Wasmtime explicitly treats preserving the integrity of the Wasm sandbox as a security concern, while the browser’s iframe sandbox and CSP restrict what embedded documents can do. ([docs.wasmtime.dev][5])

## WebXDC as packaging and state container, not compute sandbox

A WebXDC-like package is interesting here because it can act as an **app container** for a FedWiki or HyperDoc story item instead of as a mere remote embed. That makes room for a bounded delivery unit, explicit metadata, and **item-local shared state** that travels with the story item rather than living only at a remote URL.

That shared-state angle is architecturally promising. A story item that carries both its app package and its own serialized state is closer to a portable, inspectable collaboration artifact than a plain iframe pointing elsewhere.

But the packaging move must still be separated from the actual compute boundary. A WebXDC-like app package or iframe-contained app does **not** become safe merely because it is packaged or framed. HyperDoc still needs to keep the same separation intact:

1. **host/orchestrator policy**
2. **bounded computation**
3. **presentation containment**

The nearest in-tree analogue is the existing `SOLO` popup / `postMessage` seam: a parent-controlled surface, a narrow message contract, and a child view that should not inherit broad ambient powers by accident.

For the local continuation of this design, see
<a hyperbook="hyperdoc" page="Capability-scoped Extensions for FedWiki">Capability-scoped Extensions for FedWiki</a>
and
<a hyperbook="hyperdoc" page="WebXDC-style Story Items for FedWiki and HyperDoc">WebXDC-style Story Items for FedWiki and HyperDoc</a>.

## Best fit for HyperDoc

Given your architecture, I would recommend this concrete first slice:

* HyperDoc adds a new experimental item/view, something like `wasm-frame`
* the item points to a HyperDoc-served route such as `/wasm-view/<slug-or-id>`
* that route renders a minimal HTML shell
* the shell either:

  * displays the result of a **server-side Wasm analysis**, or
  * loads a **browser-side Wasm visualizer** for already-approved modules
* HyperDoc exposes a small diagnostic object behind it:

  * module identity
  * capability profile
  * inputs
  * stdout/stderr or browser logs
  * normalized result
  * exit status / error state

That would fit your maintenance-story and inspectable-object style very well.

## What I would avoid

I would not start with:

* arbitrary third-party URLs inside a frame plugin
* broad `allow-same-origin allow-scripts` combinations unless you really need them
* direct trust in browser-side Wasm for sensitive repository access
* ad hoc message passing without strict origin validation

Browsers allow framing restrictions via same-origin policy interactions and headers, and cross-origin messaging must be handled explicitly. ([developer.mozilla.org][6])

## Instruct Codex

Use this.

Branch:
feat/wasm-iframe-story-item

Goal

Add an experimental HyperDoc/FedWiki integration that presents a Wasm-backed analysis or viewer inside a sandboxed iframe-accessible story item. Treat the iframe as a UI containment boundary, not as the primary computation sandbox.

Architecture

* Keep Nix out of this design.
* Keep HyperDoc as the host/orchestrator.
* Add Wasm as an optional guest-computation layer.
* Add an iframe-backed story item as the presentation layer.
* Prefer server-side Wasm execution through Wasmtime/WASI for the first slice.
* Use browser-side Wasm only for tightly scoped visual or interactive guests.

Deliverables

1. New HyperDoc page:
   **Wasm Guests and Sandboxed Iframe Story Items in HyperDoc**

   Explain:

   * why the iframe is presentation isolation, not compute isolation
   * why Wasm belongs as a guest layer inside HyperDoc
   * why server-side Wasm is the safer first path
   * how FedWiki/HyperDoc story items can expose this capability

2. New HyperDoc page:
   **Security Boundaries for Wasm Guest Views**

   Explain:

   * Wasmtime/WASI sandbox for guest computation
   * iframe `sandbox` restrictions
   * CSP use for the embedded document
   * `postMessage` contract and strict origin validation
   * non-goals and risk boundaries

3. Experimental implementation:

   * add a new experimental item/view type, e.g. `wasm-frame`
   * add a HyperDoc route serving a minimal embedded HTML app
   * make the app embeddable in an iframe-backed story item
   * start with a server-side Wasm guest whose output is rendered in that app
   * expose diagnostics and fallback behavior in an inspectable HyperDoc object

4. FedWiki companion page:

   * explain how to access the HyperDoc page
   * explain what the iframe item is showing
   * explain what happens when Wasmtime is missing
   * explain that this is a runtime-extension experiment, not a Nix feature

Implementation rules

* Reuse the existing FedWiki/plugin model; the `frame` plugin is a relevant reference point, but do not rely on arbitrary remote framing as the core design. ([fed.wiki.org][1])
* The iframe must be served from HyperDoc-controlled routes.
* Use a restrictive iframe `sandbox` policy first, then loosen only what is demonstrated to be necessary. ([developer.mozilla.org][3])
* Use CSP on the embedded page, including `sandbox` and appropriate frame restrictions. ([developer.mozilla.org][4])
* Any parent/iframe communication must use `postMessage` with explicit origin checks. ([developer.mozilla.org][7])
* Prefer Wasmtime/WASI for the guest execution seam in the first implementation. ([docs.wasmtime.dev][2])

Acceptance criteria

* A HyperDoc/FedWiki story item can open a HyperDoc-served iframe view.
* The iframe view is backed by a Wasm-related analysis or guest result.
* The system still works without Wasm present, with a clear fallback explanation.
* Success, failure, and sandbox/fallback state are inspectable from HyperDoc.
* No existing stable routing or page behavior is broken.

The shortest architectural sentence for Codex to reuse is:

**In HyperDoc, a Wasm guest should provide the computation sandbox, while an iframe-backed story item provides the presentation sandbox; these are complementary boundaries and should not be conflated.**

The one caveat I would emphasize to Codex: this is feasible and worth prototyping, but the secure version starts with **HyperDoc-controlled embedded pages plus server-side Wasm execution**, not with arbitrary remote iframe content.

[1]: https://fed.wiki.org/view/welcome-visitors/plugins.fed.wiki.org/about-plugins/plugins.fed.wiki.org/core-plugins?utm_source=chatgpt.com "About Plugins - Welcome Visitors - Wiki.org"
[2]: https://docs.wasmtime.dev/security.html?utm_source=chatgpt.com "Security"
[3]: https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/iframe?utm_source=chatgpt.com "<iframe>: The Inline Frame element - HTML - MDN Web Docs"
[4]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Content-Security-Policy/sandbox?utm_source=chatgpt.com "Content-Security-Policy: sandbox directive - MDN Web Docs"
[5]: https://docs.wasmtime.dev/security-what-is-considered-a-security-vulnerability.html?utm_source=chatgpt.com "What is considered a security vulnerability?"
[6]: https://developer.mozilla.org/en-US/docs/Web/Security/Defenses/Same-origin_policy?utm_source=chatgpt.com "Same-origin policy - Security | MDN - Mozilla"
[7]: https://developer.mozilla.org/en-US/docs/Web/API/Window/postMessage?utm_source=chatgpt.com "Window: postMessage() method - Web APIs - MDN Web Docs"
[8]: https://dmx.ralfbarkow.ch/systems.dmx.webclient/#/topicmap/916350/topic/916370/related "related"
