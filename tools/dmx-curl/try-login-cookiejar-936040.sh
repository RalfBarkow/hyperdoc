#!/usr/bin/env bash
set -euo pipefail

DMX_BASE="${DMX_BASE:-https://dmx.ralfbarkow.ch}"
WORKSPACE_ID="${WORKSPACE_ID:-919815}"
OBJECT_ID="${OBJECT_ID:-936040}"
PASSWORD_FILE="${DMX_PASSWORD_FILE:-.dmx-admin-password}"

COOKIE_JAR="$(mktemp -t dmx-cookiejar.XXXXXX)"
trap 'rm -f "$COOKIE_JAR"' EXIT

printf "DMX username: "
read -r USERNAME

if [ -f "$PASSWORD_FILE" ]; then
  PASSWORD="$(cat "$PASSWORD_FILE")"
  echo "DMX password: read from $PASSWORD_FILE"
else
  printf "DMX password: "
  stty -echo
  read -r PASSWORD
  stty echo
  printf "\n"
fi

B64="$(printf '%s' "${USERNAME}:${PASSWORD}" | base64 | tr -d '\n')"
AUTH_BASIC="Authorization: Basic ${B64}"
AUTH_XBASIC="Authorization: xBasic ${B64}"

echo
echo "============================================================"
echo "1) Login endpoint with Basic, saving cookie jar"
echo "POST /access-control/login"
echo "Authorization: Basic <redacted>"
echo "============================================================"

curl -sS -i \
  -X POST \
  -H "$AUTH_BASIC" \
  -H 'Content-Type:' \
  --data-binary '' \
  -c "$COOKIE_JAR" \
  "${DMX_BASE}/access-control/login"

echo
echo
echo "Cookie jar now contains:"
sed -E 's/(JSESSIONID[[:space:]]+).*/\1<redacted>/' "$COOKIE_JAR" || true

echo
echo
echo "============================================================"
echo "2) PUT with login cookie jar + workspace cookie"
echo "PUT /workspaces/${WORKSPACE_ID}/object/${OBJECT_ID}"
echo "Cookie jar: <redacted>; dmx_workspace_id=${WORKSPACE_ID}"
echo "============================================================"

curl -sS -i \
  -X PUT \
  -H 'Accept: application/json' \
  -H 'Content-Type:' \
  --data-binary '' \
  -b "$COOKIE_JAR" \
  -H "Cookie: dmx_workspace_id=${WORKSPACE_ID}" \
  "${DMX_BASE}/workspaces/${WORKSPACE_ID}/object/${OBJECT_ID}"

echo
echo
echo "============================================================"
echo "3) Direct xBasic PUT, because server challenges with xBasic realm=DMX"
echo "Authorization: xBasic <redacted>"
echo "============================================================"

curl -sS -i \
  -X PUT \
  -H "$AUTH_XBASIC" \
  -H 'Accept: application/json' \
  -H 'Content-Type:' \
  --data-binary '' \
  --cookie "dmx_workspace_id=${WORKSPACE_ID}" \
  "${DMX_BASE}/workspaces/${WORKSPACE_ID}/object/${OBJECT_ID}"

echo
echo
echo "============================================================"
echo "4) xBasic login endpoint, saving fresh cookie jar"
echo "POST /access-control/login"
echo "Authorization: xBasic <redacted>"
echo "============================================================"

: > "$COOKIE_JAR"

curl -sS -i \
  -X POST \
  -H "$AUTH_XBASIC" \
  -H 'Content-Type:' \
  --data-binary '' \
  -c "$COOKIE_JAR" \
  "${DMX_BASE}/access-control/login"

echo
echo
echo "============================================================"
echo "5) PUT with xBasic login cookie jar + workspace cookie"
echo "============================================================"

curl -sS -i \
  -X PUT \
  -H 'Accept: application/json' \
  -H 'Content-Type:' \
  --data-binary '' \
  -b "$COOKIE_JAR" \
  -H "Cookie: dmx_workspace_id=${WORKSPACE_ID}" \
  "${DMX_BASE}/workspaces/${WORKSPACE_ID}/object/${OBJECT_ID}"

echo
echo
echo "============================================================"
echo "6) Workspace readback"
echo "============================================================"

curl -sS -i \
  "${DMX_BASE}/workspaces/object/${OBJECT_ID}"

echo
echo
echo "============================================================"
echo "7) Topicmap readback"
echo "============================================================"

curl -sS -i \
  "${DMX_BASE}/topicmaps/object/${OBJECT_ID}"

echo
echo "Done."