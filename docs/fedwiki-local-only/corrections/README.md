# PR #35 – Korrekturen F1–F3

Ausgangsstand: `49ef9afd52539234290e38064847d4589a3be412`, Branch
`codex/fedwiki-local-only-integration`. Der Arbeitsbaum war vor den Änderungen sauber.
PR #35 bleibt ein Draft auf PR #34 (`4e76e9aff910e9da45c1fe9252e528669c2683fb`).
Die Befunde und Gegenproben in [../review/](../review/README.md) wurden gelesen und
bleiben bytegleich erhalten. Ihre Erwartungen beschreiben weiterhin den alten
Implementierungsstand `68ca0c5`; sie werden nicht als Erwartungen an die Korrektur umgedeutet.

## Quelländerungen

**F1 – lokale Verfügbarkeit.** `observe-link` weist externe `page-available`,
`page-unavailable` und `request-error` für die ausdrücklich gewählte eigene Site mit
`invalid-observation` zurück. Das gilt für die gemeinsame Beobachtungsgrenze beider
Planungsmodi. Es wird kein Fakt stillschweigend entfernt. Vorhandene lokale Seiten,
bestätigte Abwesenheit und Lesefehler bleiben getrennte Befunde. Die HTTP-500-,
302- und Transport-Fixtures benennen jetzt `remote-item`; kollaborative Auflösung
kann diese Remote-Evidenz weiterhin nutzen. Hypothetische Präsenz entsteht weiterhin
nur aus einem zur Beobachtung registrierten und geprüften PR-33-Planungsergebnis.

**F2 – gespeicherte Kopien.** Jede deklarierte Kopie wird geprüft, auch wenn kein
Snapshot-Fakt sie verwendet. Der Evidenzbereich ist `snapshots/` direkt neben der
kanonischen Evidenzdatei. Zulässig sind ausschließlich direkte Dateien der Form
`snapshots/[A-Za-z0-9_-]+.json`. Absolute Pfade, Verzeichniswechsel, fehlende Dateien
und symbolische Links auf Datei- oder Verzeichnisebene werden zurückgewiesen.
Anschließend müssen SHA-256 und JSON-Struktur stimmen: Seitenobjekt mit nichtleerem
Titel, Story-/Journal-Arrays, Objekten als Einträgen, Story-Typ und passenden Typen
für vorhandene String-Felder. Jeder `remote-snapshot` muss über Site, Slug und Digest
zu einer geprüften Kopie passen. Die vorhandene Evidenz trägt diese Zuordnung.

**Struktur, Dateipfad und Digest beweisen keine historische Echtheit einer
Remote-Herkunft.** Es findet weder eine Remote-Abfrage noch eine Authentifizierung
der Herkunft statt. Die Prüfung setzt einen während des Lesens stabilen lokalen
Evidenzbereich voraus; sie ist keine atomare Abwehr gegen gleichzeitigen Austausch
von Dateien/Verzeichnissen durch einen anderen Prozess.

**F3 – diagnostizierbare Eingaben.** Evidenzobjekt, `facts`-Array, Zeilen, Arity,
Argumenttypen und vollständige Quellenpolitik werden vor Feldverwendung geprüft.
JSON-`null`, falsche Status-/Namens-Typen, ungültiges JSON einschließlich angehängter
Zeichen, fehlende Story, ungültiger Item-Index und fehlender/ungültiger Wiki-Link
werden mit einem Detail als `invalid-observation` gemeldet. Die JSON-Prüfung läuft
auch für Snapshot-Inhalte. Bekannte Datei-, Stream-, JSON-/UTF-8- und
Seiten-Lookup-Fehler werden an ihren jeweiligen Eingangsgrenzen behandelt;
unerwartete Programmierfehler werden nicht pauschal gefangen. Beim tatsächlichen
lokalen **Ziel** bleibt ein Lesefehler `:unknown`, ohne Treffer-/Abwesenheitsfakt.

Die Änderung liegt in `dreyeck/work/fedwiki-local-only.lisp`. Die vorhandene
ASDF-Testsuite lädt zusätzlich `dreyeck/tests/fedwiki-local-only-inputs.lisp`.
PR-33-Domäne, Resolver-Domäne, gemeinsame FedWiki-Linkfunktionen und
Inspector-Implementierung bleiben gegenüber dem Ausgangsstand unverändert.

