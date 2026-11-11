# S1: FedWiki acquisition evidence adapter

Assignment `:S1-ASSIGNMENT-001`; manually assigned implementer Codex; independent
verifier/reviewer Claude Code. Base `596344ae95d746f436705808462259371f5a593c`.
Branch `codex/11570-s1-acquisition-adapter`. This document and the test outputs
are implementation evidence, not a DEV-SUBMISSION, independent verification,
review acceptance or a claim that Ward's page has been acquired.

The operator supplied domain version
`f342bb4ad3455fac873a56d9a7d817ff35e7ace253527ef7db1068e3759ad315`, plan digest
`5be5c714b58c1d66b29c69b0aa8567b95859ffdacbfcab80fd002275382acf3f`, selected
alternative `d67367caa09861c124e8b94dcbf0dff3f67ce2c1c3da20e34aff1c5cbe170fe0`
and step `(!ASSIGN S1 CODEX "596344ae95d746f436705808462259371f5a593c")`.
These binding values are retained as assignment input, not independently
recomputed without the operator's complete accepted journal. Fresh Git reads
confirmed the base and the existing annotated dedicated domain tag: object
`f4c090ae59b5d7bcb6653306c40237e186973c20`, peeling to that base. No tag was created
or fetched, and no development-journal record was appended.

## API and reuse

Optional ASDF systems:

* `dreyeck/work/fedwiki-source-acquisition`
* `dreyeck/work/fedwiki-source-acquisition/tests`

Public operation:

```lisp
(acquire-source site slug protocol capture-root
                &key expected-title transport allow-network
                     (max-bytes 1048576) (timeout 20))
```

Symbols are in `DREYECK/WORK/FEDWIKI-SOURCE-ACQUISITION`. Protocol is a required
argument, exactly `"http"` or `"https"`. It is never probed, upgraded or downgraded.
Real HTTP is disabled by default. A caller must explicitly opt in with
`allow-network`; an injected transport is always labelled `:fixture`, even if its
caller supplies realistic metadata. That flag is not an authorization capability.
It does not replace the separate approval required for live Ward requests.

The operation returns a `source-acquisition`, with status `:acquired` or
`:refused`, stage, reason, original condition and all evidence obtained so far.
No HTTP, file creation or acquisition occurs while loading the new module or
rendering its evidence views. Its existing Local-only dependencies retain their
normal startup registrations and retained local planning fixture. The new S1
module adds no Catalog member and acquires no source on load. No default ASDF
dependency was changed.

The source path is:

1. Construct an unregistered existing FedWiki instance, set the explicitly
   selected protocol, and invoke **existing `fetch-sitemap :json-fetcher`**.
   The fetcher captures a response and invokes the existing SHASHT reader.
   `fetch-sitemap` constructs the usual page skeletons. Retain **`sitemap-of`**,
   **`sitemap-snapshot`**, and the selected entry from the retained sitemap.
2. Require the requested slug and, when supplied, expected title in that sitemap.
   Reject malformed entries and duplicate slugs. Derive the page URL from the
   selected native page's **`origin-of`, `origin-id-of`, `domain-name-of`,
   `protocol-of`, `wiki-url`** contracts. Require the page title to match the
   selected sitemap entry. There is no title-to-slug guessing or alternate-site
   lookup on a mismatch.
3. Use Drakma's existing HTTP boundary with binary streams, no redirects, no
   content decompression, and `Accept-Encoding: identity`. Capture both responses
   independently. Retain requested/effective URL, status, reason, headers,
   acquisition start/finish universal times, octets, SHA-256, completeness and
   transport kind **before JSON decoding**.
4. Reuse SHASHT's strict single-value parsing and Local-only's `checked-page-json`.
   Do not reinterpret Story, Journal or links. Native reader/validation errors
   remain inspectable refusal causes.
5. Atomically reserve a new mode-0700 capture directory. Write unchanged bytes
   to `sitemap.json` and `pages/<slug>` with no overwrite. Reuse Local-only's
   **`make-own-site` / `find-page`**, the native local source observer and
   **`set-page-data :context-resolver (constantly nil)`** hydration. This produces
   an existing `own-page` / `local-fedwiki-page` / `fedwiki-page`, native Story,
   Journal and links. No replacement page class is introduced.
6. Compare the hydrated source digest and separate fresh disk reads with the
   captured bytes before reporting success. Retain the original hydration source
   observation. `verify-snapshot` performs further read-only checks and returns
   another native local source observation; it never rewrites the capture.

The metadata is four distinct things: sitemap response/interpretation, page HTTP
response, dated local snapshot observation, and (only in S2) destination-store
observation. The local read time is not the HTTP acquisition time. Capturing a
page does not establish that it exists in the S2 destination.

`response-complete-p` is false after interrupted/limited reads. Its digest then
identifies retained partial bytes only, not a complete page. A proxy/transport
failure before an origin response leaves HTTP status unknown. Bytes are HTTP
body octets after transfer framing, not raw TCP/TLS packets. Only identity content
encoding and application/json with absent or UTF-8 charset are supported. Other
encodings/types refuse; nothing is silently transcoded into the snapshot.

`capture-root` must be a new absolute directory below an existing canonical
parent. It is an inert evidence store, never an existing Wiki root. A concurrent
creator loses at `mkdir`; no overwrite fallback exists. A later failure can leave
partial capture artifacts in this private directory, recorded as refused; there
is no automatic deletion or claim of successful acquisition. `verify-snapshot`
refuses changed/symlinked paths, mismatched bytes or unreadable/invalid files.

## Offline Inspector and object identity

The acquisition's **Source acquisition evidence** view links to the exact
response objects, retained sitemap/entry/snapshot, native offline page and native
local source observation. **HTTP evidence** exposes headers, original body bytes,
digest, status, kind and completeness. Standard Slots retain the other metadata,
including acquisition times and the original refusal/cause conditions.

