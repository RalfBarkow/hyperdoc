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

## 6. Was für den echten Lisp-Critic-Test fehlt, und wie er laufen soll

Fehlend: Lesezugriff auf das vollständige Verzeichnis der Seiten-Assets (`a-critic-for-lisp.asd`, `package.lisp`,
`src/loader.lisp`, `src/hyperdoc-page.lisp`, `vendor/lisp-critic/` mit den sieben aufgezeichneten Dateien). Der Nutzer
stellt es in einem nicht versteckten Verzeichnis bereit (`~/.wiki` selbst ist als verstecktes Verzeichnis direkt unter dem
Home-Verzeichnis nicht freigebbar). Ablauf danach, in dieser Reihenfolge:

1. **Rein lesend:** Dateiliste; die `.asd` mit `*read-eval* nil` als Daten lesen und jede genannte Komponente als Datei
   nachweisen; keine `.asd` auswerten.
2. **Digests unabhängig bestätigen:** SHA-256 der sieben Engine-Dateien mit `sha256sum` und Python `hashlib`, gegen beide
   gespeicherten Evaluationen.
3. **Erst dann autorisierte Ausführung** in einer isolierten Runtime (eigener Prozess, kein Netz, Kopie der Dateien):
   `dreyeck/lisp-critic/engine-integration/tests` (`run-tests`, `run-page-station-layout-tests`), danach die Regeln der
   Riesbeck/Beane-Implementierung auf die Quelltextformen von PR #32.
4. **Evaluation Records und Critiques** mit Provenienz (Datei, Commit, Formposition, Quell-Digest, Engine-Digests) für den
   HyperDoc Inspector erhalten.

Bis dahin: keine Engine Critiques.