## Ausgeführte Gegenproben

Vollständige Ausgabe: [integration.log](integration.log), [probes.log](probes.log).
Automatische Auswertung: [checks.log](checks.log).

| Gegenprobe | Korrigiertes Ergebnis |
| --- | --- |
| P1a–P1d | `invalid-observation`, eigene Verfügbarkeit muss aus dem Speicher kommen |
| P1e, ursprünglicher eigener HTTP 500 | Als eigenständige Lisp-Regression ebenfalls `invalid-observation` |
| P1e im unveränderten Review-Skript | Liest die absichtlich korrigierte **Remote**-Fixture: lokaler Befund unbekannt, kein Auflösungsplan, kein Fork |
| P2a–P2c | Lokale Seitendatei, Datei außerhalb `snapshots/` und absoluter Pfad zurückgewiesen |
| P2d–P2e | Abweichender Slug bzw. Remote-Site zurückgewiesen |
| Zusätzliche Snapshot-Proben | `..`, fehlende Datei, falscher Digest, ungültiges JSON, Nicht-Seiten-JSON sowie Datei-/Verzeichnis-Symlinks zurückgewiesen |
| Positive Snapshot-Kontrolle | Echter SHOP3-Plan mit einem simulierten Fork, native Planbäume und Endzustände; Wiederholung/Fortsetzung ohne zweiten Fork |
| P3a–P3m, zusätzlich P3n–P3o | Alle `invalid-observation` mit Detail; kein roher Type-/Index-/JSON-Parserfehler |
| P4a–P4b, weitere Index-/Link-/Quellseiten-Proben | `invalid-observation` mit Detail |
| Echter Lesefehler / injizierter Programmierfehler | `:unknown` / unerwartete Condition propagiert |
| Remote 500 / 302 / Transportfehler | Kollaborativ nächster Kandidat / nächster Kandidat / Abbruch; Local-only bleibt ohne Remote-Fallback |

**48 negative Eingabe-Regressionen** bestehen, dazu die positiven und
Erhaltungsassertionen. Das unveränderte `probes35.lisp` erreicht `PROBES35-DONE`.
Die Überschrift der historischen P1e-Probe nennt weiterhin „own site HTTP 500“;
das ist nach der geforderten Fixture-Korrektur nicht mehr ihr Inhalt. Die neue
P1e-Regression konstruiert deshalb ausdrücklich die ursprüngliche eigene 500-Evidenz.
Die alten `expectations.py`-Erwartungen werden nicht geändert oder als neue
Pass-Kriterien verwendet; [check.py](check.py) prüft die korrigierten Ergebnisse.

## Erhaltung und Netzwerk

- Reale lokale Treffer, bestätigte Abwesenheit und unbekannte Verfügbarkeit bleiben
  getrennt; Remote-Kontexte und Plugins werden beim lokalen Laden nicht aufgerufen.
- Kollaborative Reihenfolge bleibt Own-Site → Item-Site → neuester → älterer
  Journal-Kandidat. Local-only fällt nicht auf diese Remote-Kandidaten zurück.
- C0–C9 bestätigen: PR #33 als einzige Fork-Autorität, fremde/geänderte Ergebnisse
  abgewiesen, Wiederholung mit einem Fork, Fortsetzung mit keinem weiteren Fork,
  beide zulässigen Snapshot-Alternativen mit `:which :all` und getrennten Endzuständen.
  Nach hypothetischer Auflösung bleiben Beobachtung und lokaler Speicher abwesend.
- Die vorhandenen Integrationstests prüfen native Planbäume und simulierte
  Endzustände. I2 erreicht dieselben neun Objekte (`EQ`, neunmal `T`), einschließlich
  Seite, Item, Link, Evidenz, Problem, Planergebnissen und Zustands-/Planlisten.
  Das belegt keine durchgeklickte CLOG-Navigation.
