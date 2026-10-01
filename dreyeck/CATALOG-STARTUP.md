# Catalog startup contract

## Beobachteter Ausgangszustand

Lokal am 2026-10-01 beobachtet: Branch `dreyeck.ch`, HEAD
`91785f7711dfcac609ef5de084b2fd0172d46117`. Der Working Tree enthielt bereits
Änderungen an `dreyeck/pages/authority/Using HyperDoc as a Library.html` und
unversionierte `dreyeck/pages/authority/historical-witness.txt`. Beide gehören
nicht zu diesem Slice.

Der bisherige Pfad war:

```text
flake.nix: devShells.default / .tala
  → shellHook: CL_SOURCE_REGISTRY, HYPERDOC_HYPERSPEC_ROOT
  → scripts/serve-catalog.sh
  → ASDF: hyperdoc, hyperbook/server, dreyeck/local-fedwiki-view, konfiguriertes System
  → SERVE-CATALOG-WITH-LOCAL-FEDWIKI-VIEW
  → hyperbook/server:serve-catalog → serve-hyperbooks → clog:initialize
  → CLOG connection → clack:clackup → clack-handler-hunchentoot → Hunchentoot
```

Die Quellen für diese Rekonstruktion sind die genannten Dateien am beobachteten
HEAD, insbesondere [flake.nix](../flake.nix),
historisches Script (`git show 91785f7711dfcac609ef5de084b2fd0172d46117:scripts/serve-catalog.sh`),
[ASDF-Definitionen](../dreyeck.asd),
[Local-FedWiki-Start](src/local-fedwiki-view.lisp) und
[HyperBook-Server](../hyperbook-server/server.lisp). Die Backend-Auswahl wurde
zusätzlich in der tatsächlich aufgelösten, von nixpkgs gelieferten CLOG-Quelle
geprüft: CLOG 2.2, `source/clog-system.lisp:initialize` mit Default
`:server :hunchentoot`, und `source/clog-connection-websockets.lisp` mit
`clack:clackup`. `clog.asd` nennt Clack und Hunchentoot, aber nicht das dynamisch
gewählte System `clack-handler-hunchentoot`.

| Schicht | Verantwortung am Ausgangs-HEAD |
| --- | --- |
| Nix | SBCL samt Lisp-Paketquellen; gelockte zusätzliche Quellen; Emacs/SLY; HyperSpec. `.tala` ergänzt D2. Keine Catalog-App und kein NixOS-Modul. |
| Shell-Script | Repository-CWD, Portvalidierung, Umgebungsdefaults, vier ASDF-Ladevorgänge, Meldungen, Aufruf der Startfunktion, Warteschleife und SIGINT-Shutdown. |
| ASDF | Lisp-Systemgraph und Komponenten; `DEFHYPERDOC`-Ladeeffekte registrieren explizite Catalog-Mitglieder. |
| Lisp-Startfunktion | Lokale Wiki-Registrierung **vor** den Buchrouten; Serverstart; Installation von `/view` und `/gesture`. Bind-Adresse und Entwicklungsmodus werden weitergereicht. |
| CLOG / Clack / Hunchentoot | Routing/Websocket-UI, Clack-App und tatsächlicher HTTP-Listener. |

### Bereits ausgedrückte Abhängigkeiten und Dopplungen

`dreyeck/local-fedwiki-view` hängt direkt von `hyperbook/server` und
`dreyeck/catalog` ab. Über Catalog → Wiki-link → Dreyeck-HyperDoc →
`hyperdoc/explorer` ist auch `hyperdoc` abgedeckt. Damit sind die expliziten
Vorab-Ladevorgänge für `hyperdoc` und `hyperbook/server` redundant. Auch das
anschließende Laden des Default-Catalog ist redundant. Ein anderes
`HYPERDOC_CATALOG_SYSTEM` ergänzt faktisch das bereits geladene `dreyeck/catalog`;
es ersetzt dessen Mitgliedschaft nicht.

Nix stellte den Hunchentoot-Handler bereit, ohne dass der Anwendungssystemgraph
diese Laufzeitentscheidung ausdrückte. Die Shell enthielt außerdem
Anwendungs-Konfiguration und Lebensdauer als eingebetteten Lisp-Text. Der
Serverstart selbst war bereits sinnvoll in Lisp gekapselt. Das Script meldete
`127.0.0.1`, obwohl der tatsächliche Default-Bind `0.0.0.0` war.

