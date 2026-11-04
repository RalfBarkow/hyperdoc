# The CCNx Federated Wiki prototypes: a source review (Zettel 11483)

Reference: Zettel 11483, "Federated Wiki without DNS: Identity, Reachability, and Local Continuity".
Result of a read-only source review. The HyperDoc reading `dreyeck/ccnx-federated-wiki` is derived from this report.

## Scope and method

* **Read only.** Two historical repositories were fetched at fixed revisions and read. **No code of either repository was run**,
  no CCNx/NDN runtime was installed, no NDN integration was written, no browser was driven. Every statement marked *source*
  is a statement about what the cited lines say, not about observed runtime behaviour.
* **Status labels.** **[I] implemented**: the cited source does this. **[D] documented**: a README or comment says it; the
  source may or may not agree. **[H] hypothesis / open**: not established by what was read.
* **Nothing about the project's later fate is claimed.** Each repository was fetched as a single commit (`--depth=1`
  of the cited revision). No history, issue, release or deployment was read, so nothing here says why either repository
  stopped changing, or whether it did.
* Quoted source is limited to a few identifiers. **The embedded private key is not reproduced**; the report gives its
  public-key digest only.

## Sources

| | Pin | What it is |
|---|---|---|
| **Prototype** | [`rynomad/CCNx-Federated-Wiki-Prototype@c5b1b93c632ef9834a598406a25c20ad47bab26e`](https://github.com/rynomad/CCNx-Federated-Wiki-Prototype/tree/c5b1b93c632ef9834a598406a25c20ad47bab26e) | commit "commit", 2013-05-16. 5182 files, including a copy of the browser client of Smallest Federated Wiki, `ndn-js`, and test pages. |
| **Main** | [`rynomad/CCNx-Federated-Wiki@8426dc5cd326fa0d395d5bef2f73b8be33e34a8e`](https://github.com/rynomad/CCNx-Federated-Wiki/tree/8426dc5cd326fa0d395d5bef2f73b8be33e34a8e) | commit "break grunt but fix page ownership", 2013-11-08. 453 files. |
| **c2 page, shell** | <https://wiki.c2.com/?PowerOfPlainText> | Retrieved 2026-11-04: 8565 bytes of HTML, SHA-256 `319606335c20e33571204c0ea1744ec9c6a58900ccc3bc87af6498f235114af4`. It is a JavaScript application with no page text. |
| **c2 page, data** | <https://c2.com/wiki/remodel/pages/PowerOfPlainText> | The URL that the shell's script fetches (`let database = 'https://c2.com/wiki/remodel/pages/'`, then `fetch(database+title)`). JSON with two keys, `date` ("November 26, 2014") and `text` (38731 characters of wiki markup). 39707 bytes, SHA-256 `dd318a27aadaaf0a7891d89976e46c16bf17860dbec91289ca2f26920dac6c7b`. |
| **kidneybone** | <https://kidneybone.com/c2/wiki/PowerOfPlainText> | Retrieved 2026-11-04: 45615 bytes of HTML, SHA-256 `75a983b0663206fa014aa3f1045946ed20a0638036e8641fdd14b599cc514567`. A static rendering of the same page. |

Links below name the **Main** revision as `M`: `https://github.com/rynomad/CCNx-Federated-Wiki/blob/8426dc5cd326fa0d395d5bef2f73b8be33e34a8e/`
and the **Prototype** as `P`: `https://github.com/rynomad/CCNx-Federated-Wiki-Prototype/blob/c5b1b93c632ef9834a598406a25c20ad47bab26e/`.

## 1. The path: page, JSON, IndexedDB, NDN Content Object, NDN retrieval, page

### Main (`8426dc5`)

| Step | What the source does | Where | |
|---|---|---|---|
| 1 Edit | `pageHandler.put` builds the action (with `date` = now) and calls `pushToLocal`. The server variant `pushToServer` is defined but never called. | [`client/lib/pageHandler.coffee` L76-L96, L98-L110, L112-L163](https://github.com/rynomad/CCNx-Federated-Wiki/blob/8426dc5cd326fa0d395d5bef2f73b8be33e34a8e/client/lib/pageHandler.coffee#L76-L163) | [I] |
| 2 Page to JSON | `pushToLocal` appends the action (a `fork` action first, when forking) to `page.journal`, rebuilds `page.story` from the DOM, and adds `page` (slug + `.json`), `excludes` and `favicon`. | same, L76-L95 | [I] |
| 3 JSON to IndexedDB | `repo.updatePage` records the name in store `page`, sets `version` to the date of the last journal action, removes records keyed by each journal date, and puts the JSON into store `page/<slug>.json` (key path `version`). | [`client/lib/repository.coffee` L141-L176](https://github.com/rynomad/CCNx-Federated-Wiki/blob/8426dc5cd326fa0d395d5bef2f73b8be33e34a8e/client/lib/repository.coffee#L141-L176) | [I] |
| 4 Announce | When `navigator.onLine`, `sendUpdateNotifier` expresses, on every active face, an Interest `<prefix>/page/update/<page>/<version>` whose closure is `updatePageFromPeer`. | same, L127-L139, L168-L170 | [I] |
| 5 Serve | A peer's `interestHandler` answers Interests under its prefix: it reads the slug (and optionally the version) from the name, looks the page up with `repo.getPage`, and `sendData` wraps `JSON.stringify(record)` in a Content Object named `<interest name>/<version>`, sets `freshnessSeconds = 604800`, calls `sign()` and sends it. | [`client/lib/interfaces.coffee` L9-L53](https://github.com/rynomad/CCNx-Federated-Wiki/blob/8426dc5cd326fa0d395d5bef2f73b8be33e34a8e/client/lib/interfaces.coffee#L9-L53) (name L19, freshness L21, sign L22, send L24) | [I] |
| 6 NDN retrieval | `ContentClosure.upcall` takes the content of the first (unsegmented) Content Object, `JSON.parse`s it and calls the callback: `repo.updatePage` for pages asked for by name, `updatePageFromPeer` for announcements. Interests for pages are expressed for `wiki/page/welcome-visitors.json` when a face opens, and for every `[[link]]` that is rendered. | [`client/js/ndn-closures.js` L43-L149](https://github.com/rynomad/CCNx-Federated-Wiki/blob/8426dc5cd326fa0d395d5bef2f73b8be33e34a8e/client/js/ndn-closures.js#L43-L149); [`interfaces.coffee` L70-L82](https://github.com/rynomad/CCNx-Federated-Wiki/blob/8426dc5cd326fa0d395d5bef2f73b8be33e34a8e/client/lib/interfaces.coffee#L70-L82); [`client/lib/wiki.coffee` L70-L91](https://github.com/rynomad/CCNx-Federated-Wiki/blob/8426dc5cd326fa0d395d5bef2f73b8be33e34a8e/client/lib/wiki.coffee#L70-L91) | [I] |
| 7 Back into the store | `updatePageFromPeer` sets `version`, removes the records named in `json.excludes`, and puts the JSON. | `repository.coffee` L94-L124 | [I] |
| 8 Page | `pageHandler.get` calls only `repository.getPage` (the former Ajax path is commented out), so a page is rendered from IndexedDB, never directly from the network. | `pageHandler.coffee` L18-L72 | [I] |

**Documented [D].** [`ReadMe.md` L4](https://github.com/rynomad/CCNx-Federated-Wiki/blob/8426dc5cd326fa0d395d5bef2f73b8be33e34a8e/ReadMe.md#L4): "a rough port of the frontend editor from Ward Cunninghams Smallest Federated Wiki … modified to use PARC's Content Centric Networking … as a transport medium for pages via UCLA's NDN-js. Pages are stored locally in the clients IndexedDB … and synced on page update action." The source above agrees with this description.

**Server.** The ported express server still stores pages as flat JSON files (`server/express/lib/page.coffee`, header comment: "Everything is stored using json flat files") and serves `/<slug>.json` and `PUT /page/<slug>/action`; its static page loads `ndn-js.js`, `ndn-closures.js`, `ndn-utils.js`, `idbstore.js` ([`views/static.html` L16-L19](https://github.com/rynomad/CCNx-Federated-Wiki/blob/8426dc5cd326fa0d395d5bef2f73b8be33e34a8e/server/express/views/static.html#L16-L19)). [I] The client path above does not use the server's page files.

### Prototype (`c5b1b93`): same idea, different shape

| Step | What the source does | Where |
|---|---|---|
| Read | `recursiveGet` looks the page up in IndexedDB database `NeighborNetDB`, store `pageContentObjects`, index `name` = `/sfw/<slug>`; if absent and online it expresses an Interest `/sfw/<slug>`. A fetched page is shown and **immediately republished locally** with action `{type: 'fork'}`. | [`client/lib/pageHandler.coffee` L22-L78](https://github.com/rynomad/CCNx-Federated-Wiki-Prototype/blob/c5b1b93c632ef9834a598406a25c20ad47bab26e/client/lib/pageHandler.coffee#L22-L78) (L24-L36, L49, L73) |
| Write | `publishToIndexedDB` creates a `SignedInfo` (`freshnessSeconds = 5`), takes its timestamp in milliseconds, names the page `/sfw/<slug>/<timestamp>`, sets `page.version` to that timestamp, recomputes the story from the action, and registers an `AsyncPutClosure` with `JSON.stringify(page)`. | same, L115-L201 (L125-L139, L171, L178-L201) |
| Sign | The Content Object is created when an Interest for the name arrives, and signed there. | [`client/js/ndn/ndn-closures.js` L255-L277](https://github.com/rynomad/CCNx-Federated-Wiki-Prototype/blob/c5b1b93c632ef9834a598406a25c20ad47bab26e/client/js/ndn/ndn-closures.js#L255-L277) (`co.sign()` at L270) |
| Store | The record `{name, fullName, signedInfo, page}` goes into store `pageContentObjects`, key path `name`: **one record per slug**, a later put overwrites. Twins go to `pageTwinContentObjects` with `fullName = <slug>#<version>`. | [`client/js/SDB.js` L284-L312](https://github.com/rynomad/CCNx-Federated-Wiki-Prototype/blob/c5b1b93c632ef9834a598406a25c20ad47bab26e/client/js/SDB.js#L284-L312); `pageHandler.coffee` L178-L189; `refresh.coffee` L160-L163 |

**Documented [D].** The Prototype's [`ReadMe.md`](https://github.com/rynomad/CCNx-Federated-Wiki-Prototype/blob/c5b1b93c632ef9834a598406a25c20ad47bab26e/ReadMe.md): "The concept has proven to be workable, though it will be some time before it is useable." It names two components: a thin server with a websocket proxy to a CCN router, and a client that "renders, saves and serves pages in a users IndexedDB capable browser." It mentions a test deployment at `leela.rosewiki.org`; **not examined [H]**.

## 2. What is stored as JSON?

**Main [I].** The record in IndexedDB is the page JSON of Smallest Federated Wiki, `title`, `story`, `journal`, plus four fields added by this code: `page` (slug + `.json`), `excludes` (a list of journal dates, below), `favicon` (a data URL) and `version` (an integer, the date of the last journal action). The same record, `JSON.stringify`d, is the content of the NDN Content Object (`interfaces.coffee` L17-L19). Other IndexedDB stores: `page` (an index of names), `status` (the favicon record) and `system/sitemap.json` (`repository.coffee` L24-L67).

**Prototype [I].** The record `{name, fullName, signedInfo, page}` where `page` is the page JSON with `version` (timestamp), `publisher` (the local identity record), `slug` (`/sfw/<slug>`) and `isLocal: true` added (`pageHandler.coffee` L139, L178-L186). The Content Object content is `JSON.stringify(page)`.

## 3. How does the NDN name of a page arise?

| | Name | Source |
|---|---|---|
| **Main** [I] | `/wiki/page/<slug>.json/<version>`; the Interest is `/wiki/page/<slug>.json`, optionally with a version component; `<version>` is the page's last journal date in milliseconds | `interfaces.coffee` L19, L28-L50; `repository.coffee` L198 |
| **Prototype** [I] | `/sfw/<slug>/<timestamp>`; `<timestamp>` is the millisecond field of the `SignedInfo` created at publication, **not** a journal date | `pageHandler.coffee` L126-L133 |

**The host is not in the Main name.** `registerFace` computes a prefix from the host name (L57-L61) and then **assigns the constant `"wiki"`** to `hostPrefix` ([`interfaces.coffee` L62](https://github.com/rynomad/CCNx-Federated-Wiki/blob/8426dc5cd326fa0d395d5bef2f73b8be33e34a8e/client/lib/interfaces.coffee#L62)). Every site registers the same prefix. [I]

## 4. Versions and forks

**Main [I, source].**

* **Version.** `version` is the date of the last journal action (`repository.coffee` L158, L110). The NDN name carries it. Two copies with the same last date are the same version; a different last date is a different version.
* **Fork.** A fork is detected when the page's `favicon` differs from this browser's (`pageHandler.coffee` L126, L147). It is recorded as a journal action `{type: 'fork', site: <forkFrom>, date}`; **`site` is the page's favicon data URL**, not a host name (L126, L146-L160, L79-L82).
* **excludes.** Walking the journal from the newest action backwards, every action date is collected until the first `fork` action is reached (L86-L93). `updatePageFromPeer` removes the stored records whose key is in the incoming `excludes` (`repository.coffee` L111-L112). [A, derived: a peer's earlier versions of its own line since its last fork are replaced; versions before that fork remain as separate records.]
* **Twins.** `emitTwins` reads all records of a slug and sorts them as newer, same or older than the version being viewed by `version`, and shows each twin by its `favicon` (`refresh.coffee` L112-L141). The [`revision.coffee`](https://github.com/rynomad/CCNx-Federated-Wiki/blob/8426dc5cd326fa0d395d5bef2f73b8be33e34a8e/client/lib/revision.coffee) module can rebuild an earlier page state from the journal alone. [I]

**Prototype [I].** `version` is the publication timestamp. The store keeps one record per slug (overwritten). `fork` is added to the journal by `pushToLocal` and `put` (`pageHandler.coffee` L105-L107, L253-L266); twins are stored apart (above).

## 5. Where are site identity and publisher identity kept?

| | Main | Prototype |
|---|---|---|
| **Site identity** | The favicon: a 32×32 gradient drawn on a canvas with random colours (`plugins/favicon.coffee`), kept in store `status`, copied into every page as `favicon`, used to decide "is this my page" (`repository.coffee` L208-L216) and for fork detection. The NDN name has no site. | The `LocalID` record `{id: 1, name: 'anonymous', favicon}` (`client/plugins/favicon/favicon.coffee` L52-L57), copied as `page.publisher` (`pageHandler.coffee` L181-L183). |
| **Publisher in the NDN object** | `SignedInfo.publisher` is the SHA-256 digest of the public key in `KeyManager`; the key locator is that public key (`client/js/js/ContentObject.js` L281-L335). | the same library |
| **Key** | **One RSA key pair, written into the source of `KeyManager.js`** (`client/js/js/security/KeyManager.js` L31, L34; `globalKeyManager` L102), identical in both repositories: public-key DER SHA-256 `b5506b1aba3da7761b0f8d61a4aa7e3b6d15b426feb5bda82389aca765a3b81c`. An X.509 certificate with subject `axelcdv`, valid 2012-04-28 to 2012-05-28 (decoded from its DER), sits beside it. | same |
| **Server identity** | The express server still has an `owner` (Persona login) and `status/local-identity` (`server/express/lib/server.coffee` L103-L122, L363-L370). [I] The CCNx client path does not consult it. | – |

[I] Nothing in the source read maps a key to a person, a site or a name. [H] Whether any other deployment used other keys is not known.

## 6. Which signatures are created, and which are checked?

**Created [I].** Every Content Object that these clients make is signed by `ContentObject.sign()` ([`ContentObject.js` L36-L80](https://github.com/rynomad/CCNx-Federated-Wiki/blob/8426dc5cd326fa0d395d5bef2f73b8be33e34a8e/client/js/js/ContentObject.js#L36-L80)): RSA with SHA-256 over the encoded name, signed info and content element, using the key above. The call sites: `interfaces.coffee` L22 (Main), `ndn-closures.js` L270 (Prototype). A function `pageToContentObject` that also signs (`repository.coffee` L9-L17) has **no caller** in either client.

**Checked [I, source].**

1. `NDN` verifies every incoming Content Object unless `settings.verify === false` (default `true`, [`client/js/js/NDN.js` L37](https://github.com/rynomad/CCNx-Federated-Wiki/blob/8426dc5cd326fa0d395d5bef2f73b8be33e34a8e/client/js/js/NDN.js#L37)). No call site in the client sources (`client/lib`, `client/*.coffee`, plugins) sets it to `false`.
2. For a key locator that **is** a public key, which is what `SignedInfo` always writes, the code decodes the key **from the object itself**, verifies, computes `flag` (`UPCALL_CONTENT` or `UPCALL_CONTENT_BAD`), and then raises **`UPCALL_CONTENT` unconditionally** ([`NDN.js` L492-L500](https://github.com/rynomad/CCNx-Federated-Wiki/blob/8426dc5cd326fa0d395d5bef2f73b8be33e34a8e/client/js/js/NDN.js#L492-L500)). The shipped, minified `client/js/ndn-js.js` of **both** revisions has the same statement order (`c=!0==c?UPCALL_CONTENT:UPCALL_CONTENT_BAD,b.upcall(Closure.UPCALL_CONTENT,…)`).
3. `ContentClosure` accepts both `UPCALL_CONTENT` and `UPCALL_CONTENT_UNVERIFIED` alike ([`ndn-closures.js` L62-L65](https://github.com/rynomad/CCNx-Federated-Wiki/blob/8426dc5cd326fa0d395d5bef2f73b8be33e34a8e/client/js/ndn-closures.js#L62-L65)).
4. A content digest in the name is compared only if the name has one, only logged, and after the callback has been called (`ndn-closures.js` L133-L149).
5. `KeyManager.verify` (certificate based) has no call site in the client sources.

**Consequence [A, derived from 1-3, not executed].** On this path the result of the signature check does not decide whether a page is accepted. And even a correct check would show only that the object is consistent with the key it carries. With one shared key there is no trust anchor, and a signature cannot say who published a page.

**Storage [I].** What is written to IndexedDB is the plain JSON record. **Signatures are not stored**; Content Objects exist on the wire and in memory.

## 7. Can the content be read as a JSON file without the historical runtime?

* **Data files in the repositories. Yes [observed].** `default-data/pages/welcome-visitors` and `how-to-wiki` are plain Smallest Federated Wiki JSON files in both repositories, byte-identical between them (`welcome-visitors` SHA-256 prefix `78c5087a9e4bd1ac`), 7 story items and 30 journal actions for `welcome-visitors`; they read with any JSON parser. They carry none of the CCNx fields.
* **The CCNx representation. In principle [I/H].** The payload of a Content Object is JSON text, but it sits in a binary `ccnb` element together with signature, name and signed info; reading it needs a `ccnb` decoder. The IndexedDB records are JSON-like objects inside the browser profile, not files. **Neither client has an export to a file** (no `Blob`, `createObjectURL`, `saveAs` or download call in the `.coffee` sources of `client/lib`, `client/` and the plugins). [H] Extraction from a stored browser profile was not tried.

## 8. What would survive adoption by today's Federated Wiki or HyperDoc?

The example below is **derived** by applying the cited rules; neither runtime was run.

| Information | In the CCNx record | Today's page JSON / HyperDoc |
|---|---|---|
| title, story items (id, type, text), journal (type, id, date, item, after) | present, unchanged SFW vocabulary | **kept**: the CCNx record reads as an ordinary local page with the existing `dreyeck/local-fedwiki-page` (checked by the tests of this reading) |
| `version` | last journal date | derivable from the journal; not needed |
| `excludes` | journal dates since the last fork | derivable from the journal by the rule in section 4 [A]; not needed |
| `page` | slug + `.json` | derivable from the title |
| `favicon` | data URL, random per browser | an extra field; ignored by the readers used here; **not a site name** |
| `fork` actions | `site` = a favicon data URL | today `site` is a host name: **the origin cannot be located**, only compared by image |
| NDN name | `/wiki/page/<slug>.json/<version>` (no site) | **no counterpart**; derivable from slug and version, but it never named a site |
| publisher digest, key locator | constant, same for all pages | **no information** |
| signature | never stored | **absent** |

## 9. The running example

All forms are in the reading `dreyeck/ccnx-federated-wiki`. The page *Plain Text Example* has two items and five journal actions (`create`, two `add`, two `edit`); dates start at `1700000000000`; ids are illustrative. It is not a page of either repository.

* **A, as a server stores it:** `dreyeck/ccnx-federated-wiki/example-site/pages/plain-text-example`.
* **B, Main, after the last action (IndexedDB record):** `…/plain-text-example-ccnx-record`: A plus `page = "plain-text-example.json"`, `excludes = [1700000000004, …, 1700000000000]`, `favicon` (a 1×1 placeholder), `version = 1700000000004`.
* **C, NDN Content Object (Main):** name `/wiki/page/plain-text-example.json/1700000000004`; content = `JSON.stringify(B)`; signed info: publisher digest `b5506b1a…`, a timestamp taken when the object is made (not from the page), type DATA, key locator = the embedded public key, freshness 604800 s; signature RSA-SHA256 over name, signed info and content.
* **D, Prototype:** record `{name: "/sfw/plain-text-example", fullName: "/sfw/plain-text-example/<timestamp>", signedInfo, page}`; `page` = A plus `version` (= that timestamp), `publisher = {id: 1, name: "anonymous", favicon}`, `slug`, `isLocal`; NDN name `/sfw/plain-text-example/<timestamp>`; freshness 5 s.

## 10. Historical and present representation, side by side

| | Smallest Federated Wiki / today's server | CCNx FW Main (`8426dc5`) | CCNx FW Prototype (`c5b1b93`) |
|---|---|---|---|
| Where the page lives | a JSON file `pages/<slug>` on a server | a record in the browser's IndexedDB | a record in the browser's IndexedDB |
| Name | `https://<host>/<slug>.json` | `/wiki/page/<slug>.json/<version>` | `/sfw/<slug>/<timestamp>` |
| Site identity | the host name | random favicon image | random favicon image ("anonymous") |
| Version | the journal itself | last journal date | publication timestamp |
| Fork record | `{type: "fork", site: <host>}` | `{type: "fork", site: <data URL>}` | `site` of the source page |
| Authentication of content | the server's own authorization | RSA signature with one shared key; result not decisive | the same library |
| Readable without the program | yes (a file) | the IndexedDB record needs a browser profile; the wire form needs a `ccnb` decoder | the same |

## 11. "Power Of Plain Text" assessed

The c2 page (data file `PowerOfPlainText`, 2014-11-26) states the assertion: "storing resources as plain text makes them easier to view, maintain, increases their longevity, and/or makes it easier to share information with multiple languages and systems." It lists, among others: no special editor required, readable by common tools, robust against corruption, fits version control, "Every person, pipe, and computer sees the same stream of bytes"; and, as disadvantages, parsing overhead, hard random access, "Security (because security has to be placed on the file instead of on the file's editor …)". It lists "Some wiki-like systems" among examples.

| Criterion from that page | In the CCNx prototypes |
|---|---|
| Readable with common tools, "parsed … by eye" | **Partly.** The record and the content are JSON text and the journal reads as a history [I]. At rest it is inside a browser store; on the wire it is a signed binary envelope. |
| Longevity, survives the application | **Not shown by these sources.** The only files that outlive the runtime are the SFW `default-data` pages. No export exists [I]. |
| Version control, diff | **Journal yes, file no.** The journal is a complete plain-text history; there is no file to put under version control. |
| Different systems can read it | **The vocabulary yes, the container no.** Today's FW reads the record (section 8). |
| Security belongs to the file, not the editor | **The relevant point.** Signing exists, but its result is not decisive, the key is shared, and signatures are not kept. The protection of the plain text is not in the plain text. |
| A format that does too much degrades | **Not observed.** The four added fields are small and derivable. |

**Assessment [A].** The *content model* is plain text in the c2 sense and survives. What the CCNx prototypes added around it, name, identity, signature, does not survive as plain text: it is either constant, derivable, binary, or not stored.

## 12. Where is "Ward's pointer to local JSON files"?

[H, open] **A statement by Ward Cunningham about local JSON files was not found in any of the four sources.** The kidneybone text contains no occurrence of "Ward", "Cunningham", "JSON", "federated" or "CCN". What is observable in the c2 sources: the c2 application loads each page as a JSON file, `{date, text}`, from `c2.com/wiki/remodel/pages/<Title>`, and its script has an "export to fedwiki" function that turns each page into a Federated Wiki page JSON (paragraph items, ids derived by a hash, one `create` journal action) and downloads it as `wiki-export-pages.json`. The files read do not say who wrote that application. The Zettel 11483 text that holds the pointer was not available to this review.

## 13. Open questions

1. Where exactly is Ward's pointer to local JSON files (Zettel 11483, a page, a message)? It is not in the four sources.
2. **Runtime behaviour was not observed.** Does the unconditional `UPCALL_CONTENT` at `NDN.js` L500 behave as read? Does a tampered Content Object get accepted in a browser?
3. `statusOpts` (`repository.coffee` L33-L40) writes `keypath` and `autoincrement` in lowercase where the other stores write `keyPath` and `autoIncrement`. Whether the bundled `idbstore.js` honours the lowercase names, and so which key the favicon record has, was not tested.
4. How do two nodes that forked different lines settle `excludes` and `version` (the derivation in section 4 is a reading, not a run)?
5. How would a `fork` action whose `site` is an image be mapped to a host in today's Federated Wiki? Is the favicon a usable fingerprint at all?
6. The deployment named in the Prototype's ReadMe (`leela.rosewiki.org`) was not examined; was any key other than the shipped one ever used?
7. Is there any export of an IndexedDB page to a JSON file anywhere in the repositories' history (only one commit of each was read)?
8. Provenance and date of the c2 `remodel` data and application.

## The reading in the Catalog

`dreyeck/ccnx-federated-wiki` is a HyperDoc of four English pages (`dreyeck/pages/ccnx-federated-wiki/`) that restate this report for human readers, with the same pinned links and the same status labels:

1. *Reading the CCNx Federated Wiki* (main page: scope, sources, the seven questions answered briefly)
2. *One Page From Browser to NDN and Back* (the path, the example forms A-D)
3. *Identity, Versions and Signatures*
4. *Plain Text After CCNx* (readability, adoption, the Power Of Plain Text assessed, Ward's pointer, open questions)

**Reused mechanisms, no new infrastructure.** The reading is a `dreyeck/hyperdoc` HyperDoc of HTML pages like the other readings. Its example pages are ordinary local Federated Wiki
page files (`dreyeck/ccnx-federated-wiki/example-site/pages/`), hydrated by the existing `dreyeck/local-fedwiki-page` and shown by the existing Story view and Inspector; the pages open them with the
existing `<a expr>` link. The only Lisp is three small files (package, a 10-line page loader, the registration).

**Not a member of `dreyeck/catalog`.** Admitting a reading to the default Catalog is a separate decision with pinned tests
(`dreyeck/tests/catalog-startup-smoke.lisp`). Until then the system is loaded additively with `HYPERDOC_CATALOG_SYSTEM=dreyeck/ccnx-federated-wiki`
(see `dreyeck/CATALOG-OPERATIONS.md`; the variable names systems of the packaged registry, so a package built from this branch is needed).

### Verification run for this branch

* `(asdf:test-system "dreyeck/ccnx-federated-wiki")` in the `fedwiki-original-editor` dev shell (SBCL 2.4.10): passes. It checks that the reading and its four pages load; every `<a page>` target exists; every
  `<a expr>` opens only `example-page`; every reference to either repository is a full-commit blob or tree link **to the reviewed commit of that repository**; no key material is quoted; the two example pages are
  consistent with the rules cited above (added fields, `version`, `excludes`, including the stop at a fork action) and open as ordinary local pages with the Story view; the reading is not a member of `dreyeck/catalog`.
  Two deliberate breakages were run and caught (a `blob/master/` link, a wiki link inside an example).
* An ad-hoc browser check in a loopback Catalog (`HYPERDOC_CATALOG_SYSTEM`): the reading opens, the `<a expr>` link opens the example page object with its Story view ([screenshot](evidence/reading-in-catalog.png)),
  no page error. The only external request was the Story view's favicon request for `ccnx-example.invalid`, which the test browser aborted. **Following an internal `<a page>` link was not exercised in the browser**
  (the check script's selector failed); the link targets are covered by the test above.
* The same reasons as for the review apply: nothing historical was run.
