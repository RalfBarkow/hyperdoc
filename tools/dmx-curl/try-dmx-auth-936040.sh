#!/usr/bin/env bash
set -euo pipefail

DMX_BASE="${DMX_BASE:-https://dmx.ralfbarkow.ch}"
WORKSPACE_ID="${WORKSPACE_ID:-919815}"
OBJECT_ID="${OBJECT_ID:-936040}"
PASSWORD_FILE="${DMX_PASSWORD_FILE:-.dmx-admin-password}"

COOKIE_JAR="$(mktemp -t dmx-cookiejar.XXXXXX)"
trap 'rm -f "$COOKIE_JAR"' EXIT

echo "DMX base:      ${DMX_BASE}"
echo "Workspace ID:  ${WORKSPACE_ID}"
echo "Object ID:     ${OBJECT_ID}"
echo

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
AUTH_DMX="Authorization: DMX ${B64}"

echo
echo "============================================================"
echo "1) DMX login bootstrap"
echo "POST /access-control/login"
echo "Authorization: DMX <redacted>"
echo "Content-Type: application/json; charset=UTF-8"
echo "Payload: {}"
echo "============================================================"

curl -sS -i \
  -X POST \
  -H "$AUTH_DMX" \
  -H 'Accept: application/json, text/plain, */*' \
  -H 'Content-Type: application/json; charset=UTF-8' \
  --data-binary '{}' \
  -c "$COOKIE_JAR" \
  "${DMX_BASE}/access-control/login"

echo
echo
echo "Cookie jar:"
grep JSESSIONID "$COOKIE_JAR" >/dev/null && echo "JSESSIONID captured: yes" || echo "JSESSIONID captured: no"

JSESSIONID="$(
  awk '$6 == "JSESSIONID" { print $7 }' "$COOKIE_JAR" | tail -n 1
)"

if [ -z "$JSESSIONID" ]; then
  echo "No JSESSIONID captured; aborting assignment test."
  exit 1
fi

echo
echo "============================================================"
echo "2) Workspace assignment PUT, dmx.py-style session cookies"
echo "PUT /workspaces/${WORKSPACE_ID}/object/${OBJECT_ID}"
echo "Cookie: JSESSIONID=<redacted>; dmx_workspace_id=${WORKSPACE_ID}"
echo "Content-Type: application/json"
echo "Payload: zero-length body"
echo "============================================================"

curl -sS -i \
  -X PUT \
  -H 'Accept: application/json, text/plain, */*' \
  -H 'Content-Type: application/json' \
  --data-binary '' \
  --cookie "JSESSIONID=${JSESSIONID}; dmx_workspace_id=${WORKSPACE_ID}" \
  "${DMX_BASE}/workspaces/${WORKSPACE_ID}/object/${OBJECT_ID}"

echo
echo
echo "============================================================"
echo "3) Workspace readback"
echo "GET /workspaces/object/${OBJECT_ID}"
echo "============================================================"

curl -sS -i \
  --cookie "JSESSIONID=${JSESSIONID}; dmx_workspace_id=${WORKSPACE_ID}" \
  "${DMX_BASE}/workspaces/object/${OBJECT_ID}"

echo
echo
echo "============================================================"
echo "4) Topicmap readback"
echo "GET /topicmaps/object/${OBJECT_ID}"
echo "============================================================"

curl -sS -i \
  --cookie "JSESSIONID=${JSESSIONID}; dmx_workspace_id=${WORKSPACE_ID}" \
  "${DMX_BASE}/topicmaps/object/${OBJECT_ID}"

echo
echo "Done."