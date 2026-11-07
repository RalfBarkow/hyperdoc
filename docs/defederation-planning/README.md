# Planning Defederation with SHOP3 — Slice 1

Zettel 11560, aufbauend auf 11483. Die Referenzen und Wards Vorschlag stammen
aus dem Auftrag; die Zettel selbst wurden nicht als zusätzliche Quelle gelesen.

## Basis und vorhandene Routinen

Vor Arbeitsbeginn am 7. November 2026 mit `git fetch origin dreyeck.ch` und
`git ls-remote origin refs/heads/dreyeck.ch` verifiziert:
`00d2a18bbc9cbd2045454ce8f9c4af8d8b58e60a`. Feature-Branch:
`codex/planning-defederation-slice-1`. Derselbe Remote-Stand wurde nach der
Implementierung erneut geprüft.

Aufgabenort ist die Vorbereitung einer Wiki-Site mit einem erforderlichen
Linkziel. Der Prüfort ist ein isolierter Lisp-Testprozess. Für den Auftraggeber
gilt die Planung als vollständig, wenn das Ziel im simulierten Endzustand lokal
vorliegt und lokale Linkauflösung sowie Paragraph-only-Rendering vorbereitet
sind. Nach Definition 48.2 wird diese Aufgabe hier nicht als neues Problem
bestimmt: Die aufgefundenen SHOP3-Routinen lösen die Planungsaufgabe nach
Ergänzung des kleinen Domänenvokabulars; es fehlt keine zweite Planungsmaschine.

Untersucht und wiederverwendet:

- `dreyeck/work/planning.lisp` und `dreyeck/tests/work-planning.lisp`:
  rein simulierte Übergänge und Rückgabe des bestehenden Ergebnisobjekts.
  Die dortige feste Dokumentationsfolge allein erfüllt diesen Auftrag nicht.
- `dreyeck/work/remote-control-planning.lisp` und dessen Tests:
  getrennte Methodendefinitionen, `:which :all`, vier SHOP3-Rückgabewerte.
- `dreyeck/shop3/{package,plan-objects,views}.lisp` und vorhandene
  Remote-Control-Reading-Tests: `hyperdoc-htn-plan-result`, native Planbäume,
  bestehende Objektansichten und Verweise auf dieselben Ergebnisse.
- `hyperbook-fedwiki/wiki-links.lisp`: `lookup-slug-in-page-context` versucht
  lokale Seiten, Plugin-Seiten und anschließend entfernte Seiten im Kontext.
  Eine lokale Seitenquelle allein beschränkt diesen gesamten Resolver noch
  nicht auf lokale Seiten.
- `dreyeck/src/local-fedwiki-page.lisp`: `hyperbook:find-page` für `local-fedwiki`
  löst ausschließlich im lokalen Cache beziehungsweise Seitenverzeichnis auf.
  Diese vorhandene Abstraktion bezeichnet die spätere Ausführungsgrenze.

Die kleine neue Domäne verwendet SHOP3 unmittelbar. Ein Executor, eine
Catalog-Oberfläche und eine Registrierung im Catalog gehören nicht zum Slice.

## Domäne und Wissensgrenzen

Opt-in-System: `dreyeck/work/defederation-planning`, Tests unter `/tests`.
Quellen: [Domäne](../../dreyeck/work/defederation-planning.lisp),
[Tests](../../dreyeck/tests/defederation-planning.lisp).
Ein einzelnes symbolisches Site-/Remote-/Slug-Koordinat dient als Fixture;
es wird weder ein Seitentitel umgewandelt noch eine echte Seite gelesen.

| Nachweis | Expliziter Gegenbefund | Unbekannt |
| --- | --- | --- |
| `local-page` | `local-page-absent` | beide fehlen |
| `remote-page` | `remote-page-absent` | beide fehlen |
| `snapshot-available` | `snapshot-unavailable` | beide fehlen |
| `fork-permitted` | `fork-forbidden` | beide fehlen |

