# a-critic-for-lisp: Seiten-Assets, HTTP-Auslieferung und Discovery (8. November 2026)

Gesonderte Befunde zum page-attached ASDF-System `a-critic-for-lisp`, das an die Federated-Wiki-Seite
`a-critic-for-lisp` gebunden ist (https://dreyeck.ch/view/a-critic-for-lisp), und zur Riesbeck/Beane-Implementierung, die
es unter `vendor/lisp-critic/` erwartet. Alle Zugriffe waren lesende HTTP-GETs; an der produktiven Wiki-Farm wurde nichts
geändert. Kennzeichnung: **[obs]** beobachtet · **[abg]** aus dem Quelltext abgeleitet · **[rec]** aus einer
Repository-Aufzeichnung, nicht neu beobachtet.

Getrennt gehalten werden: **Seitenaufruf** (die Seite als FedWiki-JSON), **Dateizugriff** (die Seiten-Assets als Dateien),
**ASDF-Registrierung** (Auswerten einer `.asd`-Datei — das ist bereits Codeausführung) und **Ausführung** (Laden des
Systems und der Riesbeck/Beane-Implementierung).

## 1. Seitenaufruf

| Adresse | Antwort | Bedeutung |
|---|---|---|
| `https://dreyeck.ch/view/a-critic-for-lisp` | 200, 679 Byte HTML [obs] | CLOG-Startseite (`/js/boot.js`); identisch (gleicher SHA-256) für `/view/no-such-page-zz91` und `/`. Kein Nachweis, dass die Seite existiert. |
| `https://dreyeck.ch/a-critic-for-lisp.json`, `/system/sitemap.json`, `/assets/pages/…` | 404 von nginx [obs] | Die Apex-Domain ist nicht die Wiki-Farm. |
| `https://hyperdoc.dreyeck.ch/a-critic-for-lisp.json` | 200, FedWiki-JSON [obs] | 55 Story Items, 144 Journal-Aktionen |
| `https://wiki.ralfbarkow.ch/a-critic-for-lisp.json` | 200, FedWiki-JSON [obs] | dieselbe Story (gleicher Digest), 145 Journal-Aktionen |

Laut Aufzeichnung leitet nginx `dreyeck.ch` an den Catalog (`127.0.0.1:8080`) und `*.dreyeck.ch` an die Wiki-Farm
(`127.0.0.1:3000`) [rec, `docs/fedwiki-original-editor-farm/README.md`]. Die Farm-Site `dreyeck.ch` (Daten unter
`~/.wiki/dreyeck.ch/`, der Default von `configured-local-site-root`) ist damit über HTTP nicht unter ihrem eigenen Namen
erreichbar [abg]. Erratene `*.dreyeck.ch`-Hosts wurden nicht abgefragt: Die Farm legt laut Aufzeichnung für einen
unbekannten Host beim ersten Aufruf eine Site an [rec]. Der produktive Catalog bietet die Seite als page-attached
Workspace an („ASDF artifact `assets/pages/a-critic-for-lisp/a-critic-for-lisp.asd`, state offered, workspace not
materialized, reconstruction not available in this runtime“, Bildschirmfoto des Nutzers); welche Site-Root er verwendet,
ist daraus nicht ablesbar.

Asset-Referenz der Story: genau ein Item vom Typ `assets` mit dem Text `pages/a-critic-for-lisp` (beide Hosts) [obs].
Digests: [evidence/page-json-2026-11-08.txt](evidence/page-json-2026-11-08.txt).

## 2. Dateizugriff: die HTTP-Auslieferung der Seiten-Assets ist unvollständig

`GET /plugin/assets/list?assets=…` (Assets-Plugin der Farm) und direkte `GET /assets/pages/a-critic-for-lisp/…` [obs]:

| Host | `pages/a-critic-for-lisp` | `…/src` | `…/vendor/lisp-critic` |
|---|---|---|---|
| `hyperdoc.dreyeck.ch` | `PATCH-NOTES.md`, `README.md`, `a-critic-for-lisp.asd`, `package.lisp` | `ENOENT` (scandir); `src/loader.lisp`, `src/hyperdoc-page.lisp`: 404 | `ENOENT`; `README`, `lisp-critic.asd`, `lisp-critic.lisp`: 404 |
| `wiki.ralfbarkow.ch` | `ENOENT` | — | `ENOENT` |

Damit sind öffentlich ausgeliefert: die Definition des page-attached ASDF-Systems und `package.lisp`. **Nicht**
ausgeliefert: die in der Definition genannten Komponenten `src/loader.lisp` und `src/hyperdoc-page.lisp` und die gesamte
Riesbeck/Beane-Implementierung. Die Verzeichnisse fehlen auf dem Server selbst (`ENOENT`), sie werden nicht nur
zurückgehalten. Digests der vier ausgelieferten Dateien: [evidence/served-asset-digests.txt](evidence/served-asset-digests.txt).
Keine davon gehört zu den sieben Engine-Dateien, deren SHA-256 die gespeicherten Evaluationen
(`dreyeck/pages/lisp-critic/evaluations/*.json`) aufzeichnen; ein Digest-Vergleich ist über HTTP für keine dieser sieben
Dateien möglich.

Nach Angabe des Nutzers liegt die Riesbeck/Beane-Implementierung vollständig auf seinem Entwicklungsrechner
(`/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/a-critic-for-lisp/vendor/lisp-critic/`), und alle sieben Digests
stimmen dort mit `setf-push-reading-plan.json` überein. Die Unvollständigkeit betrifft also die öffentlich ausgelieferten
Seiten-Assets, nicht diesen lokalen Bestand. Die unabhängige Bestätigung der Digests steht aus, bis die Dateien dieser
Entwicklungsumgebung bereitgestellt sind.

## 3. Discovery im Repository

[abg, `dreyeck/src/fedwiki-assets.lisp`, `dreyeck/src/lisp-critic-reading.lisp`] Die Discovery ist rein dateibasiert,
ohne HTTP: Seite `<site>/pages/<slug>`, `assets`-Items → `<site>/assets/<ref>/`, dort nur die Liste der `.asd`-Dateien
(`page-attached-asdf-discovery-observation`, wertet nichts aus). Die Seiten-Assets der Riesbeck/Beane-Implementierung
werden in dieser Reihenfolge gesucht (`engine-asset-root-candidates`): `DREYECK_LISP_CRITIC_ROOT` (exklusiv, wenn gesetzt),
die konfigurierte Site-Root (`HYPERDOC_FEDWIKI_SITE_ROOT`, sonst `~/.wiki/dreyeck.ch/`), dann `~/.wiki/wiki.ralfbarkow.ch/`
(im Code `:historical-site`; die API-Bezeichner bleiben unverändert). `engine-station-files-missing` prüft nur Dateien.

Ausgeführt [obs] auf genau den von `hyperdoc.dreyeck.ch` ausgelieferten Dateien, in einer Scratch-Site-Root, einem
frischen SBCL-Prozess ohne Netzwerkzugang ([evidence/discovery-probe-2026-11-08.log](evidence/discovery-probe-2026-11-08.log),
[evidence/discovery-probe.lisp](evidence/discovery-probe.lisp)): Seite gefunden, eine `.asd`-Datei; es fehlen
`lisp-critic.asd`, `tables.lisp`, `write-wrap.lisp`, `extend-match.lisp`, `lisp-critic.lisp`, `lisp-rules.lisp`;
`require-station` verweigert mit `ENGINE-INTEGRATION-REQUIRES-A-SOURCE-STATION … lacks …`.

## 4. Befund: `:assets-present-p T` ist irreführend

In derselben Beobachtung meldet `a-critic-for-lisp-observation` unter `:loading` **`:assets-present-p T`**, während
`:wrapped-source` **`:present-p NIL`** meldet und sechs Engine-Dateien fehlen [obs]. Ursache [abg]:
`lisp-critic-source-station-present-p` (`dreyeck/src/lisp-critic.lisp`) ist nur `probe-file` auf das Asset-Verzeichnis.
„Assets vorhanden“ heißt dort also „das Verzeichnis existiert“, nicht „das page-attached ASDF-System und die
Riesbeck/Beane-Implementierung sind vollständig“. Ein Leser der Inspector-Ansicht kann daraus eine lauffähige Engine
schließen, die es nicht gibt. Kleinste Korrektur (nicht umgesetzt): die Zeile umbenennen (`:asset-root-present-p`) und
daneben `engine-station-files-missing` anzeigen.

## 5. Befund: Discovery und Ausführung sind in einer Entwicklungs-Runtime nicht getrennt

Beim obigen Lauf hat `a-critic-for-lisp-observation` die heruntergeladene `a-critic-for-lisp.asd` **ausgewertet**: Danach
war `a-critic-for-lisp` in ASDF registriert (die Pakete `A-CRITIC-FOR-LISP` und `LISP-CRITIC` wurden nicht angelegt,
nichts wurde geladen) [obs]. Das Auswerten einer `.asd` ist Codeausführung. Ursache [abg]: `%wrapper-system-observation`
ruft `asdf:find-system` auf, sobald `execution-permitted-p` wahr ist, und `execution-permitted-p`
(`dreyeck/src/page-attached-workspace-reconstruction.lisp`) ist in jedem Image ohne laufenden Server wahr — also in jeder
Entwicklungs- und Test-Runtime. Eine *Ansicht* der Seite führt dort Code der Seite aus. Der Inhalt war ein reines
`defsystem`, das vorher gelesen worden war, und der Prozess war ohne Netz; die Trennung von lesender Discovery und
autorisierter Ausführung war in diesem Schritt dennoch nicht eingehalten.
Kleinste Korrektur (nicht umgesetzt): die Beobachtung liest die `.asd` mit `*read-eval* nil` als Daten (wie die
Domain-Mutanten der Tests) und überlässt `find-system` der ausdrücklich autorisierten Materialisierung.

## 6. Die fehlende Verbindung zwischen ASDF-Referenz und ausgelieferten Assets

Drei Dinge mit demselben Namen, die nicht verbunden sind:

| Ebene | Was dort `a-critic-for-lisp` ist | HTTP? |
|---|---|---|
| **HyperDoc-Catalog-Route** `https://dreyeck.ch/view/a-critic-for-lisp` | Eine CLOG-Route. Für jeden Pfad wird dieselbe Startseite ausgeliefert; erst in der WebSocket-Sitzung liest der Catalog-Prozess die Seite aus seiner lokalen Site-Root (`install-local-fedwiki-view-route`, `dreyeck/src/local-fedwiki-view.lisp`) [abg], laut Aufzeichnung `/home/rgb/.wiki/dreyeck.ch/` [rec]. Findet die dateibasierte Discovery genau eine `.asd` mit dem Namen der Seite, nimmt `dreyeck/catalog::admit` ein Angebot in den Catalog auf. | Nein: Der Catalog liefert keine Asset-Dateien aus (`/assets/pages/…` → 404) [obs]. |
| **Inspector-Zeile „ASDF artifact“** | `page-attached-relative-asd` setzt `assets/pages/<slug>/<slug>.asd` aus der Subjekt-ID `workspace:a-critic-for-lisp` zusammen, laut Quelltext „No ASDF, no probing, no reconstruction“ [abg]. Ein Pfad relativ zu *einer* Site-Root, keine Adresse. | Nein |
| **Federated-Wiki-Seite und Seiten-Assets** | Die Farm-Site `dreyeck.ch` liegt unter `/home/rgb/.wiki/dreyeck.ch/`, aber nginx leitet keine Anfrage für `dreyeck.ch` an die Farm [rec]. Erreichbar ist dieselbe Seite auf der Farm-Site `hyperdoc.dreyeck.ch`, deren Asset-Verzeichnis (`/home/rgb/.wiki/hyperdoc.dreyeck.ch/assets/pages/a-critic-for-lisp/`) ein anderes ist. | Ja, aber nur ein Teil (Abschnitt 2) |

Die fehlende Verbindung ist damit: **Die Seiten-Assets der Site-Root, aus der der Catalog die Seite und das Angebot liest,
haben keine HTTP-Adresse.** Was unter einer HTTP-Adresse ausgeliefert wird, ist die Kopie einer *anderen* Farm-Site, und
diese ist unvollständig. Ob unter `/home/rgb/.wiki/dreyeck.ch/assets/pages/a-critic-for-lisp/` auf dem Server `src/` und
`vendor/lisp-critic/` liegen, ist von außen nicht beobachtbar: Für das Angebot genügt dem Catalog die `.asd`.

## 7. Das bestehende Repository `RalfBarkow/assets`

Die Aufzeichnung der Bereitstellung bezieht die Asset-Kopie unter `/home/rgb/.wiki/dreyeck.ch/assets/` für eine andere Seite
(`reading-java-source-as-data`) inhaltsgleich auf einen Commit von `RalfBarkow/assets`; die Herkunft der Kopie ist dort als
nicht festgestellt vermerkt [rec]. Dieses bestehende, **private** Repository enthält bei `856cf07` (21.09.2026, „Record one
Critic run so it can be read without running it“) das **vollständige** Asset-Verzeichnis `pages/a-critic-for-lisp/` [obs]:
die Systemdefinition, `package.lisp`, `src/loader.lisp`, `src/hyperdoc-page.lisp`, `vendor/lisp-critic/` (die sieben
aufgezeichneten Dateien und `README-upstream.txt`), `scripts/import-upstream.sh`, `evaluations/car-cdr.json` und
`hyperdoc/A Critic for Lisp.html`. Es wurde nur gelesen (flache, baumlose Klonung, nur dieses Verzeichnis ausgecheckt).

- **Die sieben Engine-Digests**, unabhängig mit `sha256sum` und Python `hashlib` berechnet, stimmen mit **beiden**
  gespeicherten Evaluationen überein [obs] ([evidence/assets-repository-2026-11-08.txt](evidence/assets-repository-2026-11-08.txt)).
  Das bestätigt die Angabe des Nutzers für seinen lokalen Bestand.
- **Die von `hyperdoc.dreyeck.ch` ausgelieferte Kopie** ist ein älterer Teilstand desselben Verzeichnisses: `.asd`,
  `package.lisp` und `README.md` sind byte-gleich, `PATCH-NOTES.md` ist die frühere Fassung ohne die Abschnitte „Wrapper“
  und „Vendored source“; `src/`, `vendor/`, `scripts/`, `evaluations/`, `hyperdoc/` fehlen [obs].
- `PATCH-NOTES.md` im Repository dokumentiert die eine lokale Änderung der Riesbeck/Beane-Implementierung: In
  `extend-match.lisp` ist `var-prefix` mit `defparameter` statt `defconstant` deklariert.

**Prüfung ohne Auswertung** [obs]: Beide `.asd`-Dateien wurden mit `*read-eval* nil` als Daten gelesen (kein `#.`, keine
Reader-Bedingungen); danach war keines der Systeme bei ASDF registriert. Das page-attached ASDF-System `a-critic-for-lisp`:
`:depends-on (#:uiop)`, `:serial t`, Komponenten `package.lisp`, `src/loader.lisp`, `src/hyperdoc-page.lisp` — alle
vorhanden. Die Riesbeck/Beane-Implementierung `lisp-critic`: Komponenten `tables`, `write-wrap`, `extend-match`,
`lisp-critic`, `lisp-rules`, keine externen Abhängigkeiten; beim *Auswerten* legt die Datei ein Paket
`lisp-critic-system` an. Als Text gelesen: `src/loader.lisp` greift nicht auf das Netz zu und ruft
`scripts/import-upstream.sh` (das von xach.com lädt) nicht auf; `load-lisp-critic` trägt `vendor/lisp-critic/` in die
ASDF-Registry ein und lädt `:lisp-critic`. `src/hyperdoc-page.lisp` definiert nur `install-hyperdoc-page`.

Nicht geklärt: ob sich eine unveränderliche Kopie als Archiv direkt in Claude Code Cloud bereitstellen lässt — die
Dokumentation der Umgebung nennt dafür keinen Weg; das wurde nicht weiter untersucht, weil der Zugriff über das bestehende
Repository möglich ist.

## 8. Stand und nächster Schritt

Schritte 1–3 sind ohne Auswertung erledigt (Abschnitt 7): Das page-attached ASDF-System ist im bestehenden Repository
vollständig, die sieben Digests stimmen mit beiden gespeicherten Evaluationen überein, beide ASDF-Definitionen und ihre
Abhängigkeiten sind als Daten gelesen. Öffentlich über die Seite erreichbar ist die Riesbeck/Beane-Implementierung nicht
(Abschnitte 2 und 6).

Schritt 4, die Ausführung, wartet auf eine ausdrückliche Freigabe der Quelle: einer Kopie von
`RalfBarkow/assets@856cf07:pages/a-critic-for-lisp/` in einem eigenen SBCL-Prozess dieser Cloud-Umgebung, ohne Netz
(eigener Netzwerk-Namespace), leeres HOME, eigener FASL-Cache. Dann `dreyeck/lisp-critic/engine-integration/tests`
(`run-tests`, `run-page-station-layout-tests`) und die Regeln der Riesbeck/Beane-Implementierung auf die Quelltextformen
von PR #32; Evaluation Records und Critiques mit Provenienz (Datei, Commit, Formposition, Quell-Digest, Engine-Digests) für
den HyperDoc Inspector. Eine Evaluation ohne Befund ist ein gültiges Ergebnis; die Riesbeck/Beane-Implementierung hat keine
Regeln, die SHOP3-Code als solchen beurteilen.

Bis dahin: keine Engine Critiques.
