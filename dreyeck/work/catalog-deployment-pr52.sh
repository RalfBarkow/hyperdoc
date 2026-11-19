#!/usr/bin/env bash
# Operator-owned stages for the executable Catalog update task.
set -euo pipefail
umask 077
stage=${1:?stage}
revision=${2:-}
receipt=${3:-}
fail() { printf '%s\n' "$*" >&2; exit 1; }
emit_receipt() {
  local evidence
  printf -v evidence "$@"
  printf "(dreyeck/work/catalog-deployment-pr52:submit-receipt '%s)\n" "$evidence"
}
[[ $EUID == 0 && $(hostname -s) == dreyeck ]] || fail 'Dieser Schritt gehört in die administrative Bash auf dreyeck.ch.'
cd /etc/nixos

locked_hyperdoc_field() {
  nix eval --raw --impure --expr "
    let lock = builtins.fromJSON (builtins.readFile /etc/nixos/flake.lock);
        key = lock.nodes.\${lock.root}.inputs.hyperdoc;
        node = lock.nodes.\${key}.locked;
    in assert builtins.isString key;
       builtins.getAttr \"$1\" node"
}

locked_hyperdoc_rev() { locked_hyperdoc_field rev; }

uses_git_input() {
  local url
  url=$(nix eval --raw --impure --expr '(import /etc/nixos/flake.nix).inputs.hyperdoc.url or ""') || return 1
  [[ $url == git+* ]]
}

check_git_input() {
  uses_git_input || fail 'Setze den HyperDoc-Input in /etc/nixos auf eine vom Server lesbare git+…-URL.'
}

system_path() {
  [[ $1 =~ ^/nix/store/[0-9a-z]{32}-nixos-system-dreyeck-[A-Za-z0-9.+_-]+$ ]]
}

catalog_pid() {
  local pid
  systemctl is-active --quiet hyperdoc.service || fail 'hyperdoc.service ist nicht aktiv.'
  pid=$(systemctl show hyperdoc.service -p MainPID --value)
  [[ $pid =~ ^[1-9][0-9]*$ ]] || fail 'hyperdoc.service meldet keine PID.'
  printf '%s\n' "$pid"
}

catalog_revision() {
  local pid=$1
  tr '\000' '\n' < "/proc/$pid/environ" | sed -n 's/^HYPERDOC_SOURCE_REVISION=//p'
}

readback_catalog() {
  local system=$1 pid=$2 running local_status public_status
  running=$(catalog_revision "$pid")
  [[ $running == "$revision" ]] || fail 'Der laufende Catalog meldet eine andere HyperDoc-Revision.'
  local_status=$(curl -sS --max-time 10 -o /dev/null -w '%{http_code}' http://127.0.0.1:8080/)
  public_status=$(curl -sS --max-time 15 -o /dev/null -w '%{http_code}' https://dreyeck.ch/)
  [[ $local_status == 200 && $public_status == 200 ]] || fail 'Der Catalog-Readback ergibt nicht zweimal HTTP 200.'
  [[ $(catalog_pid) == "$pid" && $(readlink -f /run/current-system) == "$system" ]] ||
    fail 'PID oder Systemgeneration hat sich während des Readbacks geändert.'
  case "$stage" in
    baseline)
      emit_receipt '(:active-readback "%s" "%s" %s %s %s)' "$running" "$system" "$pid" "$local_status" "$public_status"
      ;;
    readback)
      printf '%s\t%s\t%s\t%s\t%s\n' "$running" "$system" "$pid" "$local_status" "$public_status"
      ;;
    verify)
      emit_receipt '(:verify "%s" "%s" "%s" %s %s %s)' "$running" "$receipt" "$system" "$pid" "$local_status" "$public_status"
      ;;
  esac
}

approve_revision() {
  local answer
  printf '%s\n' "$1" >/dev/tty
  read -r answer </dev/tty
  [[ $answer == "$revision" ]] || fail 'Die Bestätigung stimmt nicht mit der Merge-SHA überein.'
}

