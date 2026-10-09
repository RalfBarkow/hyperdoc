# Reading FedWiki Configuration and Fork Behavior

Catalog entry: `dreyeck/fedwiki-config/reading`. Main page: **Reading FedWiki Configuration and Fork Behavior**. Four Text Pages, four Common Lisp Code Pages and eight runnable Inspector examples explain a Wiki installation before introducing its source coordinates. This report supports the reading; it is not its substitute.

## What the reader can follow

From the Catalog, open the reading entry and select the local development configuration. Its **Configuration** Inspector links the actual `flake.nix` and `flake.lock` source objects. The declaration names client `1aba55920f95b957bc8ccf3b3648c9b23d534c9a`; the root lock selects RalfBarkow/wiki-client `4b290709a1906c2010306f0f47ebfad530d8b4b6`. Follow that repository-qualified revision to its file and retained `pageHandler.put`/loopback provenance definitions. Compare its acquisition and journal outcome with P41 and Dreyeck, then return to the two Workspace projections.

Each new source Inspector links authority/full OID, file-at-revision, exact retained definition, full retained file, reading entry and Workspace. Code Page play thunks return actual configuration, source, profile, case and Workspace objects. They do not execute JavaScript, Nix, Git or a host query. TALA is an explicit layout example, independent of ordinary rendering.

## Source authority and observation scope

HyperDoc began clean at `/Users/rgb/workspace/hyperdoc-dreyeck-ch`, branch `dreyeck.ch`, HEAD/parent `57ce7b317c457d92d694af38bc545a47e9eb926b`; index empty, no untracked files. `.DS_Store` was absent and not recreated.

Read-only Wiki observations confirmed these clean source coordinates in the shared RalfBarkow/wiki repository:

| Configuration | Exact local revision | Component-selection mechanism |
| --- | --- | --- |
| localhost | `4dd6be43453b451615ce04fc9ac4e5792eede46e` | Root flake-lock client/server inputs; prior defaults preserved |
| dreyeck.ch | `db98a893a7c710fcb3506150b68b1aa08915c47e` | Hash-pinned component fetchers; served prebuilt client recorded separately |
| wiki.ralfbarkow.ch | `6774447eff17d705a3083378ab2c9a93b237cf91` | P41 upstream/personal archives, patches and reconstructed package inputs |
| reviewed module | `971794d2066f87f63e7685447352340d5276a959` | Independently owned module, version 0.1.0 |

The shared package composition is `9a9afef387e8c05587c95171119d627117798f56`. Package acceptance is retained from that exact Git blob. Independent fork acceptance/harness are retained from `4dd6be43453b451615ce04fc9ac4e5792eede46e`. These are historical JavaScript/build executions, not new executions by this reading.

The manifest retains 33 source/evidence objects and 35 exact source/license files. Every Git snapshot was read locally and byte-hashed without fetching. Relevant localhost definitions come from the actual locked client commit. P41's networkSecurity, siteAdapter and pageHandler bytes match both personal revision `f3c72d9fc31a3db8a296c7f2d05b36364395e4fe` and its retained client package-input archive. The separate upstream base is `d59dbd68c2a539d32add72e06d2fd74e9d6d60c2`; the personal definitions are not mislabeled as that upstream blob.

Dreyeck's selected client source is fedwiki/wiki-client `3f61a4862703f492b0d6bfb8695bd665b943bb38`; its historical tested browser asset is independently identified by digest. Their equality is not assumed. Some historical local Nix outputs were unavailable during source capture; no rebuild or substitute checkout was used. Retained source files and original input archives supplied the explicitly qualified evidence.

## Two warranted projections

**Deployment Composition:** 26 Topics, 26 Associations. The local root input links to the resolved client. Fetcher and reconstructed-archive selections use different warrants, including P41 provenance and source-input files. Wiki package composition points to the selected Mech variant. Every package-to-activation edge is OPEN; no current server package is inferred.

