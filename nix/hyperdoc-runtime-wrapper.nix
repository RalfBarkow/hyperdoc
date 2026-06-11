{ pkgs }:

let
  lib = pkgs.lib;

  runtimeLibraryPath = lib.makeLibraryPath [
    pkgs.openssl
    pkgs.sqlite
    pkgs.zlib
    pkgs.libffi
  ];
in
pkgs.writeShellScriptBin "hyperdoc-runtime-server" ''
  set -euo pipefail

  if [ -z "''${HYPERDOC_SERVER:-}" ]; then
    case "$0" in
      */*) script_dir="''${0%/*}" ;;
      *) script_dir="." ;;
    esac
    script_dir="$(cd -- "$script_dir" && pwd -P)"
    candidate="$script_dir/../hyperdoc-standalone/hyperdoc"
    if [ -x "$candidate" ]; then
      HYPERDOC_SERVER="$candidate"
    else
      echo "HYPERDOC_SERVER is not set and no bundled server was found at $candidate." >&2
      exit 1
    fi
  fi

  if [ ! -x "$HYPERDOC_SERVER" ]; then
    echo "HyperDoc server executable is not runnable: $HYPERDOC_SERVER" >&2
    exit 1
  fi

  export HYPERDOC_NIX_RUNTIME_LIBRARY_PATH="${runtimeLibraryPath}"
  export LD_LIBRARY_PATH="${runtimeLibraryPath}''${LD_LIBRARY_PATH:+:''${LD_LIBRARY_PATH}}"
  export DYLD_LIBRARY_PATH="${runtimeLibraryPath}''${DYLD_LIBRARY_PATH:+:''${DYLD_LIBRARY_PATH}}"
  export DYLD_FALLBACK_LIBRARY_PATH="${runtimeLibraryPath}''${DYLD_FALLBACK_LIBRARY_PATH:+:''${DYLD_FALLBACK_LIBRARY_PATH}}"

  exec "$HYPERDOC_SERVER" "$@"
''
