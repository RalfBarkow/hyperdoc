#!/usr/bin/env bash
# Run in a prepared project Lisp environment (e.g. nix develop).
set -euo pipefail
w2_root=$(cd "$(dirname "$0")/.." && pwd)
w2_logs=${W2_LOGS:-$(mktemp -d -t hyperdoc-w2-logs-XXXXXXXX)}
w2_sbcl=${W2_SBCL:-sbcl}
mkdir -p "$w2_logs/home" "$w2_logs/fasls"
w2_args=(--noinform --no-sysinit --no-userinit --non-interactive)
if [[ -n ${W2_BOOTSTRAP:-} ]]; then w2_args+=(--load "$W2_BOOTSTRAP"); fi
w2_args+=(--eval '(require :asdf)' --eval '(asdf:initialize-output-translations `(:output-translations (t ,(uiop:getenv "W2_FASLS")) :ignore-inherited-configuration))')
cd "$w2_root"
w2_replay_repo=''
trap 'if [[ -n $w2_replay_repo ]]; then rm -rf -- "$w2_replay_repo"; fi' EXIT
w2_lisp() {
  env HOME="$w2_logs/home" W2_FASLS="$w2_logs/fasls/" "$w2_sbcl" "${w2_args[@]}" --load "$1"
}
w2_lisp scripts/test-welcome-development.lisp > "$w2_logs/regressions.log" 2>&1
W2_KEEP_REPO=1 w2_lisp scripts/test-welcome-domain-versions.lisp > "$w2_logs/acceptance.log" 2>&1
read -r _ w2_replay_repo w2_replay_commit _ < <(rg '^W2-REPLAY-FIXTURE ' "$w2_logs/acceptance.log")
for w2_n in 1 2; do
  W2_MODE=identity w2_lisp scripts/test-welcome-domain-versions.lisp > "$w2_logs/identity-$w2_n.log" 2>&1
done
diff <(rg '^W2-IDENTITY ' "$w2_logs/identity-1.log") <(rg '^W2-IDENTITY ' "$w2_logs/identity-2.log")
git -C "$w2_replay_repo" for-each-ref refs/tags > "$w2_logs/tags-before.txt"
for w2_mode in fixture replay; do
  env HOME="$w2_logs/home" W2_FASLS="$w2_logs/fasls/" W2_MODE="$w2_mode" \
    W2_REPLAY_REPO="$w2_replay_repo" W2_REPLAY_COMMIT="$w2_replay_commit" \
    strace -f -s 4096 -e trace=%network,execve -o "$w2_logs/$w2_mode.strace" \
    "$w2_sbcl" "${w2_args[@]}" --load scripts/test-welcome-domain-versions.lisp \
    > "$w2_logs/$w2_mode.log" 2>&1
done
git -C "$w2_replay_repo" for-each-ref refs/tags > "$w2_logs/tags-after.txt"
diff "$w2_logs/tags-before.txt" "$w2_logs/tags-after.txt"
strace -f -s 4096 -e trace=%network,execve -o "$w2_logs/trace-control.strace" \
  python3 -c 'import socket; s = socket.socket(); s.close()'
python3 - "$w2_logs" <<'PY'
import json, pathlib, re, sys
root = pathlib.Path(sys.argv[1])
for mode in ['fixture', 'replay']:
    lines = (root / (mode + '.strace')).read_text().splitlines()
    calls = [line for line in lines if re.match(r'^\d+\s+(?!execve\()[a-z_0-9]+\(', line)]
    assert not calls, calls
    git = []
    for line in lines:
        if 'execve(' not in line: continue
        match = re.search(r'execve\("[^"]*/git", (\[.*?\]),', line)
        if match:
            args = json.loads(match[1])
            # DREYECK/GIT passes these two global options on every call.
            assert args[1] == '--no-lazy-fetch', args
            subcommand = args[4] if args[2] == '-C' else args[2]
            assert subcommand in ['cat-file', 'rev-parse', 'show'], args
            git.append(subcommand)
    if mode == 'fixture': assert not git, git
    else: assert git
    print(f'{mode}: network calls=0; Git exec attempts={len(git)}; subcommands={sorted(set(git))}')
assert re.search(r'\bsocket\(', (root / 'trace-control.strace').read_text())
print('Trace positive control PASS: socket syscall detected')
print('A1 cross-process ID/binding PASS; A5 read-only Git/unchanged tags PASS; A13 no fixture Git/network PASS')
PY
printf 'W2 audit logs: %s\n' "$w2_logs"
