# Lookup

[…] In the repository shape you showed, there is no standalone ASDF system named `lookup`. What exists is a split concern: <a href="https://chatgpt.com/g/g-p-6928007ad8dc8191ac5152dfb0ca199b-hyperdoc-8470/c/69ba47bb-631c-838d-ae16-b699d66fc811">chatgpt</a>, <a href="https://dmx.ralfbarkow.ch/systems.dmx.webclient/#/topicmap/916248/topic/916290/related">related</a>

* the **base lookup condition/protocol** starts in `hyperbook` itself with `lookup-failure`, `page-lookup-failure`, `find-page`, and `lookup-path` in the core package API 
* the **structured lookup-issue model and UI** live in `hyperbook/explorer`, where `lookup-failures.lisp` is just one component of that system, alongside links, rendering, HTML books, etc. 
* the **HyperDoc-specific repair layer** lives in `hyperdoc/explorer`, where `lookup-repairs.lisp` is likewise just one component of that system.

So today, “lookup” is not an ASDF subsystem boundary. It is a cross-cutting concern spread across `hyperbook`, `hyperbook/explorer`, and `hyperdoc/explorer`.

My read is that **a standalone system could make sense, but not as one monolithic `lookup` bucket**. The code already shows a natural layering:

1. `hyperbook` keeps the minimal resolution protocol and failure conditions. 
2. `hyperbook/explorer` adds the reusable, structured issue model: `lookup-issue`, `page-lookup-issue`, `make-page-lookup-issue`, `enrich-lookup-issue`, `lookup-issues-of`, status tracking, and the generic inspection views. That is the strongest candidate for extraction into something like `hyperbook/lookup` or `hyperbook/lookup-issues`. 
3. `hyperdoc/explorer` does not look generic enough to belong in that same subsystem. It defines things like `fedwiki-publication-probe`, `hyperdoc-authoring-scaffold-plan`, page-template generation, and scaffold writing into the `hyperdoc/` tree. That is plainly HyperDoc-specific repair logic, not general lookup infrastructure. 

So my recommendation is:

* **No**, `lookup` should not become a single standalone ASDF system in its current shape.
* **Yes**, the reusable part should probably be carved out as its own subsystem, but specifically the **issue model/protocol layer** from `hyperbook/explorer/lookup-failures.lisp`.
* Then `hyperdoc/explorer/lookup-repairs.lisp` should stay an extension system on top of that, because it is tightly coupled to HyperDoc publishing, topics, and authoring scaffolds.

In other words: the right boundary is not `lookup`; it is more like:

* `hyperbook/lookup` = generic lookup issue objects, statuses, repair hooks, generic views
* `hyperdoc/lookup-repairs` = HyperDoc-specific enrichment, publication probes, scaffold plans

That would align the ASDF boundaries with the code’s actual abstraction layers much better than a vague standalone `lookup` system.
