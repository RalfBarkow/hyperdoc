# PR #31 und PR #32 vor der HyperDoc-Integration: Vergleich mit ausgeführten Gegenproben

Zettel 11560. Stand 8. November 2026. Grundlage: PR #33 `68971d55f68273b77e1d33186bc66e9f019c0902` (unabhängig abgenommen,
Entscheidung A). Verglichen: PR #31 `befce10dc0055222c33d9736723a05d0122a0c9d` und PR #32
`e1ab2f570ee793e301c5af706cbcf2fc984c02a9`. Referenz: `RalfBarkow/fedwiki-java` `b58fb43e7ffbbbda66685363dcda1facbd2a46a1`
(`Main.java` SHA-256 `c53ea762…`). Dieser Branch enthält ausschließlich diese Vergleichsevidenz; keine der drei PRs und keine
Implementierung wurde geändert.

Kennzeichnung: **[obs]** in dieser Prüfung ausgeführt und beobachtet (Log genannt) · **[abg]** aus dem Quelltext abgeleitet,
nicht ausgeführt · **Judgement** eigene Bewertung (Claude) mit Evidenz · **[offen]** Integrationsentscheidung, die noch
niemand getroffen hat. Es gibt hier **keine Engine Critiques**: keine Lisp-Critic-Regel wurde ausgeführt, keine bestehende
Critic-Aufzeichnung verändert. PR #32 ist Claudes eigene Arbeit; jede Bewertung ist deshalb an eine ausführbare Gegenprobe
gebunden, und die Schwächen von PR #32 sind wie die von PR #31 benannt.

Quellverweise: `#31 :N` = `dreyeck/work/link-resolution.lisp` bei `befce10`, Zeile N; `#32 :N` =
`dreyeck/work/fedwiki-link-resolution.lisp` bei `e1ab2f5`; `#33 :N` = `dreyeck/work/defederation-planning.lisp` bei `68971d5`.
Probe-IDs (I1, F2 …) bezeichnen in [probes31.lisp](probes/probes31.lisp) und [probes32.lisp](probes/probes32.lisp)
dieselbe Eingabe, soweit die beiden Vokabulare es zulassen.

## 1. Empfehlung (Judgement)

Eine **abgegrenzte Kombination**:

- **PR #32** ist die Grundlage für die *Auflösung* und die *Evidenz*: Kandidaten als Fakten mit Herkunft, geplante
  `!request`-Schritte, eigene Ausgänge `:not-found` und `:aborted-network-error`, auf Site/Slug begrenzte Widersprüche,
  `diagnose-no-plan`, die Java-Referenz gegen das unveränderte `Main.java` und die Critic-/Judgement-Lektüre.
