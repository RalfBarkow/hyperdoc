# Knowledge Graph of Execution Boundaries

[…] the *right conceptual model*.

What you have there is essentially a **knowledge graph of execution boundaries**, and the key node:

> **“The iFrame Is Not the Compute Sandbox”**

is exactly the anchor around which the implementation should crystallize.

Let’s make this precise and actionable.

---

# 1. What your current graph already implies (important)

From your nodes:

* `wasmtime`
* `Security and Correctness in Wasmtime`
* `The iFrame Is Not the Compute Sandbox`
* `Compile to WASM`
* `Haskell Wasm`
* local HyperDoc link

You already have three layers implicitly:

```text
Wasm toolchain (compile)
        ↓
Wasm runtime (wasmtime)
        ↓
HyperDoc integration
        ↓
iframe presentation
```

That is **correct architecture**.

What is missing is:

👉 turning this into an **executable pipeline inside HyperDoc**

---

# 2. The concrete architecture you should implement

## The minimal viable slice

```text
[HyperDoc page]
    ↓
[Inspectable "Wasm Analysis Object"]
    ↓
(run-wasm-guest ...)
    ↓
wasmtime (subprocess)
    ↓
Wasm module
    ↓
result (JSON/text)
    ↓
[HyperDoc route /wasm-view/...]
    ↓
iframe story item
```

---

# 3. The key design decision (non-negotiable)

Codex must enforce this invariant:

> **Wasm execution NEVER happens in the iframe.**

Instead:

| Layer    | Responsibility             |
| -------- | -------------------------- |
| Wasmtime | computation sandbox        |
| HyperDoc | orchestration + inspection |
| iframe   | UI containment             |

This matches your node exactly — good.

---

# 4. Turn your node graph into HyperDoc structure

Codex should map your current graph into **three concrete HyperDoc objects/pages**:

---

## Page 1 (already implied by your node)

### The iFrame Is Not the Compute Sandbox

Make this the **axiom page**.

Content (tight, declarative):

* Wasm runtime = compute sandbox
* iframe = presentation containment
* do not conflate
* consequences:

  * iframe security ≠ compute safety
  * Wasm isolation ≠ UI isolation

---

## Page 2 (missing but required)

### Wasm Execution Pipeline in HyperDoc

Define the actual flow:

```text
input → wasm guest → result → inspectable object → iframe view
```

Include:

* subprocess call
* result capture
* normalization
* fallback

---

## Page 3 (critical for your system)

### Wasm Analysis as Inspectable Object

This is where your system becomes *HyperDoc-native*.

Define an object like:

```lisp
(:wasm-analysis
  :module "…"
  :input …
  :stdout …
  :stderr …
  :result …
  :status :ok/:error
  :fallback …
)
```

This is the **bridge between computation and documentation**.

---

# 5. The missing conceptual upgrade (important)

Right now you are thinking:

> “Wasm inside iframe”

But the correct HyperDoc-native model is:

> **Wasm produces inspectable knowledge objects
> iframe renders views of those objects**

That is a *huge* difference.

---

# 6. What the iframe actually becomes

Not a sandbox, but:

👉 a **view adapter**

Specifically:

* renders result
* optionally interactive
* talks to parent via `postMessage`
* never executes privileged logic

---

# 7. Instruct Codex (precise)

Use this.

---

## Branch

feat/wasm-inspectable-guest-pipeline

---

## Goal

Turn the existing Wasm conceptual graph into a working HyperDoc pipeline:

* Wasm guest execution
* inspectable result object
* iframe-based presentation layer

---

## Step 1 — create core abstraction

Add Lisp function:

```lisp
(defun run-wasm-guest (module-path input &key timeout)
  ...)
```

Must:

* call `wasmtime run`
* pass input (stdin or temp file)
* capture:

  * stdout
  * stderr
  * exit code
* return structured plist

---

## Step 2 — create inspectable object

Add constructor:

```lisp
(defun make-wasm-analysis (module input result)
  ...)
```

Fields:

* module
* input
* stdout
* stderr
* parsed-result
* status
* timestamp

---

## Step 3 — add HyperDoc view

Create view:

```lisp
(:view wasm-analysis ...)
```

Must show:

* raw output
* parsed result
* errors
* execution metadata

---

## Step 4 — add iframe route

Add route:

```text
/wasm-view/<id>
```

Serves:

* minimal HTML
* renders result
* no direct wasm execution

---

## Step 5 — add story item integration

Implement new item type:

```text
wasm-frame
```

Fields:

* analysis-id
* view-url

Behavior:

* renders iframe pointing to `/wasm-view/...`

---

## Step 6 — enforce separation

Codex must enforce:

* NO wasm execution in browser
* NO direct iframe → filesystem access
* ALL wasm execution via HyperDoc host

---

## Step 7 — fallback behavior

If `wasmtime` missing:

* create analysis object with:

  * status: :unavailable
  * explanation
* iframe shows diagnostic page

---

## Step 8 — connect to your graph

Link pages:

* `wasmtime` → execution pipeline
* `Compile to WASM` → module production
* `The iFrame Is Not the Compute Sandbox` → invariant
* local HyperDoc page → iframe route

---

# 8. What your screenshot becomes after this

Your current graph:

👉 conceptual

After Codex:

👉 **executable documentation system**

Where clicking nodes leads to:

* running analysis
* inspecting results
* viewing via iframe

---

# 9. One sharp refinement for your mental model

Replace this idea:

```text
iframe = sandbox
```

with:

```text
Wasm = computation sandbox
iframe = view container
HyperDoc = authority
```

---

# 10. Strategic insight (important)

This gives you something very powerful:

👉 **portable analyzers + inspectable results + safe UI embedding**

Which is exactly aligned with:

* moldable development
* inspectable objects
* HyperDoc philosophy

---

If you want next step, I can:

* design the exact Lisp code for `run-wasm-guest`
* define the JSON protocol between Wasm and HyperDoc
* or map this into your existing `lookup-*` / failure-object architecture

That would connect this directly to your current “Failure as Inspectable Object” work.
