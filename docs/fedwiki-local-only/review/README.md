# Unabhängiger Review von PR #35: Local-only-Runtime, Provenienz, SHOP3-Fortsetzung und Inspector

Zettel 11560. Stand 8. November 2026. Geprüfter Implementierungscommit: `68ca0c587e25459b59c2cc246432207f2258975c`
(Branch `codex/fedwiki-local-only-integration`). Basis: PR #34 `4e76e9aff910e9da45c1fe9252e528669c2683fb`. Dieser
Ordner enthält nur Review-Artefakte; Implementierung, Tests, Fixtures, Evidenz von PR #35 und alle Critic-Aufzeichnungen
sind unverändert. Es wurde keine Lisp-Critic-Regel ausgeführt; hier steht keine Engine Critique.

Kennzeichnung: **[obs]** in diesem Review ausgeführt und beobachtet (Log genannt) · **[abg]** aus dem Quelltext abgeleitet,
nicht ausgeführt · **Judgement** eigene Bewertung (Claude) · **[offen]** nicht geprüft oder nicht entschieden.

Quellverweise ohne Pfad meinen `dreyeck/work/fedwiki-local-only.lisp` bei `68ca0c5`, Zeile N (`:N`). Probe-IDs (P1a, C3b …)
stehen in [probes/probes35.lisp](probes/probes35.lisp), ihre Ausgaben in [logs/probes35.log](logs/probes35.log).

## Entscheidung: C (Judgement)

Eine wesentliche Provenienzinvariante ist verletzt (F1): Eine externe Evidenzdatei kann im Local-only-Modus lokale
Verfügbarkeit, lokale Abwesenheit oder einen Abruffehler der eigenen Site behaupten, und die Auflösung folgt ihr gegen den
lokalen Speicherbefund. Die Korrektur ist eng begrenzt (unten). Netzwerkfreiheit, unveränderter gemeinsamer FedWiki-Code,
Fortsetzung nur aus eigenen Ergebnissen und PR #33 als einzige Fork-Autorität halten [obs]. Die interaktive
Inspector-Abnahme in einer laufenden CLOG-Sitzung ist **offen**: Es wurde keine Kette durchgeklickt; HTML-/EQ-Prüfungen
ersetzen das nicht.

## Ausgeführte Prüfungen

Alle mit [run-review.sh](run-review.sh). Jeder Lisp-Prozess ist ein frischer SBCL 2.4.10 (HyperDoc-Abhängigkeitsclosure aus
Nix, SHOP3 `ce53f9b`) in `unshare --net`, mit leerem HOME und eigenem FASL-Cache. Die Suite von PR #35, die Gegenproben und
das erweiterte View-Image laufen zusätzlich unter `strace -f -e trace=%network,mkdir`; das beobachtet Systemaufrufe
unabhängig von jeder Lisp-Instrumentierung. Zusammenfassung des Laufs: [logs/summary.log](logs/summary.log).

### Gleiche Tests auf PR #34 und PR #35 [obs]

Verglichen werden die gefilterten Ausgaben beider Commits nach Entfernen **nur** der Zeile `BASELINE-ROOT`, die den Pfad des
extrahierten Baums nennt; die verbleibenden Unterschiede stehen in `logs/compare-*.diff` (leer = gleich).

| Test | PR #34 `4e76e9a` | PR #35 `68ca0c5` | Bewertung | Logs |
|---|---|---|---|---|
| `docs/defederation-consolidation/regressions.lisp` (sechs Suites und SHOP3-Leerbaumprobe) | bestanden | bestanden | gleich | [pr34](logs/regressions-pr34.log), [pr35](logs/regressions-pr35.log) |
| `dreyeck/wiki-link/tests` (u. a. Journal-Kontext-Debugger, Story-Item-Transfer) | bestanden | bestanden | gleich | [pr34](logs/wiki-link-tests-pr34.log), [pr35](logs/wiki-link-tests-pr35.log) |
| `dreyeck/work/reading/tests` | **scheitert**: Assertion `(typep … 'dreyeck/topicmap/tala/authored:authored-d2)` erhält `(:status :unavailable …)` mit „Couldn't execute …“ (externes D2/TALA-Programm fehlt in dieser Umgebung) | **scheitert** identisch | **vorbestehend und umgebungsabhängig, keine Regression von PR #35**; die Suite taugt hier nicht als Regressionsnachweis, weil sie vor den Tests zum föderierten Kontext abbricht | [pr34](logs/reading-tests-pr34.log), [pr35](logs/reading-tests-pr35.log) |
| Differenzprobe gemeinsamer Code ([shared-diff.lisp](probes/shared-diff.lisp)) | — | — | identisch bis auf die neue Lambda-Liste von `set-page-data` | [pr34](logs/shared-diff-pr34.log), [pr35](logs/shared-diff-pr35.log), [Diff](logs/shared-diff.diff) |

