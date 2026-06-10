#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -x "${SCRIPT_DIR}/clogframe" ] && [ -x "${SCRIPT_DIR}/../hyperdoc-standalone/hyperdoc" ]; then
  FRAME_DIR="${SCRIPT_DIR}"
  BUNDLE_DIR="$(cd "${FRAME_DIR}/.." && pwd)"
  REPO_ROOT="$(cd "${BUNDLE_DIR}/.." && pwd)"
else
  REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
  BUNDLE_DIR="${REPO_ROOT}/bundle-deploy"
  FRAME_DIR="${BUNDLE_DIR}/hyperdoc-frame"
fi

SERVER="${HYPERDOC_SERVER:-${BUNDLE_DIR}/hyperdoc-standalone/hyperdoc}"
FRAME="${HYPERDOC_FRAME:-${FRAME_DIR}/clogframe}"

PID_FILE="${FRAME_DIR}/hyperdoc-server.pid"
PORT_FILE="${FRAME_DIR}/hyperdoc-server.port"
LOG_FILE="${FRAME_DIR}/hyperdoc-server.log"

TITLE="${HYPERDOC_FRAME_TITLE:-HyperDoc}"
WIDTH="${HYPERDOC_FRAME_WIDTH:-1280}"
HEIGHT="${HYPERDOC_FRAME_HEIGHT:-900}"
DEVELOPMENT="${HYPERDOC_DEVELOPMENT:-0}"

resolve_openssl_lib_dir() {
  if [ -n "${HYPERDOC_OPENSSL_LIB_DIR:-}" ]; then
    printf '%s\n' "${HYPERDOC_OPENSSL_LIB_DIR}"
    return 0
  fi

  if command -v nix >/dev/null 2>&1; then
    nix eval --raw --impure --expr 'let flake = builtins.getFlake "git+file://'"${REPO_ROOT}"'"; pkgs = import flake.inputs.nixpkgs { system = builtins.currentSystem; }; in "${pkgs.openssl.out}/lib"' 2>/dev/null && return 0
    nix build --no-link --print-out-paths nixpkgs#openssl 2>/dev/null | tail -n 1 | sed 's,$,/lib,' && return 0
  fi

  return 1
}

OPENSSL_LIB_DIR="$(resolve_openssl_lib_dir || true)"
if [ -n "${OPENSSL_LIB_DIR}" ] && [ -r "${OPENSSL_LIB_DIR}/libcrypto.so.3" ]; then
  export LD_LIBRARY_PATH="${OPENSSL_LIB_DIR}${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
else
  echo "Warning: OpenSSL 3 runtime library directory not found; libcrypto.so.3 may fail to load." >&2
fi

free_port() {
  python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1]); s.close()'
}

alive() {
  test -f "$PID_FILE" && kill -0 "$(cat "$PID_FILE")" 2>/dev/null
}

ready() {
  curl -fsS "http://127.0.0.1:$1/boot.html" >/dev/null 2>&1
}

mkdir -p "${FRAME_DIR}"

if [ ! -x "$SERVER" ]; then
  echo "Missing server executable: $SERVER" >&2
  exit 1
fi

if [ ! -x "$FRAME" ]; then
  echo "Missing CLOG Frame executable: $FRAME" >&2
  exit 1
fi

if alive && test -f "$PORT_FILE"; then
  PORT="$(cat "$PORT_FILE")"
  if ready "$PORT"; then
    echo "Reusing running HyperDoc server on port $PORT"
  else
    echo "Found stale or unresponsive HyperDoc server PID; stopping it."
    old_pid="$(cat "$PID_FILE")"
    kill "$old_pid" 2>/dev/null || true
    rm -f "$PID_FILE" "$PORT_FILE"
    PORT="${HYPERDOC_PORT:-$(free_port)}"
  fi
else
  PORT="${HYPERDOC_PORT:-$(free_port)}"
fi

if ! alive; then
  echo "Starting HyperDoc server on port $PORT"
  : > "$LOG_FILE"

  HYPERDOC_PORT="$PORT" HYPERDOC_DEVELOPMENT="$DEVELOPMENT" \
    nohup "$SERVER" >> "$LOG_FILE" 2>&1 < /dev/null &

  echo "$!" > "$PID_FILE"
  echo "$PORT" > "$PORT_FILE"
fi

for _ in $(seq 1 120); do
  if ready "$PORT"; then
    echo "HyperDoc: http://127.0.0.1:$PORT/boot.html"
    "$FRAME" "$TITLE" "${PORT}/boot.html" "$WIDTH" "$HEIGHT"
    echo
    echo "CLOG Frame closed."
    echo "HyperDoc server is still running on port $PORT."
    echo "Stop it with: make stop"
    exit 0
  fi
  sleep 0.25
done

echo "Server did not become ready. Log follows:" >&2
tail -n 80 "$LOG_FILE" >&2 || true
exit 1
