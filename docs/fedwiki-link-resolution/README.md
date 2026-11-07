# Federated-Wiki-Linkauflösung: fedwiki-java, HyperDoc und ein SHOP3-Modell

Zettel 11483 und 11560. Untersuchungsgegenstand ist `RalfBarkow/fedwiki-java` bei
[`b58fb43`](https://github.com/RalfBarkow/fedwiki-java/tree/b58fb43e7ffbbbda66685363dcda1facbd2a46a1)
(verifiziert: HEAD des Klons, `Main.java` sha256 `c53ea762…`). Die Referenz ist Gegenstand, keine Norm.
Basis dieses Branches: PR #29 `ecb2b8b` (auf `dreyeck.ch` `00d2a18`). PR #29 und PR #30 bleiben unverändert;
ihre Quellen werden hier nur gelesen. Kein Merge, kein Deployment, kein Dienst, keine Wiki-Daten.

Kennzeichnung: **[obs]** in diesem Branch ausgeführt und beobachtet · **[abg]** aus dem Quelltext abgeleitet, nicht
ausgeführt · **[hyp]** Vermutung. **Judgement** = eigene Bewertung (Claude), mit Evidenz. **Engine Critique** = Ergebnis
einer tatsächlich ausgeführten Lisp-Critic-Regel; davon gibt es hier **keine** (siehe Abschnitt 5).

Zeilenverweise auf `Main.java` zeigen auf die Revision `b58fb43`.

## 1. Quellenbericht fedwiki-java

### Zustand

| Zustand | Quelle | Inhalt |
|---|---|---|
| `origin`, `slug` | [L39-L41](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L39-L41) | Heimat-Site des Lesers (Default `ward.dojo.fed.wiki`, `args[0]` überschreibt, [L50](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L50)); Startseite `welcome-visitors` |
| `lineup` | [L43-L44](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L43-L44) | Liste der Panels (Site, Slug, Page, `itemno`) |
| `neighborhood` | [L46-L47](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L46-L47) | Site → SiteMap, auch `null` bei Nicht-200 |
| Panel | [L205-L214](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L205-L214) | `site`, `slug`, `page`, aktuelles Item `itemno` |

Start: `enlarge(origin)`, dann `lineup.add(Panel.load(origin, slug))` ([L51-L52](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L51-L52)). Der Befehl `link` folgt dem
**ersten** `[[Link]]` des **aktuellen** Items des **letzten** Panels ([L104-L105](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L104-L105), [L275-L277](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L275-L277)).

### Auflösungsschritte

| Schritt | Quelle | Verhalten |
|---|---|---|
| Link → Slug | `Item.links()` [L307-L319](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L307-L319) | Nur der erste `[[…]]`; Whitespace → `-`, alles außer `[A-Za-z0-9-]` entfernt, dann `toLowerCase(Locale.getDefault())`. [obs] `slug-normalization`: `[[Ward's Página 2]]` → `wards-pgina-2`. Item ohne Link: `get(0)` auf leerer Liste → Ausnahme [abg] |
| Journal-Kontext | `Page.context()` [L289-L295](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L289-L295) | Journal vom neuesten zum ältesten; `site` jeder Aktion, erste Nennung zählt. `attribution.site` wird nicht gelesen ([L327-L333](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L327-L333)). [obs] `context-newest-first`, `journal-reorder`, `attribution-site` |
| Panel-Kontext | `Panel.context()` [L266-L273](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L266-L273) | Ist das Panel nicht von `origin`, steht seine Site vorn (aus der Liste entfernt, vorn eingefügt). [obs] `panel-site` |
| Item-Site | `Panel.load(from, slug)` [L226-L230](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L226-L230) | Hat das aktuelle Item ein `site`, steht diese Site ganz vorn im Kontext. [obs] `item-site` |
| Reihenfolge | [L232-L253](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L232-L253) | Zuerst **immer** `origin`, dann der Kontext in Reihenfolge. `origin` wird nicht aus dem Kontext entfernt und kann zweimal angefragt werden. [obs] `origin-in-context` |
| Erfolg | [L236-L243](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L236-L243), [L156-L160](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L156-L160) | Erste Site mit HTTP **200** und parsebarem JSON; neues Panel an diese Site |
| Kein Treffer | [L245-L249](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L245-L249) | Jeder andere Status (404, 500, **302**: `HttpClient` folgt Weiterleitungen nicht) → `null` → nächste Kandidatin. [obs] `context-fallthrough`, `status-500`, `redirect-302` |
| Kontext erschöpft | [L250-L252](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L250-L252), [L81-L84](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L81-L84) | `trouble("can't find page in current context")` → `System.exit(1)`. [obs] `not-found`, `attribution-site` |
| Netzwerk-/IO-Fehler | [L161-L163](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L161-L163) | `trouble("http error: …")` → **Programmende**, keine weitere Kandidatin, obwohl eine spätere die Seite hätte. [obs] `network-error` (`http error: null`). JSON-Parsefehler sind `IOException` und enden ebenso [abg] |
| Startseite | `Panel.load(site, slug)` [L216-L223](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L216-L223) | Kein Kontext; Nicht-200 → `trouble` |
| Lineup | [L104-L111](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L104-L111), [L132-L141](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L132-L141) | `link` hängt das neue Panel an; `back` entfernt von hinten bis zum passenden Titel. [obs] Lineup-Ausgabe aller Szenarien |
| Neighborhood | `enlarge` [L193-L199](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L193-L199), [L240-L242](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L240-L242) | Nach jedem erfolgreichen Laden wird die SiteMap jeder Kontext-Site des **neuen** Panels gelesen (einmal je Site, auch `null` gespeichert). Die SiteMaps werden bei der Auflösung **nie** gelesen. [obs] `sitemap_requests` |

**Implementiert vs. Roadmap** ([README](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/README.md)):
✔︎ kollaboratives Linking, ✔︎ Lineup. „Accumulate sites … neighborhood“ ist **ohne Haken**, aber teilweise
implementiert (`enlarge` sammelt SiteMaps). „Search for pages based on neighborhood sitemaps“ ist **nicht**
implementiert: kein Code liest `neighborhood` außer `containsKey` in `enlarge`. Plugins und About-Seiten: nicht implementiert.
`input.txt`/`output.txt` sind ein Testskript gegen die Live-Site `ward.dojo.fed.wiki` mit aufgezeichneter Ausgabe; die
Ausgabe zeigt dieselbe Reihenfolge (z. B. `See [[Constructionism]]`: Debug `eric.dojo.fed.wiki`, `wiki.dbbs.co`) [abg aus
der aufgezeichneten Datei; nicht erneut gegen das Netz ausgeführt].

### Beobachtete Referenzläufe

`tests/fedwiki-java-reference/run-reference.py` übersetzt das unveränderte `Main.java` mit den Jars des Repositories,
startet es in einem **leeren Netzwerk-Namespace** (nur Loopback, `example.org` löst nicht auf) gegen je einen lokalen
HTTP-Server pro Fixture-Site und protokolliert jede Anfrage. Ergebnis: [`observed.json`](../../tests/fedwiki-java-reference/observed.json),
zweimal erzeugt, byte-identisch [obs]. Zusammenfassung: [evidence/java-reference-run.txt](evidence/java-reference-run.txt).

| Szenario | Seitenanfragen nach dem Start (Site/Status) | Ergebnis |
|---|---|---|
| local-first | origin 200 | Target @ origin |
| context-newest-first | origin 404, s2 200 | Target @ s2 (s1 hätte sie auch) |
| context-fallthrough | origin 404, s2 404, s1 200 | Target @ s1 |
| item-site | origin 404, s1 200 | Target @ s1 (ohne Item-Site: s2) |
| journal-reorder | origin 404, s1 200 | Target @ s1 |
| not-found | origin 404, s2 404, s1 404 | exit 1, „can't find page in current context“ |
| status-500 / redirect-302 | origin 404, s2 500 bzw. 302, s1 200 | Target @ s1 |
| network-error | origin 404, dead (Verbindung abgelehnt) | exit 1, „http error: null“; s1 nie gefragt |
| panel-site | origin 404, s1 200; dann origin 404, s1 404, s2 200 | Lineup origin, s1, s2 |
| origin-in-context | origin 404, origin 404, s1 200 | Target @ s1 |
| attribution-site | origin 404 | exit 1; s1 (nur in `attribution`) nie gefragt |
| slug-normalization | origin 200 (`wards-pgina-2`) | gefunden |

## 2. Vergleich Java / HyperDoc / SHOP3

Ausführbare Probe ohne Netz und ohne Änderung einer Implementierung:
[evidence/hyperdoc-comparison.lisp](evidence/hyperdoc-comparison.lisp), Ausgabe [evidence/hyperdoc-comparison.log](evidence/hyperdoc-comparison.log).
Sie ruft HyperDocs eigene Funktionen auf denselben Fixtures auf: `context-site-references` (H1),
`lookup-slug-in-page-context` auf offline gebauten `fedwiki`-Objekten (H2; SiteMaps aus den Fixtures, eine nur in diesem
Probe-Image hinzugefügte aufzeichnende `:around`-Methode auf `hyperbook:find-page`) und `local-fedwiki` (H3; usocket-Verbindungen
werden aufgezeichnet und abgelehnt).

HyperDoc-Stellen (bei `ecb2b8b`): `hyperbook-fedwiki/wiki-links.lisp` `lookup-slug-in-page-context` L39-L47;
`hyperbook-fedwiki/pages.lisp` `site-of` L218, `context-site-references` L227, `extract-context` L248, `reload-page` L96-L105;
`hyperbook-fedwiki/plugins.lisp` `get-plugin-page` L73-L94; `hyperbook-fedwiki/fedwiki.lisp` `find-page` L234;
`dreyeck/src/local-fedwiki-page.lisp` `find-page` L135.

**Identisches Verhalten**
- Journal-Kontext: neueste Nennung zuerst, ohne Duplikate — in 12 von 13 Fixtures gleich (H1) [obs].
- Kontext durchlaufen, erste vorhandene Seite gewinnt; Fallthrough; Fehlschlag, wenn nichts gefunden wird (H2: local-first,
  context-newest-first, context-fallthrough, journal-reorder, not-found) [obs].
- Über die Origin erreichte Remote-Seite: deren Site steht vorn, danach ihr Journal-Kontext (H2 panel-site Link 2:
  origin, s1, s2 wie Java) [obs]. Grund: `make-remote` setzt den Kontext auf `(cons remote-wiki …)`, und die
  Remote-Proxy-Seite gehört dem Origin-Wiki.
- Origin im eigenen Journal wird ein zweites Mal gefragt (H2 origin-in-context) [obs].
- Slug-Funktion: dieselben regulären Ausdrücke (`slug` in `wiki-links.lisp` L74-L78) [abg].

**Bewusst unterschiedliches Verhalten** (im Code so angelegt)
- Existenz einer Seite: HyperDoc prüft zuerst die SiteMap (`find-page`), dann einen direkten Abruf über `get-plugin-page`
  (fehlende Seite = ungültiges JSON → `nil`); Java prüft nur HTTP 200 [abg; H2 zeigt die zwei Abfragen der eigenen Site].
- Fehlschlag: HyperDoc signalisiert `wiki-lookup-failure`, Java beendet das Programm [abg].

**Unbeabsichtigte mögliche Abweichungen** (Absicht nicht belegt)
- **Item-Site wird ignoriert** (H2 item-site): HyperDoc löst bei s2 auf, Java bei s1 [obs].
- **`attribution.site` zählt in HyperDoc** (`site-of`; H1, H2 attribution-site): HyperDoc findet die Seite bei s1, Java scheitert [obs].
- **Startpunkt ist das Wiki der Seite, nicht der Leser-Origin**: Dieselbe s1-Seite, nativ in s1s HyperBook geöffnet, fragt
  s1, dann s2, nie die Origin (H2 panel-site „s1's own page“); Java fragt immer zuerst die Origin [obs].
- **`local-fedwiki` ist nicht lokal in der Auflösung** (H3): Das Laden einer lokalen Seite versucht `remote.example:443`
  (`set-page-data` → `extract-context` → `get-fedwiki` startet die Initialisierung). Die Suche nach einem fehlenden Slug
  versucht `local.example:443` (`get-plugin-page`). Der Netzwerkfehler entweicht dann aus `lookup-slug-in-page-context`.
  Ohne diesen Schritt fragt die Suche anschließend das Remote-Wiki des Kontexts [obs]. `find-page` selbst ist lokal.
- Netzwerkfehler: in HyperDoc entweicht `ns-host-not-found-error` aus der Suche (H3) [obs]; Java beendet das Programm [obs].

**Nicht ausreichend belegte Annahmen**
- Dass Javas `origin` (Heimat des Lesers) und HyperDocs `hyperbook-of page` dasselbe meinen sollen.
- Weiterleitungen: drakma folgt ihnen standardmäßig, Javas `HttpClient` nicht (`redirect-302` [obs] für Java; HyperDoc [abg]).
- `toLowerCase(Locale.getDefault())` unter einer türkischen Locale [hyp]; Unicode in Slugs wird entfernt [obs].
- Ob die aufgezeichnete Live-Ausgabe `output.txt` heute noch gilt [nicht ausgeführt].

**PR #29 und PR #30** modellieren beide **keine** Kandidatenreihenfolge und keine HTTP-/Fehlersemantik, sondern nur
„Ziel lokal oder forkbar“ für eine Site [abg]. Sie verkörpern die beiden Antworten auf die offene Fork-Frage (Abschnitt 6):
PR #29 `remote-snapshot` genügt ohne Remote-Existenz (≈ `verified-copy-suffices`), PR #30 verlangt `remote-page` **und**
`snapshot-available` (≈ `require-remote-confirmation` plus Kopie) [abg]. PR #30 ersetzt `local-page-absent` durch
`local-page` (simulierte als beobachtete Präsenz); PR #29 bewahrt die Beobachtung, plant aber denselben Fork zweimal
(unabhängiger Review, Befunde F1 und F2). Dieses Modell übernimmt PR #29s Trennung und schließt den doppelten Fork aus (G7).

## 3. SHOP3-Modell

Opt-in-System `dreyeck/work/fedwiki-link-resolution` ([Quelle](../../dreyeck/work/fedwiki-link-resolution.lisp)),
Tests `dreyeck/work/fedwiki-link-resolution/tests` ([Quelle](../../dreyeck/tests/fedwiki-link-resolution.lisp)).
Kein Default-System hängt davon ab; `defdomain … :noset` lässt `shop3:*domain*` unverändert.

**Kandidatenreihenfolge** (reine Funktionen, Anweisung für Anweisung nach `Main.java`): `java-page-context`
(L289-L295), `java-panel-context` (L266-L273), `java-link-candidates` (L225-L255) mit Herkunft `:origin`, `:item`,
`:panel`, `:journal`. `candidate-facts` erzeugt `(candidate r pos site source)`, `(candidate-after r pos next)`, `(candidates-end r n)`.

**Beobachtungen** (fehlend = unbekannt; keine Methode deutet Fehlen als Abwesenheit): `(page-available site slug)` = 200,
`(page-unavailable site slug status)` = anderer Status, `(request-error site slug)` = keine HTTP-Antwort. Widersprüchliche
Beobachtungen (`availability-conflict`) sperren den betroffenen Schritt.

**Aufgaben und Methoden** (jede Alternative eine eigene `:method`, damit `:which :all` Überschneidungen zeigt):

| Aufgabe | Methoden | Primitive Schritte |
|---|---|---|
| `(resolve r slug collaborative)` | `walk-candidates` → `try-candidate` ab Position 0: `candidate-has-modeled-page`, `candidate-available`, `candidate-unavailable-next`, `candidate-request-error`, `candidates-exhausted` | `!request`, `!open-panel`, `!use-modeled-page`, `!abort-resolution`, `!conclude-unresolved` |
| `(resolve r slug local-only)` | `own-site-only` → `try-own-site`: `observed-local`, `modeled-local`, `missing-locally`, `own-request-error` — **keine** Methode erreicht `try-candidate` | dieselben, nur für die eigene Site |
| `(prepare-local-target slug)` | `already-observed-local` (null Schritte), `already-modeled-local` (null Schritte), `fork-planned` | `!plan-fork` |

**Simulation:** `!plan-fork` fügt nur `(modeled-local-page own slug)` und `(planned-fork own slug remote kind source)`
hinzu; die 404-Beobachtung bleibt, `page-available` entsteht nie. Ein Fork wird nur geplant, wenn die Seite weder
beobachtet noch modelliert lokal ist (Methode **und** Operator prüfen das), mit `(fork-permitted own remote slug)`, ohne
`fork-forbidden` und mit einer Quelle nach der **ausdrücklich** gesetzten `fork-source-policy`.

**Ergebnis:** `plan-link-resolution` liefert das vorhandene `hyperdoc-htn-plan-result` (`:plan-only`, alle vier
SHOP3-Rückgabewerte, `:which :all`), registriert das Problem nur für die Suche und stellt `shop3::*problem*` wieder her.
Für Pläne ohne Schritt umgeht es den Defekt des gepinnten SHOP3 `ce53f9b` (`STRIP-TREE-TAGS`: „NIL is not of type CONS“):
neue Suche ohne Bäume, Baum je Plan `(:plan-tree-unavailable :shop3-empty-plan-defect)`, Listen bleiben parallel.
`plan-outcomes` liest je Plan: `:local-observed`, `:remote-context`, `:modeled-local` (hypothetisch), `:not-found`,
`:aborted-network-error`, `:fork-planned`, `:already-local-observed`, `:already-modeled-local`. Kein Plan → `diagnose-no-plan`
nennt die erste Site mit unbekannter oder widersprüchlicher Evidenz (eine Lisp-Diagnose, kein SHOP3-Ergebnis).

## 4. Gegenproben

Alle [obs], in frischen SBCL-Images (2.4.10, SHOP3 `ce53f9b`, Projekt-Laufzeit aus Nix) in einem Netzwerk-Namespace ohne Verbindung nach außen.

| # | Prüfung | Evidenz | Ergebnis |
|---|---|---|---|
| — | Übereinstimmung mit Java | `check-java-agreement`: 13 Szenarien, Anfragenfolge und Ausgang je Link gegen `observed.json` | gleich |
| 1 | Lokaler Treffer hat Vorrang | local-first (Java); `check-local-precedence` (beide Politiken) | nur origin angefragt |
| 2 | Kontextreihenfolge ohne lokalen Treffer | context-newest-first, context-fallthrough (Java); `check-context-order` | s2 vor s1 |
| 3 | Item-Site ändert die Reihenfolge | item-site (Java) | s1 statt s2 |
| 4 | Journal-Eintrag ändert die Reihenfolge | journal-reorder (Java) | s1 statt s2 |
| 5 | Local-only verweigert Remote-Fallback | `check-local-only-gate`: alle 13 Szenarien und synthetische Zustände | nur eigene Site; `:not-found` bzw. Abbruch; kein Fork |
| 6 | Geplanter Fork ≠ ausgeführter Fork | `check-planned-fork-not-executed` | `:modeled-local`; `modeled-local-page` + `planned-fork`; 404 bleibt; kein `page-available` |
| 7 | Kein unbegründeter zweiter Fork | `check-no-second-fork` | ein Fork je Ziel; Neuplanung auf dem simulierten Endzustand: null Schritte, `:already-modeled-local` |
| 8 | Unbekannt ≠ nachgewiesen abwesend | `check-unknown-not-absent` | unbekannte Kandidatin sperrt (Diagnose nennt s2); unbekannte eigene Seite sperrt local-only; unbekannte Erlaubnis sperrt den Fork |
| — | Weitere Unterscheidungen | `check-distinctions` | erste Remote-Kandidatin gewinnt; zwei Fork-Quellen = zwei alternative Pläne; nicht gefunden ≠ Evidenz fehlt; Widerspruch; Fork-Politik in beide Richtungen; Verbot gilt |
| — | Null Schritte | `check-zero-step-plans` | Plan statt Fehlschlag, Baum markiert |

**Mutanten** (jeder muss von der genannten Prüfung erkannt werden; Kontrolle: eine unveränderte Kopie der Domäne besteht
alle acht Domänenprüfungen) — 14 von 14 erkannt [obs]:
Reihenfolge: Journal ältestes zuerst · Item-Site nicht vorn · Panel-Site nicht vorn · Origin aus dem Kontext entfernt
(ersetzte Produktionsfunktionen, `check-java-agreement`). Local-only-Gate: läuft die kollaborativen Kandidaten · fällt bei
Fehlen auf den Kontext zurück · forkt statt den Fehlschlag zu melden. Semantik: Origin übersprungen · Netzwerkfehler als
„nicht hier“ · Closed World. Fork: ohne Prüfung auf modellierte Seite · schreibt eine Beobachtung · ignoriert ein Verbot ·
verifizierte Kopie genügt ohne ausdrückliche Politik. Zwei meiner ersten Mutanten waren selbst fehlerhaft (falsches
Paket, `eql` auf Strings) und überlebten deshalb; sie wurden korrigiert, und die Kontrolle wurde danach hinzugefügt.

## 5. Inspector und Evaluation Trace

```lisp
(asdf:load-system "dreyeck/work/fedwiki-link-resolution")
(defparameter *link* (dreyeck/work/fedwiki-link-resolution:link-resolution-experiment
                      "context-newest-first" 0 'dreyeck/work/fedwiki-link-resolution::collaborative))
(defparameter *local* (dreyeck/work/fedwiki-link-resolution:link-resolution-experiment
                       "context-newest-first" 0 'dreyeck/work/fedwiki-link-resolution::local-only))
(list (getf *link* :outcomes) (getf *local* :outcomes))
(clog-moldable-inspector:clog-inspect :object *link*)
```

Der Kontext enthält: Java-Revision und Quellstelle, die Java-Beobachtung dieses Szenarios, Anfangsfakten, Aufgabe,
SHOP3-Domäne und Methoden, das `hyperdoc-htn-plan-result`, die Lesart je Plan, ggf. die Diagnose, `:execution :not-executed`,
`:engine-critiques ()` und `:rule-trace`. Die Slots-Ansicht und alle HTML-Ansichten von Ergebnis und Kontext wurden für vier
Fälle ohne Server erzeugt [obs] (`scripts/test-fedwiki-link-resolution.lisp`). Live-SLY/CLOG wurde nicht geprüft.

**Beziehungen** (`rule-trace`; Evaluation Record = die genannte Prüfung mit ihrer PASS-Zeile im Testlauf):

| Regel | Java-Quelle | Beobachtet | SHOP3-Regel | Gegenprobe | Judgement |
|---|---|---|---|---|---|
| Kandidatenreihenfolge | [L225-L255](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L225-L255), [L266-L273](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L266-L273), [L289-L295](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L289-L295) | 6 Szenarien | `java-link-candidates`, `walk-candidates` | Java-Übereinstimmung, 4 Reihenfolge-Mutanten | J1 |
| Lokaler Vorrang | [L232-L236](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L232-L236) | local-first | `candidate-available` (Position 0) | G1, Mutante „Origin übersprungen“ | — |
| Nicht-200 = nicht hier | [L156-L160](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L156-L160) | fallthrough, 500, 302 | `candidate-unavailable-next` | Java-Übereinstimmung, Closed-World-Mutante | J2 |
| Netzwerkfehler beendet | [L161-L163](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L161-L163) | network-error | `candidate-request-error`, `own-request-error` | Java-Übereinstimmung, Mutante | J3 |
| Kontext erschöpft | [L250-L252](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L250-L252) | not-found | `candidates-exhausted` | Java-Übereinstimmung | — |
| Local-only | — (Wards Vorschlag) | — | `own-site-only` … | G5, 3 Gate-Mutanten | J4 |
| Simulierter Fork | — | — | `fork-planned`, `!plan-fork` | G6, G7, 4 Fork-Mutanten | J5 |

**Engine Critiques: keine.** Die Riesbeck/Beane-Engine braucht die Source Station (Asset-Verzeichnis der Wiki-Seite
`a-critic-for-lisp`), die in dieser Umgebung fehlt. Auf einer Maschine mit Station (nicht ausgeführt; die Formen stammen aus
`car-cdr-critique-example`):

```lisp
(asdf:load-system "dreyeck/lisp-critic/critique")
(let* ((station (dreyeck/lisp-critic::make-critic-source-station "/pfad/zur/a-critic-for-lisp/"))
       (contract (make-instance 'dreyeck/lisp-critic:lisp-critic-contract
                   :id "fedwiki-link-resolution" :title "Critique of the link-resolution model" :source-station station
                   :input-policy '(:file) :invocation-policy '(:critique-file) :output-policy '(:raw-output-preserved)
                   :availability-policy '(:local-source-required) :failure-policy '(:record-condition)
                   :review-contract-role :critique)))
  (dreyeck/lisp-critic:run-lisp-critic-contract
   contract (list (asdf:system-relative-pathname "dreyeck/work/fedwiki-link-resolution"
                                                 "dreyeck/work/fedwiki-link-resolution.lisp"))))
```

**Judgements** (Claude, keine Engine-Ergebnisse):
- **J1** Die Reihenfolge ist in reinen Funktionen statt in SHOP3-Axiomen kodiert; die Listenoperationen (entfernen, vorn
  einfügen, keine Deduplizierung gegen `origin`) wären als Axiome schwer prüfbar. Evidenz: Java-Übereinstimmung und vier
  erkannte Reihenfolge-Mutanten. Folge: SHOP3 modelliert die zustandsabhängige Zerlegung, nicht die Listenbildung.
- **J2** `302` als „nicht hier“ ist eine Eigenschaft der Java-Referenz (keine Weiterleitung), keine fachliche Regel.
  Evidenz: `redirect-302`. Empfehlung: für HyperDoc nicht übernehmen, ohne Weiterleitungen bewusst zu entscheiden.
- **J3** Dass ein Netzwerkfehler die ganze Auflösung beendet, ist Java-Verhalten; ein Federated-Wiki-Client würde
  plausibel weitersuchen [hyp]. Das Modell bildet Java ab; die Gegenposition ist eine Mutante, die die Java-Übereinstimmung bricht.
- **J4** Local-only ist im Modell eine Eigenschaft der Zerlegung, nicht der Daten: Dieselben Beobachtungen ergeben
  kollaborativ `:remote-context`, lokal `:not-found`. In HyperDoc fehlt eine solche Sperre derzeit auf Auflöserebene (H3).
- **J5** Vorbereitung (Fork) und Auflösung sind getrennte Aufgaben; Local-only-Auflösung forkt nie selbst
  (Mutante „forkt statt den Fehlschlag zu melden“ wird erkannt).

## 6. Offene Modellentscheidungen

1. **Genügt eine vorhandene, überprüfbare lokale Kopie für einen Fork, ohne die ursprüngliche Remote-Site erneut zu
   kontaktieren?** Im Modell ist das die ausdrückliche Tatsache `(fork-source-policy …)`: `verified-copy-suffices` (Quelle
   `(verified-copy copy remote slug)`) oder `require-remote-confirmation` (Quelle: beobachtetes `page-available` der
   Remote-Site). Ohne Politik wird kein Fork geplant. Beide Richtungen sind getestet; die Entscheidung bleibt bei Dir.
   Hintergrund: Die Fork-Aktion im Journal nennt die Quell-Site (Zettel-11483-Bericht); PR #29 und PR #30 entsprechen je
   einer der beiden Politiken. Offen ist auch, was „überprüfbar“ heißt (Digest, Journal, Signatur).
2. **Eigene Site in Local-only**: Javas `origin` (Heimat des Lesers) oder das Wiki der Seite (HyperDoc)? Das Modell nimmt `origin`.
3. **Item-Site und `attribution.site`** in HyperDoc: an Java angleichen oder als Absicht dokumentieren?
4. **Lokale Auflösung in HyperDoc**: `local-fedwiki` kontaktiert beim Laden und beim Auflösen das Netz (H3). Ein
   Local-only-Resolver müsste `get-plugin-page` und die Kontextschleife sperren; hier nicht geändert.
5. **Netzwerkfehler**: abbrechen (Java) oder weitersuchen?
6. **SiteMap-Suche** der Java-Roadmap ist nicht implementiert und nicht modelliert; HyperDocs SiteMap-Prüfung ist eine andere Sache.
7. **Nur der erste Link eines Items** (Java) — für eine Defederation mit allen Links einer Site nicht ausreichend.

## 7. Reproduktion

```sh
# Java-Referenz (braucht JDK 11+, python3, unshare; ändert den fedwiki-java-Klon nicht):
python3 -I tests/fedwiki-java-reference/run-reference.py --fedwiki-java /pfad/zu/fedwiki-java
# Modell, Gegenproben, Mutanten, Nachbarsysteme, Inspector-Ansichten (Projekt-Registry, z. B. in nix develop):
sbcl --noinform --no-sysinit --no-userinit --non-interactive --load scripts/test-fedwiki-link-resolution.lisp
# HyperDoc-Vergleich (offline):
sbcl --noinform --no-sysinit --no-userinit --non-interactive --load docs/fedwiki-link-resolution/evidence/hyperdoc-comparison.lisp
```

In SLY getrennt auswerten: `(asdf:load-system "dreyeck/work/fedwiki-link-resolution")`, dann
`(asdf:test-system "dreyeck/work/fedwiki-link-resolution")`.

## 8. Ausgeführte Evidenz (7. November 2026)

Frische SBCL-2.4.10-Prozesse mit der Projekt-Laufzeit aus Nix, SHOP3 `ce53f9b`, eigener Netzwerk-Namespace ohne Netz,
leeres HOME, eigener FASL-Cache. Java: OpenJDK 21.0.12.1. Getestete Quelldateien und ihre sha256-Summen:
[evidence/manifest.txt](evidence/manifest.txt).

- [evidence/test-run.log](evidence/test-run.log): `FEDWIKI-LINK-RESOLUTION-PASS` (13 Szenarien, 8 Gegenproben und
  Unterscheidungen, 14 Mutanten erkannt, Kontrolle bestanden); Nachbarn `dreyeck/work/defederation-planning/tests`
  (PR #29), `dreyeck/work/planning/tests`, `dreyeck/work/remote-control-planning/tests` bestanden; kein Catalog-Mitglied
  hinzugefügt, `shop3:*domain*` unverändert; vier Inspector-Fälle gerendert.
- Basis ohne diese Änderung: Dieselben drei Nachbarsysteme bestanden auf dem unveränderten `ecb2b8b` im unabhängigen
  Review vom 7. November 2026 [obs, dort].
- [evidence/hyperdoc-comparison.log](evidence/hyperdoc-comparison.log), [evidence/java-reference-run.txt](evidence/java-reference-run.txt).

Nicht ausgeführt: Live-SLY/CLOG, eine Lisp-Critic-Engine, die Nix-Prüfung `checks.<system>.catalog` (das System ist opt-in
und nicht Teil des Catalogs), Netzläufe gegen echte Wikis.
