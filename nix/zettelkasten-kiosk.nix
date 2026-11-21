# Bootstrap for the page-attached HyperDoc «zettelkasten-kiosk»: one command from a terminal to a local Federated Wiki
# page that carries the ASDF system, and a fresh HyperBook Catalog that shows it.
#
#   nix run github:RalfBarkow/hyperdoc/work/zettelkasten-kiosk#zettelkasten-kiosk [-- --sly]
#
# Effects, each stated before it happens:
#  1. In the local wiki's site root (HYPERDOC_FEDWIKI_SITE_ROOT, default ~/.wiki/localhost): create pages/zettelkasten-kiosk
#     and assets/pages/zettelkasten-kiosk/ (the system's files) only if they are missing. Existing files are never
#     overwritten; a difference is reported.
#  2. The Catalog on 127.0.0.1 (HYPERDOC_CATALOG_PORT, default 8080), started first so that it does not depend on the wiki:
#     - default: the packaged Catalog of this revision with the system from the Nix store (the packaged Catalog refuses
#       to load a page's system after startup, and this keeps it so);
#     - with --sly: a development image like hyperdoc-sly, with Slynk, that activates the system from the page's
#       assets, and an Emacs with SLY attached to it, working in that assets directory.
#  3. If nothing answers on the wiki port (HYPERDOC_WIKI_PORT, default 3000): build and start the wiki fleet pins
#     (RalfBarkow/wiki 7dd4055, with the code and assets plugins; HYPERDOC_WIKI_FLAKE names another installable,
#     HYPERDOC_WIKI_COMMAND an installed wiki program) in farm mode on 127.0.0.1 for as long as this command runs. It
#     gets a HOME of its own, so ~/.wiki/config.json does not configure it; its data stay in ~/.wiki. Read-only unless
#     HYPERDOC_WIKI_LEGACY_EDIT=1 (unclaimed sites editable, still only on 127.0.0.1). A running wiki is used as it is.
#  4. Progress every 30 s; «Bereit:» only when both answer, otherwise which link does not and why.
{ lib, writeShellApplication, coreutils, curl, diffutils, gnugrep, emacsPackagesFor, emacs, catalog, runtime, topicMaps,
  source, revision }:
let
  emacsWithSly = (emacsPackagesFor emacs).emacsWithPackages (epkgs: [ epkgs.sly ]);
