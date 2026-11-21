# Bootstrap for the page-attached HyperDoc «zettelkasten-kiosk»: one command from a terminal to a local Federated Wiki
# page that carries the ASDF system, and a fresh HyperBook Catalog that shows it.
#
# Effects, each stated before it happens:
#  1. In the local wiki's site root (HYPERDOC_FEDWIKI_SITE_ROOT, default ~/.wiki/localhost): create pages/zettelkasten-kiosk
#     and assets/pages/zettelkasten-kiosk/ (the system's files) only if they are missing. Existing files are never
#     overwritten; a difference is reported.
#  2. If nothing answers on the wiki port (HYPERDOC_WIKI_PORT, default 3000): start the Federated Wiki that fleet pins
#     (RalfBarkow/wiki 7dd4055, with the code and assets plugins) in farm mode on 127.0.0.1, for as long as this
#     command runs. A wiki that already answers is used as it is. HYPERDOC_WIKI_FLAKE names another
#     installable, HYPERDOC_WIKI_COMMAND an installed wiki program.
#  3. Start the packaged Catalog of this revision on 127.0.0.1 (HYPERDOC_CATALOG_PORT, default 8080) with the system
#     loaded, and print the links once both answer.
{ lib, writeShellApplication, coreutils, curl, diffutils, catalog, source }:
writeShellApplication {
  name = "zettelkasten-kiosk";
  runtimeInputs = [ coreutils curl diffutils ];
  text = ''
    slug=zettelkasten-kiosk
    system_dir="${source}/dreyeck/work/zettelkasten-kiosk"
    wiki_flake="''${HYPERDOC_WIKI_FLAKE:-github:RalfBarkow/wiki/7dd4055047e9f6b9919b5d3c418abd3fa4044b3b#wiki}"
    site_root="''${HYPERDOC_FEDWIKI_SITE_ROOT:-$HOME/.wiki/localhost}"
    site_root="''${site_root%/}"
    wiki_port="''${HYPERDOC_WIKI_PORT:-3000}"
    catalog_port="''${HYPERDOC_CATALOG_PORT:-8080}"
    page="$site_root/pages/$slug"
    assets="$site_root/assets/pages/$slug"

    answers() { curl -s -o /dev/null --max-time 2 "$1"; }

    echo "Zettelkasten-Kiosk: Bootstrap"
    echo "  Wiki-Seitenordner: $site_root"
    echo "  Wiki:              http://localhost:$wiki_port/"
    echo "  Catalog:           http://localhost:$catalog_port/"
    echo

    # 1. The carrier page and its assets, only if missing.
    if answers "http://127.0.0.1:$catalog_port/"; then
      echo "Port $catalog_port ist belegt (lsof -nP -iTCP:$catalog_port -sTCP:LISTEN zeigt den Prozess)." >&2
      echo "Den Prozess beenden oder HYPERDOC_CATALOG_PORT=8081 voranstellen." >&2
      exit 1
    fi
    if [ -e "$page" ]; then
      if cmp -s "$page" "$system_dir/fedwiki/$slug.json"; then
        echo "Seite:  vorhanden, gleich wie im System ($page)"
      else
        echo "Seite:  vorhanden, weicht vom System ab; nicht überschrieben ($page)"
      fi
    else
      echo "Seite:  lege an $page"
      mkdir -p "$site_root/pages"
      install -m 0644 "$system_dir/fedwiki/$slug.json" "$page"
    fi
    if [ -e "$assets" ]; then
      if diff -rq "$system_dir" "$assets" > /dev/null 2>&1; then
        echo "Assets: vorhanden, gleich wie im System ($assets)"
      else
        echo "Assets: vorhanden, weichen vom System ab; nicht überschrieben ($assets)"
      fi
    else
      echo "Assets: lege an $assets (das ASDF-System der Seite)"
      mkdir -p "$(dirname "$assets")"
      cp -R "$system_dir" "$assets"
      chmod -R u+w "$assets"
    fi

    # 2. The wiki: use a running one, else start the pinned one on loopback.
    wiki_pid=""
    cleanup() { if [ -n "$wiki_pid" ]; then kill "$wiki_pid" 2>/dev/null || true; fi; }
    trap cleanup EXIT INT TERM
    if answers "http://127.0.0.1:$wiki_port/"; then
      echo "Wiki:   läuft bereits auf Port $wiki_port; wird so verwendet"
    else
      if [ "$(basename "$site_root")" != "localhost" ]; then
        echo "Wiki:   keine Wiki auf Port $wiki_port, und der Seitenordner heisst nicht …/localhost;" >&2
        echo "        eine Farm würde ihn nicht finden. Wiki selbst starten oder HYPERDOC_FEDWIKI_SITE_ROOT anpassen." >&2
        exit 1
      fi
      log="''${XDG_CACHE_HOME:-$HOME/.cache}/hyperdoc/zettelkasten-kiosk-wiki.log"
      mkdir -p "$(dirname "$log")"
      wiki_args=(--farm --data "$(dirname "$site_root")" --host 127.0.0.1 --port "$wiki_port")
      if [ -n "''${HYPERDOC_WIKI_COMMAND:-}" ]; then
        echo "Wiki:   starte $HYPERDOC_WIKI_COMMAND auf 127.0.0.1:$wiki_port (Farm, Daten $(dirname "$site_root")); Protokoll $log"
        "$HYPERDOC_WIKI_COMMAND" "''${wiki_args[@]}" > "$log" 2>&1 &
      else
        echo "Wiki:   starte $wiki_flake auf 127.0.0.1:$wiki_port (Farm, Daten $(dirname "$site_root")); Protokoll $log"
        nix run "$wiki_flake" -- "''${wiki_args[@]}" > "$log" 2>&1 &
      fi
      wiki_pid=$!
      for _ in $(seq 1 600); do
        answers "http://127.0.0.1:$wiki_port/" && break
        kill -0 "$wiki_pid" 2>/dev/null || { echo "Wiki-Start fehlgeschlagen; siehe $log" >&2; tail -20 "$log" >&2; exit 1; }
        sleep 1
      done
    fi

    # 3. The Catalog with the system; links once it answers.
    (
      for _ in $(seq 1 1800); do
        if answers "http://127.0.0.1:$catalog_port/"; then
          echo
          echo "Bereit:"
          echo "  Trägerseite in der Wiki:  http://localhost:$wiki_port/view/$slug"
          echo "  HyperDoc:                 http://localhost:$catalog_port/6F061-zettelkasten-kiosk"
          echo "Beenden mit Ctrl-C (beendet auch eine hier gestartete Wiki)."
          exit 0
        fi
        sleep 1
      done
    ) &
    HYPERDOC_FEDWIKI_SITE_ROOT="$site_root" HYPERDOC_CATALOG_SYSTEM="$slug" HYPERDOC_CATALOG_HOST=127.0.0.1 \
      HYPERDOC_CATALOG_PORT="$catalog_port" ${lib.getExe catalog}
  '';
  meta = {
    description = "Bootstrap: local Federated Wiki page zettelkasten-kiosk with its page-attached system, and the Catalog";
    mainProgram = "zettelkasten-kiosk";
  };
}
