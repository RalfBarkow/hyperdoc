# Trusted Executable Examples: ein begrenzter C→A-Slice

Stand: 31. Oktober 2026. Untersucht wurde `/workspace/hyperdoc`, Branch `work`,
HEAD `573fe37611a61d984260ebf43c797f7534211bdd`. Der Worktree war zu Beginn sauber.
Die Identität wurde zunächst mit Git, anschliessend mit `dreyeck/git` beobachtet.
Es wurde kein Commit, Deployment, SSH-Zugriff oder Neustart vorgenommen.

**Entscheidung:** eine explizite Seiten-/ASDF-Quellenrelation (C) mit gespeicherten,
lokal zur Darstellung freigegebenen Ergebnissen (A). B bleibt geschlossen.
Der Slice ist ein opt-in Entwicklungs- und Testartefakt, keine Freigabe des
gesamten Catalog für untrusted ausführbare Dokumente.

## A. Bestandsaufnahme und Aufgabenort

Die Aufgabe fällt am Übergang von einer untrusted Wiki-Referenz zu einem
privilegierten Lisp-Objekt an. Für Leser muss die Darstellung Herkunft,
beobachteten Testlauf und Darstellungsfreigabe unterscheiden. Für den lokalen
Betreiber muss eine Freigabe exakt begrenzt und zurücknehmbar bleiben.

Bestehende Routinen lösen Discovery, Quellbeobachtung, ASDF-Registrierung,
Inspector-Darstellung und Teile der Autorisierung. Keine im untersuchten
Quellbestand gefundene Routine verbindet diese bereits zu einer revisionsgebundenen
Freigabe gespeicherter Code-Ergebnisse. Eine Suche in den vorhandenen
Workflow-Dateien nach diesem Beispielpfad ergab keinen passenden Runner.
Die fehlende Verbindung ist hier der kleine neue Arbeitsanteil; die vorhandenen
Komponenten werden nicht durch ein weiteres Plugin-Framework ersetzt.

