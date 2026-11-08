# PR #35 – begrenzte Korrektur R1

Ausgangscommit: `ba892c8c8f1159b0199e26a568604c49cb062466`.
Branch, lokaler HEAD und Remote-HEAD wurden vor Beginn geprüft; der Arbeitsbaum
war sauber. Die vollständige unabhängige B7/B8-Review-Datei liegt hier nicht vor.
Die Fälle wurden anhand der Auftragsbeschreibung rekonstruiert.

**Änderung:** Zehn zusätzliche Zeilen in `observe-link` weisen die eigene Site als
Quelle von `remote-page`, `remote-page-absent`, `remote-snapshot` oder einer Kopie
zurück, einschließlich unreferenzierter Kopien. Die bestehende Condition
`invalid-observation` nennt den betreffenden Fakt bzw. Kopieneintrag und das Detail
`:own-site-cannot-be-remote-source` bzw. `:own-site-cannot-be-remote-copy`.

Bei `(remote-snapshot local-site slug remote-site digest)` wird ausschließlich
`remote-site` mit der eigenen Site verglichen. Die lokale Ziel-Site, ihre
Fork-Erlaubnis/-Sperre, Quellenpolitik und beobachtete Abwesenheit bleiben zulässig.
Snapshot-Verifizierung (F2), Fehlerbehandlung (F3), beide Domänen und
Inspector-Implementierung sind unverändert.

## Gegenproben: erwartet und tatsächlich ausgeführt

Alle zehn Fälle sind Assertion-Tests in `run-r1-tests`, aufgerufen von der
bestehenden Eingangsregressionssuite. Ausgabe: [integration.log](integration.log).
Die lokale Abwesenheit von `missing` wird vor den Gegenproben tatsächlich gelesen.

| Fall | Erwartet | Tatsächlich |
| --- | --- | --- |
| B7: eigene Snapshot-Quelle mit passender eigener Kopie, Cached-Politik | `invalid-observation`, kein Fork-Plan | Erfüllt; Detail benennt `remote-snapshot` |
| B8: eigene `remote-page`-Quelle, eigene Snapshot-Quelle/Kopie, strenge Politik | `invalid-observation`, kein Fork-Plan | Erfüllt; Detail benennt `remote-page` |
| Isolierte eigene `remote-page`-Behauptung, sonst gültige fremde Snapshot-Quelle | `invalid-observation` | Erfüllt; prüft den Zweig unabhängig von B7 |
| Eigene `remote-page-absent`-Quelle | `invalid-observation` | Erfüllt |
| Eigener Kopieneintrag ohne Snapshot-Verweis | `invalid-observation` | Erfüllt; eigener Kopien-Prüfzweig |
| Fremde Quelle, `:cached-copy-sufficient` | Ein Fork trotz zweimaliger Vorbereitung, Fortsetzung ohne Fork | Erfüllt |
| Fremde Quelle mit positiver Remote-Evidenz, `:require-remote-evidence` | Ein Fork trotz zweimaliger Vorbereitung, Fortsetzung ohne Fork | Erfüllt |
| Fremde Quelle mit ausdrücklicher Remote-Abwesenheit, strenge Politik | Gültige Beobachtung, kein vollständiger Plan | Erfüllt |
| `fork-forbidden` für eigene Ziel-Site | Gültige Beobachtung, kein vollständiger Plan | Erfüllt |
| Zwei fremde Snapshot-Quellen | Zwei vollständige Alternativen, je ein Fork; beide Fortsetzungen ohne Fork | Erfüllt |

Für **jede der fünf Zurückweisungen** prüft der Test Anzahl und identische Inhalte
von `*observations*` und `*results*` sowie die unveränderte SHOP3-Problemliste.
Der Test würde nach erfolgreicher Beobachtung tatsächlich `prepare-link` aufrufen;
die Zurückweisung muss davor erfolgen. Die Positivkontrollen prüfen echte SHOP3-
Pläne, native Planbäume und simulierte Endzustände. Beobachtete Abwesenheit bleibt
erhalten, kein `local-page` wird erfunden und der lokale Speicher bleibt unverändert.

