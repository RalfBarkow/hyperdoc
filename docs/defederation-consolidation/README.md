# SHOP3 Defederation – Konsolidierung Slice 1

Zettel 11560 / 11483. Neuer Branch `codex/defederation-consolidated`,
Basis PR #29 `ecb2b8b576bd1cdfd080899b3946651f22dfe345`.
Vergleich PR #30 `38c7ece3de4e0abbb20c8d2ba918ac8a5a3420da`.
Am 8. November 2026 stimmen beide Remote-Branches mit diesen Commits überein.
`dreyeck.ch` steht auf `00d2a18bbc9cbd2045454ce8f9c4af8d8b58e60a`.
PR #31 steht auf `befce10dc0055222c33d9736723a05d0122a0c9d`,
PR #32 auf `e1ab2f570ee793e301c5af706cbcf2fc984c02a9`.
Keiner dieser vier PR-Branches wird verändert. Der neue Draft baut auf #29 auf.

## Review-Verfügbarkeit und rekonstruierte Befunde

Im untersuchten Repository-Bestand der Referenzstände wurde kein vollständiger
Claude-Defederationsbericht F1–F7 gefunden. Die gefundenen F1–F11-Verweise unter
`conversation-coordinates` betreffen einen anderen Review. Ein fehlender Bericht
wurde nicht gelesen. F2/F3/F4 sind hier die Aufgabenbeschreibungen des Auftraggebers;
F1/F5/F6/F7 werden mangels Bericht nicht rekonstruierten Aussagen zugeordnet.
Die folgenden Befunde stammen aus eigener Quellprüfung und ausgeführten SHOP3-Läufen.

[reference-probes.lisp](reference-probes.lisp) läuft unverändert auf beiden
Referenzständen und verwendet deren tatsächliche Domänen. Ergebnisse:

| Gegenprobe | PR #29 | PR #30 | Konsolidierung |
| --- | --- | --- | --- |
| Zweimal dasselbe Ziel vorbereiten | Zwei Fork-Operatoren | Ein Fork; setzt `local-page`, löscht Abwesenheit | Ein Fork, zwei Zielvorbereitungen; `modeled-local-page`, ursprüngliche Beobachtungen erhalten |
| Widerspruch an anderer Seite | Ein vollständiger Plan | Kein Plan wegen globaler Konsistenzprüfung | Ein vollständiger Plan; zielgebundene Prüfung beibehalten |
| Lokales Ziel | Kein Fork | Kein Fork | Kein Fork, auch bei Wiederholung |
| Vorbereitungseffekte | Siteweite Fakten nach einem Ziel | Siteweite Fakten nach einem Ziel | Beide Fakten tragen zusätzlich den Slug; keine Site-Freigabe |

Ausgaben: [PR29](pr29-probes.log), [PR30](pr30-probes.log).

## Fachlicher Vertrag

Eine Aufgabe `prepare-defederation(site, slug)` bereitet genau ein benötigtes
Linkziel vor. `local-links-prepared(site, slug)` bedeutet: die modellierte
Local-only-Anforderung wurde für dieses Ziel vorbereitet.
`paragraph-rendering-prepared(site, slug)` bedeutet: die Paragraph-only-Anforderung
wurde innerhalb derselben Zielvorbereitung vorgemerkt. Es wurde weder ein Renderer
umgestellt noch die Story einer ganzen Site geprüft. Diese Fakten sind ausschließlich
simulierte Planungsmarker; sie sind keine Aussagen über laufende Konfigurationen.
Die frühere einstellige Arity ist absichtlich ersetzt. Es gibt weder eine
Gesamtliste aller benötigten Ziele noch eine HTN-Aufgabe zur vollständigen
Site-Vorbereitung. Ein Einzelzielplan kann daher keine Site-Freigabe begründen.

Beibehalten aus #29: beobachtetes `local-page`, getrenntes `modeled-local-page`,
explizite Abwesenheit/Verbote, zielgebundene Konfliktprüfung, echtes SHOP3,
`:which :all`, `hyperdoc-htn-plan-result` mit unveränderten nativen Planbäumen,
simulierten Endzuständen und `:plan-only`. Die bisherigen Methodenmutanten bleiben
Teil der Tests. Initiale Beobachtungen werden nicht gelöscht.

