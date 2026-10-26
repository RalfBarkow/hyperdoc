# Lokale HyperDoc-Lektüre des Topic-Maps-Beispiels 22U

Beobachtet am 26. Oktober 2026. Das optionale System lädt das abgeschlossene Beispiel aus dem eigenständigen Checkout und zeigt dessen native TMDM-Objekte im bestehenden Inspector. Es erzeugt keine zweite Topic-Identität oder eigenständige Graphkopie.

## Revisionen und Arbeitsbäume

- Quelle: `topic-maps`, `b2eecffa05de4fce41c10ae1ada9ae11a0c6e7dc`, sauber. Maßgebliche Lektüre dort: `docs/slice-22u-project-work.md`.
- Ziel: `hyperdoc-dreyeck-ch`, Branch **`dreyeck.ch`**, Basis `a9daaf8c1245bbaca79822be2cdabdab134b2fd7`. Die Ausführungsevidenz beschreibt den damals uncommittierten Testzustand auf dieser Basis. Der lokale Abschlusscommit auf `dreyeck.ch`, der diese Dateien enthält, versioniert die unveränderten getesteten Programm- und Testdateien; ihre Hashes stehen im Abschlussmanifest.
- Der anfangs ausgecheckte Branch `codex/nixos-migration-topic-map` bei `847a0743420712e5503cc1b343fa8ecd24fb018d` wurde nicht als Integrationsziel benutzt. `dreyeck.ch` war keinem anderen Worktree zugewiesen; der anfangs saubere Checkout wurde regulär umgeschaltet.
- Andere Worktrees und ihre begonnenen Änderungen sind erhalten. [Anfangszustand](initial-state.json), [Integritätsaudit](integrity.json).

Abschlussvermerk: `summary.json` und die Laufberichte bleiben datierte Beobachtungen vor dem Commit. Für den lokalen Commit wurden Diff, Manifest, gespeicherte Testergebnisse und geschützte Quellen erneut geprüft; keine Tests wurden neu ausgeführt. Lediglich dieser Abschlussvermerk und die zugehörige Dokumentationsbeschreibung im Manifest wurden ergänzt.

## Anschluss und native Navigation

ASDF-Systeme:

- `topic-maps/project-work-example`: unveränderte 22U-Quelle und produktiver CTM-Reader.
- `dreyeck/inspector/tmdm`: bestehende native Map-, Topic- und Name-Views samt Ausführungsprovenienz.
- `dreyeck/work/tmdm-reading`: bestehende Lektüre und Evaluation-Record-Verfahren.
- **`dreyeck/work/topic-maps-project-example`**: neue optionale Lektüre, nicht Bestandteil des produktiven Dienststarts.
- `dreyeck/work/topic-maps-project-example/tests`: über den normalen `asdf:test-system`-Aufruf des Elternsystems tatsächlich ausgeführt.

`checked-source-path` prüft den sauberen Quellcheckout und seine genaue Revision. Die CTM-Datei wird mit `asdf:system-relative-pathname` des registrierten Systems ermittelt. `run-example` verwendet `topic-maps.project-work.example:load-map` und damit den produktiven CTM-Reader. Die Document IRI stammt unverändert aus dem Beispiel. ASDF muss die Kernsysteme aus demselben Checkout laden.

`project-example-run` hält nur Ausführungsmetadaten, Git-Quellenreferenzen, eine datierte Modellbeobachtung und die CXTM-Bytes zu **einer** nativen Map. Die bereits vorhandene `register-execution`-Operation bindet diese Evidenz an genau dieses Map-Objekt. Die bestehenden DEFVIEW-Methoden und deren Quelldatei bleiben unverändert. Ergänzt werden Views für die tatsächlich gespielten Roles und deren native Associations, Types und Players.

Im Catalog **Topic Maps Project Example (22U)** öffnen, dann **Text pages → Reading Slice 22U → Topic Maps 22U → Read a fresh 22U Map**. Alternativ ist der neue View auf **Work Breakdown** auffindbar. Die Anzeige allein führt das Beispiel nicht aus.

