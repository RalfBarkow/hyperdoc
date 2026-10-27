#!/usr/bin/env bash
# Run the project CTM emitter on the proposals in its own process, with the Topic Maps revision the Project Workspace is
# pinned to (a clean clone of 5a4a668), never in the reading's image. The same pinned SBCL and registry as serve.sh; a fresh
# compilation cache; no network; nothing in either repository is writable but this directory's evidence/.
#   dreyeck/work/topic-maps-deployment-review/proposals/run-emitter-crosscheck.sh
# Environment: TOPIC_MAPS_5A4A668 (default /Users/rgb/workspace/topic-maps-hyperdoc-5a4a668).
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd -P)
hyperdoc=$(cd "$here/../../../.." && pwd -P)
clone="${TOPIC_MAPS_5A4A668:-/Users/rgb/workspace/topic-maps-hyperdoc-5a4a668}"
sbcl=/nix/store/8j4gxfa63znzgcba9x1mw68yz7cb0ywf-sbcl-with-packages/bin/sbcl
registry=(/nix/store/7l95gid3niz995qqpkgclj6355k50phf-source /nix/store/w26nr9dxpfsyzbviphnaaydmcww2h3y6-source
          /nix/store/ibq9zs9js02ln87vjmcl6xdafvpxzffx-source /nix/store/p62cd9zn5gnrd34wgbjjnqragxwx6dhh-source
          /nix/store/w15dbn9gy780n3p9k5b69dr3rrr5lczr-source /nix/store/9zkvhs70z8w06kximfrw3zm099qa87vj-source)
fail() { echo "run-emitter-crosscheck.sh: $*" >&2; exit 1; }
[[ -x "$sbcl" ]] || fail "the SBCL runtime $sbcl is not in the Nix store"
[[ "$(git -C "$clone" rev-parse HEAD)" == 5a4a66850403cdfe2755c6c88083a8e31af89628 ]] || fail "$clone is not at 5a4a668"
[[ -z "$(git -C "$clone" status --porcelain)" ]] || fail "$clone is not clean"
cache=$(mktemp -d "${TMPDIR:-/tmp}/tmd-crosscheck-cache.XXXXXX"); trap 'rm -rf "$cache"' EXIT
mkdir -p "$here/evidence"
policy="(version 1)(allow default)(deny network*)(deny file-write* (subpath \"$hyperdoc\"))(deny file-write* (subpath \"$clone\"))(deny file-write* (subpath \"/Users/rgb/workspace/topic-maps\"))(allow file-write* (subpath \"$here/evidence\"))"
cd "$hyperdoc"
env -i HOME="$HOME" USER="${USER:-}" LANG="${LANG:-en_US.UTF-8}" TMPDIR="${TMPDIR:-/tmp}" PATH=/usr/bin:/bin:/usr/sbin:/sbin \
    TOPIC_MAPS_ROOT="$clone" CL_SOURCE_REGISTRY="$(printf '%s//:' "${registry[@]}")" XDG_CACHE_HOME="$cache" \
    /usr/bin/sandbox-exec -p "$policy" "$sbcl" --noinform --no-sysinit --no-userinit --non-interactive \
    --load scripts/tmdm-model-bootstrap.lisp --load "$here/emitter-crosscheck.lisp"