F2-Korrektur: Eine neue `already-modeled`-Methode übernimmt bereits hypothetisch
lokale Ziele. Sowohl Fork-Methode als auch primitiver Fork-Operator verlangen,
dass weder beobachtete noch modellierte lokale Präsenz vorliegt. Die Negation
modellierter Präsenz steuert nur die Simulation; sie ersetzt niemals den positiven
Nachweis `local-page-absent`. Zwei direkt angeforderte primitive Forks liefern
keinen Plan. Weiterplanen aus dem simulierten Endzustand benötigt keinen neuen Fork.
Ein unabhängiger Suchlauf mit ursprünglichem Zustand kann erneut denselben
hypothetischen Fork beschreiben: Planung ist keine persistierte Ausführung.

## F4: Kopie und Remote-Evidenz

`remote-snapshot(site, slug, remote, snapshot)` bleibt eine identifizierte,
als überprüfbar bereitgestellte gespeicherte Kopie im modellierten Eingangszustand.
Der Planner prüft keine Datei oder Prüfsumme selbst. Der Fakt sagt nichts über die
gegenwärtige Erreichbarkeit von `remote`. PR #30 trennt `snapshot-available` und
`remote-page`, fordert jedoch beide ohne auswählbare Annahme. Seine Snapshot-Aussage
enthält zudem keine separate Snapshot-Identität.

Übernommen wird die nützliche Unterscheidung durch einen zusätzlichen positiven
`remote-page(remote, slug)`-Nachweis und sein explizites Gegenteil. Die vorhandene
Snapshot-Identität aus #29 bleibt erhalten. Zwei explizite, zielgebundene Politiken:

- `fork-source-policy(site, slug, :cached-copy-sufficient)`: Die gespeicherte Kopie
  genügt zusammen mit lokaler Abwesenheit und Fork-Erlaubnis. Selbst ausdrücklich
  negative Remote-Evidenz verhindert diesen Plan nicht.
- `fork-source-policy(site, slug, :require-remote-evidence)`: Zusätzlich ist
  `remote-page` erforderlich. Unbekannte oder negative Remote-Evidenz genügt nicht.

Ohne Quellenpolitik kein Fork-Plan. Gleichzeitige gegensätzliche Politiken oder
positive und negative Remote-Evidenz für eine angebotene Kopie blockieren das Ziel.
Widersprüche zu anderen Zielen bleiben außerhalb dieser Prüfung. Beobachtungen
enthalten noch keine Zeit-/Frischegarantie: auch die strengere Variante beweist
keine jetzige Erreichbarkeit und kontaktiert keine Site. Welche Politik fachlich
gelten soll, bleibt ausdrücklich offen; Fixture B wählt die Kopienvariante.

Nicht übernommen aus #30: Umdeuten simulierter Präsenz in Beobachtung, globale
Konfliktsperre, siteweite Vorbereitungseffekte, obligatorische Remote-Präsenz.
Seine um eine Remote-Koordinate erweiterte Fork-Erlaubnis wird ebenfalls nicht
übernommen: für den begrenzten Zielvertrag ist ihr Nutzen hier nicht nachgewiesen.
Es wird keine zweite Domäne oder HTN-Engine eingeführt.

## Ausgeführte Abnahme und Grenzen

[feature-tests.log](feature-tests.log) enthält die ausgeführten ursprünglichen
#29-Tests mit angepasster Effekt-Arity sowie zusätzliche Prüfungen:
A/B/C; jede entfernte Fork-Voraussetzung; fehlende und ausdrücklich negative
Evidenz; Zielkonflikte und unabhängiger Konflikt; Wiederholung; Weiterplanung;
primitive Wiederholung; beide Quellenpolitiken; widersprüchliche Quellenpolitik;
zwei echte alternative Snapshot-Quellen. Alle Suchen enumerieren `:which :all`.
Die Alternativenprobe liefert zwei vollständige Pläne, je einen Fork, zwei
Planbäume und zwei Endzustände. Die Methodenmutanten fordern zusätzliche
`fork-reviewed`-Evidenz: ohne sie keine alternative Lösung, mit ihr wieder Erfolg.
Die Tests prüfen Operatorfolgen und Endzustände, nicht nur Methodenlabels.