- [integration.strace](integration.strace): **0 Netzwerk-Systemaufrufe** im gesamten
  Prozesslauf einschließlich der neuen Regressionen. [probes.strace](probes.strace):
  **0** vor dem Kontrollmarker, **11** danach beim expliziten Versuch zu
  `127.0.0.1:9` (Connection refused). Der Kontrollversuch gehört nicht zum
  Local-only-Pfad. Die breiteren Review-Guards zählen nur 16 lokale `load-page`-
  Aufrufe, keine Socket-, DNS-, HTTP-, Plugin-, Kontext- oder Prozess-Aufrufe.
- Netzwerk-Namespaces waren hier nicht erlaubt (`unshare --net`: Operation not
  permitted; `unshare -rn`: uid_map read-only). Der Nachweis beruht auf tatsächlichen
  Systemaufruf-Traces und Guards, nicht auf behaupteter Namespace-Isolation.
- [regressions.log](regressions.log): sechs bestehende Suites bestanden
  (Defederation, Planning, Remote-Control Planning und Reading, lokale Seiten,
  HyperBook/FedWiki). Der bekannte SHOP3-Fehler bei leeren Planbäumen wurde separat
  reproduziert. [wiki-link.log](wiki-link.log): Wiki-Link-Suite bestanden.
- [reading.log](reading.log): **nicht bestanden**. Externes D2/TALA fehlt;
  `authored-d2` erhält `:STATUS :UNAVAILABLE`. Derselbe Befund ist im unveränderten
  Review bereits auf PR #34 und #35 belegt. Das wird nicht als neuer Testpass gezählt.

## Reproduktion und geprüfte Revision

Mit SBCL, der vorhandenen ASDF-Abhängigkeitsumgebung, Python 3, `ln` und `strace`,
vom Repository aus:

```sh
docs/fedwiki-local-only/corrections/run.sh /tmp/pr35-corrections
python3 docs/fedwiki-local-only/corrections/check.py results /tmp/pr35-corrections
```

`SBCL` kann einen konfigurierten Wrapper bezeichnen. Der tatsächlich verwendete
Cloud-Aufruf, Wrapper, Runtime-Versionen und Ausgabedigests stehen in
[run-record.json](run-record.json). Es wurden SBCL 2.4.10 und das unveränderte SHOP3
`ce53f9b651acde8c44dc21eddb1a1c5b97f10536` verwendet. Die beiden identischen Dateien
[source-before.json](source-before.json) und [source-after.json](source-after.json)
identifizieren die getestete Korrektur über Ausgangscommit und Quell-/Fixture-/
Probe-Digests. [run.log](run.log) protokolliert die abgeschlossenen Aufrufe.

Die abgelegten Resultate lassen sich im zugehörigen Commit erneut prüfen:

```sh
python3 docs/fedwiki-local-only/corrections/check.py results docs/fedwiki-local-only/corrections
```

Die ursprüngliche `evidence/tested-source.json` und ihr Checkskript bleiben
historische Nachweise für `68ca0c5`; sie passen absichtlich nicht zur geänderten
Implementierung. Sie werden durch diese Korrektur nicht rückwirkend überschrieben.
Für SLY bleibt der Einstieg unverändert:

```lisp
(asdf:load-system "dreyeck/work/fedwiki-local-only")
```

Danach als **separate** Eingabe, wenn das Paket geladen ist:

```lisp
(dreyeck/work/fedwiki-local-only:demo)
```

## Weiter offene Grenzen

F4–F7 bleiben dokumentiert: begrenzte alte Lisp-Transport-Hooks (hier durch erneute
Syscall-Traces ergänzt), Own-Site-Titlebar mit externem Öffnen, sternförmige
Inspector-Lektüre ohne Rückverweise und ohne interaktive Abnahme, kooperative
In-Image-Seals statt vollständiger Provenienzarchitektur sowie wachsende
SHOP3-Problemregistrierungen und Grenzen des alten Evidenz-Checkskripts.
Auch die fehlende Inspector-Darstellung leerer Methodenzerlegungen und der
SHOP3-Planbaumfehler bleiben bestehen. Kein realer Fork, keine produktiven
Wiki-Schreibvorgänge, kein Resolver-/Renderer-Rollout, keine neue Critic-Evaluation,
kein Dienststart/-neustart, kein Merge und kein Deployment.

Die Arbeit stoppt hier für die unabhängige Abnahme durch Claude Code.
