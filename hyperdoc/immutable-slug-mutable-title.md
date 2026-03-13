At least five things must become true.

First, **page identity must stop being the title**. In the core HyperBook model, each page has an `id` and lookup is by page id.  But for HTML/Markdown text pages, the loader currently sets that page id from the first `title`/`h1`/`h2`… element and stores the page under that title. So today a rename is literally an id change, not a metadata edit.  In the FedWiki-twin workflow, the localhost slug is likewise derived from the title.  If you want rename-in-journal, you need an immutable page key that survives title changes.

Second, **title must become replayable page state**. Right now the journal discipline is: the visible `story` must be reconstructable by replaying `journal`, with `create` first and later actions recorded in journal order.  The replay/checking model is explicit that integrity means “does replay produce the current page?”, and the currently documented supported action shapes are `create`, `add`, `edit`, `move`, and `remove`.  A rename can only be “part of the journal” if title and any lookup-relevant metadata are inside that replayed state, not outside in a filename or loader convention.

Third, **the action vocabulary must gain an explicit rename operation**. Something like `rename-page`, `set-title`, or `retitle`, with clear semantics. At minimum it would need to say: page key stays the same; title changes from old to new; optional display-slug/alias metadata changes in a controlled way. Since replay is the truth criterion, the replay engine and checker must understand that action and still be able to reconstruct the current page state.

Fourth, **linking must target stable identity, not mutable labels**. Your current breakage happens because lookup is against the mutable title/id, so old links go red after a rename.  On the FedWiki side, your own workflow already moved toward the right pattern: prefer slug-keyed links and use title only as visible text.  The same principle must exist for HyperDoc pages: links should resolve by stable page key, while title is display metadata. If you still want old title-based references to work, then rename must also write an alias/redirect entry into replayable metadata.

Fifth, **the writable surface must actually be journal-backed**. HyperDoc text pages today are loaded from authored files, and the authoritative identity of an HTML page is reconstructed from the file content on reload.  That means a heading edit in Git is upstream of everything else. For rename to be “in the journal,” the system that owns the page must be a journaled object store, or HyperDoc must maintain its own journal layer above file loading. Otherwise the journal can only describe a downstream mirror, not the authoritative rename.

So the shortest honest answer is:

* stable immutable page key
* title as mutable metadata
* explicit rename action in the journal
* replay/checker support for that action
* links keyed to stable identity, with optional aliases
* an actually journaled source of truth for the page

And one more design point: for the FedWiki twin, the cleanest route is probably **immutable slug, mutable title**. Since your current workflow derives slug from title, slug churn turns every retitle into a path migration.  If slug becomes the durable key and title becomes journaled metadata, then rename stops being a lookup catastrophe and becomes the bounded operation you want.
