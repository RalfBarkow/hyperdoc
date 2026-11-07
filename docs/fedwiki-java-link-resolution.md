# Linkauflösung aus fedwiki-java und zwei SHOP3-Politiken

## Quellenortung vor der Implementierung

Zettel 11483 und 11560. Verifiziert am 7. November 2026:

- Java: `RalfBarkow/fedwiki-java`, `b58fb43e7ffbbbda66685363dcda1facbd2a46a1`.
- HyperDoc-Remote `dreyeck.ch`: `00d2a18bbc9cbd2045454ce8f9c4af8d8b58e60a`.
- Neue Branchbasis: PR #29, `ecb2b8b576bd1cdfd080899b3946651f22dfe345`.
  Die im Auftrag mitgeteilte unabhängige Review-Präferenz ist eine externe
  Beurteilung, keine hier ausgeführte Critic Rule.
- Vergleich PR #30: `38c7ece3de4e0abbb20c8d2ba918ac8a5a3420da`.

Die beiden bisherigen Implementierungen bleiben unverändert. Die folgenden
Phase-1-/Phase-2-Befunde wurden vor dem neuen Modell dokumentiert. Die
Referenzimplementation beschreibt beobachtbares Verhalten; sie wird nicht
zur normativen Definition des Federated-Wiki-Verhaltens erklärt.

## Phase 1: Tatsächliche Java-Semantik

Alle Java-Links fixieren dieselbe Revision:
[Main.java](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java),
[README](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/README.md),
[input.txt](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/input.txt),
[output.txt](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/output.txt).