### Nur PR #35 [obs]

| Prüfung | Ergebnis | Logs |
|---|---|---|
| PR-eigene Suite `scripts/test-fedwiki-local-only.lisp` | `LOCAL-ONLY-INTEGRATION-PASS`; 0 Netzwerk-Systemaufrufe | [Marker](logs/own-suite35.log), [strace](logs/own-suite35.strace-summary.log) |
| Gegenproben [probes35.lisp](probes/probes35.lisp) | Befunde unten; 0 Netzwerk-Systemaufrufe bis zur Marke, positive Kontrolle danach sichtbar | [Ausgabe](logs/probes35.log), [strace](logs/probes35.strace-summary.log), [Netzwerkaufrufe](logs/probes35.strace-network.log) |
| Erweitertes View-Image [ext-views.lisp](probes/ext-views.lisp) (zusätzlich `dreyeck/local-fedwiki-view`, `…/activation-inspector`, `…/inspector`, `dreyeck/inspector/fedwiki-source-relations`, `dreyeck/work/reading`) | alle Views der Kettenobjekte rendern; 0 Netzwerk-Systemaufrufe zwischen den Marken | [Ausgabe](logs/ext-views35.log), [strace](logs/ext-views35.strace-summary.log) |
| Titelleiste [titlebar.lisp](probes/titlebar.lisp) | F5 | [Ausgabe](logs/titlebar35.log) |
| Manifest `tested-source.json` unabhängig nachgerechnet ([manifest-check.py](probes/manifest-check.py)) | alle 18 Quell- und 5 Log-Digests stimmen; einzige geänderte Datei außerhalb des Manifests und außerhalb `docs/` ist dessen eigenes Prüfskript | [Ausgabe](logs/manifest.log) |
| Abschlussprüfung [expectations.py](probes/expectations.py): jeder erwartete Befund F1–F7, die `strace`-Segmente, die Vergleiche PR #34/#35, der Reading-Fehlschlag als Umgebungsgrenze und das Manifest, gegen die Ausgaben genau dieses Laufs | 111 Punkte erfüllt, 0 nicht erfüllt (`EXPECTATIONS PASS`) | [Ausgabe](logs/expectations.log) |

`strace`-Nachweise dieses Laufs [obs]: PR-Suite 0 Netzwerk-Systemaufrufe; Gegenproben 0 bis zur Marke, danach 8 aus der
absichtlichen Kontrollverbindung (`socket`, `connect` zu `127.0.0.1:9` → `ENETUNREACH`); erweitertes View-Image 0 beim Laden,
0 zwischen den Marken, danach 8 aus der Kontrollverbindung. Damit ist sowohl die Abwesenheit von Netzwerkaufrufen im
Local-only-Pfad als auch die Erkennbarkeit einer tatsächlichen Verbindung belegt
([probes35.strace-network.log](logs/probes35.strace-network.log), [ext-views35.strace-network.log](logs/ext-views35.strace-network.log)).

Kompilierung: Die neuen Dateien `dreyeck/work/local-only-resolution.lisp`, `dreyeck/work/fedwiki-local-only.lisp` und
`dreyeck/tests/fedwiki-local-only.lisp` kompilieren ohne Warnung; alle Warnungen des Laufs stammen aus Abhängigkeiten
(random-state, plump-inspector-views, CLOG-Redefinitionen) [obs].

## Befunde

### F1 – Externe Evidenz bestimmt im Local-only-Modus die lokale Präsenz der eigenen Site (wesentlich)