**Fork Behavior and Provenance:** 26 Topics, 32 Associations. Browser-origin, site acquisition, actual loopback predicates, forkPage/put, authenticated storage and journal provenance are distinct represented objects. A derived boundary explicitly separates acquired values from a separately supplied preloaded fixture snapshot; JavaScript object identity is not inferred. Policy calls are source-observed; comparison with retained served-bundle execution is derived and bounded to the fixture.

All Associations expose source, target, relation kind, basis and warrant. Observed declarations, retained execution facts, derived comparisons and open activation boundaries remain distinct. Shared configuration objects retain Point/history across projections; absent Points remain explicit. TALA changes geometry, not evidence or represented objects.

## What the fork evidence establishes

The destination-origin browser normally sends an authenticated same-origin PUT with `forkPage`; the server stores that snapshot and journal. Server remoteGet without the snapshot would resolve localhost on the server, not the user's workstation. A locally initiated normal fork writes to its own local origin; selecting a remote destination is a separate operation.

The retained fixture uses a non-loopback *hostname* mapped to loopback. The client's public-origin classification is not a verified public-IP browser network boundary.

- Dreyeck: controlled source acquisition succeeds; localhost:3000 provenance is preserved.
- P41: acquisition is rejected before any source request; a separately preloaded snapshot loses its source site.
- Localhost recipe: controlled acquisition succeeds; source provenance is stripped.

Each final case has eight passing controls, including authorization denial/no mutation, unavailable source and real distinct-origin CORS rejection. Negative controls do not promote blocked/partial workflows to success. The failed invalid-favicon fixture attempt remains separately recorded. No client/server policy was changed.

## Mech and remaining boundaries

Both profiles retain unchanged upstream `a028b4bba04e539dcaa090423d38a00a0050489d`. The upstream profile has 31 commands; Discourse adds EXTRACT/EDGES/DEBUG and wraps role WALK, with ordinary WALK delegated. The reading links the existing upstream catalog object and separately verified committed installer/entry/build definitions, preserving their different evidence roles.

Mech derivation success, primary Wiki package construction, isolated browser operation and activation are separate records. The retained original trusted CODE trails run returns two aspects; the Discourse chain is separately tested. Full behavioral equivalence remains FAIL (33 pass, 2 differences), with four duplicate-slug cases and four uninstrumented controls preserved. No sorting wrapper, graph-resolution normalization or typed-relations projection is introduced.

Active hosts, future hyperdoc Wiki profile, Linux package/runtime acceptance, production Solo lifecycle, CODE page/import/message trust, HTTPS/Local Network Access/authentication and intended transfer/provenance policy remain unverified or undecided. Ward's temporary LISTEN behavior is not incorporated. Earlier HyperDoc deployment observations and Mech pre-commit acceptance records are unchanged.

## Verification

Durable entry points:

```lisp
(asdf:test-system "dreyeck/fedwiki-config/reading/tests" :force t)
(asdf:test-system "dreyeck/fedwiki-config/tala/tests")
(asdf:test-system "dreyeck/mech-intake/reading/tests")
(asdf:test-system "dreyeck/mech-intake/tala/tests")
(asdf:test-system "dreyeck/nested-actions/reading/tests")
(asdf:test-system "dreyeck/git/tests")
(asdf:test-system "dreyeck/topicmap/tests")
(asdf:test-system "dreyeck/topicmap/tala/tests")
(asdf:test-system "dreyeck/topicmap/tala/reading/tests")
(asdf:test-system "dreyeck/catalog/tests")
```

Fresh cached SBCL 2.4.10 processes use no sysinit/userinit and never reload the long-running image. Guarded structural authoring uses the existing editor at `38afb02d79838d4098589c2e203ba39799a44853`; Text Pages use the existing HTML DSL and are reparsed. Normal Catalog acceptance excludes the authoring runtime. Test commands, log digests and final outcomes are in `docs/fedwiki-config-reading-executors.json`.

The source slice is limited to the new reading, retained evidence, tests, ASDF membership and one Catalog discovery assertion. Wiki sources remain read-only. No server access, Git fetch, deployment, service operation or production data change occurred. The authorized local commit follows successful verification; its OID is supplied in the executor handoff, not invented in pre-commit evidence.
