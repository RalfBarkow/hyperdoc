#!/usr/bin/env bash
# Re-runs the independent review of PR #35 against the pinned commits.
#   run-review.sh OUT_DIR
# Needs: git, python3, SBCL with the HyperDoc dependency closure on the ASDF source registry (nix develop; or
# HYPERDOC_RUNTIME_REGISTRY = the closure alone, SBCL = its sbcl), both commits in this repository's object store
# (git fetch origin pull/34/head pull/35/head). Optional: strace (system-call evidence), unshare (no network).
# PR #34 (base) and PR #35 are extracted unmodified with git archive into a private temporary directory, removed at exit.
# Every Lisp process gets an empty HOME, its own FASL cache and, where possible, an empty network namespace.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
REPO=$(git -C "$HERE" rev-parse --show-toplevel)
OUT=${1:?usage: run-review.sh OUT_DIR}; mkdir -p "$OUT"; OUT=$(cd "$OUT" && pwd)
SBCL=${SBCL:-sbcl}
REGISTRY=${HYPERDOC_RUNTIME_REGISTRY:-${CL_SOURCE_REGISTRY:-}}
PR34=4e76e9aff910e9da45c1fe9252e528669c2683fb
PR35=68ca0c587e25459b59c2cc246432207f2258975c
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
if unshare --net true 2>/dev/null; then NET=(unshare --net); elif unshare -rn true 2>/dev/null; then NET=(unshare -rn); else NET=(); fi
if command -v strace >/dev/null 2>&1; then HAVE_STRACE=1; else HAVE_STRACE=0; fi
SUMMARY=$OUT/summary.log; : > "$SUMMARY"
note() { echo "$*" | tee -a "$SUMMARY"; }
note "REVIEW-RUN pr34=$PR34 pr35=$PR35 network-isolation=${NET[*]:-none} strace=$HAVE_STRACE"
for c in $PR34 $PR35; do
  git -C "$REPO" cat-file -e "$c^{commit}" 2>/dev/null || { note "MISSING-COMMIT $c: git fetch origin pull/34/head pull/35/head"; exit 2; }
done
for t in pr34:$PR34 pr35:$PR35; do mkdir -p "$WORK/${t%%:*}" && git -C "$REPO" archive "${t#*:}" | tar -x -C "$WORK/${t%%:*}"; done
P=$HERE/probes
# Normalise what legitimately differs between runs: the private directory, object addresses, trailing blanks.
norm() { sed -e "s|$WORK|<WORK>|g" -e 's/{[0-9A-F]\{6,\}}/{ADDR}/g' -e "s/id='\(inspect\|action\)-[0-9]*'/id='\1-N'/g" -e 's/[[:space:]]*$//'; }
# lisp STEP TREE SCRIPT MARKER-REGEX KEEP-REGEX TRACE(0/1) [VAR=VALUE ...]
lisp() {
  local step=$1 tree=$2 script=$3 marker=$4 regex=$5 trace=$6; shift 6
  local pd=$WORK/pd-$step; mkdir -p "$WORK/home-$step" "$WORK/cache-$step" "$pd"
  local pre=(); if [ "$trace" = 1 ] && [ $HAVE_STRACE = 1 ]; then pre=(strace -f -qq -e trace=%network,mkdir -o "$WORK/$step.strace"); fi
  (cd "$tree" && env HOME="$WORK/home-$step" XDG_CACHE_HOME="$WORK/cache-$step" CL_SOURCE_REGISTRY="$tree//:$REGISTRY" \
     PR_TREE="$tree" PROBE_DIR="$pd" "$@" "${pre[@]}" "${NET[@]}" "$SBCL" --noinform --no-sysinit --no-userinit --non-interactive --load "$script") \
     > "$WORK/$step.raw" 2>&1
  local rc=$?
  grep -E "$regex" "$WORK/$step.raw" | norm > "$OUT/$step.log"
  note "STEP $step exit=$rc marker=$(grep -qE "$marker" "$WORK/$step.raw" && echo present || echo ABSENT)"
}
# strace_evidence STEP [MARKER ...]: network system calls counted per segment between the mkdir markers; excerpt kept.
NETCALLS='^[0-9]+ +(socket|socketpair|connect|bind|listen|accept4?|sendto|sendmsg|sendmmsg|recvfrom|recvmsg|recvmmsg|getsockname|getpeername|setsockopt|getsockopt|shutdown)\('
strace_evidence() {
  local step=$1; shift; local f=$WORK/$step.strace
  [ -f "$f" ] || { note "STRACE $step not recorded"; return; }
  python3 -I - "$f" "$NETCALLS" "$@" > "$OUT/$step.strace-summary.log" <<'PY'
import re, sys
path, pattern, markers = sys.argv[1], re.compile(sys.argv[2]), sys.argv[3:]
lines = open(path, errors='replace').read().splitlines()
segments, current, seen = [], 'start', []
counts = {'start': 0}
for line in lines:
    marked = next((m for m in markers if 'mkdir(' in line and m in line), None)
    if marked: current = 'after ' + marked; counts[current] = 0; seen.append(marked); continue
    if pattern.match(line): counts[current] += 1
for segment, n in counts.items(): print('STRACE-SEGMENT', segment, 'network-syscalls', n)
print('STRACE-MARKERS-SEEN', seen)
PY
  grep -E "$NETCALLS" "$f" | sed -E -e 's/^[0-9]+ +//' -e 's/nlmsg_seq=[0-9]+/nlmsg_seq=N/g' -e 's/nl_pid=[0-9]+/nl_pid=N/g' -e 's/(getsockname|bind|sendto|recvmsg)\(([0-9]+),.*/\1(\2, …)/' \
    | norm > "$OUT/$step.strace-network.log"
  note "STRACE $step $(tr '\n' ' ' < "$OUT/$step.strace-summary.log")"
}
# same A B: compare two steps' logs after removing ONLY the BASELINE-ROOT line (it names the extracted tree); diff kept.
same() { diff <(grep -v '^BASELINE-ROOT ' "$OUT/$1.log") <(grep -v '^BASELINE-ROOT ' "$OUT/$2.log") > "$OUT/compare-$1-$2.diff"
         if [ -s "$OUT/compare-$1-$2.diff" ]; then note "COMPARE $1 != $2 (see compare-$1-$2.diff)"
         else note "COMPARE $1 = $2 (identical after removing only the BASELINE-ROOT line)"; fi; }

