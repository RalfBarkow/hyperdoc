# PR #33 – begrenzte Korrekturen nach Claude-Review

Ausgangsstand: `33487ff7e58eb74562ca751cd6873723874d7c10`.
HEAD und sauberer Arbeitsbaum wurden vor Änderungen geprüft; der lokale Branch
wurde vom Vorgänger ausschließlich per Fast-forward auf diesen Review-Commit gebracht.
Der vollständige [Claude-Review](../review/README.md) und alle sechs ausführbaren
Probe-/Harness-Dateien wurden gelesen. Dessen Artefakte bleiben unverändert.
Die folgenden Ergebnisse sind eigene Testläufe, keine Critic-Engine-Ergebnisse.

## Quelländerungen

- K1/C1: `already-modeled` und der simulierte Zweig von `target-ready` verlangen
  zusätzlich `modeled-fork` für dieselbe Site und denselben Slug. Dadurch genügt
  unpaarige Präsenz weder im HTN noch für primitive Vorbereitung. Die Remote- und
  Snapshot-Koordinaten des Forks sind hier existenziell. Das Paar bedeutet interne
  Konsistenz, nicht bewiesene Herkunft aus einem ausgeführten Plan.
- K2: Der neue zielgebundene Konfliktzweig `incomplete-simulation` erkennt einen
  `modeled-fork` ohne zugehörige `modeled-local-page`. Die bestehenden HTN- und
  Fork-Operator-Konfliktwächter weisen diesen Zustand ab. Ein zweiter Fork repariert
  den Zustand nicht stillschweigend. Ein solcher Konflikt an einem anderen Ziel
  blockiert die untersuchte Vorbereitung nicht.
- K3/C2: `!prepare-paragraph-rendering` verlangt neben dem Zielmarker auch
  `target-ready`. Ein manuell mitgelieferter Marker genügt nicht.
- K4/T1/T2: X1.1–X1.3, F2.7, F3.5b, direkte Forks unter widersprüchlicher Erlaubnis,
  unpaarige/mismatched modellierte Fakten, positive primitive Kontrollen und die
  Fortsetzung aus B sind Regressionstests. Primitive Top-Level-Aufgaben laufen mit
  `:plan-tree nil`; reguläre HTN-Aufgaben behalten native Bäume und Endzustände.
  Auch `primitive-repeat` wurde umgestellt. Der Wiederholungstest liest einen
  Endzustand nur, wenn einer vorhanden ist; ein Mutant ohne Lösung scheitert nun
  zuerst an der Assertion über die Plananzahl statt an einem Zugriff auf NIL.
- K6/C3: Im Zweig `remote-conflict` heißt die existenzielle Variable jetzt
  `?_snapshot`. Die Semantik ist unverändert; die Singleton-Warnung entfällt.

## Ausgeführte Gegenproben

Die historischen Skripte wurden **vor** der Korrektur unverändert ausgeführt:
[Suite](before-own-suite.log), [Counter-Probes](before-counter-probes.log),
[primitive Aufgaben](before-primitive-tasks.log), [Mutanten](before-mutants.log).
Ihre diagnostischen Fehlerausgaben reproduzieren den Review; ein Prozessende 0
allein bedeutet dort nicht, dass jede Probe erfolgreich geplant wurde.

Nach der Korrektur: [vollständige Regressionen](after-regressions.log).

| Probe | Ergebnis |
| --- | --- |
| X1.1–X1.3 im regulären HTN | Je kein Plan |
| Dieselben Zustände, direkte Link-/Paragraph-Vorbereitung | Je kein Plan, ohne Baumextraktion |
| Modellierte Präsenz und Fork für andere Site/anderen Slug | Kein Plan |
| F2.7, regulär und direkter Fork | Kein Plan; kein zweiter Fork |
| F2.7, direkte Link-/Paragraph-Vorbereitung | Kein Plan |
| Unvollständige Simulation eines anderen Ziels | Untersuchte Vorbereitung gelingt |
| F3.5b, Marker plus lokale Abwesenheit | Kein primitiver Paragraph-Plan |
| Direkter Fork bei gleichzeitig permitted/forbidden | Kein Plan; konsistente Kontrolle liefert einen Plan |
| Fortsetzung aus vollständigem Endzustand B | Ein HTN-Plan mit Baum/Endzustand, kein neuer Fork; direkte Vorbereitungen ebenfalls möglich |
| Wiederholung und zwei Snapshot-Alternativen | Höchstens ein Fork pro Plan; beide zulässigen Alternativen bleiben erhalten |

