# `checks.x86_64-linux.catalog` in a strict Linux build sandbox (2026-11-03)

Builder: x86_64-linux cloud container, Nix 2.34.6, `sandbox = true`, run with `--option sandbox-fallback false` so that a sandbox
that could not be set up would fail the build instead of being dropped. A probe derivation built the same way saw uid 1000,
hostname `localhost`, only `/bin /build /dev /etc /nix /proc /tmp`, and `getaddrinfo("ward.voices.ustawi.wiki")` failing with
`EAI_AGAIN` ("Temporary failure in name resolution") [obs].

The flake's GitHub inputs could not be downloaded as tarballs through the container's proxy. They were fetched with git at the
locked revisions, exported with `git archive` and added to the store; each `nix hash path` equals its `narHash` in `flake.lock` [obs].
No input, pin or lock entry was changed.

| Tree | Result |
|---|---|
| `dreyeck.ch` `19e824d` | fails before the walk, in `check-view`: the E3 edit-view diagnosis refuses (`DIAGNOSIS-SOURCE-ERROR`, observation lacks `hunchentoot`) [obs] |
| `19e824d` + `b989c01` (that fix only) | fails before the walk, in `check-reviewed-controls-match-their-sites`: `used but not registered: ("fedwiki-original-editor-demo/reread")` [obs]. RalfBarkow/hyperdoc#12 fixes both |
| RalfBarkow/hyperdoc#12 head `5c6a604` | fails in the walk: `Unhandled USOCKET:NS-TRY-AGAIN-ERROR` in a FedWiki initializer thread, host `ward.voices.ustawi.wiki`, then `unhandled condition in --disable-debugger mode, quitting` (`failure-before.txt`) [obs] |
| `5c6a604` + the offline walk (tree `64c4e471…`) | **exit 0** [obs]. Every step of the contract passes, including 6 executable tests (202 s). The walk: 300 objects, 9538 controls (inert 8478, slot-reader 993, reviewed 11, reviewed-class 56, refused 0, unknown 0); connections refused to `mech.dreyeck.ch`, `next.ward.dojo.fed.wiki`, `ward.voices.ustawi.wiki` (`public-views.log`) |
| The same tree, the walk's negative control (`negative-control.nix`, `negative-control.lisp`): `check-reachable-controls` unchanged, `served` replaced by `developing` | the walk fails, as it must: 300 objects, 12713 controls, 3140 of them of no allowed kind (plain `HV:THUNK`s and others), at the assertion "Controls reachable when served that are none of the allowed kinds"; the same three hosts refused (`negative-control.txt`) [obs] |

The counts of the offline walk equal those recorded for revision 2 on Linux (sandbox off) and Darwin (README, "The walk on both
platforms"). The diagnostic run recorded in RalfBarkow/hyperdoc#12, whose probe recorder ended its thread, met 9534 controls
(989 slot readers). Not investigated; probably because such a wiki's status stays a finished thread rather than a failure.