Alle Eingaben sind hypothetische Befunde. Keine fehlende Aussage wird in einen
negativen Befund umgewandelt. `input-conflict` erkennt jedes zugleich vorhandene
Faktenpaar für dieselben Koordinaten. Die Wurzelmethode verlangt
`(not (input-conflict))`: Das prüft die Konsistenz der gelieferten Befunde,
behauptet aber keine Vollständigkeit der Beobachtung. Ein Widerspruch irgendwo
im gelieferten Eingangszustand sperrt die vollständige Vorbereitung.

`prepare-defederation` zerlegt sich in Zielbereitstellung, Vorbereitung lokaler
Linkauflösung und Vorbereitung des Paragraph-only-Renderings. Für
`ensure-local-target` existieren genau zwei getrennte Methoden:

- `already-local` verlangt `local-page` und hat keine primitiven Schritte.
  Remote-Snapshot und Fork-Erlaubnis werden für eine lokale Seite nicht benötigt.
- `fork-supported` verlangt ausdrücklich lokale Abwesenheit, Remote-Vorkommen,
  verfügbaren Snapshot und Fork-Erlaubnis. Nur dann plant SHOP3 `!simulate-fork`.

`!simulate-fork` prüft dieselben vier Voraussetzungen, entfernt im simulierten
Zustand lokale Abwesenheit und fügt lokale Präsenz plus `fork-prepared` hinzu.
`!prepare-local-resolution` setzt lokale Präsenz voraus und erzeugt
`resolution-prepared … local-only`. `!prepare-paragraph-rendering` setzt diese
Vorbereitung voraus und erzeugt `rendering-prepared … paragraph-only`.
Die Effekte bestehen ausschließlich aus SHOP3-Lösch- und Hinzufügelisten.
Die Zustandsfolge beschreibt angenommene zukünftige Zustände, keine neu
gemessenen Beobachtungen einer realen Site.

Die behauptete Leistung ist begrenzt: zustandsabhängige Auswahl vorhandener
HTN-Methoden und Verweigerung bei fehlenden Voraussetzungen. Sie belegt keine
Methodenerfindung, Refederation oder Überlegenheit gegenüber einem konditionalen
Programm. Reale Forks und Änderungen von Resolver oder Renderer stehen aus.

## Drei reproduzierbare Szenarien

| Szenario / SHOP3-Problem | Eingabe | Ergebnis | Primitive Schritte |
| --- | --- | --- | --- |
| A / `defederation-a` | Ziel lokal | `:planned`, 1 Plan | lokale Auflösung, Paragraph-Rendering |
| B / `defederation-b` | Ziel nachweislich abwesend; remote, Snapshot und Fork-Erlaubnis nachgewiesen | `:planned`, 1 Plan | Fork, lokale Auflösung, Paragraph-Rendering |
| C / `defederation-c` | wie B, aber Fork-Erlaubnis unbekannt | `:no-plan`, 0 Pläne | keine vollständige Lösung |

In allen Fällen gilt separat `:execution-status :not-executed`.
Die vorbereiteten realen Handlungen wurden nicht ausgeführt. Ein fehlender
vollständiger Plan ist kein teilweise ausgeführter Plan.

`defederation-plan` gibt direkt `hyperdoc-htn-plan-result` mit `:plan-only`
zurück. Es bewahrt Rohpläne, verkürzte Pläne, native Planbäume, Endzustände und
CPU-Zeit. `raw-plans = NIL` bedeutet keine Lösung; `(NIL)` bezeichnet einen
erfolgreichen leeren Plan. Die vollständige Vorbereitung hat mindestens zwei
Schritte. `defederation-experiment` liefert zusätzlich das echte SHOP3-Problem,
Anfangsfakten, Aufgaben, Domäne und Methoden, ausgewählten Plan und beide Status.
`scenario-state` liest die Fakten aus dem tatsächlichen SHOP3-Problem.

Die rekursive `find-plans`-API liefert S-Expressions als Planbäume. Diese werden
unverändert inspiziert; `plan-tree->safe-sexp` ist für diese Darstellung nicht
der passende Konverter. SHOP3 lässt beim leeren `already-local`-Teilbaum dessen
Methodenlabel weg. Der Test prüft deshalb den tatsächlichen leeren Aufgabenknoten,
die fehlende Fork-Alternative, die Operatorfolge und den Endzustand gemeinsam.

