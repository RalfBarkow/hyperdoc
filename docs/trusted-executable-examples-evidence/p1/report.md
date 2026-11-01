# P1-Evidenz zu Review-Befund D1

Diese Ablage sichert den bereits abgeschlossenen P1-Lauf vom 1. November 2026.
Bei der Sicherung wurde P1 **nicht erneut ausgeführt**. Alle 20 Dateien unter
[`original/`](original/) sind unveränderte Kopien der vorhandenen Artefakte aus
`/tmp/hyperdoc-p1/`; der damalige Bericht bleibt als
[`original/report.md`](original/report.md) erhalten. Dieser Bericht ergänzt die
Einordnung und beschreibt die Ablage, ohne historische Belege umzuschreiben.

**`P1-PASS` bedeutet erfolgreiche Durchführung der Gegenprobe, nicht Erfüllung
eines beschlossenen Rendering-Vertrags.** Eine Entscheidung über I0 steht aus.

## Provenienz und vorhandene Belege

- Repository: `RalfBarkow/hyperdoc`.
- Untersuchte Code-Revision: `9b57bd4bb87d92fbf3061b91a42a6f539e18cdb1`.
- Review-Artefakte: `4b56c1d80a6d061e1cc1da9321e132032c019dd8`,
  „Reading the Trusted Executable Examples Review“, D1.
- Quellbaum: `1c2a981db7cf7700f39325cc3aad26440555370e`.
- Laufzeit laut beiden vorhandenen Protokollen: **SBCL 2.4.10**.
- Beide Protokolle enden mit `P1-PASS`; der gespeicherte Exitcode ist **0**.

Die untersuchte Revision war im lokalen Repository nicht vorhanden. Für den
damaligen Lauf wurde sie unter `/tmp/hyperdoc-p1/source/` aus dem lokalen direkten
Elterncommit `573fe37611a61d984260ebf43c797f7534211bdd` und elf über den
GitHub-Connector gelesenen Zielblobs rekonstruiert. Die gespeicherte
[Quellverifikation](original/source-verification.json) weist **1510 geprüfte
Datei-Blobs und keine Abweichung** aus; der zugehörige
[Commitbaum](original/source-tree.json) ist mitgesichert. Der aktuelle
Repository-HEAD bei der Sicherung ist der genannte Elterncommit und darf nicht
mit der untersuchten Revision verwechselt werden.

Die Prüfung bei der Sicherung fand keine fehlende Datei. Alle zehn Einträge des
ursprünglichen [SHA-256-Manifests](original/artifact-sha256.json) stimmen mit den
vorhandenen Dateien überein. Zusätzlich wurden alle 20 Kopien byteweise mit den
Originalen verglichen, die gespeicherten Verifikationsdaten auf Konsistenz
geprüft und die acht HTML-Dateien mit den HTML-Ausgaben des finalen Logs
verglichen. Diese Archivprüfungen sind in
[`preservation-check.json`](preservation-check.json) dokumentiert. Sie ersetzen
keine neue Laufzeit- oder Quellverifikation; eine solche fand hier nicht statt.

## Beobachtungen des abgeschlossenen Laufs

Das [Lisp-Testskript](original/probe.lisp) erzeugt das gewöhnliche Wiki-Item aus
dem vorgegebenen JSON und rendert dasselbe Objekt vor und nach dem ausdrücklichen
Laden von `dreyeck/verified-example` über `render-story-item :code` innerhalb von
`html-and-references`. Das Item ist eine ausdrücklich deklarierte Gegenprobe,
keine als ursprüngliche Wiki-Quelle ausgegebene Ersatzquelle.

```json
{"type":"code","id":"render-probe","text":"(defun square (x) (* x x))","language":"lisp"}
```

Vor dem Laden, aus dem [finalen Laufprotokoll](original/final-result.log):

```html
<div><i><small><span class='inspector-inspect'><span id='inspect-309'>code</span></span></small></i></div><pre style='background-color: #eee;'>(defun square (x) (* x x))</pre>
```

```lisp
REFS ((:ID "inspect-309" :ID-IN-HTML T :EQ-ITEM T :EQ-RESOLVED T)) ASSETS NIL
```

Nach dem ausdrücklichen Laden:

```html
<pre>(defun square (x) (* x x))</pre>
```

```lisp
REFS NIL ASSETS NIL
```

Der sichtbare Quelltext bleibt erhalten. Typkennzeichnung, grauer Hintergrund
und Inspector-Referenz entfallen im zweiten Story-HTML. Vorher löst die im HTML
enthaltene ID in der tatsächlich zurückgegebenen Referenz-Alist auf dasselbe
Item auf (`eq`). Geprüft wurde diese Datenschnittstelle, kein Browserklick.
Generierte Inspector-IDs können zwischen Läufen variieren.

Die zusätzliche Escaping-Probe liefert in beiden Phasen denselben Inhalt:

```html
&lt;script&gt;alert(1)&lt;/script&gt;&amp;&quot;&#039;
```

`language: "lisp"` und der unbekannte Wert `"p1-unknown-language"` bleiben im
Item sowie seiner Data-View erhalten. Bei fehlendem `language` bleibt das Feld
fehlend (`LANGUAGE NIL PRESENT NIL`). Alle drei Fälle zeigen innerhalb derselben
Phase denselben Story-HTML-Aufbau und dieselbe Methodenkette.

Die protokollierten anwendbaren Primärmethoden sind:

```lisp
;; vorher
((T T T))
;; nachher
(((EQL :CODE) T T) (T T T))
DEFAULT-METHOD-IDENTICAL-AND-NEXT T
```

Ein markiertes Item mit unbekanntem Grant ergab als schmale zusätzliche Probe:

