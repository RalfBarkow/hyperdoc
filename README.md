# hyperdoc

Hypertext documentation system based on [html-inspector-views](https://codeberg.org/khinsen/html-inspector-views).

## Running a Web server for the HyperDoc catalog

The basic command for SBCL is:
```
sbcl --no-userinit \
     --eval '(require :asdf)' \
     --eval '(asdf:load-system "hyperdoc/server")' \
     --eval '(hyperdoc/server:serve-catalog)'
```

This will serve a catalog containing a single HyperDoc, the one for HyperDoc itself. In practice, you will load additional systems providing HyperDocs, before the last `--eval` line.

## License

[BSD](./LICENSE)