Nach expliziter Ausführung:

1. **Topics → Topic #question → Roles → Role Gegenstand in Betrifft**.
2. **Parent Association → Role Arbeit in Betrifft → Role Player → Topic #project**.
3. Zur Parent Topic Map zurück, wieder `question`, dann **Roles → Role Gegenstand in Dokumentiert durch → Parent Association → Role Dokumentierte Quelle in Dokumentiert durch → Role Player → Topic #disposition**.

Die Namen sind Anzeigetexte. Links halten unmittelbar die nativen TMDM-Objekte. [Browser-Evidenz](browser.json), [EQ-Protokoll](native-eq.log), [Projektansicht](project.png), [Disposition](disposition.png) belegen beide Pfade im **selben frischen HyperDoc-Prozess**. Die zusätzlich beobachteten Pane-Ziele wurden gegen die kanonischen Topics, Roles und Associations derselben Map geprüft; inverse `rolesPlayed`-Beziehungen und der unveränderte Modellzustand wurden mitgeprüft.

## Ausführung und Regression

[Integrationslauf](integration-tests.json), [vollständiges Log](integration-tests.log): frischer SBCL **2.4.10**, ohne Benutzer-/Systeminitialisierung, Netzwerk gesperrt und beide Repositories schreibgeschützt. Exit 0 **und** Abschlussmarker wurden geprüft.

- 40 neue Prüfungen: ASDF-Quellpfad, echtes CTM-Einlesen, beide nativen Navigationspfade, Referenzziele und Types, inverse Beziehungen, kanonische EQ-Referenzen, vorhandene Views/Provenienz, explizite Ausführbarkeit ohne Ausführung beim Rendern, getrennte Übungsmap, unveränderte Quelldatei, kein Persistenz-Writer sowie eine gegen veränderliche String-Aliase abgesicherte datierte Beobachtung an einer separaten diagnostischen Wegwerfmap.
- 98 bestehende TMDM-Lektüreprüfungen: tatsächlich neu ausgeführt, einschließlich passender Fehlerdiagnostik.
- Bestehende Evaluation-Record-, Git- und Topicmap-Regressionen einschließlich deterministischer Projektion und TALA-Eingaben: erfolgreich. Es werden keine festen globalen Catalog-Eintragszahlen vorausgesetzt.
- Dokumentierter Startweg: `serve-topic-maps-project-example.lisp` in eigenem frischem Prozess, HTTP 200, anschließend eigener Testserver beendet ([Startbeleg](serve-smoke.json)).
- Browser: expliziter Button führt CTM-Einlesen aus, anschließend beide vollständigen Inspector-Pfade; Source-SHA-256 vorher/nachher `8f7012f3db2da4199a00029dc600ff7492747b9c9b081f4135dd817e66e9a85b`. Der ausschließlich lokal gestartete Testserver wurde beendet. Für diesen Browserlauf war nur Loopback im Lisp-Prozess erlaubt; der Browserkontext blockiert fremde HTTP-Ursprünge.

Eine ältere Unsupported-Gegenprobe musste an den aktuellen Readerstand angepasst werden. `template-topic-nested.ctm` besteht inzwischen tatsächlich. Dies wird zusätzlich geprüft. Der unveränderte Include-Vertrag **ohne expliziten Resolver** liefert im begrenzten Lektürepfad `CTM-UNSUPPORTED/:resource-resolver-required`, Zeile 1, Spalte 1, keine Map und niemals PASS. Der vollständige Korpus-Harness besitzt einen Resolver und behält seinen ursprünglichen PASS. [Retargeting](retargeting.json). Ein zunächst erwogener Template-Tail-Fall liefert CTM-REJECTION und wurde deshalb nicht als Unsupported-Kontrolle verwendet.

