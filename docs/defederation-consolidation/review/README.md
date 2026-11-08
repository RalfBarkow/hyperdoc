# Unabhängiger Review – SHOP3-Defederation-Konsolidierung, PR #33

Zettel 11560 und 11483. Gegenstand: PR #33, Commit `7bc2fced4e970e813d870307162ec349380ca0aa` (Branch
`codex/defederation-consolidated`), Basis PR #29 `ecb2b8b576bd1cdfd080899b3946651f22dfe345`, Vergleich PR #30
`38c7ece3de4e0abbb20c8d2ba918ac8a5a3420da`. Review vom 8. November 2026, Rolle: semantischer Lisp Critic.

Dieser Ordner enthält nur Review-Artefakte. Domäne und Tests von PR #33 sind **nicht** geändert; die Korrekturen
C1–C3 wurden ausschließlich als Mutanten im Prozess der Gegenprobe definiert ([probes/mutants.lisp](probes/mutants.lisp))
und nirgends angewendet. Alle Bewertungen sind **Claude-Judgements**. Keine Riesbeck/Beane-Critic-Rule wurde ausgeführt;
es gibt hier keine Engine Critiques.

Kennzeichnung: **[obs]** in den Gegenproben beobachtet · **[abg]** aus dem Quelltext abgeleitet · **[inf]** gefolgert ·
**[hyp]** Hypothese, nicht ausgeführt.

## Entscheidung: B

PR #33 ist für den nächsten HyperDoc-Integrations-Slice geeignet **nach drei kleinen Korrekturen und zwei Testergänzungen**:

| | Korrektur | Ausgeführt als Mutant gegen die PR-Suite |
|---|---|---|
| C1 | `already-modeled` verlangt zusätzlich `(modeled-fork ?site ?slug ?_remote ?_snapshot)` (K1) | Suite grün; X1.1 ohne Plan; Fortsetzung aus dem Endzustand von B ohne Fork [obs] |
| C2 | `!prepare-paragraph-rendering` verlangt zusätzlich `(target-ready ?site ?slug)` (K3) | Suite grün; F3.5 ohne Plan [obs] |
| C3 | `?snapshot` → `?_snapshot` im Zweig `remote-conflict` (K6) | Suite grün [obs] |
| T1 | Tests für die Zustände X1.1–X1.3 und für einen direkt angeforderten Fork unter widersprüchlicher Eingabe (K4) | — |
| T2 | Die Primitiv-Probe `primitive-repeat` mit `:plan-tree nil` ausführen, damit ein Rückfall als Assertion und nicht als SHOP3-Absturz sichtbar wird (K4, K5) | — |

Begründung, nur aus überprüften Eigenschaften: F2, F3 und F4 halten in allen Gegenproben; Methoden- und
Operator-Präbedingungen verhindern gemeinsam einen Fork ohne Evidenz; alle Beobachtungen bleiben in allen 20
erfolgreichen Endzuständen von counter-probes.lisp erhalten; die PR-eigene Suite erkennt 11 von 14 gezielten Mutanten sauber. Die gefundenen
Lücken sind lokal und durch je eine zusätzliche Präbedingung bzw. eine Umbenennung behebbar, ausgeführt und mit der
Suite verträglich. Eine grundlegende Überarbeitung (C) ist durch nichts begründet; unverändert übernommen (A) trüge K1
in den Integrations-Slice. Die Korrekturen übernimmt Codex in einem gesonderten Auftrag.

## Vier Unterscheidungen

**1. Konsistenz zweier modellierter Fakten ≠ nachgewiesene Herkunft.** `already-modeled` (Z. 61–64) prüft nur
`modeled-local-page`. C1 verlangt zusätzlich `modeled-fork` und macht damit zwei *modellierte* Fakten miteinander
konsistent: eine modellierte Präsenz ohne den sie erzeugenden modellierten Fork wird abgewiesen (X1.1 [obs]). Das ist
keine nachgewiesene Herkunft. Ein Eingangszustand kann beide Fakten gemeinsam enthalten, ohne dass je ein Plan sie aus
Evidenz erzeugt hat [abg]; nichts in der Domäne verbindet `modeled-fork` mit dem Plan, der Evidenz oder dem Zeitpunkt,
aus denen er stammt. Nachgewiesene Herkunft verlangt eine Provenienzangabe außerhalb dieser Fakten (z. B. ein Verweis auf
das erzeugende `hyperdoc-htn-plan-result` und seinen Anfangszustand) – eine Aufgabe für den Integrations-Slice, nicht
Teil von C1 [inf].