# 1. PR #35's own suite, under strace
lisp own-suite35 "$WORK/pr35" "$WORK/pr35/scripts/test-fedwiki-local-only.lisp" '^LOCAL-ONLY-INTEGRATION-PASS' '^LOCAL-ONLY' 1
strace_evidence own-suite35
# 2. the same suites on PR #34 and PR #35
for t in pr34 pr35; do
  lisp regressions-$t "$WORK/$t" "$WORK/$t/docs/defederation-consolidation/regressions.lisp" '^BASELINE EMPTY-WITH-TREE REPRODUCED' '^BASELINE' 0
  lisp wiki-link-tests-$t "$WORK/$t" "$P/suite.lisp" '^SUITE-PASS' '^SUITE-' 0 SUITE=dreyeck/wiki-link/tests
  lisp reading-tests-$t "$WORK/$t" "$P/suite.lisp" '^SUITE-(PASS|ERROR)' '^SUITE-' 0 SUITE=dreyeck/work/reading/tests
done
same regressions-pr34 regressions-pr35; same wiki-link-tests-pr34 wiki-link-tests-pr35; same reading-tests-pr34 reading-tests-pr35
# 3. shared FedWiki code, identical probe on both commits
for t in pr34 pr35; do lisp shared-diff-$t "$WORK/$t" "$P/shared-diff.lisp" '^SD-DONE' '^SD' 0; done
diff "$OUT/shared-diff-pr34.log" "$OUT/shared-diff-pr35.log" > "$OUT/shared-diff.diff"; note "COMPARE shared-diff: $(grep -c '^[<>]' "$OUT/shared-diff.diff") differing lines (see shared-diff.diff)"
# 4. counter-probes, extended view image, title bar; strace with positive control after the marker
lisp probes35 "$WORK/pr35" "$P/probes35.lisp" '^PROBES35-DONE' '^((N|P|C|I|G) [0-9]|STRACE-MARKER|PROBES35)' 1
strace_evidence probes35 STRACE-MARKER-BEFORE-CONTROL
lisp ext-views35 "$WORK/pr35" "$P/ext-views.lisp" '^EXT-DONE' '^EXT' 1
strace_evidence ext-views35 EXT-MARKER-A-AFTER-LOAD EXT-MARKER-B-BEFORE-CONTROL
lisp titlebar35 "$WORK/pr35" "$P/titlebar.lisp" '^TB story' '^TB' 0
# 5. manifest of PR #35, recomputed independently
python3 -I "$P/manifest-check.py" "$WORK/pr35" $PR34 "$REPO" $PR35 > "$OUT/manifest.log" 2>&1; note "STEP manifest exit=$? $(grep -c 'log-digest ok' "$OUT/manifest.log") log digests ok"
# 6. every expected finding, checked against this run's outputs
python3 -I "$P/expectations.py" "$OUT" > "$OUT/expectations.log" 2>&1; note "STEP expectations exit=$? $(grep -c '^EXPECT-PASS' "$OUT/expectations.log") pass $(grep -c '^EXPECT-FAIL' "$OUT/expectations.log") fail"
note "REVIEW-RUN-DONE"