in
writeShellApplication {
  name = "zettelkasten-kiosk";
  runtimeInputs = [ coreutils curl diffutils gnugrep ];
  text = ''
    slug=zettelkasten-kiosk
    system_dir="${source}/dreyeck/work/zettelkasten-kiosk"
    wiki_flake="''${HYPERDOC_WIKI_FLAKE:-github:RalfBarkow/wiki/7dd4055047e9f6b9919b5d3c418abd3fa4044b3b#wiki}"
    site_root="''${HYPERDOC_FEDWIKI_SITE_ROOT:-$HOME/.wiki/localhost}"
    site_root="''${site_root%/}"
    wiki_port="''${HYPERDOC_WIKI_PORT:-3000}"
    catalog_port="''${HYPERDOC_CATALOG_PORT:-8080}"
    state="''${XDG_CACHE_HOME:-$HOME/.cache}/hyperdoc/zettelkasten-kiosk"
    page="$site_root/pages/$slug"
    assets="$site_root/assets/pages/$slug"
    sly=0
    for argument in "$@"; do
      case "$argument" in
        --sly) sly=1 ;;
        *) echo "Unbekannte Option: $argument (erlaubt: --sly)" >&2; exit 2 ;;
      esac
    done

    answers() { curl -s -o /dev/null --max-time 2 "$1"; }
    pids=()
    cleanup() { for p in "''${pids[@]}"; do kill "$p" 2>/dev/null || true; done; }
    trap cleanup EXIT INT TERM
    mkdir -p "$state"

    echo "Zettelkasten-Kiosk: Bootstrap ($([ "$sly" = 1 ] && echo "mit Emacs/SLY" || echo "verpackter Catalog"))"
    echo "  Wiki-Seitenordner: $site_root"
    echo "  Wiki:              http://localhost:$wiki_port/"
    echo "  Catalog:           http://localhost:$catalog_port/"
    echo "  Protokolle:        $state/"
    echo

    if answers "http://127.0.0.1:$catalog_port/"; then
      echo "Port $catalog_port ist belegt (lsof -nP -iTCP:$catalog_port -sTCP:LISTEN zeigt den Prozess)." >&2
      echo "Den Prozess beenden oder HYPERDOC_CATALOG_PORT=8081 voranstellen." >&2
      exit 1
    fi

    # 1. The carrier page and its assets, only if missing.
    if [ -e "$page" ]; then
      if cmp -s "$page" "$system_dir/fedwiki/$slug.json"; then
        echo "Seite:   vorhanden, gleich wie im System ($page)"
      else
        echo "Seite:   vorhanden, weicht vom System ab; nicht überschrieben ($page)"
      fi
    else
      echo "Seite:   lege an $page"
      mkdir -p "$site_root/pages"
      install -m 0644 "$system_dir/fedwiki/$slug.json" "$page"
    fi
    if [ -e "$assets" ]; then
      if diff -rq "$system_dir" "$assets" > /dev/null 2>&1; then
        echo "Assets:  vorhanden, gleich wie im System ($assets)"
      else
        echo "Assets:  vorhanden, weichen vom System ab; nicht überschrieben ($assets)"
      fi
    else
      echo "Assets:  lege an $assets (das ASDF-System der Seite)"
      mkdir -p "$(dirname "$assets")"
      cp -R "$system_dir" "$assets"
      chmod -R u+w "$assets"
    fi

    # 2. The Catalog, first and independent of the wiki.
    catalog_log="$state/catalog.log"
    common_env=(HYPERDOC_FEDWIKI_SITE_ROOT="$site_root" HYPERDOC_CATALOG_HOST=127.0.0.1 HYPERDOC_CATALOG_PORT="$catalog_port")
    if [ "$sly" = 1 ]; then
      loader=$(${emacsWithSly}/bin/emacs -Q --batch --eval \
        '(progn (require (quote sly)) (princ (expand-file-name "slynk/slynk-loader.lisp" (file-name-directory (locate-library "sly")))))')
      port_file="$state/slynk-port"
      rm -f "$port_file"
      echo "Catalog: starte Entwicklungs-Image mit Slynk; System aus den Assets der Seite; Protokoll $catalog_log"
      env "''${common_env[@]}" HYPERDOC_PAGE_SLUG="$slug" HYPERDOC_SLYNK_LOADER="$loader" HYPERDOC_SLYNK_PORT_FILE="$port_file" \
        CL_SOURCE_REGISTRY="${runtime.sourceRegistry}:${topicMaps}//:${source}//" \
        HYPERDOC_HYPERSPEC_ROOT="${runtime.hyperspecRoot}" HYPERDOC_SOURCE_REVISION="${revision}" \
        ${runtime.sbcl}/bin/sbcl --dynamic-space-size 8192 --noinform --no-sysinit --no-userinit --non-interactive \
          --load "${source}/scripts/zettelkasten-kiosk-sly.lisp" > "$catalog_log" 2>&1 &
      pids+=($!)
      catalog_pid=$!
      for _ in $(seq 1 600); do [ -s "$port_file" ] && break; kill -0 "$catalog_pid" 2>/dev/null || break; sleep 1; done
      if [ -s "$port_file" ]; then
        slynk_port=$(cat "$port_file")
        echo "Emacs:   verbinde mit Slynk auf 127.0.0.1:$slynk_port; Arbeitsverzeichnis $assets"
        echo
        echo "Fresh Lisp image:"
        echo "  implementation/version: SBCL $(${runtime.sbcl}/bin/sbcl --version | cut -d' ' -f2)"
        echo "  Slynk host: 127.0.0.1"
        echo "  Slynk port: $slynk_port"
        echo
        echo "Attach another SLY client:"
        echo "  M-x sly-connect"
        echo "  Host: 127.0.0.1"
        echo "  Port: $slynk_port"
        echo
        echo "Example:"
        echo "  Spacemacs -> M-x sly-connect -> 127.0.0.1 -> $slynk_port"
        echo
        HYPERDOC_REPO_ROOT="$assets" HYPERDOC_SLYNK_HOST=127.0.0.1 HYPERDOC_SLYNK_PORT="$slynk_port" \
          ${emacsWithSly}/bin/emacs -Q --load "${source}/scripts/hyperdoc-sly.el" > "$state/emacs.log" 2>&1 &
        pids+=($!)
      else
        echo "Slynk meldete sich nicht; siehe $catalog_log" >&2
        tail -20 "$catalog_log" >&2
      fi
    else
      echo "Catalog: starte den verpackten Catalog mit dem System; Protokoll $catalog_log"
      env "''${common_env[@]}" HYPERDOC_CATALOG_SYSTEM="$slug" ${lib.getExe catalog} > "$catalog_log" 2>&1 &
      pids+=($!)
      catalog_pid=$!
    fi

    # 3. The wiki: use a running one, else build and start the pinned one on loopback.
    wiki_pid=""
    wiki_log="$state/wiki.log"
    if answers "http://127.0.0.1:$wiki_port/"; then
      echo "Wiki:    läuft bereits auf Port $wiki_port; wird so verwendet"
    elif [ "$(basename "$site_root")" != "localhost" ]; then
      echo "Wiki:    keine Wiki auf Port $wiki_port, und der Seitenordner heisst nicht …/localhost; eine Farm würde ihn" >&2
      echo "         nicht finden. Wiki selbst starten oder HYPERDOC_FEDWIKI_SITE_ROOT anpassen." >&2
    else
      if [ -n "''${HYPERDOC_WIKI_COMMAND:-}" ]; then
        wiki_program="$HYPERDOC_WIKI_COMMAND"
      else
        echo "Wiki:    baue $wiki_flake (beim ersten Mal einige Minuten)"
        wiki_out=$(nix build --no-link --print-out-paths "$wiki_flake" 2> "$state/wiki-build.log" | tail -1) || {
          echo "Wiki-Build fehlgeschlagen; siehe $state/wiki-build.log" >&2; tail -20 "$state/wiki-build.log" >&2; }
        wiki_program="''${wiki_out:+$wiki_out/bin/wiki}"
      fi
      if [ -n "$wiki_program" ]; then
        wiki_args=(--farm --data "$(dirname "$site_root")" --host 127.0.0.1 --port "$wiki_port")
        [ "''${HYPERDOC_WIKI_LEGACY_EDIT:-0}" = 1 ] && wiki_args+=(--security_legacy true)
        mkdir -p "$state/wiki-home"
        echo "Wiki:    starte $wiki_program auf 127.0.0.1:$wiki_port (Farm, Daten $(dirname "$site_root"), eigenes HOME); Protokoll $wiki_log"
        HOME="$state/wiki-home" "$wiki_program" "''${wiki_args[@]}" > "$wiki_log" 2>&1 &
        wiki_pid=$!
        pids+=("$wiki_pid")
      fi
    fi

    # 4. Wait for both, with progress; say plainly what does not answer.
    wiki_ok=0; catalog_ok=0; waited=0
    while :; do
      answers "http://localhost:$wiki_port/" && wiki_ok=1
      answers "http://127.0.0.1:$catalog_port/" && catalog_ok=1
      [ "$wiki_ok" = 1 ] && [ "$catalog_ok" = 1 ] && break
      if [ "$catalog_ok" = 0 ] && ! kill -0 "$catalog_pid" 2>/dev/null; then
        echo "Catalog beendet, bevor er antwortete; siehe $catalog_log" >&2; tail -20 "$catalog_log" >&2; exit 1
      fi
      if [ "$wiki_ok" = 0 ]; then
        if [ -z "$wiki_pid" ] && [ "$waited" -ge 5 ]; then
          echo "Wiki:    keine Wiki auf Port $wiki_port; die Trägerseite ist nicht erreichbar." >&2; wiki_ok=skip
        elif [ -n "$wiki_pid" ] && { ! kill -0 "$wiki_pid" 2>/dev/null || grep -q "unexpectly exitted\|Error:" "$wiki_log"; }; then
          echo "Wiki-Start fehlgeschlagen; siehe $wiki_log" >&2; tail -20 "$wiki_log" >&2; wiki_ok=skip
        fi
      fi
      [ "$wiki_ok" = skip ] && [ "$catalog_ok" = 1 ] && break
      sleep 1; waited=$((waited + 1))
      [ $((waited % 30)) = 0 ] && echo "  … ''${waited} s: Wiki $([ "$wiki_ok" = 1 ] && echo antwortet || echo "noch nicht"), Catalog $([ "$catalog_ok" = 1 ] && echo antwortet || echo "noch nicht (der erste Start übersetzt Lisp-Quellen)")"
    done
    echo
    if [ "$wiki_ok" = 1 ]; then echo "Bereit:"; else echo "Teilweise bereit (Wiki fehlt, siehe oben):"; fi
    [ "$wiki_ok" = 1 ] && echo "  Trägerseite in der Wiki:  http://localhost:$wiki_port/view/$slug"
    echo "  HyperDoc:                 http://localhost:$catalog_port/6F061-zettelkasten-kiosk"
    echo "Beenden mit Ctrl-C (beendet auch alles, was hier gestartet wurde)."
    wait "$catalog_pid"
  '';
  meta = {
    description = "Bootstrap: local Federated Wiki page zettelkasten-kiosk with its page-attached system, and the Catalog";
    mainProgram = "zettelkasten-kiosk";
  };
}
