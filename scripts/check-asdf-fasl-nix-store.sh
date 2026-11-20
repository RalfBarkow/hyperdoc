#!/usr/bin/env bash
# Run with nix develop --no-update-lock-file -c bash scripts/check-asdf-fasl-nix-store.sh
set -eu
cd "$(git rev-parse --show-toplevel)"
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
scratch=$(cd "$scratch" && pwd -P)
export FAQ_SOURCE_DIR="$scratch/source/"
mkdir -p "$FAQ_SOURCE_DIR"
printf '%s\n' '(asdf:defsystem "faq-probe" :components ((:file "answer")))' > "$FAQ_SOURCE_DIR/faq-probe.asd"
printf '%s\n' '(defun cl-user::faq-answer () 42)' > "$FAQ_SOURCE_DIR/answer.lisp"
printf 'UTC=%s\ncheckout=%s\n' "$(date -u +%FT%TZ)" "$(git rev-parse HEAD)"
python3 - <<'PY'
import hashlib, json, pathlib
data = pathlib.Path("flake.lock").read_bytes()
lock = json.loads(data)
pin = lock["nodes"][lock["nodes"][lock["root"]]["inputs"]["nixpkgs"]]["locked"]["rev"]
print("flake.lock SHA-256=" + hashlib.sha256(data).hexdigest())
print("nixpkgs=" + pin)
PY
printf 'platform=%s\n' "$(nix eval --impure --raw --expr builtins.currentSystem)"
probe() {
  sbcl --noinform --no-sysinit --no-userinit --disable-debugger \
    --script scripts/check-asdf-fasl-nix-store.lisp "$1"
}
XDG_CACHE_HOME="$scratch/source-cache" probe source
probe packaged
# The Nix wrapper prepends its package-specific rules to this caller-supplied rule.
XDG_CACHE_HOME="$scratch/override-cache" ASDF_OUTPUT_TRANSLATIONS="/nix/store/:$scratch/env-cache/:" probe destinations
rm "$FAQ_SOURCE_DIR/answer.lisp"
XDG_CACHE_HOME="$scratch/missing-cache" probe missing
# The transcript is publishable only after every fresh process has exited successfully.
printf 'SUCCESS_UTC=%s\n' "$(date -u +%FT%TZ)"
