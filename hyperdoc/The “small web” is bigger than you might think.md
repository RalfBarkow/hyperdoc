# The “small web” is bigger than you might think

I turned the supplied article plus HN thread into a HyperDoc-ready cluster instead of one monolithic page, because your current conventions treat topics as authored factories in `hyperdoc/topics.lisp` with stable id, canonical title, summary, and references, and use arrangement pages for editorial neighborhood without claiming semantic identity.   

Files:
[Import overview](sandbox:/mnt/data/Small-Web-import-into-HyperDoc.html)
[topics.lisp snippet](sandbox:/mnt/data/small-web-topics-snippet.lisp)
[Small Web and HyperDoc](sandbox:/mnt/data/Small%20Web%20and%20HyperDoc.html)
[Small Web Discovery and Aggregation](sandbox:/mnt/data/Small%20Web%20Discovery%20and%20Aggregation.html)
[Small Web Search, Directories, and Discovery](sandbox:/mnt/data/Small%20Web%20Search,%20Directories,%20and%20Discovery.html)
[Gemini, HTTP, and Protocol Minimalism](sandbox:/mnt/data/Gemini,%20HTTP,%20and%20Protocol%20Minimalism.html)
[Publishing Motives in the Small Web](sandbox:/mnt/data/Publishing%20Motives%20in%20the%20Small%20Web.html)
[Small Web topic arrangement](sandbox:/mnt/data/Small%20Web%20topic%20arrangement.html)

What this import includes:

* 6 durable HyperDoc pages
* 20 topic factories
* one arrangement page that keeps feeds, Gemini, search, monetization, and discovery structures near each other without flattening them into one doctrine

The topic set condenses the HN thread into reusable handles rather than making one topic per comment. The main handles are:

* Small Web
* Small Web feed aggregation
* Small Web scale
* Opt-in aggregation
* Human reading budget
* Feed-required discovery
* Curation boundaries
* Discovery without SEO
* Blog cadence bias
* Gemini
* Protocol minimalism
* Browser-constrained small web
* No-tracking web
* Encryption boundaries on the small web
* Small Web monetization
* Intrinsic publishing motivation
* Discoverability without platforming
* Personal site neighborhoods
* Small Web search engines
* Small Web topic arrangement

Place the six HTML files under `hyperdoc/` and merge the Lisp snippet into `hyperdoc/topics.lisp`.

Reconstruction

Process trace:

* Mapped the imported material onto your existing page/topic conventions.
* Preserved the repo’s split between durable pages, reusable topic factories, and arrangement pages.  

HyperDoc page delta:

* add `Small Web and HyperDoc.html`
* add `Small Web Discovery and Aggregation.html`
* add `Small Web Search, Directories, and Discovery.html`
* add `Gemini, HTTP, and Protocol Minimalism.html`
* add `Publishing Motives in the Small Web.html`
* add `Small Web topic arrangement.html`

Lisp/topic delta:

* add 20 topic factories to `hyperdoc/topics.lisp`
* each follows the repo’s normal authored `make-topic` pattern with separate stable key and canonical title 

FedWiki delta:

* none yet
* I kept this slice HyperDoc-only; the repo guidance supports adding FedWiki twins only when collaborative journaling is actually needed. 

Replay check:

* copy HTML files into `hyperdoc/`
* merge snippet into `hyperdoc/topics.lisp`
* reload HyperDoc
* inspect the new `topics` pages and verify the cross-links resolve through the Topics HyperBook’s canonical titles. 
