# HyperDoc Goldberg Programmer-as-Reader Zettel Slice

This bundle rewrites Adele Goldberg's 1987 paper **Programmer as Reader** as a HyperDoc-compatible Zettel slice.

## Local provenance

This local copy was imported from the FedWiki page asset:

`/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/programmer-as-reader/`

Source slug: `programmer-as-reader`.

It contains:

- a loadable ASDF system: `hyperdoc-goldberg-programmer-as-reader.asd`
- code objects for topics, reader questions, and operations under `src/`
- five authored HyperDoc pages under `pages/`
- a smoke-test system: `hyperdoc-goldberg-programmer-as-reader/test`

## Load

```lisp
(asdf:load-system :hyperdoc-goldberg-programmer-as-reader)
```

## Inspect the slice

```lisp
(hyperdoc-goldberg-programmer-as-reader:goldberg-zettel-summary)
(hyperdoc-goldberg-programmer-as-reader:goldberg-reader-question-demo :what-is-that)
(hyperdoc-goldberg-programmer-as-reader:goldberg-reader-question-matrix)
```

## Register topics into a loaded HyperDoc image

Registration is explicit. Loading the ASDF system does **not** silently mutate a host HyperDoc registry.

```lisp
(hyperdoc-goldberg-programmer-as-reader:register-goldberg-topics-into-hyperdoc)
```

If `HYPERDOC::MAKE-TOPIC` is unavailable, the function returns an explicit `:unavailable` report.

## Materialize pages into a HyperDoc tree

```lisp
(hyperdoc-goldberg-programmer-as-reader:materialize-goldberg-hyperdoc-pages
  :destination #P"/path/to/hyperdoc/")
```

## Run smoke tests

```lisp
(asdf:test-system :hyperdoc-goldberg-programmer-as-reader/test)
```

## Design boundary

The ASDF system is intentionally data-first and side-effect-light:

- topics are plain inspectable objects until explicitly registered;
- pages are static authored templates until explicitly materialized;
- reader questions are operations, not hidden commands;
- HyperDoc integration is optional at load time.
