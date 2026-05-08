#!/usr/bin/env bash
set -euo pipefail

DMX_BASE="${DMX_BASE:-https://dmx.ralfbarkow.ch}"
WORKSPACE_ID="${WORKSPACE_ID:-919815}"
OBJECT_ID="${OBJECT_ID:-936040}"

restore_tty() {
  stty echo 2>/dev/null || true
}
trap restore_tty EXIT

echo "DMX base:      ${DMX_BASE}"
echo "Workspace ID:  ${WORKSPACE_ID}"
echo "Object ID:     ${OBJECT_ID}"
echo

printf "DMX username: "
read -r USERNAME

if [ -n "${DMX_PASSWORD_FILE:-}" ]; then
  PASSWORD="$(cat "$DMX_PASSWORD_FILE")"
  echo "DMX password: read from ${DMX_PASSWORD_FILE}"
elif [ -n "${DMX_PASSWORD:-}" ]; then
  PASSWORD="$DMX_PASSWORD"
  echo "DMX password: read from DMX_PASSWORD environment variable"
else
  printf "DMX password: "
  stty -echo
  read -r PASSWORD
  stty echo
  printf "\n\n"
fi

B64="$(printf '%s' "${USERNAME}:${PASSWORD}" | base64 | tr -d '\n')"
AUTH_BASIC="Authorization: Basic ${B64}"
AUTH_LDAP="Authorization: LDAP ${B64}"

run_put() {
  local label="$1"
  local auth_header="$2"
  local cookie_header="${3:-dmx_workspace_id=${WORKSPACE_ID}}"

  echo "============================================================"
  echo "${label}"
  echo "PUT /workspaces/${WORKSPACE_ID}/object/${OBJECT_ID}"
  echo "Auth: ${auth_header%% *} <redacted>"
  echo "Cookie: ${cookie_header/JSESSIONID=*/JSESSIONID=<redacted>}"
  echo "Body: zero-length"
  echo "============================================================"

  curl -sS -i \
    -X PUT \
    -H "${auth_header}" \
    -H 'Accept: application/json' \
    -H 'Content-Type:' \
    --data-binary '' \
    --cookie "${cookie_header}" \
    "${DMX_BASE}/workspaces/${WORKSPACE_ID}/object/${OBJECT_ID}"

  echo
  echo
}

echo "Test 1: direct Basic Authorization header on the PUT"
run_put \
  "DIRECT BASIC PUT" \
  "${AUTH_BASIC}" \
  "dmx_workspace_id=${WORKSPACE_ID}"

echo "Test 2: direct LDAP Authorization header on the PUT"
run_put \
  "DIRECT LDAP PUT" \
  "${AUTH_LDAP}" \
  "dmx_workspace_id=${WORKSPACE_ID}"

if [ -x "./dmx-sessionid.sh" ]; then
  echo "Test 3: Basic bootstrap via dmx-sessionid.sh, then Basic + JSESSIONID on PUT"

  JSESSIONID="$(
    ./dmx-sessionid.sh "$USERNAME" "$PASSWORD" "$DMX_BASE/core/topic/0" \
      | tail -n 1 \
      | tr -d '\r\n'
  )"

  if [ -z "${JSESSIONID}" ] || [ "${JSESSIONID}" = "login failed!" ]; then
    echo "JSESSIONID bootstrap failed; skipping Basic + session PUT."
  else
    run_put \
      "BASIC HEADER + JSESSIONID PUT" \
      "${AUTH_BASIC}" \
      "JSESSIONID=${JSESSIONID}; dmx_workspace_id=${WORKSPACE_ID}"
  fi
else
  echo "Skipping Test 3: ./dmx-sessionid.sh is not executable or not found."
fi

echo "============================================================"
echo "Readback: workspace assignment"
echo "GET /workspaces/object/${OBJECT_ID}"
echo "============================================================"

curl -sS -i \
  "${DMX_BASE}/workspaces/object/${OBJECT_ID}"

echo
echo

echo "============================================================"
echo "Readback: topicmap memberships"
echo "GET /topicmaps/object/${OBJECT_ID}"
echo "============================================================"

curl -sS -i \
  "${DMX_BASE}/topicmaps/object/${OBJECT_ID}"

echo
echo
echo "Done."