# Wiki source publication and deployment-page reading

The task preserves the existing Work HyperBook and improves its two deployment explanations. It adds contextual objects for operator observations, package identity, service/process records, Nix source selection, activation and unresolved source-to-runtime relationships. The four original observation functions in deployment-reading.lisp remain byte-for-byte unchanged. No host was accessed or activated.

## Published Wiki sources

Configured remote: origin, git@github.com:RalfBarkow/wiki.git. The remote refs were queried before each normal fast-forward push. Shared composition 9a9afef387e8c05587c95171119d627117798f56 and localhost 4dd6be43453b451615ce04fc9ac4e5792eede46e were already publicly resolvable and were not pushed again.

- dreyeck.ch: 548ee4c31ec7824bf19954b745f12b3b5212fc2b → db98a893a7c710fcb3506150b68b1aa08915c47e.
- wiki.ralfbarkow.ch: b42eb888d6e5d59803667c6320e0779523fc265c → 6774447eff17d705a3083378ab2c9a93b237cf91.

After publication, separate ls-remote queries matched each expected OID. Canonical GitHub HTML responses succeeded with the actual commit OID, and GitHub API responses independently matched the full OID. The first Dreyeck canonical request received a gateway timeout after its successful push; a bounded read retry succeeded, without repeating that push. The measured publication record is retained under dreyeck/work/deployment-evidence/publication.json.

## Reader journey

From Working on HyperDoc → Work Breakdown → Operational reading, select the RalfBarkow deployment explanation. Read what the Wiki server, systemd and Nix do. Inspect the historical witness, its Nix package, its repository-qualified revision, file-at-revision and exact retained recipe. Return to the explanation and compare the separate newer declared configuration and unresolved activation boundary. Continue to Reading FedWiki Configuration and Fork Behavior, then use its explained return link to the Dreyeck deployment page. Inspect the separate HyperDoc/Wiki services, recorded source selection and activation operation, and return to Work Breakdown.

The RalfBarkow opening does not dump the unknown-time P41 witness. The Dreyeck opening starts with the latest supported 8 October capture and separates the exact HyperDoc hostname from the wildcard Node Wiki farm, with the MCP exception retained. September/October observations remain separate, with their capture limits and warrants. Long revisions, paths and raw process properties sit behind contextual Inspector views. Store paths are package/source resources, not Git objects or live processes. Published external objects do not imply a locally attached checkout.

## Verification

Durable test entry points:

```lisp
(asdf:test-system "dreyeck/work/reading/tests" :force t)
(asdf:test-system "dreyeck/fedwiki-config/reading/tests")
(asdf:test-system "dreyeck/fedwiki-config/tala/tests")
(asdf:test-system "dreyeck/mech-intake/reading/tests")
(asdf:test-system "dreyeck/git/tests")
(asdf:test-system "dreyeck/topicmap/tests")
(asdf:test-system "dreyeck/topicmap/tala/tests")
(asdf:test-system "dreyeck/topicmap/tala/reading/tests")
(asdf:test-system "dreyeck/catalog/tests")
```

The new reader contract has 227 assertions for exact native links, Inspector values, source/files, distinct identities, preserved raw observations, activation boundaries and return paths. Original negative controls still reject invented timestamps, promoted inferences and source identities assigned to a process.

Visible verification uses scripts/test-deployment-reading-browser.mjs with explicit cached Lisp wrapper, Playwright-core and browser paths. It starts only a disposable fresh ordinary CLOG Inspector on loopback, with no authoring capability, production URL or page write. Browser-native clicks traverse the real Inspector and both directions between books. At 1440px and 380px, twenty content/layout checks pass with no horizontal content overflow, page errors or external requests. Screenshots were visually inspected; three narrow examples are retained in docs/deployment-reading-layout. This is local UI evidence, not production-server verification. The original task attachment contained text; no additional screenshot file was available.

The browser source-location label initially differed from the harness assumption. The corrected harness uses the actual native label. A contextual retained-source default view ensures the file's evidence-location route returns to the deployment explanation. No dispatcher, source semantics or general UI framework was changed.

All verification uses fresh processes. The existing long-running Lisp image is neither read for definitions nor reloaded. Source objects retain exact historical Git blobs with qualified identities and hashes, without optional checkout bindings or implicit fetches.

## Publication versus serving

HyperDoc began clean on dreyeck.ch at 454ee9e32c794bb66a4339e09e523c85b506ec42; its GitHub remote resolved to the same parent. Only the intended reading, contextual source/evidence, tests, layout evidence and existing ASDF membership are committed. The authorized final source publication uses github's existing dreyeck.ch ref and a normal fast-forward; the exact new commit/ref is reported after that operation.

Publishing these sources does not activate a Wiki profile or restart HyperDoc. The latest supplied HyperDoc host capture remains 2026-10-08T03:29:16Z, with lock/store content corresponding to fab214334279bc5d3df0f2f624d34e6a1bdc1897. It does not prove the server's current state after later publication. RalfBarkow's P41 witness still has no supplied capture time. No current service package, new deployment or loaded-definition claim is inferred from the newly published branches.