### Einstiege am Ausgangs-HEAD

- `hyperdoc-sly`: nur in der Entwicklungsshell angeboten. Shell → Python →
  frisches SBCL/Slynk + Emacs/SLY. Keine Anwendungssysteme werden vorgeladen;
  [Slynk-Bootstrap](../scripts/hyperdoc-slynk.lisp) ist bewusst eine weiße Image.
- Lokaler Catalog: Script im vorbereiteten Lisp-Runtime. Das Script stellte
  weder gelockte Quellen noch HyperSpec selbst bereit. Lokal schlug ein nacktes
  SBCL ohne Registry bereits bei `dreyeck/local-fedwiki-view` mit
  `MISSING-COMPONENT` fehl. `nix develop` war somit der vorhandene, implizite
  Bereitstellungsweg, obwohl eine anderweitig gleichwertig konfigurierte
  Lisp-Installation prinzipiell ebenfalls genügte.
- NixOS: [WORKFLOW.md](WORKFLOW.md) und
  [deployment-reading.lisp](work/deployment-reading.lisp) bewahren
  **Operator-Evidenz**, wonach `/etc/nixos/hyperdoc-service.nix` im Checkout
  `/home/rgb/workspace/hyperdoc` den Befehl
  `nix develop .#tala -c ./scripts/serve-catalog.sh 8080` verwendet hat.
  Das ist keine aktuelle Serverbeobachtung. Der Service ist hier nicht definiert.

## Abgegrenzter, implementierter Slice

Die ausführbare Anwendung liegt als `packages.<system>.hyperdoc-catalog` und
`apps.<system>.catalog` in der Flake. [nix/lisp-runtime.nix](../nix/lisp-runtime.nix)
enthält die gemeinsame SBCL-Paket- und Quellenkonfiguration.
[nix/catalog.nix](../nix/catalog.nix) liefert das Executable mit seinen
Laufzeitressourcen einschließlich Git, HyperSpec und D2/TALA. `cleanSource`
entfernt VCS-Metadaten auch bei einem lokalen `path:`-Flake. Es startet SBCL
über einen absoluten Store-Pfad und verwendet den paketierten Quellensnapshot.

```text
nix run .#catalog / installiertes hyperdoc-catalog / NixOS ExecStart
  → scripts/catalog-main.lisp (ASDF-Adapter)
  → ASDF dreyeck/catalog-application
       → dreyeck/local-fedwiki-view + clack-handler-hunchentoot
  → dreyeck/catalog-application:main (Konfiguration, Vordergrund, Shutdown)
  → dreyeck/catalog-application:start-catalog (gemeinsamer Lisp-Anwendungskern)
  → bestehendes SERVE-CATALOG-WITH-LOCAL-FEDWIKI-VIEW
  → CLOG / Clack / Hunchentoot
```

[Die Anwendung](src/catalog-application.lisp) bietet `START-CATALOG` auch in
SLY an, ohne Signalhandler oder eine blockierende Warteschleife ins interaktive
Image einzubauen. `MAIN` ist der Prozessadapter und behandelt SIGINT/SIGTERM,
Fehlerstatus und Shutdown auch nach einem teilweise fehlgeschlagenen Start.
Die Portpräzedenz ist Argument → `HYPERDOC_CATALOG_PORT` → 8080; Hostdefault
bleibt `0.0.0.0`, `HYPERDOC_CATALOG_HOST` erlaubt eine explizite Bind-Adresse.
Der lokale Site-Root wird weiterhin ausschließlich von
`dreyeck/fedwiki-assets:configured-local-site-root` bestimmt.

Das Executable setzt seine Quellen unabhängig von `shellHook`, CWD und
persönlichen SBCL-Initdateien. Der ASDF-Adapter schließt persönliche
Source-Registry-Vererbung ausdrücklich aus: Der nixpkgs-SBCL-Wrapper erzeugt
leere Registry-Einträge, die sonst persönliche ASDF-Konfiguration einbeziehen.
Benutzer starten lokal mit `nix run .#catalog -- 8080` oder mit dem
installierten `hyperdoc-catalog`. Services verwenden dasselbe Executable
aus dem gebauten Nix-Paket.

### Verwendung und Service-Anschluss

Benutzerstart ohne Entwicklungsshell:

