# HyperDoc

Hypertext documentation system based on [html-inspector-views](https://codeberg.org/khinsen/html-inspector-views).

## Running a Web server for the HyperDoc catalog

The basic command for SBCL is:
```
sbcl --no-userinit \
     --eval '(require :asdf)' \
     --eval '(asdf:load-system "hyperdoc/server")' \
     --eval '(hyperbook/server:serve-catalog)'
```

This will serve a catalog containing a single HyperDoc, the one for HyperDoc itself, with explorer methods loaded for navigation.

## Docs Topic Coverage Gate

To validate `expr="(hyperdoc::...)"` references for the SD-image docs cluster:

```
nix develop --command sbcl --no-userinit --non-interactive \
  --load tools/check-topic-coverage.lisp
```

To check an explicit set of pages instead of the default cluster:

```
nix develop --command sbcl --no-userinit --non-interactive \
  --load tools/check-topic-coverage.lisp -- hyperdoc/page-a.html hyperdoc/page-b.html
```

When explicit page paths are provided, only those pages are checked.

## License

[BSD](./LICENSE)

Copyright (c) 2025 Konrad Hinsen

The SVG icons in the directory [assets/hyperdoc/icons](./assets/hyperdoc/icons) are from the [Font Awesome](https://fontawesome.com) collection, and are subject to its [license](https://fontawesome.com/license/free).