| Komponente | Fundstelle / bestehende Routine | Bedeutung und Grenze |
| --- | --- | --- |
| Wiki, Page, Story, Journal | `hyperbook-fedwiki/pages.lisp`: `fedwiki-page`, `story-item`, `journal-entry`, `set-page-data` | Roh-JSON bleibt getrennt von den Story-Objekten; `make-story-item` entfernt Standardfelder aus seiner Kopie. |
| Lokale Provenance | `dreyeck/src/local-fedwiki-page.lisp`: `local-fedwiki`, `local-fedwiki-page` | Kanonische lokale Site-Wurzel und Slug; ein Hostname allein ist keine Autorität. |
| Seitenrevision, Item-Identität | `dreyeck/src/local-fedwiki-page-source.lisp`: `observe-local-fedwiki-page-source`, `find-story-item` | SHA-256 und JSON stammen aus denselben gelesenen Bytes. Item-ID ist Identität, Index nur Position. |
| Typabhängige Darstellung | `hyperbook-fedwiki/story-items.lisp`: `render-story-item` | Code hatte keinen eigenen Renderer, nur die passive Standarddarstellung. HTML verwendet `unsafe-html`; das ist keine sichere allgemeine Publikationsfläche. |
| Lokale Item-Views und Bearbeitung | `local-fedwiki-page-source-views.lisp`, `fedwiki-item-edit-preview.lisp`, `fedwiki-page-edit-plan.lisp` | Vorhandene Item-Beobachtung und Edit-/Preview-Routine; kein nachgewiesener eigener Lisp-Code-Editor. Der Slice fügt keinen generischen Editor hinzu. |
| DITA | `dreyeck/src/dita-story-item.lisp`: `resolve-hyperdoc-reference` | `system` benutzt `asdf:find-system`; `example` kann registrierte Funktionen aufrufen. Nicht als passiver Freigabe-Renderer verwendbar. |
| Browser-Mech | `assets/hyperbook/fedwiki/mech-story.js`, `mech-host/host.js` | Separater Origin und Browser-Frame; kein Lisp-Worker. Nur definierte Nachrichten passieren die Brücke. |
| Seitengebundener JS-Code | `assets/hyperbook/fedwiki/mech-host/plugins/mech/blocks.js`: `code_emit` | Sammelt Code-Items, importiert ein `data:text/javascript`-Modul, ruft benannten Export auf. Die CLICK/TICK/Owner-Regel ersetzt keine lokale Lisp-Freigabe. |
| Ergebnis-Seiten im Browser | `mech-host/plugins/mech/blocks.js`: `showResult`; `library.js`: Solo-Nachrichten | Vorhandene `wiki.showResult(wiki.newPage(...))`-Aufrufstellen; im schmalen `host.js` sind beide APIs ausdrücklich `unavailable`. Kein neuer Lisp-Endpunkt daraus abgeleitet. |
| ASDF-Discovery | `dreyeck/src/fedwiki-assets.lisp`: `discover-asdf-files`, `page-attached-asdf-discovery-observation` | Beobachtet Dateien ohne deren Evaluation. |
| Registrierung | `dreyeck/src/page-attached-asdf.lisp`: `register-asd-systems`, `systems-defined-by-asd` | Erstere evaluiert bewusst vertrauenswürdige ASD-Dateien. Letztere beobachtet `registered-system`; kein `find-system`. Ein frischer Testprozess ist keine Sandbox. |
| Catalog-Angebot | `dreyeck/src/local-fedwiki-view.lisp`: `ensure-page-attached-workspace-offer`; `catalog.lisp`: `admit` | Öffnen einer Seite wertet die ASD-Datei nicht aus. Das bestehende Angebot erwartet einen eindeutigen zum Slug passenden Dateinamen. |
| Quellenrelationen | `page-attached-system-projection.lisp`, `topicmap.lisp`: `page-attached-asdf-projection` | Ein ASD-Autoritätsknoten kann mehrere Systemknoten definieren. Die Projektion bereits registrierter Systeme ist von deren Registrierung zu trennen. |
| Materialisierung | `page-attached-workspace-offer.lisp`, `page-attached-workspace-reconstruction.lisp` | Server-Development-Flag als Ausführungsgrenze; kein digestgebundener Grant. Ohne Server erlaubt die bisherige Policy Ausführung. |
| Inspector-Containment | `dreyeck/src/authority-policy.lisp`: `operation-contract`, `invocation-decision`, `example-thunk`, `run-button` | Registry ausserhalb des Wikis und serverseitige Wiederprüfung sind wiederverwendbar. Bisherige Verträge sind nicht automatisch revisionsgebunden; Entwicklungsmodus umgeht Teile des Containments. |
| Signierte Schreiboperationen | `fedwiki-item-edit-execution.lisp`, `authoring-http` | Signierte, begrenzte Seitenänderungen existieren. Deren Authority/Challenge ist kein Grant zum Ausführen eines ASDF-Systems. |
| Evaluation Records | `dreyeck/src/evaluation-record*.lisp` | Generisches Protokoll für Spezifikation, Input, Status, Resultat, Fehler, Evidenz, Zeiten und Identität. |
| Git-Provenance | `dreyeck/src/git-revision-reference.lisp`, `git-asdf-references.lisp`, `git-commit-inspection.lisp` | Commit-/Blob- und historische ASDF-Referenzen. Ein Branchname allein bindet keine Dirty-Worktree-Revision. |
| Quell-Snapshot | `dreyeck/src/source-snapshot.lisp` | Verifiziert ein spezielles Topic-Maps-Git-Manifest; nicht ohne neue Annahmen ein allgemeiner ASDF-Closure-Hasher. |
| Reading-Systeme | `dreyeck.asd`: `authority/reading`, `nested-actions/reading`, `clog-tutorial/reading`, `work/reading` | Bewährte lokale Lesepfade. CLOG-Tutorial-Beispiele montieren Routen; für diesen ersten Slice unnötig grosse Ausführungswirkung. |

Die Upstream-Dateien wurden nur gelesen. Alle neuen Implementierungsdateien
liegen unter `dreyeck/*`, ergänzt um Subsysteme in `dreyeck.asd` und diesen Bericht.

### Yen als Vergleich

