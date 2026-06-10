#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -x "${SCRIPT_DIR}/clogframe" ] && [ -x "${SCRIPT_DIR}/../hyperdoc-standalone/hyperdoc" ]; then
  FRAME_DIR="${SCRIPT_DIR}"
else
  FRAME_DIR="$(cd "${SCRIPT_DIR}/../bundle-deploy/hyperdoc-frame" && pwd)"
fi

CLOSURE_ENV="${HYPERDOC_RUNTIME_CLOSURE_ENV:-${FRAME_DIR}/hyperdoc-runtime-closure.env}"

if [ ! -r "${CLOSURE_ENV}" ]; then
  echo "Missing HyperDoc runtime closure manifest: ${CLOSURE_ENV}" >&2
  echo "Rebuild the bundle so make generates hyperdoc-runtime-closure.env." >&2
  exit 1
fi

. "${CLOSURE_ENV}"

SERVER="${HYPERDOC_SERVER:?HYPERDOC_SERVER missing from runtime closure}"
FRAME="${HYPERDOC_FRAME:?HYPERDOC_FRAME missing from runtime closure}"
BOOT_PATH="${HYPERDOC_BOOT_PATH:-/boot.html}"
PID_FILE="${HYPERDOC_PID_FILE:?HYPERDOC_PID_FILE missing from runtime closure}"
PORT_FILE="${HYPERDOC_PORT_FILE:?HYPERDOC_PORT_FILE missing from runtime closure}"
LOG_FILE="${HYPERDOC_LOG_FILE:?HYPERDOC_LOG_FILE missing from runtime closure}"
FRAME_LOG_FILE="${HYPERDOC_FRAME_LOG_FILE:-${FRAME_DIR}/hyperdoc-frame.log}"
KEEP_SERVER_AFTER_FRAME="${HYPERDOC_KEEP_SERVER_AFTER_FRAME:-0}"

TITLE="${HYPERDOC_FRAME_TITLE:-HyperDoc}"
WIDTH="${HYPERDOC_FRAME_WIDTH:-1280}"
HEIGHT="${HYPERDOC_FRAME_HEIGHT:-900}"
DEVELOPMENT="${HYPERDOC_DEVELOPMENT:-0}"

if [ -n "${HYPERDOC_RUNTIME_LIBRARY_PATH:-}" ]; then
  export LD_LIBRARY_PATH="${HYPERDOC_RUNTIME_LIBRARY_PATH}${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
  export DYLD_LIBRARY_PATH="${HYPERDOC_RUNTIME_LIBRARY_PATH}${DYLD_LIBRARY_PATH:+:${DYLD_LIBRARY_PATH}}"
  export DYLD_FALLBACK_LIBRARY_PATH="${HYPERDOC_RUNTIME_LIBRARY_PATH}${DYLD_FALLBACK_LIBRARY_PATH:+:${DYLD_FALLBACK_LIBRARY_PATH}}"
fi

free_port() {
  python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1]); s.close()'
}

alive() {
  test -f "$PID_FILE" && kill -0 "$(cat "$PID_FILE")" 2>/dev/null
}

ready() {
  curl -fsS "http://127.0.0.1:$1${BOOT_PATH}" >/dev/null 2>&1
}

mkdir -p "$(dirname "$PID_FILE")"

if [ ! -x "$SERVER" ]; then
  echo "Missing server executable from runtime closure: $SERVER" >&2
  exit 1
fi

if [ ! -x "$FRAME" ]; then
  echo "Missing CLOG Frame executable from runtime closure: $FRAME" >&2
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
    BOOT_URL="http://127.0.0.1:${PORT}${BOOT_PATH}"
    echo "HyperDoc: ${BOOT_URL}"
    echo "CLOG Frame log: ${FRAME_LOG_FILE}"
    : > "$FRAME_LOG_FILE"

    set +e
    "$FRAME" "$TITLE" "$PORT" "$WIDTH" "$HEIGHT" 2>&1 | tee -a "$FRAME_LOG_FILE"
    FRAME_STATUS="${PIPESTATUS[0]}"
    set -e

    echo
    echo "CLOG Frame closed."

    if [ "${KEEP_SERVER_AFTER_FRAME}" = "1" ]; then
      echo "HyperDoc server is still running on port $PORT."
      echo "Stop it with: make stop"
    else
      if alive; then
        SERVER_PID="$(cat "$PID_FILE")"
        echo "Stopping HyperDoc server $SERVER_PID"
        kill "$SERVER_PID" 2>/dev/null || true
        for _ in $(seq 1 40); do
          kill -0 "$SERVER_PID" 2>/dev/null || break
          sleep 0.25
        done
        if kill -0 "$SERVER_PID" 2>/dev/null; then
          echo "HyperDoc server did not stop after TERM; killing $SERVER_PID"
          kill -9 "$SERVER_PID" 2>/dev/null || true
        fi
      fi
      rm -f "$PID_FILE" "$PORT_FILE"
    fi

    if [ "$FRAME_STATUS" -ne 0 ]; then
      echo "CLOG Frame exited with status $FRAME_STATUS. Log follows:" >&2
      tail -n 80 "$FRAME_LOG_FILE" >&2 || true
      exit "$FRAME_STATUS"
    fi

    exit 0
  fi
  sleep 0.25
done

echo "Server did not become ready. Log follows:" >&2
tail -n 80 "$LOG_FILE" >&2 || true
exit 1
