#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage: tools/repomix-pack.sh <pack>

Packs:
  core         default project orientation
  dock         Dock/mobile route-first work
  validation   ASDF and smoke-test runner work
  fedwiki      FedWiki story/materialization work
  dmx          DMX annotations/import/workspace work
  deployment   dreyeck/Nix/deploy/release work
  dm6          DM6 Elm/app embedding work
  zotero       Zotero/topic-enrichment work
  full         intentional whole-repo snapshot

The runner uses repomix from PATH first. If it is missing and nix is available,
it falls back to nix run nixpkgs#repomix unless
HYPERDOC_REPOMIX_DISABLE_NIX_FALLBACK=1 is set.
USAGE
}

pack="${1:-}"

case "${pack}" in
  core|dock|validation|fedwiki|dmx|deployment|dm6|zotero|full)
    ;;
  ""|-h|--help)
    usage
    exit 0
    ;;
  *)
    echo "Unknown Repomix pack: ${pack}" >&2
    usage
    exit 2
    ;;
esac

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config="${repo_root}/repomix.config.${pack}.json"

if [[ ! -f "${config}" ]]; then
  echo "Missing Repomix config: ${config}" >&2
  exit 1
fi

cd "${repo_root}"

if command -v repomix >/dev/null 2>&1; then
  exec repomix -c "${config}"
fi

if [[ "${HYPERDOC_REPOMIX_DISABLE_NIX_FALLBACK:-0}" != "1" ]] && command -v nix >/dev/null 2>&1; then
  exec nix run nixpkgs#repomix -- -c "${config}"
fi

echo "Repomix executable not found." >&2
echo "Install/provide repomix, then rerun: repomix -c ${config}" >&2
exit 127