## Erhaltung und Grenzen

- Integrationssuite, alle 48 bestehenden Eingabe-Regressionen und die zehn neuen
  R1-Fälle bestanden. Kollaborative Reihenfolge, Remote-500/302/Transport-Evidenz,
  Local-only ohne Fallback, Fehlerdiagnostik und Inspector-`EQ` bleiben erhalten.
- Die unveränderten unabhängigen Gegenproben erreichen `PROBES35-DONE`;
  ihre Erhaltungsassertionen bestehen: [probes.log](probes.log), [checks.log](checks.log).
- Alle sechs bestehenden Planung-/Seiten-Suites und die Wiki-Link-Suite bestanden:
  [regressions.log](regressions.log), [wiki-link.log](wiki-link.log).
- `strace`: **0 Netzwerk-Systemaufrufe** in der gesamten Integrationssuite
  einschließlich R1; **0** in den unabhängigen Proben vor dem Kontrollmarker und
  **11** danach beim kontrollierten Verbindungsversuch zu `127.0.0.1:9`.
  Die Verbindung wurde abgewiesen, ihre Systemaufrufe sind sichtbar.
  Die breiteren Guards melden keine Netzwerk-, Plugin- oder Remote-Kontextaufrufe.
  Traces: [integration.strace](integration.strace), [probes.strace](probes.strace).
- `unshare --net` bleibt mit „Operation not permitted“ gesperrt. Es wird keine
  Namespace-Isolation behauptet.
- Die zusätzlich erneut ausgeführte allgemeine Reading-Suite scheitert weiterhin
  am fehlenden D2/TALA (`:STATUS :UNAVAILABLE`), wie zuvor dokumentiert. Kein Testpass:
  [reading.log](reading.log). Der bekannte SHOP3-Fehler bei leeren Planbäumen wurde
  separat reproduziert. F4–F7 und die interaktive Inspector-Abnahme bleiben offen.
- Keine historische Remote-Echtheit durch Pfad/Digest/Strukturprüfung bewiesen;
  weiterhin stabiler Evidenzbereich während des Lesens vorausgesetzt. Keine neue
  Provenienzarchitektur, Critic-Evaluation oder reale Fork-Ausführung.

## Reproduktion und Revision

Die vorhandene ASDF-Suite führt R1 automatisch aus:

```lisp
(asdf:test-system "dreyeck/work/fedwiki-local-only/tests")
```

Kompletter isolierter Lauf mit konfigurierter SBCL-/ASDF-Umgebung und `strace`:

```sh
docs/fedwiki-local-only/corrections/run.sh /tmp/pr35-r1-check
python3 docs/fedwiki-local-only/corrections/check.py results /tmp/pr35-r1-check
```

Der tatsächlich verwendete Wrapper/Aufruf und Ausgabedigests stehen in
[run-record.json](run-record.json), die Ergebnisse in [run.log](run.log).
[source-before.json](source-before.json) und [source-after.json](source-after.json)
sind identisch und binden den Lauf an die getesteten Quell-/Fixture-/Probe-Digests.
Der wiederverwendete Prüfer führt weiterhin `49ef9afd…` als historischen
F1–F3-Ausgangscommit; der R1-Ausgangscommit ist oben und im neuen Run-Record angegeben.

Die älteren Dateien unter `review/`, `evidence/` und direkt unter `corrections/`
bleiben unverändert. Zum Prüfen dieser neuen gespeicherten Ergebnisse im R1-Commit:

```sh
python3 docs/fedwiki-local-only/corrections/check.py results docs/fedwiki-local-only/corrections/r1
```

Die Arbeit stoppt für die unabhängige Claude-Code-Abnahme. Kein Merge, Deployment
oder Dienststart/-neustart; keine produktiven Wiki-Schreibvorgänge.