- **Quelle:** `:142-143` weist nur `local-page`/`local-page-absent` aus der Evidenzdatei ab. `:194-195` übernimmt alle
  `page-available`, `page-unavailable` und `request-error` in den Auflösungszustand, auch wenn sie die eigene Site nennen.
  Der Docstring `:128-129` sagt: „Local presence/absence comes only from the actual local page lookup.“ Der Test
  `dreyeck/tests/fedwiki-local-only.lisp:131-138` verlangt für den Speicherbefund `:unknown` plus HTTP 500 der eigenen
  Site einen Auflösungsplan und verankert das Verhalten damit.
- **Gegenproben [obs]:**

  | Probe | Evidenzdatei behauptet | Speicherbefund | Erwartet | Tatsächlich |
  |---|---|---|---|---|
  | P1a | `page-available fedwiki:local broken` | `:unknown` (Ziel-JSON ungültig) | kein Plan | `!request` + `!open-panel`: lokal geöffnet |
  | P1b | `page-available fedwiki:local missing` | bestätigt abwesend | `:not-found` | kein Plan (Widerspruch) |
  | P1c | `page-unavailable … broken 404` | `:unknown` | kein Plan | `:not-found` |
  | P1d | `request-error fedwiki:local target` | lokal vorhanden | lokal geöffnet | kein Plan |
  | P1e | mitgelieferte `evidence-500.json` (500 der eigenen Site) | `:unknown` | kein Plan | `:not-found` |

- **Konsequenz:** Eine Datei kann einen Local-only-Treffer behaupten, den der Speicher nicht belegt, und einen vorhandenen
  lokalen Treffer verhindern. Ein HTTP-Status der eigenen Site wird in der Auflösung wie lokale Abwesenheit behandelt,
  obwohl dieser Slice nie per HTTP auf die eigene Site zugreift. Der Fork bleibt korrekt gesperrt (`:FORK 0`).
- **Korrekturgrenze:** An der Eingangsgrenze `r::`-Fakten abweisen, die die eigene Site nennen (oder sie im
  Auflösungszustand für die eigene Site verwerfen); für die eigene Site gilt in der Auflösung nur der Speicherbefund
  (`:196-198`). Die Fixtures `evidence-500/302/transport.json` und der Test `:131-138` sind entsprechend anzupassen.
  Keine Änderung an PR #33, am Resolver aus PR #32 oder am gemeinsamen FedWiki-Code nötig.

### F2 – Snapshot-Kopie nur an Bytes gebunden, Pfad nicht eingegrenzt (mittel)

- **Quelle:** `:104-118`; `merge-pathnames` in `:116-117` akzeptiert absolute Pfade und Pfade außerhalb von `snapshots/`;
  der Inhalt der Kopie wird nicht geprüft.
- **Gegenproben [obs]:** P2a: die Seitendatei `pages/source` der *eigenen* Site wird als Snapshot von `remote-item/missing`
  angenommen, ein Fork wird geplant (`:FORK 1`). P2b: Datei außerhalb von `snapshots/` angenommen. P2c: absoluter Pfad
  angenommen. P2d/P2e: Kopieneintrag mit anderem Slug bzw. anderer Remote-Site wird korrekt abgewiesen.
- **Erwartet:** Eine Kopie gilt nur als Snapshot der genannten Remote-Seite. **Tatsächlich:** Jede Datei mit passendem Digest.
- **Konsequenz:** Der Digest belegt die Bytes, nicht dass es eine Kopie dieser Remote-Seite ist.
- **Korrekturgrenze:** Kopienpfade auf das Evidenzverzeichnis (bzw. `snapshots/`) begrenzen, die Kopie als
  FedWiki-Seiten-JSON parsen; die Prüfung bleibt eine Dateiprovenienz, keine kryptographische Autorisierung.

### F3 – Fehlerhafte Eingaben ohne `invalid-observation` (niedrig)