Gelesen wurden [render.nix](https://github.com/vic/yen/blob/main/docs/modules/render.nix),
[site.nix](https://github.com/vic/yen/blob/main/docs/modules/site.nix), die
[docs-Verzeichnisstruktur](https://github.com/vic/yen/tree/main/docs) und das
[sini/files-README](https://github.com/sini/files/blob/main/README.md).
Bei Yen lesen Codeblöcke die Beispiel-Dateien; Werte und Tests greifen auf die
zugehörige Beispielauswertung zu. Die Page liefert Dokumentdatei, Sidebar und
Tests; `files` kann generierte Dateien gegen ihre deklarierte Quelle prüfen.
Übernommen wird diese gemeinsame Quellenbasis, keine Nix-Implementierung und
keine daraus abgeleitete Behauptung einer Runtime-Sicherheitsfreigabe.
Die beiden genannten `yen.oeiuwq.com`-Seiten waren mit dem Web-Werkzeug nicht
zugänglich; eine Prüfung ihrer tatsächlich ausgelieferten UI fand nicht statt.

## B. Architekturentscheidung

| Pfad | Wiederverwendung | Aufwand / verbleibendes Risiko | Entscheidung |
| --- | --- | --- | --- |
| A: gespeicherte geprüfte Darstellung | Page-Source, Code-Dispatch, SHA-256, Operation Contract, Evaluation Record | Klein; braucht expliziten Grant, vollständige vereinbarte Eingabeliste, Escaping und einen eingegrenzten Renderer | Jetzt als opt-in Slice implementiert |
| C: Seite ↔ ASDF-Systeme | Lokale Seitenobjekte, vorhandene ASDF-Discovery/-Projektion und registrierte Systeme | Klein für Quellenrelation, grösser bei generischer Closure-Ermittlung; Name und Version reichen nicht | Im Slice als explizite geprüfte Relation auf ein vorhandenes System |
| B: kontrolliertes Play | Identitätsbasierte Anfrage und bestehendes Entscheidungsprinzip | Hoch: authentifizierte Ausführungsfreigabe, Worker-Vertrag, vollständige Eingabe-Closure und OS-Isolation fehlen | Keine Ausführung implementiert |

Reihenfolge: C→A, danach dauerhafte Artefaktübergabe und schmale Publikationsroute;
erst anschliessend B. Die vorhandenen allgemeinen HTML-/Mech-/DITA-Pfade werden
nicht als geprüfte Umgebung für den neuen Trust Contract ausgegeben.

Mehrere Systeme lassen sich als Liste von Quellenbeschreibungen am Ergebnis
darstellen, ohne eine zweite Systemregistry. Mehrere Items pro Seite erhalten
getrennte Grants; mehrere Seiten dürfen dieselbe Quellenrevision referenzieren,
benötigen aber jeweils eigene an ihre Seitenkoordinate gebundene Grants.
Das bestehende Catalog-Angebot mit genau einem passenden Slug wird dafür nicht
umgedeutet oder erweitert. Der Slice demonstriert genau ein System.

## C. Trust Contract

`trusted` ist eine lokale Erlaubnis für eine benannte Wirkung an einer exakten
Revision, keine Eigenschaft eines Wiki-Strings.

1. **Provenance:** Site-Wurzel + Slug + SHA-256 der kompletten Page-Bytes,
   einschliesslich Journal; Item-ID + exakter Inhalt; Systemname, ASD-Pfad und
   ASD-SHA-256; manifestierte Dateien und Implementierungsversion. Die Fixture
   deklariert keine ASDF-Version; deshalb wird keine erfunden. Die Bytes sind
   massgeblich. Die Item-Revision ist durch Page-Digest und Item-Inhalt gebunden.
2. **Verification:** Der explizite Producer lädt die bekannte lokale Fixture
   und prüft `fixture-value` gegen `:fixture`. Er erfasst Beginn, Ende, Ergebnis
   oder Fehler. Vorher/nachher müssen dieselben manifestierten Dateien vorliegen.
   `:passed` bedeutet nur diesen Oracle-Erfolg, nicht erfolgreiche Durchführung
   sämtlicher Projektprüfungen und keine Sicherheitsanalyse beliebigen Codes.
3. **Authorization:** Nur vertrauenswürdiger lokaler Lisp-Code kann über
   `approve-display` einen bestehenden `operation-contract` registrieren.
   Der Reviewer-String ist Attribution, keine neue Authentifizierung.
   Der Contract bindet SHA-256 des gesamten gespeicherten Datensatzes und erlaubt
   ausschliesslich `:display-only`. Ein `trusted`-, `systems`- oder Hostname-Feld
   im Wiki erzeugt weder Contract noch Systemlookup. Der Marker
   `hyperdocExample` ist nur ein untrusted Suchschlüssel.
4. **Rendering:** Jede Darstellung prüft den aktuellen Registry-Eintrag,
   Wirkung, Status, Artefakt-Digest, Seitenkoordinate, hydratisiertes JSON,
   übergebenes Story-Item, aktuelle Seitenbytes und alle manifestierten Dateien.
   Der Registry-Eintrag wird nach den Dateiprüfungen nochmals verglichen.
   Fehler oder fehlende Dateien verweigern. Ausgegeben werden ausschliesslich
   gespeicherte Strings mit `esc`; keine Thunks, Scripts, DITA-Resolver,
   Transklusion, ASDF-Lookups oder Loader. Unmarkierter Code bleibt passive,
   escaped Auditansicht. Markierter, abgewiesener Code zeigt nur den Grund.
5. **Ausführung:** Der Slice kennt keinen ausführungsberechtigten Zustand und
   installiert keinen HTTP-Endpunkt. `request-play` antwortet auch bei einem
   gültigen Display-Grant mit `:refused`, `:execution-unavailable`, `:executed-p nil`.
   Es nimmt keine S-Expression und keinen Funktionsnamen zur Ausführung an.
6. **Invalidierung:** Änderungen an Seite, Item, Ergebnis, Manifest oder
   manifestierten Quellen/Abhängigkeiten machen die bisherige Freigabe ungültig.
   Prüfung gegen SHA-256 statt mtime oder Git-Branch. Kopieren auf einen anderen
   Slug oder eine andere lokale Site überträgt keine Freigabe; Remote-Seiten
   werden abgewiesen. Transklusion wird vom neuen Renderer nicht unterstützt.
7. **Widerruf:** `revoke-display` ersetzt den aktuellen Contract durch `:unsafe`.
   Ein zuvor gespeichertes Contract-Objekt wird nicht akzeptiert. Bereits
   ausgelieferte Bytes kann Widerruf nicht zurückholen; er gilt für neue
   Darstellungsentscheidungen. Grants sind volatil, werden nicht ins Wiki
   geschrieben und nicht nach einem Image-Neustart wiederhergestellt.
8. **Runtime Isolation:** Im Darstellungspfad findet keine Beispielausführung
   statt. Der Producer ist eine ausdrücklich vertrauenswürdige Wartungsoperation
   in einem Testprozess oder der kontrollierten SLY-Image. Er ist keine Sandbox
   und darf nicht an untrusted Seiten oder Browser-Aufrufe angebunden werden.

Die Eingabeliste ist ausdrücklich auf das CL-only-Beispiel beschränkt: ASD,
Package/Core, statische Fixture-Seite, Producer, Renderer, Testdefinition,
`dreyeck.asd`, `flake.lock`, SBCL-Core, Runtime-Pfad und SBCL-Executable.
Die geladene Fixture muss ASDF-seitig dependency-frei sein. `flake.lock` bindet
die deklarierte Plattform, verifiziert aber nicht alle tatsächlich installierten
Shared Libraries oder Lisp-Abhängigkeiten. Diese sowie die vertrauenswürdige
Build-Image sind TCB-Annahmen, kein nachgewiesener generischer Closure-Mechanismus.
Bei anderen Beispielen muss der Betreiber die vollständige relevante Closure
erst bestimmen und freigeben. Der Producer ist daher absichtlich fest verdrahtet.
Lisp-seitige Umdefinitionen durch privilegierte Betreiber liegen ebenfalls in
dieser Vertrauensgrenze. Der Testprozess lädt die Fixture frisch aus den Dateien.

## D. Implementierung und Prüffälle

Neue Dateien:

- `dreyeck/src/verified-example.lisp`: eine zusätzliche Klasse `stored-example`
  für die bisher fehlende Verbindung zwischen gespeicherten Ergebnissen,
  Seitenrevision und Quellenmanifest; implementiert das vorhandene
  Evaluation-Record-Protokoll. Wiederverwendet die Contract-Registry.
- `dreyeck/src/verified-example-fixture.lisp`: separat ladbarer Producer für
  das bestehende `page-attached-hyperdoc-fixture`, Operation `fixture-value`.
- `dreyeck/tests/verified-example.lisp`: positive und adversariale Prüfungen.
- `dreyeck/tests/fixtures/verified-example-site/pages/verified-fixture-value`:
  eine lokale Wiki-Seite mit einem bestehenden `code`-Item und Systemreferenz.
  Die ASDF-Datei liegt weiterhin bei der vorhandenen Fixture; es wird kein
  kopierter oder vom Wiki neu gelieferter Lisp-Code geladen. C wird als explizite
  Quellenrelation gezeigt, nicht als neuer Directory-Discovery-Mechanismus.

`dreyeck.asd` ergänzt `dreyeck/verified-example`, `/fixture` und `/tests`.
Der Catalog lädt diese Systeme nicht automatisch. Der Renderer hängt nicht
vom Producer ab. Die Fixture wird auch beim Laden des Producers noch nicht geladen.

| Geforderte Gegenprobe | Nachweis im Slice |
| --- | --- |
| Bekanntes freigegebenes Beispiel | Realer `render-story-item :code` zeigt gespeicherten Quelltext und `:FIXTURE`. |
| Unbekannt / nicht freigegeben | Keine Ergebnisdarstellung; sämtliche Play-Identitäten verweigert. |
| Codeänderung | SHA-Änderung einer deklarierten temporären Quelldatei verweigert. Der Worktree-Code wird für die Gegenprobe nicht verändert. |
| Kopie / Federation | Gleiche Bytes unter anderer Site oder anderem Slug verweigert. Keine Transklusionsroutine im Renderer. |
| Gefälschtes `trusted` | Manipuliertes Item verweigert; unbekannte Identität mit Reader-Makro-/Loop-/Script-Text bleibt Daten. |
| Direkter Ausführungsaufruf | `request-play` serverseitig verweigert. Es gibt keinen neuen HTTP-Endpunkt; ein HTTP-Integrationstest wurde nicht vorgetäuscht. |
| Fehlerhafte Auswertung | Die Fixture-Funktion wird im Test zeitweilig durch eine Fehlerfunktion ersetzt; Capture liefert `:failed` und Fehlertext. Display-Grant wird abgewiesen. |
| Endlose Ausführung | Loop-Text und alle Play-Anfragen starten nichts. Keine Aussage über Timeout/Abbruch eines tatsächlich gestarteten untrusted Workers. |
| Variable Catalog-Grösse | Vorhandener Catalog bleibt identisch; zusätzlich leerer und erweiterter Test-Catalog ohne feste erwartete Gesamtzahl. |
| Weitere Kontrollen | Ergebnis-Manipulation, case-only Änderung, fehlende Datei, Abhängigkeitsänderung, Widerruf, Escaping auch ausdrücklich freigegebener Ausgabe. |

Während positiver und negativer Render-/Play-Prüfungen sind `asdf:find-system`,
`asdf:load-system`, `asdf:load-asd`, `uiop:run-program` und die konkrete
Fixture-Funktion durch protokollierende Fehlerfallen ersetzt. Jede erreichte
Falle lässt den Test scheitern, auch wenn die Darstellung den Fehler abfängt.
Der ausgewählte View hat weder Assets noch Inspector-Referenzen/Thunks.

## E. Inspector-Handoff für die eigene SLY-Image

Zweck: Page-Source, tatsächlich registriertes ASDF-System, Display-Contract und
Evaluation Record als verschiedene Objekte sehen. Dies ist ein lokaler
Fixture-/Wartungsdurchlauf, kein Live-Nachweis deiner laufenden Image und keine
Produktionsoperation. Die folgenden Blöcke separat auswerten, damit die Packages
beim Lesen des nächsten Blocks existieren. ASDF muss den aktuellen Checkout kennen.

```lisp
(asdf:load-system "dreyeck/verified-example/fixture")
```

```lisp
(defun inspect-verified-example (object)
  (inspect object))
(dreyeck/verified-example/fixture:prepare-fixture)
(defparameter *verified-site*
  (dreyeck/verified-example/fixture:fixture-site-root))
(defparameter *verified-page*
  (dreyeck/local-fedwiki-page:make-local-fedwiki-page
   *verified-site*
   (dreyeck/local-fedwiki-page:make-local-fedwiki *verified-site* "verified-example-local")
   "verified-fixture-value"))
(defparameter *verified-item*
  (aref (hyperbook/fedwiki::story-of *verified-page*) 0))
(defparameter *verified-record*
  (dreyeck/verified-example/fixture:capture-fixture *verified-site* "fixture-value"))
(list (dreyeck/evaluation-record:evaluation-status-of *verified-record*)
      (dreyeck/evaluation-record:evaluation-result-of *verified-record*)
      (dreyeck/evaluation-record:evaluation-failure-of *verified-record*))
(inspect *verified-record*)
```

Erwartung: `(:PASSED ":FIXTURE" NIL)` vor dem Inspector. Die Evidenzansicht und
Slots zeigen Herkunft, Manifest, Spezifikation und Zeitpunkte; das ist noch
keine Darstellungsfreigabe. Nach Prüfung dieser konkreten lokalen Fixture kann
der Betreiber mit dem folgenden ausdrücklichen Wartungsschritt die Darstellung
in genau dieser Image erlauben:

```lisp
(defparameter *verified-display-grant*
  (dreyeck/verified-example:approve-display
   "local/fixture-value" *verified-record* "local SLY operator"))
(defparameter *verified-view*
  (dreyeck/verified-example:example-view
   "local/fixture-value" *verified-page* *verified-item*))
(list :decision
      (multiple-value-list
       (dreyeck/verified-example:display-decision
        "local/fixture-value" *verified-page* *verified-item*))
      :play (dreyeck/verified-example:request-play "local/fixture-value"))
(inspect-verified-example *verified-view*)
```

Der Helper benutzt ausschliesslich den Lisp-Inspector. Korrektur nach
Quellprüfung: `clog-inspect` startet CLOG selbst, wenn es noch nicht läuft; die
frühere Fallback-Version des Helpers garantierte daher keinen startfreien Aufruf.
Der [aktualisierte Handoff](verified-example-sly-run.md) enthält den expliziten
Weg in einen bereits manuell bereitgestellten CLOG-Body. Erwartung: `:DISPLAY-ONLY`,
gespeichertes `:FIXTURE`, kein Play-Button. Play liefert `:REFUSED`.

Für die unterscheidbaren Objekte und Relationen, nur im lokalen Betreiber-Inspector:

```lisp
(defparameter *verified-relations*
  (list :page *verified-page*
        :page-source (dreyeck/verified-example:example-page-source *verified-record*)
        :attached-systems (dreyeck/verified-example:example-systems *verified-record*)
        :registered-system (asdf:registered-system "page-attached-hyperdoc-fixture")
        :display-authorization *verified-display-grant*
        :evaluation-record *verified-record*
        :result-view *verified-view*))
(inspect-verified-example *verified-relations*)
```

`registered-system` beobachtet nur; es ersetzt sich hier nicht durch `find-system`.
Die allgemeine Page-/ASDF-Inspektion ist ein Betreiberwerkzeug und gehört nicht
in eine untrusted Publikationsroute. Zurückzusenden sind der Status-/Ergebnis-
Ausdruck, die `:DISPLAY-ONLY`-Entscheidung, die Play-Ablehnung und die beobachteten
Objekttypen. So bleibt der Testprozess-Nachweis von deiner Live-Image getrennt.

Widerruf und erneute Darstellung:

```lisp
(dreyeck/verified-example:revoke-display "local/fixture-value" "local review ended")
(defparameter *revoked-view*
  (dreyeck/verified-example:example-view
   "local/fixture-value" *verified-page* *verified-item*))
(inspect-verified-example *revoked-view*)
```

Erwartung: `REVOKED`, keine Quell-/Ergebnisanzeige im neuen View. Bereits
angezeigte Inspector-Views werden nicht nachträglich aus dem Browser gelöscht.

## F. Grenzen, Validierung und nächster Schritt

Die konkrete Testausführung und die erzeugte HTML-Probe stehen unter
[`trusted-executable-examples-evidence/`](trusted-executable-examples-evidence/).
Beobachtet: neue ASDF-Suite und bestehende Local-FedWiki-Page-Suite bestanden;
`git diff --check` sauber. Die zusätzliche `dreyeck/authority-policy`-Suite
scheitert an `containment-adapter-drift` für `CONTEXT-FEDWIKI-PAGE`. Derselbe
Fehler wurde in einem frischen Prozess ohne Laden des neuen Slices reproduziert.
Die betreffende Methode in `dreyeck/work/trails-rendered-federated-context.lisp`
liefert `nil`; der Scanner meldet die noch nicht erfasste neue Methode. Das ist
ein vorhandener Review-/Drift-Befund, kein hier nachgewiesener ausführbarer
Title-Bar-Bypass. Die vollständige Authority-Suite wird deshalb nicht als grün
ausgegeben und ihre Allowlist wurde nicht geändert.

Bei der Entwicklung wurden ausserdem eine zusätzliche schliessende Klammer
und der unzulässige verschachtelte `:force`-Load korrigiert. Ein erster
Authority-Testlauf scheiterte am hier nicht vorhandenen Standard-Wiki-Verzeichnis;
mit `HYPERDOC_FEDWIKI_SITE_ROOT` auf die vorhandene Test-Fixture kam der oben
reproduzierte Drift-Befund zum Vorschein. Keine Produktionsdateien wurden dafür
angelegt oder verändert.

Der reguläre Einstieg ist `(asdf:test-system "dreyeck/verified-example")`.
Wie die vorhandenen Page-attached-Tests startet er einen Testprozess, damit der
Fixture-`load-system :force t` ausserhalb eines laufenden ASDF-`test-op` erfolgt.
Der SBCL-Aufruf über PATH bewahrt dabei die konfigurierte Runtime-Hülle.

Nicht nachgewiesen: Browser-End-to-End, allgemeine Wiki-Sicherheit, persistente
signierte Artefakte, atomare Autorisierung gegenüber beliebigen externen
Dateischreibern, vollständige Plattform-Closure, untrusted Worker-Ausführung,
Timeout-/Kill-Verhalten, Netzwerk-/Credential-Isolation oder dein SLY-Livezustand.
Die nur lesenden Digest-Prüfungen erfolgen zum Darstellungszeitpunkt; sie halten
keine globalen Filesystem-Locks. Keine dieser Grenzen wird durch erfolgreiche
Unit-Tests zu einer Sicherheitsgarantie.

Für B fehlen konkret: ein auf Operation, Artefakt-Digest, Policy-Digest und
Ausführungsrecht begrenzter lokaler Grant; ein ID-only Request ohne Formularcode;
serverseitige erneute Freigabeprüfung vor Workerstart; unveränderliche Eingaben;
ein unprivilegierter separater OS-Worker mit CPU-/Speicher-/PID-/Output-Limits,
Wall-Clock-Timeout und Beendigung der gesamten Prozessgruppe; read-only
Input-Dateisystem und begrenztes Wegwerfverzeichnis; kein Netzwerk und keine
übernommenen Credentials/Sockets; ausschliesslich begrenzte Datenausgabe;
unterscheidbare Zustände für Erfolg, Fehler, Timeout und Abbruch. Ein frischer
SBCL-Prozess oder der vorhandene Mech-Frame erfüllt diesen Vertrag nicht.

Kleinster nächster Schritt: den obigen Fixture-View in SLY inspizieren und danach
eine dauerhafte, datengebundene Producer→Renderer-Übergabe für genau dieses
Beispiel spezifizieren und testen. Erst eine schmale Publikationsroute, die
ausschliesslich solche Artefakte rendert, sollte in den Catalog integriert werden.
Der allgemeine Story-Renderer darf dafür nicht ungeprüft mitbenutzt werden.

Rekonstruktionsdelta: Quellensuche → C→A-Entscheidung → lokaler Slice → Test- und
Ablehnungsnachweis. HyperDoc: opt-in View, keine Catalog-Registrierung. Lisp:
ein Record-Typ, vorhandene Contract-Registry und Evaluation-Generics, drei
Subsysteme. FedWiki: eine lokale Fixture-Seite, keine föderierte Publikation.
Replay: frischer Testprozess; SLY-Reload und Inspector-Beobachtung bleiben als
ausführbare, ausdrücklich lokale Handoff-Sequenz getrennt.
