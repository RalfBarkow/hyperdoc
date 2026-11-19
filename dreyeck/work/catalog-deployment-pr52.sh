#!/usr/bin/env bash
# Operator-owned stages for the executable PR #52 DITA task.
set -euo pipefail
umask 077
stage=${1:?stage}
revision=${2:?merge revision}
receipt=${3:-}
fail() { printf '%s\n' "$*" >&2; exit 1; }
[[ $revision =~ ^[0-9a-f]{40}$ ]] || fail 'Ungültige Merge-SHA.'
[[ $EUID == 0 && $(hostname -s) == dreyeck ]] || fail 'Dieser Schritt gehört in die administrative Bash auf dreyeck.ch.'
cd /etc/nixos

locked_hyperdoc_rev() {
  nix eval --raw --impure --expr '
    let lock = builtins.fromJSON (builtins.readFile /etc/nixos/flake.lock);
        key = lock.nodes.${lock.root}.inputs.hyperdoc;
        node = lock.nodes.${key}.locked;
    in assert builtins.isString key;
       assert node.owner == "RalfBarkow" && node.repo == "hyperdoc";
       node.rev'
}

system_path() {
  [[ $1 =~ ^/nix/store/[0-9a-z]{32}-nixos-system-dreyeck-[A-Za-z0-9.+_-]+$ ]]
}

approve_revision() {
  local answer
  printf '%s\n' "$1" >/dev/tty
  read -r answer </dev/tty
  [[ $answer == "$revision" ]] || fail 'Die Bestätigung stimmt nicht mit der Merge-SHA überein.'
}

check_pin() {
  [[ $(locked_hyperdoc_rev) == "$revision" ]] || fail 'Der Lockfile verweist auf eine andere HyperDoc-Revision.'
}

configured_system() {
  nix eval --raw '/etc/nixos#nixosConfigurations.dreyeck.config.system.build.toplevel.outPath'
}

restore_failed_build_lock() {
  local status=$?
  if [[ $status != 0 && -s $selected_lock ]] && cmp -s flake.lock "$selected_lock"; then
    cp -p "$prior_lock" flake.lock
    printf '%s\n' 'Der Lockfile vor diesem Build wurde wiederhergestellt.' >&2
  fi
  rm -f "$prior_lock" "$selected_lock"
  exit "$status"
}

if [[ $stage == baseline ]]; then
  systemctl is-active --quiet hyperdoc.service
  df -h /nix/store
  previous=$(readlink -f /run/current-system)
  system_path "$previous"
  old_rev=$(locked_hyperdoc_rev)
  [[ $old_rev =~ ^[0-9a-f]{40}$ ]]
  receipt=$(mktemp -d /var/tmp/hyperdoc-pr52.XXXXXXXX)
  cp -p flake.nix flake.lock "$receipt/"
  printf '%s\n' "$revision" > "$receipt/target-revision"
  printf '%s\n' "$previous" > "$receipt/previous-system"
  printf '(:baseline "%s" "%s" "%s" "%s")\n' "$revision" "$receipt" "$previous" "$old_rev"
  exit 0
fi

[[ $receipt =~ ^/var/tmp/hyperdoc-pr52\.[A-Za-z0-9]{8}$ ]]
[[ -d $receipt && -O $receipt && ! -L $receipt ]]
[[ $(cat "$receipt/target-revision") == "$revision" ]]
case "$stage" in
  build)
    prior_lock=$(mktemp "$receipt/prior-lock.XXXXXXXX")
    selected_lock=$(mktemp "$receipt/selected-lock.XXXXXXXX")
    cp -p flake.lock "$prior_lock"
    trap restore_failed_build_lock EXIT
    nix flake update hyperdoc
    cp -p flake.lock "$selected_lock"
    check_pin
    diff -u "$receipt/flake.lock" flake.lock || [[ $? == 1 ]]
    approve_revision 'Prüfe den Lock-Diff. Bestätige danach den Build mit der vollständigen Merge-SHA.'
    check_pin
    (cd "$receipt" && nixos-rebuild build --flake /etc/nixos#dreyeck --no-write-lock-file)
    built=$(readlink -f "$receipt/result")
    system_path "$built"
    [[ $(configured_system) == "$built" ]] || fail 'Die aktuelle Konfiguration weicht vom Build ab.'
    nixos-rebuild dry-activate --flake /etc/nixos#dreyeck --no-write-lock-file
    check_pin
    [[ $(configured_system) == "$built" ]] || fail 'Die Konfiguration hat sich während der Vorschau geändert.'
    printf '%s\n' "$built" > "$receipt/built-system"
    printf '(:build "%s" "%s" "%s")\n' "$revision" "$receipt" "$built"
    ;;
  activate)
    built=$(cat "$receipt/built-system")
    system_path "$built"
    check_pin
    planned=$(configured_system)
    [[ $planned == "$built" ]] || fail 'Die Vorschau gehört zu einer anderen NixOS-Generation.'
    if [[ $(readlink -f /run/current-system) != "$built" ]]; then
      [[ $(readlink -f /run/current-system) == "$(cat "$receipt/previous-system")" ]] ||
        fail 'Die vorher aktive Generation hat sich seit der Bestandsaufnahme geändert.'
      approve_revision 'Prüfe die Aktivierungsvorschau. Bestätige switch mit der vollständigen Merge-SHA.'
      check_pin
      [[ $(configured_system) == "$built" ]] || fail 'Die Konfiguration hat sich seit der Vorschau geändert.'
      nixos-rebuild switch --flake /etc/nixos#dreyeck --no-write-lock-file
    fi
    [[ $(readlink -f /run/current-system) == "$built" ]] || fail 'Die aktive Generation weicht vom Build ab.'
    printf '(:activate "%s" "%s" "%s")\n' "$revision" "$receipt" "$built"
    ;;
  verify)
    built=$(cat "$receipt/built-system")
    system_path "$built"
    [[ $(readlink -f /run/current-system) == "$built" ]] || fail 'Die aktive Generation weicht vom Build ab.'
    systemctl is-active --quiet hyperdoc.service
    pid=$(systemctl show hyperdoc.service -p MainPID --value)
    [[ $pid =~ ^[1-9][0-9]*$ ]]
    running=$(tr '\000' '\n' < "/proc/$pid/environ" | sed -n 's/^HYPERDOC_SOURCE_REVISION=//p')
    [[ $running == "$revision" ]] || fail 'Der laufende Catalog meldet eine andere HyperDoc-Revision.'
    local_status=$(curl -fsS --max-time 10 -o /dev/null -w '%{http_code}' http://127.0.0.1:8080/)
    public_status=$(curl -fsS --max-time 15 -o /dev/null -w '%{http_code}' https://dreyeck.ch/)
    [[ $local_status == 200 && $public_status == 200 ]] || fail 'Der Catalog-Readback ergibt nicht zweimal HTTP 200.'
    [[ $(systemctl show hyperdoc.service -p MainPID --value) == "$pid" ]]
    printf '(:verify "%s" "%s" "%s" %s %s %s)\n' "$running" "$receipt" "$built" "$pid" "$local_status" "$public_status"
    ;;
  *) printf 'Unbekannter Catalog-Schritt: %s\n' "$stage" >&2; exit 2 ;;
esac
