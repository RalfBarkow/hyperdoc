#!/bin/sh
# Usage: run.sh EXECUTABLE OUTDIR [node-args...]  -- run inside `unshare -rn`
set -u
EXE=$1; OUT=$2; shift 2
python3 -I "$(dirname "$0")/loup.py"
mkdir -p "$OUT"; HOME_DIR=$(mktemp -d); PORT=${PORT:-18765}
env -i HOME="$HOME_DIR" PATH=/nonexistent HYPERDOC_CATALOG_SYSTEM=dreyeck/catalog HYPERDOC_CATALOG_HOST=127.0.0.1 \
  HYPERDOC_FEDWIKI_SITE_ROOT=${REPO:-.}/dreyeck/tests/fixtures/local-fedwiki-view-site \
  "$EXE" $PORT > "$OUT/catalog.log" 2>&1 &
PID=$!
echo $PID > "$OUT/pid"
env -u HTTPS_PROXY -u HTTP_PROXY -u https_proxy -u http_proxy CATALOG_PID=$PID PORT=$PORT node "$@"
echo "NODE-EXIT $?"
if kill -0 $PID 2>/dev/null; then echo "CATALOG-ALIVE"; kill -TERM $PID; wait $PID; echo "CATALOG-EXIT-AFTER-SIGTERM $?"; else wait $PID; echo "CATALOG-DIED exit=$?"; fi
