# HyperDoc reconstruction of *The Roots of Lisp*

This bundle separates four layers that are often conflated:

1. **Graham's semantic core** — seven primitive operators plus `lambda` and
   `label` notation.
2. **The paper's derived library** — `null.`, `and.`, `not.`, `append.`,
   `pair.`, `assoc.`, `eval.`, `evcon.`, and `evlis.`.
3. **The Stanford-style adapter** — parser boundary, top-level `defun`,
   persistent environment, `list`, generated c[ad]+r accessors, and error
   handling.
4. **HyperDoc projection** — authored pages, topics, system-scoped
   `defexample` registrations, evaluation reports, and bounded traces.

## Repository placement

Place the directory and ASD file at the HyperDoc repository root:

```text
hyperdoc/
  hyperdoc-graham-roots-of-lisp.asd
  hyperdoc-graham-roots-of-lisp/
    src/
    pages/
    tests/
```

The outer directory shown in this bundle already has that shape: copy the ASD
file to the repository root and copy the `hyperdoc-graham-roots-of-lisp/`
directory beside it.

## First live-image evaluation

From the SLY mREPL:

```lisp
(asdf:load-system :hyperdoc-graham-roots-of-lisp)
```

Run the direct recursive definition:

```lisp
(defparameter *roots-direct*
  (hyperdoc-graham-roots-of-lisp:roots-direct-subst-report
   :event-limit 2000))

(clog-moldable-inspector:clog-inspect :object *roots-direct*)
```

Then run the actual Surprise: the object-language `eval.` evaluates the object-
language `subst` call.

```lisp
(defparameter *roots-surprise*
  (hyperdoc-graham-roots-of-lisp:roots-surprise-report
   :event-limit 5000))

(clog-moldable-inspector:clog-inspect :object *roots-surprise*)
```

Expected result:

```lisp
(A M (A M C) D)
```

Inspect `EVENTS-OF`, then look for these event kinds:

```text
:ATOM-LOOKUP
:NAMED-OPERATOR-REWRITE
:LABEL-BIND
:LAMBDA-BIND
:COND-TEST
:COND-SELECTED
:PRIMITIVE
```

## Materialize pages and topics

From the repository root:

```lisp
(hyperdoc-graham-roots-of-lisp:materialize-roots-hyperdoc-pages
 :destination #P"hyperdoc/")

(hyperdoc-graham-roots-of-lisp:register-roots-topics-into-hyperdoc)
```

The first operation copies eight authored HTML pages. The second registers nine
topics if `HYPERDOC::MAKE-TOPIC` is loaded. The two retrace topics are also
projected into the loaded Topics hyperbook for authored page links.

## Test

```lisp
(asdf:test-system :hyperdoc-graham-roots-of-lisp/test)
```

The development launcher loads
`hyperdoc-graham-roots-of-lisp/development-server`, a composition system that
depends on both `hyperdoc/server` and this standalone content system. Core
HyperDoc and production startup remain independent of the optional Roots
bundle.

The six registered examples are defined in `src/examples.lisp`; opening that
code page in HyperDoc renders the normal play affordance before every
top-level `hyperdoc:defexample` form. The named-call example returns a
comparison between `:mccarthy-paper` and `:graham-corrected`; the historical
failure is captured rather than signalled from the example. The dynamic-capture
example returns `INNER`, preserving the evaluator's historical dynamic scope.

## Important semantic qualification

The evaluator's explicit association list implements the historical dynamic
environment. It is not a model of modern Common Lisp lexical closures.

The Common Lisp reader is used only to obtain cons-tree data, with
`*READ-EVAL*` disabled. Object-language forms are never passed to `CL:EVAL`.