check_pin() {
  [[ $(locked_hyperdoc_rev) == "$revision" ]] || fail 'Der Lockfile verweist auf eine andere HyperDoc-Revision.'
  [[ $(locked_hyperdoc_field type) == git ]] || fail 'Der Lockfile verwendet für HyperDoc keinen Git-Input.'
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

if [[ $stage == observe ]]; then
  active=$(readlink -f /run/current-system)
  system_path "$active" || fail 'Ungültige aktive Systemgeneration.'
  state=$(systemctl show hyperdoc.service -p ActiveState --value)
  pid=$(systemctl show hyperdoc.service -p MainPID --value)
  [[ $pid =~ ^[0-9]+$ ]] || fail 'hyperdoc.service meldet keine gültige PID.'
  running=-
  if [[ $pid != 0 ]]; then
    observed=$(catalog_revision "$pid")
    if [[ $observed =~ ^[0-9a-f]{40}$ ]]; then running=$observed; fi
  fi
  local_status=$(curl -sS --max-time 10 -o /dev/null -w '%{http_code}' http://127.0.0.1:8080/) || local_status=000
  public_status=$(curl -sS --max-time 15 -o /dev/null -w '%{http_code}' https://dreyeck.ch/) || public_status=000
  [[ $(systemctl show hyperdoc.service -p ActiveState --value) == "$state" &&
     $(systemctl show hyperdoc.service -p MainPID --value) == "$pid" &&
     $(readlink -f /run/current-system) == "$active" ]] || fail 'Dienst oder Systemgeneration hat sich während des Readbacks geändert.'
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$state" "$running" "$active" "$pid" "$local_status" "$public_status"
  exit 0
fi

[[ $revision =~ ^[0-9a-f]{40}$ ]] || fail 'Ungültige Merge-SHA.'

if [[ $stage == readback ]]; then
  active=$(readlink -f /run/current-system)
  system_path "$active"
  pid=$(catalog_pid)
  readback_catalog "$active" "$pid"
  exit 0
fi

if [[ $stage == baseline ]]; then
  previous=$(readlink -f /run/current-system)
  system_path "$previous"
  pid=$(catalog_pid)
  running=$(catalog_revision "$pid")
  if [[ $running == "$revision" ]]; then
    readback_catalog "$previous" "$pid"
    exit 0
  fi
  df -h /nix/store
  old_rev=$(locked_hyperdoc_rev)
  [[ $old_rev =~ ^[0-9a-f]{40}$ ]]
  kind=other
  if uses_git_input; then kind=git; fi
  receipt=$(mktemp -d /var/tmp/hyperdoc-pr52.XXXXXXXX)
  cp -p flake.nix flake.lock "$receipt/"
  printf '%s\n' "$revision" > "$receipt/target-revision"
  printf '%s\n' "$previous" > "$receipt/previous-system"
  emit_receipt '(:baseline "%s" "%s" "%s" "%s" :%s)' "$revision" "$receipt" "$previous" "$old_rev" "$kind"
  exit 0
fi

[[ $receipt =~ ^/var/tmp/hyperdoc-pr52\.[A-Za-z0-9]{8}$ ]]
[[ -d $receipt && -O $receipt && ! -L $receipt ]]
[[ $(cat "$receipt/target-revision") == "$revision" ]]
case "$stage" in
  git-source)
    check_git_input
    previous=$(cat "$receipt/previous-system")
    system_path "$previous"
    emit_receipt '(:git-source "%s" "%s" "%s")' "$revision" "$receipt" "$previous"
    ;;
  build)
    check_git_input
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
    emit_receipt '(:build "%s" "%s" "%s")' "$revision" "$receipt" "$built"
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
    emit_receipt '(:activate "%s" "%s" "%s")' "$revision" "$receipt" "$built"
    ;;
  verify)
    built=$(cat "$receipt/built-system")
    system_path "$built"
    [[ $(readlink -f /run/current-system) == "$built" ]] || fail 'Die aktive Generation weicht vom Build ab.'
    pid=$(catalog_pid)
    readback_catalog "$built" "$pid"
    ;;
  *) printf 'Unbekannter Catalog-Schritt: %s\n' "$stage" >&2; exit 2 ;;
esac
