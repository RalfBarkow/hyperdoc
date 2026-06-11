#!/usr/bin/env bash
set -euo pipefail

SERVER="${HYPERDOC_SERVER:?HYPERDOC_SERVER is required}"
SERVER_WRAPPER="${HYPERDOC_SERVER_WRAPPER:?HYPERDOC_SERVER_WRAPPER is required}"
BOOT_PATH="${HYPERDOC_BOOT_PATH:-/boot.html}"
LOG_FILE="${HYPERDOC_RUNTIME_VALIDATION_LOG_FILE:-bundle-deploy/hyperdoc-frame/hyperdoc-runtime-wrapper-validation.log}"

free_port() {
  python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1]); s.close()'
}

ready() {
  curl -fsS "http://127.0.0.1:$1${BOOT_PATH}" >/dev/null 2>&1
}

missing_library_errors() {
  grep -E \
    'lib(crypto|ssl|sqlite3).*((cannot open|not found|No such file|image not found)|Library not loaded)|Library not loaded:.*lib(crypto|ssl|sqlite3)|cannot load.*lib(crypto|ssl|sqlite3)' \
    "$LOG_FILE" || true
}

if [ ! -x "$SERVER" ]; then
  echo "HyperDoc server executable is not runnable: $SERVER" >&2
  exit 1
fi

if [ ! -x "$SERVER_WRAPPER" ]; then
  echo "HyperDoc Nix runtime wrapper is not runnable: $SERVER_WRAPPER" >&2
  exit 1
fi

mkdir -p "$(dirname "$LOG_FILE")"
: > "$LOG_FILE"

PORT="${HYPERDOC_PORT:-$(free_port)}"
URL="http://127.0.0.1:${PORT}${BOOT_PATH}"

echo "==> Validating saved image through Nix runtime wrapper"
echo "    server:  $SERVER"
echo "    wrapper: $SERVER_WRAPPER"
echo "    url:     $URL"
echo "    log:     $LOG_FILE"

env -i \
  HYPERDOC_SERVER="$SERVER" \
  HYPERDOC_PORT="$PORT" \
  HYPERDOC_DEVELOPMENT=0 \
  "$SERVER_WRAPPER" >> "$LOG_FILE" 2>&1 &
SERVER_PID="$!"

cleanup() {
  kill "$SERVER_PID" 2>/dev/null || true
  wait "$SERVER_PID" 2>/dev/null || true
}
trap cleanup EXIT

for _ in $(seq 1 120); do
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    echo "HyperDoc server exited before readiness." >&2
    tail -n 120 "$LOG_FILE" >&2 || true
    exit 1
  fi
  if ready "$PORT"; then
    break
  fi
  sleep 0.25
done

if ! ready "$PORT"; then
  echo "HyperDoc server did not become ready at $URL." >&2
  tail -n 120 "$LOG_FILE" >&2 || true
  exit 1
fi

if errors="$(missing_library_errors)" && [ -n "$errors" ]; then
  echo "Native library loader errors were found in the server log:" >&2
  printf '%s\n' "$errors" >&2
  tail -n 120 "$LOG_FILE" >&2 || true
  exit 1
fi

echo "==> Runtime wrapper validation passed"
echo "    reached: $URL"
