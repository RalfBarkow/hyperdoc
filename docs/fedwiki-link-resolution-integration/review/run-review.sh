#!/usr/bin/env bash
# Re-runs every check of the PR #31 / PR #32 integration comparison against the pinned commits.
#   run-review.sh OUT_DIR
# Needs: git >= 2.38 (merge-tree --write-tree), SBCL with the HyperDoc dependency closure on the ASDF source registry
# (nix develop; or HYPERDOC_RUNTIME_REGISTRY = the closure alone), and the three PR commits in this repository's object store:
#   git fetch origin pull/31/head pull/32/head pull/33/head
# Optional: FEDWIKI_JAVA_ROOT = a clean fedwiki-java checkout at b58fb43 (JDK 11+, python3) for the two Java reference runs.
# Each PR is extracted unmodified with git archive into a private temporary directory, removed at exit. Nothing in this
# checkout, in the PR branches or in fedwiki-java is changed; merge-tree only adds unreferenced objects to the object store.
# Every Lisp process gets an empty HOME and its own FASL cache; with unshare available it runs without a network.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
REPO=$(git -C "$HERE" rev-parse --show-toplevel)
OUT=${1:?usage: run-review.sh OUT_DIR}; mkdir -p "$OUT"; OUT=$(cd "$OUT" && pwd)
SBCL=${SBCL:-sbcl}
REGISTRY=${HYPERDOC_RUNTIME_REGISTRY:-${CL_SOURCE_REGISTRY:-}}
PR31=befce10dc0055222c33d9736723a05d0122a0c9d
PR32=e1ab2f570ee793e301c5af706cbcf2fc984c02a9
PR33=68971d55f68273b77e1d33186bc66e9f019c0902
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
if unshare --net true 2>/dev/null; then NET=(unshare --net)
elif unshare -rn true 2>/dev/null; then NET=(unshare -rn)
else NET=(); fi
SUMMARY=$OUT/summary.log; : > "$SUMMARY"
note() { echo "$*" | tee -a "$SUMMARY"; }
note "REVIEW-RUN pr31=$PR31 pr32=$PR32 pr33=$PR33 network-isolation=${NET[*]:-none}"
for c in $PR31 $PR32 $PR33; do
  git -C "$REPO" cat-file -e "$c^{commit}" 2>/dev/null || { note "MISSING-COMMIT $c: git fetch origin pull/31/head pull/32/head pull/33/head"; exit 2; }
done
extract() { mkdir -p "$WORK/$1" && git -C "$REPO" archive "$2" | tar -x -C "$WORK/$1"; }
extract pr31 $PR31; extract pr32 $PR32
extract merged31 "$(git -C "$REPO" merge-tree --write-tree $PR33 $PR31 | head -1)"
extract merged32 "$(git -C "$REPO" merge-tree --write-tree $PR33 $PR32 | head -1)"
# keep STEP REGEX: the step's marker lines, with the private temporary directory replaced by <WORK>, trailing blanks removed.
keep() { grep -E "$2" "$WORK/$1.raw" | sed -e "s|$WORK|<WORK>|g" -e 's/[[:space:]]*$//' > "$OUT/$1.log"; }
# lisp STEP TREE SCRIPT MARKER REGEX [VAR=VALUE ...]
lisp() {
  local step=$1 tree=$2 script=$3 marker=$4 regex=$5; shift 5
  mkdir -p "$WORK/home-$step" "$WORK/cache-$step"
  (cd "$tree" && env HOME="$WORK/home-$step" XDG_CACHE_HOME="$WORK/cache-$step" CL_SOURCE_REGISTRY="$tree//:$REGISTRY" \
     PR_TREE="$tree" "$@" "${NET[@]}" "$SBCL" --noinform --no-sysinit --no-userinit --non-interactive --load "$script") \
     > "$WORK/$step.raw" 2>&1
  local rc=$?; keep "$step" "$regex"
  note "STEP $step exit=$rc marker=$(grep -qE "$marker" "$WORK/$step.raw" && echo present || echo ABSENT)"
}
P=$HERE/probes
mkdir -p "$WORK/empty"
lisp order-equivalence "$WORK/empty" "$P/order-equivalence.lisp" '^ORDER-EQUIVALENCE 20000 random inputs, 0 differences' '^ORDER' \
     PR31_TREE="$WORK/pr31" PR32_TREE="$WORK/pr32"