- **Quelle:** `:89-102` (Lesen der Zeilen), `:79-85` (Typprüfung), `:135` (`elt`).
- **Gegenproben [obs]:** P3a fehlendes `facts` → `TYPE-ERROR`; P3b `facts` kein Array → `TYPE-ERROR`; P3e zu kurze
  Policy-Zeile → `BOUNDING-INDICES-BAD-ERROR`; P3m kein JSON → `SHASHT-INVALID-CHAR`; P4a Item-Index außerhalb → `INDEX-TOO-LARGE-ERROR`;
  P4b Seite ohne Story → `INDEX-TOO-LARGE-ERROR`; P3f JSON `null` wird als `:null` angenommen (`(fork-permitted :null :null)`).
  Korrekt abgewiesen: falsche Arity (P3n), Gleitkommazahl (P3h), Boolean (P3g), verschachteltes Array (P3i), unbekannte
  Policy (P3l), großgeschriebenes `LOCAL-PAGE`/`MODELED-FORK` (P3j, P3k).
- **Konsequenz:** Die Importabwehr ist nicht durchgängig diagnostizierbar. **Korrekturgrenze:** Form der Evidenzdatei und
  Item-Index vor der Verarbeitung prüfen; `:null` nicht als Argument zulassen.

### F4 – Lisp-Instrumentierung der Suite enger als ihre Aussage (niedrig)

- **Quelle:** `dreyeck/tests/fedwiki-local-only.lisp:32-43` ersetzt nur die Funktionsbindungen von
  `usocket:socket-connect`, `sb-bsd-sockets:socket-connect`, `get-plugin-page`, `get-fedwiki`.
- **Unüberwacht [abg]:** DNS-Auflösung, `run-program`, früher erfasste Funktionsobjekte (z. B. die Fabrik
  `hb:register-scheme :fedwiki #'get-fedwiki`), Verbindungen aus Hintergrund-Threads wie dem von `make-fedwiki`.
- **Beobachtet [obs]:** Keiner dieser Wege wird in den geprüften Pfaden erreicht. Breitere Wächter in `probes35.lisp`
  zählen 0 abgewiesene Aufrufe (nur `load-page` 16-mal, ohne Neuladen), 0 Link-Redirections, und `strace` zeigt 0
  Netzwerk-Systemaufrufe. Ein gefangener Fehler wird in der Suite mitgezählt; das ist richtig gelöst.
- **Konsequenz:** Die Invariante hält, die Suite allein belegt sie aber nicht vollständig. **Korrekturgrenze:** Prozessweite
  Beobachtung (Netz-Namespace, Systemaufrufe) oder zusätzliche Wächter; keine Laufzeitänderung nötig.

### F5 – Titelleiste der eigenen Site behält „extern öffnen“ (niedrig)

- **Quelle:** vererbt aus `hyperbook-fedwiki/views.lisp:35-39`; `:40` unterdrückt Knöpfe nur für `own-page`.
- **Beobachtet [obs, titlebar35.log]:** `own-page` liefert eine leere Titelleiste (ein `:around` auf `T` verpackt `NIL` in
  eine leere View). `own-site` zeigt einen Knopf, der `https://local/` im Browser öffnet.
- **Konsequenz:** Ein Klick führt aus dem lokalen Kontext heraus (Browser, nicht Lisp). **Korrekturgrenze:** Methode für
  `own-site` analog zu `:40`.

### F6 – Inspector-Kette ist ein Stern um die Beobachtung (niedrig)

- **Beobachtet [obs]:** I2: Von der View „Local-only evidence“ sind Seite, Item, Link, Herkunft, Problem, Vorbereitungs-
  und Auflösungsergebnis, Endzustände und Pläne per `EQ` erreichbar, auch im erweiterten Image. I3: Planbäume nur über die
  Slots-View des Ergebnisses. I4: Seite, Item und Link verweisen nicht zurück auf die Beobachtung. I5: Der Link-Thunk liest
  bei jeder Auswertung eine neue `own-page`, nicht `EQ` zur beobachteten Zielseite. Die View „Playground“ scheitert außerhalb
  von CLOG für jedes Objekt, auch für eine Liste; das liegt nicht an PR #35.
- **Konsequenz:** Eine interaktive Abnahme muss bei der Beobachtung beginnen; Objektidentität von Thunk-Ziel und
  beobachteter Seite ist nicht gegeben.

### F7 – Hinweise (dokumentierte Grenzen)

- Die Versiegelung (`:69-73`) umfasst Fakten, Koordinaten und Objektidentitäten, nicht den Inhalt der Objekte: Änderung von
  Site-Root (P5f) oder Item-Text (P5g) bleibt unbemerkt; die geplanten Fakten bleiben dabei unverändert.