```html
<section class='hyperdoc-stored-example'><p>NOT-APPROVED; execution disabled</p></section>
```

Dies ist kein umfassender Nachweis aller markierten Verified-Example-Fälle.

## Technische Ableitungen

Die nach dem Laden nächste allgemeine Methode ist nachweislich dasselbe
Methodenobjekt wie zuvor. Ein `call-next-method` ausschließlich im unmarkierten
Else-Zweig würde in der untersuchten Revision deshalb die bisherige
Inspector-Darstellung wiederverwenden, einschließlich Typreferenz, Escaping
und grauem `<pre>`. Die generierte Referenz-ID wäre neu, ihr Ziel erneut das
übergebene Item.

Der markierte Zweig ruft laut untersuchter Verzweigung separat `%render-example`
auf. Eine ausschließlich auf den Else-Zweig begrenzte Delegation würde ihn nicht
verändern. Diese Einschätzung verbindet die beobachtete Methodenkette mit der
Quelltextanalyse; eine entsprechende Korrektur wurde weder implementiert noch
ausgeführt.

Die Metadaten werden nicht aus dem Item entfernt. Der beobachtete Verlust
betrifft den Zugang über die bisherige Typreferenz im Story-HTML.

## Offene normative Fragen

- Soll I0 für unmarkierte Code-Items die bisherige Inspector-Darstellung
  einschließlich Typreferenz und Hintergrund erhalten?
- Welcher gewünschte Vertrag soll für vorhandene, fehlende und unbekannte
  `language`-Werte gelten?

P1 dokumentiert die tatsächlichen Unterschiede und entscheidet diese Fragen
nicht. Insbesondere wird aus der Bestandsaufnahme kein Sprach-Fallback-Vertrag
abgeleitet und keine Korrektur freigegeben.

## Testbedingungen und Reproduzierbarkeit

Die vorhandenen Skripte und Protokolle dokumentieren jeweils einen frischen,
isolierten SBCL-Prozess mit `--no-sysinit --no-userinit --non-interactive`.
Zunächst wird `hyperbook/fedwiki` geladen; vor der Baseline prüft das Skript,
dass das Package `DREYECK/VERIFIED-EXAMPLE` noch nicht existiert. Anschließend
wird `dreyeck/verified-example` ausdrücklich geladen und dasselbe Item mit
demselben Page-Objekt erneut gerendert.

Verwendet wurden vorhandene lokale Abhängigkeiten, ein temporärer FASL-Cache
und eine reine `fedwiki-page`-Instanz ohne Seitenabruf. Kein Serverstart, keine
HTTP-Ausführung gegen HyperDoc, kein Deployment, keine Berührung laufender
CLOG-/SLY-Images oder von Port 8081. Der Beispieltext wurde als Daten gerendert,
nicht evaluiert. Die Data-Views wurden direkt erzeugt.

Die unveränderten Originale enthalten bewusst die damaligen absoluten Pfade:

- [`run.py`](original/run.py): Launcher mit Wurzel `/tmp/hyperdoc-p1/`, der
  Quellwurzel `source/` und temporärem FASL-Ziel `fasl/`.
- [`probe.lisp`](original/probe.lisp): eigentliche Gegenprobe, schreibt die
  HTML-Ausgaben ebenfalls unter `/tmp/hyperdoc-p1/`.
- [`local-environment.json`](original/local-environment.json): damalige lokale
  ASDF-Registry und PATH; der Launcher überschreibt Registry-Quellwurzel und
  FASL-Ziel ausdrücklich.
- [`verify-source.py`](original/verify-source.py): prüft die Git-Blob-Hashes
  des danebenliegenden `source/` gegen `source-tree.json` und schreibt einen
  neuen Verifikationsbericht.

Für eine spätere Wiederholung müssen diese Dateien in einen separaten
Arbeitsbereich unter der ursprünglichen Wurzel kopiert, die **exakte untersuchte
Revision** als `source/` bereitgestellt und SBCL sowie die dokumentierten lokalen
Abhängigkeiten verfügbar sein. Die historischen Befehle lauten:

```sh
python /tmp/hyperdoc-p1/verify-source.py
python /tmp/hyperdoc-p1/run.py > /tmp/hyperdoc-p1/reproduced.log 2>&1
```

Diese Befehle wurden bei der Sicherung **nicht** ausgeführt. Ein Start direkt
aus `original/` macht den Launcher nicht portabel. Der temporär rekonstruierte
vollständige Quellbaum, die kompilierten FASLs und die separaten Review-Kopien
sind nicht Teil dieser Evidenzablage. Die Sicherung enthält Quellrevision,
Commitbaum und damaligen Verifikationsbericht, kein eigenständiges Paket aller
Quellen und Abhängigkeiten. Nach Wegfall von `/tmp` muss die Quellrevision erneut
bereitgestellt werden; der aktuelle Projekt-HEAD genügt dafür nicht.

## Umfang der Sicherung

Gesichert sind beide vollständigen Laufprotokolle
([erster Lauf mit Kompilierung](original/result.log),
[finaler Wiederholungslauf](original/final-result.log)), die acht HTML-Dateien,
Skripte, Umgebung, Exitcode, kompakte Belege, ursprünglicher Bericht und
Hash-/Quellmanifeste. Für die gesamte Ablage enthält
[`archive-sha256.json`](archive-sha256.json) SHA-256-Werte aller übrigen Dateien.

Die Aussage „Keine Repositorydatei wurde geändert“ im historischen Originalbericht
beschreibt den damaligen P1-Lauf. Diese spätere Sicherung fügt ausschließlich
Dateien unter `docs/trusted-executable-examples-evidence/p1/` hinzu. Sie ändert
keinen produktiven Renderer und keine Wiki-Seite; kein Commit oder Push wurde
erstellt.
