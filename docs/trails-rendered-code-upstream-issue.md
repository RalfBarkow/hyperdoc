Draft for the owning fork: [RalfBarkow/wiki-plugin-mech](https://github.com/RalfBarkow/wiki-plugin-mech). Not posted.

**Title:** Trails Rendered requires CODE, but the deployed 0.1.32-dev.1 catalog has no CODE block

The Wiki installation at [hyperdoc.dreyeck.ch](https://hyperdoc.dreyeck.ch/view/welcome-visitors/view/trails-rendered) renders Ward's Trails Rendered experiment but rejects its `CLICK → CODE trails` action. Clicking the red cross reveals exactly `CODE doesn't name a block we know.`

Reproduced on 2026-10-08 with fresh, unauthenticated Playwright Chrome 154.0.8037.98. The loaded Mech entry reports `0.1.32-dev.1`, build `2026-03-03T15:12:15Z`, commit `abd88d2da6c89029515f2a456356832dffe038ab`. The served `blocks.js`, `interpreter.js` and `library.js` match the corresponding complete Git source files at that revision byte-for-byte. The local checkout identifies its origin as this fork.

The source boundary is `src/client/blocks.js:254–271` (`run`), especially the unknown all-caps operation branch at line 267, and `:1124–1154` (catalog). The catalog lacks CODE and the file has no code_emit. `trouble` at `:21–27` produces and reveals the observed message. No page module import, trails() execution or Graph request occurs. Removing Welcome Visitors from the lineup reproduces the same result. Both page contexts are local and unauthenticated; this dispatch path has no CODE ownership/initiator check to reach.

The comparison [Ward installation](http://ward.voices.ustawi.wiki/view/trails-rendered) succeeds with `⇒ 2 aspects`. Its loaded Mech bundle is 0.1.48-3; the served source-map blocks.js matches repository `WardCunningham/wiki-plugin-mech`, revision `a028b4bba04e539dcaa090423d38a00a0050489d`. That source implements CODE, including the CLICK initiator contract. The pages carry the same Mech and Code item IDs/texts and relative Code order. Matching source-file bytes establish those file revisions, not an inferred complete deployed checkout HEAD.

Proposed resolution: choose a CODE-capable Mech release or integrate compatible CODE support into this fork through its normal release process. Validate the fork's existing EXTRACT/EDGES and other custom capabilities before replacing it. A compatible implementation must retain the newer CODE invocation/permission contract and required APIs/dependencies; copying only the catalog entry is insufficient. No change to the page's trails()/trail() functions is indicated.

Acceptance for that later owning-plugin/release change:

- The original full lineup and single-page `CLICK → CODE trails` both return `⇒ 2 aspects` when run unauthenticated through CLICK.
- Existing owned/non-owned invocation rules remain enforced; CODE is present and its handler actually runs.
- Graph and Cypher load successfully with recorded actual response identities.
- Existing fork functionality remains green.

The portable read-only reproduction harness, exact successful/failing captures, served sources and a bounded source reduction are retained in this HyperDoc slice. This draft does not request or perform an automatic update, clone, deployment or server reload. The observed favicon/proxy errors are separate from the proven unsupported-command diagnostic.