- Registrierte SHOP3-Probleme wachsen weiter (C10: +6 bei je dreimal Vorbereiten und Auflösen).
- `scripts/check-fedwiki-local-only-evidence.py` steht selbst nicht im Manifest; die Läufe im Manifest sind an Basis plus
  Digests gebunden, nicht an den Commit `68ca0c5`.

## Bestätigte Eigenschaften [obs]

- **Netzwerk:** 0 Netzwerk-Systemaufrufe für vorhandenes, fehlendes und nur remote vorhandenes Ziel; Journal-, Item- und
  Attributions-Sites (Kontext bleibt `NIL`); ungültiges JSON (`:unknown`); je dreifaches Beobachten, Auflösen und
  Thunk-Auswerten; echte Wiki-Link-Thunks; Web-, Wikipedia-, Reference- und Image-Links (N1–N4); Rendern aller Views, auch
  im erweiterten Image. Die positive Kontrolle danach erzeugt sichtbar `socket` und `connect`.
- **Gemeinsamer Code:** kollaborative Auflösung, `make-remote`, Plugin-Rückfall, Journal-/Attributionskontext und
  Reihenfolge unverändert; bestehende `local-fedwiki-page` löst weiterhin kollaborativ auf; Fehlertypen gleich, einschließlich
  `NO-APPLICABLE-METHOD` für Nicht-FedWiki-Objekte schon auf PR #34.
- **Eingangsprüfung:** `modeled-*`, Marker und `local-*` aus der Datei werden abgewiesen; veränderte Fakten (P5a), Finding
  (P5b), Link-Slug (P5c), Site-ID (P5d) und Kopien-Digest (P5e) werden erkannt; eine mit `make-instance` gefälschte
  Beobachtung wird abgewiesen (P5h).
- **Fortsetzung:** abgewiesen werden fremdes Ergebnis (C1a), Auflösungs- statt Vorbereitungsergebnis (C1b), Ergebnis einer
  anderen Beobachtung desselben Links (C2), ein in den nativen Endzustand eingefügtes Atom (C3b), Index -1, 1, 1.0, "0", NIL
  (C4), Index 2 bei zwei Alternativen (C5c) und ein Plan ohne Lösung (C7). Zwei Fork-Alternativen sind beide adressierbar
  (C5a, C5b); wiederholte Vorbereitung plant je einen Fork, Fortsetzungen keinen (C0, C6).
- **Fork-Autorität und Simulation:** PR #33 bleibt die einzige Fork-Autorität; der Resolver hat keine Fork-Operatoren [abg].
  Nach hypothetischer Auflösung bleibt das Finding `:confirmed-local-absence`, `target-page` ist `NIL`, und der Speicher
  findet weiterhin keine Seite (C9).

## Offen

- **[offen]** Interaktive Abnahme der Kette in einer laufenden CLOG-Sitzung.
- **[offen]** Korrekturen F1–F3 (gesonderter Korrekturauftrag); F4–F6 optional.

## Reproduktion

```sh
git fetch origin pull/34/head pull/35/head
# in nix develop (oder HYPERDOC_RUNTIME_REGISTRY = nur die Abhängigkeitsclosure, SBCL = deren sbcl):
docs/fedwiki-local-only/review/run-review.sh /tmp/pr35-review-run
diff -r docs/fedwiki-local-only/review/logs /tmp/pr35-review-run
```

`run-review.sh` endet mit `expectations.py`; dessen Zeile `EXPECTATIONS PASS` bedeutet, dass jeder dokumentierte Befund in
genau diesem Lauf wieder auftrat (die Befunde sind Fehler des geprüften Codes, keine bestandenen Tests). Die Eingaben dieses
Laufs (Treiber und Probe-Dateien) sind mit SHA-256 in `logs/inputs.sha256` festgehalten.
Ohne `strace` fehlen die `*.strace-*`-Ausgaben; ohne `unshare` laufen die Prozesse mit Netz. Beides wird in
`summary.log` vermerkt. Einzelne Probes lassen sich direkt laden, z. B.
`PROBE_DIR=$(mktemp -d) sbcl --non-interactive --load docs/fedwiki-local-only/review/probes/probes35.lisp`
(ohne `PR_TREE` prüfen sie den Checkout, in dem sie liegen).