Sechs bestehende Suites bestehen erneut: Defederation, Planning, Remote-Control
Planning, Remote-Control Reading, Local-FedWiki-Page, Hyperbook/FedWiki.
Die bisherigen Tests sichern weiterhin A/B/C, F2/F3/F4, beobachtete versus modellierte
Präsenz, erhaltene Beobachtungen, Ziel-Arity, beide Quellenpolitiken und `:which :all`.
Der bekannte leere-Planbaum-Defekt wird separat vom Regressionstreiber reproduziert.

## Mutantenanalyse vor/nach

[mutants.lisp](mutants.lisp) wiederholt die Review-Mutanten und ergänzt gezielte
Rücknahmen der neuen Korrekturen. Der neue Runner akzeptiert als Erkennung nur
`SIMPLE-ERROR` mit einer fehlgeschlagenen Assertion. TYPE-ERROR und andere unerwartete
Fehler propagieren; die erwarteten Überlebens-/Erkennungsresultate werden ebenfalls
assertiert. [Vollständige Ausgabe](after-mutants.log).

| Mutant | Vorher | Nachher |
| --- | --- | --- |
| M1: nur Methodenwächter gegen wiederholte Präsenz entfernt | Überlebt | Überlebt; Operator schützt dieselben Pläne |
| M2: entsprechender Operatorwächter entfernt | SHOP3-TYPE-ERROR | Assertion weist tatsächlichen Plan mit zwei Forks ab |
| M3–M9, M11–M14 | Erkannt | Durch fachliche Assertions erkannt |
| M10: Operator-Konfliktwächter entfernt | Überlebt | Direkte widersprüchliche Fork-Probe erkennt ihn per Assertion |
| M0, M15 | Identitätskontrollen | Identitätskontrollen; M15 verändert keinen Code und prüft deshalb keine Rücknahme von C1 |
| C1–C3 | Kompatibilitätskontrollen grün | Bleiben grün |
| R1: nur Paarprüfung in already-modeled zurückgenommen | Neu | Überlebt; target-ready verhindert die vollständige Vorbereitung |
| R2: nur Paarprüfung in target-ready zurückgenommen | Neu | Primitive Regression erkennt ihn |
| R3: beide Paarprüfungen zurückgenommen | Neu | X1.1 erkennt ihn |
| R4: K2-Konfliktzweig entfernt | Neu | F2.7 erkennt ihn |
| R5: Paragraph-Bereitschaft entfernt | Neu | Primitive Paragraph-Regression erkennt ihn |

24 Läufe: 17 Assertion-Erkennungen und 7 erwartete Überlebende/Kontrollen.
Es wird keine vollständige Fehlerabdeckung behauptet; die überlappenden Wächter
von M1 und R1 sind ausdrücklich ausgewiesen.

## Reproduktion und verbleibende Grenzen

Mit registrierten Projekt-Abhängigkeiten (SBCL 2.4.10, SHOP3 `ce53f9b`), jeweils
in einem frischen Prozess aus dem Repository-Wurzelverzeichnis:

```sh
sbcl --no-sysinit --no-userinit --non-interactive \
  --load docs/defederation-consolidation/regressions.lisp
sbcl --no-sysinit --no-userinit --non-interactive \
  --load docs/defederation-consolidation/corrections/mutants.lisp
```

Cloud-Läufe verwendeten den vorhandenen Launcher
`/workspace/scratch/defederation-tools/run.py` mit
`DEFEDERATION_TEST_ROOT=/workspace/scratch/hyperdoc-defederation-consolidated`.
Logs enthalten die vollständige Ausgabe mit entfernten nachgestellten Leerzeichen.
Keine Ausführung in einem Benutzer-SLY-Image wird behauptet; dessen bestehender
Inspector-Einstieg bleibt gültig.

K5 bleibt ein separater SHOP3-Defekt, K7-Problemregistrierungen bleiben unverändert,
K8 bleibt die Grenze der nativen Baumdarstellung leerer Methodenzerlegungen.
Ein importiertes konsistentes Faktenpaar beweist weiterhin keine Herkunft.
Keine Provenienzinfrastruktur, reale Fork-Ausführung oder Änderung an Resolver,
Renderer, Catalog und PR #29–#32. Kein Merge oder Deployment; unabhängige Abnahme folgt.