**2. Gültige Fortsetzung ≠ beliebig importierter Zustand.** Gültig ist eine Fortsetzung, wenn ihr Anfangszustand der
Endzustand eines Plans dieser Domäne ist: F2.2b plant aus dem Endzustand von B ohne neuen Fork [obs]; dieser Zustand
enthält `modeled-local-page` und `modeled-fork` gemeinsam, weil der Fork beide setzt (Z. 40–41) [abg]. Die Domäne kann
einen solchen Zustand nicht von einem beliebig importierten unterscheiden: X1.1–X1.3 (nur modellierte Präsenz, sogar mit
`fork-forbidden`, ohne Snapshot und Politik) und F2.7 (`modeled-fork` ohne `modeled-local-page`) werden ebenso
angenommen [obs]. C1 schließt X1.1–X1.3; F2.7 bleibt (K2). Für importierte Zustände braucht der Integrations-Slice eine
Grenze: modellierte Fakten nur mit Herkunft (Punkt 1) annehmen oder beim Import entfernen [inf].

**3. Direkte primitive SHOP3-Aufgaben ≠ reguläre HTN-Aufgabe `prepare-defederation`.** Die reguläre Aufgabe prüft
`input-conflict` in der Top-Methode und wählt `ensure-local-target` vor den Vorbereitungsschritten. Eine direkt
angeforderte primitive Aufgabe umgeht beides; dann gelten nur die Präbedingungen des Operators [abg]. Für den Fork
genügen sie: ohne jede einzelne Evidenz kein Plan (X2), zweimal direkt kein Plan (F2.4), nach `prepare` kein Plan (F2.3)
[obs]. Für den Paragraph-Schritt nicht: mit einem mitgelieferten Marker gelingt er ohne Zielbereitschaft (F3.5b, K3)
[obs]. Primitive Aufgaben sind nicht die vorgesehene Schnittstelle; K3 betrifft nur Aufrufer, die das HTN umgehen.

**4. SHOP3-Planbaumfehler ≠ Fehler der Defederationsdomäne.** Das gepinnte SHOP3 `ce53f9b` bricht die
Planbaum-Extraktion mit `TYPE-ERROR` (`NIL` ist kein `CONS`) ab, wenn ein Plan keinen Schritt hat (bekannt) **oder** die
Top-Level-Aufgabe primitiv ist (K5). Unabhängig von jeder dreyeck-Domäne mit einer Minidomäne reproduziert
([probes/shop3-primitive-tree.lisp](probes/shop3-primitive-tree.lisp)): `(!step)` mit `:plan-tree t` → `TYPE-ERROR`,
ohne Baum → Plan, in eine Methode verpackt → Plan [obs]. In der Defederationsdomäne erscheint derselbe Fehler bei S1 und
X6.1 [obs]; er sagt nichts über die Domäne. Er beeinflusst aber die Tests: Mutant M2 wird nur dadurch erkannt, dass
`primitive-repeat` im Planbaum abstürzt (K4).

## Befunde

**K1 – `already-modeled` akzeptiert modellierte Präsenz ohne erzeugenden Fork** (Konsequenz mittel)
- Quelle: `dreyeck/work/defederation-planning.lisp` Z. 61–64; `input-conflict` (Z. 10–21) prüft keine modellierten Fakten.
- Gegenprobe: X1.1, X1.2, X1.3 in [probes/counter-probes.lisp](probes/counter-probes.lisp).
- Ergebnis [obs]: Nur `(modeled-local-page :s :t)` → vollständiger Plan mit beiden Markern; ebenso mit
  `local-page-absent` und `fork-forbidden` ohne Snapshot und Politik, und mit `snapshot-unavailable` und
  `remote-page-absent`.
