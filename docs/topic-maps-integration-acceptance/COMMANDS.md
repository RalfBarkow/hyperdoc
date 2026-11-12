# Exact acceptance commands

These commands were actually executed. Each adjacent JSON record retains UTC times and the real exit status. Host-specific roots and the prepared dependency registry must be reconstructed on another machine. Nix commands ending in `-outer` and the Nix exporter check ran outside the outer command sandbox with Nix sandboxing retained.

## browser

Exit code: `0`. Record: [browser.json](browser.json).

```sh
cd /workspace/work/acceptance-pr42
env python3 /workspace/work/topic-maps-integration-acceptance/docs/topic-maps-integration-acceptance/browser.py
```

## namespace-preflight

Exit code: `1`. Record: [namespace-preflight.json](namespace-preflight.json).

```sh
cd /workspace/work/acceptance-pr42
env unshare --user --map-root-user --mount --pid --fork /bin/true
```

## nix-catalog-derivation

Exit code: `0`. Record: [nix-catalog-derivation.json](nix-catalog-derivation.json).

```sh
cd /workspace/work/acceptance-pr42
env /workspace/tools/nix-portable-data/.nix-portable/bin/nix --extra-experimental-features nix-command derivation show --store /workspace/work/acceptance-nix-root /nix/store/bjvr6bjh2y18mc5zkm9vhyrb30d17a2i-hyperdoc-catalog.drv /nix/store/jh789q8by2ihdnlikw746in5cvmwrxcf-topic-maps-c446a822-acceptance-source.drv
```

## nix-closure

Exit code: `0`. Record: [nix-closure.json](nix-closure.json).

```sh
cd /workspace/work/acceptance-pr42
env /workspace/tools/nix-portable-data/.nix-portable/bin/nix --extra-experimental-features nix-command path-info --store /workspace/work/acceptance-nix-root --json --recursive /nix/store/4c0bkyyin13xpby4r8cvnxr5w73w662d-hyperdoc-catalog /nix/store/g72z50szzsc5b5b3id0xyh2cxwd2iyy8-topic-maps-c446a822-acceptance-source
```

## nix-exporter-check

Exit code: `0`. Record: [nix-exporter-check.json](nix-exporter-check.json).

```sh
cd /workspace/work/acceptance-pr42
env XDG_CACHE_HOME=/workspace/work/acceptance-nix-cache XDG_STATE_HOME=/workspace/work/acceptance-nix-state /workspace/tools/nix-portable-data/.nix-portable/bin/nix build --store /workspace/work/acceptance-nix-root --extra-experimental-features 'nix-command flakes' --option sandbox true --option sandbox-fallback false --option build-users-group '' --no-write-lock-file --no-link --print-build-logs --show-trace --file /workspace/work/topic-maps-integration-acceptance/docs/topic-maps-integration-acceptance/candidate-build.nix exporter-check
```

## nix-full-candidate

Exit code: `1`. Record: [nix-full-candidate.json](nix-full-candidate.json).

```sh
cd /workspace/work/acceptance-pr42
env 'NIX_CONFIG=experimental-features = nix-command flakes' /workspace/tools/nix-portable-data/.nix-portable/bin/nix build --option sandbox true --option sandbox-fallback false --no-write-lock-file --no-link --print-build-logs --show-trace --file /workspace/work/topic-maps-integration-acceptance/docs/topic-maps-integration-acceptance/candidate-build.nix catalog
```

## nix-full-candidate-outer

Exit code: `0`. Record: [nix-full-candidate-outer.json](nix-full-candidate-outer.json).

```sh
cd /workspace/work/acceptance-pr42
env XDG_CACHE_HOME=/workspace/work/acceptance-nix-cache XDG_STATE_HOME=/workspace/work/acceptance-nix-state /workspace/tools/nix-portable-data/.nix-portable/bin/nix build --store /workspace/work/acceptance-nix-root --extra-experimental-features 'nix-command flakes' --option sandbox true --option sandbox-fallback false --option build-users-group '' --no-write-lock-file --no-link --print-build-logs --show-trace --file /workspace/work/topic-maps-integration-acceptance/docs/topic-maps-integration-acceptance/candidate-build.nix catalog
```

## nix-full-candidate-private

Exit code: `1`. Record: [nix-full-candidate-private.json](nix-full-candidate-private.json).

```sh
cd /workspace/work/acceptance-pr42
env XDG_CACHE_HOME=/workspace/work/acceptance-nix-cache XDG_STATE_HOME=/workspace/work/acceptance-nix-state /workspace/tools/nix-portable-data/.nix-portable/bin/nix build --store /workspace/work/acceptance-nix-root --extra-experimental-features 'nix-command flakes' --option sandbox true --option sandbox-fallback false --option build-users-group '' --no-write-lock-file --no-link --print-build-logs --show-trace --file /workspace/work/topic-maps-integration-acceptance/docs/topic-maps-integration-acceptance/candidate-build.nix catalog
```

## nix-full-candidate-relocated

Exit code: `1`. Record: [nix-full-candidate-relocated.json](nix-full-candidate-relocated.json).