lisp probes31 "$WORK/pr31" "$P/probes31.lisp" '^P31-DONE' '^P31'
lisp probes32 "$WORK/pr32" "$P/probes32.lisp" '^P32-DONE' '^P32 '
lisp prim32 "$WORK/pr32" "$P/prim32.lisp" '^P32P X6' '^P32P'
S31='^(LINK-RESOLUTION|MUTANT-KILLED|HYPERDOC-JAVA-CONTEXT-PASS|JAVA-DERIVED)'
S32='^(LINK-RESOLUTION|FEDWIKI-LINK-RESOLUTION|DEFEDERATION|CONSOLIDATION|REVIEW|REMOTE-CONTROL|DOCUMENTATION)'
lisp suite31 "$WORK/pr31" "$WORK/pr31/scripts/test-link-resolution.lisp" '^JAVA-DERIVED-LINK-RESOLUTION-ACCEPTANCE-PASS' "$S31"
lisp suite32 "$WORK/pr32" "$WORK/pr32/scripts/test-fedwiki-link-resolution.lisp" '^LINK-RESOLUTION-ALL-PASS' "$S32"
lisp critic-reader32 "$WORK/pr32" "$P/critic-reader-32.lisp" '^FEDWIKI-LINK-RESOLUTION-CRITIC-PASS' '^(FEDWIKI-LINK-RESOLUTION-CRITIC|CRITIC-READER)'
lisp hyperdoc-comparison32 "$WORK/pr32" "$WORK/pr32/docs/fedwiki-link-resolution/evidence/hyperdoc-comparison.lisp" '^HYPERDOC-COMPARISON DONE' '^HYPERDOC-COMPARISON'
if diff -q "$OUT/hyperdoc-comparison32.log" "$WORK/pr32/docs/fedwiki-link-resolution/evidence/hyperdoc-comparison.log" >/dev/null
then note "COMPARE hyperdoc-comparison32 identical to PR #32's committed log"
else note "COMPARE hyperdoc-comparison32 DIFFERS from PR #32's committed log"; fi
lisp merged31-suite "$WORK/merged31" "$WORK/merged31/scripts/test-link-resolution.lisp" '^JAVA-DERIVED-LINK-RESOLUTION-ACCEPTANCE-PASS' "$S31"
lisp merged32-suite "$WORK/merged32" "$WORK/merged32/scripts/test-fedwiki-link-resolution.lisp" '^LINK-RESOLUTION-ALL-PASS' "$S32"
if [ -n "${FEDWIKI_JAVA_ROOT:-}" ]; then
  J=$(cd "$FEDWIKI_JAVA_ROOT" && pwd)
  (cd "$WORK" && env -u JAVA_TOOL_OPTIONS FEDWIKI_JAVA_ROOT="$J" "${NET[@]}" python3 -I "$WORK/pr31/scripts/test-fedwiki-java-reference.py") > "$WORK/java31.raw" 2>&1
  rc=$?; keep java31 '^JAVA-REFERENCE'
  note "STEP java31 exit=$rc marker=$(grep -q '^JAVA-REFERENCE-ALL-PASS' "$WORK/java31.raw" && echo present || echo ABSENT) cases=$(grep -c '^JAVA-REFERENCE-PASS ' "$WORK/java31.raw")"
  # PR #32's runner puts itself into an empty network namespace; it writes only --out.
  (cd "$WORK" && env -u JAVA_TOOL_OPTIONS python3 -I "$WORK/pr32/tests/fedwiki-java-reference/run-reference.py" --fedwiki-java "$J" --out "$WORK/observed32.json") > "$WORK/java32.raw" 2>&1
  rc=$?; keep java32 '.'
  if cmp -s "$WORK/observed32.json" "$WORK/pr32/tests/fedwiki-java-reference/observed.json"
  then note "STEP java32 exit=$rc observed.json byte-identical to PR #32's committed file"
  else note "STEP java32 exit=$rc observed.json DIFFERS from PR #32's committed file"; fi
else
  note "SKIPPED java31 java32: FEDWIKI_JAVA_ROOT not set"
fi
note "REVIEW-RUN-DONE"