- Erwartet: kein Plan ohne den Fork, der die modellierte Präsenz begründet.
- Konsequenz [inf]: Ein importierter oder von Hand erstellter Zustand macht ein Ziel „vorbereitet“, ohne dass je ein
  zulässiger Fork geplant wurde, selbst gegen ein ausdrückliches Verbot.
- Kleinste Korrektur: C1 (Konsistenz, siehe Unterscheidung 1). Optional [hyp]: ein `input-conflict`-Zweig für
  `modeled-fork` zusammen mit `fork-forbidden`.

**K2 – `modeled-fork` ohne `modeled-local-page` plant einen weiteren Fork** (niedrig)
- Quelle: Fork-Methode Z. 65–72 und Operator Z. 33–41 prüfen nur `modeled-local-page`.
- Gegenprobe: F2.7. Ergebnis [obs]: `!simulate-fork` wird geplant, obwohl derselbe `modeled-fork` schon vorliegt.
- Erwartet: kein zweiter Fork für ein Ziel, dessen Fork bereits modelliert ist.
- Konsequenz: aus Endzuständen der Domäne nicht erreichbar, nur aus inkonsistenten Eingaben [abg].
- Kleinste Korrektur [hyp, nicht ausgeführt]: `(not (modeled-fork ?site ?slug ?_r ?_s))` in Methode und Operator,
  oder ein entsprechender Konfliktzweig.

**K3 – Paragraph-Schritt ohne Zielbereitschaft als direkte Aufgabe** (niedrig)
- Quelle: `!prepare-paragraph-rendering` Z. 46–48 verlangt nur `local-links-prepared`.
- Gegenprobe: F3.5b in [probes/primitive-tasks.lisp](probes/primitive-tasks.lisp). Ergebnis [obs]: Mit mitgeliefertem
  `(local-links-prepared :s :t)` und `local-page-absent` ergibt sich ein Plan.
- Erwartet: keine Paragraph-Vorbereitung für ein nicht bereites Ziel.
- Konsequenz: nur bei Umgehung des HTN (Unterscheidung 3) [abg].
- Kleinste Korrektur: C2, ausgeführt [obs].

**K4 – Testaussagekraft** (niedrig)
- Gegenprobe: [probes/mutants.lisp](probes/mutants.lisp), Tabelle unten.
- Ergebnis [obs]: 11 von 14 Mutanten sauber erkannt. M2 (Operator ohne `(not modeled-local-page)`) wird nur durch den
  SHOP3-Absturz in `primitive-repeat` (Testdatei Z. 164–167, `:plan-tree t`) erkannt. M1 und M10 sind auf Planebene
  äquivalent, weil sich Methoden- und Operator-Wächter decken. M15 (das Verhalten von K1) wird von keinem Test
  berührt.
- Kleinste Korrektur: T1 und T2.

**K5 – SHOP3-Planbaumfehler auch bei primitiven Top-Level-Aufgaben** (Beobachtung, kein Domänenfehler)
- Gegenproben: S1/S2 in [probes/primitive-tasks.lisp](probes/primitive-tasks.lisp);
  [probes/shop3-primitive-tree.lisp](probes/shop3-primitive-tree.lisp) ohne dreyeck-Code. Ergebnis siehe Unterscheidung 4.
- Konsequenz: Primitive Top-Level-Aufgaben nur mit `:plan-tree nil` prüfen; Planbäume kommen aus regulären Aufgaben.

**K6 – Singleton-Warnung `?SNAPSHOT`** (harmlos)
- Quelle: `input-conflict`, Zweig 4 `remote-conflict` (Z. 18–19); Warnung in [logs/own-suite.log](logs/own-suite.log).
- Bedeutung [abg]: existenziell – „irgendeine angebotene Kopie von diesem Remote“, so wie dokumentiert.
- Folge, kein Fehler [obs]: Widersprüchliche Evidenz zum Remote einer angebotenen Kopie blockiert das ganze Ziel, auch
  wenn eine andere Quelle sauber ist (F4.8); Widersprüche zu einem Remote ohne angebotene Kopie blockieren nicht (F4.9).
- Kleinste Korrektur: C3; Präfix `?_` unterdrückt die Warnung, wie Zweig 2 zeigt [obs].

