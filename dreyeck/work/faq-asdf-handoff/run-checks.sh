#!/usr/bin/env bash
# Runs the unchanged revision-2 check of FAQ asdf-fasl-nix-store in fresh SBCL processes.
#
#   nix develop --no-update-lock-file -c bash dreyeck/work/faq-asdf-handoff/run-checks.sh
#       the eleven calls of HANDOVER.md (C1-C11) with a fresh HOME each, then the restore probe
#   nix develop --no-update-lock-file -c bash dreyeck/work/faq-asdf-handoff/run-checks.sh read-only
#       two read-only calls (R1 salza2, R2 store probe) in the caller's own environment
#
# One tab-separated line per result:
#   CASE <id> <exit> <fasl-destination> <last line>   CREATED <id> <entries>
#   RESTORE <point> <destination>                      RESTORE-EXIT <exit>
# Nothing is written into /nix/store. The full run creates only temporary directories, removed on exit;
# C6 is skipped as root, because root could create /nonexistent.
set -u
here=$(cd "$(dirname "$0")" && pwd -P)
top=$(cd "$here/../../.." && pwd -P)
check="$top/docs/faq/asdf-fasl-nix-store/revision-2/check-asdf-fasl-destination.lisp"
probe="$here/restore-probe.lisp"
sbcl_check() { sbcl --noinform --non-interactive --no-userinit --load "$check"; }

report() { # id exit output
  dest=$(printf '%s\n' "$3" | sed -n 's/^fasl-destination //p' | head -n 1)
  last=$(printf '%s\n' "$3" | grep -E '^(PASS|FAIL)' | tail -n 1)
  printf 'CASE\t%s\t%s\t%s\t%s\n' "$1" "$2" "${dest:--}" "${last:--}"
}

printf 'PLATFORM\t%s-%s\n' "$(uname -s)" "$(uname -m)"
printf 'SBCL\t%s\n' "$(sbcl --version)"

if [ "${1:-}" = read-only ]; then
  out=$(FAQ_CHECK_READ_ONLY=1 FAQ_SYSTEM=salza2 sbcl_check 2>&1); report R1 $? "$out"
  out=$(FAQ_CHECK_READ_ONLY=1 sbcl_check 2>&1); report R2 $? "$out"
  exit 0
fi

scratch=$(mktemp -d) || { printf 'ERROR\tno temporary directory\n'; exit 1; }
trap 'rm -rf "$scratch"' EXIT
salza2=$(sbcl --noinform --non-interactive --no-userinit --eval '(require :asdf)' \
           --eval '(princ (namestring (asdf:system-source-directory "salza2")))' 2>/dev/null)

case_run() { # id, then settings
  id=$1; shift
  home="$scratch/$id"; mkdir -p "$home"
  out=$(env -u ASDF_OUTPUT_TRANSLATIONS -u XDG_CACHE_HOME HOME="$home" "$@" \
          sbcl --noinform --non-interactive --no-userinit --load "$check" 2>&1)
  report "$id" $? "$out"
}

case_run C1
case_run C2 FAQ_SYSTEM=salza2
case_run C3 FAQ_SYSTEM=salza2 FAQ_COMPONENT=package
case_run C4 ASDF_OUTPUT_TRANSLATIONS=/nix/store/:/nix/store/
case_run C5 FAQ_PROBE_SOURCE="${salza2}no-such-file.lisp"
if [ "$(id -u)" -eq 0 ]; then
  printf 'CASE\tC6\tskipped\t-\troot could create /nonexistent\n'
else
  out=$(env -u ASDF_OUTPUT_TRANSLATIONS -u XDG_CACHE_HOME HOME=/nonexistent \
          sbcl --noinform --non-interactive --no-userinit --load "$check" 2>&1)
  report C6 $? "$out"
fi
case_run C7 FAQ_CHECK_READ_ONLY=1
printf 'CREATED\tC7\t%s\n' "$(find "$scratch/C7" -mindepth 1 | wc -l | tr -d ' ')"
case_run C8 FAQ_SYSTEM=no-such-system
case_run C9 ASDF_OUTPUT_TRANSLATIONS="/nix/store/:$scratch/C9/.cache/asdf-nix-store/"
case_run C10 FAQ_SYSTEM=salza2 ASDF_OUTPUT_TRANSLATIONS="/nix/store/:$scratch/C10/.cache/asdf-nix-store/"
case_run C11 FAQ_SYSTEM=shop3

mkdir -p "$scratch/restore"
env -u ASDF_OUTPUT_TRANSLATIONS -u XDG_CACHE_HOME HOME="$scratch/restore" \
  sbcl --noinform --non-interactive --no-userinit --load "$probe" 2>&1 | grep -E '^RESTORE'
printf 'RESTORE-EXIT\t%s\n' "${PIPESTATUS[0]}"
