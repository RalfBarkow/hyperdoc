# Deferred references

HyperDoc has already moved part of the way there: authored expression-bearing elements now render as **deferred references** with metadata such as expression source, package, requested view, and source page, and the render-safety smoke test asserts that opening a page must not execute those expressions during normal render.   

But the current explicit-evaluation path is still **in-process**. `parse-and-eval`, `eval-parsed`, and `make-expr-link` ultimately call `eval` in the server image, and the deferred reference model still carries a thunk that is evaluated later inside that same Lisp runtime. That improves render stability, but it is not yet a real sandbox.  

So the contract should become:

**Render-time**

* parse nothing beyond what is needed to classify the construct,
* never execute authored code,
* always emit a latent inspectable reference.

**Inspection-time**

* show what would be run before anything runs,
* show the uncertainty of that analysis,
* require an explicit user action to move to trial execution.

**Trial-execution-time**

* execute outside the main server image,
* under resource limits and capability limits,
* return a structured result object, not a raw crash.

The important nuance is the “dependency graph” requirement. In Common Lisp, a full exact execution graph is generally impossible to know ahead of time because of macros, generic dispatch, dynamic variables, runtime function lookup, `eval`, reader behavior, and side effects. So HyperDoc should present this as an **execution plan / dependency estimate**, not as a mathematically complete graph. A good inspectable plan would include:

* raw source string,
* parsed form,
* package,
* macroexpansion,
* top-level operator symbols,
* referenced globals/specials,
* reachable function and generic-function roots,
* known external capability touches such as file, network, process, ASDF, git, Zotero bridge,
* confidence notes like “dynamic dispatch unresolved” or “contains EVAL / FUNCALL / APPLY / reader effects.”  

I would model the flow as four inspectable object types:

**1. `authored-expression-reference`**
Already close to what you have now: source, label, kind, package, requested view, source page. 

**2. `authored-expression-plan`**
New. Produced without execution. Contains parse result, macroexpansion preview, symbol graph, capability flags, and risk classification.

**3. `authored-expression-trial`**
New. A request object that runs the expression in a worker.

**4. `authored-expression-result` / `authored-expression-failure`**
New. Structured output, stdout/stderr, timing, memory, side-effect report if available, and bounded failure details.

That gives you the separate view you want. For every expr-bearing link or tag, the UI should first open something like:

* **Plan**
* **Dependencies**
* **Capabilities**
* **Trial Result**
* **Source**

Only **Trial Result** should actually run code.

For safety, the worker must be outside the main image. A same-image “trial” is still not safe. The right boundary is an OS process or container with:

* time limit,
* memory limit,
* restricted filesystem,
* no ambient network by default,
* no inherited server sockets,
* explicit allowlist for operations if needed.

In other words:

**deferred click-to-evaluate is a UI contract;
process isolation is the security contract.**

I would also split authored constructs into policy tiers.

**Tier A: passive references**
`a[page]`, `a[hyperbook]`, normal `href`. These stay render-safe.

**Tier B: analyzable expr references**
`a[expr]`, `a[expr][view]`, `<value-of>`, `<html-expr>`, `<html-generator>`, `<view-transclusion>`, `<source-of-class>`, `<source-of-function>`. These should always open a plan first, not execute directly. Current HyperDoc already treats several of these as latent during normal render, which is the right base to build on. 

**Tier C: forbidden in untrusted mode**
Expressions whose plan shows obvious dangerous capabilities or unanalyzable forms such as nested `eval`, process spawning, uncontrolled I/O, or broad package mutation. These should be blocked or require an admin-only override.

I would phrase the new rule like this:

**An authored expr is unknown code. HyperDoc may render it, classify it, and analyze it, but must not execute it in the main render path, and must not treat an in-image click as a security sandbox.**

That is also consistent with the current smoke-test direction: the repo now explicitly tests that authored HTML opens without executing embedded expressions and that deferred metadata is present in the rendered content.  

The only thing I would soften is “dependency graph must be clear.” I would instead say:

**HyperDoc must show the best available execution plan, with uncertainty made explicit.**

That is achievable. A total dependency graph is often not.

The next good implementation slice would be:

* add `authored-expression-plan` objects and views,
* make expr clicks open **Plan** first instead of evaluating,
* add a worker-based **Trial Result** path,
* keep result/failure bounded as inspectable objects rather than crashing the server.
