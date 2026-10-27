#!/bin/bash
# Serve the HyperDoc reading "Deploying Topic Maps with HyperDoc", with its ASDF Method Collision extension, on
# 127.0.0.1 only, in the foreground. Ctrl-C stops it.
#
#   dreyeck/work/topic-maps-deployment-review/serve.sh [PORT]        PORT defaults to 18777
#
# Starting compiles and loads code and serves pages; no review experiment runs until you press its button in the
# reading. HyperDoc comes from this working tree, Topic Maps from its pinned store snapshot (b2eecffa without reports/).
# If that snapshot is missing from the Nix store, it is recreated from the local Topic Maps repository and checked
# against nix/topic-maps-b2eecffa.manifest; no GC root is created. The compilation cache is kept under
# HYPERDOC_REVIEW_STATE (default ~/Library/Caches/hyperdoc-topic-maps-deployment-review); the site root is temporary.
# The server runs under sandbox-exec: no network beyond localhost, no writes to the HyperDoc or Topic Maps repositories.
set -euo pipefail

port="${1:-18777}"
if ! [[ "$port" =~ ^[0-9]+$ ]] || (( port < 1024 || port > 65535 )); then
  echo "serve.sh: PORT must be a number from 1024 to 65535, not '$port'." >&2; exit 2
fi
here=$(cd "$(dirname "$0")" && pwd -P)
hyperdoc=$(cd "$here/../../.." && pwd -P)
topic_maps_repository="${TOPIC_MAPS_REPOSITORY:-/Users/rgb/workspace/topic-maps}"
state="${HYPERDOC_REVIEW_STATE:-$HOME/Library/Caches/hyperdoc-topic-maps-deployment-review}"

# The pinned runtime and sources: the SBCL environment and Inspector sources of HyperDoc's x86_64-darwin flake lock,
# and the Topic Maps snapshot that nix/topic-maps-source.nix pins.
sbcl=/nix/store/8j4gxfa63znzgcba9x1mw68yz7cb0ywf-sbcl-with-packages/bin/sbcl
registry=(/nix/store/7l95gid3niz995qqpkgclj6355k50phf-source /nix/store/w26nr9dxpfsyzbviphnaaydmcww2h3y6-source
          /nix/store/ibq9zs9js02ln87vjmcl6xdafvpxzffx-source /nix/store/p62cd9zn5gnrd34wgbjjnqragxwx6dhh-source
          /nix/store/w15dbn9gy780n3p9k5b69dr3rrr5lczr-source /nix/store/9zkvhs70z8w06kximfrw3zm099qa87vj-source)
commit=b2eecffa05de4fce41c10ae1ada9ae11a0c6e7dc
snapshot=/nix/store/1l6im929rknvgp3jxx83i01crcf3ahmg-source
manifest="$hyperdoc/nix/topic-maps-b2eecffa.manifest"

fail() { echo "serve.sh: $*" >&2; exit 1; }
[[ -x "$sbcl" ]] || fail "the SBCL runtime $sbcl is not in the Nix store. In $hyperdoc: nix build --no-link .#packages.x86_64-darwin.hyperdoc-catalog"
for p in "${registry[@]}"; do [[ -d "$p" ]] || fail "the Inspector source $p is not in the Nix store (see the line above for how to bring the runtime back)."; done
[[ -x /usr/bin/sandbox-exec ]] || fail "/usr/bin/sandbox-exec is missing."
if lsof -w -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; then
  fail "port $port is in use: $(lsof -w -nP -iTCP:"$port" -sTCP:LISTEN | awk 'NR==2{print $1" pid "$2}')."
fi

