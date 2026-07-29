#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage: tools/repomix-pack.sh <pack>

Packs:
  core         default project orientation
  roots        Roots of Lisp implementation and validation slice
  dock         Dock/mobile route-first work
  validation   ASDF and smoke-test runner work
  fedwiki      FedWiki story/materialization work
  dmx          DMX annotations/import/workspace work
  deployment   dreyeck/Nix/deploy/release work
  dm6          DM6 Elm/app embedding work
  zotero       Zotero/topic-enrichment work
  full         intentional whole-repo snapshot

The runner uses HYPERDOC_REPOMIX_BIN or repomix from PATH first. If neither is
available and nix is present, it falls back to a pinned x86_64-darwin-compatible
Nixpkgs Repomix unless HYPERDOC_REPOMIX_DISABLE_NIX_FALLBACK=1 is set. Override
that source with HYPERDOC_REPOMIX_NIX_REF when required.
USAGE
}

pack="${1:-}"

case "${pack}" in
  core|roots|dock|validation|fedwiki|dmx|deployment|dm6|zotero|full)
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

repomix_command=()
if [[ -n "${HYPERDOC_REPOMIX_BIN:-}" ]]; then
  if [[ ! -x "${HYPERDOC_REPOMIX_BIN}" ]]; then
    echo "HYPERDOC_REPOMIX_BIN is not executable: ${HYPERDOC_REPOMIX_BIN}" >&2
    exit 127
  fi
  repomix_command=("${HYPERDOC_REPOMIX_BIN}")
elif command -v repomix >/dev/null 2>&1; then
  repomix_command=(repomix)
elif [[ "${HYPERDOC_REPOMIX_DISABLE_NIX_FALLBACK:-0}" != "1" ]] && command -v nix >/dev/null 2>&1; then
  repomix_nix_ref="${HYPERDOC_REPOMIX_NIX_REF:-github:NixOS/nixpkgs/8623c4c20aa4ca2f5fb81510d2944066c3fb0d96#repomix}"
  repomix_command=(nix run "${repomix_nix_ref}" --)
else
  echo "Repomix executable not found." >&2
  echo "Install/provide repomix, then rerun: repomix -c ${config}" >&2
  exit 127
fi

repomix_version="$("${repomix_command[@]}" --version | tail -n 1 | tr -d '[:space:]')"
if [[ -z "${repomix_version}" ]]; then
  echo "Could not determine Repomix version." >&2
  exit 1
fi

generation_marker="$(mktemp "${TMPDIR:-/tmp}/hyperdoc-repomix-generation.XXXXXX")"
trap 'rm -f "${generation_marker}"' EXIT

"${repomix_command[@]}" -c "${config}"

output_path="$(jq -er '.output.filePath' "${config}")"
split_limit="$(jq -er '.output.splitOutput // 0' "${config}")"
parts=()

if (( split_limit > 0 )); then
  output_extension=".${output_path##*.}"
  output_stem="${output_path%"${output_extension}"}"
  part_number=1
  while true; do
    candidate="${output_stem}.${part_number}${output_extension}"
    if [[ ! -f "${candidate}" ]] || [[ ! "${candidate}" -nt "${generation_marker}" ]]; then
      break
    fi
    parts+=("${candidate}")
    part_number=$((part_number + 1))
  done
else
  if [[ -f "${output_path}" ]] && [[ "${output_path}" -nt "${generation_marker}" ]]; then
    parts+=("${output_path}")
  fi
fi

if [[ "${#parts[@]}" -eq 0 ]]; then
  echo "Repomix did not produce a current output part for ${pack}." >&2
  exit 1
fi

manifest_path="${output_path%.*}.manifest.json"
tools/repomix-snapshot-manifest.sh create \
  "${pack}" \
  "${repomix_version}" \
  "${config}" \
  "${manifest_path}" \
  "${parts[@]}"
tools/repomix-snapshot-manifest.sh verify "${manifest_path}"

printf 'Snapshot bundle ready (%s):\n' "${pack}"
printf '  %s\n' "${parts[@]}" "${manifest_path}"