```sh
HYPERDOC_CATALOG_HOST=127.0.0.1 nix run .#catalog -- 8080
# oder: nix build .#hyperdoc-catalog
# ./result/bin/hyperdoc-catalog 8080
```

In `nix develop` ist dasselbe paketierte `hyperdoc-catalog` verfügbar. Für die
Arbeit an den **aktuellen Checkout-Quellen** in einer weißen `hyperdoc-sly`-Image:

```lisp
(asdf:load-system "dreyeck/catalog-application")
(dreyeck/catalog-application:start-catalog :host "127.0.0.1" :port 8080)
;; Die interaktive Image besitzt die Lebensdauer:
(clog:shutdown)
```

Für den Removal-Slice hat der Betreiber am 2026-10-01 bestätigt, dass der
NixOS-Service bereits das gebaute `hyperdoc-catalog` verwendet. Das ist neue
Operator-Evidenz; dieser Task führt keine Remote-Prüfung durch. Die oben
zitierten früheren Service-Snapshots bleiben historische Evidenz. Der bisherige
Kompatibilitätswrapper wird deshalb entfernt.

Beispiel für den Service-Anschluss an einen gepinnten Flake-Input `hyperdoc`:

```nix
let
  catalog = inputs.hyperdoc.packages.${pkgs.stdenv.hostPlatform.system}.hyperdoc-catalog;
in {
  systemd.services.hyperdoc.serviceConfig.ExecStart =
    "${catalog}/bin/hyperdoc-catalog 8080";
  systemd.services.hyperdoc.environment = {
    HYPERDOC_CATALOG_HOST = "127.0.0.1";
    HYPERDOC_FEDWIKI_SITE_ROOT = "/home/rgb/.wiki/dreyeck.ch/";
  };
}
```

Benutzer, Dateizugriff und Proxy-Konfiguration bleiben Verantwortung des
serverlokalen Moduls. Der Service-Benutzer braucht einen schreibbaren Lisp-Kompilationscache
und Zugriff auf seinen Wiki-Store. `ExecStart` benötigt weder Nix noch einen
Checkout zum **Starten** des Catalog. NixOS-Aktivierung, Linux-Laufzeittest und
Proxy/Websocket-Akzeptanz auf dem Server wurden lokal nicht behauptet.

### Grenzen und dauerhafte Tests

Das Paket enthält Quellen/Assets und startet eine frische Lisp-Image; es ist
kein gespeichertes SBCL-Core. Beim ersten Start werden die zusätzlichen
Quellsysteme im Benutzer-Cache kompiliert. Der gepinnte Entwicklungspaketbestand
wurde für diesen Slice beibehalten, nicht auf eine minimale Closure reduziert.

Ein Flake-Quellensnapshot enthält keine `.git`-Historie. Die bestehenden
Git-Lesebeispiele entdecken ihren Checkout anhand des ASDF-Quellortes
([git-repository-checkout.lisp](src/git-repository-checkout.lisp)); im Store
steht ihnen daher kein impliziter Checkout zur Verfügung. Ein expliziter,
separater Git-Lesekontext wäre ein weiterer Slice. Ebenso ergänzt
`HYPERDOC_CATALOG_SYSTEM` nur Systeme aus der paketierten Registry.

- [ASDF-Anwendungstests](tests/catalog-application.lisp): ein Systemload reicht;
  18 Bücher, kein Authoring-Runtime, Konfiguration/Portpräzedenz, bestehende
  Routen und Shutdown nach normalem Stop bzw. Teilstartfehler.
- [Executable-Tests](../tests/test_catalog_executable.py): fremdes CWD,
  isoliertes HOME, vergiftete persönliche ASDF/SBCL-Konfiguration und PATH;
  echte HTTP-Antworten von `/` und `/view`, Portvalidierung, Vordergrund und
  SIGINT/SIGTERM samt Freigabe des Ports. Kein Browser/Websocket-UI-Test.
- [Nix-Check](../nix/catalog-check.nix) verbindet beide Tests unter
  `checks.<system>.catalog`. Bestehende Catalog-/FedWiki-Tests bleiben erhalten.

```sh
nix build .#checks.x86_64-darwin.catalog
nix develop -c sbcl --noinform --no-userinit --non-interactive \
  --eval '(require :asdf)' \
  --eval '(asdf:test-system "dreyeck/local-fedwiki-view")' \
  --eval '(asdf:test-system "dreyeck/catalog")'
```