**K7 – Problemregistrierungen bleiben liegen** (niedrig)
- Quelle: `plan-defederation` Z. 92–110 registriert je Aufruf ein Gensym-Problem und löscht es nicht.
- Gegenprobe: R1. Ergebnis [obs]: fünf Aufrufe → `*all-problems*` wächst um 5.
- Kleinste Korrektur [hyp]: `shop3:delete-problem` in einem `unwind-protect`, außer wenn `defederation-experiment` das
  Problem über `find-problem` noch braucht (Z. 126).

**K8 – Leere Zerlegungen fehlen im Planbaum** (Information)
- Ergebnis [obs]: `already-local` und `already-modeled` erscheinen nicht unter den Methodenlabels des nativen Planbaums
  (X1.1, F2.2b: nur `PREPARE-AFTER-CONSISTENCY-CHECK`).
- Konsequenz [inf]: Eine Inspector-Lektüre muss „beobachtet lokal“ und „modelliert lokal“ aus dem Zustand lesen, nicht
  aus dem Baum.

## Was hält [obs]

| Bereich | Gegenproben | Ergebnis |
|---|---|---|
| F2 Wiederholung | F2.1, F2.5, F2.6 | dreimal ein Ziel: ein Fork; zwei Snapshots, zweimal: zwei Alternativen mit je einem Fork |
| F2 Fortsetzung vs. neuer Plan | F2.2a–c | Fortsetzung aus dem Endzustand: kein Fork; neuer Plan aus unverändertem B: derselbe hypothetische Fork |
| F2 Primitive | F2.3, F2.4 | nach `prepare` und zweimal direkt, auch mit zwei Snapshots: kein Plan |
| F3 Geltungsbereich | F3.1–F3.4, F3.6–F3.8 | Marker nur mit Ziel-Slug; Widerspruch an anderem Slug blockiert nicht; zwei Ziele: Fork nur für das abwesende; jeder Zielkonflikt blockiert, auch bei lokalem Ziel |
| F4 Kopie | F4.1, F4.2, F4.9, F4.10 | unbekannt und negativ: Fork (dokumentiert); unbeteiligtes Remote blockiert nicht; zwei Snapshots: zwei Alternativen |
| F4 strikt | F4.3–F4.8 | unbekannt/negativ: kein Plan; Evidenz nur für anderes Remote: kein Plan; zwei Snapshots: genau der mit Evidenz |
| F4 Politik | F4.11, F4.12, F3.6 | unbekannter Wert, nur für anderen Slug, gegensätzliche Politiken: kein Plan |
| Kopie ≠ Erreichbarkeit | alle F4 | kein Endzustand enthält `remote-page`; der Fork fügt nur `modeled-fork` und `modeled-local-page` hinzu |
| Operator-Wächter | X2 | ohne jede einzelne Evidenz bzw. strikt ohne Remote-Evidenz: kein Plan |
| Beobachtungen | alle Pläne in counter-probes.lisp | 20 von 20 Endzuständen enthalten alle Eingangsbeobachtungen; nichts entfernt |
| Leerer Plan vs. keine Lösung | X6.1–X6.3 | Szenario C: `:no-plan`; null Schritte: Plan nur ohne Baum (K5) |
| Axiomsemantik | F4.7, F4.10 | SHOP3 wertet Axiomzweige wie if-then-else mit `%cut%` aus (Quelltext); der strikte Zweig greift, wenn der Kopien-Zweig fehlschlägt, und innerhalb eines Zweigs werden alle Snapshots aufgezählt |

## Mutanten gegen die PR-eigene Suite [obs]

