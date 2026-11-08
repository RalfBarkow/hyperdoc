# Der echte Riesbeck/Beane Lisp Critic über den Lisp-Code von PR #32

Stand 8. November 2026. **Engine-Ergebnisse** (ausgeführte Regeln) und **Judgements** (Claudes Bewertungen) sind getrennt:
die Engine-Ergebnisse stehen in [`pr-32-critique.json`](pr-32-critique.json), die Judgements in
[`judgements.json`](judgements.json). Kein Code wurde aufgrund der Befunde geändert.

## Herkunft

| Was | Wert |
|---|---|
| Riesbeck/Beane-Implementierung | Seiten-Assets des page-attached ASDF-Systems `a-critic-for-lisp`, kopiert aus `RalfBarkow/assets@856cf07:pages/a-critic-for-lisp/`; alle sieben Engine-Digests stimmen mit beiden gespeicherten Evaluationen überein ([../../lisp-critic-page-assets/README.md](../../lisp-critic-page-assets/README.md), Abschnitt 7) |
| Vorab | `dreyeck/lisp-critic/engine-integration/tests`: `run-tests` und `run-page-station-layout-tests` bestanden ([Log](../../lisp-critic-page-assets/evidence/engine-run-2026-11-08.log)) |
| Laufzeit | autorisiert, isoliert: eigener SBCL-2.4.10-Prozess, eigener Netzwerk-Namespace ohne Netz, leeres HOME, eigener FASL-Cache; nicht auf dem Mac des Nutzers, nicht auf `dreyeck.ch` |
| Beurteilter Stand | Commit `5d24d853b7cab38d7d741ecb75a7c7bfc88bd837` (der Recorder verweigert ungespeicherte Änderungen der Zieldateien) |
| Ziele | `dreyeck/work/fedwiki-link-resolution.lisp`, `dreyeck/tests/fedwiki-link-resolution.lisp`, `scripts/test-fedwiki-link-resolution.lisp` (je alle Formen), in `dreyeck.asd` die zwei von PR #32 hinzugefügten Systeme. Nicht beurteilt (mit Grund in der JSON-Datei): die zwei Evidenz-Proben und der Recorder selbst |
| Verfahren | Jede Top-Level-Form als Daten gelesen (`*read-eval* nil`), nie ausgewertet; **jede** der 78 Regeln der Engine einzeln mit `run-critic-rule` angewandt, je eine eigene Evaluation |

## Ergebnis

70 Formen × 78 Regeln = 5460 Evaluationen, **0 fehlgeschlagen**. 40 Formen ohne jeden Befund; 47 Evaluationen mit je einem
Befund in 30 Formen. Eine Evaluation ohne Befund ist ein Ergebnis und wird je Form gezählt. Kein Befund liegt in gequoteten
Daten oder in der SHOP3-Domänennotation (die `defdomain`-Form hat keinen Befund): Die Riesbeck/Beane-Implementierung hat
keine Regeln für SHOP3.

| Regel (Engine) | Befunde | Judgement (Claude) |
|---|---|---|
| `USE-EQL` | 21 | bestritten: `EQUAL` vergleicht Zeichenketten/Listen, `EQ` Symbole/Objekte |
| `FUNCTION-TOO-LONG` | 14 | teilweise anerkannt (`plan-outcomes`, `check-java-agreement`, `check-distinctions`) |
| `QNIL` | 3 | beabsichtigt (`'()`-Initialisierungen; laut Engine-Text in Ordnung) |
| `OPTIONALS` | 2 | anerkannt (`link-resolution-experiment` besser mit `&key`) |
| `LENGTH=NUM` | 2 | anerkannt, gering |
| `USES-OPEN` | 1 | Fehlalarm: `open` ist eine `LET*`-Variable, `cl:open` wird nicht aufgerufen |
| `DOLIST-SETF` | 1 | anerkannt, gering |
| `APPEND-LIST2-LIST` | 1 | beabsichtigt |
| `CONSTANT-BAD-EOF` | 1 | anerkannt: `:eof` als Endmarke in `domain-items`; frische Marke empfohlen |
| `EVIL-EVAL` | 1 | beabsichtigt: definiert die Wegwerf-Mutanten-Domäne der Tests |

Je Befund enthält die Aufzeichnung: Datei, Commit, Formschlüssel, Zeichen- und Zeilenbereich, einen commit-fixierten Link,
den SHA-256 des Formtexts, den vollständigen Evaluation Record (das bestehende Snapshot-Format), die getroffene Teilform mit
Pfad, ob sie gequotet ist, und den Empfehlungstext der Engine.

## Lesen im Inspector (ohne Engine)

```lisp
(asdf:load-system "dreyeck/work/fedwiki-link-resolution/critic")
(defparameter *pr-critique* (dreyeck/work/fedwiki-link-resolution/critic:read-pr-critique-review))
(clog-moldable-inspector:clog-inspect :object *pr-critique*)
```

Navigation: Review („PR critique“: Form, Regel, Empfehlung; darunter die Judgements) → Judgement (View „Judgement“: ID, Autor,
Regel, Verdict, Statement, Evidence und alle zugehörigen Befunde als Objektreferenzen) oder direkt → Befund (Link auf die Zeilen im Commit,
getroffene Teilform, Pfad, Empfehlung) → rekonstituierter Lauf (Evaluation Record, mit den bestehenden Views von
`dreyeck/inspector/lisp-critic`) → Critique. Beim Lesen wird jede Form erneut in diesem Checkout beobachtet: Weicht der Text
am aufgezeichneten Ort ab, zeigt der Befund „changed since recorded“ (Negativkontrolle mit einem manipulierten Digest
ausgeführt). Lesen lädt weder die Engine noch Code der Seite.

Die Brücke zu den PR-Review-Objekten aus PR #8 ist nicht gebaut: PR #8 ist nicht in `dreyeck.ch`. Die Aufzeichnung verankert
jeden Befund wie dort über Commit und Digest, damit eine spätere PR-Review-Lektüre sie übernehmen kann.

## Reproduktion

```sh
# Nur in einer autorisierten, isolierten Runtime mit den vollständigen Seiten-Assets:
DREYECK_LISP_CRITIC_ROOT=/pfad/zu/den/seiten-assets/a-critic-for-lisp/ \
  sbcl --noinform --no-sysinit --no-userinit --non-interactive --load scripts/record-fedwiki-link-resolution-critiques.lisp
# Überall, ohne Engine:
sbcl --noinform --no-sysinit --no-userinit --non-interactive --eval '(require :asdf)' \
  --eval '(asdf:test-system "dreyeck/work/fedwiki-link-resolution/critic")'
```

Ausgaben dieses Laufs: [record-and-read.log](record-and-read.log).