- **PR #33** ist die *einzige* Quelle der *Fork-Vorbereitung* (`prepare-defederation`). Die Vorbereitungen beider
  Linkmodelle (`prepare-local-target` in #31 und #32) werden nicht übernommen (Abschnitt 4).
- **PR #31** liefert sechs gezielt übernommene Eigenschaften (Abschnitt 6), nicht als Ganzes.

## 2. Tatsächlich erneut ausgeführte Prüfungen

Alle mit [run-review.sh](run-review.sh) aus diesem Branch, zweimal hintereinander; beide Läufe waren **byte-identisch**
[obs]. Die gespeicherten Ausgaben in [logs/](logs/) stammen aus dem ersten Lauf. Laufzeit: SBCL 2.4.10 mit der
HyperDoc-Abhängigkeitsclosure aus Nix, SHOP3 `ce53f9b`, jeder Lisp-Prozess in `unshare --net` (ohne Netz), leeres HOME,
eigener FASL-Cache; OpenJDK 21. Nicht auf dem Mac des Nutzers, nicht auf `dreyeck.ch`.

| Schritt | Inhalt | Ergebnis [obs] | Log |
|---|---|---|---|
| order-equivalence | reine Ordnungsfunktionen beider PRs, 20 000 Zufallseingaben | 0 Abweichungen | [order-equivalence.log](logs/order-equivalence.log) |
| probes31 / probes32 | Vertrags-Gegenproben über den öffentlichen Einstieg | siehe Abschnitte 3–5 | [probes31.log](logs/probes31.log), [probes32.log](logs/probes32.log) |
| prim32 | PR #32-Primitive direkt, `:plan-tree nil` | alle vier planen | [prim32.log](logs/prim32.log) |
| suite31 / suite32 | die PR-eigenen Suites | bestanden | [suite31.log](logs/suite31.log), [suite32.log](logs/suite32.log) |
| critic-reader32 | PR #32 Critic-/Judgement-Lektüre (liest nur, keine Engine) | bestanden | [critic-reader32.log](logs/critic-reader32.log) |
| hyperdoc-comparison32 | PR #32 H1–H3 gegen HyperDocs eigene Resolver-Funktionen | identisch mit dem in PR #32 committeten Log | [hyperdoc-comparison32.log](logs/hyperdoc-comparison32.log) |
| merged31-suite / merged32-suite | PR #33 mit PR #31 bzw. #32 zusammengeführt (`git merge-tree`, keine Textkonflikte) | bestanden, einschließlich `REVIEW-REGRESSIONS-PASS` von PR #33 | [merged31-suite.log](logs/merged31-suite.log), [merged32-suite.log](logs/merged32-suite.log) |
| java31 | PR #31 Java-Harness (Transport-Stub) | 12 von 12 Fällen | [java31.log](logs/java31.log) |
| java32 | PR #32 Java-Harness (Loopback-HTTP, eigener Netz-Namespace) | `observed.json` byte-identisch mit dem committeten | [java32.log](logs/java32.log) |

Zusammenfassung des Laufs: [summary.log](logs/summary.log).

## 3. Vergleich: Java, Politiken, Kandidaten, Befunde

| Thema | PR #31 | PR #32 |
|---|---|---|
| Java-Abgleich | Folge der Miss-/Treffer-Sites; Javas „nicht gefunden“ und „Netzwerkabbruch“ nur als „kein Plan“ (Tests `dreyeck/tests/link-resolution.lisp:58-61`); Transport-Stub mit zwei ersetzten `HttpClient`-Fabriken, Start per Reflection [abg] | Anfragenfolge und Ausgang je Link, 13 Szenarien (`check-java-agreement`, `dreyeck/tests/fedwiki-link-resolution.lisp:40`); unverändertes `Main.java` gegen Loopback-HTTP [abg] |
| Reihenfolge | gleich [obs order-equivalence] | gleich [obs] |
| Fehlende Evidenz | kein Plan [obs M1, M6-Gegenstück in Suite] | kein Plan, `diagnose-no-plan` nennt die Site [obs M6] |
| „nicht gefunden“, Netzwerkfehler | kein Plan, von fehlender Evidenz nicht unterscheidbar [obs M2–M4] | `:not-found`, `:aborted-network-error` [obs M2–M4] |
| Widersprüche | `input-conflict` ohne Argumente (`#31 :18-23`): ein Widerspruch an unbeteiligter Seite blockiert alles [obs C1, C2]; `page-present` + `http-miss 200` gilt als Konflikt [obs C3] | `availability-conflict` je Site/Slug (`#32 :64-67`): unbeteiligte blockieren nicht [obs C1, C2], einer vor dem Treffer schon [obs C2b] |
| Local-only | Gate `allowed` (`#31 :24-25`); kein Remote-Plan [obs M5] | eigene Methoden (`#32 :124-142`); plant nur `!request` an die eigene Site [obs M5] |
| Fork-Voraussetzung | bestätigte Abwesenheit; HTTP 500 genügt nicht [obs F1] | jeder Nicht-200-Status, auch 500 (`#32 :90`) [obs F1] |
| Fork-Verbot | Prädikat fehlt: Fork trotz `fork-forbidden` [obs F2, C5] | beachtet (`#32 :92`, `:157`) [obs F2, C5] |
| Strenge Quellenpolitik | Kopie und Remote-Präsenz [obs F3] | Remote-Präsenz ohne Kopie genügt (`#32 :72-73`) [obs F3] |
| Beide Politiken gesetzt | blockiert [obs C4] | zwei alternative Fork-Pläne [obs C4] |
| Öffentlicher Einstieg | baut nur HTN-Aufgaben (`#31 :79-81`), Origin/Slug fest `:origin`/`:target` | nimmt beliebige Aufgaben (`#32 :163`); Primitive enden im SHOP3-Leerbaum-`TYPE-ERROR` [obs X2, X3, X5] und planen ohne Baum sogar ohne Evidenz [obs prim32] |
| Seiteneffekte beim Laden | `defdomain` ohne `:noset` setzt `shop3:*domain*` [obs R1] | `:noset` [obs R1]; Problem-Registrierungen räumen beide auf [obs R1] |

## 4. Gemeinsame K1/K2-Analogien beider Linkmodelle

PR #33 hat im Review K1 (modellierte Präsenz ohne erzeugenden Fork genügt) und K2 (Fork-Eintrag ohne Präsenz wird erneut
geforkt) korrigiert. **Beide Linkmodelle enthalten dieselben zwei Fehler** [obs]:

| | PR #31 | PR #32 |
|---|---|---|
| K1: importierte `modeled-local-page` allein genügt | modellierte Auflösung, auch Local-only und ohne Fork-Erlaubnis [obs I1–I3]; Quelle `#31 :51-55`, `:63-64` | `:modeled-local` bzw. `:already-modeled-local` [obs I1–I3]; Quelle `#32 :81-83`, `:100-103`, `:149-152` |
| K1-Zusatz: modellierte Präsenz an einer Remote-Kandidatin | nicht möglich, nur an der Origin [obs I4] | wird benutzt [obs I4, prim32 X6] |
| K2: Fork-Eintrag ohne Präsenz | neuer Fork [obs I5]; Quelle `#31 :41-44`, `:65-69` | neuer Fork [obs I5]; Quelle `#32 :89-94`, `:153-159` |
| Fork-Operator direkt zweimal | zwei Forks (Operator ohne `(not modeled-local-page)`) [obs X1] | kein Plan [obs X1] |

Judgement: Keine der beiden Vorbereitungen gehört in den Slice; `prepare-defederation` aus PR #33 schließt beide Fälle
(dort X1.1–X1.3, F2.7).

## 5. HTTP-Miss, lokale Abwesenheit, modellierte Präsenz

Drei verschiedene Dinge, die die Modelle unterschiedlich benennen:

| Bedeutung | Java `b58fb43` | PR #31 | PR #32 | PR #33 |
|---|---|---|---|---|
| Treffer: HTTP 200 mit JSON | Panel öffnen [abg L156-L160] | `page-present` | `page-available` | `local-page` (nur eigene Site), `remote-page` |
| **HTTP-Miss**: ein anderer Status | `null`, nächste Kandidatin; 404, 500 und 302 gleich [abg L156-L160; obs status-500, redirect-302] | 404 → `page-absent`, sonst `http-miss` mit Status (Fixture-Abbildung `OfflineReferenceProbe.java:103`) [abg] | `page-unavailable` mit Status, unabhängig vom Code [abg] | kein Gegenstück |
| **Lokale Abwesenheit**: bestätigt, dass die eigene Seite fehlt | keine eigene Kategorie | `page-absent`; nur sie erlaubt den Fork [obs F1] | keine eigene Kategorie; jeder Miss erlaubt den Fork [obs F1] | `local-page-absent`, Fork-Voraussetzung |
| Kein HTTP-Ergebnis | `trouble`, Programmende [abg L161-L163; obs network-error] | `network-failed`, kein Plan [obs M4] | `request-error`, Abbruch-Plan [obs M4] | kein Gegenstück |
| **Modellierte Präsenz**: Wirkung eines *geplanten* Forks | — | `modeled-local-page` (+ `modeled-fork origin remote slug snapshot`) | `modeled-local-page` (+ `planned-fork own slug remote kind source`) | `modeled-local-page` + `modeled-fork site slug remote snapshot`, nur als Paar (`#33 :32-35`, `:65-70`) |

