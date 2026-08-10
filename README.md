# HyperDoc

Hypertext documentation system based on [html-inspector-views](https://codeberg.org/khinsen/html-inspector-views).

## Running a Web server for the HyperDoc catalog

The basic command for SBCL is:
```
sbcl --no-userinit \
     --eval '(require :asdf)' \
     --eval '(asdf:load-system "hyperdoc")' \
     --eval '(asdf:load-system "hyperbook/server")' \
     --eval '(hyperbook/server:serve-catalog)'
```

This will serve a catalog containing a single HyperDoc, the one for HyperDoc itself. In practice, you will load additional systems providing HyperDocs, before the last `--eval` line.

## License

[BSD](./LICENSE)

Copyright (c) 2025-2026 Konrad Hinsen

The SVG icons in the directory [assets/hyperdoc/icons](./assets/hyperdoc/icons) are from the [Font Awesome](https://fontawesome.com) collection, and are subject to its [license](https://fontawesome.com/license/free).
