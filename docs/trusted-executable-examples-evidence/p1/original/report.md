# P1-Gegenprobe zu D1

Ausgeführt am 1. November 2026 in einem frischen, isolierten SBCL-2.4.10-Prozess.
Exitcode: **0**, Abschluss: `P1-PASS`.

Code: `RalfBarkow/hyperdoc` bei `9b57bd4bb87d92fbf3061b91a42a6f539e18cdb1`.
Review-Kontext: `4b56c1d80a6d061e1cc1da9321e132032c019dd8`,
„Reading the Trusted Executable Examples Review“, D1.

Die Zielrevision fehlte in den lokalen Git-Objektdatenbanken. Der vollständige
Quellbaum wurde unter `/tmp/hyperdoc-p1/source/` aus dem lokalen direkten
Elterncommit `573fe37611a61d984260ebf43c797f7534211bdd` und elf read-only über den
GitHub-Connector gelesenen Zielblobs rekonstruiert. Alle **1510** Datei-Blobs
stimmen mit dem GitHub-Commitbaum überein: **0 Abweichungen**. Der Tree-SHA ist
`1c2a981db7cf7700f39325cc3aad26440555370e`; Details in `source-verification.json`.
ASDF meldet sowohl `hyperbook/fedwiki` als auch `dreyeck/verified-example` mit
dieser temporären Quellwurzel. Ausschließlich vorhandene lokale Abhängigkeiten
wurden verwendet; ihre Registry ist in `local-environment.json` festgehalten.

## Reproduktion

```sh
python /tmp/hyperdoc-p1/verify-source.py
python /tmp/hyperdoc-p1/run.py > /tmp/hyperdoc-p1/reproduced.log 2>&1
```

Der Launcher deaktiviert System-/Benutzer-Init, startet einen eigenen SBCL und
legt FASLs unter `/tmp/hyperdoc-p1/fasl/` ab. Das Skript `probe.lisp` lädt zunächst
`hyperbook/fedwiki`, prüft, dass `DREYECK/VERIFIED-EXAMPLE` noch nicht existiert,
rendert die Items, lädt anschließend explizit `dreyeck/verified-example` und
rendert dieselben Item- und Page-Objekte erneut. Es benutzt in beiden Phasen
`render-story-item :code` innerhalb `html-and-references`. Das Page-Objekt ist
eine reine `fedwiki-page`-Instanz, ohne Seitenabruf oder Server.

## Beobachtete Ausgaben

Unmarkiertes JSON:

```json
{"type":"code","id":"render-probe","text":"(defun square (x) (* x x))","language":"lisp"}
```

Vor dem expliziten Laden:

```html
<div><i><small><span class='inspector-inspect'><span id='inspect-309'>code</span></span></small></i></div><pre style='background-color: #eee;'>(defun square (x) (* x x))</pre>
```

```lisp
REFS ((:ID "inspect-309" :ID-IN-HTML T :EQ-ITEM T :EQ-RESOLVED T)) ASSETS NIL
```

Nach dem expliziten Laden:

```html
<pre>(defun square (x) (* x x))</pre>
```

```lisp
REFS NIL ASSETS NIL
```

Die generierte Inspector-ID steht vorher im HTML und löst in der tatsächlich
zurückgegebenen Referenz-Alist mit `assoc` auf genau dasselbe Objekt (`eq`) auf.
Nachher existiert weder ein entsprechendes HTML-Element noch ein Referenzeintrag.
Dies prüft die HTML-/Inspector-Datenschnittstelle; ein Browserklick wurde nicht
ausgeführt. Die ID ist durch `gensym` erzeugt und kann bei Wiederholung variieren.

| Eigenschaft | Vorher | Nachher |
| --- | --- | --- |
| Quelltext | vollständig im `<pre>` | vollständig im `<pre>` |
| Typkennzeichnung | `code` als Inspector-Referenz | entfällt im Story-HTML |
| Grauer Hintergrund | Inline-Stil vorhanden | entfällt |
| Referenz zum selben Item | ein Eintrag, `eq` wahr | keine Referenzen |
| Item-Klasse / Typ | `STORY-ITEM` / `:CODE` | unverändert |
| `language` im Objekt | `"lisp"`, vorhanden | unverändert |

Die zusätzliche Escaping-Probe mit `<script>alert(1)</script>&"'` ergibt in
beiden Fällen denselben escaped Inhalt:

```html
&lt;script&gt;alert(1)&lt;/script&gt;&amp;&quot;&#039;
```

Die vorhandene Data-View zeigt das `language`-Feld vor und nach dem Laden.
Die neue Methode entfernt die Metadaten also nicht aus dem Objekt; sie entfernt
den bisherigen Zugang über die Typreferenz im Story-HTML.

## Fehlende und unbekannte Sprache: Bestandsaufnahme

`language` fehlt: `LANGUAGE NIL PRESENT NIL` in beiden Phasen; Data-View ohne
language-Zeile. `language: "p1-unknown-language"`: Wert und Anwesenheit bleiben
in beiden Phasen erhalten; Data-View mit entsprechender Zeile. Beide Varianten
erzeugen jeweils denselben Story-HTML-Aufbau wie die lisp-Variante derselben
Phase. Es gibt dabei keinen sprachabhängigen Methodendispatch, keine
Syntaxhervorhebung und keine Ausführung. Daraus wird kein normativer
Fallback-Vertrag abgeleitet.

## Dispatch und Einschätzung zu `call-next-method`

Tatsächliche anwendbare Primärmethoden, in Reihenfolge:

```lisp
;; vorher
((T T T))
;; nachher
(((EQL :CODE) T T) (T T T))
DEFAULT-METHOD-IDENTICAL-AND-NEXT T
```

Die nachher nächste Defaultmethode ist nachweislich dasselbe Methodenobjekt wie
vorher. Ein `call-next-method` ausschließlich im unmarkierten Else-Zweig würde
deshalb in dieser Revision die vorherige Inspector-Darstellung einschließlich
Typreferenz, Escaping und grauem `<pre>` wiederverwenden. Die generierte ID wäre
neu; ihr Ziel wäre erneut dasselbe übergebene Item.

Der markierte Zweig ruft separat `%render-example` auf. Ein nur im Else-Zweig
eingesetztes `call-next-method` würde ihn nicht verändern. Als schmale
Beobachtung erzeugte ein markiertes Item mit unbekanntem Grant unverändert:

```html
<section class='hyperdoc-stored-example'><p>NOT-APPROVED; execution disabled</p></section>
```

Diese Einschätzung folgt aus der tatsächlich beobachteten Methodenkette und
der gelesenen Verzweigung; ein hypothetischer Fix wurde **nicht implementiert**.
P1 bestätigt die Darstellungsänderung des Befunds D1. Ob die passive neue
Darstellung beabsichtigt ist oder die bisherige Darstellung erhalten werden
soll, entscheidet diese technische Gegenprobe nicht.

Kein Serverstart, kein HTTP-Zugriff auf HyperDoc, kein Deployment und keine
Berührung laufender CLOG-/SLY-Images oder von Port 8081. Keine Repositorydatei
wurde geändert; kein Commit oder Push. Das Codebeispiel wurde als Daten
gerendert und nicht evaluiert. Die geladenen ASDF-Systeme und Bibliotheken
wurden regulär in diesem eigenen Prozess geladen.

Rohbelege: `final-result.log` (finaler Lauf), `result.log` (erster Lauf mit
Kompilierung), `exit-code.txt`, `before-*.html`, `after-*.html`.
