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

## Fresh interactive Lisp image

Run `nix develop`, then `hyperdoc-sly` from this repository (or a subdirectory).
The launcher creates one fresh SBCL, loads the Slynk bundled with the shell's
SLY, and attaches a clean Emacs/SLY session. The banner reports repository,
branch, commit, implementation/version, and the actual `127.0.0.1` port allocated
by the operating system. Additional SLY clients can attach to that same port.
No application systems, SBCL init files, or personal Slynk init files are loaded.

A dedicated pipe carries the endpoint after `slynk:create-server` returns;
startup waits for readiness, EOF on failure, or a 120-second failure deadline.
The launcher owns both child processes. Closing the initial Emacs or sending
SIGINT, SIGTERM, or SIGHUP to the launcher shuts down its image and disconnects
all clients. Disconnecting an individual SLY connection leaves the listener
available. Each new launcher invocation creates a new image. Non-interactive
fresh-process tests remain separate from this interactive image.

Run the headless contract tests with:

```sh
nix develop --command python3 tests/test_hyperdoc_sly.py
```

These run the production launcher and editor bootstrap with batch Emacs,
connect multiple real SLY clients, inspect the bound listener address and port,
verify shared state and process identity, and check banner provenance and
shutdown. They do not validate GUI window or mREPL presentation.

### Manual two-editor acceptance

1. Run `hyperdoc-sly` and read the advertised host and port.
2. In the initial mREPL evaluate:
   ```lisp
   (defparameter *multi-client-witness* (gensym "WHITE-IMAGE-"))
   ```
3. In Spacemacs use `M-x sly-connect`, host `127.0.0.1`, and the advertised port.
4. Evaluate in Spacemacs:
   ```lisp
   (list :witness *multi-client-witness*
         :machine (machine-instance)
         :implementation (lisp-implementation-type)
         :version (lisp-implementation-version)
         :directory (uiop:getcwd))
   ```
   Compare the witness with the original mREPL, then evaluate:
   ```lisp
   (setf *multi-client-witness* :changed-from-spacemacs)
   ```
5. Evaluate `*multi-client-witness*` in the original mREPL and verify
   `:CHANGED-FROM-SPACEMACS`. Disconnect Spacemacs and reconnect to the same port.
6. Remove the witness with `(makunbound '*multi-client-witness*)`, or close the
   launcher session. Restarting must not retain the witness. Persist intended
   definitions in repository sources before ending an interactive session.

## License

[BSD](./LICENSE)

Copyright (c) 2025-2026 Konrad Hinsen

The SVG icons in the directory [assets/hyperdoc/icons](./assets/hyperdoc/icons) are from the [Font Awesome](https://fontawesome.com) collection, and are subject to its [license](https://fontawesome.com/license/free).