Der vorhandene **HyperDoc Project Workspace** ist eine andere Lektüre mit eigener Quellbindung `5a4a66850403cdfe2755c6c88083a8e31af89628`. Diese wurde nicht auf 22U umgestellt. Der Zusatzlauf in einem eigenen frischen Prozess mit dem vorhandenen Normalisierungscheckout bestand 265 Quell- und 175 Readback-Prüfungen (initiales Einlesen mit Modell: 14,1 Sekunden), überschritt anschließend während der Acceptance-Phase das 300-Sekunden-Fenster. Er gilt nicht insgesamt als bestanden: [separater Lauf](project-tests.json), [Log](project-tests.log). Die anschließend separat ausgeführte Acceptance-Phase bestand alle **125 Prüfungen** ([Evidenz](project-acceptance.json), [Log](project-acceptance.log)). Damit sind alle drei Phasen mit zusammen 565 Prüfungen tatsächlich nachgewiesen, verteilt auf zwei frische Prozesse; der erste zeitbegrenzte Gesamtlauf bleibt als solcher gekennzeichnet. Das ist kein Nachweis, dass beide unterschiedlich gepinnten Beispiele in einer gemeinsamen Lisp-Instanz gleichzeitig geladen werden können.

Vorbereitungsfehler sind als fehlgeschlagene Versuche erhalten: anfängliche ASDF-Output-Translation-Konfiguration, fehlende HyperBook-Registrierung sowie die alte und die unpassende Ersatz-Unsupported-Kontrolle. Der zusätzliche Workspace-Versuch mit dem falschen 22U-Pin wurde unterbrochen und gilt trotz SBCL-Exit 0 ausdrücklich nicht als bestanden. Ein separater erster Registry-Versuch ohne Nix-Bibliothekspräfix scheiterte an Alexandria. Maßgeblich sind ausschließlich die explizit erfolgreichen finalen Berichte; alte Slice-12A-Dateien gelten hier nie als neue 22U-Ausführung.

## Reproduzierbarer lokaler Start

Der reguläre aktuelle Nix-DevShell ist **nicht offline verfügbar**. `nix print-dev-env --offline --no-write-lock-file --option substitute false --option builders '' --option max-jobs 0 --json .#default` scheitert mit „Unable to start any build; either increase '--max-jobs' or enable remote builds.“ Ein reiner Dry-run weist 1846 noch zu bauende Ableitungen aus ([Plan](dev-shell-dry-run.json)). Nichts davon wurde gebaut oder heruntergeladen; keine Lockdatei, Profile, Konfiguration oder Dienste wurden geändert.

Der hier nachgewiesene begrenzte Lauf verwendet stattdessen das bereits vorhandene `sbcl-with-packages` und die vorhandenen sechs Inspector-Quellinputs. Deren NAR-Hashes stimmen mit dem aktuellen `flake.lock` überein ([Laufzeit/Hashes](runtime-sources.json)). Die übrigen Common-Lisp-Bibliotheken werden aus der bereits bestehenden Nix-Binary-Umgebung geladen. Daraus wird **keine vollständige Qualifikation des aktuellen Flakes** abgeleitet. Der erfolgreiche lokale Runtime-Preflight ist separat protokolliert.

Im Zielcheckout mit den lokal vorhandenen Store-Pfaden:

```sh
export TOPIC_MAPS_ROOT=/Users/rgb/workspace/topic-maps
export CL_SOURCE_REGISTRY='/nix/store/7l95gid3niz995qqpkgclj6355k50phf-source//:/nix/store/w26nr9dxpfsyzbviphnaaydmcww2h3y6-source//:/nix/store/ibq9zs9js02ln87vjmcl6xdafvpxzffx-source//:/nix/store/p62cd9zn5gnrd34wgbjjnqragxwx6dhh-source//:/nix/store/w15dbn9gy780n3p9k5b69dr3rrr5lczr-source//:/nix/store/9zkvhs70z8w06kximfrw3zm099qa87vj-source//'
env -u ASDF_OUTPUT_TRANSLATIONS /nix/store/8j4gxfa63znzgcba9x1mw68yz7cb0ywf-sbcl-with-packages/bin/sbcl \
  --noinform --no-sysinit --no-userinit --script scripts/test-topic-maps-project-example.lisp
```