```sh
cd /workspace/work/acceptance-pr42
env NIX_CONF_DIR=/workspace/tools/nix-portable-data/.nix-portable/conf XDG_CACHE_HOME=/workspace/work/acceptance-nix-cache XDG_STATE_HOME=/workspace/work/acceptance-nix-state /workspace/tools/nix-portable-data/.nix-portable/bin/nix build --option sandbox true --option sandbox-fallback false --no-write-lock-file --no-link --print-build-logs --show-trace --file /workspace/work/topic-maps-integration-acceptance/docs/topic-maps-integration-acceptance/candidate-build.nix catalog
```

## pr1-focused

Exit code: `0`. Record: [pr1-focused.json](pr1-focused.json).

```sh
cd /workspace/work/acceptance-runtime/topic-maps-c446a822
env /workspace/scratch/tmdm-mcp-portable/bin/sbcl --noinform --no-sysinit --no-userinit --non-interactive --load /workspace/work/topic-maps-integration-acceptance/docs/topic-maps-integration-acceptance/pr1-focused.lisp
```

## pr1-full-launcher

Exit code: `0`. Record: [pr1-full-launcher.json](pr1-full-launcher.json).

```sh
cd /workspace/work/acceptance-runtime/topic-maps-c446a822
env SBCL=/workspace/scratch/tmdm-mcp-portable/bin/sbcl TOPIC_MAPS_REPORT=/workspace/work/topic-maps-integration-acceptance/docs/topic-maps-integration-acceptance/pr1-reports/validation.json sh scripts/test.sh
```

## pr41-planning

Exit code: `0`. Record: [pr41-planning.json](pr41-planning.json).

```sh
cd /workspace/work/acceptance-pr41
env DEFEDERATION_REPO=/workspace/work/acceptance-pr41 TOPIC_MAPS_EVIDENCE_REPOSITORY=/workspace/topic-maps /workspace/scratch/tmdm-mcp-portable/bin/sbcl --noinform --no-sysinit --no-userinit --non-interactive --load /workspace/work/topic-maps-integration-acceptance/docs/topic-maps-integration-acceptance/hyperdoc-bootstrap.lisp --load docs/topic-maps-conformance-planning/run.lisp
```

## pr42-exporter

Exit code: `1`. Record: [pr42-exporter.json](pr42-exporter.json).

```sh
cd /workspace/work/acceptance-pr42
env DEFEDERATION_REPO=/workspace/work/acceptance-pr42 TOPIC_MAPS_CANDIDATE_ROOT=/workspace/work/acceptance-runtime/topic-maps-c446a822 TOPIC_MAPS_EVIDENCE_REPOSITORY=/workspace/topic-maps /workspace/scratch/tmdm-mcp-portable/bin/sbcl --noinform --no-sysinit --no-userinit --non-interactive --load /workspace/work/topic-maps-integration-acceptance/docs/topic-maps-integration-acceptance/hyperdoc-bootstrap.lisp --load docs/topic-maps-instance-of-export/run.lisp
```

## pr42-exporter-clean

Exit code: `0`. Record: [pr42-exporter-clean.json](pr42-exporter-clean.json).

```sh
cd /workspace/work/acceptance-pr42
env DEFEDERATION_REPO=/workspace/work/acceptance-pr42 TOPIC_MAPS_CANDIDATE_ROOT=/workspace/work/acceptance-runtime/pr42/topic-maps-c446a822 TOPIC_MAPS_EVIDENCE_REPOSITORY=/workspace/topic-maps /workspace/scratch/tmdm-mcp-portable/bin/sbcl --noinform --no-sysinit --no-userinit --non-interactive --load /workspace/work/topic-maps-integration-acceptance/docs/topic-maps-integration-acceptance/hyperdoc-bootstrap.lisp --load docs/topic-maps-instance-of-export/run.lisp
```

## pr42-old-pin

Exit code: `0`. Record: [pr42-old-pin.json](pr42-old-pin.json).

```sh
cd /workspace/work/acceptance-pr42
env DEFEDERATION_REPO=/workspace/work/acceptance-pr42 TOPIC_MAPS_CANDIDATE_ROOT=/workspace/work/acceptance-runtime/active/topic-maps-88994c1b /workspace/scratch/tmdm-mcp-portable/bin/sbcl --noinform --no-sysinit --no-userinit --non-interactive --load /workspace/work/topic-maps-integration-acceptance/docs/topic-maps-integration-acceptance/hyperdoc-bootstrap.lisp --load docs/topic-maps-instance-of-export/old-pin.lisp
```

## snapshot-reverify

Exit code: `0`. Record: [snapshot-reverify.json](snapshot-reverify.json).

```sh
cd /workspace/work/acceptance-pr42
env PATH=/workspace/tools/nix-portable-data/.nix-portable/bin:/usr/local/bin:/usr/bin:/bin 'NIX_CONFIG=experimental-features = nix-command flakes' python3 scripts/topic-maps-snapshot.py verify /workspace/work/topic-maps-readers-source.git c446a8228017f405c3a2650ca893e9450ac7cd7b nix/topic-maps-c446a822-runtime.tar.gz nix/topic-maps-c446a822.manifest /workspace/work/topic-maps-integration-acceptance/docs/topic-maps-integration-acceptance/snapshot-reverified.json
```