if [[ ! -d "$snapshot" ]]; then
  echo "The Topic Maps snapshot is not in the Nix store; recreating it from $topic_maps_repository at $commit ..."
  [[ "$(git -C "$topic_maps_repository" rev-parse --verify --quiet "$commit^{commit}")" == "$commit" ]] \
    || fail "$topic_maps_repository does not hold commit $commit."
  work=$(mktemp -d "${TMPDIR:-/tmp}/hyperdoc-review-snapshot.XXXXXX")
  python3 -I "$hyperdoc/scripts/topic-maps-snapshot.py" create "$topic_maps_repository" "$commit" "$work" >/dev/null
  cmp -s "$work/topic-maps-b2eecffa.manifest" "$manifest" || fail "the recreated manifest differs from $manifest; nothing added."
  tar -xzf "$work/topic-maps-b2eecffa-runtime.tar.gz" -C "$work"
  expected=$(sed -n 's/^ :nar-hash "\(.*\)"$/\1/p' "$manifest")
  actual=$(nix hash path --type sha256 --sri "$work/topic-maps-b2eecffa")
  [[ "$actual" == "$expected" ]] || fail "the recreated snapshot hashes to $actual, not $expected; nothing added."
  added=$(nix store add --mode nar --hash-algo sha256 --name source "$work/topic-maps-b2eecffa")
  rm -rf "$work"
  [[ "$added" == "$snapshot" ]] || fail "the snapshot was added as $added, not $snapshot."
  echo "Recreated $snapshot (NAR hash $expected)."
fi
[[ -f "$snapshot/topic-maps.asd" && ! -e "$snapshot/.git" ]] || fail "$snapshot is not the Topic Maps snapshot."

mkdir -p "$state/cache"
site=$(mktemp -d "${TMPDIR:-/tmp}/hyperdoc-review-site.XXXXXX"); mkdir "$site/pages"
watcher=""
# Under set -e a failing command would end the trap early; the watcher has usually finished already.
cleanup() { if [[ -n "$watcher" ]]; then kill "$watcher" 2>/dev/null || true; fi; rm -rf "$site"; }
trap cleanup EXIT

cat <<EOF
Deploying Topic Maps with HyperDoc, with the ASDF Method Collision extension
  HyperDoc working tree   $hyperdoc
  Topic Maps snapshot     $snapshot ($commit without reports/)
  Topic Maps repository   $topic_maps_repository (read only)
  Compilation cache       $state/cache
  Temporary site root     $site (removed on exit)
  Host and port           127.0.0.1:$port
Loading compiles code on the first start, which takes a few minutes; later starts reuse the cache.
EOF

# Report the address only once the Catalog answers.
( for _ in $(seq 1 1800); do
    if curl -fsS -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null; then
      printf '\nReady: http://127.0.0.1:%s/   (Ctrl-C stops the server)\n' "$port"; exit 0
    fi
    sleep 1
  done ) &
watcher=$!

policy="(version 1)(allow default)(deny network*)(allow network-inbound (local ip \"localhost:*\"))(allow network-outbound (remote ip \"localhost:*\"))(deny file-write* (subpath \"$hyperdoc\"))(deny file-write* (subpath \"$topic_maps_repository\"))"
status=0
env -i HOME="$HOME" USER="${USER:-}" LANG="${LANG:-en_US.UTF-8}" TMPDIR="${TMPDIR:-/tmp}" PATH=/usr/bin:/bin:/usr/sbin:/sbin \
    TOPIC_MAPS_ROOT="$snapshot" TOPIC_MAPS_REPOSITORY="$topic_maps_repository" \
    CL_SOURCE_REGISTRY="$(printf '%s//:' "${registry[@]}")" XDG_CACHE_HOME="$state/cache" \
    HYPERDOC_CATALOG_HOST=127.0.0.1 HYPERDOC_FEDWIKI_SITE_ROOT="$site/" \
    /usr/bin/sandbox-exec -p "$policy" "$sbcl" --noinform --no-sysinit --no-userinit --script "$here/serve.lisp" "$port" \
  || status=$?
echo "Server stopped (exit status $status)."
exit "$status"
