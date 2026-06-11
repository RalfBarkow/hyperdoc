#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -x "${SCRIPT_DIR}/clogframe" ] && [ -x "${SCRIPT_DIR}/../hyperdoc-standalone/hyperdoc" ]; then
  FRAME_DIR="${SCRIPT_DIR}"
  BUNDLE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
else
  FRAME_DIR="$(cd "${SCRIPT_DIR}/../bundle-deploy/hyperdoc-frame" && pwd)"
  BUNDLE_DIR="$(cd "${FRAME_DIR}/.." && pwd)"
fi

SERVER="${HYPERDOC_SERVER:-${BUNDLE_DIR}/hyperdoc-standalone/hyperdoc}"
SERVER_WRAPPER="${HYPERDOC_SERVER_WRAPPER:-${FRAME_DIR}/hyperdoc-runtime-server}"
FRAME="${HYPERDOC_FRAME:-${FRAME_DIR}/clogframe}"
BOOT_PATH="${HYPERDOC_BOOT_PATH:-/boot.html}"
PID_FILE="${HYPERDOC_PID_FILE:-${FRAME_DIR}/hyperdoc-server.pid}"
PORT_FILE="${HYPERDOC_PORT_FILE:-${FRAME_DIR}/hyperdoc-server.port}"
LOG_FILE="${HYPERDOC_LOG_FILE:-${FRAME_DIR}/hyperdoc-server.log}"
FRAME_LOG_FILE="${HYPERDOC_FRAME_LOG_FILE:-${FRAME_DIR}/hyperdoc-frame.log}"
KEEP_SERVER_AFTER_FRAME="${HYPERDOC_KEEP_SERVER_AFTER_FRAME:-0}"

TITLE="${HYPERDOC_FRAME_TITLE:-HyperDoc}"
WIDTH="${HYPERDOC_FRAME_WIDTH:-1280}"
HEIGHT="${HYPERDOC_FRAME_HEIGHT:-900}"
DEVELOPMENT="${HYPERDOC_DEVELOPMENT:-0}"

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
  echo "Missing HyperDoc server executable: $SERVER" >&2
  exit 1
fi

if [ ! -x "$SERVER_WRAPPER" ]; then
  echo "Missing Nix runtime server wrapper: $SERVER_WRAPPER" >&2
  echo "Rebuild the bundle with make build-runtime-wrapper." >&2
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

  HYPERDOC_SERVER="$SERVER" HYPERDOC_PORT="$PORT" HYPERDOC_DEVELOPMENT="$DEVELOPMENT" \
    nohup "$SERVER_WRAPPER" >> "$LOG_FILE" 2>&1 < /dev/null &

  echo "$!" > "$PID_FILE"
  echo "$PORT" > "$PORT_FILE"
fi

for _ in $(seq 1 120); do
  if ready "$PORT"; then
    BOOT_URL="http://127.0.0.1:${PORT}${BOOT_PATH}"
    echo "HyperDoc: ${BOOT_URL}"
    echo "CLOG Frame log: ${FRAME_LOG_FILE}"
    : > "$FRAME_LOG_FILE"

    {
      echo "CLOG Frame display env:"
      echo "  DISPLAY=${DISPLAY:-}"
      echo "  WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-}"
      echo "  XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-}"
      echo "  GDK_BACKEND=${GDK_BACKEND:-}"
      echo "  WEBKIT_DISABLE_DMABUF_RENDERER=${WEBKIT_DISABLE_DMABUF_RENDERER:-}"
      echo "  WEBKIT_DISABLE_COMPOSITING_MODE=${WEBKIT_DISABLE_COMPOSITING_MODE:-}"
      echo "  LIBGL_ALWAYS_SOFTWARE=${LIBGL_ALWAYS_SOFTWARE:-}"
      echo "  MESA_LOADER_DRIVER_OVERRIDE=${MESA_LOADER_DRIVER_OVERRIDE:-}"
      echo "  GSK_RENDERER=${GSK_RENDERER:-}"
      echo "  GDK_GL=${GDK_GL:-}"
    } >> "$FRAME_LOG_FILE"

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
