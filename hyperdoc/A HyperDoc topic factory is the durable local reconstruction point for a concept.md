# A HyperDoc topic factory is the durable local reconstruction point for a concept

Then the right mental model is **three layers**, not two:

1. **the concept**
2. **the HyperDoc authored topic factory / Topics HyperBook page**
3. **the DMX topic object**

That is the interplay Codex should preserve.

In your current HyperDoc design, the **Topics HyperBook** is built from **authored topic factories**. Those factories are durable functions that return topic objects with a stable key, canonical title, summary, and editorial references, and HyperDoc uses them to rebuild the topic-page surface. The repo is explicit that this authored topic-page surface is intentionally distinct from live DMX-backed runtime proxies.  

For your concrete example, the DMX side is a separate graph object: topic **917064**, type **`dmx.notes.note`**, value **“Encryption boundaries on the small web”**, with timestamp children and a composed child title topic **917059** via composition assoc **917067**. ([dmx.ralfbarkow.ch][1])

So I would describe the interplay like this:

## 1) What the topic factory is

A topic factory is **not merely a topic value**. In HyperDoc it is the **authored reconstruction point** for a topic. The repo says the important part is not only that the function returns a topic object; the function itself is the durable reconstruction point in the repository, and Topics HyperBook pages are rebuilt from those authored factories. 

For your small-web example, that factory is effectively:

* stable key: `encryption-boundaries-on-the-small-web`
* canonical title: `Encryption boundaries on the small web`
* summary
* references

That means the HyperDoc-side identity is not “whatever DMX currently says.” It is “the authored HyperDoc concept entry with its own stable local key.”

## 2) What the DMX reincarnation is

The DMX reincarnation is the **graph-native counterpart** of that same subject, but in DMX terms:

* DMX numeric topic id
* DMX type URI
* DMX title/value topics
* DMX associations and children
* timestamps
* topic-map placement

So the DMX object is **not the same runtime object** as the HyperDoc topic object. It is a **counterpart representation** of the same subject in a different ontology and storage model. HyperDoc’s own docs already separate “stable authored topic pages” from “live DMX-backed runtime-object surface.” 

## 3) What the bridge should mean

The clean formulation for Codex is:

* **HyperDoc topic factory** = durable local authored identity and reconstruction unit
* **Topics HyperBook page** = readable local documentary surface for that identity
* **DMX topic** = external graph counterpart / reincarnation
* **mapping** = explicit correspondence relation, not object identity collapse

So the bridge should be:

`HyperDoc stable key <-> DMX topic id`

not

`HyperDoc title == DMX title == identity`

The title may match today, but it is presentation. Identity should survive title changes.

## 4) If HyperDoc reads/imports a DMX topic and adds it to Topics HyperBook

This is the key part of your interruption.

If HyperDoc can read a DMX topic and then “add it to Topics HyperBook,” there are two possible designs.

### A. Proxy-only design

HyperDoc reads DMX live and exposes a page in Topics HyperBook directly from DMX data.

That would mean:

* the topic page is effectively a DMX-backed view
* no authored factory is created
* the Topics HyperBook becomes partly live, partly authored

This is possible, but it cuts against the current architecture, because the repo keeps the Topics HyperBook as a stable authored surface and treats DMX as a separate runtime-proxy surface.  

The risk is that:

* offline rebuild becomes weaker
* title changes in DMX can destabilize page routing
* your local authoring layer stops being the authoritative reconstruction layer

### B. Materialized-import design

HyperDoc reads DMX, then **materializes** an authored topic factory from the DMX topic.

This fits your architecture much better.

That would mean:

* DMX is a source
* HyperDoc generates or updates a topic factory
* Topics HyperBook remains authored and rebuildable
* the topic object also stores its DMX correspondence

This is much closer to how your repo already thinks about stable authored factories versus live proxies.  

## 5) Recommended model for Codex handover

I would recommend this exact rule:

**Import from DMX into Topics HyperBook by materializing a local authored topic factory, while preserving a live DMX proxy link as a secondary runtime surface.**

That gives you both:

* stable local documentation
* live graph correspondence

In concrete terms, an imported topic should have at least:

* `hyperdoc-stable-id`
  e.g. `encryption-boundaries-on-the-small-web`

* `canonical-title`
  e.g. `Encryption boundaries on the small web`

* `dmx-topic-id`
  e.g. `917064`

* `dmx-type-uri`
  e.g. `dmx.notes.note`

* `dmx-source-url`

* `summary`
  maybe imported, inferred, or left empty for later authoring

* `editorial-references`
  including the DMX URL and related local pages

* optional `live-proxy-entry-point`
  so the topic page can still open the live `dmx-topic-proxy`

## 6) Identity rule that matters most

The most important constraint is this:

**A DMX import should not create HyperDoc identity from the DMX title string.**

Instead:

* DMX topic id identifies the DMX object
* HyperDoc stable key identifies the HyperDoc topic
* a mapping record binds them
* title synchronization is an update, not a re-creation

That matches your broader “stable subject identity, mutable presentation relation” direction much better than title-based identity. The repo’s authored topic model already separates stable key from canonical title for exactly that reason. 

## 7) One-sentence formulation for the handover

You could hand this to Codex as:

**A HyperDoc topic factory is the durable local reconstruction point for a concept; its DMX reincarnation is a graph counterpart with its own DMX identity; importing from DMX into Topics HyperBook should materialize or refresh the local authored topic while preserving an explicit HyperDoc-key ↔ DMX-topic-id correspondence and optional live DMX proxy access.**

## 8) Applied to “Encryption boundaries on the small web”

For this specific case:

* HyperDoc side:

  * stable key: `encryption-boundaries-on-the-small-web`
  * canonical title: `Encryption boundaries on the small web`

* DMX side:

  * topic id: `917064`
  * type: `dmx.notes.note`
  * title/value: `Encryption boundaries on the small web` ([dmx.ralfbarkow.ch][1])

So the correct interpretation is:

* these are **not literally the same object**
* they are **two incarnations of one subject**
* the bridge is an explicit correspondence
* if imported, DMX should feed the authored topic layer, not erase it

If you want, I can turn this into a Codex-facing handover note in your usual plain-text style.

[1]: https://dmx.ralfbarkow.ch/core/topic/917064?assocChildren=true&children=true "dmx.ralfbarkow.ch"