## Beobachtete Abnahme und Gegenproben

Ausgeführt am 7. November 2026 mit SBCL 2.4.10 und echtem SHOP3 4.3.1,
Commit `ce53f9b651acde8c44dc21eddb1a1c5b97f10536` aus `flake.lock`.
Auch die ergänzten SHOP3-Abhängigkeiten wurden auf die Lockfile-Commits gesetzt.
Die übrige Closure stammt aus den bereits vorhandenen lokalen Nix-Quellen.
Das ist ein isolierter Cloud-Testlauf, kein Nachweis für das bestehende SLY-Image.

Alle 23 Planungsabfragen der neuen Suite bestanden:

- A/B/C: 1/1/0 Pläne; Pläne, Bäume und Endzustände stimmen in ihrer Anzahl überein.
- Jeden der vier Fork-Nachweise einzeln entfernen: jeweils 0 Pläne.
  Ein vollständig unbekannter Eingangszustand liefert ebenfalls 0 Pläne.
- B durch lokale Präsenz ersetzen: 1 Plan ohne Fork. Auch explizites Fork-Verbot
  verhindert die Vorbereitung einer bereits lokalen Seite nicht.
- Explizite Remote-Abwesenheit, fehlender Snapshot oder Fork-Verbot:
  jeweils 0 Pläne. Alle vier Widerspruchspaare werden einzeln zurückgewiesen.
- Nur die Fork-Methodenpräbedingung um `review-confirmed` ergänzen:
  B liefert 0 Pläne; A weiterhin 1. Den zusätzlichen Fakt liefern: B wieder 1.
  Die produktive Domäne wird dabei nicht verändert; die Tests verwenden Kopien
  der echten Domänendefinition unter vorübergehenden SHOP3-Domänennamen.
- Nur den Erlaubnisnachweis aus der Methode entfernen: C liefert weiterhin
  0 Pläne, weil der primitive Operator seine Voraussetzung beibehält.
- Bereits lokales Ziel als einzelne Teilaufgabe: erfolgreicher leerer Plan.
- Nach den Mutationen liefert die ursprüngliche Domäne für B weiterhin 1 Plan.

Alle Abfragen verwenden `:which :all`. Insbesondere bei der verschärften Methode
wird der `already-local`-Zweig mitgeprüft und kann B nicht lösen. Die Tests
prüfen genau zwei registrierte Zielbereitstellungsmethoden. Damit belegt die
Evidenz eine Zustandswahl, die durch gezielte Änderungen widerlegbar ist.

Der [Batch-Einstieg](../../scripts/test-defederation-planning.lisp) führt
die neue Suite sowie diese fünf vorhandenen ASDF-Tests aus:

```lisp
"dreyeck/work/planning/tests"
"dreyeck/work/remote-control-planning/tests"
"dreyeck/work/remote-control-planning/reading/tests"
"dreyeck/local-fedwiki-page/tests"
"hyperbook/fedwiki/tests"
```

Alle fünf bestehen sowohl auf dem unveränderten Basischeckout als auch auf dem
Feature-Branch; kein Test wurde übersprungen. Die bestehende Slots-Ansicht wurde
für A/B/C als HTML erzeugt: alle sieben Ergebnis-Slots sind sichtbar, und die
Objektverweise zeigen auf dieselben Plan-, Baum- und Zustandsobjekte. Ein Browser
oder Inspector-Server wurde dafür nicht gestartet. Interaktive SLY-Navigation
bleibt Bestandteil des anschließenden unabhängigen Reviews.

Ausgaben: [Feature-Lauf](evidence/slice-1-tests.log),
[Basislauf](evidence/baseline-tests.log). Das sind vollständige Prozessausgaben
mit entfernten Leerzeichen am Zeilenende;
CLOG-Redefinitionswarnungen und der SHOP3-Singletonhinweis für die im lokalen
Zweig unbenutzte Remote-Variable sind darin sichtbar.

### Separat reproduzierter SHOP3-Basisfehler

