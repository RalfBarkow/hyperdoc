#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
SERVER="$DIR/../hyperdoc-standalone/hyperdoc"
FRAME="$DIR/clogframe"

PID_FILE="$DIR/hyperdoc-server.pid"
PORT_FILE="$DIR/hyperdoc-server.port"
LOG_FILE="$DIR/hyperdoc-server.log"

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
  curl -fsS "http://127.0.0.1:$1/boot.html" >/dev/null 2>&1
}

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