| Schritt / Quelle | Zustand, Reihenfolge und beobachtete Wirkung |
| --- | --- |
| [Page.context, L289–295](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L289-L295) | Journal rückwärts durchlaufen, nicht-null `Action.site` ohne Duplikate aufnehmen. Die letzte Erwähnung steht zuerst, unabhängig vom Action-Typ. `attribution.site` wird nicht gelesen. Jeder Aufruf liefert eine neue Liste. |
| [Panel.context, L266–273](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L266-L273) | Kontext der aktuellen Page; falls die aktuelle Panel-Site nicht Origin ist, diese Site entfernen und vorne einfügen. |
| [Panel.load(from, slug), L225–255](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L225-L255) | Ausgangspunkt ist das aktuelle Panel mit `itemno`, nicht irgendein Item der Page. Nicht-null `from.item().site` wird im Kontext nach vorne verschoben. **Danach beginnt die Suche trotzdem bei `origin`.** Erst nach einem Miss werden die Kontext-Sites der Reihe nach verbraucht. Origin kann dadurch zweimal versucht werden, falls es im Kontext vorkommt. |
| [Erfolg, L236–243](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L236-L243) | Erstes nicht-null Page-Ergebnis gewinnt. Neues Panel mit gefundener Site, Slug und `itemno=0`. Aus dessen Panel-Kontext (Page-Journal plus erfolgreiche Remote-Panel-Site) werden Neighborhood-Sitemaps geladen; das erste Story-Item der gefundenen Page wird dabei nicht als zusätzlicher Suchkontext herangezogen. |
| [Panel.load(site, slug), L216–223](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L216-L223) | Ein einzelner expliziter Ort, kein Kontext-Fallback und kein `enlarge` in dieser Überladung. Null-Page beendet den Prozess. |
| [Item.links, L307–319](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L307-L319) | Nur der erste `[[…]]`-Treffer im aktuellen `text`. Whitespace durch `-` ersetzen, außerhalb ASCII-Buchstaben/Ziffern/Bindestrich entfernen, mit Default-Locale kleinschreiben. Kein Link ergibt leere Liste; `Panel.link().get(0)` scheitert dann, ohne freundlichen Resolver-Fallback. Ein Reference-Item mit nur `slug`/`site` und ohne Textlink liefert hier keinen Link. |
| [fetch, L143–165](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L143-L165) | HTTP GET mit User-Agent und HTTP/1.1. Nur Status **200** wird als Page geparst. Jeder andere Status ergibt null, einschließlich 403/500: fehlgeschlagener Abruf, keine sichere ontologische Aussage über die Seitenexistenz. URI-, IO- und Interrupted-Fehler rufen `trouble` auf und beenden mit Exit 1. JSON-Parsing-Fehler sind IO-Fehler. Kein Retry/Timeout konfiguriert; nicht jeder Runtime-Fehler ist gefangen. |
| [enlarge/fetchSiteMap, L167–199](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L167-L199) | Nur bisher unbekannte Site-Keys laden `/system/sitemap.json`. Auch null nach HTTP-Miss wird als Mapwert gespeichert; `containsKey` verhindert dann einen erneuten Versuch. Netzwerk-/JSON-Fehler beenden den Prozess. Eine Sitemap kann also die nachfolgende erfolgreiche Linkoperation noch abbrechen. |
| [Main.main/link/back, L49–68,104–111,132–140](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/Main.java#L49-L68) | Start: `enlarge(origin)`, explizite Welcome-Page, Lineup ein Panel. `link` hängt erst nach Rückkehr von `load` an. Bei Abruch während `load/enlarge` wird kein neues Panel angehängt. `back` entfernt Panels, aber keine Neighborhood-Einträge. Der Shell-Runner übergibt ohne Argument einen leeren Origin-String; README-Aufruf und Java-Default sind darum nicht gleichbedeutend. |

Die TODO-Liste ist keine Implementierungsbeschreibung:
[README L35–40](https://github.com/RalfBarkow/fedwiki-java/blob/b58fb43e7ffbbbda66685363dcda1facbd2a46a1/README.md#L35-L40)
führt Neighborhood-Akkumulation noch als Roadmap, obwohl `enlarge` sie bereits
implementiert. **Sitemap-Suche bleibt tatsächlich unimplementiert**: kein
Suchpfad verwendet `SiteMap.infos` zur Kandidatenwahl.

`input.txt` ist ein CLI-Skript mit Navigation und Textassertionen, keine
netzwerkfreie Fixture. `output.txt` ist ein historisches Transkript mit
Remote-Treffern (etwa `Constructionism` und `Tips for Modeling`), aber ohne
fixierte HTTP-Antworten. Es zeigt außerdem nicht alle heutigen Logzeilen
(`Reading SiteMap`, `location`). Es wird als historische Evidenz gelesen,
nicht als frisch reproduziertes Golden File ausgegeben. Das Skript wurde
nicht gegen öffentliche Wiki-Sites abgespielt.

## Phase 2: Vergleich vor Änderungen

HyperDoc-Links fixieren die gewählte Branchbasis:
[wiki-links.lisp](https://github.com/RalfBarkow/hyperdoc/blob/ecb2b8b576bd1cdfd080899b3946651f22dfe345/hyperbook-fedwiki/wiki-links.lisp),
[pages.lisp](https://github.com/RalfBarkow/hyperdoc/blob/ecb2b8b576bd1cdfd080899b3946651f22dfe345/hyperbook-fedwiki/pages.lisp),
[story-items.lisp](https://github.com/RalfBarkow/hyperdoc/blob/ecb2b8b576bd1cdfd080899b3946651f22dfe345/hyperbook-fedwiki/story-items.lisp),
[local-fedwiki-page.lisp](https://github.com/RalfBarkow/hyperdoc/blob/ecb2b8b576bd1cdfd080899b3946651f22dfe345/dreyeck/src/local-fedwiki-page.lisp),
[PR-29-Domäne](https://github.com/RalfBarkow/hyperdoc/blob/ecb2b8b576bd1cdfd080899b3946651f22dfe345/dreyeck/work/defederation-planning.lisp),
[PR-30-Domäne](https://github.com/RalfBarkow/hyperdoc/blob/38c7ece3de4e0abbb20c8d2ba918ac8a5a3420da/dreyeck/work/defederation-planning.lisp).

| Kategorie | Gegenüberstellung / Grenze des Befunds |
| --- | --- |
| Identisch | Journal-Site-Strings werden nach letzter Erwähnung geordnet und dedupliziert. `pages.lisp:context-site-references` erreicht dies durch Vorwärtsschleife mit Entfernen/Voranstellen. Beide Resolver bevorzugen zunächst ihre lokale Ausgangs-Site und stoppen beim ersten Treffer. |
| Bewusst unterschiedliche Abstraktion | Java startet bei globalem Origin und besitzt Panel-/Item-Zustand. HyperDocs `lookup-slug-in-page-context` startet beim HyperBook der Quellpage, versucht anschließend Plugin-Page und dann Page-Kontext. Eine Item-Site ist dort kein Argument. Remote-Wrapping bewahrt die lokale HyperBook-Zuordnung; die Remote-Origin wird zum Page-Kontext hinzugefügt. |
| Bewusste Erweiterung | HyperDoc berücksichtigt zusätzlich `attribution.site`, wenn direktes `site` fehlt. Seine Reference-Story-Items können Site/Slug direkt verlinken; Java `Item.links` wertet ausschließlich den ersten Textlink aus. HyperDoc extrahiert mehrere Textlinks. Ein pauschales Urteil „Reference-Kontext fehlt“ wäre daher falsch: die Pfade haben unterschiedliche Eingänge. |
| Unterschiedlicher Treffernachweis | HyperDocs [find-page](https://github.com/RalfBarkow/hyperdoc/blob/ecb2b8b576bd1cdfd080899b3946651f22dfe345/hyperbook-fedwiki/fedwiki.lisp#L234-L240) wartet auf die Sitemap und sucht Page-Skelette im Cache. Das ist keine Java-artige HTTP-200-Prüfung des Ziel-JSON bei jedem Kandidaten. Story-Daten werden später geladen. Die in der README noch offene Java-Sitemap-Suche darf daher nicht mit HyperDocs vorhandener Sitemap-Projektion gleichgesetzt werden. |
| Mögliche unbeabsichtigte Abweichung | Java dedupliziert vor dem Voranstellen der Panel-Site; HyperDoc `reload-page` pusht die Origin ohne solche Deduplikation. Welche Duplikate praktisch relevant sind, muss an konkreten Pages geprüft werden. Locale-/Unicode-Details des Sluggings und Cache-/Sitemap-Verfügbarkeit können Treffer ebenfalls unterscheiden. Ähnliche Namen allein belegen keine semantische Gleichheit. |
| Local-only | `local-fedwiki:find-page` liest ausschließlich lokalen Speicher. Der darüberliegende normale Linkresolver kann trotzdem Plugin-/Remote-Fallback ausführen. Ein lokaler Page-Provider allein ist daher noch kein Nachweis einer deföderierten Linkpolitik. |
| PR #29 | Vorbereitung eines Einzelziels, nicht die Java-Kandidatensuche. Trennt `local-page` und `modeled-local-page`; beobachtete Abwesenheit bleibt nach hypothetischem Fork erhalten. Gute Ausgangsabstraktion für den neuen Slice. |
| PR #30 | Ebenfalls Vorbereitung eines Einzelziels; trennt zusätzliche Remote-Nachweise. Sein simulierter Fork löscht lokale Abwesenheit und setzt `local-page`. Für den hier geforderten Vergleich muss modellierte Präsenz ausdrücklich separat bleiben. Diese Beobachtung ändert PR #30 nicht. |
| Nicht belegt | Keines der beiden bisherigen Modelle begründet Kandidatenreihenfolge, HTTP-Verhalten, Lineup/Neighborhood oder eine erneut erforderliche Remote-Verbindung beim Fork. Keine vorhandene Regel wird deshalb stillschweigend als vollständige FedWiki-Spezifikation übernommen. |

## Offene Modellentscheidung vor Phase 3

Ob eine überprüfte lokale Kopie für einen Fork genügt, bleibt als explizite
Politik sichtbar: `:cached-copy-sufficient` versus `:require-remote-evidence`.
Auch die zweite Variante plant nur anhand bereits vorliegender Nachweise;
sie kontaktiert keine Remote-Site. Ohne gewählte Politik entsteht daraus kein
Fork-Plan. Ein HTTP-500-Miss wird nicht als bestätigte lokale Abwesenheit
verwendet, obwohl Java damit den nächsten Kandidaten versucht.

## Phase 3: Modell und Grenzen

Optionales System: `dreyeck/work/link-resolution`. Es lädt keine der alten
Defederationsdomänen und verwendet den vorhandenen echten SHOP3-Runner.
`plan-resolution` bewahrt alle vier FIND-PLANS-Werte in
`hyperdoc-htn-plan-result`: Rohpläne, verkürzte Pläne, Planbäume, Endzustände
und Zeit. `:which :all` sucht alle Lösungen. Keine vollständige Lösung ist
etwas anderes als eine ausgeführte Aktion; immer gilt `:plan-only` und
`:execution :not-executed`.

`candidate-context` rekonstruiert ausschließlich die geordnete Datenliste:
Journal zuletzt-genannt-zuerst → Panel-Site vorziehen → aktuelle Item-Site
vorziehen → Origin davor setzen. Diese Liste ist für beide Politiken gleich.
Die Methoden entscheiden anhand des Zustands:

- `observed-hit`: positive Präsenz und eine zulässige Kandidaten-Site.
- `hypothetical-local-hit`: getrennte `modeled-local-page`, niemals eine
  neu behauptete Beobachtung. Sie gilt ausschließlich für die Origin-Site.
- `next-after-proven-miss`: bestätigte Abwesenheit oder positiv beobachteter
  HTTP-Non-200; erst dann wird rekursiv die restliche Liste bearbeitet.
  Ein früher Treffer kann nicht zugunsten eines späteren übersprungen werden.
  Fehlende Evidenz und bekannte Netzwerkfehler berechtigen nicht zum Weitergehen.
- `allowed`: Collaborative lässt alle Kandidaten zu; Local-only verlangt
  Gleichheit mit Origin. Dieses Gate liegt im SHOP3-Modell und wird nicht
  schon durch einen Host-Helper redundant vorweggenommen.

Externe Beobachtungen sind `page-present`, `page-absent`, `http-miss` und
`network-failed`. Ein fehlender Fakt erzeugt keinen gegenteiligen Fakt.
HTTP-500 ist explizit ein Miss des Abrufs, keine `page-absent`-Beobachtung.
Die Negation modellinterner Fakten wie `modeled-local-page` steuert dagegen,
ob bereits ein hypothetischer Übergang stattgefunden hat. Widersprüchliche
Präsenz-/Abwesenheitsbefunde sperren den Plan.

`prepare-local-target` bietet getrennte Methoden für beobachtete Präsenz,
schon modellierte Präsenz und einen explizit erlaubten Fork. Der Fork benötigt
bestätigte lokale Abwesenheit, Fork-Erlaubnis, eine als überprüft modellierte
lokale Kopie und eine gewählte Fork-Quellenpolitik. Er fügt ausschließlich
`modeled-local-page` und `modeled-fork` hinzu. Beobachtungen werden weder
gelöscht noch durch simulierte Beobachtungen ersetzt. Die Fixture-Snapshot-ID
`:sha256-fixture` ist ein synthetischer Nachweisparameter, kein behaupteter
Digest einer realen Wiki-Seite.

Zwei Aufgaben im selben Plan teilen den hypothetischen Zustand. Aus dessen
Endzustand erneut zu planen erzeugt keinen weiteren Fork. Ein unabhängiger
Suchlauf mit unveränderten ursprünglichen Befunden beschreibt dagegen erneut
dieselbe hypothetische Vorbereitung; er behauptet keine persistierte Ausführung.

Bewusste Begrenzung: Der kleine Slice plant Zielwahl/Vorbereitung für einen
Origin-/Ziel-Koordinatenfall. Er ist kein vollständiger Java-Interpreter.
Lineup- und Neighborhood-Effekte werden an der Referenz beobachtet, aber nicht
als HTN-UI- oder Transport-Simulator nachgebaut. Insbesondere ein nach dem
Treffer abbrechender Sitemap-Ladevorgang wird hier nicht als erfolgreich
ausgeführtes `Panel.load` behauptet. Ebenso werden keine Renderer geändert;
die Paragraph-only-Vorbereitung aus PR #29 bleibt ein eigener Vergleichsgegenstand.
Antwortbefunde gelten pro Site/Ziel für den gesamten Plan; zeitlich wechselnde
Antworten bei Wiederholungen und Cache-Frische sind nicht modelliert.

## Phase 4: Ausgeführte Gegenproben

Die gemeinsame [Fixture-Datei](../dreyeck/tests/fixtures/link-resolution/cases.json)
enthält 13 Fälle. 12 werden mit Java ausgeführt; der Fall mit unbekanntem
früherem Kandidaten hat absichtlich keine vollständige Transportantwort.
Der Adapter würde eine nicht deklarierte Antwort als Fehler behandeln,
niemals stillschweigend als HTTP-404.

[Java-Test](../scripts/test-fedwiki-java-reference.py) kompiliert `Main.java`
und die drei Jackson-2.14.2-Jars aus den fixierten Git-Blobs. Vorhandene
`.class`-Dateien werden nicht benutzt. Im temporären Testverzeichnis werden
**nur zwei HttpClient-Fabriken** durch den deterministischen Adapter ersetzt:
[exakter Patch](fedwiki-java-link-resolution-evidence/java-transport.patch).
Die originalen Methoden `Page.context`, `Panel.context`, beide `Panel.load`,
`Item.links`, `Main.fetch`, `fetchSiteMap`, `link` und `enlarge` werden ausgeführt.
Private Panel-Methoden werden per Reflection angesprochen. Das ist eine
offengelegte Transportadaption, kein byteidentischer Ganzprogramm-Lauf und
keine unabhängige Portierung des Resolvers. Es werden keine Sockets geöffnet.
Der Harness beginnt mit einem expliziten Quellpanel, ausgewähltem Item und
leerer Neighborhood. Er führt nicht `Main.main` oder das öffentliche
`input.txt` aus. Das normale Programm hätte beim Start bereits Origin über
`enlarge` aufgenommen; die abweichende Test-Anfangslage ist in der Evidenz benannt.

Die [aufgezeichnete Java-Evidenz](fedwiki-java-link-resolution-evidence/java.json)
hält Commit, Main.java-SHA-256, neun exakte Quellpassagen samt Digests, Zustände,
Versuchsreihenfolge, Exit-Code, Lineup-Größe und Neighborhood/Sitemap-Zugriffe.
Java 21.0.12.1 mit dem vorhandenen Compiler-Modul, SBCL 2.4.10 und SHOP3 4.3.1
(`ce53f9b651acde8c44dc21eddb1a1c5b97f10536` aus `flake.lock`) wurden verwendet.

| Gegenprobe | Ergebnis |
| --- | --- |
| Lokal vorhanden trotz Remote-/Item-Kontext | Origin gewinnt in Java und Collaborative SHOP3; Local-only ebenfalls lokal. |
| Zwei verfügbare Remotes | Bei Journal `[a,b]` gewinnt `b`; keine Alternative überspringt diesen Treffer. |
| Item-Site `a` | Nach lokalem Miss gewinnt `a` vor `b`. Auch ein ausgewähltes zweites Story-Item (`itemno=1`) wird korrekt berücksichtigt; der Ziel-Panelindex wird wieder 0. |
| Journal `[b,a]` | `a` gewinnt; mehrfaches `a` im Journal verschmilzt nach jüngster Position. |
| Aktuelle Remote-Panel-Site | Wird vor den Journal-Kontext gestellt; Origin bleibt erster Versuch. |
| Origin selbst als Item-Site | Der lokal fehlgeschlagene Origin wird im Kontext nochmals versucht; kein stilles globales Deduplizieren. |
| Local-only | Jeder nichtlokale Fallback wird verweigert, obwohl die vollständige Kandidatenliste vorliegt. |
| Fork und Wiederplanung | Ein Fork für zwei Aufgaben; null zusätzliche Forks beim Weiterplanen aus dem simulierten Endzustand. Beide Resultate tragen `:modeled`; `page-present` wird nicht hinzugefügt. |
| Fehlender Fork-Nachweis | Fehlende Kopie, Erlaubnis, explizite lokale Abwesenheit oder gewählte Quellenpolitik liefern keinen vollständigen Vorbereitungsplan. |
| Kopie genügt / Remote-Nachweis nötig | Unter `:cached-copy-sufficient` reicht die modellierte überprüfte Kopie. Unter `:require-remote-evidence` muss zusätzlich positive Remote-Präsenz gegeben sein. Ohne sie kein Plan; mit ihr wieder ein Plan. Keine Variante macht eine Netzwerkanfrage. |
| Bekannte vollständige Abwesenheit | Keine vollständige Lösung; der Kontext zeigt überall `:observed-absent`. Java beendet mit „can't find page in current context“. |
| Unbekanntes `b` vor bekanntem Treffer `a` | Kein Plan. Ein zusätzlich gelieferter Abwesenheitsnachweis für `b` ermöglicht den Treffer `a`. Das ist keine Aussage, das Ziel sei nicht vorhanden. |
| HTTP 500 / IO-Fehler | Java und Collaborative unterscheiden Fallback nach 500 von Prozessabbruch nach IO-Fehler. 500 allein berechtigt nicht zur Fork-Vorbereitung. Die Java-Fehlermeldung und das Ausbleiben eines Lineup-Anhangs werden geprüft. |
| Neighborhood | Zwei Linkaufrufe erweitern Lineup zweimal, laden jede der drei betreffenden Sitemaps aber nur einmal. Auch drei HTTP-404-Sitemap-Ergebnisse bleiben als null-Werte gecacht. |
| Locale | Der tatsächliche Java-Slugger liefert für `[[I Ä]]` unter Englisch `i-`, unter Türkisch `ı-`. Die ASCII-Filterung liegt vor der Locale-Kleinschreibung. Dieser Befund wird nicht durch eine Korrektur am Referenzcode versteckt. |

Die [SHOP3-Suite](../dreyeck/tests/link-resolution.lisp) führt 39 benannte
Akzeptanzabfragen plus zwei Mutantenabfragen aus. Erfolgreiche Collaborative-
Pläne werden gegen die tatsächlichen Java-Versuchsfolgen verglichen.

- Ein Kandidaten-Mutant kehrt die Fallbackliste des tatsächlich benutzten
  Host-Helpers temporär um. Dieselbe Fixture erwartet `b`, der Mutant liefert
  `a`. Die Akzeptanzbedingung weist ihn zurück; der Helper wird wiederhergestellt.
- Ein isolierter SHOP3-Domänen-Mutant weicht nur das Local-only-Gate auf.
  Statt Verweigerung liefert er einen Remote-Plan. Dieselbe Akzeptanzbedingung
  weist ihn zurück. Die normale Domäne und die alten PR-Domänen bleiben unverändert.

Alle Suchen verwenden `:which :all`; Rohpläne, Bäume und Endzustände stimmen
in ihrer Anzahl überein. Die Tests bestätigen außerdem unveränderte
Eingabefakten und erhaltene Beobachtungen in jedem simulierten Endzustand.
Der tatsächliche HyperDoc-Helper `context-site-references` wird zusätzlich
ohne Site-Proxys auf den zwölf direkten Journal-Fixtures ausgeführt; seine
Ergebnisse stimmen mit den aufgezeichneten Java-Page-Kontexten überein.

Sechs vorhandene Suites bestanden jeweils in frischen Prozessen sowohl auf
dem unveränderten PR-29-Basischeckout als auch auf dem Feature-Stand:
`dreyeck/work/defederation-planning/tests`, `dreyeck/work/planning/tests`,
`dreyeck/work/remote-control-planning/tests`, `hyperbook/fedwiki/tests`,
`dreyeck/local-fedwiki-page/tests`, `dreyeck/lisp-critic/recorded/tests`.
Kein Basisfehler wurde dabei beobachtet. Das ist keine Behauptung über sämtliche
weiteren Repository-Suites oder die nicht verfügbare historische Engine-Integration.

Ausgaben: [Java](fedwiki-java-link-resolution-evidence/java-tests.log),
[SHOP3/Inspector](fedwiki-java-link-resolution-evidence/shop3-tests.log),
[Basis](fedwiki-java-link-resolution-evidence/baseline-tests.log),
[Regressionen](fedwiki-java-link-resolution-evidence/regressions.log).
Vollständige Prozessausgaben, nur Leerzeichen am Zeilenende entfernt.

## Phase 5: Evaluation Records und Inspector

Optional: `dreyeck/work/link-resolution/reading`. Seine `resolution-evaluation`
implementiert das vorhandene `dreyeck/evaluation-record`-Protokoll. Sie führt
SHOP3 tatsächlich aus, vergleicht die Zielwahl und bewahrt das originale
`hyperdoc-htn-plan-result`. Eine abgeschlossene Prüfung mit negativem Urteil
ist nicht dasselbe wie eine durch Condition fehlgeschlagene Prüfung.

| Beziehung | Inspizierbare Evidenz |
| --- | --- |
| Java-Quelltext → Beobachtung | Fixierter Commit, vollständiger Quelltext-Digest, neun Quellpassagen und protokollierte Java-Tests im gemeinsamen Referenzobjekt. |
| Beobachtung → SHOP3-Regel | Der Record verweist auf die tatsächlich registrierten `search-sites`-Methodendefinitionen. Das sind HTN-Methoden, keine Lisp-Critic-Regeln. |
| Regel → Gegenprobe → Evaluation Record | 26 frisch ausgeführte Model-Evaluationen über 13 Fixtures × zwei Politiken. Source-/Methoden-/Planverweise werden mit `EQ` geprüft. Die Reading-Seite materialisiert dieselben gecachten Objekte. |
| Java-Beobachtung versus Gegenentwurf | Das Evidence-Protokoll unterscheidet `:source-derived-collaborative-search` und `:counterfactual-local-policy`. Für die unvollständige Fixture existiert ausdrücklich keine Java-Fallbeobachtung. |
| Plan → Zustand | Originale Pläne, native Planbäume und hypothetische Endzustände im vorhandenen Ergebnisobjekt. Kein Wiki-Executor. |
| Historische Critique | Separater Link auf `dreyeck/lisp-critic/recorded:setf-push-recorded-example`, unverändert an der ursprünglichen Workflow-Quelle. Keine Zuschreibung zum neuen Modell. |

Es wird keine neue Lisp-Critic-Engine entwickelt oder ausgeführt. Die
authentische Beane-Station ist hier nach Auskunft des Auftraggebers nicht
nachweislich verfügbar; ein kompatibel erscheinender Mirror wird nicht als
Ersatz benutzt. `:cloud-engine-status :engine-unavailable` und
`:live-lisp-critic :not-invoked` machen die Grenze explizit. Die historischen
JSON-Records und ihre gespeicherten Digests werden nicht überschrieben.

**Judgement (Codex, Quelleninterpretation; keine Engine Critique):** Die
getestete Zustandswahl rekonstruiert den geordneten Suchkern unter gegebenen
Antwortnachweisen. Sie belegt weder die Verfügbarkeit realer Seiten noch die
Angemessenheit von Wards Vorschlag. Basis sind die zitierten Quellpassagen,
die Java-Protokolle und die zwei gezielt widerlegten Mutanten. Die im Auftrag
mitgeteilte Präferenz eines unabhängigen Reviews für PR #29 bleibt separat
dieser mitgeteilten Herkunft zugeordnet.

## Reproduktion und Handoff

Mit einer lokalen Referenzkopie und registrierter HyperDoc-Dependency-Closure:

```sh
FEDWIKI_JAVA_ROOT=/absolute/path/to/fedwiki-java \
  python3 scripts/test-fedwiki-java-reference.py \
  docs/fedwiki-java-link-resolution-evidence/java.json
sbcl --no-sysinit --no-userinit --non-interactive \
  --load scripts/test-link-resolution.lisp
```

Die Java-Quelle/Jars werden mit `git show` am fixierten Commit gelesen; der
ausgecheckte Branch und dort eventuell geänderte Dateien sind keine Autorität.
JDK 11+ mit Compiler-Modul ist erforderlich (`java -m jdk.compiler/com.sun.tools.javac.Main`).
Es werden temporäre Builddateien geschrieben, aber weder öffentliche Sites
kontaktiert noch Referenzrepository-/Wiki-Dateien geändert. Die gespeicherte
Java-Evidenz genügt für einen rein lokalen SHOP3-/Inspector-Testlauf.

Cloud-Befehl für Lisp: der bereits vorhandene relocatierte Nix-Launcher
`/workspace/scratch/defederation-tools/run.py --load scripts/test-link-resolution.lisp`
mit `DEFEDERATION_TEST_ROOT=/workspace/scratch/hyperdoc-link-resolution`.
Die ASDF-Registry und der FASL-Cache sind getrennt vom menschlichen SLY-Image.

In SLY, ohne Laden einer alten Defederationsdomäne oder der Critic-Engine:

```lisp
(asdf:load-system "dreyeck/work/link-resolution/reading")
(defparameter *link-evaluation*
  (dreyeck/work/link-resolution/evidence:evaluate-fixture "item-order" :collaborative))
(dreyeck/evaluation-record:evaluation-result-of *link-evaluation*)
(clog-moldable-inspector:clog-inspect :object *link-evaluation*)
```

Erwartet: `:completed`, `:matches-expected T`, Ziel `:a`. Die View
„Resolution evaluation“ führt zu Quellpassagen/Java-Beobachtungen, echten
HTN-Methoden, Kontext und dem ursprünglichen Plan-Ergebnis. Dort native
Planbäume und Endzustände öffnen. Für den lokalen Gegenentwurf denselben
Fall mit `:local-only` evaluieren: abgeschlossene Prüfung, korrekt keine
vollständige Auflösung. Alle initialen Befunde bleiben sichtbar.

Das opt-in-HyperBook ist ein zweiter Einstieg:

```lisp
(clog-moldable-inspector:clog-inspect
 :object dreyeck/work/link-resolution/evidence:*link-resolution-book*)
```

Ein nachweisbar hypothetischer Fork mit zwei Aufgaben lässt sich separat binden:

```lisp
(defparameter *hypothetical-fork-plan*
  (dreyeck/work/link-resolution:plan-resolution
   '((dreyeck/work/link-resolution::page-absent :origin :target)
     (dreyeck/work/link-resolution::verified-copy :a :target :sha256-fixture)
     (dreyeck/work/link-resolution::fork-permitted :origin :target)
     (dreyeck/work/link-resolution::fork-source-policy :cached-copy-sufficient))
   '(:origin :a) :policy :local-only :prepare t :repeat 2))
(clog-moldable-inspector:clog-inspect :object *hypothetical-fork-plan*)
```

Erwartet: ein `!prepare-fork`, zwei `!record-resolution` mit `:modeled`, erhaltene
`page-absent`-Beobachtung und keine hinzugefügte `page-present`-Beobachtung.
Für den unabhängigen Review Plan-/Zustandsobjekte, Eval-Status, Referenzen und
Conditions zurückgeben. Es wird kein bestehendes SLY-Live-Image als geprüft behauptet.

Offen bleiben insbesondere die Aktualitäts-/Integritätsanforderungen an eine
lokale Kopie und die zusätzliche Remote-Evidenz. `:require-remote-evidence`
prüft modellierte Präsenz, keine Aktualität oder erneute Hash-Gleichheit.
Die Entscheidung, ob ein erneuter Kontakt nötig ist, wird nicht aus Java
hergeleitet und nicht durch den Fixture-Erfolg normativ entschieden.

Delta: ein neuer optionaler Planungs-/Reading-Slice mit reproduzierbarer
Quellen- und Testevidenz. PR #29 und #30, produktive Resolver/Renderer und
Wiki-Daten bleiben unverändert. Kein Merge, Deployment oder Dienstneustart.
