#!/usr/bin/env bash
# Operator-owned, read-only query for hyperdoc.service.
set -euo pipefail

request=${1:?Auftragskennung}
fail() { printf '%s\n' "$*" >&2; exit 1; }
[[ $EUID == 0 && $(hostname -s) == dreyeck ]] || fail 'Dieser Auftrag gehört in die administrative Bash auf dreyeck.ch.'

[[ $request =~ ^[0-9a-f]{32}$ ]] || fail 'Ungültige Auftragskennung.'
active=$(readlink -f /run/current-system)
[[ $active =~ ^/nix/store/[0-9a-z]{32}-nixos-system-dreyeck-[A-Za-z0-9.+_-]+$ ]] || fail 'Ungültige aktive Systemgeneration.'
state=$(systemctl show hyperdoc.service -p ActiveState --value)
case "$state" in
  active|inactive|failed|activating|deactivating|reloading|maintenance|refreshing) ;;
  *) fail 'Unbekannter Dienstzustand.' ;;
esac
pid=$(systemctl show hyperdoc.service -p MainPID --value)
[[ $pid =~ ^[0-9]+$ ]] || fail 'hyperdoc.service meldet keine gültige PID.'
running=-
if [[ $pid != 0 ]]; then
  observed=$(tr '\000' '\n' < "/proc/$pid/environ" | sed -n 's/^HYPERDOC_SOURCE_REVISION=//p')
  if [[ $observed =~ ^[0-9a-f]{40}$ ]]; then running=$observed; fi
fi
local_status=$(curl -sS --max-time 10 -o /dev/null -w '%{http_code}' http://127.0.0.1:8080/) || local_status=000
public_status=$(curl -sS --max-time 15 -o /dev/null -w '%{http_code}' https://dreyeck.ch/) || public_status=000
[[ $(systemctl show hyperdoc.service -p ActiveState --value) == "$state" &&
   $(systemctl show hyperdoc.service -p MainPID --value) == "$pid" &&
   $(readlink -f /run/current-system) == "$active" ]] || fail 'Dienst oder Systemgeneration hat sich während des Readbacks geändert.'
printf "(dreyeck/work/catalog-deployment-pr52:submit-service-observation '(\"%s\" \"%s\" \"%s\" \"%s\" %d %d %d))\n" \
  "$request" "$state" "$running" "$active" "$((10#$pid))" "$((10#$local_status))" "$((10#$public_status))"
