# Install steps

Run this from a HyperDoc SLY MREPL:

```lisp
(asdf:load-system :hyperdoc/fedwiki-asdf-assets)

(in-package :hyperdoc)

(defparameter *metagraph-spec*
  (make-metagraph-jsonld-fluree-asset-spec
   :asset-root #P"/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/"))

(page-asdf-asset-workflow
 *metagraph-spec*
 :clean t
 :force t
 :test t
 :inspect t
 :zip t)
```

Workflow order:

1. Write the flat ASDF asset directly into the FedWiki page assets directory.
2. Load the written `.asd` with `asdf:load-asd` using its exact pathname.
3. Load and test the generated ASDF system in the same image.
4. Register and open CLOG inspector views for `mg-topicmap-projection`.
5. Render the three DM6 Topic Map HTML pages.
6. Create the deployable ZIP from the already-tested flat directory.

If the CLOG inspector layer is not loaded, `mg-ensure-inspector-views` returns
an `mg-inspector-views-diagnostic` object instead of entering the debugger.
Load `:hyperdoc/server`, then call the workflow again.