Sechs bestehende Suites wurden auf **jedem** der beiden unveränderten Referenzstände
und auf dem Feature ausgeführt: Defederation, allgemeines Planning, Remote-Control
Planning, Remote-Control Reading, Local-FedWiki-Page und Hyperbook/FedWiki.
Die jeweilige Defederationssuite stammt dabei aus dem jeweiligen PR, nicht aus
einer Portierung. Sie bestehen. [PR29-Ausgabe](pr29-tests.log),
[PR30-Ausgabe](pr30-tests.log), [Feature-Ausgabe](feature-tests.log).

Der bekannte separate SHOP3-Fehler ist auf beiden Referenzständen und dem Feature
reproduziert: Ein rein leerer Plan gelingt ohne Baum mit Rohwert `(NIL)`; mit
`:plan-tree t` entsteht ein `TYPE-ERROR` (`NIL` ist kein `CONS`).
`regressions.lisp` prüft beide Wege und fängt ausschließlich den erwarteten
TYPE-ERROR. SHOP3 wurde nicht geändert und keine künstliche Aktion eingefügt,
um den Defekt zu verstecken. Die vollständigen A/B-Vorbereitungen besitzen echte
primitive Schritte; ihre Bäume und Endzustände bleiben verfügbar. C bleibt
`:no-plan`, niemals erfolgreiche Ausführung. Kein anderer Basisfehler wurde beobachtet.

## Reproduktion und SLY-Einstieg

Mit registrierten Repository-Abhängigkeiten, SBCL 2.4.10 und dem gepinnten SHOP3
4.3.1 (`ce53f9b651acde8c44dc21eddb1a1c5b97f10536`):

```sh
sbcl --no-sysinit --no-userinit --non-interactive \
  --load docs/defederation-consolidation/regressions.lisp
```

Für Referenzläufe muss die ASDF-Registry auf den jeweiligen unveränderten Checkout
zeigen. Dann denselben Regressionstreiber und `reference-probes.lisp` laden.
Cloud-Ausführung: `DEFEDERATION_TEST_ROOT=<checkout> python3
/workspace/scratch/defederation-tools/run.py --load <absoluter-treiberpfad>`.
Ausgaben sind vollständige Prozesslogs, nur nachgestellte Leerzeichen entfernt.
Diese Nachweise stammen aus isolierten Testprozessen, nicht aus einem Benutzer-SLY-Image.

In SLY zuerst das optionale System laden, danach separat auswerten:

```lisp
(asdf:load-system "dreyeck/work/defederation-planning")
```

```lisp
(defparameter *defederation-repeat*
  (dreyeck/work/defederation-planning:plan-defederation
    (dreyeck/work/defederation-planning:scenario-state :b) :repeat 2))
(dreyeck/shop3:plans-of *defederation-repeat*)
(clog-moldable-inspector:clog-inspect :object *defederation-repeat*)
```

Erwartet: ein Plan mit fünf Operatoren, davon genau ein Fork; zwei Zielvorbereitungen
im nativen Planbaum; `modeled-local-page` plus erhaltene beobachtete Abwesenheit im
Endzustand. Zum Review Plan, Baum, Endzustand oder eine tatsächliche Condition
zurückgeben. Keine Behauptung eines bereits durchgeführten SLY-Laufs.

Kein neuer HyperBook-/Catalog-Slice. PR #31/#32 und deren Resolvermodelle bleiben
unverändert. Keine produktiven Wiki-Schreibvorgänge, keine Resolver-/Renderer-
Umstellung, kein Merge, Deployment oder Dienstneustart. Danach unabhängiger Claude-Review.