Local-only's existing **Story** view escapes text and retains native item
references. Its existing local-only link dispatch does not invoke plugins or
remote contexts; the **Journal** and item **Data** views reuse the original
objects. Unknown Story types and arbitrary fields survive in complete raw JSON
and native item data. No Paragraph-only filtering is applied to source bytes.
Do not substitute ordinary network-enabled FedWiki rendering for these views.
The broader optional `dreyeck/local-fedwiki-view` supplies **Page source**, but S1
does not load its server/Catalog layer just to inspect a retained source object.

For a controlled, in-memory fixture inspection, evaluate each block as a separate
SLY request in the intended image. This writes only a fresh local fixture capture:

```lisp
(asdf:load-system "dreyeck/work/fedwiki-source-acquisition/tests")
```

```lisp
(defparameter *s1-fixture-evidence*
  (dreyeck/work/fedwiki-source-acquisition::capture-fixture
   #P"/tmp/hyperdoc-s1-human-review/"))
(inspect *s1-fixture-evidence*)
```

That root must not already exist. Use a fresh chosen root on a repeat; do not
delete or overwrite someone else's capture. No Ward request occurs. If CLOG is
already connected in the same image, use its existing Inspector entry point:

```lisp
(clog-moldable-inspector:clog-inspect :object *s1-fixture-evidence*)
```

No interactive CLOG/SLY navigation is claimed by the automated evidence.

## S2 and ISO/IEC 13250 boundaries

S2 may make a byte-identical copy under its evidence-relative
`snapshots/<name>.json`, verify its digest, and fill the existing `copies` fields
`site`, `slug`, `path`, `sha256`. The existing `remote-snapshot` tuple binds that
copy to the chosen destination/slug. Fork permission and source policy remain
separate explicit decisions. The adapter creates no S2 evidence file or
destination site at runtime. Only the isolated boundary test creates those
fixtures and calls existing `observe-link`, `prepare-link`, continuation and
resolution. Its modeled page remains hypothetical, all results `:PLAN-ONLY`, and
the actual destination stays absent. The SHOP3 domains are unchanged.

The retained FedWiki objects and source coordinates are available for later
TMDM-oriented readings. They are not TMDM Topics/Associations. No automatic
mapping or second TMDM implementation exists; any future mapping needs its own
semantic decision and must retain original object references/provenance.

## Executed evidence and reproducibility

The [evidence runner](s1-evidence/run.lisp) has three explicit modes: `s1`,
`regressions`, `w2`. It verifies source-file hashes before/after each suite run and
asserts the S1 module adds no Catalog member beyond its existing dependencies. The final logs and summary are
under [s1-evidence](s1-evidence/). The summary records exact commands, exit codes,
source hashes and results; `SHA256SUMS` binds retained evidence files.

Prepared-environment commands from the checkout (no dependency acquisition):

```sh
S1_TEST_MODE=s1 sbcl --noinform --no-sysinit --no-userinit --non-interactive \
  --load docs/welcome-development/s1-evidence/run.lisp
S1_TEST_MODE=regressions sbcl --noinform --no-sysinit --no-userinit --non-interactive \
  --load docs/welcome-development/s1-evidence/run.lisp
S1_TEST_MODE=w2 sbcl --noinform --no-sysinit --no-userinit --non-interactive \
  --load docs/welcome-development/s1-evidence/run.lisp
```

The Cloud execution additionally uses the already available portable SBCL launcher
and retained dependency-registry bootstrap; see the exact summary commands.
That bootstrap contains host-specific existing paths and is not a portable
dependency installer. The runner defaults to a per-process cache **with source-directory
structure preserved**. `S1_FASL_CACHE` can reuse an explicit, correctly structured
cache between disposable images. Earlier runner attempts used pathname destinations that
flattened package filenames, causing package-load failures before tests; these
were harness failures, not passing suite evidence. An overly early Catalog
snapshot also counted existing dependency registrations as S1 additions; the
final check takes that baseline after loading the existing Local-only system.
No shared dependency fix or upstream change was made.

The six S1 markers cover sitemap provenance, actual loopback HTTP acquisition and
non-followed redirects, exact snapshot integrity and tampering, offline native
objects/EQ references, refused responses/interruptions/limits, and the S2 boundary.
Injected transport responses are `:fixture`. The real HTTP fixtures use only
127.0.0.1, ephemeral listeners and explicit test threads, closed on exit. They
are not agent dispatch or persistent service actions. Tests delete their own
temporary captures; reconstruction uses the retained fixture source.

## Limits and required follow-up

* **Ward's source remains unverified and unacquired.** No request to
  ward.asia.wiki.org was made. A separately authorized live capture is still
  required; fixture markers never stand for that observation. A future source
  failure must remain a blocker, not successful S1 source evidence.
* SBCL/POSIX implementation, tested on Linux with SBCL 2.4.10 and Drakma 2.0.10;
  no new macOS/Windows or full Nix-closure validation is claimed.
* Body bytes and elapsed request time are bounded. This is not a sandbox, an
  authenticated provenance service or a general HTTP/JSON implementation. Header
  parsing remains Drakma's; byte limits are body limits. Inspector objects are
  cooperative in-image data, not signed immutable attestations.
* A fresh read and hash in one test image is not independent Claude verification.
  The independent reviewer must check the delivered commit/tree, scope, exact
  test evidence and limitations. No verdict or DEV-SUBMISSION is produced here.
* A live Ward request, retention of its resulting source evidence, any later S2
  assignment, and any mapping to TMDM require their own authorizations/decisions.
  No executor, Wiki/fork write, merge, deployment, service restart, Catalog surface
  or production authority change is supplied.