Eine zusätzliche Gegenprobe mit einem erfolgreichen leeren Plan und
`:plan-tree t` scheitert im gepinnten rekursiven SHOP3 bei `extract-trees` /
`strip-tree-tags`: `NIL is not of type CONS`. Derselbe Fall liefert ohne
Baumextraktion korrekt `(NIL)`. Das ist durch eine eigenständige Mini-Domäne
auf dem unveränderten Basischeckout reproduziert; keine neue Defederationsdatei
wird dort geladen. Der [Basis-Probe-Code](evidence/baseline-probe.lisp) und
der Basislauf enthalten den Nachweis. Die neue Suite prüft die leere Teilaufgabe
deshalb mit `:plan-tree nil`. A/B samt Bäumen und Endzuständen sowie C sind
unverändert vollständig getestet. SHOP3 selbst wurde nicht geändert.

Der erste Basislauf zeigte außerdem einen Fehler des Cloud-Launchers:
Der dynamische Nix-Lader wurde vom bestehenden Fresh-Process-Test als Lisp-Binary
verwendet und wies `--noinform` zurück. Im externen Testharness wurde
`sb-ext:*runtime-pathname*` auf den vorhandenen SBCL-Wrapper gesetzt. Danach
bestanden die unveränderten Fresh-Process-Tests. Das war kein Repositoryfehler.

## Wiederholung und Inspector-Handoff

Mit der registrierten Projekt-Closure, beispielsweise in `nix develop`:

```sh
sbcl --no-sysinit --no-userinit --non-interactive \
  --load scripts/test-defederation-planning.lisp
```

Tatsächliche Cloud-Befehle, jeweils Exit 0:

```sh
python3 /workspace/scratch/defederation-tools/run.py \
  --load scripts/test-defederation-planning.lisp
DEFEDERATION_TEST_ROOT=/workspace/scratch/defederation-base \
  python3 /workspace/scratch/defederation-tools/run.py \
  --load /workspace/hyperdoc/docs/defederation-planning/evidence/baseline-probe.lisp
```

Das externe Harness verwendet die vorhandene relocatierte Nix-SBCL-Installation,
registriert die vorhandenen Dependency-Quellen plus die gepinnten SHOP3-Quellen,
setzt einen separaten FASL-Cache und den beschriebenen Fresh-Process-Wrapper.
Für eine Basiswiederholung muss das unveränderte Basischeckout vor dem
Feature-Checkout in der ASDF-Source-Registry stehen.

In der eigenen SLY-mREPL getrennt evaluieren:

```lisp
(asdf:load-system "dreyeck/work/defederation-planning")
(asdf:test-system "dreyeck/work/defederation-planning/tests")
```

Nur wenn der Inspector im Image noch fehlt:

```lisp
(unless (find-package "CLOG-MOLDABLE-INSPECTOR")
  (asdf:load-system "clog-moldable-inspector"))
```

Dann pro Szenario, zunächst B:

```lisp
(defparameter *defederation-experiment*
  (dreyeck/work/defederation-planning:defederation-experiment :b))
(defparameter *defederation-result*
  (getf *defederation-experiment* :result))
(list (getf *defederation-experiment* :outcome)
      (getf *defederation-experiment* :execution-status)
      (dreyeck/shop3:plans-of *defederation-result*))
(clog-moldable-inspector:clog-inspect :object *defederation-experiment*)
```

Erwartet: `(:planned :not-executed …)`, für B drei Schritte, für A zwei und
für C `:no-plan` mit leerer Planliste. Im Kontext über `:result` die vorhandenen
Slots und von dort Planbaum und simulierten Endzustand öffnen. Für den Review
Testmarker, etwaige Conditions und beobachtete Objektverweise zurückgeben.

Prozess: Aufgabenortung → Routinenwiederverwendung → Domäne → echte SHOP3-Läufe
und Falsifikationsproben → Basisvergleich → Inspector-Ansichten → lokaler Commit
und Draft-PR. HyperDoc-Delta: diese Quelldokumentation und inspizierbare
Ergebnisse. Lisp-Delta: opt-in-Domäne, Szenarien und Tests. FedWiki-Delta: keines.
Disk/Reload-Nachweis: frischer ASDF-Lauf erfolgreich. Keine Ausführung der
geplanten Wiki-Handlungen. Danach Halt für den unabhängigen Claude-Code-Review.
