#!/bin/sh
set -eu

DMX_BASE="${DMX_BASE:-https://dmx.ralfbarkow.ch}"
WORKSPACE_ID="${WORKSPACE_ID:-919815}"
OBJECT_ID="${OBJECT_ID:-936040}"

printf 'DMX username: '
read USERNAME

printf 'DMX password: '
stty -echo
read PASSWORD
stty echo
printf '\n'

echo "1) Basic session bootstrap via dmx-sessionid.sh"
JSESSIONID="$(
  ./dmx-sessionid.sh "$USERNAME" "$PASSWORD" "$DMX_BASE/core/topic/0"
)"

if [ -z "$JSESSIONID" ] || [ "$JSESSIONID" = "login failed!" ]; then
  echo "Basic session bootstrap failed"
  exit 1
fi

echo "JSESSIONID captured: yes"

echo
echo "2) Guarded zero-body PUT"
echo "PUT /workspaces/${WORKSPACE_ID}/object/${OBJECT_ID}"
echo "Cookie: JSESSIONID=<redacted>; dmx_workspace_id=${WORKSPACE_ID}"
echo "Accept: application/json"
echo "Content-Length: 0"

curl -sS -i \
  -X PUT \
  -H 'Accept: application/json' \
  -H 'Content-Type:' \
  --data-binary '' \
  --cookie "JSESSIONID=${JSESSIONID}; dmx_workspace_id=${WORKSPACE_ID}" \
  "${DMX_BASE}/workspaces/${WORKSPACE_ID}/object/${OBJECT_ID}"

echo
echo "3) Workspace readback"
curl -sS -i \
  --cookie "JSESSIONID=${JSESSIONID}; dmx_workspace_id=${WORKSPACE_ID}" \
  "${DMX_BASE}/workspaces/object/${OBJECT_ID}"

echo
echo "4) Topicmap readback"
curl -sS -i \
  --cookie "JSESSIONID=${JSESSIONID}; dmx_workspace_id=${WORKSPACE_ID}" \
  "${DMX_BASE}/topicmaps/object/${OBJECT_ID}"