Der Nix-Wrapper ergänzt seine Bibliotheksregistrierung. Das Bootstrap übernimmt daraus ausschließlich Store-Einträge neben den beiden ausdrücklich ausgewählten Checkouts. FASLs der beiden Checkouts gehen in einen temporären Cache. ASDF-Output-Translations werden **innerhalb von Lisp** gesetzt; keine Lisp-Ausdruckszeichenfolge an die vom Wrapper ergänzte Colon-Variable anhängen.

Für die interaktive lokale Lektüre dieselben Variablen verwenden, dann einen leeren temporären Site-Root mit `pages/` erstellen und ausdrücklich starten:

```sh
export HYPERDOC_22U_SITE_ROOT="$(mktemp -d /tmp/hyperdoc-22u-site.XXXXXX)"
mkdir -p "$HYPERDOC_22U_SITE_ROOT/pages"
export HYPERDOC_22U_PORT=18773
env -u ASDF_OUTPUT_TRANSLATIONS /nix/store/8j4gxfa63znzgcba9x1mw68yz7cb0ywf-sbcl-with-packages/bin/sbcl \
  --noinform --no-sysinit --no-userinit --script scripts/serve-topic-maps-project-example.lisp
```

`http://127.0.0.1:18773/` öffnen und den oben angegebenen Catalog-Pfad benutzen. Beenden mit Ctrl-C; kein produktiver Dienst wird dafür neu geladen. Der Browser-Regressionstest verwendet bereits installiertes Playwright und Chrome; seine exakten Argumente stehen in `browser.json`. Er erzeugt einen eigenen temporären Server und beendet ihn selbst.

In einer anderweitig vollständig vorbereiteten frischen Lisp-Umgebung genügen die Registrierung beider Checkouts und der Abhängigkeiten, `(asdf:load-system "dreyeck/work/topic-maps-project-example")` sowie der explizite Aufruf von `inspect-project-example`. Systemladen und Anzeigen der Lektüre sind keine automatische CTM-Ausführung.

## Geltungsgrenzen

- **Exercise on a separate fresh Map** erzeugt eine eigene Map und fügt nur dort die dokumentierte, scoped Übungsannotation hinzu. Die ursprüngliche Map und der CTM-Quelltext bleiben unverändert. Spätere Modelländerung wird in der datierten Ausführung als solche kenntlich.
- Das Editieren eines nativen Modells ist weder eine Änderung der ursprünglichen CTM-Quelle noch dauerhafte Speicherung. Es gibt keinen neuen CTM-Writer, Roundtrip, automatische Persistenz oder Publikation.
- Die bereits vorhandene CTM-Originalquelle enthält lokale `file:`-IRIs ihrer historischen Dokumente. Diese bleiben als Modellwerte unverändert; ein anderer Checkout-Ort löst solche Verweise nicht automatisch um. Nur die **Quellfindung** des Beispiels erfolgt ortsunabhängig über ASDF.
- Q-XTM-LOOP bleibt offen. Keine neuen historischen Aussagen oder Normentscheidungen.
- Alte generische Definitions-/Evidence-Views unterstützen wie bisher Map, Topic und Name. Die ergänzten Role-/Association-Views bieten native Navigation; daraus wird keine neue Quellenpositionszuordnung für diese Items abgeleitet.
- Die Originalkorpus-Tests und die vollständige Topic-Maps-Offline-Regression wurden in diesem HyperDoc-Schritt nicht neu ausgeführt. Das Audit prüft deren Dateien; gespeicherte Korpusstände sind keine neu ausgeführten Ergebnisse. Kein Case-Record und keine Registrierung wurde geändert.
- Keine Änderungen am eigenständigen Topic-Maps-Repository, kein Vendoring, keine Nix-Migration, keine neuen Abhängigkeiten, keine produktiven Dienste oder langlebigen Images, kein Push/Deployment.
