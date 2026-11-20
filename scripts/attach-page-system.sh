#!/usr/bin/env bash
# Attach a HyperDoc work system to a Federated Wiki page as a copy of one commit.
#
#   bash scripts/attach-page-system.sh <work-dir> <slug> <site-root> [commit]
#   bash scripts/attach-page-system.sh dreyeck/work/site-observation site-observation ~/.wiki/wiki.ralfbarkow.ch
#
# The repository stays the source, with its tests. The page gets the files of COMMIT (default HEAD) under
# <site-root>/assets/pages/<slug>/, plus SOURCE (repository, commit, path, time) and SHA256SUMS, so that
# the copy can be checked against the commit it came from. An earlier copy in that directory is replaced.
set -euo pipefail
work=${1:?work directory, e.g. dreyeck/work/site-observation}
slug=${2:?page slug}
site=${3:?site root, e.g. ~/.wiki/wiki.ralfbarkow.ch}
commit=$(git rev-parse --verify "${4:-HEAD}^{commit}")
top=$(git rev-parse --show-toplevel)

[ -f "$top/$work/$slug.asd" ] || git -C "$top" cat-file -e "$commit:$work/$slug.asd" ||
  { echo "No $work/$slug.asd at $commit: the system name must be the slug." >&2; exit 1; }
[ -d "$site/pages" ] || { echo "$site has no pages/ directory: not a wiki site root." >&2; exit 1; }

pages="$site/assets/pages"
target="$pages/$slug"
mkdir -p "$pages"
staging=$(mktemp -d "$pages/.$slug.XXXXXX")
trap 'rm -rf "$staging"' EXIT

git -C "$top" archive "$commit:$work" | tar -x -C "$staging"
if command -v sha256sum >/dev/null; then sum() { sha256sum "$@"; }; else sum() { shasum -a 256 "$@"; }; fi
(cd "$staging" && find . -type f ! -name SHA256SUMS ! -name SOURCE | sed 's|^\./||' | LC_ALL=C sort |
   while read -r f; do sum "$f"; done > SHA256SUMS)
{
  printf 'repository: %s\n' "$(git -C "$top" remote get-url origin 2>/dev/null | sed 's|^git@github.com:|https://github.com/|; s|\.git$||')"
  printf 'commit: %s\n' "$commit"
  printf 'path: %s\n' "$work"
  printf 'attached: %s\n' "$(date -u +%FT%TZ)"
} > "$staging/SOURCE"

rm -rf "$target"
mv "$staging" "$target"
trap - EXIT
echo "Attached $work at $commit to $target"
echo
echo "For the page (assets item: pages/$slug):"
echo "Page-attached ASDF system $slug, a copy of $work at commit $commit. The repository is the source; SOURCE and SHA256SUMS in the page assets record and check the copy."
