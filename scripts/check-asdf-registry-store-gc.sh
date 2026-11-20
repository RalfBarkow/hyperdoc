#!/usr/bin/env bash
# Run with nix develop --no-update-lock-file -c bash scripts/check-asdf-registry-store-gc.sh
# Adds one small fixture directory to the Nix store, deletes exactly that path, adds it again, and checks that a
# GC root protects it. It deletes no other store path.
set -eu
cd "$(git rev-parse --show-toplevel)"
scratch=$(mktemp -d)
cleanup() { [ -n "${store:-}" ] && rm -f "$scratch/gcroot" && nix-store --delete "$store" >/dev/null 2>&1 || true; rm -rf "$scratch"; }
trap cleanup EXIT
fixture="$scratch/fixture"
mkdir -p "$fixture"
printf '%s\n' '(asdf:defsystem "faq-gc-probe" :components ((:file "answer")))' > "$fixture/faq-gc-probe.asd"
printf '%s\n' "(defun cl-user::faq-gc-answer () 42) ; $(date -u +%FT%TZ) $$" > "$fixture/answer.lisp"
user_dir="$scratch/user"
mkdir -p "$user_dir"
printf '%s\n' '(asdf:defsystem "faq-gc-user" :depends-on ("faq-gc-probe"))' > "$user_dir/faq-gc-user.asd"
printf 'UTC=%s\ncheckout=%s\n' "$(date -u +%FT%TZ)" "$(git rev-parse HEAD)"
python3 - <<'PY'
import hashlib, json, pathlib
data = pathlib.Path("flake.lock").read_bytes()
lock = json.loads(data)
pin = lock["nodes"][lock["nodes"][lock["root"]]["inputs"]["nixpkgs"]]["locked"]["rev"]
print("flake.lock SHA-256=" + hashlib.sha256(data).hexdigest())
print("nixpkgs=" + pin)
PY
printf 'platform=%s\nuser=%s\nnix=%s\n' "$(nix eval --impure --raw --expr builtins.currentSystem)" "$(id -un)" "$(nix --version)"
# The timestamp in answer.lisp makes the path unique to this run, so no other run or package shares it.
store=$(nix --extra-experimental-features nix-command store add-path --name faq-gc-probe "$fixture")
printf 'fixture=%s\n' "$store"
printf '%s\n' "$store" > "$scratch/store-path"
FAQ_STORE_PATH_FILE="$scratch/store-path" FAQ_FIXTURE_DIR="$fixture" FAQ_USER_DIR="$user_dir" XDG_CACHE_HOME="$scratch/cache" \
  sbcl --noinform --no-sysinit --no-userinit --disable-debugger --script scripts/check-asdf-registry-store-gc.lisp
echo "case=rooted"
nix-store --add-root "$scratch/gcroot" --realise "$store" >/dev/null
if nix-store --delete "$store" > "$scratch/rooted.log" 2>&1; then
  echo "FAIL rooted: a path with a GC root was deleted"; exit 1
fi
[ -e "$store/faq-gc-probe.asd" ] || { echo "FAIL rooted: path missing"; exit 1; }
echo "PASS rooted: nix-store --delete refused while $scratch/gcroot pointed at the path: $(grep -o 'still alive' "$scratch/rooted.log" | head -1)"
# The transcript is publishable only after every step has succeeded.
printf 'SUCCESS_UTC=%s\n' "$(date -u +%FT%TZ)"