| Mutant | Änderung | Ergebnis |
|---|---|---|
| M0 | keine | überlebt (Kontrolle) |
| M1 | Fork-Methode ohne `(not modeled-local-page)` | überlebt (Operator schützt) |
| M2 | Fork-Operator ohne `(not modeled-local-page)` | erkannt, aber nur durch SHOP3-`TYPE-ERROR` (K4, K5) |
| M3 | beide ohne `(not modeled-local-page)` | erkannt |
| M4 | `already-modeled` entfernt | erkannt |
| M5 | strikter Zweig ohne `remote-page` | erkannt |
| M6 | Kopien-Zweig ohne Politik | erkannt |
| M7–M9 | Konfliktzweige `policy`, `remote`, `snapshot` entfernt | je erkannt |
| M10 | Operator ohne `(not input-conflict)` | überlebt (Top-Methode schützt) |
| M11 | Marker wieder mit Site-Arity | erkannt |
| M12 | `target-ready` ohne simulierten Zweig | erkannt |
| M13 | Fork ohne `local-page-absent` | erkannt |
| M14 | Fork fügt zusätzlich `local-page` hinzu | erkannt |
| M15 | unverändert (Verhalten von K1) | überlebt: kein Test |
| C1–C3 | Korrekturen | überleben, d. h. die Suite bleibt grün |

## Zuordnung

| Probe | Datei | Log | Befund |
|---|---|---|---|
| F2.1–F2.6 | probes/counter-probes.lisp | logs/counter-probes.log | F2 hält |
| F2.7 | probes/counter-probes.lisp | logs/counter-probes.log | K2 |
| X1.1–X1.3 | probes/counter-probes.lisp | logs/counter-probes.log | K1, K8 |
| F3.1–F3.4, F3.6–F3.8 | probes/counter-probes.lisp | logs/counter-probes.log | F3 hält |
| F3.5 (`:plan-tree t`) / F3.5b (`nil`) | probes/counter-probes.lisp / probes/primitive-tasks.lisp | logs/counter-probes.log / logs/primitive-tasks.log | K5 / K3 |
| F4.1–F4.12 | probes/counter-probes.lisp | logs/counter-probes.log | F4 hält, K6 |
| X2 | probes/counter-probes.lisp | logs/counter-probes.log | Operator-Wächter halten |
| X6.1–X6.3 | probes/counter-probes.lisp | logs/counter-probes.log | K5; leerer Plan vs. keine Lösung |
| R1 | probes/counter-probes.lisp | logs/counter-probes.log | K7 |
| S1, S2 | probes/primitive-tasks.lisp | logs/primitive-tasks.log | K5 |
| M0–M15, C1–C3 | probes/mutants.lisp | logs/mutants.log | K4, C1–C3 |
| `(!step)` | probes/shop3-primitive-tree.lisp | logs/shop3-primitive-tree.log | K5 (ohne dreyeck-Code) |
| PR-eigene Suite | probes/own-suite.lisp | logs/own-suite.log | K6 (Warnung), Ausgangslage |

## Reproduktion

Vom Wurzelverzeichnis eines Checkouts von `7bc2fce` (oder dieses Review-Commits, der nur diesen Ordner hinzufügt), mit
der ASDF-Registry der Projektabhängigkeiten (SBCL 2.4.10, SHOP3 `ce53f9b`; z. B. in `nix develop`). Jeder Aufruf ist
ein eigener frischer Prozess; die Skripte schreiben nichts und ändern weder Domäne noch Tests.

```sh
sbcl --noinform --no-sysinit --no-userinit --non-interactive --load docs/defederation-consolidation/review/probes/own-suite.lisp
sbcl --noinform --no-sysinit --no-userinit --non-interactive --load docs/defederation-consolidation/review/probes/counter-probes.lisp
sbcl --noinform --no-sysinit --no-userinit --non-interactive --load docs/defederation-consolidation/review/probes/primitive-tasks.lisp
sbcl --noinform --no-sysinit --no-userinit --non-interactive --load docs/defederation-consolidation/review/probes/mutants.lisp
sbcl --noinform --no-sysinit --no-userinit --non-interactive --load docs/defederation-consolidation/review/probes/shop3-primitive-tree.lisp
```

Die Logs in [logs/](logs/) stammen aus genau diesen Dateien, ausgeführt am 8. November 2026 in frischen Prozessen mit
eigenem Netzwerk-Namespace ohne Netz, leerem HOME und eigenem FASL-Cache, alle mit Exit-Status 0. Jeder Log nennt im
Kopf den Aufruf und den Filter, mit dem er aus der vollständigen Prozessausgabe entnommen wurde. Die Ergebnisse sind
zeilengleich mit den Läufen, auf denen der Review zuerst beruhte.
