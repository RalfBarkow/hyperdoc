#!/bin/sh

#TODO: Test on busybox

USERNAME="$1"
PASSWORD="$2"
if [ -z "$3" ]; then
    HOST_URL='http://localhost:8080/core/topic/0'
else
    HOST_URL="$3"
fi
BASE64=$( echo -n "${USERNAME}:${PASSWORD}" | base64 )
AUTH="Authorization: Basic ${BASE64}"
SESSIONID="$( curl -sS -H "${AUTH}" "${HOST_URL}" -i 2>&1 | grep ^Set-Cookie: | cut -d';' -f1 | cut -d'=' -f2 )"
if [ -z "${SESSIONID}" ]; then
    echo "login failed!"
else
    echo "${SESSIONID}"
fi