Judgement:
- Ein HTTP-Miss ist ein fehlgeschlagener Abruf, keine Aussage über die Existenz der Seite. Nur eine *bestätigte* lokale
  Abwesenheit darf einen Fork begründen; damit hat PR #31 gegen PR #32 recht (F1).
- Modellierte Präsenz ist nie ein Nachweis einer existierenden lokalen Seite. In allen drei Modellen erzeugt sie keine
  Beobachtung [obs: kein `page-present`/`page-available`/`local-page` in den Endzuständen]. Das Ergebnis muss die
  Grundlage (`:observed` oder `:modeled`) ausweisen; PR #31 und PR #32 tun das bereits.
- Die drei `modeled-fork`-Varianten haben verschiedene Argumentreihenfolgen. Maßgeblich wird die von PR #33.

## 6. Sechs Eigenschaften, die gezielt aus PR #31 übernommen werden (Judgement)

1. **Bestätigte Abwesenheit als Fork-Voraussetzung** (`#31 :42`), nicht jeder HTTP-Miss [obs F1 in beiden].
2. **Modellierte Auflösung nur an der Origin** (`#31 :51-55`) [obs I4 in beiden].
3. **Geschlossener öffentlicher HTN-Einstieg**: `plan-resolution` baut die Aufgaben selbst (`#31 :79-81`), statt beliebige
   Aufgabenlisten anzunehmen (PR #32 X2–X5).
4. **Zusätzliche Java-Fixtures**: Neighborhood und Sitemap-Cache bei Wiederholung, Locale-abhängiges Slugging, ausgewähltes
   zweites Story-Item (`itemno=1`) (`dreyeck/tests/fixtures/link-resolution/cases.json`) [obs java31].
5. **Assertierter HyperDoc-Helper-Abgleich**: `context-site-references` gegen Javas `Page.context` als Testbedingung
   (`dreyeck/tests/link-resolution-evidence.lisp:27-39`) [obs suite31]; PR #32 hat denselben Vergleich nur als Log.
6. **Model-Comparison-Records** im Protokoll `dreyeck/evaluation-record` (`dreyeck/work/link-resolution-evidence.lisp:8-68`)
   als Evidenzobjekt, auf das ein Judgement verweisen kann.

Nicht übernommen: der globale Konflikt, die fehlende Verbotssemantik, die Fork-Vorbereitung und die fest verdrahteten
Koordinaten von PR #31.

## 7. Wiederverwendung der Critic-/Judgement-Lektüre aus PR #32

[abg] `read-pr-critique-review (&key record judgements)` nimmt die Pfade als Parameter; die Klassen `pr-critique-review`,
`pr-source-form`, `pr-critique-finding`, `pr-judgement`, die Judgement-View, die Drift-Erkennung über commit-fixierte
Digests und die Rekonstitution der Evaluation Records sind nicht an die Linkauflösung gebunden. An PR #32 gebunden sind
der Paketname, `%path` auf `docs/fedwiki-link-resolution/critic/` und im Recorder `+pull-request+`/`+targets+`.
Judgement: ein generisches System (etwa `dreyeck/pr-critique`) und ein Recorder mit PR und Zieldateien als Argumenten;
das JSON-Schema bleibt. Die Model-Comparison-Records aus PR #31 ergänzen Judgements als Evidenz, ersetzen aber keine
Critique. Die Reading-Seite von PR #31 nennt die Riesbeck/Beane-Implementierung noch „historical station … unavailable“;
das ist überholt.

## 8. Tests, Reproduzierbarkeit, HyperDoc-Anbindung

- Umfang [abg]: PR #31 39 benannte Abfragen, 2 Mutanten, 26 Evaluation Records; PR #32 13 Szenarien, 8 Prüfungen plus
  Unterscheidungen, 14 Mutanten plus Kontrolle, drei Nachbar-Suites, Critic-Reader.
- Nur in PR #32: 302, `attribution-site`, Slug-Normalisierung, zweiter Link über die Panel-Site [abg].
- HyperDoc [obs hyperdoc-comparison32]: PR #32 ruft `lookup-slug-in-page-context` und `local-fedwiki` offline auf und belegt
  Abweichungen (Item-Site ignoriert, `attribution.site` zählt, Start beim Wiki der Seite) sowie **Verbindungsversuche von
  `local-fedwiki`** beim Laden und Auflösen (H3). Das ist nur geloggt, nicht assertiert. Keine der beiden PRs ändert den
  produktiven Resolver; keine ist Teil des Catalogs.

## 9. Integrationsvertrag

1. **Nur zugelassene Beobachtungsprädikate** und 2. **Eingangsschutz für importierte Zustände** (Judgement, vorgesehen, nicht
   gebaut): eine Prüfung an der Slice-Grenze mit fester Liste.
   - Auflösung: `page-available`, `page-unavailable`, `request-error`.
   - Defederation: `local-page`, `local-page-absent`, `remote-snapshot`, `snapshot-unavailable`, `remote-page`,
     `remote-page-absent`, `fork-permitted`, `fork-forbidden`, `fork-source-policy`.
   - `modeled-local-page`, `modeled-fork`, `planned-fork`, `local-links-prepared`, `paragraph-rendering-prepared` und
     `planned-*`-Marker werden mit einer Condition **abgewiesen** (nicht stillschweigend entfernt, nicht „kein Plan“).
   - Ausnahme nur mit überprüfbarer Herkunft: eine Fortsetzungs-API, die ein eigenes `hyperdoc-htn-plan-result`
     annimmt und dessen Endzustand selbst liest, statt eine Faktenliste des Aufrufers.
   - Heute planen alle drei Modelle mit importierten modellierten Fakten: PR #31 hier I1–I3 und I5, PR #32 I1–I5,
     PR #33 im Abschluss-Review P1–P5 [obs].
3. **HTN-Einstieg**: PR #33 und PR #31 erfüllen ihn [abg]; PR #32 muss die Aufgabe im Einstieg bauen [obs X2–X5].
4. **Simulation ist kein Seitennachweis**: erfüllt in allen drei Modellen [obs]; die Grundlage muss im Ergebnis stehen.
5. **Local-only ohne Remote-Zugriff**: Die Planer greifen nie auf das Netz zu [abg]. Das Risiko liegt in der realen
   Auflösung (H3 [obs]). Siehe Abschnitt 11.

## 10. Notwendige Anpassungen an PR #33 (Judgement, nicht ausgeführt)

1. **Eingangsschutz** in oder vor `plan-defederation` (`#33 :98`) nach Abschnitt 9; dazu die Fortsetzung aus dem eigenen
   Ergebnisobjekt. Tests: P1–P5 werden abgewiesen, die Fortsetzung aus B (K1.cont) bleibt möglich.
2. **Beobachtungsabbildung festlegen und dokumentieren**: eigene Site HTTP 200 → `local-page`; nur bestätigte Abwesenheit →
   `local-page-absent`; andere Status, Weiterleitungen und Request-Fehler → kein Fakt.
3. **Grundlage der Zielbereitschaft auslesbar machen** (`observed` oder `simulated`, `#33 :32-35`).
4. **Hygiene**: `delete-problem` in `unwind-protect` (K7), wie PR #31 und #32; `defdomain … :noset` (`#33 :8`) [abg].
5. **Optional, zur Absicherung**: `(not (input-conflict …))` in den zwei Vorbereitungs-Operatoren (`#33 :47-52`, N3 des
   Abschluss-Reviews); Tests, die R1 und X-R8 festhalten (N1, N2).

## 11. Offene Integrationsentscheidungen und ausstehende Prüfungen

- **[offen] Bestimmung der eigenen Site.** Java nimmt `origin`, die Heimat des Lesers (`Main.java` L39-L50). HyperDoc
  beginnt beim Wiki der Seite (`hyperbook-of page`; obs H2 panel-site „s1's own page“: die Origin wird nie gefragt). Beide
  Linkmodelle nehmen `origin` an; PR #33 nimmt die übergebene `site`. Für Local-only entscheidet diese Wahl, welche Site
  überhaupt „lokal“ ist. Niemand hat sie bisher getroffen.
- **[ausstehend] Netzwerkfreie Local-only-Runtime.** Noch nicht geprüft. Erforderlich ist ein Local-only-Pfad in HyperDoc
  ohne `get-plugin-page` und ohne Kontextschleife, dazu ein Test, der jede Socket-Verbindung protokolliert und ablehnt
  und **null Versuche** assertiert (H3 als Test statt Log). Die `!request`-Schritte aus PR #32 können als Erlaubnisliste
  für die Erhebung der Beobachtungen dienen. Unter Local-only darf die strenge Quellenpolitik nur vorhandene
  `remote-page`-Evidenz verwenden; der Slice darf sie nicht nachladen.
- [offen] Welche Statuscodes als bestätigte Abwesenheit gelten (nur 404?).
- [offen] Netzwerkfehler: abbrechen wie Java oder weitersuchen.
- [offen] Weiterleitungen (Java folgt nicht, drakma folgt).
- [offen] Nur der erste Link eines Items (Java) reicht für eine Defederation aller Links nicht.

## 12. Dateien und Reproduktion

- [run-review.sh](run-review.sh): extrahiert die drei PR-Commits unverändert per `git archive` in ein privates
  Temporärverzeichnis (am Ende gelöscht), führt jede Prüfung aus Abschnitt 2 in einem eigenen Prozess aus und schreibt die
  Markerzeilen nach `OUT_DIR`, mit dem Temporärverzeichnis durch `<WORK>` ersetzt. `git merge-tree` legt dabei nur
  unreferenzierte Objekte im Objektspeicher ab; kein Ref ändert sich.
- [probes/](probes/): `probes31.lisp`, `probes32.lisp`, `prim32.lisp`, `order-equivalence.lisp` (liest nur die reinen
  Ordnungsfunktionen beider PRs als Daten, `*read-eval* nil`) und `critic-reader-32.lisp`. Die Probes lesen den zu
  prüfenden Baum aus `PR_TREE` bzw. `PR31_TREE`/`PR32_TREE`; sie enthalten keine lokalen Pfade.
- [logs/](logs/): die Ausgaben aus Abschnitt 2.

```sh
git fetch origin pull/31/head pull/32/head pull/33/head
# in nix develop (oder HYPERDOC_RUNTIME_REGISTRY = nur die Abhängigkeitsclosure, SBCL = deren sbcl):
FEDWIKI_JAVA_ROOT=/pfad/zu/fedwiki-java \
  docs/fedwiki-link-resolution-integration/review/run-review.sh /tmp/integration-review-run
diff -r docs/fedwiki-link-resolution-integration/review/logs /tmp/integration-review-run
```

Ohne `FEDWIKI_JAVA_ROOT` (sauberer Checkout auf `b58fb43`, JDK 11+, python3) werden die zwei Java-Schritte übersprungen und
in `summary.log` als übersprungen vermerkt.
