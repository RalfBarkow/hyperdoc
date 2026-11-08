# FedWiki Local-only: lokaler Runtime- und Planungseinstieg

Zettel 11560 / 11483. Neuer Branch `codex/fedwiki-local-only-integration` ab
PR #34, `4e76e9aff910e9da45c1fe9252e528669c2683fb`. Repository, sauberer
Arbeitsbaum und tatsächlicher PR-Head wurden vor Änderungen geprüft.
Der [Integrationsreview](../fedwiki-link-resolution-integration/review/README.md)
wurde gelesen. PR #29–#34 werden nicht verändert.

## Wiederverwendung und kleinster Integrationspunkt

Optionales ASDF-System: `dreyeck/work/fedwiki-local-only`, Tests: `/tests`.

- PR #33 bleibt unverändert die einzige Fork-Autorität:
  [defederation-planning.lisp](../../dreyeck/work/defederation-planning.lisp).
  `prepare-link` und `continue-preparation` rufen dessen `plan-defederation` auf.
- [local-only-resolution.lisp](../../dreyeck/work/local-only-resolution.lisp)
  extrahiert ausschließlich Kandidatenfunktionen, Auflösungsmethoden und deren
  Operatoren aus [PR #32 bei e1ab2f5](https://github.com/RalfBarkow/hyperdoc/blob/e1ab2f570ee793e301c5af706cbcf2fc984c02a9/dreyeck/work/fedwiki-link-resolution.lisp).
  Keine `fork-source-ok`-Axiome, kein `!plan-fork`, kein `prepare-local-target`.
  Anpassungen: expliziter `own-site`-Fakt und entsprechende Herkunftsbezeichnung
  statt Java-Origin für Local-only; modellierte Kandidaten ausschließlich an
  dieser Site. Die Java-Ordnungsfunktionen bleiben unverändert.
- Vorbereitung und Auflösung sind zwei SHOP3-Suchen mit ihren eigenen originalen
  `hyperdoc-htn-plan-result`-Objekten. Nur ein verifiziert zugeordnetes Ergebnis
  der Vorbereitung darf eine hypothetische lokale Präsenz an die Auflösung liefern.
  Dies ist keine dritte Fork-Domäne und kein zusätzlicher HTN-Interpreter.
- Bestehende `local-fedwiki`, `local-fedwiki-page`, `story-item`, `wiki-link`,
  `local-fedwiki-page-source` mit SHA-256 und Inspector-Views werden verwendet.

Zwei kleine Erweiterungsstellen im bestehenden Runtime-Code:
`set-page-data` erhält einen optionalen `context-resolver` (Default unverändert).
`lookup-slug-in-page-context` behält seinen Funktionsvertrag und delegiert an
`lookup-page-link`; dessen Standardmethode enthält den bisherigen Resolver.
Nur die opt-in-Unterklasse `own-page` verwendet einen lokalen Resolver.
Die bestehenden Local-FedWiki- und normalen kollaborativen Seiten werden nicht
umgestellt. Insbesondere wird nicht jede `local-fedwiki` pauschal als deföderiert behandelt.

## Explizite eigene Site und tatsächliches Lesen

`make-own-site(root, id)` erzeugt eine lokale Wiki-Instanz ohne Netzinitialisierung.
`observe-link` verlangt diese Instanz ausdrücklich. Die geladenen `own-page`-Objekte
speichern sie zusätzlich in einem eigenen Slot; der Local-only-Resolver liest
sie nicht aus Java-Origin oder einer Story-Item-Site ab.

Der Fixture-Vertrag setzt `own-site` auf die lokale Testinstanz `fedwiki:local`.
Für kollaborative Planung werden `reader-origin` und `panel-site` separat
angegeben. Ohne diese Angaben wird kein kollaborativer Plan erzeugt. Eine Probe
setzt bewusst `reader-origin="reader"` und `panel-site="panel"`: Local-only findet
weiterhin die lokale Zielseite, während die kollaborative Planung an der fehlenden
Reader-Evidenz scheitert. Dies entscheidet keine universelle FedWiki-Semantik.

Der tatsächliche Ladepfad liest JSON aus `pages/`, verwendet die vorhandenen
Story-/Journal-Konstruktoren und behält die Originaldaten. Er materialisiert
Journal-Sites **nicht** mittels `get-fedwiki`. Die Journal- und Item-Site-Referenzen
bleiben als Quelldaten für Kandidatenherkunft und Inspector erhalten.
Die echte `wiki-link`-Thunk-Auflösung dispatcht für `own-page` ausschließlich auf
`hb:find-page` der ausdrücklich gespeicherten eigenen Site. Sie ruft weder
`get-plugin-page` auf noch durchläuft sie Remote-Kontexte.

Die eigene Story-View zeigt die vorhandenen Items als escapten Quelltext mit
Objektverweisen. Sie aktiviert keine Plugins, Remote-Bilder oder Favicons und
bietet keinen Remote-Reload-Knopf. Das ist eine lokale Leseansicht, keine produktive
Paragraph-only-Renderer-Umstellung.

## Beobachtung, Herkunft und Eingangsgrenze

`observe-link` bindet Quellseite, ausgewähltes vorhandenes Story Item und dessen
ersten Wiki-Link. Unterstützte lokale Befunde:

| Befund | Nachweis | Planungsfakt |
| --- | --- | --- |
| Beobachtet lokal | Erfolgreicher lokaler Dateilesevorgang; Originalbytes, SHA-256 und JSON im vorhandenen Source-Objekt | `local-page` |
| Bestätigt lokal abwesend | Kein Dateieintrag am geprüften lokalen Slug-Pfad; Pfad und Beobachtungszeit festgehalten | `local-page-absent` |
| Unbekannt | Lokales Lesen/Parsen scheitert; Condition wird erhalten | Kein Präsenz-/Abwesenheitsfakt |
| Hypothetisch lokal | Passendes `modeled-local-page`/`modeled-fork`-Paar aus einem zugeordneten PR-33-Ergebnis | Nur interne Projektion in den Auflösungsplan |

HTTP-500, HTTP-302 und Transportfehler aus Zusatzbeobachtungen erzeugen niemals
`local-page-absent`. Die Auflösung kann damit gemäß PR #32 einen Miss beziehungsweise
Abbruch planen; die Fork-Vorbereitung braucht weiterhin bestätigte lokale Abwesenheit.
Die Miss-Repräsentation `page-unavailable ... :local-store-absent` bezeichnet den
lokalen Dateibefund und behauptet keinen tatsächlich empfangenen HTTP-404.

Zusätzliche Fakten stammen aus einer inerten JSON-Evidenzdatei. Ihr absoluter Pfad,
SHA-256 und die tatsächlich gelesenen Fakten bleiben am Beobachtungsobjekt.
Ein `remote-snapshot` muss außerdem zu einem Kopieneintrag mit Site, Slug, Pfad
und SHA-256 passen; die gespeicherten Kopienbytes werden vor Annahme geprüft.
Das belegt eine vorhandene lokale Kopie, keine gegenwärtige Remote-Erreichbarkeit.
Remote-Präsenz/Erlaubnis in dieser Datei bleiben ausdrücklich Aussagen der Fixture;
sie werden nicht durch einen Netzabruf verifiziert.

Die feste Liste zugelassener Prädikate besteht aus den Beobachtungen von #33 und
`page-available`, `page-unavailable`, `request-error` von #32. `local-page` und
`local-page-absent` dürfen im Integrationsslice ausschließlich aus der lokalen
Beobachtung kommen, nicht aus der Zusatzdatei. Importierte `modeled-*`, `planned-*`,
Vorbereitungsmarker, Kandidaten und Operatoren führen zu `invalid-observation`.
Eine optional übergebene Faktenliste muss zusätzlich exakt zur Evidenzdatei passen.
Unbekannte freie HTN-/Primitiv-Aufgaben sind keine API-Parameter.

`prepare-link` akzeptiert nur eine vom Slice erzeugte Beobachtung. Eine interne
Identitätsregistrierung prüft deren eingefrorene Fakten, Koordinaten und Herkunft.
`continue-preparation(observation, result)` verlangt genau ein hier erzeugtes und
zu dieser Beobachtung registriertes `hyperdoc-htn-plan-result`. Es prüft dessen
Endzustände gegen die bei Erzeugung festgehaltenen Kopien und liest dann selbst
den gewählten Endzustand. Es akzeptiert weder Faktenlisten noch fremde Planergebnisse
oder nachträglich veränderte Zustände. Alle Alternativen bleiben adressierbar über
`:index`. Veränderte Beobachtungsfakten werden ebenfalls abgewiesen.

Dies ist eine überprüfbare Zuordnung innerhalb dieses Lisp-Images, keine
kryptographische Autorisierung gegen beliebigen Lisp-Code, der private Registries
ändern könnte. Es ist auch kein Importformat für gespeicherte Fremdpläne. Die
Beobachtungen benennen einen Zeitpunkt/eine Revision; erneutes `observe-link` liest
die Dateien neu. Eine alte Beobachtung behauptet keine Aktualität nach Dateiänderungen.

## Ausgeführte Tests

[Integrationstest und native Pläne/Bäume/Endzustände](evidence/integration-tests.log):

- Lokaler Treffer; fehlender Slug; nur im Remote-Kontext vorhandenes Ziel.
- Quellseite mit zwei Journal-Sites und Item-Site wird tatsächlich lokal geladen.
- Echte HyperBook-Link-Thunks und direkter Runtime-Lookup: lokal erfolgreich,
  Remote-only verweigert. Kollaborativer SHOP3-Plan folgt
  `fedwiki:local → remote-item`; vollständige Kandidatenliste enthält danach
  `remote-new → remote-old`.
- Zwei Vorbereitungen planen genau einen Fork. Fortsetzung aus dem eigenen
  Ergebnis plant keinen weiteren Fork. Beobachtungen bleiben erhalten.
- Die anschließende hypothetische Auflösung verwendet `!use-modeled-page`.
  Ein erneutes reales Lesen findet weiterhin keine Datei; ohne übergebenes
  Vorbereitungsergebnis bleibt die Auflösung `:not-found`.
- 500, 302 und Transportbefund bei unbekannter lokaler Verfügbarkeit erlauben
  keinen Fork. Die unbekannte lokale Verfügbarkeit wird durch eine absichtlich
  ungültige Ziel-JSON-Datei reproduziert, nicht durch einen Netzversuch.
- Eingeschleuste modellierte Fakten, Marker, freie Aufgaben, nicht quellengedeckte
  Fakten, falscher Kopien-Digest, fremde/anders zugeordnete Ergebnisse sowie
  veränderte Endzustände und Beobachtungen werden abgewiesen.
- Inspector-HTML enthält dieselben Quell-, Item-, Link-, Evidenz-, Problem-,
  Ergebnis-, Endzustands- und Operationsobjekte (`EQ`), einschließlich älterer
  Pläne in der Beobachtungshistorie. Die vorhandene Standard-Slots-View bewahrt
  native Baum-/Zustandsreferenzen.

Der Netzwerk-Test ersetzt für seinen isolierten Prozess `usocket:socket-connect`
und `sb-bsd-sockets:socket-connect` durch zählende, ablehnende Wächter. Zusätzlich
zählt/verbietet er `get-plugin-page` und `get-fedwiki`. Eine absichtliche Kontroll-
Verbindung beweist zunächst den Zähler; anschließend werden die Fixture-Zähler
auf null gesetzt und **vor jeder Site-/Quellseiten-Erzeugung** bewacht.
Alle normalen Erfolgs-/Fehlerbefunde werden assertiert; erst dann werden exakt
**0 Socketversuche und 0 Plugin-/Kontextaufrufe** assertiert. Ein gefangener
Verbindungsfehler könnte diese Prüfung nicht bestehen. Die gelesenen Seiten- und
Snapshot-Dateien bleiben bytegleich. Die Wächter werden im `unwind-protect` restauriert.
Das ist ein Lisp-Runtime-Test, kein Browser-Paketmitschnitt.

Erneut ausgeführte Referenztests, jeweils auf ihren unveränderten Ständen:

- [PR #31](evidence/pr31-tests.log), `befce10dc0055222c33d9736723a05d0122a0c9d`:
  `scripts/test-link-resolution.lisp`, einschließlich Reading-/Inspector-Tests.
- [PR #32](evidence/pr32-tests.log), `e1ab2f570ee793e301c5af706cbcf2fc984c02a9`:
  `scripts/test-fedwiki-link-resolution.lisp`, einschließlich Nachbar-Suites und Inspector.
- [PR #33](evidence/pr33-tests.log), `68971d55f68273b77e1d33186bc66e9f019c0902`:
  sechs bestehende Suites und separate SHOP3-Leerbaumprobe.
- [Feature-Regressionen](evidence/feature-regressions.log): dieselben sechs Suites
  auf dem neuen Stand, insbesondere die bestehenden HyperBook-/Local-FedWiki-Tests
  nach Einführung der beiden Dispatch-/Ladestellen. Alle bestehen.

Der bekannte SHOP3-Leerbaumdefekt bleibt separat reproduziert. Reguläre neue
HTN-Aufgaben liefern native Bäume und simulierte Endzustände; kein künstlicher
Ersatzbaum. Java wird hier nicht erneut ausgeführt: die Java-Vergleichsevidenz
stammt aus PR #34; die genannten Lisp-Referenztests wurden jetzt erneut ausgeführt.
Keine Lisp-Critic-Engine wurde für diesen Auftrag ausgeführt.

## Reproduktion und interaktiver Einstieg

Mit der registrierten HyperDoc-Abhängigkeitsclosure (SBCL 2.4.10, SHOP3 4.3.1,
`ce53f9b651acde8c44dc21eddb1a1c5b97f10536`), aus dem Checkout:

```sh
sbcl --no-sysinit --no-userinit --non-interactive \
  --load scripts/test-fedwiki-local-only.lisp
sbcl --no-sysinit --no-userinit --non-interactive \
  --load docs/defederation-consolidation/regressions.lisp
```

Cloud-Läufe verwenden den vorhandenen relocatierten Launcher
`/workspace/scratch/defederation-tools/run.py` und `DEFEDERATION_TEST_ROOT=<checkout>`.
Die Logs enthalten die vollständigen Ausgaben, lediglich nachgestellte Leerzeichen
sind entfernt. Tests laufen getrennt vom menschlichen SLY-Image.

Im lokalen SLY jede Form als **separate mREPL-Eingabe** auswerten. Das
optionale FedWiki-System lädt den separaten Inspector nicht automatisch; bei
einer zusammen eingereichten Eingabe kann SBCL bereits beim Lesen der späteren
`clog-moldable-inspector:`-Form scheitern, bevor ASDF die erste Form lädt.

```lisp
(asdf:load-system "dreyeck/work/fedwiki-local-only")
```

```lisp
(asdf:load-system "clog-moldable-inspector")
```

```lisp
(defparameter *local-only-study*
  (dreyeck/work/fedwiki-local-only:demo))
```

```lisp
(list (dreyeck/work/fedwiki-local-only:finding *local-only-study*)
      (dreyeck/work/fedwiki-local-only:target-page *local-only-study*))
```

Erwartet: `(:CONFIRMED-LOCAL-ABSENCE NIL)`. Für die browserbasierte Lektüre
müssen CLOG und ein verbundener Browser-Body **in derselben SLY-Image**
bereits bereitstehen. `clog-inspect` kann bei fehlendem Listener CLOG starten
und wird deshalb hier nicht als stillschweigende Voraussetzung verwendet.
Die HyperDoc-Page **Reading a Local-only FedWiki Link**, Abschnitt 4, enthält
eine Task-Anleitung mit expliziten Voraussetzungen, einem
`clog:is-running-p`-/Body-Check und einem kontrollierten
`clog-moldable-inspector:on-new-inspector`-Aufruf ohne Listenerstart.

Die View **Local-only evidence** zeigt bestätigte lokale Abwesenheit und daneben
`:hypothetical-local` als Planungsresultat. Von dort: Source page → Source revision
und Story Item → Link target; Observation facts/Provenance → SHOP3 problem →
Preparation result → native Planbäume und simulierte Endzustände → geplante
`!simulate-fork`-Operation. Die Historie behält dieselben Objekte auch nach Fortsetzung.
Die Standard-Slots-View dient zum weiteren Navigieren. Ein vorheriges Ergebnis
kann lokal gebunden und mit `continue-preparation` fortgesetzt werden.

Keine Site-Freigabe aus einem Einzelziel, kein Executor, keine produktiven
Wiki-Schreibvorgänge, kein Catalog, keine Topic Map, kein Deployment, Merge oder
Dienstneustart. Registrierte Beobachtungen/Probleme bleiben für die Inspector-
Lektüre im Image; ihre Lebensdauerverwaltung ist noch kein Produktionsdienst.

## Wiederaufnahme und Abnahmestatus

Bei der Wiederaufnahme war der vorhandene Worktree
`/workspace/scratch/hyperdoc-local-only` auf Branch
`codex/fedwiki-local-only-integration`, HEAD `4e76e9aff910e9da45c1fe9252e528669c2683fb`.
Die oben beschriebene Implementierung, Tests und Dokumentation lagen bereits
als Änderungen/unversionierte Dateien vor. Es wurde keine neue Implementierungsrunde
begonnen. Zur Sicherung wurden die bisherigen Logs unter [evidence/prior/](evidence/prior/)
behalten und die fünf Testtreiber erneut ausgeführt.

[tested-source.json](evidence/tested-source.json) bindet diese erneuten Läufe an
Basiscommit plus SHA-256-Werte sämtlicher geänderter/neuer ASDF-, Runtime-, Domänen-,
Test-, Launcher- und Fixture-Dateien. Die Dateien wurden vor und nach den Läufen
verglichen. Die Referenzcheckouts für #31/#32/#33 waren sauber; deren vollständige
Commits, Befehle, Exit-Codes und Log-Digests sind ebenfalls festgehalten. Die Logs
unter `prior/` bleiben historische Ausgaben vor dieser expliziten Hash-Zuordnung.

Nach Checkout des gelieferten Commits kann diese Zuordnung geprüft werden:

```sh
python3 scripts/check-fedwiki-local-only-evidence.py
```

| Akzeptanzkriterium | Nachgewiesener Stand |
| --- | --- |
| Neuer Branch ab unverändertem PR #34 | Erfüllt; eigener Integrationsbranch, keine Änderung an #29–#34 |
| Explizite eigene Site | Erfüllt; getrennte Parameter/Koordinaten und Gegenprobe mit abweichendem Java-Origin |
| Echte lokale Seiten, Story Items und Runtime-Linkauflösung | Erfüllt für die beschriebenen Fixtures |
| Keine Plugin-/Remote-Suche, null Socketversuche auch beim Laden | Erfüllt im instrumentierten Lisp-Prozess; positive lokale Auflösung und negative Fälle assertiert |
| Zulässige Beobachtungsprädikate, diagnostizierbare Importabwehr | Erfüllt am neuen öffentlichen Slice-Einstieg |
| Herkunft und Fortsetzung aus eigenem Ergebnis | Erfüllt innerhalb desselben Images, mit unveränderter Beobachtung und eingefrorenen Endzuständen |
| PR #33 als einzige Fork-Vorbereitung; Auflösung aus #32 | Erfüllt; Fork-Domäne unverändert und im neuen Resolver keine Fork-Operatoren |
| Beobachtete versus hypothetische Präsenz, höchstens ein Fork | Erfüllt durch ausgeführte Pläne und erneutes Lesen derselben lokalen Site |
| Inspector-Objekte, Views, native Bäume/Endzustände und EQ-Verweise | Programmatisch geprüft; auch frühere Planobjekte bleiben navigierbar referenziert |
| Tatsächlich durchgeklickte Inspector-Kette in einer laufenden CLOG-Sitzung | **Offen.** Kein interaktiver Browser-/SLY-Lauf wurde durchgeführt. Erfolgreiche Unit-/HTML-Tests werden nicht als solcher Nachweis ausgegeben. |
| Relevante Tests #31/#32/#33 und Feature-Regressionen | Erfüllt; erneute Läufe und zugehörige Quellstände im Manifest |

Für die offene menschliche Abnahme die oben angegebene SLY-Form ausführen und
wirklich von der Quellseite bzw. dem Item über Ziel und Beobachtungsherkunft zu
Problem, Plan, simuliertem Endzustand und dem geplanten Fork navigieren. Dabei
Objektidentität und Kennzeichnung als hypothetisch prüfen. Es wurde dafür weder
ein Dienst gestartet/neu gestartet noch eine bestehende Live-Sitzung verändert.
